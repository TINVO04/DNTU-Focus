package com.example.moji_todo

import android.Manifest
import android.annotation.SuppressLint
import android.app.Service
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context

interface TimerStrategy {
    fun tick(currentSeconds: Int): Int
    fun getDisplayText(seconds: Int, isRunning: Boolean, isPaused: Boolean): String
}

class CountUpStrategy : TimerStrategy {
    override fun tick(currentSeconds: Int): Int = currentSeconds + 1
    override fun getDisplayText(seconds: Int, isRunning: Boolean, isPaused: Boolean): String {
        val minutes = (seconds / 60).toString().padStart(2, '0')
        val secondsStr = (seconds % 60).toString().padStart(2, '0')
        val status = if (isRunning) if (isPaused) "Paused" else "Counting Up" else "Stopped"
        return "激烈: $minutes:$secondsStr ($status)"
    }
}

class CountDownStrategy : TimerStrategy {
    override fun tick(currentSeconds: Int): Int = if (currentSeconds > 0) currentSeconds - 1 else 0
    override fun getDisplayText(seconds: Int, isRunning: Boolean, isPaused: Boolean): String {
        val minutes = (seconds / 60).toString().padStart(2, '0')
        val secondsStr = (seconds % 60).toString().padStart(2, '0')
        val status = if (isRunning) if (isPaused) "Paused" else "Running" else "Stopped"
        return "激烈: $minutes:$secondsStr ($status)"
    }
}

data class TimerState(
    val timerSeconds: Int,
    val isRunning: Boolean,
    val isPaused: Boolean,
    val isCountingUp: Boolean,
    val isWorkSession: Boolean
)

class TimerService : Service() {
    companion object {
        const val ACTION_PAUSE = "com.example.moji_todo.PAUSE"
        const val ACTION_RESUME = "com.example.moji_todo.RESUME"
        const val ACTION_STOP = "com.example.moji_todo.STOP"
        const val ACTION_OPEN_APP = "com.example.moji_todo.OPEN_APP"
        const val ACTION_GET_STATE = "GET_STATE"
        const val TIMER_NOTIFICATION_ID = 100
        const val ACTION_SESSION_END = "com.example.moji_todo.SESSION_END"
    }

    private var timerSeconds: Int = 0
    private var isRunning: Boolean = false
    private var isPaused: Boolean = false
    private var isCountingUp: Boolean = false
    private var isServiceRunning: Boolean = false
    private var hasEnded: Boolean = false
    private var isWorkSession: Boolean = true
    private var hasSentEndNotification: Boolean = false

    private lateinit var timerStrategy: TimerStrategy
    private val handler = Handler(Looper.getMainLooper())
    private var timerRunnable: Runnable? = null
    private val timerStateFlow = MutableStateFlow(TimerState(0, false, false, false, true))
    private val coroutineScope = CoroutineScope(Dispatchers.Main)

