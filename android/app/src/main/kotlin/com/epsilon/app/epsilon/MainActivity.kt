package com.epsilon.app.epsilon

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.AlarmClock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.epsilon.app/device_clock"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Request notification permission on Android 13+ (Tiramisu)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 101)
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setAlarm" -> {
                    val id = call.argument<String>("id") ?: "epsilon_alarm"
                    val epochMillis = call.argument<Number>("epochMillis")?.toLong() ?: 0L
                    val title = call.argument<String>("title") ?: "Epsilon Contest Reminder"
                    val message = call.argument<String>("message") ?: "Your contest is starting soon!"

                    val success = try {
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        val intent = Intent(this, AlarmReceiver::class.java).apply {
                            action = "com.epsilon.app.ALARM_TRIGGER"
                            putExtra("id", id)
                            putExtra("title", title)
                            putExtra("message", message)
                        }
                        val pendingIntent = PendingIntent.getBroadcast(
                            this,
                            id.hashCode(),
                            intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )

                        val showIntent = Intent(this, MainActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        }
                        val showPendingIntent = PendingIntent.getActivity(
                            this,
                            id.hashCode(),
                            showIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )

                        // 1. Primary: Use setAlarmClock (bypasses Doze/Samsung app sleep & needs no special permissions)
                        try {
                            val clockInfo = AlarmManager.AlarmClockInfo(epochMillis, showPendingIntent)
                            alarmManager.setAlarmClock(clockInfo, pendingIntent)
                        } catch (e: Exception) {
                            // 2. Fallback: setExactAndAllowWhileIdle
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                alarmManager.setExactAndAllowWhileIdle(
                                    AlarmManager.RTC_WAKEUP,
                                    epochMillis,
                                    pendingIntent
                                )
                            } else {
                                alarmManager.setExact(
                                    AlarmManager.RTC_WAKEUP,
                                    epochMillis,
                                    pendingIntent
                                )
                            }
                        }

                        // Persist to SharedPreferences so alarms survive device reboots
                        val prefs = getSharedPreferences("epsilon_alarms_prefs", Context.MODE_PRIVATE)
                        val alarmJson = org.json.JSONObject().apply {
                            put("id", id)
                            put("epochMillis", epochMillis)
                            put("title", title)
                            put("message", message)
                        }
                        prefs.edit().putString(id, alarmJson.toString()).apply()
                        true
                    } catch (e: Exception) {
                        e.printStackTrace()
                        false
                    }
                    result.success(success)
                }
                "cancelAlarm" -> {
                    val id = call.argument<String>("id") ?: "epsilon_alarm"
                    val success = try {
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        val intent = Intent(this, AlarmReceiver::class.java).apply {
                            action = "com.epsilon.app.ALARM_TRIGGER"
                        }
                        val pendingIntent = PendingIntent.getBroadcast(
                            this,
                            id.hashCode(),
                            intent,
                            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
                        )
                        if (pendingIntent != null) {
                            alarmManager.cancel(pendingIntent)
                            pendingIntent.cancel()
                        }
                        // Remove from persistent storage
                        val prefs = getSharedPreferences("epsilon_alarms_prefs", Context.MODE_PRIVATE)
                        prefs.edit().remove(id).apply()

                        // Also dismiss any existing notification for this event
                        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        notificationManager.cancel(id.hashCode())
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
                "updateWidgetEvents" -> {
                    val eventsJson = call.argument<String>("eventsJson") ?: "[]"
                    val prefs = getSharedPreferences("epsilon_widget_prefs", Context.MODE_PRIVATE)
                    prefs.edit().putString("events_json", eventsJson).apply()
                    CalendarWidgetProvider.updateAllWidgets(this)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
