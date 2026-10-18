import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

void main() {
  test(
      'resource file total counts physical inventory independently from graph files',
      () {
    final catalog = ResourcePackCatalog();
    final report = const CatalogBudgetCalculator()
        .measureResourcePack(catalog, files: const [
      CatalogBudgetFile(path: 'licenses/a.txt', byteLength: 3),
      CatalogBudgetFile(
          path: 'previews/a.png', byteLength: 4, imageWidth: 1, imageHeight: 1)
    ]);
    expect(report.totals['files'], 2 + report.totals['catalogObjects']!);
    expect(report.totals['referencedFiles'], 0);
    expect(report.totals['zipEntries'], 4 + report.totals['catalogObjects']!);
  });

  test('minimal bounded summary handles long Unicode scopes within exact bytes',
      () {
    final report = CatalogBudgetReport(scope: '漢' * 1000, metrics: [
      CatalogBudgetMetric(
          scope: 'asset',
          dimension: 'bytes',
          observed: 2,
          allowed: 1,
          unit: 'octets',
          label: 'A' * 10000,
          remedy: 'B' * 10000)
    ]);
    final bounded = report.toBoundedJson(maximumBytes: 512);
    expect(CanonicalJson.encodeUtf8(bounded).length, lessThanOrEqualTo(512));
    expect(bounded['metricCount'], 1);
    expect(bounded['violationCount'], 1);
  });

  test('bounded JSON retains exact report when it fits', () {
    final report = const CatalogBudgetCalculator().measureProjectJson({});
    expect(report.toBoundedJson(), report.toJson());
  });

  test(
      'bounded JSON aggregates 20000 individual violations without summing quotas',
      () {
    final files = List.generate(
        20000,
        (i) => CatalogBudgetFile(
            path: 'assets/file_$i.bin', byteLength: i == 42 ? 9 : 5));
    const calculator = CatalogBudgetCalculator(
        gamePackagePolicy: GamePackageSecurityPolicy(maxFileBytes: 4));
    final report = calculator.measureProjectJson({}, files: files);
    final bounded = report.toBoundedJson();
    expect(CanonicalJson.encodeUtf8(bounded).length,
        lessThanOrEqualTo(200 * 1024));
    expect(bounded['truncated'], isTrue);
    expect(bounded['metricCount'], report.metrics.length);
    expect(bounded['violationCount'], 20000);
    expect(bounded['accepted'], report.accepted);
    final grouped = (bounded['metrics'] as List).cast<Map<String, Object?>>();
    final fileMetric =
        grouped.singleWhere((e) => e['dimension'] == 'fileBytes');
    expect(fileMetric['observed'], 9);
    expect(fileMetric['allowed'], 4);
    expect(fileMetric['metricCount'], 20000);
    expect(fileMetric['violationCount'], 20000);
    expect(fileMetric['scope'], 'assets/file_42.bin');
    final reversed = calculator
        .measureProjectJson({}, files: files.reversed).toBoundedJson();
    expect(CanonicalJson.encode(bounded), CanonicalJson.encode(reversed));
  });

  test(
      'bounded JSON bounds unknown metadata and keeps complete omission counts',
      () {
    final files = List.generate(
        20000, (i) => CatalogBudgetFile(path: 'assets/file_$i.bin'));
    final report =
        const CatalogBudgetCalculator().measureProjectJson({}, files: files);
    final bounded = report.toBoundedJson(maximumBytes: 2048);
    expect(CanonicalJson.encodeUtf8(bounded).length, lessThanOrEqualTo(2048));
    expect(bounded['measurementComplete'], isFalse);
    expect(bounded['unknownDimensionsCount'], report.unknownDimensions.length);
    expect(
        bounded['omittedUnknownDimensions'], report.unknownDimensions.length);
    expect(bounded['violationCount'], report.violations.length);
  });

  test('bounded JSON returns minimal summary for oversized labels', () {
    final report = CatalogBudgetReport(scope: 'project', metrics: [
      CatalogBudgetMetric(
          scope: 'project',
          dimension: 'custom',
          observed: 2,
          allowed: 1,
          unit: 'unités',
          label: 'A' * 10000,
          remedy: 'B' * 10000)
    ]);
    final bounded = report.toBoundedJson(maximumBytes: 1024);
    expect(CanonicalJson.encodeUtf8(bounded).length, lessThanOrEqualTo(1024));
    expect(bounded['truncated'], isTrue);
    expect(bounded['metricCount'], 1);
    expect(bounded['violationCount'], 1);
    expect(bounded['accepted'], isFalse);
    expect(bounded['scope'], 'project');
  });

  test('project remedies describe document complexity', () {
    final report = const CatalogBudgetCalculator(
            gamePackagePolicy: GamePackageSecurityPolicy(maxJsonBytes: 1))
        .measureProjectJson({});
    expect(report.violations.single.remedy, isNot(contains('plusieurs packs')));
    expect(report.violations.single.remedy, contains('document'));
  });

  test(
      'resource pack metadata quotas accept exact bounds and collect every excess',
      () {
    final catalog = ResourcePackCatalog();
    final bytes = CatalogBudgetCalculator()
        .measureResourcePack(catalog)
        .totals['catalogBytes']!;
    final objects = PortableCatalogPublication.encodeCatalog(catalog)
        .storage
        .objects
        .length;
    final maximumCatalogFileBytes =
        PortableCatalogPublication.encodeCatalog(catalog)
            .storage
            .objects
            .values
            .map((bytes) => bytes.length)
            .reduce((a, b) => a > b ? a : b);
    const files = [
      CatalogBudgetFile(
          path: 'previews/a.png',
          byteLength: 4,
          imageWidth: 2,
          imageHeight: 2,
          isPreview: true),
      CatalogBudgetFile(
          path: 'previews/b.png',
          byteLength: 4,
          imageWidth: 2,
          imageHeight: 2,
          isPreview: true),
    ];
    final exact = CatalogBudgetCalculator(
            resourcePackPolicy: ResourcePackSecurityPolicy(
                maxTotalPayloadBytes: bytes + 8,
                maxFileBytes: maximumCatalogFileBytes,
                maxPreviewBytes: 4,
                maxPreviewFiles: 2,
                maxZipEntries: 4 + objects,
                maxImageDimension: 2,
                maxImagePixels: 4,
                maxArchiveBytes: 2,
                maxManifestBytes: 2))
        .measureResourcePack(catalog,
            files: files, archiveBytes: 2, manifestBytes: 2);
    expect(exact.violations, isEmpty);
    expect(exact.totals['payloadBytes'], bytes + 8);
    expect(exact.totals['publishedFiles'], isNull);
    expect(exact.unknownDimensions, contains('publishedFiles'));
    expect(exact.totals['rgba8BytesEstimate'], 32);
    final exceeded = CatalogBudgetCalculator(
            resourcePackPolicy: ResourcePackSecurityPolicy(
                maxTotalPayloadBytes: bytes + 7,
                maxFileBytes: 3,
                maxPreviewBytes: 3,
                maxPreviewFiles: 1,
                maxZipEntries: 3 + objects,
                maxImageDimension: 1,
                maxImagePixels: 3,
                maxArchiveBytes: 1,
                maxManifestBytes: 1))
        .measureResourcePack(catalog,
            files: files, archiveBytes: 2, manifestBytes: 2);
    expect(
        exceeded.violations.map((e) => e.dimension),
        containsAll([
          'payloadBytes',
          'fileBytes',
          'previewBytes',
          'previewFiles',
          'zipEntries',
          'imageWidth',
          'imageHeight',
          'imagePixels',
          'archiveBytes',
          'manifestBytes'
        ]));
  });

  test(
      'rejects invalid JSON and absolute metadata paths without disclosing them',
      () {
    for (final value in [double.nan, Object(), String.fromCharCode(0xd800)]) {
      expect(
          () => const CatalogBudgetCalculator()
              .measureJsonDocument(value, scope: 'document'),
          throwsFormatException);
    }
    expect(
        () => const CatalogBudgetCalculator()
            .measureJsonDocument({1: true}, scope: 'document'),
        throwsFormatException);
    try {
      const CatalogBudgetCalculator().measureProjectJson({},
          files: const [CatalogBudgetFile(path: '/Users/secret/private.png')]);
      fail('absolute path was accepted');
    } on FormatException catch (error) {
      expect(error.toString(), isNot(contains('/Users/secret')));
    }
  });

  test('stable JSON report ordering does not depend on object insertion order',
      () {
    const calculator = CatalogBudgetCalculator(maxBreakdownEntries: 2);
    final left = calculator.measureJsonDocument({
      'z': [1],
      'a': [2],
      'b': [3]
    }, scope: 'document');
    final right = calculator.measureJsonDocument({
      'b': [3],
      'a': [2],
      'z': [1]
    }, scope: 'document');
    expect(CanonicalJson.encode(left.toJson()),
        CanonicalJson.encode(right.toJson()));
    expect(left.omittedBreakdownEntries, 1);
  });

  test('raw document API uses explicit limits without typed decoding', () {
    final report = const CatalogBudgetCalculator().measureJsonDocument({
      'badTypedVersion': 999,
      'data': [1, 2]
    }, scope: 'nativeSelection', maxBytes: 1, maxNodes: 1, maxDepth: 1);
    expect(report.violations.map((e) => e.dimension),
        containsAll(['catalogBytes', 'jsonNodes', 'jsonDepth']));
    expect(report.scope, 'nativeSelection');
    final scalar = const CatalogBudgetCalculator()
        .measureJsonDocument('é', scope: 'document');
    expect(scalar.totals['catalogBytes'], 4);
    expect(scalar.totals['jsonDepth'], 0);
    expect(scalar.accepted, isTrue);
  });

  test('counts canonical bytes and values, not keys', () {
    final json = <String, Object?>{
      'é': ['😀', null, 2],
      'empty': {}
    };
    final report = const CatalogBudgetCalculator().measureProjectJson(json);
    expect(
        report.totals['catalogBytes'], CanonicalJson.encodeUtf8(json).length);
    expect(report.totals['jsonNodes'], 6);
    expect(report.totals['jsonDepth'], 2);
    expect(report.totals['archiveBytes'], isNull);
    expect(report.measurementComplete, isFalse);
    expect(report.unknownDimensions, contains('archiveBytes'));
  });

  test('evaluates every dimension at exact bounds and plus one', () {
    final json = <String, Object?>{
      'maps': [1, 2]
    };
    final bytes = CanonicalJson.encodeUtf8(json).length;
    final exact = CatalogBudgetCalculator(
            gamePackagePolicy: GamePackageSecurityPolicy(
                maxJsonBytes: bytes,
                maxJsonNodes: 4,
                maxJsonDepth: 2,
                maxProjectCollectionEntries: 2))
        .measureProjectJson(json);
    expect(exact.violations, isEmpty);
    final exceeded = CatalogBudgetCalculator(
            gamePackagePolicy: GamePackageSecurityPolicy(
                maxJsonBytes: bytes - 1,
                maxJsonNodes: 3,
                maxJsonDepth: 1,
                maxProjectCollectionEntries: 1))
        .measureProjectJson(json);
    expect(
        exceeded.violations.map((e) => e.dimension),
        containsAll(
            ['catalogBytes', 'jsonNodes', 'jsonDepth', 'collectionEntries']));
    final error = CatalogBudgetExceededException(exceeded);
    expect(error.code, 'catalog.budget_exceeded');
    expect(error.report, same(exceeded));
    expect(error.toString(), contains('limite'));
  });

  test('keeps compact project JSON and nested counts informative', () {
    final report = const CatalogBudgetCalculator().measureProjectJson({
      'maps': [1],
      'smartTileCatalog': {
        'presets': [1, 2, 3]
      }
    });
    expect(report.totals['collectionEntries'], 1);
    final count = report.breakdown
        .singleWhere((e) => e.scope == 'project.smartTileCatalog.presets');
    expect(count.observed, 3);
    expect(count.allowed, isNull);
  });

  test('typed catalog excludes implicit builtin families', () {
    final catalog = ResourcePackCatalog();
    final report = const CatalogBudgetCalculator().measureResourcePack(catalog);
    expect(report.totals['resources'], 0);
    expect(report.totals['supports'], 0);
    final publication = PortableCatalogPublication.encodeCatalog(catalog);
    expect(
        report.totals['catalogBytes'],
        CanonicalJson.encodeUtf8(publication.descriptor).length +
            publication.storage.objects.values
                .fold<int>(0, (sum, bytes) => sum + bytes.length));
    expect(report.totals['graphNodes'], greaterThan(0));
  });

  test('typed hierarchy and supports exact limit then plus one', () {
    final catalog = ResourcePackCatalog(tilesetFolders: const [
      ProjectTilesetFolder(id: 'a', name: 'A'),
      ProjectTilesetFolder(id: 'b', name: 'B', parentFolderId: 'a')
    ]);
    final exact = const CatalogBudgetCalculator(
            resourcePackPolicy: ResourcePackSecurityPolicy(
                maxSupports: 2, maxHierarchyEntries: 2, maxHierarchyDepth: 2))
        .measureResourcePack(catalog);
    expect(exact.violations, isEmpty);
    final exceeded = const CatalogBudgetCalculator(
            resourcePackPolicy: ResourcePackSecurityPolicy(
                maxSupports: 1, maxHierarchyEntries: 1, maxHierarchyDepth: 1))
        .measureResourcePack(catalog);
    expect(exceeded.violations.map((e) => e.dimension),
        containsAll(['supports', 'hierarchyEntries', 'hierarchyDepth']));
  });

  test('bounds details but retains violations and unknown descriptor totals',
      () {
    final report = const CatalogBudgetCalculator(
            maxBreakdownEntries: 1,
            gamePackagePolicy: GamePackageSecurityPolicy(
                maxFileBytes: 4, maxImageDimension: 2, maxImagePixels: 4))
        .measureProjectJson({}, files: const [
      CatalogBudgetFile(
          path: 'assets/a.png', byteLength: 5, imageWidth: 3, imageHeight: 2),
      CatalogBudgetFile(path: 'assets/b.png')
    ]);
    expect(report.breakdown.length, 1);
    expect(report.omittedBreakdownEntries, greaterThan(0));
    expect(report.violations.map((e) => e.dimension),
        containsAll(['fileBytes', 'imageWidth', 'imagePixels']));
    expect(report.totals['fileBytes'], isNull);
    expect(report.totals['rgba8BytesEstimate'], isNull);
    expect(
        report.metrics
            .singleWhere((e) =>
                e.scope == 'assets/a.png' &&
                e.dimension == 'rgba8BytesEstimate')
            .observed,
        24);
    expect(report.toJson()['measurementComplete'], isFalse);
  });

  test('deep JSON avoids stack overflow and cycles fail safely', () {
    Object? nested;
    for (var i = 0; i < 10000; i++) {
      nested = [nested];
    }
    final report =
        const CatalogBudgetCalculator().measureProjectJson({'x': nested});
    expect(report.totals['jsonDepth'], 10001);
    expect(report.totals['jsonNodes'], 10002);
    final cycle = <Object?>[];
    cycle.add(cycle);
    expect(
        () => const CatalogBudgetCalculator().measureProjectJson({'x': cycle}),
        throwsFormatException);
    final shared = [1];
    final sharedReport = const CatalogBudgetCalculator()
        .measureProjectJson({'a': shared, 'b': shared});
    expect(sharedReport.totals['jsonNodes'], 5);
    expect(sharedReport.totals['catalogBytes'],
        CanonicalJson.encodeUtf8({'a': shared, 'b': shared}).length);
  });

  test('project cycles are violations and reports preserve input immutability',
      () {
    final data = <String, Object?>{
      'groups': [
        {'id': 'a', 'parentGroupId': 'b'},
        {'id': 'b', 'parentGroupId': 'a'}
      ]
    };
    final before = CanonicalJson.encode(data);
    final report = const CatalogBudgetCalculator()
        .measureProjectJson(data, scope: 'sourceProject');
    expect(
        report.violations.any((e) => e.dimension == 'hierarchyCycles'), isTrue);
    expect(CanonicalJson.encode(data), before);
    expect(() => report.metrics.clear(), throwsUnsupportedError);
    expect(() => report.totals.clear(), throwsUnsupportedError);
    expect(report.scope, 'sourceProject');
  });
}
