package eu.marandos.offload

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

/** Removing copies a stopped save or export left in the cache (rule 2). */
class BackupFileChannelTest {
    @get:Rule
    val folder = TemporaryFolder()

    private val now = 1_800_000_000_000L

    private fun file(name: String, ageMillis: Long) = File(folder.root, name).apply {
        writeText("x")
        setLastModified(now - ageMillis)
    }

    @Test
    fun removesOldCopiesOnly() {
        val old = BackupFileChannel.LEFTOVER_MILLIS + 1
        val export = file("save-out.md", old)
        val backupOut = file("backup-out.offload", old)
        val backupIn = file("backup-in.offload", old)
        val running = file("save-out.json", 60_000)
        val other = file("other.md", old)

        BackupFileChannel.removeLeftoverCopies(folder.root, now)

        assertFalse(export.exists())
        assertFalse(backupOut.exists())
        assertFalse(backupIn.exists())
        assertTrue(running.exists())
        assertTrue(other.exists())
    }
}
