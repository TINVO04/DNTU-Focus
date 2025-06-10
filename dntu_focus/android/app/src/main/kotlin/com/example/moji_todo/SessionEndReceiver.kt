package com.example.moji_todo

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class SessionEndReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("SessionEndReceiver", "Received broadcast: action=${intent.action}")
        if (intent.action == TimerService.ACTION_SESSION_END) {
            val isWorkSession = intent.getBooleanExtra("isWorkSession", true)
            Log.d("SessionEndReceiver", "Processing SESSION_END: isWorkSession=$isWorkSession")
            val mainActivityIntent = Intent(context, MainActivity::class.java).apply {
                action = "com.example.moji_todo.SESSION_END_ACTIVATED"
                putExtra("isWorkSession", isWorkSession)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            context.startActivity(mainActivityIntent)
            Log.d("SessionEndReceiver", "Launched MainActivity for session end")
        }
    }
}
