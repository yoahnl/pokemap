package com.yoahnl.avelune.player.presentation

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.toggleable
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.MonitorHeart
import androidx.compose.material.icons.filled.Public
import androidx.compose.material.icons.outlined.Devices
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.yoahnl.avelune.player.runtime.SurfaceProbeSession

@Composable
fun SettingsScreen(
    modifier: Modifier = Modifier,
    onStartSurfaceProbe: () -> Unit = {},
    canStartSurfaceProbe: Boolean = true,
) {
    val context = LocalContext.current.applicationContext
    val preferences = remember(context) { context.getSharedPreferences("avelune_settings", Context.MODE_PRIVATE) }
    var showDebug by remember(preferences) { mutableStateOf(preferences.getBoolean("showDebugInfo", false)) }
    val version = remember(context) { installedVersion(context) }
    val palette = avelunePalette
    val updateDebug: (Boolean) -> Unit = {
        showDebug = it
        preferences.edit().putBoolean("showDebugInfo", it).apply()
    }
    AveluneBackground(modifier) {
        Column(Modifier.fillMaxSize()) {
            SettingsHeader()
            Column(
                modifier = Modifier.weight(1f).fillMaxWidth().verticalScroll(rememberScrollState())
                    .padding(horizontal = 24.dp).padding(top = 22.dp, bottom = 40.dp),
                verticalArrangement = Arrangement.spacedBy(28.dp),
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    SettingsSectionTitle("PRÉFÉRENCES")
                    SettingsRow {
                        SettingsIcon(Icons.Filled.Public)
                        SettingsLabels("Langue", "Langue de l’application", Modifier.weight(1f))
                        Text("Français", color = palette.muted, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                    }
                }
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    SettingsSectionTitle("POUR LES CURIEUX")
                    SettingsRow(
                        Modifier.focusRing(22).toggleable(
                            value = showDebug,
                            role = Role.Switch,
                            onValueChange = updateDebug,
                        ),
                    ) {
                        SettingsIcon(Icons.Filled.MonitorHeart)
                        SettingsLabels("Infos de debug", "FPS, latence de rendu, mémoire et CPU dans le jeu", Modifier.weight(1f))
                        Switch(
                            checked = showDebug,
                            onCheckedChange = null,
                            colors = SwitchDefaults.colors(
                                checkedThumbColor = palette.artworkText,
                                checkedTrackColor = palette.lilac,
                                checkedBorderColor = palette.lilac,
                                uncheckedThumbColor = palette.muted,
                                uncheckedTrackColor = palette.surfaceRaised,
                                uncheckedBorderColor = palette.border,
                            ),
                        )
                    }
                    if (showDebug && SurfaceProbeSession.isEnabled) {
                        AveluneButton(
                            "Tester les deux écrans",
                            onStartSurfaceProbe,
                            Modifier.fillMaxWidth(),
                            enabled = canStartSurfaceProbe && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O,
                            icon = Icons.Outlined.Devices,
                        )
                    }
                }
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    SettingsSectionTitle("À PROPOS")
                    Column(
                        Modifier.fillMaxWidth().background(palette.surface, RoundedCornerShape(24.dp))
                            .border(1.dp, palette.border, RoundedCornerShape(24.dp)).padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(15.dp),
                    ) {
                        Text(
                            "Des histoires à emporter partout.",
                            color = palette.text,
                            fontSize = 17.sp,
                            fontWeight = FontWeight.SemiBold,
                            textAlign = TextAlign.Center,
                        )
                        Text(
                            "Avelune pour Android · Version $version",
                            color = palette.muted,
                            fontSize = 12.sp,
                            textAlign = TextAlign.Center,
                        )
                        if (showDebug) {
                            HorizontalDivider(color = palette.border)
                            Text("Moteur Flutter + Flame · map_runtime", color = palette.muted, fontSize = 11.sp)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun SettingsHeader() {
    val palette = avelunePalette
    Column(
        modifier = Modifier.fillMaxWidth()
            .background(Brush.verticalGradient(listOf(palette.surface.copy(alpha = 0.9f), palette.background.copy(alpha = 0.96f))))
            .drawBehind {
                drawLine(palette.border, Offset(0f, size.height), Offset(size.width, size.height), 1.dp.toPx())
            }
            .padding(horizontal = 24.dp).padding(top = 8.dp, bottom = 22.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        AveluneWordmark(Modifier.size(width = 205.dp, height = 58.dp).offset(x = (-18).dp))
        Text("VOTRE ESPACE", color = palette.cyan, fontSize = 11.sp, fontWeight = FontWeight.Bold, letterSpacing = 2.5.sp)
        Text("Réglages", color = palette.text, fontSize = 32.sp, lineHeight = 38.sp, fontWeight = FontWeight.Bold)
        Text("Une expérience à votre image.", color = palette.muted, fontSize = 15.sp)
    }
}

@Composable
private fun SettingsSectionTitle(title: String) {
    Text(
        title,
        Modifier.padding(start = 4.dp),
        color = avelunePalette.muted,
        fontSize = 11.sp,
        fontWeight = FontWeight.Bold,
        letterSpacing = 2.sp,
    )
}

@Composable
private fun SettingsRow(modifier: Modifier = Modifier, content: @Composable androidx.compose.foundation.layout.RowScope.() -> Unit) {
    val palette = avelunePalette
    Row(
        modifier.fillMaxWidth().background(palette.surface, RoundedCornerShape(22.dp))
            .border(1.dp, palette.border, RoundedCornerShape(22.dp)).padding(18.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(15.dp),
        content = content,
    )
}

@Composable
private fun SettingsLabels(title: String, subtitle: String, modifier: Modifier) {
    val palette = avelunePalette
    Column(modifier, verticalArrangement = Arrangement.spacedBy(3.dp)) {
        Text(title, color = palette.text, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
        Text(subtitle, color = palette.muted, fontSize = 12.sp)
    }
}

@Composable
private fun SettingsIcon(icon: ImageVector) {
    val palette = avelunePalette
    Box(
        Modifier.size(42.dp).background(palette.surfaceRaised, RoundedCornerShape(13.dp)),
        contentAlignment = Alignment.Center,
    ) {
        Icon(icon, null, Modifier.size(18.dp), tint = palette.cyan)
    }
}

private fun installedVersion(context: Context): String = runCatching {
    val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        context.packageManager.getPackageInfo(context.packageName, PackageManager.PackageInfoFlags.of(0))
    } else {
        @Suppress("DEPRECATION")
        context.packageManager.getPackageInfo(context.packageName, 0)
    }
    info.versionName ?: "—"
}.getOrDefault("—")
