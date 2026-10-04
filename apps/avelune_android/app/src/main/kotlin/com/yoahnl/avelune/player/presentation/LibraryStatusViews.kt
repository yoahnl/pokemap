package com.yoahnl.avelune.player.presentation

import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.outlined.FileDownload
import androidx.compose.material.icons.outlined.FolderZip
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Layers
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material.icons.outlined.Verified
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun LibraryLoading() {
    val palette = avelunePalette
    Column(
        modifier = Modifier.fillMaxWidth().padding(vertical = 42.dp).testTag("library-loading")
            .clearAndSetSemantics { contentDescription = "Chargement de la bibliothèque Avelune" },
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        LibraryLoadingArtwork()
        Text(
            "Vos mondes se rassemblent",
            color = palette.text,
            fontSize = 25.sp,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center,
        )
        Text("On prépare votre bibliothèque…", color = palette.muted, fontSize = 15.sp, textAlign = TextAlign.Center)
        Box(
            Modifier.padding(top = 4.dp).size(width = 78.dp, height = 3.dp)
                .background(Brush.linearGradient(listOf(palette.lilac, palette.cyan)), CircleShape),
        )
    }
}

@Composable
fun EmptyLibrary(enabled: Boolean, importGame: () -> Unit) {
    val palette = avelunePalette
    val shape = RoundedCornerShape(30.dp)
    Column(
        Modifier.fillMaxWidth().background(palette.surface, shape).border(1.dp, palette.border, shape)
            .padding(horizontal = 24.dp, vertical = 28.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(20.dp),
    ) {
        Box(Modifier.size(190.dp), contentAlignment = Alignment.Center) {
            Canvas(Modifier.fillMaxSize()) {
                drawCircle(
                    Brush.radialGradient(
                        listOf(palette.lilac.copy(alpha = 0.22f), palette.lilac.copy(alpha = 0f)),
                        center = center,
                        radius = 110.dp.toPx(),
                    ),
                )
            }
            AveluneMoon(Modifier.fillMaxSize())
        }
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text(
                "Un monde vous attend",
                color = palette.text,
                fontSize = 26.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
            )
            Text(
                "Importez votre premier jeu et retrouvez toutes vos aventures au même endroit.",
                color = palette.muted,
                fontSize = 15.sp,
                textAlign = TextAlign.Center,
            )
        }
        AveluneButton(
            "Importer un jeu",
            importGame,
            Modifier.fillMaxWidth(),
            enabled = enabled,
            icon = Icons.Outlined.FileDownload,
            prominent = true,
        )
        Text("Fichier .avelunegame", color = palette.muted, fontSize = 12.sp)
    }
}

@Composable
fun FailedLibrary(detail: String?, retry: () -> Unit) {
    val palette = avelunePalette
    val shape = RoundedCornerShape(30.dp)
    Column(
        Modifier.fillMaxWidth().testTag("library-load-failed").background(palette.surface, shape)
            .border(1.dp, palette.border, shape).padding(28.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        AveluneMoon(Modifier.size(104.dp))
        Text(
            "La bibliothèque ne s’ouvre pas",
            color = palette.text,
            fontSize = 25.sp,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center,
        )
        Text(
            "Impossible de retrouver vos jeux pour le moment. Réessayons.",
            color = palette.muted,
            fontSize = 15.sp,
            textAlign = TextAlign.Center,
        )
        if (detail != null) {
            Text(
                detail,
                color = palette.muted,
                fontSize = 12.sp,
                textAlign = TextAlign.Center,
                maxLines = 3,
                overflow = TextOverflow.Ellipsis,
            )
        }
        AveluneButton("Réessayer", retry, Modifier.fillMaxWidth(), icon = Icons.Outlined.Refresh, prominent = true)
    }
}

@Composable
fun InstallationScreen(stage: LibraryInstallationStage, gameName: String) {
    val palette = avelunePalette
    AveluneBackground {
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 26.dp)
                .padding(top = 24.dp, bottom = 40.dp),
            verticalArrangement = Arrangement.spacedBy(25.dp),
        ) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                AveluneWordmark(Modifier.size(width = 170.dp, height = 50.dp).offset(x = (-14).dp))
                Spacer(Modifier.weight(1f))
                Text("INSTALLATION", color = palette.cyan, fontSize = 10.sp, fontWeight = FontWeight.Bold, letterSpacing = 2.sp)
            }
            InstallationArtwork()
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text("Une nouvelle aventure arrive", color = palette.text, fontSize = 29.sp, fontWeight = FontWeight.Bold)
                Text(gameName, color = palette.cyan, fontSize = 20.sp, fontWeight = FontWeight.SemiBold, maxLines = 2, overflow = TextOverflow.Ellipsis)
                Crossfade(stage, animationSpec = tween(350), label = "installation-detail") {
                    Text(it.detail, color = palette.muted, fontSize = 15.sp)
                }
            }
            InstallationProgress(stage)
            Row(horizontalArrangement = Arrangement.spacedBy(7.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Outlined.Info, null, Modifier.size(14.dp), tint = palette.muted)
                Text("Gardez Avelune ouverte pendant l’installation.", color = palette.muted, fontSize = 12.sp)
            }
        }
    }
}

