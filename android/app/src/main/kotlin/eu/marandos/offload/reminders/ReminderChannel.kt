package eu.marandos.offload.reminders

import android.Manifest
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

/**
 * Deadline reminders on Android (`AndroidReminderScheduler`, T4.1, DD-005):
 * inexact alarms through [AlarmManager.setWindow] with a window of 10
 * minutes, the Android 12 minimum (SPEC Q38), no exact-alarm permission.
 * The app hands over the whole plan each time; this replaces what was
 * planned. The alarms and their texts live in the alarm service until they
 * go off or the device restarts; for a restart only the dates, times and
 * count lines are kept, encrypted ([ReminderPlans], T4.3).
 */
class ReminderChannel(private val activity: Activity) : MethodChannel.MethodCallHandler {

    private val context: Context get() = activity.applicationContext
    private var pendingRequest: MethodChannel.Result? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "replaceAll" -> replaceAll(call, result)
            "enabled" -> result.success(enabled())
            "request" -> request(result)
            "openSettings" -> openSettings(result)
            "takeOpened" -> result.success(takeOpened(activity.intent))
            else -> result.notImplemented()
        }
    }

    private fun enabled(): Boolean =
        context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED &&
            context.getSystemService(NotificationManager::class.java)
                .areNotificationsEnabled()

    private fun replaceAll(call: MethodCall, result: MethodChannel.Result) {
        val reminders = call.argument<List<Map<String, Any?>>>("reminders")
        val cancel = call.argument<List<Int>>("cancel")
        val channelName = call.argument<String>("channelName")
        if (reminders == null || cancel == null || channelName == null) {
            result.error("invalid", "Missing arguments", null)
            return
        }
        val notifications = context.getSystemService(NotificationManager::class.java)
        notifications.createNotificationChannel(
            NotificationChannel(
                ReminderReceiver.CHANNEL_ID,
                channelName,
                NotificationManager.IMPORTANCE_DEFAULT,
            ),
        )
        // Every day the plan can hold that is no longer in it.
        val planned = reminders.mapNotNull { (it["id"] as? Number)?.toInt() }.toSet()
        for (id in cancel) {
            if (id !in planned) ReminderAlarms.cancel(context, id)
        }
        val kept = mutableListOf<PlanDay>()
        for (reminder in reminders) {
            val id = (reminder["id"] as? Number)?.toInt() ?: continue
            val at = (reminder["at"] as? Number)?.toLong() ?: continue
            val title = reminder["title"] as? String ?: ""
            val publicTitle = reminder["publicTitle"] as? String ?: title
            val open = reminder["open"] as? String ?: ""
            ReminderAlarms.schedule(
                context,
                id = id,
                at = at,
                title = title,
                lines = (reminder["lines"] as? List<*>)?.filterIsInstance<String>() ?: emptyList(),
                publicTitle = publicTitle,
                open = open,
            )
            // For a restart: the local date and minute, no item titles.
            val local = Instant.ofEpochMilli(at).atZone(ZoneId.systemDefault())
            kept.add(
                PlanDay(
                    id = id,
                    date = local.toLocalDate(),
                    minute = local.hour * 60 + local.minute,
                    publicTitle = publicTitle,
                    open = open,
                ),
            )
        }
        try {
            ReminderPlans.forContext(context).update {
                mergedPlan(it, kept, cancel, LocalDate.now())
            }
        } catch (e: Exception) {
            // The alarms are planned; only a restart before the next plan
            // would miss them.
        }
        result.success(null)
    }

    /** Asks for the notification permission; answers whether it is granted. */
    private fun request(result: MethodChannel.Result) {
        if (enabled()) {
            result.success(true)
            return
        }
        pendingRequest?.success(false)
        pendingRequest = result
        activity.requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            REQUEST_CODE,
        )
    }

    /** The answer to [request], from `MainActivity`; false when not ours. */
    fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        pendingRequest?.success(granted)
        pendingRequest = null
        return true
    }

    private fun openSettings(result: MethodChannel.Result) {
        activity.startActivity(
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName),
        )
        result.success(null)
    }

    companion object {
        const val CHANNEL = "eu.marandos.offload/reminders"
        private const val REQUEST_CODE = 4101

        /**
         * What a tap on a notification, the Offload bar or an app shortcut
         * opens, once: an item id, empty for Today, `#review`, `#person:<id>`,
         * `#today` or `#insights`; null when [intent] asks nothing.
         */
        fun takeOpened(intent: Intent?): String? {
            if (intent?.action != ReminderReceiver.ACTION_OPEN) return null
            val open = intent.getStringExtra(ReminderReceiver.EXTRA_OPEN) ?: ""
            intent.action = null
            return open
        }

        /** Undoes [takeOpened], for a tap the app has not heard yet. */
        fun putBack(intent: Intent, open: String) {
            intent.action = ReminderReceiver.ACTION_OPEN
            intent.putExtra(ReminderReceiver.EXTRA_OPEN, open)
        }
    }
}
