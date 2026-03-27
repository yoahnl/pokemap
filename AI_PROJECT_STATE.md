# AI_PROJECT_STATE — pokemonProject

> Fichier pensé pour une IA. Dense, factuel, centré sur l'état réel du code.
> Source : audit complet du code (2026-03-26), mis à jour 2026-03-27 (interactions runtime + clarification dialogue + dialogue Yarn MVP runtime + blocksMovement entités).

---

## Résumé en 5 lignes

Monorepo Dart/Flutter pour créer et jouer à des RPG Pokémon-like sur grille.
4 packages : `map_core` (schéma + validation), `map_gameplay` (boucle jeu pure Dart), `map_runtime` (Flame viewer + jouable), `map_editor` (GUI desktop macOS).
Format de projet : `project.json` + `maps/*.json` + `assets/tilesets/*.png`.
L'éditeur produit les données. Le runtime les consomme. Les deux ne se connaissent pas (sauf via `map_core`).
Stade actuel : éditeur riche et fonctionnel, runtime jouable au clavier avec collisions, warps, interactions entités et dialogues Yarn MVP (lecture .yarn, affichage ligne par ligne, blocage gameplay). Pas encore : moteur Yarn complet (choix, sauts), rencontres, NPC actifs.

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

**Barrel** : `packages/map_core/lib/map_core.dart` — 35 exports, aucune restriction `show`.

**Dépendances** : `freezed_annotation`, `json_annotation`, `meta` uniquement. Aucune dépendance Flutter.

### Modèles clés (tous @freezed avec JSON)

```dart
GridPos(x: int, y: int)
GridSize(width: int, height: int)
MapRect(pos: GridPos, size: GridSize)

MapData(
  id, name, size: GridSize, version, tilesetId?,
  layers: List<MapLayer>,        // sealed: tile | collision | terrain | path | object
  entities: List<MapEntity>,
  connections: List<MapConnection>,
  warps: List<MapWarp>,
  triggers: List<MapTrigger>,
  gameplayZones: List<MapGameplayZone>,
  mapMetadata: MapMetadata,
  properties: Map<String, dynamic>,
)

MapWarp(id, pos: GridPos, targetMapId: String, targetPos: GridPos)
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
  blocksMovement: bool = true,   // toutes les cellules couvertes par size bloquent le mouvement
  properties,
)
// Extensions: resolvedProjectElementIdForEditor (editorVisual.elementId ?? npc.visualElementId)
//             inspectorHeadline → string d'affichage (name ou id selon kind)

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
  settings: ProjectSettings,
  ...folders, categories,
)

ProjectSettings(tileWidth: 16, tileHeight: 16, displayScale: 2.0, defaultMapWidth: 20, defaultMapHeight: 15)
ProjectElementEntry(id, name, tilesetId, frames: List<TilesetVisualFrame>, ...)
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

### Couche opérations (17 modules)

Fonctions pures pour modifier les données en éditeur : `addEntityOnMap`, `removeEntityFromMap`, `updateEntityOnMap`, `resizeMap`, `paintTile`, `toggleCollision`, `addWarp`, `updateMapMetadata`, etc. Toutes retournent `MapData` modifié (immutable).

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
    required GridPos playerPos,
    Direction playerFacing = Direction.south,
  });
  factory GameplayWorldState.fromMap(MapData map);
  // Lance GameplaySpawnResolutionException si pas de spawn ou spawn bloqué

  final MapData map;
  final GameplayPlayerState player;
  bool isBlocked(int x, int y);
  // 1. hors bornes → true
  // 2. collisionCache[idx] → true si tuile de collision
  // 3. entityByPos[idx]?.blocksMovement → true si entité bloquante
  MapWarp? warpAt(int x, int y);
  MapEntity? entityAt(int x, int y);
  // cache Map<int, MapEntity> y*w+x — spawns exclus
  // couvre TOUTES les cellules de entity.size (pas seulement pos)
  // → interaction possible depuis n'importe quelle cellule adjacente d'un sprite multi-cases
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
final class NothingToInteract extends GameplayStepResult {}
final class NpcInteracted extends GameplayStepResult { final MapEntity entity; }
final class SignInteracted extends GameplayStepResult { final MapEntity entity; }
final class ItemInteracted extends GameplayStepResult { final MapEntity entity; }
final class EntityInteracted extends GameplayStepResult { final MapEntity entity; }

class TriggeredWarp {
  final String warpId;
  final String targetMapId;
  final GridPos targetPos;
}

// Boucle principale
GameplayStepResult stepGameplayWorld(GameplayWorldState world, GameplayIntent intent);

// Résolution spawn
GameplayPlayerState resolveInitialPlayerSpawn(MapData map);
// Priorité : map.mapMetadata.defaultSpawnId → spawn entity avec role=playerStart (tri par id) → exception

class GameplaySpawnResolutionException implements Exception { final String message; }
```

### Comportement de stepGameplayWorld

