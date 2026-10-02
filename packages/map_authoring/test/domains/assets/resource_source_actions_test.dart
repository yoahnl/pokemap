import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart'
    show ResourceSourceActions;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../maps/map_catalog_fixture.dart';
import 'resource_source_fixture.dart';

void main() {
  Future<AuthoringMutationDraft> replace(
      ResourceSourceFixture fixture, List<int> bytes,
      {ProjectSnapshot? snapshot}) async {
    final store = MemoryArtifactStore(maximumArtifactBytes: 1024 * 1024);
    final candidate = await store.put(bytes, declaredMediaType: 'image/png');
    return ResourceSourceActions(artifactStore: store).build(catalogContext(
        snapshot ?? fixture.snapshot(),
        'tileset.source.replace',
        {'tilesetId': 'sheet', 'artifactHandle': candidate.reference.handle}));
  }

  test(
      'stable source replacement preserves geometry, original shared blob and other identity',
      () async {
    final fixture = ResourceSourceFixture(shared: true);
    final draft = await replace(fixture, sourcePng(red: 255));
    final changes = {
      for (final change in draft.changeSet.changes) change.storageKey: change
    };
    expect(changes[fixture.path]!.afterBytes, sourcePng(red: 255));
    expect(changes.containsKey('project.json'), isFalse);
    expect(changes.containsKey(assetBlobStorageKey(fixture.old)), isFalse);
    expect(changes.containsKey('assets/other.png'), isFalse);
    final catalog = AssetCatalog.fromJson(
        jsonDecode(utf8.decode(changes[assetCatalogStorageKey]!.afterBytes!)));
    expect(catalog.require('other').artifact, fixture.old);
    expect(catalog.require('asset').tags, fixture.asset.tags);
    expect(draft.projectedProject!.tilesets, fixture.project.tilesets);
  });

  test('same logical asset consumers follow content addressed replacement',
      () async {
    final fixture = ResourceSourceFixture(addressed: true);
    final manifest = fixture.project.copyWith(tilesets: [
      fixture.project.tilesets.single,
      fixture.project.tilesets.single.copyWith(id: 'alias', name: 'Alias')
    ]);
    final draft = await replace(fixture, sourcePng(red: 255),
        snapshot: fixture.snapshot(manifest: manifest));
    final path = assetBlobStorageKey(ContentArtifactRef.fromBytes(
        sourcePng(red: 255),
        mediaType: 'image/png'));
    expect(draft.projectedProject!.tilesets.map((entry) => entry.relativePath),
        [path, path]);
    expect(draft.projectedProject!.tilesets.map((entry) => entry.source),
        manifest.tilesets.map((entry) => entry.source));
    expect(draft.changeSet.changes.where((change) => change.afterBytes == null),
        isEmpty);
  });

  test('same bytes is no-op without catalog, file or blob writes', () async {
    final fixture = ResourceSourceFixture();
    final draft = await replace(fixture, fixture.oldBytes);
    expect(draft.changeSet.changes, isEmpty);
    expect(draft.preview['noOp'], isTrue);
  });

  test('smaller, larger and corrupt same-header PNG are refused', () async {
    final fixture = ResourceSourceFixture();
    for (final candidate in [
      sourcePng(width: 16),
      sourcePng(width: 64),
      fixture.oldBytes.sublist(0, 33)
    ]) {
      await expectLater(
          replace(fixture, candidate), throwsA(isA<VisualLibraryException>()));
    }
  });

  test('expired candidate is refused without a projected write', () async {
    final fixture = ResourceSourceFixture();
    final store = MemoryArtifactStore(maximumArtifactBytes: 1024 * 1024);
    final candidate = await store.put(sourcePng(red: 255));
    await store.release(candidate.reference.handle);
    await expectLater(
        ResourceSourceActions(artifactStore: store).build(catalogContext(
            fixture.snapshot(), 'tileset.source.replace', {
          'tilesetId': 'sheet',
          'artifactHandle': candidate.reference.handle
        })),
        throwsA(isA<ArtifactStoreException>()));
  });

  test(
      'definition-only removal permits independent shared source and preserves its bytes',
      () async {
    final fixture = ResourceSourceFixture(shared: true);
    final draft = await const ResourceSourceActions().build(catalogContext(
        fixture.snapshot(), 'tileset.remove', {'tilesetId': 'sheet'}));
    expect(draft.projectedProject!.tilesets.map((entry) => entry.id),
        ['other-sheet']);
    expect(draft.changeSet.changes.single.storageKey, 'project.json');
  });

  test(
      'source option removes logical record and file while retaining historical blob',
      () async {
    final fixture = ResourceSourceFixture();
    final draft = await const ResourceSourceActions().build(catalogContext(
        fixture.snapshot(),
        'tileset.remove',
        {'tilesetId': 'sheet', 'removeSource': true}));
    expect(draft.changeSet.changes.map((change) => change.storageKey).toSet(),
        {'project.json', assetCatalogStorageKey, fixture.path});
    expect(
        draft.changeSet.changes
            .where((change) => change.storageKey == fixture.path)
            .single
            .afterBytes,
        isNull);
    expect(draft.preview['blobPreserved'], isTrue);
  });

  test('unplaced decor blocks tileset removal, without cascade', () async {
    final fixture = ResourceSourceFixture();
    final manifest = fixture.project.copyWith(elementCategories: const [
      ProjectElementCategory(id: 'props', name: 'Props')
    ], elements: const [
      ProjectElementEntry(
          id: 'decor',
          name: 'Décor',
          tilesetId: 'sheet',
          categoryId: 'props',
          frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))])
    ]);
    await expectLater(
        const ResourceSourceActions().build(catalogContext(
            fixture.snapshot(manifest: manifest),
            'tileset.remove',
            {'tilesetId': 'sheet'})),
        throwsA(isA<VisualLibraryException>().having(
            (error) => error.code, 'code', 'tileset.references_blocking')));
    expect(manifest.elements.single.id, 'decor');
  });

  test('closed map and incomplete inventory independently block removal',
      () async {
    final fixture = ResourceSourceFixture();
    final map = catalogMap('closed').copyWith(tilesetId: 'sheet');
    final manifest = fixture.project.copyWith(maps: [
      ProjectMapEntry(
          id: map.id, name: map.name, relativePath: 'maps/closed.json')
    ]);
    for (final snapshot in [
      fixture.snapshot(manifest: manifest, maps: [map]),
      fixture.snapshot(manifest: manifest)
    ]) {
      await expectLater(
          const ResourceSourceActions().build(catalogContext(
              snapshot, 'tileset.remove', {'tilesetId': 'sheet'})),
          throwsA(isA<VisualLibraryException>()));
    }
  });

  test('invalid Pokemon media inventory blocks source removal', () async {
    final fixture = ResourceSourceFixture();
    final manifest = fixture.project
        .copyWith(pokemon: fixture.project.pokemon.copyWith(enabled: true));
    final snapshot = fixture.snapshot(
        manifest: manifest,
        extra: {'pokemonMedia:broken': utf8.encode('{"variants":[]}')},
        extraPaths: {'pokemonMedia:broken': 'pokemon/media/broken.json'});
    await expectLater(
        const ResourceSourceActions().build(catalogContext(snapshot,
            'tileset.remove', {'tilesetId': 'sheet', 'removeSource': true})),
        throwsA(isA<VisualLibraryException>().having((error) => error.code,
            'code', 'resource.source.inventory_incomplete')));
  });

  test(
      'shared logical source permits definition removal but blocks optional source removal',
      () async {
    final fixture = ResourceSourceFixture();
    final manifest = fixture.project.copyWith(tilesets: [
      fixture.project.tilesets.single,
      fixture.project.tilesets.single.copyWith(id: 'alias', name: 'Alias')
    ]);
    final snapshot = fixture.snapshot(manifest: manifest);
    final draft = await const ResourceSourceActions().build(
        catalogContext(snapshot, 'tileset.remove', {'tilesetId': 'sheet'}));
    expect(draft.projectedProject!.tilesets.single.id, 'alias');
    await expectLater(
        const ResourceSourceActions().build(catalogContext(snapshot,
            'tileset.remove', {'tilesetId': 'sheet', 'removeSource': true})),
        throwsA(isA<VisualLibraryException>().having(
            (error) => error.code, 'code', 'asset.references_blocking')));
  });

  test('immutable content addressed snapshot remains pinned to old pixels',
      () async {
    final fixture = ResourceSourceFixture(addressed: true);
    final hash = List.filled(64, 'a').join();
    final visual = BorderVisualSnapshot(
        id: 'border-snapshot-sha256:$hash',
        contentFingerprint: hash,
        frames: [
          BorderVisualFrameSnapshot(
              relativeAssetPath: 'assets/borders/snapshots/old.png',
              sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 32, height: 32),
              durationMs: 100)
        ]);
    final manifest = fixture.project.copyWith(
        borderCatalog:
            ProjectBorderCatalog(formatVersion: 4, visualSnapshots: [visual]));
    final draft = await replace(fixture, sourcePng(red: 255),
        snapshot: fixture.snapshot(manifest: manifest));
    expect(
        draft.projectedProject!.borderCatalog.visualSnapshots.single, visual);
    expect(
        draft.changeSet.changes
            .where((change) => change.storageKey == fixture.path),
        isEmpty);
  });

  test('immutable snapshot of stable logical pixels blocks unsafe replacement',
      () async {
    final fixture = ResourceSourceFixture(
        logicalPath: 'assets/borders/snapshots/source.png');
    final hash = List.filled(64, 'a').join();
    final visual = BorderVisualSnapshot(
        id: 'border-snapshot-sha256:$hash',
        contentFingerprint: hash,
        frames: [
          BorderVisualFrameSnapshot(
              relativeAssetPath: fixture.path,
              sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 32, height: 32),
              durationMs: 100)
        ]);
    final manifest = fixture.project.copyWith(
        borderCatalog:
            ProjectBorderCatalog(formatVersion: 4, visualSnapshots: [visual]));
    await expectLater(
        replace(fixture, sourcePng(red: 255),
            snapshot: fixture.snapshot(manifest: manifest)),
        throwsA(isA<VisualLibraryException>().having(
            (error) => error.code, 'code', 'tileset.immutable_path_blocking')));
  });

  test('Character Studio portrait source refuses generic replacement',
      () async {
    final fixture = ResourceSourceFixture();
    final manifest = fixture.project.copyWith(characters: const [
      ProjectCharacterEntry(id: 'hero', name: 'Héros', tilesetId: 'sheet')
    ]);
    await expectLater(
        replace(fixture, sourcePng(red: 255),
            snapshot: fixture.snapshot(manifest: manifest)),
        throwsA(isA<VisualLibraryException>().having((error) => error.code,
            'code', 'tileset.character_owner_required')));
  });

  test(
      'historical source supports definition-only removal without improvising physical deletion',
      () async {
    final fixture = ResourceSourceFixture();
    final historical = fixture.project.copyWith(tilesets: [
      ProjectTilesetEntry(
          id: 'sheet', name: 'Historique', relativePath: fixture.path)
    ]);
    final snapshot = fixture.snapshot(manifest: historical);
    final draft = await const ResourceSourceActions().build(
        catalogContext(snapshot, 'tileset.remove', {'tilesetId': 'sheet'}));
    expect(draft.changeSet.changes.single.storageKey, 'project.json');
    await expectLater(
        const ResourceSourceActions().build(catalogContext(snapshot,
            'tileset.remove', {'tilesetId': 'sheet', 'removeSource': true})),
        throwsA(isA<VisualLibraryException>().having(
            (error) => error.code, 'code', 'tileset.source_not_supported')));
  });
}
