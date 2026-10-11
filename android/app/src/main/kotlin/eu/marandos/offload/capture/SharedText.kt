package eu.marandos.offload.capture

/**
 * Text shared to Offload from another app (REQ-002, DD-010): a mail subject
 * and body, or a page title and its link.
 */
object SharedText {
    /**
     * The text to prefill, or null when nothing capturable was shared.
     *
     * The subject goes on the first line and the text below it; when the
     * text already contains the subject, only the text (PO decision
     * 27-09-2026). Both are kept exactly as received, line breaks included
     * (DD-004: the raw text is the source of truth).
     */
    fun compose(subject: CharSequence?, text: CharSequence?): String? {
        val s = subject?.toString()?.takeIf(CaptureQueue::hasCapturableText)
        val t = text?.toString()?.takeIf(CaptureQueue::hasCapturableText)
        return when {
            s == null -> t
            t == null -> s
            t.contains(s) -> t
            else -> s + "\n" + t
        }
    }

    /**
     * [shared] added to what is already in the window: never replaces text
     * that was typed but not saved yet.
     */
    fun appendTo(current: String, shared: String): String =
        if (CaptureQueue.hasCapturableText(current)) current + "\n" + shared else shared
}
