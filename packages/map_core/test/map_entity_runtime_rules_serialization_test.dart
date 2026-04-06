import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Règles runtime PNJ (JSON)', () {
    test('roundtrip visibilité + variantes dialogue + completedCutsceneIds', () {
      final npc = MapEntityNpcData(
        dialogue: const DialogueRef(dialogueId: 'intro'),
        visibilityRule: const MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.visibleWhen,
          predicate: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.storyFlagSet,
            refId: 'met_emma',
          ),
        ),
        conditionalDialogues: [
          MapEntityConditionalDialogue(
            when: const MapEntityRuntimePredicate(
              kind: MapEntityRuntimePredicateKind.stepCompleted,
              refId: 'starter_choice',
            ),
            dialogue: const DialogueRef(dialogueId: 'after_starter'),
          ),
        ],
      );

      final entity = MapEntity(
        id: 'npc1',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 1, y: 1),
        npc: npc,
      );

      final json = entity.toJson();
      final roundtrip = MapEntity.fromJson(json);
      final n = roundtrip.npc!;

      expect(n.visibilityRule?.mode, MapEntityNpcVisibilityMode.visibleWhen);
      expect(
        n.visibilityRule?.predicate?.kind,
        MapEntityRuntimePredicateKind.storyFlagSet,
      );
      expect(n.visibilityRule?.predicate?.refId, 'met_emma');
      expect(n.conditionalDialogues, hasLength(1));
      expect(
        n.conditionalDialogues.single.when.kind,
        MapEntityRuntimePredicateKind.stepCompleted,
      );
      expect(n.conditionalDialogues.single.dialogue.dialogueId, 'after_starter');
      expect(n.dialogue?.dialogueId, 'intro');
    });

    test('PlayerProgression sérialise completedCutsceneIds', () {
      const p = PlayerProgression(
        completedCutsceneIds: ['cut_a', 'cut_b'],
      );
      final json = p.toJson();
      final back = PlayerProgression.fromJson(json);
      expect(back.completedCutsceneIds, ['cut_a', 'cut_b']);
    });
  });
}
