import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/src/source_event_sound_binding.dart';
import 'package:avelune_converter_adapters/src/source_card_key_gate_audio.dart';
import 'package:avelune_converter_adapters/src/builtin_source_interpretation_profiles.dart';
import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/source_map_music_fixture.dart';

void main() {
  final scripts = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];
  final optionalSoundRoot =
      Platform.environment['OPTIONAL_SOUND_ROOT'];
  final optionalScripts =
      Platform.environment['OPTIONAL_SOUND_SCRIPTS'] ?? scripts;
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

    test(
        'native authored sound binds exact audio without claiming source engine gain',
        () async {
      final input = await SourceMapMusicFixture.create(
          oracle: oracle,
          missingEngine: true,
          extraFiles: {
            'Audio/SE/ItemGet.wav': sourceMapMusicFixtureWav(),
          });
      final binding = await const SourceEventSoundResolver().read(
          source: input.source,
          files: input.files,
          name: 'ItemGet',
          policy: SourceEventSoundPolicy.nativeAuthoredVolume);
      expect(binding.gainForVolume(100), 1);
      expect(binding.gainForVolume(35), 0.35);
      expect(binding.evidence['sourceEngineGainQualified'], isFalse);
      expect(binding.evidence['fullSourceParity'], isFalse);
      expect(binding.evidence['nativeGain'], 'authoredVolume/100');
      expect(binding.evidence.containsKey('sourceEngineFile'), isFalse);
      expect(binding.artifact.bytes, input.sourceBytes['Audio/SE/ItemGet.wav']);
      await expectLater(
          const SourceEventSoundResolver()
              .read(source: input.source, files: input.files, name: 'ItemGet'),
          throwsA(isA<SourceEventSoundBindingUnavailable>()));
      input.files.overrides['Audio/SE/ItemGet.wav'] = [0, 1];
      await expectLater(
          const SourceEventSoundResolver().read(
              source: input.source,
              files: input.files,
              name: 'ItemGet',
              policy: SourceEventSoundPolicy.nativeAuthoredVolume),
          throwsA(isA<SourceEventSoundBindingUnavailable>()
              .having((error) => error.reason, 'reason', 'audio_changed')));
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

  group('qualified optional source sound absence', () {
    late Map<String, List<int>> sourceFiles;
    late List<int> archive;
    setUpAll(() async {
      final root = Directory(optionalSoundRoot!);
      archive = await File(optionalScripts!).readAsBytes();
      sourceFiles = {
        for (final path in ['Game.ini', 'mkxp.json', 'Data/PluginScripts.rxdata'])
          path: await File('${root.path}/$path').readAsBytes(),
      };
      await for (final entry in root.list(recursive: true, followLinks: false)) {
        if (entry is File && entry.path.toLowerCase().endsWith('.rb')) {
          sourceFiles[entry.path.substring(root.path.length + 1)] =
              await entry.readAsBytes();
        }
      }
    });
    Future<({NormalizedSourceProject source, LiteralFixtureFiles files})>
        fixture({Map<String, List<int>> extra = const {},
          List<String> exclusions = const []}) async {
      final input = await LiteralTileFixture.create(
          scriptsBytes: archive, includeEventSystem: true,
          extraFiles: {...sourceFiles, ...extra});
      final original = input.snapshot;
      final snapshot = SourceSnapshot(
          logicalProjectNamespace: original.logicalProjectNamespace,
          policyHash: original.policyHash, entries: original.entries,
          diagnostics: original.diagnostics, excludedPaths: exclusions,
          profileEvidence: original.profileEvidence, state: original.state);
      final profile = detectBuiltinSourceInterpretationProfile(snapshot);
      expect(profile, isNotNull);
      final source = await const RmxpSourceNormalizer().normalize(
          snapshot: snapshot, files: input.files,
          interpretationProfile: profile, includeEventSystem: true);
      return (source: source, files: input.files);
    }
    const resolver = SourceMissingOptionalSoundResolver();

    test('seals an arbitrary absent literal sound without substituting audio',
        () async {
      final input = await fixture(extra: {
        'Audio/SE/Other Sound.wav': sourceMapMusicFixtureWav(),
      });
      final proof = await resolver.read(source: input.source, files: input.files,
          name: 'Unlisted Reward Chime');
      final profile = SourceEventProfile.forProject(input.source);
      expect(proof.isBoundTo(input.source, profile,
          name: 'Unlisted Reward Chime'), isTrue);
      expect(proof.isBoundTo(input.source, profile, name: 'Other Sound'), isFalse);
      expect(proof.toJson()['name'], 'Unlisted Reward Chime');
      expect(proof.toJson()['nativeSoundSubstituted'], isFalse);
      expect(proof.toJson()['sourceDiagnosticRetained'], isTrue);
      expect(proof.toJson()['sourceScriptsExecuted'], 0);
      expect(proof.witnesses, isNotEmpty);
    });

    test('accepts an arbitrary title while retaining local empty RTP', () async {
      final text = latin1.decode(sourceFiles['Game.ini']!);
      final input = await fixture(extra: {
        'Game.ini': latin1.encode(text.replaceFirst(
            RegExp(r'Title=[^\r\n]*'), 'Title=Orbit Adventure')),
      });
      final proof = await resolver.read(source: input.source, files: input.files,
          name: 'Unlisted Reward Chime');
      expect(proof.toJson()['sourceGameIniPolicy'],
          'bounded-local-scripts-and-empty-rtp-v1');
    });

    test('refuses external RTP, script redirection and ambiguous INI fields',
        () async {
      final text = latin1.decode(sourceFiles['Game.ini']!);
      for (final modified in [
        text.replaceFirst('RTP1=', 'RTP1=External Pack'),
        text.replaceFirst(r'Scripts=Data\Scripts.rxdata',
            r'Scripts=Other\Scripts.rxdata'),
        text.replaceFirst('Library=RGSS104E.dll', 'Library=Other.dll'),
        '$text\r\nRTP1=\r\n',
      ]) {
        final input = await fixture(extra: {'Game.ini': latin1.encode(modified)});
        await expectLater(resolver.read(source: input.source, files: input.files,
            name: 'Unlisted Reward Chime'),
            throwsA(isA<NativeWriteException>().having((error) => error.code,
                'code', 'events.optional_sound.audio_resolution_unqualified')));
      }
    });

    for (final variant in ['exact', 'case', 'unsupported']) {
      test('refuses $variant existing audio even when it cannot be imported',
          () async {
        final path = switch (variant) {
          'case' => 'Audio/SE/UNLISTED REWARD CHIME.wav',
          'unsupported' => 'Audio/SE/Unlisted Reward Chime.wma',
          _ => 'Audio/SE/Unlisted Reward Chime.wav',
        };
        final input = await fixture(extra: {path: [0, 1]});
        await expectLater(resolver.read(source: input.source, files: input.files,
            name: 'Unlisted Reward Chime'),
            throwsA(isA<NativeWriteException>().having((error) => error.code,
                'code', 'events.optional_sound.audio_absence_unqualified')));
      });
    }

    test('refuses hidden audio and unknown Ruby overrides', () async {
      final hidden = await fixture(exclusions: ['Audio/SE']);
      await expectLater(resolver.read(source: hidden.source, files: hidden.files,
          name: 'Unlisted Reward Chime'),
          throwsA(isA<NativeWriteException>().having((error) => error.code,
              'code', 'events.optional_sound.audio_absence_unqualified')));
      final overridden = await fixture(extra: {'Plugins/NewAudio.rb': [35]});
      await expectLater(resolver.read(source: overridden.source,
          files: overridden.files, name: 'Unlisted Reward Chime'),
          throwsA(isA<NativeWriteException>().having((error) => error.code,
              'code', 'events.optional_sound.audio_overrides_unqualified')));
      final compiledOverride = await fixture(extra: {
        'Data/PluginScripts.rxdata': [0, 1],
      });
      await expectLater(resolver.read(source: compiledOverride.source,
          files: compiledOverride.files, name: 'Unlisted Reward Chime'),
          throwsA(isA<NativeWriteException>().having((error) => error.code,
              'code', 'events.optional_sound.audio_overrides_unqualified')));
    });

    test('refuses changed proof bytes and nonliteral sound paths', () async {
      final input = await fixture();
      input.files.overrides['Data/PluginScripts.rxdata'] = [0, 1];
      await expectLater(resolver.read(source: input.source, files: input.files,
          name: 'Unlisted Reward Chime'),
          throwsA(isA<NativeWriteException>().having((error) => error.code,
              'code', 'events.optional_sound.audio_proof_changed')));
      for (final name in ['', '..', '../Sound', 'Sound/Other']) {
        await expectLater(resolver.read(source: input.source, files: input.files,
            name: name), throwsA(isA<NativeWriteException>().having(
                (error) => error.code, 'code',
                'events.optional_sound.audio_name_unqualified')));
      }
    });
  }, skip: optionalScripts == null || optionalSoundRoot == null);
}
