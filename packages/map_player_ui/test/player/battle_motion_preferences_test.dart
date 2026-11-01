import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('legacy preference bytes remain unchanged after an unrelated edit', () {
    final legacy = const PlayerPreferences(reducedMotion: true).toJson();
    final loaded = PlayerPreferences.fromJson(legacy);
    final edited = loaded.copyWith(musicVolume: .3).toJson();
    expect(edited.containsKey('battleMotion'), isFalse);
    expect(edited['reducedMotion'], isTrue);
  });

  test('independent battle settings survive persistence and runtime transport', () {
    final json = const PlayerPreferences(
      language: PlayerLanguage.fr, reducedMotion: true).toJson()
      ..['battleMotion'] = <String, Object?>{
        'playbackSpeed': 2.5,
        'reducedMotion': false,
        'effectIntensity': .35,
      };
    final loaded = PlayerPreferences.fromJson(json);
    final snapshot = loaded.toRuntimeSnapshot(fallbackLocale: 'fr');
    final transported = RuntimeCompanionPresentationCodec
        .decodePlayerPreferencesSnapshot(RuntimeCompanionPresentationCodec
            .encodePlayerPreferencesSnapshot(snapshot));
    final reopened = const PlayerPreferences()
        .copyWithRuntimeSnapshot(transported);
    expect(reopened.toJson()['battleMotion'], json['battleMotion']);
    expect(reopened.reducedMotion, isTrue);
    expect(reopened, loaded);
    expect(reopened.hashCode, loaded.hashCode);
  });

  test('invalid battle settings are rejected without silently resetting', () {
    for (final raw in <Object?>[
      null, 'fast', <String, Object?>{},
      {'playbackSpeed': 0, 'reducedMotion': false, 'effectIntensity': 1},
      {'playbackSpeed': 1, 'reducedMotion': 'yes', 'effectIntensity': 1},
      {'playbackSpeed': 1, 'reducedMotion': false, 'effectIntensity': 2},
      {'playbackSpeed': 1, 'reducedMotion': false, 'effectIntensity': 1,
        'unknown': true},
    ]) {
      expect(() => PlayerPreferences.fromJson(
        const PlayerPreferences().toJson()..['battleMotion'] = raw),
        throwsFormatException);
    }
  });
}
