package com.anexon.noor.widget.service

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.anexon.noor.widget.provider.PrayerTimesWidgetProvider
import com.anexon.noor.widget.provider.RamadanWidgetProvider

/**
 * BroadcastReceiver that fires every ~60 seconds via AlarmManager
 * to update the prayer-times countdown. Also handles timezone and
 * time-setting changes, plus device boot.
 */
class WidgetTickReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_TICK = "com.anexon.noor.widget.ACTION_TICK"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_TICK,
            Intent.ACTION_TIME_TICK,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> {
                // Refresh both widgets
                PrayerTimesWidgetProvider.refreshAll(context)
                RamadanWidgetProvider.refreshAll(context)
            }
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON" -> {
                // Re-schedule alarms after reboot
                WidgetUpdateScheduler.schedulePeriodicUpdate(context)
                WidgetUpdateScheduler.scheduleMinuteUpdate(context)
                // And push an immediate refresh
                PrayerTimesWidgetProvider.refreshAll(context)
                RamadanWidgetProvider.refreshAll(context)
            }
        }
    }
}
