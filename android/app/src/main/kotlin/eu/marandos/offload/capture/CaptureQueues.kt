package eu.marandos.offload.capture

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.system.Os
import android.system.OsConstants
import java.io.File
import java.security.KeyStore
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey

/**
 * The production [CaptureQueue]: `files/capture_queue/`, encrypted with its
 * own non-exportable Android Keystore key. That key is deliberately separate
 * from the master key (PO decision 27-09-2026, DD-007): the capture window
 * then never has to unwrap the master key, which keeps it small and fast.
 */
object CaptureQueues {
    private const val DIRECTORY = "capture_queue"
    private const val KEY_ALIAS = "offload_capture_queue_v1"

    fun forContext(context: Context): CaptureQueue = CaptureQueue(
        dir = File(context.filesDir, DIRECTORY),
        key = ::keystoreKey,
        syncDirectory = ::syncDirectory,
    )

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

    /** Makes a rename in [dir] durable. */
    private fun syncDirectory(dir: File) {
        val fd = Os.open(dir.path, OsConstants.O_RDONLY, 0)
        try {
            Os.fsync(fd)
        } finally {
            Os.close(fd)
        }
    }
}
