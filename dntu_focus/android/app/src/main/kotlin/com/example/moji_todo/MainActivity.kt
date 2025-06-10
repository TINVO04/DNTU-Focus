package com.example.moji_todo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.content.ComponentName
import android.accessibilityservice.AccessibilityServiceInfo
import android.util.Log
import android.view.accessibility.AccessibilityManager
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import android.Manifest
import androidx.core.app.ActivityCompat
import android.content.Context
import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Bundle

class MainActivity : FlutterActivity() {
    private val PERMISSION_CHANNEL = "com.example.moji_todo/permissions"
    private val SERVICE_CHANNEL = "com.example.moji_todo/app_block_service"
    private val NOTIFICATION_CHANNEL = "com.example.moji_todo/notification"
    private val EVENT_CHANNEL = "com.example.moji_todo/timer_events"
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private val REQUEST_NOTIFICATION_PERMISSION = 1001
    private val REQUEST_IGNORE_BATTERY_OPTIMIZATIONS = 1002

    companion object {
        var timerEvents: EventChannel.EventSink? = null
        const val TIMER_NOTIFICATION_ID = TimerService.TIMER_NOTIFICATION_ID
        const val SESSION_END_NOTIFICATION_ID = 101
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val mgr = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // --- channel timer (unchanged) ---
            val timerChannel = NotificationChannel(
                "timer_channel_id",
                "Timer Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Pomodoro timer running"
                setSound(null, null)    // im lặng
                enableVibration(false)
            }
            mgr.createNotificationChannel(timerChannel)

            // --- channel có âm thanh (đã xóa setSound) ---
            val soundChannel = NotificationChannel(
                "pomodoro_channel",
                "Pomodoro Session End",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Session end with sound"
                // Xóa setSound để âm thanh được quyết định bởi Flutter
                enableVibration(true)
            }
            mgr.createNotificationChannel(soundChannel)

            // --- channel im lặng ---
            val silentChannel = NotificationChannel(
                "pomodoro_channel_silent",
                "Pomodoro Session End (Silent)",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Session end without sound"
                setSound(null, null)    // IM LẶNG
                enableVibration(false)
            }
            mgr.createNotificationChannel(silentChannel)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        checkAndRequestNotificationPermission()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityPermissionEnabled" -> {
                    val isEnabled = isAccessibilityServiceEnabled()
                    Log.d("MainActivity", "isAccessibilityPermissionEnabled: $isEnabled")
                    result.success(isEnabled)
                }
                "requestAccessibilityPermission" -> {
                    Log.d("MainActivity", "Requesting accessibility permission")
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(null)
                }
                "openAppSettings" -> {
                    val uri = call.arguments<Map<String, Any>>()?.get("uri") as String?
                    if (uri != null) {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.parse(uri)
                        }
                        startActivity(intent)
                        result.success(null)
                    } else {
                        result.error("INVALID_URI", "URI is null", null)
                    }
                }
                "checkIgnoreBatteryOptimizations" -> {
                    val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                    val isIgnoringBatteryOptimizations = powerManager.isIgnoringBatteryOptimizations(packageName)
                    Log.d("MainActivity", "checkIgnoreBatteryOptimizations: $isIgnoringBatteryOptimizations")
                    result.success(isIgnoringBatteryOptimizations)
                }
                "requestIgnoreBatteryOptimizations" -> {
                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                        data = Uri.parse("package:$packageName")
                    }
                    startActivityForResult(intent, REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SERVICE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setBlockedApps" -> {
                    val apps = call.argument<List<String>>("apps")
                    Log.d("MainActivity", "setBlockedApps called with apps: $apps")
                    if (apps != null) {
                        AppBlockService.setBlockedApps(apps.toSet())
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Blocked apps list is null", null)
                    }
                }
                "setAppBlockingEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    Log.d("MainActivity", "setAppBlockingEnabled called with enabled: $enabled")
                    AppBlockService.setAppBlockingEnabled(enabled)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startTimerService" -> {
                    try {
                        val arguments = call.arguments as? Map<*, *> ?: mapOf<String, Any>()
                        val action = arguments["action"] as? String ?: ""
                        val timerSeconds = (arguments["timerSeconds"] as? Number)?.toInt() ?: 0
                        val isRunning = (arguments["isRunning"] as? Boolean ?: false)
                        val isPaused = (arguments["isPaused"] as? Boolean ?: false)
                        val isCountingUp = (arguments["isCountingUp"] as? Boolean ?: false)
                        val isWorkSession = (arguments["isWorkSession"] as? Boolean ?: true)

                        Log.d("MainActivity", "startTimerService: action=$action, timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused, isCountingUp=$isCountingUp, isWorkSession=$isWorkSession")

                        val serviceIntent = Intent(this, TimerService::class.java).apply {
                            this.action = action
                            putExtra("timerSeconds", timerSeconds)
                            putExtra("isRunning", isRunning)
                            putExtra("isPaused", isPaused)
                            putExtra("isCountingUp", isCountingUp)
                            putExtra("isWorkSession", isWorkSession)
                        }

                        if (action == "START") {
                            NotificationManagerCompat.from(this).cancel(TIMER_NOTIFICATION_ID)
                            Log.d("MainActivity", "Cancelled notification on START action.")
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(serviceIntent)
                        } else {
                            startService(serviceIntent)
                        }
                        Log.d("MainActivity", "Sent intent to TimerService with action: ${serviceIntent.action}")

                        result.success(null)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error in startTimerService: ${e.message}")
                        result.error("ERROR", e.message, null)
                    }
                }
                "getTimerState" -> {
                    val prefs = getSharedPreferences("FlutterSharedPref", Context.MODE_PRIVATE)
                    val state = mapOf(
                        "timerSeconds" to prefs.getInt("timerSeconds", 25 * 60),
                        "isRunning" to prefs.getBoolean("isRunning", false),
                        "isPaused" to prefs.getBoolean("isPaused", false),
                        "isCountingUp" to prefs.getBoolean("isCountingUp", false),
                        "isWorkSession" to prefs.getBoolean("isWorkSession", true)
                    )
                    Log.d("MainActivity", "getTimerState (from SharedPreferences for immediate display): $state")
                    result.success(state)
                }
                TimerService.ACTION_PAUSE, TimerService.ACTION_RESUME, TimerService.ACTION_STOP -> {
                    try {
                        Log.d("MainActivity", "Handling ${call.method} action from Flutter UI")
                        val intent = Intent(this, TimerService::class.java).apply {
                            action = call.method
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        Log.d("MainActivity", "Sent ${call.method} intent to TimerService")

                        result.success(null)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error in ${call.method} action: ${e.message}")
                        result.error("ERROR", e.message, null)
                    }
                }
                "checkNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        val hasPermission = ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.POST_NOTIFICATIONS
                        ) == PackageManager.PERMISSION_GRANTED
                        Log.d("MainActivity", "checkNotificationPermission: $hasPermission")
                        result.success(hasPermission)
                    } else {
                        result.success(true)
                    }
                }
                "cancelNotification" -> {
                    try {
                        val args = call.arguments as? Map<*, *>
                        val id = args?.get("id") as? Int
                        if (id != null) {
                            NotificationManagerCompat.from(this).cancel(id)
                            Log.d("MainActivity", "Cancelled notification with ID $id from Flutter")
                        } else {
                            NotificationManagerCompat.from(this).cancel(TIMER_NOTIFICATION_ID)
                            NotificationManagerCompat.from(this).cancel(SESSION_END_NOTIFICATION_ID)
                            Log.d("MainActivity", "Cancelled all timer/session end notifications from Flutter (no specific ID provided).")
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error cancelling notification: ${e.message}")
                        result.error("ERROR", e.message, null)
                    }
                }
                "setFromNotification" -> {
                    result.success(null)
                }
                "handleNotificationAction" -> {
                    try {
                        val arguments = call.arguments as? Map<*, *> ?: mapOf<String, Any>()
                        val action = arguments["action"] as? String ?: ""
                        Log.d("MainActivity", "Handling notification action from MethodChannel: action=$action")

                        val serviceIntent = Intent(this, TimerService::class.java)
                        when (action) {
                            "pause_action" -> serviceIntent.action = TimerService.ACTION_PAUSE
                            "resume_action" -> serviceIntent.action = TimerService.ACTION_RESUME
                            "stop_action" -> serviceIntent.action = TimerService.ACTION_STOP
                            else -> {
                                Log.w("MainActivity", "Unknown notification action: $action")
                                result.notImplemented()
                                return@setMethodCallHandler
                            }
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(serviceIntent)
                        } else {
                            startService(serviceIntent)
                        }
                        Log.d("MainActivity", "Sent ${serviceIntent.action} intent to TimerService for notification action")
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error handling notification action: ${e.message}")
                        result.error("ERROR", e.message, null)
                    }
                }
                "handleNotificationIntent" -> {
                    val arguments = call.arguments as? Map<*, *> ?: mapOf<String, Any>()
                    val flutterNotificationPayload = arguments["Flutter_notification_payload"] as? String

                    Log.d("MainActivity", "handleNotificationIntent (from Flutter): payload=$flutterNotificationPayload")

                    NotificationManagerCompat.from(this).cancel(SESSION_END_NOTIFICATION_ID)

                    when (flutterNotificationPayload) {
                        "START_BREAK" -> {
                            methodChannel?.invokeMethod("startBreak", null)
                            Log.d("MainActivity", "Invoked startBreak on Flutter from notification tap.")
                        }
                        "START_WORK" -> {
                            methodChannel?.invokeMethod("startWork", null)
                            Log.d("MainActivity", "Invoked startWork on Flutter via handleNotificationIntent.")
                        }
                        "COMPLETED_ALL_SESSIONS" -> {
                            methodChannel?.invokeMethod("completedAllSessions", null)
                            Log.d("MainActivity", "Invoked completedAllSessions on Flutter via handleNotificationIntent.")
                        }
                        else -> {
                            Log.d("MainActivity", "Generic notification tap, HomeCubit will restore state automatically.")
                        }
                    }
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
        eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                timerEvents = events
                Log.d("MainActivity", "EventChannel listener started. Waiting for TimerService to emit state.")
            }

            override fun onCancel(arguments: Any?) {
                timerEvents = null
                Log.d("MainActivity", "EventChannel listener cancelled")
            }
        })

        handleNotificationIntent(intent)
    }

    private fun checkAndRequestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val hasPermission = ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
            Log.d("MainActivity", "Initial checkNotificationPermission: $hasPermission")
            if (!hasPermission) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    REQUEST_NOTIFICATION_PERMISSION
                )
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_IGNORE_BATTERY_OPTIMIZATIONS) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            val isIgnoringBatteryOptimizations = powerManager.isIgnoringBatteryOptimizations(packageName)
            methodChannel?.invokeMethod("ignoreBatteryOptimizationsResult", mapOf("isIgnoring" to isIgnoringBatteryOptimizations))
            Log.d("MainActivity", "ignoreBatteryOptimizationsResult: $isIgnoringBatteryOptimizations")
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_NOTIFICATION_PERMISSION) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            Log.d("MainActivity", "Notification permission result: granted=$granted")
            methodChannel?.invokeMethod("notificationPermissionResult", granted)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleNotificationIntent(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("MainActivity", "No need to unregister manifest-declared receivers.")

        NotificationManagerCompat.from(this).cancel(TIMER_NOTIFICATION_ID)
        NotificationManagerCompat.from(this).cancel(SESSION_END_NOTIFICATION_ID)
        Log.d("MainActivity", "MainActivity destroyed, all relevant notifications cancelled.")
    }

    private fun handleNotificationIntent(intent: Intent?) {
        Log.d("MainActivity", "Handling intent with action: ${intent?.action}, extras: ${intent?.extras}")

        val flutterNotificationPayload = intent?.extras?.getString("Flutter_notification_payload")
        Log.d("MainActivity", "handleNotificationIntent - Flutter_notification_payload: $flutterNotificationPayload")
        Log.d("MainActivity", "handleNotificationIntent - Intent Action: ${intent?.action}")

        val isAppOpenFromFlutterNotification = (flutterNotificationPayload != null &&
                (flutterNotificationPayload == "open_app" || flutterNotificationPayload == "START_BREAK" ||
                        flutterNotificationPayload == "START_WORK" || flutterNotificationPayload == "COMPLETED_ALL_SESSIONS")) ||
                (intent?.getBooleanExtra("fromNotification", false) == true && intent.action != "com.example.moji_todo.SESSION_END_ACTIVATED")

        val isSessionEndBroadcastIntent = intent?.action == "com.example.moji_todo.SESSION_END_ACTIVATED"

        if (isAppOpenFromFlutterNotification || isSessionEndBroadcastIntent) {
            Log.d("MainActivity", "App opened from notification OR session end broadcast detected. Action: ${intent?.action}, Payload: $flutterNotificationPayload")

            NotificationManagerCompat.from(this).cancel(TIMER_NOTIFICATION_ID)
            NotificationManagerCompat.from(this).cancel(SESSION_END_NOTIFICATION_ID)
            Log.d("MainActivity", "Cancelled timer and session end notifications on app open/session end.")

            if (isSessionEndBroadcastIntent) {
                val isWorkSession = intent?.getBooleanExtra("isWorkSession", true) ?: true
                try {
                    methodChannel?.invokeMethod("onSessionEnded", mapOf("isWorkSession" to isWorkSession))
                    Log.d("MainActivity", "Invoked onSessionEnded on Flutter from broadcast intent: isWorkSession=$isWorkSession")
                } catch (e: Exception) {
                    Log.e("MainActivity", "Error invoking onSessionEnded on Flutter from broadcast intent: ${e.message}")
                }
            } else if (isAppOpenFromFlutterNotification) {
                when (flutterNotificationPayload) {
                    "START_BREAK" -> {
                        methodChannel?.invokeMethod("startBreak", null)
                        Log.d("MainActivity", "Invoked startBreak on Flutter from notification tap.")
                    }
                    "START_WORK" -> {
                        methodChannel?.invokeMethod("startWork", null)
                        Log.d("MainActivity", "Invoked startWork on Flutter via handleNotificationIntent.")
                    }
                    "COMPLETED_ALL_SESSIONS" -> {
                        methodChannel?.invokeMethod("completedAllSessions", null)
                        Log.d("MainActivity", "Invoked completedAllSessions on Flutter via handleNotificationIntent.")
                    }
                    else -> {
                        Log.d("MainActivity", "Generic notification tap, HomeCubit will restore state automatically.")
                    }
                }
            }
            return
        }

        val flutterActionId = intent?.getStringExtra("action")
        if (flutterActionId != null) {
            Log.d("MainActivity", "Handling Flutter notification action ID: $flutterActionId")
            val serviceIntent = Intent(this, TimerService::class.java)
            when (flutterActionId) {
                "pause_action" -> serviceIntent.action = TimerService.ACTION_PAUSE
                "resume_action" -> serviceIntent.action = TimerService.ACTION_RESUME
                "stop_action" -> serviceIntent.action = TimerService.ACTION_STOP
                else -> {
                    Log.w("MainActivity", "Unknown notification action ID: $flutterActionId")
                    return
                }
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
            } else {
                startService(serviceIntent)
            }
            Log.d("MainActivity", "Sent ${serviceIntent.action} intent to TimerService for notification action ID.")
            return
        }

        Log.d("MainActivity", "No specific intent handler found for this intent. Defaulting to state restoration on EventChannel listen.")
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val accessibilityManager = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val expectedComponentName = ComponentName(this, AppBlockService::class.java)
        val enabledServices = accessibilityManager.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
        val isEnabled = enabledServices.any { service ->
            service.resolveInfo.serviceInfo.packageName == expectedComponentName.packageName
        }
        Log.d("MainActivity", "isAccessibilityServiceEnabled: $isEnabled")
        return isEnabled
    }
}