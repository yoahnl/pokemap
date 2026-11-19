package com.yoahnl.avelune.player.data

import android.content.Context
import android.net.Uri
import android.os.StatFs
import android.provider.OpenableColumns
import com.yoahnl.avelune.host.PackageName
import com.yoahnl.avelune.player.R
import com.yoahnl.avelune.player.localization.NativeFailure
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

class PackageStager(private val context: Context) {
    suspend fun stage(uri: Uri): File = withContext(Dispatchers.IO) {
        val resolver = context.contentResolver
        var name: String? = null
        var size: Long? = null
        resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)?.use {
            if (it.moveToFirst()) {
                val nameIndex = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                val sizeIndex = it.getColumnIndex(OpenableColumns.SIZE)
                if (nameIndex >= 0 && !it.isNull(nameIndex)) name = it.getString(nameIndex)
                if (sizeIndex >= 0 && !it.isNull(sizeIndex)) size = it.getLong(sizeIndex)
            }
        }
        val extension = try {
            PackageName.extension(name?.takeIf(String::isNotBlank) ?: "package.avelunegame")
        } catch (error: IllegalArgumentException) {
            throw NativeFailure(R.string.error_package_extension, cause = error)
        }
        val directory = File(context.cacheDir, "imports").apply { mkdirs() }
        val available = StatFs(directory.absolutePath).availableBytes
        val declaredSize = size
        if (declaredSize != null && declaredSize >= available) throw NativeFailure(R.string.error_package_disk)
        val staged = File.createTempFile("avelune_", ".$extension", directory)
        try {
            val input = resolver.openInputStream(uri)
                ?: throw NativeFailure(R.string.error_package_open)
            input.use { source -> staged.outputStream().use { target -> source.copyTo(target) } }
            if (staged.length() == 0L) throw NativeFailure(R.string.error_package_empty)
            staged
        } catch (error: Throwable) {
            staged.delete()
            throw error
        }
    }
}
