package com.yoahnl.avelune.player.presentation

import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.PageSize
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.Business
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.outlined.MoreHoriz
import androidx.compose.material.icons.outlined.PersonOutline
import androidx.compose.material.icons.outlined.PlayArrow
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.SportsEsports
import androidx.compose.material.icons.outlined.Tag
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.yoahnl.avelune.host.InstalledGame
import com.yoahnl.avelune.player.runtime.RuntimeRecoveryState
import com.yoahnl.avelune.player.runtime.RuntimeSession
import java.text.DateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.floor

@Composable
fun GameLibraryScreen(
    viewModel: GameLibraryViewModel,
    runtime: RuntimeSession,
    resetRuntime: () -> Unit,
    startSurfaceProbe: () -> Unit = {},
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val activeGame by runtime.activeGame.collectAsStateWithLifecycle()
    val recovery by runtime.recovery.collectAsStateWithLifecycle()
    val probeSession by runtime.surfaceProbe.activeSession.collectAsStateWithLifecycle()
    val palette = avelunePalette
    var tab by rememberSaveable { mutableIntStateOf(0) }
    var quickGameId by rememberSaveable { mutableStateOf<String?>(null) }
    val quickGame = state.games.firstOrNull { it.id == quickGameId }
    val enabled = state.busy == null && activeGame == null && probeSession == null
    val importFocus = remember { FocusRequester() }
    val snackbar = remember { SnackbarHostState() }
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        uri?.let(viewModel::importPackage)
    }
    val importGame = { picker.launch(arrayOf("*/*")) }
    BackHandler(tab == 0 && state.selectedGameId != null && quickGame == null) { viewModel.select(null) }
    BackHandler(state.busy != null) { }
    LaunchedEffect(enabled, tab, state.selectedGameId, quickGameId) {
        if (enabled && tab == 0 && state.selectedGameId == null && quickGameId == null) importFocus.requestFocus()
    }
    LaunchedEffect(state.notice) {
        state.notice?.let {
            snackbar.showSnackbar(it)
            viewModel.dismissMessage()
        }
    }
    AveluneBackground {
        Scaffold(
            containerColor = palette.background.copy(alpha = 0f),
            contentWindowInsets = WindowInsets.safeDrawing,
            snackbarHost = { SnackbarHost(snackbar) },
            bottomBar = { LibraryTabs(tab) { tab = it } },
            topBar = {
                if (activeGame != null) RecoveryBanner(recovery, runtime::requestStop, resetRuntime)
            },
        ) { insets ->
            Box(Modifier.fillMaxSize().padding(insets)) {
                when {
                    tab == 1 -> SettingsScreen(onStartSurfaceProbe = startSurfaceProbe, canStartSurfaceProbe = enabled)
                    state.selectedGame != null -> GameDetail(state.selectedGame!!, enabled, viewModel)
                    else -> LibraryHome(state, enabled, importFocus, importGame, viewModel, onQuickView = { quickGameId = it.id })
                }
                if (state.busy != null && state.isLoaded && state.installationStage == null) {
                    Box(
                        Modifier.fillMaxSize().background(palette.background.copy(alpha = 0.85f))
                            .pointerInput(Unit) { detectTapGestures { } },
                        contentAlignment = Alignment.Center,
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
                            CircularProgressIndicator(color = palette.lilac)
                            Text(state.busy!!, color = palette.text)
                        }
                    }
                }
            }
        }
    }
    quickGame?.let { game ->
        QuickGameView(
            game, enabled,
            onClose = { quickGameId = null },
            onPlay = { quickGameId = null; viewModel.play(game.id) },
            onDetails = { quickGameId = null; viewModel.select(game.id) },
        )
    }
    state.installationStage?.let { stage ->
        Dialog({}, properties = DialogProperties(dismissOnBackPress = false, dismissOnClickOutside = false, usePlatformDefaultWidth = false)) {
            AveluneDialogGamepadKeys {}
            InstallationScreen(stage, state.installationName ?: "Nouveau jeu")
        }
    }
    if (state.error != null && state.isLoaded) {
        AlertDialog(
            onDismissRequest = viewModel::dismissMessage,
            title = { AveluneDialogGamepadKeys(viewModel::dismissMessage); Text("Erreur") },
            text = { Text(state.error!!) },
            confirmButton = { TextButton(onClick = viewModel::dismissMessage, modifier = Modifier.focusRing()) { Text("OK") } },
        )
    }
    state.uninstallGame?.let { game ->
        AlertDialog(
            onDismissRequest = { viewModel.requestUninstall(null) },
            title = { AveluneDialogGamepadKeys { viewModel.requestUninstall(null) }; Text("Désinstaller ${game.title} ?") },
            text = { Text("Le jeu sera retiré de votre bibliothèque. Vous pourrez le réimporter avec son fichier.") },
            confirmButton = {
                TextButton(onClick = { viewModel.uninstall(game.id) }, enabled = enabled, modifier = Modifier.focusRing()) {
                    Text("Désinstaller")
                }
            },
            dismissButton = { TextButton(onClick = { viewModel.requestUninstall(null) }) { Text("Annuler") } },
        )
    }
}

