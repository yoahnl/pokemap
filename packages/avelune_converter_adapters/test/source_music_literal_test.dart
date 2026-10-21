import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_converter_adapters/src/source_event_sound_binding.dart';
import 'package:test/test.dart';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/source_map_music_fixture.dart';

Future<LiteralTileFixture> _fixture(
        {Object? volume = 100,
        Object? pitch = 100,
        bool night = false,
        bool duplicate = false}) =>
    LiteralTileFixture.create(
        interpretationProfile: syntheticSourceInterpretationProfile,
        scriptsBytes: syntheticInterpretationArchive,
        includeEventSystem: true,
        extraFiles: {
          'Audio/BGM/Theme.wav': sourceMapMusicFixtureWav(),
          if (night) 'Audio/BGM/Theme_n.wav': sourceMapMusicFixtureWav(),
          if (duplicate) 'Audio/BGM/Theme.ogg': sourceMapMusicFixtureWav(),
        },
        maps: [
          LiteralFixtureMap(id: 1, events: [
            LiteralFixtureEvent(id: 1, x: 1, y: 0, pages: [
              LiteralFixtureEventPage(commands: [
                LiteralFixtureEventCommand(241, [
                  LiteralFixtureObject('RPG::AudioFile',
                      {'@name': 'Theme', '@volume': volume, '@pitch': pitch})
                ])
              ])
            ])
          ])
        ]);

void main() {
  test(
      'literal music keeps attested values and imports typed looping native music',
      () async {
    final f = await _fixture(volume: 75);
    final a = SourceEventAnalyzer.forProject(f.source,
            profile: SourceEventProfile.forProject(f.source))
        .analyze();
    expect(a.events.single.isQuarantined, isFalse);
    final music =
        a.events.single.pages.single.body.nodes.single as SourceMusicNode;
    expect(music.name, 'Theme');
    expect(music.volume, 75);
    expect(music.pitch, 100);
    expect(music.rawDataRef.toJson(), isNotEmpty);
    final binding = await const SourceEventSoundResolver().read(
        source: f.source,
        files: f.files,
        name: music.name,
        kind: SourceEventAudioKind.music,
        policy: SourceEventSoundPolicy.nativeAuthoredVolume);
    expect(binding.kind, SourceEventAudioKind.music);
    expect(binding.audioFile.relativePath, 'Audio/BGM/Theme.wav');
    expect(binding.gainForVolume(75), .75);
    expect(binding.mutation.parameters['mediaKind'], 'music');
    expect(binding.artifact.bytes, sourceMapMusicFixtureWav());
  });
  for (final value in <Object?>[-1, 101, '100', null]) {
    test('music refuses nonliteral or out-of-range authored volume $value',
        () async {
      final f = await _fixture(volume: value);
      final a = SourceEventAnalyzer.forProject(f.source,
              profile: SourceEventProfile.forProject(f.source))
          .analyze();
      expect(a.events.single.isQuarantined, isTrue);
    });
  }
  for (final duplicate in [false, true]) {
    test('music refuses ${duplicate ? 'ambiguous audio' : 'night variants'}',
        () async {
      final f = await _fixture(duplicate: duplicate, night: !duplicate);
      await expectLater(
          const SourceEventSoundResolver().read(
              source: f.source,
              files: f.files,
              name: 'Theme',
              kind: SourceEventAudioKind.music,
              policy: SourceEventSoundPolicy.nativeAuthoredVolume),
          throwsA(isA<SourceEventSoundBindingUnavailable>().having(
              (e) => e.reason,
              'reason',
              duplicate ? 'audio_ambiguous' : 'night_variant_unsupported')));
    });
  }
}
