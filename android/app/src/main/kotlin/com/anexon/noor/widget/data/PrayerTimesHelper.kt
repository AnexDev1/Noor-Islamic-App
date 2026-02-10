package com.anexon.noor.widget.data

import com.batoulapps.adhan.*
import com.batoulapps.adhan.data.DateComponents
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.TimeUnit

/**
 * Prayer-time calculation helper powered by the Adhan library.
 *
 * Provides:
 *  - All five prayer times for a given date/location
 *  - Next upcoming prayer name & time
 *  - Human-readable countdown string (e.g. "1 h 30 min")
 *  - Current prayer if one is active
 *  - Localized prayer names (English & Arabic)
 */
object PrayerTimesHelper {

    // ── Prayer name localizations ──

    private val PRAYER_NAMES_EN = mapOf(
        Prayer.FAJR    to "Fajr",
        Prayer.SUNRISE to "Sunrise",
        Prayer.DHUHR   to "Dhuhr",
        Prayer.ASR     to "Asr",
        Prayer.MAGHRIB to "Maghrib",
        Prayer.ISHA    to "Isha"
    )

    private val PRAYER_NAMES_AR = mapOf(
        Prayer.FAJR    to "الفجر",
        Prayer.SUNRISE to "الشروق",
        Prayer.DHUHR   to "الظهر",
        Prayer.ASR     to "العصر",
        Prayer.MAGHRIB to "المغرب",
        Prayer.ISHA    to "العشاء"
    )

    // ── Default fallback coordinates (Mecca) ──
    private val DEFAULT_COORDINATES = Coordinates(21.4225, 39.8262)

    // ── Data models ──

    data class PrayerInfo(
        val prayer: Prayer,
        val nameEn: String,
        val nameAr: String,
        val time: Date,
        val formattedTime12: String,  // "3:45 PM"
        val formattedTime24: String   // "15:45"
    )

    data class NextPrayerInfo(
        val prayer: Prayer,
        val nameEn: String,
        val nameAr: String,
        val time: Date,
        val formattedTime12: String,
        val countdownText: String,      // "1 h 30 min"
        val countdownTextAr: String,    // "١ س ٣٠ د"
        val remainingMinutes: Long,
        val totalMinutesBetween: Long,  // for progress bar
        val elapsedMinutes: Long        // for progress bar
    )

    data class AllPrayerTimes(
        val prayers: List<PrayerInfo>,
        val nextPrayer: NextPrayerInfo?,
        val currentPrayer: Prayer?,
        val date: Date
    )

    // ── Configuration ──

    enum class CalculationMethodType {
        MUSLIM_WORLD_LEAGUE,
        EGYPTIAN,
        KARACHI,
        UMM_AL_QURA,
        DUBAI,
        NORTH_AMERICA,
        KUWAIT,
        QATAR,
        SINGAPORE,
        MOON_SIGHTING
    }

    enum class MadhabType { SHAFI, HANAFI }

    /**
     * Resolves an [CalculationMethodType] enum to the Adhan [CalculationParameters].
     */
    fun getCalculationParams(
        method: CalculationMethodType = CalculationMethodType.UMM_AL_QURA,
        madhab: MadhabType = MadhabType.SHAFI
    ): CalculationParameters {
        val params = when (method) {
            CalculationMethodType.MUSLIM_WORLD_LEAGUE -> CalculationMethod.MUSLIM_WORLD_LEAGUE.parameters
            CalculationMethodType.EGYPTIAN            -> CalculationMethod.EGYPTIAN.parameters
            CalculationMethodType.KARACHI             -> CalculationMethod.KARACHI.parameters
            CalculationMethodType.UMM_AL_QURA         -> CalculationMethod.UMM_AL_QURA.parameters
            CalculationMethodType.DUBAI               -> CalculationMethod.DUBAI.parameters
            CalculationMethodType.NORTH_AMERICA        -> CalculationMethod.NORTH_AMERICA.parameters
            CalculationMethodType.KUWAIT              -> CalculationMethod.KUWAIT.parameters
            CalculationMethodType.QATAR               -> CalculationMethod.QATAR.parameters
            CalculationMethodType.SINGAPORE           -> CalculationMethod.SINGAPORE.parameters
            CalculationMethodType.MOON_SIGHTING        -> CalculationMethod.MOON_SIGHTING_COMMITTEE.parameters
        }
        params.madhab = when (madhab) {
            MadhabType.SHAFI  -> Madhab.SHAFI
            MadhabType.HANAFI -> Madhab.HANAFI
        }
        return params
    }

    // ── Public API ──

