package com.yoahnl.avelune.player.presentation

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.yoahnl.avelune.host.InstalledGame

data class AvelunePalette(
    val background: Color,
    val surface: Color,
    val surfaceRaised: Color,
    val lilac: Color,
    val cyan: Color,
    val rose: Color,
    val mint: Color,
    val text: Color,
    val muted: Color,
    val border: Color,
) {
    val artworkText = Color.White
    val artworkShade = Color.Black
}

private val DarkPalette = AvelunePalette(
    background = Color(0.035f, 0.045f, 0.105f),
    surface = Color(0.085f, 0.105f, 0.19f),
    surfaceRaised = Color(0.12f, 0.14f, 0.24f),
    lilac = Color(0.76f, 0.71f, 1f),
    cyan = Color(0.61f, 0.91f, 1f),
    rose = Color(1f, 0.62f, 0.8f),
    mint = Color(0.55f, 0.94f, 0.8f),
    text = Color.White,
    muted = Color(0.68f, 0.71f, 0.81f),
    border = Color.White.copy(alpha = 0.12f),
)

private val LightPalette = AvelunePalette(
    background = Color(0.96f, 0.97f, 1f),
    surface = Color.White,
    surfaceRaised = Color(0.91f, 0.93f, 0.99f),
    lilac = Color(0.43f, 0.35f, 0.84f),
    cyan = Color(0.2f, 0.43f, 0.73f),
    rose = Color(0.8f, 0.35f, 0.59f),
    mint = Color(0.2f, 0.58f, 0.49f),
    text = Color(0.07f, 0.11f, 0.23f),
    muted = Color(0.36f, 0.42f, 0.57f),
    border = Color(0.75f, 0.79f, 0.9f, 0.65f),
)

private val LocalAvelunePalette = staticCompositionLocalOf { DarkPalette }

val avelunePalette: AvelunePalette
    @Composable get() = LocalAvelunePalette.current

data class AveluneArtworkStyle(val glow: Color, val secondary: Color, val action: Color)

private val ArtworkStyles = listOf(
    AveluneArtworkStyle(Color(0.32f, 0.75f, 0.88f), Color(0.19f, 0.37f, 0.65f), Color(0.20f, 0.49f, 0.65f)),
    AveluneArtworkStyle(Color(1f, 0.65f, 0.43f), Color(0.78f, 0.32f, 0.50f), Color(0.74f, 0.35f, 0.43f)),
    AveluneArtworkStyle(Color(0.70f, 0.60f, 1f), Color(0.34f, 0.43f, 0.82f), Color(0.48f, 0.40f, 0.77f)),
    AveluneArtworkStyle(Color(0.64f, 0.84f, 0.57f), Color(0.18f, 0.53f, 0.56f), Color(0.25f, 0.53f, 0.46f)),
)

fun artworkStyle(game: InstalledGame): AveluneArtworkStyle {
    var hash = 2_166_136_261L
    for (byte in game.title.toByteArray(Charsets.UTF_8)) {
        hash = ((hash xor (byte.toLong() and 255)) * 16_777_619) and 0xffffffffL
    }
    val style = ArtworkStyles[(hash % ArtworkStyles.size).toInt()]
    val hex = game.accentColor?.trim()?.trim('#') ?: return style
    if (!hex.matches(Regex("[0-9a-fA-F]{6}"))) return style
    return style.copy(glow = Color(0xff000000L or hex.toLong(16)))
}

@Composable
fun AveluneTheme(content: @Composable () -> Unit) {
    val dark = isSystemInDarkTheme()
    val palette = if (dark) DarkPalette else LightPalette
    val scheme = if (dark) darkColorScheme() else lightColorScheme()
    CompositionLocalProvider(LocalAvelunePalette provides palette) {
        MaterialTheme(
            colorScheme = scheme.copy(
                primary = palette.lilac,
                onPrimary = palette.background,
                primaryContainer = palette.surfaceRaised,
                onPrimaryContainer = palette.text,
                background = palette.background,
                surface = palette.surface,
                surfaceContainer = palette.surface,
                surfaceContainerHigh = palette.surfaceRaised,
                onSurface = palette.text,
                onSurfaceVariant = palette.muted,
                outline = palette.border,
                outlineVariant = palette.border,
                secondary = palette.cyan,
            ),
            content = content,
        )
    }
}

@Composable
fun AveluneBackground(
    modifier: Modifier = Modifier,
    accent: Color? = null,
    content: @Composable BoxScope.() -> Unit,
) {
    val palette = avelunePalette
    Box(modifier.fillMaxSize()) {
        Canvas(Modifier.fillMaxSize()) {
            drawRect(palette.background)
            drawRect(Brush.radialGradient(
                listOf((accent ?: palette.cyan).copy(alpha = 0.16f), palette.background.copy(alpha = 0f)),
                center = Offset(size.width, 0f),
                radius = 340.dp.toPx(),
            ))
            drawRect(Brush.radialGradient(
                listOf(palette.lilac.copy(alpha = 0.09f), palette.background.copy(alpha = 0f)),
                center = Offset(0f, size.height),
                radius = 360.dp.toPx(),
            ))
        }
        content()
    }
}
