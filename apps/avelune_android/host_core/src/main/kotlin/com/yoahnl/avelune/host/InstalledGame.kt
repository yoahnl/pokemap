package com.yoahnl.avelune.host

import java.time.Instant

data class InstalledGame(
    val id: String,
    val title: String,
    val author: String = "",
    val description: String? = null,
    val version: String? = null,
    val iconPath: String? = null,
    val coverPath: String? = null,
    val heroPath: String? = null,
    val canContinue: Boolean = false,
    val playTimeSeconds: Long = 0,
    val publisher: String? = null,
    val supportedLocales: List<String> = listOf("fr"),
    val accentColor: String? = null,
    val lastPlayedAt: Instant? = null,
) {
    val artworkPaths: List<String>
        get() = listOfNotNull(coverPath, heroPath, iconPath).filter(String::isNotBlank).distinct()

    val heroArtworkPaths: List<String>
        get() = listOfNotNull(heroPath, coverPath, iconPath).filter(String::isNotBlank).distinct()

    companion object {
        fun featuredOrder(games: List<InstalledGame>): List<InstalledGame> {
            val recent = games.filter { it.lastPlayedAt != null }.maxByOrNull { it.lastPlayedAt!! } ?: return games
            return listOf(recent) + games.filter { it.id != recent.id }
        }

        fun fromPayload(payload: Map<*, *>): InstalledGame {
            val id = payload["gameId"] as? String
            val title = payload["title"] as? String
            require(!id.isNullOrBlank() && !title.isNullOrBlank()) {
                "Réponse inattendue de la bibliothèque Avelune."
            }
            return InstalledGame(
                id = id,
                title = title,
                author = payload["author"] as? String ?: "",
                description = payload["description"] as? String,
                version = payload["version"] as? String,
                iconPath = payload["iconPath"] as? String,
                coverPath = payload["coverPath"] as? String,
                heroPath = payload["heroPath"] as? String,
                canContinue = payload["canContinue"] as? Boolean ?: false,
                playTimeSeconds = (payload["playTimeSeconds"] as? Number)?.toLong() ?: 0,
                publisher = payload["publisher"] as? String,
                supportedLocales = (payload["supportedLocales"] as? List<*>)?.filterIsInstance<String>()
                    ?: listOf(payload["defaultLocale"] as? String ?: "fr"),
                accentColor = payload["accentColor"] as? String,
                lastPlayedAt = (payload["lastPlayedAt"] as? String)?.let { runCatching { Instant.parse(it) }.getOrNull() },
            )
        }

        fun listFromPayload(payload: Any?): List<InstalledGame> {
            require(payload is List<*>) { "Réponse inattendue de la bibliothèque Avelune." }
            return payload.map {
                require(it is Map<*, *>) { "Réponse inattendue de la bibliothèque Avelune." }
                fromPayload(it)
            }
        }
    }
}

object PackageName {
    fun extension(name: String): String {
        val extension = name.substringAfterLast('.', "").lowercase()
        require(extension == "avelunegame" || extension == "pokemapgame") {
            "Choisis un jeu au format .avelunegame ou .pokemapgame."
        }
        return extension
    }
}
