# P5-01 — Runtime Project Disk Smoke / Editor-created Project Proof

## 1. Résumé exécutif

P5-01 produit une preuve exécutable du socle disque/runtime demandé :

```text
projet technique non-Selbrume écrit sur disque
-> vrai project.json
-> vraie map JSON référencée
-> loadRuntimeMapBundle
-> RuntimeMapBundle validé
-> launch save host lue
-> PlayableMapGame instancié et chargé via onLoad
```

Verdict :

```text
P5-01 : validable.
Niveau de preuve : Level 4 partiel + Level 3 partiel.
Prochain lot exact : P5-02 — New Game / Initial GameState Builder V0.
```

Limite honnête :

```text
Le test ne peut pas importer directement FileProjectRepository et
loadRuntimeMapBundle dans le même package sans créer une dépendance inter-package
sale. Il écrit donc le project.json et la map JSON avec le même format que les
repositories éditeur : ProjectValidator/MapValidator + toJson + JsonEncoder.
```

## 2. Scope du lot

Inclus :

```text
audit des dépendances editor/runtime/host
test exécutable host
écriture disque temporaire d'un project.json
écriture disque temporaire d'une map JSON
lecture runtime via loadRuntimeMapBundle
lecture host runtime_host_launch_save.json
instanciation PlayableMapGame
appel PlayableMapGame.onLoad
mise à jour road_map_phase_5.md
rapport P5-01
```

Exclus et non exécutés :

```text
New Game
starter flow
rewards / money / XP
heal center
capture party-or-box
Boot Flow complet
UI
Selbrume
P5-02
```

## 3. Audit de faisabilité / dépendances

Packages observés :

| Package | Peut importer repository éditeur ? | Peut importer runtime loader ? | Peut instancier PlayableMapGame ? | Conclusion |
|---|---:|---:|---:|---|
| `packages/map_editor` | Oui | Non sans dépendance vers `map_runtime` | Non sans dépendance vers `map_runtime` | Mauvais lieu pour le smoke runtime. |
| `packages/map_runtime` | Non sans dépendance vers `map_editor` | Oui | Oui | Bon runtime, mais pas repository éditeur. |
| `examples/playable_runtime_host` | Non sans ajouter `map_editor` | Oui | Oui | Meilleur lieu pour prouver host/runtime sans dépendance sale. |

Décision :

```text
Option B retenue.
Le test vit dans examples/playable_runtime_host.
Il écrit un project.json et une map JSON validés avec les mêmes règles et le
même shape JSON que FileProjectRepository/FileMapRepository.
```

Justification :

```text
Ajouter map_editor comme dépendance du host ou de map_runtime aurait mélangé les
frontières editor/runtime pour un test. Le test P5-01 évite donc toute dépendance
circulaire ou refactor d'architecture.
```

Références lues :

```text
FileProjectRepository.saveProject :
ProjectValidator.validate(project)
project.toJson()
JsonEncoder.withIndent('  ')

FileMapRepository.saveMap :
MapValidator.validate(map, projectDialogueContext: manifest)
map.toJson()
JsonEncoder.withIndent('  ')
```

## 4. Chemin disque testé

Chemin testé par `examples/playable_runtime_host/test/p5_runtime_project_disk_smoke_test.dart` :

```text
Directory.systemTemp.createTemp('p5_runtime_project_disk_smoke_')
-> project.json
-> maps/p5_runtime_smoke_map.json
-> runtime_host_launch_save.json
-> loadRuntimeHostLaunchSaveData(projectFilePath)
-> loadRuntimeMapBundle(projectFilePath, mapId)
-> PlayableMapGame(bundle, projectFilePath, saveData)
-> PlayableMapGame.onLoad()
```

Le projet temporaire est supprimé en `tearDown`.

## 5. Fixture ou projet temporaire créé

Aucune fixture versionnée n'a été créée.

Le test crée à l'exécution :

```text
project.json
maps/p5_runtime_smoke_map.json
runtime_host_launch_save.json
```

IDs techniques utilisés :

```text
project name : P5 Runtime Project Disk Smoke
map id : p5_runtime_smoke_map
map name : P5 Runtime Smoke Field
spawn id : p5_runtime_smoke_spawn
save id : p5_runtime_smoke_launch_save
```

