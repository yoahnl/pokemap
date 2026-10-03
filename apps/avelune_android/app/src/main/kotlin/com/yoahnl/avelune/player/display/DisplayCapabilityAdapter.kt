package com.yoahnl.avelune.player.display

import android.content.Context
import android.hardware.display.DisplayManager
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Display
import com.yoahnl.avelune.host.DisplayCapability
import com.yoahnl.avelune.host.DisplayRolePolicy
import com.yoahnl.avelune.host.DisplayTopology
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class DisplayCapabilityAdapter(context: Context) : DisplayManager.DisplayListener {
    private val manager = context.getSystemService(DisplayManager::class.java)
    private val mutableTopology = MutableStateFlow(DisplayTopology())
    private var hostDisplayId: Int? = null
    val topology: StateFlow<DisplayTopology> = mutableTopology.asStateFlow()

    init {
        manager.registerDisplayListener(this, Handler(Looper.getMainLooper()))
        refresh()
    }

    fun useHostDisplay(id: Int?) {
        hostDisplayId = id
        refresh()
    }

    override fun onDisplayAdded(displayId: Int) = refresh()
    override fun onDisplayRemoved(displayId: Int) = refresh()
    override fun onDisplayChanged(displayId: Int) = refresh()

    private fun refresh() {
        val capabilities = manager.displays.map { display ->
            val mode = display.mode
            DisplayCapability(
                id = display.displayId,
                name = display.name,
                width = mode.physicalWidth,
                height = mode.physicalHeight,
                isDefault = display.displayId == Display.DEFAULT_DISPLAY,
                isPrivate = display.flags and Display.FLAG_PRIVATE != 0,
                isAvailable = display.isValid && display.state == Display.STATE_ON,
            )
        }
        val next = DisplayRolePolicy.resolve(capabilities, hostDisplayId)
        if (next != mutableTopology.value) {
            mutableTopology.value = next
            Log.i("AveluneDisplays", next.diagnostics().toString())
        }
    }
}
