# PERF-RM-01 — Plan d'implémentation assets runtime

**Scope :** single-flight des tilesets par `(absolutePath, transparentColor)`, ownership des codecs et chargement asynchrone des icônes de sac battle. Aucun changement de format projet, de sémantique authoring ou de rendu attendu.

## Audit initial

- `PlayableMapGame._loadTilesetImagesCached` ne mémorise que les résultats terminés : deux callers concurrents peuvent charger la même clé.
- `tile_image_loader.dart` crée des codecs sans `dispose()`.
- `_BattleItemIcon.build` appelle `existsSync` puis `readAsBytesSync`.
- `BattleFxBundleCache` fournit le pattern local de future en vol avec éviction après erreur.

## Étapes test-first

- [ ] Ajouter `tile_image_loader_singleflight_test.dart` : N callers identiques, couleurs distinctes, chemins distincts, erreur puis retry, fermeture/reload.
- [ ] Exécuter le test et conserver l'échec RED dû à l'API/cache absent.
- [ ] Introduire un cache runtime possédé et borné au cycle de vie de `PlayableMapGame`, clé valeur `(path, transparentColor)` ; stocker la future avant le premier `await`, évincer uniquement la future identique en échec, conserver le résultat réussi.
- [ ] Faire charger chaque clé manquante indépendamment pour que des ids différents partageant le même chemin convergent vers la même future.
- [ ] Ajouter `try/finally { codec.dispose(); }` sur chaque codec créé, sans disposer l'image remise au caller.
- [ ] Ajouter `battle_mobile_command_overlay_asset_loading_test.dart` : le premier build n'exécute pas de lecture, succès async, fichier absent/erreur, changement de chemin recharge.
- [ ] Exécuter le test et conserver l'échec RED sur le loader asynchrone absent.
- [ ] Convertir l'icône privée en widget stateful possédant une seule future par chemin ; effectuer `File.exists/readAsBytes` uniquement hors `build`, exprimer loading/error par le fallback existant.
- [ ] Relancer tests ciblés, suite `map_runtime`, analyseur, smoke host.

## Non-objectifs et risques

- Pas de cache global, LRU cross-project, watcher de fichier ni nouvelle API authoring.
- Les `ui.Image` restent détenues par le runtime ; seule la ressource codec temporaire est fermée.
- Le cache doit distinguer strictement la couleur transparente et ne jamais retenir une erreur.

## Preuves attendues

- Un seul appel loader pour N appels concurrents identiques ; retry après erreur.
- Recherche source : aucun `existsSync/readAsBytesSync` dans l'overlay.
- Tests visuels/battle existants inchangés.