Contrôle anti-contenu final :

```text
Le test vérifie que les fichiers temporaires générés ne contiennent pas les
fragments Selbrume/Lysa/Mado/Port des Brisants/Phare/Brume/Rival.
```

## 6. RuntimeMapBundle chargé

Preuves testées :

```text
bundle.manifest.name == P5 Runtime Project Disk Smoke
bundle.map.id == p5_runtime_smoke_map
bundle.map.entities contient p5_runtime_smoke_spawn
bundle.projectRootDirectory == dossier temporaire normalisé
bundle.tilesetAbsolutePathsById est vide
bundle.cellWidth == 32
bundle.cellHeight == 32
```

Tilesets :

```text
Le projet technique ne référence aucun tileset.
Le fallback est acceptable pour ce smoke, car la map contient seulement une
entité spawn et un object layer vide. loadRuntimeMapBundle collecte donc zéro
tileset et PlayableMapGame.onLoad passe sans charger d'image.
```

## 7. Host / PlayableMapGame smoke

Host :

```text
loadRuntimeHostLaunchSaveData lit runtime_host_launch_save.json adjacent au
project.json.
```

PlayableMapGame :

```text
PlayableMapGame est instancié avec le RuntimeMapBundle et la launch save.
saveLoadInfo est lisible avant onLoad.
onGameResize(Vector2(320, 240)) est appelé.
onLoad() est appelé.
game.update(0) est appelé.
gameStateSnapshot.currentMapId reste p5_runtime_smoke_map.
```

Ce smoke prouve que le host/runtime accepte le bundle. Il ne prouve pas encore
un écran de sélection projet, une UI de lancement, ni un New Game.

## 8. Niveau de preuve obtenu

```text
Level 4 partiel :
- vraie écriture disque temporaire ;
- vrai project.json ;
- vraie map JSON ;
- vraie lecture runtime via loadRuntimeMapBundle.

Level 3 partiel :
- PlayableMapGame instancié ;
- PlayableMapGame.onLoad exécuté ;
- runtime world construit sur le spawn.
```

Non vendu comme preuve complète :

```text
Ce n'est pas une preuve d'un projet créé par une session UI complète de l'éditeur.
Ce n'est pas une preuve New Game.
Ce n'est pas une preuve gameplay rewards/save/load beta.
```

## 9. Ce qui est prouvé

```text
Un project.json au format PokeMap peut être écrit sur disque.
Une map JSON référencée par ce manifest peut être écrite sur disque.
Le runtime lit ce project.json depuis disque.
loadRuntimeMapBundle résout la map relative et charge la map.
RuntimeMapBundle porte manifest, map, projectRootDirectory et tilesets cohérents.
Le host lit une launch save adjacente.
PlayableMapGame accepte le bundle et passe onLoad.
Le smoke reste générique et non-Selbrume.
```

## 10. Ce qui n’est pas prouvé

```text
Pas de sauvegarde via une instance FileProjectRepository importée directement
dans le même test que loadRuntimeMapBundle.
Pas de projet créé depuis l'UI editor.
Pas de project picker interactif.
Pas de New Game.
Pas de starter.
Pas de rewards / money / XP.
Pas de heal center.
Pas de capture party-or-box.
Pas de Boot Flow complet.
Pas de save/load gameplay beta.
```

## 11. Limites et reports vers P5-02 / P5-08

Vers P5-02 :

```text
relier New Game minimal au manifest / map / spawn prouvés ici ;
définir le contrat GameState initial ;
ne pas ouvrir Boot Flow complet.
```

Vers P5-08 :

```text
réutiliser ce type de smoke host/runtime pour une boucle plus longue :
New Game -> Battle -> Reward -> Save/Load.
```

Limite d'architecture :

```text
Si le produit exige une preuve stricte "FileProjectRepository concret ->
loadRuntimeMapBundle" dans un seul test, il faudra un micro-lot de design ou
un package test harness explicitement autorisé. P5-01 évite volontairement cette
dépendance sale.
```

## 12. Tests exécutés

Test ciblé :

```bash
cd examples/playable_runtime_host && flutter test test/p5_runtime_project_disk_smoke_test.dart
```

Régressions ciblées :

