import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final definition = PeriodicItemRewardDefinition(
    rewardId: 'tree-fruit',
    label: 'Fruit quotidien',
    itemId: 'fruit',
    quantity: 2,
  );
  final command = SceneInteractiveCommand.claimPeriodicReward(
    definition: definition,
  );
  final scene = SceneAsset(
    id: 'reward',
    name: 'Reward',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'reward',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.interactive(command),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'enter',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'reward',
          kind: SceneEdgeKind.defaultFlow,
        ),
        for (final port in command.outputPortIds)
          SceneEdge(
            id: port,
            fromNodeId: 'reward',
            fromPortId: port,
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
      ],
    ),
  );
  final project = const ProjectManifest(
    name: 'Periodic',
    maps: [],
    tilesets: [],
  ).copyWith(scenes: [scene]);
  test('periodic reward is typed publishable authoring with four outputs', () {
    final descriptor = NarrativeCommandCatalog.canonical().byId(
      'claimPeriodicReward',
    );
    expect(descriptor, isNotNull);
    expect(descriptor!.isPublishable, isTrue);
    expect(descriptor.parameters.map((field) => field.id), [
      'rewardId',
      'label',
      'itemId',
      'quantity',
    ]);
    final payload =
        buildScenePayloadForNarrativeCommand(
              commandId: descriptor.id,
              parameters: {
                'rewardId': 'tree-fruit',
                'label': 'Fruit quotidien',
                'itemId': 'fruit',
                'quantity': '2',
              },
            )
            as SceneActionPayload;
    expect(payload.interactiveCommand, command);
    expect(command.outputPortIds, [
      'received',
      'alreadyClaimed',
      'bagFull',
      'blocked',
    ]);
    expect(
      authorableSceneOutputPortsForNode(
        scene.graph.nodes[1],
      ).map((port) => port.id),
      command.outputPortIds,
    );
    expect(
      SpatialGameplayCapabilities.supportsSceneNode(
        SceneExecutionProfile.world,
        scene.graph.nodes[1],
      ),
      isTrue,
    );
  });
  test(
    'periodic reward rejects invalid identities quantities and unknown parameters',
    () {
      final valid = {
        'rewardId': 'tree-fruit',
        'label': 'Fruit',
        'itemId': 'fruit',
        'quantity': '2',
      };
      for (final entry in [
        {'rewardId': ''},
        {'itemId': ''},
        {'quantity': '0'},
        {'quantity': '-1'},
        {'quantity': '1.5'},
        {'unexpected': 'value'},
      ]) {
        expect(
          () => buildScenePayloadForNarrativeCommand(
            commandId: 'claimPeriodicReward',
            parameters: {...valid, ...entry},
          ),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'periodic item diagnostics distinguish unloaded known and unknown catalogs',
    () {
      final diagnostics = SceneProjectDiagnosticsContext(
        project,
      ).diagnose(scene);
      expect(
        diagnostics
            .byCode(SceneDiagnosticCode.commandItemCatalogUnavailable)
            .single
            .severity,
        SceneDiagnosticSeverity.warning,
      );
      expect(
        SceneProjectDiagnosticsContext(
          project,
          availableItemIds: {'fruit'},
        ).diagnose(scene).hasErrors,
        isFalse,
      );
      expect(
        SceneProjectDiagnosticsContext(project, availableItemIds: {})
            .diagnose(scene)
            .byCode(SceneDiagnosticCode.commandUnknownItem)
            .single
            .severity,
        SceneDiagnosticSeverity.error,
      );
    },
  );
  test(
    'periodic reward item is a blocking typed dependency and deletion reference',
    () {
      final dependency = buildNarrativeDependencyIndex(
        project: project,
      ).usages.singleWhere((usage) => usage.target.id == 'fruit');
      expect(dependency.target.kind, NarrativeDependencyTargetKind.item);
      expect(dependency.path, endsWith('.definition.itemId'));
      expect(
        dependency.criticality,
        NarrativeDependencyCriticality.runtimeBlocking,
      );
      final references = buildProjectItemReferenceIndex(
        project: project,
      ).blockingReferencesFor('fruit');
      expect(references, hasLength(1));
      expect(references.single.editablePath, endsWith('.definition.itemId'));
    },
  );
}
