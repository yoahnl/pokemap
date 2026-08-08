import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('RuntimeTitleMenuPolicy.singleSave', () {
    test('projects exactly Continue, New Game, and Options in that order', () {
      final projection = const RuntimeTitleMenuPolicy.singleSave().project(
        RuntimePlayerSnapshot(
          revision: 3,
          phase: RuntimePlayerPhase.title,
          gameTitle: 'Le Train de 17h42',
          hasDiscoveredSave: true,
          actions: <RuntimePlayerActionAvailability>[
            const RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.newGame,
            ),
            const RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.showCredits,
            ),
            const RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.continueGame,
            ),
            const RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.openOptions,
            ),
            const RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.load,
            ),
          ],
        ),
      );

      expect(
        projection.actions.map((entry) => entry.action),
        <RuntimePlayerAction>[
          RuntimePlayerAction.continueGame,
          RuntimePlayerAction.newGame,
          RuntimePlayerAction.openOptions,
        ],
      );
      expect(
        projection.initialSelection,
        RuntimePlayerAction.continueGame,
      );
      expect(projection.requiresNewGameConfirmation, isTrue);
    });

    test('preserves unavailable reasons and selects New Game without a save',
        () {
      final projection = const RuntimeTitleMenuPolicy.singleSave().project(
        RuntimePlayerSnapshot(
          revision: 1,
          phase: RuntimePlayerPhase.title,
          gameTitle: 'Le Train de 17h42',
          hasDiscoveredSave: true,
          actions: <RuntimePlayerActionAvailability>[
            RuntimePlayerActionAvailability.disabled(
              RuntimePlayerAction.continueGame,
              reason: 'Aucune sauvegarde compatible.',
            ),
            const RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.newGame,
            ),
            const RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.openOptions,
            ),
          ],
        ),
      );

      expect(projection.actions.first.isEnabled, isFalse);
      expect(
        projection.actions.first.unavailableReason,
        'Aucune sauvegarde compatible.',
      );
      expect(projection.initialSelection, RuntimePlayerAction.newGame);
      expect(projection.requiresNewGameConfirmation, isTrue);
    });

    test('fails closed when the player omitted a public menu action', () {
      final projection = const RuntimeTitleMenuPolicy.singleSave().project(
        RuntimePlayerSnapshot(
          revision: 0,
          phase: RuntimePlayerPhase.title,
          gameTitle: 'Le Train de 17h42',
          actions: <RuntimePlayerActionAvailability>[],
        ),
      );

      expect(projection.actions, hasLength(3));
      expect(projection.actions,
          everyElement(isA<RuntimePlayerActionAvailability>()));
      expect(
          projection.actions,
          everyElement(predicate<RuntimePlayerActionAvailability>(
              (entry) => !entry.isEnabled)));
      expect(projection.initialSelection, isNull);
      expect(projection.requiresNewGameConfirmation, isFalse);
    });
  });
}
