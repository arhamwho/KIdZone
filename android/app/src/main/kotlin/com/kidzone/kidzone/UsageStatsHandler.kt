package com.kidzone.kidzone

import android.app.AppOpsManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Reads today's foreground usage from [UsageStatsManager] and exposes it to
 * Flutter. Never invents values — empty results mean the API returned nothing.
 */
class UsageStatsHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkUsageAccess", "hasPermission" ->
                result.success(hasUsageAccess())
            "openUsageAccessSettings", "openSettings" -> {
                openUsageAccessSettings()
                result.success(null)
            }
            "getTodayUsage", "todayUsage" ->
                result.success(getTodayUsage())
            else -> result.notImplemented()
        }
    }

    fun hasUsageAccess(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager
            ?: return false
        val mode =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    context.packageName,
                )
            } else {
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    context.packageName,
                )
            }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    fun openUsageAccessSettings() {
        val intents =
            listOf(
                Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                    data = Uri.parse("package:${context.packageName}")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                },
                Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                },
            )
        for (intent in intents) {
            try {
                context.startActivity(intent)
                return
            } catch (_: Exception) {
            }
        }
    }

    fun getTodayUsage(): Map<String, Any> {
        if (!hasUsageAccess()) {
            return mapOf(
                "granted" to false,
                "available" to true,
                "totalMinutes" to 0,
                "apps" to emptyList<Map<String, Any>>(),
            )
        }

        val manager =
            context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
        if (manager == null) {
            return mapOf(
                "granted" to true,
                "available" to false,
                "totalMinutes" to 0,
                "apps" to emptyList<Map<String, Any>>(),
            )
        }

        val start = startOfTodayMillis()
        val end = System.currentTimeMillis()
        val aggregated = LinkedHashMap<String, Long>()

        fun collect(stats: UsageStats) {
            val time = usageMillis(stats)
            if (time > 0L) {
                aggregated[stats.packageName] =
                    (aggregated[stats.packageName] ?: 0L) + time
            }
        }

        val fromAggregate = manager.queryAndAggregateUsageStats(start, end)
        for ((_, stats) in fromAggregate) {
            collect(stats)
        }

        if (aggregated.isEmpty()) {
            val daily =
                manager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, start, end)
                    ?: emptyList()
            for (stats in daily) collect(stats)
        }
        if (aggregated.isEmpty()) {
            val best =
                manager.queryUsageStats(UsageStatsManager.INTERVAL_BEST, start, end)
                    ?: emptyList()
            for (stats in best) collect(stats)
        }

        val apps =
            aggregated.entries
                .filter { it.value >= 60_000L && !isIgnoredPackage(it.key) }
                .sortedByDescending { it.value }
                .take(16)
                .map { entry ->
                    val minutes = (entry.value / 60_000L).toInt()
                    mapOf(
                        "packageName" to entry.key,
                        "appName" to appLabel(entry.key),
                        "name" to appLabel(entry.key),
                        "minutes" to minutes,
                    )
                }

        val totalMinutes = apps.sumOf { it["minutes"] as Int }
        return mapOf(
            "granted" to true,
            "available" to true,
            "totalMinutes" to totalMinutes,
            "apps" to apps,
        )
    }

    private fun usageMillis(stats: UsageStats): Long {
        var time = stats.totalTimeInForeground
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            time = maxOf(time, stats.totalTimeVisible)
        }
        return time
    }

    private fun startOfTodayMillis(): Long {
        val calendar = java.util.Calendar.getInstance()
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0)
        calendar.set(java.util.Calendar.MINUTE, 0)
        calendar.set(java.util.Calendar.SECOND, 0)
        calendar.set(java.util.Calendar.MILLISECOND, 0)
        return calendar.timeInMillis
    }

    private fun appLabel(packageName: String): String {
        return try {
            val info = context.packageManager.getApplicationInfo(packageName, 0)
            context.packageManager.getApplicationLabel(info).toString()
        } catch (_: Exception) {
            packageName.substringAfterLast('.')
        }
    }

    private fun isIgnoredPackage(packageName: String): Boolean {
        if (packageName == context.packageName) return true
        val ignored =
            setOf(
                "com.android.systemui",
                "com.android.settings",
                "com.android.vending",
                "com.android.phone",
                "com.android.server.telecom",
                "com.google.android.gms",
                "com.google.android.gsf",
                "com.google.android.permissioncontroller",
                "com.android.permissioncontroller",
                "com.google.android.packageinstaller",
                "com.android.packageinstaller",
                "com.google.android.inputmethod.latin",
                "com.android.inputmethod.latin",
                "com.google.android.apps.nexuslauncher",
                "com.android.launcher",
                "com.android.launcher3",
                "com.miui.home",
                "com.sec.android.app.launcher",
                "com.huawei.android.launcher",
                "com.oppo.launcher",
                "com.vivo.launcher",
            )
        if (packageName in ignored) return true
        if (packageName.startsWith("com.android.providers.")) return true
        if (packageName.startsWith("com.qualcomm.")) return true
        return try {
            val info = context.packageManager.getApplicationInfo(packageName, 0)
            val isLauncher = info.name?.contains("Launcher", ignoreCase = true) == true
            isLauncher && info.flags and ApplicationInfo.FLAG_SYSTEM != 0
        } catch (_: Exception) {
            false
        }
    }
}
