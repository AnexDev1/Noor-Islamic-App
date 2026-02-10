package com.anexon.noor.widget.data

import com.github.msarhan.ummalqura.calendar.UmmalquraCalendar
import java.util.Calendar
import java.util.GregorianCalendar
import java.util.Locale

/**
 * Hijri (Islamic) calendar helper using the Umm al-Qura calendar system.
 *
 * Provides:
 * - Current Hijri date
 * - Ramadan status (pre / during / post)
 * - Days-until-Ramadan countdown
 * - Current Ramadan day (1-30)
 * - Formatted date strings (English & Arabic)
 */
object HijriCalendarHelper {

    // ── Hijri month constants ──
    private const val RAMADAN = 8  // 0-indexed → 9th month

    /** Hijri month names in English */
    private val HIJRI_MONTHS_EN = arrayOf(
        "Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Thani",
        "Jumada al-Ula", "Jumada al-Thani", "Rajab", "Sha'ban",
        "Ramadan", "Shawwal", "Dhul Qi'dah", "Dhul Hijjah"
    )

    /** Hijri month names in Arabic */
    private val HIJRI_MONTHS_AR = arrayOf(
        "محرّم", "صفر", "ربيع الأوّل", "ربيع الثاني",
        "جمادى الأولى", "جمادى الثانية", "رجب", "شعبان",
        "رمضان", "شوّال", "ذو القعدة", "ذو الحجّة"
    )

    // ── Data classes ──

    data class HijriDate(
        val day: Int,
        val month: Int,        // 1-based (1 = Muharram … 12 = Dhul Hijjah)
        val year: Int,
        val monthNameEn: String,
        val monthNameAr: String,
        val gregorianDate: Calendar
    )

    enum class RamadanPhase { PRE_RAMADAN, DURING_RAMADAN, POST_RAMADAN }

    data class RamadanStatus(
        val phase: RamadanPhase,
        /** Days until Ramadan 1 (only meaningful when PRE_RAMADAN) */
        val daysUntilRamadan: Int,
        /** Current day of Ramadan, 1-based (only meaningful when DURING_RAMADAN) */
        val currentRamadanDay: Int,
        /** Total days in this Ramadan (29 or 30) */
        val totalRamadanDays: Int,
        /** Hijri year of the Ramadan in question */
        val ramadanYear: Int
    )

    // ── Public API ──

    /** Returns the current Hijri date. */
    fun getCurrentHijriDate(): HijriDate {
        val uq = UmmalquraCalendar()
        val now = GregorianCalendar()
        uq.time = now.time

        val day = uq.get(Calendar.DAY_OF_MONTH)
        val month0 = uq.get(Calendar.MONTH)          // 0-indexed
        val year = uq.get(Calendar.YEAR)

        return HijriDate(
            day = day,
            month = month0 + 1,
            year = year,
            monthNameEn = HIJRI_MONTHS_EN[month0],
            monthNameAr = HIJRI_MONTHS_AR[month0],
            gregorianDate = now
        )
    }

    /** Formatted Hijri date string, e.g. "15 Ramadan 1447 AH". */
    fun getFormattedDateEn(): String {
        val h = getCurrentHijriDate()
        return "${h.day} ${h.monthNameEn} ${h.year} AH"
    }

    /** Formatted Hijri date string in Arabic, e.g. "١٥ رمضان ١٤٤٧ هـ". */
    fun getFormattedDateAr(): String {
        val h = getCurrentHijriDate()
        val dayAr = toArabicNumerals(h.day)
        val yearAr = toArabicNumerals(h.year)
        return "$dayAr ${h.monthNameAr} $yearAr هـ"
    }

