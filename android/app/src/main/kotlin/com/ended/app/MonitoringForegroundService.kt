package com.ended.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

/**
 * Foreground service that monitors app usage in the background.
 * 
 * Uses UsageStatsManager to detect when supported short-form video apps
 * are brought to the foreground. Reports events to Flutter via MethodChannel.
 * 
 * PRIVACY NOTE: This service ONLY detects which app package is in the
 * foreground. It does NOT read screen content, capture media, or access
 * any user data within the apps.
 */
class MonitoringForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "ended_monitoring"
        const val CHANNEL_NAME = "Background Monitoring"
        const val NOTIFICATION_ID = 1001
        const val METHOD_CHANNEL = "com.ended.app/monitoring"

        // Supported platforms
        val SUPPORTED_PACKAGES = setOf(
            "com.instagram.android",
            "com.google.android.youtube",
            "com.facebook.katana",
            "com.snapchat.android"
        )
    }

    private var isRunning = false
    private var lastForegroundApp: String? = null
    private var foregroundStartTime: Long = 0L
    private val usageStatsManager by lazy {
        getSystemService(USAGE_STATS_SERVICE) as UsageStatsManager
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!isRunning) {
            isRunning = true
            startForeground(NOTIFICATION_ID, createNotification())
            startMonitoring()
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Ended is monitoring your scrolling habits"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Ended is active")
            .setContentText("Tracking your scrolling awareness")
            .setSmallIcon(android.R.drawable.ic_menu_manage)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    /**
     * Poll UsageStatsManager every 15 seconds to detect foreground app changes.
     */
    private fun startMonitoring() {
        Thread {
            while (isRunning) {
                try {
                    pollUsageStats()
                    Thread.sleep(15_000) // 15 second interval
                } catch (e: InterruptedException) {
                    break
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }.start()
    }

    /**
     * Check which app is currently in the foreground using UsageStatsManager.
     */
    private fun pollUsageStats() {
        val endTime = System.currentTimeMillis()
        val startTime = endTime - 30_000 // Look back 30 seconds

        val events = usageStatsManager.queryEvents(startTime, endTime)
        val event = UsageEvents.Event()

        var currentApp: String? = null

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                currentApp = event.packageName
            }
        }

        // Check if a supported app is in foreground
        if (currentApp != null && SUPPORTED_PACKAGES.contains(currentApp)) {
            if (lastForegroundApp != currentApp) {
                // New supported app came to foreground
                lastForegroundApp = currentApp
                foregroundStartTime = System.currentTimeMillis()
                reportToFlutter("app_foreground", currentApp, 0L)
            }
        } else {
            // User left a supported app
            if (lastForegroundApp != null) {
                val duration = System.currentTimeMillis() - foregroundStartTime
                reportToFlutter("app_background", lastForegroundApp!!, duration)
                lastForegroundApp = null
                foregroundStartTime = 0L
            }
        }
    }

    /**
     * Send event to Flutter via MethodChannel.
     */
    private fun reportToFlutter(eventType: String, packageName: String, durationMs: Long) {
        try {
            val engine = FlutterEngineCache.getInstance().get("main_engine")
            engine?.let {
                MethodChannel(it.dartExecutor.binaryMessenger, METHOD_CHANNEL)
                    .invokeMethod("onUsageEvent", mapOf(
                        "eventType" to eventType,
                        "packageName" to packageName,
                        "durationMs" to durationMs
                    ))
            }
        } catch (e: Exception) {
            // Flutter engine not ready — events will be picked up on next launch
        }
    }
}