```bash
cd examples/playable_runtime_host && flutter test test/runtime_launch_save_test.dart
cd examples/playable_runtime_host && flutter test test/phase_a_golden_slice_launch_test.dart
cd examples/playable_runtime_host && flutter test test/p3_narrative_smoke_slice_test.dart
```

Format :

```bash
cd examples/playable_runtime_host && dart format --set-exit-if-changed test/p5_runtime_project_disk_smoke_test.dart
```

## 13. Modifications effectuées

Fichier créé :

```text
examples/playable_runtime_host/test/p5_runtime_project_disk_smoke_test.dart
reports/roadmap/phase_5/p5_01_runtime_project_disk_smoke_editor_created_project_proof.md
```

Fichier modifié :

```text
MVP Selbrume/road_map_phase_5.md
```

Fichiers non modifiés :

```text
MVP Selbrume/road_map_global.md
packages/map_core/**
packages/map_gameplay/**
packages/map_runtime/lib/**
packages/map_editor/**
packages/map_battle/**
ProjectManifest
GameState
SaveData
```

## 14. Evidence Pack

### git status initial exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
```

### Fichiers lus principaux

```text
AGENTS.md
skills/README.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_5.md
reports/roadmap/phase_5/p5_00_phase_5_roadmap_recalibration_gameplay_loop_audit.md
packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
packages/map_runtime/lib/src/application/runtime_map_bundle.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/map_data.dart
packages/map_core/lib/src/models/map_layer.dart
packages/map_core/lib/src/models/tileset.dart
examples/playable_runtime_host/lib/main.dart
examples/playable_runtime_host/lib/src/runtime_launch_save.dart
examples/playable_runtime_host/test/runtime_launch_save_test.dart
examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart
examples/playable_runtime_host/test/p3_narrative_smoke_slice_test.dart
```

### Commandes exécutées

```bash
git status --short --untracked-files=all
sed -n '1,360p' "MVP Selbrume/road_map_global.md"
sed -n '1,900p' "MVP Selbrume/road_map_phase_5.md"
sed -n '1,320p' reports/roadmap/phase_5/p5_00_phase_5_roadmap_recalibration_gameplay_loop_audit.md
sed -n '1,260p' packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
sed -n '1,320p' packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
sed -n '1,260p' packages/map_runtime/lib/src/application/runtime_map_bundle.dart
sed -n '1,360p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '1,260p' examples/playable_runtime_host/lib/src/runtime_launch_save.dart
sed -n '1,260p' examples/playable_runtime_host/test/runtime_launch_save_test.dart
sed -n '1,260p' examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart
sed -n '1,220p' packages/map_runtime/pubspec.yaml
sed -n '1,220p' examples/playable_runtime_host/pubspec.yaml
sed -n '1,220p' packages/map_editor/pubspec.yaml
rg -n "const factory ProjectManifest|const factory ProjectMapEntry|const factory ProjectTilesetEntry|const factory MapData|const factory MapLayer|const factory Tileset|class ProjectManifest" packages/map_core/lib/src/models/project_manifest.dart packages/map_core/lib/src/models/map_data.dart packages/map_core/lib/src/models/map_layer.dart packages/map_core/lib/src/models/tileset.dart packages/map_core/lib/src/models -g '*.dart'
find examples/playable_runtime_host -maxdepth 3 -type f | sort
rg -n "FileProjectRepository|ProjectRepository|saveProject|loadProject|saveProjectManifest|loadRuntimeMapBundle|RuntimeMapBundle|PlayableMapGame|runtime_host_launch_save|project.json|ProjectMapEntry|ProjectTilesetEntry|MapData|MapLayer|spawn|defaultSpawn" packages examples --glob '!build/**' --glob '!**/.dart_tool/**'
find packages/map_runtime/test -maxdepth 3 -type f | sort | rg "runtime|project|bundle|smoke|launch|save|p3|p5"
find packages/map_editor/test -maxdepth 3 -type f | sort | rg "project|repository|save|load|runtime|p5"
rg -n "Future<void> onLoad|onLoad\\(" packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '1,140p' packages/map_core/lib/src/models/map_data.dart
sed -n '120,360p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '1,120p' packages/map_core/lib/src/models/map_layer.dart
sed -n '1330,1425p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '1,140p' examples/playable_runtime_host/test/p3_narrative_smoke_slice_test.dart
sed -n '1,80p' packages/map_runtime/test/playable_map_game_public_getters_test.dart
sed -n '80,180p' packages/map_runtime/test/playable_map_game_public_getters_test.dart
rg -n "const factory MapEntity|class MapEntity|const factory MapEntitySpawnData|enum EntitySpawnRole" packages/map_core/lib/src/models/map_entity_payloads.dart packages/map_core/lib/src/models/map_data.dart packages/map_core/lib/src/models/enums.dart
sed -n '190,255p' packages/map_core/lib/src/models/map_data.dart
sed -n '188,220p' packages/map_core/lib/src/models/map_entity_payloads.dart
sed -n '112,128p' packages/map_core/lib/src/models/enums.dart
cd examples/playable_runtime_host && flutter test test/p5_runtime_project_disk_smoke_test.dart
cd examples/playable_runtime_host && dart format --set-exit-if-changed test/p5_runtime_project_disk_smoke_test.dart
cd examples/playable_runtime_host && flutter test test/runtime_launch_save_test.dart
cd examples/playable_runtime_host && flutter test test/phase_a_golden_slice_launch_test.dart
cd examples/playable_runtime_host && flutter test test/p3_narrative_smoke_slice_test.dart
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

