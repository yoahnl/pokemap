# Project Status — pokemonProject

> Dernière mise à jour : 2026-03-27 (interactions runtime + logs structurés + clarification dialogue + dialogue Yarn MVP runtime + blocksMovement entités + Yarn branches : <<jump>> + choix ->)
> Source de vérité : code du dépôt. Ce fichier a été entièrement regénéré depuis les fichiers sources.

---

## 1. Vision produit

Suite **outil + format + runtime** pour créer et jouer à des jeux de type Pokémon-like / RPG sur grille.

| Axe | Statut |
|-----|--------|
| **Éditeur de contenu** (`map_editor`) | En cours — priorité actuelle |
| **Runtime jouable** (`map_runtime` + `map_gameplay`) | Amorcé — socle fonctionnel livré |
| **Couches haut niveau** (no-code, framework abstrait) | Volontairement plus tard |

### Rôles

- **Créateur de contenu** : travaille dans `map_editor`, produit un projet JSON + assets.
- **Développeur jeu** : intègre `map_runtime` dans une app Flutter/Flame, étend ce qui dépasse le comportement standard.

### Principe directeur des données

- `map_core` = schéma métier + invariants + validateurs + opérations pures. Aucune dépendance Flutter/Flame/Yarn.
- `map_editor` produit les données (JSON + assets).
- `map_runtime` et `map_gameplay` consomment les données.
- Compat JSON legacy : `migrateProjectManifestJson` / `migrateMapDataJson` dans `map_core/src/io/legacy_editor_json_compat.dart`. Migrations appliquées à la désérialisation.

---

## 2. Architecture réelle

### Graphe de dépendances

```
map_core          (pure Dart, freezed, json_serializable)
  ↑
  ├── map_gameplay  (pure Dart, aucune dépendance Flutter/Flame)
  │
  ├── map_runtime   (Flutter + Flame, consomme map_core + map_gameplay)
  │     └── example/ (app Flutter interne, identique à playable_runtime_host)
  │
  └── map_editor    (Flutter + Riverpod + macos_ui, NE dépend PAS de map_runtime ni map_gameplay)

examples/playable_runtime_host  (app Flutter externe, consomme map_runtime uniquement)
```

**Point critique** : `map_editor` ignore totalement `map_gameplay` et `map_runtime`. Les trois packages sont indépendants sauf par `map_core`.

### Résumé par package

| Package | Version | Type | Rôle réel |
|---------|---------|------|-----------|
| `map_core` | 0.1.0 | Dart pur | Schéma métier, validation, sérialisation JSON, migrations legacy, opérations pures sur les données |
| `map_gameplay` | 0.1.0 | Dart pur | Boucle d'exploration : mouvement, collision, warps, interactions entités, résolution spawn |
| `map_runtime` | 0.1.0 | Flutter + Flame | Chargement projet depuis disque, rendu Flame (layers + entités animées), boucle jouable au clavier |
| `map_editor` | 0.2.0 | Flutter desktop (macOS) | Éditeur GUI complet : maps, layers, entités, tilesets, terrains, paths, warps, triggers, zones, dialogues, dresseurs, rencontres |

---

## 3. Inventaire fonctionnel (état réel depuis le code)

### map_core

