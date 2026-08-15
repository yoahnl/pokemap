import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('New Game entrypoint migration', () {
    test('dry-run plans one canonical field without mutating input', () {
      final source = _legacyProjectJson();
      final before = _deepCopy(source);

      final plan = planNewGameEntrypointMigration(
        projectJson: source,
        projectRevision: 'project-r1',
      );

      expect(plan.status, NewGameEntrypointMigrationStatus.ready);
      expect(plan.sourceRevision, 'project-r1');
      expect(plan.sourceSceneId, 'scene_intro');
      expect(plan.changes, [
        const NewGameEntrypointMigrationChange(
          path: r'$.version',
          before: 'v6',
          after: 'v7',
        ),
        const NewGameEntrypointMigrationChange(
          path: r'$.newGame.starterSelectionSceneId',
          before: 'scene_intro',
          after: null,
        ),
        const NewGameEntrypointMigrationChange(
          path: r'$.newGame.preSessionSceneId',
          before: null,
          after: 'scene_intro',
        ),
      ]);
      expect(source, before);
    });

    test('apply is exact for the planned revision and keeps source intact', () {
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

      expect(result.status, NewGameEntrypointMigrationApplyStatus.applied);
      expect(source, before);
      expect(result.projectJson['version'], 'v7');
      final newGame = result.projectJson['newGame'] as Map<String, dynamic>;
      expect(newGame, isNot(contains('starterSelectionSceneId')));
      expect(newGame['preSessionSceneId'], 'scene_intro');
      final decoded = ProjectManifest.fromJson(result.projectJson);
      expect(decoded.newGame.preSessionSceneId, 'scene_intro');
      expect(() => ProjectValidator.validate(decoded), returnsNormally);
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

    test('blocks a world Scene with an actionable diagnostic', () {
      final source = _legacyProjectJson(profile: SceneExecutionProfile.world);

      final plan = planNewGameEntrypointMigration(
        projectJson: source,
        projectRevision: 'project-r1',
      );

      expect(plan.status, NewGameEntrypointMigrationStatus.blocked);
      expect(
        plan.issues.single.code,
        NewGameEntrypointMigrationIssueCode.sceneProfileIncompatible,
      );
      expect(
        plan.issues.single.diagnosticCode,
        'new_game.migration_scene_profile_incompatible',
      );
      expect(plan.issues.single.path, r'$.scenes[scene_intro]');
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
