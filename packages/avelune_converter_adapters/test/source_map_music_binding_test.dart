import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:avelune_converter_adapters/src/source_map_music_binding.dart';
import 'package:avelune_converter_adapters/src/source_semantic_study_composer.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/source_map_music_fixture.dart';

Matcher _unavailable(String reason) => isA<SourceMapMusicBindingUnavailable>()
    .having((error) => error.reason, 'reason', 'map.music.$reason');

Future<SourceMapMusicBinding?> _read(SourceMapMusicFixture fixture,
        {int mapId = 1,
        NativeWriteLimits limits = const NativeWriteLimits(),
        ScanCancellation? cancellation}) =>
    const SourceMapMusicResolver().read(
        source: fixture.source,
        files: fixture.files,
        sourceMapId: mapId,
        limits: limits,
        cancellation: cancellation);

void main() {
  final scriptsPath = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];
  if (scriptsPath == null) {
    test('source map music requires the exact inert Kanto oracle', () {},
        skip:
            'Set AVELUNE_AC13_SOURCE_SCRIPTS for the source-qualified suite.');
    return;
  }
  late SourceMapMusicOracle oracle;
  setUpAll(() async {
    oracle = await SourceMapMusicOracle.read(scriptsPath);
  });

  test('imports exact music and exposes the post-map canonical audio mutation',
      () async {
    final fixture = await SourceMapMusicFixture.create(oracle: oracle);
    final binding = (await _read(fixture))!;
    expect(binding.sourceMapId, 1);
    expect(binding.sourceSnapshotHash, fixture.snapshot.canonicalHash);
    expect(binding.normalizedSourceHash, fixture.source.canonicalHash);
    expect(binding.mapFile.relativePath, 'Data/Map001.rxdata');
    expect(binding.nativeVolume, 0.64);
    expect(binding.artifacts, hasLength(1));
    final artifact = binding.artifacts.single;
    expect(artifact.bytes, fixture.sourceBytes['Audio/BGM/Original Route.wav']);
    expect(artifact.reference.mediaType, 'audio/wav');
    expect(binding.importMutations, hasLength(1));
    final import = binding.importMutations.single;
    expect(import.actionId, 'asset.import');
    expect(import.parameters['artifactHandle'], artifact.handle);
    expect(import.parameters['logicalPath'], binding.mapMusicPath);
    expect(
        import.parameters.keys,
        unorderedEquals(
            ['artifactHandle', 'assetId', 'logicalPath', 'tags', 'usages']));
    final map = binding.mapMutation(nativeMapId: 'native-map-1');
    expect(map.actionId, 'map.audio.update');
    expect(map.sourceEntityIds, contains(fixture.source.mapIdentity(1)));
    expect(map.parameters, {
      'mapId': 'native-map-1',
      'musicPath': binding.mapMusicPath,
      'musicVolume': 0.64,
    });
    expect(binding.evidence['sourceRubyAudioGain'], 0.8);
    expect(binding.evidence['sourceEngineGlobalGain'], 0.8);
    expect(binding.evidence['nativeAudioGain'], 0.64);
    expect(binding.evidence['sourceEngineBinaryRetained'], isFalse);
    expect(binding.evidence['sourceEngineBinaryExecuted'], isFalse);
    expect(binding.evidence['upstreamBinaryByteEquivalenceQualified'], isFalse);
    expect(binding.evidence['sourceAudioPlaybackObserved'], isFalse);
    expect(binding.evidence['battleAuthority'], 'aveluneNative');
    expect(
        binding.evidence['requiredRuntimeContext'], 'freshGameDefaultOptions');
    expect(
        fixture.files.reads,
        isNot(contains(fixture.snapshot.entries
            .singleWhere((entry) => entry.relativePath == 'Game.exe')
            .fileId)));
    expect(() => binding.artifacts.clear(), throwsUnsupportedError);
    expect(
        () => binding.evidence['nativeAudioGain'] = 1, throwsUnsupportedError);
    expect(() => artifact.bytes[0] = 0, throwsUnsupportedError);
  });

  test('stable music identities survive unrelated snapshot changes', () async {
    final original = await SourceMapMusicFixture.create(oracle: oracle);
    final changed = await SourceMapMusicFixture.create(
        oracle: oracle,
        extraFiles: {'PBS/unused.txt': utf8.encode('original')});
    final first = (await _read(original))!;
    final second = (await _read(changed))!;
    expect(first.sourceSnapshotHash, isNot(second.sourceSnapshotHash));
    expect(first.mapMusicPath, second.mapMusicPath);
    expect(first.importMutations.single.operationId,
        second.importMutations.single.operationId);
    expect(first.mapMutation(nativeMapId: 'map').operationId,
        second.mapMutation(nativeMapId: 'map').operationId);
  });

  test('autoplay false returns no binding without engine or audio reads',
      () async {
    final fixture = await SourceMapMusicFixture.create(
        oracle: oracle, missingEngine: true, maps: [LiteralFixtureMap(id: 1)]);
    expect(await _read(fixture), isNull);
    expect(fixture.files.reads, [
      fixture.snapshot.entries
          .singleWhere((entry) => entry.relativePath == 'Data/Map001.rxdata')
          .fileId
    ]);
  });

  for (final params in [
    (name: '', volume: 100, pitch: 100, reason: 'name_unqualified'),
    (
      name: 'Original Route',
      volume: 80,
      pitch: 100,
      reason: 'volume_unsupported'
    ),
    (
      name: 'Original Route',
      volume: 100,
      pitch: 90,
      reason: 'pitch_unsupported'
    ),
    (
      name: '../Original Route',
      volume: 100,
      pitch: 100,
      reason: 'name_unqualified'
    ),
  ]) {
    test('refuses unsupported source audio fields ${params.reason}', () async {
      final fixture = await SourceMapMusicFixture.create(oracle: oracle, maps: [
        LiteralFixtureMap(
            id: 1,
            autoplayBgm: true,
            bgmName: params.name,
            bgmVolume: params.volume,
            bgmPitch: params.pitch)
      ]);
      await expectLater(_read(fixture), throwsA(_unavailable(params.reason)));
    });
  }

  test('refuses unqualified autoplay rather than inventing a silent map',
      () async {
    final original = await SourceMapMusicFixture.create(oracle: oracle);
    final raw = List<int>.of(original.sourceBytes['Data/Map001.rxdata']!);
    final doc =
        const MarshalDecoder().decode(raw, sourcePath: 'Data/Map001.rxdata');
    final id = doc
        .node(doc.rootId)
        .instanceVariables
        .singleWhere((pair) => doc.node(pair.key).name == '@autoplay_bgm')
        .value;
    raw[doc.node(id).location.byteOffset] = 0x30;
    final fixture = await SourceMapMusicFixture.create(
        oracle: oracle, filePatches: {'Data/Map001.rxdata': raw});
    await expectLater(
        _read(fixture), throwsA(_unavailable('autoplay_unqualified')));
  });

  test('refuses a source scripts profile different from the oracle', () async {
    final fixture =
        await SourceMapMusicFixture.create(oracle: oracle, filePatches: {
      'Data/Scripts.rxdata': [4, 8, 0x30]
    });
    await expectLater(
        _read(fixture), throwsA(_unavailable('profile_unqualified')));
  });

  test('refuses a missing engine identity', () async {
    final fixture =
        await SourceMapMusicFixture.create(oracle: oracle, missingEngine: true);
    await expectLater(
        _read(fixture), throwsA(_unavailable('engine_unqualified')));
  });

  test('refuses changed engine hashes even with an advertised version',
      () async {
    final fixture = await SourceMapMusicFixture.create(
        oracle: oracle,
        engineHash: literalFixtureHash(utf8.encode('mkxp-z 2.4.2/c9378cf')));
    await expectLater(
        _read(fixture), throwsA(_unavailable('engine_unqualified')));
  });

  test('refuses changed engine sizes even with the exact known hash', () async {
    final fixture = await SourceMapMusicFixture.create(
        oracle: oracle, engineByteLength: oracle.engineByteLength - 1);
    await expectLater(
        _read(fixture), throwsA(_unavailable('engine_unqualified')));
  });

  for (final path in ['Game.ini', 'mkxp.json']) {
    test('refuses runtime configuration variants $path', () async {
      final fixture = await SourceMapMusicFixture.create(
          oracle: oracle, filePatches: {path: utf8.encode('original variant')});
      await expectLater(
          _read(fixture), throwsA(_unavailable('configuration_unqualified')));
    });
  }

  test('refuses a night-time variant instead of fixing an unknown clock',
      () async {
    final fixture =
        await SourceMapMusicFixture.create(oracle: oracle, extraFiles: {
      'Audio/BGM/Original Route_n.wav': sourceMapMusicFixtureWav(),
    });
    await expectLater(
        _read(fixture), throwsA(_unavailable('night_variant_unsupported')));
  });

  test('refuses ambiguous file extensions before reading audio', () async {
    final fixture =
        await SourceMapMusicFixture.create(oracle: oracle, extraFiles: {
      'Audio/BGM/Original Route.ogg': sourceMapMusicFixtureWav(),
    });
    await expectLater(_read(fixture), throwsA(_unavailable('audio_ambiguous')));
  });

  test('refuses bytes whose MIME does not match the file extension', () async {
    final fixture = await SourceMapMusicFixture.create(oracle: oracle, maps: [
      LiteralFixtureMap(id: 1, autoplayBgm: true, bgmName: 'Invalid Audio'),
    ], extraFiles: {
      'Audio/BGM/Invalid Audio.ogg': sourceMapMusicFixtureWav()
    });
    await expectLater(
        _read(fixture), throwsA(_unavailable('audio_unsupported')));
  });

  test(
      'rejects changed source bytes instead of accepting the old snapshot hash',
      () async {
    final fixture = await SourceMapMusicFixture.create(oracle: oracle);
    fixture.files.overrides['Audio/BGM/Original Route.wav'] = [1, 2, 3];
    await expectLater(
        _read(fixture),
        throwsA(isA<ContractError>().having(
            (error) => error.code, 'code', 'source.map_music.source_changed')));
  });

  test('retains the caller byte quota and checks it before audio I/O',
      () async {
    final fixture = await SourceMapMusicFixture.create(oracle: oracle);
    await expectLater(
        _read(fixture, limits: const NativeWriteLimits(maxArtifactBytes: 128)),
        throwsA(isA<ContractError>()
            .having((error) => error.code, 'code', 'source.map_music.quota')));
    expect(
        fixture.files.reads,
        isNot(contains(fixture.snapshot.entries
            .singleWhere(
                (entry) => entry.relativePath == 'Audio/BGM/Original Route.wav')
            .fileId)));
  });

  test('cooperative cancellation runs before any source read', () async {
    final fixture = await SourceMapMusicFixture.create(oracle: oracle);
    final cancellation = ScanCancellation()..cancel();
    await expectLater(
        _read(fixture, cancellation: cancellation),
        throwsA(isA<ContractError>()
            .having((error) => error.code, 'code', 'source.cancelled')));
    expect(fixture.files.reads, isEmpty);
  });

  test('refuses an active music reference with no exact source file', () async {
    final fixture = await SourceMapMusicFixture.create(oracle: oracle, maps: [
      LiteralFixtureMap(id: 1, autoplayBgm: true, bgmName: 'Absent Music'),
    ]);
    await expectLater(_read(fixture), throwsA(_unavailable('audio_missing')));
  });

  test('refuses an extensionless source file without guessing its MIME',
      () async {
    final fixture = await SourceMapMusicFixture.create(oracle: oracle, maps: [
      LiteralFixtureMap(id: 1, autoplayBgm: true, bgmName: 'Extensionless'),
    ], extraFiles: {
      'Audio/BGM/Extensionless': sourceMapMusicFixtureWav(),
    });
    await expectLater(
        _read(fixture), throwsA(_unavailable('audio_unsupported')));
  });

  test('active music operation quotas remain caller bounded', () async {
    final fixture = await SourceMapMusicFixture.create(oracle: oracle);
    await expectLater(
        _read(fixture, limits: const NativeWriteLimits(maxMutations: 1)),
        throwsA(isA<ContractError>()
            .having((error) => error.code, 'code', 'source.map_music.quota')));
    expect(fixture.files.reads, [
      fixture.snapshot.entries
          .singleWhere((entry) => entry.relativePath == 'Data/Map001.rxdata')
          .fileId
    ]);
  });

  test('changed runtime configuration bytes reject the sealed old hash',
      () async {
    final fixture = await SourceMapMusicFixture.create(oracle: oracle);
    fixture.files.overrides['mkxp.json'] = [1, 2, 3];
    await expectLater(
        _read(fixture),
        throwsA(isA<ContractError>().having(
            (error) => error.code, 'code', 'source.map_music.source_changed')));
  });

  final snapshotPath = Platform.environment['AVELUNE_AC13_SOURCE_SNAPSHOT'];
  test(
      'Route9 admitted inventory yields exact music bytes and sealed witnesses',
      () async {
    final input = File(snapshotPath!);
    expect(await input.length(), lessThanOrEqualTo(8388608));
    final raw = jsonDecode(await input.readAsString()) as Map<String, dynamic>;
    final snapshot = _sourceSnapshot(raw);
    expect(snapshot.canonicalHash.value, raw['canonicalHash']);
    expect(snapshot.canonicalHash.value,
        '5bc0f5dd57e70951cb86fe7c71114e983827251830b2b11f23ef2dab48f1c8de');
    final files = _ExactFiles(File(scriptsPath).parent.parent.path, snapshot);
    final cancellation = ScanCancellation();
    final witnesses = SourceSemanticWitnessFiles(
        snapshot, files, const NativeWriteLimits(), cancellation);
    final source = await const RmxpSourceNormalizer().normalize(
        snapshot: snapshot,
        files: witnesses,
        selectedMapIds: {98},
        cancellation: cancellation);
    final binding = (await const SourceMapMusicResolver().read(
        source: source,
        files: witnesses,
        sourceMapId: 98,
        cancellation: cancellation))!;
    expect(binding.mapFile.sha256!.value,
        'b6761d596c30bf7fc7119cbc422ac9a01e910a77c0a4a3da597eb8e4be59b620');
    expect(binding.audioFile.relativePath,
        'Audio/BGM/FRLG Route 03 (Road to Cerulean City - From Mt. Moon).ogg');
    expect(binding.audioFile.sha256!.value,
        '0d3ce709cb67e9b13a2c1b78e9133c56c7cd58e50aceb6cbb30c22fe28cccf2d');
    expect(binding.artifacts.single.bytes, hasLength(591824));
    expect(binding.artifacts.single.reference.mediaType, 'audio/ogg');
    expect(binding.nativeVolume, 0.64);
    expect(binding.mapMutation(nativeMapId: 'route9').sourceEntityIds,
        contains(source.mapIdentity(98)));
    expect(files.readPaths, isNot(contains('Game.exe')));
    final requiredPaths = [
      binding.mapFile.relativePath,
      binding.audioFile.relativePath,
      'Data/Scripts.rxdata',
      'Game.ini',
      'mkxp.json'
    ];
    expect(witnesses.evidence.map((entry) => entry['relativePath']),
        containsAll(requiredPaths));
    for (final witness in witnesses.evidence) {
      final original = snapshot.entries
          .singleWhere((entry) => entry.fileId.value == witness['fileId']);
      expect(witness['byteLength'], original.byteLength);
      expect(witness['rawSha256'], original.sha256!.value);
      for (final chunk in witness['chunks'] as List? ?? []) {
        expect(witnesses.artifacts, contains(chunk['artifactHandle']));
      }
    }
    final output = Platform.environment['AVELUNE_AC13_MAP_MUSIC_PROOF'];
    if (output != null) {
      final file = File(output);
      expect(await file.exists(), isFalse);
      await file.writeAsString(jsonEncode({
        'kind': 'sourceMapMusicRoute9Qualification',
        'binding': binding.evidence,
        'mapMutation': binding.mapMutation(nativeMapId: 'route9').toJson(1),
        'witnesses': witnesses.evidence,
        'engineFreshOracleHash': oracle.engineHash.value,
        'engineFreshOracleByteLength': oracle.engineByteLength,
        'binaryExecuted': false,
        'sourceScanRepeated': false,
        'sourceWrites': 0,
      }));
    }
  },
      skip: snapshotPath == null
          ? 'Set AVELUNE_AC13_SOURCE_SNAPSHOT for Route9.'
          : false);
}

