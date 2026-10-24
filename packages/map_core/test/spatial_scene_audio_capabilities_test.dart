import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('spatial scenes admit owned effects, fanfares and explicit stop', () {
    for (final id in [
      NarrativeCommandIds.playSoundEffect,
      NarrativeCommandIds.playMusicEffect,
      NarrativeCommandIds.stopSoundEffects,
    ]) {
      expect(SpatialGameplayCapabilities.commandIds, contains(id));
    }
  });
}
