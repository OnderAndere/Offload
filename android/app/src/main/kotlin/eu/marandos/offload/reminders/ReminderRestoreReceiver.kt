package eu.marandos.offload.reminders

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import java.time.ZonedDateTime

/**
 * Plans the stored reminder days again after a restart, an update of the
 * app or a change of time zone (T4.3, DD-005): Android forgets planned alarms
 * at a restart, may drop them at an update, and keeps their old moments at a
 * change of zone; the app may not be opened for a while. The texts are only
 * the title lines with the counts, as on the lock screen; no item title is
 * ever stored. When the app opens, its full plan with titles replaces these.
 * After an update a day whose alarm is still planned keeps it, with its
 * titles.
 *
 * Only the system sends the three broadcasts it listens to (protected
 * broadcasts), which is why it is exported.
 */
class ReminderRestoreReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action !in ACTIONS) return
        val store = ReminderPlans.forContext(context)
        try {
            store.update { days ->
                val restore = daysToRestore(days, ZonedDateTime.now())
                val updated = intent.action == Intent.ACTION_MY_PACKAGE_REPLACED
                for ((day, at) in restore) {
                    if (updated && ReminderAlarms.exists(context, day.id)) continue
                    ReminderAlarms.schedule(
                        context,
                        id = day.id,
                        at = at.toInstant().toEpochMilli(),
                        title = day.publicTitle,
                        lines = emptyList(),
                        publicTitle = day.publicTitle,
                        open = day.open,
                    )
                }
                // Earlier days are dropped: their items are on Today.
                restore.map { it.first }
            }
        } catch (e: Exception) {
            // Nothing to restore from (no key, a damaged file): the app plans
            // everything again when it opens.
        }
    }

    companion object {
        private val ACTIONS = setOf(
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIMEZONE_CHANGED,
        )
    }
}
