import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Cinematic legacy migration', () {
    test('previews and applies an empty Cutscene bridge without deleting it',
        () {
      final project = _project(
        scenarios: const [
          ScenarioAsset(
            id: 'intro',
            name: 'Intro legacy',
            entryNodeId: 'start',
            metadata: {'authoring.cutsceneSchema': 'cutscene-studio-v0'},
          ),
        ],
        scenes: [_scene('intro')],
      );

      final plan = buildCinematicLegacyMigrationPlan(project);

      expect(plan.readyCount, 1);
      expect(plan.blockedCount, 0);
      expect(plan.candidates.single.sceneReferenceCount, 1);
      final result = applyCinematicLegacyMigration(
        project,
        plan.candidates.single,
      );
      expect(result.disposition, CinematicLegacyMigrationDisposition.migrated);
      expect(result.after.scenarios, project.scenarios,
          reason: 'The source remains as rollback evidence.');
      expect(result.after.cinematics.single.id, 'cinematic_intro');
      expect(
        (result.after.scenes.single.graph.nodes[1].payload
                as SceneCinematicPayload)
            .cinematicId,
        'cinematic_intro',
      );
      expect(result.rollback(), project);
    });

    test('blocks unknown authored nodes instead of silently losing data', () {
      final project = _project(
        scenarios: const [
          ScenarioAsset(
            id: 'intro',
            name: 'Intro legacy',
            entryNodeId: 'start',
            nodes: [ScenarioNode(id: 'start', type: ScenarioNodeType.start)],
            metadata: {'authoring.cutsceneSchema': 'cutscene-studio-v0'},
          ),
        ],
      );

      final plan = buildCinematicLegacyMigrationPlan(project);

      expect(plan.readyCount, 0);
      expect(plan.blockedCount, 1);
      expect(plan.lossRiskCount, 1);
      expect(plan.candidates.single.canApply, isFalse);
    });

    test('is idempotent when a canonical receipt already owns the source', () {
      final project = _project(
        scenarios: const [
          ScenarioAsset(
            id: 'intro',
            name: 'Intro legacy',
            entryNodeId: 'start',
            metadata: {'authoring.cutsceneSchema': 'cutscene-studio-v0'},
          ),
        ],
        cinematics: [
          CinematicAsset(
            id: 'cinematic_intro',
            title: 'Intro',
            timeline: CinematicTimeline(),
            metadata: const {
              'migration.sourceScenarioId': 'intro',
              'migration.schemaVersion': '1',
            },
            legacyBridge: CinematicLegacyBridge(
              sourceKind: CinematicLegacyBridgeSourceKind.cutsceneStudio,
              scenarioId: 'intro',
            ),
          ),
        ],
      );

      final plan = buildCinematicLegacyMigrationPlan(project);

      expect(plan.alreadyMigratedCount, 1);
      final result = applyCinematicLegacyMigration(
        project,
        plan.candidates.single,
      );
      expect(result.disposition, CinematicLegacyMigrationDisposition.noChange);
      expect(result.after, project);
    });
  });

  group('consolidated legacy scan and recovery', () {
    test('counts each domain and exposes explicit retirement conditions', () {
      final project = _project(
        scenarios: const [
          ScenarioAsset(
            id: 'story',
            name: 'Story',
            scope: ScenarioScope.globalStory,
            entryNodeId: 'start',
          ),
          ScenarioAsset(
            id: 'intro',
            name: 'Intro legacy',
            entryNodeId: 'start',
            metadata: {'authoring.cutsceneSchema': 'cutscene-studio-v0'},
          ),
        ],
      );

      final scan = buildNarrativeLegacyMigrationScan(
        project,
        legacyMapEventCount: 2,
        eventBlockerCount: 1,
      );

      expect(scan.schemaVersion, 1);
      expect(scan.legacyRemainingCount, 4);
      expect(scan.domain(NarrativeLegacyDomain.storyline).remainingCount, 1);
      expect(scan.domain(NarrativeLegacyDomain.event).remainingCount, 2);
      expect(scan.domain(NarrativeLegacyDomain.cinematic).remainingCount, 1);
      expect(scan.canRetireLegacyReaders, isFalse);
      expect(scan.backupRequired, isTrue);
    });

    test('publishes the consolidated remaining counter in Validator', () {
      final project = _project(
        scenarios: const [
          ScenarioAsset(
            id: 'story',
            name: 'Story',
            scope: ScenarioScope.globalStory,
            entryNodeId: 'start',
          ),
        ],
      );

      final report = validateNarrativeProject(project, maps: const []);

      final diagnostic = report.byCode('narrativeLegacyRemaining').single;
      expect(diagnostic.message, contains('1 source'));
      expect(
        diagnostic.destination,
        NarrativeProjectDiagnosticDestination.overview,
      );
    });

    test('resumes after interruption and rolls back all completed domains', () {
      final project = _project();
      final transaction = NarrativeLegacyMigrationTransaction.start(project);
      final afterStory = transaction.applyDomain(
        NarrativeLegacyDomain.storyline,
        (current) => current.copyWith(name: 'after-story'),
      );
      final interrupted = afterStory.applyDomain(
        NarrativeLegacyDomain.event,
        (_) => throw StateError('simulated interruption'),
      );

      expect(interrupted.status, NarrativeLegacyTransactionStatus.interrupted);
      expect(interrupted.current.name, 'after-story');
      expect(interrupted.completedDomains, [NarrativeLegacyDomain.storyline]);

      final resumed = interrupted.resume().applyDomain(
            NarrativeLegacyDomain.event,
            (current) => current.copyWith(name: 'after-event'),
          );
      expect(resumed.status, NarrativeLegacyTransactionStatus.active);
      expect(resumed.completedDomains, [
        NarrativeLegacyDomain.storyline,
        NarrativeLegacyDomain.event,
      ]);
      expect(resumed.rollback(), project);
    });
  });
}

ProjectManifest _project({
  List<ScenarioAsset> scenarios = const [],
  List<CinematicAsset> cinematics = const [],
  List<SceneAsset> scenes = const [],
}) {
  return ProjectManifest(
    name: 'legacy_project',
    maps: const [],
    tilesets: const [],
    scenarios: scenarios,
    cinematics: cinematics,
    scenes: scenes,
  );
}

SceneAsset _scene(String cinematicId) {
  return SceneAsset(
    id: 'scene_intro',
    name: 'Intro',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'cinematic',
          kind: SceneNodeKind.cinematic,
          payload: SceneCinematicPayload(cinematicId: cinematicId),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'e1',
          fromNodeId: 'start',
          fromPortId: 'next',
          toNodeId: 'cinematic',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'e2',
          fromNodeId: 'cinematic',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.cinematicCompleted,
        ),
      ],
    ),
  );
}
