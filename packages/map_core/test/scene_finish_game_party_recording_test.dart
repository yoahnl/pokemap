import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  SceneFinishGameConsequence completion({bool recordParty = false}) =>
      SceneConsequence.finishGame(
            endingId: 'ending.victory',
            outcome: SceneGameCompletionOutcome.victory,
            result: SceneFinishGameResult(
              title: SceneLocalizedText(fallback: 'Victoire'),
              summary: SceneLocalizedText(fallback: 'Une aventure terminée.'),
            ),
            postGamePolicy: ScenePostGamePolicy.returnToTitle,
            recordParty: recordParty,
          )
          as SceneFinishGameConsequence;

  test(
    'party recording is opt-in and round-trips through the typed contract',
    () {
      expect(completion().recordParty, isFalse);
      final enabled = completion(recordParty: true);
      expect(enabled.toJson()['recordParty'], isTrue);
      expect(SceneConsequence.fromJson(enabled.toJson()), enabled);
      expect(enabled, isNot(completion()));
    },
  );

  test('party recording rejects nonboolean authored values', () {
    for (final invalid in ['true', 1, null, <String, Object?>{}]) {
      expect(
        () => SceneConsequence.fromJson({
          ...completion().toJson(),
          'recordParty': invalid,
        }),
        throwsFormatException,
      );
    }
  });

  test('an unversioned payload cannot silently discard party recording', () {
    expect(
      () => SceneConsequence.fromJson(
        completion(recordParty: true).toJson()..remove('contractVersion'),
      ),
      throwsFormatException,
    );
  });
}
