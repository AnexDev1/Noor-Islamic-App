package com.anexon.noor.widget.provider

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import com.anexon.noor.R
import com.anexon.noor.widget.data.HijriCalendarHelper
import com.anexon.noor.widget.data.HijriCalendarHelper.RamadanPhase
import com.anexon.noor.widget.data.WidgetPreferences
import com.anexon.noor.widget.service.WidgetUpdateScheduler
import java.text.SimpleDateFormat
import java.util.*

/**
 * AppWidgetProvider for the **Ramadan Countdown** home-screen widget.
 *
 * Resizable behaviour:
 *  - Small  (1×1): number only ("5 days left" or "Day 1")
 *  - Medium (2×1 / 2×2): full text + Gregorian date
 *  - Large  (4×2+): Hijri calendar grid for the current month
 *
 * Tapping opens the app's calendar / Ramadan section.
 */
class RamadanWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_REFRESH = "com.anexon.noor.widget.RAMADAN_REFRESH"

        /** Manually trigger an update for all Ramadan widgets. */
        fun refreshAll(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(
                ComponentName(context, RamadanWidgetProvider::class.java)
            )
            val intent = Intent(context, RamadanWidgetProvider::class.java).apply {
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
        // Re-render when user resizes the widget
        updateWidget(context, appWidgetManager, appWidgetId)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetUpdateScheduler.schedulePeriodicUpdate(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        // Cancel only if no Prayer widget instances remain
        val mgr = AppWidgetManager.getInstance(context)
        val prayerIds = mgr.getAppWidgetIds(
            ComponentName(context, PrayerTimesWidgetProvider::class.java)
        )
        if (prayerIds.isEmpty()) {
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

    private fun updateWidget(
        context: Context,
        mgr: AppWidgetManager,
        widgetId: Int
    ) {
        val options = mgr.getAppWidgetOptions(widgetId)
        val minW = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 40)
        val minH = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 40)

        val views = when {
            minW >= 250 && minH >= 110 -> buildLargeLayout(context)
            minW >= 110                -> buildMediumLayout(context)
            else                       -> buildSmallLayout(context)
        }

        // Tap action → open app
        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
        if (launchIntent != null) {
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            else PendingIntent.FLAG_UPDATE_CURRENT
            val pi = PendingIntent.getActivity(context, widgetId, launchIntent, flags)
            views.setOnClickPendingIntent(R.id.widget_ramadan_root, pi)
        }

        mgr.updateAppWidget(widgetId, views)
    }

    // ── Small (1×1) ──

    private fun buildSmallLayout(context: Context): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_ramadan_small)
        val isAr = WidgetPreferences.isArabic(context)
        val status = HijriCalendarHelper.getRamadanStatus()

        when (status.phase) {
            RamadanPhase.PRE_RAMADAN -> {
                views.setTextViewText(R.id.tv_ramadan_number, "${status.daysUntilRamadan}")
                views.setTextViewText(
                    R.id.tv_ramadan_label,
                    if (isAr) "يوم حتى رمضان" else "days left"
                )
            }
            RamadanPhase.DURING_RAMADAN -> {
                views.setTextViewText(R.id.tv_ramadan_number, "${status.currentRamadanDay}")
                views.setTextViewText(
                    R.id.tv_ramadan_label,
                    if (isAr) "يوم رمضان" else "Ramadan day"
                )
            }
            RamadanPhase.POST_RAMADAN -> {
                views.setTextViewText(R.id.tv_ramadan_number, "🌙")
                views.setTextViewText(
                    R.id.tv_ramadan_label,
                    if (isAr) "عيد الفطر" else "Eid Mubarak"
                )
            }
        }
        return views
    }

    // ── Medium (2×1 / 2×2) ──

    private fun buildMediumLayout(context: Context): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_ramadan_medium)
        val isAr = WidgetPreferences.isArabic(context)
        val status = HijriCalendarHelper.getRamadanStatus()
        val hijri = HijriCalendarHelper.getCurrentHijriDate()

        when (status.phase) {
            RamadanPhase.PRE_RAMADAN -> {
                views.setTextViewText(
                    R.id.tv_ramadan_title,
                    if (isAr) "رمضان قريب" else "Ramadan is coming"
                )
                views.setTextViewText(
                    R.id.tv_ramadan_detail,
                    if (isAr) "${status.daysUntilRamadan} يوم حتى رمضان"
                    else "${status.daysUntilRamadan} days until Ramadan"
                )
            }
            RamadanPhase.DURING_RAMADAN -> {
                views.setTextViewText(
                    R.id.tv_ramadan_title,
                    if (isAr) "رمضان مبارك" else "Ramadan Mubarak"
                )
                views.setTextViewText(
                    R.id.tv_ramadan_detail,
                    if (isAr) "اليوم ${status.currentRamadanDay} من ${status.totalRamadanDays}"
                    else "Day ${status.currentRamadanDay} of ${status.totalRamadanDays}"
                )
            }
            RamadanPhase.POST_RAMADAN -> {
                views.setTextViewText(
                    R.id.tv_ramadan_title,
                    if (isAr) "عيد الفطر المبارك" else "Eid al-Fitr"
                )
                views.setTextViewText(
                    R.id.tv_ramadan_detail,
                    if (isAr) "${status.daysUntilRamadan} يوم حتى رمضان القادم"
                    else "${status.daysUntilRamadan} days until next Ramadan"
                )
            }
        }

        // Gregorian + Hijri date
        val sdf = SimpleDateFormat("EEE, d MMM yyyy", if (isAr) Locale("ar") else Locale.ENGLISH)
        views.setTextViewText(R.id.tv_gregorian_date, sdf.format(Date()))
        views.setTextViewText(
            R.id.tv_hijri_date,
            if (isAr) HijriCalendarHelper.getFormattedDateAr()
            else HijriCalendarHelper.getFormattedDateEn()
        )

        // Progress bar (Ramadan day / total)
        if (status.phase == RamadanPhase.DURING_RAMADAN) {
            views.setProgressBar(
                R.id.pb_ramadan_progress,
                status.totalRamadanDays,
                status.currentRamadanDay,
                false
            )
            views.setViewVisibility(R.id.pb_ramadan_progress, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.pb_ramadan_progress, View.GONE)
        }

        return views
    }

    // ── Large (4×2+) — Hijri month calendar grid ──

    private fun buildLargeLayout(context: Context): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_ramadan_large)
        val isAr = WidgetPreferences.isArabic(context)
        val hijri = HijriCalendarHelper.getCurrentHijriDate()
        val status = HijriCalendarHelper.getRamadanStatus()

        // Title row
        views.setTextViewText(
            R.id.tv_month_title,
            if (isAr) "${hijri.monthNameAr} ${hijri.year}"
            else "${hijri.monthNameEn} ${hijri.year} AH"
        )

        // Status sub-title
        val subtitle = when (status.phase) {
            RamadanPhase.PRE_RAMADAN ->
                if (isAr) "${status.daysUntilRamadan} يوم حتى رمضان" else "${status.daysUntilRamadan} days to Ramadan"
            RamadanPhase.DURING_RAMADAN ->
                if (isAr) "رمضان — اليوم ${status.currentRamadanDay}" else "Ramadan — Day ${status.currentRamadanDay}"
            RamadanPhase.POST_RAMADAN ->
                if (isAr) "عيد الفطر المبارك" else "Eid al-Fitr Mubarak"
        }
        views.setTextViewText(R.id.tv_status_subtitle, subtitle)

        // Day-of-week header
        val dowLabels = if (isAr)
            listOf("أح", "اث", "ثل", "أر", "خم", "جم", "سب")
        else
            listOf("Su", "Mo", "Tu", "We", "Th", "Fr", "Sa")

        val dowIds = listOf(
            R.id.tv_dow_1, R.id.tv_dow_2, R.id.tv_dow_3, R.id.tv_dow_4,
            R.id.tv_dow_5, R.id.tv_dow_6, R.id.tv_dow_7
        )
        dowLabels.forEachIndexed { i, label ->
            views.setTextViewText(dowIds[i], label)
        }

        // Calendar grid (6 rows × 7 cols = 42 cells)
        val grid = HijriCalendarHelper.getMonthGrid(hijri.month - 1, hijri.year)
        val cellIds = getGridCellIds()

        for (i in cellIds.indices) {
            if (i < grid.size) {
                val cell = grid[i]
                if (cell.isBlank) {
                    views.setTextViewText(cellIds[i], "")
                } else {
                    views.setTextViewText(cellIds[i], "${cell.dayNumber}")
                    if (cell.isToday) {
                        views.setInt(cellIds[i], "setBackgroundResource", R.drawable.widget_today_circle)
                        views.setTextColor(cellIds[i], 0xFFFFFFFF.toInt())
                    } else {
                        views.setInt(cellIds[i], "setBackgroundResource", 0)
                        views.setTextColor(cellIds[i], 0xFF333333.toInt())
                    }
                }
            } else {
                views.setTextViewText(cellIds[i], "")
            }
        }

        return views
    }

    /**
     * Returns view IDs for the 42-cell (6×7) calendar grid.
     * These IDs correspond to TextViews in widget_ramadan_large.xml.
     */
    private fun getGridCellIds(): List<Int> {
        val ids = mutableListOf<Int>()
        for (row in 1..6) {
            for (col in 1..7) {
                // R.id.tv_cell_1_1 … R.id.tv_cell_6_7
                val name = "tv_cell_${row}_${col}"
                try {
                    val field = R.id::class.java.getField(name)
                    ids.add(field.getInt(null))
                } catch (_: Exception) {
                    ids.add(0)
                }
            }
        }
        return ids
    }
}
