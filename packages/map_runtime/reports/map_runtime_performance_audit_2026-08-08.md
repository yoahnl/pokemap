# Audit de performance — `map_runtime` (2026-08-08)

Audit statique complet du package (201 fichiers, ~372k lignes), mené en parallèle sur 5 sous-systèmes : boucle de rendu, battle/catalogues, couche application, chargement/persistance/session, border/shadow. Les constats sont référencés `fichier:ligne` et classés P0 → P3.

## Résumé exécutif

Le package a de **bonnes fondations** (culling viewport des tuiles, index spatiaux, cache tileset single-flight, `ui.Picture` pour les patchs d'occlusion, garde de changement sur les ombres d'acteurs) — mais plusieurs consommateurs **ignorent ces mécanismes** et recalculent des données statiques à 60 Hz. Quatre problèmes dominent :

1. **Rendu** : la résolution Smart Tile, les instructions de bordure et la fusion des collections d'ombres sont **reconstruites à chaque frame** alors que la carte est immuable (viewer read-only) — plusieurs milliers d'allocations/frame.
2. **Battle** : `TextPainter` reconstruit + `layout()` ~20-30×/frame dans les HUD, gradients/shaders recréés chaque frame, backdrop statique re-rasterisé, et **aucune `ui.Image` décodée n'est jamais `dispose()`** (cache non borné + cache FX recréé par combat → croissance mémoire native sur la session).
3. **Compilation/binaire** : `battle_sdk_rmxp_animation_catalog.dart` (283k lignes, 36 903 constructeurs const) coûte ~**2,5 Mo de snapshot AOT** et domine le temps de build/analyse ; tout est importé eagerly même sans combat.
4. **Sauvegarde** : chaque checkpoint fait **~8-10 traversées/sérialisations complètes de l'état + 3-4 SHA-256, tout sur l'isolate UI**. Le benchmark `game_save_codec_offload_profile_test.dart` profile `GameSaveCodecExecutor`… qui **n'est pas sur le chemin de prod** (`captureCheckpoint` → `HubSessionCheckpointCommitter` → `HubSaveRepositoryImpl`).

Transversal : **312 `debugPrint` non gardés** (non strippés en release, dont plusieurs dans `update()` et sur le chemin de sauvegarde, avec interpolation de collections).

---

## A. Boucle de rendu overworld (par frame)

### A1 (P0) — Smart Tile : résolution complète re-exécutée chaque frame
`map_layers_component.dart:509` → `smart_tile_layer_visual_resolver.dart:219-470` (map_core). Chaque `render()` :
- rescanne linéairement `catalog.presets` ;
- **reconstruit 3 `Map` depuis tout le catalogue** (atlases, animations, patterns) ;
- alloue contexte + règles + visuels par cellule visible ;
- construit et hashe **une chaîne par cellule de pattern** (`smart_tile_layer_visual_resolver.dart:442`).

~3-10k allocations/frame pour un viewport 20×15, × 2 composants (bg/fg) × cartes résidentes.
**Fix** : préparer une fois (étendre `SmartTilePatternOwnerIndex` déjà présent à `map_layers_component.dart:131`), mémoïser la résolution par cellule, ne re-choisir que la frame d'animation via `elapsedMs`.

### A2 (P0) — Bordure : instructions reconstruites chaque frame, sans index spatial
`map_layers_component.dart:438-443` → `border_runtime_draw_instruction.dart:86-143`. Deux passes sur toutes les features × cellules × placements, 1 `BorderRuntimeGroundInstruction` + 1 `BorderPixelRect` par cellule, + `List.unmodifiable` — par frame, par carte résidente (~240k objets/s pour 2 000 cellules). Puis `border_runtime_renderer.dart:17-68` : scan linéaire sans bucketing, `_animationFrame` (`:73-96`) re-somme **toutes** les durées de frames par instruction, 1-2 `Rect` alloués par instruction (`:163`, `:182`, `:56`).
**Fix** : construire une fois au mount (ou au prepare, partagé entre instances), pré-scaler les rects, précalculer la durée totale par snapshot, résoudre la frame active une fois par snapshot et par frame.

### A3 (P0) — `RuntimeTilesetImage.drawImageRect` : allocations sur *chaque* draw de tuile
`runtime_tileset_image.dart:150-172`. Le call le plus interne du renderer (tuiles, smart tiles, objets, placed elements, acteurs, bordures) alloue une liste de slices + 3 `Rect` par tuile, alors que le cas mono-chunk (< 4096 px) est l'écrasante majorité.
**Fix** : fast path mono-chunk → `canvas.drawImageRect` direct, zéro allocation. Gain transversal immédiat, changement quasi-une-ligne.

