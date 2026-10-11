package eu.marandos.offload.capture

import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Durable, encrypted hand-off queue between the native capture window and the
 * app (REQ-001, DD-010; design from spike S3).
 *
 * Guarantee (AC REQ-001): once [enqueue] has returned, the capture is never
 * lost before the app has stored it and called [acknowledge].
 * - [enqueue] writes `<id>.tmp`, syncs it, renames it to `<id>.cq` and syncs
 *   the directory before it returns. A crash before the rename leaves a `.tmp`
 *   that was never confirmed to the user.
 * - [drain] never deletes a capture; only [acknowledge] does, after the app
 *   stored it. The id is fixed at capture time, so a capture delivered twice
 *   is stored once.
 * - A file that cannot be read is moved to `quarantine/`, never deleted.
 *
 * File format: format version (1 byte) | IV (12) | AES-256-GCM ciphertext and
 * tag, with the id as associated data, so a file renamed to another id cannot
 * be read. Plaintext: payload version (1 byte) | source (modified UTF-8) |
 * text length (4 bytes) | text (UTF-8). The text is kept exactly as typed.
 *
 * All operations of all instances run one at a time: the capture window and
 * the app live in the same process, and a drain must never remove the `.tmp`
 * of a capture that is still being written.
 */
class CaptureQueue(
    private val dir: File,
    private val key: () -> SecretKey,
    private val syncDirectory: (File) -> Unit,
    private val newId: () -> String = { UuidV7.next() },
) {
    data class Entry(val id: String, val text: String, val source: String)

    data class Drained(val entries: List<Entry>, val newlyQuarantined: Int)

    private val quarantine = File(dir, QUARANTINE_DIR)

    /**
     * Stores [text] for the app and returns its id; the capture is safe once
     * this returns. Throws when it could not be stored; nothing was confirmed.
     */
    fun enqueue(text: String, source: String): String = synchronized(LOCK) {
        require(hasCapturableText(text)) { "No text to capture" }
        require(SOURCE.matches(source)) { "Invalid source" }
        ensureDir()
        val id = newId()
        check(UuidV7.isValid(id)) { "Invalid id" }

        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, key())
        cipher.updateAAD(id.toByteArray(Charsets.UTF_8))
        val sealed = cipher.doFinal(encodePayload(text, source))

        val tmp = File(dir, "$id$TMP")
        try {
            FileOutputStream(tmp).use { out ->
                out.write(FORMAT_VERSION)
                out.write(cipher.iv)
                out.write(sealed)
                out.fd.sync()
            }
            if (!tmp.renameTo(File(dir, "$id$QUEUED"))) throw IOException("Rename failed")
        } catch (e: Exception) {
            tmp.delete()
            throw e
        }
        // If this fails the user sees an error although the capture exists;
        // saving again then gives a duplicate, never a loss.
        syncDirectory(dir)
        id
    }

    /**
     * The waiting captures, oldest first. Removes leftover `.tmp` files and
     * moves files whose content cannot be read to quarantine; deletes no
     * capture.
     *
     * Only the content of a file sends it to quarantine. A failure outside
     * the file (the key is unavailable, a read error) makes the whole drain
     * fail and moves nothing, so the captures come back at the next attempt.
     */
    fun drain(): Drained = synchronized(LOCK) {
        if (!dir.isDirectory) return Drained(emptyList(), 0)
        dir.listFiles { f -> f.isFile && f.name.endsWith(TMP) }?.forEach { it.delete() }
        val files = dir.listFiles { f -> f.isFile && f.name.endsWith(QUEUED) }.orEmpty()
        if (files.isEmpty()) return Drained(emptyList(), 0)

        val secretKey = key()
        val entries = mutableListOf<Entry>()
        val unreadable = mutableListOf<File>()
        for (file in files) {
            val id = file.name.removeSuffix(QUEUED)
            val entry = if (UuidV7.isValid(id)) read(id, file.readBytes(), secretKey) else null
            if (entry == null) unreadable += file else entries += entry
        }
        val quarantined = moveToQuarantine(unreadable)
        // UUIDv7 ids sort by capture time.
        Drained(entries.sortedBy { it.id }, quarantined)
    }

    /** Removes the captures [ids]; call only after the app stored them. */
    fun acknowledge(ids: Collection<String>) = synchronized(LOCK) {
        var removed = false
        for (id in ids) {
            // Only real ids: never a path from outside.
            if (UuidV7.isValid(id) && File(dir, "$id$QUEUED").delete()) removed = true
        }
        if (removed) syncDirectory(dir)
    }

    /**
     * Moves the captures [ids] to quarantine: the app could read them but
     * refuses to store them. Kept, never deleted; returns how many moved.
     */
    fun setAside(ids: Collection<String>): Int = synchronized(LOCK) {
        moveToQuarantine(ids.filter(UuidV7::isValid).map { File(dir, "$it$QUEUED") }.filter { it.isFile })
    }

    private fun moveToQuarantine(files: List<File>): Int {
        if (files.isEmpty()) return 0
        quarantine.mkdirs()
        val moved = files.count { it.renameTo(File(quarantine, it.name)) }
        try {
            syncDirectory(dir)
        } catch (e: Exception) {
            // The files are moved; only the durability of the move is unsure.
            // Not failing here keeps the count, so the app can report them.
        }
        return moved
    }

    private fun ensureDir() {
        if (!dir.isDirectory && !dir.mkdirs()) throw IOException("Cannot create queue directory")
    }

    /**
     * The capture in [bytes], or null when the content cannot be read: a bad
     * header, a failed authentication (damaged, renamed or written under
     * another key) or a bad payload. Key and provider errors are not about
     * the content and propagate.
     */
    private fun read(id: String, bytes: ByteArray, secretKey: SecretKey): Entry? {
        if (bytes.size <= HEADER_SIZE || bytes[0] != FORMAT_VERSION.toByte()) return null
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.DECRYPT_MODE, secretKey, GCMParameterSpec(TAG_BITS, bytes, 1, IV_SIZE))
        cipher.updateAAD(id.toByteArray(Charsets.UTF_8))
        val plain = try {
            cipher.doFinal(bytes, HEADER_SIZE, bytes.size - HEADER_SIZE)
        } catch (e: AEADBadTagException) {
            return null
        }
        return try {
            decodePayload(id, plain)
        } catch (e: IllegalArgumentException) {
            null
        } catch (e: IOException) {
            // Truncated or trailing bytes in the decrypted payload.
            null
        }
    }

    private fun encodePayload(text: String, source: String): ByteArray {
        val textBytes = text.toByteArray(Charsets.UTF_8)
        val buffer = ByteArrayOutputStream()
        DataOutputStream(buffer).use { out ->
            out.writeByte(PAYLOAD_VERSION)
            out.writeUTF(source)
            out.writeInt(textBytes.size)
            out.write(textBytes)
        }
        return buffer.toByteArray()
    }

    private fun decodePayload(id: String, plain: ByteArray): Entry {
        DataInputStream(ByteArrayInputStream(plain)).use { input ->
            require(input.readUnsignedByte() == PAYLOAD_VERSION) { "Unknown payload version" }
            val source = input.readUTF()
            require(SOURCE.matches(source)) { "Invalid source" }
            val length = input.readInt()
            require(length in 0..input.available()) { "Bad text length" }
            val textBytes = ByteArray(length)
            input.readFully(textBytes)
            if (input.read() != -1) throw IOException("Trailing bytes")
            val text = String(textBytes, Charsets.UTF_8)
            require(hasCapturableText(text)) { "No text" }
            return Entry(id, text, source)
        }
    }

    companion object {
        private val LOCK = Any()

        /**
         * The characters Dart's `String.trim()` removes: Unicode White_Space
         * plus U+FEFF. The window and the app must agree on what "no text"
         * is, or a capture the app refuses could be confirmed here.
         */
        private val TRIMMED = setOf(
            '\u0009', '\u000A', '\u000B', '\u000C', '\u000D', ' ', '\u0085', '\u00A0',
            '\u1680', '\u2000', '\u2001', '\u2002', '\u2003', '\u2004', '\u2005', '\u2006',
            '\u2007', '\u2008', '\u2009', '\u200A', '\u2028', '\u2029', '\u202F', '\u205F',
            '\u3000', '\uFEFF',
        )

        /** Same rule as the app's `hasCapturableText` (REQ-018). */
        fun hasCapturableText(text: String): Boolean = text.any { it !in TRIMMED }

        const val QUARANTINE_DIR = "quarantine"
        private const val TMP = ".tmp"
        private const val QUEUED = ".cq"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val FORMAT_VERSION = 1
        private const val PAYLOAD_VERSION = 1
        private const val IV_SIZE = 12
        private const val TAG_BITS = 128
        private const val HEADER_SIZE = 1 + IV_SIZE
        private val SOURCE = Regex("^[a-z]{1,16}$")
    }
}
