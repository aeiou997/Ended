package com.ended.app

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent

/**
 * Optional Accessibility Service for detecting short-form video app usage.
 * 
 * LIMITATIONS (critically important):
 * ─────────────────────────────────
 * 1. This service can detect when supported apps are in the foreground
 *    via window state change events.
 * 
 * 2. It CANNOT reliably read or extract unique video/reel IDs from
 *    Instagram, YouTube, Facebook, or Snapchat. These apps use
 *    dynamic, obfuscated view hierarchies that change with every update.
 * 
 * 3. It CANNOT determine the content of a video being watched.
 * 
 * 4. What it CAN do:
 *    - Detect when a supported app is opened (MOVE_TO_FOREGROUND)
 *    - Detect when the user switches between apps
 *    - Estimate session duration based on foreground time
 * 
 * 5. PRIVACY:
 *    - canRetrieveWindowContent is set to FALSE in the config
 *    - We never read any node content
 *    - We only track package names and event timestamps
 * 
 * USAGE: The user must manually enable this service in Settings → 
 * Accessibility → Ended. The app provides clear instructions.
 */
class EndedAccessibilityService : AccessibilityService() {

    companion object {
        const val METHOD_CHANNEL = "com.ended.app/monitoring"
        val SUPPORTED_PACKAGES = setOf(
            "com.instagram.android",
            "com.google.android.youtube",
            "com.facebook.katana",
            "com.snapchat.android"
        )
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                val packageName = event.packageName?.toString() ?: return
                
                if (SUPPORTED_PACKAGES.contains(packageName)) {
                    // A supported app window is now active
                    reportEvent("app_foreground", packageName, 0L)
                }
            }
        }
    }

    override fun onInterrupt() {
        // Service interrupted — no action needed
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        // Service is now active
    }

    private fun reportEvent(eventType: String, packageName: String, durationMs: Long) {
        try {
            val engine = io.flutter.embedding.engine.FlutterEngineCache
                .getInstance().get("main_engine")
            engine?.let {
                io.flutter.plugin.common.MethodChannel(
                    it.dartExecutor.binaryMessenger, METHOD_CHANNEL
                ).invokeMethod("onUsageEvent", mapOf(
                    "eventType" to eventType,
                    "packageName" to packageName,
                    "durationMs" to durationMs
                ))
            }
        } catch (e: Exception) {
            // Flutter engine may not be available
        }
    }
}
