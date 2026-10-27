package com.yoahnl.avelune.player.runtime

import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class RuntimeCompanionAttachmentTest {
    @Test
    fun ownerMutexCannotDropADetachWhenTheSurfaceReattachesBeforeItIsReleased() = runBlocking {
        val ownerCalls = Mutex(locked = true)
        val reported = mutableListOf<Boolean>()
        val failures = mutableListOf<Exception>()
        val attachment = attachment(this, failures = failures, report = { attached, beforeInvoke ->
            ownerCalls.withLock {
                beforeInvoke()
                reported += attached
                snapshot(reported.size, attached)
            }
        })

        val initial = attachment.update(true)!!
        val detached = attachment.update(false)!!
        val reattached = attachment.update(true)!!
        assertTrue(reported.isEmpty())
        assertFalse(attachment.isConfirmed)
        ownerCalls.unlock()
        initial.join()
        detached.join()
        reattached.join()

        assertEquals(listOf(true, false, true), reported)
        assertTrue(failures.isEmpty())
        assertTrue(attachment.isConfirmed)
    }

    @Test(timeout = 5_000)
    fun aSupersededAttachReplyCannotMakeTheReattachedSurfaceActionable() = runBlocking {
        val firstReply = CompletableDeferred<Unit>()
        val latestReply = CompletableDeferred<Unit>()
        val latestStarted = CompletableDeferred<Unit>()
        val ownerCalls = Mutex()
        val accepted = mutableListOf<Any?>()
        var calls = 0
        val attachment = attachment(this, accepted = accepted, report = { attached, beforeInvoke ->
            ownerCalls.withLock {
                beforeInvoke()
                calls++
                if (calls == 1) firstReply.await()
                if (calls == 3) {
                    latestStarted.complete(Unit)
                    latestReply.await()
                }
                snapshot(calls, attached)
            }
        })

        val initial = attachment.update(true)!!
        attachment.update(false)
        val reattached = attachment.update(true)!!
        firstReply.complete(Unit)
        initial.join()
        latestStarted.await()
        assertEquals(3, calls)
        assertFalse(attachment.isConfirmed)
        assertTrue(accepted.isEmpty())
        assertWaiting(attachment.snapshot(snapshot(1, true)))
        latestReply.complete(Unit)
        reattached.join()

        assertEquals(listOf(snapshot(3, true)), accepted)
        assertTrue(attachment.isConfirmed)
        assertEquals(snapshot(3, true), attachment.snapshot(snapshot(3, true)))
    }

    @Test
    fun handshakeAndBroadcastProjectionKeepGameplayHiddenUntilTheCurrentAck() = runBlocking {
        val reply = CompletableDeferred<Unit>()
        val attachment = attachment(this, report = { attached, beforeInvoke ->
            beforeInvoke()
            reply.await()
            snapshot(2, attached)
        })
        val stale = snapshot(1, true)

        assertNull(attachment.snapshot(null))
        assertWaiting(attachment.snapshot(stale))
        val pending = attachment.update(true)!!
        assertWaiting(attachment.snapshot(stale))
        reply.complete(Unit)
        pending.join()
        assertSame(stale, attachment.snapshot(stale))
        attachment.update(false)!!.join()
        assertWaiting(attachment.snapshot(stale))
    }

    @Test
    fun pendingOwnerWaitingDoesNotDiscardTheAlreadyConfiguredPresentation() = runBlocking {
        val attachment = attachment(this)
        attachment.update(true)!!.join()
        val configured = snapshot(3, true) + ("presentation" to mapOf("images" to mapOf("menu" to "file:///menu.png")))
        attachment.snapshot(configured)
        attachment.update(false)!!.join()

        val waiting = attachment.snapshot(snapshot(4, false) + ("presentation" to emptyMap<String, Any>()))!!

        assertWaiting(waiting)
        assertEquals(configured["presentation"], waiting["presentation"])
    }

    @Test
    fun pendingProjectionCannotConsumeTheRevisionOfTheFreshAck() = runBlocking {
        val reply = CompletableDeferred<Unit>()
        val attachment = attachment(this, report = { attached, beforeInvoke ->
            beforeInvoke()
            reply.await()
            snapshot(3, attached)
        })
        assertEquals(1, attachment.snapshot(snapshot(1, false))!!["revision"])
        val pending = attachment.update(true)!!

        assertEquals(1, attachment.snapshot(snapshot(2, true))!!["revision"])
        assertEquals(1, attachment.snapshot(snapshot(3, true))!!["revision"])
        reply.complete(Unit)
        pending.join()
        assertEquals(3, attachment.snapshot(snapshot(3, true))!!["revision"])
    }

    @Test
    fun obsoleteErrorsCannotCloseTheCurrentSurfaceAndCurrentErrorsCannotConfirmIt() = runBlocking {
        val failedReply = CompletableDeferred<Unit>()
        val failures = mutableListOf<Exception>()
        var calls = 0
        val attachment = attachment(this, failures = failures, report = { attached, beforeInvoke ->
            beforeInvoke()
            calls++
            if (calls == 1) {
                failedReply.await()
                error("obsolete attach")
            }
            snapshot(calls, attached)
        })

        val obsolete = attachment.update(true)!!
        attachment.update(false)!!.join()
        attachment.update(true)!!.join()
        failedReply.complete(Unit)
        obsolete.join()
        assertTrue(failures.isEmpty())
        assertTrue(attachment.isConfirmed)

        val current = attachment(this, failures = failures, report = { _, _ -> error("current attach") })
        current.update(true)!!.join()
        assertFalse(current.isConfirmed)
        assertEquals("current attach", failures.single().message)
    }

    @Test
    fun aClosedOrReplacedSessionCannotInvokeOrConfirmAnAttach() = runBlocking {
        val ownerCalls = Mutex(locked = true)
        val accepted = mutableListOf<Any?>()
        var active = true
        var calls = 0
        val attachment = RuntimeCompanionAttachment(
            scope = this,
            canReport = { active },
            report = { attached, beforeInvoke -> ownerCalls.withLock {
                beforeInvoke()
                calls++
                snapshot(1, attached)
            } },
            onReply = { accepted += it },
            onFailure = { _, _ -> },
        )
        val pending = attachment.update(true)!!
        active = false
        ownerCalls.unlock()
        pending.join()
        assertEquals(0, calls)
        assertFalse(attachment.isConfirmed)
        assertTrue(accepted.isEmpty())
    }

    @Test
    fun stoppingSkipsAPendingAttachAndStillDeliversTheQueuedDetach() = runBlocking {
        val ownerCalls = Mutex(locked = true)
        val reported = mutableListOf<Boolean>()
        var ending = false
        val attachment = RuntimeCompanionAttachment(
            scope = this,
            canReport = { attached -> !attached || !ending },
            report = { attached, beforeInvoke -> ownerCalls.withLock {
                beforeInvoke()
                reported += attached
                snapshot(1, attached)
            } },
            onReply = {},
            onFailure = { _, _ -> },
        )
        val pending = attachment.update(true)!!
        val detached = attachment.update(false)!!
        ending = true
        ownerCalls.unlock()
        pending.join()
        detached.join()

        assertEquals(listOf(false), reported)
        assertFalse(attachment.isConfirmed)
    }

    @Test
    fun repeatedPhysicalStateDoesNotEnqueueAnotherOwnerCall() = runBlocking {
        var calls = 0
        val attachment = attachment(this, report = { attached, beforeInvoke ->
            beforeInvoke()
            calls++
            snapshot(calls, attached)
        })
        assertNull(attachment.update(false))
        attachment.update(true)!!.join()
        assertNull(attachment.update(true))
        attachment.update(false)!!.join()
        assertNull(attachment.update(false))
        assertEquals(2, calls)
    }

    @Test
    fun missingOrDetachedOwnerRepliesCannotEnableTheSurface() = runBlocking {
        for (reply in listOf(null, snapshot(1, false))) {
            val failures = mutableListOf<Exception>()
            val attachment = attachment(this, failures = failures, report = { _, beforeInvoke -> beforeInvoke(); reply })
            attachment.update(true)!!.join()
            assertFalse(attachment.isConfirmed)
            assertEquals(1, failures.size)
        }
    }

    private fun attachment(
        scope: CoroutineScope,
        accepted: MutableList<Any?> = mutableListOf(),
        failures: MutableList<Exception> = mutableListOf(),
        report: suspend (Boolean, () -> Unit) -> Any? = { attached, beforeInvoke -> beforeInvoke(); snapshot(1, attached) },
    ) = RuntimeCompanionAttachment(
        scope = scope,
        canReport = { true },
        report = report,
        onReply = { accepted += it },
        onFailure = { _, error -> failures += error },
    )

    private fun assertWaiting(snapshot: Map<String, Any?>?) {
        requireNotNull(snapshot)
        assertEquals("waiting", snapshot["mode"])
        assertEquals(false, snapshot["companionAttached"])
        assertEquals(false, snapshot["narrativeReady"])
        for (field in listOf("player", "battle", "dialogue")) assertNull(snapshot[field])
    }

    private fun snapshot(revision: Int, attached: Boolean): Map<String, Any?> = mapOf(
        "sessionId" to "session-a", "revision" to revision, "mode" to "menu", "companionAttached" to attached,
        "narrativeReady" to true, "player" to mapOf("revision" to revision), "battle" to null, "dialogue" to null,
        "presentation" to emptyMap<String, Any>(),
    )
}
