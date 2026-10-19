package com.epsilon.app.epsilon

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.PowerManager
import androidx.core.app.NotificationCompat

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getStringExtra("id") ?: "epsilon_alarm"
        val title = intent.getStringExtra("title") ?: "Epsilon Contest Reminder"
        val message = intent.getStringExtra("message") ?: "Your contest is starting soon!"

        // Briefly acquire wake lock to ensure the notification heads-up shows
        try {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
            val wakeLock = powerManager?.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "Epsilon:AlarmWakeLock"
            )
            wakeLock?.acquire(10000)
        } catch (_: Exception) {
            // Ignore wake lock issues if restricted
        }

        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val channelId = "epsilon_contest_alarms"
        val alarmSound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)

        val vibrationPattern = longArrayOf(0, 500, 200, 500, 200, 500)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_ALARM)
                .build()

            val channel = NotificationChannel(
                channelId,
                "Contest Alarms & Reminders",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "High-priority alarms for scheduled contests and timers"
                enableVibration(true)
                setVibrationPattern(vibrationPattern)
                setSound(alarmSound, audioAttributes)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }
            notificationManager.createNotificationChannel(channel)
        }

        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("event_id", id)
        }
        val contentPendingIntent = PendingIntent.getActivity(
            context,
            id.hashCode(),
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setSound(alarmSound)
            .setVibrate(vibrationPattern)
            .setAutoCancel(true)
            .setContentIntent(contentPendingIntent)
            .setFullScreenIntent(contentPendingIntent, true)
            .build()

        notificationManager.notify(id.hashCode(), notification)
    }
}

