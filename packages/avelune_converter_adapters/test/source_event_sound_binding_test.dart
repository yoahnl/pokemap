import 'dart:io';

import 'package:avelune_converter_adapters/src/source_event_sound_binding.dart';
import 'package:test/test.dart';

import 'support/source_map_music_fixture.dart';

void main() {
  final scripts = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];
  group('source scene sound', () {
    late SourceMapMusicOracle oracle;
    setUpAll(() async {
      oracle = await SourceMapMusicOracle.read(scripts!);
    });
    Future<SourceMapMusicFixture> fixture({bool duplicate = false}) =>
        SourceMapMusicFixture.create(oracle: oracle, extraFiles: {
          'Audio/SE/Original Door.wav': sourceMapMusicFixtureWav(),
          if (duplicate)
            'Audio/SE/Original Door.ogg': sourceMapMusicFixtureWav(),
        });

    test('imports finite canonical sound with source option and engine gain',
        () async {
      final input = await fixture();
      final binding = await const SourceEventSoundResolver().read(
          source: input.source, files: input.files, name: 'Original Door');
      expect(binding.gainForVolume(100), closeTo(0.48, 1e-12));
      expect(binding.gainForVolume(80), closeTo(0.384, 1e-12));
      expect(binding.artifact.bytes,
          input.sourceBytes['Audio/SE/Original Door.wav']);
      expect(binding.mutation.actionId, 'scene.dialogue.audioMedia.import');
      expect(binding.evidence['usesDialogueFeedback'], isFalse);
      expect(binding.evidence['sourceScriptsExecuted'], 0);
      expect(binding.evidence['requiredRuntimeContext'],
          'freshGameDefaultOptions');
      expect(() => binding.gainForVolume(101), throwsArgumentError);
      expect(() => binding.artifact.bytes[0] = 0, throwsUnsupportedError);
    });

    test('rejects ambiguous source paths before an audio read', () async {
      final input = await fixture(duplicate: true);
      await expectLater(
          const SourceEventSoundResolver().read(
              source: input.source, files: input.files, name: 'Original Door'),
          throwsA(isA<SourceEventSoundBindingUnavailable>()
              .having((error) => error.reason, 'reason', 'audio_ambiguous')));
      expect(
          input.files.reads.where((id) => input.snapshot.entries
              .singleWhere((entry) => entry.fileId == id)
              .relativePath
              .startsWith('Audio/SE/')),
          isEmpty);
    });

    test('rejects noncanonical paths and changed source bytes', () async {
      final input = await fixture();
      await expectLater(
          const SourceEventSoundResolver().read(
              source: input.source,
              files: input.files,
              name: '../Original Door'),
          throwsA(isA<SourceEventSoundBindingUnavailable>()));
      input.files.overrides['Audio/SE/Original Door.wav'] = [0, 1];
      await expectLater(
          const SourceEventSoundResolver().read(
              source: input.source, files: input.files, name: 'Original Door'),
          throwsA(isA<SourceEventSoundBindingUnavailable>()
              .having((error) => error.reason, 'reason', 'audio_changed')));
    });
  }, skip: scripts == null);
}
