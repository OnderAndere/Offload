package eu.marandos.offload.reminders

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.io.File
import java.security.KeyStore
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey

/**
 * Plans and cancels the alarm of one day's reminder (DD-005): an inexact
 * alarm through [AlarmManager.setWindow] with a window of 10 minutes, the
 * Android 12 minimum (SPEC Q38); no exact-alarm permission. Used by the
 * channel for the app's plan and by [ReminderRestoreReceiver] after a
 * restart.
 */
object ReminderAlarms {
    private const val WINDOW_MILLIS = 10 * 60 * 1000L

    fun schedule(
        context: Context,
        id: Int,
        at: Long,
        title: String,
        lines: List<String>,
        publicTitle: String,
        open: String,
    ) {
        val intent = Intent(context, ReminderReceiver::class.java).apply {
            putExtra(ReminderReceiver.EXTRA_ID, id)
            putExtra(ReminderReceiver.EXTRA_TITLE, title)
            putStringArrayListExtra(ReminderReceiver.EXTRA_LINES, ArrayList(lines))
            putExtra(ReminderReceiver.EXTRA_PUBLIC_TITLE, publicTitle)
            putExtra(ReminderReceiver.EXTRA_OPEN, open)
        }
        val pending = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        context.getSystemService(AlarmManager::class.java)
            .setWindow(AlarmManager.RTC_WAKEUP, at, WINDOW_MILLIS, pending)
    }

    /** Whether the alarm of day [id] is still planned. */
    fun exists(context: Context, id: Int): Boolean = PendingIntent.getBroadcast(
        context,
        id,
        Intent(context, ReminderReceiver::class.java),
        PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
    ) != null

    fun cancel(context: Context, id: Int) {
        val existing = PendingIntent.getBroadcast(
            context,
            id,
            Intent(context, ReminderReceiver::class.java),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        ) ?: return
        context.getSystemService(AlarmManager::class.java).cancel(existing)
        existing.cancel()
    }
}

/**
 * The production [ReminderPlanStore]: `no_backup/reminder_plan.bin` (not in
 * any system backup), encrypted with its own non-exportable Android Keystore
 * key, separate from the master key as the capture queue's is (DD-005,
 * DD-010).
 */
object ReminderPlans {
    private const val FILE = "reminder_plan.bin"
    private const val KEY_ALIAS = "offload_reminder_plan_v1"

    fun forContext(context: Context): ReminderPlanStore =
        ReminderPlanStore(File(context.noBackupFilesDir, FILE), ::keystoreKey)

    @Synchronized
    private fun keystoreKey(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(KEY_ALIAS, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build(),
        )
        return generator.generateKey()
    }
}
