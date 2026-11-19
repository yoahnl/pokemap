package com.yoahnl.avelune.player.runtime

import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class LanguagePreferencesTest {
    @Test
    fun decodesEffectiveLocaleSeparatelyFromPhoneMode() {
        val confirmed = LanguagePreferences.fromPayload(payload("system", "fr"))

        assertEquals(
            LanguagePreferences(AppLanguage.SYSTEM, "fr", listOf(AppLanguage.FRENCH, AppLanguage.ENGLISH)),
            confirmed,
        )
        assertEquals(AppLanguage.FRENCH, LanguagePreferences.fromPayload(payload("fr", "fr"))?.appLanguage)
    }

    @Test
    fun rejectsMalformedOrInconsistentPayloads() {
        assertNull(LanguagePreferences.fromPayload(listOf("system", "fr")))
        assertNull(LanguagePreferences.fromPayload(payload("de", "en")))
        assertNull(LanguagePreferences.fromPayload(payload("system", "de")))
        assertNull(LanguagePreferences.fromPayload(payload("fr", "en")))
        assertNull(LanguagePreferences.fromPayload(payload("system", "fr") - "supportedAppLanguages"))
        assertNull(LanguagePreferences.fromPayload(payload("system", "fr") + ("supportedAppLanguages" to listOf("en"))))
        assertNull(LanguagePreferences.fromPayload(payload("system", "fr") + ("supportedAppLanguages" to listOf("fr", 1))))
    }

    @Test
    fun switchesFromFrenchToEnglishAndBackToPhoneModeAfterConfirmation() = runBlocking {
        val written = mutableListOf<AppLanguage>()
        val controller = LanguagePreferencesController(
            read = { payload("fr", "fr") },
            write = { choice ->
                written += choice
                when (choice) {
                    AppLanguage.SYSTEM, AppLanguage.FRENCH -> payload(choice.wireValue, "fr")
                    AppLanguage.ENGLISH -> payload(choice.wireValue, "en")
                }
            },
        )

        controller.refresh()
        controller.select(AppLanguage.ENGLISH)
        assertEquals(AppLanguage.ENGLISH, controller.state.value.confirmed?.appLanguage)
        assertEquals("en", controller.state.value.confirmed?.appLocale)

        controller.select(AppLanguage.SYSTEM)
        assertEquals(AppLanguage.SYSTEM, controller.state.value.confirmed?.appLanguage)
        assertEquals("fr", controller.state.value.confirmed?.appLocale)
        assertEquals(listOf(AppLanguage.ENGLISH, AppLanguage.SYSTEM), written)

        controller.select(AppLanguage.FRENCH)
        assertEquals(AppLanguage.FRENCH, controller.state.value.confirmed?.appLanguage)
        assertEquals("fr", controller.state.value.confirmed?.appLocale)
    }

    @Test
    fun keepsConfirmedChoiceAndIgnoresOtherSelectionsUntilWriteFinishes() = runBlocking {
        val receipt = CompletableDeferred<Any?>()
        val written = mutableListOf<AppLanguage>()
        val controller = LanguagePreferencesController(
            read = { payload("fr", "fr") },
            write = { choice ->
                written += choice
                receipt.await()
            },
        )
        controller.refresh()

        val selecting = launch(start = CoroutineStart.UNDISPATCHED) { controller.select(AppLanguage.ENGLISH) }
        controller.select(AppLanguage.ENGLISH)
        controller.select(AppLanguage.SYSTEM)

        assertTrue(controller.state.value.isSaving)
        assertEquals("fr", controller.state.value.confirmed?.appLocale)
        assertEquals(listOf(AppLanguage.ENGLISH), written)

        receipt.complete(payload("en", "en"))
        selecting.join()

        assertFalse(controller.state.value.isSaving)
        assertEquals("en", controller.state.value.confirmed?.appLocale)
    }

    @Test
    fun failedWriteKeepsConfirmedPreferenceAndAllowsRetry() = runBlocking {
        var fails = true
        val controller = LanguagePreferencesController(
            read = { payload("system", "fr") },
            write = {
                check(!fails)
                payload("en", "en")
            },
        )
        controller.refresh()
        controller.select(AppLanguage.ENGLISH)

        assertEquals(AppLanguage.SYSTEM, controller.state.value.confirmed?.appLanguage)
        assertEquals(LanguagePreferencesFailure.SAVE, controller.state.value.failure)
        assertFalse(controller.state.value.isSaving)

        fails = false
        controller.select(AppLanguage.ENGLISH)

        assertEquals(AppLanguage.ENGLISH, controller.state.value.confirmed?.appLanguage)
        assertNull(controller.state.value.failure)
    }

    @Test
    fun lateConfirmationClearsSaveFailureWhenTheStoredChoiceChanges() = runBlocking {
        val controller = LanguagePreferencesController(read = { payload("system", "fr") }, write = { error("Timed out") })
        controller.refresh()
        controller.select(AppLanguage.ENGLISH)

        controller.acceptNotification(payload("system", "en"))
        assertEquals(LanguagePreferencesFailure.SAVE, controller.state.value.failure)

        controller.acceptNotification(payload("en", "en"))
        assertEquals(AppLanguage.ENGLISH, controller.state.value.confirmed?.appLanguage)
        assertNull(controller.state.value.failure)
    }

    @Test
    fun ignoresAReadThatReturnsAfterANewerNotification() = runBlocking {
        val receipt = CompletableDeferred<Any?>()
        val controller = LanguagePreferencesController(read = { receipt.await() }, write = { error("Unused") })

        val refreshing = launch(start = CoroutineStart.UNDISPATCHED) { controller.refresh() }
        assertTrue(controller.acceptNotification(payload("system", "en")))
        receipt.complete(payload("system", "fr"))
        refreshing.join()

        assertFalse(controller.acceptNotification(payload("system", "de")))
        assertEquals("en", controller.state.value.confirmed?.appLocale)
    }

    @Test
    fun ignoresAReadThatReturnsAfterAConfirmedWrite() = runBlocking {
        val receipt = CompletableDeferred<Any?>()
        val controller = LanguagePreferencesController(read = { receipt.await() }, write = { payload("en", "en") })
        controller.acceptNotification(payload("fr", "fr"))

        val refreshing = launch(start = CoroutineStart.UNDISPATCHED) { controller.refresh() }
        controller.select(AppLanguage.ENGLISH)
        receipt.complete(payload("fr", "fr"))
        refreshing.join()

        assertEquals(AppLanguage.ENGLISH, controller.state.value.confirmed?.appLanguage)
        assertEquals("en", controller.state.value.confirmed?.appLocale)
    }

    @Test
    fun failedInitialReadCanBeRetried() = runBlocking {
        var response: Any? = null
        val controller = LanguagePreferencesController(read = { response }, write = { error("Unused") })

        controller.refresh()
        assertNull(controller.state.value.confirmed)
        assertEquals(LanguagePreferencesFailure.LOAD, controller.state.value.failure)

        response = payload("system", "en")
        controller.refresh()
        assertEquals(AppLanguage.SYSTEM, controller.state.value.confirmed?.appLanguage)
        assertNull(controller.state.value.failure)
    }

    @Test
    fun keepsTheEffectivePhoneLocaleFromANewerNotificationWhenAWriteReturns() = runBlocking {
        val receipt = CompletableDeferred<Any?>()
        val controller = LanguagePreferencesController(read = { payload("en", "en") }, write = { receipt.await() })
        controller.refresh()

        val selecting = launch(start = CoroutineStart.UNDISPATCHED) { controller.select(AppLanguage.SYSTEM) }
        assertTrue(controller.acceptNotification(payload("system", "en")))
        receipt.complete(payload("system", "fr"))
        selecting.join()

        assertEquals(AppLanguage.SYSTEM, controller.state.value.confirmed?.appLanguage)
        assertEquals("en", controller.state.value.confirmed?.appLocale)
        assertFalse(controller.state.value.isSaving)
    }

    private fun payload(appLanguage: String, appLocale: String): Map<String, Any> = mapOf(
        "appLanguage" to appLanguage,
        "appLocale" to appLocale,
        "supportedAppLanguages" to listOf("fr", "en"),
    )
}
