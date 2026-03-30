# Project Status — pokemonProject

> Dernière mise à jour : 2026-03-30 (runtime jouable consolidé : player animé + interpolation de pas + maintien des touches + tri de profondeur Y + NPC qui fait face au joueur ; collisions entités par footprint avec séparation interaction/blocage ; rencontres actives MVP walk ; transitions naturelles inter-maps via `MapConnection` + streaming de voisinage (maps adjacentes visibles) ; battle handoff MVP structuré encounter → transition → battle shell → reprise overworld ; **handoff battle trainer depuis interaction NPC** (`MapEntityNpcData.trainerId` → `TrainerBattleStartRequest` → battle) ; pipeline warp runtime propre avec verrouillage gameplay + fade out/in + validation cible + rollback ; warps avancés `onEnter`/`onBump` avec côtés actifs + padding d'activation éditable ; système personnages overworld : modèles, CRUD éditeur, composants Flame, éditeur d'animations visuel ; `Character` canonique pour joueur / NPC / trainers ; tuile éditeur `Tiles & Elements` refondue en double mode palette + gestion d'instances posées ; collisions d'éléments livrées via profils auto par preset + padding par élément + override par instance persistée ; rendu runtime foreground pour passer derrière les bâtiments ; animation locale des `MapPlacedElement` livrée en MVP (none/loop/pingPong, autoplay/speed/start offset/randomStart) ; authoring animation des éléments bibliothèque (`ProjectElementEntry.frames`) livré en MVP ; comportements d'instances posées hardenés côté runtime avec `behavior.id` stable, priorité explicite `onEnter > onExit > onNear`, cooldown anti-spam avec fallback runtime + override data `cooldownMs`, `triggerScope` MVP (`default`/`oncePerEnter`/`whileInsideSingleShot`/`facingOnly`/`nearCardinalOnly`) et debug overlay léger ; animation terrain/path multi-frames en runtime/éditeur, authoring des frames de path presets par variant + type de surface `Ground/Water` en UI éditeur, et mode de déplacement joueur `walk|surf` avec blocage eau explicite + feedback runtime ; **correction bug résolution dialogue scripté** : `_openDialogueForScript()` utilise `_bundle.projectRootDirectory` au lieu de `projectFilePath` ; **politique « single winner »** documentée et testée pour la résolution des multi-behaviors).
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
| `map_gameplay` | 0.1.0 | Dart pur | Boucle d'exploration : mouvement, collision, warps, connections, interactions entités + comportements d’éléments posés (`onAction`/`onEnter`/`onBump`/`onExit`/`onNear`), résolution spawn, check rencontres |
| `map_runtime` | 0.1.0 | Flutter + Flame | Chargement projet depuis disque, rendu Flame (layers + entités animées), boucle jouable au clavier |
| `map_editor` | 0.2.0 | Flutter desktop (macOS) | Éditeur GUI complet : maps, layers, entités, tilesets, terrains, paths, warps, triggers, zones, dialogues, dresseurs, rencontres |

---

## 3. Inventaire fonctionnel (état réel depuis le code)

### map_core

| Capacité | Statut | Notes |
|----------|--------|-------|
| Modèles freezed (MapData, ProjectManifest, entités, layers, warps, zones…) | **Fait** | Tous @freezed avec JSON serialization |
| `MapEntity.blocksMovement` (défaut true) | **Fait** | Intention de blocage ; la footprint effective est résolue côté gameplay (`resolveEntityCollisionCells`) |
| Enums métier complets (MapEntityKind, EntityFacing, MapLayerKind, TerrainType, PathSurfaceKind, GameplayZoneKind, etc.) | **Fait** | Très complet, 20+ enums |
| Géométrie (GridPos, GridSize, MapRect) | **Fait** | |
| Layers typés scellés (tile, collision, terrain, path, object) | **Fait** | Sealed class Dart 3, `whenOrNull` |
| Entités typées (npc, sign, item, spawn, custom) avec payloads | **Fait** | Freezed, payloads séparés |
| Métadonnées de map (MapMetadata) | **Fait** | displayName, type, musique, météo, indoor, escapeRope, defaultSpawnId, tags |
| Warps (MapWarp) | **Fait** | id, pos, targetMapId, targetPos, `triggerMode` (`onEnter`/`onBump`), `allowedApproachFacings`, `triggerPadding` (px) |
| Connexions inter-maps (MapConnection) | **Fait** | direction, targetMapId, offset |
| Triggers (MapTrigger) | **Fait** | id, name, type, area, properties |
| Zones gameplay typées (MapGameplayZone) | **Fait** | payloads : encounter, movement, hazard, special |
| Tables de rencontres (ProjectEncounterTable) | **Fait** | entries avec speciesId, niveaux, poids |
| Dialogues projet (ProjectDialogueEntry) | **Fait** | relativePath, tags, startNode, folderId |
| Dresseurs (ProjectTrainerEntry + équipe) | **Fait** | team[], moves[], held item, form, gender, shiny, `characterId?`, `portraitElementId?` |
| Personnages overworld (ProjectCharacterEntry) | **Fait** | id, name, tilesetId, frameWidth, frameHeight, animations[]: CharacterAnimation(state, direction, frames[]: CharacterAnimationFrame(source, durationMs)) |
| defaultPlayerCharacterId dans ProjectSettings | **Fait** | Définit seulement l'apparence initiale du joueur au lancement |
| CharacterAnimationState (idle, walk, run) | **Fait** | Enum + JSON |
| Validation personnages (validators.dart) | **Fait** | IDs uniques, tilesetId connu, dims positives, `defaultPlayerCharacterId`, `trainer.characterId` et `npc.characterId` référencent des Characters connus |
| Éléments visuels projet (ProjectElementEntry) | **Fait** | frames[], tilesetId, categoryId, groupId, `presetKind`, `collisionProfile` — multi-frames supporté |
| Profil collision élément (ElementCollisionProfile) | **Fait** | `source` (`generated`/`manual`) + cellules grille (`cells`) + `padding` (px) |
| Instances posées persistées (MapPlacedElement) | **Fait** | `MapData.placedElements` avec `layerId`, `elementId`, `pos`, `applyCollision`, `animation`, `behaviors`, `properties` |
| Animation d’instance posée (MapPlacedElementAnimation) | **Fait** | `enabled`, `mode` (`none`/`loop`/`pingPong`), `autoplay`, `speed`, `startOffsetMs`, `randomStart` + validation (`speed>0`, offset >= 0) |
| Comportements d’instance posée (MapPlacedElementBehavior/Effect) | **Fait (MVP étendu + hardening)** | Triggers typés (`onAction`/`onEnter`/`onBump`/`onExit`/`onNear`) + effets typés (`showMessage`/`openDialogue`/`setAnimationEnabled`/`playAnimationOnce`) + `behavior.id` stable + `cooldownMs` optionnel par behavior + `triggerScope` (`defaultScope`/`oncePerEnter`/`whileInsideSingleShot`/`facingOnly`/`nearCardinalOnly`) + migration legacy `interaction` -> `behaviors` |
| Presets terrain (ProjectTerrainPreset) | **Fait** | variants avec poids, frames[] |
| Presets path / autotile (ProjectPathPreset) | **Fait** | 20 variantes (corners, tees, cross, edges…) |
| Palette tilesets (TilesetPaletteEntry) | **Fait** | |
| Validation projet (ProjectValidator) | **Fait** | Unicité IDs, hiérarchies, cycles, frames, chemins dialogues |
| Validation map (MapValidator) | **Fait** | Inclut validation `editorVisual` contre projet, cohérence `placedElements` (ids/layers/elements/bounds) |
| Migrations JSON legacy (migrateProjectManifestJson, migrateMapDataJson) | **Fait** | Appliquées à la désérialisation |
| Migration entités legacy (migrateMapEntityJson) | **Fait** | Convertit ancien format properties plat → payloads typés |
| Migration zones gameplay legacy | **Fait** | `transition` → `special`, payloads aplatis → typés |
| Opérations pures sur les données (18+ modules) | **Fait** | Resize, paint, collision, terrain, path, layers, entities, warps, triggers, zones, connections, metadata, `map_placed_elements`, tileset/dialogue library trees |
| Opérations pures animation/comportement d’instance posée | **Fait** | Animation: `set/reset/setEnabled`; Behaviors: `set/add/update/remove/setEnabledAt` |
| Exceptions hiérarchisées (ValidationException, ProjectLoadException, etc.) | **Fait** | Sealed class |

### map_gameplay

| Capacité | Statut | Notes |
|----------|--------|-------|
| Direction (enum + extensions dx/dy/asFacing) | **Fait** | |
| EntityFacingX.asDirection (bridge map_core ↔ gameplay) | **Fait** | |
| GameplayPlayerState (pos, facing, movementMode, copyWith) | **Fait** | Plain class immuable, pas Freezed ; `movementMode` (`walk`/`surf`) extensible |
| GameplayWorldState (collision cache, warp cache, caches entités) | **Fait** | Cache plat List<bool> + 2 caches row-major : `blockingEntityByPos` (blocage) et `entityByPos` (interaction), spawns exclus ; cache warp par zone d’activation (padding) ; inclut collisions d’instances `placedElements` quand `applyCollision=true` et profil élément présent |
| GameplayWorldState water cache | **Fait** | Cache `isWaterCell` construit depuis path presets `surfaceKind=water` et zones movement surf ; `movementBlockReasonAt(...)` expose une raison typée (`solid`/`outOfBounds`/`waterRequiresSurf`) |
| GameplayWorldState.initial (pos + facing explicites) | **Fait** | Ne valide pas la cellule ; accepte `project` optionnel pour collisions d’éléments |
| GameplayWorldState.fromMap (spawn automatique) | **Fait** | Lance exception si spawn bloqué ; accepte `project` optionnel |
| Résolution spawn : defaultSpawnId → playerStart (tri par id) → exception | **Fait** | |
| stepGameplayWorld (move intent → result) | **Fait** | Turn-face + raison de blocage typée (`solid`/`outOfBounds`/`waterRequiresSurf`) + règle eau selon `movementMode` (`walk` bloque, `surf` autorise) + warp `onBump` (sur case bloquée) + warp `onEnter` (sur case d’arrivée) + détection sortie connectée (`MapConnection`) + triggers placés `onEnter` puis `onExit` puis `onNear` (transition déterministe) + filtres `triggerScope` (réarmement entrée/sortie, `facingOnly`, proximité cardinale explicite) |
| stepGameplayWorld (interact intent → result) | **Fait** | Cellule devant joueur → NPC/sign/item/entity/nothing |
| Résolution pure d'arrivée connection | **Fait** | `resolveConnectedMapTargetPos(...)` avec convention canonique `targetAxis = sourceAxis - offset` |
| Check rencontre gameplay (MVP) | **Fait** | `checkEncounterAtPlayerPosition(...)` : lookup zone encounter (priorité max), filtre `EncounterKind`, lookup table projet, roll chance par pas, tirage pondéré espèce + niveau |
| Résultat rencontre typé | **Fait** | `GameplayEncounter` + `GameplayEncounterCheckResult` (+ `toJson/fromJson` pour `GameplayEncounter`) |
| Résultats scellés (Moved, Blocked, WarpTriggered, ConnectionTriggered, TriggeredWarp, TriggeredConnection) | **Fait** | `Blocked.reason` typé côté gameplay |
| Résultats interaction | **Fait** | `NothingToInteract`, `NpcInteracted`, `SignInteracted`, `ItemInteracted`, `EntityInteracted`, `PlacedElementInteracted(element, behavior, trigger)` |
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
| Rendu TerrainLayer (variantes + animation preset) | **Fait** | Graine : coordonnées + preset.id.hashCode → variante déterministe ; frames terrain animées en boucle (durées `durationMs`, fallback) |
| Rendu PathLayer (autotile 20 variantes + animation preset) | **Fait** | RuntimePathAutotileSet depuis ProjectPathPreset, lecture des frames de variant selon temps écoulé |
| Rendu entités animées (multi-frames) | **Fait** | _pickEntityFrame avec cycle durationMs (fallback 200ms) |
| Rendu CollisionLayer (overlay semi-transparent) | **Fait** | Visible si couche visible dans les données |
| Ordre de rendu : terrain → path → tile → entités → collision | **Fait** | Identique à l'éditeur, avec split runtime background/foreground |
| Rendu runtime foreground | **Fait** | Passe foreground (toits/overlay) basée sur couches nommées `foreground|fg|above|overlay|front|roof|toit` + cellules non-collision des `placedElements` |
| Rendu runtime des `placedElements` animés | **Fait** | Animation par instance via `MapPlacedElement.animation` sur `ProjectElementEntry.frames` (mode none/loop/pingPong, autoplay, speed, startOffset, randomStart déterministe par `instance.id`) |
| RuntimeMapGame (viewer statique) | **Fait** | Caméra = map entière visible |
| PlayableMapGame (jouable au clavier) | **Fait** | KeyboardEvents : flèches + WASD + E/Space, maintien de touche, file warp post-step, tri de profondeur par Y |
| Mode déplacement runtime (`walk|surf`) | **Fait (MVP)** | API `setPlayerMovementMode` / `setSurfingEnabled`, et toggles debug dans les 2 apps exemple runtime |
| PlayerComponent (runtime actor joueur) | **Fait** | Sprite personnage via `OverworldActorComponent` (idle/walk) + interpolation de pas ; fallback disque bleu si aucun Character |
| OverworldActorComponent | **Fait** | Composant Flame : rendu sprite personnage depuis spritesheet, animation time-based, facing + state, fallback cercle vert |
| Sprites personnages NPC dans PlayableMapGame | **Fait** | _addNpcActors, skip rendu entité dans MapLayersComponent si `npc.characterId` ou fallback `trainer.characterId` est défini |
| NPC se tourne vers le joueur à l'interaction | **Fait** | `NpcInteracted` → `_faceNpcTowardPlayer()` avant ouverture dialogue |
| Résolution tilesets personnages (runtime_manifest_tilesets) | **Fait** | Collecte tilesets joueur + NPCs pour préchargement via Character |
| Collisions au clavier via map_gameplay | **Fait** | Inclut collisions layers, entités bloquantes et collisions d’instances d’éléments (`MapPlacedElement` + `collisionProfile`) |
| Warps : pipeline runtime explicite | **Fait** | `WarpTriggered` traité post-step avec garde de phase, clear état transitoire, `WarpTransitionOverlayComponent` (fade out/in), chargement cible, validation bornes + blocage, swap map atomique puis unlock ; `onBump` ne lance pas de faux pas interpolé |
| Connections : transition naturelle inter-map | **Fait** | Sortie hors bornes -> `ConnectionTriggered` -> résolution map cible, calcul case d'entrée, pas interpolé source→cible, refus si entrée invalide/bloquée |
| Streaming maps adjacentes | **Fait** | Map active + voisines connectées (et précédente immédiate) restent montées simultanément pour continuité visuelle |
| Interactions entités + comportements d’éléments posés (E/Space + move) | **Fait (MVP étendu + hardening)** | Triggers exécutés côté runtime/gameplay : `onAction`/`onEnter`/`onBump`/`onExit`/`onNear` ; effets actifs : `showMessage`, `openDialogue`, `setAnimationEnabled`, `playAnimationOnce` ; anti-spam runtime par cooldown `(instanceId, behaviorId, trigger, effectType)` avec fallback policy runtime et override data `behavior.cooldownMs` ; scopes de déclenchement `triggerScope` appliqués côté gameplay |
| Rencontres actives MVP (`walk`/`surf` selon mode) | **Fait** | Check déclenché sur `Moved` uniquement, jamais sur `Blocked`/`WarpTriggered`, ni hors phase overworld ; kind transmis = `walk` ou `surf` selon `player.movementMode` |
| BattleStartRequest (handoff runtime) | **Fait** | Modèle dédié `BattleStartRequest` + variantes `WildBattleStartRequest` / `TrainerBattleStartRequest` + `OverworldReturnContext` |
| Mapping rencontre → battle request | **Fait** | `buildBattleStartRequestFromEncounter(...)` en couche application runtime (testable, sans UI) |
| État runtime centralisé | **Fait** | Phases `overworld` / `dialogue` / `mapTransition` / `battleTransition` / `battle` dans `PlayableMapGame` |
| Transition visuelle battle | **Fait** | `BattleTransitionOverlayComponent` (suspension gameplay + handoff visuel court) |
| Battle shell minimal | **Fait** | `BattleOverlayComponent` (infos combat, sortie test, point d'entrée futur système de combat) |
| Reprise overworld après battle | **Fait** | Fermeture overlay battle → cleanup strict + restauration contrôle joueur |
| Transition visuelle warp | **Fait** | `WarpTransitionOverlayComponent` couvre le viewport pendant le changement de map |
| Priorité warp vs connection | **Fait** | Warp explicite prioritaire ; connection appliquée seulement sur sortie hors bornes sans warp |
| Logs structurés runtime | **Fait** | Préfixes `[runtime]` `[warp]` `[connection]` `[interact]` `[dialogue]` `[encounter]` `[battle]` et `[placed_behavior]` via debugPrint |
| Debug behaviors runtime | **Fait** | `PlayableMapGame.setBehaviorDebugOverlayVisible(bool)` affiche le dernier behavior déclenché/filtré ; utilisé par `map_runtime/example` |
| HUD notification 2s | **Fait** | TextComponent sur camera.viewport |
| Feedback blocage eau sans surf | **Fait** | Message runtime dédié : `On ne peut pas aller sur l’eau sans un Pokémon ayant Surf.` (cooldown anti-spam local) |
| Caméra follow-player (~15×11 tuiles viewport) | **Fait** | |
| Fallback spawn (0,0) si pas de spawn configuré | **Fait** | PlayableMapGame.onLoad catch GameplaySpawnResolutionException |
| Barrel public runtime + handoff battle | **Fait** | Exporte `BattleStartRequest` (+ variantes), mapper encounter→battle, loadRuntimeMapBundle, RuntimeMapBundle, RuntimeMapGame, PlayableMapGame |
| Résolution dialogue (`resolveDialogue`) | **Fait** | Résout fichier .yarn + startNode, logs [dialogue] ; utilise `_bundle.projectRootDirectory` (corrigé 2026-03-30) |
| Parser Yarn (`parseYarnFile`) | **Fait** | `YarnStepLine`, `YarnStepJump`, `YarnStepChoiceBlock`, `YarnChoice` — détecte `<<jump X>>` et blocs `->` avec corps indentés |
| Moteur dialogue (`DialogueSession`) | **Fait** | `advance()`, `moveChoiceCursor()`, `confirmChoice()` ; résolution automatique des `<<jump>>` via `_resolveStep()` |
| Chargement dialogue (`loadDialogueContent`) | **Fait** | Lecture .yarn → parse → DialogueSession, fallback premier nœud |
| UI dialogue runtime (`DialogueOverlayComponent`) | **Fait** | Mode ligne (E · Suite/Fermer) + mode choix (▶ curseur, ↑/↓, E valider) |
| Blocage gameplay pendant dialogue | **Fait** | `_dialogueOverlay != null` bloque mouvement + re-interaction ; clavier routé selon mode (ligne/choix) |
| Rencontres `rod` / `special` | **Non fait** | `EncounterKind.surf` est désormais demandé quand le mode joueur est `surf`, mais les règles de progression/transition auto rive ne sont pas encore livrées |
| Système de combat complet | **Non fait** | Battle shell uniquement : pas de tours, attaques, HP, capture, IA trainer |
| Streaming multi-hop profond | **Non fait** | Le runtime ne garde pas un graphe large de maps lointaines, seulement le voisinage immédiat utile |
| Comportements NPC (patrouille, LoS) | **Non fait** | |
| Sauvegarde/chargement état jeu | **Non fait** | |

Convention runtime `MapConnection` appliquée :
- `offset` est le décalage de la map cible par rapport à la source sur l’axe partagé.
- Formule unique : `targetAxis = sourceAxis - offset`.
- Direction `east` / `west` : `targetY = sourceY - offset`, entrée côté opposé (`x=0` ou `x=width-1`).
- Direction `north` / `south` : `targetX = sourceX - offset`, entrée côté opposé (`y=height-1` ou `y=0`).
- Si la case d’entrée calculée est hors bornes ou bloquée, la transition est refusée avec log `[connection]`.

Convention gameplay/runtime `MapWarp` appliquée :
- `triggerMode=onEnter` : déclenchement après déplacement réussi vers une cellule de la zone d’activation.
- `triggerMode=onBump` : déclenchement quand la tentative de déplacement est bloquée sur une cellule de la zone d’activation.
- `allowedApproachFacings` représente le côté depuis lequel le joueur arrive (et non sa direction brute), ex. porte active par le bas => `south`.
- `triggerPadding` élargit la zone d’activation autour de la cellule warp en pixels (`top/right/bottom/left`).

### map_editor

| Capacité | Statut | Notes |
|----------|--------|-------|
| Création / chargement / sauvegarde projet | **Fait** | Via FileProjectRepository + FileProjectMapRepository |
| Création / chargement / sauvegarde maps | **Fait** | Avec migration + validation |
| Undo / Redo (map) | **Fait** | MapHistoryCoordinator, 100 entrées max, stroke-based |
| Canvas éditeur (Flutter Canvas, pas Flame) | **Fait** | Zoom, pan, rendu layers identique au runtime |
| Rendu terrain/path/tile/entités/collision sur canvas | **Fait** | Même pipeline visuel que map_runtime |
| Animation entités + surfaces sur canvas | **Fait** | Timer.periodic ~110ms si nécessaire ; presets terrain/path multi-frames animés en preview et rendu map |
| Layers panel (visibilité, ordre) | **Fait** | |
| Tiles & Elements panel (palette + instances posées) | **Fait** | Mode palette conservé (tileset/filtres/sélection/placement) + mode instances posées sur le layer actif (liste persistée + sélection + panneau détail) |
| Sélection d’instance posée centralisée | **Fait** | `EditorState.tilesElementsPanelMode` + `selectedPlacedElementInstanceId`, sélection via `EditorNotifier`, surlignage de l’instance sélectionnée sur le canvas |
| Génération auto collision élément | **Fait** | Service `ElementCollisionProfileGenerator` (alpha coverage) + presets `tree/building/rock/cliff/tallDecoration/generic` |
| Édition collision élément (visuelle) | **Fait** | Preview du sprite + overlay cellules collision éditables, padding (px) par élément avec preview visuelle, sauvegarde profil `manual` |
| Sync instances posées depuis tuiles | **Fait** | `PlacedElementInstanceIndexer` synchronise `MapData.placedElements` au chargement et après peinture/effacement |
| Animation locale des instances posées | **Fait** | Panneau détail instance: `enabled`, mode, autoplay, speed, randomStart, startOffset; preview locale animée; persistance via `EditorNotifier.setPlacedElementInstanceAnimationConfig` |
| Authoring animation des éléments bibliothèque | **Fait** | Édition `ProjectElementEntry.frames` dans le dialog Edit Element: ajout frame visuel depuis tileset, suppression, duplication, réordonnancement, durée par frame, preview animée |
| Entity properties panel (NPC, signe, item, spawn, custom) | **Fait** | Dropdown manifest pour dialogue principal + défaite, label "Dialogue (bibliothèque)", "Nœud Yarn (optionnel)", toggle "Bloque le mouvement" |
| Map properties panel (MapMetadata) | **Fait** | displayName, type, musique, météo, indoor, escapeRope, defaultSpawnId, tags |
| Map connections panel | **Fait** | |
| Warp properties panel | **Fait** | Édition mode (`onEnter`/`onBump`), côtés actifs (N/S/E/W), padding d’activation (top/right/bottom/left px), presets rapides porte + preview visuelle sur canvas |
| Trigger properties panel | **Fait** | |
| Map inspector panel | **Fait** | |
| Terrain editor panel | **Fait** | Édition path preset enrichie : type de surface produit `Ground/Water`, mapping visuel des variants autotile, et authoring d’animation `frames[]` par variant (ajout/suppression/duplication/réordonnancement/durée + preview animée) |
| Gameplay zone properties panel | **Fait** | |
| Encounter tables panel | **Fait** | |
| Trainer library panel | **Fait** | CRUD dresseurs + sélection de `Character` overworld |
| Character library panel | **Fait** | CRUD personnages, désignation du `Default Player Character` ; éditeur d'animations visuel : grille 3×4 (états × directions), sélecteur spritesheet par frame complète (clic sélectionne frameWidth×frameHeight tiles d'un coup), frame strip avec miniatures, preview animée en direct, contrôles durée / réordonnement / suppression ; supporte naturellement 3 frames par direction (walk cycle classique) |
| Entity properties panel — NPC characterId | **Fait** | Dropdown pour assigner un personnage-sprite à chaque entité NPC |
| Project Settings — Default Player Character | **Fait** | Sélecteur depuis la Character Library, explicité comme valeur initiale uniquement |
| Project explorer panel | **Fait** | maps, groupes, tilesets, éléments, dialogues, dresseurs, personnages |
| EditorBrush (tile, palette, element) | **Fait** | |
| Édition visuels entités (editorVisual → ProjectElementEntry) | **Fait** | |
| Propriétés d’instance posée (collision/animation/comportements) | **Fait (MVP étendu)** | Collision + animation locale + comportements (liste, trigger, effet) éditables dans `Tiles & Elements`; saisie texte stabilisée via draft local + commit contrôlé; aides UX explicites trigger/effect et frontière `PlacedElement` vs `MapEntity`; dropdown script+nœud Yarn; `playAnimationOnce` exécuté côté runtime |
| Propriétés map avancées (hooks gameplay, flags progression) | **Non fait** | Identifié comme manquant |
| Interface dialogues avancée (éditeur Yarn intégré) | **Non fait** | Seulement référencement de fichiers .yarn |
| Comportements NPC éditables (IA, patrouille) | **Non fait** | |

### Exemples consommateurs

| Exemple | Statut | Notes |
|---------|--------|-------|
| `packages/map_runtime/example` | **Fait** | App Flutter interne au package, PlayableMapGame + toggles `Collisions` et `Behaviors` (debug overlay) |
| `examples/playable_runtime_host` | **Fait** | App Flutter externe indépendante, même code, entitlements macOS sans sandbox |

**Redondance** : les deux exemples font exactement la même chose. L'exemple interne est une convention pub.dev ; l'externe valide la consommabilité depuis un projet tiers.

---

## 4. API publiques

### map_core (barrel complet, 36 exports)

Tout est exporté sans restriction `show`. Les exports couvrent :
- Modèles (`enums`, `geometry`, `tileset`, `map_data`, `map_entity_payloads`, `map_entity_editor_visual`, `map_gameplay_zone_payloads`, `map_layer`, `map_metadata`, `project_manifest`, `project_trainer`, `visual_frame_json`, `element_collision_profile`)
- Opérations (`map_resize`, `map_paint`, `map_collision`, `map_path`, `map_terrain`, `map_terrain_autotile`, `map_layers`, `map_connections`, `map_entities`, `map_triggers`, `map_warps`, `map_gameplay_zones`, `map_map_metadata`, `map_placed_elements`, `tileset_library_tree`, `dialogue_library_tree`, `project_dialogue_refs`)
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
resolveConnectedMapTargetPos
stepGameplayWorld
GameplayStepResult, Moved, Blocked, WarpTriggered, ConnectionTriggered,
  TriggeredWarp, TriggeredConnection,
  NothingToInteract, NpcInteracted, SignInteracted, ItemInteracted, EntityInteracted
GameplayWorldState
```

### map_runtime (barrel restrictif avec `show`, runtime + handoff battle)

```dart
RuntimeBattleKind / RuntimeBattleSourceKind
OverworldReturnContext
BattleStartRequest / WildBattleStartRequest / TrainerBattleStartRequest
buildBattleStartRequestFromEncounter
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
| API publique propre | Oui |
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

**Prochaine recommandation : ajouter une politique de résolution de multi-effets sur un même trigger (MVP limité), sans transformer `MapPlacedElement` en moteur de script.**

Justification :
1. La chaîne data → édition → gameplay/runtime est maintenant en place pour l’identité (`behavior.id`), le cooldown (`cooldownMs`) et le scope (`triggerScope`).
2. Le prochain gain produit utile est de clarifier l’exécution quand plusieurs effets/behaviors deviennent valides dans le même tick, pour éviter les ambiguïtés de priorités côté UX.
3. Cette étape reste locale et déterministe, sans élargir prématurément le modèle vers un DSL.

**Ne pas faire maintenant** :
- Couches haut niveau (no-code, framework abstrait) — trop tôt.
- Publication pub.dev — les packages sont encore en `path:` local.
- Persistance sauvegarde — dépend d'une boucle de jeu plus complète.

**Déjà stabilisé (cette session)** :
- Warp runtime robuste : pipeline verrouillé, logs `[warp]` structurés (trigger/start/load/place/complete/fail/unlock), validation `targetPos`, rollback best-effort vers la map source en cas d'échec pré-swap.
- README `map_runtime` : corrigé, `PlayableMapGame` décrit correctement.
- Interactions entités : `InteractIntent`, 5 résultats typés, E/Space, overlay 2s, logs structurés.
- Dialogue Yarn MVP : parse .yarn, `DialogueSession`, `DialogueOverlayComponent`, blocage gameplay.
- Collision entités : footprint configurable (`collision.*` + alias legacy), NPC par défaut en 1×1 ; séparation cache interaction / cache blocage ; entités `custom` non bloquantes par défaut sans override explicite.
- Rencontres actives MVP : `checkEncounterAtPlayerPosition`, tirage pondéré, niveau aléatoire, logs `[encounter]`, avec kind `walk|surf` selon `movementMode`.
- Battle handoff MVP : `BattleStartRequest` (wild/trainer-ready), mapper `buildBattleStartRequestFromEncounter`, `BattleTransitionOverlayComponent`, `BattleOverlayComponent`, états runtime centralisés, logs `[battle]`.
- Connections runtime : `ConnectionTriggered`, calcul d’entrée canonique via `resolveConnectedMapTargetPos`, priorité warp > connection, logs `[connection]`, refus déterministe des entrées invalides/bloquées, streaming de voisinage et transition interpolée sans coupure visuelle.
- Collisions d’éléments + override par instance : `ElementPresetKind`, `ElementCollisionProfile` (`generated`/`manual`), `MapData.placedElements` + `applyCollision`, génération auto via analyse alpha, édition visuelle collision dans l’éditeur, prise en compte gameplay/runtime via `GameplayWorldState(project: ...)`.
- Animation locale d’instances posées : `MapPlacedElement.animation`, validations core, opérations pures de mise à jour/reset, UI éditeur dédiée avec preview, rendu runtime par instance (loop/pingPong/autoplay/randomStart déterministe).
- Comportements d’instances posées : `MapPlacedElement.behaviors` typé, migration legacy `interaction`, triggers `onAction/onEnter/onBump/onExit/onNear` branchés gameplay/runtime, effets MVP (`showMessage`, `openDialogue`, `setAnimationEnabled`, `playAnimationOnce`) branchés.
- Behavior Runtime Hardening : `MapPlacedElementBehavior.id` stable (JSON + migration legacy + validation + normalisation), priorité mouvement explicite `onEnter > onExit > onNear`, résolution déterministe sur chevauchement (ordre `map.placedElements` puis ordre `behaviors`), anti-spam runtime par cooldown `(instanceId, behaviorId, trigger, effectType)`, et debug overlay léger activable.
- Cooldown configurable par behavior (MVP limité) : `MapPlacedElementBehavior.cooldownMs` optionnel (validation core `0..600000`), UI éditeur “Cooldown explicite” (fallback runtime vs override), et runtime qui applique `behavior.cooldownMs` quand renseigné.
- Trigger scope MVP : `MapPlacedElementBehavior.triggerScope` (`defaultScope`, `oncePerEnter`, `whileInsideSingleShot`, `facingOnly`, `nearCardinalOnly`) avec validation de compatibilité trigger/scope côté core, filtrage déterministe côté gameplay (`onAction`, `onEnter`, `onNear`) et UI éditeur avec options restreintes selon le trigger + aide contextuelle.
- Authoring animation d’éléments bibliothèque : `UpdateProjectElementUseCase` accepte `frames`, UI d’édition des frames dans `TilesetPalettePanel`, preview et persistance sur `ProjectElementEntry.frames`.
- Water Animation + Movement Mode MVP : animation des presets terrain/path multi-frames en runtime/éditeur, `GameplayPlayerState.movementMode` (`walk|surf`), blocage eau typé (`waterRequiresSurf`) côté gameplay, message runtime dédié et point d’entrée debug pour basculer en surf.

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
| map_core + map_editor + map_runtime — Characters canonique overworld | 2026-03-27 | `defaultPlayerCharacterId`, `trainer.characterId`, NPC/Trainer UI via Character Library, runtime fallback trainer→character pour acteurs overworld |
| map_runtime — Runtime 1 (chargement + rendu Flame) | 2026-03-26 | loadRuntimeMapBundle, MapLayersComponent, RuntimeMapGame, example macOS |
| map_runtime — Runtime 2 (rendu entités animées) | 2026-03-26 | _paintEntities, _pickEntityFrame, _animElapsed |
| map_runtime — Runtime 3 (API cleanup) | 2026-03-26 | Renommage `manifestPath` → `projectFilePath`, images internes, barrel resserré, README |
| map_gameplay — Socle exploration | 2026-03-26 | Direction, GameplayPlayerState, GameplayWorldState, stepGameplayWorld, GameplayStepResult |
| map_gameplay — Spawn joueur | 2026-03-26 | resolveInitialPlayerSpawn, GameplayWorldState.fromMap, GameplaySpawnResolutionException |
| map_runtime — Runtime 4 (boucle jouable) | 2026-03-26 | PlayableMapGame, PlayerComponent, KeyboardEvents, warps, caméra follow-player |
| examples/playable_runtime_host | 2026-03-26 | App Flutter externe consommatrice de map_runtime, entitlements macOS sans sandbox |
| map_gameplay — Interactions + entity cache | 2026-03-27 | InteractIntent, entityAt(), _buildEntityByPos(), 5 résultats typés (NpcInteracted, SignInteracted, ItemInteracted, EntityInteracted, NothingToInteract) |
| map_runtime — Logs structurés + interactions + HUD | 2026-03-27 | E/Space → InteractIntent, overlay 2s via TextComponent HUD, logs [runtime]/[warp]/[interact], fix warp silence → catch (e, st) |
| map_runtime + map_editor — Clarification dialogue | 2026-03-27 | resolve_dialogue.dart (règle canonique + logs [dialogue]), defeat dialogue dropdown, labels UI "Dialogue (bibliothèque)"/"Nœud Yarn", fix chargement scriptPathRelative défaite |
| map_runtime — Dialogue Yarn MVP | 2026-03-27 | dialogue_runtime_models.dart (YarnNode, DialogueSession), parse_yarn_dialogue.dart, load_dialogue_content.dart, dialogue_overlay_component.dart (HUD ligne par ligne), PlayableMapGame branché (blocage gameplay, E/Space avance/ferme) |
| map_core + map_gameplay + map_editor — Collision entités | 2026-03-27 | MapEntity.blocksMovement + `resolveEntityCollisionCells`, footprint configurable (`collision.*` + alias legacy), NPC par défaut 1×1, toggle "Bloque le mouvement" |
| map_runtime — Yarn avec branches | 2026-03-27 | YarnStep sealed (YarnStepLine/Jump/ChoiceBlock), YarnChoice, DialogueSessionState sealed (ShowingLine/WaitingForChoice), _resolveStep() auto-exécute les <<jump>>, DialogueOverlayComponent mode choix (▶ curseur, ↑/↓, E valider), PlayableMapGame route les touches selon le mode |
| map_runtime + map_gameplay — Polish déplacement/collisions | 2026-03-27 | Maintien de touches + interpolation visuelle des pas, tri de profondeur Y, NPC qui fait face au joueur en interaction, séparation caches blocage/interaction, blocage `custom` seulement sur override collision explicite |
| map_gameplay + map_runtime — Rencontres actives MVP walk | 2026-03-27 | `checkEncounterAtPlayerPosition` (zone overlap priorité, filtre kind, table lookup, chance par pas, tirage pondéré, niveau random), `GameplayEncounter` typé, logs `[encounter]` |
| map_gameplay + map_runtime — Connections naturelles runtime + streaming voisinage | 2026-03-27 | `ConnectionTriggered` dans `stepGameplayWorld`, `resolveConnectedMapTargetPos` (convention offset canonique), maps adjacentes montées en parallèle, transition interpolée source→cible dans `PlayableMapGame`, priorité warp>connection, logs `[connection]`, refus propre des entrées invalides/bloquées |
| map_runtime — Battle handoff MVP | 2026-03-27 | `BattleStartRequest` + mapper rencontre→battle, `BattleTransitionOverlayComponent`, `BattleOverlayComponent`, état runtime centralisé (overworld/dialogue/mapTransition/battleTransition/battle), reprise overworld propre, logs `[battle]` |
| map_runtime — Warp transition pipeline | 2026-03-27 | Nouveau `WarpTransitionOverlayComponent`, fade out/in autour du warp, validation `targetPos` (bornes + cellule libre), rollback runtime best-effort si échec avant swap, logs `[warp]` enrichis |
| map_core + map_gameplay + map_editor + map_runtime — Warp activation avancée | 2026-03-27 | `MapWarp.triggerMode` (`onEnter`/`onBump`), `allowedApproachFacings`, `triggerPadding`; résolution gameplay côté approche réelle; runtime `onBump` sans faux pas; panneau warp enrichi (mode/côtés/padding/presets) + preview canvas de zone active |
| map_core + map_editor + map_gameplay + map_runtime — Element Collision Profiles + Instance Collision Overrides | 2026-03-28 | `ProjectElementEntry.presetKind` + `collisionProfile`, nouveau `MapData.placedElements` (`MapPlacedElement.applyCollision`), génération auto collision par analyse alpha et preset, éditeur visuel collision, sync instances persistées, toggle collision par instance, collisions prises en compte dans `GameplayWorldState(project: ...)` et donc en runtime |
| map_core + map_editor + map_runtime — Placed Element Instance Animation MVP | 2026-03-28 | `MapPlacedElement.animation` typé (`enabled`, `mode`, `autoplay`, `speed`, `startOffsetMs`, `randomStart`), validation core, opérations pures set/reset/enable, UI édition/preview par instance dans Tiles & Elements, rendu runtime des éléments posés animé avec randomStart déterministe par `instance.id` |
| map_core + map_editor + map_gameplay + map_runtime — Placed Element Triggers & Effects MVP (extension) | 2026-03-28 | `MapPlacedElement.behaviors` étendu avec triggers `onExit`/`onNear`, priorité move déterministe (`onEnter` > `onExit` > `onNear`), exécution runtime réelle de `playAnimationOnce` via état transitoire par `instanceId` (stratégie restart), UI éditeur trigger/effect mise à jour + dropdown script+nœud Yarn, tests core/gameplay ajoutés |
| map_core + map_gameplay + map_runtime — Behavior Runtime Hardening | 2026-03-29 | `MapPlacedElementBehavior.id` ajouté et normalisé (JSON + migration legacy + validation d’unicité par instance), résolution gameplay déterministe testée (priorité `onEnter > onExit > onNear`, chevauchements éléments/behaviors), cooldown anti-spam runtime par clé `(instanceId, behaviorId, trigger, effectType)`, `setAnimationEnabled` idempotent, debug overlay behaviors activable dans `PlayableMapGame` + toggle dans l’exemple runtime |
| map_core + map_editor + map_runtime — Behavior Cooldown Data Override MVP | 2026-03-29 | `MapPlacedElementBehavior.cooldownMs` optionnel dans le modèle (JSON + compat legacy), validation map core (`0..600000`), UI éditeur de behavior (`Cooldown explicite` + presets 250/500/1000ms), et runtime gate qui garde la policy par défaut mais applique l’override par behavior quand présent |
| map_core + map_gameplay + map_editor + map_runtime — Behavior Trigger Scope MVP | 2026-03-29 | `MapPlacedElementBehavior.triggerScope` optionnel avec défaut compatible legacy, validation core des couples trigger/scope, filtres gameplay (`oncePerEnter`, `whileInsideSingleShot`, `facingOnly`, `nearCardinalOnly`), logs runtime enrichis (`scope=...`) et UI éditeur avec menu scope dépendant du trigger |
| map_editor + map_runtime + map_core — Element Library Animation Authoring MVP | 2026-03-28 | Édition des `ProjectElementEntry.frames` dans l’éditeur d’éléments (frame strip, preview animée, ajout visuel depuis tileset, duplication, suppression, réordonnancement, durée par frame) + persistance via `updateProjectElement(frames: ...)`; runtime inchangé sur le fond et consomme directement ces frames pour les instances animées |
| map_gameplay + map_runtime + map_editor — Water Animation + Movement Mode `walk|surf` MVP | 2026-03-29 | Animation des frames de presets terrain/path (eau incluse) en runtime et canvas éditeur ; `GameplayPlayerState.movementMode` + `Blocked.reason` typé (`waterRequiresSurf`) ; eau traversable seulement en surf ; feedback runtime explicite sur tentative sans surf ; toggle surf debug dans les exemples runtime |
