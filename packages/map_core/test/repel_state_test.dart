import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'repel state survives both save transports and preserves pending renewal',
    () {
      final state = GameState(
        saveId: 'repel',
        repelState: RepelState.active(itemId: 'repel', steps: 2),
      );
      final first = state.repelState.advance(1);
      expect(first.remainingSteps, 1);
      final expired = first.advance(1);
      expect(expired.remainingSteps, 0);
      expect(expired.expirationPending, isTrue);
      expect(expired.advance(3), expired);
      final saved = saveDataFromGameState(state.copyWith(repelState: expired));
      expect(
        gameStateFromSaveData(SaveData.fromJson(saved.toJson())).repelState,
        expired,
      );
      expect(
        gameStateFromStrictSaveJson(strictGameStateSaveJson(state)).repelState,
        state.repelState,
      );
    },
  );
  test('repel state rejects malformed and contradictory persisted values', () {
    for (final value in [-1, 1.5, '2', null]) {
      expect(
        () => RepelState.fromJson({
          'remainingSteps': value,
          'itemId': 'repel',
          'expirationPending': false,
        }),
        throwsFormatException,
      );
    }
    expect(
      () => RepelState.fromJson({
        'remainingSteps': 2,
        'itemId': '',
        'expirationPending': false,
      }),
      throwsFormatException,
    );
    expect(
      () => RepelState.fromJson({
        'remainingSteps': 2,
        'itemId': 'repel',
        'expirationPending': true,
      }),
      throwsFormatException,
    );
  });
}
