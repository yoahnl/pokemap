package com.yoahnl.avelune.player.presentation

import android.view.KeyEvent
import android.view.Window
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material3.Icon
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.DialogWindowProvider
import coil.compose.AsyncImage
import com.yoahnl.avelune.player.R
import java.io.File

private fun KeyEvent.navigationEvent(): KeyEvent? {
    val mapped = when (keyCode) {
        KeyEvent.KEYCODE_BUTTON_A -> KeyEvent.KEYCODE_DPAD_CENTER
        KeyEvent.KEYCODE_BUTTON_B -> KeyEvent.KEYCODE_BACK
        else -> return null
    }
    return KeyEvent(downTime, eventTime, action, mapped, repeatCount, metaState, deviceId, scanCode, flags, source)
}

@Composable
fun AveluneDialogGamepadKeys(dismiss: () -> Unit) {
    val view = LocalView.current
    val currentDismiss by rememberUpdatedState(dismiss)
    val window = (view.parent as? DialogWindowProvider)?.window ?: return
    DisposableEffect(window) {
        val previous = requireNotNull(window.callback)
        val callback = object : Window.Callback by previous {
            override fun dispatchKeyEvent(event: KeyEvent): Boolean {
                if (event.keyCode == KeyEvent.KEYCODE_BUTTON_B) {
                    if (event.action == KeyEvent.ACTION_UP) currentDismiss()
                    return true
                }
                return previous.dispatchKeyEvent(event.navigationEvent() ?: event)
            }
        }
        window.callback = callback
        onDispose { if (window.callback === callback) window.callback = previous }
    }
}

fun Modifier.popupGamepadKeys(dismiss: () -> Unit): Modifier = composed {
    val view = LocalView.current
    onPreviewKeyEvent {
        val event = it.nativeKeyEvent
        when (event.keyCode) {
            KeyEvent.KEYCODE_BUTTON_A -> view.dispatchKeyEvent(requireNotNull(event.navigationEvent()))
            KeyEvent.KEYCODE_BUTTON_B -> {
                if (event.action == KeyEvent.ACTION_UP) dismiss()
                true
            }
            else -> false
        }
    }
}

@Composable
fun AveluneMoon(modifier: Modifier) {
    Image(painterResource(R.drawable.avelune_moon), null, modifier)
}

@Composable
fun AveluneWordmark(modifier: Modifier) {
    Image(painterResource(R.drawable.avelune_glass_wordmark), "Avelune", modifier)
}

@Composable
fun AveluneButton(
    label: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    icon: ImageVector? = null,
    prominent: Boolean = false,
    actionColor: Color? = null,
) {
    val palette = avelunePalette
    val shape = RoundedCornerShape(if (actionColor != null) 10.dp else 22.dp)
    val color = actionColor ?: if (prominent) palette.lilac.copy(alpha = 0.4f) else palette.surfaceRaised.copy(alpha = 0.55f)
    Surface(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier.focusRing(if (actionColor != null) 10 else 22).border(1.dp, palette.border, shape),
        shape = shape,
        color = color.copy(alpha = if (enabled) color.alpha else 0.3f),
        contentColor = (if (actionColor != null) palette.artworkText else palette.text).copy(alpha = if (enabled) 1f else 0.45f),
    ) {
        Row(
            Modifier.padding(horizontal = 18.dp).heightIn(min = 50.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center,
        ) {
            if (icon != null) {
                Icon(icon, null, Modifier.size(18.dp))
                Spacer(Modifier.width(8.dp))
            }
            Text(label, fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
    }
}

@Composable
fun AveluneIconButton(
    icon: ImageVector,
    description: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
) {
    val palette = avelunePalette
    Surface(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier.size(44.dp).focusRing(24).border(1.dp, palette.border, CircleShape),
        shape = CircleShape,
        color = palette.surfaceRaised.copy(alpha = 0.6f),
        contentColor = palette.text.copy(alpha = if (enabled) 1f else 0.45f),
    ) {
        Box(contentAlignment = Alignment.Center) {
            Icon(icon, description, Modifier.size(20.dp))
        }
    }
}

@Composable
fun Modifier.focusRing(radius: Int = 22): Modifier {
    var focused by remember { mutableStateOf(false) }
    val color = avelunePalette.cyan.copy(alpha = if (focused) 1f else 0f)
    return onFocusChanged { focused = it.isFocused }.border(2.dp, color, RoundedCornerShape(radius.dp))
}

@Composable
fun AveluneArtwork(paths: List<String>, style: AveluneArtworkStyle, modifier: Modifier = Modifier) {
    val candidates = remember(paths) { paths.map(::File).filter(File::isFile) }
    var index by remember(paths) { mutableIntStateOf(0) }
    Box(modifier) {
        ArtworkFallback(style, Modifier.fillMaxSize())
        if (index < candidates.size) {
            AsyncImage(
                candidates[index],
                null,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop,
                onError = { index++ },
            )
        }
    }
}

@Composable
private fun ArtworkFallback(style: AveluneArtworkStyle, modifier: Modifier) {
    val palette = avelunePalette
    Box(modifier) {
        Canvas(Modifier.fillMaxSize()) {
            drawRect(Brush.linearGradient(
                listOf(palette.surfaceRaised, style.secondary.copy(alpha = 0.72f), palette.background),
                end = Offset(size.width, size.height),
            ))
            drawRect(Brush.radialGradient(
                listOf(style.glow.copy(alpha = 0.9f), style.secondary.copy(alpha = 0.25f), palette.background.copy(alpha = 0f)),
                center = Offset(size.width * 0.75f, size.height * 0.26f),
                radius = size.width * 0.8f,
            ))
            drawOval(palette.background.copy(alpha = 0.62f),
                topLeft = Offset(-size.width * 0.17f, size.height * 0.62f),
                size = Size(size.width * 1.5f, size.height * 0.5f))
            drawOval(palette.background.copy(alpha = 0.82f),
                topLeft = Offset(size.width * 0.25f, size.height * 0.78f),
                size = Size(size.width * 1.5f, size.height * 0.35f))
        }
        Icon(
            Icons.Outlined.AutoAwesome,
            null,
            Modifier.align(Alignment.Center).padding(end = 36.dp, bottom = 28.dp).size(54.dp),
            tint = palette.artworkText.copy(alpha = 0.85f),
        )
    }
}

@Composable
fun ArtworkScrim(modifier: Modifier = Modifier, opacity: Float = 0.72f) {
    val shade = avelunePalette.artworkShade
    Canvas(modifier.fillMaxSize()) {
        drawRect(Brush.verticalGradient(listOf(shade.copy(alpha = 0f), shade.copy(alpha = 0.1f), shade.copy(alpha = opacity))))
    }
}
