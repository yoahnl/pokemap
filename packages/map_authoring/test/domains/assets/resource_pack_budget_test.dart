import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/assets/resource_pack_budget.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import 'resource_pack_export_test.dart' as source;
import 'resource_pack_import_fixture.dart';

void main() {
  test('project measurements preserve actual bytes and unknown raw fields', () async {
    final raw = {'name': 'Été', 'rawExtension': ['x' * 5000]};
    final bytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(raw));
    final report = await measureProjectDocumentBudget(bytes,
        scope: 'mergedProjectDistribution');
    expect(report.totals['catalogBytes'], bytes.length);
    expect(report.totals['jsonNodes'], 4);
    expect(report.totals['jsonDepth'], 2);
    expect(report.totals['catalogBytes'], greaterThan(5000));
    expect(report.totals['files'], isNull);
    expect(report.totals['payloadBytes'], isNull);
    expect(report.totals['imagePixels'], isNull);
    expect(report.unknownDimensions, contains('fileInventory'));
    expect(jsonDecode(utf8.decode(bytes)), raw);
  });

  test('import preview measures the real merged document without applying it', () async {
    final fixture = await ResourcePackImportFixture.create();
    try {
      final raw = {
        ...fixture.snapshot.manifest.toJson(),
        'rawExtension': 'x' * 5000,
      };
      fixture.snapshot = makeSnapshot(fixture.snapshot.manifest,
          resources: {'project': utf8.encode(jsonEncode(raw))});
      final before = fixture.snapshot.revision;
      final prepared = await fixture.prepare();
      final report = prepared.review.summary['budgetReport'] as Map;
      expect(report['scope'], 'mergedProjectDistribution');
      expect((report['totals'] as Map)['catalogBytes'],
          greaterThan(fixture.snapshot.resourceBytes('project').length));
      expect(prepared.review.summary['budgetAdmission'], 'gameDistributionOnly');
      expect(fixture.snapshot.revision, before);
      expect(jsonDecode(utf8.decode(fixture.snapshot.resourceBytes('project'))), raw);
    } finally {
      await fixture.dispose();
    }
  });

  test('native selection reports every exceeded counter without reading media',
      () async {
    final manifest = source.originalManifest();
    final before = jsonEncode(manifest.toJson());
    final file = source.nativeImage();
    var reads = 0;
    final descriptor = NativeResourcePackFile(
      id: file.id,
      logicalPath: file.logicalPath,
      byteLength: file.byteLength,
      rawSha256: file.rawSha256,
      mediaType: file.mediaType,
      openRead: () {
        reads++;
        throw StateError('Diagnostic must not read media');
      },
    );
    const builder = ResourcePackProjectionBuilder(
      policy: ResourcePackSecurityPolicy(maxResources: 1, maxSupports: 1),
    );
    final report = await builder.measureNativeSelection(
      manifest: manifest,
      roots: [
        NativeResourcePackRef(kind: ResourcePackKind.smartTilePreset, id: 'sol'),
      ],
      files: [descriptor],
    );
    expect(report.accepted, isFalse);
    expect(report.violations.map((fact) => fact.dimension),
        containsAll(['resources', 'supports']));
    expect(reads, 0);
    expect(jsonEncode(manifest.toJson()), before);
    expect(report.scope, 'nativeSelection');
    expect(report.unknownDimensions, contains('publicationMetadata'));
  });

  test('native preparation refuses with the same aggregate budget facts',
      () async {
    const builder = ResourcePackProjectionBuilder(
      policy: ResourcePackSecurityPolicy(maxResources: 1, maxSupports: 1),
    );
    final manifest = source.originalManifest();
    final roots = [
      NativeResourcePackRef(kind: ResourcePackKind.smartTilePreset, id: 'sol'),
    ];
    final report = await builder.measureNativeSelection(
      manifest: manifest,
      roots: roots,
      files: [source.nativeImage()],
    );
    await expectLater(
      builder.selectedFileIds(
        manifest: manifest,
        roots: roots,
        files: [source.nativeImage()],
      ),
      throwsA(isA<CatalogBudgetExceededException>().having(
        (failure) => failure.report.toJson(),
        'budget report',
        report.toJson(),
      )),
    );
  });

  test('unknown native references remain structural failures', () async {
    await expectLater(
      const ResourcePackProjectionBuilder().measureNativeSelection(
        manifest: source.originalManifest(),
        roots: [
          NativeResourcePackRef(kind: ResourcePackKind.element, id: 'absent'),
        ],
        files: [source.nativeImage()],
      ),
      throwsFormatException,
    );
  });
}
