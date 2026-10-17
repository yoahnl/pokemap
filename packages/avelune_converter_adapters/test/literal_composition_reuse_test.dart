import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';

const _maximums = {
  'maxArtifacts': 1024,
  'maxMutations': 2048,
  'maxArtifactBytes': 67108864,
  'maxTotalArtifactBytes': 268435456,
  'maxTotalDraftJsonBytes': 268435456,
  'maxImagePixels': 16777216,
  'maxTotalImagePixels': 33554432,
  'maxMapCells': 4194304,
  'maxDepth': 64,
  'maxNodes': 4000000,
  'maxStringCodeUnits': 1048576,
  'maxTextCodeUnits': 16777216,
};

NativeWriteLimits _limits([Map<String, int> changes = const {}]) {
  final values = {..._maximums, ...changes};
  return NativeWriteLimits(
      maxArtifacts: values['maxArtifacts']!,
      maxMutations: values['maxMutations']!,
      maxArtifactBytes: values['maxArtifactBytes']!,
      maxTotalArtifactBytes: values['maxTotalArtifactBytes']!,
      maxTotalDraftJsonBytes: values['maxTotalDraftJsonBytes']!,
      maxImagePixels: values['maxImagePixels']!,
      maxTotalImagePixels: values['maxTotalImagePixels']!,
      maxMapCells: values['maxMapCells']!,
      jsonLimits: ContractLimits(
          maxDepth: values['maxDepth']!,
          maxNodes: values['maxNodes']!,
          maxStringCodeUnits: values['maxStringCodeUnits']!,
          maxTextCodeUnits: values['maxTextCodeUnits']!));
}

Future<LiteralTileComposition> _compose(LiteralTileFixture fixture,
        {NativeWriteLimits limits = const NativeWriteLimits()}) =>
    const LiteralTileComposer().compose(
        source: fixture.source,
        files: fixture.files,
        selectedSourceMapIds: [1],
        projectName: 'Original reuse fixture',
        parentPath: '/private/tmp/original-reuse-output',
        folderName: 'original-reuse-project',
        limits: limits);

void main() {
  late LiteralTileFixture fixture;
  late LiteralTileComposition base;

  setUpAll(() async {
    fixture = await LiteralTileFixture.create();
    base = await _compose(fixture, limits: _limits());
    expect(base.canWrite, isTrue);
  });

  setUp(() {
    fixture.files.reads.clear();
    fixture.files.overrides.clear();
    fixture.files.onRead = null;
  });

  test('equal limits verify fresh witnesses and retain the sealed composition',
      () async {
    final recording = SourceSemanticWitnessFiles(
        fixture.snapshot, fixture.files, _limits(), null);
    expect(
        await base.verifyForReuse(
            source: fixture.source, files: recording, limits: _limits()),
        same(base));
    expect(fixture.files.reads, hasLength(1));
    final atlas = fixture.snapshot.entries.singleWhere((entry) =>
        entry.relativePath == 'Graphics/Tilesets/OriginalAtlas1.png');
    expect(fixture.files.reads.single, atlas.fileId);
    expect(recording.evidence.single['rawSha256'], atlas.sha256!.value);
    expect(recording.artifacts.values.single.rawSha256, atlas.sha256);
  });

  test('looser limits retain the original composition', () async {
    final tighter = await _compose(fixture);
    expect(
        await tighter.verifyForReuse(
            source: fixture.source, files: fixture.files, limits: _limits()),
        same(tighter));
  });

  test('equivalent normalized instances are accepted by their bound identity',
      () async {
    final equivalent = await LiteralTileFixture.create();
    expect(equivalent.source, isNot(same(fixture.source)));
    expect(
        await base.verifyForReuse(
            source: equivalent.source,
            files: equivalent.files,
            limits: _limits()),
        same(base));
  });

  for (final entry in _maximums.entries) {
    test('stricter ${entry.key} requests exact literal replay', () async {
      expect(
          await base.verifyForReuse(
              source: fixture.source,
              files: fixture.files,
              limits: _limits({entry.key: entry.value - 1})),
          isNull);
      expect(fixture.files.reads, isEmpty);
    });
  }

  test('changed normalized source cannot reuse the sealed composition',
      () async {
    final changed = await LiteralTileFixture.create(
        maps: [LiteralFixtureMap(id: 1, name: 'Changed source name')]);
    changed.files.reads.clear();
    await expectLater(
        base.verifyForReuse(
            source: changed.source, files: changed.files, limits: _limits()),
        throwsA(isA<NativeWriteException>().having(
            (error) => error.code, 'code', 'semantics.literal.changed')));
    expect(changed.files.reads, isEmpty);
  });

  test('changed atlas is rejected even through a plain source port', () async {
    fixture.files.overrides['Graphics/Tilesets/OriginalAtlas1.png'] =
        literalFixtureAtlas(alternate: true);
    await expectLater(
        base.verifyForReuse(
            source: fixture.source, files: fixture.files, limits: _limits()),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'literal.source.changed')));
  });

  test('cancellation before or during source verification prevents reuse',
      () async {
    final early = ScanCancellation()..cancel();
    await expectLater(
        base.verifyForReuse(
            source: fixture.source,
            files: fixture.files,
            limits: _limits(),
            cancellation: early),
        throwsA(isA<ContractError>()
            .having((error) => error.code, 'code', 'source.cancelled')));
    expect(fixture.files.reads, isEmpty);
    final active = ScanCancellation();
    fixture.files.onRead = (_) => active.cancel();
    await expectLater(
        base.verifyForReuse(
            source: fixture.source,
            files: fixture.files,
            limits: _limits(),
            cancellation: active),
        throwsA(isA<ContractError>()
            .having((error) => error.code, 'code', 'source.cancelled')));
    expect(fixture.files.reads, hasLength(1));
  });
}
