import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
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

  for (final pixels in [-1, 0, 41943041, 1000000000]) {
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
