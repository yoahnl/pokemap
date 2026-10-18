import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_distribution/src/deterministic_zip_encoder.dart';
import 'package:test/test.dart';

void main() {
  test(
      'successful budget report preserves raw JSON bytes and nodes with final image dimensions',
      () {
    final fixture = _fixture();
    final json = fixture.catalog.toJson();
    for (final field in [
      'elements',
      'models3d',
      'characters',
      'environmentPresets',
      'elementCategories',
      'tilesetFolders'
    ]) {
      json.remove(field);
    }
    final archive = _archiveFor(fixture, json: json, prettyJson: true);
    final inspection =
        const ResourcePackInspector().inspectSourceSync(_Source(archive));
    final report = inspection.budgetReport!;
    final raw = utf8.encode(const JsonEncoder.withIndent('  ').convert(json));
    final nodes = const CatalogBudgetCalculator()
        .measureJsonDocument(json, scope: 'raw')
        .totals['jsonNodes'];
    expect(report.totals['catalogBytes'], raw.length);
    expect(report.totals['jsonNodes'], nodes);
    expect(report.totals['files'], inspection.manifest.content.files.length);
    expect(report.totals['referencedFiles'], 1);
    expect(report.totals['imagePixels'], 256);
    expect(report.totals['rgba8BytesEstimate'], 1024);
    expect(
        report.metrics.singleWhere((m) => m.dimension == 'imageWidth').observed,
        16);
    expect(
        report.unknownDimensions,
        isNot(contains(
            '${fixture.catalog.files.single.archivePath}.imageDimensions')));
    expect(report.accepted, isTrue);
    expect(report.totals['catalogBytes'],
        isNot(CanonicalJson.encodeUtf8(inspection.catalog.toJson()).length));
  });

  test('image policy refusal includes exact width height and pixel violations',
      () async {
    final fixture = _fixture();
    final sink = _Sink();
    await _build(fixture, sink);
    final error = await _failure(() => const ResourcePackInspector(
            policy: ResourcePackSecurityPolicy(
                maxImageDimension: 15, maxImagePixels: 255))
        .inspectSourceSync(_Source(sink.bytes)));
    expect(error.code, 'resource_pack.image_limit');
    final report = error.details!['budgetReport'] as Map<String, Object?>;
    expect(_dimensions(report),
        containsAll(['imageWidth', 'imageHeight', 'imagePixels']));
    final metrics = (report['metrics'] as List).cast<Map<String, Object?>>();
    expect(
        metrics.singleWhere((m) => m['dimension'] == 'imageWidth')['observed'],
        16);
    expect(
        metrics.singleWhere((m) => m['dimension'] == 'imagePixels')['observed'],
        256);
    expect(
        metrics.singleWhere(
            (m) => m['dimension'] == 'rgba8BytesEstimate')['observed'],
        1024);
    expect(report['accepted'], isFalse);
  });

  test('successful inspection exposes immutable verified image dimensions',
      () async {
    final fixture = _fixture();
    final sink = _Sink();
    await _build(fixture, sink);
    final result =
        const ResourcePackInspector().inspectSourceSync(_Source(sink.bytes));
    final dimensions =
        result.imageDimensions[fixture.catalog.files.single.archivePath]!;
    expect(dimensions.width, 16);
    expect(dimensions.height, 16);
    expect(() => result.imageDimensions.clear(), throwsUnsupportedError);
  });

  test('cyclic hierarchy preserves legacy failfast hierarchy code', () async {
    final fixture = _fixture();
    final json = fixture.catalog.toJson();
    json['tilesetFolders'] = [
      {'id': 'a', 'name': 'A', 'parentFolderId': 'b', 'sortOrder': 0},
      {'id': 'b', 'name': 'B', 'parentFolderId': 'a', 'sortOrder': 0},
    ];
    final error = await _failure(() => const ResourcePackInspector()
        .inspectSourceSync(_Source(_archiveFor(fixture, json: json))));
    expect(error.code, 'resource_pack.hierarchy_limit');
    expect(error.details, isNull);
  });

  test('format exception keeps default contract and snapshots optional details',
      () {
    final plain = GamePackageFormatException(
        code: 'old', path: 'catalog.json', message: 'Old');
    expect(plain.details, isNull);
    expect(plain.code, 'old');
    expect(plain.path, 'catalog.json');
    expect(plain.toString(),
        'GamePackageFormatException(old at catalog.json): Old');
    final details = <String, Object?>{
      'budgetReport': {'accepted': false}
    };
    final enriched = GamePackageFormatException(
        code: 'old', path: 'catalog.json', message: 'Old', details: details);
    details.clear();
    expect(enriched.details, contains('budgetReport'));
    expect(() => enriched.details!.clear(), throwsUnsupportedError);
  });

  test('archive and manifest byte guards keep exact bounded partial reports',
      () async {
    final fixture = _fixture();
    final sink = _Sink();
    await _build(fixture, sink);
    final archiveError = await _failure(() => const ResourcePackInspector(
            policy: ResourcePackSecurityPolicy(maxArchiveBytes: 1))
        .inspectSourceSync(_Source(sink.bytes)));
    expect(archiveError.code, 'resource_pack.archive_too_large');
    final archiveReport =
        archiveError.details!['budgetReport'] as Map<String, Object?>;
    expect((archiveReport['totals'] as Map)['archiveBytes'], sink.bytes.length);
    expect(archiveReport['accepted'], isFalse);
    final manifestError = await _failure(() => const ResourcePackInspector(
            policy: ResourcePackSecurityPolicy(maxManifestBytes: 1))
        .inspectSourceSync(_Source(sink.bytes)));
    expect(manifestError.code, 'resource_pack.manifest_too_large');
    final manifestReport =
        manifestError.details!['budgetReport'] as Map<String, Object?>;
    expect((manifestReport['totals'] as Map)['manifestBytes'], greaterThan(1));
    expect(manifestReport['accepted'], isFalse);
    final builderError = await _failure(() => const ResourcePackBuilder(
            policy: ResourcePackSecurityPolicy(maxArchiveBytes: 1))
        .build(
            metadata: _metadata,
            catalog: fixture.catalog,
            tileWidth: 16,
            tileHeight: 16,
            sources: fixture.sources,
            sink: _Sink()));
    expect(builderError.code, 'resource_pack.archive_too_large');
    final builderReport =
        builderError.details!['budgetReport'] as Map<String, Object?>;
    expect((builderReport['totals'] as Map)['archiveBytes'], sink.bytes.length);
  });

  test('file and payload refusals retain all known catalog quota violations',
      () async {
    final fixture = _fixture();
    final bytes = CanonicalJson.encodeUtf8(fixture.catalog.toJson()).length;
    final pngBytes = fixture.payload.values.first.length;
    final policy = ResourcePackSecurityPolicy(
        maxResources: 1,
        maxSupports: 1,
        maxFileBytes: pngBytes - 1,
        maxTotalPayloadBytes: bytes);
    final builderError = await _failure(() =>
        ResourcePackBuilder(policy: policy).build(
            metadata: _metadata,
            catalog: fixture.catalog,
            tileWidth: 16,
            tileHeight: 16,
            sources: fixture.sources,
            sink: _Sink()));
    expect(builderError.code, 'resource_pack.file_too_large');
    expect(
        _dimensions(
            builderError.details!['budgetReport'] as Map<String, Object?>),
        containsAll(['fileBytes', 'payloadBytes', 'resources', 'supports']));
    final sink = _Sink();
    await _build(fixture, sink);
    final inspectorError = await _failure(() =>
        ResourcePackInspector(policy: policy)
            .inspectSourceSync(_Source(sink.bytes)));
    expect(inspectorError.code, 'resource_pack.file_too_large');
    expect(
        _dimensions(
            inspectorError.details!['budgetReport'] as Map<String, Object?>),
        containsAll(['fileBytes', 'payloadBytes', 'resources', 'supports']));
  });

  test(
      'manifest JSON guard carries partial refusal without inventing node count',
      () async {
    final fixture = _fixture();
    final sink = _Sink();
    await _build(fixture, sink);
    final error = await _failure(() => const ResourcePackInspector(
            policy: ResourcePackSecurityPolicy(maxJsonNodes: 1))
        .inspectSourceSync(_Source(sink.bytes)));
    expect(error.code, 'resource_pack.json_complexity');
    final report = error.details!['budgetReport'] as Map<String, Object?>;
    expect(report['accepted'], isFalse);
    expect(report['measurementComplete'], isFalse);
    expect(report['unknownDimensions'], contains('jsonNodes'));
  });

  test('catalog JSON guard carries partial refusal without claiming acceptance',
      () async {
    final fixture = _fixture();
    final sink = _Sink();
    await _build(fixture, sink);
    final nodes = const CatalogBudgetCalculator()
        .measureJsonDocument(fixture.catalog.toJson(), scope: 'catalog')
        .totals['jsonNodes']!;
    final error = await _failure(() => ResourcePackInspector(
            policy: ResourcePackSecurityPolicy(maxJsonNodes: nodes - 1))
        .inspectSourceSync(_Source(sink.bytes)));
    expect(error.code, 'resource_pack.json_complexity');
    final report = error.details!['budgetReport'] as Map<String, Object?>;
    expect(report['accepted'], isFalse);
    expect(report['measurementComplete'], isFalse);
    expect(report['unknownDimensions'], contains('jsonNodes'));
  });

  test(
      'builder keeps legacy refusal and includes all simultaneously exceeded budgets',
      () async {
    final fixture = _fixture();
    final sink = _Sink();
    final error = await _failure(() => const ResourcePackBuilder(
            policy: ResourcePackSecurityPolicy(maxResources: 1, maxSupports: 1))
        .build(
            metadata: _metadata,
            catalog: fixture.catalog,
            tileWidth: 16,
            tileHeight: 16,
            sources: fixture.sources,
            sink: sink));
    expect(error.code, 'resource_pack.resource_limit');
    final report = error.details!['budgetReport'] as Map<String, Object?>;
    expect(_dimensions(report), containsAll(['resources', 'supports']));
    expect(
        CanonicalJson.encodeUtf8(report).length, lessThanOrEqualTo(96 * 1024));
    expect(sink.aborted, isTrue);
    expect(sink.bytes, isEmpty);
    expect(fixture.opens, isEmpty);
  });

  test('inspector keeps legacy code and includes resources plus supports',
      () async {
    final fixture = _fixture();
    final sink = _Sink();
    await _build(fixture, sink);
    final error = await _failure(() => const ResourcePackInspector(
            policy: ResourcePackSecurityPolicy(maxResources: 1, maxSupports: 1))
        .inspectSourceSync(_Source(sink.bytes)));
    expect(error.code, 'resource_pack.resource_limit');
    expect(_dimensions(error.details!['budgetReport'] as Map<String, Object?>),
        containsAll(['resources', 'supports']));
  });

  test(
      'preparse catalog bytes refusal reports exact size and unknown parsed dimensions',
      () async {
    final fixture = _fixture();
    final sink = _Sink();
    await _build(fixture, sink);
    final bytes = CanonicalJson.encodeUtf8(fixture.catalog.toJson()).length;
    final error = await _failure(() => ResourcePackInspector(
            policy: ResourcePackSecurityPolicy(maxCatalogBytes: bytes - 1))
        .inspectSourceSync(_Source(sink.bytes)));
    expect(error.code, 'resource_pack.catalog_too_large');
    final report = error.details!['budgetReport'] as Map<String, Object?>;
    final metrics = (report['metrics'] as List).cast<Map<String, Object?>>();
    final metric = metrics.singleWhere((e) => e['dimension'] == 'catalogBytes');
    expect(metric['observed'], bytes);
    expect(metric['allowed'], bytes - 1);
    expect(report['measurementComplete'], isFalse);
    expect(report['unknownDimensions'],
        containsAll(['jsonNodes', 'jsonDepth', 'resources', 'supports']));
  });

  test('integrity failure keeps failfast code and has no budget details',
      () async {
    final fixture = _fixture();
    final archive = _archiveFor(fixture, rawSha256: 'a' * 64);
    final error = await _failure(() =>
        const ResourcePackInspector().inspectSourceSync(_Source(archive)));
    expect(error.code, 'resource_pack.hash_mismatch');
    expect(error.details, isNull);
  });
}

