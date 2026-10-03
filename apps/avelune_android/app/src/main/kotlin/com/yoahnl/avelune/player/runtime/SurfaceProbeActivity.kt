package com.yoahnl.avelune.player.runtime

import android.app.AlertDialog
import android.os.Bundle
import android.view.KeyEvent
import android.view.Window
import androidx.activity.ComponentActivity
import androidx.activity.addCallback
import com.yoahnl.avelune.player.AveluneApplication
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class SurfaceProbeActivity : ComponentActivity() {
    private val activityScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var probe: SurfaceProbeSession? = null
    private var engine: FlutterEngine? = null
    private var surface: FlutterView? = null
    private var errorDialog: AlertDialog? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val runtime = (application as AveluneApplication).existingRuntime
        val currentProbe = runtime?.surfaceProbe
        val sessionId = intent.getStringExtra(SurfaceProbeSession.EXTRA_SESSION)
        if (runtime == null || currentProbe == null || runtime.activeGame.value != null || !currentProbe.ownerCreated(this, sessionId)) {
            finish()
            return
        }
        probe = currentProbe
        engine = runtime.engine
        val view = FlutterView(this)
        surface = view
        setContentView(view)
        view.attachToFlutterEngine(runtime.engine)
        configureGamepadKeys(currentProbe)
        onBackPressedDispatcher.addCallback(this) { currentProbe.requestStop() }
        activityScope.launch {
            currentProbe.activeSession.collect { sessionId ->
                if (sessionId == null && !isFinishing) finish()
            }
        }
        activityScope.launch {
            currentProbe.stopError.collect { error ->
                errorDialog?.dismiss()
                errorDialog = null
                if (error != null && !isFinishing) {
                    errorDialog = AlertDialog.Builder(this@SurfaceProbeActivity)
                        .setTitle("Le test reste ouvert")
                        .setMessage(error)
                        .setCancelable(false)
                        .setPositiveButton("Réessayer") { _, _ -> currentProbe.requestStop() }
                        .show()
                }
            }
        }
    }

    override fun onStart() {
        super.onStart()
        if (!isFinishing) probe?.ownerStarted(this)
    }

    override fun onResume() {
        super.onResume()
        engine?.lifecycleChannel?.appIsResumed()
    }

    override fun onPostResume() {
        super.onPostResume()
        if (!isFinishing) probe?.ownerResumed()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) engine?.lifecycleChannel?.aWindowIsFocused() else engine?.lifecycleChannel?.noWindowsAreFocused()
    }

    override fun onPause() {
        engine?.lifecycleChannel?.appIsInactive()
        super.onPause()
    }

    override fun onStop() {
        probe?.ownerStopped(this)
        engine?.lifecycleChannel?.appIsPaused()
        super.onStop()
    }

    private fun configureGamepadKeys(currentProbe: SurfaceProbeSession) {
        val callback = window.callback
        window.callback = object : Window.Callback by callback {
            override fun dispatchKeyEvent(event: KeyEvent): Boolean {
                if (event.keyCode == KeyEvent.KEYCODE_BUTTON_B) {
                    if (event.action == KeyEvent.ACTION_UP) currentProbe.requestStop()
                    return true
                }
                if (event.keyCode != KeyEvent.KEYCODE_BUTTON_A) return callback.dispatchKeyEvent(event)
                return callback.dispatchKeyEvent(
                    KeyEvent(
                        event.downTime, event.eventTime, event.action, KeyEvent.KEYCODE_DPAD_CENTER, event.repeatCount,
                        event.metaState, event.deviceId, event.scanCode, event.flags, event.source,
                    ),
                )
            }
        }
    }

    override fun onDestroy() {
        activityScope.cancel()
        errorDialog?.dismiss()
        errorDialog = null
        detachSurface()
        super.onDestroy()
        probe?.ownerDestroyed(this)
    }

    fun detachSurface() {
        surface?.detachFromFlutterEngine()
        surface = null
        engine?.lifecycleChannel?.appIsDetached()
        engine = null
    }
}
