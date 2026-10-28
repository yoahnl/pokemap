import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import 'support/cs_audio_package_fixture.dart';

void main() {
  for (final dimension in ProjectDimension.values) {
    test('$dimension new action sound requires explicit extended capability', () {
      final files = csAudioPayload(dimension, audio: ProjectAudioSettings.fromJson({
        'cues': {'field.rock_smash': {'source': 'silent', 'gain': 1}},
      }));
      expect(() => const GamePackageBuilder().build(
        manifest: csAudioManifest(dimension, const ['audio.project-sfx@1']),
        payloadFiles: files,
      ), throwsA(isA<GamePackageFormatException>().having((error) => error.message, 'missing capability', contains('audio.project-sfx@2'))));
      final artifact = const GamePackageBuilder().build(
        manifest: csAudioManifest(dimension, const ['audio.project-sfx@1', 'audio.project-sfx@2']),
        payloadFiles: files,
      );
      expect(const GamePackageInspector().inspect(artifact.packageBytes).manifest.compatibility.requiredCapabilities,
          contains('audio.project-sfx@2'));
    });
  }
}
