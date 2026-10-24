import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('typed party readiness and refusal survive NPC JSON', () {
    final npc = MapEntityNpcData.fromJson({
      'trainerId': 'pair',
      'trainerBattleReadyWhen': {
        'kind': 'partyUsableCountAtLeast',
        'minimumCount': 2,
      },
      'trainerBattleNotReadyDialogue': {'dialogueId': 'need_two'},
    });
    expect(npc.toJson()['trainerBattleReadyWhen'], {
      'kind': 'partyUsableCountAtLeast',
      'refId': '',
      'minimumCount': 2,
    });
    expect(
      npc.toJson()['trainerBattleNotReadyDialogue'],
      containsPair('dialogueId', 'need_two'),
    );
    expect(MapEntityNpcData.fromJson(npc.toJson()), npc);
  });
  test(
    'party threshold rejects missing, out of range and incompatible fields',
    () {
      for (final value in [null, 0, 7, -1, 1.5, '2']) {
        expect(
          () => MapEntityRuntimePredicate.fromJson({
            'kind': 'partyUsableCountAtLeast',
            'minimumCount': value,
          }),
          throwsA(isA<FormatException>()),
        );
      }
      expect(
        () => MapEntityRuntimePredicate.fromJson({
          'kind': 'storyFlagSet',
          'refId': 'flag',
          'minimumCount': 2,
        }),
        throwsA(isA<FormatException>()),
      );
    },
  );
  test(
    'refusal requires a trainer and readiness and is a dialogue dependency',
    () {
      const condition = MapEntityRuntimePredicate(
        kind: MapEntityRuntimePredicateKind.partyUsableCountAtLeast,
        minimumCount: 2,
      );
      MapEntity entity(MapEntityNpcData npc) => MapEntity(
        id: 'pair',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 0, y: 0),
        npc: npc,
      );
      for (final npc in [
        const MapEntityNpcData(trainerBattleReadyWhen: condition),
        const MapEntityNpcData(
          trainerId: 'pair',
          trainerBattleNotReadyDialogue: DialogueRef(dialogueId: 'refusal'),
        ),
      ]) {
        expect(
          () => assertValidMapEntityTypedPayloads(entity(npc)),
          throwsA(isA<ValidationException>()),
        );
      }
      final npc = const MapEntityNpcData(
        trainerId: 'pair',
        trainerBattleReadyWhen: condition,
        trainerBattleNotReadyDialogue: DialogueRef(dialogueId: 'refusal'),
      );
      expect(
        () => assertEntityDialogueRefsAgainstProject(
          entity(npc),
          const ProjectManifest(name: 'Refs', maps: [], tilesets: []),
        ),
        throwsA(isA<ValidationException>()),
      );
    },
  );
}
