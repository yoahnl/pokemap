# Project Status (pokemonProject)

Last updated: 2026-03-26 (`map_runtime` Runtime 4 : boucle jouable `PlayableMapGame` + `PlayerComponent` + warps ; `map_gameplay` spawn joueur + `fromMap` ; socle exploration ; Runtime 3 ; dresseurs éditeur — voir lots ci-dessous)

## Vision produit

### Positionnement

Le monorepo **n est plus defini** comme un simple « editeur de maps Pokemon-like ». La vision cible est une **suite outil + format + runtime** pour produire et jouer un jeu de type Pokemon-like sur grille.

**Ordre de priorite explicite (strategie produit):**

1. **Editeur de contenu de jeu tres riche** — **priorite actuelle**. Permettre a une personne **non developpeuse** de construire: maps, liens entre maps, terrains et surfaces, entites (visuel editeur via elements projet), dialogues (partiel : registre + assignation), rencontres (partiel : zones + tables), interactions, donnees standard de gameplay — avec des ecrans et workflows **guides**, pas un simple editeur technique.
2. **Package Flutter / Flame lecteur de projet** (`map_runtime`) — **prochaine grande etape** pour le **jeu jouable complet** ; un **premier socle** est livré (lecture `project.json` + map + affichage Flame aligné sur l’éditeur pour tile/terrain/path/collision). La suite : déplacement, collisions actives, warps, entités, dialogues, rencontres, etc.
3. **Couches plus haut niveau** (framework super abstrait, no-code integral) — **volontairement plus tard**. Ce n est **pas** la priorite immediate; l objectif immediat est la **qualite du contenu modelise** et sa **future execution standard**, pas un meta-moteur tout-fait sur la premiere iteration.

### Tableau de bord des phases (etat actuel)

| Phase | Contenu | Etat |
|-------|---------|------|
| **1 — Editeur de contenu riche** | Maps, connexions, terrains, collisions, warps, triggers, entites (NPC/signe/objet/spawn), dialogues, rencontres, dresseurs, proprietes de map | **En cours — priorite actuelle** |
| **2 — Runtime standard** (`map_runtime` + `map_gameplay`) | Lecteur projet + scène + déplacement/collisions/warps + interactions + dialogues + comportements standards | **Amorcé** : `map_runtime` Runtime 1-4 (chargement + rendu layers + entités + **boucle jouable** avec `PlayableMapGame` / `PlayerComponent` / warps) **livré** ; `map_gameplay` socle exploration **livré** ; interactions/dialogues/rencontres **à construire** |
| **3 — Couches haut niveau** | No-code, framework abstrait, simplification maximale creation jeu | **Volontairement plus tard** |

*Phase 1 avancée : maps/layers/tilesets/terrains/collisions/warps/triggers/entités avec visuel éditeur (`editorVisual` → `ProjectElementEntry`, animation canvas multi-frames), **propriétés de map** (`MapMetadata` : nom, type, musique, météo, indoor, escape rope, spawn par défaut, tags — UI panel + use case livrés), **zones gameplay** (`MapGameplayZone` avec payloads typés : encounter/movement/hazard/special) + **tables de rencontres** (`ProjectEncounterTable` + entrées espèces/niveaux/poids — modèle + UI éditeur complet), **dialogues** (registre `ProjectDialogueEntry`, dossiers, UI bibliothèque, assignation depuis NPC/signe), **dresseurs** (`ProjectTrainerEntry` + équipe `ProjectTrainerPokemonEntry` — modèle `map_core`, Trainer Library dans l'explorateur, champs combat dans l'inspecteur NPC : trainerId, lineOfSightRange, defeatDialogueRef) — solide et avancé. Manque encore côté éditeur : propriétés de map avancées (hooks gameplay, flags progression, restrictions). Côté runtime : boucle jouable, entités in-game, dialogues Yarn, rencontres actives.*

*Phase 2 bien amorcée : `map_runtime` est un **visualiseur read-only** — lit le même JSON que l’éditeur, charge les tilesets, affiche layers + entités animés via `ProjectElementEntry.frames` dans une scène Flame. `map_gameplay` porte la logique d’exploration (déplacement grille, collisions, warps) en pur Dart sans rendu. Pas encore : interactions NPC/signe, dialogues runtime, rencontres actives.*

### Repartition des roles

- **Createur de contenu (non dev)**: travaille dans `map_editor`, manipule des concepts metier (maps, groupes, tilesets, entites, triggers, warps, etc.), exporte / sauvegarde un **projet structure** (JSON + assets).
- **Developpeur jeu**: integre le package runtime (ou le dossier projet) dans une app Flutter/Flame, se concentre sur **l integration technique**, les extensions et ce qui depasse le comportement standard — **pas** sur la re-saisie manuelle du contenu dans le code.

### Consequences pour la conception des donnees

- Toute **nouvelle donnee metier** doit etre pensee **a la fois** pour l edition (`map_editor`) et pour une **execution future** par `map_runtime` (semantique claire, validation dans `map_core`, serialisation stable).
- `map_core` = **schema metier + invariants + operations pures** (pas de Flutter, pas de Yarn, pas de Flame) ; **compat JSON legacy** éditeur (`migrateProjectManifestJson` / `migrateMapDataJson` dans `src/io/legacy_editor_json_compat.dart`, export barrel) pour qu’éditeur et runtime lisent les mêmes migrations.
- `map_editor` = **production** de ces donnees (UI, use cases, fichiers).
- `map_runtime` = **visualiseur read-only** (lecture projet, rendu layers + entités, scène Flame) ; **Runtime 1-3** livrés.
- `map_gameplay` = **logique de jeu d'exploration**, pur Dart, sans rendu ; consomme `MapData` de `map_core` ; boucle : `stepGameplayWorld(world, intent) → GameplayStepResult`.

### Integrations externes (ex. Yarn Spinner)

- Les **references metier** (ex. `DialogueRef`) vivent dans `map_core`.
- Les **adaptateurs moteur** (chargement Yarn, VM, etc.) vivent dans `map_runtime` ou une couche infra — **pas** de dependance sale du domaine vers un runtime concret.

### Structure du document

- **Sections 1–2**: resume et architecture — vue d ensemble stable.
- **Sections 3–6**: etat des fonctionnalites et tache en cours — reference vivante.
- **Sections 8–9**: prochaines etapes et decisions d architecture — directive.
- **Section 7 et lots ci-dessous**: historique technique des lots livres — archive.

> En cas de tension entre un lot historique et la presente section Vision produit, **c est la Vision produit qui fait foi**.

---

