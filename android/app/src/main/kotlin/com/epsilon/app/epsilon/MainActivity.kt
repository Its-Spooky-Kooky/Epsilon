package com.epsilon.app.epsilon

import android.content.Intent
import android.provider.AlarmClock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.epsilon.app/device_clock"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setAlarm" -> {
                    val hour = call.argument<Int>("hour") ?: 0
                    val minutes = call.argument<Int>("minutes") ?: 0
                    val title = call.argument<String>("title") ?: "Epsilon Reminder"
                    val skipUi = call.argument<Boolean>("skipUi") ?: true

                    val success = try {
                        val intent = Intent(AlarmClock.ACTION_SET_ALARM).apply {
                            putExtra(AlarmClock.EXTRA_HOUR, hour)
                            putExtra(AlarmClock.EXTRA_MINUTES, minutes)
                            putExtra(AlarmClock.EXTRA_MESSAGE, title)
                            putExtra(AlarmClock.EXTRA_SKIP_UI, skipUi)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        true
                    } catch (e: Exception) {
                        e.printStackTrace()
                        false
                    }
                    result.success(success)
                }
                "showAlarms" -> {
                    val success = try {
                        val intent = Intent(AlarmClock.ACTION_SHOW_ALARMS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        true
                    } catch (e: Exception) {
                        e.printStackTrace()
                        false
                    }
                    result.success(success)
                }
                else -> result.notImplemented()
            }
        }
    }
}