@Composable
private fun LibraryLoadingArtwork() {
    val palette = avelunePalette
    val transition = rememberInfiniteTransition(label = "library-orbits")
    val outerRotation by transition.animateFloat(
        0f, 360f, infiniteRepeatable(tween(7_000, easing = LinearEasing), RepeatMode.Restart), label = "outer-orbit",
    )
    val innerRotation by transition.animateFloat(
        0f, -360f, infiniteRepeatable(tween(10_000, easing = LinearEasing), RepeatMode.Restart), label = "inner-orbit",
    )
    Box(Modifier.fillMaxWidth().height(260.dp), contentAlignment = Alignment.Center) {
        Canvas(Modifier.size(250.dp)) {
            drawCircle(
                Brush.radialGradient(
                    listOf(palette.lilac.copy(alpha = 0.28f), palette.cyan.copy(alpha = 0.12f), palette.cyan.copy(alpha = 0f)),
                    center = center,
                    radius = 125.dp.toPx(),
                ),
            )
            drawCircle(palette.border, radius = 107.dp.toPx(), style = Stroke(1.dp.toPx()))
            rotate(outerRotation) {
                drawArc(
                    Brush.sweepGradient(listOf(palette.rose, palette.lilac, palette.cyan, palette.mint), center),
                    10.8f,
                    140.4f,
                    false,
                    topLeft = center - Offset(107.dp.toPx(), 107.dp.toPx()),
                    size = Size(214.dp.toPx(), 214.dp.toPx()),
                    style = Stroke(4.dp.toPx(), cap = StrokeCap.Round),
                )
            }
            rotate(innerRotation) {
                drawArc(
                    Brush.sweepGradient(listOf(palette.cyan, palette.mint, palette.rose), center),
                    172.8f,
                    122.4f,
                    false,
                    topLeft = center - Offset(88.dp.toPx(), 88.dp.toPx()),
                    size = Size(176.dp.toPx(), 176.dp.toPx()),
                    style = Stroke(2.5.dp.toPx(), cap = StrokeCap.Round),
                )
            }
        }
        AveluneMoon(Modifier.size(136.dp))
        Box(Modifier.size(7.dp).offset(x = (-110).dp, y = (-50).dp).background(palette.rose, CircleShape))
        Box(Modifier.size(5.dp).offset(x = 111.dp, y = 48.dp).background(palette.mint, CircleShape))
    }
}

@Composable
private fun InstallationArtwork() {
    val palette = avelunePalette
    val transition = rememberInfiniteTransition(label = "installation-orbit")
    val rotation by transition.animateFloat(
        0f, 360f, infiniteRepeatable(tween(9_000, easing = LinearEasing), RepeatMode.Restart), label = "installation-ring",
    )
    Box(Modifier.fillMaxWidth().padding(vertical = 6.dp).height(166.dp), contentAlignment = Alignment.Center) {
        Canvas(Modifier.size(158.dp)) {
            drawCircle(palette.border, style = Stroke(1.dp.toPx()))
            rotate(rotation) {
                drawArc(
                    Brush.sweepGradient(listOf(palette.lilac, palette.cyan), center),
                    7.2f,
                    100.8f,
                    false,
                    style = Stroke(2.dp.toPx(), cap = StrokeCap.Round),
                )
            }
        }
        Box(
            Modifier.size(116.dp).background(palette.surfaceRaised.copy(alpha = 0.7f), RoundedCornerShape(32.dp)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Outlined.Layers, null, Modifier.size(42.dp), tint = palette.cyan)
        }
    }
}

@Composable
private fun InstallationProgress(stage: LibraryInstallationStage) {
    val palette = avelunePalette
    val shape = RoundedCornerShape(26.dp)
    Column(
        Modifier.fillMaxWidth().background(palette.surface, shape).border(1.dp, palette.border, shape).padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            CircularProgressIndicator(Modifier.size(18.dp), color = palette.cyan, strokeWidth = 2.dp)
            Text(stage.title, Modifier.weight(1f), color = palette.text, fontSize = 15.sp, fontWeight = FontWeight.SemiBold)
            Text("Étape ${stage.ordinal + 1} sur 3", color = palette.muted, fontSize = 12.sp, fontFamily = FontFamily.Monospace)
        }
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            for (step in LibraryInstallationStage.entries) {
                val fill = if (step.ordinal < stage.ordinal) {
                    Brush.linearGradient(listOf(palette.lilac, palette.cyan))
                } else {
                    Brush.linearGradient(listOf(palette.surfaceRaised, palette.surfaceRaised))
                }
                val outline = if (step == stage) Modifier.border(1.dp, palette.cyan, CircleShape) else Modifier
                Box(Modifier.weight(1f).height(5.dp).background(fill, CircleShape).then(outline))
            }
        }
        Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
            for (step in LibraryInstallationStage.entries) {
                val completed = step.ordinal < stage.ordinal
                val current = step == stage
                Row(
                    Modifier.fillMaxWidth().semantics(mergeDescendants = true) {
                        stateDescription = if (completed) "Terminée" else if (current) "En cours" else "À venir"
                    },
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(13.dp),
                ) {
                    Icon(
                        if (completed) Icons.Filled.CheckCircle else installationIcon(step),
                        null,
                        Modifier.width(25.dp).height(20.dp),
                        tint = if (step.ordinal <= stage.ordinal) palette.cyan else palette.muted,
                    )
                    Text(
                        step.title,
                        Modifier.weight(1f),
                        color = if (step.ordinal <= stage.ordinal) palette.text else palette.muted,
                        fontSize = 15.sp,
                        fontWeight = if (current) FontWeight.SemiBold else FontWeight.Normal,
                    )
                    if (current) {
                        Text(
                            "En cours",
                            Modifier.clearAndSetSemantics { },
                            color = palette.cyan,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.SemiBold,
                        )
                    }
                }
            }
        }
    }
}

private fun installationIcon(stage: LibraryInstallationStage): ImageVector = when (stage) {
    LibraryInstallationStage.PREPARING -> Icons.Outlined.FolderZip
    LibraryInstallationStage.INSTALLING -> Icons.Outlined.Layers
    LibraryInstallationStage.FINISHING -> Icons.Outlined.Verified
}
