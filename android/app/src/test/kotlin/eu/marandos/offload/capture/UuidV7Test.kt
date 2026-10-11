package eu.marandos.offload.capture

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Same scheme as the app's UuidV7Generator, so the app can read the capture time. */
class UuidV7Test {
    @Test
    fun `has the canonical version 7 format`() {
        assertTrue(UuidV7.isValid(UuidV7.next()))
    }

    @Test
    fun `encodes the time in the first 48 bits`() {
        val id = UuidV7.next(0x0192a1b2c3d4L)

        assertEquals("0192a1b2c3d4", id.replace("-", "").substring(0, 12))
    }

    @Test
    fun `later milliseconds sort after earlier ones`() {
        val ids = (0L until 200L).map { UuidV7.next(1_790_000_000_000L + it) }

        assertEquals(ids.sorted(), ids)
    }

    @Test
    fun `rejects other versions and forms`() {
        assertFalse(UuidV7.isValid("0192a1b2-c3d4-4000-8000-000000000000"))
        assertFalse(UuidV7.isValid("0192A1B2-C3D4-7000-8000-000000000000"))
        assertFalse(UuidV7.isValid("../0192a1b2-c3d4-7000-8000-000000000000"))
    }
}