    /** Determines the current Ramadan status (pre / during / post). */
    fun getRamadanStatus(): RamadanStatus {
        val uq = UmmalquraCalendar()
        uq.time = GregorianCalendar().time

        val currentMonth = uq.get(Calendar.MONTH)   // 0-indexed
        val currentDay = uq.get(Calendar.DAY_OF_MONTH)
        val currentYear = uq.get(Calendar.YEAR)

        // Days in Ramadan this year
        val ramadanDays = daysInHijriMonth(RAMADAN, currentYear)

        return when {
            currentMonth < RAMADAN -> {
                // Before Ramadan → compute days until 1 Ramadan
                val daysUntil = daysUntilMonth(RAMADAN, currentYear, uq)
                RamadanStatus(
                    phase = RamadanPhase.PRE_RAMADAN,
                    daysUntilRamadan = daysUntil,
                    currentRamadanDay = 0,
                    totalRamadanDays = ramadanDays,
                    ramadanYear = currentYear
                )
            }
            currentMonth == RAMADAN -> {
                RamadanStatus(
                    phase = RamadanPhase.DURING_RAMADAN,
                    daysUntilRamadan = 0,
                    currentRamadanDay = currentDay,
                    totalRamadanDays = ramadanDays,
                    ramadanYear = currentYear
                )
            }
            else -> {
                // After Ramadan → countdown to next year's Ramadan
                val nextYear = currentYear + 1
                val daysUntil = daysUntilMonth(RAMADAN, nextYear, uq)
                val nextRamadanDays = daysInHijriMonth(RAMADAN, nextYear)
                RamadanStatus(
                    phase = RamadanPhase.POST_RAMADAN,
                    daysUntilRamadan = daysUntil,
                    currentRamadanDay = 0,
                    totalRamadanDays = nextRamadanDays,
                    ramadanYear = nextYear
                )
            }
        }
    }

    /**
     * Generates the grid data for an entire Hijri month (day number + day-of-week).
     * Useful for the large (4×2) Ramadan widget calendar grid.
     */
    fun getMonthGrid(hijriMonth: Int, hijriYear: Int): List<DayCell> {
        val uq = UmmalquraCalendar()
        uq.set(Calendar.YEAR, hijriYear)
        uq.set(Calendar.MONTH, hijriMonth)  // 0-indexed
        uq.set(Calendar.DAY_OF_MONTH, 1)

        val totalDays = uq.getActualMaximum(Calendar.DAY_OF_MONTH)
        val firstDow = uq.get(Calendar.DAY_OF_WEEK) // 1=Sun…7=Sat
        val todayUq = UmmalquraCalendar().apply { time = GregorianCalendar().time }
        val todayDay = todayUq.get(Calendar.DAY_OF_MONTH)
        val todayMonth = todayUq.get(Calendar.MONTH)
        val todayYear = todayUq.get(Calendar.YEAR)

        val cells = mutableListOf<DayCell>()

        // Leading blanks
        for (i in 1 until firstDow) {
            cells.add(DayCell(dayNumber = 0, isToday = false, isBlank = true))
        }

        for (d in 1..totalDays) {
            val isToday = (d == todayDay && hijriMonth == todayMonth && hijriYear == todayYear)
            cells.add(DayCell(dayNumber = d, isToday = isToday, isBlank = false))
        }

        return cells
    }

    data class DayCell(val dayNumber: Int, val isToday: Boolean, val isBlank: Boolean)

    // ── Private helpers ──

    /** Days in a given 0-indexed Hijri month of a given year. */
    private fun daysInHijriMonth(month0: Int, year: Int): Int {
        val uq = UmmalquraCalendar()
        uq.set(Calendar.YEAR, year)
        uq.set(Calendar.MONTH, month0)
        return uq.getActualMaximum(Calendar.DAY_OF_MONTH)
    }

    /**
     * Counts remaining days from current date (captured in [now]) to the 1st
     * of [targetMonth0] (0-indexed) in [targetYear].
     */
    private fun daysUntilMonth(targetMonth0: Int, targetYear: Int, now: UmmalquraCalendar): Int {
        val target = UmmalquraCalendar()
        target.set(Calendar.YEAR, targetYear)
        target.set(Calendar.MONTH, targetMonth0)
        target.set(Calendar.DAY_OF_MONTH, 1)

        val diffMs = target.timeInMillis - now.timeInMillis
        return (diffMs / (24 * 60 * 60 * 1000)).toInt().coerceAtLeast(0)
    }

    /** Converts an integer to Eastern-Arabic (Hindi) numerals for Arabic UI. */
    private fun toArabicNumerals(number: Int): String {
        val arabicDigits = charArrayOf('٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩')
        return number.toString().map { ch ->
            if (ch.isDigit()) arabicDigits[ch - '0'] else ch
        }.joinToString("")
    }
}
