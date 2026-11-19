package com.yoahnl.avelune.player.runtime

import android.content.Context
import android.content.res.Configuration
import android.hardware.input.InputManager
import android.os.Handler
import android.os.StatFs
import android.util.Log
import com.yoahnl.avelune.host.InstalledGame
import com.yoahnl.avelune.player.R
import com.yoahnl.avelune.player.display.DisplayCapabilityAdapter
import com.yoahnl.avelune.player.localization.NativeFailure
import com.yoahnl.avelune.player.localization.NativeMessage
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

interface RuntimeLibraryPort {
    suspend fun listGames(): List<InstalledGame>
    suspend fun install(packagePath: String): InstalledGame
    suspend fun uninstall(gameId: String): List<InstalledGame>
    suspend fun play(gameId: String)
}

internal data class RuntimeRecoveryState(val isStopping: Boolean = false, val error: NativeMessage? = null)

class RuntimeSession(context: Context, displays: DisplayCapabilityAdapter) : RuntimeLibraryPort {
    private val engineGroup = FlutterEngineGroup(context.applicationContext)
    val engine: FlutterEngine = engineGroup.createAndRunEngine(
        FlutterEngineGroup.Options(context.applicationContext).setAutomaticallyRegisterPlugins(false),
    )
    private val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "com.avelune.runtime/library")
    private val platform = MethodChannel(engine.dartExecutor.binaryMessenger, "com.yoahnl.avelune.player/android")
    private val diagnostics = MethodChannel(engine.dartExecutor.binaryMessenger, "com.avelune.runtime/diagnostics")
    private val frameRateChannel = MethodChannel(engine.dartExecutor.binaryMessenger, "com.avelune.runtime/frame_rate")
    private val frameRate = RuntimeFrameRate()
    private val settings = context.getSharedPreferences("avelune_settings", Context.MODE_PRIVATE)
    private val inputManager = context.getSystemService(InputManager::class.java)
    private val inputListeners = mutableSetOf<InputManager.InputDeviceListener>()
    private val ready = CompletableDeferred<Unit>()
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var pendingGameId: String? = null
    private var startJob: Job? = null
    private var stopJob: Job? = null
    private var playbackError: NativeMessage? = null
    private var isClosed = false
    private val language = LanguagePreferencesController(
        read = { invoke("getLanguagePreferences") },
        write = { choice -> invoke("setAppLanguage", mapOf("appLanguage" to choice.wireValue)) },
    )
    private val mutablePresentationFailure = MutableStateFlow<NativeMessage?>(null)
    private val mutableRecovery = MutableStateFlow(RuntimeRecoveryState())
    private val mutableActiveGame = MutableStateFlow<String?>(null)
    val activeGame: StateFlow<String?> = mutableActiveGame.asStateFlow()
    internal val applicationLanguage = language.state
    internal val presentationFailure = mutablePresentationFailure.asStateFlow()
    internal val recovery = mutableRecovery.asStateFlow()
    val frameRateLimit: StateFlow<Int> = frameRate.limit
    val surfaceProbe = SurfaceProbeSession(context, engine, engineGroup, displays, ::awaitReady)
    val gameplayCompanion = RuntimeCompanionSession(context, engine, engineGroup, displays)

    init {
        frameRateChannel.setMethodCallHandler { call, result ->
            if (call.method == "setLimit") {
                try {
                    frameRate.setLimit(call.arguments)
                    result.success(null)
                } catch (error: IllegalArgumentException) {
                    result.error("invalidArguments", "Limite d’images par seconde invalide.", null)
                }
            } else {
                result.notImplemented()
            }
        }
        diagnostics.setMethodCallHandler { call, result ->
            if (call.method == "processSample") {
                scope.launch {
                    withContext(Dispatchers.IO) { runCatching { NativeProcessMetrics.read(context.applicationContext) } }
                        .onSuccess(result::success)
                        .onFailure { result.error("metricsUnavailable", "Mesures du processus indisponibles.", null) }
                }
            } else {
                result.notImplemented()
            }
        }
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "runtimeReady" -> {
                    val becameReady = ready.complete(Unit)
                    result.success(null)
                    if (becameReady) refreshLanguagePreferences()
                }
                "languagePreferencesChanged" -> {
                    if (language.acceptNotification(call.arguments)) {
                        result.success(null)
                    } else {
                        result.error("invalidLanguagePreferences", "Invalid application language preferences.", null)
                    }
                }
                "playerDidExit" -> {
                    gameplayCompanion.beginStop()
                    scope.launch {
                        gameplayCompanion.stopTransport()
                        mutableActiveGame.value = null
                        mutableRecovery.value = RuntimeRecoveryState()
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        platform.setMethodCallHandler { call, result ->
            when (call.method) {
                "availableDiskBytes" -> runCatching { StatFs(context.filesDir.absolutePath).availableBytes }
                    .onSuccess(result::success)
                    .onFailure { result.error("diskCapacityFailed", "Impossible de lire l’espace disponible.", null) }
                "displayTopology" -> result.success(displays.topology.value.diagnostics())
                else -> result.notImplemented()
            }
        }
        GeneratedPluginRegistrant.registerWith(engine)
        FlutterEngineCache.getInstance().put(ENGINE_ID, engine)
    }

    internal fun refreshLanguagePreferences(systemConfiguration: Configuration? = null) {
        if (isClosed) return
        systemConfiguration?.let(engine.localizationPlugin::sendLocalesToFlutter)
        scope.launch { language.refresh() }
    }

    internal fun setAppLanguage(choice: AppLanguage) {
        scope.launch { language.select(choice) }
    }

    override suspend fun listGames(): List<InstalledGame> {
        val payload = invoke("listGames")
        return decodeLibraryResponse { InstalledGame.listFromPayload(payload) }
    }

    override suspend fun install(packagePath: String): InstalledGame {
        requireDisplayTestClosed()
        val payload = invoke("installGame", mapOf("packagePath" to packagePath))
        return decodeLibraryResponse {
            require(payload is Map<*, *>)
            InstalledGame.fromPayload(payload)
        }
    }

    override suspend fun uninstall(gameId: String): List<InstalledGame> {
        requireDisplayTestClosed()
        val payload = invoke("uninstallGame", mapOf("gameId" to gameId))
        return decodeLibraryResponse { InstalledGame.listFromPayload(payload) }
    }

    override suspend fun play(gameId: String) {
        awaitReady()
        requireDisplayTestClosed()
        if (mutableActiveGame.value != null || stopJob?.isActive == true) throw NativeFailure(R.string.error_game_already_playing)
        mutablePresentationFailure.value = null
        mutableRecovery.value = RuntimeRecoveryState()
        gameplayCompanion.prepare()
        pendingGameId = gameId
        mutableActiveGame.value = gameId
    }

    fun startPreparedGame() {
        val gameId = pendingGameId ?: return
        pendingGameId = null
        startJob = scope.launch {
            try {
                gameplayCompanion.startTransport()
                if (stopJob?.isActive == true) return@launch
                invoke("playGame", mapOf("gameId" to gameId))
                diagnostics.invokeMethod("setEnabled", mapOf("enabled" to settings.getBoolean("showDebugInfo", false)))
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                playbackError = NativeMessage.fromError(error, R.string.error_game_start)
                mutablePresentationFailure.value = playbackError
            }
        }
    }

    fun requestStop() {
        if (stopJob?.isActive == true) return
        diagnostics.invokeMethod("setEnabled", mapOf("enabled" to false))
        pendingGameId = null
        gameplayCompanion.beginStop()
        mutableRecovery.value = RuntimeRecoveryState(isStopping = true)
        stopJob = scope.launch {
            startJob?.join()
            try {
                gameplayCompanion.stopTransport()
                if (mutableActiveGame.value != null) invoke("stopGame")
                mutableActiveGame.value = null
                mutableRecovery.value = RuntimeRecoveryState()
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                playbackError = NativeMessage.fromError(error, R.string.error_game_stop)
                mutableRecovery.value = RuntimeRecoveryState(error = playbackError)
            }
        }
    }

    internal fun consumePlaybackError(): NativeMessage? = playbackError.also {
        playbackError = null
    }

    fun registerInputDeviceListener(listener: InputManager.InputDeviceListener, handler: Handler?) {
        if (inputListeners.add(listener)) inputManager.registerInputDeviceListener(listener, handler)
    }

    suspend fun prepareSurfaceProbe(): String {
        awaitReady()
        if (mutableActiveGame.value != null || stopJob?.isActive == true) throw NativeFailure(R.string.error_probe_game_active)
        return surfaceProbe.prepare()
    }

    fun close() {
        if (isClosed) return
        scope.cancel()
        surfaceProbe.close()
        gameplayCompanion.close()
        inputListeners.forEach(inputManager::unregisterInputDeviceListener)
        inputListeners.clear()
        channel.setMethodCallHandler(null)
        platform.setMethodCallHandler(null)
        diagnostics.setMethodCallHandler(null)
        frameRateChannel.setMethodCallHandler(null)
        val cache = FlutterEngineCache.getInstance()
        if (cache.get(ENGINE_ID) === engine) cache.remove(ENGINE_ID)
        engine.destroy()
        isClosed = true
    }

    private fun requireDisplayTestClosed() {
        if (surfaceProbe.activeSession.value != null) throw NativeFailure(R.string.error_display_test_active)
    }

    private inline fun <T> decodeLibraryResponse(decode: () -> T): T = try {
        decode()
    } catch (error: IllegalArgumentException) {
        throw NativeFailure(R.string.error_unexpected_library_response, cause = error)
    }

    private suspend fun invoke(method: String, arguments: Map<String, Any>? = null): Any? {
        awaitReady()
        if (method == "installGame") return awaitResponse(method, arguments)
        val reply = withTimeoutOrNull(40_000) { RuntimeReply(awaitResponse(method, arguments)) }
        if (reply == null) throw NativeFailure(R.string.error_runtime_timeout)
        return reply.value
    }

    private suspend fun awaitResponse(method: String, arguments: Map<String, Any>?): Any? =
        suspendCancellableCoroutine { continuation ->
            channel.invokeMethod(method, arguments, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    if (continuation.isActive) continuation.resume(result)
                }

                override fun error(code: String, message: String?, details: Any?) {
                    Log.w("AveluneRuntime", "$method failed: $code $details")
                    if (continuation.isActive) continuation.resumeWithException(runtimeChannelFailure(method, code, details))
                }

                override fun notImplemented() {
                    if (continuation.isActive) continuation.resumeWithException(
                        NativeFailure(R.string.error_runtime_unsupported),
                    )
                }
            })
        }

    private suspend fun awaitReady() {
        if (withTimeoutOrNull(40_000) { ready.await() } == null) {
            throw NativeFailure(R.string.error_runtime_not_ready)
        }
    }

    companion object {
        const val ENGINE_ID = "avelune_runtime"
    }

    private data class RuntimeReply(val value: Any?)
}
