import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('clock and weather modes are typed visual parameters', () {
    final patch = SpatialVisualPatch.fromJson({
      'timeMode': 'real',
      'weatherMode': 'automatic',
      'weatherIntervalSeconds': 600,
      'weatherSequence': ['clear', 'cloudy', 'rain'],
    });
    expect(patch.toJson()['timeMode'], 'real');
    final document = SpatialVisualDocument(profile: patch);
    expect(SpatialVisualDocument.fromJson(document.toJson()).profile, patch);
  });
  test('save state preserves the clock while legacy saves stay unchanged', () {
    final legacy = GameState(saveId: 'old').toJson();
    expect(legacy, isNot(contains('environmentState')));
    final clock = {'schemaVersion': 1, 'elapsedSeconds': 123.5};
    final restored = GameState.fromJson({...legacy, 'environmentState': clock});
    expect(restored.toJson()['environmentState'], clock);
  });
  test(
    'world environment schema cannot be hidden in legacy visual documents',
    () {
      final patch = SpatialVisualPatch.fromJson({
        'timeMode': 'real',
        'weatherSequence': ['clear', 'rain'],
      });
      final doc = SpatialVisualDocument(profile: patch);
      expect(doc.toJson()['schemaVersion'], 5);
      for (final version in [1, 2, 3, 4]) {
        expect(
          () => SpatialVisualDocument.fromJson({
            ...doc.toJson(),
            'schemaVersion': version,
          }),
          throwsFormatException,
        );
      }
      expect(patch.requiresWeatherSound, isFalse);
      expect(patch.requiresWorldEnvironment, isTrue);
      expect(patch, SpatialVisualPatch.fromJson(patch.toJson()));
      expect(
        patch.hashCode,
        SpatialVisualPatch.fromJson(patch.toJson()).hashCode,
      );
    },
  );
  test('invalid modes, sequences and future saved states are refused', () {
    for (final patch in [
      {'timeMode': 'future'},
      {'weatherMode': 'internet'},
      {'weatherSequence': []},
      {
        'weatherSequence': ['rain', 'rain'],
      },
      {
        'weatherSequence': ['unknown'],
      },
      {'weatherIntervalSeconds': 0},
    ]) {
      expect(() => SpatialVisualPatch.fromJson(patch), throwsFormatException);
    }
    for (final state in [
      {'schemaVersion': 2, 'elapsedSeconds': 10},
      {'schemaVersion': 1, 'elapsedSeconds': -1},
      {'schemaVersion': 1, 'elapsedSeconds': double.infinity},
    ]) {
      expect(
        () => WorldEnvironmentState.fromJson(state),
        throwsFormatException,
      );
    }
  });
  test('both supported save bridges retain the optional environment state', () {
    final state = GameState(
      saveId: 'save',
      environmentState: WorldEnvironmentState(elapsedSeconds: 83),
    );
    expect(
      gameStateFromStrictSaveJson(
        strictGameStateSaveJson(state),
      ).environmentState,
      state.environmentState,
    );
    expect(
      gameStateFromSaveData(saveDataFromGameState(state)).environmentState,
      state.environmentState,
    );
    expect(
      SaveData(saveId: 'legacy').toJson(),
      isNot(contains('environmentState')),
    );
  });
}
