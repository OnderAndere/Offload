package eu.marandos.offload

import android.content.Intent
import android.os.Bundle
import android.os.StatFs
import eu.marandos.offload.capture.CaptureQueueChannel
import eu.marandos.offload.reminders.ReminderChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val backupFiles = BackupFileChannel(this)
    private val photos = PhotoChannel(this)
    private val shares = ShareChannel(this)
    private val aead = AeadChannel()
    private var captureQueue: CaptureQueueChannel? = null
    private val reminders = ReminderChannel(this)
    private var reminderChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // A request to open something (a reminder, the Offload bar, a shortcut)
        // counts once. Recreated after the process died, or started again from
        // Recents, the activity gets its old intent back: that request was
        // handled then and must not open its item or screen again (DD-018 point 5:
        // otherwise the app starts on Today).
        val fromHistory = (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0
        if (savedInstanceState != null || fromHistory) ReminderChannel.takeOpened(intent)
        super.onCreate(savedInstanceState)
        // A shared file left for a day goes (DD-014, SPEC Q12), a copy of a
        // save or an export the process left behind, and a photo of the camera
        // app (T5.3); off the main thread, and not in the capture window
        // (CLAUDE.md rule 7).
        val cache = cacheDir
        Thread {
            ShareChannel.removeOldShares(cache)
            BackupFileChannel.removeLeftoverCopies(cache)
            PhotoChannel.removeCameraFiles(cache)
        }.start()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, KeyStoreChannel.CHANNEL)
            .setMethodCallHandler(KeyStoreChannel(applicationContext))
        // AES-256-GCM for the attachments (AndroidAeadCipher, T5.1).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AeadChannel.CHANNEL)
            .setMethodCallHandler(aead)
        // The app's private files directory for the database (AndroidAppDirectory).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_DIRECTORY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "dataDirectory" -> result.success(applicationContext.filesDir.absolutePath)
                    "cacheDirectory" -> result.success(applicationContext.cacheDir.absolutePath)
                    // Room left for a backup or a restore (T7.2b); null when unknown.
                    "freeBytes" -> result.success(
                        call.argument<String>("path")?.let {
                            try {
                                StatFs(it).availableBytes
                            } catch (e: IllegalArgumentException) {
                                null
                            }
                        },
                    )
                    else -> result.notImplemented()
                }
            }
        // Captures from the home-screen widget (AndroidCaptureChannel).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CaptureQueueChannel.CHANNEL)
            .setMethodCallHandler(CaptureQueueChannel(applicationContext).also { captureQueue = it })
        // Sharing an item as text and a backup as a file (AndroidShareChannel);
        // needs the activity to start the share menu.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ShareChannel.CHANNEL)
            .setMethodCallHandler(shares)
        // Dialling a number or mailing an address of a person
        // (AndroidContactLauncher); needs the activity to start them.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ContactLauncherChannel.CHANNEL)
            .setMethodCallHandler(ContactLauncherChannel(this))
        // Saving and opening a backup through the document picker
        // (AndroidBackupFilePicker, T7.2).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BackupFileChannel.CHANNEL)
            .setMethodCallHandler(backupFiles)
        // Taking or choosing a photo for an item (AndroidPhotoSource, T5.3).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PhotoChannel.CHANNEL)
            .setMethodCallHandler(photos)
        // Deadline reminders (AndroidReminderScheduler, T4.1).
        reminderChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ReminderChannel.CHANNEL)
            .also { it.setMethodCallHandler(reminders) }
    }

    // Each channel has a worker thread of its own; made again with the
    // activity (low memory, "Don't keep activities"), the old ones would stay
    // idle until the process ends. After super: no call reaches them then.
    override fun onDestroy() {
        super.onDestroy()
        backupFiles.close()
        photos.close()
        shares.close()
        aead.close()
        captureQueue?.close()
    }

    // A tap on a reminder while the app runs: tell the app what to open.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val open = ReminderChannel.takeOpened(intent) ?: return
        val channel = reminderChannel
        if (channel == null) {
            ReminderChannel.putBack(intent, open)
            return
        }
        // Not heard yet (the app still starting): put it back, so the app
        // takes it when it asks at start.
        channel.invokeMethod(
            "opened",
            open,
            object : MethodChannel.Result {
                override fun success(result: Any?) {}
                override fun error(code: String, message: String?, details: Any?) =
                    ReminderChannel.putBack(intent, open)
                override fun notImplemented() = ReminderChannel.putBack(intent, open)
            },
        )
    }

    // The answer to the notification permission (ReminderChannel).
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (!reminders.onRequestPermissionsResult(requestCode, grantResults)) {
            super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        }
    }

    // Results of the document picker (BackupFileChannel), the camera app and
    // the photo picker (PhotoChannel).
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (!backupFiles.onActivityResult(requestCode, resultCode, data) &&
            !photos.onActivityResult(requestCode, resultCode, data)
        ) {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

    private companion object {
        const val APP_DIRECTORY_CHANNEL = "eu.marandos.offload/app_directory"
    }
}