> **Derniers lots documentés** — detail technique des lots les plus recents (historique complet dans **## 7**).

## Lot: Animation légère des entités sur le canvas éditeur (2026-03-24)

Objectif: sur le canvas `map_editor`, faire défiler les **`ProjectElementEntry.frames`** pour les entités dont le visuel canonique est résolu via **`MapEntity.editorVisual` → `resolvedProjectElementIdForEditor`** (puis legacy `npc.visualElementId`), **sans** dupliquer de frames ni d’animation sur `MapEntity`, **sans** pipeline visuel PNJ séparé, **sans** Flame ni `map_runtime`.

### Principe

- **Un visuel d’entité = une référence à un `ProjectElementEntry`.** Les frames vivent uniquement sur l’entrée projet.
- **Une seule frame** sur l’élément → rendu identique au comportement précédent (frame unique, pas de tick timer inutile pour la carte).
- **Plusieurs frames** → le canvas choisit la frame courante selon un temps éditeur monotonique : `durationMs` par frame si renseigné et > 0, sinon fallback **200 ms** ; cycle sur la somme des durées (`elapsedMs % total`).
- **Résolution** : même règles qu’avant pour `tilesetId` effectif (frame explicite ou héritage de `entry.tilesetId`), `Rect` source depuis `frame.source` et tailles tile projet.
- **Préchargement** : `collectTilesetIdsForEntityEditorVisuals` parcourt **toutes** les frames de chaque élément référencé par une entité sur la map (y compris tilesets distincts par frame).

### Où vit quoi (`map_editor` uniquement)

- **`entity_editor_element_visual.dart`** : `entityEditorPickFrame`, `resolveEntityElementVisualForEditor(..., editorAnimationTimeMs)`, `mapEntitiesNeedEditorFrameAnimation`, `collectTilesetIdsForEntityEditorVisuals` (multi-frames).
- **`MapCanvas` (`_MapCanvasState`)** : `Timer.periodic` (~110 ms) **uniquement** si `mapEntitiesNeedEditorFrameAnimation` ; compteur `_editorEntityAnimationMs` ; annulation au `dispose` et quand aucune map / plus besoin d’anim.
- **`MapGridPainter`** : paramètre `editorEntityAnimationMs` ; `shouldRepaint` si ce temps change ; `_paintEntities` appelle `resolveEntityElementVisualForEditor` puis `_paintEntityProjectElementFrame` (contain, clip, fallbacks N/S/I/P/+, sélection, badge, label inchangés).

### Hors scope (inchangé)

- Runtime jeu, facing, vitesses par type d’entité, tweening, preview inspector async riche.

### Fichiers touchés (ce lot)

- `packages/map_editor/lib/src/application/services/entity_editor_element_visual.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart` (tooltip aligné)
- `packages/map_core/lib/src/models/project_manifest.dart` (commentaire `ProjectElementEntry.frames` + regen Freezed)
- `PROJECT_STATUS.md`

### Suite possible (après ce lot)

- Réutiliser la même logique de frame courante pour d’autres previews éditeur ; runtime `map_runtime` avec sémantique gameplay (direction, états, etc.).

---

## Lot: map_runtime — Runtime 1 (lecteur projet + scène Flame + parité rendu) (2026-03-26)

Objectif: prouver que le **format produit par l’éditeur** est **lisible et affichable** par `map_runtime` (Flame), sans dupliquer les schémas (`map_core` uniquement), sans nouveau format JSON runtime.

### Livré dans ce lot

- **Chargement** : `project.json` → `ProjectManifest` (migration + `ProjectValidator`) ; map via `ProjectMapEntry.relativePath` → `MapData` (migration + `MapValidator` avec `projectDialogueContext`).
- **Assets** : résolution chemins absolus des tilesets référencés par les **TileLayer** *et* par les **presets terrain/path** utilisés sur la map (`collectAllRuntimeTilesetIds` + `resolveTilesetAbsolutePaths`) ; décodage PNG → `dart:ui.Image`.
- **Architecture package** : `application/` (`RuntimeMapBundle`, `loadRuntimeMapBundle`, `runtime_manifest_tilesets`), `infrastructure/` (`tile_image_loader`), `presentation/flame/` (`RuntimeMapGame`, `MapLayersComponent`, `RuntimePathAutotileSet`).
- **Rendu** : **même ordre de peinture que `MapGridPainter`** (terrain → path → tile → collision, couches visibles parcourues en indices décroissants par type) ; terrain via **presets** (`ProjectTerrainPreset` + graine de cellule comme l’éditeur) ; path via **autotile** (`resolvePathVariantAt` + mapping `ProjectPathPreset`) ; fallback couleur si image absente ; overlay collision semi-transparent si couche visible.
- **Exemple** : app `packages/map_runtime/example` (`map_runtime_example`) — bouton **Parcourir** (`file_picker`) pour choisir `project.json` + champ map id → `GameWidget`. **macOS** : sandbox désactivé dans les entitlements Debug/Release pour permettre la lecture de projets hors conteneur (outil de dev local ; pas adapté tel quel à une distribution Mac App Store sandboxée).

### map_core — JSON legacy partagé (même lot / même vague)

- **`legacy_editor_json_compat.dart`** : `migrateProjectManifestJson`, `migrateMapDataJson` (logique déplacée depuis `map_editor` `file_repositories.dart`).
- **`map_editor`** : chargement projet/map appelle désormais ces fonctions via `map_core` (une seule source de vérité pour la compat lecture disque).

### Hors scope (inchangé pour Runtime 1)

- Déplacement joueur, collisions bloquantes gameplay, warps/triggers/rencontres actifs, **rendu des entités** (`MapEntity` / `ProjectElementEntry` in-game), dialogues Yarn, sauvegarde runtime.

### Fichiers principaux

- `map_core` : `lib/src/io/legacy_editor_json_compat.dart`, `map_core.dart` (export).
- `map_editor` : `lib/src/infrastructure/repositories/file_repositories.dart`.
- `map_runtime` : `lib/map_runtime.dart`, `lib/src/application/load_runtime_map_bundle.dart`, `runtime_map_bundle.dart`, `runtime_manifest_tilesets.dart`, `lib/src/infrastructure/tile_image_loader.dart`, `lib/src/presentation/flame/runtime_map_game.dart`, `map_layers_component.dart`, `runtime_path_autotile.dart`, `pubspec.yaml` ; `example/` (projet Flutter + entitlements macOS).
- Supprimé : ancien stub `map_runtime_base.dart` (remplacé par le pipeline ci-dessus).

### Suite probable (Runtime 2+)

- Dessin des entités avec la même règle que l’éditeur (`editorVisual` → `ProjectElementEntry.frames`, tilesets projet) ; caméra / monde ; input ; collisions ; warps ; etc.

---

## Lot: map_runtime — Runtime 2 (entités animées) + Runtime 3 (API cleanup) + map_gameplay socle + Spawn joueur (2026-03-26)

*(Regroupement des lots précédents livrés dans la même session, documentés rétrospectivement.)*

### Runtime 2 — Rendu des entités dans `MapLayersComponent`

- `_paintEntities` : parcours `map.entities`, résolution `resolvedProjectElementIdForEditor` → `ProjectElementEntry` → frame courante → `tileImagesByTilesetId[tilesetId]` → `drawImageRect` en **contain** dans la hitbox.
- `_pickEntityFrame` : cycle modulo sur la somme des `durationMs` (fallback 200 ms par frame).
- `_paintEntityFrame` : ratio source préservé (contain, centré).
- `update(dt)` : accumulation `_animElapsed` pour l’animation.

### Runtime 3 — Stabilisation API `map_runtime`

- `loadRuntimeMapBundle` : paramètre renommé `manifestPath` → `projectFilePath`.
- `RuntimeMapGame` : images chargées **en interne** dans `onLoad()` (plus de `tileImagesByTilesetId` en constructeur).
- Barrel `map_runtime.dart` : resserré à 3 exports avec `show` (`loadRuntimeMapBundle`, `RuntimeMapBundle`, `RuntimeMapGame`).
- `pubspec.yaml` : nettoyé pour pub.dev (`publish_to` supprimé, `repository`, `topics`).
- Exemple : mis à jour avec `projectFilePath:` et sans `tileImagesByTilesetId`.
- `README.md` : rédigé (positionnement, API publique, exceptions, limitations).

### map_gameplay — Socle exploration

- Package pur Dart `packages/map_gameplay` (sans Flutter/Flame).
- `Direction`, `DirectionX` (dx/dy/asFacing), `EntityFacingX.asDirection`.
- `GameplayPlayerState` (pos, facing, copyWith).
- `GameplayWorldState` (collision cache, warp lookup, `initial`/`fromMap` factories, `withPlayer`, `isBlocked`, `warpAt`).
- `GameplayIntent` / `MoveIntent`.
- `GameplayStepResult` / `Moved` / `Blocked` / `WarpTriggered` / `TriggeredWarp`.
- `stepGameplayWorld(world, intent) → GameplayStepResult` (turn-face, collision check, warp check).

### map_gameplay — Spawn joueur

- `GameplaySpawnResolutionException`.
- `resolveInitialPlayerSpawn(MapData)` : priorité `defaultSpawnId` → role `playerStart` (tri par id, premier) → exception.
- `GameplayWorldState.fromMap(MapData)` : spawn résolu + vérification cellule bloquée.

### Fichiers principaux

- `map_runtime` : `map_layers_component.dart` (entités), `runtime_map_game.dart` (images internes), `load_runtime_map_bundle.dart` (renommage), `map_runtime.dart` (barrel), `pubspec.yaml`, `README.md`, `example/lib/main.dart`.
- `map_gameplay` : `pubspec.yaml`, `map_gameplay.dart`, `direction.dart`, `gameplay_player_state.dart`, `gameplay_world_state.dart`, `gameplay_intent.dart`, `gameplay_step_result.dart`, `gameplay_step.dart`, `gameplay_exceptions.dart`, `player_spawn_resolver.dart`.

---

## Lot: map_runtime — Runtime 4 (boucle jouable : PlayableMapGame + PlayerComponent + warps) (2026-03-26)

Objectif: premier chemin d’exécution **jouable** au-dessus du visualiseur existant — déplacement au clavier, collisions actives, transitions de map via warp.

### Livré dans ce lot

- **`PlayerComponent`** (Flame `PositionComponent`) : marqueur visuel (disque bleu + point blanc direction) à la position grille du joueur. `updateState(GameplayPlayerState)` déplace le composant.
- **`PlayableMapGame`** (FlameGame + `KeyboardEvents`) :
  - Construit `GameplayWorldState.fromMap(bundle.map)` à l’initialisation.
  - Gère les touches flèches / WASD → `MoveIntent(Direction)` → `stepGameplayWorld`.
  - Sur `WarpTriggered` : charge async le nouveau `RuntimeMapBundle` via `loadRuntimeMapBundle`, recrée `MapLayersComponent` + `PlayerComponent`, rebascule la caméra.
  - Caméra centrée sur le joueur avec viewport de ~15×11 tuiles (adapté si la map est plus petite).
  - `KeyDownEvent` + `KeyRepeatEvent` acceptés ; `_transitioning` flag pour bloquer l’input pendant le chargement de warp.
- **Barrel** `map_runtime.dart` : ajout `PlayableMapGame`.
- **Exemple** `packages/map_runtime/example` : remplace `RuntimeMapGame` par `PlayableMapGame(bundle: bundle, projectFilePath: _manifestPath)`.

### Hors scope (volontaire)

- Interactions NPC/signe, dialogues, rencontres actives, animations joueur orienté, son.

### Fichiers principaux

- `map_runtime/lib/src/presentation/flame/player_component.dart` (nouveau)
- `map_runtime/lib/src/presentation/flame/playable_map_game.dart` (nouveau)
- `map_runtime/lib/map_runtime.dart` (ajout export `PlayableMapGame`)
- `map_runtime/pubspec.yaml` (ajout dépendance `map_gameplay`)
- `map_runtime/example/lib/main.dart` (utilise `PlayableMapGame`)

---

## Lot: Visuel entités éditeur — Entity Visual Presentation (2026-03-25)

Objectif: sur le canvas, ne plus seulement un rectangle coloré : afficher le **visuel** issu d’un **`ProjectElementEntry`** via ses `TilesetVisualFrame` quand il est configuré, sinon un **fallback** lisible par type. Référence canonique : **`MapEntity.editorVisual.elementId`** ; **`npc.visualElementId`** = compatibilité legacy uniquement. *(Au moment de ce lot, le canvas utilisait la première frame ; l’animation multi-frame canvas est documentée dans le lot **Animation légère des entités sur le canvas éditeur**.)*

### Modèle (`map_core`)

- **`MapEntityEditorVisual`** (`map_entity_editor_visual.dart`, Freezed + JSON) : `elementId` → `ProjectElementEntry.id` (sémantique **éditeur uniquement**).
- **`MapEntity.editorVisual?`** : champ optionnel (pas dans `properties`) ; JSON `editorVisual` ; rétrocompat absences → `null` → fallback canvas.
- **`MapEntityProjectElementVisualX`** sur `MapEntity` (`map_data.dart`) : `canonicalEditorVisualProjectElementId` (= `editorVisual.elementId`), `legacyNpcVisualProjectElementId` (= ancien `npc.visualElementId`), `resolvedProjectElementIdForEditor` (canonique puis legacy).
- **`updateEntityOnMap`** : paramètre `editorVisual` avec sentinelle `mapEntityTypedPayloadUnset` ; `_normalizeEditorVisual` (trim, id vide → `null`).
- **`assertEntityEditorVisualAgainstProject`** : si `MapValidator.validate(..., projectDialogueContext: project)` est appelé avec un manifeste, l’`elementId` doit exister dans `project.elements`.
- **Pas de système visuel parallèle** : animation éventuelle = `frames` sur `ProjectElementEntry` ; l’entité ne duplique pas cette structure.
- Export `map_core.dart`, `entity_editor_visual_validation.dart`.

### Éditeur (`map_editor`)

- **`entity_editor_element_visual.dart`** : résolution visuelle entité (image tileset + `Rect` source) ; `collectTilesetIdsForEntityEditorVisuals` pour précharger les tilesets (voir lot animation pour multi-frames).
- **`MapCanvas`** : `_collectLayerTilesetPaths` inclut ces tilesets ; `MapGridPainter` reçoit `project` ; `_paintEntities` : frame d’élément projet en **contain** dans la hitbox (coins arrondis, clip) ou fallback (fond teinté + glyphe **N/S/I/P/+**) ; **bordure de sélection**, badge type et **label** conservés.
- **`EntityPropertiesPanel`** : section **Référence visuelle (bibliothèque)** — même liste `ProjectElementEntry` pour **tous** les kinds (pas de volet « sprite PNJ » séparé) ; à l’enregistrement : `editorVisual` + `npc.visualElementId` vidé.
- **`EntityEditingService`**, **`UpdateEntityOnMapUseCase`**, **`EditorNotifier`** : paramètre `editorVisual` sur update.

### Hors scope à l’époque du lot (volontaire)

- Animation canvas multi-frame (lot ultérieur), pas de Flame / `map_runtime`, pas de preview image async dans l’inspector (libellé + dropdown seulement dans ce lot).

### Fichiers principaux touchés

- `map_core` : `map_entity_editor_visual.dart`, `map_data.dart`, `map_entities.dart`, `validators.dart`, `entity_editor_visual_validation.dart`, `map_core.dart` ; fichiers générés Freezed/JSON.
- `map_editor` : `entity_editor_element_visual.dart`, `map_canvas.dart`, `entity_properties_panel.dart`, `entity_editing_service.dart`, `entity_use_cases.dart`, `editor_notifier.dart`.

### Consolidation architecture (recadrage 2026-03-26)

- **Règle unique** : bibliothèque visuelle = `ProjectElementEntry` (`frames` statiques ou animés) ; l’entité ne porte qu’une **référence** `MapEntity.editorVisual.elementId` — pas de structure de frames dupliquée côté entité.
- **Legacy** : `MapEntityNpcData.visualElementId` conservé pour compatibilité / migration ; résolution éditeur explicite via `legacyNpcVisualProjectElementId` vs `canonicalEditorVisualProjectElementId`.
- **UI** : libellés inspector centrés sur « référence visuelle (bibliothèque) » et `ProjectElementEntry` pour **tous** les kinds ; tooltips alignés avec le canvas (frames sur l’élément, pas sur l’entité).
- **Canvas** : rendu entité via `_paintEntityProjectElementFrame` et résolution `resolveEntityElementVisualForEditor` (lot animation) ; pas de pipeline PNJ séparé.

---

## Lot: Refactoring zones gameplay — payloads typés + drag-to-draw (2026-03-25)

Objectif: rendre `GameplayZone` un vrai concept métier avec séparation nette des payloads par kind, suppression du kind `transition`, et **dessin direct des zones par clic+glisser** sur le canvas.

### Modèle (`map_core`)

- **`HazardKind`** (nouveau enum): `lava`, `poison`, `swamp`, `pitfall`, `other`.
- **`GameplayZoneKind`** simplifié: suppression de `transition` (migré → `special`); `custom` conservé comme fallback documenté.
- **Payloads typés** (nouveau fichier `map_gameplay_zone_payloads.dart`, Freezed + JSON):
  - `EncounterZonePayload`: `encounterTableId?`, `encounterKind`.
  - `MovementZonePayload`: `requiredMode`, `allowedModes`.
  - `HazardZonePayload`: `hazardKind`, `damagePerStep`.
  - `SpecialZonePayload`: `scriptKey?`, `properties`.
- **`MapGameplayZone`** refactorisé: `encounterTableId`/`movementMode`/`properties` plats remplacés par `encounter?`, `movement?`, `hazard?`, `special?`.
- **`migrateMapGameplayZoneJson`**: migration transparente du JSON legacy (champs plats → payloads; `transition` → `special`).
- **`updateGameplayZoneOnMap`**: sentinelles `_kUnset` par payload (`encounter`, `movement`, `hazard`, `special`).
- **`validators.dart`**: validation `special.properties` (clés non vides).
- Export dans `map_core.dart`.

### Editor (`map_editor`)

- **Use cases** mis à jour pour les nouveaux paramètres payload.
- **`GameplayZoneEditingCoordinator`**: `createDefaultZone` initialise `EncounterZonePayload`; nouvelle méthode `createZoneFromRect(map, rect, {kind})`.
- **`GameplayZoneEditingService`**: nouvelle méthode `addZoneInRect(map, rect, {kind})` pour le drag-to-draw.
- **`EditorState`**: nouveau champ `gameplayZoneDraftArea: MapRect?` (fantôme en cours de tracé).
- **`EditorNotifier`**: mise à jour des méthodes update pour les payloads typés; nouvelles méthodes `setGameplayZoneDraftArea`, `commitGameplayZoneDraft`, `cancelGameplayZoneDraft`.
- **`MapCanvas`** (drag-to-draw):
  - `_zoneDragStart: GridPos?` dans le state du widget.
  - `onPanStart/Update/End` gèrent le tracé de zone par clic+glisser.
  - `_rectFromCorners`: normalise les deux coins en `MapRect` (inclusif).
  - `MapGridPainter`: `gameplayZoneDraftArea?` avec rendu fantôme (remplissage + bordure pointillée).
  - `_gameplayZoneColor`: case `transition` supprimé.
- **`GameplayZonePropertiesPanel`** entièrement réécrit:
  - Formulaires contextuels par kind (encounter / movement / hazard / special-custom).
  - Suppression des dropdowns `encounterTableId`/`movementMode` plats → payloads structurés.
  - `_SectionDivider` pour séparation visuelle des sections.
  - Message "draw a rectangle" dans le placeholder vide.

### Fichiers touchés dans ce lot

- `map_core`: `enums.dart`, `map_gameplay_zone_payloads.dart` (nouveau), `map_data.dart`, `map_gameplay_zones.dart`, `validators.dart`, `map_core.dart`.
- `map_editor`: `gameplay_zone_use_cases.dart`, `gameplay_zone_editing_coordinator.dart`, `gameplay_zone_editing_service.dart`, `editor_state.dart`, `editor_notifier.dart`, `map_canvas.dart`, `gameplay_zone_properties_panel.dart`.

---

## Lot: Zones gameplay + Tables de rencontres (domaine + editor complet)

Objectif: introduire la séparation propre entre **visuel** (`PathSurfaceKind`), **comportement de terrain** (futur runtime) et **logique de rencontre**; fournir à l'éditeur un système complet de zones rectangulaires sur map et de tables de rencontres réutilisables au niveau projet.

### Modèle (`map_core`)

- `GameplayZoneKind`: `encounter`, `movement`, `hazard`, `transition`, `special`, `custom`.
- `MovementMode`: `walk`, `surf`, `fly`, `cut`, `strength`, `rockSmash`.
- `EncounterKind`: `walk`, `surf`, `headbutt`, `oldRod`, `goodRod`, `superRod`, `gift`, `special`.
- `MapGameplayZone` (freezed + JSON) sur `MapData.gameplayZones`: id, name, kind, area (`MapRect`), `encounterTableId?`, `movementMode?`, priority, properties.
- `ProjectEncounterEntry` (freezed + JSON): `speciesId`, `minLevel`, `maxLevel`, `weight`.
- `ProjectEncounterTable` (freezed + JSON) sur `ProjectManifest.encounterTables`: id, name, `encounterKind`, entries, tags.
- `map_gameplay_zones.dart`: opérations CRUD pures (`find*`, `add*`, `update*`, `move*`, `resize*`, `remove*`) avec sentinelle `_kUnset` pour les champs nullable optionnels.
- `ProjectValidator`: validation tables (unicité id, entries valides: levels, weight, speciesId).
- `MapValidator`: validation zones (id non vide, area > 0, propriétés sans clé vide, unicité id).

### Editor (`map_editor`)

- **Architecture**: `GameplayZoneEditingCoordinator` (helpers stateless) + `GameplayZoneEditingService` (orchestration) + 3 use cases map-level (`Add/Update/DeleteGameplayZoneToMapUseCase`) + 6 use cases projet (`Create/Update/DeleteEncounterTableUseCase`, `Add/Update/DeleteEncounterEntryUseCase`).
- **Providers Riverpod** enregistrés pour tous les use cases et services.
- **`EditorState`**: `selectedGameplayZoneId` + outil `gameplayZonePlacement`.
- **`EditorNotifier`**: `placeOrSelectGameplayZoneAt`, `addGameplayZoneAt`, `selectGameplayZone`, `updateSelectedGameplayZone`, `updateGameplayZone`, `deleteSelectedGameplayZone`, `deleteGameplayZone`; `createEncounterTable`, `updateEncounterTable`, `deleteEncounterTable`, `addEncounterEntry`, `updateEncounterEntry`, `deleteEncounterEntry`.
- **Canvas**: overlay coloré par `GameplayZoneKind` (remplissage + bordure + label) avec sélection visuellement distincte; clic via outil `gameplayZonePlacement`.
- **`GameplayZonePropertiesPanel`**: liste des zones + éditeur (id, name, kind, area, encounterTableId dropdown, movementMode dropdown, priority) + Save/Delete.
- **`EncounterTablesPanel`**: liste des tables projet + formulaire création/édition table + édition inline des entrées (species, levels, weight).
- **`MapInspectorPanel`**: sections "Gameplay Zones" et "Encounter Tables" conditionnelles.
- **`TopToolbar`**: bouton outil "Gameplay Zone Tool" dans le groupe Gameplay Tools.

### Fichiers touchés dans ce lot

- `map_core`: `enums.dart`, `map_data.dart`, `project_manifest.dart`, `map_gameplay_zones.dart` (nouveau), `validators.dart`, `map_core.dart`.
- `map_editor`: `editor_tool.dart`, `editor_state.dart`, `gameplay_zone_editing_coordinator.dart` (nouveau), `gameplay_zone_editing_service.dart` (nouveau), `gameplay_zone_use_cases.dart` (nouveau), `encounter_table_use_cases.dart` (nouveau), `use_cases.dart`, `use_case_providers.dart`, `editor_notifier.dart`, `map_canvas.dart`, `gameplay_zone_properties_panel.dart` (nouveau), `encounter_tables_panel.dart` (nouveau), `map_inspector_panel.dart`, `top_toolbar.dart`.

---

## Lot: Entites structurees + DialogueRef (domaine + inspector)

Objectif: sortir les champs gameplay des seules `properties` pour `npc`, `sign`, `item`, `spawn`, preparer les references de dialogue sans coupler `map_core` a Yarn Spinner.

### Modele (`map_core`)

- `DialogueRef`: `dialogueId`, `scriptPathRelative`, `startNode` (optionnel) — logique metier uniquement.
- Payloads optionnels sur `MapEntity`: `npc`, `sign`, `item`, `spawn` (freezed + JSON + `explicitToJson`).
- Enums: `EntityFacing`, `ItemPickupMode`, `ItemRespawnPolicy`, `EntitySpawnRole`.
- `migrateMapEntityJson`: remonte les cles legacy depuis `properties` vers les blocs typés au chargement.
- `updateEntityOnMap`: fusionne `id/name/kind/pos/size/properties` et les blocs typés ; constante `mapEntityTypedPayloadUnset` pour **omettre** un bloc (ne pas ecraser lors des updates partiels). `null` explicite sur un bloc reste supporte via `copyWith`.
- `assertValidMapEntityTypedPayloads`: dialogue avec `dialogueId` non vide si ref presente ; chemin script relatif sans `..` s il est renseigne ; quantite item > 0.
- Extension `MapEntityDisplayX.inspectorHeadline` pour libelles liste / canvas.

### Editor (`map_editor`)

- `EntityPropertiesPanel`: sections contextuelles par `MapEntityKind` (formulaires PNJ, panneau, objet, spawn) + proprietes libres en **extensions** ; `custom` reste oriente proprietes libres.
- Validation UX basique des chemins de script dialogue avant sauvegarde.
- `UpdateEntityOnMapUseCase`: `?? mapEntityTypedPayloadUnset` pour ne pas ecraser les payloads quand le caller omet les parametres optionnels.
- Canvas: etiquette entite basee sur `inspectorHeadline`.

### Yarn Spinner / runtime (hors lot)

- Aucune dependance moteur dans `map_core`. Prochaine etape: infrastructure `map_runtime` ou couche projet qui resout `DialogueRef` vers des fichiers Yarn.

### Fichiers touches dans ce lot (complement)

- `map_core`: `map_entities.dart` (update typed + sentinelle `mapEntityTypedPayloadUnset`).
- `map_editor`: `entity_use_cases.dart`, `entity_properties_panel.dart`, `map_canvas.dart`.
- Deja en place avant ce complement (reference): `map_entity_payloads.dart`, `map_data.dart`, `enums.dart`, `validators.dart`, `entity_editing_*`, `editor_notifier`.

---

## Lot precedent: Visuels multi-frames (domaine + JSON)

Objectif: preparer animations futures (eau, lave, herbes, etc.) sans UI d’animation lourde.

### Modele unique: `TilesetVisualFrame` (`map_core`)

- Champs: `tilesetId` (vide = heriter du tileset parent), `source` ([`TilesetSourceRect`]), `durationMs` (optionnel, futur lecteur).
- Liste ordonnee `frames` partout ou un visuel etait un seul `source`:
  - `ProjectElementEntry.frames`
  - `TilesetPaletteEntry.frames`
  - `TerrainPresetVariant.frames`
  - `PathPresetVariantMapping.frames`
- Extension `TilesetVisualFrameListX`: `primaryFrame` / `primarySource` (premiere frame).

### Regles de validation (`ProjectValidator._validateVisualFrames`)

- Au moins une frame; rectangles sources valides; `durationMs` > 0 si present.
- Si plusieurs frames: meme `width` et `height` sur toutes les sources (cohérence animation).
- `tilesetId` non vide sur une frame doit exister dans le manifest.

### Migration JSON (chargement)

- Fichier pur: `map_core/lib/src/models/visual_frame_json.dart` — `jsonCoerceLegacySourceToFrames`.
- Ancienne forme avec `"source": { x, y, width, height }` au meme niveau que l’objet → convertie en `"frames": [ { "source": … } ]` avant `fromJson`.
- La serialisation **sortante** n’ecrit que `frames` (plus de cle `source` au niveau entree/variante).

### Rendu editeur (évolution après lots ultérieurs)

- **Entités sur le canvas** : `ProjectElementEntry.frames` avec animation légère (timer éditeur) — voir lot *Animation légère des entités sur le canvas éditeur*.
- **Autre UI** (brush, previews tile, autotile path, panneaux terrain/path/palette) : en général **première frame** / `primarySource` sur les presets.

### Non couvert dans ce lot (historique)

- Pas de timeline générale, pas d’édition multi-frame riche partout dans l’UI.
- `TileLayer` / triggers : pas d’animation multi-frame côté ces objets (hors scope de ce lot historique).
- *Note post-Runtime 1* : `map_runtime` dispose désormais d’un lecteur + rendu layers — voir lot *map_runtime — Runtime 1*.

### Fichiers touches (resume)

- `map_core`: `project_manifest.dart`, `project_manifest.*.dart`, `visual_frame_json.dart`, `validators.dart`
- `map_editor`: use cases elements/tilesets/terrain presets, `editor_notifier`, `map_canvas`, `path_autotile_set`, `terrain_editor_panel`, `tileset_palette_panel`

---

## 1. Resume du projet
Suite **edition de contenu + format de projet + runtime** pour jeux Pokemon-like / RPG sur grille, en monorepo Flutter/Dart:
- `packages/map_core` — **schemas metier**, validation, JSON, operations pures (cible: consommation par editeur **et** runtime).
- `packages/map_editor` — application desktop **productrice** de contenu (Flutter, Riverpod, use cases, fichiers).
- `packages/map_runtime` — lecteur Flame du même format (**Runtime 1 livré** : chargement projet/map + rendu tile/terrain/path/collision aligné éditeur ; gameplay jouable et entités in-game : à venir).

Pipeline editeur (application):
UI -> `EditorNotifier` -> use cases -> repositories/filesystem -> JSON.

**Priorite immediate:** enrichir et stabiliser le **contenu modelise** dans l editeur de facon **lisible et durable** pour le runtime — le **socle de lecture + affichage map** (`map_runtime` Runtime 1) est en place ; la suite est le **gameplay** et le **rendu entites** in-game.

Note importante:
les tests ne sont pas une priorite pour le moment. Ne pas ajouter de tests ni passer du temps sur la couverture sauf demande explicite.

## 2. Architecture actuelle
- `map_core`: modeles metier, serialization JSON, validation metier, operations pures — **contrat** partage entre editeur et futur runtime.
- `map_editor`: Flutter Desktop, Riverpod, use cases, persistance filesystem, UI — **produit** les donnees conformes a `map_core`.
- `map_runtime`: **Runtime 1** — pipeline `loadRuntimeMapBundle` + `RuntimeMapGame` / `MapLayersComponent` (ordre et sémantique de rendu proches du canvas) ; **à faire** : entités, déplacement, collisions gameplay, warps, dialogues, rencontres, etc.

Toute evolution metier significative doit se demander: *est-ce serialisable, valide dans `map_core`, editable dans l editeur, et interpretable par le runtime sans hack ad hoc ?*

Separations metier explicites:
- Groupes du monde (`ProjectMapGroup`) pour l organisation des maps.
- Dossiers de bibliotheque tilesets (`ProjectTilesetFolder`, `ProjectTilesetEntry.folderId`) pour classer les tilesets dans l explorateur: independants des groupes de maps et des groupes d elements de tileset.
- Groupes internes de tileset (`TilesetElementGroup`) pour organiser la bibliotheque d elements d un tileset.
- Categories d elements (`ProjectElementCategory`) pour classifier la bibliotheque.
- Layers de map (`TileLayer`, `TerrainLayer`, `PathLayer`, `CollisionLayer`, `ObjectLayer`) pour la cible de peinture.
- Affectation des tilesets au niveau `TileLayer.tilesetId` (et non plus au niveau map pour la logique active).

## 3. Fonctionnalites faites
- Ouvrir/sauvegarder projet.
- Gestion du manifest projet.
- Creer/charger/sauvegarder/renommer/supprimer/dupliquer/resize de map.
- Parametres globaux projet (`tileWidth`, `tileHeight`, `displayScale`, `defaultMapWidth`, `defaultMapHeight`).
- **Propriétés de map** (`MapMetadata`) : `displayName`, `mapType` (route/city/building/interior/cave/forest/facility/special/custom), `musicId`, `weather` (none/rain/storm/snow/fog/sandstorm/harshSunlight/custom), `isIndoor`, `allowEscapeRope`, `defaultSpawnId`, `tags` — modèle `map_core` + `UpdateMapMetadataUseCase` + panneau `MapPropertiesPanel` dans l'éditeur.
- **Zones gameplay** : `MapGameplayZone` (id, name, kind, area, priority) avec payloads typés (`EncounterZonePayload`, `MovementZonePayload`, `HazardZonePayload`, `SpecialZonePayload`), dessin drag-to-draw canvas, overlay coloré, `GameplayZonePropertiesPanel` — modèle + UI éditeur complet.
- **Tables de rencontres** : `ProjectEncounterTable` (id, name, encounterKind, tags) + `ProjectEncounterEntry` (speciesId, minLevel, maxLevel, weight) au niveau projet — CRUD use cases + `EncounterTablesPanel` — modèle + UI éditeur complet.
- **Bibliothèque dialogues projet** : `ProjectDialogueEntry` (id, name, relativePath, description, tags, defaultStartNode, folderId) + dossiers hiérarchiques `ProjectDialogueFolder` + CRUD use cases + UI Script Library dans l'explorateur + assignation depuis entities NPC/signe via `DialogueRef`.
- Import tilesets (copie locale + chemin relatif), scope global/groupe, assignation a une `TileLayer`.
- Bibliotheque tilesets hierarchique (dossiers projet):
  - modele `ProjectTilesetFolder` + `folderId` sur `ProjectTilesetEntry`, persistance dans `project.json` (`tilesetFolders`),
  - validation `ProjectValidator`: IDs dossiers uniques, noms non vides, parents valides, pas de cycles, `folderId` tileset coherent,
  - operations pures `buildTilesetLibraryTree`, `flattenTilesetFoldersForPicker`, `tilesetFolderSubtreeIds` dans `map_core`,
  - use cases dedies: creer/renommer/deplacer/supprimer dossier, assigner tileset a un dossier, racine bibliotheque; suppression dossier **refusee** si sous-dossiers ou tilesets presents (message explicite),
  - tri / reorder tilesets par bucket: scope, groupe (si groupe) **et** dossier bibliotheque,
  - UI explorateur: arbre repliable sous TILESETS, actions dossier (menu) et tileset (deplacer vers dossier / racine), import avec choix du dossier cible optionnel,
  - projets anciens sans `tilesetFolders`: chargement OK (liste vide implicite), tilesets a la racine.
- **Package `map_runtime` (Runtime 1)** — lecture disque `project.json` + fichier map, validation `map_core`, resolution tilesets (layers + presets terrain/path), scene Flame avec empilement des layers **aligne** sur `MapGridPainter` ; app `packages/map_runtime/example` pour previsualiser une map ; migrations JSON legacy partagees avec l editeur (`map_core` `legacy_editor_json_compat.dart`).
- Rendu des tile layers sur canvas + peinture tile unitaire et multi-tile.
- Ghost preview map operationnel:
  - preview paint pour tile simple, palette entry et project element,
  - statut visuel valide/invalide selon compatibilite de tileset avec la `TileLayer` active,
  - preview erase dedie avec rendu distinct.
- Outil eraser operationnel:
  - clic + drag,
  - effacement 1x1 sans brush selectionne,
  - effacement multi-tiles base sur la taille du brush courant.
- Resolution commune du brush dans `EditorNotifier`:
  - partagee entre paint, erase et preview,
  - meme logique de pattern/tileset/source rect,
  - aucune emission d erreur au simple hover.
- Systeme de layers operationnel sur map active:
  - ajout / renommage / suppression / reorder (avant/arriere),
  - action "supprimer tous les layers" avec map pouvant rester a zero layer,
  - masquage / affichage,
  - opacite editable,
  - selection de layer active robuste avec fallback coherent (ou `null` si aucun layer).
- Tilesets par layer operationnels:
  - chaque `TileLayer` porte son `tilesetId`,
  - le rendu map gere plusieurs tilesets en parallele selon la pile de layers,
  - la peinture valide le brush contre le tileset de la layer active.
- Panneau `Layers` dedie dans l UI (mode map):
  - liste ordonnee des layers,
  - type (`tile` / `collision` / `object`),
  - selection active,
  - actions directes (move/rename/delete/visibility/opacity/add).
- Bibliotheque d elements projet persistee:
  - categories hierarchiques,
  - elements nommes avec liste de frames visuelles (`frames` ; canvas **entites** = animation multi-frames ; autres usages editeur = souvent premiere frame),
  - scope monde optionnel (`groupId`),
  - layer recommandee optionnelle,
  - tags optionnels.
- Workspace Tileset (menu Tilesets + panneau droit):
  - selection explicite du tileset courant dans l explorateur,
  - affichage image complete du tileset avec grille + scroll,
  - creation d element depuis selection rectangulaire,
  - listing des elements du tileset selectionne.
- Modes de workspace central:
  - mode `map`: le canvas central affiche et edite la map selectionnee,
  - mode `tileset`: le canvas central affiche et edite le tileset selectionne.
- Canvas central polymorphe:
  - `EditorCanvasHost` route vers `MapCanvas` ou `TilesetEditorCanvas` selon le mode,
  - en mode tileset, la map active peut rester en memoire mais n est plus affichee.
- Groupes internes de tileset persistes:
  - modele `TilesetElementGroup` par tileset,
  - sous-groupes via `parentGroupId`,
  - rattachement d un element via `tilesetGroupId`,
  - edition de groupe (create/subgroup/rename) depuis l UI.
- Validation metier etendue:
  - unicite IDs (maps, groupes monde, tilesets, categories, elements),
  - coherence hierarchies (groupes monde, categories, groupes internes tileset),
  - detection de cycles,
  - coherence element -> tileset/category/groupId/tilesetGroupId/frames (sources valides).
- Validation map renforcee (`MapValidator.validate`):
  - checks stricts des champs map (id/name/size),
  - unicite IDs internes (layers/entities/warps/triggers),
  - validation complete des layers (opacity, tailles de grilles, tile IDs non negatifs),
  - validation des positions entites/warps/triggers et des zones de triggers,
- map valide meme avec zero layer (choix explicite de conception pour ce projet).
- Undo/redo map-level operationnel pour la map active:
  - paint/erase tile et pattern,
  - mutations layers (add/rename/delete/delete all/reorder/visibility/opacity),
  - resize map,
  - assignation tileset a la layer active,
  - piles `undo/redo` limitees et coherentes avec l etat dirty,
  - drag paint/erase groupe en une seule entree d historique (stroke).
- Raccourcis clavier desktop operationnels:
  - macOS: `Cmd+Z`, `Cmd+Shift+Z`, `Cmd+Y`,
  - Windows/Linux: `Ctrl+Z`, `Ctrl+Shift+Z`, `Ctrl+Y`,
  - sauvegarde: `Cmd+S` (macOS), `Ctrl+S` (Windows/Linux),
  - raccourcis ignores quand un champ texte est focus.
- Suppression d element projet operationnelle:
  - use case dedie + provider + integration notifier,
  - action UI explicite sur chaque carte d element,
  - nettoyage automatique du brush si l element supprime etait selectionne.
- Refactor structurel engage sur les use cases:
  - extraction de `paint`, `layer`, `map` dans des fichiers dedies:
    - `paint_use_cases.dart`,
    - `layer_use_cases.dart`,
    - `map_use_cases.dart`,
  - `project_use_cases.dart` reste point d entree, avec `part` pour ces blocs.
- Collisions MVP operationnelles:
  - outil `collisionPaint` dedie,
  - `eraser` contextuel: efface les collisions si la layer active est une `CollisionLayer`,
  - paint/erase collision au clic + drag avec regroupement stroke dans l historique,
  - overlay collision visible dans le canvas map (au-dessus des tiles),
  - ghost preview collision paint/erase distinct du preview tile.
- Terrains/Sols/Surfaces refactores et operationnels:
  - separation metier nette:
    - `TerrainLayer` = fond uniquement,
    - `PathLayer` = surfaces specialisees posees au-dessus.
  - `TerrainType` recentre sur les fonds:
    - `grass`,
    - `dirt`,
    - `sand`,
    - `rock`,
    - `stone`,
    - `indoor`,
    - `none`.
  - `PathSurfaceKind` porte les surfaces gameplay/editor:
    - `path`,
    - `road`,
    - `water`,
    - `tallGrass`,
    - `ice`,
    - `lava`,
    - `swamp`,
    - `rails`,
    - `bridge`,
    - `special`,
    - `custom`.
  - `tallGrass`, `water` et `ice` ne sont plus traitees comme des terrains.
  - `map_core` porte les operations pures terrain/path, la validation et la serialisation JSON.
  - `PathLayer` metier stable dans `map_core` avec:
    - `presetId`,
    - grille logique `cells`,
    - `properties` arbitraires `String -> String`.
  - validation metier et resize map etendus a `TerrainLayer` et `PathLayer`.
  - paint/erase terrain et path integres au pipeline map-level avec undo/redo.
  - rendu editor stabilise:
    - terrain d abord,
    - path ensuite,
    - tiles au-dessus,
    - aucune transparence appliquee aux layers de map.
  - les terrains ne passent jamais au-dessus des paths au rendu.
  - le footprint terrain reste volontairement en 1x1 pour eviter les heritages de taille de brush.
- Presets terrain/path refondus:
  - `ProjectManifest` distingue maintenant:
    - `terrainPresets`,
    - `pathPresets`,
    - `terrainCategories`,
    - `pathCategories`.
  - modeles metier:
    - `ProjectTerrainPreset`,
    - `TerrainPresetVariant`,
    - `ProjectPathPreset`,
    - `PathPresetVariantMapping`,
    - `ProjectPresetCategory`.
  - categories terrain/path separees avec hierarchie visible (`parentCategoryId`).
  - aucun preset ni dossier terrain/path n est injecte automatiquement a la creation/au chargement du projet.
  - use cases dedies:
    - create/update/delete terrain preset,
    - create/update/delete path preset,
    - create/rename/delete categories terrain/path.
  - validation metier etendue:
    - unicite des IDs,
    - coherence des hierarchies de categories,
    - coherence preset -> categorie,
    - coherence des tilesets references,
    - variants terrain valides,
    - unicite des mappings de variantes path.
  - separation stricte des tilesets entre presets terrain et presets path.
  - migration legacy limitee:
    - support des anciens champs de categories,
    - cassure assumee pour les anciens terrains qui representaient en realite des surfaces.
- UI terrain/path refaite:
  - panneau gauche `Surface Library` transforme en vraie bibliotheque hierarchique visible:
    - racine `Terrains`,
    - racine `Paths`,
    - sections racines pliables/depliables pour reduire l encombrement,
    - dossiers et sous-dossiers repliables,
    - presets visibles dans l arborescence,
    - distinctions visuelles nettes entre fond et surface.
  - fiche de preset enrichie:
    - metadonnees du preset,
    - apercu du tileset,
    - action `Edit Preset`,
    - action `Edit Sprites` pour les terrains,
    - action `Edit Mapping` pour les paths,
    - bloc `Selected Preset` repliable.
  - edition visuelle restauree:
    - variantes terrain editables par selection rectangulaire dans le tileset,
    - mappings autotile path editables dans un editeur visuel dedie.
  - panneau map de droite `TerrainMapPanel` clarifie:
    - bloc `Base Ground`,
    - bloc `Surface Overlays`,
    - selection de la `TerrainLayer` active,
    - selection de la `PathLayer` active,
    - affectation du preset path a la layer,
    - creation rapide d une nouvelle `PathLayer`.
  - edition de presets possible sans map active.
- Warps MVP operationnels:
  - operations pures `map_core` dediees (`add/update/remove`) avec validations metier explicites,
  - use cases + providers Riverpod dedies dans `map_editor`,
  - outil `warpPlacement` branche dans la toolbar et le canvas map,
  - clic en mode warp:
    - selection d un warp existant sur la cellule,
    - sinon creation d un warp valide (`targetMapId = map active`, `targetPos = pos`),
  - rendu overlay des warps dans `MapGridPainter` avec distinction du warp selectionne,
  - validation inter-map cote editor sur existence de `targetMapId` dans le `ProjectManifest`,
  - panneau `WarpPropertiesPanel` (liste, selection, edition `id/targetMapId/targetPos`, suppression) avec picker de map cible et resume destination,
  - action `Create Return Warp`:
    - creation assistee d un warp retour dans la map cible,
    - refuse la creation si un warp existe deja sur la case destination cible,
    - gere le cas same-map sans dupliquer le pipeline de mutation,
  - integration complete dans le pipeline map-level (`_applyMapMutation`) avec undo/redo et dirty state.
- Connexions inter-maps operationnelles:
  - nouveau modele metier `MapConnection` dans `map_core` avec:
    - `direction` (`north`, `south`, `east`, `west`),
    - `targetMapId`,
    - `offset`,
    - stockage dans `MapData.connections`.
  - operations pures dediees:
    - recherche de connexion,
    - ajout/mise a jour par direction,
    - suppression,
    - calcul d overlap de bord entre maps.
  - validation metier locale:
    - une seule connexion par direction,
    - pas de cible vide,
    - pas d auto-connexion.
  - validation editor croisee:
    - map cible existante,
    - overlap de bord non nul selon la taille des maps et l offset,
    - verification simple de coherence avec la connexion inverse si elle existe deja.
  - use cases + service dedies dans `map_editor`:
    - create/update/delete connection,
    - resolution de map cible,
    - navigation rapide vers la map connectee.
  - panneau droit `MapConnectionsPanel` dedie:
    - 4 cotes explicites,
    - choix de la map cible,
    - edition de l offset,
    - actions `Set/Save`, `Open`, `Remove`.
  - feedback visuel sur le canvas map:
    - badges de bord pour les connexions presentes,
    - nom de la map cible visible directement sur la map active.
- Triggers MVP operationnels:
  - modele metier `MapTrigger` refondu dans `map_core` avec:
    - `id`,
    - `name`,
    - `type`,
    - `area` rectangulaire,
    - `properties` cle/valeur.
  - enum `TriggerType` recentre sur les cas editor/gameplay:
    - `warp`,
    - `message`,
    - `interaction`,
    - `event`,
    - `spawn`,
    - `camera`,
    - `custom`.
  - operations pures dediees:
    - recherche par ID,
    - recherche a une position,
    - ajout,
    - update,
    - move,
    - resize,
    - suppression.
  - validation metier explicite:
    - ID non vide,
    - unicite des IDs dans la map,
    - zone positive,
    - zone entierement dans la map,
    - cles de proprietes non vides.
  - use cases + coordinator + service dedies dans `map_editor`.
  - outil `triggerPlacement` branche dans la toolbar et le canvas map.
  - clic en mode trigger:
    - selection d un trigger existant sous le curseur,
    - sinon creation d un trigger 1x1 par defaut.
  - overlay canvas lisible avec zone coloree, bordure et label.
  - panneau droit `TriggerPropertiesPanel` dedie:
    - liste,
    - selection,
    - edition `id/name/type/x/y/width/height`,
    - edition des proprietes cle/valeur,
    - suppression.
  - integration complete au pipeline map-level:
    - undo,
    - redo,
    - dirty state,
    - sauvegarde/reload JSON.
- Entites de map MVP operationnelles:
  - modele metier `MapEntity` renforce dans `map_core` avec:
    - `id`,
    - `name`,
    - `kind`,
    - `pos`,
    - `size`,
    - `properties` cle/valeur.
  - enum `MapEntityKind` recentre sur le contenu visible Pokemon-like:
    - `npc`,
    - `sign`,
    - `item`,
    - `spawn`,
    - `custom`.
  - distinction metier explicite entre:
    - `Trigger` = zone logique,
    - `Entity` = contenu visible pose sur la map.
  - operations pures dediees:
    - recherche par ID,
    - recherche a une position,
    - ajout,
    - update,
    - move,
    - resize,
    - suppression.
  - validation metier explicite:
    - ID non vide,
    - unicite des IDs dans la map,
    - taille positive,
    - zone entiere de l entite dans les bornes de la map,
    - cles de proprietes non vides.
  - migration legacy map:
    - ancien champ `type` migre vers `kind`,
    - `monster` migre vers `npc`,
    - `chest` migre vers `item`,
    - normalisation des proprietes en `String -> String`,
    - taille par defaut `1x1`.
  - use cases + coordinator + service dedies dans `map_editor`.
  - outil `entityPlacement` branche dans la toolbar et le canvas map.
  - clic en mode entity:
    - selection d une entite existante sous le curseur,
    - sinon creation d une entite 1x1 du type actuellement choisi.
  - selection du type de pose visible:
    - depuis la toolbar,
    - depuis le panneau de proprietes.
  - overlay canvas lisible:
    - zone coloree par type,
    - bordure plus forte pour l entite selectionnee,
    - badge court (`NPC`, `SIGN`, `ITEM`, `SPAWN`, `CUSTOM`),
    - label nom/id si la place est suffisante.
  - panneau droit `EntityPropertiesPanel` dedie:
    - liste des entites de la map,
    - selection,
    - edition `id/name/kind/x/y/width/height`,
    - edition des proprietes cle/valeur,
    - suppression.
  - integration complete au pipeline map-level:
    - undo,
    - redo,
    - dirty state,
    - sauvegarde/reload JSON.
- Inspector map de droite refactorise:
  - sections pliables/depliables pour reduire l encombrement,
  - affichage contextuel selon la layer active,
  - panneau `Tiles & Elements` masque hors contexte tile,
  - panneau `Ground & Surfaces` masque hors contexte terrain/path,
  - sections map-level (`Map Entities`, `Connections`, `Triggers`, `Warps`) gardees accessibles mais compactes.

## 4. Fonctionnalites partiellement faites
- Gestion multi-tilesets: fonctionnelle mais UX de tri/recherche encore simple.
- Edition palette brute tiles + bibliotheque elements: coexistent, rationalisation UX restante.
- Systeme de layers: base edition/rendu solide, mais edition avancee (locks/groupes/layers specialisees Pokemon) non implementee.
- Collisions: base MVP solide (bool paint/erase/overlay/preview), types de collisions et comportements de sol non implementes.
- Terrains/Sols: base forte (paint/erase + path auto-connecte + presets visuels terrains/paths + stabilisation bords/rendu + debut de separation `TerrainLayer`/`PathLayer`), migration complete du legacy `TerrainType.path` et comportements gameplay/runtime non implementes.
- Warps: edition utile avec validation inter-map + picker map cible + resume destination texte + creation assistee d un warp retour; lien persistant bidirectionnel et visualisation graphique de destination non implementes.
- Connexions inter-maps: base metier/editor solide (modele, validation, panneau dedie, preview canvas, jump rapide), mais pas encore de creation assistee de connexion inverse, pas encore de vue monde globale et pas encore de preview de continuite graphique avancee.
- Triggers: base MVP solide (pose, selection, edition zone/type/proprietes, overlay, undo/redo), mais pas encore de drag-create de zone, pas encore d UI specialisee par type et pas encore de runtime/evenements.
- Entites de map: payloads typés + inspector par type + `DialogueRef` + **visuel canvas** via `editorVisual` → `ProjectElementEntry` (animation multi-frames) ; **pas encore** de rendu de ces sprites dans `map_runtime` ni adaptation auto au resize map côté gameplay.
- Zones gameplay + tables de rencontres : **modèle + UI éditeur complets** (zones avec payloads typés, tables espèces/niveaux/poids, drag-to-draw, panels dédiés) ; **runtime rencontre** (déclenchement, logique combat, taux d’apparition actifs) non livré.
- Dialogues : **registre projet + dossiers + UI bibliothèque + assignation NPC/signe** livrés ; **exécution runtime** (résolution `DialogueRef`, chargement Yarn, VM dialogue) non livrée ; pas d’éditeur narratif graphique intégré.
- Dresseurs : **modèle + UI éditeur livrés** (`ProjectTrainerEntry` + `ProjectTrainerPokemonEntry` dans `map_core`, Trainer Library panel, champs battle dans l’inspecteur NPC : `trainerId`, `lineOfSightRange`, `defeatDialogueRef`) ; **runtime non livré** (déclenchement combat, IA, défaite).
- Propriétés de map : **base livrée** (`MapMetadata` : nom, type, musique, météo, indoor, escape rope, spawn, tags — modèle + UI panel) ; **avancées non livrées** : hooks gameplay, flags de progression, restrictions d’accès, logique conditionnelle runtime sur ces flags.
- Inspector map de droite: base bien plus lisible (accordeons + filtrage contextuel), mais pas encore d inspector specialise pour collisions/objets ni de personnalisation de layout par utilisateur.
- Elements contextuels monde: resolution de base ok, pas encore de modes avances configurables.
- Workspace tileset: suppression/reorder des groupes internes non implementes.
- Interaction selection vs scroll dans le canvas tileset: base solide, raffinements UX possibles.
- Dirty state: operationnel sur les flux principaux, a homogeniser.
- Runtime Flame: **Runtime 1** (chargement + affichage map) livré via package + exemple ; preview in-game **dans l’éditeur** et **gameplay** non livrés.

## 5. Fonctionnalites non faites

### Blocs produits centraux encore absents ou tres incomplets

Ces themes sont **structurants** pour la vision « contenu riche + runtime standard »; ils completent les lacunes editoriales deja listees ailleurs.

- **Dialogues — exécution runtime** : résolution `DialogueRef` → fichiers Yarn, chargement VM Yarn Spinner (ou équivalent), exécution in-game des scripts, branchements conditionnels, progression d’histoire — **aucune** dépendance moteur dans `map_core` (intentionnel) ; intégration runtime à brancher dans `map_runtime` via adaptateur infra. *(Côté éditeur : registre, dossiers, UI bibliothèque, assignation NPC/signe — livrés.)*
- **Dialogues — éditeur narratif riche** : éditeur Yarn intégré dans l’outil (timeline, nœuds visuels, préview dialogue) — pas encore fait ; la bibliothèque gère les fichiers et les références, pas l’édition ligne à ligne du contenu Yarn.
- **Rencontres — runtime** : déclenchement de rencontre selon zone et table, calcul du taux d’apparition actif, sélection espèce/niveau, transition vers combat — pas fait. *(Côté éditeur : zones gameplay `EncounterZonePayload` + tables `ProjectEncounterTable` + UI complète — livrés.)*
- **Dresseurs / equipes PNJ**: donnees d equipe, IA basique ou scriptee, declencheurs — modele + UI + runtime.
- **Propriétés de map avancées** : hooks gameplay (script déclenchés à l’entrée/sortie de map), flags de progression conditionnels, restrictions d’accès (ex. badge requis), logique runtime sur ces flags — pas fait. *(Côté éditeur : propriétés de base `MapMetadata` : nom, type, musique, météo, indoor, escape rope, spawn, tags — livrés.)*
- **Runtime standard** (`map_runtime`): **partiel** — lecteur projet + map + rendu layers (**Runtime 1**) ; manquent encore boucle exploration, collisions/warps/triggers **actifs**, **entités** à l’écran, dialogues, rencontres, tels que prescrits par `map_core` pour un jeu complet.
- **Comportements Pokemon-like standard**: interaction PNJ, ramassage objet, panneaux, spawns joueur, transitions de map, base inventaire / progression si le scope le requiert — en coherence avec les schemas.

### Lacunes editoriales et outillage (deja identifiees, toujours valides)

- Edition avancee des layers (locks/groupes/presets/layers specialisees).
- Outils avances map (fill/selection rect map/copy-paste).
- Undo/redo global projet (au-dela de la map active).
- Collisions avancees (types/comportements).
- Entites: preview canvas via `editorVisual` → `ProjectElementEntry.frames` (**animation légère canvas** livrée) ; restent: catalogues d’objets dédiés, affinage gameplay au-delà des payloads actuels, interprétation runtime (animation jeu / facing / états).
- Triggers avances (UI specialisee par type, drag-create de zone, logique evenementielle, runtime).
- Warps avances (lien persistant bidirectionnel, edition/synchronisation de paires, visualisation graphique de destination).
- Inspector de proprietes complet sur tous les objets.
- Preview runtime in-game integree a l editeur (optionnel) ; en attendant, **app separee** `packages/map_runtime/example` permet de charger projet + map (**Runtime 1**).
- Gestion assets projet au-dela des tilesets.

## 6. Tache en cours

### Phase actuelle (alignee vision produit)

**Zones gameplay + tables de rencontres**: lot livré (2026-03-25). `MapGameplayZone` sur map + `ProjectEncounterTable` au niveau projet, éditeur complet (overlay canvas, panels, toolbar, inspector).

**Animation canvas entités** (2026-03-24): lot livré — tick léger + `resolveEntityElementVisualForEditor` / `ProjectElementEntry.frames` uniquement.

**map_runtime Runtime 1** (2026-03-26): lot livré — lecture `project.json` + map, résolution tilesets (layers + presets terrain/path), scène Flame + exemple desktop ; parité d’empilement des couches avec `MapGridPainter`.

**map_runtime Runtime 2 — visualiseur entités** (2026-03-26): lot livré — rendu sprites entités (`_paintEntities`) via `ProjectElementEntry.frames` (même source que l’éditeur) ; animation frame `_animElapsed` ; aspect-ratio preserving centré ; collecte tilesets entités (`addEntityVisualTilesetIds`) ; recadrage `map_runtime` comme **visualiseur read-only**. (Les doc-comments ajoutés dans ce lot ont été supprimés dans Runtime 3.)

**map_runtime Runtime 3 — API publique propre + README** (2026-03-26): lot livré — package-maintainer pass complet :
- Barrel réduit à **3 noms publics** via `show` : `loadRuntimeMapBundle`, `RuntimeMapBundle`, `RuntimeMapGame` ; 7 fonctions internes retirées de l’API publique.
- `RuntimeMapGame` : suppression du paramètre `tileImagesByTilesetId` — chargement images internalisé dans `onLoad()`.
- `loadRuntimeMapBundle` : renommage `manifestPath` → `projectFilePath`.
- `pubspec.yaml` : suppression `publish_to: none`, suppression `uses-material-design: true`, description précise, `topics`, `repository`.
- Tous les `///` doc-comments supprimés des sources (barrel, `RuntimeMapGame`, `RuntimeMapBundle`, `MapLayersComponent`, `runtime_manifest_tilesets`).
- `README.md` réécrit : positionnement, ce que fait / ne fait pas le package, usage minimal, API publique tabulée, exceptions, limites, note `map_core` path-dep.
- API finale : `final bundle = await loadRuntimeMapBundle(projectFilePath: ‘...’, mapId: ‘...’); final game = RuntimeMapGame(bundle: bundle);`
- Limite pub.dev : `map_core` est une dépendance locale (`path:`), à publier séparément avant publication sur pub.dev.

**map_gameplay — Socle exploration** (2026-03-26): lot livré — package pur Dart `packages/map_gameplay` :
- `Direction` (enum N/S/E/O) + extensions `dx/dy/asFacing` et `EntityFacingX.asDirection`
- `GameplayPlayerState` (pos `GridPos` + facing `Direction`)
- `GameplayWorldState` : cache collision + lookup warp ; factories `initial` et `fromMap` ; `isBlocked`, `warpAt`, `withPlayer`
- `GameplayIntent` (sealed) : `MoveIntent(Direction)`
- `GameplayStepResult` (sealed) : `Moved`, `Blocked`, `WarpTriggered(TriggeredWarp)`
- `stepGameplayWorld(world, intent) → GameplayStepResult`
- Aucune dépendance Flame ni Flutter — pur Dart + `map_core`

**map_gameplay — Spawn joueur** (2026-03-26): lot livré :
- `GameplaySpawnResolutionException` : erreur métier dédiée à la résolution du spawn
- `resolveInitialPlayerSpawn(MapData) → GameplayPlayerState` : résolution en 3 cas par priorité stricte :
  1. `map.mapMetadata.defaultSpawnId` → cherche l'entité par id, vérifie kind=spawn, convertit `EntityFacing → Direction`
  2. Fallback : entités `kind=spawn` + `role=playerStart`, triées par id (déterministe), première retenue
  3. Aucun spawn valide → `GameplaySpawnResolutionException`
- `GameplayWorldState.fromMap(MapData)` : appelle `resolveInitialPlayerSpawn`, construit le monde, vérifie que la case spawn n'est pas bloquée (sinon exception)
- Facing : utilise le facing de l'entité spawn s'il est disponible ; fallback `Direction.south`

**Prochaines priorités immédiates:**

- **`map_gameplay`** : intégration Flame (component joueur, game loop) ; `InteractIntent` (NPC/signe) ; connexions entre maps.
- **Entités (éditeur)** : catalogues objets ; affinage gameplay NPC/item/spawn.
- **Dialogues**: poursuite intégration Yarn — résolution `DialogueRef` côté runtime.
- **Dresseurs / équipes**: à brancher côté runtime `map_gameplay`.

### Référence historique (lots déjà livrés)

- **map_runtime Runtime 1 + parité rendu** : voir lot dédié en tête de document (après animation entités).
- **Zones gameplay + tables de rencontres**: `MapGameplayZone`, `ProjectEncounterTable`, overlay canvas, panels — voir lot ci-dessus.
- **Entités structurées + DialogueRef**: payloads typés, `DialogueRef`, inspector contextuel — voir lot précédent.
- **Visuel entités éditeur**: `MapEntityEditorVisual`, rendu canvas (élément projet / fallback), inspector — voir lot historique.
- **Animation canvas entités**: `ProjectElementEntry.frames` + timer éditeur — voir lot en tête de document.

### Suite directe (hors scope de cette section detaillee)

Voir **8. Prochaines etapes recommandees** (decoupage **editor court terme** / **runtime moyen terme**).

## 7. Dernieres modifications realisees
2026-03-26 (map_runtime **Runtime 1** + parité rendu + exemple + `map_core` JSON legacy partagé):
- `map_core`: nouveau `lib/src/io/legacy_editor_json_compat.dart` (`migrateProjectManifestJson`, `migrateMapDataJson`) ; export dans `map_core.dart`.
- `map_editor`: `file_repositories.dart` délègue les migrations à `map_core`.
- `map_runtime`: pipeline `loadRuntimeMapBundle`, `RuntimeMapBundle`, `collectAllRuntimeTilesetIds`, `RuntimeMapGame`, `MapLayersComponent` (ordre terrain → path → tile → collision ; presets terrain + autotile path), `RuntimePathAutotileSet`, `tile_image_loader` ; `example/map_runtime_example` (Flutter desktop) ; entitlements macOS **sans** App Sandbox pour chemins absolus dev ; `pubspec` (`path`, `flame`) ; suppression de l’ancien `map_runtime_base.dart`.
- `map_runtime` `example` (suite UX) : choix de `project.json` via **`file_picker`** (bouton **Parcourir…**) au lieu d’un champ chemin manuel.
- `PROJECT_STATUS.md`: cette mise à jour (phases, lots, sections 4–7, checklist, mini-tableaux).

2026-03-24 (animation legere entites canvas — `ProjectElementEntry.frames`):
- `map_editor`: `entity_editor_element_visual.dart` — `entityEditorPickFrame`, `resolveEntityElementVisualForEditor`, `mapEntitiesNeedEditorFrameAnimation`, `collectTilesetIdsForEntityEditorVisuals` (toutes les frames) ; `map_canvas.dart` — timer ~110 ms conditionnel, `editorEntityAnimationMs` → `MapGridPainter`, `shouldRepaint` ; `entity_properties_panel.dart` — tooltip.
- `map_core`: commentaire `ProjectElementEntry.frames` (canvas entites vs premiere frame ailleurs) + regen Freezed si necessaire.
- `PROJECT_STATUS.md`: nouveau lot + sections 5/6/7/tableau Phase 1 alignes.

2026-03-25–26 (visuel entites editeur — Entity Visual Presentation + consolidation):
- `map_core`: `MapEntityEditorVisual`, champ `MapEntity.editorVisual`, extension `MapEntityProjectElementVisualX` (`canonicalEditorVisualProjectElementId` / `legacyNpcVisualProjectElementId` / `resolvedProjectElementIdForEditor`), `assertEntityEditorVisualAgainstProject`, parametre `editorVisual` sur `updateEntityOnMap`.
- `map_editor`: service `entity_editor_element_visual.dart`, `MapCanvas` / `MapGridPainter`, `EntityPropertiesPanel`, filiere `editorVisual` jusqu a `EditorNotifier`.
- **2026-03-26**: recadrage doc + code — pas de systeme visuel parallele ; libelles UI alignes sur `ProjectElementEntry` ; `PROJECT_STATUS` synchronise.

2026-03-25 (zones gameplay + tables de rencontres — domaine + editor complet):
- `map_core`: nouveaux enums `GameplayZoneKind`/`MovementMode`/`EncounterKind`; modele `MapGameplayZone` sur `MapData`; modeles `ProjectEncounterEntry`/`ProjectEncounterTable` sur `ProjectManifest`; operations CRUD `map_gameplay_zones.dart`; validation `ProjectValidator` et `MapValidator`.
- `map_editor`: `GameplayZoneEditingCoordinator` + `GameplayZoneEditingService` + 9 use cases (3 map-level + 6 projet); providers Riverpod; `EditorState.selectedGameplayZoneId` + outil `gameplayZonePlacement`; `EditorNotifier` (7 methodes zones + 6 methodes tables); overlay canvas coloré par kind; `GameplayZonePropertiesPanel` + `EncounterTablesPanel`; sections inspector + bouton toolbar.

2026-03-25 (documentation — renforcement recadrage + coherence documentaire):
- **Tableau de bord des phases** ajoute dans la section Vision produit (etat factuel des 3 phases avec colonnes claires).
- **Sections lots recents** renommees (`## Lot:` / `## Lot precedent:`) pour ne plus perturber la numerotation principale; note introductive ajoutee.
- **Section "Structure du document"** remplace "Lecture du reste du document" : plus directive, liste les sections par role.
- **Checklist enrichie**: ajout des blocs produits manquants (DialogueRef partiel, dialogues, rencontres, dresseurs, proprietes map, items runtime: lecteur projet, scene jouable, deplacement/warps, interactions, dialogues runtime, rencontres, comportement Pokemon-like).
- **Mini tableau priorites** restructure en deux tableaux distincts (Phase 1 editorial / Phase 2 runtime) avec etat factuel par chantier.

2026-03-24 (documentation — recadrage **Vision produit**):
- Ajout section **Vision produit** en tete du document (priorites: editeur de contenu riche -> runtime standard -> couches haut niveau plus tard).
- Reecriture **1. Resume**, enrichissement **2. Architecture**, restructuration **5 / 6 / 8 / 9** et **Mini tableau priorites** pour alignement editor/runtime; conservation de l historique technique existant.

2026-03-24 (entites structurees + inspector contextuel + correctif `updateEntityOnMap`):
- `map_core` `map_entities.dart`:
  - `mapEntityTypedPayloadUnset` et parametres optionnels typés sur `updateEntityOnMap` avec fusion correcte avant `_normalizeEntity` / coercition par `kind`.
- `map_editor`:
  - `entity_use_cases.dart`: passage des payloads avec sentinelle `?? mapEntityTypedPayloadUnset`.
  - `entity_properties_panel.dart`: formulaires par type (NPC, sign, item, spawn, custom), champs `DialogueRef`, validation chemin script, fingerprint de sync incluant JSON des blocs typés.
  - `map_canvas.dart`: libelle d entite via `inspectorHeadline`.

2026-03-24 (entites de map MVP - contenu gameplay visible):
- `map_core`:
  - refonte de `MapEntity`:
    - ajout `name`,
    - remplacement de `type` par `kind`,
    - ajout `size`,
    - normalisation des proprietes en `Map<String, String>`.
  - nouvel enum `MapEntityKind`:
    - `npc`,
    - `sign`,
    - `item`,
    - `spawn`,
    - `custom`.
  - ajout `src/operations/map_entities.dart`:
    - `findEntityById`,
    - `findEntityAtPos`,
    - `addEntityToMap`,
    - `updateEntityOnMap`,
    - `moveEntityOnMap`,
    - `resizeEntityOnMap`,
    - `removeEntityFromMap`.
  - validation map renforcee pour les entites:
    - taille positive,
    - zone en bornes,
    - cles de proprietes non vides.
- `map_editor/application`:
  - ajout:
    - `entity_use_cases.dart`,
    - `entity_editing_coordinator.dart`,
    - `entity_editing_service.dart`.
  - providers Riverpod dedies pour les use cases/coordinator/service.
  - integration de `selectedEntityId` dans:
    - session map,
    - snapshot historique,
    - mutation coordinator,
    - undo/redo map-level.
- `map_editor/features/editor/state`:
  - ajout `selectedEntityKind` et `selectedEntityId` dans `EditorState`.
  - `EditorNotifier` etendu avec:
    - `getSelectedEntity`,
    - `placeOrSelectEntityAt`,
    - `addEntityAt`,
    - `selectEntity`,
    - `selectEntityKind`,
    - `updateSelectedEntity`,
    - `updateEntity`,
    - `deleteSelectedEntity`,
    - `deleteEntity`.
- `map_editor/ui`:
  - toolbar:
    - ajout de l outil `Entity Tool`,
    - picker du type d entite courant.
  - canvas map:
    - creation/selection par clic en mode entity,
    - overlay colore par type,
    - mise en evidence de l entite selectionnee.
  - inspector map:
    - nouvelle section `Map Entities`.
  - ajout `EntityPropertiesPanel`:
    - choix du type a poser,
    - liste des entites,
    - edition generique des proprietes.
- `infrastructure`:
  - migration legacy des entites JSON vers le nouveau schema (`kind`, `size`, proprietes stringifiees).

2026-03-23 (refacto clean architecture - erreurs applicatives + vrai split des use cases + mutation map):
- `map_editor`:
  - ajout `application/errors/application_errors.dart`:
    - introduction d une hierarchie d erreurs applicatives explicites:
      - `EditorValidationException`,
      - `EditorNotFoundException`,
      - `EditorConflictException`,
      - `EditorInvalidOperationException`,
      - `EditorMissingDependencyException`,
      - `EditorPersistenceException`.
    - objectif: supprimer les `throw Exception(...)` generiques dans la couche application.
  - suppression du faux monolithe `application/use_cases/project_use_cases.dart`.
  - ajout d un vrai decoupage par domaine dans `application/use_cases/`:
    - `project_management_use_cases.dart`,
    - `project_tileset_use_cases.dart`,
    - `project_element_use_cases.dart`,
    - `project_group_use_cases.dart`,
    - `map_use_cases.dart`,
    - `layer_use_cases.dart`,
    - `paint_use_cases.dart`,
    - `collision_use_cases.dart`,
    - `terrain_use_cases.dart`,
    - `terrain_preset_use_cases.dart`,
    - `warp_use_cases.dart`,
    - `project_use_case_support.dart`,
    - `use_cases.dart` comme barrel d export uniquement.
  - conversion des anciens fichiers `part of` en vraies unites autonomes avec imports explicites.
  - remplacement des `Exception` generiques dans les use cases terrain/path/tilesets/elements/maps/warps/layers par des erreurs applicatives explicites.
  - ajout `application/models/`:
    - `map_history_snapshot.dart`,
    - `path_autotile_set.dart`,
    - `map_tool_preview.dart`.
    - objectif:
      - sortir les modeles editor-facing des `features`,
      - supprimer les dependances `application -> features`.
  - suppression de l import `application -> features` dans:
    - `MapHistoryCoordinator`,
    - `PathAutotileResolver`.
  - ajout `application/services/editor_map_mutation_coordinator.dart`:
    - centralise l orchestration map-level autour de:
      - begin stroke,
      - finalize stroke,
      - apply mutation,
      - undo,
      - redo,
      - re-synchronisation session/historique/dirty state.
  - `app/providers/use_case_providers.dart`:
    - ajout du provider `editorMapMutationCoordinatorProvider`,
    - imports alignes sur les nouveaux fichiers de use cases reellement separes.
  - `EditorNotifier`:
    - delegation du pipeline map-level au `EditorMapMutationCoordinator`,
    - retrait des types `MapToolPreview*` du notifier,
    - remplacement des `StateError` locaux par des erreurs applicatives explicites sur les presets introuvables,
    - `EditorState` ne stocke plus de service `ProjectWorkspace`: seul `projectRootPath` reste dans le state, et le workspace est resolu a la demande via la factory injectee.
  - `ui/canvas/map_canvas.dart`:
    - utilise maintenant les modeles applicatifs `MapToolPreview` et `PathAutotileSet` au lieu de types definis dans les `features`.
  - `infrastructure/filesystem/project_filesystem.dart`:
    - remplacement du `throw Exception(...)` restant par `FileSystemException`.
- impact:
  - la couche application ne depend plus des `features`,
  - le faux monolithe des use cases a ete remplace par un vrai decoupage lisible,
  - `EditorNotifier` perd une partie importante de la logique historique/mutation map-level,
  - les erreurs applicatives sont bien plus explicites dans les flux editor.

2026-03-23 (refacto clean architecture - lot 1 ports workspace):
- `map_editor`:
  - ajout `application/ports/project_workspace.dart`:
    - introduction des abstractions `ProjectWorkspace` et `ProjectWorkspaceFactory`,
    - objectif: supprimer la dependance directe de la couche application vers `ProjectFileSystem`.
  - `infrastructure/filesystem/project_filesystem.dart`:
    - `ProjectFileSystem` implemente maintenant `ProjectWorkspace`,
    - ajout `FileProjectWorkspaceFactory` comme implementation infrastructure du port de creation.
  - `app/providers/core_providers.dart`:
    - ajout du provider `projectWorkspaceFactoryProvider` pour injecter la factory infrastructure depuis la composition root.
  - `application/use_cases/*`:
    - remplacement des signatures `ProjectFileSystem` par `ProjectWorkspace` dans les use cases projet/map/terrain preset/warp,
    - `CreateProjectUseCase` depend maintenant de `ProjectWorkspaceFactory` au lieu d instancier directement `ProjectFileSystem`.
  - `application/services/warp_editing_service.dart`:
    - depend maintenant du port `ProjectWorkspace` plutot que de l implementation infrastructure concrete.
  - `features/editor/state/editor_state.dart`:
    - remplacement de `fileSystem` par un handle de workspace abstrait pour retirer la fuite d infrastructure dans l etat editor.
  - `features/editor/state/editor_notifier.dart`:
    - creation/chargement de workspace via `ProjectWorkspaceFactory`,
    - migration de tous les usages de `state.fileSystem` vers le port `ProjectWorkspace`.
  - `ui/shared/top_toolbar.dart`:
    - aligne sur le contexte de workspace courant.
- impact:
  - la couche application ne reference plus directement `ProjectFileSystem`,
  - l etat editor ne reference plus un type d infrastructure concret,
  - la direction de dependance est plus propre: ports applicatifs -> implementations infrastructure.

2026-03-23 (refacto clean architecture - injection services + orchestration warp):
- `map_editor`:
  - `app/providers/use_case_providers.dart`:
    - ajout de providers Riverpod pour les services/coordinators editor:
      - `TerrainPresetResolver`,
      - `TerrainPresetSelectionCoordinator`,
      - `PathAutotileResolver`,
      - `EditorMapSessionCoordinator`,
      - `MapHistoryCoordinator`,
      - `WarpEditingCoordinator`,
      - `TerrainPaintingCoordinator`,
      - `WarpEditingService`.
    - objectif: supprimer la construction locale/statique de dependances dans `EditorNotifier`.
  - ajout `application/services/warp_editing_service.dart`:
    - orchestration applicative warp:
      - selection/recherche warp,
      - creation warp par defaut via coordinator + validation cible projet,
      - update/delete warp,
      - creation reciprocal warp.
    - retourne des resultats applicatifs explicites (`WarpCreationResult`, `WarpUpdateResult`) pour simplifier le notifier.
  - `features/editor/state/editor_notifier.dart`:
    - migration vers l injection via providers (plus de singletons statiques ni de construction locale `TerrainPaintingCoordinator`),
    - delegation des flux warp au `WarpEditingService`,
    - suppression de helpers notifier redondants de session map (`_resolveActiveLayerId`, `_resolveFallbackLayerIdAfterDeletion`, `_resolveSelectedTilesetIdForMap`),
    - usage direct du `EditorMapSessionCoordinator` aux call sites.
  - `application/use_cases/warp_use_cases.dart`:
    - conversion des `Exception` generiques en `ValidationException` sur les validations cross-map warp.
  - `application/use_cases/project_use_cases.dart` + `map_use_cases.dart`:
    - suppression des `debugPrint` de bruit technique dans les use cases.
- impact:
  - `EditorNotifier` est plus fin: orchestration d etat + delegations explicites,
  - la feature warp suit maintenant un pattern applicatif reutilisable pour triggers/NPC/objets,
  - dependances applicatives homogenes via Riverpod.

2026-03-23 (refacto cible clean architecture - session map/historique/warp):
- `map_editor`:
  - ajout `application/services/editor_map_session_coordinator.dart`:
    - centralise la resolution de session map:
      - `activeLayerId`,
      - `selectedWarpId`,
      - `selectedTilesetEditorId`,
      - fallback apres suppression de layer.
  - ajout `application/services/map_history_coordinator.dart`:
    - centralise la mecanique d historique map-level:
      - begin/finalize stroke,
      - application mutation historique (undo stack / redo stack / stroke start),
      - undo/redo restore,
      - push snapshot avec dedup + limite d entree.
  - ajout `application/services/warp_editing_coordinator.dart`:
    - centralise les helpers warp utilitaires:
      - recherche par id/position,
      - generation id unique,
      - creation warp par defaut.
  - `EditorNotifier`:
    - delegation de la logique session map au `EditorMapSessionCoordinator`,
    - delegation de la logique historique map-level au `MapHistoryCoordinator`,
    - delegation des helpers warp au `WarpEditingCoordinator`,
    - conservation du pipeline central `_applyMapMutation(...)` avec orchestration d etat.
  - `application/use_cases/warp_use_cases.dart`:
    - remplacement d exceptions generiques par `ValidationException` sur les validations warp cross-map.
- impact:
  - `EditorNotifier` est plus proche d un orchestrateur d etat UI,
  - les responsabilites transverses session/historique/warp sont explicites et testables de maniere isolee plus tard,
  - comportement fonctionnel conserve (terrains/paths/presets/rendu/preview/undo/redo/persistance).

2026-03-23 (refacto cible clean architecture terrain/path - etape 2):
- `map_editor`:
  - ajout `application/services/terrain_preset_selection_coordinator.dart`:
    - centralise les transitions de selection terrain/path:
      - initialisation,
      - normalisation apres mutation de projet,
      - selection par type/preset,
      - post-create/update/delete des presets.
  - ajout `application/services/path_autotile_resolver.dart`:
    - centralise la resolution du `PathAutotileSet` courant a partir du preset path selectionne + validation tileset.
  - `EditorNotifier`:
    - delegation des transitions de selection terrain/path au `TerrainPresetSelectionCoordinator`,
    - delegation de la resolution `PathAutotileSet` au `PathAutotileResolver`,
    - suppression de logique de fallback/normalisation inline dans les flux:
      - create/load map,
      - delete tileset,
      - select terrain/path mode,
      - create/update/delete presets terrain/path.
    - remplacement d erreurs generiques locales par `StateError` sur les cas "preset introuvable" post-mutation.
- impact:
  - `EditorNotifier` reste orchestrateur d etat et de pipeline, avec moins de logique applicative terrain/path embarquee,
  - meme comportement fonctionnel conserve (selection presets, rendu path, undo/redo, dirty state, persistance).

2026-03-23 (refacto cible clean architecture terrain/path):
- `map_editor`:
  - ajout `application/services/terrain_preset_resolver.dart`:
    - centralise le tri, la recherche et la resolution de selection des presets terrain/path,
    - centralise la resolution des categories terrain/path et du chemin de categorie,
    - centralise la normalisation des selections (`selectedTerrainPresetId`, `selectedPathPresetId`, `selectedTerrainPresetByType`),
    - centralise la detection des presets nouvellement crees.
  - ajout `application/services/terrain_painting_coordinator.dart`:
    - orchestre paint/erase/fill terrain via les use cases existants,
    - encapsule la regle de preservation des cellules `TerrainType.path` pour paint/fill non-path,
    - encapsule la resolution du footprint terrain (1x1).
  - `EditorNotifier` allégé:
    - delegation de la logique presets terrain/path au `TerrainPresetResolver`,
    - delegation de la logique de mutation terrain au `TerrainPaintingCoordinator`,
    - suppression des helpers internes redondants (tri/recherche/selection presets et preservation path cells).
- impact:
  - separation plus nette entre etat/session editor et orchestration applicative terrain/path,
  - comportement produit conserve (paint/fill/erase terrain, path, presets, undo/redo, dirty state, preview).

2026-03-23 (stabilisation rendu terrain/path + brush):
- `map_core`:
  - `map_terrain_autotile.dart`:
    - correction de `_resolveEdgeCornerAsBorderVariant(...)`:
      - mapping miroir des coins de bord,
      - plus de reutilisation du meme sprite `end*` pour les deux cotes d un meme bord.
- `map_editor`:
  - `MapCanvas`:
    - ordre de rendu corrige:
      - parcours unique de la pile de layers (bas -> haut),
      - fin du rendu "par type" qui faisait passer le terrain devant certains `TileLayer`.
  - `EditorNotifier`:
    - `fillActiveTerrainLayer(...)`:
      - conservation des cellules `TerrainType.path` lors d un fill non-path.
    - `_resolveTerrainFootprint(...)`:
      - footprint terrain fixe en 1x1 (normal + path),
      - suppression de l effet "brush geante" heritee d un element multi-tiles precedemment selectionne.
- impact:
  - elements tile map ne deviennent plus "delaves" par un terrain dessine au-dessus par erreur de pipeline de rendu,
  - `Fill Layer` ne casse plus les chemins existants,
  - peinture terrain previsible meme apres placement d un gros element.

2026-03-23 (logos path encore plus explicites):
- `map_editor`:
  - `TerrainEditorPanel`:
    - icones de variantes path revues avec mini-compas visuel integre (`N/E/S/O`),
    - connexions actives mises en evidence directement dans le logo,
    - libelles de connexions en toutes lettres (`Nord/Est/Sud/Ouest`) au lieu des abreviations seules,
    - texte contextualise `Connecte: ...` pour chaque variante dans la grille.
- impact:
  - lecture plus immediate de la correspondance coin/jonction/extremite,
  - reduction de l ambiguite pendant le mapping case-par-case.

2026-03-23 (coins internes path + clarification interne/externe):
- `map_core`:
  - `TerrainPathVariant` etendu avec:
    - `innerCornerNE`,
    - `innerCornerSE`,
    - `innerCornerSW`,
    - `innerCornerNW`.
  - `resolveTerrainPathVariantAt(...)` etendu:
    - detection des coins internes quand les 4 directions cardinales sont connectees, avec diagonale manquante.
- `map_editor`:
  - `PathAutotileSet` enrichi avec mappings par defaut pour les nouveaux coins internes.
  - `TerrainEditorPanel`:
    - grille de variantes mise a jour avec coins externes + coins internes,
    - badge de type (`Coin externe` / `Coin interne`),
    - description explicite de la difference:
      - coin externe = virage,
      - coin interne = encoche dans un bloc entoure.
- impact:
  - set de variantes path enrichi (20 variantes au total),
  - difference interne/externe visible directement dans l UI et exploitable dans le rendu.

2026-03-22 (clarification UX mapping path):
- `map_editor`:
  - `TerrainEditorPanel`:
    - editeur visuel de mapping path clarifie:
      - libelles de variantes explicites (Extremite, Coin, Jonction T, Croisement),
      - affichage direct des directions de connexion (`N/E/S/O`) pour chaque variante,
      - panneau d explication contextuel de la variante active (quand elle est utilisee),
      - repere visuel global des directions (N=haut, E=droite, S=bas, O=gauche),
      - action de suppression ciblee de la variante selectionnee.
- impact:
  - reduction de l ambiguite sur la correspondance coin/jonction <-> variante,
  - mapping des chemins plus rapide et plus comprehensible.

2026-03-22 (categories terrain/path + pickers map + type de path):
- `map_core`:
  - ajout `TerrainPresetCategoryKind` (`terrain`, `path`) dans `enums.dart`,
  - `ProjectManifest` enrichi avec:
    - `terrainPresetCategories`,
    - `ProjectTerrainPreset.categoryId`,
    - `ProjectPathPreset.categoryId`,
    - `ProjectPathPreset.groundTerrainType`,
    - modele `ProjectTerrainPresetCategory`,
  - `ProjectValidator` etendu:
    - unicite IDs categories presets,
    - coherence parent/enfant et detection de cycles,
    - coherence du `kind` des categories,
    - coherence preset -> categorie,
    - validation du type de path (`groundTerrainType`),
    - maintien de la separation stricte tilesets terrain/path.
- `map_editor`:
  - use cases:
    - `CreateTerrainPresetCategoryUseCase`,
    - `RenameTerrainPresetCategoryUseCase`,
    - extension create/update presets terrain/path avec `categoryId` et `groundTerrainType`,
  - providers Riverpod ajoutes pour les categories presets,
  - `EditorNotifier` enrichi:
    - listing/lookup des categories terrain/path,
    - resolution du chemin de categorie (`Parent / Enfant`),
    - APIs create/rename categories,
    - integration des nouveaux champs sur create/update presets,
  - `TerrainEditorPanel`:
    - creation de categories terrain/path (avec parent optionnel),
    - choix de categorie dans les dialogs terrain/path,
    - type de path selectable dans creation/edition de preset,
    - affichage de la categorie et du type dans les listes/details,
    - nouvel editeur visuel de mapping path:
      - grille des variantes de chemin (coins, T, croisement, extremites),
      - selection d une variante dans la grille,
      - selection directe case-par-case dans le tileset path charge,
      - mapping applique en 1x1 par variante pour un workflow plus clair.
  - `TerrainMapPanel`:
    - selection des presets terrain/path via dropdown (plus robuste qu une liste libre),
    - affichage des chemins de categories dans les options,
    - affichage du type du path selectionne.
- impact:
  - modele metier categorie/sous-categorie en place pour terrains/paths,
  - selection map orientee picker demandee,
  - type de chemin explicite au niveau preset et dans l UX map.

2026-03-22 (listes terrains/chemins + panneau map droit + separation tilesets):
- `map_editor`:
  - nouveau panneau `TerrainMapPanel` ajoute en mode map dans la colonne droite:
    - statut de `TerrainLayer` active,
    - liste des presets terrain,
    - liste des presets chemin,
    - actions `Paint` et `Fill Layer` appliquees au preset selectionne.
  - `EditorShellPage`:
    - integration du panneau `TerrainMapPanel` dans la colonne droite map,
    - zone gauche `Terrains & Paths` agrandie pour mieux exposer la bibliotheque.
  - `TerrainEditorPanel`:
    - simplifie en bibliotheque independante de la map:
      - section `Terrains` (liste + creation + edition),
      - section `Paths` (liste + creation + edition),
    - suppression des actions de peinture map dans ce panneau (deplacees a droite),
    - filtres de choix de tileset ajustes pour respecter la separation terrain/path.
  - `terrain_preset_use_cases.dart`:
    - validation metier ajoutee pour refuser un tileset deja utilise par l autre famille de preset.
- `map_core`:
  - `ProjectValidator` etendu pour refuser un tileset partage entre `terrainPresets` et `pathPresets`.
- Impact:
  - workflow demande par produit respecte:
    - gauche = bibliotheque terrain/path,
    - droite (map) = choix rapide des presets a appliquer sur `TerrainLayer`,
  - coherence metier renforcee sur la separation des assets terrain vs chemins.

2026-03-22 (terrain/path editor independant + assistants de mapping):
- `map_editor`:
  - `EditorShellPage`:
    - colonne gauche fixe avec:
      - `ProjectExplorerPanel`,
      - `TerrainEditorPanel`,
    - panneau terrain/path accessible en mode map et en mode tileset.
  - `TerrainEditorPanel`:
    - mode bibliotheque actif meme sans map chargee,
    - liste terrain selectionnable (style liste) + details du terrain selectionne,
    - preview image du tileset du terrain selectionne,
    - import direct de tileset terrain/path depuis les dialogs de presets,
    - assistant `Add Members` pour terrains (selection de zones successives dans l image),
    - assistant `Map All Variants` pour path (mapping guide variante par variante),
    - mapping path via selection visuelle case/zone depuis le tileset.
- Impact:
  - workflow terrain/path decouple de la creation/edition immediate de map,
  - creation de presets plus proche d un editeur type Tiled (source image + selection guidee),
  - persistance inchangee: donnees presets toujours sauvegardees dans `project.json`.

2026-03-22 (terrain editor independant + import direct):
- `map_editor`:
  - `TerrainEditorPanel`:
    - mode bibliotheque disponible meme sans map active,
    - import direct d images pour terrains et paths depuis les dialogs de preset,
    - mapping path: bouton `Pick From Tileset` ajoute dans le dialog de variante,
    - creation/edit terrain: variantes visuelles selectionnables directement dans le tileset,
  - `EditorShellPage`:
    - panneau `Terrains & Paths` fixe dans la colonne gauche pour separer clairement:
      - bibliotheque terrain/path (gauche),
      - edition elements/tilesets (droite).
- Impact:
  - edition terrain/path decouplee du flux de creation/map active,
  - workflow proche d un terrain editor dedie:
    - import source,
    - selection des cases,
    - creation de presets reutilisables persistants.

2026-03-22 (terrain presets - picker visuel + panneau gauche):
- `map_editor`:
  - `TerrainEditorPanel`:
    - ajout d un picker visuel de rect depuis un tileset pour les variantes terrain,
    - prise en charge create + edit de preset terrain avec variantes des la creation,
    - conservation de la saisie manuelle `x/y/width/height` en fallback,
    - clear des variantes temporaires lors du changement de tileset dans le dialog de creation.
  - `EditorShellPage`:
    - panneau `Terrains & Paths` ajoute dans la colonne gauche en mode map,
    - retrait du panneau terrain de la colonne droite pour eviter la redondance,
    - panneau terrain/path desormais separe du workflow tileset/elements.
- Impact:
  - creation de terrains visuels beaucoup plus rapide (selection directe dans le tileset),
  - UX plus claire entre bibliotheque terrain/path (gauche) et edition elements tileset (droite),
  - persistance inchangee: les presets restent sauvegardes dans `project.json`.

2026-03-22 (terrains/paths presets v2):
- `map_core`:
  - `ProjectManifest` enrichi avec `terrainPresets` et `pathPresets`,
  - nouveaux modeles:
    - `ProjectTerrainPreset`,
    - `TerrainPresetVariant`,
    - `ProjectPathPreset`,
    - `PathPresetVariantMapping`,
  - validation metier etendue:
    - unicite IDs presets,
    - references tileset valides,
    - coherence des variants (coordonnees, taille, poids),
    - unicite des mappings de variantes path.
- `map_editor`:
  - nouveaux use cases dedies presets:
    - `CreateTerrainPresetUseCase`, `UpdateTerrainPresetUseCase`, `DeleteTerrainPresetUseCase`,
    - `CreatePathPresetUseCase`, `UpdatePathPresetUseCase`, `DeletePathPresetUseCase`,
  - providers Riverpod associes ajoutes et codegen regenere,
  - creation/chargement projet:
    - injection automatique de presets par defaut quand absents,
  - suppression tileset:
    - nettoyage automatique des references presets vers le tileset supprime,
  - `EditorState` enrichi:
    - `selectedTerrainPresetId`,
    - `selectedPathPresetId`,
    - `selectedTerrainPresetByType`,
  - `EditorNotifier` enrichi:
    - resolution/listing des presets,
    - selection explicite des presets actifs,
    - CRUD presets (avec persistance),
    - normalisation de la selection apres chargement/projet/mutations,
  - `PathAutotileSet`:
    - support `fromPreset(ProjectPathPreset)`,
  - `MapCanvas` / `MapGridPainter`:
    - rendu terrains non-path via presets multi-variants,
    - selection stable des variantes par cellule (ponderee),
    - rendu path auto-connecte via preset path selectionne,
    - previews paint/erase adaptees aux presets,
  - `TerrainEditorPanel`:
    - refonte UI en panneau complet `Terrains & Paths`,
    - sections presets background/path,
    - creation/edition/suppression de presets,
    - edition des variantes terrain et du mapping path 16 variantes.
- Impact:
  - workflow terrain plus proche d un editeur type Tiled (bibliotheque + presets reutilisables),
  - rendu moins repetitif pour les sols grace aux variantes visuelles,
  - configuration explicite des chemins auto-connectes,
  - compatibilite preservee avec undo/redo, dirty state, hover preview et pipeline `_applyMapMutation(...)`.

2026-03-22 (terrains - terrain editor UX):
- `map_editor`:
  - nouveau panneau `TerrainEditorPanel`:
    - selection visuelle des terrains de fond,
    - section dediee au dessin de chemins,
    - indicateur d etat du mode courant,
    - action `Fill Layer` pour poser rapidement un terrain de fond sur toute la `TerrainLayer` active,
    - gestion claire du cas sans `TerrainLayer` active (activer une layer existante ou en creer une).
  - `EditorNotifier`:
    - ajout `fillActiveTerrainLayer(...)`,
    - ajout `selectTerrainPaintMode(...)`,
    - ajout `activateFirstTerrainLayer(...)`,
    - `path` force un footprint 1x1 pour garantir un dessin stable pendant le drag.
  - `MapGridPainter`:
    - preview terrain path enrichie (variant auto-connectee simulee sur la cellule hover),
    - fallback automatique vers preview overlay classique si ressource path indisponible.
  - `EditorShellPage`:
    - integration du `TerrainEditorPanel` dans la colonne droite du mode map.
- Impact:
  - workflow terrain nettement plus lisible (fond puis chemin),
  - edition plus rapide pour poser un fond et dessiner des routes,
  - aucune rupture du pipeline map-level centralise.

2026-03-22 (terrains - path auto-connecte MVP):
- `map_core`:
  - ajout de `TerrainType.path` dans le modele metier,
  - ajout de `TerrainPathVariant`,
  - ajout de `map_terrain_autotile.dart` avec operations pures:
    - `resolveTerrainCardinalMaskAt(...)`,
    - `resolveTerrainPathVariantFromMask(...)`,
    - `resolveTerrainPathVariantAt(...)`,
  - export des operations d autotiling via `map_core.dart`.
- `map_editor`:
  - ajout de `PathAutotileSet` (mapping logique -> source rect) avec preset par defaut 4x4,
  - `EditorNotifier`:
    - ajout `getPathAutotileSet()` pour resoudre le mapping visuel courant,
    - ajout `selectPathPaintMode()` pour basculer directement sur la peinture de chemin,
  - `TopToolbar`:
    - ajout du bouton `Path Paint Tool`,
    - ajout de `path` dans la liste des types de terrain selectionnables,
  - `MapCanvas` / `MapGridPainter`:
    - chargement du tileset necessaire au rendu path,
    - rendu auto-connecte des cellules `TerrainType.path` selon leurs voisins,
    - fallback overlay si la ressource visuelle de path n est pas disponible.
- Impact:
  - dessin de chemins nettement plus ergonomique (coins, segments, T et croisement automatiques),
  - donnees metier restees simples (stockage du type logique uniquement),
  - compatibilite conservee avec paint/erase terrain, undo/redo, resize et sauvegarde JSON.

2026-03-22 (warps - creation assistee du warp retour):
- `map_editor`:
  - use cases:
    - ajout `CreateReciprocalWarpUseCase` dans `warp_use_cases.dart`,
    - resultat explicite `CreateReciprocalWarpResult`,
    - chargement map cible via repository si cible differente de la map source.
  - regles appliquees a la creation retour:
    - validation `targetMapId` non vide et existant dans le manifest,
    - verification des bornes de `targetPos` dans la map cible,
    - refus explicite si un warp existe deja sur la case cible,
    - generation d ID unique (`warp`, `warp_1`, ...),
    - sauvegarde map cible automatique si cible != map source.
  - providers:
    - ajout `createReciprocalWarpUseCaseProvider`.
  - `EditorNotifier`:
    - ajout `createReciprocalWarpForSelectedWarp()`,
    - same-map: application via `_applyMapMutation(...)` pour garder undo/redo/dirty coherents,
    - cross-map: sauvegarde cible sans casser l etat de la map active.
  - `WarpPropertiesPanel`:
    - ajout bouton `Create Return Warp`,
    - bouton desactive si la cible courante n existe pas dans le projet,
    - texte d aide UX sur le comportement de la creation retour.
  - robustesse UI:
    - correction du tri des maps projet dans le panneau warp via copie mutable locale (evite l erreur `Unsupported operation: Cannot modify an unmodifiable list`).
- Impact:
  - liaison assistee MVP disponible sans modifier `map_core` avec de la logique projet,
  - comportement previsible sur cas limites (cible manquante/hors bornes/deja occupee),
  - aucune regression sur la creation/edition/suppression de warp existante.

2026-03-22 (warps UX + validation inter-map):
- `map_editor`:
  - ajout du use case `ValidateWarpTargetMapUseCase` (validation d existence de `targetMapId` dans le manifest projet),
  - ajout du provider Riverpod `validateWarpTargetMapUseCaseProvider`,
  - `EditorNotifier`:
    - validation inter-map executee avant creation/mise a jour de warp,
    - message d erreur explicite si `targetMapId` est vide ou inexistant,
    - conservation du pipeline `_applyMapMutation(...)` pour garder undo/redo/dirty/selection coherents,
  - `WarpPropertiesPanel`:
    - remplacement du champ libre `targetMapId` par un dropdown des maps du projet,
    - indication visuelle quand la cible courante n existe plus,
    - resume destination explicite (map cible + position).
- Impact:
  - edition warp plus fiable et plus guidée,
  - moins d erreurs de saisie manuelle sur `targetMapId`,
  - aucune regression sur la selection warp, la creation au clic, ni l historique map-level.

2026-03-22 (bugfix affichage elements multi-tileset):
- `map_editor`:
  - ajout d un contexte de selection tileset explicite dans `EditorNotifier`:
    - `selectTilesetEditorContext(String? tilesetId)`.
  - ajout d un selecteur `Tileset` dans `TilesetPalettePanel` pour choisir le tileset affiche dans le panneau droit sans changer le mode du workspace central.
  - suppression du couplage implicite `setActiveLayer(...)` -> `selectedTilesetEditorId` pour eviter les retours silencieux vers le tileset de layer.
- Impact:
  - la liste d elements du panneau droit peut maintenant basculer explicitement entre tous les tilesets importes,
  - l affichage n est plus force par le changement de layer active.

2026-03-22 (bugfix tileset elements visibles):
- `map_editor`:
  - correction de la resolution du tileset courant dans `getSelectedTilesetEntry()`:
    - priorite au tileset de la `TileLayer` active quand disponible.
  - correction de la conservation du contexte tileset:
    - `loadMap(...)` preserve `selectedTilesetEditorId` quand il reste valide dans le projet,
    - `_applyMapMutation(...)` ne force plus un reset systematique vers le tileset map/layer quand un tileset utilisateur est deja selectionne.
- Impact:
  - la selection explicite utilisateur du tileset est conservee au chargement map et pendant les mutations map-level.

2026-03-22 (terrain / sols MVP):
- `map_core`:
  - ajout `TerrainType` dans `enums.dart`,
  - ajout du type de layer `terrain` dans `MapLayerKind`,
  - ajout du variant `TerrainLayer` dans `map_layer.dart`,
  - ajout des operations pures terrain dans `map_terrain.dart`:
    - `paintTerrainOnLayer(...)`,
    - `paintTerrainPatternOnLayer(...)`,
    - `eraseTerrainOnLayer(...)`,
    - `eraseTerrainPatternOnLayer(...)`,
  - export des operations terrain dans `map_core.dart`,
  - resize map etendu aux terrains (`TerrainType.none` pour les nouvelles cellules),
  - operations layers etendues pour ajouter/copier une `TerrainLayer`,
  - validation map etendue:
    - `TerrainLayer.terrains.length` doit correspondre a `map.size.width * map.size.height`.
- `map_editor`:
  - use cases dedies terrain:
    - `PaintTerrainOnMapUseCase`,
    - `PaintTerrainPatternOnMapUseCase`,
    - `EraseTerrainOnMapUseCase`,
    - `EraseTerrainPatternOnMapUseCase`,
  - providers Riverpod dedies ajoutes dans `use_case_providers.dart`,
  - `CreateMapUseCase` initialise une `TerrainLayer` par defaut (`l_terrain`),
  - `AddMapLayerUseCase` et `LayersPanel` etendus au type `TerrainLayer`,
  - `EditorState` enrichi avec `selectedTerrainType`,
  - `EditorToolType` enrichi avec `terrainPaint`,
  - `EditorNotifier`:
    - ajout `paintTerrainAt(...)`,
    - ajout de la resolution footprint terrain,
    - ajout des mutations terrain paint/erase dans le pipeline `_applyMapMutation(...)`,
    - integration des previews terrain paint/erase,
    - ajout `selectTerrainType(...)`,
  - `TopToolbar`:
    - bouton outil `terrainPaint`,
    - menu de selection du type de terrain actif,
  - `MapCanvas`:
    - routing gestuel terrain (clic + drag),
  - `MapGridPainter`:
    - rendu overlay des `TerrainLayer` visibles,
    - rendu du ghost preview terrain paint/erase.
- `map_runtime`:
  - branchement de `TerrainLayer` dans le chargement des layers runtime (placeholder).

2026-03-22 (warp MVP):
- `map_core`:
  - ajout `map_warps.dart` avec operations pures:
    - `addWarpToMap(...)`,
    - `updateWarpOnMap(...)`,
    - `removeWarpFromMap(...)`,
  - validations dediees: ID non vide/unique, position source en bornes, `targetMapId` non vide, `targetPos` >= 0.
  - export via `map_core.dart`.
- `map_editor`:
  - ajout des use cases:
    - `AddWarpToMapUseCase`,
    - `UpdateWarpOnMapUseCase`,
    - `DeleteWarpFromMapUseCase`.
  - ajout des providers Riverpod associes.
  - `EditorState`:
    - ajout `selectedWarpId`,
    - extension de `MapHistorySnapshot` avec `selectedWarpId`.
  - `EditorNotifier`:
    - ajout des actions warp:
      - `placeOrSelectWarpAt(...)`,
      - `addWarpAt(...)`,
      - `selectWarp(...)`,
      - `updateSelectedWarp(...)`,
      - `deleteSelectedWarp(...)`,
    - generation ID warp unique (`warp`, `warp_1`, ...),
    - creation warp par defaut valide (`targetMapId = map active`, `targetPos = pos`),
    - nettoyage/maintien de `selectedWarpId` sur mutations map + undo/redo + changement de map/projet.
  - `MapCanvas`:
    - integration de `EditorToolType.warpPlacement` au clic,
    - clic en mode warp:
      - selection si warp deja present sur la cellule,
      - creation sinon.
  - `MapGridPainter`:
    - overlay warps au-dessus des layers map/collision,
    - style distinct pour le warp selectionne.
  - UI:
    - bouton `Warp Tool` dans `TopToolbar`,
    - nouveau `WarpPropertiesPanel` dans la colonne droite en mode map:
      - liste des warps,
      - selection,
      - edition (`id`, `targetMapId`, `targetPos.x`, `targetPos.y`),
      - suppression.

2026-03-22 (ghost preview + erase):
- `map_core`:
  - nouvelles operations pures dans `map_paint.dart`:
    - `eraseTileOnLayer(...)`,
    - `eraseTilePatternOnLayer(...)`.
- `map_editor`:
  - nouveaux use cases:
    - `EraseTileOnMapUseCase`,
    - `EraseTilePatternOnMapUseCase`.
  - nouveaux providers Riverpod associes.
  - `EditorNotifier`:
    - refactor de resolution brush partagee (paint/preview/erase),
    - ajout `resolveMapToolPreview(...)` (preview paint/erase),
    - ajout `eraseAt(...)` (clic + drag),
    - compatibilite tileset/layer evaluee pour distinguer preview valide/invalide,
    - aucun spam `errorMessage` lors du hover.
  - `MapCanvas` / `MapGridPainter`:
    - routing gestures `tilePaint` et `eraser`,
    - rendu du ghost preview paint semi-transparent,
    - rendu preview invalide avec overlay de refus,
    - rendu preview erase dedie.

2026-03-22 (undo/redo + shortcuts + delete element):
- `map_editor`:
  - `EditorState`:
    - ajout de l historique map active (`mapUndoStack`, `mapRedoStack`),
    - ajout de `mapStrokeStart`,
    - ajout de `savedMapSnapshot`,
    - ajout des flags `canUndoMap` / `canRedoMap`.
  - `EditorNotifier`:
    - ajout `beginMapStroke()`, `endMapStroke()`, `undoMap()`, `redoMap()`,
    - centralisation des mutations map via `_applyMapMutation(...)`,
    - invalidation redo sur nouvelle mutation,
    - coherence dirty/snapshot apres undo/redo/save,
    - integration stroke dans paint/erase pour produire une seule entree par drag.
  - `MapCanvas`:
    - integration cycle stroke en gestures (tap/pan start/update/end/cancel),
    - drag paint/erase agrège en une seule action undo.
  - `EditorShellPage`:
    - ajout du systeme `Shortcuts`/`Actions` pour undo/redo desktop,
    - ajout du raccourci sauvegarde desktop (`Cmd+S` / `Ctrl+S`),
    - garde contre declenchement quand un champ texte est focus.
  - `TopToolbar`:
    - ajout boutons `Undo` / `Redo` relies a `canUndoMap` / `canRedoMap`.
  - Elements:
    - ajout `DeleteProjectElementUseCase` + provider,
    - ajout `deleteProjectElement(...)` dans le notifier,
    - action de suppression UI dans `TilesetPalettePanel` avec confirmation.
  - Refactor use cases:
    - extraction dans fichiers dedies:
      - `map_use_cases.dart`,
      - `layer_use_cases.dart`,
      - `paint_use_cases.dart`.

2026-03-22 (collisions MVP):
- `map_core`:
  - ajout des operations pures collisions:
    - `paintCollisionOnLayer(...)`,
    - `paintCollisionPatternOnLayer(...)`,
    - `eraseCollisionOnLayer(...)`,
    - `eraseCollisionPatternOnLayer(...)`.
  - operations purement immuables avec validations (layer type, bounds, pattern size, clipping).
- `map_editor`:
  - use cases collisions dedies:
    - `PaintCollisionOnMapUseCase`,
    - `PaintCollisionPatternOnMapUseCase`,
    - `EraseCollisionOnMapUseCase`,
    - `EraseCollisionPatternOnMapUseCase`.
  - providers Riverpod associes.
  - `EditorNotifier`:
    - ajout `paintCollisionAt(...)`,
    - `eraseAt(...)` devient contextuel selon le type de layer active (`TileLayer` ou `CollisionLayer`),
    - preview outillage etendu avec modes collision paint/erase,
    - integration complete au pipeline central `_applyMapMutation(...)` + strokes undo/redo.
  - `MapCanvas`:
    - routing gestuel etendu pour `collisionPaint`,
    - drag collision groupe en un seul stroke.
  - `MapGridPainter`:
    - rendu overlay des `CollisionLayer` visibles (avec opacite),
    - preview collision paint/erase dedie.
  - `TopToolbar`:
    - ajout bouton `collisionPaint`,
    - bouton `eraser` explicite.
  - refactor use cases:
    - ajout `collision_use_cases.dart` et eclatement poursuivi du monolithe.

2026-03-22 (correctifs fin d etape layers):
- `map_editor`:
  - `LayersPanel`: correction des actions de reorder pour que:
    - bouton Haut -> `moveMapLayerUp`,
    - bouton Bas -> `moveMapLayerDown`,
    - tooltips alignes avec ce comportement.
  - `MapCanvas`: correction de l ordre de peinture pour respecter la pile affichee:
    - layer la plus basse dessinee en premier,
    - layer la plus haute dessinee en dernier (donc visible au-dessus).

2026-03-22:
- refonte tilesets par layer (option 1):
  - `map_core`:
    - `TileLayer` enrichi avec `tilesetId`,
    - `MapData.tilesetId` garde en mode legacy de compatibilite JSON,
    - `MapValidator` adapte: plus de contrainte sur `map.tilesetId`; validation du `tilesetId` de `TileLayer` quand renseigne.
  - `map_editor`:
    - assignation de tileset deplacee de la map vers les `TileLayer`,
    - suppression du selecteur explicite de tileset dans la toolbar (plus de notion UI "Map Tileset" / "Active Layer Tileset"),
    - liaison implicite: au paint, une tile layer vide/sans tileset se lie automatiquement au tileset du brush,
    - migration a chaud des anciennes maps chargees: si une tile layer n a pas de `tilesetId`, reprise du `map.tilesetId` legacy,
    - blocage de suppression d un tileset s il est encore utilise par une tile layer d une map,
    - rendu `MapCanvas` multi-tilesets (une image par `tilesetId` de tile layer),
    - peinture basee sur le tileset du brush + coherence de la tile layer cible (fin du couplage dur `map.tilesetId`).

2026-03-22:
- `map_core`:
  - ajout d operations pures `map_layers.dart`:
    - ajout de layer (`tile`/`collision`/`object`) avec initialisation de grilles correcte,
    - renommage / suppression sans contrainte de minimum de layers,
    - reorder,
    - visibilite,
    - opacite.
  - ajout enum `MapLayerKind`.
  - export des operations layers dans `map_core.dart`.
- `map_editor`:
  - nouveaux use cases layers:
    - `AddMapLayerUseCase`,
    - `RenameMapLayerUseCase`,
    - `DeleteMapLayerUseCase`,
    - `MoveMapLayerUseCase`,
    - `SetMapLayerVisibilityUseCase`,
    - `SetMapLayerOpacityUseCase`.
  - nouveaux providers Riverpod associes.
  - `EditorNotifier`:
    - CRUD layers map active + reorder + visibilite + opacite,
    - selection de layer active robuste (validation + fallback apres suppression),
    - coherence `activeLayerId` renforcee sur create/load/resize/assign/delete map,
    - peinture bloquee explicitement si la layer active n est pas une `TileLayer`.
  - UI:
    - ajout d un panneau dedie `LayersPanel` (mode map),
    - integration du panneau layers dans la colonne droite via `EditorShellPage`,
    - actions utilisateur disponibles: select/add/rename/delete/reorder/visibility/opacity.
  - action supplementaire layers:
    - suppression globale des layers de la map sans layer de fallback; une map vide en layers est valide/sauvegardable.
  - canvas map:
    - rendu des tile layers garde l ordre reel de la pile,
    - visibilite respectee,
    - opacite appliquee au niveau layer via `saveLayer`.

2026-03-22:
- `map_editor`:
  - refonte du modele de brush selectionne:
    - `EditorBrush` devient la source unique de verite (none/tile/paletteEntry/projectElement),
    - enrichissement des variants `tile` et `paletteEntry` avec `tilesetId` pour eviter les ambiguities cross-tileset.
  - `EditorNotifier`:
    - suppression de la logique concurrente sur `selectedTileId` / `selectedPaletteEntryId` / `selectedProjectElementId`,
    - `create/load project/map`, `assign tileset`, `delete map` et `delete tileset` synchronisent correctement `activeBrush`,
    - `selectPaletteTile`, `selectPaletteEntry`, `selectProjectElement` alimentent uniquement `activeBrush`,
    - `paintSelectedBrushAt` simplifie et rebase sur `activeBrush` uniquement,
    - ajout de helpers pour resoudre un brush en pattern de peinture et centraliser les erreurs de peinture.
  - `TilesetPalettePanel`:
    - lecture de la selection via `activeBrush`,
    - highlight/preview/selection d element adaptes au nouveau modele,
    - suppression des dependances UI aux anciens champs de selection.
  - codegen regenere (`freezed`/`riverpod`) pour aligner l etat et le notifier.

2026-03-22:
- `map_core`:
  - `MapValidator.validate(MapData map)` etendu avec validations completes:
    - champs map obligatoires non vides (`id`, `name`),
    - tailles map strictement positives,
    - unicite des IDs internes (`layers`, `entities`, `warps`, `triggers`),
    - validation par type de layer:
      - `TileLayer`: taille de grille exacte + tile IDs non negatifs,
      - `CollisionLayer`: taille de grille exacte,
      - `ObjectLayer`: validation structurelle (`id`, `name`, `opacity`),
    - map valide meme sans aucun layer,
    - validation bornes entites/warps/triggers,
    - validation zones de triggers (taille positive + zone entierement dans la map),
    - messages `ValidationException` explicites et orientes diagnostic.
- `map_editor`:
  - aucun changement fonctionnel dans cette etape.

2026-03-22 (iteration precedente):
- `map_editor` etat/notifier:
  - ajout du mode explicite `EditorWorkspaceMode` (`map` / `tileset`) dans `EditorState`,
  - `loadMap(...)` force le mode `map`,
  - `selectTilesetWorkspace(...)` force le mode `tileset`.
- UI shell:
  - ajout d un host central `EditorCanvasHost`,
  - le centre n affiche plus toujours `MapCanvas`.
- Nouveau canvas central tileset:
  - ajout de `TilesetEditorCanvas`,
  - affichage principal de l image tileset + grille + scroll + selection rectangulaire,
  - creation d element depuis selection directement dans le canvas central.
- Panneau droit:
  - `TilesetPalettePanel` rendu secondaire en mode tileset (onglet `Elements` uniquement),
  - l edition visuelle principale du tileset est deplacee au centre.

2026-03-21:
- `map_core`:
  - `ProjectTilesetEntry` enrichi avec `elementGroups`.
  - Nouveau modele `TilesetElementGroup`.
  - `ProjectElementEntry` enrichi avec `tilesetGroupId`.
  - Codegen `freezed/json` regenere.
  - Validation etendue:
    - coherence/acyclicite groupes internes tileset,
    - coherence element `tilesetGroupId`.
- `map_editor` use cases:
  - `CreateTilesetElementGroupUseCase`
  - `CreateTilesetElementSubgroupUseCase`
  - `RenameTilesetElementGroupUseCase`
  - `ResolveTilesetElementsUseCase`
  - `CreateProjectElementUseCase` / `UpdateProjectElementUseCase` etendus avec `tilesetGroupId`.
- Providers Riverpod:
  - nouveaux providers pour les use cases ci-dessus + codegen regenere.
- `EditorState`:
  - ajout `selectedTilesetEditorId`
  - ajout `selectedTilesetElementGroupId`
- `EditorNotifier`:
  - selection du tileset workspace,
  - CRUD minimal groupes internes tileset,
  - listage des elements par tileset/groupe interne,
  - create/update element avec `tilesetGroupId`,
  - synchro de la selection workspace sur create/load/assign/delete tileset/map.
- UI:
  - `ProjectExplorerPanel`: node tileset selectionnable + highlight + correction overflow header.
  - `TilesetPalettePanel`:
    - mode workspace sur tileset selectionne (pas uniquement map active),
    - affichage image complete du tileset avec grille/scroll,
    - panneau groupes internes (create/subgroup/rename + filtre),
    - creation/edition d element avec champ groupe interne tileset,
    - liste des elements du tileset avec metadonnees (groupe monde + groupe interne + layer).

## 8. Prochaines etapes recommandees

Decoupage aligne sur la **Vision produit**: d abord **richir l editeur de contenu**, puis **construire le runtime standard**. Les deux listes ne sont pas exclusives (certains sujets touchent les deux), mais l **ordre de priorite** reste: modeliser et editer proprement **avant** ou **en parallele raisonnable** avec l execution.

### 8.1. Priorites editoriales (court terme)

- **Entites / gameplay pose sur map**: specialisation continue (catalogues, preview visuelle canvas, affinage item / spawn / PNJ / panneaux). *(Base livrée : payloads typés, DialogueRef, visuel canvas, animation multi-frames.)*
- **Dialogues / scripts** : éditeur narratif intégré (Yarn ligne à ligne, nœuds visuels) ; harmonisation des chemins de sauvegarde passant `projectDialogueContext`. *(Base livrée : registre, dossiers, UI bibliothèque, assignation NPC/signe.)*
- **Rencontres — extensions éditeur** : affinage UX (preview espèces, conditions de zone, lien zone ↔ table dans l'inspector), validation croisée. *(Base livrée : zones gameplay + tables de rencontres — modèle + UI éditeur complets.)*
- **Dresseurs / equipes**: modele + panneaux dedies (lie aux entites / triggers selon le design retenu).
- **Propriétés de map avancées** : hooks gameplay (script entrée/sortie map), flags de progression conditionnels, restrictions d'accès. *(Base livrée : `MapMetadata` nom/type/musique/météo/indoor/escape rope/spawn/tags + UI.)*
- **Outils d edition avances**: fill / copy-paste map, selection rect etendue, filtres et navigation explorateur.
- **Collisions enrichies**: types, comportements de sol, presets — toujours valides dans `map_core`.
- **Triggers / warps / terrains (extensions MVP)**: UI plus specialisee, pairing warps, presets terrains avances (biomes, import/export), feedback d invalidite dans l UI.
- **Qualite de vie editeur**: brush metadata uniforme, locks/groupes layers, drag/drop elements tileset, filtres tags/recherche, navigation `TilesetEditorCanvas`, validation batch inter-maps (`targetMapId`, references croisees).

### 8.2. Priorites runtime (moyen terme)

- **Lecteur standard de projet** : ✅ **livré (Runtime 1)** — `loadRuntimeMapBundle`, migrations JSON partagées `map_core`, résolution tilesets, `RuntimeMapGame` + `MapLayersComponent`, app exemple `packages/map_runtime/example`.
- **Entités à l'écran** : rendu sprites in-game via `ProjectElementEntry.frames` (même source que l'éditeur) — prochaine priorité runtime.
- **Déplacement / collisions / warps** : boucle exploration, collisions bloquantes gameplay, activation des warps — à construire.
- **Interactions** : PNJ, panneaux, objets ramassables, spawns — branchement sur les payloads entites existants.
- **Dialogues** : resolution de `DialogueRef` vers fichiers scripts via couche **infra** (Yarn ou autre); **aucune** logique Yarn dans `map_core`.
- **Rencontres sauvages actives** : lecture des zones `EncounterZonePayload` + tables `ProjectEncounterTable` → déclenchement runtime et logique de calcul des taux.
- **Execution standard**: objectif **jouable** avec un minimum d integration dans une app Flutter/Flame (le runtime encapsule le maximum de comportements communs).
- **Separation editor / runtime**: l editeur peut eventuellement embarquer une **preview** plus tard; le coeur reste le **package runtime** consommant les memes JSON.

### 8.3. Themes transverses (editor + runtime)

- Comportements de sol et rencontres (tags terrains, zones) — **schema** dans `map_core`, **edition** dans `map_editor`, **effet** dans `map_runtime`.
- Separation rendu editor vs rendu runtime pour terrains animes / transitions (deja amorcee conceptuellement pour les paths).

## 9. Decisions d architecture importantes

### 9.1. Strategie monorepo (vision produit + execution)

- Les **nouvelles donnees metier** ne sont pas concues **uniquement** pour l editeur: elles doivent rester **validables dans `map_core`** et **interpretables** par un **`map_runtime` standard** qui evolue en parallele.
- **`map_core`**: schema metier, invariants, serialisation JSON, operations pures — **aucune** dependance Flutter / Flame / Yarn / moteur de dialogue concret.
- **`map_editor`**: production et maintenance des donnees conformes (UI, use cases, fichiers).
- **`map_runtime`**: lecture et execution progressive des memes schemas; les integrations externes (ex. Yarn Spinner) s y branchent via **adaptateurs**, pas via fuites depuis le domaine.
- **Runtime 1 (2026-03-26)** : lecture `project.json` / map via les memes migrations JSON que l editeur (`map_core`) ; rendu Flame des layers **aligne** sur le canvas (ordre terrain → path → tile → collision ; autotile path `resolvePathVariantAt` ; presets terrain avec graine stable) ; **sans** pipeline visuel parallele pour les donnees map.
- **No-code / framework tres haut niveau**: hors priorite immediate; la feuille de route court terme est **contenu riche + runtime standard**, pas un meta-outil complet sur la premiere vague.

### 9.2. Decisions editeur et UX (detail operationnel)

- `EditorState.activeBrush` est la seule source de verite pour la selection de brush.
- Les types de brush restent explicites et distincts:
  - tile unitaire (`tileId` + `tilesetId`),
  - palette entry (`entryId` + `tilesetId`),
  - project element (`elementId`).
- La resolution de brush est mutualisee dans `EditorNotifier` et reutilisee par paint/erase/preview.
- La peinture map ne lit plus de champs de selection concurrents; elle ne consomme que `activeBrush`.
- Le ghost preview est pilote cote notifier avec un statut explicite (`valid` / `invalid`) et rendu cote painter.
- L eraser reutilise la taille du brush courant, avec fallback 1x1 quand `activeBrush` vaut `none`.
- Les mutations de layers sont centralisees via operations pures `map_core` + use cases `map_editor`.
- `activeLayerId` reste pilote cote notifier et est resolu automatiquement vers une layer valide, ou `null` si la map n a plus de layer.
- Les groupes internes de tileset sont separes des groupes du monde et des layers.
- Le lien element -> groupe interne est persiste via `tilesetGroupId`.
- Le workspace central est pilote par un mode explicite (`EditorWorkspaceMode`).
- Le tileset cible est pilote par `selectedTilesetEditorId` dans `EditorNotifier`.
- La validation map stricte reste centralisee dans `map_core` via `MapValidator`.
- La logique de resolution/liste des elements d un tileset reste cote use cases, pas dans les widgets.
- Les tilesets sont portes par les `TileLayer`; `MapData.tilesetId` reste seulement en fallback legacy.
- L historique undo/redo est volontairement scope a la map active (pas d historique global projet pour cette iteration).
- Toute mutation map passe par `_applyMapMutation(...)` dans le notifier pour garder un seul pipeline de coherence (undo/redo, dirty, layer active, tileset selectionne).
- Les strokes paint/erase sont traites comme des transactions logiques (begin/end) pour eviter une entree d historique par cellule.
- Les raccourcis undo/redo sont geres au shell via `Shortcuts/Actions` avec garde de focus texte.
- Decision UX collisions:
  - outil dedie `collisionPaint` pour poser des collisions,
  - `eraser` reste unique et efface selon le type de layer active:
    - tile -> effacement de tiles,
    - collision -> effacement de collisions.
  - overlay collision rendu au-dessus des tiles pour garder la lisibilite d edition.
- Decision UX terrains:
  - outil dedie `terrainPaint`,
  - bibliotheque dediee `Surface Library` dans la colonne gauche,
  - sections `Terrains` et `Paths` de la bibliotheque repliables,
  - panneau map dedie `TerrainMapPanel` pour rendre explicites les usages `Base Ground` et `Surface Overlays`,
  - type de fond actif selectionne depuis la toolbar,
  - `eraser` contextuel efface les terrains (`TerrainType.none`) si la layer active est une `TerrainLayer`,
  - paint/erase des terrains en footprint 1x1 pour eviter les heritages de taille involontaires apres selection d elements multi-tiles,
  - rendu path auto-connecte base sur les voisins cardinaux, sans stocker la variante visuelle dans les donnees map,
  - separation explicite metier/rendu:
    - `TerrainType` stocke uniquement des fonds,
    - `PathSurfaceKind` decrit les familles de surfaces,
    - presets terrain/path stockent la configuration visuelle,
  - categories terrain/path persistees et separees par `kind`:
    - `terrain` pour presets de fond,
    - `path` pour presets de chemin,
    - hierarchie parent/enfant disponible pour organiser la bibliotheque,
  - presets persistes dans le `ProjectManifest` (pas d etat UI temporaire),
  - aucun preset terrain/path par defaut n est injecte automatiquement,
  - edition terrain/path positionnee dans un panneau dedie de la colonne gauche, distinct du panneau tileset/elements,
  - creation de variantes terrain supporte la selection visuelle depuis le tileset (rect picker),
  - mapping path supporte un editeur visuel dedie pour les variantes autotile,
  - rendu terrain (hors path) peut utiliser des variantes visuelles multi-tiles avec poids,
  - choix des variantes terrain stable par cellule (seed deterministic) pour eviter le flicker en edition.
- Decision UX warps:
  - outil dedie `warpPlacement`,
  - clic sur cellule avec warp existant => selection,
  - clic sur cellule vide => creation warp,
  - creation warp immediate avec valeurs valides par defaut (`targetMapId = map active`, `targetPos = pos`) pour eviter des objets invalides,
  - edition warp via dropdown de map cible (pas de saisie libre) pour limiter les erreurs de reference,
  - validation inter-map gardee cote editor/application (et non `map_core`) car dependante du `ProjectManifest`,
  - creation retour assistee via action explicite `Create Return Warp` (pas d automatisme a chaque edition),
  - same-map: mutation appliquee dans le pipeline map-level; cross-map: sauvegarde directe de la map cible.
- `selectedWarpId` fait partie de l etat editor et de l historique map-level pour garder undo/redo coherent avec la selection.
- La compatibilite avec l existant est conservee:
  - import/assign tileset,
  - painting tile unitaire/multi-tile,
  - bibliotheque d elements deja en place.
- Refacto cible terrain/path:
  - `EditorNotifier` conserve le role de coordination d etat et de pipeline map-level,
  - les dependances applicatives editor sont injectees via providers Riverpod (plus de singletons statiques dans le notifier),
  - la session map active (`activeLayerId` / `selectedWarpId` / `selectedTilesetEditorId`) est deleguee au `EditorMapSessionCoordinator`,
  - l historique map-level (stroke, undo/redo, dedup snapshots) est delegue au `MapHistoryCoordinator`,
  - la resolution/normalisation des presets terrain/path est externalisee dans `TerrainPresetResolver`,
  - les transitions de selection terrain/path sont externalisees dans `TerrainPresetSelectionCoordinator`,
  - l orchestration paint/fill/erase terrain est externalisee dans `TerrainPaintingCoordinator`,
  - l orchestration applicative warp est externalisee dans `WarpEditingService`,
  - la resolution du `PathAutotileSet` courant est externalisee dans `PathAutotileResolver`,
  - les widgets restent passifs (aucune logique metier terrain/path ajoutee dans l UI).

## 10. Points de vigilance / dette technique / bugs connus
- Le ghost preview invalide pre-vient le refus avant clic, mais la raison detaillee n est pas encore affichee directement dans l UI.
- Les brushes lies a un tileset different restent bloques a la peinture si la layer active ne peut pas etre rebindee.
- Les layers `collision` sont maintenant rendues en overlay, mais le rendu reste volontairement simple (bool), sans typage avance.
- Les layers `terrain`/`path` : rendu **editeur** et **Runtime 1** (`map_runtime`) partagent presets + autotile (affichage) ; **gameplay** runtime (rencontres surf, glace, etc.) non branche.
- App exemple `map_runtime` sur **macOS** : sandbox desactive pour lire des chemins absolus vers `project.json` — choix **dev local** ; une distribution Mac App Store exigerait autre strategie (ex. `NSOpenPanel` + droits sandbox).
- Le footprint de peinture terrain est volontairement fixe en 1x1 pour eviter les heritages de taille de brush apres selection d elements multi-tiles; les poses massives passent par `Fill Layer` pour l instant.
- Le systeme de presets est operationnel mais reste encore incomplet:
  - pas encore de gestion avancee des biomes (profiles globaux, inheritance),
  - pas encore d outils batch (rebind de tileset, migration de presets),
  - pas encore de mapping de transitions entre terrains (blend/edges).
- La migration legacy terrain -> path est une cassure assumee:
  - un ancien preset terrain representant en realite de l eau/de la glace/de la haute herbe n est pas remappe automatiquement vers un `PathPreset`.
- Les layers `object` restent sans rendu editorial dedie.
- Le Warp MVP n interdit pas explicitement plusieurs warps sur la meme case dans les donnees importees; en UI, le clic selectionne le premier warp trouve sur la case.
- Le panneau layers est fonctionnel mais sans lock/groupes/filtres; ergonomie a enrichir avant des maps tres grandes.
- Une map peut maintenant etre volontairement sans layers; toute action de peinture est alors no-op tant qu aucune layer active tile n est selectionnee.
- La creation d element depend toujours de l existence d au moins une categorie d element:
  - l UI affiche maintenant un message explicite au lieu d echouer silencieusement.
- Les anciennes maps restent lisibles via fallback legacy `map.tilesetId`; la migration complete du champ legacy n est pas encore supprimee du schema.
- Suppression/reparentage de groupes internes non implemente dans cette iteration.
- Undo/redo reste limite a la map active:
  - pas d historique cross-map,
  - pas de persistance d historique entre changements de map.
- Quelques lints/deprecations preexistants dans le projet restent presents (hors scope).
- La logique visuelle tileset est maintenant centrale; le panneau droit reste mixte (outils + bibliotheque) et peut encore etre simplifie.
- Le paint d un element d un autre tileset que celui de la map active est bloque cote notifier avec message d erreur (comportement volontaire).
- `MapValidator` ne verifie pas l existence reelle de la map cible des warps (verification volontairement gardee au niveau projet).
- Le panneau warp reste MVP:
  - edition de base (`id`, `targetMapId`, `targetPos`) avec picker map cible et resume destination texte,
  - creation retour assistee disponible, mais sans lien persistant bidirectionnel ni preview graphique.
- Le concept metier courant est `tileset par TileLayer`; `MapData.tilesetId` est conserve en legacy JSON uniquement.
- `EditorState` reste encore volumineux; la prochaine etape logique sera de mieux separer etat de session editor, etat map-level et etat purement UI pour continuer a alleger `EditorNotifier`.

## Checklist fonctionnelle (etat)
- Ouvrir un projet existant: fait
- Sauvegarder un projet: fait
- Gerer un manifest de projet: fait
- Creer une map: fait
- Charger une map: fait
- Sauvegarder une map: fait
- Renommer une map: fait
- Supprimer une map: fait
- Dupliquer une map: fait
- Redimensionner une map: fait
- Gerer plusieurs maps dans un meme projet: fait
- Gerer les connexions entre maps: fait (MVP)
- Afficher une grille editable: partiellement fait
- Se deplacer dans le canvas: fait
- Zoomer dans le canvas: fait
- Selectionner un outil: fait
- Selectionner une layer active: fait
- Ajouter/renommer/reordonner/masquer/supprimer des layers: fait
- Peindre des tiles: fait
- Effacer des tiles: fait
- Ghost preview brush: fait
- Preview d effacement: fait
- Remplir une zone: pas fait
- Faire de la selection rectangulaire: fait
- Copier-coller une zone: pas fait
- Avoir une palette de tiles: fait
- Charger et afficher un vrai tileset: fait
- Gerer plusieurs tilesets: fait
- Associer un tileset a une TileLayer: fait
- Workspace d edition de tileset: fait
- Panneau Layers dedie: fait
- Respect strict de la pile visuelle des layers (ordre panneau -> rendu canvas): fait
- Mode explicite map/tileset du canvas central: fait
- Affichage du tileset selectionne dans le canvas central: fait
- Groupes internes de tileset (categorie/sous-categorie): fait
- Creation d element depuis tileset: fait
- Feedback explicite si aucune categorie d element n existe: fait
- Edition d element (nom/categorie/groupe monde/groupe interne/layer/tags): fait
- Resolution des elements par tileset + groupe interne: fait
- Peindre les collisions: fait (MVP bool)
- Visualiser les collisions: fait (MVP overlay)
- Gerer plusieurs types de collisions ou comportements de sol: pas fait
- Peindre des terrains/sols: fait (MVP)
- Effacer des terrains/sols: fait (MVP)
- Dessiner des chemins auto-connectes: fait (MVP)
- Visualiser les terrains/sols: fait (MVP overlay + path autotile)
- Avoir un vrai editeur terrain (fond + chemins): fait (v2 presets)
- Presets de terrain visuels (multi-variants): fait
- Presets de chemins configurables (mapping complet des variantes): fait
- Categories/sous-categories de presets terrain: fait
- Categories/sous-categories de presets path: fait
- Picker terrain en mode map: fait
- Picker path en mode map: fait
- Type de path configurable (`Path`/`Road`/`Water`/`Tall Grass`/`Ice`/`Lava`/`Swamp`/`Rails`/`Bridge`/`Special`/`Custom`): fait
- Poser des warps: fait (MVP)
- Configurer les warps: partiellement fait (picker map cible + id/targetPos + resume destination + suppression + creation retour assistee; lien persistant bidirectionnel non fait)
- Poser des triggers: fait (MVP)
- Configurer les triggers: fait (MVP generique)
- Poser des PNJ: fait (MVP generique via entites)
- Poser des objets ramassables: fait (MVP generique via entites)
- Poser des panneaux: fait (MVP generique via entites)
- Poser des points de spawn: fait (MVP generique via entites)
- Editer les proprietes des entites: fait (MVP generique + payloads types par kind + DialogueRef)
- Lier une entite a un fichier de dialogue (DialogueRef): partiellement fait (modele + inspector; resolution fichier / execution non faits)
- Gerer une bibliotheque de fichiers de dialogues / scripts projet: partiellement fait (registre manifest + dossiers + DnD + Script Library ; pas d editeur Yarn integre)
- Définir des zones de rencontres sauvages (areas, kind, payload encounter/movement/hazard/special) dans l'éditeur: fait (MVP + drag-to-draw + payloads typés)
- Configurer les tables de rencontres (espèces, niveaux, poids) dans l'éditeur: fait (tables projet réutilisables + entrées + EncounterTablesPanel)
- Déclencher des rencontres sauvages activement dans le runtime: pas fait
- Creer et editer des dresseurs / equipes PNJ dans l'éditeur: fait (ProjectTrainerEntry + équipe Pokémon, Trainer Library panel, champs battle NPC — runtime non fait)
- Editer les propriétés de map de base (nom affiché, type, musique, météo, indoor, escape rope, spawn par défaut, tags): fait (MapMetadata + MapPropertiesPanel + UpdateMapMetadataUseCase)
- Editer les propriétés de map avancées (hooks gameplay, flags progression, restrictions accès): pas fait
- Editer les proprietes globales du projet: partiellement fait
- Avoir un inspector de proprietes: partiellement fait (inspector map contextuel + sections pliables; inspector complet multi-systemes encore a pousser)
- Avoir un explorateur de projet: fait (tuiles repliables type inspecteur, liste deroulante globale, sans redimensionnement vertical entre cartes)
- Avoir une toolbar claire: fait
- Avoir une barre de statut: fait
- Supporter l undo/redo: fait (map active)
- Avoir une sauvegarde propre avec etat dirty: partiellement fait
- Pouvoir previsualiser le rendu in-game: pas fait (hors app exemple `map_runtime` séparée)
- Charger un projet dans le runtime et afficher les maps: **partiellement fait** (package `map_runtime` + app `example` ; pas d’intégration dans la fenêtre de l’éditeur)
- Avoir une boucle d exploration jouable (deplacement / collisions / warps): pas fait
- Interagir avec les entites via le runtime (PNJ / panneaux / objets): pas fait
- Executer les dialogues via le runtime (resolution DialogueRef / Yarn): pas fait
- Declencher des rencontres sauvages selon les zones terrain: pas fait
- Avoir un comportement standard Pokemon-like jouable out-of-the-box: pas fait
- Preparer un runtime compatible Flame: partiellement fait (**Runtime 1** : lecture projet/map + rendu layers ; gameplay / entités / dialogues non faits)
- Avoir un format JSON propre et stable: fait
- Valider les donnees metier: fait
- Verifier les erreurs de coherence: partiellement fait
- Gerer les assets du projet: partiellement fait
- Pouvoir editer progressivement routes/villes/interieurs/donjons: partiellement fait
- Etre pense specifiquement pour un jeu de type Pokemon sur grille: partiellement fait
- Rester coherent avec une Clean Architecture stricte: partiellement fait
- Rester modulaire entre core, editor et runtime: fait

### Fichiers touches — bibliotheque tilesets hierarchique (lot recent)
- **map_core**: `lib/map_core.dart`, `lib/src/models/project_manifest.dart` (+ `.freezed.dart` / `.g.dart` generes), `lib/src/validation/validators.dart`, `lib/src/operations/tileset_library_tree.dart`
- **map_editor**: `lib/src/application/use_cases/project_tileset_library_use_cases.dart`, `project_tileset_use_cases.dart`, `project_use_case_support.dart`, `lib/src/app/providers/use_case_providers.dart` (+ `.g.dart`), `lib/src/infrastructure/repositories/file_repositories.dart`, `lib/src/features/editor/state/editor_notifier.dart`, `lib/src/ui/panels/project_explorer_panel.dart`
- **racine**: `PROJECT_STATUS.md`
- **map_runtime**: voir lot **Runtime 1** (2026-03-26) pour l’état actuel du package ; cette puce historique concernait un lot tilesets **sans** toucher au runtime

### Lot bibliotheque dialogues projet (registre + editeur)

**Objectif**: fondation editeriale pour gerer les dialogues au niveau projet (sans Yarn dans `map_core`, sans execution runtime dans ce lot).

**Decisions structurantes**

1. **Modele manifest** : liste `ProjectManifest.dialogues` d entrees `ProjectDialogueEntry` (`id`, `name`, `relativePath`, metadonnees optionnelles : description, tags, `defaultStartNode`). IDs uniques, nom et chemin non vides, chemins valides via `dialogue_validation.dart` (relatif, prefixe `dialogues/`, pas de `..` ni chemin absolu).
2. **Convention fichiers** : dossier racine projet `dialogues/` ; creation standard `dialogues/<id>.yarn` (contenu minimal) ; import conserve l extension source (ex. `.yarn`, `.txt`).
3. **DialogueRef** : `scriptPathRelative` vide = resolution future via registre (`dialogueId` doit exister dans le manifest a la validation carte) ; chemin non vide = legacy / override fichier, pas d exigence d entree manifest pour cette reference.
4. **Suppression** : **refusee** si le dialogue est encore reference par une entite NPC ou signe sur une map du projet (fichiers charges) **ou** sur la carte active (y compris non sauvegardee) ; pas de suppression silencieuse ni nettoyage auto des references dans ce lot.
5. **Validation** : regles de forme et coherence registre dans `map_core` (`validators`, `map_entities`, `project_dialogue_refs`) ; persistance et CRUD dans l editeur (use cases + repo) ; UI affiche les erreurs de sauvegarde / alertes utilisateur.
6. **Compatibilite** : projets sans cle `dialogues` dans le JSON manifest : migration douce vers `dialogues: []` a la lecture / sauvegarde.

**Fichiers principaux**

- **map_core** : `lib/src/models/project_manifest.dart` (+ codegen), `lib/src/validation/dialogue_validation.dart`, `lib/src/validation/validators.dart`, `lib/src/operations/map_entities.dart`, `lib/src/operations/project_dialogue_refs.dart`, `lib/map_core.dart` (exports), `map_entity_payloads.dart` (doc `DialogueRef`).
- **map_editor** : `lib/src/application/use_cases/project_dialogue_use_cases.dart`, `map_use_cases.dart` / `SaveMapUseCase` + `file_repositories.dart` (`projectDialogueContext`), `editor_notifier.dart` (actions bibliotheque, pas de logique lourde), `editor_state.dart` (`selectedProjectDialogueId`), `use_case_providers.dart`, `project_explorer_panel.dart` (Script Library + tuiles), `entity_properties_panel.dart` (picker NPC / signe + mode fichier avance), `cupertino_editor_widgets.dart` (confirmation suppression via `showMacosEditorTwoChoiceAlert`), `inspector_section_card.dart` (tuiles explorateur = meme widget que panneau inspecteur map).

**Limites restantes**

- Aucune execution de dialogues dans `map_runtime` ; pas de parse Yarn dans le domaine.
- Pas d editeur narratif graphique ; la bibliotheque gere les fichiers et les references, pas le contenu Yarn ligne a ligne dans l outil.
- Autres chemins de sauvegarde de carte hors flux principal peuvent ne pas encore passer `projectDialogueContext` partout (a harmoniser si besoin).

**Extension explorateur (scripts + UI)**

- Volet **Script Library** (fichiers `.yarn` / registre dialogues) : dossiers hierarchiques `ProjectDialogueFolder` + `ProjectDialogueEntry.folderId`, glisser-deposer dossiers/scripts comme la bibliotheque tilesets, bandeau racine de depot.
- Fichiers cles supplementaires : `map_core` `dialogue_library_tree.dart`, `project_dialogue_library_use_cases.dart`, migration JSON `dialogueFolders: []`.

**World Explorer — tuiles repliables + scroll (alignement panneau droit)**

- Le panneau gauche **World Explorer** n utilise plus de **`ResizablePane`** entre les zones : tout le contenu projet (en-tete + sections) est dans un **`SingleChildScrollView`** vertical.
- Les quatre zones **Tileset Library**, **Script Library**, **World Maps**, **Surface Library** sont des **`InspectorSectionCard`** (meme composant que l inspecteur de map a droite) : degrades colores, coins arrondis (~28 px), icone encadree, titre / sous-titre, **badge** (compteurs : tilesets, scripts, maps, presets terrain+chemins), chevron, actions d en-tete (`headerTrailing`) sans declencher le repli.
- Couleurs d accent par tuile (proches de l inspecteur) : orange `inspectorJoyBlue` (tilesets), rose `inspectorJoyLilac` (scripts), violet `inspectorJoyPlum` (cartes), vert `inspectorJoyMint` (surfaces).
- Hauteur du corps d une tuile ouverte : fonction de la hauteur d ecran (clamp), avec scroll interne dans la zone comme pour l inspecteur ; `TerrainEditorPanel(omitOuterHeader: true)` conserve un seul titre « Surface » sur la tuile.
- **`_SidebarHeaderAction`** supporte `iconColor` / `hoverFill` pour les icones claires sur fond de tuile coloree.

## Mini tableau priorites (etat)

*(Etat factuel des chantiers outil; l ordre strategique global est dans **Vision produit** et **## 8**.)*

### Phase 1 — Editeur de contenu (priorite actuelle)

| Chantier | Etat |
|----------|------|
| Maps / groupes / connexions | fait |
| Layers (tile/terrain/path/collision/object) | fait (MVP) |
| Tilesets + bibliotheque hierarchique | fait |
| Elements + categories | fait |
| Visuels multi-frames | fait (domaine + JSON; animation canvas **entités** oui ; autres previews éditeur = souvent première frame) |
| Terrains + paths autotile | fait (MVP + presets visuels) |
| Collisions | partiellement fait (MVP bool) |
| Warps | partiellement fait (MVP + retour assiste; lien bidirectionnel non fait) |
| Triggers | partiellement fait (MVP generique) |
| Entites (NPC / signe / objet / spawn) | partiellement fait (payloads types + DialogueRef + **preview canvas** via `editorVisual` → `ProjectElementEntry.frames` avec **animation legere canvas** ; runtime / facing / gameplay non faits) |
| Dialogues / scripts | partiellement fait (registre projet + UI bibliotheque + assignation NPC/signe ; runtime Yarn non fait) |
| Rencontres sauvages | partiellement fait (zones gameplay + tables de rencontres : **modèle + UI éditeur complets** ; runtime rencontre actif : pas fait) |
| Dresseurs / equipes | partiellement fait (**éditeur livré** : `ProjectTrainerEntry` + équipe `ProjectTrainerPokemonEntry`, Trainer Library panel, champs battle NPC (`trainerId`, `lineOfSightRange`, `defeatDialogueRef`) ; runtime non fait) |
| Proprietes de map | partiellement fait (**base livrée** : `MapMetadata` nom/type/musique/météo/indoor/escape rope/spawn/tags + UI panel ; avancées non faites : hooks, flags progression, restrictions) |

### Phase 2 — Runtime standard (prochaine grande etape)

| Chantier | Etat |
|----------|------|
| Lecteur de projet (manifest + maps + assets) | **fait** (Runtime 1 : `loadRuntimeMapBundle(projectFilePath:, mapId:)`, migrations JSON `map_core`, tilesets, images PNG, app exemple) |
| Scene de jeu (grille + camera + layers tile/terrain/path/collision) | **fait** (Flame : `RuntimeMapGame(bundle:)` + `MapLayersComponent`, ordre rendu aligné éditeur, caméra vue carte) |
| Entités à l'écran (sprites in-game) | **fait** (Runtime 2 : `_paintEntities` via `ProjectElementEntry.frames`, animation `_animElapsed`, aspect-ratio preserving) |
| API publique propre / package importable | **fait** (Runtime 3 : barrel `show` 3 noms, chargement images interne, `pubspec.yaml` pub.dev-ready, `README.md` complet, zéro doc-comment dans sources) |
| Déplacement / collisions / warps (`map_gameplay`) | **fait** (socle exploration : `stepGameplayWorld`, `GameplayWorldState.fromMap`, `GameplayIntent.move`, `Moved`/`Blocked`/`WarpTriggered` ; spawn joueur résolu depuis métadonnées map) |
| Intégration Flame (component joueur, game loop) | pas fait |
| Interactions entités (NPC, signe) | pas fait |
| Dialogues (resolution DialogueRef) | pas fait |
| Rencontres sauvages actives (déclenchement runtime) | pas fait |
| Comportements standard Pokemon-like jouable | pas fait |
