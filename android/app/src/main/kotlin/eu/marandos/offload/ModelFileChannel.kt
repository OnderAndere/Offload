package eu.marandos.offload

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import android.system.ErrnoException
import android.system.OsConstants
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.security.MessageDigest
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong

/**
 * The files of a model (`AndroidModelFileSource`, T6a.3, DD-002): the
 * system document picker with several files at once, no storage permission,
 * so a NAS or cloud app that offers documents works too. A copy streams the
 * document straight into the app's own storage and computes its SHA-256 on
 * the way: no copy in the cache first (1.5 GB), and the file is read once.
 */
class ModelFileChannel(private val activity: Activity) : MethodChannel.MethodCallHandler {

    private var pending: MethodChannel.Result? = null
    private val main = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickFiles" -> pick(result)
            "copy" -> {
                val job = call.argument<Int>("job")!!
                val source = Uri.parse(call.argument<String>("uri")!!)
                val target = File(call.argument<String>("target")!!)
                val progress = AtomicLong(0)
                val cancel = AtomicBoolean(false)
                jobs[job] = Job(progress, cancel)
                copies.execute {
                    try {
                        val hash = copy(source, target, progress, cancel)
                        main.post { result.success(hash) }
                    } catch (e: CancelledException) {
                        main.post { result.error("cancelled", null, null) }
                    } catch (e: IOException) {
                        val code = if (isNoSpace(e)) "noSpace" else "unavailable"
                        main.post { result.error(code, e.javaClass.simpleName, null) }
                    } catch (e: Exception) {
                        main.post { result.error("unavailable", e.javaClass.simpleName, null) }
                    } finally {
                        jobs.remove(job)
                    }
                }
            }
            // The bytes a running copy has written; null when it has ended.
            "progress" -> result.success(jobs[call.argument<Int>("job")!!]?.progress?.get())
            "cancel" -> {
                jobs[call.argument<Int>("job")!!]?.cancel?.set(true)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun pick(result: MethodChannel.Result) {
        if (pending != null) {
            result.error("busy", "A file window is already open", null)
            return
        }
        pending = result
        try {
            activity.startActivityForResult(
                Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    // GGUF has no registered type: every file can be chosen.
                    type = "*/*"
                    putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                },
                REQUEST_PICK,
            )
        } catch (e: ActivityNotFoundException) {
            pending = null
            result.error("unavailable", e.message, null)
        }
    }

    /** The picked documents with name and size; empty when cancelled. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_PICK) return false
        val result = pending ?: return true
        pending = null
        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(emptyList<Map<String, Any?>>())
            return true
        }
        val uris = mutableListOf<Uri>()
        val clip = data.clipData
        if (clip != null) {
            for (i in 0 until clip.itemCount) uris += clip.getItemAt(i).uri
        } else {
            data.data?.let { uris += it }
        }
        // Names and sizes come from the provider (a NAS may be slow): off main.
        copies.execute {
            try {
                val files = uris.map { describe(it) }
                main.post { result.success(files) }
            } catch (e: Exception) {
                main.post { result.error("unavailable", e.javaClass.simpleName, null) }
            }
        }
        return true
    }

    private fun describe(uri: Uri): Map<String, Any?> {
        var name: String? = null
        var size: Long? = null
        activity.contentResolver
            .query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val n = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    val s = cursor.getColumnIndex(OpenableColumns.SIZE)
                    if (n >= 0 && !cursor.isNull(n)) name = cursor.getString(n)
                    if (s >= 0 && !cursor.isNull(s)) size = cursor.getLong(s)
                }
            }
        return mapOf("uri" to uri.toString(), "name" to (name ?: uri.lastPathSegment ?: ""), "size" to size)
    }

    private fun copy(source: Uri, target: File, progress: AtomicLong, cancel: AtomicBoolean): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val input = activity.contentResolver.openInputStream(source)
            ?: throw IOException("no stream")
        input.use { stream ->
            target.outputStream().use { out ->
                val buffer = ByteArray(BLOCK)
                while (true) {
                    if (cancel.get()) throw CancelledException()
                    val n = stream.read(buffer)
                    if (n < 0) break
                    digest.update(buffer, 0, n)
                    out.write(buffer, 0, n)
                    progress.addAndGet(n.toLong())
                }
                out.fd.sync()
            }
        }
        return digest.digest().joinToString("") { "%02x".format(it) }
    }

    private class Job(val progress: AtomicLong, val cancel: AtomicBoolean)

    private class CancelledException : Exception()

    companion object {
        const val CHANNEL = "eu.marandos.offload/model_files"
        private const val REQUEST_PICK = 7301
        private const val BLOCK = 1 shl 20

        // Process-wide, so a copy and its progress outlive a recreated
        // activity; one copy at a time.
        private val copies = Executors.newSingleThreadExecutor()
        private val jobs = ConcurrentHashMap<Int, Job>()

        /** Whether [e] means the drive is full. */
        fun isNoSpace(e: IOException): Boolean {
            var cause: Throwable? = e
            while (cause != null) {
                if (cause is ErrnoException && cause.errno == OsConstants.ENOSPC) return true
                cause = cause.cause
            }
            return e.message?.contains("ENOSPC") == true
        }
    }
}
