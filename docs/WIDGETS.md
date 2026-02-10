# Noor App — Home Screen Widgets

## Architecture Overview

```
android/app/src/main/kotlin/com/anexon/noor/widget/
├── config/
│   └── WidgetConfigActivity.kt      # Shared config (theme, language)
├── data/
│   ├── HijriCalendarHelper.kt       # Hijri date, Ramadan status, calendar grid
│   ├── PrayerTimesHelper.kt         # Adhan-based prayer calculations
│   └── WidgetPreferences.kt         # SharedPreferences persistence
├── glance/
│   ├── RamadanGlanceWidget.kt       # Jetpack Glance (API 26+) Ramadan widget
│   └── PrayerTimesGlanceWidget.kt   # Jetpack Glance (API 26+) Prayer widget
├── provider/
│   ├── RamadanWidgetProvider.kt      # XML RemoteViews Ramadan widget (API 21+)
│   └── PrayerTimesWidgetProvider.kt  # XML RemoteViews Prayer widget (API 21+)
├── service/
│   ├── WidgetUpdateScheduler.kt      # WorkManager (15min) + AlarmManager (1min)
│   ├── WidgetUpdateWorker.kt         # WorkManager coroutine worker
│   └── WidgetTickReceiver.kt         # Broadcast receiver (time/timezone/boot)
└── WidgetMethodChannel.kt            # Flutter ↔ Native bridge
```

## What's Included

### Widget 1: Ramadan Countdown
| Size | Content |
|------|---------|
| **Small (1×1)** | Number + "days left" / "Ramadan day" / "Eid Mubarak" |
| **Medium (2×1/2×2)** | Title, countdown detail, progress bar, Gregorian & Hijri dates |
| **Large (4×2+)** | Full Hijri month calendar grid with today highlighted |

### Widget 2: Prayer Times
| Size | Content |
|------|---------|
| **Small (1×1)** | Next prayer name + time |
| **Medium (2×1)** | Name, time, countdown, progress bar, city |
| **Large (4×1+)** | All 5 daily prayers with times, next highlighted, countdown |

## Dependencies Added (`android/app/build.gradle.kts`)

| Library | Purpose |
|---------|---------|
| `com.batoulapps.adhan:adhan:1.2.1` | Prayer time calculation |
| `com.github.msarhan:ummalqura-calendar:2.0.2` | Hijri (Umm al-Qura) calendar |
| `androidx.work:work-runtime-ktx:2.9.1` | Periodic widget updates |
| `kotlinx-coroutines-android:1.7.3` | Async worker support |
| `androidx.glance:glance-appwidget:1.1.1` | Modern Compose-based widgets |
| `androidx.glance:glance-material3:1.1.1` | Material 3 Glance theming |
| `androidx.appcompat:appcompat:1.7.0` | XML widget compatibility |

## Flutter Integration

### Dart bridge: `lib/core/services/noor_widget_bridge.dart`

```dart
// Push location to widgets (call when user location changes)
await NoorWidgetBridge.updateLocation(
  latitude: 21.4225,
  longitude: 39.8262,
  city: 'Mecca',
);

// Set calculation method
await NoorWidgetBridge.setCalculationMethod(
  method: 'UMM_AL_QURA',
  madhab: 'SHAFI',
);

// Set language
await NoorWidgetBridge.setLocale('ar'); // or 'en'

// Set theme
await NoorWidgetBridge.setTheme('auto'); // 'light', 'dark', 'auto'

// Force immediate refresh
await NoorWidgetBridge.refreshWidgets();

// Ensure background schedules are active (call once at app startup)
await NoorWidgetBridge.ensureScheduled();
```

## Update Strategy

| Mechanism | Interval | Purpose |
|-----------|----------|---------|
| **WorkManager** | Every 15 min | Both widgets — battery-friendly periodic refresh |
| **AlarmManager** | Every ~60 sec | Prayer countdown accuracy (inexact, batched) |
| **BroadcastReceiver** | On event | TIME_SET, TIMEZONE_CHANGED, BOOT_COMPLETED |
| **onAppWidgetOptionsChanged** | On resize | Re-renders with appropriate layout |
| **Flutter MethodChannel** | On demand | Location/settings changes from app |

