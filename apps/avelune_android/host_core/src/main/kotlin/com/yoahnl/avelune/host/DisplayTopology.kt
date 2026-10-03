package com.yoahnl.avelune.host

data class DisplayCapability(
    val id: Int,
    val name: String,
    val width: Int,
    val height: Int,
    val isDefault: Boolean,
    val isPrivate: Boolean,
    val isAvailable: Boolean,
)

enum class DisplaySessionMode { SINGLE }

data class DisplayTopology(
    val primary: DisplayCapability? = null,
    val companions: List<DisplayCapability> = emptyList(),
    val activeMode: DisplaySessionMode = DisplaySessionMode.SINGLE,
) {
    fun diagnostics(): Map<String, Any?> = mapOf(
        "activeMode" to activeMode.name.lowercase(),
        "primary" to primary?.payload(),
        "companions" to companions.map { it.payload() },
    )

    private fun DisplayCapability.payload(): Map<String, Any> = mapOf(
        "displayId" to id,
        "name" to name,
        "width" to width,
        "height" to height,
    )
}

object DisplayRolePolicy {
    fun resolve(displays: List<DisplayCapability>, hostDisplayId: Int? = null): DisplayTopology {
        val available = displays.filter { it.isAvailable && !it.isPrivate && it.width > 0 && it.height > 0 }
            .distinctBy { it.id }
            .sortedBy { it.id }
        val primary = available.firstOrNull { it.id == hostDisplayId }
            ?: available.firstOrNull { it.isDefault }
            ?: available.firstOrNull()
        return DisplayTopology(primary, available.filter { it.id != primary?.id })
    }
}
