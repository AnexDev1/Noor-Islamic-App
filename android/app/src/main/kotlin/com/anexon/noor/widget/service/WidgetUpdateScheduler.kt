package com.anexon.noor.widget.service

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import androidx.work.*
import com.anexon.noor.widget.provider.PrayerTimesWidgetProvider
import com.anexon.noor.widget.provider.RamadanWidgetProvider
import java.util.concurrent.TimeUnit

/**
 * Schedules periodic and minute-level widget updates.
 *
 * - **Periodic (WorkManager):** every 15 min for both widgets — battery-friendly.
 * - **Minute-level (AlarmManager):** every 60 s for the prayer countdown — kept
 *   separate so it can be cancelled independently when no PrayerTimes widget
 *   instances are on the home screen.
 */
object WidgetUpdateScheduler {

    private const val PERIODIC_WORK_TAG = "noor_widget_periodic"
    private const val MINUTE_ALARM_REQUEST_CODE = 9001

    // ───────────────────────────── WorkManager (every 15 min) ─────────────────

    fun schedulePeriodicUpdate(context: Context) {
        val constraints = Constraints.Builder()
            .setRequiresBatteryNotLow(false)   // update even on low battery
            .build()

        val request = PeriodicWorkRequestBuilder<WidgetUpdateWorker>(
            15, TimeUnit.MINUTES
        )
            .setConstraints(constraints)
            .addTag(PERIODIC_WORK_TAG)
            .build()

        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            PERIODIC_WORK_TAG,
            ExistingPeriodicWorkPolicy.KEEP,
            request
        )
    }

    fun cancelPeriodicUpdate(context: Context) {
        WorkManager.getInstance(context).cancelUniqueWork(PERIODIC_WORK_TAG)
    }

    // ───────────────────────────── AlarmManager (every 60 s) ─────────────────

    /**
     * Uses inexact repeating alarm for minute-level prayer countdown updates.
     * Batches with other alarms to save battery.
     */
    fun scheduleMinuteUpdate(context: Context) {
        val alarmMgr = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, WidgetTickReceiver::class.java).apply {
            action = WidgetTickReceiver.ACTION_TICK
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        else PendingIntent.FLAG_UPDATE_CURRENT

        val pi = PendingIntent.getBroadcast(context, MINUTE_ALARM_REQUEST_CODE, intent, flags)

        // Inexact repeating — system batches to save battery
        alarmMgr.setInexactRepeating(
            AlarmManager.ELAPSED_REALTIME,
            SystemClock.elapsedRealtime() + 60_000,
            60_000,  // ~1 min
            pi
        )
    }

    fun cancelMinuteUpdate(context: Context) {
        val alarmMgr = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, WidgetTickReceiver::class.java).apply {
            action = WidgetTickReceiver.ACTION_TICK
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        else PendingIntent.FLAG_UPDATE_CURRENT

        val pi = PendingIntent.getBroadcast(context, MINUTE_ALARM_REQUEST_CODE, intent, flags)
        alarmMgr.cancel(pi)
    }
}
