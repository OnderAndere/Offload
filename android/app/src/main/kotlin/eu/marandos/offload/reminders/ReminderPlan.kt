package eu.marandos.offload.reminders

import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.time.LocalDate
import java.time.ZonedDateTime
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * One day of the reminder plan as kept for a restart (T4.3, DD-005): when it
 * comes (a local date and minute, so a change of time zone keeps 09:00 at
 * 09:00), the title line with the counts and what a tap opens. Never an item
 * title: those exist only in the alarms the app hands over.
 */
data class PlanDay(
    val id: Int,
    val date: LocalDate,
    val minute: Int,
    val publicTitle: String,
    val open: String,
) {
    /** When it comes in the zone of [now]. */
    fun at(now: ZonedDateTime): ZonedDateTime =
        date.atStartOfDay(now.zone).plusMinutes(minute.toLong())
}

/**
 * What a restart plans again from the stored [days] at [now]: the days still
 * to come at their own time, and a day of today whose time passed while the
 * phone was off right away (at [now]); earlier days are dropped, their items
 * are on Today. Returns each day with the moment to plan it at.
 */
fun daysToRestore(days: List<PlanDay>, now: ZonedDateTime): List<Pair<PlanDay, ZonedDateTime>> {
    val today = now.toLocalDate()
    return days.filter { !it.date.isBefore(today) }.map { day ->
        val at = day.at(now)
        day to if (at.isAfter(now)) at else now
    }
}

/**
 * The notifications among [active] that showing [shown] replaces: the older
 * ones of its kind, a day's reminder (`yyyymmdd`), a weekly-review reminder
 * (`1yyyymmdd`), a birthday reminder (`2yyyymmdd`) or a nudge
 * (`3yyyymmdd`). Within a kind the id orders by day, so a late alarm never
 * removes a newer one. Ids outside these ranges are never touched.
 */
fun olderOfKind(active: List<Int>, shown: Int): List<Int> {
    fun kind(id: Int): Int? = when (id) {
        in DAY_IDS -> 0
        in REVIEW_IDS -> 1
        in BIRTHDAY_IDS -> 2
        in NUDGE_IDS -> 3
        else -> null
    }
    val shownKind = kind(shown) ?: return emptyList()
    return active.filter { it < shown && kind(it) == shownKind }
}

/** `yyyymmdd` of the years 2000 to 2999. */
private val DAY_IDS = 20000101..29991231

/** The same days as weekly-review ids, `1yyyymmdd`. */
private val REVIEW_IDS =
    DAY_IDS.first + ReminderReceiver.REVIEW_ID_OFFSET..DAY_IDS.last + ReminderReceiver.REVIEW_ID_OFFSET

/** The same days as birthday ids, `2yyyymmdd`. */
private val BIRTHDAY_IDS =
    DAY_IDS.first + ReminderReceiver.BIRTHDAY_ID_OFFSET..DAY_IDS.last + ReminderReceiver.BIRTHDAY_ID_OFFSET

/** The same days as nudge ids, `3yyyymmdd`. */
private val NUDGE_IDS =
    DAY_IDS.first + ReminderReceiver.NUDGE_ID_OFFSET..DAY_IDS.last + ReminderReceiver.NUDGE_ID_OFFSET

/**
 * The stored plan after the app hands over [planned] on [today]: the days it
 * may take away ([cancel], the same candidates as the alarms) and the planned
 * days are replaced; others stay, such as a day of today whose time passed
 * but that Android has not shown yet. Days before [today] go: a restart
 * would drop them anyway. Sorted by id, which is the day.
 */
fun mergedPlan(
    existing: List<PlanDay>,
    planned: List<PlanDay>,
    cancel: Collection<Int>,
    today: LocalDate,
): List<PlanDay> {
    val replaced = cancel.toSet() + planned.map { it.id }
    return (existing.filter { it.id !in replaced && !it.date.isBefore(today) } + planned)
        .sortedBy { it.id }
}