### A4 (P0) — Ombres : fusion + re-partition par frame, sans culling
`map_layers_component.dart:484-499` → `playable_map_game.dart:4020-4044` → `runtime_shadow_collection_merge.dart:4`. ~5 copies de liste + 3 traversées par frame, par carte résidente (`shadow_runtime_instruction_collection.dart:48-68`). Et `_paintShadows` dessine **toutes** les ombres statiques de la carte : l'API de culling (`shadowRuntimeInstructionIntersectsBounds`, `collectShadowRuntimeInstructions`) existe mais est **du code mort** (aucun call site).
**Fix** : cacher la fusion par `mapId`, invalider sur les événements de refresh existants ; passer `_visibleLocalRect` ; partitionner en une seule passe.

### A5 (P0) — Ombres projetées : bandes, paths, paints et instructions reconstruits par bâtiment par frame
`shadow_runtime_renderer.dart:50-57` : par bâtiment et par frame, 7 bandes → 7 `Path` + 7 `Paint` + 7 instructions complètes (avec re-validation `RegExp` + aire du polygone, `shadow_runtime_render_instruction.dart:52-61`) + **`int.parse` du hex couleur par ombre par frame** (`:85`). ~1 500 allocations/frame pour 20 bâtiments.
**Fix** : cuire les paires `(Path, Color)` à la construction de la collection (`runtime_projected_building_shadow_collection.dart:77`) ; résoudre la couleur une fois dans le constructeur d'instruction ; le render se réduit à 7 `drawPath` cachés.

### A6 (P1) — Classification foreground des calques : ~58 allocations de chaînes par appel, par frame
`map_layers_component.dart:1140-1188`, appelé de `:741` et `:1007`. Résultat constant pour la vie du composant.
**Fix** : `Map<String,bool>` calculée au constructeur ; variantes de markers en `const`.

### A7 (P1) — `_visibleTileCellRange` rescanne toute la palette par calque par frame
`map_layers_component.dart:227-278`. Les marges ne dépendent que de données immuables.
**Fix** : cacher les marges par layer id.

### A8 (P1) — Index spatial des placed elements : requêté une fois *par calque*, avec Set+sort+copies par requête
`map_layers_component.dart:1027`, `:1697-1715`. Récupère tous les éléments visibles puis jette ceux des autres calques (`instance.layerId.trim() != layerId`).
**Fix** : un index par layer id ; `query` sans allocation (buffer scratch + visit-stamp) ; clé de bucket `int` plate au lieu d'un record `(x,y)`.

