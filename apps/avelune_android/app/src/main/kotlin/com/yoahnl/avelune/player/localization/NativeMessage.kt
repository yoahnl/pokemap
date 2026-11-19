package com.yoahnl.avelune.player.localization

import android.content.res.Resources
import androidx.annotation.StringRes
import com.yoahnl.avelune.player.R

internal data class NativeMessage(
    @get:StringRes val resourceId: Int,
    val arguments: List<Any> = emptyList(),
    val code: String? = null,
) {
    fun resolve(resources: Resources): String {
        val message = resources.getString(resourceId, *arguments.toTypedArray())
        return if (code == null) message else resources.getString(R.string.error_with_code, message, code)
    }

    companion object {
        fun fromError(error: Exception, @StringRes fallback: Int): NativeMessage =
            (error as? NativeFailure)?.displayMessage ?: NativeMessage(fallback)
    }
}

internal class NativeFailure(
    @StringRes resourceId: Int,
    code: String? = null,
    cause: Throwable? = null,
    arguments: List<Any> = emptyList(),
) : RuntimeException(code ?: cause?.message, cause) {
    val displayMessage = NativeMessage(resourceId, arguments, code)
}