| Capacité | Statut | Notes |
|----------|--------|-------|
| Modèles freezed (MapData, ProjectManifest, entités, layers, warps, zones…) | **Fait** | Tous @freezed avec JSON serialization |
| `MapEntity.blocksMovement` (défaut true) | **Fait** | Toutes les cellules couvertes par entity.size bloquent le mouvement ; désactivable par entité |
| Enums métier complets (MapEntityKind, EntityFacing, MapLayerKind, TerrainType, PathSurfaceKind, GameplayZoneKind, etc.) | **Fait** | Très complet, 20+ enums |
| Géométrie (GridPos, GridSize, MapRect) | **Fait** | |
| Layers typés scellés (tile, collision, terrain, path, object) | **Fait** | Sealed class Dart 3, `whenOrNull` |
| Entités typées (npc, sign, item, spawn, custom) avec payloads | **Fait** | Freezed, payloads séparés |
| Métadonnées de map (MapMetadata) | **Fait** | displayName, type, musique, météo, indoor, escapeRope, defaultSpawnId, tags |
| Warps (MapWarp) | **Fait** | id, pos, targetMapId, targetPos |
| Connexions inter-maps (MapConnection) | **Fait** | direction, targetMapId, offset |
| Triggers (MapTrigger) | **Fait** | id, name, type, area, properties |
| Zones gameplay typées (MapGameplayZone) | **Fait** | payloads : encounter, movement, hazard, special |
| Tables de rencontres (ProjectEncounterTable) | **Fait** | entries avec speciesId, niveaux, poids |
| Dialogues projet (ProjectDialogueEntry) | **Fait** | relativePath, tags, startNode, folderId |
| Dresseurs (ProjectTrainerEntry + équipe) | **Fait** | team[], moves[], held item, form, gender, shiny |
| Éléments visuels projet (ProjectElementEntry) | **Fait** | frames[], tilesetId, categoryId, groupId — multi-frames supporté |
| Presets terrain (ProjectTerrainPreset) | **Fait** | variants avec poids, frames[] |
| Presets path / autotile (ProjectPathPreset) | **Fait** | 20 variantes (corners, tees, cross, edges…) |
| Palette tilesets (TilesetPaletteEntry) | **Fait** | |
| Validation projet (ProjectValidator) | **Fait** | Unicité IDs, hiérarchies, cycles, frames, chemins dialogues |
| Validation map (MapValidator) | **Fait** | Inclut validation `editorVisual` contre projet |
| Migrations JSON legacy (migrateProjectManifestJson, migrateMapDataJson) | **Fait** | Appliquées à la désérialisation |
| Migration entités legacy (migrateMapEntityJson) | **Fait** | Convertit ancien format properties plat → payloads typés |
| Migration zones gameplay legacy | **Fait** | `transition` → `special`, payloads aplatis → typés |
| Opérations pures sur les données (17+ modules) | **Fait** | Resize, paint, collision, terrain, path, layers, entities, warps, triggers, zones, connections, metadata, tileset/dialogue library trees |
| Exceptions hiérarchisées (ValidationException, ProjectLoadException, etc.) | **Fait** | Sealed class |

### map_gameplay

| Capacité | Statut | Notes |
|----------|--------|-------|
| Direction (enum + extensions dx/dy/asFacing) | **Fait** | |
| EntityFacingX.asDirection (bridge map_core ↔ gameplay) | **Fait** | |
| GameplayPlayerState (pos, facing, copyWith) | **Fait** | Plain class immuable, pas Freezed |
| GameplayWorldState (collision cache, warp cache, entity cache) | **Fait** | Cache plat List<bool> + Map<int, MapEntity> row-major, spawns exclus ; entity cache couvre toutes les cellules de entity.size |
| GameplayWorldState.initial (pos + facing explicites) | **Fait** | Ne valide pas la cellule |
| GameplayWorldState.fromMap (spawn automatique) | **Fait** | Lance exception si spawn bloqué |
| Résolution spawn : defaultSpawnId → playerStart (tri par id) → exception | **Fait** | |
| stepGameplayWorld (move intent → result) | **Fait** | Turn-face + collision (tuiles + entités blocksMovement) + warp check |
| stepGameplayWorld (interact intent → result) | **Fait** | Cellule devant joueur → NPC/sign/item/entity/nothing |
| Résultats scellés (Moved, Blocked, WarpTriggered, TriggeredWarp) | **Fait** | |
| Résultats interaction (NothingToInteract, NpcInteracted, SignInteracted, ItemInteracted, EntityInteracted) | **Fait** | |
| GameplaySpawnResolutionException | **Fait** | |
| Logique de dialogue, rencontres, NPC AI | **Non fait** | Hors périmètre actuel |
| Persistance de l'état de jeu (sauvegarde) | **Non fait** | |

### map_runtime

