package com.yoahnl.avelune.host

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant

class InstalledGameTest {
    @Test
    fun detailPayloadPreservesTheSameInformationAsIos() {
        val game = InstalledGame.fromPayload(
            mapOf(
                "gameId" to "one",
                "title" to "One",
                "publisher" to "Avelune",
                "defaultLocale" to "en",
                "supportedLocales" to listOf("fr", "en"),
                "accentColor" to "#abcdef",
                "lastPlayedAt" to "2026-10-03T18:20:30.123456Z",
                "heroPath" to "/hero.png",
                "coverPath" to "/cover.png",
            ),
        )

        assertEquals("Avelune", game.publisher)
        assertEquals(listOf("fr", "en"), game.supportedLocales)
        assertEquals("#abcdef", game.accentColor)
        assertEquals(Instant.parse("2026-10-03T18:20:30.123456Z"), game.lastPlayedAt)
        assertEquals(listOf("/hero.png", "/cover.png"), game.heroArtworkPaths)
        assertEquals(listOf("/cover.png", "/hero.png"), game.artworkPaths)
    }

    @Test
    fun featuredOrderMovesOnlyTheMostRecentGame() {
        val older = InstalledGame("older", "Older", lastPlayedAt = Instant.parse("2026-10-01T12:00:00Z"))
        val unplayed = InstalledGame("new", "New")
        val recent = InstalledGame("recent", "Recent", lastPlayedAt = Instant.parse("2026-10-03T12:00:00Z"))

        assertEquals(listOf(recent, older, unplayed), InstalledGame.featuredOrder(listOf(older, unplayed, recent)))
        val anotherUnplayed = InstalledGame("another", "Another")
        assertEquals(listOf(unplayed, anotherUnplayed), InstalledGame.featuredOrder(listOf(unplayed, anotherUnplayed)))
        assertEquals(listOf(unplayed), InstalledGame.featuredOrder(listOf(unplayed)))
    }

    @Test
    fun invalidOptionalDateDoesNotPreventOpeningTheLibrary() {
        val game = InstalledGame.fromPayload(
            mapOf("gameId" to "one", "title" to "One", "defaultLocale" to "en", "lastPlayedAt" to "not a date"),
        )

        assertEquals(null, game.lastPlayedAt)
        assertEquals(listOf("en"), game.supportedLocales)
    }

    @Test
    fun libraryPayloadPreservesMetadataAndDeduplicatesArtwork() {
        val game = InstalledGame.fromPayload(
            mapOf(
                "gameId" to "clairbois",
                "title" to "Clairbois",
                "author" to "Yoahn",
                "version" to "1.2",
                "coverPath" to "/library/cover.png",
                "heroPath" to "/library/cover.png",
                "iconPath" to "/library/icon.png",
                "canContinue" to true,
                "playTimeSeconds" to 120L,
            ),
        )

        assertEquals("clairbois", game.id)
        assertEquals("Yoahn", game.author)
        assertEquals("1.2", game.version)
        assertTrue(game.canContinue)
        assertEquals(120L, game.playTimeSeconds)
        assertEquals(listOf("/library/cover.png", "/library/icon.png"), game.artworkPaths)
    }

    @Test(expected = IllegalArgumentException::class)
    fun invalidLibraryRowFailsInsteadOfSilentlyDroppingTheGame() {
        InstalledGame.fromPayload(mapOf("gameId" to "", "title" to "Clairbois"))
    }

    @Test
    fun optionalLibraryFieldsHaveSafeDefaults() {
        val game = InstalledGame.fromPayload(mapOf("gameId" to "one", "title" to "One"))

        assertFalse(game.canContinue)
        assertEquals(0L, game.playTimeSeconds)
        assertTrue(game.artworkPaths.isEmpty())
    }

    @Test
    fun acceptedPackageExtensionsAreCaseInsensitive() {
        assertEquals("avelunegame", PackageName.extension("Jeu.AVELUNEGAME"))
        assertEquals("pokemapgame", PackageName.extension("demo.pokemapgame"))
    }

    @Test(expected = IllegalArgumentException::class)
    fun unrelatedFilesCannotBeImportedAsGames() {
        PackageName.extension("save.zip")
    }
}