    /**
     * Calculates all prayer times for today at the given location.
     *
     * @param latitude  user latitude (null → fallback to Mecca)
     * @param longitude user longitude (null → fallback to Mecca)
     * @param params   calculation parameters (method + madhab)
     */
    fun getAllPrayerTimes(
        latitude: Double? = null,
        longitude: Double? = null,
        params: CalculationParameters = getCalculationParams()
    ): AllPrayerTimes {
        val coords = if (latitude != null && longitude != null)
            Coordinates(latitude, longitude)
        else DEFAULT_COORDINATES

        val now = Date()
        val cal = GregorianCalendar().apply { time = now }
        val dateComponents = DateComponents.from(now)
        val prayerTimes = PrayerTimes(coords, dateComponents, params)

        val fmt12 = SimpleDateFormat("h:mm a", Locale.ENGLISH)
        val fmt24 = SimpleDateFormat("HH:mm", Locale.ENGLISH)
        fmt12.timeZone = TimeZone.getDefault()
        fmt24.timeZone = TimeZone.getDefault()

        // Ordered list of the 5 obligatory prayers + sunrise
        val orderedPrayers = listOf(
            Prayer.FAJR, Prayer.SUNRISE, Prayer.DHUHR,
            Prayer.ASR, Prayer.MAGHRIB, Prayer.ISHA
        )

        val prayerInfoList = orderedPrayers.mapNotNull { prayer ->
            val time = prayerTimes.timeForPrayer(prayer) ?: return@mapNotNull null
            PrayerInfo(
                prayer = prayer,
                nameEn = PRAYER_NAMES_EN[prayer] ?: "",
                nameAr = PRAYER_NAMES_AR[prayer] ?: "",
                time = time,
                formattedTime12 = fmt12.format(time),
                formattedTime24 = fmt24.format(time)
            )
        }

        val currentPrayer = prayerTimes.currentPrayer()
        val nextPrayer = prayerTimes.nextPrayer()

        val nextPrayerInfo = if (nextPrayer != Prayer.NONE) {
            val nextTime = prayerTimes.timeForPrayer(nextPrayer)
            if (nextTime != null) {
                buildNextPrayerInfo(nextTime, nextPrayer, now, prayerTimes, currentPrayer, fmt12)
            } else null
        } else {
            // After Isha → next Fajr is tomorrow
            buildTomorrowFajrInfo(coords, params, now, fmt12)
        }

        return AllPrayerTimes(
            prayers = prayerInfoList,
            nextPrayer = nextPrayerInfo,
            currentPrayer = if (currentPrayer != Prayer.NONE) currentPrayer else null,
            date = now
        )
    }

    /**
     * Quick access: only the next prayer info (used by the widget).
     */
    fun getNextPrayerQuick(
        latitude: Double? = null,
        longitude: Double? = null,
        params: CalculationParameters = getCalculationParams()
    ): NextPrayerInfo? = getAllPrayerTimes(latitude, longitude, params).nextPrayer

    // ── Private helpers ──

    private fun buildNextPrayerInfo(
        nextTime: Date,
        nextPrayer: Prayer,
        now: Date,
        prayerTimes: PrayerTimes,
        currentPrayer: Prayer,
        fmt12: SimpleDateFormat
    ): NextPrayerInfo {
        val diffMs = nextTime.time - now.time
        val remainingMin = TimeUnit.MILLISECONDS.toMinutes(diffMs).coerceAtLeast(0)

        // Elapsed & total for progress (between current prayer start → next prayer)
        val currentTime = if (currentPrayer != Prayer.NONE)
            prayerTimes.timeForPrayer(currentPrayer) else null
        val totalMin = if (currentTime != null)
            TimeUnit.MILLISECONDS.toMinutes(nextTime.time - currentTime.time).coerceAtLeast(1)
        else remainingMin
        val elapsedMin = totalMin - remainingMin

        return NextPrayerInfo(
            prayer = nextPrayer,
            nameEn = PRAYER_NAMES_EN[nextPrayer] ?: "",
            nameAr = PRAYER_NAMES_AR[nextPrayer] ?: "",
            time = nextTime,
            formattedTime12 = fmt12.format(nextTime),
            countdownText = formatCountdown(remainingMin),
            countdownTextAr = formatCountdownAr(remainingMin),
            remainingMinutes = remainingMin,
            totalMinutesBetween = totalMin,
            elapsedMinutes = elapsedMin
        )
    }

    private fun buildTomorrowFajrInfo(
        coords: Coordinates,
        params: CalculationParameters,
        now: Date,
        fmt12: SimpleDateFormat
    ): NextPrayerInfo? {
        val tomorrow = GregorianCalendar().apply {
            time = now
            add(Calendar.DAY_OF_YEAR, 1)
        }
        val dc = DateComponents.from(tomorrow.time)
        val tmrwTimes = PrayerTimes(coords, dc, params)
        val fajrTime = tmrwTimes.timeForPrayer(Prayer.FAJR) ?: return null

        val diffMs = fajrTime.time - now.time
        val remainingMin = TimeUnit.MILLISECONDS.toMinutes(diffMs).coerceAtLeast(0)

        return NextPrayerInfo(
            prayer = Prayer.FAJR,
            nameEn = "Fajr",
            nameAr = "الفجر",
            time = fajrTime,
            formattedTime12 = fmt12.format(fajrTime),
            countdownText = formatCountdown(remainingMin),
            countdownTextAr = formatCountdownAr(remainingMin),
            remainingMinutes = remainingMin,
            totalMinutesBetween = remainingMin,
            elapsedMinutes = 0
        )
    }

    /** Formats minutes into "X h Y min" */
    private fun formatCountdown(totalMinutes: Long): String {
        val h = totalMinutes / 60
        val m = totalMinutes % 60
        return when {
            h > 0 && m > 0 -> "${h}h ${m}min"
            h > 0          -> "${h}h"
            else           -> "${m}min"
        }
    }

    /** Formats minutes into Arabic numerals, e.g. "٢ س ٣٥ د" */
    private fun formatCountdownAr(totalMinutes: Long): String {
        val h = totalMinutes / 60
        val m = totalMinutes % 60
        val digits = charArrayOf('٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩')
        fun toAr(n: Long) = n.toString().map { digits[it - '0'] }.joinToString("")
        return when {
            h > 0 && m > 0 -> "${toAr(h)} س ${toAr(m)} د"
            h > 0          -> "${toAr(h)} س"
            else           -> "${toAr(m)} د"
        }
    }
}
