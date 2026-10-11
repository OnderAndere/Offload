package eu.marandos.offload

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

/**
 * AES-256-GCM with a 16-byte tag from Android's own `javax.crypto`
 * (`AndroidAeadCipher`, DD-006, REQ-023): no crypto library ships with the
 * app. A call carries a batch of messages, so the attachments' segments
 * cross the channel a batch at a time. Off the main thread.
 */
class AeadChannel : MethodChannel.MethodCallHandler {

    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val mode = when (call.method) {
            "seal" -> Cipher.ENCRYPT_MODE
            "open" -> Cipher.DECRYPT_MODE
            else -> {
                result.notImplemented()
                return
            }
        }
        val key = call.argument<ByteArray>("key")
        val nonces = call.argument<List<ByteArray>>("nonces")
        val aads = call.argument<List<ByteArray>>("aads")
        val data = call.argument<List<ByteArray>>("data")
        if (key == null || key.size != KEY_LENGTH || nonces == null || aads == null ||
            data == null || nonces.size != data.size || aads.size != data.size
        ) {
            result.error("invalid", "Missing or malformed arguments", null)
            return
        }
        worker.execute {
            try {
                val secret = SecretKeySpec(key, "AES")
                val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                val out = data.indices.map { i ->
                    // GCM needs a fresh init per message (its own nonce).
                    cipher.init(mode, secret, GCMParameterSpec(TAG_BITS, nonces[i]))
                    if (aads[i].isNotEmpty()) cipher.updateAAD(aads[i])
                    cipher.doFinal(data[i])
                }
                main.post { result.success(out) }
            } catch (e: AEADBadTagException) {
                main.post { result.error("auth", "Tag mismatch", null) }
            } catch (e: Exception) {
                main.post { result.error("unavailable", e.javaClass.simpleName, null) }
            } finally {
                key.fill(0)
            }
        }
    }

    companion object {
        const val CHANNEL = "eu.marandos.offload/aead"
        private const val KEY_LENGTH = 32
        private const val TAG_BITS = 128
    }
}
