package com.yoahnl.avelune.host

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertThrows
import org.junit.Test

class RuntimeCompanionTest {
    @Test
    fun focusedOwnerOrCurrentResumedCompanionKeepsTheOwnerActive() {
        assertEquals(RuntimeOwnerLifecycle.RESUMED, lifecycle(ownerFocused = true))
        assertEquals(RuntimeOwnerLifecycle.RESUMED, lifecycle(ownerResumed = false, companionFocused = true))
        assertEquals(RuntimeOwnerLifecycle.INACTIVE, lifecycle())
        assertEquals(RuntimeOwnerLifecycle.INACTIVE, lifecycle(companionFocused = true, currentCompanion = false))
        assertEquals(RuntimeOwnerLifecycle.INACTIVE, lifecycle(companionFocused = true, companionVisible = false))
        assertEquals(RuntimeOwnerLifecycle.INACTIVE, lifecycle(companionFocused = true, companionResumed = false))
    }

    @Test
    fun stoppingHiddenAndReplacedOwnersCannotBeActivatedByTheCompanion() {
        assertEquals(RuntimeOwnerLifecycle.INACTIVE, lifecycle(companionFocused = true, stopping = true))
        assertEquals(RuntimeOwnerLifecycle.INACTIVE, lifecycle(companionFocused = true, active = false))
        assertEquals(RuntimeOwnerLifecycle.PAUSED, lifecycle(companionFocused = true, visible = false))
        assertEquals(RuntimeOwnerLifecycle.DETACHED, lifecycle(companionFocused = true, present = false))
    }

    @Test
    fun focusHandoffUsesTheLatestPairStateWithoutRequiringMenuReadiness() {
        assertEquals(RuntimeOwnerLifecycle.RESUMED, lifecycle(ownerFocused = true))
        assertEquals(RuntimeOwnerLifecycle.RESUMED, lifecycle(companionFocused = true))
        assertEquals(RuntimeOwnerLifecycle.RESUMED, lifecycle(ownerFocused = true, currentCompanion = false))
        assertEquals(RuntimeOwnerLifecycle.INACTIVE, lifecycle())
    }

    @Test
    fun handshakeDoesNotDelegateBeforeTheConfiguredSurfaceIsReadyAndVisible() {
        assertEquals(false, RuntimeCompanionWindowPolicy.attached(true, true, false, true, false, true, true))
        assertEquals(false, RuntimeCompanionWindowPolicy.attached(true, true, false, true, true, false, true))
        assertEquals(false, RuntimeCompanionWindowPolicy.attached(true, true, false, true, true, true, false))
        assertEquals(false, RuntimeCompanionWindowPolicy.attached(true, true, true, true, true, true, true))
        assertEquals(false, RuntimeCompanionWindowPolicy.attached(true, false, false, true, true, true, true))
        assertEquals(true, RuntimeCompanionWindowPolicy.attached(true, true, false, true, true, true, true))
    }

    @Test
    fun gameplayRequiresMultiResumeAndAnActiveVisibleOwner() {
        assertNull(select(api = 28))
        assertEquals(43, select(api = 29))
        assertNull(select(active = false))
        assertNull(select(visible = false))
        assertNull(select(stopping = true))
        assertNull(select(supported = false))
    }

    @Test
    fun unavailableCompanionFallsBackWithoutChangingTheOwnerSnapshot() {
        val relay = RuntimeCompanionRelay("session-a")
        val state = snapshot(12)
        assertEquals(state, relay.acceptSnapshot(state))
        assertNull(select(topology = topology().copy(companions = emptyList())))
        assertNull(select(topology = topology().copy(companions = listOf(display(43).copy(isAvailable = false)))))
        assertNull(select(topology = topology().copy(companions = listOf(display(43).copy(isPrivate = true)))))
        assertEquals(state, relay.snapshot)
    }

