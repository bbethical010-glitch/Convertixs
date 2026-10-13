package com.allformat.convertix

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build

class ChooserReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val componentName = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_CHOSEN_COMPONENT, ComponentName::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_CHOSEN_COMPONENT)
        }

        val toolName = intent.getStringExtra("toolName")

        if (componentName != null && toolName != null) {
            context.getSharedPreferences("convertix_source_prefs", Context.MODE_PRIVATE)
                .edit()
                .putString("pref_source_$toolName", componentName.flattenToString())
                .apply()
        }
    }
}
