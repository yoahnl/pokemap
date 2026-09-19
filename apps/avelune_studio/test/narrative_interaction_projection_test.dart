import 'package:avelune_studio/features/narrative/application/narrative_interaction.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction_reader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  final draft = NarrativeInteractionDraft(
    id: 'evt_019abcde-9000-7000-8000-000000000001',
    name: 'Une conversation',
    mapId: 'map',
    source: NarrativeEventSourceRef.entityInteract('map', 'npc'),
    dialogueId: 'dialogue',
    conditions: [NarrativeEventCondition.fact('ready', true)],
    steps: const [
      NarrativeSequenceStep(
        kind: NarrativeSequenceKind.facing,
        targetId: 'npc',
        facing: EntityFacing.west,
      ),
      NarrativeSequenceStep(
        kind: NarrativeSequenceKind.wait,
        milliseconds: 400,
      ),
    ],
    branches: const {
      'accept': [
        NarrativeSequenceStep(
          kind: NarrativeSequenceKind.setFact,
          targetId: 'accepted',
        ),
      ],
      'refuse': [],
    },
  );
  final projection = draft.project();
  final manifest = ProjectManifest(
    name: 'Test',
    maps: [],
    tilesets: [],
    scenes: [projection.scene],
    cinematics: projection.cinematics,
  );

  test(
    'editable projection roundtrips every branch and ordered native action',
    () {
      final decoded = readStudioInteraction(projection.event, manifest)!;
      expect(decoded.project().scene, projection.scene);
      expect(decoded.project().cinematics, projection.cinematics);
      expect(decoded.branches['accept']!.single.targetId, 'accepted');
      expect(decoded.steps.map((step) => step.kind), [
        NarrativeSequenceKind.facing,
        NarrativeSequenceKind.wait,
      ]);
    },
  );

  test('non-boolean condition remains read-only instead of changing type', () {
    final json = projection.event.toJson();
    final definition = Map<String, Object?>.from(json['definition']! as Map);
    definition.remove('conditionExpression');
    definition['conditions'] = [
      NarrativeEventCondition.factValue(
        'count',
        operator: NarrativeFactOperator.equals,
        expectedValue: NarrativeValue.integer(2),
      ).toJson(),
    ];
    final changed = NarrativeEventRecord.fromJson({
      ...json,
      'definition': definition,
    });
    expect(readStudioInteraction(changed, manifest), isNull);
  });

  test('advanced scene additions remain read-only and unchanged', () {
    final scene = projection.scene;
    final advanced = SceneAsset(
      id: scene.id,
      name: scene.name,
      graph: SceneGraph(
        startNodeId: scene.graph.startNodeId,
        nodes: [
          ...scene.graph.nodes,
          SceneNode(
            id: 'advanced',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(
              SceneInteractiveCommand.openShop(shopId: 'existing_shop'),
            ),
          ),
        ],
        edges: scene.graph.edges,
      ),
    );
    final project = manifest.copyWith(scenes: [advanced]);
    expect(readStudioInteraction(projection.event, project), isNull);
    expect(project.scenes.single, advanced);
  });

  test(
    'mismatched event and scene titles are never silently reconstructed',
    () {
      final json = projection.event.toJson();
      final definition = Map<String, Object?>.from(json['definition']! as Map);
      definition['name'] = 'Titre externe';
      final changed = NarrativeEventRecord.fromJson({
        ...json,
        'definition': definition,
      });
      expect(readStudioInteraction(changed, manifest), isNull);
    },
  );
}
