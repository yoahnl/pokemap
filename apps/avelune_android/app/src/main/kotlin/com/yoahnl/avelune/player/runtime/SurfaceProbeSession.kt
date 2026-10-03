package com.yoahnl.avelune.player.runtime

import android.app.ActivityOptions
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import com.yoahnl.avelune.host.SurfaceProbeRelay
import com.yoahnl.avelune.host.SurfaceProbeWindowLease
import com.yoahnl.avelune.host.SurfaceProbeWindowPolicy
import com.yoahnl.avelune.host.SurfaceProbeWindows
import com.yoahnl.avelune.player.BuildConfig
import com.yoahnl.avelune.player.display.DisplayCapabilityAdapter
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withTimeout
import java.util.UUID
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class SurfaceProbeSession(
    context: Context,
    private val ownerEngine: FlutterEngine,
    private val engineGroup: FlutterEngineGroup,
    private val displays: DisplayCapabilityAdapter,
    private val awaitRuntimeReady: suspend () -> Unit,
) {
    private val context = context.applicationContext
    private val ownerChannel = MethodChannel(ownerEngine.dartExecutor.binaryMessenger, CHANNEL)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val ownerCalls = Mutex()
    private val windows = SurfaceProbeWindows()
    private val presence = MutableStateFlow(false)
    private val mutableActiveSession = MutableStateFlow<String?>(null)
    private val mutableStopError = MutableStateFlow<String?>(null)
    val activeSession = mutableActiveSession.asStateFlow()
    val stopError = mutableStopError.asStateFlow()
    private var relay: SurfaceProbeRelay? = null
    private var ownerActivity: SurfaceProbeActivity? = null
    private var companion: CompanionSurface? = null
    private var ownerVisible = false
    private var companionEnabled = true
    private var started = false
    private var startJob: Job? = null
    private var stopJob: Job? = null
    private var blockedDisplayId: Int? = null
    private var pendingError: String? = null
    private var closed = false

    init {
        if (isEnabled) ownerChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "stateChanged" -> runCatching { acceptSnapshot(call.arguments) }
                    .onSuccess { result.success(null) }
                    .onFailure { result.error("invalidProbeState", it.message, null) }
                "setCompanionEnabled" -> {
                    val enabled = (call.arguments as? Map<*, *>)?.get("enabled") as? Boolean
                    if (enabled == null || relay == null) {
                        result.error("invalidProbeSession", "Le prototype n’est pas actif.", null)
                    } else {
                        companionEnabled = enabled
                        blockedDisplayId = null
                        result.success(null)
                        reconcile()
                    }
                }
                "exit" -> {
                    result.success(null)
                    requestStop()
                }
                else -> result.notImplemented()
            }
        }
        scope.launch {
            displays.topology.collect {
                blockedDisplayId = null
                reconcile()
            }
        }
        scope.launch {
            presence.collect { attached ->
                if (started && relay != null) {
                    runCatching { acceptSnapshot(invokeOwner("setCompanionAttached", mapOf("attached" to attached))) }
                        .onFailure { Log.w(TAG, "Companion attachment could not be reported", it) }
                }
            }
        }
    }

    fun prepare(): String {
        check(isEnabled && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) { "Ce test est disponible uniquement dans la version de debug sur Android 8 ou plus récent." }
        check(!closed && relay == null) { "Le test des écrans est déjà ouvert." }
        val sessionId = UUID.randomUUID().toString()
        relay = SurfaceProbeRelay(sessionId)
        mutableActiveSession.value = sessionId
        mutableStopError.value = null
        companionEnabled = true
        blockedDisplayId = null
        return sessionId
    }

    fun isOwnerSession(sessionId: String?): Boolean = isEnabled && sessionId != null && activeSession.value == sessionId

    fun ownerCreated(activity: SurfaceProbeActivity, sessionId: String?): Boolean {
        if (!isOwnerSession(sessionId) || ownerActivity != null || closed) return false
        ownerActivity = activity
        return true
    }

    fun ownerStarted(activity: SurfaceProbeActivity) {
        if (ownerActivity !== activity) return
        ownerVisible = true
        blockedDisplayId = null
        reconcile()
    }

    fun ownerResumed() {
        val current = relay ?: return
        if (startJob?.isActive == true || stopJob?.isActive == true) return
        if (started) {
            scope.launch {
                runCatching { acceptSnapshot(invokeOwner("snapshot")) }
                    .onFailure { Log.w(TAG, "Owner snapshot could not be refreshed", it) }
            }
            return
        }
        startJob = scope.launch {
            try {
                awaitRuntimeReady()
                acceptSnapshot(invokeOwner("start", mapOf("sessionId" to current.sessionId)))
                started = true
                reconcile()
            } catch (error: Exception) {
                pendingError = error.message ?: "Le test des écrans n’a pas pu démarrer."
                requestStop()
            }
        }
    }

    fun ownerStopped(activity: SurfaceProbeActivity) {
        if (ownerActivity !== activity) return
        ownerVisible = false
        reconcile()
    }

    fun ownerDestroyed(activity: SurfaceProbeActivity) {
        if (ownerActivity !== activity) return
        ownerActivity = null
        ownerVisible = false
        if (activity.isFinishing && relay != null) requestStop()
    }

    fun companionEngine(generation: Long, sessionId: String?): FlutterEngine? =
        companion?.takeIf { isOwnerSession(sessionId) && it.lease.generation == generation && !it.closing && windows.isCurrent(generation) }?.engine

    fun companionCreated(activity: SurfaceProbeCompanionActivity, generation: Long, sessionId: String?, actualDisplayId: Int?): Boolean {
        val surface = companion?.takeIf { it.lease.generation == generation } ?: return false
        surface.activity = activity
        if (!isOwnerSession(sessionId) || surface.closing || !windows.isCurrent(generation) || actualDisplayId != surface.lease.displayId) {
            blockedDisplayId = surface.lease.displayId
            closeCompanion()
            activity.finishAndRemoveTask()
            return false
        }
        return true
    }

    fun companionStarted(activity: SurfaceProbeCompanionActivity, generation: Long) {
        val surface = companion?.takeIf { it.activity === activity && it.lease.generation == generation && !it.closing } ?: return
        surface.visible = true
        presence.value = surface.ready
    }

    fun companionStopped(activity: SurfaceProbeCompanionActivity, generation: Long) {
        val surface = companion?.takeIf { it.activity === activity && it.lease.generation == generation } ?: return
        surface.visible = false
        presence.value = false
    }

    fun companionDestroyed(activity: SurfaceProbeCompanionActivity, generation: Long) {
        val surface = companion?.takeIf { it.activity === activity && it.lease.generation == generation } ?: return
        presence.value = false
        surface.channel.setMethodCallHandler(null)
        surface.engine.destroy()
        companion = null
        windows.select(null)
        reconcile()
    }

    fun requestStop() {
        if (relay == null || stopJob?.isActive == true || closed) return
        mutableStopError.value = null
        stopJob = scope.launch {
            startJob?.join()
            started = false
            closeCompanion()
            try {
                invokeOwner("stop")
                val activity = ownerActivity
                activity?.detachSurface()
                ownerActivity = null
                ownerVisible = false
                relay = null
                mutableActiveSession.value = null
                activity?.finish()
            } catch (error: Exception) {
                started = true
                mutableStopError.value = error.message ?: "Le test des écrans n’a pas pu être fermé."
            }
        }
    }

    fun consumeError(): String? = pendingError.also { pendingError = null }

    fun close() {
        if (closed) return
        closed = true
        scope.cancel()
        ownerChannel.setMethodCallHandler(null)
        ownerActivity?.detachSurface()
        ownerActivity?.finish()
        companion?.let {
            it.channel.setMethodCallHandler(null)
            it.activity?.detachSurface()
            it.activity?.finishAndRemoveTask()
            it.engine.destroy()
        }
        companion = null
        windows.select(null)
        relay = null
        mutableActiveSession.value = null
    }

    private fun reconcile() {
        if (closed) return
        val supported = context.packageManager.hasSystemFeature(PackageManager.FEATURE_ACTIVITIES_ON_SECONDARY_DISPLAYS)
        val desired = SurfaceProbeWindowPolicy.companionDisplay(
            isEnabled, Build.VERSION.SDK_INT, started && relay != null && stopJob?.isActive != true,
            ownerVisible, companionEnabled && supported, displays.topology.value,
        )?.takeUnless { it == blockedDisplayId }
        val surface = companion
        if (surface != null) {
            if (!surface.closing && surface.lease.displayId != desired) closeCompanion()
            return
        }
        val lease = windows.select(desired) ?: return
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        try {
            val entrypoint = DartExecutor.DartEntrypoint(FlutterInjector.instance().flutterLoader().findAppBundlePath(), "aveluneCompanionMain")
            val engine = engineGroup.createAndRunEngine(
                FlutterEngineGroup.Options(context).setAutomaticallyRegisterPlugins(false).setDartEntrypoint(entrypoint),
            )
            val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            val next = CompanionSurface(lease, engine, channel)
            companion = next
            channel.setMethodCallHandler { call, result ->
                if (next.closing || !windows.isCurrent(lease.generation)) {
                    result.error("staleSurface", "Cette surface compagnon a été fermée.", null)
                } else when (call.method) {
                    "companionReady" -> {
                        next.ready = true
                        presence.value = next.visible
                        result.success(relay?.snapshot?.payload())
                    }
                    "intent" -> scope.launch {
                        try {
                            val current = requireNotNull(relay)
                            val request = current.companionIntent(call.arguments, lease.sourceId)
                            val response = invokeOwner("intent", request) {
                                check(relay === current && windows.isCurrent(lease.generation) && !next.closing && started && stopJob?.isActive != true) {
                                    "Cette surface compagnon a été fermée."
                                }
                            }
                            check(relay === current && windows.isCurrent(lease.generation) && !next.closing) { "Cette surface compagnon a été fermée." }
                            val snapshot = current.acceptSnapshot(response)
                            if (snapshot != null) broadcastSnapshot(snapshot.payload())
                            result.success(current.snapshot?.payload())
                        } catch (error: Exception) {
                            result.error("probeIntentFailed", error.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
            val intent = Intent(context, SurfaceProbeCompanionActivity::class.java)
                .putExtra(EXTRA_GENERATION, lease.generation)
                .putExtra(EXTRA_SESSION, relay?.sessionId)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_MULTIPLE_TASK)
            context.startActivity(intent, ActivityOptions.makeBasic().setLaunchDisplayId(lease.displayId).toBundle())
            Log.i(TAG, "Companion launched display=${lease.displayId} generation=${lease.generation}")
        } catch (error: Exception) {
            blockedDisplayId = lease.displayId
            companion?.channel?.setMethodCallHandler(null)
            companion?.engine?.destroy()
            companion = null
            windows.select(null)
            presence.value = false
            Log.w(TAG, "Companion unavailable; owner state retained", error)
        }
    }

    private fun closeCompanion() {
        val surface = companion ?: return
        if (surface.closing) return
        surface.closing = true
        windows.select(null)
        presence.value = false
        surface.channel.invokeMethod("stateChanged", null)
        surface.channel.setMethodCallHandler(null)
        val activity = surface.activity
        if (activity != null) {
            activity.finishAndRemoveTask()
        } else {
            surface.engine.destroy()
            companion = null
            reconcile()
        }
    }

    private fun acceptSnapshot(payload: Any?) {
        if (payload == null) {
            companion?.takeIf { it.ready && !it.closing }?.channel?.invokeMethod("stateChanged", null)
            return
        }
        val snapshot = relay?.acceptSnapshot(payload) ?: return
        Log.i(TAG, "Owner state session=${snapshot.sessionId} value=${snapshot.value} revision=${snapshot.revision} attached=${snapshot.companionAttached}")
        broadcastSnapshot(snapshot.payload())
    }

    private fun broadcastSnapshot(payload: Map<String, Any>) {
        companion?.takeIf { it.ready && !it.closing }?.channel?.invokeMethod("stateChanged", payload)
    }

    private suspend fun invokeOwner(method: String, arguments: Map<String, Any>? = null, beforeInvoke: () -> Unit = {}): Any? = ownerCalls.withLock {
        beforeInvoke()
        withTimeout(15_000) {
            suspendCancellableCoroutine { continuation ->
                ownerChannel.invokeMethod(method, arguments, object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        if (continuation.isActive) continuation.resume(result)
                    }

                    override fun error(code: String, message: String?, details: Any?) {
                        if (continuation.isActive) continuation.resumeWithException(IllegalStateException(message ?: code))
                    }

                    override fun notImplemented() {
                        if (continuation.isActive) continuation.resumeWithException(IllegalStateException("Le moteur ne prend pas en charge ce test des écrans."))
                    }
                })
            }
        }
    }

    private class CompanionSurface(val lease: SurfaceProbeWindowLease, val engine: FlutterEngine, val channel: MethodChannel) {
        var activity: SurfaceProbeCompanionActivity? = null
        var ready = false
        var visible = false
        var closing = false
    }

    companion object {
        const val CHANNEL = "com.avelune.runtime/surface_probe"
        const val EXTRA_SESSION = "surfaceProbeSession"
        const val EXTRA_GENERATION = "surfaceProbeGeneration"
        val isEnabled get() = BuildConfig.DEBUG && BuildConfig.BUILD_TYPE == "debug"
        private const val TAG = "AveluneSurfaceProbe"
    }
}
