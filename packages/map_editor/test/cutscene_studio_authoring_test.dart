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
          CutsceneStudioBlockKind.emitOutcome);
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
      expect(compiled.metadata[kCutsceneStudioSchemaMetadataKey],
          kCutsceneStudioSchemaVersion);
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
  });
}
