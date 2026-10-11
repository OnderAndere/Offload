package eu.marandos.offload

import android.content.Context
import android.content.pm.ApplicationInfo
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.system.ErrnoException
import android.system.Os
import android.system.OsConstants
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.nio.channels.FileChannel
import java.nio.file.Files
import java.nio.file.StandardCopyOption
import java.nio.file.StandardOpenOption
import java.security.GeneralSecurityException
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Stores the master key wrapped by an AES-256-GCM key that never leaves the
 * Android Keystore (DD-007). The wrapped key lives in `noBackupFilesDir`, so it
 * is not part of any system backup.
 *
 * File layout: [format version][IV length][IV][ciphertext + GCM tag].
 */
class KeyStoreChannel(private val context: Context) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val name = call.argument<String>("name")
        if (name == null || !NAME_PATTERN.matches(name)) {
            result.error("invalid", "Invalid key name", null)
            return
        }
        try {
            when (call.method) {
                "read" -> result.success(read(name))
                "create" -> {
                    val key = call.argument<ByteArray>("key")
                    if (key == null || key.size != KEY_LENGTH) {
                        result.error("invalid", "Key must be $KEY_LENGTH bytes", null)
                        return
                    }
                    create(name, key)
                    result.success(null)
                }
                "deleteForTesting" -> {
                    val debuggable =
                        (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
                    if (!debuggable) {
                        result.notImplemented()
                        return
                    }
                    if (name == MASTER_KEY_NAME) {
                        result.error("invalid", "The master key is never deleted", null)
                        return
                    }
                    deleteForTesting(name)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (e: KeyExistsException) {
            result.error("exists", "A key named $name already exists", null)
        } catch (e: GeneralSecurityException) {
            result.error("unavailable", e.javaClass.simpleName, null)
        } catch (e: IOException) {
            result.error("unavailable", e.javaClass.simpleName, null)
        } catch (e: ErrnoException) {
            result.error("unavailable", e.javaClass.simpleName, null)
        }
    }

    private fun fileFor(name: String) = File(context.noBackupFilesDir, "$name.key")

    private fun aliasFor(name: String) = "eu.marandos.offload.$name"

    private fun read(name: String): ByteArray? {
        val file = fileFor(name)
        if (!file.exists()) return null
        val bytes = file.readBytes()
        if (bytes.size < 2 || bytes[0] != FORMAT_VERSION) {
            throw GeneralSecurityException("Unknown key file format")
        }
        val ivLength = bytes[1].toInt()
        if (bytes.size < 2 + ivLength) throw GeneralSecurityException("Truncated key file")
        // A stored key without its wrapping key is unreadable, never "absent".
        val wrappingKey = wrappingKey(name, create = false)
            ?: throw GeneralSecurityException("Wrapping key is missing")
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(
            Cipher.DECRYPT_MODE,
            wrappingKey,
            GCMParameterSpec(TAG_BITS, bytes, 2, ivLength),
        )
        cipher.updateAAD(name.toByteArray(Charsets.UTF_8))
        return cipher.doFinal(bytes, 2 + ivLength, bytes.size - 2 - ivLength)
    }

    private fun create(name: String, key: ByteArray) {
        val file = fileFor(name)
        if (file.exists()) throw KeyExistsException()
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, wrappingKey(name, create = true))
        cipher.updateAAD(name.toByteArray(Charsets.UTF_8))
        val wrapped = cipher.doFinal(key)
        val iv = cipher.iv
        val directory = file.parentFile!!
        // An exclusive lock (also across processes) around check, write and move: an existing
        // key is never replaced, not even by a second process creating one at the same time.
        // Android forbids hard links in app storage, so "link, fail if it exists" is no option.
        FileChannel.open(
            File(directory, "$name.lock").toPath(),
            StandardOpenOption.CREATE,
            StandardOpenOption.WRITE,
        ).use { lockChannel ->
            lockChannel.lock().use {
                if (file.exists()) throw KeyExistsException()
                // Write to a temporary file and sync it, so a crash never leaves a half key.
                val temp = File(directory, "${file.name}.tmp")
                FileOutputStream(temp).use { out ->
                    out.write(byteArrayOf(FORMAT_VERSION, iv.size.toByte()))
                    out.write(iv)
                    out.write(wrapped)
                    out.fd.sync()
                }
                Files.move(temp.toPath(), file.toPath(), StandardCopyOption.ATOMIC_MOVE)
                syncDirectory(directory)
            }
        }
    }

    /** Makes a new directory entry durable before any data is encrypted with the new key. */
    private fun syncDirectory(directory: File) {
        val fd = Os.open(directory.path, OsConstants.O_RDONLY, 0)
        try {
            Os.fsync(fd)
        } finally {
            Os.close(fd)
        }
    }

    private fun deleteForTesting(name: String) {
        fileFor(name).delete()
        File(context.noBackupFilesDir, "$name.lock").delete()
        keyStore().deleteEntry(aliasFor(name))
    }

    private fun wrappingKey(name: String, create: Boolean): SecretKey? {
        val existing = keyStore().getKey(aliasFor(name), null) as SecretKey?
        if (existing != null || !create) return existing
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEY_STORE)
        generator.init(
            KeyGenParameterSpec.Builder(
                aliasFor(name),
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build(),
        )
        return generator.generateKey()
    }

    private fun keyStore() = KeyStore.getInstance(ANDROID_KEY_STORE).apply { load(null) }

    private class KeyExistsException : Exception()

    companion object {
        const val CHANNEL = "eu.marandos.offload/key_store"
        private const val MASTER_KEY_NAME = "master_key"
        private const val ANDROID_KEY_STORE = "AndroidKeyStore"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val TAG_BITS = 128
        private const val KEY_LENGTH = 32
        private const val FORMAT_VERSION: Byte = 1
        private val NAME_PATTERN = Regex("[a-z_]{1,32}")
    }
}
