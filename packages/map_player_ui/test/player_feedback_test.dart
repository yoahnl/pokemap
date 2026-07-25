import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  test('feedback respects volumes, haptics and event deduplication', () async {
    final port = _RecordingFeedbackPort();
    final controller = PlayerFeedbackController(port: port);
    const event = PlayerFeedbackEvent(
      id: 'battle:12',
      sound: PlayerFeedbackSound.victory,
      haptic: PlayerFeedbackHaptic.success,
    );
    const preferences = PlayerPreferences(
      masterVolume: 0.5,
      effectsVolume: 0.4,
    );

    await controller.handle(event, preferences);
    await controller.handle(event, preferences);

    expect(port.sounds, <(PlayerFeedbackSound, double)>[
      (PlayerFeedbackSound.victory, 0.2),
    ]);
    expect(port.haptics, <PlayerFeedbackHaptic>[
      PlayerFeedbackHaptic.success,
    ]);
  });

  test('bounded preloader deduplicates and caps requested assets', () async {
    final loaded = <String>[];
    final preloader = PlayerAssetPreloader(
      load: (path) async => loaded.add(path),
      maxCachedAssets: 2,
    );

    await preloader.preload(<String>['a.png', 'a.png', 'b.png', 'c.png']);
    await preloader.preload(<String>['a.png', 'b.png']);

    expect(loaded, <String>['a.png', 'b.png', 'c.png', 'a.png', 'b.png']);
  });
}

final class _RecordingFeedbackPort implements PlayerFeedbackPort {
  final sounds = <(PlayerFeedbackSound, double)>[];
  final haptics = <PlayerFeedbackHaptic>[];

  @override
  Future<void> playSound(PlayerFeedbackSound sound, double volume) async {
    sounds.add((sound, volume));
  }

  @override
  Future<void> performHaptic(PlayerFeedbackHaptic haptic) async {
    haptics.add(haptic);
  }
}
