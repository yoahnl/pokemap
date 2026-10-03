package com.yoahnl.avelune.player.runtime

import android.os.Build
import android.os.Bundle
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.Window
import androidx.activity.ComponentActivity
import androidx.activity.addCallback
import com.yoahnl.avelune.player.AveluneApplication
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine

class RuntimeCompanionActivity : ComponentActivity() {
    private var companionSession: RuntimeCompanionSession? = null
    private val generation get() = intent.getLongExtra(RuntimeCompanionSession.EXTRA_GENERATION, -1)
    private var engine: FlutterEngine? = null
    private var surface: FlutterView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val current = (application as AveluneApplication).existingRuntime?.gameplayCompanion
        val sessionId = intent.getStringExtra(RuntimeCompanionSession.EXTRA_SESSION)
        val companionEngine = current?.companionEngine(generation, sessionId)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q || current == null || companionEngine == null ||
            !current.companionCreated(this, generation, sessionId, currentDisplayId())) {
            finishAndRemoveTask()
            return
        }
        companionSession = current
        engine = companionEngine
        val view = FlutterView(this)
        view.setDefaultFocusHighlightEnabled(false)
        surface = view
        setContentView(view)
        view.attachToFlutterEngine(companionEngine)
        configureOwnerInput(current)
        onBackPressedDispatcher.addCallback(this) { current.companionBack(this@RuntimeCompanionActivity, generation) }
        current.companionSurfaceAttached(this, generation)
    }

    override fun onStart() {
        super.onStart()
        if (!isFinishing) companionSession?.companionStarted(this, generation)
    }

    override fun onResume() {
        super.onResume()
        engine?.lifecycleChannel?.appIsResumed()
        companionSession?.companionResumed(this, generation)
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) engine?.lifecycleChannel?.aWindowIsFocused() else engine?.lifecycleChannel?.noWindowsAreFocused()
        companionSession?.companionFocusChanged(this, generation, hasFocus)
    }

    override fun onPause() {
        engine?.lifecycleChannel?.appIsInactive()
        super.onPause()
        companionSession?.companionPaused(this, generation)
    }

    override fun onStop() {
        engine?.lifecycleChannel?.appIsPaused()
        companionSession?.companionStopped(this, generation)
        super.onStop()
    }

    override fun onDestroy() {
        detachSurface()
        super.onDestroy()
        companionSession?.companionDestroyed(this, generation)
    }

    fun detachSurface() {
        surface?.detachFromFlutterEngine()
        surface = null
        engine?.lifecycleChannel?.appIsDetached()
        engine = null
    }

    private fun configureOwnerInput(current: RuntimeCompanionSession) {
        val callback = window.callback
        window.callback = object : Window.Callback by callback {
            override fun dispatchKeyEvent(event: KeyEvent): Boolean {
                current.companionKeyEvent(this@RuntimeCompanionActivity, generation, event)
                return true
            }

            override fun dispatchGenericMotionEvent(event: MotionEvent): Boolean {
                current.companionMotionEvent(this@RuntimeCompanionActivity, generation, event)
                return true
            }
        }
    }

    private fun currentDisplayId(): Int? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) return display?.displayId
        @Suppress("DEPRECATION")
        val current = windowManager.defaultDisplay
        return current.displayId
    }
}
