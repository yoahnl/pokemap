import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/assets/resource_pack_import_projection.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import '../../support/resource_pack_stdio_client.dart';
import 'resource_pack_import_fixture.dart';

void main() {
  late ResourcePackImportFixture source;
  setUpAll(() async {
    source = await ResourcePackImportFixture.create();
  });
  tearDownAll(() async {
    await source.dispose();
  });

  for (final family in ResourceLibraryCatalog.predefinedFamilies) {
    test('projects implicit ${family.id} without materializing another root',
        () {
      final original = source.archive.inspection;
      final catalog = classifiedCatalog(original.catalog, family.id);
      final inspection = ResourcePackInspection(
        manifest: original.manifest,
        catalog: catalog,
        archiveRawSha256: original.archiveRawSha256,
        archiveBytes: original.archiveBytes,
        manifestBytes: original.manifestBytes,
        payloadBytes: original.payloadBytes,
        fileCount: original.fileCount,
        resourceCount: original.resourceCount,
        supportCount: original.supportCount,
        provenanceStatus: original.provenanceStatus,
        modelInspections: original.modelInspections,
      );
      final closure = ResourcePackDependencyGraph.fromCatalog(catalog).closure(
        roots: [
          for (final element in catalog.elements)
            ResourcePackRef(kind: ResourcePackKind.element, id: element.id),
        ],
      );
      expect(
        closure.supports.any((support) => support.id == family.id),
        isTrue,
      );
      final projection = ResourcePackImportProjection(
        inspection: inspection,
        closure: closure,
        copyOrdinal: 0,
      )..project();
      expect(projection.reference('resourceFamily', family.id), family.id);
      expect(
        projection.catalog.resourceLibraryCatalog.families,
        hasLength(1),
      );
      expect(
        projection.catalog.resourceLibraryCatalog.families.single.parentId,
        family.id,
      );
      expect(
        projection.catalog.resourceLibraryCatalog.entries
            .map((entry) => entry.familyId),
        contains(family.id),
      );
      expect(
        projection.catalog.resourceLibraryCatalog.effectiveFamilies
            .where((entry) => entry.name == family.name),
        hasLength(1),
      );
    });
  }

  test('definition index rejects an explicit redefinition of a builtin family',
      () {
    expect(
      () => indexResourcePackDefinitions({
        'resourceLibraryCatalog': {
          'families': [
            {'id': 'props', 'name': 'Replaced predefined family'},
          ],
        },
      }),
      throwsA(isA<FormatException>().having(
        (error) => error.message,
        'message',
        'resource_pack.duplicate_native_identity',
      )),
    );
  });

  test('native import copy reimport and reopen reuse builtin family roots',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    try {
      final bytes = await classifiedArchive(fixture.source, 'props');
      final store = fixture.mutations
          .resourcePackPayloadStore(fixture.opened.projectHandle);
      await store.release(
        scope: fixture.preparer.scope,
        leaseId: fixture.staged!.leaseId,
      );
      fixture.staged = await store.stage(
        scope: fixture.preparer.scope,
        chunks: Stream.value(bytes),
        byteLength: bytes.length,
      );
      final selected = await fixture.select(
        roots: [
          for (final element
              in fixture.source.archive.inspection.catalog.elements)
            ResourcePackRef(kind: ResourcePackKind.element, id: element.id),
        ],
      );
      final prepared = await fixture.prepare(selection: selected);
      expect(prepared.status, ResourcePackPreparedImportStatus.ready);
      final builtinReview = prepared.review.rows.singleWhere(
        (row) => row['kind'] == 'resourceFamily' && row['id'] == 'props',
      );
      expect(builtinReview['label'], 'Objets');
      expect(builtinReview['disposition'], 'historical');
      expect(prepared.review.summary['reusedDefinitionCount'], 1);
      await fixture.apply(await fixture.plan(prepared));
      final first =
          (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      expectBuiltinHierarchy(first, customFamilies: 1);
      expect(
        first.resourcePackInstallations.entries.single.supports
            .singleWhere((support) => support.sourceId == 'props')
            .targetId,
        'props',
      );
      expect(
        (await fixture.prepare(selection: selected)).status,
        ResourcePackPreparedImportStatus.alreadyInstalled,
      );
      final copied = await fixture.prepare(
        selection: selected,
        policy: ResourcePackConflictPolicy.importCopy,
      );
      expect(copied.status, ResourcePackPreparedImportStatus.ready);
      await fixture.apply(await fixture.plan(copied));
      final copiedManifest =
          (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      expectBuiltinHierarchy(copiedManifest, customFamilies: 2);
      await fixture.close();
      await fixture.open();
      final reopened =
          (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      expect(
        reopened.resourceLibraryCatalog.toJson(),
        copiedManifest.resourceLibraryCatalog.toJson(),
      );
      expectBuiltinHierarchy(reopened, customFamilies: 2);
    } finally {
      await fixture.dispose();
    }
  });

  test('JSONL native import preserves builtin parents across reopen', () async {
    final fixture = await NativeResourcePackImportFixture.create();
    ResourcePackStdioClient? client;
    try {
      final bytes = await classifiedArchive(fixture.source, 'props');
      final archive = File('${fixture.root.path}/builtin.aveluneassets');
      await archive.writeAsBytes(bytes);
      await fixture.close();
      client =
          await ResourcePackStdioClient.start(fixture.source.directory.path);
      final opened =
          await client.call('open', {'projectRoot': fixture.root.path});
      final planned =
          await client.planImport(opened, archive.path, 'builtin-family');
      await client.result(
        opened,
        await client.pack(opened, 'start_apply', {
          'planId': planned['planId'],
          'operationId': 'builtin-family-import',
        }),
      );
      await client.close();
      client = null;
      await fixture.open();
      final reopened =
          (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      expectBuiltinHierarchy(reopened, customFamilies: 1);
    } finally {
      await client?.close();
      await fixture.dispose();
    }
  });
}

ResourcePackCatalog classifiedCatalog(
    ResourcePackCatalog catalog, String builtinFamilyId) {
  return ResourcePackCatalog.fromJson({
    ...catalog.toJson(),
    'resourceLibraryCatalog': ResourceLibraryCatalog(
      families: [
        ResourceFamily(
          id: 'custom-seating',
          name: 'Assises',
          parentId: builtinFamilyId,
        ),
      ],
      entries: [
        for (final (index, element) in catalog.elements.indexed)
          ResourceLibraryEntry(
            resourceKind: 'element',
            resourceId: element.id,
            familyId: index == 0 ? builtinFamilyId : 'custom-seating',
            placementContext: ResourcePlacementContext.interior,
          ),
      ],
    ).toJson(),
  });
}

void expectBuiltinHierarchy(ProjectManifest manifest,
    {required int customFamilies}) {
  final library = manifest.resourceLibraryCatalog;
  expect(library.families, hasLength(customFamilies));
  expect(
      library.families.every((family) => family.parentId == 'props'), isTrue);
  expect(
    library.effectiveFamilies.where((family) => family.name == 'Objets'),
    hasLength(1),
  );
  expect(
    library.entries.any((entry) => entry.familyId == 'props'),
    isTrue,
  );
  expect(
    ResourceLibraryCatalog.fromJson(library.toJson()).toJson(),
    library.toJson(),
  );
}

Future<Uint8List> classifiedArchive(
    ResourcePackImportFixture fixture, String builtinFamilyId) async {
  final original = fixture.archive.inspection;
  final zip = await fixture.archive.withSource(
    (source) async =>
        ZipDecoder().decodeBytes(source.readAtSync(0, source.length)),
  );
  final sink = _Sink();
  await ResourcePackBuilder().build(
    metadata: original.manifest.pack,
    catalog: classifiedCatalog(original.catalog, builtinFamilyId),
    tileWidth: original.manifest.compatibility.tileWidth,
    tileHeight: original.manifest.compatibility.tileHeight,
    sources: [
      for (final file in original.manifest.content.files)
        if (!file.path.startsWith('catalog/'))
          ResourcePackBuildSource(
            path: file.path,
            byteLength: file.byteLength,
            rawSha256: file.rawSha256,
            mediaType: file.mediaType,
            openRead: () => Stream.value(
              zip.findFile(file.path)!.content as List<int>,
            ),
          ),
    ],
    sink: sink,
  );
  return sink.bytes.takeBytes();
}

final class _Sink implements ResourcePackArchiveSink {
  final bytes = BytesBuilder(copy: false);
  @override
  Future<void> write(Uint8List chunk) async => bytes.add(chunk);
  @override
  Future<void> finish() async {}
  @override
  Future<void> abort() async {}
}
