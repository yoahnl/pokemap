import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/narrative_template_catalog.dart';
import 'package:path/path.dart' as p;

void main() {
  test('Selbrume consumes both guided NPC state contracts', () {
    final root = _repositoryRoot();
    final project = ProjectManifest.fromJson(
      _readJson(p.join(root.path, 'selbrume', 'project.json')),
    );
    final map = MapData.fromJson(
      _readJson(
        p.join(
          root.path,
          'selbrume',
          'maps',
          'map_bourg_selbrume.json',
        ),
      ),
    );
    final payloads = <String, SceneNodePayload>{
      NarrativeCommandIds.setNpcPresence:
          buildScenePayloadForNarrativeCommand(
        commandId: NarrativeCommandIds.setNpcPresence,
        parameters: const {
          'npcRef': 'map_bourg_selbrume::npc_mael',
          'present': 'false',
        },
      ),
      NarrativeCommandIds.moveNpc: buildScenePayloadForNarrativeCommand(
        commandId: NarrativeCommandIds.moveNpc,
        parameters: const {
          'npcRef': 'map_bourg_selbrume::npc_mael',
          'warpId': 'warp_bourg_to_maison',
        },
      ),
    };

    for (final entry in payloads.entries) {
      final scene = _scene(entry.key, entry.value);
      final diagnostics = diagnoseSceneAgainstProject(
        scene,
        project,
        mapsById: {map.id: map},
      );

      expect(diagnostics.hasErrors, isFalse, reason: entry.key);
      expect(buildSceneRuntimePlan(scene).canBuild, isTrue, reason: entry.key);
      expect(
        SceneNodePayload.fromJson(entry.value.toJson()),
        entry.value,
        reason: entry.key,
      );
    }
  });
}

SceneAsset _scene(String commandId, SceneNodePayload payload) => SceneAsset(
      id: 'scene.selbrume.npc.$commandId',
      name: 'Selbrume NPC $commandId',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(id: 'command', kind: payload.kind, payload: payload),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'start-command',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'command',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'command-end',
            fromNodeId: 'command',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
        ],
      ),
    );

Map<String, dynamic> _readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

Directory _repositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
      return current;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Repository root containing Selbrume was not found.');
    }
    current = parent;
  }
}
