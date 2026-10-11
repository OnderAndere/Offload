package eu.marandos.offload

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Where a backup or an export goes and where a backup comes from
 * (`AndroidBackupFilePicker`, T7.2, T7.3, DD-007): the system document
 * picker, so no storage permission is needed. Picking returns a document
 * address; copying moves the bytes of a finished file between it and the
 * app's own cache. Nothing here reads or decrypts it.
 */
class BackupFileChannel(private val activity: Activity) : MethodChannel.MethodCallHandler {

    private var pending: MethodChannel.Result? = null
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    /** Lets the worker thread end with this activity; a running task finishes. */
    fun close() = io.shutdown()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickSaveTarget" -> pick(result, REQUEST_SAVE) {
                Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    // A backup, or an export (T7.3) with its own type.
                    type = call.argument<String>("mimeType") ?: MIME_TYPE
                    putExtra(Intent.EXTRA_TITLE, call.argument<String>("suggestedName"))
                }
            }
            "pickOpenFile" -> pick(result, REQUEST_OPEN) {
                Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    // A backup has no registered type: every file can be chosen.
                    type = "*/*"
                }
            }
            "copyToUri" -> offMain(result) {
                val source = File(call.argument<String>("source")!!)
                val target = Uri.parse(call.argument<String>("uri")!!)
                activity.contentResolver.openOutputStream(target, "wt").use { out ->
                    source.inputStream().use { it.copyTo(out!!) }
                }
                null
            }
            // The size of a picked save target, or null when unknown: an empty
            // one was just made by the picker, a larger one is a file the user
            // chose to overwrite (T7.2 follow-up, review).
            "documentSize" -> offMain(result) {
                val target = Uri.parse(call.argument<String>("uri")!!)
                activity.contentResolver
                    .query(target, arrayOf(OpenableColumns.SIZE), null, null, null)
                    ?.use { cursor ->
                        val column = cursor.getColumnIndex(OpenableColumns.SIZE)
                        if (cursor.moveToFirst() && column >= 0 && !cursor.isNull(column)) {
                            cursor.getLong(column)
                        } else {
                            null
                        }
                    }
            }
            // A document the picker made for a save that then failed (T7.2).
            "deleteDocument" -> offMain(result) {
                val target = Uri.parse(call.argument<String>("uri")!!)
                DocumentsContract.deleteDocument(activity.contentResolver, target)
                null
            }
            "copyFromUri" -> offMain(result) {
                val source = Uri.parse(call.argument<String>("uri")!!)
                val target = File(call.argument<String>("target")!!)
                activity.contentResolver.openInputStream(source).use { input ->
                    target.outputStream().use { input!!.copyTo(it) }
                }
                null
            }
            else -> result.notImplemented()
        }
    }

    private fun pick(result: MethodChannel.Result, request: Int, intent: () -> Intent) {
        if (pending != null) {
            result.error("busy", "A file window is already open", null)
            return
        }
        pending = result
        try {
            activity.startActivityForResult(intent(), request)
        } catch (e: ActivityNotFoundException) {
            pending = null
            result.error("unavailable", e.message, null)
        }
    }

    /** The answer of the picker: the document address, or null when cancelled. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_SAVE && requestCode != REQUEST_OPEN) return false
        val result = pending ?: return true
        pending = null
        val uri = data?.data
        result.success(if (resultCode == Activity.RESULT_OK && uri != null) uri.toString() else null)
        return true
    }

    /** Runs [work] off the main thread (file and provider I/O), then answers on it. */
    private fun offMain(result: MethodChannel.Result, work: () -> Any?) {
        io.execute {
            try {
                val answer = work()
                main.post { result.success(answer) }
            } catch (e: Exception) {
                main.post { result.error("unavailable", e.javaClass.simpleName, null) }
            }
        }
    }

    companion object {
        const val CHANNEL = "eu.marandos.offload/backup_file"
        private const val MIME_TYPE = "application/octet-stream"
        private const val REQUEST_SAVE = 7201
        private const val REQUEST_OPEN = 7202

        /** The copies `AndroidBackupFilePicker` makes in the cache. */
        private val COPY = Regex("""^(save-out|backup-out|backup-in)\..+$""")

        /** Long enough that no save or open still runs on such a copy. */
        const val LEFTOVER_MILLIS = 60L * 60 * 1000

        /**
         * Removes copies in [cacheDir] left behind when the process stopped
         * between writing and removing them, older than [LEFTOVER_MILLIS] at
         * [now]: an export is unencrypted (CLAUDE.md rule 2). Run at app
         * start, off the main thread.
         */
        fun removeLeftoverCopies(cacheDir: File, now: Long = System.currentTimeMillis()) {
            cacheDir.listFiles()
                ?.filter { it.isFile && COPY.matches(it.name) && now - it.lastModified() > LEFTOVER_MILLIS }
                ?.forEach { it.delete() }
        }
    }
}
