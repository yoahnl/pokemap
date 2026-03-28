# AI_PROJECT_STATE — pokemonProject

> Fichier pensé pour une IA. Dense, factuel, centré sur l'état réel du code.
> Source : audit complet du code (2026-03-26), mis à jour 2026-03-28 (interactions runtime + clarification dialogue + dialogue Yarn MVP runtime + système personnages overworld + éditeur d'animations visuel ; consolidation `Character` comme abstraction canonique joueur / NPC / trainer ; player animé avec déplacement interpolé, NPC qui fait face au joueur, tri de profondeur, collisions entités par footprint, rencontres actives MVP walk, transitions naturelles inter-maps via `MapConnection`, streaming de maps adjacentes côté runtime, battle handoff MVP structuré encounter → transition → battle shell → retour overworld, pipeline warp runtime verrouillé avec transition fade + rollback, warps gameplay avancés `onEnter`/`onBump` + côtés actifs + padding d’activation, refonte `Tiles & Elements` côté éditeur en mode palette + navigateur d’instances posées, puis milestone collisions d’éléments: profils de collision auto (preset kind) + override d’application par instance posée persistée).

---

## Résumé en 5 lignes

Monorepo Dart/Flutter pour créer et jouer à des RPG Pokémon-like sur grille.
4 packages : `map_core` (schéma + validation), `map_gameplay` (boucle jeu pure Dart), `map_runtime` (Flame viewer + jouable), `map_editor` (GUI desktop macOS).
Format de projet : `project.json` + `maps/*.json` + `assets/tilesets/*.png`.
L'éditeur produit les données. Le runtime les consomme. Les deux ne se connaissent pas (sauf via `map_core`).
Stade actuel : éditeur riche et fonctionnel, runtime jouable au clavier avec collisions, warps, interactions entités, dialogues Yarn avec branches (<<jump>>, choix ->, navigation ↑/↓, confirmation E), rencontres actives MVP en déplacement walk, navigation naturelle bord-à-bord via `MapConnection`, streaming visuel des maps adjacentes (map active + voisines directes), handoff battle MVP (transition + écran battle minimal + reprise overworld), et warps explicites avec pipeline runtime propre (verrouillage gameplay, fade out/in, validation cible, rollback en cas d'échec). Les warps supportent aussi un déclenchement avancé (`onEnter`/`onBump`, côtés actifs, padding d’activation) éditable visuellement. Côté éditeur, `Tiles & Elements` est en double mode (palette + instances posées sur layer actif) avec sélection centralisée, toggle collision par instance, et édition/génération de collision sur les éléments de bibliothèque (`tree`, `building`, `rock`, `cliff`, `tallDecoration`). Les instances posées sont persistées dans `MapData.placedElements` et consommées par le runtime/gameplay pour le blocage réel. Système personnages overworld complet (modèles, CRUD éditeur, rendu Flame, éditeur d'animations visuel), player animé (idle/walk) + interpolation de pas + tri de profondeur Y. Pas encore : logique de combat complète, rencontres surf/rod, NPC actifs avec IA, sauvegarde.

---

## Graphe de dépendances

```
map_core (pure Dart)
  ├── map_gameplay (pure Dart, consomme map_core)
  ├── map_runtime (Flutter + Flame, consomme map_core + map_gameplay)
  └── map_editor (Flutter + Riverpod + macos_ui, consomme map_core uniquement)

examples/playable_runtime_host (Flutter app, consomme map_runtime)
packages/map_runtime/example/ (Flutter app, identique à l'externe)
```

`map_editor` n'importe PAS `map_gameplay` ni `map_runtime`. C'est voulu.

---

## map_core — Schéma métier

**Barrel** : `packages/map_core/lib/map_core.dart` — 36 exports, aucune restriction `show`.

**Dépendances** : `freezed_annotation`, `json_annotation`, `meta` uniquement. Aucune dépendance Flutter.

### Modèles clés (tous @freezed avec JSON)

```dart
GridPos(x: int, y: int)
GridSize(width: int, height: int)
MapRect(pos: GridPos, size: GridSize)

MapData(
  id, name, size: GridSize, version, tilesetId?,
  layers: List<MapLayer>,        // sealed: tile | collision | terrain | path | object
  placedElements: List<MapPlacedElement>,
  entities: List<MapEntity>,
  connections: List<MapConnection>,
  warps: List<MapWarp>,
  triggers: List<MapTrigger>,
  gameplayZones: List<MapGameplayZone>,
  mapMetadata: MapMetadata,
  properties: Map<String, dynamic>,
)

MapPlacedElement(
  id, layerId, elementId, pos: GridPos,
  applyCollision: bool = true,
  properties: Map<String, String> = {},
)

MapWarp(
  id,
  pos: GridPos,
  targetMapId: String,
  targetPos: GridPos,
  triggerMode: MapWarpTriggerMode = onEnter,   // onEnter | onBump
  allowedApproachFacings: List<EntityFacing> = [],   // [] = tous côtés ; côté depuis lequel le joueur arrive
  triggerPadding: WarpTriggerPadding(top/right/bottom/left en px) = 0,
)
MapConnection(direction: MapConnectionDirection, targetMapId, offset: 0)
MapTrigger(id, name, type: TriggerType, area: MapRect, properties)
MapGameplayZone(id, name, kind, area, priority, encounter?, movement?, hazard?, special?)

MapEntity(
  id, name, kind: MapEntityKind,
  pos: GridPos, size: GridSize,
  npc?: MapEntityNpcData,
  sign?: MapEntitySignData,
  item?: MapEntityItemData,
  spawn?: MapEntitySpawnData,
  editorVisual?: MapEntityEditorVisual,
  blocksMovement: bool = true,   // intention de blocage (la footprint effective est résolue côté gameplay)
  properties,
)
// Extensions: resolvedProjectElementIdForEditor (editorVisual.elementId ?? npc.visualElementId)
//             inspectorHeadline → string d'affichage (name ou id selon kind)

MapEntityNpcData(displayName, dialogue?, facing, visualElementId, trainerId?, lineOfSightRange, defeatDialogueRef?, characterId?)
// characterId = apparence overworld canonique du NPC
// trainerId = lien optionnel vers une fiche ProjectTrainerEntry
// visualElementId reste un fallback legacy d'éditeur, plus la vérité métier visuelle

MapEntitySpawnData(spawnKey, role: EntitySpawnRole, facing: EntityFacing, categoryTag)
// EntitySpawnRole.playerStart = spawn joueur initial

MapMetadata(
  displayName, type: MapType, musicId?, weather: MapWeather,
  isIndoor: false, allowEscapeRope: true,
  defaultSpawnId?,   // <-- utilisé par map_gameplay pour le spawn
  tags,
)

ProjectManifest(
  name, version,
  maps: List<ProjectMapEntry>,
  groups: List<ProjectMapGroup>,
  tilesets: List<ProjectTilesetEntry>,
  elements: List<ProjectElementEntry>,   // visuels entités (frames[])
  terrainPresets: List<ProjectTerrainPreset>,
  pathPresets: List<ProjectPathPreset>,
  encounterTables: List<ProjectEncounterTable>,
  dialogues: List<ProjectDialogueEntry>,
  trainers: List<ProjectTrainerEntry>,
  characters: List<ProjectCharacterEntry>,  // personnages overworld (sprites animés)
  settings: ProjectSettings,
  ...folders, categories,
)

ProjectCharacterEntry(id, name, tilesetId, frameWidth: int, frameHeight: int, animations: List<CharacterAnimation>)
ProjectTrainerEntry(id, name, trainerClass, characterId?, portraitElementId?, battleThemeId?, victoryThemeId?, team, tags)
CharacterAnimation(state: CharacterAnimationState, direction: EntityFacing, frames: List<CharacterAnimationFrame>)
CharacterAnimationFrame(source: TilesetSourceRect, durationMs: int)
// CharacterAnimationState: idle | walk | run
// TilesetSourceRect.x/y = coordonnées en TILE (même convention que le reste du projet)
//   → pixelX = source.x * tileWidth, pixelY = source.y * tileHeight
//   → l'éditeur stocke (col * frameWidth, row * frameHeight) en coords tile
//   → OverworldActorComponent recalcule le srcRect correctement de son côté
//   Exemple : char 1×2, frame-grid (0,1) → TilesetSourceRect(x:0, y:2)
//   → pixel (0, 32) avec tileHeight=16 → sprite complet 2 tuiles de haut ✓

ProjectSettings(tileWidth: 16, tileHeight: 16, displayScale: 2.0, defaultMapWidth: 20, defaultMapHeight: 15, defaultPlayerCharacterId: String?)
ProjectElementEntry(
  id, name, tilesetId, frames: List<TilesetVisualFrame>, ...,
  presetKind: ElementPresetKind = generic,
  collisionProfile?: ElementCollisionProfile,
)
ElementCollisionProfile(source: generated|manual, cells: List<GridPos>)
TilesetVisualFrame(tilesetId: '', source: TilesetSourceRect, durationMs?: int)
TilesetSourceRect(x, y, width: 1, height: 1)  // en coordonnées tuiles

// Dialogue
class DialogueRef {             // porte la référence d'une entité vers un dialogue
  final String dialogueId;      // id dans ProjectManifest.dialogues — vide si legacy
  final String scriptPathRelative;  // '' = résolution via registre ; non vide = chemin direct (legacy/override)
  final String? startNode;     // titre du nœud Yarn à utiliser — null = appliquer le fallback
}

class ProjectDialogueEntry {   // dans ProjectManifest.dialogues
  final String id;
  final String name;
  final String relativePath;   // chemin relatif à la racine projet, ex. 'dialogues/intro.yarn'
  final String? defaultStartNode;  // nœud Yarn suggéré par défaut — surchargeable par DialogueRef.startNode
  final String? folderId;
  final List<String> tags;
  final String description;
}
```

`defaultPlayerCharacterId` est une valeur de départ projet uniquement.
Le runtime l'utilise au boot pour choisir l'apparence initiale du joueur, mais le système est maintenant pensé pour permettre plus tard des changements dynamiques en cours de partie.

### Validation

```dart
ProjectValidator.validate(ProjectManifest)  // unicité IDs, hiérarchies, cycles, frames
MapValidator.validate(MapData, {ProjectManifest? projectDialogueContext})
```
Lance `ValidationException` (sealed `MapException`) au premier problème.

### Migrations JSON legacy

```dart
// Appliquées pendant la désérialisation — transparentes pour le consommateur
migrateProjectManifestJson(Map<String, dynamic>) → Map<String, dynamic>
migrateMapDataJson(Map<String, dynamic>) → Map<String, dynamic>
// Aussi dans les fromJson internes : migrateMapEntityJson, migrateMapGameplayZoneJson
```

### Couche opérations (18 modules)

Fonctions pures pour modifier les données en éditeur : `addEntityOnMap`, `removeEntityFromMap`, `updateEntityOnMap`, `resizeMap`, `paintTile`, `toggleCollision`, `addWarp`, `updateMapMetadata`, `upsertMapPlacedElement`, `setMapPlacedElementCollisionApplied`, etc. Toutes retournent `MapData` modifié (immutable).

---

## map_gameplay — Logique d'exploration

**Barrel** : `packages/map_gameplay/lib/map_gameplay.dart` — exports restreints avec `show`.

**Dépendances** : `map_core` uniquement. Pur Dart. Aucun Flame, aucun Flutter.

### API publique complète

```dart
// Directions
enum Direction { north, south, east, west }
extension DirectionX on Direction {
  int get dx;  // east=1, west=-1, north/south=0
  int get dy;  // south=1, north=-1, east/west=0
  EntityFacing get asFacing;
}
extension EntityFacingX on EntityFacing {  // EntityFacing est dans map_core
  Direction get asDirection;
}

// État joueur
class GameplayPlayerState {
  final GridPos pos;
  final Direction facing;
  GameplayPlayerState copyWith({GridPos? pos, Direction? facing});
}

// État monde
class GameplayWorldState {
  factory GameplayWorldState.initial({
    required MapData map,
    ProjectManifest? project,
    required GridPos playerPos,
    Direction playerFacing = Direction.south,
  });
  factory GameplayWorldState.fromMap(MapData map, {ProjectManifest? project});
  // Lance GameplaySpawnResolutionException si pas de spawn ou spawn bloqué

  final MapData map;
  final GameplayPlayerState player;
  bool isBlocked(int x, int y);
  // 1. hors bornes → true
  // 2. collisionCache[idx] → true si tuile de collision
  // 3. blockingEntityByPos[idx]?.blocksMovement → true si entité bloquante
  // 4. placedElements[idx] via collisionProfile (si applyCollision=true)
  MapWarp? warpAt(int x, int y);
  MapEntity? entityAt(int x, int y);
  // entityByPos : cache d'interaction (footprint entité), spawns exclus
  // blockingEntityByPos : cache blocage séparé (spawns exclus ; custom bloquants uniquement si override explicite collision.*)
  GameplayWorldState withPlayer(GameplayPlayerState player);
}

// Intents
sealed class GameplayIntent {}
final class MoveIntent extends GameplayIntent {
  final Direction direction;
}
final class InteractIntent extends GameplayIntent {}  // E / Space

// Résultats
sealed class GameplayStepResult {
  final GameplayWorldState world;
}
final class Moved extends GameplayStepResult {}
final class Blocked extends GameplayStepResult {}
final class WarpTriggered extends GameplayStepResult {
  final TriggeredWarp warp;
}
final class ConnectionTriggered extends GameplayStepResult {
  final TriggeredConnection connection;
}
final class NothingToInteract extends GameplayStepResult {}
final class NpcInteracted extends GameplayStepResult { final MapEntity entity; }
final class SignInteracted extends GameplayStepResult { final MapEntity entity; }
final class ItemInteracted extends GameplayStepResult { final MapEntity entity; }
final class EntityInteracted extends GameplayStepResult { final MapEntity entity; }

class TriggeredWarp {
  final String warpId;
  final String targetMapId;
  final GridPos targetPos;
  final MapWarpTriggerMode triggerMode;
}

class TriggeredConnection {
  final MapConnectionDirection direction;
  final String targetMapId;
  final int offset;
  final GridPos sourcePos;
}

// Boucle principale
GameplayStepResult stepGameplayWorld(GameplayWorldState world, GameplayIntent intent);

GridPos? resolveConnectedMapTargetPos({
  required GridPos sourcePos,
  required GridSize sourceSize,
  required GridSize targetSize,
  required MapConnectionDirection direction,
  required int offset,
});

// Résolution spawn
GameplayPlayerState resolveInitialPlayerSpawn(MapData map);
// Priorité : map.mapMetadata.defaultSpawnId → spawn entity avec role=playerStart (tri par id) → exception

class GameplaySpawnResolutionException implements Exception { final String message; }

// Rencontres
const double defaultEncounterChancePerStep = 0.12;

class GameplayEncounterPolicy {
  final double chancePerStep; // [0..1]
}

enum GameplayEncounterCheckStatus {
  noZone,
  noEncounterTableId,
  encounterTableNotFound,
  encounterKindMismatch,
  emptyEncounterTable,
  rollFailed,
  triggered,
}

class GameplayEncounter {
  final String mapId;
  final String zoneId;
  final String tableId;
  final EncounterKind encounterKind;
  final String speciesId;
  final int level;
  final int minLevel;
  final int maxLevel;
  final int weight;
  final GridPos playerPos;
  Map<String, dynamic> toJson();
  factory GameplayEncounter.fromJson(Map<String, dynamic> json);
}

class GameplayEncounterCheckResult {
  final GameplayEncounterCheckStatus status;
  final String? zoneId;
  final String? tableId;
  final EncounterKind? encounterKind;
  final double? roll;
  final GameplayEncounter? encounter;
  bool get triggered;
}

GameplayEncounterCheckResult checkEncounterAtPlayerPosition({
  required GameplayWorldState world,
  required ProjectManifest project,
  required EncounterKind encounterKind,
  Random? random,
  GameplayEncounterPolicy policy = const GameplayEncounterPolicy(),
});
```

### Comportement de stepGameplayWorld

Pour `MoveIntent(direction)` :
1. Tourne le joueur dans la direction (même si bloqué)
2. Calcule `(tx, ty) = pos + direction.delta`
3. Si `(tx, ty)` est hors map :
   - cherche une `MapConnection` sur le bord correspondant à `direction`
   - si absente → `Blocked(facedWorld)`
   - si présente → `ConnectionTriggered(facedWorld, connection)` (pas de déplacement hors bornes dans l'état pur)
4. Si `isBlocked(tx, ty)` :
   - si un warp `onBump` correspond (côté autorisé + zone/padding ; côté = côté d’arrivée réel du joueur) → `WarpTriggered(facingWorld, warp)` sans déplacement
   - sinon → `Blocked(facedWorld)`
5. Sinon déplace le joueur à `(tx, ty)`
6. Si un warp `onEnter` correspond sur la cellule d'arrivée (côté autorisé + zone/padding ; côté = côté d’arrivée réel du joueur) → `WarpTriggered(movedWorld, warp)`
7. Sinon → `Moved(movedWorld)`

Pour `InteractIntent()` :
1. Calcule `(tx, ty) = pos + facing.delta` (cellule devant le joueur)
2. Si `entityAt(tx, ty) == null` → retourne `NothingToInteract`
3. Sinon switch sur `entity.kind` → `NpcInteracted` | `SignInteracted` | `ItemInteracted` | `EntityInteracted`

---

## map_runtime — Viewer + Runtime jouable

**Barrel** : `packages/map_runtime/lib/map_runtime.dart` — exports runtime + handoff battle avec `show`.

**Dépendances** : `map_core`, `map_gameplay`, `flutter` (SDK), `flame ^1.36.0`, `path`.

### API publique

```dart
// Handoff battle
enum RuntimeBattleKind { wild, trainer }
enum RuntimeBattleSourceKind { encounterZone, trainerInteraction, script }
class OverworldReturnContext { mapId, playerPos, playerFacing }
sealed class BattleStartRequest { ... }
class WildBattleStartRequest extends BattleStartRequest { ... }
class TrainerBattleStartRequest extends BattleStartRequest { ... }
WildBattleStartRequest buildBattleStartRequestFromEncounter(...)

// Chargement
Future<RuntimeMapBundle> loadRuntimeMapBundle({
  required String projectFilePath,   // chemin absolu vers project.json
  required String mapId,             // id dans manifest.maps
})
// Lance : ProjectLoadException, MapLoadException, AssetNotFoundException, ValidationException

class RuntimeMapBundle {
  final ProjectManifest manifest;
  final MapData map;
  final String projectRootDirectory;
  final Map<String, String> tilesetAbsolutePathsById;  // tilesetId → chemin absolu PNG
  double get cellWidth;   // tileWidth * displayScale
  double get cellHeight;  // tileHeight * displayScale
}

// Viewer statique
class RuntimeMapGame extends FlameGame {
  RuntimeMapGame({required RuntimeMapBundle bundle});
  // Charge images, ajoute MapLayersComponent, caméra = map entière
}

// Jouable au clavier
class PlayableMapGame extends FlameGame with KeyboardEvents {
  PlayableMapGame({
    required RuntimeMapBundle bundle,
    required String projectFilePath,  // pour charger les maps de warp/connection
  });
  // Gère flèches + WASD en maintien de touche → MoveIntent → stepGameplayWorld
  // Déplacement visuel interpolé (step tween) via PlayerComponent.startStep()
  // Animation player idle/walk selon état de mouvement
  // E / Space → InteractIntent → si dialogue résolu → loadDialogueContent() → ouvre DialogueOverlayComponent
  // Si dialogue actif : E / Space → advance() (ligne suivante ou fermeture) ; mouvement bloqué
  // NpcInteracted → NPC se tourne vers le joueur
  // Tri de profondeur dynamique (priority basée sur Y du pied)
  // NpcInteracted/SignInteracted → _tryOpenDialogue() → resolveDialogue() + loadDialogueContent()
  // Moved (non warp) → checkEncounterAtPlayerPosition(..., EncounterKind.walk)
  // Rencontre déclenchée : création BattleStartRequest (mapper pur) puis handoff battle
  // Flow runtime centralisé : overworld | dialogue | mapTransition | battleTransition | battle
  // Battle transition + battle shell dédiés :
  //   BattleTransitionOverlayComponent -> BattleOverlayComponent (MVP)
  //   fermeture battle => reprise overworld propre
  // Collisions depuis GameplayWorldState
  // WarpTriggered → pipeline runtime verrouillé: clear transient state, fade out, load+validate cible,
  //   swap map, place player, resync camera/streaming, fade in, unlock gameplay
  //   rollback source map en cas d'échec avant swap
  // ConnectionTriggered → résout/précharge la map cible, calcule la case d'entrée
  //   avec resolveConnectedMapTargetPos(), puis déclenche un pas interpolé source→cible
  //   (transition invisible), refuse si entrée invalide/bloquée
  // Streaming voisinage : map active + maps connectées directes gardées montées pour visibilité continue
  // Fallback spawn (0,0) si GameplaySpawnResolutionException
  // Priorité : warp explicite > connection implicite (connection uniquement en sortie hors bornes)
  // Logs structurés : [runtime] | [warp] | [connection] | [interact] | [dialogue] | [encounter] | [battle]
  // HUD notification 2s via TextComponent sur camera.viewport (fallback si pas de dialogue)
}

// Résolution dialogue (interne map_runtime, non exporté)
// packages/map_runtime/lib/src/application/resolve_dialogue.dart
class ResolvedDialogue {
  final String absoluteFilePath;  // chemin absolu vers le .yarn
  final String dialogueId;
  final String? startNode;        // null = utiliser premier nœud du fichier
}

ResolvedDialogue? resolveDialogue({
  required String entityId,
  required DialogueRef? ref,           // null → log + return null
  required String projectRootDirectory,
  required List<ProjectDialogueEntry> dialogues,
})
// Règle de résolution (canonique, stable, documentée) :
// 1. Si ref == null → log [dialogue] no dialogue configured
// 2. Si ref.scriptPathRelative non vide → absPath = join(projectRoot, scriptPathRelative) [legacy/override]
// 3. Sinon → chercher ProjectDialogueEntry par ref.dialogueId dans dialogues
//    → si absent → log [dialogue] error unknown dialogueId=xxx
// 4. startNode :
//    a. ref.startNode non null/vide → utiliser [priorité entité]
//    b. sinon entry.defaultStartNode non null/vide → utiliser [fallback bibliothèque]
//    c. sinon → null + log [dialogue] no startNode
//
// startNode = title: d'un nœud Yarn (ex. "Intro", "fresh_start_house_01_mail_box")
// Logs produits : [dialogue] interaction, resolved dialogueId, resolved file,
//                 requested startNode | fallback defaultStartNode | no startNode | error

// Pipeline Yarn avec branches (interne map_runtime)
// packages/map_runtime/lib/src/application/dialogue_runtime_models.dart

// Étapes Yarn (sealed)
sealed class YarnStep {}
class YarnStepLine extends YarnStep { final String text; }
class YarnStepJump extends YarnStep { final String targetNode; }
class YarnStepChoiceBlock extends YarnStep { final List<YarnChoice> choices; }
class YarnChoice { final String text; final List<YarnStep> steps; }

class YarnNode {
  final String title;
  final List<YarnStep> steps;
}

// État de session (sealed)
sealed class DialogueSessionState {}
class DialogueShowingLine extends DialogueSessionState { final String text; }
class DialogueWaitingForChoice extends DialogueSessionState {
  final List<YarnChoice> choices;
  final int selectedIndex;
}

class DialogueSession {
  final List<YarnNode> nodes;
  final DialogueSessionState state;
  String? get currentNodeTitle;
  bool get isLastContent;   // vrai si advance() retournerait null
  DialogueSession? advance();             // null = session terminée
  DialogueSession moveChoiceCursor(int delta);   // clamp sur [0, choices.length-1]
  DialogueSession? confirmChoice();       // exécute la branche choisie, null = terminé
  static DialogueSession? start(List<YarnNode> nodes, String? startNodeTitle);
}
// _resolveStep() : boucle de résolution — exécute les <<jump>> automatiquement jusqu'à
// trouver un YarnStepLine ou YarnStepChoiceBlock (ou retourner null si fin de nœud)

// packages/map_runtime/lib/src/application/parse_yarn_dialogue.dart
List<YarnNode> parseYarnFile(String content);
// Règles :
//   - ligne avec leading whitespace → corps d'une option (body de choix courant)
//   - "-> texte" → nouvelle option de choix
//   - "<<jump X>>" en root → YarnStepJump(X)
//   - "<<jump X>>" indenté → YarnStepJump(X) dans corps du choix courant
//   - autres "<<...>>" → ignorés
//   - texte ordinaire → YarnStepLine (ferme le bloc de choix en cours si ouvert)

// packages/map_runtime/lib/src/application/load_dialogue_content.dart
Future<DialogueSession?> loadDialogueContent(ResolvedDialogue resolved);
// Lit fichier .yarn, parse, start(nodes, startNode)
// Si startNode absent → premier nœud du fichier (log explicite)
// Si startNode demandé mais absent → log + fallback premier nœud

// packages/map_runtime/lib/src/presentation/flame/dialogue_overlay_component.dart
class DialogueOverlayComponent extends PositionComponent {
  // priority: 100, taille = viewport
  // Mode ligne : panneau 28% hauteur, texte + "E · Suite" / "E · Fermer"
  // Mode choix : panneau dynamique (hauteur selon nb options),
  //              "▶" curseur sur option sélectionnée, hint "↑/↓ · Choisir  E · Valider"
  DialogueSession get currentSession;
  bool get isShowingChoices;
  void moveCursor(int delta);
  bool confirmChoice();  // true si encore ouvert
  bool advance();        // true si encore ouvert
}
```

### Rendu (MapLayersComponent)

Ordre de rendu (terrain → path → tile → entités → collision) :
- **Terrain** : `TerrainType` → `ProjectTerrainPreset` → variante via graine `(x+1)*73856093 ^ (y+1)*19349663 ^ preset.id.hashCode`
- **Path** : `PathLayer.presetId` → `ProjectPathPreset` → `RuntimePathAutotileSet` → 20 variantes autotile
- **Tile** : `tileId - 1` → col/row dans l'image tileset (tileId=0 = vide)
- **Entités** : `entity.resolvedProjectElementIdForEditor` → `ProjectElementEntry.frames` → frame courante via `_animElapsed % totalDurationMs` (fallback 200ms/frame)
- **Collision** : overlay rouge semi-transparent si couche visible

### Utilisations typiques

```dart
// Viewer
final bundle = await loadRuntimeMapBundle(projectFilePath: '/...', mapId: 'map_001');
GameWidget(game: RuntimeMapGame(bundle: bundle));

// Jouable
GameWidget(game: PlayableMapGame(bundle: bundle, projectFilePath: '/...'));

// Boucle manuelle (sans rendu Flame)
var world = GameplayWorldState.fromMap(bundle.map);
final result = stepGameplayWorld(world, MoveIntent(Direction.north));
switch (result) {
  case Moved(:final world): ...
  case Blocked(:final world): ...
  case WarpTriggered(:final world, :final warp): ...
  case NpcInteracted(:final world, :final entity): ...
  case SignInteracted(:final world, :final entity): ...
  case ItemInteracted(:final world, :final entity): ...
  case NothingToInteract(): ...
  case EntityInteracted(): ...
}
```

---

## map_editor — Éditeur desktop

**Type** : Application Flutter (macOS). Pas un package consommable. Pas de barrel.

**Dépendances** : `map_core`, `flutter_riverpod`, `macos_ui`, `file_picker`, `path_provider`. **Pas** `map_gameplay` ni `map_runtime`.

### Structure

```
lib/
  main.dart                           → EditorShellPage (MacosApp)
  src/
    app/providers/                    → Riverpod providers (core, use cases)
    features/editor/state/            → EditorState (freezed), EditorNotifier, EditorBrush
    application/
      use_cases/                      → 20+ use case modules (une fonction = une opération)
      services/                       → coordinateurs (history, terrain, warp, entity, zones…)
      models/                         → MapHistorySnapshot (freezed), MapToolPreview, PathAutotileSet
      ports/                          → ProjectWorkspace interface
    infrastructure/
      repositories/                   → FileProjectRepository, FileProjectMapRepository
      filesystem/                     → ProjectFileSystem
    domain/repositories/              → interfaces dépôts
    ui/
      panels/                         → 16+ panneaux (layers, entity, map, warp, trigger, terrain, zones, encounters, trainers, characters…)
      canvas/                         → map_canvas.dart (rendu Flutter Canvas), tileset_editor_canvas
      shared/                         → top_toolbar, status_bar, inspector widgets, cupertino controls
```

### Undo/Redo

`MapHistoryCoordinator` — stroke-based, max 100 entrées. Entièrement implémenté :
- `beginStroke` → `applyMutation` × N → `finalizeStroke` (committé si map changée)
- `undo()` / `redo()` → `MapHistoryRestoreResult`
- Les stacks sont dans `EditorState` (Riverpod)

### État EditorState (clés importantes)

```dart
ProjectManifest? project
MapData? activeMap
String? activeMapPath
EditorToolType activeTool          // selection, paint, collision, terrain, path, entity, warp, trigger, zone…
String? activeLayerId
EditorBrush activeBrush            // none | tile(tileId, tilesetId) | paletteEntry | projectElement
TilesElementsPanelMode tilesElementsPanelMode   // palette | placedInstances
String? selectedPlacedElementInstanceId         // id technique d'une MapPlacedElement persistée
String? selectedEntityId
String? selectedWarpId
String? selectedTriggerId
String? selectedGameplayZoneId
List<MapHistorySnapshot> mapUndoStack
List<MapHistorySnapshot> mapRedoStack
bool isDirty
double zoom
Offset panOffset
```

---

## État fonctionnel — Ce qui marche vraiment

### Marche aujourd'hui

- Éditeur complet : créer/éditer/sauvegarder projets et maps, toutes les couches, toutes les entités (avec toggle "Bloque le mouvement"), warps, triggers, zones, dialogues, dresseurs, rencontres, personnages overworld (bibliothèque + éditeur d'animations visuel).
- Tuile `Tiles & Elements` refondue : mode `Palette` (inchangé pour le flux de pose) + mode `Instances posées` (liste des occurrences persistées dans `MapData.placedElements` sur le calque actif, sélection centralisée dans `EditorState`, panneau détail d’instance).
- Éléments de bibliothèque : `presetKind` éditable + génération auto de `collisionProfile` depuis le visuel réel du tileset (analyse alpha), avec comportement différencié par preset (`tree`, `building`, `rock`, `cliff`, `tallDecoration`, `generic`).
- Édition collision élément : preview visuelle + overlay cellules de collision éditables manuellement, sauvegarde en profil `manual` ou reset.
- Surlignage canvas de l’instance posée sélectionnée (`MapGridPainter`) pour synchroniser la sélection panel ↔ map.
- Override collision par instance posée : toggle `applyCollision` dans le panneau détail ; valeur persistée dans `MapPlacedElement` et consommée par gameplay/runtime.
- Éditeur d'animations personnages : grille d'états 3×4 (idle/walk/run × N/S/E/W), sélecteur de frames par clic sur spritesheet (1 clic = 1 frame complète = frameWidth×frameHeight tiles), frame strip avec miniatures, preview animée temps réel, contrôles durée/réordonnement/suppression. Supporte nativement N frames par direction (ex. cycle marche 3 frames). Assignation d'un personnage-sprite aux entités NPC.
- Undo/redo dans l'éditeur.
- Viewer statique Flame : rendu fidèle de toutes les couches (terrain, path, tile, entités animées, collision).
- Boucle jouable : déplacement clavier, collisions bloquantes, transitions de map via warps.
- Warps gameplay : modes `onEnter` et `onBump` (déclenchement sur case bloquée), filtres de côtés (`allowedApproachFacings`, côté d’arrivée réel du joueur) et zone d’activation élargie par `triggerPadding`.
- UI warp éditeur : panneau enrichi (mode d’activation, côtés actifs N/S/E/W, padding top/right/bottom/left, presets rapides porte/reset) + preview canvas de la zone d’activation et des côtés autorisés.
- Warps explicites runtime : pipeline anti-concurrence avec phase `mapTransition`, fade out/in (`WarpTransitionOverlayComponent`), validation stricte cible (bornes + case non bloquée), et rollback vers la map source en cas d'échec pré-swap.
- Connexions naturelles inter-maps (`MapConnection`) : sortie de bord déclenche une transition vers la map cible sans warp explicite, avec garde d'état (pas de transition concurrente), validation stricte de la case d'entrée, et interpolation visuelle continue source→cible.
- Streaming maps adjacentes : la map active, sa précédente immédiate et ses voisines connectées directes restent montées dans le monde Flame ; on voit la map suivante/précédente sans changer de scène.
- Convention canonique `offset` appliquée runtime : `targetAxis = sourceAxis - offset` (offset = décalage de la map cible par rapport à la source). Formules : E/W `targetY = sourceY - offset`, N/S `targetX = sourceX - offset`; entrée sur la bordure opposée (E→x0, W→xMax, N→yMax, S→y0).
- Priorité des transitions : un warp explicite gagne toujours ; une connection ne s'applique que sur tentative de sortie hors bornes.
- Interactions entités : E/Space → détecte NPC/signe/item devant le joueur, affiche `entity.inspectorHeadline` en overlay 2s + log `[interact]`.
- Collision entités : footprint résolue via `resolveEntityCollisionCells()` ; NPC par défaut en 1×1 (bas centré), override possible via `collision.width/height/offsetX/offsetY` (et alias legacy). Le cache de blocage est séparé du cache d'interaction ; les entités `custom` ne bloquent pas par défaut sans override explicite.
- Résolution dialogue : sur interaction NPC/signe, `resolveDialogue()` résout le fichier .yarn et le startNode avec logs structurés `[dialogue]`.
- **Dialogue Yarn avec branches** : `loadDialogueContent()` lit le fichier .yarn, le parse, démarre la session. `DialogueOverlayComponent` affiche lignes (E · Suite / E · Fermer) et blocs de choix (▶ curseur, ↑/↓ pour naviguer, E pour valider). `<<jump>>` exécuté automatiquement. Le mouvement est bloqué pendant tout le dialogue.
- **Rencontres actives MVP (walk)** : après un `Moved` accepté (hors `Blocked` / `WarpTriggered`), le runtime appelle `checkEncounterAtPlayerPosition()` (`map_gameplay`). Zone retenue = zone encounter de plus haute priorité contenant la cellule joueur et compatible `EncounterKind.walk`. Tirage pondéré dans la table projet, niveau aléatoire `[minLevel..maxLevel]`, logs `[encounter]`.
- **Battle handoff MVP** : une rencontre déclenchée est transformée via `buildBattleStartRequestFromEncounter()` en `WildBattleStartRequest` (avec `OverworldReturnContext`). Le runtime suspend l'overworld, lance `BattleTransitionOverlayComponent`, puis ouvre `BattleOverlayComponent` (shell battle minimal). La fermeture du battle overlay reprend proprement l'overworld.
- Logs structurés : `[runtime]`, `[warp]`, `[connection]`, `[interact]`, `[dialogue]`, `[encounter]`, `[battle]` via `debugPrint`.
- Logs battle : `[battle] battle request created`, `[battle] transition started`, `[battle] overlay opened`, `[battle] battle closed`, `[battle] overworld resumed`.
- Warp failure robuste : logs `[warp]` détaillés (trigger/start/load/place/complete/fail/unlock), notification "Warp failed", et rollback best-effort pour éviter un runtime bloqué/écran noir.
- Résolution automatique du spawn joueur.
- Consommation externe de `map_runtime` depuis un projet Flutter séparé.

### Ne marche pas encore

- Pas de variables/conditions Yarn : le moteur ne supporte que `<<jump>>` et `->` choix (pas `<<set>>`, `<<if>>`, expressions).
- Les propriétés avancées d’instance restent partielles : collision est branchée (toggle `applyCollision`), animation/triggers/comportement restent à implémenter.
- Les instances posées sont persistées dans `MapData.placedElements`, avec resynchronisation depuis les motifs tuiles du calque après peinture/effacement et au chargement de map.
- Rencontres MVP limitées à `EncounterKind.walk` (pas surf, rod, gift, special).
- Pas de logique de combat Pokémon complète : battle shell minimal sans tour par tour, HP, attaques, capture, IA.
- LoS dresseur / comportement NPC.
- Sauvegarde/chargement état de jeu.
- Pas de streaming profond multi-hop : le runtime garde surtout le voisinage immédiat (active + connexions directes + précédente), pas un graphe complet de maps lointaines.

---

## Pièges / incohérences / legacy

1. **Spawn requis en données** : `GameplayWorldState.fromMap` lève une exception si la map n'a pas de spawn configuré. `PlayableMapGame` l'attrape et démarre à `(0,0)` — fallback dev uniquement.

2. **Yarn sans variables** : `DialogueSession` supporte `<<jump>>` et options `->` mais pas les variables (`<<set>>`), conditions (`<<if>>`), ni portraits/audio. Suffisant pour des dialogues RPG classiques.

3. **DialogueRef.scriptPathRelative non vide = legacy** : si une entité a un chemin de script direct (migré depuis une ancienne version), `resolveDialogue()` utilise ce chemin directement sans passer par le registre. Pas d'erreur si le fichier n'existe pas à ce stade — validation runtime uniquement à l'exécution.

4. **tileId=0 = vide** dans les layers tile. `tileId=1` → tile en position 0 dans l'image tileset.

5. **TilesetVisualFrame.tilesetId = ""** : string vide = hériter du `tilesetId` parent (`ProjectElementEntry.tilesetId`). À ne pas confondre avec un ID manquant.

6. **Deux exemples redondants** : `packages/map_runtime/example/` et `examples/playable_runtime_host/` font la même chose. Le second valide la consommabilité externe.

7. **map_editor v0.2.0, autres v0.1.0** : versions désynchronisées mais sans impact fonctionnel (packages path-locaux, pas publiés).

8. **Pas de GameplayPlayerState @freezed** : plain class avec copyWith manuel — cohérent fonctionnellement mais pas uniforme avec le reste du domaine.

9. **`blocksMovement` ignoré pour spawn** : le champ existe sur `MapEntity` (kind=spawn), mais les entités spawn sont exclues des caches gameplay (`_buildEntityByPos` et `_buildBlockingEntityByPos`) → le flag n'a aucun effet pour les spawns.

10. **Entités `custom` et blocage runtime** : côté gameplay, les entités `custom` ne sont ajoutées au cache bloquant que si un override collision explicite est présent (`collision.*` ou alias legacy). Sans override, le blocage attendu doit venir des collision layers.

11. **Offsets de connexion à respecter** : l'éditeur et le runtime utilisent la même convention (`targetAxis = sourceAxis - offset`). Un inverse de connexion valide doit donc pointer en sens opposé avec `offset = -sourceOffset`.

12. **Entrée de connection invalidée** : si la case d'arrivée calculée est hors bornes ou bloquée sur la map cible, la transition est annulée côté runtime (log `[connection]` + notification), sans fallback heuristique.

---

## Fichiers à lire en premier pour comprendre le repo

| Priorité | Fichier | Pourquoi |
|----------|---------|----------|
| 1 | `packages/map_core/lib/map_core.dart` | Tout ce qui est public |
| 2 | `packages/map_core/lib/src/models/map_data.dart` | Structure MapData + MapEntity + MapGameplayZone |
| 3 | `packages/map_core/lib/src/models/project_manifest.dart` | Structure ProjectManifest + tous les registres projet |
| 4 | `packages/map_gameplay/lib/map_gameplay.dart` | API publique gameplay |
| 5 | `packages/map_gameplay/lib/src/gameplay_step.dart` | Boucle d'exploration |
| 6 | `packages/map_gameplay/lib/src/gameplay_connection.dart` | Convention offset + calcul source→cible des `MapConnection` |
| 7 | `packages/map_gameplay/lib/src/player_spawn_resolver.dart` | Logique spawn |
| 8 | `packages/map_runtime/lib/map_runtime.dart` | Exports runtime + handoff battle |
| 9 | `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart` | Pipeline de chargement |
| 10 | `packages/map_runtime/lib/src/application/battle_start_request.dart` | Modèle de handoff battle (wild/trainer) |
| 11 | `packages/map_runtime/lib/src/application/encounter_to_battle_request.dart` | Mapper pur rencontre → battle request |
| 12 | `packages/map_runtime/lib/src/application/resolve_dialogue.dart` | Règle canonique de résolution dialogue |
| 13 | `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | Boucle jouable + handoff battle |
| 14 | `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart` | Rendu complet |
| 15 | `packages/map_editor/lib/src/features/editor/state/editor_state.dart` | État éditeur complet |
| 16 | `packages/map_editor/lib/src/application/services/map_history_coordinator.dart` | Undo/redo |
| 17 | `packages/map_core/lib/src/io/legacy_editor_json_compat.dart` | Migrations JSON |
| 18 | `packages/map_core/lib/src/validation/validators.dart` | Règles de validation |
| 19 | `packages/map_core/lib/src/models/map_entity_payloads.dart` | DialogueRef, NpcData, SignData |

---

## Prochaines priorités

1. Implémenter la boucle combat réelle sur `BattleStartRequest`/`BattleOverlayComponent` (commandes, tour par tour, résolution).
2. Étendre les rencontres à `surf`/`rod` et aux conditions de contexte (mode de déplacement, tags de map/zone).
3. Ajouter le handoff `TrainerBattleStartRequest` depuis un déclenchement trainer (LoS/interact) et brancher team/theme.