@Composable
private fun LibraryTabs(selected: Int, select: (Int) -> Unit) {
    val palette = avelunePalette
    Row(
        Modifier.fillMaxWidth().background(palette.surface.copy(alpha = 0.94f))
            .border(1.dp, palette.border).navigationBarsPadding().height(56.dp),
    ) {
        listOf("Jeux" to Icons.Outlined.SportsEsports, "Réglages" to Icons.Outlined.Settings).forEachIndexed { index, (title, icon) ->
            Surface(
                onClick = { select(index) },
                modifier = Modifier.weight(1f).fillMaxSize().focusRing(10),
                color = palette.surface.copy(alpha = 0f),
                contentColor = if (selected == index) palette.lilac else palette.muted,
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
                    Icon(icon, null, Modifier.size(24.dp))
                    Spacer(Modifier.height(3.dp))
                    Text(title, fontSize = 11.sp, fontWeight = FontWeight.Medium)
                }
            }
        }
    }
}

@Composable
private fun RecoveryBanner(recovery: RuntimeRecoveryState, stop: () -> Unit, reset: () -> Unit) {
    val palette = avelunePalette
    Surface(color = palette.surfaceRaised, modifier = Modifier.fillMaxWidth().statusBarsPadding()) {
        Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(
                if (recovery.isStopping) "Fermeture du jeu…" else recovery.error ?: "Une partie est encore ouverte.",
                Modifier.weight(1f), color = palette.text,
            )
            AveluneButton("Fermer le jeu", stop, enabled = !recovery.isStopping)
            if (recovery.error != null && !recovery.isStopping) AveluneButton("Réinitialiser Avelune", reset)
        }
    }
}

