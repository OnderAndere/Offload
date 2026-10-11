package eu.marandos.offload.capture

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.text.Editable
import android.text.InputType
import android.text.TextWatcher
import android.view.KeyEvent
import android.view.View
import android.view.WindowInsets
import android.view.inputmethod.EditorInfo
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import eu.marandos.offload.R

/**
 * Quick capture from the home-screen widget (REQ-001, DD-010, spike S3
 * variant A): a small native window over the home screen, without starting
 * Flutter. The text goes into the encrypted [CaptureQueue]; the app stores it
 * the next time it starts or comes back. The window closes only once the
 * capture is safely written; if that fails, the text stays with a message.
 *
 * Texts come from Android resources generated from the ARB files and follow
 * the system language (PO decision 27-09-2026).
 *
 * The same window receives text and links from the Android share sheet
 * (REQ-002, T2.1), through the exported `ShareCaptureActivity` alias: it
 * opens with the shared text filled in, to add `@who` or a date before
 * saving, and records the source `share` (PO decision 27-09-2026).
 */
class QuickCaptureActivity : Activity() {
    private lateinit var input: EditText
    private lateinit var save: Button
    private lateinit var error: TextView

    // The keyboard can deliver both "done" and an Enter key event for one
    // press, and the button can be tapped twice: capture only once.
    private var submitted = false
    private var source = SOURCE_WIDGET

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_quick_capture)
        input = findViewById(R.id.capture_text)
        save = findViewById(R.id.capture_save)
        error = findViewById(R.id.capture_error)

        // The field shows line breaks, for shared text that has them, but the
        // keyboard sees a single line and shows its action key, which saves:
        // typing adds no line breaks (PO decision 25-09-2026).
        input.setRawInputType(InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_CAP_SENTENCES)
        input.setHorizontallyScrolling(false)
        input.maxLines = MAX_VISIBLE_LINES
        input.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                save.isEnabled = s != null && CaptureQueue.hasCapturableText(s.toString())
            }
        })
        save.isEnabled = false
        if (savedInstanceState == null) {
            receiveShared(intent)
        } else {
            // Recreated, for example after a rotation: the field restores its
            // own text; the source must not fall back to the first intent.
            source = savedInstanceState.getString(KEY_SOURCE) ?: SOURCE_WIDGET
            if (source == SOURCE_SHARE) input.maxLines = MAX_VISIBLE_LINES_SHARED
        }

        // The soft keyboard's action key sends IME_ACTION_DONE.
        input.setOnEditorActionListener { _, actionId, _ ->
            if (actionId == EditorInfo.IME_ACTION_DONE) {
                submit()
                true
            } else {
                false
            }
        }
        // A hardware Enter saves, also with Shift or Ctrl: the field is
        // multi-line to show shared line breaks, and would otherwise insert
        // one (review T2.1). Down saves; up is swallowed too.
        input.setOnKeyListener { _, keyCode, event ->
            if (keyCode == KeyEvent.KEYCODE_ENTER || keyCode == KeyEvent.KEYCODE_NUMPAD_ENTER) {
                if (event.action == KeyEvent.ACTION_DOWN) submit()
                true
            } else {
                false
            }
        }
        save.setOnClickListener { submit() }

        input.requestFocus()
        input.post { window.insetsController?.show(WindowInsets.Type.ime()) }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putString(KEY_SOURCE, source)
    }

    /** Shared again while the window is still open: nothing typed is lost. */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        receiveShared(intent)
    }

    private fun receiveShared(intent: Intent?) {
        if (intent?.action != Intent.ACTION_SEND) return
        // The extras come from another app: a malformed one is ignored, never
        // allowed to close the window over unsaved text (review T2.1).
        val shared = try {
            SharedText.compose(
                intent.getCharSequenceExtra(Intent.EXTRA_SUBJECT),
                intent.getCharSequenceExtra(Intent.EXTRA_TEXT),
            )
        } catch (e: RuntimeException) {
            null
        } ?: return
        source = SOURCE_SHARE
        // Shared text is often a few lines, such as a short mail: show more.
        input.maxLines = MAX_VISIBLE_LINES_SHARED
        val text = SharedText.appendTo(input.text.toString(), shared)
        input.setText(text)
        input.setSelection(text.length)
    }

    private fun submit() {
        if (submitted) return
        // Stored exactly as typed (DD-004); only empty text is refused.
        val text = input.text.toString()
        if (!CaptureQueue.hasCapturableText(text)) return
        submitted = true
        try {
            CaptureQueues.forContext(this).enqueue(text, source)
        } catch (e: Exception) {
            submitted = false
            error.visibility = View.VISIBLE
            error.announceForAccessibility(error.text)
            input.requestFocus()
            return
        }
        finish()
    }

    private companion object {
        const val SOURCE_WIDGET = "widget"
        const val SOURCE_SHARE = "share"
        const val KEY_SOURCE = "source"
        const val MAX_VISIBLE_LINES = 6
        const val MAX_VISIBLE_LINES_SHARED = 10
    }
}
