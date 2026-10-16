import 'dart:async';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_distribution/src/deterministic_zip_encoder.dart';
import 'package:test/test.dart';

void main() {
  test('streams the exact deterministic ZIP profile with backpressure',
      () async {
    final catalog = ResourcePackCatalog();
    final first = _Sink();
    final second = _Sink();
    final builder = ResourcePackBuilder();
    final a = await builder.build(
        metadata: _metadata,
        catalog: catalog,
        tileWidth: 16,
        tileHeight: 16,
        sources: [],
        sink: first);
    final b = await builder.build(
        metadata: _metadata,
        catalog: catalog,
        tileWidth: 16,
        tileHeight: 16,
        sources: [],
        sink: second);
    expect(first.bytes, second.bytes);
    expect(a.archiveRawSha256, b.archiveRawSha256);
    expect(a.archiveBytes, first.bytes.length);
    final expected = DeterministicZipEncoder.encode([
      MapEntry('catalog.json', CanonicalJson.encodeUtf8(catalog.toJson())),
      MapEntry(
          'manifest.json', ResourcePackManifestCodec().encodeUtf8(a.manifest)),
    ]);
    expect(first.bytes, expected);
    expect(
        ResourcePackInspector()
            .inspectSourceSync(_Source(first.bytes))
            .archiveRawSha256,
        a.archiveRawSha256);
    expect(first.finished, isTrue);
    expect(first.aborted, isFalse);
  });

  test('reads each source twice and refuses mutation before publication',
      () async {
    final original = Uint8List.fromList([1, 2, 3]);
    final digest = sha256.convert(original).toString();
    var reads = 0;
    final sink = _Sink();
    final file = ResourcePackBuildSource(
        path: 'licenses/$digest.txt',
        byteLength: 3,
        rawSha256: digest,
        mediaType: 'text/plain',
        openRead: () {
          reads++;
          return Stream.value(reads == 1 ? original : [3, 2, 1]);
        });
    await expectLater(
        ResourcePackBuilder().build(
            metadata: _metadata,
            catalog: ResourcePackCatalog(),
            tileWidth: 16,
            tileHeight: 16,
            sources: [file],
            sink: sink),
        throwsA(isA<GamePackageFormatException>()
            .having((e) => e.code, 'code', 'resource_pack.source_changed')));
    expect(reads, 2);
    expect(sink.aborted, isTrue);
    expect(sink.bytes, isEmpty);
    expect(sink.finished, isFalse);
  });

  test('rejects quotas from descriptors without opening virtual large files',
      () async {
    var opened = false;
    final sink = _Sink();
    final digest = 'a' * 64;
    await expectLater(
        ResourcePackBuilder(policy: ResourcePackSecurityPolicy(maxFileBytes: 4))
            .build(
                metadata: _metadata,
                catalog: ResourcePackCatalog(),
                tileWidth: 16,
                tileHeight: 16,
                sources: [
                  ResourcePackBuildSource(
                      path: 'licenses/$digest.txt',
                      byteLength: 5,
                      rawSha256: digest,
                      mediaType: 'text/plain',
                      openRead: () {
                        opened = true;
                        return Stream.empty();
                      })
                ],
                sink: sink),
        throwsA(isA<GamePackageFormatException>()));
    expect(opened, isFalse);
    expect(sink.aborted, isTrue);
  });

  test('aborts a failed sink and never finishes it', () async {
    final sink = _Sink(failAt: 2);
    await expectLater(
        ResourcePackBuilder().build(
            metadata: _metadata,
            catalog: ResourcePackCatalog(),
            tileWidth: 16,
            tileHeight: 16,
            sources: [],
            sink: sink),
        throwsStateError);
    expect(sink.aborted, isTrue);
    expect(sink.finished, isFalse);
  });

  test('sorts sources by UTF8 and caps every sink write and input chunk',
      () async {
    final data = Uint8List.fromList(List.generate(23, (i) => i));
    final digest = sha256.convert(data).toString();
    final sink = _Sink();
    var opens = 0;
    await ResourcePackBuilder(
            policy: ResourcePackSecurityPolicy(maxChunkBytes: 7))
        .build(
            metadata: _metadata,
            catalog: ResourcePackCatalog(),
            tileWidth: 16,
            tileHeight: 16,
            sources: [
              ResourcePackBuildSource(
                  path: 'licenses/$digest.txt',
                  byteLength: data.length,
                  rawSha256: digest,
                  mediaType: 'text/plain',
                  openRead: () {
                    opens++;
                    return Stream.fromIterable([
                      data.sublist(0, 7),
                      data.sublist(7, 14),
                      data.sublist(14, 21),
                      data.sublist(21)
                    ]);
                  })
            ],
            sink: sink);
    expect(opens, 2);
    expect(sink.maximumWrite, lessThanOrEqualTo(7));
  });
}

final _metadata = ResourcePackMetadata(
    id: 'original.fixture',
    version: '1.0.0',
    name: 'Original fixture',
    description: '',
    universeId: 'original',
    authors: ['Avelune tests'],
    provenance: 'Original test assets');

final class _Sink implements ResourcePackArchiveSink {
  _Sink({this.failAt});
  final int? failAt;
  final List<int> bytes = [];
  bool finished = false;
  bool aborted = false;
  bool writing = false;
  int writes = 0;
  int maximumWrite = 0;
  @override
  Future<void> write(Uint8List chunk) async {
    if (writing) throw StateError('Concurrent write violates backpressure');
    writing = true;
    await Future<void>.delayed(Duration.zero);
    writes++;
    if (writes == failAt) throw StateError('Injected sink failure');
    if (chunk.length > maximumWrite) maximumWrite = chunk.length;
    bytes.addAll(chunk);
    writing = false;
  }

  @override
  Future<void> finish() async {
    finished = true;
  }

  @override
  Future<void> abort() async {
    aborted = true;
    bytes.clear();
  }
}

final class _Source implements RandomAccessPackageSource {
  _Source(List<int> bytes) : bytes = Uint8List.fromList(bytes);
  final Uint8List bytes;
  @override
  int get length => bytes.length;
  @override
  Uint8List readAtSync(int offset, int length) =>
      Uint8List.sublistView(bytes, offset, offset + length);
}