### Sorties utiles

Audit dépendances :

```text
map_runtime dépend de map_core/map_gameplay/map_battle, pas map_editor.
map_editor dépend de map_core, pas map_runtime.
playable_runtime_host dépend de map_core/map_gameplay/map_runtime, pas map_editor.
```

Runtime loader :

```text
loadRuntimeMapBundle lit projectFilePath, valide ProjectManifest, résout
ProjectMapEntry.relativePath, charge la map, collecte les tilesets runtime et
retourne RuntimeMapBundle(manifest, map, projectRootDirectory, tileset paths).
```

PlayableMapGame :

```text
Le constructeur accepte RuntimeMapBundle + projectFilePath + SaveData?.
onLoad construit GameplayWorldState, charge les tilesets, monte la map, crée le
PlayerComponent, synchronise GameState et dispatch mapEnter.
```

### Fichiers créés

```text
examples/playable_runtime_host/test/p5_runtime_project_disk_smoke_test.dart
reports/roadmap/phase_5/p5_01_runtime_project_disk_smoke_editor_created_project_proof.md
```

### Fichiers modifiés

```text
MVP Selbrume/road_map_phase_5.md
```

### Contenu complet du nouveau test

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/runtime_launch_save.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P5 runtime project disk smoke', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp(
        'p5_runtime_project_disk_smoke_',
      );
    });

    tearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });

    test(
        'writes editor-shaped project files, loads a RuntimeMapBundle, and boots PlayableMapGame',
        () async {
      final projectFilePath = p.join(root.path, 'project.json');
      final mapFilePath =
          p.join(root.path, 'maps', 'p5_runtime_smoke_map.json');
      final launchSaveFilePath =
          p.join(root.path, kRuntimeHostLaunchSaveFileName);

      final manifest = _p5SmokeManifest();
      final map = _p5SmokeMap();
      final launchSave = _p5LaunchSave();

      await _writeProjectUsingEditorRepositoryShape(
        manifest: manifest,
        projectFilePath: projectFilePath,
      );
      await _writeMapUsingEditorRepositoryShape(
        map: map,
        manifest: manifest,
        mapFilePath: mapFilePath,
      );
      await _writeLaunchSave(
        saveData: launchSave,
        launchSaveFilePath: launchSaveFilePath,
      );

      expect(await File(projectFilePath).exists(), isTrue);
      expect(await File(mapFilePath).exists(), isTrue);
      expect(await File(launchSaveFilePath).exists(), isTrue);

      final persistedProjectJson =
          jsonDecode(await File(projectFilePath).readAsString())
              as Map<String, dynamic>;
      expect(persistedProjectJson['name'], _projectName);
      expect(persistedProjectJson['maps'], isA<List<dynamic>>());
      expect(
        (persistedProjectJson['maps'] as List<dynamic>).single,
        containsPair('relativePath', 'maps/p5_runtime_smoke_map.json'),
      );

      final persistedMapJson =
          jsonDecode(await File(mapFilePath).readAsString())
              as Map<String, dynamic>;
      expect(persistedMapJson['id'], _mapId);
      expect(persistedMapJson['mapMetadata'],
          containsPair('defaultSpawnId', _spawnId));

      final hostLaunchSave = await loadRuntimeHostLaunchSaveData(
        projectFilePath: projectFilePath,
      );
      expect(hostLaunchSave, isNotNull);
      expect(hostLaunchSave!.currentMapId, _mapId);
      expect(hostLaunchSave.playerPosition, const GridPos(x: 1, y: 1));

      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _mapId,
      );

      expect(bundle.manifest.name, _projectName);
      expect(bundle.map.id, _mapId);
      expect(
          bundle.map.entities.map((entity) => entity.id), contains(_spawnId));
      expect(bundle.projectRootDirectory, p.normalize(root.path));
      expect(bundle.tilesetAbsolutePathsById, isEmpty);
      expect(bundle.cellWidth, 32);
      expect(bundle.cellHeight, 32);

      final game = PlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveData: hostLaunchSave,
      );

      expect(game.saveLoadInfo.mapId, _mapId);
      expect(game.saveLoadInfo.playerX, 1);
      expect(game.saveLoadInfo.playerY, 1);

      game.onGameResize(Vector2(320, 240));
      await game.onLoad();
      game.update(0);

      expect(game.saveLoadInfo.mapId, _mapId);
      expect(game.gameStateSnapshot.currentMapId, _mapId);
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 1));

      await _expectNoForbiddenProjectContent(root);
    });
  });
}

