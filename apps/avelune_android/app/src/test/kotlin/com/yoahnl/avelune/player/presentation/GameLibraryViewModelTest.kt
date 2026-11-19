package com.yoahnl.avelune.player.presentation

import com.yoahnl.avelune.host.InstalledGame
import com.yoahnl.avelune.player.R
import com.yoahnl.avelune.player.localization.NativeFailure
import com.yoahnl.avelune.player.localization.NativeMessage
import com.yoahnl.avelune.player.runtime.RuntimeLibraryPort
import com.yoahnl.avelune.player.runtime.runtimeChannelFailure
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class GameLibraryViewModelTest {
    private val dispatcher = StandardTestDispatcher()

    @Before
    fun setUp() {
        Dispatchers.setMain(dispatcher)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun initialLoadingCannotAppearAsAnEmptyLibrary() = runTest(dispatcher) {
        val port = FakeRuntime()
        port.listGate = CompletableDeferred()
        val viewModel = GameLibraryViewModel(port) { error("Picker unused") }
        advanceUntilIdle()

        assertFalse(viewModel.state.value.isLoaded)
        assertEquals(R.string.library_busy_loading, viewModel.state.value.busy)
        port.listGate!!.complete(Unit)
        advanceUntilIdle()

        assertTrue(viewModel.state.value.isLoaded)
        assertEquals(listOf(port.game), viewModel.state.value.games)
    }

    @Test
    fun failedInitialLoadCanBeRetriedWithoutShowingEmptyContent() = runTest(dispatcher) {
        val port = FakeRuntime()
        port.listError = IllegalStateException("Lecture impossible")
        val viewModel = GameLibraryViewModel(port) { error("Picker unused") }
        advanceUntilIdle()

        assertFalse(viewModel.state.value.isLoaded)
        assertEquals(NativeMessage(R.string.error_library_load), viewModel.state.value.error)
        port.listError = null
        viewModel.refresh()
        advanceUntilIdle()

        assertTrue(viewModel.state.value.isLoaded)
        assertNull(viewModel.state.value.error)
    }

    @Test
    fun refreshFailureIsVisibleAndPreservesTheInstalledLibrary() = runTest(dispatcher) {
        val port = FakeRuntime()
        val viewModel = GameLibraryViewModel(port) { error("Picker unused") }
        advanceUntilIdle()
        port.listError = NativeFailure(R.string.error_unexpected_library_response, code = "badPayload")

        viewModel.refresh()
        advanceUntilIdle()

        assertEquals(listOf(port.game), viewModel.state.value.games)
        assertEquals(NativeMessage(R.string.error_unexpected_library_response, code = "badPayload"), viewModel.state.value.error)
        assertNull(viewModel.state.value.busy)
    }

    @Test
    fun duplicatePlayWhileLaunchingDoesNotCreateAnotherSession() = runTest(dispatcher) {
        val port = FakeRuntime()
        val viewModel = GameLibraryViewModel(port) { error("Picker unused") }
        advanceUntilIdle()
        port.playGate = CompletableDeferred()

        viewModel.play("clairbois")
        viewModel.play("clairbois")
        advanceUntilIdle()

        assertEquals(1, port.playCalls)
        assertEquals(R.string.library_busy_opening, viewModel.state.value.busy)
        port.playGate!!.complete(Unit)
        advanceUntilIdle()
        assertNull(viewModel.state.value.busy)
    }

    @Test
    fun uninstallRemovesSelectionOnlyAfterSuccess() = runTest(dispatcher) {
        val port = FakeRuntime()
        val viewModel = GameLibraryViewModel(port) { error("Picker unused") }
        advanceUntilIdle()
        viewModel.select("clairbois")
        port.uninstallError = runtimeChannelFailure("uninstallGame", "installation.uninstallFallbackRequired", null)

        viewModel.uninstall("clairbois")
        advanceUntilIdle()

        assertEquals("clairbois", viewModel.state.value.selectedGameId)
        assertFalse(viewModel.state.value.games.isEmpty())
        assertEquals(
            NativeMessage(R.string.error_uninstall_fallback, code = "installation.uninstallFallbackRequired"),
            viewModel.state.value.error,
        )
        port.uninstallError = null
        viewModel.uninstall("clairbois")
        advanceUntilIdle()
        assertNull(viewModel.state.value.selectedGameId)
        assertTrue(viewModel.state.value.games.isEmpty())
    }

    private class FakeRuntime : RuntimeLibraryPort {
        val game = InstalledGame("clairbois", "Clairbois")
        var listError: Exception? = null
        var uninstallError: Exception? = null
        var playCalls = 0
        var playGate: CompletableDeferred<Unit>? = null
        var listGate: CompletableDeferred<Unit>? = null

        override suspend fun listGames(): List<InstalledGame> {
            listGate?.await()
            listError?.let { throw it }
            return listOf(game)
        }

        override suspend fun install(packagePath: String): InstalledGame = game

        override suspend fun uninstall(gameId: String): List<InstalledGame> {
            uninstallError?.let { throw it }
            return emptyList()
        }

        override suspend fun play(gameId: String) {
            playCalls++
            playGate?.await()
        }
    }
}
