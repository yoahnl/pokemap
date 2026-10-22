import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:avelune_converter_adapters/src/source_map_music_binding.dart';
import 'package:avelune_converter_adapters/src/source_semantic_study_composer.dart';
import 'package:avelune_converter_adapters/src/source_event_study_composer.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
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

Future<LiteralTileFixture> _sharedMusicFixture({
  String namespace = 'shared-music-owner',
  Map<String, List<int>> extraFiles = const {},
}) =>
    LiteralTileFixture.create(
        namespace: namespace,
        interpretationProfile: syntheticSourceInterpretationProfile,
        scriptsBytes: syntheticInterpretationArchive,
        maps: [
          for (final id in [1, 2])
            LiteralFixtureMap(
                id: id,
                autoplayBgm: true,
                bgmName: 'Original Route',
                bgmVolume: id * 25)
        ],
        extraFiles: {
          'Audio/BGM/Original Route.wav': sourceMapMusicFixtureWav(),
          ...extraFiles
        });

void main() {
  test(
      'owner-bound music shares only immutable audio and retains map provenance',
      () async {
    final fixture = await _sharedMusicFixture();
    final resolver = SourceMapMusicResolver.forProject(
        source: fixture.source, files: fixture.files);
    final bindings = <SourceMapMusicBinding>[];
    for (final id in [1, 2]) {
      bindings.add((await resolver.read(
          source: fixture.source,
          files: fixture.files,
          sourceMapId: id,
          policy: SourceMapMusicPolicy.nativeAuthoredVolume))!);
    }
    final first = bindings.first, second = bindings.last;
    expect(second.artifacts.single, same(first.artifacts.single));
    expect(first.nativeVolume, 0.25);
    expect(second.nativeVolume, 0.5);
    expect(first.mapFile.fileId, isNot(second.mapFile.fileId));
    expect(first.mapMutation(nativeMapId: 'map-1').operationId,
        isNot(second.mapMutation(nativeMapId: 'map-2').operationId));
    final uncached = (await const SourceMapMusicResolver().read(
        source: fixture.source,
        files: fixture.files,
        sourceMapId: 2,
        policy: SourceMapMusicPolicy.nativeAuthoredVolume))!;
    expect(
        canonicalJsonOf(second.evidence), canonicalJsonOf(uncached.evidence));
    expect(second.importMutations.single.toJson(0),
        uncached.importMutations.single.toJson(0));
    expect(second.artifacts.single.bytes, uncached.artifacts.single.bytes);
    expect(second.artifacts.single, isNot(same(uncached.artifacts.single)));
    expect(() => second.artifacts.single.bytes[0] = 0, throwsUnsupportedError);
  });

  test(
      'warm music resolution revalidates changed bytes cancellation and limits',
      () async {
    final fixture = await _sharedMusicFixture();
    final resolver = SourceMapMusicResolver.forProject(
        source: fixture.source, files: fixture.files);
    Future<SourceMapMusicBinding?> read(
            {NativeWriteLimits limits = const NativeWriteLimits(),
            ScanCancellation? cancellation}) =>
        resolver.read(
            source: fixture.source,
            files: fixture.files,
            sourceMapId: 2,
            policy: SourceMapMusicPolicy.nativeAuthoredVolume,
            limits: limits,
            cancellation: cancellation);
    final warm = (await read())!;
    final beforeReads = fixture.files.reads.length;
    await expectLater(
        read(cancellation: ScanCancellation()..cancel()),
        throwsA(isA<ContractError>()
            .having((e) => e.code, 'code', 'source.cancelled')));
    expect(fixture.files.reads.length, beforeReads);
    for (final limits in [
      const NativeWriteLimits(maxArtifactBytes: 128),
      const NativeWriteLimits(maxTotalArtifactBytes: 128),
      const NativeWriteLimits(maxMutations: 1),
    ]) {
      await expectLater(
          read(limits: limits),
          throwsA(isA<ContractError>()
              .having((e) => e.code, 'code', 'source.map_music.quota')));
    }
    final differentLimits =
        (await read(limits: const NativeWriteLimits(maxArtifacts: 1)))!;
    expect(
        differentLimits.artifacts.single, isNot(same(warm.artifacts.single)));
    final cancel = ScanCancellation();
    fixture.files.onRead = (path) {
      if (path == 'Audio/BGM/Original Route.wav') cancel.cancel();
    };
    await expectLater(
        read(cancellation: cancel),
        throwsA(isA<ContractError>()
            .having((e) => e.code, 'code', 'source.cancelled')));
    fixture.files.onRead = null;
    fixture.files.overrides['Audio/BGM/Original Route.wav'] =
        List<int>.of(sourceMapMusicFixtureWav())..[100] = 0;
    await expectLater(
        read(),
        throwsA(isA<ContractError>()
            .having((e) => e.code, 'code', 'source.map_music.source_changed')));
    fixture.files.overrides.clear();
    expect((await read())!.artifacts.single, same(warm.artifacts.single));
  });

  test('owner-bound music refuses foreign source or file owners', () async {
    final fixture = await _sharedMusicFixture();
    final foreign = await _sharedMusicFixture();
    expect(foreign.source.canonicalHash, fixture.source.canonicalHash);
    final resolver = SourceMapMusicResolver.forProject(
        source: fixture.source, files: fixture.files);
    await resolver.read(
        source: fixture.source,
        files: fixture.files,
        sourceMapId: 1,
        policy: SourceMapMusicPolicy.nativeAuthoredVolume);
    for (final input in [
      (foreign.source, fixture.files),
      (fixture.source, foreign.files)
    ]) {
      await expectLater(
          resolver.read(
              source: input.$1,
              files: input.$2,
              sourceMapId: 2,
              policy: SourceMapMusicPolicy.nativeAuthoredVolume),
          throwsA(isA<NativeWriteException>()
              .having((e) => e.code, 'code', 'source.map_music.binding')));
    }
    expect(
        foreign.files.reads,
        isNot(contains(foreign.snapshot.entries
            .singleWhere(
                (e) => e.relativePath == 'Audio/BGM/Original Route.wav')
            .fileId)));
  });

  for (final variant in [
    (path: 'Audio/BGM/Original Route.wav.backup', reason: 'audio_ambiguous'),
    (
      path: 'Audio/BGM/Original Route_n.wav.backup',
      reason: 'night_variant_unsupported'
    ),
  ]) {
    test('indexed music keeps exact prefix refusal ${variant.path}', () async {
      final fixture = await _sharedMusicFixture(extraFiles: {
        variant.path: sourceMapMusicFixtureWav(),
      });
      final resolver = SourceMapMusicResolver.forProject(
          source: fixture.source, files: fixture.files);
      for (final reader in [
        const SourceMapMusicResolver(),
        resolver,
        resolver
      ]) {
        await expectLater(
            reader.read(
                source: fixture.source,
                files: fixture.files,
                sourceMapId: 1,
                policy: SourceMapMusicPolicy.nativeAuthoredVolume),
            throwsA(_unavailable(variant.reason)));
      }
    });
  }

  test('music inventory rejects case and Unicode normalization collisions',
      () async {
    for (final extraFiles in [
      {'Audio/BGM/ORIGINAL ROUTE.wav': sourceMapMusicFixtureWav()},
      {
        'Audio/BGM/Café.wav': sourceMapMusicFixtureWav(),
        'Audio/BGM/Cafe\u0301.wav': sourceMapMusicFixtureWav()
      },
    ]) {
      await expectLater(
          _sharedMusicFixture(extraFiles: extraFiles),
          throwsA(isA<ContractError>()
              .having((e) => e.code, 'code', 'source.snapshot_collision')));
    }
  });

  test('owner-bound music never caches failed media validation', () async {
    final fixture = await _sharedMusicFixture(extraFiles: {
      'Audio/BGM/Original Route.wav': [1, 2, 3],
    });
    final resolver = SourceMapMusicResolver.forProject(
        source: fixture.source, files: fixture.files);
    for (var attempt = 0; attempt < 2; attempt++) {
      await expectLater(
          resolver.read(
              source: fixture.source,
              files: fixture.files,
              sourceMapId: 1,
              policy: SourceMapMusicPolicy.nativeAuthoredVolume),
          throwsA(_unavailable('audio_unsupported')));
    }
    final audioId = fixture.snapshot.entries
        .singleWhere(
            (entry) => entry.relativePath == 'Audio/BGM/Original Route.wav')
        .fileId;
    expect(fixture.files.reads.where((id) => id == audioId), hasLength(2));
  });

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

  test(
      'composition shares a qualified music artifact across distinct map owners',
      () async {
    final fixture = await SourceMapMusicFixture.create(
        oracle: oracle,
        includeEventSystem: true,
        extraFiles: {
          'Data/map_connections.dat': literalFixtureMarshal([])
        },
        maps: [
          for (final id in [1, 2])
            LiteralFixtureMap(
                id: id, autoplayBgm: true, bgmName: 'Original Route')
        ]);
    final base = NativeProjectDraft(
        source: fixture.source,
        projectName: 'Shared music',
        parentPath: '/private/tmp',
        folderName: 'unused-shared-music',
        mapIds: const {
          1: 'map-1',
          2: 'map-2'
        },
        artifacts: [],
        compositionEvidence: const {
          'sourceSemantics': {}
        },
        mutations: [
          for (final id in [1, 2])
            NativeMutation(
                operationId: ConverterId('save-map-$id'),
                actionId: 'map.save',
                sourceEntityIds: [
                  fixture.source.mapIdentity(id)
                ],
                targetEntityIds: [
                  ConverterId('map-$id')
                ],
                parameters: {
                  'map': MapData(
                      id: 'map-$id',
                      name: 'Map $id',
                      size: const GridSize(width: 3, height: 1),
                      layers: []).toJson(),
                })
        ]);
    final watch = Stopwatch()..start();
    final composition = (await const SourceEventStudyComposer()
        .compose(source: fixture.source, base: base, files: fixture.files))!;
    watch.stop();
    final first = composition.musicBindings[1]!;
    final second = composition.musicBindings[2]!;
    expect(first.mapFile.fileId, isNot(second.mapFile.fileId));
    expect(first.mapMutation(nativeMapId: 'map-1').operationId,
        isNot(second.mapMutation(nativeMapId: 'map-2').operationId));
    expect(first.artifacts.single.rawSha256, second.artifacts.single.rawSha256);
    expect(first.evidence['sourceMapId'], 1);
    expect(second.evidence['sourceMapId'], 2);
    final output = Platform.environment['AVELUNE_RC03_MUSIC_ORACLE'];
    if (output != null) {
      await File(output).writeAsString(jsonEncode({
        'elapsedMicros': watch.elapsedMicroseconds,
        'draftHash': composition.draft.canonicalHash.value,
        'evidenceHash':
            canonicalHashOf(composition.draft.compositionEvidence).value,
        'mutationsHash': canonicalHashOf(composition.draft.mutations.indexed
                .map((row) => row.$2.toJson(row.$1))
                .toList())
            .value,
        'artifacts': [
          for (final artifact in composition.draft.artifacts)
            {
              'handle': artifact.handle,
              'sha256': artifact.rawSha256.value,
              'length': artifact.bytes.length
            }
        ],
        'music': [first.evidence, second.evidence],
        'sharedArtifact':
            identical(first.artifacts.single, second.artifacts.single),
      }));
    }
    expect(second.artifacts.single, same(first.artifacts.single));
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

  test('refuses foreign source scripts before music resolution', () async {
    await expectLater(
        SourceMapMusicFixture.create(oracle: oracle, filePatches: {
          'Data/Scripts.rxdata': [4, 8, 0x30]
        }),
        throwsA(isA<ContractError>().having((error) => error.code, 'code',
            'interpretation_profile.source_mismatch')));
  });

  test(
      'native authored music preserves attested map volume without an engine claim',
      () async {
    final fixture = await SourceMapMusicFixture.create(
        oracle: oracle,
        missingEngine: true,
        maps: [
          LiteralFixtureMap(
              id: 1,
              autoplayBgm: true,
              bgmName: 'Original Route',
              bgmVolume: 35)
        ]);
    final binding = (await const SourceMapMusicResolver().read(
        source: fixture.source,
        files: fixture.files,
        sourceMapId: 1,
        policy: SourceMapMusicPolicy.nativeAuthoredVolume))!;
    expect(binding.nativeVolume, 0.35);
    expect(binding.evidence['sourceEngineGainQualified'], isFalse);
    expect(binding.evidence['fullSourceParity'], isFalse);
    expect(binding.evidence['sourceVolume'], 35);
    expect(binding.evidence['nativeGain'], 'authoredVolume/100');
    expect(binding.evidence.containsKey('sourceEngineFile'), isFalse);
    expect(binding.artifacts.single.bytes,
        fixture.sourceBytes['Audio/BGM/Original Route.wav']);
    final cancel = ScanCancellation()..cancel();
    await expectLater(
        const SourceMapMusicResolver().read(
            source: fixture.source,
            files: fixture.files,
            sourceMapId: 1,
            policy: SourceMapMusicPolicy.nativeAuthoredVolume,
            cancellation: cancel),
        throwsA(isA<ContractError>()
            .having((error) => error.code, 'code', 'source.cancelled')));
    fixture.files.overrides['Audio/BGM/Original Route.wav'] = [0, 1];
    await expectLater(
        const SourceMapMusicResolver().read(
            source: fixture.source,
            files: fixture.files,
            sourceMapId: 1,
            policy: SourceMapMusicPolicy.nativeAuthoredVolume),
        throwsA(isA<ContractError>().having(
            (error) => error.code, 'code', 'source.map_music.source_changed')));
  });

  test('native music keeps malformed audio unsupported pitch and quota closed',
      () async {
    final malformed = await SourceMapMusicFixture.create(
        oracle: oracle,
        missingEngine: true,
        filePatches: {
          'Audio/BGM/Original Route.wav': [1, 2, 3]
        });
    await expectLater(
        const SourceMapMusicResolver().read(
            source: malformed.source,
            files: malformed.files,
            sourceMapId: 1,
            policy: SourceMapMusicPolicy.nativeAuthoredVolume),
        throwsA(_unavailable('audio_unsupported')));
    final pitch = await SourceMapMusicFixture.create(
        oracle: oracle,
        missingEngine: true,
        maps: [
          LiteralFixtureMap(
              id: 1, autoplayBgm: true, bgmName: 'Original Route', bgmPitch: 99)
        ]);
    await expectLater(
        const SourceMapMusicResolver().read(
            source: pitch.source,
            files: pitch.files,
            sourceMapId: 1,
            policy: SourceMapMusicPolicy.nativeAuthoredVolume),
        throwsA(_unavailable('pitch_unsupported')));
    final quota =
        await SourceMapMusicFixture.create(oracle: oracle, missingEngine: true);
    await expectLater(
        const SourceMapMusicResolver().read(
            source: quota.source,
            files: quota.files,
            sourceMapId: 1,
            policy: SourceMapMusicPolicy.nativeAuthoredVolume,
            limits: const NativeWriteLimits(maxArtifactBytes: 128)),
        throwsA(isA<ContractError>()
            .having((error) => error.code, 'code', 'source.map_music.quota')));
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
