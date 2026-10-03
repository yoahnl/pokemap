package com.yoahnl.avelune.player.runtime

import android.app.ActivityOptions
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import android.view.Choreographer
import android.view.KeyEvent
import android.view.MotionEvent
import com.yoahnl.avelune.host.RuntimeCompanionFocusPolicy
import com.yoahnl.avelune.host.RuntimeCompanionRelay
import com.yoahnl.avelune.host.RuntimeCompanionWindowLease
import com.yoahnl.avelune.host.RuntimeCompanionWindowPolicy
import com.yoahnl.avelune.host.RuntimeCompanionWindows
import com.yoahnl.avelune.host.RuntimeOwnerLifecycle
import com.yoahnl.avelune.player.display.DisplayCapabilityAdapter
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.TimeoutCancellationException
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

class RuntimeCompanionSession(
    context: Context,
    private val ownerEngine: FlutterEngine,
    private val engineGroup: FlutterEngineGroup,
    private val displays: DisplayCapabilityAdapter,
) {
    private val context = context.applicationContext
    private val ownerChannel = MethodChannel(ownerEngine.dartExecutor.binaryMessenger, CHANNEL)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val ownerCalls = Mutex()
    private val windows = RuntimeCompanionWindows()
    private val mutableAttached = MutableStateFlow(false)
    val attached = mutableAttached.asStateFlow()
    private var relay: RuntimeCompanionRelay? = null
    private var ownerActivity: RuntimeActivity? = null
    private var ownerVisible = false
    private var ownerResumed = false
    private var ownerFocused = false
    private var companion: CompanionSurface? = null
    private var started = false
    private var ending = false
    private var closed = false
    private var blockedDisplayId: Int? = null
    private val choreographer by lazy { Choreographer.getInstance() }
    private var lifecyclePending = false
    private val lifecycleFrame = Choreographer.FrameCallback {
        lifecyclePending = false
        projectOwnerLifecycle()
    }

    init {
        ownerChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "stateChanged" -> runCatching { acceptOwnerState(call.arguments) }
                    .onSuccess { result.success(null) }
                    .onFailure { result.error("invalidCompanionState", it.message, null) }
                "input" -> runCatching { forwardInput(call.arguments) }
                    .onSuccess { result.success(null) }
                    .onFailure { result.error("invalidCompanionInput", it.message, null) }
                else -> result.notImplemented()
            }
        }
        scope.launch {
            displays.topology.collect {
                blockedDisplayId = null
                reconcile()
            }
        }
    }

    fun prepare(): String {
        check(!closed && relay == null) { "La partie précédente est encore en cours de fermeture." }
        val sessionId = UUID.randomUUID().toString()
        relay = RuntimeCompanionRelay(sessionId)
        ending = false
        started = false
        blockedDisplayId = null
        mutableAttached.value = false
        return sessionId
    }

    suspend fun startTransport() {
        val current = relay ?: return
        try {
            val response = invokeOwner("start", mapOf("sessionId" to current.sessionId)) {
                check(relay === current && !ending && !closed) { "Cette partie est en cours de fermeture." }
            }
            if (relay !== current || ending || closed) return
            acceptReply(current, response)
            started = true
            reconcile()
        } catch (error: Exception) {
            if (error is CancellationException && error !is TimeoutCancellationException) throw error
            closeCompanion()
            Log.w(TAG, "Companion transport unavailable; primary controls retained", error)
        }
    }

    fun ownerCreated(activity: RuntimeActivity) {
        if (closed || relay == null || ending) return
        if (ownerActivity != null && ownerActivity !== activity) return
        ownerActivity = activity
        ownerFocused = activity.hasWindowFocus()
    }

    fun isOwner(activity: RuntimeActivity): Boolean = ownerActivity === activity && !closed

    fun ownerStarted(activity: RuntimeActivity, displayId: Int?) {
        if (ownerActivity !== activity) return
        ownerVisible = true
        displays.useHostDisplay(displayId)
        blockedDisplayId = null
        reconcile()
        updateOwnerLifecycle()
    }

    fun ownerResumed(activity: RuntimeActivity) {
        if (ownerActivity !== activity) return
        ownerResumed = true
        blockedDisplayId = null
        reconcile()
        updateOwnerLifecycle()
        val current = relay ?: return
        if (!started || ending) return
        scope.launch {
            runCatching {
                val response = invokeOwner("snapshot") { check(relay === current && started && !ending && !closed) }
                if (relay === current && !ending) acceptReply(current, response)
            }.onFailure { Log.w(TAG, "Companion snapshot could not be refreshed", it) }
        }
    }

    fun ownerPaused(activity: RuntimeActivity) {
        if (ownerActivity !== activity) return
        ownerResumed = false
        updateOwnerLifecycle()
    }

    fun ownerFocusChanged(activity: RuntimeActivity, focused: Boolean) {
        if (ownerActivity !== activity) return
        ownerFocused = focused
        updateOwnerLifecycle()
    }

    fun ownerStopped(activity: RuntimeActivity) {
        if (ownerActivity !== activity) return
        ownerVisible = false
        ownerResumed = false
        ownerFocused = false
        reconcile()
        updateOwnerLifecycle(immediate = true)
    }

    fun ownerDestroyed(activity: RuntimeActivity) {
        if (ownerActivity !== activity) return
        ownerActivity = null
        ownerVisible = false
        ownerResumed = false
        ownerFocused = false
        closeCompanion()
        updateOwnerLifecycle(immediate = true)
    }

    fun companionEngine(generation: Long, sessionId: String?): FlutterEngine? = companion?.takeIf {
        sessionId != null && relay?.sessionId == sessionId && it.lease.generation == generation &&
            windows.isCurrent(generation) && !ending && !closed
    }?.engine

    fun companionCreated(activity: RuntimeCompanionActivity, generation: Long, sessionId: String?, actualDisplayId: Int?): Boolean {
        val surface = companion?.takeIf { it.lease.generation == generation && relay?.sessionId == sessionId } ?: return false
        if (!windows.isCurrent(generation) || ending || closed || surface.activity != null || actualDisplayId != surface.lease.displayId) {
            if (surface.activity == null && actualDisplayId != surface.lease.displayId) {
                blockedDisplayId = surface.lease.displayId
                closeCompanion()
            }
            return false
        }
        surface.activity = activity
        return true
    }

    fun companionSurfaceAttached(activity: RuntimeCompanionActivity, generation: Long) {
        val surface = currentSurface(activity, generation) ?: return
        surface.viewAttached = true
        updateAttachment()
    }

    fun companionStarted(activity: RuntimeCompanionActivity, generation: Long) {
        val surface = currentSurface(activity, generation) ?: return
        surface.visible = true
        updateAttachment()
        updateOwnerLifecycle()
    }

    fun companionResumed(activity: RuntimeCompanionActivity, generation: Long) {
        val surface = currentSurface(activity, generation) ?: return
        surface.resumed = true
        updateOwnerLifecycle()
    }

    fun companionFocusChanged(activity: RuntimeCompanionActivity, generation: Long, focused: Boolean) {
        val surface = currentSurface(activity, generation) ?: return
        surface.focused = focused
        updateOwnerLifecycle()
    }

    fun companionPaused(activity: RuntimeCompanionActivity, generation: Long) {
        val surface = currentSurface(activity, generation) ?: return
        surface.resumed = false
        updateOwnerLifecycle()
    }

    fun companionStopped(activity: RuntimeCompanionActivity, generation: Long) {
        val surface = currentSurface(activity, generation) ?: return
        surface.visible = false
        surface.resumed = false
        surface.focused = false
        updateAttachment()
        updateOwnerLifecycle(immediate = true)
    }

    fun companionDestroyed(activity: RuntimeCompanionActivity, generation: Long) {
        val surface = currentSurface(activity, generation) ?: return
        blockedDisplayId = surface.lease.displayId
        closeCompanion()
    }

    fun companionKeyEvent(activity: RuntimeCompanionActivity, generation: Long, event: KeyEvent) {
        inputOwner(activity, generation)?.dispatchCompanionKeyEvent(event)
    }

    fun companionMotionEvent(activity: RuntimeCompanionActivity, generation: Long, event: MotionEvent) {
        inputOwner(activity, generation)?.dispatchCompanionMotionEvent(event)
    }

    fun companionBack(activity: RuntimeCompanionActivity, generation: Long) {
        if (inputOwner(activity, generation) != null) ownerEngine.navigationChannel.popRoute()
    }

    fun beginStop() {
        ending = true
        closeCompanion()
        updateOwnerLifecycle(immediate = true)
    }

    suspend fun stopTransport() {
        val current = relay ?: return
        beginStop()
        started = false
        for ((method, arguments) in listOf(
            "setCompanionAttached" to mapOf("sessionId" to current.sessionId, "attached" to false),
            "stop" to mapOf("sessionId" to current.sessionId),
        )) {
            runCatching {
                invokeOwner(method, arguments) { check(relay === current && !closed) }
            }.onFailure { Log.w(TAG, "Companion transport closure failed: $method", it) }
        }
        if (relay === current) {
            relay = null
            ownerActivity = null
            ownerVisible = false
            ownerResumed = false
            ownerFocused = false
            updateOwnerLifecycle(immediate = true)
        }
    }

    fun close() {
        if (closed) return
        closed = true
        ending = true
        scope.cancel()
        closeCompanion()
        ownerChannel.setMethodCallHandler(null)
        relay = null
        ownerActivity = null
        ownerVisible = false
        ownerResumed = false
        ownerFocused = false
        updateOwnerLifecycle(immediate = true)
    }

    private fun reconcile() {
        if (closed) return
        val supported = context.packageManager.hasSystemFeature(PackageManager.FEATURE_ACTIVITIES_ON_SECONDARY_DISPLAYS)
        val desired = RuntimeCompanionWindowPolicy.companionDisplay(
            Build.VERSION.SDK_INT, started && relay != null, ownerVisible,
            ending, supported, displays.topology.value,
        )?.takeUnless { it == blockedDisplayId }
        val surface = companion
        if (surface != null && surface.lease.displayId == desired) return
        if (surface != null) closeCompanion()
        val lease = windows.select(desired) ?: return
        val current = relay ?: return
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return
        try {
            val entrypoint = DartExecutor.DartEntrypoint(
                FlutterInjector.instance().flutterLoader().findAppBundlePath(), "aveluneGameplayCompanionMain",
            )
            val engine = engineGroup.createAndRunEngine(
                FlutterEngineGroup.Options(context).setAutomaticallyRegisterPlugins(false).setDartEntrypoint(entrypoint),
            )
            val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            val next = CompanionSurface(lease, engine, channel)
            companion = next
            channel.setMethodCallHandler { call, result ->
                if (companion !== next || !windows.isCurrent(lease.generation) || relay !== current || ending || closed) {
                    result.error("staleSurface", "Cet écran compagnon a été fermé.", null)
                } else when (call.method) {
                    "companionReady" -> {
                        next.connected = true
                        result.success(current.snapshot)
                    }
                    "surfaceReady" -> {
                        val arguments = call.arguments as? Map<*, *>
                        if (!next.connected || arguments == null || arguments["sessionId"] != current.sessionId) {
                            result.error("staleSession", "Cet écran compagnon appartient à une autre partie.", null)
                        } else {
                            next.ready = arguments["ready"] as? Boolean ?: true
                            updateAttachment()
                            result.success(current.snapshot)
                        }
                    }
                    "intent" -> scope.launch {
                        try {
                            val request = current.companionIntent(call.arguments, lease.sourceId)
                            val response = invokeOwner("intent", request) {
                                check(companion === next && windows.isCurrent(lease.generation) && relay === current &&
                                    mutableAttached.value && started && !ending && !closed) { "Cet écran compagnon a été fermé." }
                            }
                            check(companion === next && relay === current && windows.isCurrent(lease.generation) && !ending && !closed) {
                                "Cet écran compagnon a été fermé."
                            }
                            acceptReply(current, response)
                            result.success(current.snapshot)
                        } catch (error: Exception) {
                            if (error is OwnerMethodFailure) result.error(error.code, error.message, error.details)
                            else result.error("companionIntentFailed", error.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
            val intent = Intent(context, RuntimeCompanionActivity::class.java)
                .putExtra(EXTRA_SESSION, current.sessionId)
                .putExtra(EXTRA_GENERATION, lease.generation)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_MULTIPLE_TASK)
            context.startActivity(intent, ActivityOptions.makeBasic().setLaunchDisplayId(lease.displayId).toBundle())
            Log.i(TAG, "Companion launched session=${current.sessionId} display=${lease.displayId} generation=${lease.generation}")
        } catch (error: Exception) {
            blockedDisplayId = lease.displayId
            closeCompanion()
            windows.select(null)
            Log.w(TAG, "Companion unavailable; primary controls retained", error)
        }
    }

    private fun currentSurface(activity: RuntimeCompanionActivity, generation: Long): CompanionSurface? = companion?.takeIf {
        it.activity === activity && it.lease.generation == generation && windows.isCurrent(generation)
    }

    private fun inputOwner(activity: RuntimeCompanionActivity, generation: Long): RuntimeActivity? {
        if (currentSurface(activity, generation) == null || relay == null || ending || closed || !ownerVisible) return null
        if (ownerLifecycle() != RuntimeOwnerLifecycle.RESUMED) return null
        val owner = ownerActivity?.takeUnless { it.isFinishing || it.isDestroyed } ?: return null
        if (lifecyclePending) updateOwnerLifecycle(immediate = true)
        return owner
    }

    private fun ownerLifecycle(): RuntimeOwnerLifecycle {
        val surface = companion
        return RuntimeCompanionFocusPolicy.ownerLifecycle(
            ownerActivity != null, relay != null && !closed, ownerVisible, ending || closed,
            ownerResumed, ownerFocused, surface != null && windows.isCurrent(surface.lease.generation),
            surface?.visible == true, surface?.resumed == true, surface?.focused == true,
        )
    }

    private fun updateOwnerLifecycle(immediate: Boolean = false) {
        if (immediate) {
            if (lifecyclePending) choreographer.removeFrameCallback(lifecycleFrame)
            lifecyclePending = false
            projectOwnerLifecycle()
        } else if (!lifecyclePending && !closed) {
            lifecyclePending = true
            choreographer.postFrameCallback(lifecycleFrame)
        }
    }

    private fun projectOwnerLifecycle() {
        val channel = ownerEngine.lifecycleChannel
        when (ownerLifecycle()) {
            RuntimeOwnerLifecycle.RESUMED -> {
                channel.aWindowIsFocused()
                channel.appIsResumed()
            }
            RuntimeOwnerLifecycle.INACTIVE -> {
                channel.appIsInactive()
                channel.noWindowsAreFocused()
            }
            RuntimeOwnerLifecycle.PAUSED -> {
                channel.appIsPaused()
                channel.noWindowsAreFocused()
            }
            RuntimeOwnerLifecycle.DETACHED -> {
                channel.appIsDetached()
                channel.noWindowsAreFocused()
            }
        }
        updateAttachment()
    }

    private fun updateAttachment() {
        val surface = companion
        val attached = surface != null && !closed && windows.isCurrent(surface.lease.generation) && RuntimeCompanionWindowPolicy.attached(
            started, ownerLifecycle() == RuntimeOwnerLifecycle.RESUMED, ending,
            surface.connected, surface.ready, surface.viewAttached, surface.visible,
        )
        if (attached == mutableAttached.value) return
        mutableAttached.value = attached
        if (attached) broadcastSnapshot(relay?.snapshot)
        val current = relay ?: return
        if (!started || closed) return
        scope.launch {
            runCatching {
                val response = invokeOwner("setCompanionAttached", mapOf("sessionId" to current.sessionId, "attached" to attached)) {
                    check(relay === current && !closed && mutableAttached.value == attached && (!attached || !ending))
                }
                if (relay === current && !ending) acceptReply(current, response)
            }.onFailure {
                if (attached && relay === current && mutableAttached.value) {
                    blockedDisplayId = companion?.lease?.displayId
                    closeCompanion()
                }
                Log.w(TAG, "Companion attachment could not be reported", it)
            }
        }
    }

    private fun closeCompanion() {
        val surface = companion
        companion = null
        windows.select(null)
        updateAttachment()
        updateOwnerLifecycle(immediate = true)
        if (surface == null) return
        surface.channel.invokeMethod("stateChanged", null)
        surface.channel.setMethodCallHandler(null)
        surface.activity?.detachSurface()
        surface.activity?.finishAndRemoveTask()
        surface.engine.destroy()
    }

    private fun acceptOwnerState(payload: Any?) {
        if (payload == null) {
            relay?.clearSnapshot()
            beginStop()
            return
        }
        if (ending || closed) return
        val snapshot = relay?.acceptSnapshot(payload) ?: return
        broadcastSnapshot(snapshot)
    }

    private fun acceptReply(current: RuntimeCompanionRelay, payload: Any?) {
        if (relay !== current || payload == null || ending || closed) return
        val snapshot = current.acceptSnapshot(payload) ?: return
        broadcastSnapshot(snapshot)
    }

    private fun broadcastSnapshot(payload: Map<String, Any?>?) {
        companion?.takeIf { it.connected && windows.isCurrent(it.lease.generation) }
            ?.channel?.invokeMethod("stateChanged", payload)
    }

    private fun forwardInput(payload: Any?) {
        val surface = companion ?: return
        val input = relay?.ownerInput(payload, mutableAttached.value, windows.isCurrent(surface.lease.generation)) ?: return
        surface.channel.invokeMethod("input", input)
    }

    private suspend fun invokeOwner(method: String, arguments: Map<String, Any?>? = null, beforeInvoke: () -> Unit = {}): Any? = ownerCalls.withLock {
        beforeInvoke()
        withTimeout(15_000) {
            suspendCancellableCoroutine { continuation ->
                ownerChannel.invokeMethod(method, arguments, object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        if (continuation.isActive) continuation.resume(result)
                    }

                    override fun error(code: String, message: String?, details: Any?) {
                        if (continuation.isActive) continuation.resumeWithException(OwnerMethodFailure(code, message, details))
                    }

                    override fun notImplemented() {
                        if (continuation.isActive) continuation.resumeWithException(IllegalStateException("Le moteur ne prend pas en charge cet écran compagnon."))
                    }
                })
            }
        }
    }

    private class CompanionSurface(val lease: RuntimeCompanionWindowLease, val engine: FlutterEngine, val channel: MethodChannel) {
        var activity: RuntimeCompanionActivity? = null
        var connected = false
        var ready = false
        var visible = false
        var resumed = false
        var focused = false
        var viewAttached = false
    }

    private class OwnerMethodFailure(val code: String, message: String?, val details: Any?) : RuntimeException(message ?: code)

    companion object {
        const val CHANNEL = "com.avelune.runtime/companion"
        const val EXTRA_SESSION = "runtimeCompanionSession"
        const val EXTRA_GENERATION = "runtimeCompanionGeneration"
        private const val TAG = "AveluneCompanion"
    }
}
