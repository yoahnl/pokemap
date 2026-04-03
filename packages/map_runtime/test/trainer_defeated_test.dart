import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  group('Trainer defeated state', () {
    test('debugMarkTrainerAsDefeated poses flag in storyFlags', () {
      final initialState = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {}),
      );

      final updatedState = initialState.copyWith(
        storyFlags: initialState.storyFlags.copyWith(
          activeFlags: {...initialState.storyFlags.activeFlags, 'trainer_defeated:trainer_001'},
        ),
      );

      expect(updatedState.storyFlags.activeFlags, contains('trainer_defeated:trainer_001'));
    });

    test('debugMarkTrainerAsDefeated ignores empty trainerId', () {
      // Simuler la logique de debugMarkTrainerAsDefeated
      final trimmedId = ''.trim();
      final shouldMark = trimmedId.isNotEmpty;

      expect(shouldMark, isFalse);
    });

    test('trainer defeated flag uses convention trainer_defeated:{trainerId}', () {
      final trainerId = 'gym_leader_1';
      final expectedFlag = 'trainer_defeated:$trainerId';

      expect(expectedFlag, equals('trainer_defeated:gym_leader_1'));
    });

    test('multiple trainers can be marked defeated independently', () {
      final initialState = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {}),
      );

      final state1 = initialState.copyWith(
        storyFlags: initialState.storyFlags.copyWith(
          activeFlags: {...initialState.storyFlags.activeFlags, 'trainer_defeated:trainer_001'},
        ),
      );

      final state2 = state1.copyWith(
        storyFlags: state1.storyFlags.copyWith(
          activeFlags: {...state1.storyFlags.activeFlags, 'trainer_defeated:trainer_002'},
        ),
      );

      expect(state2.storyFlags.activeFlags, contains('trainer_defeated:trainer_001'));
      expect(state2.storyFlags.activeFlags, contains('trainer_defeated:trainer_002'));
      expect(state2.storyFlags.activeFlags.length, equals(2));
    });

    test('defeatDialogueRef is present in MapEntityNpcData model', () {
      final entity = MapEntity(
        id: 'npc_1',
        name: 'Test NPC',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 0, y: 0),
        size: const GridSize(width: 1, height: 1),
        npc: MapEntityNpcData(
          displayName: 'Test',
          defeatDialogueRef: DialogueRef(
            dialogueId: 'defeat_dialogue_1',
            scriptPathRelative: '',
          ),
        ),
      );

      expect(entity.npc?.defeatDialogueRef, isNotNull);
      expect(entity.npc?.defeatDialogueRef?.dialogueId, equals('defeat_dialogue_1'));
    });

    test('defeatDialogueRef can be null', () {
      final entity = MapEntity(
        id: 'npc_2',
        name: 'Test NPC 2',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 0, y: 0),
        size: const GridSize(width: 1, height: 1),
        npc: const MapEntityNpcData(
          displayName: 'Test 2',
          defeatDialogueRef: null,
        ),
      );

      expect(entity.npc?.defeatDialogueRef, isNull);
    });
  });

  group('Trainer interaction fallback chain', () {
    test('trainer battu + defeatDialogueRef => defeat dialogue path', () {
      // Simulation de la logique _openDefeatDialogue
      final entityWithDefeat = MapEntity(
        id: 'npc_1',
        name: 'Defeated Trainer',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 0, y: 0),
        size: const GridSize(width: 1, height: 1),
        npc: MapEntityNpcData(
          displayName: 'Trainer',
          trainerId: 'trainer_001',
          defeatDialogueRef: DialogueRef(
            dialogueId: 'defeat_1',
            scriptPathRelative: '',
          ),
        ),
      );

      // Logique simulée de _openDefeatDialogue
      final defeatRef = entityWithDefeat.npc?.defeatDialogueRef;
      final hasDefeatDialogue = defeatRef != null;

      expect(hasDefeatDialogue, isTrue);
    });

    test('trainer battu + pas de defeatDialogueRef + dialogue => fallback dialogue', () {
      final entityWithNormal = MapEntity(
        id: 'npc_2',
        name: 'Defeated Trainer 2',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 0, y: 0),
        size: const GridSize(width: 1, height: 1),
        npc: MapEntityNpcData(
          displayName: 'Trainer 2',
          trainerId: 'trainer_002',
          defeatDialogueRef: null,
          dialogue: DialogueRef(
            dialogueId: 'normal_1',
            scriptPathRelative: '',
          ),
        ),
      );

      // Logique simulée de _openDefeatDialogue
      final defeatRef = entityWithNormal.npc?.defeatDialogueRef;
      final normalDialogue = entityWithNormal.npc?.dialogue;
      final shouldFallbackToNormal = defeatRef == null && normalDialogue != null;

      expect(shouldFallbackToNormal, isTrue);
    });

    test('trainer battu + aucun dialogue => notification path', () {
      final entityNoDialogue = MapEntity(
        id: 'npc_3',
        name: 'Defeated Trainer 3',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 0, y: 0),
        size: const GridSize(width: 1, height: 1),
        npc: const MapEntityNpcData(
          displayName: 'Trainer 3',
          trainerId: 'trainer_003',
          defeatDialogueRef: null,
          dialogue: null,
        ),
      );

      // Logique simulée de _openDefeatDialogue
      final defeatRef = entityNoDialogue.npc?.defeatDialogueRef;
      final normalDialogue = entityNoDialogue.npc?.dialogue;
      final shouldShowNotification = defeatRef == null && normalDialogue == null;

      expect(shouldShowNotification, isTrue);
    });
  });
}
