package com.yoahnl.avelune.player

import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.yoahnl.avelune.player/android",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "availableDiskBytes" -> {
                    try {
                        result.success(StatFs(filesDir.absolutePath).availableBytes)
                    } catch (error: Exception) {
                        result.error(
                            "storage.unavailable",
                            "Available Android storage capacity is unavailable.",
                            error.message,
                        )
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
