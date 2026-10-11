package eu.marandos.offload.capture

import java.security.SecureRandom
import java.util.Random

/**
 * RFC 9562 version 7 UUIDs, the same scheme as the app's `UuidV7Generator`
 * (REQ-008): 48 bits of Unix time in milliseconds, then random bits. The app
 * reads an item's capture time back from its id, so a capture made in the
 * widget keeps the moment of the tap, however late the app picks it up.
 */
internal object UuidV7 {
    private val secureRandom = SecureRandom()

    private val FORMAT =
        Regex("^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$")

    fun next(nowMillis: Long = System.currentTimeMillis(), random: Random = secureRandom): String {
        require(nowMillis >= 0 && nowMillis < (1L shl 48)) { "Timestamp out of range: $nowMillis" }
        val bytes = ByteArray(16)
        random.nextBytes(bytes)
        for (i in 0 until 6) {
            bytes[i] = ((nowMillis ushr (8 * (5 - i))) and 0xff).toByte()
        }
        bytes[6] = ((bytes[6].toInt() and 0x0f) or 0x70).toByte() // version 7
        bytes[8] = ((bytes[8].toInt() and 0x3f) or 0x80).toByte() // RFC 9562 variant
        val hex = bytes.joinToString("") { "%02x".format(it.toInt() and 0xff) }
        return "${hex.substring(0, 8)}-${hex.substring(8, 12)}-" +
            "${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}"
    }

    /** Whether [id] is a canonical, lowercase version 7 UUID. */
    fun isValid(id: String): Boolean = FORMAT.matches(id)
}
