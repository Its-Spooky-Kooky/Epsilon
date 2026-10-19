package com.epsilon.app.epsilon

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONObject

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == "com.htc.intent.action.QUICKBOOT_POWERON"
        ) {
            val prefs = context.getSharedPreferences("epsilon_alarms_prefs", Context.MODE_PRIVATE)
            val allEntries = prefs.all
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val now = System.currentTimeMillis()
            val editor = prefs.edit()

            for ((key, value) in allEntries) {
                if (value is String) {
                    try {
                        val json = JSONObject(value)
                        val id = json.optString("id", key)
                        val epochMillis = json.optLong("epochMillis", 0L)
                        val title = json.optString("title", "Epsilon Contest Reminder")
                        val message = json.optString("message", "Your contest is starting soon!")

                        if (epochMillis > now) {
                            val alarmIntent = Intent(context, AlarmReceiver::class.java).apply {
                                this.action = "com.epsilon.app.ALARM_TRIGGER"
                                putExtra("id", id)
                                putExtra("title", title)
                                putExtra("message", message)
                            }
                            val pendingIntent = PendingIntent.getBroadcast(
                                context,
                                id.hashCode(),
                                alarmIntent,
                                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                            )

                            val showIntent = Intent(context, MainActivity::class.java).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                            }
                            val showPendingIntent = PendingIntent.getActivity(
                                context,
                                id.hashCode(),
                                showIntent,
                                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                            )

                            try {
                                val clockInfo = AlarmManager.AlarmClockInfo(epochMillis, showPendingIntent)
                                alarmManager.setAlarmClock(clockInfo, pendingIntent)
                            } catch (_: Exception) {
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
                        } else {
                            editor.remove(key)
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }
            editor.apply()
        }
    }
}

