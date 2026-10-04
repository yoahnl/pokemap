package com.yoahnl.avelune.player.data

import android.content.Context
import android.net.Uri
import android.os.StatFs
import android.provider.OpenableColumns
import com.yoahnl.avelune.host.PackageName
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
        val extension = PackageName.extension(name?.takeIf(String::isNotBlank) ?: "package.avelunegame")
        val directory = File(context.cacheDir, "imports").apply { mkdirs() }
        val available = StatFs(directory.absolutePath).availableBytes
        require(size == null || size!! < available) { "L’espace disponible ne suffit pas pour importer ce jeu." }
        val staged = File.createTempFile("avelune_", ".$extension", directory)
        try {
            val input = resolver.openInputStream(uri)
                ?: throw IllegalArgumentException("Impossible d’ouvrir le fichier choisi.")
            input.use { source -> staged.outputStream().use { target -> source.copyTo(target) } }
            require(staged.length() > 0) { "Le fichier choisi est vide." }
            staged
        } catch (error: Throwable) {
            staged.delete()
            throw error
        }
    }
}
