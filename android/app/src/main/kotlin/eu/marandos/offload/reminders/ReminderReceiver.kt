package eu.marandos.offload.reminders

import android.Manifest
import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import eu.marandos.offload.MainActivity
import eu.marandos.offload.R

/**
 * Posts the notification of one planned reminder when its alarm goes off
 * (T4.1, DD-005): the texts come with the alarm, made by the app in the UI
 * language. They live only in the alarm service's memory. Once shown, the
 * day leaves the plan kept for a restart (T4.3), so a restart never shows it
 * twice.
 */
class ReminderReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        val id = intent.getIntExtra(EXTRA_ID, 0)
        val title = intent.getStringExtra(EXTRA_TITLE) ?: return
        val lines = intent.getStringArrayListExtra(EXTRA_LINES) ?: arrayListOf()
        val publicTitle = intent.getStringExtra(EXTRA_PUBLIC_TITLE) ?: title
        val open = intent.getStringExtra(EXTRA_OPEN) ?: ""

        // A tap opens what the app asked for: an item, a person or the
        // weekly review, or Today (DD-005).
        val tap = PendingIntent.getActivity(
            context,
            id,
            Intent(context, MainActivity::class.java).apply {
                action = ACTION_OPEN
                putExtra(EXTRA_OPEN, open)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        // On the lock screen only the count, never a title (decision a).
        val public = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(publicTitle)
            .build()
        val builder = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(lines.firstOrNull() ?: "")
            .setContentIntent(tap)
            .setAutoCancel(true)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .setPublicVersion(public)
            .setCategory(Notification.CATEGORY_REMINDER)
        if (lines.size > 1) {
            val inbox = Notification.InboxStyle()
            lines.forEach { inbox.addLine(it) }
            builder.setStyle(inbox)
        }
        val notifications = context.getSystemService(NotificationManager::class.java)
        notifications.notify(id, builder.build())
        // The previous one of its kind goes: yesterday's deadlines are on
        // Today now, and a weekly review due last week is due this week.
        try {
            for (old in olderOfKind(notifications.activeNotifications.map { it.id }, id)) {
                notifications.cancel(old)
            }
        } catch (e: Exception) {
            // At worst an older one stays until swiped away.
        }
        try {
            ReminderPlans.forContext(context).update { days -> days.filter { it.id != id } }
        } catch (e: Exception) {
            // At worst a restart today shows the count line once more.
        }
    }

    companion object {
        /**
         * Where the ids of the weekly-review reminders start (`1yyyymmdd`,
         * T4.4); the same number as `reviewReminderIdOffset` in the app.
         */
        const val REVIEW_ID_OFFSET = 100_000_000

        /**
         * Where the ids of the birthday reminders start (`2yyyymmdd`, T4.6);
         * the same number as `birthdayReminderIdOffset` in the app.
         */
        const val BIRTHDAY_ID_OFFSET = 200_000_000

        /**
         * Where the ids of the nudges of silent waiting items start
         * (`3yyyymmdd`, T10.1); the same number as `nudgeReminderIdOffset`
         * in the app.
         */
        const val NUDGE_ID_OFFSET = 300_000_000

        /** The channel of deadline reminders; named in the UI language. */
        const val CHANNEL_ID = "deadlines"

        const val ACTION_OPEN = "eu.marandos.offload.OPEN_REMINDER"
        const val EXTRA_ID = "id"
        const val EXTRA_TITLE = "title"
        const val EXTRA_LINES = "lines"
        const val EXTRA_PUBLIC_TITLE = "publicTitle"

        /**
         * What a tap opens, made by the app: an item id, `#person:<id>`,
         * `#review`, or empty for Today.
         */
        const val EXTRA_OPEN = "open"
    }
}
