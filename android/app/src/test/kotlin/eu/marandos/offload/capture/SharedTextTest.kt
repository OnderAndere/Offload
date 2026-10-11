package eu.marandos.offload.capture

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** Text shared from another app (REQ-002; PO decisions 27-09-2026). */
class SharedTextTest {
    @Test
    fun `subject on the first line, text below`() {
        assertEquals(
            "Offerte renovatie\nKun je voor vrijdag reageren?",
            SharedText.compose("Offerte renovatie", "Kun je voor vrijdag reageren?"),
        )
    }

    @Test
    fun `a page title and its link`() {
        assertEquals(
            "Renovatie basics\nhttps://example.org/renovatie",
            SharedText.compose("Renovatie basics", "https://example.org/renovatie"),
        )
    }

    @Test
    fun `only the text when it already contains the subject`() {
        assertEquals(
            "Renovatie basics https://example.org/renovatie",
            SharedText.compose("Renovatie basics", "Renovatie basics https://example.org/renovatie"),
        )
    }

    @Test
    fun `only one of the two`() {
        assertEquals("https://example.org", SharedText.compose(null, "https://example.org"))
        assertEquals("https://example.org", SharedText.compose("  ", "https://example.org"))
        assertEquals("Alleen onderwerp", SharedText.compose("Alleen onderwerp", null))
    }

    @Test
    fun `line breaks and spacing are kept exactly`() {
        val body = "  Regel een\n\nRegel drie  "

        assertEquals(body, SharedText.compose(null, body))
    }

    @Test
    fun `nothing capturable`() {
        assertNull(SharedText.compose(null, null))
        assertNull(SharedText.compose(" ", "\n"))
    }

    @Test
    fun `sharing into a window with unsaved text adds a line`() {
        assertEquals("Bel Jan\nhttps://example.org", SharedText.appendTo("Bel Jan", "https://example.org"))
        assertEquals("https://example.org", SharedText.appendTo("", "https://example.org"))
    }
}