Uint8List _archiveFor(_Fixture fixture,
    {Map<String, Object?>? json, String? rawSha256, bool prettyJson = false}) {
  final catalog = prettyJson
      ? Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ')
          .convert(json ?? fixture.catalog.toJson())))
      : CanonicalJson.encodeUtf8(json ?? fixture.catalog.toJson());
  final file = ResourcePackInventoryFile(
      path: 'catalog.json',
      byteLength: catalog.length,
      mediaType: 'application/json',
      rawSha256: rawSha256 ?? sha256.convert(catalog).toString());
  final inventory = fixture.sources.map((s) => s.inventory).toList();
  final manifest = ResourcePackManifest(
      pack: _metadata,
      compatibility: ResourcePackCompatibility(
          tileWidth: 16,
          tileHeight: 16,
          smartTileCatalogVersion: ProjectSmartTileCatalog.currentFormatVersion,
          borderCatalogVersion:
              ProjectBorderCatalog.latestSupportedFormatVersion,
          resourceLibraryCatalogVersion:
              ResourceLibraryCatalog.currentFormatVersion,
          requiredCapabilities:
              ResourcePackCapabilities.requiredFor(fixture.catalog, inventory)),
      content: ResourcePackContent(
          catalog: file,
          files: inventory,
          treeSha256: resourcePackTreeSha256(file, inventory)));
  return DeterministicZipEncoder.encode([
    MapEntry('catalog.json', catalog),
    MapEntry('manifest.json',
        const ResourcePackManifestCodec().encodeUtf8(manifest)),
    ...fixture.payload.entries,
  ]..sort((a, b) => a.key.compareTo(b.key)));
}