@Composable
private fun LibraryHome(
    state: GameLibraryState,
    enabled: Boolean,
    importFocus: FocusRequester,
    importGame: () -> Unit,
    viewModel: GameLibraryViewModel,
    onQuickView: (InstalledGame) -> Unit,
) {
    val palette = avelunePalette
    BoxWithConstraints(Modifier.fillMaxSize()) {
        val viewport = maxWidth.value
        val scroll = rememberLazyListState()
        val collapsed by remember { derivedStateOf { scroll.firstVisibleItemIndex > 0 } }
        val columns = floor((maxWidth.value - 48 + 14) / (145 + 14)).toInt().coerceAtLeast(1)
        val collection = (state.games + listOf<InstalledGame?>(null)).chunked(columns)
        Column {
            Row(
                Modifier.fillMaxWidth().padding(horizontal = 24.dp).height(44.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                AveluneMoon(Modifier.size(28.dp).semantics { contentDescription = "Avelune" })
                if (collapsed) Text("Bibliothèque", Modifier.weight(1f), textAlign = TextAlign.Center,
                    fontSize = 17.sp, fontWeight = FontWeight.SemiBold, color = palette.text)
                else Spacer(Modifier.weight(1f))
                AveluneIconButton(Icons.Outlined.Add, "Importer un jeu", importGame, Modifier.focusRequester(importFocus), enabled)
            }
            LazyColumn(
                Modifier.fillMaxWidth().weight(1f),
                state = scroll,
                contentPadding = PaddingValues(top = 8.dp, bottom = 36.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                item {
                    Text("Bibliothèque", Modifier.padding(horizontal = 24.dp).padding(bottom = 10.dp),
                        fontSize = 34.sp, fontWeight = FontWeight.Bold, color = palette.text)
                }
                when {
                    !state.isLoaded && state.error != null -> item {
                        Box(Modifier.padding(horizontal = 24.dp)) { FailedLibrary(state.error, viewModel::refresh) }
                    }
                    !state.isLoaded -> item { LibraryLoading() }
                    else -> {
                        item {
                            Text(if (state.games.isEmpty()) "Vos aventures commencent ici." else "${state.games.size} aventure${if (state.games.size > 1) "s" else ""}",
                                Modifier.padding(horizontal = 24.dp).padding(bottom = 12.dp), color = palette.muted, fontSize = 14.sp)
                        }
                        if (state.games.isEmpty()) item {
                            Box(Modifier.padding(horizontal = 24.dp)) { EmptyLibrary(enabled, importGame) }
                        } else {
                            item {
                                FeaturedGames(InstalledGame.featuredOrder(state.games), viewport, enabled, viewModel, onQuickView)
                            }
                            item {
                                Text("Ma collection", Modifier.padding(horizontal = 24.dp),
                                    fontSize = 22.sp, fontWeight = FontWeight.Bold, color = palette.text)
                            }
                            items(collection.size) { rowIndex ->
                                Row(
                                    Modifier.fillMaxWidth().padding(horizontal = 24.dp),
                                    horizontalArrangement = Arrangement.spacedBy(14.dp),
                                ) {
                                    collection[rowIndex].forEach { game ->
                                        Box(Modifier.weight(1f), contentAlignment = Alignment.TopStart) {
                                            if (game == null) AddGameCard(enabled, importGame)
                                            else CollectionCard(game, enabled, viewModel, onQuickView)
                                        }
                                    }
                                    repeat(columns - collection[rowIndex].size) { Spacer(Modifier.weight(1f)) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun FeaturedGames(
    games: List<InstalledGame>,
    viewport: Float,
    enabled: Boolean,
    viewModel: GameLibraryViewModel,
    onQuickView: (InstalledGame) -> Unit,
) {
    val palette = avelunePalette
    val cardWidth = (viewport - 64).coerceAtMost(600f).coerceAtLeast(120f)
    val pager = rememberPagerState { games.size }
    Column(Modifier.padding(bottom = 12.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Text("À la une", Modifier.padding(horizontal = 24.dp), fontSize = 22.sp, fontWeight = FontWeight.Bold, color = palette.text)
        HorizontalPager(
            pager,
            pageSize = PageSize.Fixed(cardWidth.dp),
            contentPadding = PaddingValues(horizontal = ((viewport - cardWidth) / 2).dp),
            pageSpacing = 12.dp,
            modifier = Modifier.height(292.dp),
        ) { page ->
            val game = games[page]
            FeaturedCard(game, enabled, { viewModel.play(game.id) }, { viewModel.select(game.id) }, { onQuickView(game) })
        }
        if (games.size > 1) Row(
            Modifier.fillMaxWidth().semantics { contentDescription = "Jeu ${pager.currentPage + 1} sur ${games.size}" },
            horizontalArrangement = Arrangement.spacedBy(7.dp, Alignment.CenterHorizontally),
        ) {
            games.indices.forEach { index ->
                Box(Modifier.width(if (pager.currentPage == index) 18.dp else 7.dp).height(7.dp)
                    .background(if (pager.currentPage == index) palette.lilac else palette.muted.copy(alpha = 0.35f), CircleShape))
            }
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun FeaturedCard(game: InstalledGame, enabled: Boolean, play: () -> Unit, details: () -> Unit, quick: () -> Unit) {
    val palette = avelunePalette
    val style = artworkStyle(game)
    Box(
        Modifier.fillMaxSize().clip(RoundedCornerShape(26.dp)).border(1.dp, palette.border, RoundedCornerShape(26.dp))
            .focusRing(26).combinedClickable(enabled = enabled, onClick = details, onLongClick = quick),
    ) {
        AveluneArtwork(game.heroArtworkPaths, style, Modifier.fillMaxSize())
        ArtworkScrim()
        Column(Modifier.align(Alignment.BottomStart).fillMaxWidth().padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(game.title, fontSize = 28.sp, fontFamily = FontFamily.Serif, fontWeight = FontWeight.Bold,
                color = palette.artworkText, maxLines = 2, overflow = TextOverflow.Ellipsis)
            if (game.author.isNotBlank()) Text(game.author, color = palette.artworkText.copy(alpha = 0.8f),
                fontSize = 14.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                AveluneButton(if (game.canContinue) "Reprendre" else "Jouer", play, Modifier.weight(1f),
                    enabled, Icons.Outlined.PlayArrow, actionColor = style.action)
                AveluneButton("Détails", details, Modifier.weight(1f), enabled, Icons.Outlined.Info)
            }
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun CollectionCard(game: InstalledGame, enabled: Boolean, viewModel: GameLibraryViewModel, quick: (InstalledGame) -> Unit) {
    val palette = avelunePalette
    var options by remember(game.id) { mutableStateOf(false) }
    Box(Modifier.widthIn(max = 210.dp).fillMaxWidth().aspectRatio(0.72f)) {
        Box(
            Modifier.fillMaxSize().clip(RoundedCornerShape(20.dp)).border(1.dp, palette.border, RoundedCornerShape(20.dp))
                .focusRing(20).combinedClickable(enabled = enabled, onClick = { viewModel.select(game.id) }, onLongClick = { quick(game) })
                .semantics { contentDescription = "${game.title}, voir la fiche" },
        ) {
            AveluneArtwork(game.artworkPaths, artworkStyle(game), Modifier.fillMaxSize())
            ArtworkScrim(opacity = 0.68f)
            Text(game.title, Modifier.align(Alignment.BottomStart).padding(12.dp), color = palette.artworkText,
                fontSize = 17.sp, fontFamily = FontFamily.Serif, maxLines = 2, overflow = TextOverflow.Ellipsis)
        }
        Box(Modifier.align(Alignment.TopEnd).padding(8.dp)) {
            AveluneIconButton(Icons.Outlined.MoreHoriz, "Options pour ${game.title}", { options = true }, enabled = enabled)
            DropdownMenu(options, { options = false }, modifier = Modifier.popupGamepadKeys { options = false }) {
                DropdownMenuItem(text = { Text("Voir la fiche") }, onClick = { options = false; viewModel.select(game.id) })
                DropdownMenuItem(text = { Text("Supprimer le jeu") }, onClick = { options = false; viewModel.requestUninstall(game.id) }, enabled = enabled)
            }
        }
    }
}

@Composable
private fun AddGameCard(enabled: Boolean, importGame: () -> Unit) {
    val palette = avelunePalette
    Surface(
        onClick = importGame, enabled = enabled,
        modifier = Modifier.widthIn(max = 210.dp).fillMaxWidth().aspectRatio(0.72f).focusRing(20)
            .border(1.dp, palette.border, RoundedCornerShape(20.dp)),
        shape = RoundedCornerShape(20.dp),
        color = palette.surface.copy(alpha = 0.5f),
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterVertically)) {
            Box(Modifier.size(58.dp).background(palette.lilac.copy(alpha = 0.14f), CircleShape), contentAlignment = Alignment.Center) {
                Icon(Icons.Outlined.Add, null, Modifier.size(25.dp), tint = palette.text)
            }
            Text("Ajouter un jeu", color = palette.text, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
        }
    }
}

@Composable
private fun GameDetail(game: InstalledGame, enabled: Boolean, viewModel: GameLibraryViewModel) {
    val palette = avelunePalette
    val style = artworkStyle(game)
    var expanded by rememberSaveable(game.id) { mutableStateOf(false) }
    val backFocus = remember(game.id) { FocusRequester() }
    LaunchedEffect(game.id) { backFocus.requestFocus() }
    AveluneBackground(accent = style.glow) {
        Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(top = 12.dp, bottom = 36.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp)) {
            Row(Modifier.padding(horizontal = 24.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                AveluneIconButton(Icons.AutoMirrored.Outlined.ArrowBack, "Retour à la bibliothèque", { viewModel.select(null) }, Modifier.focusRequester(backFocus))
                AveluneMoon(Modifier.size(38.dp).clip(RoundedCornerShape(10.dp)))
                Text("Avelune", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = palette.text)
            }
            Box(Modifier.padding(horizontal = 20.dp).fillMaxWidth().height(300.dp).clip(RoundedCornerShape(28.dp))) {
                AveluneArtwork(game.heroArtworkPaths, style, Modifier.fillMaxSize())
                ArtworkScrim(opacity = 0.7f)
                Text(game.title, Modifier.align(Alignment.BottomStart).padding(22.dp),
                    fontSize = 34.sp, fontFamily = FontFamily.Serif, fontWeight = FontWeight.Bold, color = palette.artworkText)
            }
            Column(Modifier.padding(horizontal = 24.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
                AveluneButton(if (game.canContinue) "Reprendre" else "Jouer", { viewModel.play(game.id) },
                    Modifier.fillMaxWidth(), enabled, Icons.Outlined.PlayArrow, actionColor = style.action)
                game.description?.takeIf(String::isNotBlank)?.let { description ->
                    InformationPanel {
                        Text("À propos de ce jeu", color = palette.text, fontSize = 22.sp, fontWeight = FontWeight.Bold)
                        Text(description, color = palette.muted, maxLines = if (expanded) Int.MAX_VALUE else 4)
                        if (description.length > 180) TextButton({ expanded = !expanded }) { Text(if (expanded) "Voir moins" else "Voir plus", color = style.action) }
                    }
                }
                InformationPanel {
                    Text("Informations", color = palette.text, fontSize = 22.sp, fontWeight = FontWeight.Bold)
                    if (game.author.isNotBlank()) InformationRow("Créé par", game.author, Icons.Outlined.PersonOutline, style)
                    game.publisher?.takeIf(String::isNotBlank)?.let { InformationRow("Édité par", it, Icons.Outlined.Business, style) }
                    game.version?.takeIf(String::isNotBlank)?.let { InformationRow("Version", it, Icons.Outlined.Tag, style) }
                    if (game.supportedLocales.isNotEmpty()) InformationRow("Langues", game.supportedLocales.joinToString(", ") {
                        Locale.forLanguageTag(it.replace('_', '-')).getDisplayName(Locale.FRENCH)
                    }, Icons.Outlined.Language, style)
                    game.lastPlayedAt?.let { played ->
                        InformationRow("Dernière partie", DateFormat.getDateTimeInstance(DateFormat.MEDIUM, DateFormat.SHORT, Locale.FRENCH)
                            .format(Date.from(played)), Icons.Outlined.Schedule, style)
                    }
                    if (game.playTimeSeconds > 0) {
                        val minutes = game.playTimeSeconds / 60
                        val duration = if (minutes >= 60) "${minutes / 60} h ${minutes % 60} min" else "$minutes min"
                        InformationRow("Temps de jeu", duration, Icons.Outlined.Timer, style)
                    }
                }
            }
        }
    }
}

@Composable
private fun InformationPanel(content: @Composable androidx.compose.foundation.layout.ColumnScope.() -> Unit) {
    Surface(color = avelunePalette.surface, shape = RoundedCornerShape(22.dp), modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(14.dp), content = content)
    }
}

@Composable
private fun InformationRow(title: String, value: String, icon: ImageVector, style: AveluneArtworkStyle) {
    val palette = avelunePalette
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.Top) {
        Icon(icon, null, Modifier.width(22.dp).height(22.dp), tint = style.action)
        Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(title, color = palette.muted, fontSize = 12.sp)
            Text(value, color = palette.text, fontSize = 14.sp)
        }
    }
}

@Composable
private fun QuickGameView(game: InstalledGame, enabled: Boolean, onClose: () -> Unit, onPlay: () -> Unit, onDetails: () -> Unit) {
    val palette = avelunePalette
    val closeFocus = remember(game.id) { FocusRequester() }
    Dialog(onClose, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        AveluneDialogGamepadKeys(onClose)
        LaunchedEffect(game.id) { closeFocus.requestFocus() }
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Box(Modifier.fillMaxSize().background(palette.background.copy(alpha = 0.65f)).pointerInput(Unit) { detectTapGestures { onClose() } })
            Surface(
                color = palette.surface, shape = RoundedCornerShape(28.dp),
                modifier = Modifier.padding(horizontal = 20.dp).widthIn(max = 600.dp).fillMaxWidth().heightIn(max = 620.dp)
                    .border(1.dp, palette.border, RoundedCornerShape(28.dp))
                    .pointerInput(Unit) { detectTapGestures { } },
            ) {
                Column(Modifier.verticalScroll(rememberScrollState())) {
                    Box(Modifier.fillMaxWidth().height(240.dp)) {
                        AveluneArtwork(game.heroArtworkPaths, artworkStyle(game), Modifier.fillMaxSize())
                        AveluneIconButton(Icons.Outlined.Close, "Fermer l’aperçu", onClose,
                            Modifier.align(Alignment.TopEnd).padding(12.dp).focusRequester(closeFocus))
                    }
                    Column(Modifier.padding(22.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                        Text(game.title, color = palette.text, fontSize = 34.sp, fontFamily = FontFamily.Serif, fontWeight = FontWeight.Bold)
                        game.description?.takeIf(String::isNotBlank)?.let { Text(it, color = palette.muted, maxLines = 4, overflow = TextOverflow.Ellipsis) }
                        game.lastPlayedAt?.let {
                            Text("Dernière partie : ${DateFormat.getDateInstance(DateFormat.MEDIUM, Locale.FRENCH).format(Date.from(it))}",
                                color = palette.muted, fontSize = 14.sp)
                        }
                        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            AveluneButton(if (game.canContinue) "Reprendre" else "Jouer", onPlay, Modifier.weight(1f),
                                enabled, Icons.Outlined.PlayArrow, actionColor = artworkStyle(game).action)
                            AveluneButton("Voir la fiche", onDetails, Modifier.weight(1f), enabled)
                        }
                    }
                }
            }
        }
    }
}
