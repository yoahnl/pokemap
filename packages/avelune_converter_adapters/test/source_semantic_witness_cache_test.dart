import 'dart:convert';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';

void main() {
  test('cached witness owns bytes returned directly by a mutable source port',
      () async {
    final original = List.generate(1024, (index) => index % 251);
    final fixture = await LiteralTileFixture.create(scriptsBytes: original);
    final entry = fixture.source.snapshot.entries
        .singleWhere((entry) => entry.relativePath == 'Data/Scripts.rxdata');
    final direct =
        _DirectMutableSourceFiles(entry.fileId, Uint8List.fromList(original));
    final witnesses = SourceSemanticWitnessFiles(
        fixture.source.snapshot, direct, const NativeWriteLimits(), null);

    final retained = await witnesses.read(entry.fileId);
    direct.bytes[0] ^= 1;

    expect(retained, original);
    expect(await witnesses.read(entry.fileId), same(retained));
    expect(retained, isA<Uint8List>());
    expect(() => retained[0] = 7, throwsUnsupportedError);
    expect(direct.reads, 1);
    final evidence = witnesses.evidence.single;
    expect(evidence['rawSha256'], entry.sha256!.value);
    final restored = <int>[];
    for (final chunk in evidence['chunks'] as List) {
      final artifact = witnesses.artifacts[chunk['artifactHandle']]!;
      final payload = jsonDecode(utf8.decode(artifact.bytes)) as Map;
      restored.addAll(base64Decode(payload['bytesBase64'] as String));
    }
    expect(restored, original);
    expect(literalFixtureHash(restored), entry.sha256);
  });

  test('cumulative witness quota rejects the next file before source reading',
      () async {
    final fixture = await LiteralTileFixture.create(
        scriptsBytes: List.filled(1024, 17),
        extraFiles: {'Data/SharedEvidence.bin': List.filled(1024, 29)});
    final first = fixture.source.snapshot.entries
        .singleWhere((entry) => entry.relativePath == 'Data/Scripts.rxdata');
    final second = fixture.source.snapshot.entries.singleWhere(
        (entry) => entry.relativePath == 'Data/SharedEvidence.bin');
    final witnesses = SourceSemanticWitnessFiles(
        fixture.source.snapshot,
        fixture.files,
        const NativeWriteLimits(
            maxArtifacts: 2,
            maxArtifactBytes: 2048,
            maxTotalArtifactBytes: 2500),
        null);

    expect(await witnesses.read(first.fileId),
        fixture.sourceBytes[first.relativePath]);
    final evidence = witnesses.evidence;
    final artifactHandles = witnesses.artifacts.keys.toSet();
    await expectLater(
        witnesses.read(second.fileId),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'semantics.witness.quota')));

    expect(fixture.files.reads, [first.fileId]);
    expect(witnesses.evidence, evidence);
    expect(witnesses.artifacts.keys.toSet(), artifactHandles);
    expect(await witnesses.read(first.fileId),
        fixture.sourceBytes[first.relativePath]);
    expect(fixture.files.reads, [first.fileId]);
  });

  test('a fresh witness scope revalidates changed bytes after a cached read',
      () async {
    final fixture = await LiteralTileFixture.create(
        scriptsBytes: List.generate(1024, (index) => index % 251));
    final entry = fixture.source.snapshot.entries
        .singleWhere((entry) => entry.relativePath == 'Data/Scripts.rxdata');
    final original = fixture.sourceBytes[entry.relativePath]!;
    final first = SourceSemanticWitnessFiles(fixture.source.snapshot,
        fixture.files, const NativeWriteLimits(), null);

    expect(await first.read(entry.fileId), original);
    fixture.files.overrides[entry.relativePath] = original.toList()..[0] ^= 1;
    expect(await first.read(entry.fileId), original);
    expect(fixture.files.reads, [entry.fileId]);

    final fresh = SourceSemanticWitnessFiles(fixture.source.snapshot,
        fixture.files, const NativeWriteLimits(), null);
    await expectLater(
        fresh.read(entry.fileId),
        throwsA(isA<NativeWriteException>().having(
            (error) => error.code, 'code', 'semantics.witness.changed')));

    expect(fixture.files.reads, [entry.fileId, entry.fileId]);
    expect(fresh.evidence, isEmpty);
    expect(fresh.artifacts, isEmpty);
  });

  test('cancellation is checked before returning an already cached witness',
      () async {
    final fixture =
        await LiteralTileFixture.create(scriptsBytes: List.filled(1024, 37));
    final entry = fixture.source.snapshot.entries
        .singleWhere((entry) => entry.relativePath == 'Data/Scripts.rxdata');
    final cancellation = ScanCancellation();
    final witnesses = SourceSemanticWitnessFiles(fixture.source.snapshot,
        fixture.files, const NativeWriteLimits(), cancellation);

    expect(await witnesses.read(entry.fileId),
        fixture.sourceBytes[entry.relativePath]);
    final evidence = witnesses.evidence;
    final artifactHandles = witnesses.artifacts.keys.toSet();
    cancellation.cancel();
    await expectLater(
        witnesses.read(entry.fileId),
        throwsA(isA<ContractError>()
            .having((error) => error.code, 'code', 'source.cancelled')));

    expect(fixture.files.reads, [entry.fileId]);
    expect(witnesses.evidence, evidence);
    expect(witnesses.artifacts.keys.toSet(), artifactHandles);
  });
}

final class _DirectMutableSourceFiles implements SourceFilePort {
  _DirectMutableSourceFiles(this.fileId, this.bytes);

  final ConverterId fileId;
  final Uint8List bytes;
  var reads = 0;

  @override
  Future<List<int>> read(ConverterId requested) async {
    if (requested != fileId) throw StateError('Unexpected source file');
    reads++;
    return bytes;
  }
}
