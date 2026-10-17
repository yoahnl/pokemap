import 'dart:io';
import 'package:map_authoring/src/infrastructure/local_resource_pack_store.dart';
import 'package:map_authoring/src/ports/file_backed_payload_store.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'resource_pack_export_test.dart' as fixture;

void main() {
  test(
      'pure native projection describes normalization before export acknowledgement',
      () async {
    final source = fixture.mixedFixture();
    final manifest = source.$1.copyWith(tilesets: [
      source.$1.tilesets.single
          .copyWith(groupId: 'private-tree', isWorldTileset: true)
    ]);
    final before = manifest.toJson();
    final projection = await const ResourcePackProjectionBuilder().project(
        manifest: manifest,
        roots: [
          NativeResourcePackRef(kind: ResourcePackKind.tileset, id: 'atlas')
        ],
        files: source.$2,
        author: 'Original',
        sourceRevision: 'revision');
    expect(projection.removedOrganization, isNotEmpty);
    expect(manifest.toJson(), before);
  });
  test('direct archive creation cannot bypass normalization acknowledgement',
      () async {
    final source = fixture.mixedFixture();
    final manifest = source.$1.copyWith(tilesets: [
      source.$1.tilesets.single
          .copyWith(groupId: 'private-tree', isWorldTileset: true)
    ]);
    final projection = await fixture.projectFixture(manifest, source.$2,
        roots: [
          NativeResourcePackRef(kind: ResourcePackKind.tileset, id: 'atlas')
        ]);
    final directory =
        await Directory.systemTemp.createTemp('p11-review-guard-');
    final store = LocalResourcePackStore(
        cacheDirectory: directory.path, allowedSourceRoots: []);
    const scope =
        FileBackedPayloadScope(sessionId: 'review', projectId: 'project');
    OwnedResourcePackExport? result;
    try {
      await expectLater(() async {
        result =
            await CanonicalResourcePackExportService(store: store, scope: scope)
                .export(
                    projection: projection,
                    metadata: fixture.metadata(),
                    expectedRevision: 'revision',
                    readCurrentRevision: () async => 'revision');
      },
          throwsA(isA<FormatException>().having((error) => error.message,
              'message', contains('organization_acknowledgement_required'))));
    } finally {
      await result?.dispose();
      await store.close();
      await directory.delete(recursive: true);
    }
  });

  test(
      'native review ignores Border workflow revision and reports saved definition divergence',
      () async {
    final source = fixture.mixedFixture();
    final published = source.$1.borderCatalog.records.single.latestPublished!;
    final canonical = reconstructResourcePackBorderDraft(published);
    var record = BorderBlueprintRecord(
        id: 'border',
        draft: BorderBlueprintDraft(
            baseRevision: 999, definition: canonical.definition),
        latestPublished: published);
    Future<ResourcePackExportProjection> project() => fixture.projectFixture(
            source.$1.copyWith(
                borderCatalog: ProjectBorderCatalog(
                    records: [record],
                    visualSnapshots: source.$1.borderCatalog.visualSnapshots)),
            source.$2,
            roots: [
              NativeResourcePackRef(
                  kind: ResourcePackKind.borderBlueprint, id: 'border')
            ]);
    final equal = await project();
    expect(
        equal.review.rows.singleWhere(
            (row) => row['kind'] == 'publication')['draftComparison'],
        'equivalent');
    expect(
        equal.review.rows
            .singleWhere((row) => row['kind'] == 'publication')['label'],
        published.definition.name);
    final json = encodeBorderBlueprintRecordJson(record,
        formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion);
    ((json['draft'] as Map)['definition'] as Map)['name'] =
        'Changed saved draft';
    record = decodeBorderBlueprintRecordJson(json,
        formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion);
    final changed = await project();
    expect(
        changed.review.rows.singleWhere(
            (row) => row['kind'] == 'publication')['draftComparison'],
        'divergent');
    expect(
        changed.catalog.borderCatalog.records.single.latestPublished!.definition
            .name,
        published.definition.name);
    expect(changed.review.reachedNativeIds['borderBlueprint'], ['border']);
    expect(() => changed.review.reachedNativeIds['borderBlueprint']!.clear(),
        throwsUnsupportedError);
  });

  test(
      'terrain notice compares compiled reached supports by ID and reports a noncompilable draft honestly',
      () async {
    final source = fixture.originalManifest();
    final preset = source.smartTileCatalog.presets.single;
    final canonical = reconstructResourcePackSmartTileDraft(
        preset: preset, catalog: source.smartTileCatalog);
    var draft = canonical.copyWith(
        id: 'workflow', lastStage: SmartTileAuthoringStage.values.first);
    Future<ResourcePackExportProjection> project() async {
      final catalog = ProjectSmartTileCatalog.fromJson({
        ...source.smartTileCatalog.toJson(),
        'drafts': [draft.toJson()]
      });
      final manifest = source.copyWith(smartTileCatalog: catalog);
      return fixture.projectFixture(manifest, [
        fixture.nativeImage()
      ], roots: [
        NativeResourcePackRef(
            kind: ResourcePackKind.smartTilePreset, id: preset.id)
      ]);
    }

    final equivalent = await project();
    expect(
        equivalent.review.rows.singleWhere(
            (row) => row['kind'] == 'publication')['draftComparison'],
        'equivalent');
    draft = canonical.copyWith(materials: [
      canonical.materials.single.copyWith(name: 'Different saved support')
    ]);
    expect(
        compileSmartTileAuthoringDraft(
            draft: draft, catalog: source.smartTileCatalog, manifest: source),
        isA<SmartTileDraftCompilationSuccess>());
    final changed = await project();
    expect(
        changed.review.rows.singleWhere(
            (row) => row['kind'] == 'publication')['draftComparison'],
        'divergent');
    draft = canonical.copyWith(primaryAtlasId: null);
    final invalid = await project();
    expect(
        invalid.review.rows.singleWhere(
            (row) => row['kind'] == 'publication')['draftComparison'],
        'notComparable');
    expect(invalid.catalog.smartTileCatalog.presets.single.status,
        SmartTilePresetStatus.published);
  });

  test('only reached missing publications can block a valid export review',
      () async {
    final source = fixture.originalManifest();
    final unpublished = source.smartTileCatalog.presets.single
        .copyWith(status: SmartTilePresetStatus.draft);
    final catalog = ProjectSmartTileCatalog.fromJson({
      ...source.smartTileCatalog.toJson(),
      'presets': [unpublished.toJson()]
    });
    final manifest = source.copyWith(smartTileCatalog: catalog);
    final valid = await fixture.projectFixture(manifest, [
      fixture.nativeImage()
    ], roots: [
      NativeResourcePackRef(kind: ResourcePackKind.tileset, id: 'atlas')
    ]);
    expect(valid.review.rows.where((row) => row['kind'] == 'publication'),
        isEmpty);
    await expectLater(
        fixture.projectFixture(manifest, [
          fixture.nativeImage()
        ], roots: [
          NativeResourcePackRef(
              kind: ResourcePackKind.smartTilePreset, id: unpublished.id)
        ]),
        throwsA(isA<FormatException>().having((error) => error.message,
            'message', contains('smart_tile_unpublished'))));
  });
}