const _projectName = 'P5 Runtime Project Disk Smoke';
const _mapId = 'p5_runtime_smoke_map';
const _spawnId = 'p5_runtime_smoke_spawn';
const _saveId = 'p5_runtime_smoke_launch_save';

ProjectManifest _p5SmokeManifest() {
  return const ProjectManifest(
    name: _projectName,
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'P5 Runtime Smoke Field',
        relativePath: 'maps/p5_runtime_smoke_map.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
    settings: ProjectSettings(
      tileWidth: 16,
      tileHeight: 16,
      displayScale: 2,
      defaultMapWidth: 4,
      defaultMapHeight: 4,
    ),
  );
}

MapData _p5SmokeMap() {
  return const MapData(
    id: _mapId,
    name: 'P5 Runtime Smoke Field',
    size: GridSize(width: 4, height: 4),
    layers: <MapLayer>[
      MapLayer.object(id: 'p5_runtime_smoke_objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: _spawnId,
        name: 'P5 Runtime Smoke Spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 1),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          spawnKey: _spawnId,
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.south,
        ),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: _spawnId),
  );
}

SaveData _p5LaunchSave() {
  return const SaveData(
    saveId: _saveId,
    currentMapId: _mapId,
    playerPosition: GridPos(x: 1, y: 1),
    playerFacing: EntityFacing.south,
    trainerProfile: TrainerProfile(name: 'P5 Runtime Tester'),
  );
}

Future<void> _writeProjectUsingEditorRepositoryShape({
  required ProjectManifest manifest,
  required String projectFilePath,
}) async {
  ProjectValidator.validate(manifest);
  final file = File(projectFilePath);
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
  );
}

Future<void> _writeMapUsingEditorRepositoryShape({
  required MapData map,
  required ProjectManifest manifest,
  required String mapFilePath,
}) async {
  MapValidator.validate(map, projectDialogueContext: manifest);
  final file = File(mapFilePath);
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(map.toJson()),
  );
}

Future<void> _writeLaunchSave({
  required SaveData saveData,
  required String launchSaveFilePath,
}) async {
  final file = File(launchSaveFilePath);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(saveData.toJson()),
  );
}

