package eu.marandos.offload.capture

import android.content.Context
import android.content.pm.ApplicationInfo
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Lets the app take captures from the [CaptureQueue] (`AndroidCaptureChannel`
 * in Dart): `drain` returns them without deleting, `acknowledge` removes them
 * once the app has stored them, `setAside` moves the ones the app refuses to
 * quarantine. File work runs off the main thread.
 */
class CaptureQueueChannel(private val context: Context) : MethodChannel.MethodCallHandler {
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    /** Lets the worker thread end with this activity; a running task finishes. */
    fun close() = worker.shutdown()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "drain" -> run(result) {
                val drained = CaptureQueues.forContext(context).drain()
                mapOf(
                    "captures" to drained.entries.map {
                        mapOf("id" to it.id, "text" to it.text, "source" to it.source)
                    },
                    "newlyQuarantined" to drained.newlyQuarantined,
                )
            }
            "acknowledge" -> {
                val ids = call.argument<List<String>>("ids")
                if (ids == null) {
                    result.error("invalid", "Missing ids", null)
                    return
                }
                run(result) { CaptureQueues.forContext(context).acknowledge(ids) }
            }
            "setAside" -> {
                val ids = call.argument<List<String>>("ids")
                if (ids == null) {
                    result.error("invalid", "Missing ids", null)
                    return
                }
                run(result) { CaptureQueues.forContext(context).setAside(ids) }
            }
            // Integration tests only: the capture window cannot be driven from Dart.
            "enqueueForTesting" -> {
                val debuggable =
                    (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
                val text = call.argument<String>("text")
                val source = call.argument<String>("source")
                if (!debuggable || text == null || source == null) {
                    result.notImplemented()
                    return
                }
                run(result) { CaptureQueues.forContext(context).enqueue(text, source) }
            }
            else -> result.notImplemented()
        }
    }

    private fun run(result: MethodChannel.Result, work: () -> Any?) {
        worker.execute {
            try {
                val value = work()
                main.post { result.success(if (value == Unit) null else value) }
            } catch (e: Throwable) {
                // Always answer, or the app would wait for this call forever.
                main.post { result.error("unavailable", e.javaClass.simpleName, null) }
            }
        }
    }

    companion object {
        const val CHANNEL = "eu.marandos.offload/capture_queue"
    }
}
