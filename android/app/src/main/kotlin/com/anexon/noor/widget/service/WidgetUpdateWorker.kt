package com.anexon.noor.widget.service

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.anexon.noor.widget.provider.PrayerTimesWidgetProvider
import com.anexon.noor.widget.provider.RamadanWidgetProvider
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * WorkManager worker that refreshes both widget types.
 *
 * Runs on a background coroutine dispatcher; the actual RemoteViews
 * rendering happens on the main thread via the widget providers.
 */
class WidgetUpdateWorker(
    appContext: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(appContext, workerParams) {

    override suspend fun doWork(): Result = withContext(Dispatchers.Main) {
        try {
            RamadanWidgetProvider.refreshAll(applicationContext)
            PrayerTimesWidgetProvider.refreshAll(applicationContext)
            Result.success()
        } catch (e: Exception) {
            // Don't crash the whole WorkManager chain — retry later
            Result.retry()
        }
    }
}
