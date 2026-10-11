package eu.marandos.offload.reminders

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File
import java.security.SecureRandom
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZonedDateTime
import javax.crypto.SecretKey
import javax.crypto.spec.SecretKeySpec

/**
 * The reminder plan kept for a restart (T4.3, DD-005), with a software AES
 * key instead of the Android Keystore.
 */
class ReminderPlanTest {
    @get:Rule
    val folder = TemporaryFolder()

    private val key: SecretKey = newKey()
    private val amsterdam = ZoneId.of("Europe/Amsterdam")
    private val friday = LocalDate.of(2026, 10, 9)

    private fun newKey(): SecretKey =
        SecretKeySpec(ByteArray(32).also { SecureRandom().nextBytes(it) }, "AES")

    private fun file() = File(folder.root, "reminder_plan.bin")

    private fun store(withKey: SecretKey = key) = ReminderPlanStore(file(), { withKey })

    private fun day(date: LocalDate, minute: Int = 540, title: String = "2 deadlines vandaag") =
        PlanDay(
            id = date.year * 10000 + date.monthValue * 100 + date.dayOfMonth,
            date = date,
            minute = minute,
            publicTitle = title,
            open = "",
        )

    @Test
    fun `a plan comes back as it was saved`() {
        val days = listOf(
            day(friday, title = "1 deadline · 2 terug in je inbox"),
            day(friday.plusDays(3), minute = 0, title = "Deadline vandaag").copy(open = "0192-abc"),
        )
        store().save(days)
        assertEquals(days, store().load())
    }

    @Test
    fun `the file is encrypted, no count line in it`() {
        store().save(listOf(day(friday, title = "3 deadlines vandaag")))
        val bytes = file().readBytes()
        assertFalse(String(bytes, Charsets.ISO_8859_1).contains("deadlines"))
    }

    @Test
    fun `another key, a damaged file or none is no plan`() {
        assertEquals(emptyList<PlanDay>(), store().load())
        store().save(listOf(day(friday)))
        assertEquals(emptyList<PlanDay>(), store(newKey()).load())
        val bytes = file().readBytes()
        bytes[bytes.size - 1] = (bytes[bytes.size - 1].toInt() xor 1).toByte()
        file().writeBytes(bytes)
        assertEquals(emptyList<PlanDay>(), store().load())
    }

    @Test
    fun `an empty plan removes the file`() {
        store().save(listOf(day(friday)))
        store().save(emptyList())
        assertFalse(file().exists())
    }

    @Test
    fun `a new plan replaces what it may take away and keeps a passed day`() {
        val passed = day(friday)
        val later = day(friday.plusDays(1))
        val gone = day(friday.plusDays(2))
        val existing = listOf(passed, later, gone)
        val planned = listOf(day(friday.plusDays(1), title = "Terug in je inbox"))
        // After 09:00 on Friday the app may take away Saturday onwards.
        val cancel = listOf(later.id, gone.id, day(friday.plusDays(3)).id)

        val merged = mergedPlan(existing, planned, cancel, friday)

        assertEquals(listOf(passed, planned.single()), merged)
    }

    @Test
    fun `a new plan drops days before today`() {
        val yesterday = day(friday.minusDays(1))
        val today = day(friday)
        assertEquals(listOf(today), mergedPlan(listOf(yesterday, today), emptyList(), emptyList(), friday))
    }

    @Test
    fun `a restart plans coming days at their time and today's missed one now`() {
        val now = ZonedDateTime.of(2026, 10, 9, 11, 0, 0, 0, amsterdam)
        val earlier = day(friday.minusDays(1))
        val missed = day(friday)
        val evening = day(friday, minute = 20 * 60).copy(id = 1)
        val coming = day(friday.plusDays(2))

        val restore = daysToRestore(listOf(earlier, missed, evening, coming), now)

        assertEquals(listOf(missed, evening, coming), restore.map { it.first })
        assertEquals(now, restore[0].second)
        assertEquals(ZonedDateTime.of(2026, 10, 9, 20, 0, 0, 0, amsterdam), restore[1].second)
        assertEquals(ZonedDateTime.of(2026, 10, 11, 9, 0, 0, 0, amsterdam), restore[2].second)
    }

    @Test
    fun `after a change of time zone 09 00 stays 09 00 local time`() {
        val london = ZoneId.of("Europe/London")
        val now = ZonedDateTime.of(2026, 10, 9, 6, 0, 0, 0, london)
        val at = daysToRestore(listOf(day(friday.plusDays(1))), now).single().second
        assertEquals(ZonedDateTime.of(2026, 10, 10, 9, 0, 0, 0, london), at)
        assertTrue(at.isAfter(now))
    }

    @Test
    fun `update changes the stored plan in one step`() {
        store().save(listOf(day(friday), day(friday.plusDays(1))))
        store().update { days -> days.filter { it.date != friday } }
        assertEquals(listOf(day(friday.plusDays(1))), store().load())
    }

    @Test
    fun `a new notification replaces the older ones of its kind only`() {
        val active = listOf(20261008, 20261009, 120261002, 120261009, 220261001, 220261009, 7)
        assertEquals(listOf(20261008), olderOfKind(active, 20261009))
        assertEquals(listOf(120261002), olderOfKind(active, 120261009))
        assertEquals(listOf(220261001), olderOfKind(active, 220261009))
        assertEquals(emptyList<Int>(), olderOfKind(active, 320261009))
        assertEquals(listOf(320261001), olderOfKind(active + 320261001, 320261009))
        assertEquals(emptyList<Int>(), olderOfKind(active, 7))
        // A late alarm of an earlier day leaves the newer one alone.
        assertEquals(emptyList<Int>(), olderOfKind(active, 20261007))
    }
}
