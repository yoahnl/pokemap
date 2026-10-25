package com.yoahnl.avelune.player.runtime

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class RuntimeFrameRateTest {
    @Test
    fun defaultsToSixtyAndAcceptsEverySupportedInteger() {
        val setting = RuntimeFrameRate()
        assertEquals(60, setting.limit.value)

        for (limit in listOf(30, 45, 60, 90, 120)) {
            setting.setLimit(mapOf("framesPerSecond" to limit))
            assertEquals(limit, setting.limit.value)
        }
    }

    @Test
    fun malformedArgumentsKeepTheConfirmedLimit() {
        val setting = RuntimeFrameRate()
        setting.setLimit(mapOf("framesPerSecond" to 90))

        for (arguments in listOf(
            null,
            60,
            emptyMap<String, Any>(),
            mapOf("framesPerSecond" to null),
            mapOf("framesPerSecond" to "60"),
            mapOf("framesPerSecond" to 60.0),
            mapOf("framesPerSecond" to 60L),
            mapOf("framesPerSecond" to true),
            mapOf("framesPerSecond" to 0),
            mapOf("framesPerSecond" to 24),
            mapOf("framesPerSecond" to 59),
            mapOf("framesPerSecond" to 144),
        )) {
            expectInvalid { setting.setLimit(arguments) }
            assertEquals(90, setting.limit.value)
        }
    }

    @Test
    fun hintsWaitForBothAStartedActivityAndAReadySurface() {
        val target = RecordingTarget()
        val hint = target.hint

        hint.updateLimit(120)
        hint.start()
        assertTrue(target.requests.isEmpty())
        hint.surfaceAvailable()
        assertEquals(listOf(120), target.requests)
        hint.updateLimit(120)
        assertEquals(listOf(120), target.requests)
        hint.updateLimit(90)
        assertEquals(listOf(120, 90), target.requests)
    }

    @Test
    fun aNewSurfaceReceivesTheLatestLimitAndThePreviousHintIsCleared() {
        val target = RecordingTarget()
        val hint = target.hint

        hint.start()
        hint.surfaceAvailable()
        hint.surfaceDestroyed()
        hint.updateLimit(45)
        assertEquals(listOf(60, 0), target.requests)
        hint.surfaceAvailable()
        hint.surfaceAvailable()
        assertEquals(listOf(60, 0, 45, 45), target.requests)
    }

    @Test
    fun stoppedActivitiesClearHintsAndDeferUpdatesUntilRestart() {
        val target = RecordingTarget()
        val hint = target.hint

        hint.surfaceAvailable()
        hint.start()
        hint.stop()
        hint.stop()
        hint.updateLimit(30)
        hint.surfaceDestroyed()
        hint.surfaceAvailable()
        assertEquals(listOf(60, 0), target.requests)
        hint.start()
        assertEquals(listOf(60, 0, 30), target.requests)
        hint.surfaceDestroyed()
        hint.stop()
        assertEquals(listOf(60, 0, 30, 0), target.requests)
    }

    @Test
    fun invalidLiveLimitsCannotReachTheSurface() {
        val target = RecordingTarget()
        target.hint.start()
        target.hint.surfaceAvailable()

        expectInvalid { target.hint.updateLimit(144) }

        assertEquals(listOf(60), target.requests)
    }

    private fun expectInvalid(block: () -> Unit) {
        var rejected = false
        try {
            block()
        } catch (error: IllegalArgumentException) {
            rejected = true
        }
        assertTrue("The invalid frame rate must be rejected", rejected)
    }

    private class RecordingTarget {
        val requests = mutableListOf<Int>()
        val hint = RuntimeFrameRateHint(
            applyLimit = { requests += it },
            clearLimit = { requests += 0 },
        )
    }
}
