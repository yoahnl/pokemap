import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const wire = <String, dynamic>{
    'kind': 'receivePokemonFromCatalog',
    'speciesId': 'clockbird',
    'formId': 'bronze',
    'level': 7,
    'nicknamePolicy': 'offer',
    'nicknameMaxGraphemes': 10,
    'pokedexPresentationPolicy': 'whenNewAndPokedexVisible',
  };

  test('interactive catalog gift has strict policies and business ports', () {
    final command = SceneInteractiveCommand.fromJson(wire);
    expect(command.toJson(), wire);
    expect(SceneInteractiveCommand.fromJson(command.toJson()), command);
    expect(command.outputPortIds, ['party', 'pc', 'noCapacity']);
  });

  test('interactive catalog gift rejects malformed fields and overrides', () {
    for (final field in wire.keys.where((field) => field != 'kind')) {
      final missing = {...wire}..remove(field);
      expect(
        () => SceneInteractiveCommand.fromJson(missing),
        throwsFormatException,
      );
    }
    for (final entry in <String, Object?>{
      'level': 0,
      'nicknameMaxGraphemes': 0,
      'nicknamePolicy': 'automatic',
      'pokedexPresentationPolicy': 'hasDex',
      'nickname': 'override',
      'currentHp': 999,
    }.entries) {
      expect(
        () =>
            SceneInteractiveCommand.fromJson({...wire, entry.key: entry.value}),
        throwsFormatException,
      );
    }
  });

  test(
    'guided builder and catalogue expose the complete native interaction',
    () {
      final payload =
          buildScenePayloadForNarrativeCommand(
                commandId: 'receivePokemonFromCatalog',
                parameters: {
                  for (final entry in wire.entries)
                    if (entry.key != 'kind') entry.key: '${entry.value}',
                },
              )
              as SceneActionPayload;
      expect(payload.interactiveCommand!.toJson(), wire);
      final descriptor = NarrativeCommandCatalog.canonical().byId(
        'receivePokemonFromCatalog',
      )!;
      expect(descriptor.isAwaitable, isTrue);
      expect(descriptor.isPersistent, isTrue);
      expect(descriptor.fgLotId, 'FG-103');
      expect(
        descriptor.parameters.map((p) => p.id),
        [...wire.keys.where((k) => k != 'kind'), 'moveIds'],
      );
    },
  );

  test('dry run requires a business outcome and routes branchByOutcome', () {
    final gift = SceneInteractiveCommand.fromJson(wire);
    final nodes = [
      SceneRuntimePlanNode(
        id: 'start',
        kind: SceneNodeKind.start,
        intent: SceneRuntimePlanIntent.start(),
      ),
      SceneRuntimePlanNode(
        id: 'gift',
        kind: SceneNodeKind.action,
        intent: SceneRuntimePlanIntent.executeInteractiveCommand(
          command: gift,
          sourceNodeId: 'gift',
        ),
      ),
      SceneRuntimePlanNode(
        id: 'branch',
        kind: SceneNodeKind.branchByOutcome,
        intent: SceneRuntimePlanIntent.branchByOutcome(
          sourceNodeId: 'gift',
          fallbackPolicy: SceneBranchOutcomeFallbackPolicy.exact,
          sourceOutcomes: gift.outputPortIds,
        ),
      ),
      for (final port in gift.outputPortIds)
        SceneRuntimePlanNode(
          id: port,
          kind: SceneNodeKind.end,
          intent: SceneRuntimePlanIntent.end(sceneOutcomeId: port),
        ),
    ];
    final plan = SceneRuntimePlan(
      sceneId: 'gift',
      startNodeId: 'start',
      declaredOutcomes: [
        for (final port in gift.outputPortIds)
          SceneOutcome(id: port, label: port),
      ],
      nodes: nodes,
      edges: [
        SceneRuntimePlanEdge(
          id: 'a',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'gift',
          kind: SceneEdgeKind.defaultFlow,
        ),
        for (final port in gift.outputPortIds) ...[
          SceneRuntimePlanEdge(
            id: 'gift-$port',
            fromNodeId: 'gift',
            fromPortId: port,
            toNodeId: 'branch',
            kind: SceneEdgeKind.actionCompleted,
          ),
          SceneRuntimePlanEdge(
            id: 'branch-$port',
            fromNodeId: 'branch',
            fromPortId: port,
            toNodeId: port,
            kind: SceneEdgeKind.branchOutcome,
          ),
        ],
      ],
    );
    final awaiting = previewSceneRuntimePath(
      plan,
      input: const SceneDryRunInputState(),
    );
    expect(awaiting.status, SceneDryRunPreviewStatus.awaitingInput);
    expect(awaiting.acceptedOutputPortIds, gift.outputPortIds);
    for (final port in gift.outputPortIds) {
      final result = previewSceneRuntimePath(
        plan,
        input: SceneDryRunInputState(outputPortByNodeId: {'gift': port}),
      );
      expect(
        result.status,
        SceneDryRunPreviewStatus.completed,
        reason: result.message,
      );
      expect(result.sceneOutcomeId, port);
      expect(result.context.lastOutcomeByNodeId['gift'], port);
    }
    final invalid = previewSceneRuntimePath(
      plan,
      input: SceneDryRunInputState(outputPortByNodeId: {'gift': 'cancelled'}),
    );
    expect(invalid.status, SceneDryRunPreviewStatus.failed);
  });

  test(
    'both native dimensions expose external catalog verification honestly',
    () {
      final command = SceneInteractiveCommand.fromJson(wire);
      final scene = SceneAsset(
        id: 'gift',
        name: 'Gift',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'gift',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.interactive(command),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'start',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'gift',
              kind: SceneEdgeKind.defaultFlow,
            ),
            for (final port in command.outputPortIds)
              SceneEdge(
                id: port,
                fromNodeId: 'gift',
                fromPortId: port,
                toNodeId: 'end',
                kind: SceneEdgeKind.actionCompleted,
              ),
          ],
        ),
      );
      for (final dimension in ProjectDimension.values) {
        final project = ProjectManifest(
          name: 'Gift',
          maps: [],
          tilesets: [],
          scenes: [scene],
          settings: ProjectSettings(dimension: dimension),
        );
        final diagnostics = diagnoseSceneAgainstProject(scene, project);
        expect(diagnostics.hasErrors, isFalse);
        expect(
          diagnostics.diagnostics
              .where(
                (d) =>
                    d.code == SceneDiagnosticCode.commandPokemonCatalogDeferred,
              )
              .single
              .severity,
          SceneDiagnosticSeverity.info,
        );
        final disabled = diagnoseSceneAgainstProject(
          scene,
          project.copyWith(pokemon: project.pokemon.copyWith(enabled: false)),
        );
        expect(
          disabled.diagnostics.any(
            (d) =>
                d.code ==
                    SceneDiagnosticCode.commandPokemonCatalogUnavailable &&
                d.severity == SceneDiagnosticSeverity.error,
          ),
          isTrue,
        );
      }
    },
  );

  test('catalog consequence remains closed against nickname overrides', () {
    expect(
      () => SceneConsequence.fromJson({
        'kind': 'givePokemonFromCatalog',
        'speciesId': 'clockbird',
        'formId': 'bronze',
        'level': 7,
        'nickname': 'No',
      }),
      throwsFormatException,
    );
  });
}
