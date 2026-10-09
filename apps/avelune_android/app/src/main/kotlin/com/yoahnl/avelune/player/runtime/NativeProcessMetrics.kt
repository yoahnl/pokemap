package com.yoahnl.avelune.player.runtime

import android.content.Context
import android.os.Build
import android.os.Debug
import android.os.PowerManager
import android.os.Process
import android.os.SystemClock

internal object NativeProcessMetrics {
    fun read(context: Context): Map<String, Any> {
        val sample = mutableMapOf<String, Any>(
            "cpuSeconds" to Process.getElapsedCpuTime() / 1000.0,
            "uptimeSeconds" to SystemClock.elapsedRealtime() / 1000.0,
            "memoryKind" to "pss",
        )
        runCatching {
            val memory = Debug.MemoryInfo()
            Debug.getMemoryInfo(memory)
            memory.totalPss.toLong() * 1024
        }.onSuccess { sample["memoryBytes"] = it }
        val power = context.getSystemService(PowerManager::class.java)
        sample["lowPowerMode"] = power.isPowerSaveMode
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            sample["thermalState"] = when (power.currentThermalStatus) {
                PowerManager.THERMAL_STATUS_NONE -> "nominal"
                PowerManager.THERMAL_STATUS_LIGHT, PowerManager.THERMAL_STATUS_MODERATE -> "fair"
                PowerManager.THERMAL_STATUS_SEVERE -> "serious"
                PowerManager.THERMAL_STATUS_CRITICAL, PowerManager.THERMAL_STATUS_EMERGENCY, PowerManager.THERMAL_STATUS_SHUTDOWN -> "critical"
                else -> "unknown"
            }
        }
        return sample
    }
}
