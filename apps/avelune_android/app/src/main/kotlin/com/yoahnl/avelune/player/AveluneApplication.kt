package com.yoahnl.avelune.player

import android.app.Application
import com.yoahnl.avelune.player.display.DisplayCapabilityAdapter
import com.yoahnl.avelune.player.runtime.RuntimeSession

class AveluneApplication : Application() {
    val displays by lazy { DisplayCapabilityAdapter(this) }
    private var runtimeSession: RuntimeSession? = null
    val existingRuntime get() = runtimeSession
    val runtime: RuntimeSession
        get() = runtimeSession ?: RuntimeSession(this, displays).also { runtimeSession = it }

    fun resetRuntime() {
        runtimeSession?.close()
        runtimeSession = null
        runtime
    }
}