Pour `MoveIntent(direction)` :
1. Tourne le joueur dans la direction (même si bloqué)
2. Calcule `(tx, ty) = pos + direction.delta`
3. Si `isBlocked(tx, ty)` → retourne `Blocked(facedWorld)`
4. Sinon déplace le joueur à `(tx, ty)`
5. Si `warpAt(tx, ty) != null` → retourne `WarpTriggered(movedWorld, warp)`
6. Sinon → retourne `Moved(movedWorld)`

Pour `InteractIntent()` :
1. Calcule `(tx, ty) = pos + facing.delta` (cellule devant le joueur)
2. Si `entityAt(tx, ty) == null` → retourne `NothingToInteract`
3. Sinon switch sur `entity.kind` → `NpcInteracted` | `SignInteracted` | `ItemInteracted` | `EntityInteracted`

---

## map_runtime — Viewer + Runtime jouable

**Barrel** : `packages/map_runtime/lib/map_runtime.dart` — 4 exports avec `show`.

**Dépendances** : `map_core`, `map_gameplay`, `flutter` (SDK), `flame ^1.36.0`, `path`.

### API publique

```dart
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
    required String projectFilePath,  // pour charger les maps de warp
  });
  // Gère flèches + WASD → MoveIntent → stepGameplayWorld
  // E / Space → InteractIntent → si dialogue résolu → loadDialogueContent() → ouvre DialogueOverlayComponent
  // Si dialogue actif : E / Space → advance() (ligne suivante ou fermeture) ; mouvement bloqué
  // NpcInteracted/SignInteracted → _tryOpenDialogue() → resolveDialogue() + loadDialogueContent()
  // Collisions depuis GameplayWorldState
  // WarpTriggered → charge async nouvelle map (images avant swap, erreur loggée)
  // Fallback spawn (0,0) si GameplaySpawnResolutionException
  // Logs structurés : [runtime] | [move] | [warp] | [interact] | [dialogue]
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

// Pipeline Yarn MVP (interne map_runtime)
// packages/map_runtime/lib/src/application/dialogue_runtime_models.dart
class YarnNode {
  final String title;
  final List<String> bodyLines;  // lignes filtrées (sans blancs ni commandes <<...>>)
}
class DialogueSession {
  final List<YarnNode> nodes;
  final int currentNodeIndex;
  final int currentLineIndex;
  YarnNode get currentNode;
  String get currentLine;
  bool get isLastLine;
  DialogueSession? advance();   // null = session terminée
  static DialogueSession? start(List<YarnNode> nodes, String? startNodeTitle);
}

// packages/map_runtime/lib/src/application/parse_yarn_dialogue.dart
List<YarnNode> parseYarnFile(String content);   // parse sections title:/---/===
YarnNode? findYarnNode(List<YarnNode> nodes, String title);

// packages/map_runtime/lib/src/application/load_dialogue_content.dart
Future<DialogueSession?> loadDialogueContent(ResolvedDialogue resolved);
// Lit fichier .yarn, parse, start(nodes, startNode)
// Si startNode absent → premier nœud du fichier (log explicite)
// Si startNode demandé mais absent → log + fallback premier nœud

// packages/map_runtime/lib/src/presentation/flame/dialogue_overlay_component.dart
class DialogueOverlayComponent extends PositionComponent {
  // priority: 100, taille = viewport
  // Panneau en bas de l'écran (28% hauteur), fond noir semi-transparent, bordure blanche
  // Texte courant + hint "E · Suite" / "E · Fermer"
  // bool advance() → true si encore ouvert, false si terminé (se retire + appelle onFinished)
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
      panels/                         → 15+ panneaux (layers, entity, map, warp, trigger, terrain, zones, encounters, trainers…)
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

- Éditeur complet : créer/éditer/sauvegarder projets et maps, toutes les couches, toutes les entités (avec toggle "Bloque le mouvement"), warps, triggers, zones, dialogues, dresseurs, rencontres.
- Undo/redo dans l'éditeur.
- Viewer statique Flame : rendu fidèle de toutes les couches (terrain, path, tile, entités animées, collision).
- Boucle jouable : déplacement clavier, collisions bloquantes, transitions de map via warps.
- Interactions entités : E/Space → détecte NPC/signe/item devant le joueur, affiche `entity.inspectorHeadline` en overlay 2s + log `[interact]`.
- Collision entités : `MapEntity.blocksMovement` (défaut `true`) — toutes les cellules couvertes par `entity.size` bloquent le joueur. Désactivable par entité via toggle dans l'inspecteur éditeur.
- Résolution dialogue : sur interaction NPC/signe, `resolveDialogue()` résout le fichier .yarn et le startNode avec logs structurés `[dialogue]`.
- **Dialogue Yarn MVP** : `loadDialogueContent()` lit le fichier .yarn, le parse, démarre la session. `DialogueOverlayComponent` affiche les lignes une par une avec hint clavier. E/Space avance ou ferme. Le mouvement est bloqué pendant le dialogue.
- Logs structurés : `[runtime]`, `[move]`, `[warp]`, `[interact]`, `[dialogue]` via `debugPrint`.
- Warp failure visible : `catch (e, st)` avec log + notification "Warp failed".
- Résolution automatique du spawn joueur.
- Consommation externe de `map_runtime` depuis un projet Flutter séparé.

### Ne marche pas encore

- Dialogues Yarn complets : la lecture/affichage ligne par ligne est faite, mais les nœuds multiples avec sauts (`-> option` / `<<jump>>`) ne sont pas supportés — un seul nœud est exécuté par interaction.
- Rencontres aléatoires actives (zones définies mais pas de déclenchement).
- LoS dresseur / comportement NPC.
- Sauvegarde/chargement état de jeu.
- Animations joueur orientées (le `PlayerComponent` n'a qu'un disque fixe).

---

## Pièges / incohérences / legacy

1. **Spawn requis en données** : `GameplayWorldState.fromMap` lève une exception si la map n'a pas de spawn configuré. `PlayableMapGame` l'attrape et démarre à `(0,0)` — fallback dev uniquement.

2. **Dialogue Yarn MVP (pas de sauts)** : `DialogueSession` n'exécute qu'un seul nœud Yarn — `<<jump>>` et options (`->`) ne sont pas parsés ni traités. Le MVN couvre le cas le plus courant (dialogues linéaires). Pour les dialogues avec branches, il faudra un vrai moteur Yarn.

3. **DialogueRef.scriptPathRelative non vide = legacy** : si une entité a un chemin de script direct (migré depuis une ancienne version), `resolveDialogue()` utilise ce chemin directement sans passer par le registre. Pas d'erreur si le fichier n'existe pas à ce stade — validation runtime uniquement à l'exécution.

4. **tileId=0 = vide** dans les layers tile. `tileId=1` → tile en position 0 dans l'image tileset.

5. **TilesetVisualFrame.tilesetId = ""** : string vide = hériter du `tilesetId` parent (`ProjectElementEntry.tilesetId`). À ne pas confondre avec un ID manquant.

6. **Deux exemples redondants** : `packages/map_runtime/example/` et `examples/playable_runtime_host/` font la même chose. Le second valide la consommabilité externe.

7. **map_editor v0.2.0, autres v0.1.0** : versions désynchronisées mais sans impact fonctionnel (packages path-locaux, pas publiés).

8. **Pas de GameplayPlayerState @freezed** : plain class avec copyWith manuel — cohérent fonctionnellement mais pas uniforme avec le reste du domaine.

9. **`blocksMovement` ignoré pour spawn** : le champ existe sur `MapEntity` (kind=spawn), mais les entités spawn sont exclues de `_buildEntityByPos` → le flag n'a aucun effet pour les spawns. C'est voulu (le spawn est invisible au runtime), mais ne pas s'attendre à un comportement de collision dessus.

---

## Fichiers à lire en premier pour comprendre le repo

| Priorité | Fichier | Pourquoi |
|----------|---------|----------|
| 1 | `packages/map_core/lib/map_core.dart` | Tout ce qui est public |
| 2 | `packages/map_core/lib/src/models/map_data.dart` | Structure MapData + MapEntity + MapGameplayZone |
| 3 | `packages/map_core/lib/src/models/project_manifest.dart` | Structure ProjectManifest + tous les registres projet |
| 4 | `packages/map_gameplay/lib/map_gameplay.dart` | API publique gameplay |
| 5 | `packages/map_gameplay/lib/src/gameplay_step.dart` | Boucle d'exploration |
| 6 | `packages/map_gameplay/lib/src/player_spawn_resolver.dart` | Logique spawn |
| 7 | `packages/map_runtime/lib/map_runtime.dart` | 4 exports publics |
| 8 | `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart` | Pipeline de chargement |
| 9 | `packages/map_runtime/lib/src/application/resolve_dialogue.dart` | Règle canonique de résolution dialogue |
| 10 | `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | Boucle jouable |
| 11 | `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart` | Rendu complet |
| 12 | `packages/map_editor/lib/src/features/editor/state/editor_state.dart` | État éditeur complet |
| 13 | `packages/map_editor/lib/src/application/services/map_history_coordinator.dart` | Undo/redo |
| 14 | `packages/map_core/lib/src/io/legacy_editor_json_compat.dart` | Migrations JSON |
| 15 | `packages/map_core/lib/src/validation/validators.dart` | Règles de validation |
| 16 | `packages/map_core/lib/src/models/map_entity_payloads.dart` | DialogueRef, NpcData, SignData |

---

## Prochaines priorités

1. **Yarn avec sauts/options** : `DialogueSession` ne supporte qu'un nœud linéaire. Ajouter un vrai moteur Yarn (sauts `<<jump>>`, options `->`) pour les dialogues avec branches.
2. **Animations joueur orientées** : `PlayerComponent` ne dessine qu'un disque fixe.
3. (Plus tard) Rencontres actives, comportement NPC, sauvegarde.
