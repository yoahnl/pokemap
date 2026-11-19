package com.yoahnl.avelune.player.runtime

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

internal enum class AppLanguage(val wireValue: String) {
    SYSTEM("system"),
    FRENCH("fr"),
    ENGLISH("en");

    companion object {
        fun fromWire(value: Any?): AppLanguage? = entries.find { it.wireValue == value }
    }
}

internal data class LanguagePreferences(
    val appLanguage: AppLanguage,
    val appLocale: String,
    val supportedAppLanguages: List<AppLanguage>,
) {
    companion object {
        fun fromPayload(payload: Any?): LanguagePreferences? {
            val fields = payload as? Map<*, *> ?: return null
            val selection = AppLanguage.fromWire(fields["appLanguage"]) ?: return null
            val locale = AppLanguage.fromWire(fields["appLocale"]) ?: return null
            val languages = fields["supportedAppLanguages"] as? List<*> ?: return null
            val supported = languages.map { AppLanguage.fromWire(it) ?: return null }.distinct()
            if (AppLanguage.SYSTEM in supported || locale !in supported) return null
            if (selection != AppLanguage.SYSTEM && selection != locale) return null
            return LanguagePreferences(selection, locale.wireValue, supported)
        }
    }
}

internal enum class LanguagePreferencesFailure { LOAD, SAVE }

internal data class LanguagePreferencesState(
    val confirmed: LanguagePreferences? = null,
    val isSaving: Boolean = false,
    val failure: LanguagePreferencesFailure? = null,
)

internal class LanguagePreferencesController(
    private val read: suspend () -> Any?,
    private val write: suspend (AppLanguage) -> Any?,
) {
    private val mutableState = MutableStateFlow(LanguagePreferencesState())
    val state = mutableState.asStateFlow()
    private var isReading = false
    private var revision = 0L

    suspend fun refresh() {
        if (isReading || state.value.isSaving) return
        isReading = true
        val startedAt = revision
        mutableState.value = state.value.copy(failure = null)
        try {
            val confirmed = requireNotNull(LanguagePreferences.fromPayload(read()))
            if (startedAt == revision) mutableState.value = state.value.copy(confirmed = confirmed)
        } catch (error: CancellationException) {
            throw error
        } catch (_: Exception) {
            if (startedAt == revision) mutableState.value = state.value.copy(failure = LanguagePreferencesFailure.LOAD)
        } finally {
            isReading = false
        }
    }

    suspend fun select(choice: AppLanguage) {
        val current = state.value
        val confirmed = current.confirmed ?: return
        if (current.isSaving || confirmed.appLanguage == choice) return
        if (choice != AppLanguage.SYSTEM && choice !in confirmed.supportedAppLanguages) return
        val startedAt = ++revision
        mutableState.value = current.copy(isSaving = true, failure = null)
        try {
            val saved = requireNotNull(LanguagePreferences.fromPayload(write(choice)))
            require(saved.appLanguage == choice)
            if (!confirmedByNotification(choice, startedAt)) mutableState.value = state.value.copy(confirmed = saved)
        } catch (error: CancellationException) {
            throw error
        } catch (_: Exception) {
            if (!confirmedByNotification(choice, startedAt)) {
                mutableState.value = state.value.copy(failure = LanguagePreferencesFailure.SAVE)
            }
        } finally {
            mutableState.value = state.value.copy(isSaving = false)
        }
    }

    fun acceptNotification(payload: Any?): Boolean {
        val confirmed = LanguagePreferences.fromPayload(payload) ?: return false
        revision++
        val current = state.value
        val failure = current.failure.takeUnless {
            it == LanguagePreferencesFailure.LOAD || current.confirmed?.appLanguage != confirmed.appLanguage
        }
        mutableState.value = current.copy(confirmed = confirmed, failure = failure)
        return true
    }

    private fun confirmedByNotification(choice: AppLanguage, startedAt: Long): Boolean =
        revision != startedAt && state.value.confirmed?.appLanguage == choice
}
