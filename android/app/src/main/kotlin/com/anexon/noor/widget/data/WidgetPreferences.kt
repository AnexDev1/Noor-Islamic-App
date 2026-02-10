package com.anexon.noor.widget.data

import android.content.Context
import android.content.SharedPreferences

/**
 * Persists widget-related user preferences using SharedPreferences.
 *
 * Stores:
 *  - Last known location (lat/lng)
 *  - Calculation method & madhab
 *  - Locale preference (en / ar)
 *  - Widget theme (light / dark / auto)
 *  - Per-widget configuration (theme, location override)
 */
object WidgetPreferences {

    private const val PREFS_NAME = "noor_widget_prefs"

    // ── Keys ──
    private const val KEY_LATITUDE      = "last_latitude"
    private const val KEY_LONGITUDE     = "last_longitude"
    private const val KEY_HAS_LOCATION  = "has_location"
    private const val KEY_CALC_METHOD   = "calculation_method"
    private const val KEY_MADHAB        = "madhab"
    private const val KEY_LOCALE        = "widget_locale"        // "en" | "ar"
    private const val KEY_THEME         = "widget_theme"         // "light" | "dark" | "auto"
    private const val KEY_CITY_NAME     = "city_name"

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    // ── Location ──

    fun saveLocation(context: Context, lat: Double, lng: Double, cityName: String? = null) {
        prefs(context).edit()
            .putFloat(KEY_LATITUDE, lat.toFloat())
            .putFloat(KEY_LONGITUDE, lng.toFloat())
            .putBoolean(KEY_HAS_LOCATION, true)
            .apply {
                cityName?.let { putString(KEY_CITY_NAME, it) }
            }
            .apply()
    }

    fun getLatitude(context: Context): Double? =
        if (prefs(context).getBoolean(KEY_HAS_LOCATION, false))
            prefs(context).getFloat(KEY_LATITUDE, 0f).toDouble()
        else null

    fun getLongitude(context: Context): Double? =
        if (prefs(context).getBoolean(KEY_HAS_LOCATION, false))
            prefs(context).getFloat(KEY_LONGITUDE, 0f).toDouble()
        else null

    fun hasLocation(context: Context): Boolean =
        prefs(context).getBoolean(KEY_HAS_LOCATION, false)

    fun getCityName(context: Context): String =
        prefs(context).getString(KEY_CITY_NAME, "Mecca") ?: "Mecca"

    // ── Calculation method ──

    fun saveCalculationMethod(context: Context, method: PrayerTimesHelper.CalculationMethodType) {
        prefs(context).edit().putString(KEY_CALC_METHOD, method.name).apply()
    }

    fun getCalculationMethod(context: Context): PrayerTimesHelper.CalculationMethodType {
        val name = prefs(context).getString(KEY_CALC_METHOD, null)
        return name?.let {
            try { PrayerTimesHelper.CalculationMethodType.valueOf(it) }
            catch (_: Exception) { PrayerTimesHelper.CalculationMethodType.UMM_AL_QURA }
        } ?: PrayerTimesHelper.CalculationMethodType.UMM_AL_QURA
    }

    fun saveMadhab(context: Context, madhab: PrayerTimesHelper.MadhabType) {
        prefs(context).edit().putString(KEY_MADHAB, madhab.name).apply()
    }

    fun getMadhab(context: Context): PrayerTimesHelper.MadhabType {
        val name = prefs(context).getString(KEY_MADHAB, null)
        return name?.let {
            try { PrayerTimesHelper.MadhabType.valueOf(it) }
            catch (_: Exception) { PrayerTimesHelper.MadhabType.SHAFI }
        } ?: PrayerTimesHelper.MadhabType.SHAFI
    }

    // ── Locale ──

    fun saveLocale(context: Context, locale: String) {
        prefs(context).edit().putString(KEY_LOCALE, locale).apply()
    }

    /** Returns "en" or "ar". */
    fun getLocale(context: Context): String =
        prefs(context).getString(KEY_LOCALE, "en") ?: "en"

    fun isArabic(context: Context): Boolean = getLocale(context) == "ar"

    // ── Theme ──

    fun saveTheme(context: Context, theme: String) {
        prefs(context).edit().putString(KEY_THEME, theme).apply()
    }

    /** Returns "light", "dark", or "auto". */
    fun getTheme(context: Context): String =
        prefs(context).getString(KEY_THEME, "auto") ?: "auto"

    // ── Per-widget config ──

    fun saveWidgetTheme(context: Context, widgetId: Int, theme: String) {
        prefs(context).edit().putString("widget_${widgetId}_theme", theme).apply()
    }

    fun getWidgetTheme(context: Context, widgetId: Int): String =
        prefs(context).getString("widget_${widgetId}_theme", null)
            ?: getTheme(context)

    fun removeWidgetConfig(context: Context, widgetId: Int) {
        prefs(context).edit().remove("widget_${widgetId}_theme").apply()
    }
}
