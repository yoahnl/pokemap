package com.yoahnl.avelune.player.presentation

import android.net.Uri
import androidx.annotation.StringRes
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.yoahnl.avelune.host.InstalledGame
import com.yoahnl.avelune.player.R
import com.yoahnl.avelune.player.localization.NativeMessage
import com.yoahnl.avelune.player.runtime.RuntimeLibraryPort
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.io.File

internal data class GameLibraryState(
    val games: List<InstalledGame> = emptyList(),
    val selectedGameId: String? = null,
    val uninstallGameId: String? = null,
    @get:StringRes val busy: Int? = null,
    val error: NativeMessage? = null,
    val notice: NativeMessage? = null,
    val isLoaded: Boolean = false,
    val installationStage: LibraryInstallationStage? = null,
    val installationName: String? = null,
) {
    val selectedGame: InstalledGame? get() = games.firstOrNull { it.id == selectedGameId }
    val uninstallGame: InstalledGame? get() = games.firstOrNull { it.id == uninstallGameId }
}

internal enum class LibraryInstallationStage(@get:StringRes val title: Int, @get:StringRes val detail: Int) {
    PREPARING(R.string.install_step_preparing, R.string.install_detail_preparing),
    INSTALLING(R.string.install_step_installing, R.string.install_detail_installing),
    FINISHING(R.string.install_step_finishing, R.string.install_detail_finishing),
}

internal class GameLibraryViewModel(
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

    fun refresh() = operation(R.string.library_busy_loading, R.string.error_library_load) {
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

    fun showError(message: NativeMessage) {
        mutableState.update { it.copy(error = message, notice = null) }
    }

    fun importPackage(uri: Uri) = operation(R.string.library_busy_importing, R.string.error_game_import) {
        mutableState.update { it.copy(installationStage = LibraryInstallationStage.PREPARING, installationName = null) }
        val staged = stagePackage(uri)
        try {
            mutableState.update { it.copy(installationStage = LibraryInstallationStage.INSTALLING) }
            val game = runtime.install(staged.absolutePath)
            mutableState.update { it.copy(installationStage = LibraryInstallationStage.FINISHING, installationName = game.title) }
            val games = runtime.listGames()
            mutableState.update {
                it.copy(
                    games = games,
                    isLoaded = true,
                    selectedGameId = game.id,
                    notice = NativeMessage(R.string.library_notice_imported, listOf(game.title)),
                )
            }
        } finally {
            staged.delete()
        }
    }

    fun uninstall(gameId: String) = operation(R.string.library_busy_uninstalling, R.string.error_game_uninstall) {
        mutableState.update { it.copy(uninstallGameId = null) }
        val games = runtime.uninstall(gameId)
        mutableState.update {
            it.copy(games = games, selectedGameId = null, notice = NativeMessage(R.string.library_notice_uninstalled))
        }
    }

    fun play(gameId: String) = operation(R.string.library_busy_opening, R.string.error_game_start) {
        runtime.play(gameId)
        launchEvents.send(Unit)
    }

    private fun operation(@StringRes label: Int, @StringRes failure: Int, action: suspend () -> Unit) {
        viewModelScope.launch {
            if (mutableState.value.busy != null) return@launch
            mutableState.update { it.copy(busy = label, error = null, notice = null) }
            try {
                action()
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                mutableState.update { it.copy(error = NativeMessage.fromError(error, failure)) }
            } finally {
                mutableState.update { it.copy(busy = null, installationStage = null, installationName = null) }
            }
        }
    }
}
