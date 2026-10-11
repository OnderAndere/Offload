package eu.marandos.offload.capture

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File
import java.security.SecureRandom
import javax.crypto.SecretKey
import javax.crypto.spec.SecretKeySpec

/**
 * The loss guarantees of the capture queue (AC REQ-001, spike S3 tests T2-T4),
 * with a software AES key instead of the Android Keystore.
 */
class CaptureQueueTest {
    @get:Rule
    val folder = TemporaryFolder()

    private lateinit var dir: File
    private val key: SecretKey = SecretKeySpec(ByteArray(32).also { SecureRandom().nextBytes(it) }, "AES")
    private var clock = 1_790_000_000_000L

    private fun queue(withKey: SecretKey = key) = CaptureQueue(
        dir = dir,
        key = { withKey },
        syncDirectory = {},
        newId = { UuidV7.next(clock++) },
    )

    private fun queued() = dir.listFiles { f -> f.name.endsWith(".cq") }!!.map { it.name }

    private fun quarantined() = File(dir, CaptureQueue.QUARANTINE_DIR).listFiles()?.size ?: 0

    @Before
    fun setUp() {
        dir = File(folder.root, "capture_queue")
    }

    @Test
    fun `a capture comes back exactly as typed, with its source`() {
        val text = "  bel Jan @Jan !vr\nover de markt  "
        val id = queue().enqueue(text, "widget")

        val drained = queue().drain()

        assertEquals(listOf(CaptureQueue.Entry(id, text, "widget")), drained.entries)
        assertEquals(0, drained.newlyQuarantined)
    }

    @Test
    fun `ids are version 7 UUIDs and captures come back oldest first`() {
        val first = queue().enqueue("first", "widget")
        val second = queue().enqueue("second", "widget")

        assertTrue(UuidV7.isValid(first))
        assertEquals(listOf(first, second), queue().drain().entries.map { it.id })
    }

    @Test
    fun `nothing is readable on disk`() {
        queue().enqueue("geheim plan", "widget")

        val bytes = dir.listFiles()!!.single().readBytes()
        assertFalse(String(bytes, Charsets.ISO_8859_1).contains("geheim"))
    }

    @Test
    fun `draining does not remove captures (T2 - app stops before storing)`() {
        val id = queue().enqueue("Call Jan", "widget")

        queue().drain()

        assertEquals(listOf(id), queue().drain().entries.map { it.id })
    }

    @Test
    fun `a capture delivered again keeps its id (T3 - app stops before acknowledging)`() {
        val id = queue().enqueue("Call Jan", "widget")
        val first = queue().drain().entries

        val second = queue().drain().entries

        assertEquals(first, second)
        assertEquals(id, second.single().id)
    }

    @Test
    fun `acknowledging removes only the stored captures`() {
        val stored = queue().enqueue("stored", "widget")
        val waiting = queue().enqueue("waiting", "widget")

        queue().acknowledge(listOf(stored))

        assertEquals(listOf(waiting), queue().drain().entries.map { it.id })
    }

    @Test
    fun `acknowledge ignores anything that is not an id`() {
        queue().enqueue("keep", "widget")
        val outside = File(folder.root, "outside.cq").apply { writeText("x") }

        queue().acknowledge(listOf("../outside", "not-an-id"))

        assertTrue(outside.exists())
        assertEquals(1, queue().drain().entries.size)
    }

    @Test
    fun `a half-written file is removed and never delivered (T4)`() {
        val id = queue().enqueue("ok", "widget")
        File(dir, "${UuidV7.next(clock++)}.tmp").writeBytes(byteArrayOf(1, 2, 3))

        val drained = queue().drain()

        assertEquals(listOf(id), drained.entries.map { it.id })
        assertTrue(dir.listFiles { f -> f.name.endsWith(".tmp") }!!.isEmpty())
    }

    @Test
    fun `a damaged file goes to quarantine, the rest is delivered (T4)`() {
        val good = queue().enqueue("good", "widget")
        val bad = queue().enqueue("bad", "widget")
        File(dir, "$bad.cq").apply { writeBytes(readBytes().also { it[it.size - 1] = (it[it.size - 1] + 1).toByte() }) }

        val drained = queue().drain()

        assertEquals(listOf(good), drained.entries.map { it.id })
        assertEquals(1, drained.newlyQuarantined)
        assertEquals(1, quarantined())
        assertEquals(0, queue().drain().newlyQuarantined)
    }

    @Test
    fun `a file renamed to another id cannot be read (T4)`() {
        val real = queue().enqueue("real", "widget")
        val other = UuidV7.next(clock++)
        File(dir, "$real.cq").renameTo(File(dir, "$other.cq"))

        val drained = queue().drain()

        assertTrue(drained.entries.isEmpty())
        assertEquals(1, drained.newlyQuarantined)
    }

    @Test
    fun `a file with a foreign name goes to quarantine`() {
        dir.mkdirs()
        File(dir, "notes.cq").writeText("x")

        assertEquals(1, queue().drain().newlyQuarantined)
    }

    @Test
    fun `a capture under another key goes to quarantine, never deleted`() {
        queue().enqueue("written with the old key", "widget")
        val otherKey = SecretKeySpec(ByteArray(32).also { SecureRandom().nextBytes(it) }, "AES")

        val drained = queue(otherKey).drain()

        assertTrue(drained.entries.isEmpty())
        assertEquals(1, quarantined())
    }

    @Test
    fun `an unavailable key moves nothing to quarantine`() {
        val id = queue().enqueue("Call Jan", "widget")
        val broken = CaptureQueue(
            dir = dir,
            key = { throw java.security.KeyStoreException("temporarily unavailable") },
            syncDirectory = {},
        )

        var failed = false
        try {
            broken.drain()
        } catch (e: java.security.KeyStoreException) {
            failed = true
        }

        assertTrue(failed)
        assertEquals(0, quarantined())
        assertEquals(listOf(id), queue().drain().entries.map { it.id })
    }

    @Test
    fun `a capture the app refuses is set aside, not deleted`() {
        val refused = queue().enqueue("refused", "widget")
        val kept = queue().enqueue("kept", "widget")

        val moved = queue().setAside(listOf(refused, "../not-an-id"))

        assertEquals(1, moved)
        assertEquals(1, quarantined())
        assertEquals(listOf(kept), queue().drain().entries.map { it.id })
    }

    @Test(expected = IllegalArgumentException::class)
    fun `empty text is refused`() {
        queue().enqueue(" \n ", "widget")
    }

    @Test
    fun `no text means the same as in the app (Dart trim)`() {
        for (blank in listOf("\uFEFF", "\u0085", "\u00A0\u3000", "\u2028")) {
            assertFalse(blank, CaptureQueue.hasCapturableText(blank))
        }
        // Not white space for Dart either: a real, if invisible, character.
        assertTrue(CaptureQueue.hasCapturableText("\u200B"))
        assertTrue(CaptureQueue.hasCapturableText("  x  "))
    }

    @Test(expected = IllegalArgumentException::class)
    fun `an invalid source is refused`() {
        queue().enqueue("text", "../widget")
    }

    @Test
    fun `an empty or missing queue drains to nothing`() {
        val drained = queue().drain()

        assertTrue(drained.entries.isEmpty())
        assertEquals(0, drained.newlyQuarantined)
    }
}
