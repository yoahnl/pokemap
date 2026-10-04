package com.yoahnl.avelune.player.presentation

import android.content.Intent
import android.os.Bundle
import android.os.Build
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.Window
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.repeatOnLifecycle
import com.yoahnl.avelune.player.AveluneApplication
import com.yoahnl.avelune.player.data.PackageStager
import com.yoahnl.avelune.player.runtime.RuntimeActivity
import com.yoahnl.avelune.player.runtime.SurfaceProbeActivity
import com.yoahnl.avelune.player.runtime.SurfaceProbeSession
import kotlinx.coroutines.launch
import kotlin.math.abs

class MainActivity : ComponentActivity() {
    private lateinit var viewModel: GameLibraryViewModel
    private var lastStickNavigationAt = 0L
    private var launchingSurfaceProbe = false
    private val app get() = application as AveluneApplication

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        configureGamepadKeys()
        val stager = PackageStager(applicationContext)
        viewModel = ViewModelProvider(this, object : ViewModelProvider.Factory {
            override fun <T : ViewModel> create(modelClass: Class<T>): T {
                require(modelClass.isAssignableFrom(GameLibraryViewModel::class.java))
                @Suppress("UNCHECKED_CAST")
                return GameLibraryViewModel(app.runtime, stager::stage) as T
            }
        })[GameLibraryViewModel::class.java]
        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                viewModel.launches.collect {
                    startActivity(Intent(this@MainActivity, RuntimeActivity::class.java))
                }
            }
        }
        setContent {
            AveluneTheme {
                GameLibraryScreen(viewModel, app.runtime, ::resetRuntime, ::startSurfaceProbe)
            }
        }
    }

    override fun onResume() {
        super.onResume()
        app.displays.useHostDisplay(currentDisplayId())
        if (::viewModel.isInitialized) {
            val playbackError = app.runtime.consumePlaybackError() ?: app.runtime.surfaceProbe.consumeError()
            if (playbackError != null) viewModel.showError(playbackError) else viewModel.refresh()
        }
    }

    private fun configureGamepadKeys() {
        val callback = window.callback
        window.callback = object : Window.Callback by callback {
            override fun dispatchKeyEvent(event: KeyEvent): Boolean {
                if (event.keyCode == KeyEvent.KEYCODE_BUTTON_B) {
                    if (event.action == KeyEvent.ACTION_UP) onBackPressedDispatcher.onBackPressed()
                    return true
                }
                val keyCode = when (event.keyCode) {
                    KeyEvent.KEYCODE_BUTTON_A -> KeyEvent.KEYCODE_DPAD_CENTER
                    else -> return callback.dispatchKeyEvent(event)
                }
                return callback.dispatchKeyEvent(
                    KeyEvent(
                        event.downTime, event.eventTime, event.action, keyCode, event.repeatCount,
                        event.metaState, event.deviceId, event.scanCode, event.flags, event.source,
                    ),
                )
            }
        }
    }

    private fun currentDisplayId(): Int? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) return display?.displayId
        @Suppress("DEPRECATION")
        val currentDisplay = windowManager.defaultDisplay
        return currentDisplay.displayId
    }

    private fun resetRuntime() {
        try {
            app.resetRuntime()
            finish()
            startActivity(
                Intent(this, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK),
            )
        } catch (error: Exception) {
            viewModel.showError(error.message ?: "Avelune n’a pas pu être réinitialisé.")
        }
    }

    private fun startSurfaceProbe() {
        if (launchingSurfaceProbe) return
        launchingSurfaceProbe = true
        lifecycleScope.launch {
            var prepared = false
            try {
                check(viewModel.state.value.busy == null) { "Attends la fin de l’action en cours avant de tester les écrans." }
                val sessionId = app.runtime.prepareSurfaceProbe()
                prepared = true
                startActivity(
                    Intent(this@MainActivity, SurfaceProbeActivity::class.java)
                        .putExtra(SurfaceProbeSession.EXTRA_SESSION, sessionId),
                )
            } catch (error: Exception) {
                if (prepared) app.runtime.surfaceProbe.requestStop()
                viewModel.showError(error.message ?: "Le test des écrans n’a pas pu être ouvert.")
            } finally {
                launchingSurfaceProbe = false
            }
        }
    }

    override fun dispatchGenericMotionEvent(event: MotionEvent): Boolean {
        if (event.source and InputDevice.SOURCE_JOYSTICK != InputDevice.SOURCE_JOYSTICK) {
            return super.dispatchGenericMotionEvent(event)
        }
        val x = event.getAxisValue(MotionEvent.AXIS_HAT_X).takeIf { abs(it) > 0.5f }
            ?: event.getAxisValue(MotionEvent.AXIS_X)
        val y = event.getAxisValue(MotionEvent.AXIS_HAT_Y).takeIf { abs(it) > 0.5f }
            ?: event.getAxisValue(MotionEvent.AXIS_Y)
        val keyCode = when {
            abs(x) > abs(y) && x > 0.55f -> KeyEvent.KEYCODE_DPAD_RIGHT
            abs(x) > abs(y) && x < -0.55f -> KeyEvent.KEYCODE_DPAD_LEFT
            y > 0.55f -> KeyEvent.KEYCODE_DPAD_DOWN
            y < -0.55f -> KeyEvent.KEYCODE_DPAD_UP
            else -> {
                lastStickNavigationAt = 0L
                return super.dispatchGenericMotionEvent(event)
            }
        }
        if (event.eventTime - lastStickNavigationAt >= 180L) {
            lastStickNavigationAt = event.eventTime
            window.callback.dispatchKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
            window.callback.dispatchKeyEvent(KeyEvent(KeyEvent.ACTION_UP, keyCode))
        }
        return true
    }
}
