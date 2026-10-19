import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';

void main() {
  test('aggregate image budget defaults remain bounded per image and in total',
      () {
    const limits = NativeWriteLimits();
    expect(limits.maxImagePixels, 16777216);
    expect(limits.maxTotalImagePixels, 16777216);
    expect(limits.validate, returnsNormally);
  });

  test('aggregate image budget explicitly permits 32M without raising one PNG',
      () {
    const limits = NativeWriteLimits(maxTotalImagePixels: 33554432);
    expect(limits.maxImagePixels, 16777216);
    expect(limits.maxTotalImagePixels, 33554432);
    expect(limits.validate, returnsNormally);
    expect(
        const NativeWriteLimits(
                maxImagePixels: 16777217, maxTotalImagePixels: 33554432)
            .validate,
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.invalid_limits')));
  });

  test('world image budget admits its ceiling while keeping one PNG bounded', () {
    const limits = NativeWriteLimits(maxTotalImagePixels: 134217728);
    expect(limits.validate, returnsNormally);
    expect(limits.maxImagePixels, 16777216);
    expect(const NativeWriteLimits(maxTotalImagePixels: 41943040).validate,
        returnsNormally);
    expect(const NativeWriteLimits(maxTotalImagePixels: 41943041).validate,
        returnsNormally);
  });

  for (final pixels in [-1, 0, 134217729, 1000000000]) {
    test('aggregate image budget refuses invalid total $pixels', () {
      expect(
          NativeWriteLimits(maxTotalImagePixels: pixels).validate,
          throwsA(isA<NativeWriteException>()
              .having((error) => error.code, 'code', 'native.invalid_limits')));
    });
  }

  test('aggregate image budget cannot admit one PNG above 16M geometry', () {
    final bytes = List<int>.filled(33, 0);
    bytes.setRange(0, 8, [137, 80, 78, 71, 13, 10, 26, 10]);
    bytes.setRange(8, 16, [0, 0, 0, 13, 73, 72, 68, 82]);
    bytes.setRange(16, 24, [0, 0, 16, 1, 0, 0, 16, 0]);
    expect(
        () => const NativePngValidator().headerDimensions(bytes,
            limits: const NativeWriteLimits(maxTotalImagePixels: 33554432)),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.quota.image')));
  });

  test('draft unique blob refusal reports measured role and union counts',
      () async {
    final fixture =
        await LiteralTileFixture.create(maps: [LiteralFixtureMap(id: 1)]);
    final artifacts = List.generate(4, (index) => NativeArtifact(bytes: [index]));
    expect(
        () => NativeProjectDraft(
            source: fixture.source,
            projectName: 'Measured quota',
            parentPath: '/private/tmp/native-draft-budget',
            folderName: 'measured-quota',
            mapIds: const {1: 'map-one'},
            artifacts: artifacts.take(2).toList(),
            sourceArtifacts: artifacts.skip(2).toList(),
            mutations: const [],
            limits: const NativeWriteLimits(maxArtifacts: 3)),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.quota.draft')
            .having(
                (error) => error.message,
                'message',
                'Unique artifact budget exceeded: artifacts=2, '
                    'sourceArtifacts=2, derivedArtifacts=0, '
                    'uniqueArtifacts=4, maxArtifacts=3')));
  });

  test('allows an explicit bounded 512 artifact native catalogue study', () {
    const limits = NativeWriteLimits(maxArtifacts: 512);
    expect(limits.validate, returnsNormally);
    expect(limits.maxMutations, 256);
    expect(limits.maxArtifactBytes, 16777216);
    expect(limits.maxTotalArtifactBytes, 67108864);
    expect(limits.maxTotalDraftJsonBytes, 67108864);
    expect(limits.maxImagePixels, 16777216);
    expect(limits.maxMapCells, 1048576);
  });

  test('aggregate byte refusal reports both roles and the complete measured total', () async {
    final fixture = await LiteralTileFixture.create(maps: [LiteralFixtureMap(id: 1)]);
    final artifacts = [
      NativeArtifact(bytes: '{}'.codeUnits, mediaType: 'application/json'),
      NativeArtifact(bytes: '{"a":0}'.codeUnits, mediaType: 'application/json'),
    ];
    final witnesses = [NativeArtifact(bytes: '{"b":10}'.codeUnits, mediaType: 'application/json')];
    NativeProjectDraft draft(int budget) => NativeProjectDraft(
        source: fixture.source, projectName: 'Measured bytes',
        parentPath: '/private/tmp/native-byte-budget', folderName: 'measured-bytes',
        mapIds: const {1: 'map-one'}, artifacts: artifacts, sourceArtifacts: witnesses,
        mutations: const [], compositionEvidence: const {'sourceEvents': {}},
        limits: NativeWriteLimits(maxTotalArtifactBytes: budget));
    expect(() => draft(16), throwsA(isA<NativeWriteException>()
        .having((error) => error.code, 'code', 'native.quota.artifact')
        .having((error) => error.message, 'message',
            'Artifact byte budget exceeded: inferredStage=sourceEvents, '
            'artifacts=2/9 bytes, sourceArtifacts=1/8 bytes, '
            'totalBytes=17/16, largestArtifactBytes=8/16777216')));
    expect(draft(17).artifacts, hasLength(2));
  });

  test('single artifact refusal distinguishes the per-blob ceiling from the total', () async {
    final fixture = await LiteralTileFixture.create(maps: [LiteralFixtureMap(id: 1)]);
    expect(() => NativeProjectDraft(
        source: fixture.source, projectName: 'Measured blob',
        parentPath: '/private/tmp/native-byte-budget', folderName: 'measured-blob',
        mapIds: const {1: 'map-one'},
        artifacts: [NativeArtifact(bytes: '{}'.codeUnits, mediaType: 'application/json')],
        mutations: const [], limits: const NativeWriteLimits(maxArtifactBytes: 1,
            maxTotalArtifactBytes: 9)),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.quota.artifact')
            .having((error) => error.message, 'message',
                'Artifact byte budget exceeded: inferredStage=unspecified, '
                'artifacts=1/2 bytes, sourceArtifacts=0/0 bytes, '
                'totalBytes=2/9, largestArtifactBytes=2/1')));
  });

  test('allows an explicit bounded 1024 artifact multi-map catalogue study',
      () {
    const limits = NativeWriteLimits(maxArtifacts: 1024);
    expect(limits.validate, returnsNormally);
    expect(limits.maxMutations, 256);
    expect(limits.maxArtifactBytes, 16777216);
    expect(limits.maxTotalArtifactBytes, 67108864);
    expect(limits.maxTotalDraftJsonBytes, 67108864);
    expect(limits.maxImagePixels, 16777216);
    expect(limits.maxMapCells, 1048576);
  });

  test('keeps the default artifact budget small', () {
    const limits = NativeWriteLimits();
    expect(limits.maxArtifacts, 32);
    expect(limits.validate, returnsNormally);
  });

  test('large full games receive a bounded byte budget without broadening other quotas', () {
    final world = sourceCatalogStudyWriteLimitsFor(383);
    final full = sourceCatalogStudyWriteLimitsFor(383, includeNativeCatalog: true, fullGameContent: true);
    final smallFull = sourceCatalogStudyWriteLimitsFor(8, includeNativeCatalog: true, fullGameContent: true);
    expect(world.maxTotalArtifactBytes, 268435456);
    expect(smallFull.maxTotalArtifactBytes, 268435456);
    expect(full.maxTotalArtifactBytes, 536870912);
    expect(full.maxArtifactBytes, world.maxArtifactBytes);
    expect(full.maxTotalDraftJsonBytes, world.maxTotalDraftJsonBytes);
    expect(full.artifactEvidenceJsonLimits.maxTextCodeUnits,
        world.artifactEvidenceJsonLimits.maxTextCodeUnits);
    expect(full.maxImagePixels, world.maxImagePixels);
    expect(full.maxTotalImagePixels, world.maxTotalImagePixels);
    expect(full.maxArtifacts, world.maxArtifacts);
    expect(full.maxMutations, world.maxMutations);
    expect(full.validate, returnsNormally);
    expect(const NativeWriteLimits().maxTotalArtifactBytes, 67108864);
    expect(const NativeWriteLimits(maxTotalArtifactBytes: 536870913).validate,
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.invalid_limits')));
  });

  for (final scope in ConverterContentScope.values) {
    for (final count in [8, 9, 383]) {
      test('settings preserve exact byte capacity scope=${scope.name} maps=$count', () {
        final limits = ConverterStudySettings(projectName: 'Scoped capacity',
            parentPath: '/private/tmp/converter-capacity', folderName: 'scoped-capacity',
            contentScope: scope, selectedSourceMapIds: [for (var id = 1; id <= count; id++) id],
            profileAcknowledgement: SourceStudyAcknowledgement(
                sourceSnapshotHash: Sha256Hash('0' * 64),
                profileEvidenceHash: Sha256Hash('1' * 64),
                humanConfirmed: true, reason: 'Bounded full-game capacity')).writeLimits;
        expect(limits.maxTotalArtifactBytes,
            scope == ConverterContentScope.full && count > 8 ? 536870912 : 268435456);
        expect(limits.maxArtifacts, 4096);
        expect(limits.maxMutations, 32768);
        expect(limits.maxTotalDraftJsonBytes, 268435456);
        expect(limits.artifactEvidenceJsonLimits.maxTextCodeUnits, 268435456);
        expect(limits.maxImagePixels, 16777216);
        expect(limits.maxTotalImagePixels, 134217728);
      });
    }
  }

  test('allows an explicit bounded 2048 artifact whole-world study', () {
    const limits = NativeWriteLimits(maxArtifacts: 2048);
    expect(limits.validate, returnsNormally);
    expect(limits.maxMutations, 256);
    expect(limits.maxArtifactBytes, 16777216);
    expect(limits.maxTotalArtifactBytes, 67108864);
    expect(limits.maxTotalDraftJsonBytes, 67108864);
    expect(limits.maxImagePixels, 16777216);
    expect(limits.maxMapCells, 1048576);
  });

  for (final count in [-1, 0, 4097, 1000000]) {
    test('refuses an invalid artifact count $count', () {
      expect(
          NativeWriteLimits(maxArtifacts: count).validate,
          throwsA(isA<NativeWriteException>()
              .having((error) => error.code, 'code', 'native.invalid_limits')));
    });
  }
}
