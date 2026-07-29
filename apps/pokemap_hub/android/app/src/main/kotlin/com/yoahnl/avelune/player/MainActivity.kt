package com.yoahnl.avelune.player

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.StatFs
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.util.UUID
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val packageCopyExecutor = Executors.newSingleThreadExecutor()
    private var pendingPackageResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.yoahnl.avelune.player/android",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickPackage" -> openPackagePicker(result)
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

    private fun openPackagePicker(result: MethodChannel.Result) {
        if (pendingPackageResult != null) {
            result.error(
                "importPicker.busy",
                "A package selection is already in progress.",
                null,
            )
            return
        }
        pendingPackageResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        try {
            startActivityForResult(intent, packagePickerRequestCode)
        } catch (error: Exception) {
            pendingPackageResult = null
            result.error(
                "importPicker.openFailed",
                "The Android file selector could not be opened.",
                error.message,
            )
        }
    }

    @Deprecated("Deprecated by Android; retained for FlutterActivity compatibility.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != packagePickerRequestCode) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }

        val result = pendingPackageResult ?: return
        pendingPackageResult = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }

        packageCopyExecutor.execute {
            try {
                val packagePath = copyPackageToCache(uri)
                runOnUiThread { result.success(packagePath) }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error(
                        "importPicker.readFailed",
                        "The selected package could not be read.",
                        error.message,
                    )
                }
            }
        }
    }

    private fun copyPackageToCache(uri: Uri): String {
        val importDirectory = File(cacheDir, "avelune-imports")
        if (!importDirectory.exists() && !importDirectory.mkdirs()) {
            throw IOException("The package import cache could not be created.")
        }
        importDirectory.listFiles()?.forEach { staleFile ->
            if (staleFile.isFile) {
                staleFile.delete()
            }
        }

        val displayName = queryDisplayName(uri) ?: "selected-package"
        val safeName = displayName
            .substringAfterLast('/')
            .substringAfterLast('\\')
            .replace(unsafeFileNameCharacters, "_")
            .take(maximumFileNameLength)
            .ifBlank { "selected-package" }
        val target = File(importDirectory, "${UUID.randomUUID()}-$safeName")

        try {
            val input = contentResolver.openInputStream(uri)
                ?: throw IOException("The selected package stream is unavailable.")
            input.use {
                target.outputStream().use { output ->
                    input.copyTo(output, bufferSize = 64 * 1024)
                }
            }
        } catch (error: Exception) {
            target.delete()
            throw error
        }
        return target.absolutePath
    }

    private fun queryDisplayName(uri: Uri): String? {
        return contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { cursor ->
            if (!cursor.moveToFirst()) {
                return@use null
            }
            val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (nameIndex < 0 || cursor.isNull(nameIndex)) {
                null
            } else {
                cursor.getString(nameIndex)
            }
        }
    }

    override fun onDestroy() {
        packageCopyExecutor.shutdownNow()
        pendingPackageResult?.error(
            "importPicker.cancelled",
            "The package selection was interrupted.",
            null,
        )
        pendingPackageResult = null
        super.onDestroy()
    }

    companion object {
        private const val packagePickerRequestCode = 7104
        private const val maximumFileNameLength = 160
        private val unsafeFileNameCharacters = Regex("[^A-Za-z0-9._-]")
    }
}
