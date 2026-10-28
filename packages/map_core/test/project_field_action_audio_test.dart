import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('all eleven field actions have distinct configurable cues and keep silence by default', () {
    final cues = <ProjectSoundCue>{};
    for (final action in ProjectFieldAbilityRegistry.entries) {
      final cue = ProjectSoundCueCatalog.forFieldAbilityId(action.id);
      expect(cues.add(cue), isTrue);
      expect(ProjectAudioSettings().bindingFor(cue).source, ProjectSoundSource.silent);
      expect(ProjectSoundCueCatalog.forCue(cue).loop, isFalse);
    }
    expect(cues.length, 11);
    expect(() => ProjectSoundCueCatalog.forFieldAbilityId('unknown'), throwsArgumentError);
  });

  test('extended cues require v2 while old cut bindings retain the same JSON and capability', () {
    final original = {'cues': {'field.cut': {'source': 'silent', 'gain': 1.0}}};
    final audio = ProjectAudioSettings.fromJson(original);
    final old = ProjectManifest(name: 'Old', maps: const [], tilesets: const [], settings: ProjectSettings(audio: audio));
    expect(audio.toJson(), original);
    expect(ProjectAudioCapabilities.requiresExtendedCapability(old), isFalse);
    for (final cue in ProjectAudioCapabilities.extendedCues) {
      final current = old.copyWith(settings: old.settings.copyWith(audio: audio.withCue(cue, const ProjectSoundBinding(source: ProjectSoundSource.silent))));
      expect(ProjectAudioCapabilities.requiresExtendedCapability(current), isTrue);
    }
  });
  test('Rock Smash has a configurable single-shot action sound', () {
    final audio = ProjectAudioSettings.fromJson({'cues': {
      'field.rock_smash': {'source': 'custom', 'mediaId': 'rock-impact', 'gain': .6},
    }});
    final cue = ProjectSoundCue.fromWireName('field.rock_smash');
    expect(audio.bindingFor(cue).mediaId, 'rock-impact');
    expect(ProjectSoundCueCatalog.forCue(cue).loop, isFalse);
    expect(ProjectAudioSettings.fromJson(audio.toJson()), audio);
  });
}
