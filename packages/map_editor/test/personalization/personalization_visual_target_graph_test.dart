import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/personalization_hub.dart';

void main() {
  test('declares stable unique targets for every studio scene', () {
    final graph = PersonalizationVisualTargetGraph.standard();

    for (final scene in PersonalizationStudioScene.values) {
      final targets = graph.targetsFor(scene);
      expect(targets, isNotEmpty, reason: scene.name);
      expect(
        targets.map((target) => target.id).toSet(),
        hasLength(targets.length),
        reason: scene.name,
      );
      expect(
        targets.every((target) => target.scene == scene),
        isTrue,
        reason: scene.name,
      );
    }
  });

  test('prefers the most specific overlapping visual target', () {
    final graph = PersonalizationVisualTargetGraph.standard();

    expect(
      graph
          .hitTest(
            scene: PersonalizationStudioScene.dialogue,
            normalizedPosition: const Offset(.5, .82),
          )
          ?.target,
      isA<DialogueTypographyTarget>(),
    );
    expect(
      graph
          .hitTest(
            scene: PersonalizationStudioScene.dialogue,
            normalizedPosition: const Offset(.08, .78),
          )
          ?.target,
      isA<DialogueAppearanceTarget>(),
    );
  });

  test('leaves declared non editable stage zones untargeted', () {
    final graph = PersonalizationVisualTargetGraph.standard();

    expect(
      graph.hitTest(
        scene: PersonalizationStudioScene.battle,
        normalizedPosition: const Offset(.5, .45),
      ),
      isNull,
    );
    expect(
      graph
          .hitTest(
            scene: PersonalizationStudioScene.intro,
            normalizedPosition: const Offset(.5, .5),
          )
          ?.target,
      isA<IntroPresentationTarget>(),
    );
  });

  test(
    'resolves overlapping battle controls from the visible battle state',
    () {
      final graph = PersonalizationVisualTargetGraph.standard();

      expect(
        graph
            .hitTest(
              scene: PersonalizationStudioScene.battle,
              normalizedPosition: const Offset(.5, .84),
              preferredTargetId: 'battleMoves',
            )
            ?.target,
        isA<BattleMovesTarget>(),
      );
      expect(
        graph
            .hitTest(
              scene: PersonalizationStudioScene.battle,
              normalizedPosition: const Offset(.5, .84),
              preferredTargetId: 'battleMessage',
            )
            ?.target,
        isA<BattleMessageTarget>(),
      );
    },
  );
}
