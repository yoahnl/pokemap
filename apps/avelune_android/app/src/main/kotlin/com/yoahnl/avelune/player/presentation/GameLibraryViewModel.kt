package com.yoahnl.avelune.player.presentation

import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.yoahnl.avelune.host.InstalledGame
import com.yoahnl.avelune.player.runtime.RuntimeLibraryPort
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.io.File

data class GameLibraryState(
    val games: List<InstalledGame> = emptyList(),
    val selectedGameId: String? = null,
    val uninstallGameId: String? = null,
    val busy: String? = null,
    val error: String? = null,
    val notice: String? = null,
    val isLoaded: Boolean = false,
    val installationStage: LibraryInstallationStage? = null,
    val installationName: String? = null,
) {
    val selectedGame: InstalledGame? get() = games.firstOrNull { it.id == selectedGameId }
    val uninstallGame: InstalledGame? get() = games.firstOrNull { it.id == uninstallGameId }
}

enum class LibraryInstallationStage(val title: String, val detail: String) {
    PREPARING("Préparation du fichier", "Copie de votre fichier dans Avelune."),
    INSTALLING("Installation du jeu", "Avelune ajoute votre jeu à la bibliothèque."),
    FINISHING("Actualisation de la bibliothèque", "Vos aventures se préparent à être lancées."),
}

class GameLibraryViewModel(
    private val runtime: RuntimeLibraryPort,
    private val stagePackage: suspend (Uri) -> File,
) : ViewModel() {
    private val mutableState = MutableStateFlow(GameLibraryState())
    private val launchEvents = Channel<Unit>(Channel.BUFFERED)
    val state = mutableState.asStateFlow()
    val launches = launchEvents.receiveAsFlow()

    init {
        refresh()
    }

    fun refresh() = operation("Préparation de la bibliothèque…") {
        val games = runtime.listGames()
        mutableState.update {
            it.copy(games = games, isLoaded = true, selectedGameId = it.selectedGameId?.takeIf { id -> games.any { game -> game.id == id } })
        }
    }

    fun select(gameId: String?) {
        mutableState.update { it.copy(selectedGameId = gameId) }
    }

    fun requestUninstall(gameId: String?) {
        mutableState.update { it.copy(uninstallGameId = gameId) }
    }

    fun dismissMessage() {
        mutableState.update { it.copy(error = null, notice = null) }
    }

    fun showError(message: String) {
        mutableState.update { it.copy(error = message, notice = null) }
    }

    fun importPackage(uri: Uri) = operation("Import du jeu…") {
        mutableState.update { it.copy(installationStage = LibraryInstallationStage.PREPARING, installationName = null) }
        val staged = stagePackage(uri)
        try {
            mutableState.update { it.copy(installationStage = LibraryInstallationStage.INSTALLING) }
            val game = runtime.install(staged.absolutePath)
            mutableState.update { it.copy(installationStage = LibraryInstallationStage.FINISHING, installationName = game.title) }
            val games = runtime.listGames()
            mutableState.update {
                it.copy(games = games, isLoaded = true, selectedGameId = game.id, notice = "${game.title} a été importé.")
            }
        } finally {
            staged.delete()
        }
    }

    fun uninstall(gameId: String) = operation("Désinstallation du jeu…") {
        mutableState.update { it.copy(uninstallGameId = null) }
        val games = runtime.uninstall(gameId)
        mutableState.update {
            it.copy(games = games, selectedGameId = null, notice = "Le jeu a été désinstallé.")
        }
    }

    fun play(gameId: String) = operation("Ouverture du jeu…") {
        runtime.play(gameId)
        launchEvents.send(Unit)
    }

    private fun operation(label: String, action: suspend () -> Unit) {
        viewModelScope.launch {
            if (mutableState.value.busy != null) return@launch
            mutableState.update { it.copy(busy = label, error = null, notice = null) }
            try {
                action()
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                mutableState.update { it.copy(error = error.message ?: "L’action n’a pas pu être terminée.") }
            } finally {
                mutableState.update { it.copy(busy = null, installationStage = null, installationName = null) }
            }
        }
    }
}
