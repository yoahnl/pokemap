import 'package:map_core/src/models/project_audio_settings.dart';
import 'package:test/test.dart';

void main() {
  test('round trips stable cue bindings and gains', () {
    final value = ProjectAudioSettings.fromJson({
      'cues': {
        'ui.confirm': {'source': 'custom', 'mediaId': 'confirm', 'gain': .7},
        'overworld.step': {'source': 'silent', 'gain': 1},
        'weather.rain': {'source': 'builtin', 'gain': .4},
      },
    });
    expect(value.cues[ProjectSoundCue.uiConfirm]!.mediaId, 'confirm');
    expect(value, ProjectAudioSettings.fromJson(value.toJson()));
    expect(value.toJson()['cues'], contains('weather.rain'));
    expect(() => value.cues.clear(), throwsUnsupportedError);
  });
  test('rejects malformed sources references gains and unknown cues', () {
    for (final binding in [
      {'source': 'custom'},
      {'source': 'builtin', 'mediaId': 'unexpected'},
      {'source': 'silent', 'mediaId': 'unexpected'},
      {'source': 'future'},
      {'source': 'builtin', 'gain': null},
      {'source': 'builtin', 'gain': -1},
      {'source': 'builtin', 'gain': double.nan},
      {'source': 'builtin', 'gain': 2},
      {'source': 'custom', 'mediaId': '../file'},
      {'source': 'custom', 'mediaId': 'not:catalog'},
      {'source': 'custom', 'mediaId': 'valid', 'path': '/outside'},
    ]) {
      expect(
        () => ProjectSoundBinding.fromJson(binding),
        throwsFormatException,
      );
    }
    expect(
      () => ProjectAudioSettings.fromJson({'cues': null}),
      throwsFormatException,
    );
    expect(
      () => ProjectAudioSettings.fromJson({
        'cues': {
          'future': {'source': 'silent'},
        },
      }),
      throwsFormatException,
    );
  });
  test(
    'keeps legacy defaults and declares loops independently from authoring',
    () {
      final value = ProjectAudioSettings();
      expect(
        value.bindingFor(ProjectSoundCue.uiConfirm).source,
        ProjectSoundSource.silent,
      );
      expect(
        value.bindingFor(ProjectSoundCue.overworldJump).source,
        ProjectSoundSource.builtin,
      );
      expect(
        value.bindingFor(ProjectSoundCue.fieldCut).source,
        ProjectSoundSource.silent,
      );
      expect(
        ProjectSoundCueCatalog.forCue(ProjectSoundCue.weatherRain).loop,
        isTrue,
      );
      expect(
        ProjectSoundCueCatalog.forCue(ProjectSoundCue.surfEnter).loop,
        isFalse,
      );
      expect(
        ProjectSoundCueCatalog.entries.map((value) => value.cue).toSet(),
        ProjectSoundCue.values.toSet(),
      );
    },
  );
}
