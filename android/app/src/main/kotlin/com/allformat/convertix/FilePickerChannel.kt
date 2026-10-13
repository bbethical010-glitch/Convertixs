package com.allformat.convertix

import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.MediaStore

class FilePickerChannel(private val activity: Activity) {

    private val prefs = activity.getSharedPreferences(
        "convertix_source_prefs", Context.MODE_PRIVATE
    )

    fun launchPicker(
        toolName: String,
        mimeType: String,
        allowMultiple: Boolean,
        requestCode: Int
    ) {
        val prefKey = "pref_source_$toolName"
        val remembered = prefs.getString(prefKey, null) ?: prefs.getString("source_$toolName", null)

        if (remembered != null) {
            val cn = ComponentName.unflattenFromString(remembered)
            if (cn != null && isAppInstalled(cn.packageName)) {
                val directIntent = buildPickIntent(mimeType, allowMultiple).apply {
                    setPackage(cn.packageName)
                }
                try {
                    activity.startActivityForResult(directIntent, requestCode)
                    return
                } catch (e: Exception) {
                    // Direct launch failed (e.g. app uninstalled or activity disabled), clear preference and fall back to chooser
                    prefs.edit().remove(prefKey).remove("source_$toolName").apply()
                }
            } else {
                // App uninstalled or invalid component — clear preference
                prefs.edit().remove(prefKey).remove("source_$toolName").apply()
            }
        }

        // Show native Android Intent Resolver / Chooser
        val baseIntent = buildPickIntent(mimeType, allowMultiple)

        val receiverIntent = Intent(activity, ChooserReceiver::class.java).apply {
            putExtra("toolName", toolName)
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_MUTABLE
        } else {
            android.app.PendingIntent.FLAG_UPDATE_CURRENT
        }
        val piRequestCode = (toolName.hashCode() and 0x7FFF) + 1000
        val pendingIntent = android.app.PendingIntent.getBroadcast(
            activity,
            piRequestCode,
            receiverIntent,
            flags
        )
        val chooser = Intent.createChooser(baseIntent, "Select file", pendingIntent.intentSender)

        // Augment media tools with ACTION_PICK for OEM Gallery apps if not in GET_CONTENT
        val extraIntents = mutableListOf<Intent>()
        if (mimeType.startsWith("image/")) {
            val pickIntent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI).apply {
                type = mimeType
                if (allowMultiple) putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            }
            val getContentPackages = queryActivities(baseIntent)
                .map { it.activityInfo.packageName }
                .toSet()
            val pickActivities = queryActivities(pickIntent)
            for (res in pickActivities) {
                val pkg = res.activityInfo.packageName
                if (!getContentPackages.contains(pkg)) {
                    val target = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI).apply {
                        type = mimeType
                        setPackage(pkg)
                        if (allowMultiple) putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                    }
                    extraIntents.add(target)
                }
            }
        } else if (mimeType.startsWith("video/")) {
            val pickIntent = Intent(Intent.ACTION_PICK, MediaStore.Video.Media.EXTERNAL_CONTENT_URI).apply {
                type = mimeType
                if (allowMultiple) putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            }
            val getContentPackages = queryActivities(baseIntent)
                .map { it.activityInfo.packageName }
                .toSet()
            val pickActivities = queryActivities(pickIntent)
            for (res in pickActivities) {
                val pkg = res.activityInfo.packageName
                if (!getContentPackages.contains(pkg)) {
                    val target = Intent(Intent.ACTION_PICK, MediaStore.Video.Media.EXTERNAL_CONTENT_URI).apply {
                        type = mimeType
                        setPackage(pkg)
                        if (allowMultiple) putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                    }
                    extraIntents.add(target)
                }
            }
        }

        if (extraIntents.isNotEmpty()) {
            chooser.putExtra(Intent.EXTRA_INITIAL_INTENTS, extraIntents.toTypedArray())
        }

        activity.startActivityForResult(chooser, requestCode)
    }

    fun onPickResult(toolName: String, resultData: Intent?) {
        val component = resultData?.resolveActivity(activity.packageManager)
        if (component != null && component.packageName != "android") {
            prefs.edit()
                .putString("pref_source_$toolName", component.flattenToString())
                .apply()
        }
    }

    fun getPreferences(): Map<String, String> {
        val result = mutableMapOf<String, String>()
        for ((key, value) in prefs.all) {
            val toolName = when {
                key.startsWith("pref_source_") -> key.removePrefix("pref_source_")
                key.startsWith("source_") -> key.removePrefix("source_")
                else -> null
            } ?: continue
            val compStr = value as? String ?: continue
            val cn = ComponentName.unflattenFromString(compStr)
            val label = cn?.let { getAppLabel(it.packageName) } ?: "Unknown"
            result[toolName] = label
        }
        return result
    }

    fun resetPreference(toolName: String) {
        prefs.edit()
            .remove("pref_source_$toolName")
            .remove("source_$toolName")
            .apply()
    }

    fun resetAllPreferences() {
        val editor = prefs.edit()
        for (key in prefs.all.keys) {
            if (key.startsWith("pref_source_") || key.startsWith("source_")) {
                editor.remove(key)
            }
        }
        editor.apply()
    }

    private fun buildPickIntent(mimeType: String, allowMultiple: Boolean): Intent {
        return Intent(Intent.ACTION_GET_CONTENT).apply {
            if (mimeType.contains(",")) {
                type = "*/*"
                putExtra(Intent.EXTRA_MIME_TYPES, mimeType.split(",").toTypedArray())
            } else {
                type = mimeType
            }
            addCategory(Intent.CATEGORY_OPENABLE)
            if (allowMultiple) {
                putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun queryActivities(intent: Intent): List<android.content.pm.ResolveInfo> {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                activity.packageManager.queryIntentActivities(
                    intent,
                    PackageManager.ResolveInfoFlags.of(0)
                )
            } else {
                activity.packageManager.queryIntentActivities(intent, 0)
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    @Suppress("DEPRECATION")
    private fun isAppInstalled(packageName: String): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                activity.packageManager.getPackageInfo(
                    packageName,
                    PackageManager.PackageInfoFlags.of(0)
                )
            } else {
                activity.packageManager.getPackageInfo(packageName, 0)
            }
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    @Suppress("DEPRECATION")
    private fun getAppLabel(packageName: String): String {
        return try {
            val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                activity.packageManager.getApplicationInfo(
                    packageName,
                    PackageManager.ApplicationInfoFlags.of(0)
                )
            } else {
                activity.packageManager.getApplicationInfo(packageName, 0)
            }
            activity.packageManager.getApplicationLabel(info).toString()
        } catch (e: Exception) {
            packageName
        }
    }
}
