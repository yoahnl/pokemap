import 'dart:convert';

import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'package:map_authoring/map_authoring_local.dart'
    show ResourceSourceActions;

import '../maps/map_catalog_fixture.dart';

void main() {
  test('source replacement reconciles content addressed tileset', () async {
    final store = MemoryArtifactStore(maximumArtifactBytes: 1024 * 1024);
    final old =
        (await store.put(image.encodePng(image.Image(width: 32, height: 32))))
            .reference;
    final pixels = image.Image(width: 32, height: 32)
      ..setPixelRgba(0, 0, 255, 0, 0, 255);
    final next = (await store.put(image.encodePng(pixels))).reference;
    final catalog = AssetCatalog(records: [
      AssetRecord(
          id: 'asset', logicalPath: assetBlobStorageKey(old), artifact: old)
    ]);
    final project =
        ProjectManifest(name: 'Regression', maps: const [], tilesets: [
      ProjectTilesetEntry(
          id: 'sheet',
          name: 'Sheet',
          relativePath: assetBlobStorageKey(old),
          source: const ProjectRegularAtlasTilesetSource(
              assetId: 'asset',
              pixelWidth: 32,
              pixelHeight: 32,
              tileWidth: 32,
              tileHeight: 32))
    ]);
    final base = catalogSnapshot(const [], project: project);
    final bytes = {
      'project': base.resourceBytes('project'),
      assetCatalogResourceIdentity: utf8.encode(jsonEncode(catalog.toJson())),
      assetBlobResourceIdentity(old.digest): await store.read(old.handle)
    };
    final paths = {
      'project': 'project.json',
      assetCatalogResourceIdentity: assetCatalogStorageKey,
      assetBlobResourceIdentity(old.digest): assetBlobStorageKey(old)
    };
    final snapshot = ProjectSnapshot(
        projectHandle: base.projectHandle,
        revision: base.revision,
        manifest: project,
        maps: const [],
        pokemonInventoryComplete: true,
        resourceFingerprints: {
          for (final key in bytes.keys)
            key: computeNarrativeProjectFingerprint([
              NarrativeProjectFingerprintEntry(
                  relativePath: paths[key]!, bytes: bytes[key]!)
            ])
        },
        resourceBytes: bytes);
    final draft = await ResourceSourceActions(artifactStore: store).build(
        catalogContext(snapshot, 'tileset.source.replace',
            {'tilesetId': 'sheet', 'artifactHandle': next.handle}));
    expect(
        draft.changeSet.changes
            .where((change) => change.storageKey == 'project.json'),
        isNotEmpty);
  });
}