List<String> _dimensions(Map<String, Object?> report) => [
      for (final value in report['violations'] as List)
        (value as Map)['dimension'] as String,
    ];

Future<GamePackageFormatException> _failure(
    FutureOr<Object?> Function() action) async {
  try {
    await action();
  } on GamePackageFormatException catch (error) {
    return error;
  }
  throw StateError('Expected refusal');
}

Future<void> _build(_Fixture fixture, _Sink sink) => ResourcePackBuilder()
    .build(
        metadata: _metadata,
        catalog: fixture.catalog,
        tileWidth: 16,
        tileHeight: 16,
        sources: fixture.sources,
        sink: sink)
    .then((_) {});

_Fixture _fixture() {
  final png = img.encodePng(img.Image(width: 16, height: 16, numChannels: 4));
  final license = utf8.encode('Original admission test asset');
  final pngHash = sha256.convert(png).toString();
  final licensePath = 'licenses/${sha256.convert(license)}.txt';
  final path = 'blobs/$pngHash.png';
  final catalog = ResourcePackCatalog(
      tilesets: [
        for (final id in ['first', 'second'])
          ProjectTilesetEntry(
              id: id,
              name: id,
              relativePath: 'assets/source.png',
              source: ProjectTilesetSource.regularAtlas(
                  assetId: 'image',
                  pixelWidth: 16,
                  pixelHeight: 16,
                  tileWidth: 16,
                  tileHeight: 16)),
      ],
      smartTileCatalog: ProjectSmartTileCatalog(categories: const [
        ProjectSmartTileCategory(id: 'first', name: 'First'),
        ProjectSmartTileCategory(id: 'second', name: 'Second'),
      ]),
      files: [
        ResourcePackFileBinding(
            id: 'image',
            logicalPath: 'assets/source.png',
            archivePath: path,
            byteLength: png.length,
            mediaType: 'image/png',
            rawSha256: pngHash,
            provenanceId: 'author',
            licenseIds: [licensePath])
      ],
      provenance: [
        ResourcePackProvenance(id: 'author', author: 'Tests', licenseIds: [
          licensePath
        ], resources: [
          for (final id in ['first', 'second'])
            ResourcePackRef(kind: ResourcePackKind.tileset, id: id)
        ])
      ]);
  return _Fixture(catalog, {path: png, licensePath: license});
}

final _metadata = ResourcePackMetadata(
    id: 'budget.admission',
    version: '1.0.0',
    name: 'Admission fixture',
    description: '',
    universeId: 'original',
    authors: ['Tests'],
    provenance: 'Original test assets');

final class _Fixture {
  _Fixture(this.catalog, this.payload);
  final ResourcePackCatalog catalog;
  final Map<String, List<int>> payload;
  final opens = <String>[];
  List<ResourcePackBuildSource> get sources => [
        for (final entry in payload.entries)
          ResourcePackBuildSource(
              path: entry.key,
              byteLength: entry.value.length,
              rawSha256: sha256.convert(entry.value).toString(),
              mediaType:
                  entry.key.endsWith('.png') ? 'image/png' : 'text/plain',
              openRead: () {
                opens.add(entry.key);
                return Stream.value(entry.value);
              })
      ];
}

final class _Sink implements ResourcePackArchiveSink {
  final bytes = <int>[];
  bool aborted = false;
  @override
  Future<void> write(Uint8List chunk) async {
    bytes.addAll(chunk);
  }

  @override
  Future<void> finish() async {}
  @override
  Future<void> abort() async {
    aborted = true;
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
