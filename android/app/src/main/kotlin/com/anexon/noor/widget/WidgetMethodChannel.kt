package com.anexon.noor.widget

import android.content.Context
import com.batoulapps.adhan.Prayer
import com.anexon.noor.widget.data.PrayerTimesHelper
import com.anexon.noor.widget.data.WidgetPreferences
import com.anexon.noor.widget.provider.PrayerTimesWidgetProvider
import com.anexon.noor.widget.provider.RamadanWidgetProvider
import com.anexon.noor.widget.service.WidgetUpdateScheduler
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter ↔ native bridge for widget operations.
 *
 * Exposes a MethodChannel ("noor/widget") so the Flutter side can:
 *  - Push updated location to the widgets
 *  - Set calculation method & madhab
 *  - Trigger an immediate widget refresh
 *  - Set locale / theme
 *
 * Call [register] from `MainActivity.configureFlutterEngine()`.
 */
object WidgetMethodChannel {

    private const val CHANNEL = "noor/widget"

    fun register(flutterEngine: FlutterEngine, context: Context) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // ── Update location ──
                    "updateLocation" -> {
                        val lat = call.argument<Double>("latitude")
                        val lng = call.argument<Double>("longitude")
                        val city = call.argument<String>("city")
                        if (lat != null && lng != null) {
                            WidgetPreferences.saveLocation(context, lat, lng, city)
                            refreshAllWidgets(context)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGS", "latitude and longitude required", null)
                        }
                    }

                    // ── Set calculation method ──
                    "setCalculationMethod" -> {
                        val method = call.argument<String>("method")
                        val madhab = call.argument<String>("madhab")
                        try {
                            if (method != null) {
                                WidgetPreferences.saveCalculationMethod(
                                    context,
                                    PrayerTimesHelper.CalculationMethodType.valueOf(method)
                                )
                            }
                            if (madhab != null) {
                                WidgetPreferences.saveMadhab(
                                    context,
                                    PrayerTimesHelper.MadhabType.valueOf(madhab)
                                )
                            }
                            refreshAllWidgets(context)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INVALID_METHOD", e.message, null)
                        }
                    }

                    // ── Get prayer times for Flutter UI ──
                    "getPrayerTimes" -> {
                        val lat = call.argument<Double>("latitude")
                        val lng = call.argument<Double>("longitude")
                        val methodName = call.argument<String>("method")
                        val madhabName = call.argument<String>("madhab")

                        try {
                            val method = try {
                                methodName?.let { PrayerTimesHelper.CalculationMethodType.valueOf(it) }
                                    ?: WidgetPreferences.getCalculationMethod(context)
                            } catch (_: Exception) {
                                PrayerTimesHelper.CalculationMethodType.UMM_AL_QURA
                            }
                            val madhab = try {
                                madhabName?.let { PrayerTimesHelper.MadhabType.valueOf(it) }
                                    ?: WidgetPreferences.getMadhab(context)
                            } catch (_: Exception) {
                                PrayerTimesHelper.MadhabType.SHAFI
                            }

                            val params = PrayerTimesHelper.getCalculationParams(method, madhab)
                            val allTimes = PrayerTimesHelper.getAllPrayerTimes(lat, lng, params)
                            val map = mapOf(
                                "Fajr" to allTimes.prayers.firstOrNull { it.prayer == Prayer.FAJR }?.formattedTime24.orEmpty(),
                                "Dhuhr" to allTimes.prayers.firstOrNull { it.prayer == Prayer.DHUHR }?.formattedTime24.orEmpty(),
                                "Asr" to allTimes.prayers.firstOrNull { it.prayer == Prayer.ASR }?.formattedTime24.orEmpty(),
                                "Maghrib" to allTimes.prayers.firstOrNull { it.prayer == Prayer.MAGHRIB }?.formattedTime24.orEmpty(),
                                "Isha" to allTimes.prayers.firstOrNull { it.prayer == Prayer.ISHA }?.formattedTime24.orEmpty()
                            )
                            result.success(map)
                        } catch (e: Exception) {
                            result.error("PRAYER_TIME_ERROR", e.message, null)
                        }
                    }

                    // ── Set locale ──
                    "setLocale" -> {
                        val locale = call.argument<String>("locale") ?: "en"
                        WidgetPreferences.saveLocale(context, locale)
                        refreshAllWidgets(context)
                        result.success(true)
                    }

                    // ── Set theme ──
                    "setTheme" -> {
                        val theme = call.argument<String>("theme") ?: "auto"
                        WidgetPreferences.saveTheme(context, theme)
                        refreshAllWidgets(context)
                        result.success(true)
                    }

                    // ── Manual refresh ──
                    "refreshWidgets" -> {
                        refreshAllWidgets(context)
                        result.success(true)
                    }

                    // ── Schedule updates (call once during app startup) ──
                    "ensureScheduled" -> {
                        WidgetUpdateScheduler.schedulePeriodicUpdate(context)
                        WidgetUpdateScheduler.scheduleMinuteUpdate(context)
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun refreshAllWidgets(context: Context) {
        RamadanWidgetProvider.refreshAll(context)
        PrayerTimesWidgetProvider.refreshAll(context)
    }
}
