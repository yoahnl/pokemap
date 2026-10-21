import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/runtime_project_catalog.dart';
import 'package:map_runtime/src/application/runtime_retained_world_catalog.dart';
import 'package:path/path.dart' as path;

void main() {
  final source = ProjectManifest(
    name: 'Retained world',
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'actors',
        name: 'Actors',
        relativePath: 'actors.png',
      ),
    ],
    characters: const [
      ProjectCharacterEntry(
        id: 'active-sprite',
        name: 'Active',
        tilesetId: 'actors',
      ),
      ProjectCharacterEntry(
        id: 'retained-sprite',
        name: 'Retained',
        tilesetId: 'actors',
      ),
      ProjectCharacterEntry(
        id: 'unrelated-sprite',
        name: 'Unrelated',
        tilesetId: 'actors',
      ),
    ],
    facts: [
      NarrativeFactDefinition(
        id: 'visible',
        label: 'Visible',
        defaultValue: true,
      ),
    ],
  );
  final activeMap = MapData(
    id: 'active',
    name: 'Active',
    size: const GridSize(width: 4, height: 4),
    entities: [
      MapEntity(
        id: 'active-npc',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 1, y: 1),
        npc: const MapEntityNpcData(characterId: 'active-sprite'),
      ),
    ],
  );
  final retainedMap = MapData(
    id: 'retained',
    name: 'Retained',
    size: const GridSize(width: 4, height: 4),
    entities: [
      MapEntity(
        id: 'conditional-npc',
        kind: MapEntityKind.custom,
        pos: const GridPos(x: 1, y: 1),
        presentation: MapEntityPresentation(
          variants: [
            MapEntityPresentationVariant(
              id: 'visible',
              condition: NarrativeEventConditionExpression.leaf(
                NarrativeEventCondition.fact('visible', true),
              ),
              characterId: 'retained-sprite',
              blocksMovement: true,
            ),
          ],
        ),
      ),
    ],
  );
  Future<RuntimeProjectCatalog> openCatalog(String suffix) async {
    final directory = await Directory.systemTemp.createTemp(
      'retained-world-$suffix-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File(path.join(directory.path, 'project.json'));
    await file.writeAsString(jsonEncode(source.toJson()));
    final catalog = await RuntimeProjectCatalog.open(file.path);
    addTearDown(catalog.dispose);
    return catalog;
  }

  MapData restore(
    ProjectManifest project, {
    GridPos position = const GridPos(x: 2, y: 1),
    String entityId = 'conditional-npc',
  }) {
    final instances = MapInstanceWorldState(
      instancesByMapId: {
        'retained': MapInstanceRuntimeState(
          instanceId: 'retained-visit',
          npcPoses: {
            entityId: MapInstanceNpcPose(
              position: position,
              facing: EntityFacing.west,
            ),
          },
        ),
      },
    );
    final projected = projectMapEntityPresentations(
      project: project,
      map: retainedMap,
      gameState: const GameState(saveId: 'cold-restore'),
    );
    return applyNpcInstancePosesToMap(
      map: projected,
      authoringMap: retainedMap,
      instances: instances,
      instance: instances.instanceRef('retained')!,
      project: project,
    );
  }

  test('cold retained NPC pose uses its own catalog character without loading unrelated definitions', () async {
    final catalog = await openCatalog('valid');
    final active = await catalog.manifestForMap(activeMap);
    final retained = await catalog.manifestForMap(retainedMap);
    expect(active.characters.map((character) => character.id), [
      'active-sprite',
    ]);
    expect(() => restore(active), throwsStateError);
    final project = runtimeRetainedWorldValidationProject(
      activeProject: active,
      retainedProjects: [retained],
    );
    expect(RuntimeProjectCatalog.ownerOf(project), same(catalog));
    expect(project.characters.map((character) => character.id).toSet(), {
      'active-sprite',
      'retained-sprite',
    });
    final restored = restore(project).entities.single;
    expect(restored.id, 'conditional-npc');
    expect(restored.pos, const GridPos(x: 2, y: 1));
    expect(restored.npc!.facing, EntityFacing.west);
    expect(active.characters.map((character) => character.id), [
      'active-sprite',
    ]);
    expect(catalog.projectMetadata.characters, isEmpty);
  });
  test('retained catalog hydration still rejects unknown saved NPCs and positions outside the map', () async {
    final catalog = await openCatalog('invalid');
    final active = await catalog.manifestForMap(activeMap);
    final retained = await catalog.manifestForMap(retainedMap);
    final project = runtimeRetainedWorldValidationProject(
      activeProject: active,
      retainedProjects: [retained],
    );
    expect(() => restore(project, entityId: 'unknown'), throwsStateError);
    expect(
      () => restore(project, position: const GridPos(x: 4, y: 1)),
      throwsStateError,
    );
  });
  test(
    'retained views from another runtime authority remain rejected',
    () async {
      final first = await openCatalog('first');
      final second = await openCatalog('second');
      final active = await first.manifestForMap(activeMap);
      final retained = await second.manifestForMap(retainedMap);
      expect(
        () => runtimeRetainedWorldValidationProject(
          activeProject: active,
          retainedProjects: [retained],
        ),
        throwsStateError,
      );
    },
  );
  test('a complete manifest without a partial catalog keeps its existing authority', () {
    expect(
      runtimeRetainedWorldValidationProject(
        activeProject: source,
        retainedProjects: const [],
      ),
      same(source),
    );
    expect(restore(source).entities.single.pos, const GridPos(x: 2, y: 1));
  });
}
