import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_converter_adapters/src/source_event_sound_binding.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/source_map_music_fixture.dart';

Future<LiteralTileFixture> _fixture({
  String name = 'Reward',
  bool duplicate = false,
  bool missing = false,
  int code = 249,
  Object? volume = 100,
  Object? pitch = 100,
  bool extraField = false,
}) => LiteralTileFixture.create(
  interpretationProfile: syntheticSourceInterpretationProfile,
  scriptsBytes: syntheticInterpretationArchive,
  includeEventSystem: true,
  extraFiles: {
    if (!missing) 'Audio/ME/$name.wav': sourceMapMusicFixtureWav(),
    if (duplicate) 'Audio/ME/$name.ogg': sourceMapMusicFixtureWav(),
    'Audio/SE/$name.wav': sourceMapMusicFixtureWav(),
  },
  maps: [LiteralFixtureMap(id: 1, events: [
    LiteralFixtureEvent(id: 1, x: 1, y: 0, pages: [
      LiteralFixtureEventPage(commands: [
        LiteralFixtureEventCommand(code, [LiteralFixtureObject('RPG::AudioFile', {
          '@name': name, '@volume': volume, '@pitch': pitch,
          if (extraField) '@plugin': true,
        })]),
      ]),
    ]),
  ])],
);

void main() {
  test('opcode249 preserves literal ME role span and source attestation', () async {
    final f = await _fixture(volume: 75);
    final analysis = SourceEventAnalyzer.forProject(f.source,
      profile: SourceEventProfile.forProject(f.source)).analyze();
    final event = analysis.events.single;
    expect(event.isQuarantined, isFalse);
    final node = event.pages.single.body.nodes.single;
    expect(node, isA<SourceMusicEffectNode>());
    final value = (node as SourceMusicEffectNode).toJson();
    expect(value['kind'], 'musicEffect');
    expect(value['name'], 'Reward');
    expect(value['volume'], 75);
    expect(value['pitch'], 100);
    expect(value['waitForCompletion'], isFalse);
    expect(value['rawDataRef'], isNotEmpty);
    expect(value['profileHash'], analysis.profile.canonicalHash.value);
    expect(value['span'], node.span.toJson());
  });

  test('opcode250 remains a distinct source sound command', () async {
    final f = await _fixture(code: 250);
    final analysis = SourceEventAnalyzer.forProject(f.source,
      profile: SourceEventProfile.forProject(f.source)).analyze();
    expect(analysis.events.single.pages.single.body.nodes.single, isA<SourceSoundEffectNode>());
  });

  for (final value in <Object?>[-1, 101, '100', null]) {
    test('opcode249 refuses invalid authored volume $value', () async {
      final f = await _fixture(volume: value);
      final analysis = SourceEventAnalyzer.forProject(f.source,
        profile: SourceEventProfile.forProject(f.source)).analyze();
      expect(analysis.events.single.isQuarantined, isTrue);
    });
  }
  for (final value in <Object?>[50, 99, 101, 150, '100', null]) {
    test('opcode249 refuses unattested pitch $value', () async {
      final f = await _fixture(pitch: value);
      final analysis = SourceEventAnalyzer.forProject(f.source,
        profile: SourceEventProfile.forProject(f.source)).analyze();
      expect(analysis.events.single.isQuarantined, isTrue);
    });
  }
  test('opcode249 refuses empty ME stop semantics and extended audio objects', () async {
    for (final f in [await _fixture(name: ''), await _fixture(extraField: true)]) {
      final analysis = SourceEventAnalyzer.forProject(f.source,
        profile: SourceEventProfile.forProject(f.source)).analyze();
      expect(analysis.events.single.isQuarantined, isTrue);
    }
  });

  test('ME binding imports exact ME bytes with explicit native music role', () async {
    final f = await _fixture();
    final binding = await const SourceEventSoundResolver().read(
      source: f.source, files: f.files, name: 'Reward',
      kind: SourceEventAudioKind.musicEffect,
      policy: SourceEventSoundPolicy.nativeAuthoredVolume,
    );
    expect(binding.kind, SourceEventAudioKind.musicEffect);
    expect(binding.audioFile.relativePath, 'Audio/ME/Reward.wav');
    expect(binding.artifact.bytes, sourceMapMusicFixtureWav());
    expect(binding.mediaId, startsWith('source_me_media_'));
    expect(binding.mutation.parameters['mediaKind'], 'sound');
    expect(binding.gainForVolume(35), .35);
    expect(binding.evidence['playbackRole'], 'musicEffect');
    expect(binding.evidence['requiredRuntimeCommand'], 'playMusicEffect');
    expect(binding.evidence['sourceBgmVolumeRouting'], isTrue);
    expect(binding.evidence['sourceMeBackendQualified'], isFalse);
    expect(binding.evidence['fullSourceParity'], isFalse);
    expect(binding.evidence['nativeAuthoredVolumeAdaptation'], isTrue);
    expect(binding.evidence['sourceScriptsExecuted'], 0);
  });

  test('ME refuses an unqualified source engine policy and never falls back to SE', () async {
    final f = await _fixture(missing: true);
    for (final policy in SourceEventSoundPolicy.values) {
      await expectLater(const SourceEventSoundResolver().read(
        source: f.source, files: f.files, name: 'Reward',
        kind: SourceEventAudioKind.musicEffect, policy: policy,
      ), throwsA(isA<SourceEventSoundBindingUnavailable>().having(
        (e) => e.reason, 'reason', policy == SourceEventSoundPolicy.sourceEngineGain
          ? 'music_effect_engine_parity_unqualified' : 'audio_missing')));
    }
  });

  test('ME refuses ambiguous source audio and changed bytes', () async {
    final duplicate = await _fixture(duplicate: true);
    await expectLater(const SourceEventSoundResolver().read(
      source: duplicate.source, files: duplicate.files, name: 'Reward',
      kind: SourceEventAudioKind.musicEffect,
      policy: SourceEventSoundPolicy.nativeAuthoredVolume,
    ), throwsA(isA<SourceEventSoundBindingUnavailable>().having(
      (e) => e.reason, 'reason', 'audio_ambiguous')));
    final changed = await _fixture();
    changed.files.overrides['Audio/ME/Reward.wav'] = [0, 1];
    await expectLater(const SourceEventSoundResolver().read(
      source: changed.source, files: changed.files, name: 'Reward',
      kind: SourceEventAudioKind.musicEffect,
      policy: SourceEventSoundPolicy.nativeAuthoredVolume,
    ), throwsA(isA<SourceEventSoundBindingUnavailable>().having(
      (e) => e.reason, 'reason', 'audio_changed')));
  });
}
