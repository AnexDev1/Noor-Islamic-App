package com.anexon.noor.widget.config

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.*
import com.anexon.noor.R
import com.anexon.noor.widget.data.WidgetPreferences
import com.anexon.noor.widget.provider.PrayerTimesWidgetProvider
import com.anexon.noor.widget.provider.RamadanWidgetProvider

/**
 * Configuration activity shown when the user adds a widget to the home screen.
 *
 * Allows selecting:
 *  - Theme (Light / Dark / Auto)
 *  - Language (English / Arabic)
 *
 * Shared by both Ramadan and Prayer widgets.
 */
class WidgetConfigActivity : Activity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Default result = CANCELED (widget won't be placed if user backs out)
        setResult(RESULT_CANCELED)

        // Extract widget ID from the intent
        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        setContentView(R.layout.activity_widget_config)

        setupThemeSpinner()
        setupLanguageSpinner()
        setupButtons()
    }

    // ── UI setup ──

    private fun setupThemeSpinner() {
        val spinner = findViewById<Spinner>(R.id.spinner_theme)
        val options = arrayOf(
            getString(R.string.widget_config_theme_auto),
            getString(R.string.widget_config_theme_light),
            getString(R.string.widget_config_theme_dark)
        )
        spinner.adapter = ArrayAdapter(this, android.R.layout.simple_spinner_dropdown_item, options)

        // Pre-select current value
        val current = WidgetPreferences.getWidgetTheme(this, appWidgetId)
        spinner.setSelection(
            when (current) {
                "light" -> 1
                "dark"  -> 2
                else    -> 0
            }
        )
    }

    private fun setupLanguageSpinner() {
        val spinner = findViewById<Spinner>(R.id.spinner_language)
        val options = arrayOf("English", "العربية")
        spinner.adapter = ArrayAdapter(this, android.R.layout.simple_spinner_dropdown_item, options)

        val current = WidgetPreferences.getLocale(this)
        spinner.setSelection(if (current == "ar") 1 else 0)
    }

    private fun setupButtons() {
        findViewById<Button>(R.id.btn_save).setOnClickListener {
            saveAndFinish()
        }
        findViewById<Button>(R.id.btn_cancel).setOnClickListener {
            finish()
        }
    }

    // ── Save & return ──

    private fun saveAndFinish() {
        // Theme
        val themeSpinner = findViewById<Spinner>(R.id.spinner_theme)
        val theme = when (themeSpinner.selectedItemPosition) {
            1    -> "light"
            2    -> "dark"
            else -> "auto"
        }
        WidgetPreferences.saveWidgetTheme(this, appWidgetId, theme)

        // Language
        val langSpinner = findViewById<Spinner>(R.id.spinner_language)
        val locale = if (langSpinner.selectedItemPosition == 1) "ar" else "en"
        WidgetPreferences.saveLocale(this, locale)

        // Trigger widget update
        RamadanWidgetProvider.refreshAll(this)
        PrayerTimesWidgetProvider.refreshAll(this)

        // Return success
        val result = Intent().apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        setResult(RESULT_OK, result)
        finish()
    }
}
