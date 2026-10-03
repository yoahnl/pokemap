package com.yoahnl.avelune.host

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertThrows
import org.junit.Test

class SurfaceProbeTest {
    @Test
    fun companionRequiresDebugCapablePlatformAndAnExclusiveVisibleProbe() {
        val topology = topology()
        assertEquals(43, SurfaceProbeWindowPolicy.companionDisplay(true, 26, true, true, true, topology))
        assertNull(SurfaceProbeWindowPolicy.companionDisplay(false, 33, true, true, true, topology))
        assertNull(SurfaceProbeWindowPolicy.companionDisplay(true, 25, true, true, true, topology))
        assertNull(SurfaceProbeWindowPolicy.companionDisplay(true, 33, false, true, true, topology))
        assertNull(SurfaceProbeWindowPolicy.companionDisplay(true, 33, true, false, true, topology))
        assertNull(SurfaceProbeWindowPolicy.companionDisplay(true, 33, true, true, false, topology))
    }

    @Test
    fun unavailableOrPrimaryOnlyTopologyFallsBackToOwner() {
        assertNull(SurfaceProbeWindowPolicy.companionDisplay(true, 33, true, true, true, DisplayTopology()))
        assertNull(SurfaceProbeWindowPolicy.companionDisplay(true, 33, true, true, true, topology().copy(companions = emptyList())))
        val sleeping = topology().copy(companions = listOf(display(43).copy(isAvailable = false)))
        assertNull(SurfaceProbeWindowPolicy.companionDisplay(true, 33, true, true, true, sleeping))
    }

    @Test
    fun windowKeepsItsLeaseUntilDisplayChangesThenIssuesANewSource() {
        val windows = SurfaceProbeWindows()
        val first = windows.select(43)!!
        assertSame(first, windows.select(43))
        assertEquals("companion-1", first.sourceId)
        assertNull(windows.select(null))
        val reconnected = windows.select(43)!!
        assertEquals("companion-2", reconnected.sourceId)
        assertEquals(43, reconnected.displayId)
        assertEquals(false, windows.isCurrent(first.generation))
        assertEquals(true, windows.isCurrent(reconnected.generation))
    }

    @Test
    fun relayPreservesOwnerValueAndRevisionAcrossWindowReconnect() {
        val relay = SurfaceProbeRelay("session-a")
        val initial = payload(value = 7, revision = 12, attached = true)
        relay.acceptSnapshot(initial)
        assertEquals(SurfaceProbeSnapshot("session-a", 7, 12, true), relay.snapshot)
        val windows = SurfaceProbeWindows()
        windows.select(43)
        windows.select(null)
        windows.select(43)
        assertEquals(initial, relay.snapshot!!.payload())
        assertNull(relay.acceptSnapshot(payload(session = "old-session", value = 99)))
        assertEquals(7L, relay.snapshot!!.value)
        assertNull(relay.acceptSnapshot(payload(value = 3, revision = 11)))
        assertEquals(12L, relay.snapshot!!.revision)
    }

    @Test
    fun companionIntentUsesNativeGenerationAndRejectsInvalidOrStaleRequests() {
        val relay = SurfaceProbeRelay("session-a")
        val intent = mapOf("sessionId" to "session-a", "sourceId" to "untrusted", "sequence" to 2L, "action" to "increment")
        assertEquals("companion-3", relay.companionIntent(intent, "companion-3")["sourceId"])
        assertEquals(2L, relay.companionIntent(intent, "companion-3")["sequence"])
        assertThrows(IllegalArgumentException::class.java) { relay.companionIntent(intent + ("sessionId" to "old"), "companion-3") }
        assertThrows(IllegalArgumentException::class.java) { relay.companionIntent(intent + ("sequence" to 0L), "companion-3") }
        assertThrows(IllegalArgumentException::class.java) { relay.companionIntent(intent + ("sequence" to 1.5), "companion-3") }
        assertThrows(IllegalArgumentException::class.java) { relay.companionIntent(intent + ("action" to "reset"), "companion-3") }
        assertNull(relay.snapshot)
    }

    private fun topology() = DisplayTopology(primary = display(12), companions = listOf(display(43)))
    private fun display(id: Int) = DisplayCapability(id, "Display $id", 1920, 1080, false, false, true)
    private fun payload(session: String = "session-a", value: Long = 7, revision: Long = 12, attached: Boolean = false) =
        mapOf("sessionId" to session, "value" to value, "revision" to revision, "companionAttached" to attached)
}
