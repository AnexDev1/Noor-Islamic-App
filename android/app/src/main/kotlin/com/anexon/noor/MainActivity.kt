package com.anexon.noor

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class MainActivity: FlutterActivity() {

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method channel for exposing local timezone identifier
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "noor/native_timezone")
            .setMethodCallHandler { call, result ->
                if (call.method == "getLocalTimezone") {
                    try {
                        val tz = TimeZone.getDefault().id
                        result.success(tz)
                    } catch (e: Exception) {
                        result.error("TZ_ERROR", "Failed to get timezone", e.localizedMessage)
                    }
                } else {
                    result.notImplemented()
                }
            }

        // This ensures that the audio_service plugin can properly communicate
        // with the Flutter engine when running in background mode
    }
}