import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/application/cutscene_studio_authoring.dart';

void main() {
  group('Cutscene Studio authoring parse/build', () {
    test('parses a linear local flow into editable blocks', () {
      const scenario = ScenarioAsset(
        id: 'npc_intro',
        name: 'NPC Intro',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'start',
        nodes: <ScenarioNode>[
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
          ScenarioNode(
            id: 'source',
            type: ScenarioNodeType.reference,
            payload: ScenarioNodePayload(
                actionKind: kCutsceneStudioSourceEntityInteract),
            binding:
                ScenarioNodeBinding(mapId: 'vova_center', entityId: 'npc_emma'),
          ),
          ScenarioNode(
            id: 'dialogue_1',
            type: ScenarioNodeType.dialogue,
            binding: ScenarioNodeBinding(dialogueId: 'emma_intro'),
          ),
          ScenarioNode(
            id: 'emit_1',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
                actionKind: kCutsceneStudioActionEmitOutcome),
            binding: ScenarioNodeBinding(outcomeId: 'emma.intro.completed'),
          ),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
        ],
        edges: <ScenarioEdge>[
          ScenarioEdge(id: 'e1', fromNodeId: 'start', toNodeId: 'source'),
          ScenarioEdge(id: 'e2', fromNodeId: 'source', toNodeId: 'dialogue_1'),
          ScenarioEdge(id: 'e3', fromNodeId: 'dialogue_1', toNodeId: 'emit_1'),
          ScenarioEdge(id: 'e4', fromNodeId: 'emit_1', toNodeId: 'end'),
        ],
      );

      final parsed = parseScenarioToCutsceneStudioDocument(scenario);

      expect(parsed.editable, isTrue);
      expect(parsed.warnings, isEmpty);
      expect(
          parsed.document.source.kind, CutsceneStudioSourceKind.entityInteract);
      expect(parsed.document.source.mapId, 'vova_center');
      expect(parsed.document.source.entityId, 'npc_emma');
      expect(parsed.document.blocks.length, 2);
      expect(
          parsed.document.blocks.first.kind, CutsceneStudioBlockKind.dialogue);
      expect(parsed.document.blocks.first.dialogueId, 'emma_intro');
      expect(parsed.document.blocks.last.kind,
          CutsceneStudioBlockKind.sceneResult);
      expect(parsed.document.blocks.last.outcomeId, 'emma.intro.completed');
    });

    test('marks branched graph as non editable in v1', () {
      const scenario = ScenarioAsset(
        id: 'branched_cutscene',
        name: 'Branched',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'start',
        nodes: <ScenarioNode>[
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
          ScenarioNode(
            id: 'source',
            type: ScenarioNodeType.reference,
            payload:
                ScenarioNodePayload(actionKind: kCutsceneStudioSourceMapEnter),
            binding: ScenarioNodeBinding(mapId: 'vova_center'),
          ),
          ScenarioNode(id: 'choice', type: ScenarioNodeType.choice),
          ScenarioNode(id: 'end_a', type: ScenarioNodeType.end),
          ScenarioNode(id: 'end_b', type: ScenarioNodeType.end),
        ],
        edges: <ScenarioEdge>[
          ScenarioEdge(id: 'e1', fromNodeId: 'start', toNodeId: 'source'),
          ScenarioEdge(id: 'e2', fromNodeId: 'source', toNodeId: 'choice'),
          ScenarioEdge(
            id: 'e3',
            fromNodeId: 'choice',
            toNodeId: 'end_a',
            kind: ScenarioEdgeKind.choice,
          ),
          ScenarioEdge(
            id: 'e4',
            fromNodeId: 'choice',
            toNodeId: 'end_b',
            kind: ScenarioEdgeKind.choice,
          ),
        ],
      );

      final parsed = parseScenarioToCutsceneStudioDocument(scenario);

      expect(parsed.editable, isFalse);
      expect(parsed.warnings, isNotEmpty);
    });

    test('builds a linear scenario graph from studio document', () {
      const document = CutsceneStudioDocument(
        id: 'starter_intro',
        name: 'Starter Intro',
        description: 'Simple guided scene',
        source: CutsceneStudioSourceConfig(
          kind: CutsceneStudioSourceKind.mapEnter,
          mapId: 'vova_east',
        ),
        blocks: <CutsceneStudioBlock>[
          CutsceneStudioBlock(
            id: 'b1',
            kind: CutsceneStudioBlockKind.dialogue,
            dialogueId: 'intro',
          ),
          CutsceneStudioBlock(
            id: 'b2',
            kind: CutsceneStudioBlockKind.setFlag,
            flagName: 'story.intro_seen',
          ),
          CutsceneStudioBlock(
            id: 'b3',
            kind: CutsceneStudioBlockKind.emitOutcome,
            outcomeId: 'chapter_1.intro_ready',
          ),
        ],
      );

      final compiled = buildScenarioFromCutsceneStudioDocument(document);

      expect(compiled.id, 'starter_intro');
      expect(compiled.scope, ScenarioScope.localEventFlow);
      expect(compiled.entryNodeId, 'start');
      expect(
        compiled.metadata[kCutsceneStudioSchemaMetadataKey],
        kCutsceneStudioSchemaVersion,
      );
      expect(compiled.metadata[kCutsceneStudioFlowMetadataKey], isNotEmpty);
      expect(compiled.declaredOutcomes, contains('chapter_1.intro_ready'));

      final sourceNode =
          compiled.nodes.firstWhere((node) => node.id == 'source');
      expect(sourceNode.payload.actionKind, kCutsceneStudioSourceMapEnter);
      expect(sourceNode.binding.mapId, 'vova_east');

      final hasDialogueNode = compiled.nodes.any((node) =>
          node.type == ScenarioNodeType.dialogue &&
          node.binding.dialogueId == 'intro');
      expect(hasDialogueNode, isTrue);

      final hasEnd =
          compiled.nodes.any((node) => node.type == ScenarioNodeType.end);
      expect(hasEnd, isTrue);
    });

    test('builds sceneResult with generated internal outcome id', () {
      const document = CutsceneStudioDocument(
        id: 'emma_intro_scene',
        name: 'Emma Intro',
        description: '',
        source: CutsceneStudioSourceConfig(
          kind: CutsceneStudioSourceKind.entityInteract,
          mapId: 'bourivka_center',
          entityId: 'emma',
        ),
        blocks: <CutsceneStudioBlock>[
          CutsceneStudioBlock(
            id: 'result_1',
            kind: CutsceneStudioBlockKind.sceneResult,
            resultLabel: 'Emma rencontrée',
            resultScope: kCutsceneStudioResultScopeProgression,
          ),
        ],
      );

      final compiled = buildScenarioFromCutsceneStudioDocument(document);
      expect(
          compiled.declaredOutcomes, contains('progression.emma_rencontr_e'));
      final resultNode =
          compiled.nodes.firstWhere((node) => node.id == 'result_1');
      expect(resultNode.payload.actionKind, kCutsceneStudioActionEmitOutcome);
      expect(resultNode.binding.outcomeId, 'progression.emma_rencontr_e');
    });

    test('builds moveCharacter block runtime payload', () {
      const document = CutsceneStudioDocument(
        id: 'move_scene',
        name: 'Move Scene',
        description: '',
        source: CutsceneStudioSourceConfig(
          kind: CutsceneStudioSourceKind.mapEnter,
          mapId: 'bourivka_center',
        ),
        blocks: <CutsceneStudioBlock>[
          CutsceneStudioBlock(
            id: 'move_1',
            kind: CutsceneStudioBlockKind.moveCharacter,
            actorId: 'emma',
            destinationTargetKind: kCutsceneStudioMoveTargetWarp,
            destinationTargetId: 'lab_entry',
            waitForCompletion: true,
          ),
        ],
      );

      final compiled = buildScenarioFromCutsceneStudioDocument(document);
      final moveNode = compiled.nodes.firstWhere((node) => node.id == 'move_1');
      expect(moveNode.payload.actionKind, kCutsceneStudioActionMoveCharacter);
      expect(moveNode.binding.entityId, 'emma');
      expect(
          moveNode.payload.params['targetKind'], kCutsceneStudioMoveTargetWarp);
      expect(moveNode.payload.params['targetId'], 'lab_entry');
      expect(moveNode.payload.params['waitForCompletion'], 'true');
    });

    test('choice compilation inserts flowMerge joints, not wait 0', () {
      final document = createCutsceneStudioDemoFlowDocument(
        id: 'flow_demo',
        name: 'Flow demo',
      );
      final compiled = buildScenarioFromCutsceneStudioDocument(document);
      final merges = compiled.nodes
          .where((n) => n.payload.actionKind == kCutsceneStudioActionFlowMerge)
          .toList();
      expect(merges, isNotEmpty);
      final fakeWaits = compiled.nodes.where(
        (n) =>
            n.payload.actionKind == kCutsceneStudioActionWaitMs &&
            n.payload.params['durationMs'] == '0',
      );
      expect(fakeWaits, isEmpty);
    });

    test('palette stub blocks compile to authoringPlaceholder metadata', () {
      const document = CutsceneStudioDocument(
        id: 'stub_scene',
        name: 'Stub',
        description: '',
        source: CutsceneStudioSourceConfig(
          kind: CutsceneStudioSourceKind.mapEnter,
          mapId: 'map_a',
        ),
        blocks: <CutsceneStudioBlock>[
          CutsceneStudioBlock(
            id: 'cam1',
            kind: CutsceneStudioBlockKind.cameraCenter,
            actorId: 'actor_x',
          ),
        ],
      );
      final compiled = buildScenarioFromCutsceneStudioDocument(document);
      final node = compiled.nodes.firstWhere((n) => n.id == 'cam1');
      expect(
        node.payload.actionKind,
        kCutsceneStudioActionAuthoringPlaceholder,
      );
      expect(
        node.metadata[kCutsceneStudioPlaceholderKindMetadataKey],
        CutsceneStudioBlockKind.cameraCenter.name,
      );
    });

    test('runtime advisories surface choice MVP limitation', () {
      final document = createCutsceneStudioDemoFlowDocument(
        id: 'adv_demo',
        name: 'Adv',
      );
      final adv = cutsceneStudioRuntimeAdvisories(document);
      expect(
        adv.any((s) => s.contains('choice') || s.contains('Choix')),
        isTrue,
      );
    });
  });
}
