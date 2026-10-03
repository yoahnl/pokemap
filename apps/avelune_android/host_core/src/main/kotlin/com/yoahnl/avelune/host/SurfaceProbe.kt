package com.yoahnl.avelune.host

object SurfaceProbeWindowPolicy {
    fun companionDisplay(
        debugBuild: Boolean,
        apiLevel: Int,
        sessionActive: Boolean,
        ownerVisible: Boolean,
        companionEnabled: Boolean,
        topology: DisplayTopology,
    ): Int? {
        if (!debugBuild || apiLevel < 26 || !sessionActive || !ownerVisible || !companionEnabled) return null
        val primary = topology.primary ?: return null
        return topology.companions.firstOrNull {
            it.id != primary.id && it.isAvailable && !it.isPrivate && it.width > 0 && it.height > 0
        }?.id
    }
}

data class SurfaceProbeWindowLease(val displayId: Int, val generation: Long) {
    val sourceId get() = "companion-$generation"
    val engineId get() = "avelune_surface_probe_$generation"
}

class SurfaceProbeWindows {
    var current: SurfaceProbeWindowLease? = null
        private set
    private var generation = 0L

    fun select(displayId: Int?): SurfaceProbeWindowLease? {
        if (current?.displayId == displayId) return current
        current = displayId?.let { SurfaceProbeWindowLease(it, ++generation) }
        return current
    }

    fun isCurrent(generation: Long): Boolean = current?.generation == generation
}

data class SurfaceProbeSnapshot(val sessionId: String, val value: Long, val revision: Long, val companionAttached: Boolean) {
    fun payload(): Map<String, Any> = mapOf(
        "sessionId" to sessionId,
        "value" to value,
        "revision" to revision,
        "companionAttached" to companionAttached,
    )

    companion object {
        fun fromPayload(payload: Any?): SurfaceProbeSnapshot {
            require(payload is Map<*, *>) { "État du prototype invalide." }
            val sessionId = payload["sessionId"] as? String
            require(!sessionId.isNullOrBlank()) { "Session du prototype invalide." }
            val value = payload["value"].integer()
            val revision = payload["revision"].integer()
            require(value >= 0 && revision >= 0) { "Valeur du prototype invalide." }
            val attached = payload["companionAttached"] as? Boolean
            require(attached != null) { "État du compagnon invalide." }
            return SurfaceProbeSnapshot(sessionId, value, revision, attached)
        }
    }
}

class SurfaceProbeRelay(val sessionId: String) {
    var snapshot: SurfaceProbeSnapshot? = null
        private set

    fun acceptSnapshot(payload: Any?): SurfaceProbeSnapshot? {
        val next = SurfaceProbeSnapshot.fromPayload(payload)
        if (next.sessionId != sessionId || next.revision < (snapshot?.revision ?: 0)) return null
        snapshot = next
        return next
    }

    fun companionIntent(payload: Any?, sourceId: String): Map<String, Any> {
        require(payload is Map<*, *>) { "Action du compagnon invalide." }
        require(payload["sessionId"] == sessionId) { "Cette action appartient à une autre session." }
        val sequence = payload["sequence"].integer()
        require(sequence > 0 && payload["action"] == "increment") { "Action du compagnon invalide." }
        return mapOf("sessionId" to sessionId, "sourceId" to sourceId, "sequence" to sequence, "action" to "increment")
    }
}

private fun Any?.integer(): Long = when (this) {
    is Int -> toLong()
    is Long -> this
    else -> throw IllegalArgumentException("Entier du prototype invalide.")
}
