package com.yoahnl.avelune.player.runtime

import android.content.Context
import android.hardware.input.InputManager
import android.os.Handler
import android.os.StatFs
import com.yoahnl.avelune.host.InstalledGame
import com.yoahnl.avelune.player.display.DisplayCapabilityAdapter
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
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
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

interface RuntimeLibraryPort {
    suspend fun listGames(): List<InstalledGame>
    suspend fun install(packagePath: String): InstalledGame
    suspend fun uninstall(gameId: String): List<InstalledGame>
    suspend fun play(gameId: String)
}

data class RuntimeRecoveryState(val isStopping: Boolean = false, val error: String? = null)

class RuntimeSession(context: Context, displays: DisplayCapabilityAdapter) : RuntimeLibraryPort {
    private val engineGroup = FlutterEngineGroup(context.applicationContext)
    val engine: FlutterEngine = engineGroup.createAndRunEngine(
        FlutterEngineGroup.Options(context.applicationContext).setAutomaticallyRegisterPlugins(false),
    )
    private val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "com.avelune.runtime/library")
    private val platform = MethodChannel(engine.dartExecutor.binaryMessenger, "com.yoahnl.avelune.player/android")
    private val inputManager = context.getSystemService(InputManager::class.java)
    private val inputListeners = mutableSetOf<InputManager.InputDeviceListener>()
    private val ready = CompletableDeferred<Unit>()
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var pendingGameId: String? = null
    private var startJob: Job? = null
    private var stopJob: Job? = null
    private var playbackError: String? = null
    private var isClosed = false
    private val mutablePresentationFailure = MutableStateFlow<String?>(null)
    private val mutableRecovery = MutableStateFlow(RuntimeRecoveryState())
    private val mutableActiveGame = MutableStateFlow<String?>(null)
    val activeGame: StateFlow<String?> = mutableActiveGame.asStateFlow()
    val presentationFailure = mutablePresentationFailure.asStateFlow()
    val recovery = mutableRecovery.asStateFlow()
    val surfaceProbe = SurfaceProbeSession(context, engine, engineGroup, displays, ::awaitReady)
    val gameplayCompanion = RuntimeCompanionSession(context, engine, engineGroup, displays)

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "runtimeReady" -> {
                    ready.complete(Unit)
                    result.success(null)
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

    override suspend fun listGames(): List<InstalledGame> = InstalledGame.listFromPayload(invoke("listGames"))

    override suspend fun install(packagePath: String): InstalledGame {
        check(surfaceProbe.activeSession.value == null) { "Ferme le test des écrans avant d’importer un jeu." }
        val payload = invoke("installGame", mapOf("packagePath" to packagePath))
        require(payload is Map<*, *>) { "Réponse inattendue après l’import du jeu." }
        return InstalledGame.fromPayload(payload)
    }

    override suspend fun uninstall(gameId: String): List<InstalledGame> {
        check(surfaceProbe.activeSession.value == null) { "Ferme le test des écrans avant de désinstaller un jeu." }
        return InstalledGame.listFromPayload(invoke("uninstallGame", mapOf("gameId" to gameId)))
    }

    override suspend fun play(gameId: String) {
        awaitReady()
        check(surfaceProbe.activeSession.value == null) { "Ferme le test des écrans avant de lancer un jeu." }
        check(mutableActiveGame.value == null && stopJob?.isActive != true) {
            "Un jeu est déjà en cours de lecture ou de fermeture."
        }
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
            } catch (error: Exception) {
                playbackError = error.message ?: "Le jeu n’a pas pu être lancé."
                mutablePresentationFailure.value = playbackError
            }
        }
    }

    fun requestStop() {
        if (stopJob?.isActive == true) return
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
            } catch (error: Exception) {
                playbackError = error.message ?: "Le jeu n’a pas pu être fermé correctement."
                mutableRecovery.value = RuntimeRecoveryState(error = playbackError)
            }
        }
    }

    fun consumePlaybackError(): String? = playbackError.also {
        playbackError = null
    }

    fun registerInputDeviceListener(listener: InputManager.InputDeviceListener, handler: Handler?) {
        if (inputListeners.add(listener)) inputManager.registerInputDeviceListener(listener, handler)
    }

    suspend fun prepareSurfaceProbe(): String {
        awaitReady()
        check(mutableActiveGame.value == null && stopJob?.isActive != true) {
            "Ferme la partie en cours avant de tester les deux écrans."
        }
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
        val cache = FlutterEngineCache.getInstance()
        if (cache.get(ENGINE_ID) === engine) cache.remove(ENGINE_ID)
        engine.destroy()
        isClosed = true
    }

    private suspend fun invoke(method: String, arguments: Map<String, Any>? = null): Any? {
        awaitReady()
        if (method == "installGame") return awaitResponse(method, arguments)
        val reply = withTimeoutOrNull(40_000) { RuntimeReply(awaitResponse(method, arguments)) }
        check(reply != null) { "Le moteur Avelune n’a pas répondu à temps. Réessaie l’action." }
        return reply.value
    }

    private suspend fun awaitResponse(method: String, arguments: Map<String, Any>?): Any? =
        suspendCancellableCoroutine { continuation ->
            channel.invokeMethod(method, arguments, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    if (continuation.isActive) continuation.resume(result)
                }

                override fun error(code: String, message: String?, details: Any?) {
                    if (continuation.isActive) continuation.resumeWithException(RuntimeException(message ?: code))
                }

                override fun notImplemented() {
                    if (continuation.isActive) continuation.resumeWithException(
                        IllegalStateException("Le moteur Avelune ne prend pas en charge cette action."),
                    )
                }
            })
        }

    private suspend fun awaitReady() {
        check(withTimeoutOrNull(40_000) { ready.await(); true } == true) {
            "Le moteur Avelune n’est pas encore prêt. Réessaie dans quelques instants."
        }
    }

    companion object {
        const val ENGINE_ID = "avelune_runtime"
    }

    private data class RuntimeReply(val value: Any?)
}
