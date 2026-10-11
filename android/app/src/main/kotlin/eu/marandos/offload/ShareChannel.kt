package eu.marandos.offload

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ComponentName
import android.content.Intent
import android.os.Handler
import android.os.Looper
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Sends text and files out through the Android share menu
 * (`AndroidShareChannel`, DD-014, REQ-043, REQ-014): an own thin
 * `ACTION_SEND`, no plugin and no permission. The user picks the app;
 * Android does not tell whether it was really sent.
 *
 * A file goes out from [SHARE_DIRECTORY] in the app's cache, the only folder
 * the `FileProvider` serves (`res/xml/share_paths.xml`). It holds one shared
 * file at a time; a file left behind is removed after [KEEP_MILLIS], because
 * the receiving app may read it only later (a mail draft, SPEC Q12).
 */
class ShareChannel(private val activity: Activity) : MethodChannel.MethodCallHandler {

    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    /** Lets the worker thread end with this activity; a running task finishes. */
    fun close() = io.shutdown()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "shareText" -> shareText(call, result)
            "prepareShareDirectory" -> prepareShareDirectory(result)
            "shareFile" -> shareFile(call, result)
            else -> result.notImplemented()
        }
    }

    private fun shareText(call: MethodCall, result: MethodChannel.Result) {
        val text = call.argument<String>("text")
        if (text == null) {
            result.error("invalid", "Missing text", null)
            return
        }
        val send = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, text)
            putSubject(call)
        }
        startChooser(send, result)
    }

    /**
     * Empties the share folder, so a new share replaces the previous one; off
     * the main thread, as the previous file can be a large backup.
     */
    private fun prepareShareDirectory(result: MethodChannel.Result) {
        val directory = shareDirectory(activity.cacheDir)
        io.execute {
            directory.listFiles()?.forEach { it.deleteRecursively() }
            if (!directory.isDirectory && !directory.mkdirs()) {
                main.post { result.error("unavailable", "Cannot create the share folder", null) }
            } else {
                main.post { result.success(directory.absolutePath) }
            }
        }
    }

    private fun shareFile(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        val mimeType = call.argument<String>("mimeType")
        if (path == null || mimeType == null) {
            result.error("invalid", "Missing path or type", null)
            return
        }
        // Throws for a file outside the share folder: nothing else goes out.
        val uri = try {
            FileProvider.getUriForFile(activity, authority(activity), File(path))
        } catch (e: IllegalArgumentException) {
            result.error("invalid", e.message, null)
            return
        }
        val send = Intent(Intent.ACTION_SEND).apply {
            type = mimeType
            putExtra(Intent.EXTRA_STREAM, uri)
            // ClipData carries the read grant to the app the user picks.
            clipData = ClipData.newRawUri(null, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            putSubject(call)
        }
        startChooser(send, result)
    }

    private fun Intent.putSubject(call: MethodCall) {
        call.argument<String>("subject")
            ?.takeIf { it.isNotEmpty() }
            ?.let { putExtra(Intent.EXTRA_SUBJECT, it) }
    }

    private fun startChooser(send: Intent, result: MethodChannel.Result) {
        // The chooser takes over the ClipData and the grant of [send].
        val chooser = Intent.createChooser(send, null).apply {
            // Not back into Offload's own share target.
            putExtra(
                Intent.EXTRA_EXCLUDE_COMPONENTS,
                arrayOf(ComponentName(activity, SHARE_TARGET)),
            )
        }
        try {
            activity.startActivity(chooser)
            result.success(null)
        } catch (e: ActivityNotFoundException) {
            result.error("unavailable", e.message, null)
        }
    }

    companion object {
        const val CHANNEL = "eu.marandos.offload/share"

        /** The `activity-alias` that receives shared text (T2.1). */
        private const val SHARE_TARGET = "eu.marandos.offload.capture.ShareCaptureActivity"

        /** The folder in the cache served by the `FileProvider`. */
        private const val SHARE_DIRECTORY = "share"

        /** How long a shared file stays when no new share replaces it. */
        const val KEEP_MILLIS = 24L * 60 * 60 * 1000

        /** The `FileProvider` authority in the manifest. */
        private fun authority(activity: Activity) = "${activity.packageName}.share"

        private fun shareDirectory(cacheDir: File) = File(cacheDir, SHARE_DIRECTORY)

        /**
         * Removes shared files older than [KEEP_MILLIS] at [now] from the share
         * folder in [cacheDir]. Run at app start, off the main thread; never
         * from the capture window (CLAUDE.md rule 7).
         */
        fun removeOldShares(cacheDir: File, now: Long = System.currentTimeMillis()) {
            shareDirectory(cacheDir).listFiles()
                ?.filter { now - it.lastModified() > KEEP_MILLIS }
                ?.forEach { it.deleteRecursively() }
        }
    }
}
