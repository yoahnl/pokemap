import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_distribution/src/deterministic_zip_encoder.dart';
import 'package:test/test.dart';

void main() {
  test('publishes only a v2 descriptor with exact reachable catalog objects',
      () async {
    final sink = _Sink();
    final result = await ResourcePackBuilder().build(
        metadata: _metadata,
        catalog: ResourcePackCatalog(),
        tileWidth: 16,
        tileHeight: 16,
        sources: [],
        sink: sink);
    final archive = ZipDecoder().decodeBytes(sink.bytes);
    final descriptor = jsonDecode(
            utf8.decode(archive.findFile('catalog.json')!.content as List<int>))
        as Map<String, dynamic>;
    expect(descriptor['format'], 'avelune.portable-catalog');
    expect(descriptor['version'], 2);
    expect(result.manifest.toJson()['formatVersion'], 2);
    final read = PortableCatalogPublication.readSync(descriptor,
        readObject: (ref) => archive
            .findFile(PortableCatalogPublication.objectPath(ref))!
            .content as List<int>);
    expect(
        result.manifest.content.files.map((f) => f.path).toSet(),
        read.objectReferences
            .map(PortableCatalogPublication.objectPath)
            .toSet());
    final inspection =
        ResourcePackInspector().inspectSourceSync(_Source(sink.bytes));
    expect(inspection.catalog.toJson(), ResourcePackCatalog().toJson());
  });

  test('counts descriptor root indexes and units in physical and value quotas',
      () async {
    final catalog = ResourcePackCatalog();
    final report = CatalogBudgetCalculator().measureResourcePack(catalog);
    final bytes = report.totals['catalogBytes']!;
    final values = report.totals['jsonNodes']!;
    final exact = ResourcePackSecurityPolicy(
        maxCatalogBytes: bytes, maxJsonNodes: values);
    final sink = _Sink();
    await ResourcePackBuilder(policy: exact).build(
        metadata: _metadata,
        catalog: catalog,
        tileWidth: 16,
        tileHeight: 16,
        sources: [],
        sink: sink);
    expect(
        ResourcePackInspector(policy: exact)
            .inspectSourceSync(_Source(sink.bytes))
            .payloadBytes,
        bytes);
    for (final policy in [
      ResourcePackSecurityPolicy(maxCatalogBytes: bytes - 1),
      ResourcePackSecurityPolicy(maxJsonNodes: values - 1)
    ]) {
      final rejected = _Sink();
      await expectLater(
          ResourcePackBuilder(policy: policy).build(
              metadata: _metadata,
              catalog: catalog,
              tileWidth: 16,
              tileHeight: 16,
              sources: [],
              sink: rejected),
          throwsA(isA<GamePackageFormatException>()));
      expect(rejected.bytes, isEmpty);
      expect(rejected.aborted, isTrue);
      expect(
          () => ResourcePackInspector(policy: policy)
              .inspectSourceSync(_Source(sink.bytes)),
          throwsA(isA<GamePackageFormatException>()));
    }
  });

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
    final publication = PortableCatalogPublication.encodeCatalog(catalog);
    final expected = DeterministicZipEncoder.encode([
      ...publication.storage.objects.entries
          .map((e) => MapEntry('catalog/objects/${e.key}.json', e.value)),
      MapEntry(
          'catalog.json', CanonicalJson.encodeUtf8(publication.descriptor)),
      MapEntry(
          'manifest.json', ResourcePackManifestCodec().encodeUtf8(a.manifest)),
    ]..sort((a, b) => PackagePathPolicy.compareUtf8(a.key, b.key)));
    expect(first.bytes, expected);
    expect(
        ResourcePackInspector()
            .inspectSourceSync(_Source(first.bytes))
            .archiveRawSha256,
        a.archiveRawSha256);
    expect(first.finished, isTrue);
    expect(first.aborted, isFalse);
  });

  test(
      'rejects useful payload one byte below catalog plus sources before opening sources',
      () async {
    final fixture = await _payloadFixture();
    final catalogBytes = CatalogBudgetCalculator()
        .measureResourcePack(fixture.catalog)
        .totals['catalogBytes']!;
    final sourceBytes =
        fixture.sources.fold<int>(0, (sum, source) => sum + source.byteLength);
    final exactBytes = catalogBytes + sourceBytes;
    final sink = _Sink();
    GamePackageFormatException? failure;
    try {
      await ResourcePackBuilder(
              policy: ResourcePackSecurityPolicy(
                  maxTotalPayloadBytes: exactBytes - 1))
          .build(
              metadata: _metadata,
              catalog: fixture.catalog,
              tileWidth: 16,
              tileHeight: 16,
              sources: fixture.sources,
              sink: sink);
    } on GamePackageFormatException catch (error) {
      failure = error;
    }
    print(jsonEncode({
      'case': 'useful-payload-minus-one',
      'catalogBytes': catalogBytes,
      'sourceBytes': sourceBytes,
      'exactBytes': exactBytes,
      'limitBytes': exactBytes - 1,
      'sourceOpens': fixture.openedPaths.length,
      'sinkWrites': sink.writes,
      'sinkFinished': sink.finished,
      'sinkAborted': sink.aborted,
      'errorCode': failure?.code
    }));
    expect(
        failure,
        isA<GamePackageFormatException>().having(
            (error) => error.code, 'code', 'resource_pack.payload_too_large'));
    expect(fixture.openedPaths, isEmpty);
    expect(sink.writes, 0);
    expect(sink.bytes, isEmpty);
    expect(sink.finished, isFalse);
    expect(sink.aborted, isTrue);
  });

  test(
      'accepts useful payload exactly at catalog plus sources with official inspection',
      () async {
    final fixture = await _payloadFixture();
    final catalogBytes = CatalogBudgetCalculator()
        .measureResourcePack(fixture.catalog)
        .totals['catalogBytes']!;
    final sourceBytes =
        fixture.sources.fold<int>(0, (sum, source) => sum + source.byteLength);
    final exactBytes = catalogBytes + sourceBytes;
    final policy = ResourcePackSecurityPolicy(maxTotalPayloadBytes: exactBytes);
    final sink = _Sink();
    final result = await ResourcePackBuilder(policy: policy).build(
        metadata: _metadata,
        catalog: fixture.catalog,
        tileWidth: 16,
        tileHeight: 16,
        sources: fixture.sources,
        sink: sink);
    final inspection = ResourcePackInspector(policy: policy)
        .inspectSourceSync(_Source(sink.bytes));
    expect(inspection.payloadBytes, exactBytes);
    expect(inspection.resourceCount, 1);
    expect(inspection.catalog.files.single.rawSha256,
        fixture.catalog.files.single.rawSha256);
    expect(
        result.manifest.content.catalog.byteLength,
        CanonicalJson.encodeUtf8(
                PortableCatalogPublication.encodeCatalog(fixture.catalog)
                    .descriptor)
            .length);
    expect(result.archiveBytes, sink.bytes.length);
    expect(inspection.archiveRawSha256, result.archiveRawSha256);
    expect(fixture.openedPaths, hasLength(fixture.sources.length * 2));
    for (final source in fixture.sources) {
      expect(fixture.openedPaths.where((path) => path == source.path),
          hasLength(2));
    }
    expect(sink.writes, greaterThan(0));
    expect(sink.finished, isTrue);
    expect(sink.aborted, isFalse);
    print(jsonEncode({
      'case': 'useful-payload-exact',
      'catalogBytes': catalogBytes,
      'sourceBytes': sourceBytes,
      'exactBytes': exactBytes,
      'limitBytes': exactBytes,
      'sourceOpens': fixture.openedPaths.length,
      'sinkFinished': sink.finished,
      'sinkAborted': sink.aborted,
      'inspectedPayloadBytes': inspection.payloadBytes,
      'archiveBytes': result.archiveBytes,
      'archiveRawSha256': result.archiveRawSha256
    }));
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

Future<
    ({
      ResourcePackCatalog catalog,
      List<ResourcePackBuildSource> sources,
      List<String> openedPaths
    })> _payloadFixture() async {
  final directory =
      await Directory.systemTemp.createTemp('resource-pack-payload-');
  addTearDown(() => directory.delete(recursive: true));
  final image = img.Image(width: 16, height: 16, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(37, 91, 143, 255));
  image.setPixelRgba(7, 11, 241, 51, 82, 255);
  final png = img.encodePng(image);
  final pngHash = sha256.convert(png).toString();
  final license = utf8.encode('Original boundary fixture licence é😀.');
  final licenseHash = sha256.convert(license).toString();
  final imagePath = 'blobs/$pngHash.png';
  final licensePath = 'licenses/$licenseHash.txt';
  final catalog = ResourcePackCatalog(tilesets: [
    ProjectTilesetEntry(
        id: 'atlas',
        name: 'Original boundary atlas',
        relativePath: 'assets/original.png',
        source: ProjectTilesetSource.regularAtlas(
            assetId: 'image',
            pixelWidth: 16,
            pixelHeight: 16,
            tileWidth: 16,
            tileHeight: 16))
  ], files: [
    ResourcePackFileBinding(
        id: 'image',
        logicalPath: 'assets/original.png',
        archivePath: imagePath,
        rawSha256: pngHash,
        byteLength: png.length,
        mediaType: 'image/png',
        provenanceId: 'author',
        licenseIds: [licensePath])
  ], provenance: [
    ResourcePackProvenance(
        id: 'author',
        author: 'Original boundary author',
        licenseIds: [
          licensePath
        ],
        resources: [
          ResourcePackRef(kind: ResourcePackKind.tileset, id: 'atlas')
        ])
  ]);
  final openedPaths = <String>[];
  final sources = <ResourcePackBuildSource>[];
  for (final entry in {imagePath: png, licensePath: license}.entries) {
    final file = File('${directory.path}/${entry.key}');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(entry.value);
    sources.add(ResourcePackBuildSource(
        path: entry.key,
        byteLength: entry.value.length,
        rawSha256: sha256.convert(entry.value).toString(),
        mediaType: entry.key == imagePath ? 'image/png' : 'text/plain',
        openRead: () {
          openedPaths.add(entry.key);
          return file.openRead();
        }));
  }
  return (catalog: catalog, sources: sources, openedPaths: openedPaths);
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
