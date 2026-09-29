import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('New Game entrypoint migration', () {
    test('strict format blocks the legacy migration without mutating input', () {
      final source = _legacyProjectJson();
      final before = _deepCopy(source);

      final plan = planNewGameEntrypointMigration(
        projectJson: source,
        projectRevision: 'project-r1',
      );

      expect(plan.status, NewGameEntrypointMigrationStatus.blocked);
      expect(plan.sourceRevision, 'project-r1');
      expect(plan.sourceSceneId, 'scene_intro');
      expect(plan.changes, isEmpty);
      expect(plan.issues.single.code, NewGameEntrypointMigrationIssueCode.projectInvalid);
      expect(source, before);
    });

    test('strict format blocks legacy apply and keeps source intact', () {
      final source = _legacyProjectJson();
      final before = _deepCopy(source);
      final plan = planNewGameEntrypointMigration(
        projectJson: source,
        projectRevision: 'project-r1',
      );

      final result = applyNewGameEntrypointMigration(
        projectJson: source,
        currentProjectRevision: 'project-r1',
        plan: plan,
      );

      expect(result.status, NewGameEntrypointMigrationApplyStatus.blocked);
      expect(source, before);
      expect(result.projectJson, same(source));
      expect(result.issues.single.code, NewGameEntrypointMigrationIssueCode.projectInvalid);
    });

    test('rejects a stale apply without returning migrated data', () {
      final source = _legacyProjectJson();
      final plan = planNewGameEntrypointMigration(
        projectJson: source,
        projectRevision: 'project-r1',
      );

      final result = applyNewGameEntrypointMigration(
        projectJson: source,
        currentProjectRevision: 'project-r2',
        plan: plan,
      );

      expect(result.status, NewGameEntrypointMigrationApplyStatus.stale);
      expect(result.projectJson, same(source));
      expect(
        result.issues.single.code,
        NewGameEntrypointMigrationIssueCode.staleRevision,
      );
      expect(result.issues.single.diagnosticCode, 'new_game.migration_stale');
    });

    test('strict format refuses legacy project before inspecting its Scene', () {
      final source = _legacyProjectJson(profile: SceneExecutionProfile.world);

      final plan = planNewGameEntrypointMigration(
        projectJson: source,
        projectRevision: 'project-r1',
      );

      expect(plan.status, NewGameEntrypointMigrationStatus.blocked);
      expect(
        plan.issues.single.code,
        NewGameEntrypointMigrationIssueCode.projectInvalid,
      );
      expect(
        plan.issues.single.diagnosticCode,
        'new_game.migration_project_invalid',
      );
      expect(plan.issues.single.path, r'$');
    });

    test('blocks ambiguous legacy and canonical entrypoints', () {
      final source = _legacyProjectJson();
      (source['newGame'] as Map<String, dynamic>)['preSessionSceneId'] =
          'scene_other';

      final plan = planNewGameEntrypointMigration(
        projectJson: source,
        projectRevision: 'project-r1',
      );

      expect(plan.status, NewGameEntrypointMigrationStatus.blocked);
      expect(
        plan.issues.single.code,
        NewGameEntrypointMigrationIssueCode.ambiguousEntrypoint,
      );
    });

    test('reports no changes without a legacy entrypoint', () {
      final source = _legacyProjectJson();
      (source['newGame'] as Map<String, dynamic>).remove(
        'starterSelectionSceneId',
      );

      final plan = planNewGameEntrypointMigration(
        projectJson: source,
        projectRevision: 'project-r1',
      );

      expect(plan.status, NewGameEntrypointMigrationStatus.noChanges);
      expect(plan.changes, isEmpty);
      expect(plan.issues, isEmpty);
    });
  });
}

Map<String, dynamic> _legacyProjectJson({
  SceneExecutionProfile profile = SceneExecutionProfile.preSession,
}) {
  final project = ProjectManifest(
    name: 'Legacy entrypoint project',
    version: ProjectVersion.v6,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    scenes: <SceneAsset>[_scene(profile)],
    newGame: const ProjectNewGameConfig(),
  ).toJson();
  (project['newGame'] as Map<String, dynamic>)['starterSelectionSceneId'] =
      'scene_intro';
  return project;
}

SceneAsset _scene(SceneExecutionProfile profile) => SceneAsset(
      id: 'scene_intro',
      name: 'Introduction',
      executionProfile: profile,
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'start-end',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
    );

Map<String, dynamic> _deepCopy(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
