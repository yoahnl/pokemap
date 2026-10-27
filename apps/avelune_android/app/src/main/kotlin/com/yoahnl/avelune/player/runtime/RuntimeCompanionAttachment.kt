package com.yoahnl.avelune.player.runtime

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Job
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.launch

internal class RuntimeCompanionAttachment(
    private val scope: CoroutineScope,
    private val canReport: (Boolean) -> Boolean,
    private val report: suspend (Boolean, () -> Unit) -> Any?,
    private val onReply: (Any?) -> Unit,
    private val onFailure: (Boolean, Exception) -> Unit,
) {
    private var attached = false
    private var transition = 0L
    private var presentation: Any? = emptyMap<String, Any?>()
    private var revision: Any? = null
    var isConfirmed = false
        private set

    fun update(next: Boolean): Job? {
        if (attached == next) return null
        attached = next
        isConfirmed = false
        val current = ++transition
        return scope.launch(start = CoroutineStart.UNDISPATCHED) {
            try {
                val response = report(next) { check(canReport(next)) }
                if (current != transition || !canReport(next)) return@launch
                check(!next || response is Map<*, *> && response["companionAttached"] == true) {
                    "Le moteur n’a pas confirmé cet écran compagnon."
                }
                isConfirmed = next
                onReply(response)
            } catch (error: Exception) {
                if (error is CancellationException && error !is TimeoutCancellationException) throw error
                if (current == transition && canReport(next)) {
                    isConfirmed = false
                    onFailure(next, error)
                }
            }
        }
    }

    fun snapshot(payload: Map<String, Any?>?): Map<String, Any?>? {
        if (payload == null) return null
        if (!attached || isConfirmed || revision == null) revision = payload["revision"]
        if (isConfirmed) {
            presentation = payload["presentation"] ?: emptyMap<String, Any?>()
            return payload
        }
        return mapOf(
            "sessionId" to payload["sessionId"],
            "revision" to revision,
            "companionAttached" to false,
            "mode" to "waiting",
            "player" to null,
            "battle" to null,
            "dialogue" to null,
            "narrativeGeneration" to payload["narrativeGeneration"],
            "narrativeReady" to false,
            "presentation" to presentation,
        )
    }
}
