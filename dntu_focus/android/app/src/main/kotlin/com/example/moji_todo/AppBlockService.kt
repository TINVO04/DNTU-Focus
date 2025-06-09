package com.example.moji_todo

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.widget.Toast
import java.util.HashSet

class AppBlockService : AccessibilityService() {
    companion object {
        private val blockedApps = HashSet<String>()
        private var isAppBlockingEnabled = false

        fun setBlockedApps(apps: Set<String>) {
            blockedApps.clear()
            blockedApps.addAll(apps)
        }

        fun setAppBlockingEnabled(enabled: Boolean) {
            isAppBlockingEnabled = enabled
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!isAppBlockingEnabled) return

        val packageName = event?.packageName?.toString() ?: return
        if (blockedApps.contains(packageName)) {
            // Hiển thị thông báo
            Toast.makeText(this, "Ứng dụng bị chặn bởi Strict Mode!", Toast.LENGTH_SHORT).show()

            // Quay lại Moji Todo
            val intent = Intent(Intent.ACTION_MAIN)
            intent.setClassName("com.example.moji_todo", "com.example.moji_todo.MainActivity")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        }
    }

    override fun onInterrupt() {
        // Không cần xử lý
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_ALL_MASK
            notificationTimeout = 100
        }
        this.serviceInfo = info
    }
}