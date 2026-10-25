package com.yoahnl.avelune.player.runtime

import android.content.Context
import android.hardware.input.InputManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.util.Log
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.Surface
import android.view.SurfaceHolder
import android.view.View
import android.view.ViewGroup
import com.yoahnl.avelune.player.AveluneApplication
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterSurfaceView
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import org.flame_engine.gamepads_android.GamepadsCompatibleActivity

class RuntimeActivity : FlutterActivity(), GamepadsCompatibleActivity {
    private val runtime get() = (application as AveluneApplication).runtime
    private val activityScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var keyEventHandler: ((KeyEvent) -> Boolean)? = null
    private var motionEventHandler: ((MotionEvent) -> Boolean)? = null
    private var companionSession: RuntimeCompanionSession? = null
    private var frameRateSurface: SurfaceHolder? = null
    private val frameRateHint = RuntimeFrameRateHint(
        applyLimit = ::applyFrameRateLimit,
        clearLimit = { applyFrameRateLimit(0) },
    )
    private val frameRateSurfaceCallback = object : SurfaceHolder.Callback {
        override fun surfaceCreated(holder: SurfaceHolder) {
            if (holder === frameRateSurface) frameRateHint.surfaceAvailable()
        }

        override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
            if (holder === frameRateSurface) frameRateHint.surfaceAvailable()
        }

        override fun surfaceDestroyed(holder: SurfaceHolder) {
            if (holder === frameRateSurface) frameRateHint.surfaceDestroyed()
        }
    }

    override fun provideFlutterEngine(context: Context): FlutterEngine = runtime.engine

    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun shouldDispatchAppLifecycleState(): Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        companionSession = runtime.gameplayCompanion.also { it.ownerCreated(this) }
        activityScope.launch {
            runtime.frameRateLimit.collect(frameRateHint::updateLimit)
        }
        activityScope.launch {
            runtime.activeGame.collect { gameId ->
                if (gameId == null && !isFinishing) finish()
            }
        }
        activityScope.launch {
            runtime.presentationFailure.collect { error ->
                if (error != null && !isFinishing) finish()
            }
        }
    }

    override fun onPostResume() {
        super.onPostResume()
        companionSession?.ownerResumed(this)
        runtime.startPreparedGame()
    }

    override fun onStart() {
        super.onStart()
        companionSession?.ownerStarted(this, currentDisplayId())
        attachFrameRateSurface()
        frameRateHint.start()
    }

    override fun onPause() {
        super.onPause()
        companionSession?.ownerPaused(this)
    }

    override fun onStop() {
        frameRateHint.stop()
        detachFrameRateSurface()
        companionSession?.ownerStopped(this)
        super.onStop()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        companionSession?.ownerFocusChanged(this, hasFocus)
    }

    override fun registerInputDeviceListener(listener: InputManager.InputDeviceListener, handler: Handler?) {
        runtime.registerInputDeviceListener(listener, handler)
    }

    override fun registerKeyEventHandler(handler: (KeyEvent) -> Boolean) {
        keyEventHandler = handler
    }

    override fun registerMotionEventHandler(handler: (MotionEvent) -> Boolean) {
        motionEventHandler = handler
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean =
        keyEventHandler?.invoke(event) == true || super.dispatchKeyEvent(event)

    override fun dispatchGenericMotionEvent(event: MotionEvent): Boolean =
        motionEventHandler?.invoke(event) == true || super.dispatchGenericMotionEvent(event)

    fun dispatchCompanionKeyEvent(event: KeyEvent): Boolean {
        if (keyEventHandler?.invoke(event) == true) return true
        val view = findViewById<FlutterView>(FLUTTER_VIEW_ID) ?: return false
        return view.dispatchKeyEvent(event)
    }

    fun dispatchCompanionMotionEvent(event: MotionEvent): Boolean {
        if (motionEventHandler?.invoke(event) == true) return true
        val view = findViewById<FlutterView>(FLUTTER_VIEW_ID) ?: return false
        return view.dispatchGenericMotionEvent(event)
    }

    override fun onDestroy() {
        frameRateHint.stop()
        detachFrameRateSurface()
        val stopSession = isFinishing && companionSession?.isOwner(this) == true && runtime.activeGame.value != null
        companionSession?.ownerDestroyed(this)
        activityScope.cancel()
        super.onDestroy()
        keyEventHandler = null
        motionEventHandler = null
        if (stopSession) runtime.requestStop()
    }

    private fun attachFrameRateSurface() {
        val flutterView = findViewById<FlutterView>(FLUTTER_VIEW_ID) ?: return
        val holder = findFlutterSurfaceView(flutterView)?.holder ?: return
        if (frameRateSurface === holder) return
        detachFrameRateSurface()
        frameRateSurface = holder
        holder.addCallback(frameRateSurfaceCallback)
        if (holder.surface.isValid) frameRateHint.surfaceAvailable()
    }

    private fun detachFrameRateSurface() {
        frameRateHint.surfaceDestroyed()
        frameRateSurface?.removeCallback(frameRateSurfaceCallback)
        frameRateSurface = null
    }

    private fun findFlutterSurfaceView(view: View): FlutterSurfaceView? {
        if (view is FlutterSurfaceView) return view
        if (view is ViewGroup) {
            for (index in 0 until view.childCount) {
                findFlutterSurfaceView(view.getChildAt(index))?.let { return it }
            }
        }
        return null
    }

    private fun applyFrameRateLimit(limit: Int) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val surface = frameRateSurface?.surface ?: return
                if (!surface.isValid) return
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    surface.setFrameRate(
                        limit.toFloat(),
                        Surface.FRAME_RATE_COMPATIBILITY_DEFAULT,
                        Surface.CHANGE_FRAME_RATE_ONLY_IF_SEAMLESS,
                    )
                } else {
                    surface.setFrameRate(limit.toFloat(), Surface.FRAME_RATE_COMPATIBILITY_DEFAULT)
                }
            } else {
                window.attributes = window.attributes.apply { preferredRefreshRate = limit.toFloat() }
            }
        } catch (error: RuntimeException) {
            Log.w("AveluneFrameRate", "La fréquence demandée n’a pas pu être appliquée.", error)
        }
    }

    private fun currentDisplayId(): Int? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) return display?.displayId
        @Suppress("DEPRECATION")
        val current = windowManager.defaultDisplay
        return current.displayId
    }
}
