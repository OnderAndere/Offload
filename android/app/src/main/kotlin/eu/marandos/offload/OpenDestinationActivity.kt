package eu.marandos.offload

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import eu.marandos.offload.reminders.ReminderReceiver

/**
 * Opens the app on a destination (REQ-063, DD-010): *Today* or *Insights*,
 * from the Offload bar and the app shortcuts. It shows nothing: it hands the
 * request to [MainActivity] the way a tap on a reminder does, so the running
 * app comes to the front and opens it (`ReminderChannel.takeOpened`), or a
 * cold start takes it. The launcher starts a static shortcut in a cleared
 * task; this activity has a task of its own, so the app's task is never
 * cleared and nothing typed in the app is lost.
 */
class OpenDestinationActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val open = intent?.getStringExtra(ReminderReceiver.EXTRA_OPEN)
        if (open == TODAY || open == INSIGHTS) startActivity(openIntent(this, open))
        finish()
    }

    companion object {
        const val ACTION = "eu.marandos.offload.OPEN_DESTINATION"

        /** The same words the app knows (`lib/domain/app/open_targets.dart`). */
        const val TODAY = "#today"
        const val INSIGHTS = "#insights"

        /** [MainActivity] asked to open [open], as a reminder tap does. */
        fun openIntent(context: Context, open: String): Intent =
            Intent(context, MainActivity::class.java).apply {
                action = ReminderReceiver.ACTION_OPEN
                putExtra(ReminderReceiver.EXTRA_OPEN, open)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
    }
}