| Capacité | Statut | Notes |
|----------|--------|-------|
| Chargement project.json (loadRuntimeMapBundle) | **Fait** | Avec migration + validation |
| Chargement MapData depuis relativePath | **Fait** | Avec migration + validation contextuelle |
| Résolution chemins absolus tilesets | **Fait** | Tous les tilesets référencés (layers + terrain + path + entités) |
| Décodage images PNG → dart:ui.Image | **Fait** | |
| RuntimeMapBundle (manifest + map + chemins) | **Fait** | Expose cellWidth / cellHeight |
| Rendu TileLayer | **Fait** | tileId - 1 → col/row dans l'image tileset |
| Rendu TerrainLayer (avec variantes seedées) | **Fait** | Graine : coordonnées + preset.id.hashCode → variante déterministe |
| Rendu PathLayer (autotile 20 variantes) | **Fait** | RuntimePathAutotileSet depuis ProjectPathPreset |
| Rendu entités animées (multi-frames) | **Fait** | _pickEntityFrame avec cycle durationMs (fallback 200ms) |
| Rendu CollisionLayer (overlay semi-transparent) | **Fait** | Visible si couche visible dans les données |
| Ordre de rendu : terrain → path → tile → entités → collision | **Fait** | Identique à l'éditeur |
| RuntimeMapGame (viewer statique) | **Fait** | Caméra = map entière visible |
| PlayableMapGame (jouable au clavier) | **Fait** | KeyboardEvents : flèches + WASD + E/Space |
| PlayerComponent (disque + indicateur direction) | **Fait** | Simple marqueur visuel bleu |
| Collisions au clavier via map_gameplay | **Fait** | |
| Warps : détection + chargement async nouvelle map | **Fait** | _handleWarp, erreur loggée + notification "Warp failed" |
| Interactions entités (E/Space) | **Fait** | Résultat typé → overlay 2s (`entity.inspectorHeadline`) + log `[interact]` |
| Logs structurés runtime | **Fait** | Préfixes `[runtime]` `[move]` `[warp]` `[interact]` via debugPrint |
| HUD notification 2s | **Fait** | TextComponent sur camera.viewport |
| Caméra follow-player (~15×11 tuiles viewport) | **Fait** | |
| Fallback spawn (0,0) si pas de spawn configuré | **Fait** | PlayableMapGame.onLoad catch GameplaySpawnResolutionException |
| Barrel public : 4 exports uniquement | **Fait** | loadRuntimeMapBundle, RuntimeMapBundle, RuntimeMapGame, PlayableMapGame |
| Résolution dialogue (`resolveDialogue`) | **Fait** | Résout fichier .yarn + startNode, logs [dialogue] |
| Parser Yarn (`parseYarnFile`) | **Fait** | `YarnStepLine`, `YarnStepJump`, `YarnStepChoiceBlock`, `YarnChoice` — détecte `<<jump X>>` et blocs `->` avec corps indentés |
| Moteur dialogue (`DialogueSession`) | **Fait** | `advance()`, `moveChoiceCursor()`, `confirmChoice()` ; résolution automatique des `<<jump>>` via `_resolveStep()` |
| Chargement dialogue (`loadDialogueContent`) | **Fait** | Lecture .yarn → parse → DialogueSession, fallback premier nœud |
| UI dialogue runtime (`DialogueOverlayComponent`) | **Fait** | Mode ligne (E · Suite/Fermer) + mode choix (▶ curseur, ↑/↓, E valider) |
| Blocage gameplay pendant dialogue | **Fait** | `_dialogueOverlay != null` bloque mouvement + re-interaction ; clavier routé selon mode (ligne/choix) |
| Rencontres aléatoires actives | **Non fait** | |
| Comportements NPC (patrouille, LoS) | **Non fait** | |
| Sauvegarde/chargement état jeu | **Non fait** | |

### map_editor

