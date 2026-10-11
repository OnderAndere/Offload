package eu.marandos.offload

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Opens a phone number in the dialler or an address in the mail app
 * (`AndroidContactLauncher`, REQ-038, DD-018 point 9). `ACTION_DIAL` only
 * fills in the number and `ACTION_SENDTO` only starts a message: the user
 * calls or sends, so neither needs a permission (no `CALL_PHONE`).
 */
class ContactLauncherChannel(private val activity: Activity) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val action = when (call.method) {
            "dial" -> Intent.ACTION_DIAL
            "mail" -> Intent.ACTION_SENDTO
            else -> {
                result.notImplemented()
                return
            }
        }
        val uri = call.argument<String>("uri")
        if (uri == null) {
            result.error("invalid", "Missing uri", null)
            return
        }
        try {
            activity.startActivity(Intent(action, Uri.parse(uri)))
            result.success(null)
        } catch (e: ActivityNotFoundException) {
            result.error("unavailable", e.message, null)
        }
    }

    companion object {
        const val CHANNEL = "eu.marandos.offload/contact"
    }
}
