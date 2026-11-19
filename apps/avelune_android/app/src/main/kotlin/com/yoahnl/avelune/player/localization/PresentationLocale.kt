package com.yoahnl.avelune.player.localization

import android.content.Context
import android.content.res.Configuration
import android.content.res.Resources
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.platform.LocalResources
import androidx.compose.ui.unit.LayoutDirection
import java.util.Locale

internal fun Context.presentationResources(locale: String): Resources =
    createConfigurationContext(Configuration().apply { setLocale(Locale.forLanguageTag(locale)) }).resources

@Composable
internal fun PresentationLocale(locale: String, content: @Composable () -> Unit) {
    val context = LocalContext.current
    val configuration = LocalConfiguration.current
    val localized = remember(context, configuration, locale) { context.presentationResources(locale) }
    CompositionLocalProvider(
        LocalConfiguration provides localized.configuration,
        LocalLayoutDirection provides LayoutDirection.Ltr,
        LocalResources provides localized,
        content = content,
    )
}

@Composable
internal fun NativeMessage.resolve(): String = resolve(LocalResources.current)

@Composable
internal fun presentationLocale(): Locale = LocalConfiguration.current.locales[0]
