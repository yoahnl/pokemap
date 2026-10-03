package com.yoahnl.avelune.player.runtime

import android.content.Context
import android.hardware.input.InputManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.view.KeyEvent
import android.view.MotionEvent
import com.yoahnl.avelune.player.AveluneApplication
import io.flutter.embedding.android.FlutterActivity
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

    override fun provideFlutterEngine(context: Context): FlutterEngine = runtime.engine

    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun shouldDispatchAppLifecycleState(): Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        companionSession = runtime.gameplayCompanion.also { it.ownerCreated(this) }
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
    }

    override fun onPause() {
        super.onPause()
        companionSession?.ownerPaused(this)
    }

    override fun onStop() {
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
        val stopSession = isFinishing && companionSession?.isOwner(this) == true && runtime.activeGame.value != null
        companionSession?.ownerDestroyed(this)
        activityScope.cancel()
        super.onDestroy()
        keyEventHandler = null
        motionEventHandler = null
        if (stopSession) runtime.requestStop()
    }

    private fun currentDisplayId(): Int? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) return display?.displayId
        @Suppress("DEPRECATION")
        val current = windowManager.defaultDisplay
        return current.displayId
    }
}