| Capacité | Statut | Notes |
|----------|--------|-------|
| Création / chargement / sauvegarde projet | **Fait** | Via FileProjectRepository + FileProjectMapRepository |
| Création / chargement / sauvegarde maps | **Fait** | Avec migration + validation |
| Undo / Redo (map) | **Fait** | MapHistoryCoordinator, 100 entrées max, stroke-based |
| Canvas éditeur (Flutter Canvas, pas Flame) | **Fait** | Zoom, pan, rendu layers identique au runtime |
| Rendu terrain/path/tile/entités/collision sur canvas | **Fait** | Même pipeline visuel que map_runtime |
| Animation entités multi-frames sur canvas | **Fait** | Timer.periodic ~110ms si nécessaire |
| Layers panel (visibilité, ordre) | **Fait** | |
| Tileset palette panel | **Fait** | |
| Entity properties panel (NPC, signe, item, spawn, custom) | **Fait** | Dropdown manifest pour dialogue principal + défaite, label "Dialogue (bibliothèque)", "Nœud Yarn (optionnel)", toggle "Bloque le mouvement" |
| Map properties panel (MapMetadata) | **Fait** | displayName, type, musique, météo, indoor, escapeRope, defaultSpawnId, tags |
| Map connections panel | **Fait** | |
| Warp properties panel | **Fait** | |
| Trigger properties panel | **Fait** | |
| Map inspector panel | **Fait** | |
| Terrain editor panel | **Fait** | |
| Gameplay zone properties panel | **Fait** | |
| Encounter tables panel | **Fait** | |
| Trainer library panel | **Fait** | |
| Project explorer panel | **Fait** | maps, groupes, tilesets, éléments, dialogues, dresseurs |
| EditorBrush (tile, palette, element) | **Fait** | |
| Édition visuels entités (editorVisual → ProjectElementEntry) | **Fait** | |
| Propriétés map avancées (hooks gameplay, flags progression) | **Non fait** | Identifié comme manquant |
| Interface dialogues avancée (éditeur Yarn intégré) | **Non fait** | Seulement référencement de fichiers .yarn |
| Comportements NPC éditables (IA, patrouille) | **Non fait** | |

### Exemples consommateurs

| Exemple | Statut | Notes |
|---------|--------|-------|
| `packages/map_runtime/example` | **Fait** | App Flutter interne au package, PlayableMapGame |
| `examples/playable_runtime_host` | **Fait** | App Flutter externe indépendante, même code, entitlements macOS sans sandbox |

**Redondance** : les deux exemples font exactement la même chose. L'exemple interne est une convention pub.dev ; l'externe valide la consommabilité depuis un projet tiers.

---

## 4. API publiques

### map_core (barrel complet, 35 exports)

Tout est exporté sans restriction `show`. Les exports couvrent :
- Modèles (`enums`, `geometry`, `tileset`, `map_data`, `map_entity_payloads`, `map_entity_editor_visual`, `map_gameplay_zone_payloads`, `map_layer`, `map_metadata`, `project_manifest`, `project_trainer`, `visual_frame_json`)
- Opérations (`map_resize`, `map_paint`, `map_collision`, `map_path`, `map_terrain`, `map_terrain_autotile`, `map_layers`, `map_connections`, `map_entities`, `map_triggers`, `map_warps`, `map_gameplay_zones`, `map_map_metadata`, `tileset_library_tree`, `dialogue_library_tree`, `project_dialogue_refs`)
- Validation (`validators`, `dialogue_validation`, `entity_editor_visual_validation`)
- Exceptions (`map_exceptions`)
- IO/compat (`legacy_editor_json_compat`)

### map_gameplay (barrel restrictif avec `show`)

```dart
Direction, DirectionX, EntityFacingX
GameplaySpawnResolutionException
resolveInitialPlayerSpawn
GameplayIntent, MoveIntent, InteractIntent
GameplayPlayerState
stepGameplayWorld
GameplayStepResult, Moved, Blocked, WarpTriggered, TriggeredWarp,
  NothingToInteract, NpcInteracted, SignInteracted, ItemInteracted, EntityInteracted
GameplayWorldState
```

### map_runtime (barrel restrictif avec `show`, 4 exports)

```dart
loadRuntimeMapBundle   // Future<RuntimeMapBundle>
RuntimeMapBundle       // manifest + map + tilesetPaths + cellWidth/Height
RuntimeMapGame         // FlameGame, viewer statique
PlayableMapGame        // FlameGame + KeyboardEvents, boucle jouable
```

### map_editor

