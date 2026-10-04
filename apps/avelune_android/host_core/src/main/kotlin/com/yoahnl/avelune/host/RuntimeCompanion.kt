package com.yoahnl.avelune.host

enum class RuntimeOwnerLifecycle { DETACHED, PAUSED, INACTIVE, RESUMED }

object RuntimeCompanionFocusPolicy {
    fun ownerLifecycle(
        ownerPresent: Boolean,
        sessionActive: Boolean,
        ownerVisible: Boolean,
        stopping: Boolean,
        ownerResumed: Boolean,
        ownerFocused: Boolean,
        currentCompanion: Boolean,
        companionVisible: Boolean,
        companionResumed: Boolean,
        companionFocused: Boolean,
    ): RuntimeOwnerLifecycle {
        if (!ownerPresent) return RuntimeOwnerLifecycle.DETACHED
        if (!ownerVisible) return RuntimeOwnerLifecycle.PAUSED
        if (!sessionActive || stopping) return RuntimeOwnerLifecycle.INACTIVE
        val focused = ownerResumed && ownerFocused || currentCompanion && companionVisible && companionResumed && companionFocused
        return if (focused) RuntimeOwnerLifecycle.RESUMED else RuntimeOwnerLifecycle.INACTIVE
    }
}

object RuntimeCompanionWindowPolicy {
    fun attached(sessionActive: Boolean, ownerVisible: Boolean, stopping: Boolean, connected: Boolean, dartReady: Boolean, viewAttached: Boolean, companionVisible: Boolean): Boolean =
        sessionActive && ownerVisible && !stopping && connected && dartReady && viewAttached && companionVisible

    fun companionDisplay(
        apiLevel: Int,
        sessionActive: Boolean,
        ownerVisible: Boolean,
        stopping: Boolean,
        secondaryActivitiesSupported: Boolean,
        topology: DisplayTopology,
    ): Int? {
        if (apiLevel < 29 || !sessionActive || !ownerVisible || stopping || !secondaryActivitiesSupported) return null
        val primary = topology.primary ?: return null
        return topology.companions.firstOrNull {
            it.id != primary.id && it.isAvailable && !it.isPrivate && it.width > 0 && it.height > 0
        }?.id
    }
}

data class RuntimeCompanionWindowLease(val displayId: Int, val generation: Long) {
    val sourceId get() = "companion-$generation"
}

class RuntimeCompanionWindows {
    var current: RuntimeCompanionWindowLease? = null
        private set
    private var generation = 0L

    fun select(displayId: Int?): RuntimeCompanionWindowLease? {
        if (current?.displayId == displayId) return current
        current = displayId?.let { RuntimeCompanionWindowLease(it, ++generation) }
        return current
    }

    fun isCurrent(generation: Long): Boolean = current?.generation == generation
}

class RuntimeCompanionRelay(val sessionId: String) {
    var snapshot: Map<String, Any?>? = null
        private set
    private var revision = -1L

    fun acceptSnapshot(payload: Any?): Map<String, Any?>? {
        val next = payload.transportMap()
        val nextRevision = next["revision"].transportRevision()
        if (next["sessionId"] != sessionId || nextRevision < revision) return null
        revision = nextRevision
        snapshot = next
        return next
    }

    fun clearSnapshot() {
        snapshot = null
    }

    fun companionIntent(payload: Any?, sourceId: String): Map<String, Any?> {
        val request = payload.transportMap()
        require(request["sessionId"] == sessionId) { "Cette action appartient à une autre partie." }
        return request + ("sourceId" to sourceId)
    }

    fun ownerInput(payload: Any?, attached: Boolean, currentLease: Boolean): Map<String, Any?>? {
        if (!attached || !currentLease || snapshot == null) return null
        val input = payload.transportMap()
        if (input["sessionId"] != sessionId || input["revision"].transportRevision() < revision) return null
        require((input["control"] as? String)?.isNotBlank() == true) { "Commande du compagnon invalide." }
        require(input["phase"] == "press" || input["phase"] == "release") { "Phase de commande invalide." }
        require(input["isRepeat"] is Boolean) { "Répétition de commande invalide." }
        return input
    }
}

private fun Any?.transportMap(): Map<String, Any?> {
    require(this is Map<*, *> && keys.all { it is String }) { "Message du compagnon invalide." }
    return entries.associate { (key, value) -> key as String to value }
}

private fun Any?.transportRevision(): Long {
    val revision = when (this) {
        is Int -> toLong()
        is Long -> this
        else -> throw IllegalArgumentException("Révision du compagnon invalide.")
    }
    require(revision >= 0) { "Révision du compagnon invalide." }
    return revision
}
