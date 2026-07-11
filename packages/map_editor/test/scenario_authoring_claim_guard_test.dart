import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/project_scenario_use_cases.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';

const _guardMessage = 'Cette source est gérée par Event Builder V2. '
    'Ouvrez les événements liés ou retirez explicitement la migration.';

void main() {
  group('NS-EVENT-V2 Phase C3 Scenario authoring claim guard', () {
    test('unclaimed Scenario keeps its existing update behavior', () async {
      final repository = _FakeProjectRepository();
      final scenario = _scenario(id: 'unclaimed');
      final project = _project(scenarios: [scenario]);

      final updated = await UpdateProjectScenarioUseCase(repository).execute(
        const _FakeWorkspace(),
        project,
        scenarioId: scenario.id,
        nextScenario: scenario.copyWith(name: 'Unclaimed updated'),
      );

      expect(updated.scenarios.single.name, 'Unclaimed updated');
      expect(repository.saveCalls, 1);
    });

    test('valid claim freezes sibling edit, binding change, rename, and delete',
        () async {
      final repository = _FakeProjectRepository();
      final scenario = _scenario(id: 'claimed');
      final project = _project(
        scenarios: [scenario],
        eventRegistry: _registryFor(scenario),
      );
      final update = UpdateProjectScenarioUseCase(repository);
      final siblingEdit = scenario.copyWith(
        nodes: [
          for (final node in scenario.nodes)
            if (node.id == 'start')
              node.copyWith(title: 'Edited sibling')
            else
              node,
        ],
      );
      final bindingEdit = scenario.copyWith(
        nodes: [
          for (final node in scenario.nodes)
            if (node.id == 'source')
              node.copyWith(
                binding: node.binding.copyWith(entityId: 'npc_b'),
              )
            else
              node,
        ],
      );

      await _expectGuarded(
        () => update.execute(
          const _FakeWorkspace(),
          project,
          scenarioId: scenario.id,
          nextScenario: siblingEdit,
        ),
      );
      await _expectGuarded(
        () => update.execute(
          const _FakeWorkspace(),
          project,
          scenarioId: scenario.id,
          nextScenario: bindingEdit,
        ),
      );
      await _expectGuarded(
        () => update.execute(
          const _FakeWorkspace(),
          project,
          scenarioId: scenario.id,
          nextScenario: scenario.copyWith(id: 'renamed'),
        ),
      );
      await _expectGuarded(
        () => DeleteProjectScenarioUseCase(repository).execute(
          const _FakeWorkspace(),
          project,
          scenarioId: scenario.id,
        ),
      );

      expect(project.scenarios.single, same(scenario));
      expect(repository.saveCalls, 0);
    });

    test('tombstone claim remains a freeze instead of looking absent',
        () async {
      final repository = _FakeProjectRepository();
      final scenario = _scenario(id: 'tombstone');
      final project = _project(
        scenarios: [scenario],
        eventRegistry: _registryFor(scenario, targetExists: false),
      );

      await _expectGuarded(
        () => UpdateProjectScenarioUseCase(repository).execute(
          const _FakeWorkspace(),
          project,
          scenarioId: scenario.id,
          nextScenario: scenario.copyWith(name: 'Must stay frozen'),
        ),
      );
      await _expectGuarded(
        () => DeleteProjectScenarioUseCase(repository).execute(
          const _FakeWorkspace(),
          project,
          scenarioId: scenario.id,
        ),
      );

      expect(repository.saveCalls, 0);
    });

    test('new ambiguous duplicate is refused while unrelated create works',
        () async {
      final claimed = _scenario(id: 'claimed');
      final project = _project(
        scenarios: [claimed],
        eventRegistry: _registryFor(claimed),
      );
      final blockedRepository = _FakeProjectRepository();

      await _expectGuarded(
        () => CreateProjectScenarioUseCase(blockedRepository).execute(
          const _FakeWorkspace(),
          project,
          scenario: _scenario(id: 'ambiguous_duplicate'),
        ),
      );
      expect(blockedRepository.saveCalls, 0);

      final allowedRepository = _FakeProjectRepository();
      final updated =
          await CreateProjectScenarioUseCase(allowedRepository).execute(
        const _FakeWorkspace(),
        project,
        scenario: _scenario(
          id: 'unrelated',
          mapId: 'map_b',
          entityId: 'npc_b',
        ),
      );
      expect(updated.scenarios.map((value) => value.id),
          containsAll(<String>['claimed', 'unrelated']));
      expect(allowedRepository.saveCalls, 1);
    });

    test('a provenance omitted from a claimed source fails closed', () async {
      final claimed = _scenario(id: 'claimed');
      final duplicate = _scenario(id: 'existing_duplicate');
      final project = _project(
        scenarios: [claimed, duplicate],
        eventRegistry: _registryFor(claimed),
      );
      final repository = _FakeProjectRepository();

      await _expectGuarded(
        () => UpdateProjectScenarioUseCase(repository).execute(
          const _FakeWorkspace(),
          project,
          scenarioId: duplicate.id,
          nextScenario: duplicate.copyWith(name: 'Must remain unchanged'),
        ),
      );
      await _expectGuarded(
        () => DeleteProjectScenarioUseCase(repository).execute(
          const _FakeWorkspace(),
          project,
          scenarioId: duplicate.id,
        ),
      );

      expect(repository.saveCalls, 0);
    });
  });
}