    override fun onCreate() {
        super.onCreate()
        Log.d("TimerService", "Service created")

        val prefs = getSharedPreferences("FlutterSharedPref", Context.MODE_PRIVATE)
        timerSeconds = prefs.getInt("timerSeconds", 25 * 60)
        isRunning = prefs.getBoolean("isRunning", false)
        isPaused = prefs.getBoolean("isPaused", false)
        isCountingUp = prefs.getBoolean("isCountingUp", false)
        isWorkSession = prefs.getBoolean("isWorkSession", true)
        // hasEnded và hasSentEndNotification cũng có thể được load ở đây
        hasEnded = prefs.getBoolean("hasEnded", false)
        hasSentEndNotification = prefs.getBoolean("hasSentEndNotification", false)

        timerStrategy = if (isCountingUp) CountUpStrategy() else CountDownStrategy()

        // Chỉ bắt đầu foreground service nếu timer đang chạy hoặc tạm dừng
        if (isRunning && !isPaused || isPaused) {
            startForegroundService()
        }

        coroutineScope.launch {
            timerStateFlow.collect { state ->
                try {
                    if (MainActivity.timerEvents == null) {
                        Log.w("TimerService", "timerEvents is null, cannot emit state")
                    } else {
                        MainActivity.timerEvents?.success(
                            mapOf(
                                "timerSeconds" to state.timerSeconds,
                                "isRunning" to state.isRunning,
                                "isPaused" to state.isPaused,
                                "isCountingUp" to state.isCountingUp,
                                "isWorkSession" to state.isWorkSession
                            )
                        )
                    }
                } catch (e: Exception) {
                    Log.e("TimerService", "Error emitting StateFlow: ${e.message}")
                }
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("TimerService", "Received intent: ${intent?.action}, extras: ${intent?.extras}")

        val prefs = getSharedPreferences("FlutterSharedPref", Context.MODE_PRIVATE)
        // Load trạng thái mới nhất từ SharedPreferences
        timerSeconds = prefs.getInt("timerSeconds", timerSeconds)
        isRunning = prefs.getBoolean("isRunning", isRunning)
        isPaused = prefs.getBoolean("isPaused", isPaused)
        isCountingUp = prefs.getBoolean("isCountingUp", isCountingUp)
        isWorkSession = prefs.getBoolean("isWorkSession", isWorkSession)
        hasEnded = prefs.getBoolean("hasEnded", hasEnded)
        hasSentEndNotification = prefs.getBoolean("hasSentEndNotification", hasSentEndNotification)

        timerStrategy = if (isCountingUp) CountUpStrategy() else CountDownStrategy()

        // Logic điều khiển Foreground Service
        // Nếu Service được lệnh START/RESUME hoặc đã đang chạy/tạm dừng, thì bắt đầu Foreground
        val shouldBeForeground = isRunning || isPaused || intent?.action == "START" || intent?.action == ACTION_RESUME
        if (shouldBeForeground && !isServiceRunning) {
            startForegroundService()
        } else if (!shouldBeForeground && isServiceRunning) {
            // Nếu không cần chạy foreground nữa và đang chạy foreground, thì dừng foreground nhưng không dừng service
            stopForeground(STOP_FOREGROUND_DETACH) // Giữ notification nhưng gỡ khỏi foreground
            NotificationManagerCompat.from(this).cancel(TIMER_NOTIFICATION_ID) // Hủy hẳn notification
            isServiceRunning = false
        }


        when (intent?.action) {
            "START" -> {
                hasEnded = false
                hasSentEndNotification = false

                if (isRunning && !isPaused && timerSeconds > 0) {
                    Log.d("TimerService", "Timer already running, ignoring START.")
                    updateTimerState()
                    return START_STICKY
                }

                timerSeconds = intent.getIntExtra("timerSeconds", 25 * 60)
                isRunning = intent.getBooleanExtra("isRunning", true)
                isPaused = intent.getBooleanExtra("isPaused", false)
                isCountingUp = intent.getBooleanExtra("isCountingUp", false)
                isWorkSession = intent.getBooleanExtra("isWorkSession", true)
                timerStrategy = if (isCountingUp) CountUpStrategy() else CountDownStrategy()

                Log.d("TimerService", "START: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused, isCountingUp=$isCountingUp, isWorkSession=$isWorkSession")

                startTimer() // startTimer sẽ gọi updateTimerState -> updateNotification -> startForegroundService
                updateTimerState() // Đảm bảo trạng thái được emit ngay lập tức
            }
            "UPDATE" -> {
                hasEnded = false
                hasSentEndNotification = false

                timerSeconds = intent.getIntExtra("timerSeconds", timerSeconds)
                isRunning = intent.getBooleanExtra("isRunning", isRunning)
                isPaused = intent.getBooleanExtra("isPaused", isPaused)
                isCountingUp = intent.getBooleanExtra("isCountingUp", isCountingUp)
                isWorkSession = intent.getBooleanExtra("isWorkSession", isWorkSession)
                timerStrategy = if (isCountingUp) CountUpStrategy() else CountDownStrategy()

                Log.d("TimerService", "UPDATE: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused, isCountingUp=$isCountingUp, isWorkSession=$isWorkSession")

                if (isRunning && !isPaused) {
                    startTimer() // Sẽ gọi updateTimerState và startForegroundService
                } else {
                    stopTimer() // Sẽ chỉ dừng runnable và updateNotification
                }
                updateTimerState()
            }
            ACTION_PAUSE -> {
                Log.d("TimerService", "PAUSE action received")
                if (isRunning && !isPaused) {
                    isRunning = false
                    isPaused = true
                    stopTimer()
                    updateTimerState()
                    Log.d("TimerService", "Timer paused: timerSeconds=$timerSeconds")
                } else {
                    Log.d("TimerService", "Ignoring PAUSE: isRunning=$isRunning, isPaused=$isPaused")
                    updateNotification()
                }
            }
            ACTION_RESUME -> {
                Log.d("TimerService", "RESUME action received")
                if (isPaused) {
                    isPaused = false
                    isRunning = true
                    startTimer() // Sẽ gọi updateTimerState và startForegroundService
                    updateTimerState()
                    Log.d("TimerService", "Timer resumed: timerSeconds=$timerSeconds")
                } else {
                    Log.d("TimerService", "Ignoring RESUME: isRunning=$isRunning, isPaused=$isPaused")
                    updateNotification()
                }
            }
            ACTION_STOP -> {
                Log.d("TimerService", "STOP action received")
                isRunning = false
                isPaused = false
                timerSeconds = if (isCountingUp) 0 else 25 * 60
                timerStrategy = if (isCountingUp) CountUpStrategy() else CountDownStrategy()
                hasEnded = false
                hasSentEndNotification = false
                stopTimer() // Dừng runnable
                stopForeground(STOP_FOREGROUND_REMOVE) // Gỡ khỏi foreground và hủy notification
                NotificationManagerCompat.from(this).cancel(TIMER_NOTIFICATION_ID) // Hủy notification một lần nữa cho chắc
                isServiceRunning = false // Đặt cờ thành false
                Log.d("TimerService", "Timer stopped and stopping self.")
                stopSelf() // Dừng service hoàn toàn
                updateTimerState() // Cập nhật trạng thái cuối cùng
            }
            ACTION_OPEN_APP -> {
                Log.d("TimerService", "OPEN_APP action received. Requesting state update for Flutter UI.")
                NotificationManagerCompat.from(this).cancel(TIMER_NOTIFICATION_ID)
                updateTimerState()
                // Nếu timer không chạy/tạm dừng, service không cần chạy foreground.
                // Không gọi stopSelf() ở đây để tránh crash nếu có nhiều lệnh start/get_state liên tiếp.
                // Logic shouldBeForeground ở trên đầu onStartCommand đã xử lý việc dừng foreground.
            }
            ACTION_GET_STATE -> {
                Log.d("TimerService", "GET_STATE action received, emitting current state.")
                updateTimerState()
                // Nếu timer không chạy/tạm dừng, service không cần chạy foreground.
                // Không gọi stopSelf() ở đây.
            }
            else -> {
                Log.d("TimerService", "Unknown or null intent action received: ${intent?.action}")
                updateTimerState()
                // Nếu không có action cụ thể và timer không chạy/tạm dừng, service không cần chạy foreground.
                // Logic shouldBeForeground ở trên đầu onStartCommand đã xử lý việc dừng foreground.
            }
        }
        return START_STICKY
    }

    @SuppressLint("MissingPermission")
    private fun startForegroundService() {
        if (!isServiceRunning) { // Chỉ gọi startForeground nếu chưa chạy foreground
            try {
                val notification = getNotificationBuilder().build() // Lấy notification ban đầu

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                    ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                    Log.w("TimerService", "POST_NOTIFICATIONS permission not granted, cannot start foreground service. Stopping self.")
                    stopSelf() // Nếu không có quyền, không thể chạy foreground, nên dừng service.
                    return
                }
                startForeground(TIMER_NOTIFICATION_ID, notification)
                isServiceRunning = true // Đặt cờ là service đang chạy foreground
                Log.d("TimerService", "Foreground service started with minimal notification. isServiceRunning = $isServiceRunning")
            } catch (e: SecurityException) {
                Log.e("TimerService", "SecurityException in startForegroundService: ${e.message}. Stopping self.")
                stopSelf()
            } catch (e: Exception) {
                Log.e("TimerService", "Failed to start foreground service: ${e.message}. Stopping self.")
                stopSelf()
            }
        } else {
            Log.d("TimerService", "Foreground service already running. No need to call startForegroundService again.")
            // Nếu đã chạy foreground, chỉ cần cập nhật notification
            updateNotification()
        }
    }

    private fun getNotificationBuilder(): NotificationCompat.Builder {
        val minutes = (timerSeconds / 60).toString().padStart(2, '0')
        val secondsStr = (timerSeconds % 60).toString().padStart(2, '0')
        val status = if (isRunning) (if (isPaused) "Paused" else "Running") else "Stopped"
        val title = "Pomodoro Timer"
        val contentText = "Time: $minutes:$secondsStr ($status)"

        val contentIntent = Intent(this, MainActivity::class.java).apply {
            action = ACTION_OPEN_APP
            putExtra("fromNotification", true)
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val contentPendingIntent = PendingIntent.getActivity(
            this,
            0,
            contentIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, "timer_channel_id")
            .setContentTitle(title)
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.ic_notification_overlay)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setOngoing(isRunning && !isPaused) // Notification is ongoing only when running and not paused
            .setSound(null)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setVibrate(null)
            .setShowWhen(false)
            .setContentIntent(contentPendingIntent)

        if (isRunning && !isPaused) {
            val pauseIntent = Intent(this, TimerService::class.java).apply { action = ACTION_PAUSE }
            val pausePendingIntent = PendingIntent.getService(this, 0, pauseIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            builder.addAction(0, "Pause", pausePendingIntent)
        } else if (isPaused) {
            val resumeIntent = Intent(this, TimerService::class.java).apply { action = ACTION_RESUME }
            val resumePendingIntent = PendingIntent.getService(this, 0, resumeIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            builder.addAction(0, "Resume", resumePendingIntent)
        }

        if (isRunning || isPaused) { // Only show stop button if timer is running or paused
            val stopIntent = Intent(this, TimerService::class.java).apply { action = ACTION_STOP }
            val stopPendingIntent = PendingIntent.getService(this, 1, stopIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            builder.addAction(0, "Stop", stopPendingIntent)
        }
        return builder
    }

    private fun updateNotification() {
        if (isServiceRunning) { // Chỉ cập nhật notification nếu service đang chạy foreground
            val notificationManager = NotificationManagerCompat.from(this)
            val notification = getNotificationBuilder().build()
            notificationManager.notify(TIMER_NOTIFICATION_ID, notification)
            Log.d("TimerService", "Notification updated: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused")
        } else {
            // Nếu service không chạy foreground, hủy notification (nếu có)
            NotificationManagerCompat.from(this).cancel(TIMER_NOTIFICATION_ID)
            Log.d("TimerService", "Notification cancelled (service not foreground).")
        }
    }

    private fun startTimer() {
        stopTimer() // Hủy runnable cũ
        timerRunnable = object : Runnable {
            override fun run() {
                if (isRunning && !isPaused) {
                    timerSeconds = timerStrategy.tick(timerSeconds)

                    if (!isCountingUp && timerSeconds <= 0 && !hasEnded) {
                        hasEnded = true
                        isRunning = false
                        isPaused = false
                        stopTimer() // Dừng runnable
                        NotificationManagerCompat.from(applicationContext).cancel(TIMER_NOTIFICATION_ID) // Hủy notification đếm giờ

                        sendSessionEndBroadcast(isWorkSession) // Gửi broadcast đến MainActivity

                        updateTimerState() // Cập nhật trạng thái cuối cùng
                        Log.d("TimerService", "Timer completed session (work/break). Waiting for Flutter to decide next action.")
                        // Sau khi phiên kết thúc, nếu autoSwitch tắt, service không cần chạy foreground.
                        // Logic shouldBeForeground ở trên đầu onStartCommand sẽ xử lý việc stopForeground.
                        // Không gọi stopSelf() ở đây để HomeCubit có thể xử lý chuyển đổi phiên.
                    } else if (!hasEnded) {
                        updateTimerState()
                        handler.postDelayed(this, 1000)
                    }
                }
            }
        }
        timerRunnable?.let {
            handler.post(it)
            updateTimerState() // Cập nhật trạng thái ban đầu khi bắt đầu timer
            Log.d("TimerService", "Timer started with timerSeconds=$timerSeconds, isCountingUp=$isCountingUp")
            startForegroundService() // Đảm bảo service chạy foreground khi timer bắt đầu
        }
    }

    private fun stopTimer() {
        timerRunnable?.let {
            handler.removeCallbacks(it)
            Log.d("TimerService", "TimerRunnable cancelled successfully")
        }
        timerRunnable = null
        Log.d("TimerService", "Timer stopped")
        // Chỉ dừng runnable và cập nhật notification. Không stopSelf() ở đây.
    }

    private fun updateTimerState() {
        try {
            if (isRunning && isPaused) {
                Log.w("TimerService", "Invalid state: isRunning=true and isPaused=true, correcting to isRunning=false")
                isRunning = false
            }
            timerStateFlow.value = TimerState(timerSeconds, isRunning, isPaused, isCountingUp, isWorkSession)

            val prefs = getSharedPreferences("FlutterSharedPref", Context.MODE_PRIVATE)
            prefs.edit().apply {
                putInt("timerSeconds", timerSeconds)
                putBoolean("isRunning", isRunning)
                putBoolean("isPaused", isPaused)
                putBoolean("isCountingUp", isCountingUp)
                putBoolean("isWorkSession", isWorkSession)
                putBoolean("hasEnded", hasEnded)
                putBoolean("hasSentEndNotification", hasSentEndNotification)
                apply()
            }
            Log.d("TimerService", "Updated state: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused, isCountingUp=$isCountingUp, isWorkSession=$isWorkSession, hasEnded=$hasEnded, hasSentEndNotification=$hasSentEndNotification")

            updateNotification() // Luôn gọi updateNotification sau khi cập nhật trạng thái
        } catch (e: Exception) {
            Log.e("TimerService", "Error updating timer state: ${e.message}")
        }
    }

    private fun sendSessionEndBroadcast(sessionTypeIsWork: Boolean) {
        if (!hasSentEndNotification) {
            val intent = Intent(ACTION_SESSION_END).apply {
                putExtra("isWorkSession", sessionTypeIsWork)
            }
            try {
                val explicitIntent = Intent(intent).apply {
                    component = ComponentName(applicationContext, MainActivity.sessionEndReceiver::class.java)
                }
                sendBroadcast(explicitIntent)
                hasSentEndNotification = true
                Log.d("TimerService", "Sent SESSION_END broadcast: isWorkSession=$sessionTypeIsWork")
            } catch (e: Exception) {
                Log.e("TimerService", "Error sending SESSION_END broadcast: ${e.message}")
            }
        } else {
            Log.d("TimerService", "Session end notification already sent for this session, ignoring.")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopTimer() // Dừng runnable
        stopForeground(STOP_FOREGROUND_REMOVE) // Gỡ khỏi foreground và hủy notification
        NotificationManagerCompat.from(this).cancel(TIMER_NOTIFICATION_ID) // Hủy notification một lần nữa
        isServiceRunning = false // Đặt cờ thành false
        hasSentEndNotification = false
        hasEnded = false
        coroutineScope.cancel()
        Log.d("TimerService", "Service destroyed, all related flags reset, notification cancelled.")
    }

    override fun onBind(intent: Intent?): IBinder? = null
}