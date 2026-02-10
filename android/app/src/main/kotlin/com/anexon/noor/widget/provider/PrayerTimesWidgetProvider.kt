package com.anexon.noor.widget.provider

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import com.anexon.noor.R
import com.anexon.noor.widget.data.PrayerTimesHelper
import com.anexon.noor.widget.data.WidgetPreferences
import com.anexon.noor.widget.service.WidgetUpdateScheduler

/**
 * AppWidgetProvider for the **Prayer Times Countdown** home-screen widget.
 *
 * Resizable behaviour:
 *  - Small  (1×1): next prayer icon + time
 *  - Medium (2×1): + countdown text + progress bar
 *  - Large  (4×1+): all 5 daily prayers listed, next one highlighted
 *
 * Tapping opens the app's prayer-times screen.
 */
class PrayerTimesWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_REFRESH = "com.anexon.noor.widget.PRAYER_REFRESH"

        fun refreshAll(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(
                ComponentName(context, PrayerTimesWidgetProvider::class.java)
            )
            val intent = Intent(context, PrayerTimesWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(intent)
        }
    }

    // ── Lifecycle ──

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?
    ) {
        updateWidget(context, appWidgetManager, appWidgetId)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetUpdateScheduler.schedulePeriodicUpdate(context)
        WidgetUpdateScheduler.scheduleMinuteUpdate(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        WidgetUpdateScheduler.cancelMinuteUpdate(context)
        val mgr = AppWidgetManager.getInstance(context)
        val ramadanIds = mgr.getAppWidgetIds(
            ComponentName(context, RamadanWidgetProvider::class.java)
        )
        if (ramadanIds.isEmpty()) {
            WidgetUpdateScheduler.cancelPeriodicUpdate(context)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        for (id in appWidgetIds) {
            WidgetPreferences.removeWidgetConfig(context, id)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_REFRESH) {
            refreshAll(context)
            return
        }
        super.onReceive(context, intent)
    }

    // ── Rendering ──

    private fun updateWidget(context: Context, mgr: AppWidgetManager, widgetId: Int) {
        val options = mgr.getAppWidgetOptions(widgetId)
        val minW = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 40)
        val minH = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 40)

        val lat = WidgetPreferences.getLatitude(context)
        val lng = WidgetPreferences.getLongitude(context)
        val method = WidgetPreferences.getCalculationMethod(context)
        val madhab = WidgetPreferences.getMadhab(context)
        val params = PrayerTimesHelper.getCalculationParams(method, madhab)

        val allTimes = PrayerTimesHelper.getAllPrayerTimes(lat, lng, params)

        val views = when {
            minW >= 250 -> buildLargeLayout(context, allTimes)
            minW >= 110 -> buildMediumLayout(context, allTimes)
            else        -> buildSmallLayout(context, allTimes)
        }

        // Tap → open app
        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
        if (launchIntent != null) {
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            else PendingIntent.FLAG_UPDATE_CURRENT
            val pi = PendingIntent.getActivity(context, widgetId + 1000, launchIntent, flags)
            views.setOnClickPendingIntent(R.id.widget_prayer_root, pi)
        }

        mgr.updateAppWidget(widgetId, views)
    }

    // ── Small (1×1) ──

    private fun buildSmallLayout(
        context: Context,
        data: PrayerTimesHelper.AllPrayerTimes
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_prayer_small)
        val isAr = WidgetPreferences.isArabic(context)
        val next = data.nextPrayer

        if (next != null) {
            views.setTextViewText(
                R.id.tv_prayer_name_small,
                if (isAr) next.nameAr else next.nameEn
            )
            views.setTextViewText(R.id.tv_prayer_time_small, next.formattedTime12)
        } else {
            views.setTextViewText(
                R.id.tv_prayer_name_small,
                if (isAr) "—" else "—"
            )
            views.setTextViewText(R.id.tv_prayer_time_small, "")
        }
        return views
    }

    // ── Medium (2×1) ──

    private fun buildMediumLayout(
        context: Context,
        data: PrayerTimesHelper.AllPrayerTimes
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_prayer_medium)
        val isAr = WidgetPreferences.isArabic(context)
        val next = data.nextPrayer

        if (next != null) {
            views.setTextViewText(
                R.id.tv_next_prayer_label,
                if (isAr) "الصلاة القادمة" else "Next Prayer"
            )
            views.setTextViewText(
                R.id.tv_prayer_name_med,
                if (isAr) next.nameAr else next.nameEn
            )
            views.setTextViewText(R.id.tv_prayer_time_med, next.formattedTime12)
            views.setTextViewText(
                R.id.tv_countdown_med,
                if (isAr) "بعد ${next.countdownTextAr}" else "in ${next.countdownText}"
            )
            // Progress bar
            views.setProgressBar(
                R.id.pb_prayer_progress,
                next.totalMinutesBetween.toInt().coerceAtLeast(1),
                next.elapsedMinutes.toInt(),
                false
            )
            views.setViewVisibility(R.id.pb_prayer_progress, View.VISIBLE)
        } else {
            views.setTextViewText(
                R.id.tv_next_prayer_label,
                if (isAr) "لا صلوات" else "No upcoming"
            )
            views.setTextViewText(R.id.tv_prayer_name_med, "")
            views.setTextViewText(R.id.tv_prayer_time_med, "")
            views.setTextViewText(R.id.tv_countdown_med, "")
            views.setViewVisibility(R.id.pb_prayer_progress, View.GONE)
        }

        // City
        views.setTextViewText(R.id.tv_city_name, WidgetPreferences.getCityName(context))

        return views
    }

    // ── Large (4×1+) — all 5 prayers ──

    private fun buildLargeLayout(
        context: Context,
        data: PrayerTimesHelper.AllPrayerTimes
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_prayer_large)
        val isAr = WidgetPreferences.isArabic(context)

        // Title
        views.setTextViewText(
            R.id.tv_prayer_title,
            if (isAr) "مواقيت الصلاة" else "Prayer Times"
        )
        views.setTextViewText(R.id.tv_prayer_city, WidgetPreferences.getCityName(context))

        // Map prayer enum → row view IDs
        data class RowIds(val nameId: Int, val timeId: Int, val rowId: Int)
        val rows = listOf(
            RowIds(R.id.tv_fajr_name,    R.id.tv_fajr_time,    R.id.row_fajr),
            RowIds(R.id.tv_dhuhr_name,   R.id.tv_dhuhr_time,   R.id.row_dhuhr),
            RowIds(R.id.tv_asr_name,     R.id.tv_asr_time,     R.id.row_asr),
            RowIds(R.id.tv_maghrib_name, R.id.tv_maghrib_time, R.id.row_maghrib),
            RowIds(R.id.tv_isha_name,    R.id.tv_isha_time,    R.id.row_isha)
        )

        // Only the five obligatory prayers (skip Sunrise)
        val obligatory = data.prayers.filter {
            it.prayer != com.batoulapps.adhan.Prayer.SUNRISE
        }

        for (i in rows.indices) {
            if (i < obligatory.size) {
                val p = obligatory[i]
                views.setTextViewText(
                    rows[i].nameId,
                    if (isAr) p.nameAr else p.nameEn
                )
                views.setTextViewText(rows[i].timeId, p.formattedTime12)

                // Highlight next prayer row
                val isNext = data.nextPrayer?.prayer == p.prayer
                if (isNext) {
                    views.setInt(
                        rows[i].rowId,
                        "setBackgroundResource",
                        R.drawable.widget_highlight_bg
                    )
                } else {
                    views.setInt(rows[i].rowId, "setBackgroundResource", 0)
                }
            }
        }

        // Countdown for next prayer
        val next = data.nextPrayer
        if (next != null) {
            views.setTextViewText(
                R.id.tv_next_countdown,
                if (isAr) "${next.nameAr} بعد ${next.countdownTextAr}"
                else "${next.nameEn} in ${next.countdownText}"
            )
        } else {
            views.setTextViewText(R.id.tv_next_countdown, "")
        }

        return views
    }
}