Future<void> _expectGuarded(Future<Object?> Function() action) async {
  await expectLater(
    action,
    throwsA(
      isA<EditorInvalidOperationException>().having(
        (error) => error.message,
        'message',
        _guardMessage,
      ),
    ),
  );
}

ScenarioAsset _scenario({
  required String id,
  String mapId = 'map_a',
  String entityId = 'npc_a',
}) {
  return ScenarioAsset(
    id: id,
    name: id,
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'start',
    nodes: [
      const ScenarioNode(id: 'start', type: ScenarioNodeType.start),
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: const ScenarioNodePayload(
          actionKind: 'sourceEntityInteract',
        ),
        binding: ScenarioNodeBinding(mapId: mapId, entityId: entityId),
      ),
      const ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: const [
      ScenarioEdge(id: 'start-source', fromNodeId: 'start', toNodeId: 'source'),
      ScenarioEdge(id: 'source-end', fromNodeId: 'source', toNodeId: 'end'),
    ],
  );
}

ProjectManifest _project({
  required List<ScenarioAsset> scenarios,
  NarrativeEventRegistry? eventRegistry,
}) {
  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: 'Phase C3',
    maps: const [
      ProjectMapEntry(
        id: 'map_a',
        name: 'Map A',
        relativePath: 'maps/map_a.json',
      ),
      ProjectMapEntry(
        id: 'map_b',
        name: 'Map B',
        relativePath: 'maps/map_b.json',
      ),
    ],
    tilesets: const [],
    scenarios: scenarios,
    eventRegistry: eventRegistry,
  );
}

NarrativeEventRegistry _registryFor(
  ScenarioAsset scenario, {
  bool targetExists = true,
}) {
  final source = NarrativeEventSourceRef.entityInteract('map_a', 'npc_a');
  final provenance = LegacySourceRef.scenarioSourceNode(
    scenario.id,
    'source',
  );
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: computeScenarioSourceFingerprint(
      scenarioId: scenario.id,
      nodeId: 'source',
      scenario: scenario,
    ),
  );
  final cohortId = computeLegacySourceCohortId(source, [provenance]);
  const eventId = 'evt_018f1234-5678-7abc-8def-0123456789ab';
  return NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.legacyOnly,
    records: targetExists
        ? [
            NarrativeEventRecord.configuredStructurallyUnchecked(
              NarrativeEventDefinition(
                id: eventId,
                name: 'Claim target',
                source: source,
                conditions: const [],
                sceneId: 'scene_target',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 0,
              ),
              enabled: false,
            ),
          ]
        : const [],
    legacyClaims: [
      LegacySourceClaim(
        cohortId: cohortId,
        source: source,
        members: [member],
        cohortFingerprint: computeLegacySourceCohortFingerprint(
          cohortId,
          [member],
        ),
        targetEventIds: const [eventId],
        migrationReceiptId: 'receipt_c3',
      ),
    ],
  );
}

final class _FakeProjectRepository implements ProjectRepository {
  int saveCalls = 0;

  @override
  Future<ProjectManifest> loadProject(String path) async {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    saveCalls++;
  }
}

final class _FakeWorkspace implements ProjectWorkspace {
  const _FakeWorkspace();

  @override
  String get projectManifestPath => '/tmp/project.json';

  @override
  String get projectRoot => '/tmp';

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {}

  @override
  Future<void> deleteDirectoryIfEmpty(String path) async {}

  @override
  Future<void> deleteRelativeFile(String relativePath) async {}

  @override
  Future<bool> directoryExists(String path) async => false;

  @override
  Future<void> ensureDirectoryExists(String path) async {}

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  String getMapPath(String mapId) => '/tmp/maps/$mapId.json';

  @override
  String getMapRelativePath(String mapId) => 'maps/$mapId.json';

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async =>
      '/tmp/tilesets/image.png';

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {}

  @override
  Future<String> readTextFile(String path) async => '';

  @override
  String resolveMapPath(String relativePath) => '/tmp/$relativePath';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '/tmp/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) => '/tmp/$relativePath';

  @override
  Future<void> writeTextFile(String path, String contents) async {}
}
