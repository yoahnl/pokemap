import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Scene Finish Game contract V1', () {
    test('round-trips the canonical localized contract', () {
      final consequence = SceneConsequence.finishGame(
        endingId: 'ending_selbrume_saved',
        outcome: SceneGameCompletionOutcome.victory,
        result: SceneFinishGameResult(
          title: SceneLocalizedText(
            fallback: 'Selbrume est sauvée',
            translations: const {
              'en': 'Selbrume is safe',
              'fr': 'Selbrume est sauvée',
            },
          ),
          summary: SceneLocalizedText(
            fallback: 'La brume se retire enfin.',
            translations: const {'en': 'The mist finally clears.'},
          ),
          details: [
            SceneLocalizedText(fallback: 'Le phare brille de nouveau.'),
          ],
        ),
        credits: SceneFinishGameCredits(
          title: SceneLocalizedText(fallback: 'Crédits'),
          author: 'PokeMap',
          endingLabel: SceneLocalizedText(fallback: 'Fin — Selbrume sauvée'),
          contributors: const ['Équipe PokeMap'],
          licenses: const ['Assets de démonstration'],
          skippable: true,
        ),
        postGamePolicy: ScenePostGamePolicy.returnToHub,
        label: 'Terminer le jeu',
      );

      expect(consequence.toJson(), {
        'kind': 'finishGame',
        'contractVersion': 1,
        'endingId': 'ending_selbrume_saved',
        'outcome': 'victory',
        'commitPolicy': 'persistBeforePresentation',
        'result': {
          'title': {
            'fallback': 'Selbrume est sauvée',
            'translations': {
              'en': 'Selbrume is safe',
              'fr': 'Selbrume est sauvée',
            },
          },
          'summary': {
            'fallback': 'La brume se retire enfin.',
            'translations': {'en': 'The mist finally clears.'},
          },
          'details': [
            {'fallback': 'Le phare brille de nouveau.'},
          ],
        },
        'credits': {
          'title': {'fallback': 'Crédits'},
          'author': 'PokeMap',
          'contributors': ['Équipe PokeMap'],
          'licenses': ['Assets de démonstration'],
          'endingLabel': {'fallback': 'Fin — Selbrume sauvée'},
          'skippable': true,
        },
        'postGamePolicy': 'returnToHub',
        'label': 'Terminer le jeu',
      });
      expect(
        SceneConsequence.fromJson(consequence.toJson()),
        equals(consequence),
      );
    });

    test('resolves exact locale, language locale, then fallback', () {
      final text = SceneLocalizedText(
        fallback: 'Fin',
        translations: const {
          'en': 'The End',
          'fr-FR': 'Fin française',
        },
      );

      expect(text.resolve('fr-FR'), 'Fin française');
      expect(text.resolve('en-US'), 'The End');
      expect(text.resolve('de-DE'), 'Fin');
    });

    test('migrates the unversioned flat legacy shape to canonical V1', () {
      final decoded = SceneConsequence.fromJson({
        'kind': 'finishGame',
        'endingId': 'ending_legacy',
        'outcome': 'alternateEnding',
        'resultTitle': 'Une autre fin',
        'resultSummary': 'La route change.',
        'resultDetails': ['Le port reste dans la brume.'],
        'creditsTitle': 'Crédits',
        'creditsAuthor': 'Studio',
        'creditsEndingLabel': 'Fin alternative',
        'creditsSkippable': false,
        'postGamePolicy': 'returnToTitle',
      });

      expect(decoded, isA<SceneFinishGameConsequence>());
      expect(decoded.toJson(), {
        'kind': 'finishGame',
        'contractVersion': 1,
        'endingId': 'ending_legacy',
        'outcome': 'alternateEnding',
        'commitPolicy': 'persistBeforePresentation',
        'result': {
          'title': {'fallback': 'Une autre fin'},
          'summary': {'fallback': 'La route change.'},
          'details': [
            {'fallback': 'Le port reste dans la brume.'},
          ],
        },
        'credits': {
          'title': {'fallback': 'Crédits'},
          'author': 'Studio',
          'endingLabel': {'fallback': 'Fin alternative'},
          'skippable': false,
        },
        'postGamePolicy': 'returnToTitle',
      });
    });

    test('keeps credits optional for the runtime fallback', () {
      final consequence = SceneConsequence.finishGame(
        endingId: 'ending_without_credits',
        outcome: SceneGameCompletionOutcome.completed,
        result: SceneFinishGameResult(
          title: SceneLocalizedText(fallback: 'Fin'),
          summary: SceneLocalizedText(fallback: 'Merci d’avoir joué.'),
        ),
        postGamePolicy: ScenePostGamePolicy.continueGame,
      ) as SceneFinishGameConsequence;

      expect(consequence.credits, isNull);
      expect(consequence.toJson(), isNot(contains('credits')));
    });

    test('rejects unsupported versions and commit ordering', () {
      final base = {
        'kind': 'finishGame',
        'contractVersion': 1,
        'endingId': 'ending',
        'outcome': 'completed',
        'commitPolicy': 'persistBeforePresentation',
        'result': {
          'title': {'fallback': 'Fin'},
          'summary': {'fallback': 'Merci.'},
        },
        'postGamePolicy': 'returnToHub',
      };

      expect(
        () => SceneConsequence.fromJson({...base, 'contractVersion': 2}),
        throwsFormatException,
      );
      expect(
        () => SceneConsequence.fromJson({
          ...base,
          'commitPolicy': 'presentBeforePersist',
        }),
        throwsFormatException,
      );
    });
  });
}