## Edge Cases Handled

- **No location permission**: Falls back to Mecca (21.4225, 39.8262)
- **Offline mode**: All calculations are 100% offline (Adhan + UmmalQura)
- **Battery optimization**: Uses inexact alarms; WorkManager respects Doze mode
- **29 vs 30-day Ramadan**: `UmmalquraCalendar.getActualMaximum(DAY_OF_MONTH)`
- **After Isha**: Calculates tomorrow's Fajr as next prayer
- **Device reboot**: WidgetTickReceiver re-registers alarms on BOOT_COMPLETED
- **Multiple widget instances**: Each widget ID has independent config
- **Dark mode**: Separate `values-night/widget_colors.xml` + system auto-detection
- **RTL / Arabic**: Full Arabic string resources; locale-aware number formatting
- **Accessibility**: All TextViews have `contentDescription` attributes

## Testing Guide

### 1. Build & Install
```bash
flutter build apk --debug
# or
flutter run
```

### 2. Add Widget to Home Screen
- Long-press home screen → "Widgets"
- Search for "Noor" or "Ramadan" or "Prayer"
- Drag "Ramadan Countdown" or "Prayer Times" to home screen
- Configuration dialog appears → select theme & language → Save

### 3. Test Resizing
- Long-press the widget → drag resize handles
- Verify layout switches between small/medium/large

### 4. Test Prayer Times Accuracy
```bash
# Verify via ADB — set device time to just before Dhuhr
adb shell su -c "date 1200"
# Widget should show Dhuhr as next prayer

# Change timezone
adb shell setprop persist.sys.timezone "Asia/Riyadh"
```

### 5. Test Ramadan Scenarios
```bash
# Simulate pre-Ramadan date (Sha'ban 1447 ≈ Feb 2026)
adb shell su -c "date 020126"

# Simulate during Ramadan (Ramadan 1447 ≈ March 2026)
adb shell su -c "date 030126"

# Simulate post-Ramadan (Shawwal 1447 ≈ April 2026)
adb shell su -c "date 040126"
```

### 6. Test Calculation Methods
From Flutter:
```dart
// Test Hanafi (later Asr time)
await NoorWidgetBridge.setCalculationMethod(madhab: 'HANAFI');

// Test Egyptian method (different Fajr angle)
await NoorWidgetBridge.setCalculationMethod(method: 'EGYPTIAN');
```

### 7. Battery Saver Mode
- Enable battery saver in Settings
- Widgets should still update via WorkManager (may be delayed)
- AlarmManager ticks may be batched more aggressively

### 8. Offline Test
- Enable airplane mode
- Widgets should continue working (all calculations are offline)

### 9. Boot Test
```bash
adb reboot
# After boot, verify widgets update and alarms are rescheduled
```

## Switching to Glance (API 26+)

The XML-based widgets (`RamadanWidgetProvider` / `PrayerTimesWidgetProvider`) work
on **API 21+**. For a modern Compose-based experience on **API 26+**, swap the
manifest receivers:

```xml
<!-- Replace RamadanWidgetProvider with: -->
<receiver
    android:name=".widget.glance.RamadanGlanceReceiver"
    android:exported="true"
    android:label="@string/widget_ramadan_name">
    ...
</receiver>

<!-- Replace PrayerTimesWidgetProvider with: -->
<receiver
    android:name=".widget.glance.PrayerTimesGlanceReceiver"
    android:exported="true"
    android:label="@string/widget_prayer_name">
    ...
</receiver>
```

## Localization

| Resource | English | Arabic |
|----------|---------|--------|
| `values/widget_strings.xml` | ✅ | — |
| `values-ar/widget_strings.xml` | — | ✅ |
| `values/widget_colors.xml` | Light mode | — |
| `values-night/widget_colors.xml` | — | Dark mode |

Prayer names, Hijri month names, and countdown text all have Arabic variants
with Eastern-Arabic (Hindi) numerals (٠١٢٣٤٥٦٧٨٩).
