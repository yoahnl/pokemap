import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('SceneFinishGameRuntimeMapper', () {
    test('maps localized authored data and post-game policy', () {
      final consequence = SceneConsequence.finishGame(
        endingId: 'ending.selbrume',
        outcome: SceneGameCompletionOutcome.alternateEnding,
        result: SceneFinishGameResult(
          title: SceneLocalizedText(
            fallback: 'Fin',
            translations: const {'en': 'Ending'},
          ),
          summary: SceneLocalizedText(
            fallback: 'Selbrume est sauvée.',
            translations: const {'en-US': 'Selbrume is safe.'},
          ),
          details: [
            SceneLocalizedText(
              fallback: 'Merci.',
              translations: const {'en': 'Thank you.'},
            ),
          ],
        ),
        credits: SceneFinishGameCredits(
          title: SceneLocalizedText(
            fallback: 'Crédits',
            translations: const {'en': 'Credits'},
          ),
          author: 'Studio Brume',
          contributors: const ['Alice'],
          licenses: const ['CC-BY'],
          endingLabel: SceneLocalizedText(
            fallback: 'Fin alternative',
            translations: const {'en': 'Alternate ending'},
          ),
          skippable: false,
        ),
        postGamePolicy: ScenePostGamePolicy.returnToHub,
      ) as SceneFinishGameConsequence;

      final request = const SceneFinishGameRuntimeMapper().map(
        consequence: consequence,
        project: _project(),
        locale: 'en-US',
      );

      expect(request.endingId, 'ending.selbrume');
      expect(request.outcome, GameCompletionOutcome.alternateEnding);
      expect(request.result.title, 'Ending');
      expect(request.result.summary, 'Selbrume is safe.');
      expect(request.result.details, ['Thank you.']);
      expect(request.credits.title, 'Credits');
      expect(request.credits.author, 'Studio Brume');
      expect(request.credits.contributors, ['Alice']);
      expect(request.credits.licenses, ['CC-BY']);
      expect(request.credits.endingLabel, 'Alternate ending');
      expect(request.credits.skippable, isFalse);
      expect(request.destination, GameCompletionDestination.hub);
      expect(request.allowPostGameContinue, isFalse);
    });

    test('builds safe project-metadata credits fallback', () {
      final consequence = SceneConsequence.finishGame(
        endingId: 'ending.main',
        outcome: SceneGameCompletionOutcome.completed,
        result: SceneFinishGameResult(
          title: SceneLocalizedText(fallback: 'À suivre'),
          summary: SceneLocalizedText(fallback: 'La quête est terminée.'),
        ),
        postGamePolicy: ScenePostGamePolicy.continueGame,
      ) as SceneFinishGameConsequence;

      final request = const SceneFinishGameRuntimeMapper().map(
        consequence: consequence,
        project: _project(),
        locale: 'fr-FR',
      );

      expect(request.credits.title, 'Selbrume');
      expect(request.credits.author, 'Studio Brume');
      expect(request.credits.endingLabel, 'À suivre');
      expect(request.credits.skippable, isTrue);
      expect(request.destination, GameCompletionDestination.playerChoice);
      expect(request.allowPostGameContinue, isTrue);
    });
  });
}

ProjectManifest _project() => const ProjectManifest(
      name: 'Selbrume',
      maps: [],
      tilesets: [],
      globalProperties: {'author': 'Studio Brume'},
    );
