package com.kidzone.kidzone

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val channelName = "kidzone/usage_stats"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPermission" -> result.success(hasUsagePermission())
                    "openSettings" -> {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(null)
                    }
                    "todayUsage" -> result.success(todayUsage())
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasUsagePermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    packageName,
                )
            } else {
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    packageName,
                )
            }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun todayUsage(): Map<String, Any> {
        if (!hasUsagePermission()) {
            return mapOf("totalMinutes" to 0, "apps" to emptyList<Map<String, Any>>())
        }
        val manager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val start =
            Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }.timeInMillis
        val stats =
            manager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                start,
                System.currentTimeMillis(),
            ) ?: emptyList()
        val apps =
            stats
                .filter { it.totalTimeInForeground > 60_000L }
                .sortedByDescending { it.totalTimeInForeground }
                .take(6)
                .map { stat ->
                    val label =
                        try {
                            val info = packageManager.getApplicationInfo(stat.packageName, 0)
                            packageManager.getApplicationLabel(info).toString()
                        } catch (_: Exception) {
                            stat.packageName.substringAfterLast('.')
                        }
                    mapOf(
                        "name" to label,
                        "minutes" to (stat.totalTimeInForeground / 60_000L).toInt(),
                    )
                }
        val totalMinutes = (stats.sumOf { it.totalTimeInForeground } / 60_000L).toInt()
        return mapOf("totalMinutes" to totalMinutes, "apps" to apps)
    }
}
