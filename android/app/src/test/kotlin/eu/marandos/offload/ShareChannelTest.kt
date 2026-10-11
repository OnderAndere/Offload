package eu.marandos.offload

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

/** Cleaning up shared files left in the share folder (DD-014, SPEC Q12). */
class ShareChannelTest {
    @get:Rule
    val folder = TemporaryFolder()

    private val now = 1_800_000_000_000L

    private fun shared(name: String, ageMillis: Long): File {
        val directory = File(folder.root, "share").apply { mkdirs() }
        return File(directory, name).apply {
            writeText("encrypted")
            setLastModified(now - ageMillis)
        }
    }

    @Test
    fun removesOnlyFilesOlderThanADay() {
        val old = shared("old.offload", ShareChannel.KEEP_MILLIS + 1)
        val fresh = shared("fresh.offload", ShareChannel.KEEP_MILLIS - 60_000)

        ShareChannel.removeOldShares(folder.root, now)

        assertFalse(old.exists())
        assertTrue(fresh.exists())
    }

    @Test
    fun leavesTheRestOfTheCacheAlone() {
        val other = File(folder.root, "backup-out.offload").apply {
            writeText("x")
            setLastModified(now - 2 * ShareChannel.KEEP_MILLIS)
        }

        ShareChannel.removeOldShares(folder.root, now)

        assertTrue(other.exists())
    }

    @Test
    fun withoutAShareFolderNothingHappens() {
        ShareChannel.removeOldShares(folder.root, now)

        assertFalse(File(folder.root, "share").exists())
    }
}