Pas de barrel. Application desktop, pas un package consommable.

---

## 5. Consommabilité externe

`map_runtime` est consommable depuis un projet Flutter externe **avec les contraintes suivantes** :

| Point | État |
|-------|------|
| Dépendance locale `map_core` (path:) | Bloquant pour pub.dev, OK en monorepo |
| Dépendance locale `map_gameplay` (path:) | Idem |
| API publique propre (4 exports) | Oui |
| Entitlements macOS sandbox | À désactiver pour accès fichiers locaux (outil dev) |
| Chargement images via `dart:io` | Requiert accès filesystem — pas WASM/web |
| Pas de configuration runtime exposée | Le cellWidth/cellHeight vient du manifest |

La consommabilité est **réelle** pour du développement local. Pour une vraie publication pub.dev, il faudrait publier `map_core` et `map_gameplay` en amont.

---

## 6. Dette technique

### Dette dangereuse

*(Aucune dette dangereuse active.)*

### Dette tolérable

- **Deux exemples quasi-identiques** : `map_runtime/example` et `examples/playable_runtime_host` font la même chose. Duplication mineure, acceptable (convention pub.dev vs. validation externe).
- **Double définition Direction/EntityFacing** : `map_core` a `EntityFacing` (JSON-first), `map_gameplay` a `Direction` (runtime). Bridge via `EntityFacingX.asDirection`. Légèrement redondant mais justifié par la séparation des couches.
- **GameplayPlayerState non-Freezed** : plain class immuable avec copyWith manuel. Fonctionne mais moins cohérent avec le reste du domaine Freezed.
- **Constante 200ms hardcodée** dans `map_runtime` et `map_editor` (fallback frame animation). Devrait être cohérente entre les deux — à vérifier.

### Purement cosmétique

- `PROJECT_STATUS.md` (avant cet audit) : mentions contradictoires entre "visualiseur read-only" et "boucle jouable livrée" dans le même document.
- Numérotation "Runtime 1 / 2 / 3 / 4" dans l'historique des lots : fonctionnelle comme archive, pas comme documentation actuelle.

### Zones solides

- `map_core` : modèles, validation, migrations — très robuste, bien structuré.
- `map_gameplay` : boucle pure, prévisible, testable indépendamment.
- `map_editor` : state management Riverpod propre, undo/redo fonctionnel (stroke-based, 100 entrées).
- Séparation des couches : `map_editor` n'importe pas `map_runtime` ni `map_gameplay` — isolation correcte.

---

## 7. Prochaine milestone recommandée

**Prochaine recommandation : animations joueur orientées.**

Justification :
1. Le moteur Yarn avec branches (`<<jump>>` + options `->`) est livré et fonctionnel.
2. Le runtime dialogue est complet pour des RPG classiques (sans variables Yarn).
3. `PlayerComponent` ne dessine qu'un disque fixe — les sprites directionnels amélioreraient fortement la lisibilité du jeu.

**Ne pas faire maintenant** :
- Couches haut niveau (no-code, framework abstrait) — trop tôt.
- Publication pub.dev — les packages sont encore en `path:` local.
- Persistance sauvegarde — dépend d'une boucle de jeu plus complète.

**Déjà stabilisé (cette session)** :
- Warp failure : `catch (e, st)` avec log + notification visible.
- README `map_runtime` : corrigé, `PlayableMapGame` décrit correctement.
- Interactions entités : `InteractIntent`, 5 résultats typés, E/Space, overlay 2s, logs structurés.
- Dialogue Yarn MVP : parse .yarn, `DialogueSession`, `DialogueOverlayComponent`, blocage gameplay.
- Collision entités : `blocksMovement` (défaut true), toutes les cellules de `entity.size` enregistrées dans le cache, toggle dans l'inspecteur éditeur.

---

## 8. Archive des lots livrés (condensé)