Future<void> _expectNoForbiddenProjectContent(Directory root) async {
  const forbiddenFragments = <String>{
    'selbrume',
    'lysa',
    'mado',
    'port des brisants',
    'phare',
    'brume',
    'rival',
  };

  await for (final entity in root.list(recursive: true)) {
    if (entity is! File) {
      continue;
    }
    final normalizedContent = (await entity.readAsString()).toLowerCase();
    for (final fragment in forbiddenFragments) {
      expect(
        normalizedContent,
        isNot(contains(fragment)),
        reason: '${entity.path} must remain a generic P5 technical fixture.',
      );
    }
  }
}
```

### Diff complet de road_map_phase_5.md

```diff
diff --git a/MVP Selbrume/road_map_phase_5.md b/MVP Selbrume/road_map_phase_5.md
index afa3e94e..286781b6 100644
--- a/MVP Selbrume/road_map_phase_5.md	
+++ b/MVP Selbrume/road_map_phase_5.md	
@@ -5,6 +5,7 @@
 Phase 5 active.
 
 P5-00 : terminé.
+P5-01 : terminé.
 
 Phase 5 reste orientée vers une boucle RPG minimale prouvable, pas vers une
 parité Pokémon complète, pas vers Selbrume final, pas vers une UI premium.
 
@@ -12,7 +13,7 @@ parité Pokémon complète, pas vers Selbrume final, pas vers une UI premium.
 Prochain lot exact :
 
 ```text
-P5-01 — Runtime Project Disk Smoke / Editor-created Project Proof
+P5-02 — New Game / Initial GameState Builder V0
 ```
 
 ## Objectif Phase 5
@@ -114,7 +115,7 @@ aucun code modifié
 
 ### P5-01 — Runtime Project Disk Smoke / Editor-created Project Proof
 
-Statut : prochain lot exact.
+Statut : terminé.
 
 But :
 
@@ -136,6 +137,8 @@ aucun contenu final Selbrume
 
 ### P5-02 — New Game / Initial GameState Builder V0
 
+Statut : prochain lot exact.
+
 But :
 
 ```text
```

Note :

```text
Le diff ci-dessus est le diff complet utile de la roadmap Phase 5 modifiée par
P5-01. Le hash index peut différer après création du présent rapport, mais les
sections modifiées sont exhaustives.
```

### Sortie complète du test ciblé

Commande :

```bash
cd examples/playable_runtime_host && flutter test test/p5_runtime_project_disk_smoke_test.dart
```

Sortie complète :

```text
00:00 +0: P5 runtime project disk smoke writes editor-shaped project files, loads a RuntimeMapBundle, and boots PlayableMapGame
[runtime_host_save] launch save lookup path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_runtime_project_disk_smoke_aEHSsc/runtime_host_launch_save.json
[runtime_host_save] launch save read start path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_runtime_project_disk_smoke_aEHSsc/runtime_host_launch_save.json
[runtime_host_save] launch save parsed mapId=p5_runtime_smoke_map party=0
[runtime_loader] bundle load start projectFilePath=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_runtime_project_disk_smoke_aEHSsc/project.json mapId=p5_runtime_smoke_map
[runtime_loader] project manifest lookup path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_runtime_project_disk_smoke_aEHSsc/project.json
[runtime_loader] project manifest read ok bytes=1956
[runtime_loader] project manifest validated maps=1 tilesets=0 scenarios=0
[runtime_loader] bundle map resolved mapId=p5_runtime_smoke_map relativePath=maps/p5_runtime_smoke_map.json mapPath=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_runtime_project_disk_smoke_aEHSsc/maps/p5_runtime_smoke_map.json
[runtime_loader] map file lookup path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_runtime_project_disk_smoke_aEHSsc/maps/p5_runtime_smoke_map.json
[runtime_loader] map file read ok bytes=1249
[runtime_loader] map validated id=p5_runtime_smoke_map size=4x4 layers=1 entities=1 placedElements=0 warps=0 triggers=0
[runtime_loader] bundle tilesets collected ids=
[runtime_loader] bundle load ok mapId=p5_runtime_smoke_map projectRoot=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_runtime_project_disk_smoke_aEHSsc tilesets=0
[runtime_game] onLoad start map=p5_runtime_smoke_map projectFilePath=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_runtime_project_disk_smoke_aEHSsc/project.json tilesets=0
[runtime_game] world build start map=p5_runtime_smoke_map
[runtime] Map loaded: p5_runtime_smoke_map, spawn at (1, 1)
[runtime_game] tileset image load start map=p5_runtime_smoke_map
[runtime_game] tileset cache skipped: no tilesets
[runtime_game] tileset image load ok count=0 map=p5_runtime_smoke_map
[runtime_game] mount root map start map=p5_runtime_smoke_map
[runtime_game] mount root map ok map=p5_runtime_smoke_map
[runtime_game] onLoad completed activeMapId=p5_runtime_smoke_map
00:00 +1: All tests passed!
```

