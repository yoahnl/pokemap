import 'package:avelune_studio/features/characters/coordination/character_studio_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  const project = ProjectManifest(
    name: 'Test',
    maps: [],
    tilesets: [],
    characters: [
      ProjectCharacterEntry(
        id: 'hero',
        name: 'Héroïne',
        tilesetId: 'sheet',
        frameWidth: 1,
        frameHeight: 1,
      ),
    ],
  );

  test(
    'climbing and every Surf pose remain selectable without mutating a draft',
    () {
      final controller = CharacterStudioController(
        project: () => project,
        mutate: (_, _) async => project,
      );
      addTearDown(controller.dispose);
      for (final state in [
        CharacterAnimationState.climb,
        CharacterAnimationState.surfIdle,
        CharacterAnimationState.surf,
        CharacterAnimationState.surfEnter,
        CharacterAnimationState.surfExit,
      ]) {
        controller.setAnimationState(state);
        expect(controller.animationState, state);
        expect(controller.selectedDraft!.dirty, isFalse);
      }
    },
  );
}
