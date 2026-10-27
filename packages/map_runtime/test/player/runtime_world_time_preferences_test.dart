import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart' show WorldEnvironmentClock;
import 'package:map_runtime/map_runtime.dart';

void main() {
  const chosen = RuntimeWorldTimePreferences(chosenMinuteOfDay: 750);

  test('real time is the default and keeps the device clock untouched', () {
    final now = DateTime(2026, 10, 28, 23, 41, 7, 250);
    expect(const RuntimeWorldTimePreferences().toJson(), isEmpty);
    expect(const RuntimeWorldTimePreferences().worldTime(now), now);
    expect(const RuntimeWorldTimePreferences().visualOverrides.isEmpty, isTrue);
  });

  test('a chosen hour keeps the date and replaces only the time of day', () {
    expect(
      chosen.worldTime(DateTime(2026, 10, 28, 23, 41, 7, 250)),
      DateTime(2026, 10, 28, 12, 30),
    );
    final utc = chosen.worldTime(DateTime.utc(2026, 10, 28, 3));
    expect(utc.isUtc, isTrue);
    expect((utc.hour, utc.minute), (12, 30));
  });

  test('persisted world time round-trips and rejects invalid data', () {
    expect(RuntimeWorldTimePreferences.fromJson(chosen.toJson()), chosen);
    expect(
      RuntimeWorldTimePreferences.fromJson(const {}),
      const RuntimeWorldTimePreferences(),
    );
    for (final invalid in <Map<String, Object?>>[
      {'chosenMinuteOfDay': 1440},
      {'chosenMinuteOfDay': -1},
      {'chosenMinuteOfDay': '720'},
      {'chosenMinuteOfDay': 720, 'other': true},
    ]) {
      expect(
        () => RuntimeWorldTimePreferences.fromJson(invalid),
        throwsFormatException,
        reason: '$invalid',
      );
    }
  });

  test('the companion codec transports the chosen hour', () {
    const snapshot = PlayerPreferencesSnapshot(
      locale: 'fr',
      accessibility: GameSessionAccessibilityOptions(),
    );
    PlayerPreferencesSnapshot transport(PlayerPreferencesSnapshot value) =>
        RuntimeCompanionPresentationCodec.decodePlayerPreferencesSnapshot(
          Map<String, dynamic>.from(
            RuntimeCompanionPresentationCodec.encodePlayerPreferencesSnapshot(
              value,
            ),
          ),
        );
    expect(
      RuntimeCompanionPresentationCodec.encodePlayerPreferencesSnapshot(
        snapshot,
      ),
      isNot(contains('worldTime')),
    );
    expect(transport(snapshot).worldTime, const RuntimeWorldTimePreferences());
    expect(transport(snapshot.copyWith(worldTime: chosen)).worldTime, chosen);
  });

  for (final authored in <String, Map<String, dynamic>>{
    'real time': {'timeMode': 'real'},
    'an accelerated cycle': {
      'timeMode': 'cycle',
      'dayDurationSeconds': 600,
      'minuteOfDay': 360,
    },
    'a scene day cycle': {'dayNightEnabled': true, 'minuteOfDay': 360},
  }.entries) {
    test('the chosen hour drives world environments authored with '
        '${authored.key}', () {
      final profile = SpatialVisualPatch.fromJson(authored.value);
      expect(RuntimeWorldTimePreferences.hasWorldClock(profile), isTrue);
      final overrides = chosen.visualOverrides;
      final frame = WorldEnvironmentClock(
        now: () => DateTime(2026, 10, 28, 23, 41),
      ).resolve(profile.overriddenBy(overrides), overrides: overrides);
      expect(frame.minuteOfDay, 750);
      expect(
        profile
            .overriddenBy(overrides)
            .applyCycle(
              SpatialDayNightCycle(durationSeconds: 600, startMinuteOfDay: 360),
            ),
        isNull,
      );
    });
  }

  test('story overrides keep priority over the chosen hour', () {
    final profile = SpatialVisualPatch.fromJson({'timeMode': 'real'});
    final overrides = chosen.visualOverrides.overriddenBy(
      SpatialVisualPatch.fromJson({'minuteOfDay': 1320}),
    );
    final frame = WorldEnvironmentClock(now: () => DateTime(2026, 10, 28, 9))
        .resolve(profile.overriddenBy(overrides), overrides: overrides);
    expect(frame.minuteOfDay, 1320);
  });

  test('games without a world clock are left untouched', () {
    expect(
      RuntimeWorldTimePreferences.hasWorldClock(
        SpatialVisualPatch.fromJson({'dayNightEnabled': false}),
      ),
      isFalse,
    );
    expect(
      RuntimeWorldTimePreferences.hasWorldClock(SpatialVisualPatch()),
      isFalse,
    );
  });
}