SourceSnapshot _sourceSnapshot(Map<String, dynamic> raw) => SourceSnapshot(
      logicalProjectNamespace:
          ConverterId(raw['logicalProjectNamespace'] as String),
      policyHash: Sha256Hash(raw['policyHash'] as String),
      state: SourceScanState.values.byName(raw['state'] as String),
      entries: [
        for (final item in raw['entries'] as List)
          SourceFileEntry(
              fileId: ConverterId(item['fileId'] as String),
              relativePath: item['relativePath'] as String,
              kind: SourceNodeKind.values.byName(item['kind'] as String),
              byteLength: item['byteLength'] as int,
              sha256: item['sha256'] == null
                  ? null
                  : Sha256Hash(item['sha256'] as String),
              format: item['format'] as String,
              family: item['family'] as String)
      ],
      diagnostics: [
        for (final item in raw['diagnostics'] as List)
          SourceScanDiagnostic(
              code: item['code'] as String,
              relativePath: item['relativePath'] as String,
              message: item['message'] as String,
              blocksExtraction: item['blocksExtraction'] as bool,
              relatedPaths: List<String>.from(item['relatedPaths'] as List))
      ],
      excludedPaths: List<String>.from(raw['excludedPaths'] as List),
      profileEvidence: [
        for (final item in raw['profileEvidence'] as List)
          SourceProfileEvidence(
              relativePath: item['relativePath'] as String,
              fileHash: Sha256Hash(item['fileHash'] as String),
              version: item['version'] as String,
              line: item['line'] as int,
              excerpt: item['excerpt'] as String)
      ],
    );

final class _ExactFiles implements SourceFilePort {
  _ExactFiles(String root, SourceSnapshot snapshot)
      : root = Directory(root).resolveSymbolicLinksSync(),
        entries = {for (final entry in snapshot.entries) entry.fileId: entry};
  final String root;
  final Map<ConverterId, SourceFileEntry> entries;
  final List<String> readPaths = [];

  @override
  Future<List<int>> read(ConverterId id) async {
    final entry = entries[id]!;
    final file = File('$root/${entry.relativePath}');
    expect(await FileSystemEntity.type(file.path, followLinks: false),
        FileSystemEntityType.file);
    expect(await file.resolveSymbolicLinks(), startsWith('$root/'));
    expect(await file.length(), entry.byteLength);
    readPaths.add(entry.relativePath);
    return file.readAsBytes();
  }
}
