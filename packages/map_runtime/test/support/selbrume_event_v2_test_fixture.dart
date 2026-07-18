import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

const selbrumePortMapId = 'map_port_brisants';
const selbrumeMarshMapId = 'map_marais_salants';
const selbrumeLysaEntityId = 'npc_lysa';
const selbrumePortEntryTriggerId = 'zone_port_entry';
const selbrumeClueEntityId = 'clue_glass_object';
const selbrumeLysaSceneId = 'scene_lysa_port';
const selbrumePortEntrySceneId = 'scene_port_entry';
const selbrumeClueSceneId = 'scene_clue_glass';
const selbrumeLysaEventId = 'evt_019abcde-4000-7000-8000-000000000001';
const selbrumePortEntryEventId = 'evt_019abcde-4000-7000-8000-000000000002';
const selbrumeClueEventId = 'evt_019abcde-4000-7000-8000-000000000003';

final class SelbrumeEventV2RuntimeFixture {
  SelbrumeEventV2RuntimeFixture._(
    this.root,
    this.projectPath,
    this.label, {
    required this.isCanonicalProject,
  });

  final Directory root;
  final String projectPath;
  final String label;
  final bool isCanonicalProject;

  static SelbrumeEventV2RuntimeFixture locate() {
    var current = Directory.current.absolute;
    while (true) {
      final candidate = Directory(
        p.join(
          current.path,
          'examples',
          'playable_runtime_host',
          'event_builder_v2_selbrume_slice',
        ),
      );
      if (File(p.join(candidate.path, 'project.json')).existsSync()) {
        return SelbrumeEventV2RuntimeFixture._(
          candidate,
          p.join(candidate.path, 'project.json'),
          'historical J5 fixture',
          isCanonicalProject: false,
        );
      }
      final parent = current.parent;
      if (parent.path == current.path) {
        throw StateError('Selbrume Event V2 fixture not found.');
      }
      current = parent;
    }
  }

  static SelbrumeEventV2RuntimeFixture locateCanonical() {
    var current = Directory.current.absolute;
    while (true) {
      final candidate = Directory(p.join(current.path, 'selbrume'));
      if (File(p.join(candidate.path, 'project.json')).existsSync() &&
          File(p.join(current.path, 'AGENTS.md')).existsSync()) {
        return SelbrumeEventV2RuntimeFixture._(
          candidate,
          p.join(candidate.path, 'project.json'),
          'canonical Selbrume',
          isCanonicalProject: true,
        );
      }
      final parent = current.parent;
      if (parent.path == current.path) {
        throw StateError('Canonical Selbrume project not found.');
      }
      current = parent;
    }
  }

  Future<RuntimeMapBundle> loadHarnessBundle({
    required String mapId,
    required GridPos playerPos,
    required EntityFacing facing,
  }) async {
    final source = await loadRuntimeMapBundle(
      projectFilePath: projectPath,
      mapId: mapId,
    );
    const spawnId = 'phase_j_runtime_test_spawn';
    final map = source.map.copyWith(
      entities: <MapEntity>[
        for (final entity in source.map.entities)
          if (entity.kind != MapEntityKind.spawn) entity,
        MapEntity(
          id: spawnId,
          name: 'Phase J runtime test spawn',
          kind: MapEntityKind.spawn,
          pos: playerPos,
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: facing,
          ),
        ),
      ],
      mapMetadata: source.map.mapMetadata.copyWith(defaultSpawnId: spawnId),
    );
    return RuntimeMapBundle(
      manifest: source.manifest,
      map: map,
      projectRootDirectory: source.projectRootDirectory,
      tilesetAbsolutePathsById: source.tilesetAbsolutePathsById,
    );
  }
}
