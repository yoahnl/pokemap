package com.yoahnl.avelune.player.runtime

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import androidx.activity.ComponentActivity
import com.yoahnl.avelune.player.AveluneApplication
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine

class SurfaceProbeCompanionActivity : ComponentActivity() {
    private var probe: SurfaceProbeSession? = null
    private val generation get() = intent.getLongExtra(SurfaceProbeSession.EXTRA_GENERATION, -1)
    private var engine: FlutterEngine? = null
    private var surface: FlutterView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        window.addFlags(WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE)
        super.onCreate(savedInstanceState)
        val currentProbe = (application as AveluneApplication).existingRuntime?.surfaceProbe
        probe = currentProbe
        val sessionId = intent.getStringExtra(SurfaceProbeSession.EXTRA_SESSION)
        val companionEngine = currentProbe?.companionEngine(generation, sessionId)
        if (!SurfaceProbeSession.isEnabled || currentProbe == null || companionEngine == null || !currentProbe.companionCreated(this, generation, sessionId, currentDisplayId())) {
            finishAndRemoveTask()
            return
        }
        engine = companionEngine
        val view = FlutterView(this)
        surface = view
        setContentView(view)
        view.attachToFlutterEngine(companionEngine)
    }

    override fun onStart() {
        super.onStart()
        if (!isFinishing) probe?.companionStarted(this, generation)
    }

    override fun onResume() {
        super.onResume()
        engine?.lifecycleChannel?.appIsResumed()
        engine?.lifecycleChannel?.noWindowsAreFocused()
    }

    override fun onPause() {
        engine?.lifecycleChannel?.appIsInactive()
        super.onPause()
    }

    override fun onStop() {
        engine?.lifecycleChannel?.appIsPaused()
        probe?.companionStopped(this, generation)
        super.onStop()
    }

    override fun onDestroy() {
        detachSurface()
        super.onDestroy()
        probe?.companionDestroyed(this, generation)
    }

    fun detachSurface() {
        surface?.detachFromFlutterEngine()
        surface = null
        engine?.lifecycleChannel?.appIsDetached()
        engine = null
    }

    private fun currentDisplayId(): Int? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) return display?.displayId
        @Suppress("DEPRECATION")
        val current = windowManager.defaultDisplay
        return current.displayId
    }
}