### A9 (P1) — Tri complet des enfants du monde à chaque frame de mouvement
`playable_map_game.dart:3999-4004` : les setters `priority` déclenchent `rebalanceAll()` de Flame → re-tri O(n log n) de **tous** les enfants (dont des centaines de patchs d'occlusion statiques). `footPoint` (`player_component.dart:110`) alloue un `Vector2` par accès.
**Fix** : n'assigner `priority` que si la valeur arrondie change ; isoler les acteurs dans un parent dédié depth-sorted.

### A10 (P2) — Divers par frame
- `PlayerComponent.syncState` : re-layout complet (3 `Vector2`) à chaque frame idle (`player_component.dart:231-247`) → early-return si état identique.
- `OverworldActorComponent.render` : re-résolution d'animation + re-somme des durées + `Paint` par acteur par frame (`overworld_actor_component.dart:236-380`) → mémoïser dans `setMotion`.
- Patchs d'occlusion : `toAbsoluteRect().inflate(1)` par patch par frame (`placed_element_occlusion_patch_component.dart:136-141`) → cacher le rect absolu (statique).
- `.trim()` + `QuarterTurnGridTransform` + `Set<int>` de collisions reconstruits par instance par frame (`map_layers_component.dart:1029-1099`).
- Objets : `Paint()` **dans** la boucle par tuile (`map_layers_component.dart:918`) — alors que `:1022` fait déjà la bonne chose.
- Dialogue : `state.text.runes.length` (O(n)) réévalué par frame (`dialogue_overlay_component.dart:75-77, 114`).
- `scripted_entity_movement_controller.dart:353-354, 505` : `keys.toList()..sort()` par frame même à vide → guard `isEmpty` + liste triée maintenue.
- `placed_behavior_runtime_cooldown.dart:115-123` : `prune` par frame → `removeWhere` ou suppression (le chemin lazy `canTrigger:74-77` suffit).

---

## B. Battle & catalogues

### B1 (P0, build/binaire) — `battle_sdk_rmxp_animation_catalog.dart` : 8,4 Mo / 283k lignes de graphe const
874 animations, 36 903 constructeurs const (22 076 cells, 11 702 frames, 2 250 timings). Tout `static const`, importé non-deferred jusqu'à `playable_map_game.dart` → dans le snapshot même sans combat. Coûts : temps de compile/analyse dominant du repo, ~**2,4-2,9 Mo** de `libapp.so`, graphe désérialisé en heap en debug/tests (~30 fichiers de tests battle le paient).
**Fix (ordonné)** :
1. `byAnimationId` → asset binaire packé (`~500 Ko` vs ~2,5 Mo ; header index `animationId → offset`, cell = 15 octets), chargé lazily et décodé **seulement** pour les `requiredFxIds` du plan (`battle_animation_plan.dart:106`). Généré par le même `tool/import_pokemon_sdk_rmxp_animations.py`.
2. Garder les 3 petites maps int/string en const Dart (~60 Ko) pour que le resolver reste synchrone.
3. Alternative sans changement d'API : structure-of-arrays (`Int16List`/`Uint8List` + vue accesseur) → ~5× moins de mémoire, ~200k pointeurs GC en moins.
4. Ne **pas** splitter en 875 part files (inutile).
⚠️ `test/battle_sdk_rmxp_animation_catalog_test.dart:8` asserte `hasLength(874)` — porter l'assertion sur l'asset décodé.

### B2 (P0, frame time) — `TextPainter` reconstruit + `layout()` ~20-30×/frame
`battle_scene_hud_component.dart:409-425` (×6-7 par HUD, ×2 HUDs) et `battle_command_panel_component.dart:2805-2836` (16-20 de plus menu ouvert). ~1 800 shaping HarfBuzz/s pour du texte qui change quelques fois par seconde ; `ui.Paragraph` jamais `dispose()`.
**Fix** : cache `(text, style, maxWidth) → TextPainter` sur le composant, invalidé dans `sync()` ; dispose à l'invalidation.

### B3 (P0, frame time) — Layout HUD complet recalculé dans `update()` à chaque frame de tween HP
`battle_scene_hud_component.dart:184, 189` → `_buildLayout()` → 4 `TextPainter.layout()` de plus (`battle_scene_hud_layout.dart:235`). Le drain de HP est l'animation la plus fréquente d'un combat : ~20 shaping/frame ×2 HUDs en pointe.
**Fix** : séparer géométrie (recalcul sur `sync()`/resize) et texte de valeur HP (recalcul quand l'entier affiché change).

### B4 (P0, mémoire) — `ui.Image` jamais disposées ; cache FX recréé par combat
Un seul `dispose()` dans tout le sous-système (`battle_fx_bundle_cache.dart:91`, le codec). `BattleVisualAssetCache` (`battle_visual_asset_cache.dart:15-18`) : map non bornée, vécue toute la session (`playable_map_game.dart:521-522`). `BattleFxBundleCache` construit **par combat** (`battle_overlay_component.dart:454`) : re-décodage des mêmes PNG à chaque combat + images orphelines du combat précédent (14 Mo d'assets sur disque, RGBA décodé = plusieurs fois plus).
**Fix** : hisser le cache FX au scope jeu ; `dispose()` sur les deux caches (appelé de `BattleOverlayComponent.onRemove()` pour le battle-scoped) ; borne LRU (~64 images) sur le cache sprites.

### B5 (P1) — Shaders de gradient recréés chaque frame (8 sites) + backdrop statique re-rasterisé
`battle_scene_combatant_component.dart:445-457`, `battle_command_panel_component.dart:876-2958` (6 sites), `battle_scene_backdrop_component.dart:81-289` (6 gradients + 2 `Path` + ~13 draws/frame pour un contenu qui ne dépend que de `(size, palette, image)`).
**Fix** : cacher les `Paint` à `sync()`/resize ; enregistrer le backdrop dans un `ui.Picture` (gain le moins cher du fichier).

### B6 (P1) — Churn `TextPaint`/`Vector2` par frame de caméra/animation
`battle_scene_combatant_component.dart:925-955` : nouveau `TextPaint` assigné à `textRenderer` chaque frame (invalide le cache texte de Flame). `battle_camera_rig.dart:88-112` : 3 `Vector2` + `math.pow` boxé/frame, getter `offset` qui clone ; +5 `Vector2`/frame en aval (`battle_overlay_component.dart:2612-2628`).
**Fix** : garde d'égalité sur l'opacité ; mutation in place (`setFrom`/`lerp`), `x*x` au lieu de `pow`.

### B7 (P2) — Divers battle
- `battle_fx_layer_component.dart:85-127` : 6 `whereType().toList()` + 2 `size.clone()` par frame → une traversée, buffer réutilisable.
- `battle_rmxp_animation_component.dart:158-190` : ~80 allocations/frame/composant (cells, `Rect`, `ColorFilter` 20 éléments, `Paint` par cell) → mémoïser `colorFilterForHue` (360 valeurs), `Paint` réutilisé, recalcul des cells seulement au changement de frame.
- `battle_scene_hud_component.dart:199-207` : `drawShadow` avec `Path` neuf par frame → path caché ou ombre dans le Picture du backdrop.
- Chaînes par frame dans `render()` (`battle_command_panel_component.dart:2432, 2153, 2163`) → précomputer dans les snapshots existants.
- `battle_visual_asset_cache.dart:117-160` : readback RGBA + scan O(W·H) sur l'isolate UI à l'entrée en combat → `Isolate.run` ou métadonnées précalculées.
- `battle_move_visual_recipe_library.dart` (12,8k lignes, 276 cases) : pas un problème mémoire (stateless) ; ~300-600 Ko de code AOT. Basse priorité — collapsible en ~20 templates paramétrés si on y touche.
- Non-problèmes : `BattleFxCatalog`/`BattleMoveVisualCatalog` (const, petits) — à laisser tels quels.

---

## C. Couche application (logique)

### C1 (P0) — Callback de passabilité du pathfinding : O(entités) + 4 allocations **par nœud A\***
`scripted_npc_anchor_passability.dart:50-68`, branché comme `isPassable` (`playable_map_game.dart:12742, 12788`). Par nœud expansé : scan linéaire de `world.map.entities`, `copyWith` freezed, `toList`, `toSet` d'un générateur `sync*` re-piloté. ~900 × tout ça pour une région 30×30, à chaque re-path de patrouille.
**Fix** : hisser les invariants hors du callback — entité résolue une fois, `dynamicBlocked` précalculé en `Set<GridPos>` par appel à `findPath`, offsets de collision précalculés et translatés par nœud.

### C2 (P0) — Présence PNJ : JSON de scénarios re-parsé par entité, projection recalculée par entité
- `npc_runtime_presence.dart:36` : `buildGlobalStoryChapterStepIndex` → `jsonDecode` du blob authoring de **chaque** scénario globalStory, appelé par entité, ×4 par refresh (monde reconstruit 2×, 2 index par monde), et `_refreshWorldNpcPresence` a 15 call sites (flags, dialogues, combats, warps…). Idem `playable_map_game.dart:2729` par résolution de dialogue.
- `runtime_world_rule_projection_hook.dart:11-44` : projection complète + 9 copies `unmodifiable` **par PNJ** (`playable_map_game.dart:2746` dans la closure par entité).
- `map_entity_runtime_predicate_evaluator.dart:30-34` : getters `.toSet()` → Set complet réalloué par évaluation de prédicat.
- `step_studio_world_presence_runtime.dart:164-183` : Set normalisé reconstruit par PNJ + scan linéaire de toutes les règles + `trim()` redondants (déjà trimmées à la construction `:116-129`).

**Fix** : cacher `chapterIndex` à côté de `_cachedStepStudioWorldRules` (`playable_map_game.dart:1406-1417`) ; mémoïser la projection par `(mapId, gameState, manifest)` ; `late final` sur les getters ; règles indexées `Map<'mapId|entityId', List<Rule>>`.

### C3 (P1) — Decode JSON cartes/manifest/validation sur l'isolate UI à chaque warp
`load_runtime_map_bundle.dart:111, 127-134, 175-190` : seul le read est async ; `jsonDecode` + `fromJson` + validateurs + composition visuelle sont synchrones → stall de plusieurs centaines de ms par warp sur une grosse carte. Un seul `Isolate.run` dans tout le package (`game_save_codec_executor.dart:88`).
**Fix** : `Isolate.run` autour de decode+fromJson (objets freezed → sendables).

### C4 (P1) — Dialogues relus du disque et re-parsés à chaque interaction PNJ, puis clonage profond intégral
`load_dialogue_content.dart:15-32` (aucun cache — le caller loggue déjà `elapsedMs`, `playable_map_game.dart:10136`) + `dialogue_runtime_models.dart:70-102` : `mapText` clone **tous** les nœuds/steps/choix et passe la regex `{{var}}` sur chaque ligne, y compris les nœuds jamais visités.
**Fix** : cache LRU `(path, mtime) → List<YarnNode>` ; interpolation lazy à l'affichage dans `_resolveStep`.

### C5 (P1) — Caches de loaders neutralisés : instances reconstruites à chaque appel
Chaque loader a un cache correct (dédup in-flight incluse) mais **par instance**, et les consommateurs construisent la leur :
`runtime_player_pokemon_progression_hydrator.dart:111`, `player_service_runtime_controller.dart:1831`, `runtime_battle_reward_resolver.dart:91-95`, `runtime_pokemon_learnset_loader.dart:25`, `runtime_battle_setup_mapper.dart:43`, `runtime_psdk_battle_setup_mapper.dart:19`, `runtime_battle_combatant_seed_builder.dart:404-405`, `runtime_pokemon_evolution_loader.dart:18`, `runtime_move_machine_loader.dart:31`. Le catalogue de moves (gros JSON) est parsé jusqu'à 3× **par début de combat**.
**Fix** : holder `RuntimePokemonDataLoaders` longue durée possédé par `PlayableMapGame` (ou `_cache` en `static`, 2 lignes, les clés incluent déjà le project root), injecté via les paramètres `?? Default()` existants.

### C6 (P1) — Menu pause : catalogue d'espèces relu séquentiellement à chaque ouverture ET après chaque usage d'objet
`runtime_player_pause_data_builder.dart:455-541` : `readAsString` + `jsonDecode` **séquentiels** par fichier d'espèce (~900 pour un dex complet), builder `const` sans état, reconstruit par appel (`playable_map_game_session_runtime.dart:263`) ; appelé 2× par interaction sac (`runtime_player_coordinator.dart:291, 336`). `_loadMoveMachineAvailability` (`:289-317`) : jusqu'à ~120 reads séquentiels de plus (sac × équipe).
**Fix** : cache du catalogue parsé par project root pour la session (données immuables), `Future.wait`, mise à jour in place de la section sac.

### C7 (P2) — Divers application
- `runtime_player_pokemon_progression_hydrator.dart:164-213` : fallback qui décode **tout** le répertoire species au load d'une save, avec `keys.toSet()` par itération → index `Map<basename, File>` + compteur ; ou réutiliser le species loader caché.
- `player_service_runtime_controller.dart:1457/1605` : `_shopEntries` calculé 2× par frappe dans le shop (re-normalise le sac en mode vente) → passer la liste en paramètre.
- `dialogue_runtime_models.dart:150, 212` : `indexWhere` par titre à chaque jump Yarn → `Map<String, YarnNode>`.
- `script_runtime_controller.dart:151-156` : `firstWhere` + exception derrière un type nullable → index + `null` honnête.
- `runtime_manifest_tilesets.dart:81, 101` : index `elementById` construit 2× par load.
- `runtime_playtest_port.dart:79-108` : historique d'événements non borné (dev-only) → ring buffer.
- `runtime_battle_move_bridge.dart:1545-1549` : scan linéaire du registre PSDK → const map (mineur).

---

## D. Chargement, persistance, session

### D1 (P0) — Pipeline de checkpoint : ~8-10 passes de sérialisation + 3-4 SHA-256, isolate UI
Chemin réel : `playable_map_game_session_runtime.dart:311-319` → `hub_session_checkpoint_committer.dart:59-72` (app) → `save_envelope_codec.dart` (map_core) → `hub_save_repository_impl.dart:100-126, 546-558` (app). Par checkpoint : `toJson` complet ; canonicalisation + sha256 ; `create()` qui **re-décode et re-checksum ce qu'il vient d'écrire** (`save_envelope_codec.dart:61→245`) ; pretty-print `withIndent('  ')` (+30-40 % de payload) ; `utf8.encode(source).length` **juste pour lire `.length`** (`:78`) ; re-decode de vérification ; ré-encode UTF-8 ; relecture du fichier temp + 4e checksum. `_writeCanonical` (`:484-550`) fait un `jsonEncode` **par chaîne** + tri des clés par objet.
Déclencheurs : pause, lifecycle, exit, manual, completion, defeatRecovery (pas par pas de déplacement) — mais c'est le hitch UI dominant à chacun de ces moments.
**Fix** : supprimer le self-verify redondant de `create` ; supprimer le round-trip `decode(encode(...))` de `writeVerified` ; encodage compact sur disque ; déplacer canonicalisation+sha256+encode dans `Isolate.run` — **en réutilisant `GameSaveCodecExecutor` pour que l'offload s'applique enfin au chemin de prod** (le benchmark existant mesure aujourd'hui un chemin mort).

### D2 (P1) — Tilesets décodés deux fois, dont une en pur Dart sur l'isolate UI
`tile_image_loader.dart:273-335` : `img.decodeImage` (package:image, 10-50× plus lent que le codec moteur) puis re-décodage des **mêmes octets** via `ui.instantiateImageCodec` ; dans le cas courant le décodage pur Dart ne sert qu'à lire width/height. Branche multi-chunk : `copyCrop` + **ré-encodage PNG** par chunk. `_applyTransparentColor` (`:337-362`) : boucle par pixel avec accesseurs boxés (~1M itérations pour un atlas 1024²).
**Fix** : sauter `img.decodeImage` dans le cas courant (dimensions via la `ui.Image` ou peek IHDR 24 octets) ; multi-chunk via `srcRect` au draw (le mapping existe déjà, `runtime_tileset_image.dart:156-178`) ; couleur transparente sur `Uint8List` plat + `Isolate.run`. Bonus : `loadTilesetImagesById` (`:369-392`) séquentiel → `Future.wait`.

### D3 (P1) — Préparation bordure : re-décodage PNG complet + fingerprint par pixel à chaque mount/warp
`border_runtime_readiness.dart:43, 131-175` : `readAsBytes` + `img.decodeImage` + boucle par pixel (`getPixel` = 1 objet boxé/pixel), synchrone sur l'isolate UI, exécuté à chaque prepare — y compris avec un bundle **déjà en cache** (`playable_map_game.dart:2952` et 6 autres sites). Hitch de plusieurs centaines de ms par warp.
**Fix** : mémoïser l'intégrité par `(path, mtime, length, sourceRect, transparentColor)` ; sinon a minima `compute()` + `getBytes()` au lieu de `getPixel`. Bonus : `border_runtime_asset_cache.dart:117-141` charge séquentiellement → `Future.wait` (le cache single-flight dédupe déjà, `:86-115`).

### D4 (P2) — `GameSaveCodecExecutor` : estimateur plus cher que ce qu'il évite
`game_save_codec_executor.dart:56-116` : traversée récursive complète avec `toString()` par nombre/bool avant chaque encode ; sous le seuil 1 Mio on paie l'estimation **et** l'encode local ; l'estimation ignore l'échappement et l'indentation ; `Isolate.run` copie structurellement le JSON capturé à l'envoi.
**Fix** : supprimer l'estimateur — proxy bon marché (taille du save précédent, cachée) ou offload systématique.

### D5 (P2) — `file_game_save_repository.dart` : platform channel + exists/create à chaque opération, écriture non atomique
`:29-36` : `getApplicationSupportDirectory()` + `exists()`/`create()` à chaque save/load/exists/delete. `:65` : `writeAsString` sans flush ni temp+rename → un crash mi-écriture tronque la save (le repo Hub le fait correctement, ce fallback non).
**Fix** : mémoïser le path ; temp + flush + rename.

### D6 (P2) — 312 `debugPrint` non gardés, 0 `kDebugMode`
Non strippés en release ; les arguments interpolés sont évalués quoi qu'il arrive. Points chauds : `file_game_save_repository.dart:62-68` (interpole `completedStepIds` 2× par save), `playable_map_game.dart:10628-10630` (idem + cutscenes par save), `:3808, 3872, 3892` (dans `update()`), `load_runtime_map_bundle.dart:44` (par tileset au load), `scripted_entity_movement_controller.dart:159-199` et `playable_map_game.dart:12753` (par nœud bloqué du pathfinder, avec `map().join()`).
**Fix** : garde `kDebugMode` ou helper à argument lazy `_trace(String Function())`.

### D7 (P3) — `RuntimePlayerSnapshot` : 2 copies de collections + re-validation par publication
`runtime_player_models.dart:201-236` : `List.unmodifiable` + `Map.from` + 2 boucles de validation à chaque `next()` (~25 sites), y compris par tick de progression de chargement (`runtime_player_coordinator.dart:823-830`).
**Fix** : constructeur interne non vérifié réutilisant par identité les collections déjà validées.

---

## Déjà bien optimisé (à ne pas casser)

- Culling viewport des tuiles/objets/entités/placed elements (`map_layers_component.dart:13099`, `_visibleLocalRect`) — le design est bon, ce sont les **consommateurs** ombres/bordures/smart-tiles qui l'ignorent.
- Index construits au constructeur de `MapLayersComponent` (`:110-138`).
- `PlacedElementOcclusionPatchComponent` : pattern `ui.Picture` exemplaire (`quarter_turn_pixel_renderer.dart:40-120`) — c'est le modèle à répliquer (backdrop battle, bordures).
- Fast paths de `drawQuarterTurnPixels` (`:151-238`).
- `RuntimeTilesetImageSingleFlightCache` (`tile_image_loader.dart:23-199`) : dédup, coalescing, disposal corrects.
- Garde de changement des ombres de contact acteurs (`playable_map_game.dart:4062-4070`) — nuance : la liste de sources est allouée *avant* la garde (`:4055`), et `enableActorContactShadows: false` dans le chemin session shippé (`playable_map_game_session_runtime.dart:194`) court-circuite le tout.
- Collections statiques d'ombres construites une fois par mount (`:11995-11996`, `:10037-10038`).
- Pas de fuite de streams/timers dans `application/` ; pas de churn freezed par tick (hors C1).
- Profiling de rendu à coût nul quand désactivé (`map_layers_component.dart:316-330`).

---

## Plan de chantier proposé (par lots)

| Lot | Contenu | Effort | Gain attendu |
|---|---|---|---|
| **1. Quick wins rendu** | A3 (fast path drawImageRect), A6, A7, gardes `isEmpty` (A10), Paint hors boucle (A10), D6 (debugPrint chauds) | Faible | Milliers d'allocations/frame en moins, immédiat |
| **2. Caches statiques rendu** | A2 (bordures construites au mount + rects pré-scalés), A4+A5 (fusion ombres cachée + bandes cuites + couleur pré-résolue + culling) | Moyen | Supprime le gros du coût par frame hors smart tiles |
| **3. Smart Tile préparé** | A1 (résolution mémoïsée par cellule, frame d'animation seule par frame) | Élevé | Le plus gros poste de la passe sol |
| **4. Battle frame time** | B2, B3 (caches TextPainter + layout scindé), B5 (gradients + Picture backdrop), B6, B7 | Moyen | Combats fluides, surtout pendant les drains de HP |
| **5. Mémoire battle** | B4 (dispose + LRU + cache FX au scope jeu) | Moyen | Stoppe la croissance mémoire native par session |
| **6. Sauvegarde** | D1 (dé-duplication des passes + offload isolate sur le vrai chemin), D4, D5 — et rebrancher le benchmark sur le chemin de prod | Moyen | Supprime le hitch UI à chaque checkpoint |
| **7. Chargement/warp** | C3 (decode en isolate), D2 (double décodage tilesets), D3 (readiness bordure mémoïsée), C4 (cache dialogues) | Moyen | Warps et entrées de carte sans stall |
| **8. Logique PNJ/pathfinding** | C1, C2 (caches chapterIndex/projection/règles), C5 (loaders partagés), C6 (catalogue pause caché) | Moyen | Refresh de présence et re-paths indolores |
| **9. Catalogue RMXP** | B1 (asset binaire lazy + maps const résiduelles) | Élevé | −2,5 Mo binaire, temps de build/analyse, mémoire debug/tests |

Les lots 1-2 sont sans risque (mémoïsation pure de données immuables, comportement identique). Le lot 9 est le plus structurant et mérite son propre chantier avec l'outil Python de génération.

---

# Addendum de clôture (2026-08-08)

Les 9 lots ont été livrés le jour même, un commit par lot, poussés sur `main` :

| Lot | Commit | Contenu livré |
|---|---|---|
| 1 | `4797a6bf2` | Quick wins rendu (fast path `drawImageRect`, caches foreground/marges, gardes `isEmpty`, `debugPrint` chauds) |
| 2 | `d13311318` | Bordures construites au mount, ombres cuites par instruction, fusion mémoïsée, culling branché |
| 3 | `fe9ab5b5d` | `SmartTileLayerVisualPlan` (map_core) : préparation par calque, cellules lazy, variantes d'animation pré-construites, test de parité plan ↔ batch |
| 4 | `4226964cb` | Battle frame time : cache `TextPainter` LRU, layout HUD scindé, caches de gradients, backdrop en `ui.Picture`, churn `TextPaint`/`Vector2` éliminé |
| 5 | `6320c1c2a` | Mémoire battle : cache FX au scope jeu, `dispose()` au teardown, borne LRU sur le cache de sprites, scan de pixels en isolate |
| 6 | `c88c08b24` | Sauvegarde : passes redondantes supprimées (self-verify de `create`, round-trip de `writeVerified`), création d'enveloppe en `Isolate.run`, estimateur borné, écriture atomique du repo fallback |
| 7 | `710b98d35` | Chargement/warp : tilesets décodés une fois (codec moteur), parse cartes/manifest en isolate, readiness bordure mémoïsée (clé stat) + isolate, dialogues cachés par (chemin, mtime, taille) |
| 8 | `87b80740d` | PNJ/pathfinding : sonde A* préparée + prédicat de blocage vivant, index de chapitres et projection World Rules cachés, loaders partagés, catalogue pause signé |
| 9 | `90d2539de` | Catalogue RMXP : 282 843 → 1 730 lignes, asset binaire 480 Ko décodé au premier combat (round-trip validé champ par champ avant suppression du const) |

**Vérification** : `dart analyze` propre à chaque lot ; suites complètes vertes à chaque lot (map_runtime 2128, map_core 3968, éditeur smart tiles 219, hub session+saves 61 — y compris les tests de crash-recovery à injection de pannes du store de sauvegarde). Les seuls échecs restants préexistaient à l'audit et ont été vérifiés par stash sur HEAD : `border_map_layers_component_ordering_test` (ne compile plus contre l'API map_core actuelle), ROT-01 (fixture désalignée), `save_envelope_codec_test` (fixture Phase 0), 16 tests d'artefacts/gates map_core, 1 test de flux de gestes smart tiles éditeur.

## Constats traités hors périmètre initial des lots

- Bug attrapé en route (lot 7) : le nouveau chemin de transparence des tilesets gardait le RGB des pixels keyés avec alpha 0 — invalide en convention prémultipliée (teinte au blending). Détecté par le test de rendu réel des bordures, corrigé en zéroant le pixel entier.
- Piège de sur-capture des closures `Isolate.run` (lot 6) : un closure créé dans une méthode capture `this` (donc le store et ses hooks de test non envoyables). Convention adoptée : construire les closures d'offload dans des portées statiques/top-level ne contenant que des valeurs envoyables — appliquée aux lots 6, 7 et à la readiness bordure.

## Constats délibérément non traités

Écarts de design assumés (le fix de l'audit a été remplacé par mieux) :
- **A4/A5 invalidation** : validation par identité à la lecture plutôt que hooks d'invalidation disséminés.
- **C1 (blocage dynamique)** : prédicat sur l'état vivant plutôt que `Set` caché — les réservations mutent au milieu d'un tick via 12 sites, un cache aurait pu faire traverser un PNJ.
- **C5 (loaders)** : partage des instances du jeu plutôt que caches `static` — un cache process-level servirait des données périmées après édition + relancement de playtest dans le même process.
- **D4 (estimateur)** : borné par le seuil plutôt que supprimé — préserve les décisions d'offload et les tests existants.
- **F15 partiel (RMXP)** : la liste des cellules visibles n'est pas mémoïsée par index de frame — leur position dépend d'ancres de combattants vivantes entre ticks (projectiles).

Reliquat classé par intérêt décroissant, pour un éventuel lot 10 :
- **C4 (suite)** : interpolation lazy des dialogues — `mapText` clone encore tous les nœuds/choix du fichier à l'ouverture et passe la regex `{{var}}` sur des nœuds jamais visités.
- **C6 (suite)** : `_loadMoveMachineAvailability` garde sa boucle sac × équipe séquentielle et le pause builder construit encore ses loaders machine/évolution par appel ; la section sac est toujours entièrement reconstruite après usage d'objet.
- **A8/A9** : index spatial des placed elements par calque (requête + Set + tri par calque par frame) et tri complet des enfants du monde sur changement de `priority` (isoler les acteurs dans un parent depth-sorted).
- **A10 reliquat** : `PlayerComponent.syncState` par frame idle, re-résolution d'animation des acteurs, rect absolu des patchs d'occlusion, `.trim()`/transforms par instance par frame, `runes.length` du dialogue.
- **D6 reliquat** : ~290 `debugPrint` non gardés restants (les points chauds — save, pathfinding, update, loaders — sont faits).
- **D7** : constructeur non vérifié pour `RuntimePlayerSnapshot.next()`.
- **C7 reliquat** : shop entries calculées 2× par frappe, lookup de nœuds Yarn linéaire, historique playtest non borné, etc.
- **B7 reliquat** : `battle_move_visual_recipe_library.dart` (12,8k lignes) collapsible en ~20 templates — uniquement si on y retouche.

## Limite de la validation

Tout a été vérifié par analyse statique et par les suites de tests (y compris les tests pixel-level des renderers modifiés et le benchmark d'offload du codec). **Aucune session de jeu réelle n'a été jouée** : le scénario qui exerce le plus de chemins modifiés — warp vers une carte à bordures animées et bâtiments à ombres projetées, ouverture du menu pause, combat complet avec animations RMXP, sauvegarde — reste à faire tourner une fois en conditions réelles.