| Lot | Date | Contenu |
|-----|------|---------|
| map_core — legacy JSON compat | 2026-03 | `migrateProjectManifestJson`, `migrateMapDataJson` extraits de l'éditeur vers map_core |
| map_editor — Visuel entités (Entity Visual Presentation) | 2026-03-25 | `MapEntityEditorVisual`, `resolvedProjectElementIdForEditor`, rendu canvas via `ProjectElementEntry.frames` |
| map_editor — Animation légère entités canvas | 2026-03-24 | Timer.periodic, `editorEntityAnimationMs`, cycle frames multi-frames |
| map_editor — Zones gameplay + tables rencontres | 2026-03-25 | `MapGameplayZone` payloads typés, `ProjectEncounterTable`, UI éditeur complet |
| map_editor — Entités structurées + DialogueRef | 2026-03 | Payloads npc/sign/item/spawn typés, DialogueRef, assignation dialogue NPC/signe |
| map_editor — Propriétés de map + Visuel éditeur dropdown | 2026-03 | MapMetadata panel, defaultSpawnId, editorVisual dropdown |
| map_editor — Refactoring zones gameplay (payloads typés + drag-to-draw) | 2026-03-25 | Réunification zones, drag sur canvas |
| map_editor — Dresseurs | 2026-03 | `ProjectTrainerEntry`, Trainer Library, champs combat dans inspecteur NPC |
| map_runtime — Runtime 1 (chargement + rendu Flame) | 2026-03-26 | loadRuntimeMapBundle, MapLayersComponent, RuntimeMapGame, example macOS |
| map_runtime — Runtime 2 (rendu entités animées) | 2026-03-26 | _paintEntities, _pickEntityFrame, _animElapsed |
| map_runtime — Runtime 3 (API cleanup) | 2026-03-26 | Renommage `manifestPath` → `projectFilePath`, images internes, barrel resserré, README |
| map_gameplay — Socle exploration | 2026-03-26 | Direction, GameplayPlayerState, GameplayWorldState, stepGameplayWorld, GameplayStepResult |
| map_gameplay — Spawn joueur | 2026-03-26 | resolveInitialPlayerSpawn, GameplayWorldState.fromMap, GameplaySpawnResolutionException |
| map_runtime — Runtime 4 (boucle jouable) | 2026-03-26 | PlayableMapGame, PlayerComponent, KeyboardEvents, warps, caméra follow-player |
| examples/playable_runtime_host | 2026-03-26 | App Flutter externe consommatrice de map_runtime, entitlements macOS sans sandbox |
| map_gameplay — Interactions + entity cache | 2026-03-27 | InteractIntent, entityAt(), _buildEntityByPos(), 5 résultats typés (NpcInteracted, SignInteracted, ItemInteracted, EntityInteracted, NothingToInteract) |
| map_runtime — Logs structurés + interactions + HUD | 2026-03-27 | E/Space → InteractIntent, overlay 2s via TextComponent HUD, logs [runtime]/[move]/[warp]/[interact], fix warp silence → catch (e, st) |
| map_runtime + map_editor — Clarification dialogue | 2026-03-27 | resolve_dialogue.dart (règle canonique + logs [dialogue]), defeat dialogue dropdown, labels UI "Dialogue (bibliothèque)"/"Nœud Yarn", fix chargement scriptPathRelative défaite |
| map_runtime — Dialogue Yarn MVP | 2026-03-27 | dialogue_runtime_models.dart (YarnNode, DialogueSession), parse_yarn_dialogue.dart, load_dialogue_content.dart, dialogue_overlay_component.dart (HUD ligne par ligne), PlayableMapGame branché (blocage gameplay, E/Space avance/ferme) |
| map_core + map_gameplay + map_editor — Collision entités | 2026-03-27 | MapEntity.blocksMovement (défaut true), _buildEntityByPos couvre toutes cellules de entity.size, isBlocked vérifie entity.blocksMovement, toggle "Bloque le mouvement" dans l'inspecteur éditeur |
| map_runtime — Yarn avec branches | 2026-03-27 | YarnStep sealed (YarnStepLine/Jump/ChoiceBlock), YarnChoice, DialogueSessionState sealed (ShowingLine/WaitingForChoice), _resolveStep() auto-exécute les <<jump>>, DialogueOverlayComponent mode choix (▶ curseur, ↑/↓, E valider), PlayableMapGame route les touches selon le mode |