    @Test
    fun relayPreservesBusinessDataAndRejectsStaleOwnerReplies() {
        val relay = RuntimeCompanionRelay("session-a")
        val latest = snapshot(12)
        assertEquals(latest, relay.acceptSnapshot(latest))
        assertNull(relay.acceptSnapshot(snapshot(11)))
        assertNull(relay.acceptSnapshot(snapshot(99) + ("sessionId" to "old-session")))
        assertEquals(latest, relay.snapshot)
        assertThrows(IllegalArgumentException::class.java) { relay.acceptSnapshot(snapshot(12) + ("revision" to 1.5)) }
        assertEquals(latest, relay.snapshot)
        relay.clearSnapshot()
        assertNull(relay.snapshot)
        assertNull(relay.acceptSnapshot(snapshot(11)))
    }

    @Test
    fun reconnectIssuesAnotherLeaseAndInvalidatesThePreviousWindow() {
        val windows = RuntimeCompanionWindows()
        val first = windows.select(43)!!
        assertSame(first, windows.select(43))
        windows.select(null)
        val second = windows.select(43)!!
        assertEquals(false, windows.isCurrent(first.generation))
        assertEquals(true, windows.isCurrent(second.generation))
        assertEquals("companion-2", second.sourceId)
    }

    @Test
    fun companionIntentKeepsTheOwnerPayloadAndRejectsAnotherSession() {
        val relay = RuntimeCompanionRelay("session-a")
        val request = mapOf("sessionId" to "session-a", "revision" to 12, "sequence" to 4, "action" to "chooseMove", "payload" to mapOf("moveIndex" to 2))
        assertEquals(request + ("sourceId" to "companion-2"), relay.companionIntent(request, "companion-2"))
        assertThrows(IllegalArgumentException::class.java) { relay.companionIntent(request + ("sessionId" to "old-session"), "companion-2") }
        assertEquals(null, relay.snapshot)
    }

    @Test
    fun inputRequiresACurrentAttachedLeaseAndForwardsTheExactOwnerEnvelope() {
        val relay = RuntimeCompanionRelay("session-a")
        relay.acceptSnapshot(snapshot(12))
        val input = mapOf("sessionId" to "session-a", "revision" to 12, "control" to "confirm", "phase" to "press", "isRepeat" to false)
        assertEquals(input, relay.ownerInput(input, attached = true, currentLease = true))
        assertNull(relay.ownerInput(input, attached = false, currentLease = true))
        assertNull(relay.ownerInput(input, attached = true, currentLease = false))
        assertNull(relay.ownerInput(input + ("sessionId" to "old-session"), true, true))
        assertNull(relay.ownerInput(input + ("revision" to 11), true, true))
        assertThrows(IllegalArgumentException::class.java) { relay.ownerInput(input + ("phase" to "toggle"), true, true) }
        assertThrows(IllegalArgumentException::class.java) { relay.ownerInput(input + ("isRepeat" to "false"), true, true) }
        assertEquals(snapshot(12), relay.snapshot)
    }

    private fun select(api: Int = 33, active: Boolean = true, visible: Boolean = true, stopping: Boolean = false, supported: Boolean = true, topology: DisplayTopology = topology()) =
        RuntimeCompanionWindowPolicy.companionDisplay(api, active, visible, stopping, supported, topology)

    private fun lifecycle(
        present: Boolean = true,
        active: Boolean = true,
        visible: Boolean = true,
        stopping: Boolean = false,
        ownerResumed: Boolean = true,
        ownerFocused: Boolean = false,
        currentCompanion: Boolean = true,
        companionVisible: Boolean = true,
        companionResumed: Boolean = true,
        companionFocused: Boolean = false,
    ) = RuntimeCompanionFocusPolicy.ownerLifecycle(
        present, active, visible, stopping, ownerResumed, ownerFocused,
        currentCompanion, companionVisible, companionResumed, companionFocused,
    )

    private fun topology() = DisplayTopology(primary = display(12), companions = listOf(display(43)))
    private fun display(id: Int) = DisplayCapability(id, "Display $id", 1920, 1080, false, false, true)
    private fun snapshot(revision: Int) = mapOf("sessionId" to "session-a", "revision" to revision, "mode" to "battle", "battle" to mapOf("moves" to listOf("Charge", "Rugissement"), "selected" to 1))
}