/**
 * The plan kept for a restart, in one file encrypted with AES-256-GCM under
 * a key that never leaves the Android Keystore (DD-005, hard rule 2), the way
 * the capture queue is kept (DD-010).
 *
 * File format: format version (1 byte) | IV (12) | ciphertext and tag, with
 * [AAD] as associated data. Plaintext: payload version (1 byte) | count (4) |
 * per day: id (4), epoch day (8), minute (4), title line and open (modified
 * UTF-8). A file that cannot be read counts as no plan: the app writes a new
 * one at its next start.
 *
 * All access goes through one lock: the channel and the receivers live in
 * the same process.
 */
class ReminderPlanStore(
    private val file: File,
    private val key: () -> SecretKey,
) {
    fun load(): List<PlanDay> = synchronized(LOCK) { read() }

    /** Writes [days]; none removes the file. */
    fun save(days: List<PlanDay>) = synchronized(LOCK) { write(days) }

    /** Applies [change] to the stored plan in one step. */
    fun update(change: (List<PlanDay>) -> List<PlanDay>) = synchronized(LOCK) {
        write(change(read()))
    }

    private fun read(): List<PlanDay> {
        if (!file.exists()) return emptyList()
        val bytes = file.readBytes()
        if (bytes.size <= HEADER_SIZE || bytes[0] != FORMAT_VERSION.toByte()) return emptyList()
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(TAG_BITS, bytes, 1, IV_SIZE))
        cipher.updateAAD(AAD)
        val plain = try {
            cipher.doFinal(bytes, HEADER_SIZE, bytes.size - HEADER_SIZE)
        } catch (e: AEADBadTagException) {
            return emptyList()
        }
        return try {
            decode(plain)
        } catch (e: IOException) {
            emptyList()
        } catch (e: IllegalArgumentException) {
            emptyList()
        }
    }

    private fun write(days: List<PlanDay>) {
        if (days.isEmpty()) {
            file.delete()
            return
        }
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, key())
        cipher.updateAAD(AAD)
        val sealed = cipher.doFinal(encode(days))
        file.parentFile?.mkdirs()
        val tmp = File(file.path + ".tmp")
        try {
            FileOutputStream(tmp).use { out ->
                out.write(FORMAT_VERSION)
                out.write(cipher.iv)
                out.write(sealed)
                out.fd.sync()
            }
            if (!tmp.renameTo(file)) throw IOException("Rename failed")
        } catch (e: Exception) {
            tmp.delete()
            throw e
        }
    }

    private fun encode(days: List<PlanDay>): ByteArray {
        val buffer = ByteArrayOutputStream()
        DataOutputStream(buffer).use { out ->
            out.writeByte(PAYLOAD_VERSION)
            out.writeInt(days.size)
            for (day in days) {
                out.writeInt(day.id)
                out.writeLong(day.date.toEpochDay())
                out.writeInt(day.minute)
                out.writeUTF(day.publicTitle)
                out.writeUTF(day.open)
            }
        }
        return buffer.toByteArray()
    }

    private fun decode(plain: ByteArray): List<PlanDay> {
        DataInputStream(ByteArrayInputStream(plain)).use { input ->
            require(input.readUnsignedByte() == PAYLOAD_VERSION) { "Unknown payload version" }
            val count = input.readInt()
            require(count in 0..MAX_DAYS) { "Bad count" }
            val days = List(count) {
                val id = input.readInt()
                val date = LocalDate.ofEpochDay(input.readLong())
                val minute = input.readInt()
                require(minute in 0 until 24 * 60) { "Bad minute" }
                PlanDay(id, date, minute, input.readUTF(), input.readUTF())
            }
            if (input.read() != -1) throw IOException("Trailing bytes")
            return days
        }
    }

    companion object {
        private val LOCK = Any()
        private val AAD = "offload_reminder_plan".toByteArray(Charsets.UTF_8)
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val FORMAT_VERSION = 1
        private const val PAYLOAD_VERSION = 1
        private const val IV_SIZE = 12
        private const val TAG_BITS = 128
        private const val HEADER_SIZE = 1 + IV_SIZE

        /** Far more than the 30 days ahead plus the days kept. */
        private const val MAX_DAYS = 400
    }
}
