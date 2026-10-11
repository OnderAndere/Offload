package eu.marandos.offload

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.OpenableColumns
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.InputStream
import java.util.concurrent.Executors

/**
 * Where a photo for an item comes from (`AndroidPhotoSource`, T5.3,
 * REQ-024): the device's camera app, or Android's photo picker. Neither needs
 * a permission: the app declares no `CAMERA`, so the camera app takes the
 * photo, and the picker grants access to the one photo chosen.
 *
 * The answer is the photo's bytes, read into memory; Offload compresses and
 * encrypts them. The camera app can only hand its photo over as a file: it
 * writes it in `cache/camera/`, served by the FileProvider, and the file is
 * removed right after reading, also when cancelled, and as a leftover at
 * start (CLAUDE.md rule 2, exception of PO 10-10-2026).
 */
class PhotoChannel(private val activity: Activity) : MethodChannel.MethodCallHandler {

    private var pending: Pending? = null
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    /** Lets the worker thread end with this activity; a running task finishes. */
    fun close() = io.shutdown()

    /** The open request: its answer, the camera's file, the largest photo taken. */
    private class Pending(val result: MethodChannel.Result, val cameraFile: File?, val maxBytes: Long)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val maxBytes = call.argument<Number>("maxBytes")?.toLong() ?: Long.MAX_VALUE
        when (call.method) {
            "takePhoto" -> {
                if (busy(result)) return
                var file: File? = null
                val uri = try {
                    file = newCameraFile(activity.cacheDir)
                    FileProvider.getUriForFile(activity, "${activity.packageName}.share", file)
                } catch (e: Exception) {
                    file?.delete()
                    result.error("unavailable", e.javaClass.simpleName, null)
                    return
                }
                start(result, REQUEST_TAKE, file, maxBytes) {
                    Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
                        putExtra(MediaStore.EXTRA_OUTPUT, uri)
                        // The grant reaches the camera app through the clip data.
                        clipData = ClipData.newRawUri("", uri)
                        addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                }
            }
            "pickPhoto" -> {
                if (busy(result)) return
                start(result, REQUEST_PICK, null, maxBytes) {
                    Intent(MediaStore.ACTION_PICK_IMAGES).apply { type = "image/*" }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun busy(result: MethodChannel.Result): Boolean {
        if (pending == null) return false
        result.error("busy", "A photo window is already open", null)
        return true
    }

    private fun start(
        result: MethodChannel.Result,
        request: Int,
        cameraFile: File?,
        maxBytes: Long,
        intent: () -> Intent,
    ) {
        pending = Pending(result, cameraFile, maxBytes)
        try {
            activity.startActivityForResult(intent(), request)
        } catch (e: ActivityNotFoundException) {
            pending = null
            cameraFile?.delete()
            result.error("unavailable", e.message, null)
        }
    }

    /** The photo taken or chosen, as bytes, or null when cancelled. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_TAKE && requestCode != REQUEST_PICK) return false
        val request = pending
        pending = null
        // No one waits (the activity was made again in between): the camera's
        // file still goes.
        if (request == null) {
            if (requestCode == REQUEST_TAKE) io.execute { removeCameraFiles(activity.cacheDir) }
            return true
        }
        val ok = resultCode == Activity.RESULT_OK
        io.execute {
            val answer: Any? = try {
                when {
                    request.cameraFile != null -> try {
                        if (ok) readCapped(request.cameraFile.inputStream(), request.cameraFile.length(), request.maxBytes) else null
                    } finally {
                        request.cameraFile.delete()
                    }
                    ok && data?.data != null -> {
                        val uri = data.data!!
                        activity.contentResolver.openInputStream(uri).use {
                            readCapped(it!!, sizeOf(uri), request.maxBytes)
                        }
                    }
                    else -> null
                }
            } catch (e: TooLarge) {
                main.post { request.result.error("tooLarge", null, null) }
                return@execute
            } catch (e: Exception) {
                main.post { request.result.error("unavailable", e.javaClass.simpleName, null) }
                return@execute
            }
            main.post { request.result.success(answer) }
        }
        return true
    }

    private fun sizeOf(uri: Uri): Long? = activity.contentResolver
        .query(uri, arrayOf(OpenableColumns.SIZE), null, null, null)
        ?.use { cursor ->
            val column = cursor.getColumnIndex(OpenableColumns.SIZE)
            if (cursor.moveToFirst() && column >= 0 && !cursor.isNull(column)) cursor.getLong(column) else null
        }

    private class TooLarge : Exception()

    /**
     * The bytes of [input], or [TooLarge] beyond [maxBytes]: by its [size]
     * when known, and while reading, as a size can be wrong. An empty camera
     * file (cancelled by a camera app that answered OK) counts as cancelled.
     */
    private fun readCapped(input: InputStream, size: Long?, maxBytes: Long): ByteArray? {
        if (size != null && size > maxBytes) throw TooLarge()
        val out = ByteArrayOutputStream(if (size != null && size in 1..maxBytes) size.toInt() else 64 * 1024)
        val buffer = ByteArray(64 * 1024)
        var total = 0L
        while (true) {
            val read = input.read(buffer)
            if (read < 0) break
            total += read
            if (total > maxBytes) throw TooLarge()
            out.write(buffer, 0, read)
        }
        return if (total == 0L) null else out.toByteArray()
    }

    companion object {
        const val CHANNEL = "eu.marandos.offload/photo"
        private const val REQUEST_TAKE = 5301
        private const val REQUEST_PICK = 5302

        /** The folder the camera app writes in; `res/xml/share_paths.xml` serves it. */
        private const val CAMERA_FOLDER = "camera"

        private fun newCameraFile(cacheDir: File): File {
            val folder = File(cacheDir, CAMERA_FOLDER)
            folder.mkdirs()
            return File.createTempFile("camera-", ".jpg", folder)
        }

        /**
         * Removes every photo the camera app left in [cacheDir], unencrypted
         * (CLAUDE.md rule 2): run at start, off the main thread. No request
         * outlives the activity, so none is still waiting for one of them.
         */
        fun removeCameraFiles(cacheDir: File) {
            File(cacheDir, CAMERA_FOLDER).listFiles()?.forEach { it.delete() }
        }
    }
}