### Sortie format

Commande :

```bash
cd examples/playable_runtime_host && dart format --set-exit-if-changed test/p5_runtime_project_disk_smoke_test.dart
```

Sortie finale :

```text
Formatted 1 file (0 changed) in 0.01 seconds.
```

Note :

```text
Le premier passage de format a modifié le nouveau test :
"Formatted 1 file (1 changed) in 0.01 seconds."
Le second passage ci-dessus prouve l'état final formaté.
```

### Sorties complètes des régressions ciblées

Commande :

```bash
cd examples/playable_runtime_host && flutter test test/runtime_launch_save_test.dart
```

Sortie :

```text
00:00 +0: loadRuntimeHostLaunchSaveData returns null when no versioned launch save is present
[runtime_host_save] launch save lookup path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/runtime_launch_save_jZrLKn/runtime_host_launch_save.json
[runtime_host_save] launch save missing path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/runtime_launch_save_jZrLKn/runtime_host_launch_save.json
00:00 +1: loadRuntimeHostLaunchSaveData loads a versioned launch save adjacent to project.json
[runtime_host_save] launch save lookup path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/runtime_launch_save_6A2IvN/runtime_host_launch_save.json
[runtime_host_save] launch save read start path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/runtime_launch_save_6A2IvN/runtime_host_launch_save.json
[runtime_host_save] launch save parsed mapId=golden_field party=1
00:00 +2: All tests passed!
```

Commande :

```bash
cd examples/playable_runtime_host && flutter test test/phase_a_golden_slice_launch_test.dart
```

Sortie :

```text
00:00 +0: the versioned Phase A golden slice exposes a real launch save
[runtime_host_save] launch save lookup path=/Users/karim/Project/pokemonProject/examples/playable_runtime_host/golden_battle_slice/runtime_host_launch_save.json
[runtime_host_save] launch save read start path=/Users/karim/Project/pokemonProject/examples/playable_runtime_host/golden_battle_slice/runtime_host_launch_save.json
[runtime_host_save] launch save parsed mapId=golden_field party=2
00:00 +1: All tests passed!
```

Commande :

```bash
cd examples/playable_runtime_host && flutter test test/p3_narrative_smoke_slice_test.dart
```

Sortie :

