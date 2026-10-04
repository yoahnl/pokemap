package com.yoahnl.avelune.host

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class DisplayTopologyTest {
    @Test
    fun availableSecondaryDisplayIsCompanionWithoutActivatingAnotherSession() {
        val topology = DisplayRolePolicy.resolve(
            listOf(display(12), display(43)),
            hostDisplayId = 12,
        )

        assertEquals(12, topology.primary?.id)
        assertEquals(listOf(43), topology.companions.map { it.id })
        assertEquals(DisplaySessionMode.SINGLE, topology.activeMode)
    }

    @Test
    fun hostDisplayWinsOverDefaultAndPrivateOrSleepingScreensAreExcluded() {
        val topology = DisplayRolePolicy.resolve(
            listOf(
                display(0, default = true),
                display(12),
                display(43, private = true),
                display(51, available = false),
            ),
            hostDisplayId = 12,
        )

        assertEquals(12, topology.primary?.id)
        assertEquals(listOf(0), topology.companions.map { it.id })
    }

    @Test
    fun removedHostDisplayFallsBackToDefaultDisplay() {
        val topology = DisplayRolePolicy.resolve(
            listOf(display(24), display(7, default = true)),
            hostDisplayId = 99,
        )

        assertEquals(7, topology.primary?.id)
        assertEquals(listOf(24), topology.companions.map { it.id })
    }

    @Test
    fun noUsableDisplayDoesNotInventAPrimary() {
        val topology = DisplayRolePolicy.resolve(listOf(display(1, available = false)))

        assertNull(topology.primary)
        assertEquals(emptyList<DisplayCapability>(), topology.companions)
    }

    private fun display(
        id: Int,
        default: Boolean = false,
        private: Boolean = false,
        available: Boolean = true,
    ) = DisplayCapability(id, "Display $id", 1920, 1080, default, private, available)
}
