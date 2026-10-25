package com.yoahnl.avelune.player.runtime

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

internal class RuntimeFrameRate {
    private val mutableLimit = MutableStateFlow(60)
    val limit = mutableLimit.asStateFlow()

    fun setLimit(arguments: Any?) {
        val value = (arguments as? Map<*, *>)?.get("framesPerSecond")
        require(value is Int) { "framesPerSecond must be an integer" }
        mutableLimit.value = validate(value)
    }

    companion object {
        fun validate(limit: Int): Int {
            require(limit in setOf(30, 45, 60, 90, 120)) { "Unsupported frame rate limit" }
            return limit
        }
    }
}

internal class RuntimeFrameRateHint(
    private val applyLimit: (Int) -> Unit,
    private val clearLimit: () -> Unit,
) {
    private var limit = 60
    private var active = false
    private var surfaceReady = false
    private var appliedLimit: Int? = null

    fun updateLimit(limit: Int) {
        val next = RuntimeFrameRate.validate(limit)
        if (this.limit == next) return
        this.limit = next
        applyIfReady()
    }

    fun start() {
        if (active) return
        active = true
        applyIfReady()
    }

    fun surfaceAvailable() {
        surfaceReady = true
        appliedLimit = null
        applyIfReady()
    }

    fun surfaceDestroyed() {
        clear()
        surfaceReady = false
    }

    fun stop() {
        active = false
        clear()
    }

    private fun applyIfReady() {
        if (!active || !surfaceReady || appliedLimit == limit) return
        applyLimit(limit)
        appliedLimit = limit
    }

    private fun clear() {
        if (appliedLimit == null) return
        clearLimit()
        appliedLimit = null
    }
}