```text
00:00 +0: P3 narrative smoke slice loads host data and PlayableMapGame dispatches mapEnter
[runtime_host_save] launch save lookup path=/Users/karim/Project/pokemonProject/examples/playable_runtime_host/p3_narrative_smoke_slice/runtime_host_launch_save.json
[runtime_host_save] launch save read start path=/Users/karim/Project/pokemonProject/examples/playable_runtime_host/p3_narrative_smoke_slice/runtime_host_launch_save.json
[runtime_host_save] launch save parsed mapId=p3_narrative_smoke_map party=0
[runtime_loader] bundle load start projectFilePath=/Users/karim/Project/pokemonProject/examples/playable_runtime_host/p3_narrative_smoke_slice/project.json mapId=p3_narrative_smoke_map
[runtime_loader] project manifest lookup path=/Users/karim/Project/pokemonProject/examples/playable_runtime_host/p3_narrative_smoke_slice/project.json
[runtime_loader] project manifest read ok bytes=2224
[runtime_loader] project manifest validated maps=1 tilesets=0 scenarios=1
[runtime_loader] bundle map resolved mapId=p3_narrative_smoke_map relativePath=maps/p3_narrative_smoke_field.json mapPath=/Users/karim/Project/pokemonProject/examples/playable_runtime_host/p3_narrative_smoke_slice/maps/p3_narrative_smoke_field.json
[runtime_loader] map file lookup path=/Users/karim/Project/pokemonProject/examples/playable_runtime_host/p3_narrative_smoke_slice/maps/p3_narrative_smoke_field.json
[runtime_loader] map file read ok bytes=920
[runtime_loader] map validated id=p3_narrative_smoke_map size=4x4 layers=0 entities=2 placedElements=0 warps=0 triggers=0
[runtime_loader] bundle tilesets collected ids=
[runtime_loader] bundle load ok mapId=p3_narrative_smoke_map projectRoot=/Users/karim/Project/pokemonProject/examples/playable_runtime_host/p3_narrative_smoke_slice tilesets=0
[runtime_game] onLoad start map=p3_narrative_smoke_map projectFilePath=/Users/karim/Project/pokemonProject/examples/playable_runtime_host/p3_narrative_smoke_slice/project.json tilesets=0
[runtime_game] world build start map=p3_narrative_smoke_map
[runtime] Map loaded: p3_narrative_smoke_map, spawn at (1, 1)
[runtime_game] tileset image load start map=p3_narrative_smoke_map
[runtime_game] tileset cache skipped: no tilesets
[runtime_game] tileset image load ok count=0 map=p3_narrative_smoke_map
[runtime_game] mount root map start map=p3_narrative_smoke_map
[step_studio_trace] npc_mount_skipped map=p3_narrative_smoke_map entity=p3_smoke_npc reason=presence_predicate_false
[step_studio_trace] npc_presence_applied map=p3_narrative_smoke_map entity=p3_smoke_npc present=false
[runtime_game] mount root map ok map=p3_narrative_smoke_map
[runtime] local scenario "p3_narrative_smoke_scenario" marked completed (predicate cutsceneCompleted).
[step_studio_trace] completion_applied scenario=p3_narrative_smoke_scenario origin=dispatch:mapEnter completedSteps=[p3.smoke.step.completed] completedCutscenes=[p3_narrative_smoke_scenario]
[scenario_runtime] source=mapEnter map=p3_narrative_smoke_map trigger=- entity=- status=reachedEnd scenario=p3_narrative_smoke_scenario sourceNode=p3_smoke_source stopNode=p3_smoke_end message=Flow terminé sur End.
[runtime_game] onLoad completed activeMapId=p3_narrative_smoke_map
00:00 +1: All tests passed!
```

### git diff --check exact

Commande :

```bash
git diff --check
```

Sortie exacte :

```text
```

### git diff --stat exact

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 MVP Selbrume/road_map_phase_5.md | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)
```

### git diff --name-only exact

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
MVP Selbrume/road_map_phase_5.md
```

### git status final exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M "MVP Selbrume/road_map_phase_5.md"
?? examples/playable_runtime_host/test/p5_runtime_project_disk_smoke_test.dart
?? reports/roadmap/phase_5/p5_01_runtime_project_disk_smoke_editor_created_project_proof.md
```

### Contrôles hors scope

Commande :

```bash
git diff --name-only -- "MVP Selbrume/road_map_global.md" packages/map_core/lib packages/map_gameplay packages/map_runtime/lib packages/map_editor packages/map_battle
```

Sortie exacte :

```text
```

```text
MVP Selbrume/road_map_global.md n'a pas été modifié.
P5-02 n'a pas été exécuté.
New Game n'a pas été implémenté.
Boot Flow complet non créé.
Selbrume final non créé.
Aucune UI premium créée.
Aucun reward/money/XP ajouté.
packages/map_core/lib non modifié.
packages/map_gameplay non modifié.
packages/map_runtime/lib non modifié.
packages/map_editor non modifié.
packages/map_battle non modifié.
```

## 15. Auto-review critique

Points forts :

```text
La preuve n'est pas audit-only.
Le test écrit de vrais fichiers disque temporaires.
Le runtime loader est exercé réellement.
PlayableMapGame.onLoad est exercé.
Les frontières package sont respectées.
Le niveau de preuve est limité mais honnête.
```

Réserves :

```text
Le test ne prouve pas une session UI editor réelle.
Le test ne prouve pas FileProjectRepository importé directement dans le même
package que loadRuntimeMapBundle.
La map ne référence aucun tileset ; c'est suffisant pour ce smoke mais pas pour
un projet visuellement riche.
```

## 16. Regard critique sur le prompt

Le prompt force le bon ordre : prouver le sol disque/runtime avant de brancher
New Game. C'est sain. La nuance importante est le mot "éditeur" : le repo ne
fournit pas aujourd'hui un package propre pouvant importer à la fois le
repository éditeur et le runtime loader sans dépendance sale. P5-01 documente
donc cette frontière au lieu de la contourner.
