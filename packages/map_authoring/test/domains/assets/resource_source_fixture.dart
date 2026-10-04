import 'dart:convert';

import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../maps/map_catalog_fixture.dart';

List<int> sourcePng({int width = 32, int height = 32, int red = 0}) {
  final pixels = image.Image(width: width, height: height, numChannels: 4);
  image.fill(pixels, color: image.ColorRgba8(red, 128, 64, 255));
  return image.encodePng(pixels);
}

final class ResourceSourceFixture {
  ResourceSourceFixture(
      {this.addressed = false, this.shared = false, String? logicalPath}) {
    oldBytes = sourcePng();
    old = ContentArtifactRef.fromBytes(oldBytes, mediaType: 'image/png');
    path = logicalPath ??
        (addressed ? assetBlobStorageKey(old) : 'assets/sheet.png');
    asset = AssetRecord(
        id: 'asset',
        logicalPath: path,
        artifact: old,
        usages: const ['tileset'],
        tags: const ['conserved']);
    catalog = AssetCatalog(records: [
      asset,
      if (shared)
        AssetRecord(id: 'other', logicalPath: 'assets/other.png', artifact: old)
    ]);
    project = ProjectManifest(
        name: 'Source fixture',
        maps: const [],
        pokemon: ProjectManifest(
            name: 'Defaults',
            maps: const [],
            tilesets: const []).pokemon.copyWith(enabled: false),
        tilesets: [
          ProjectTilesetEntry(
              id: 'sheet',
              name: 'Planche été',
              relativePath: path,
              source: const ProjectRegularAtlasTilesetSource(
                  assetId: 'asset',
                  pixelWidth: 32,
                  pixelHeight: 32,
                  tileWidth: 32,
                  tileHeight: 32)),
          if (shared)
            const ProjectTilesetEntry(
                id: 'other-sheet',
                name: 'Autre',
                relativePath: 'assets/other.png',
                source: ProjectRegularAtlasTilesetSource(
                    assetId: 'other',
                    pixelWidth: 32,
                    pixelHeight: 32,
                    tileWidth: 32,
                    tileHeight: 32))
        ]);
  }

  final bool addressed;
  final bool shared;
  late final List<int> oldBytes;
  late final ContentArtifactRef old;
  late final String path;
  late final AssetRecord asset;
  late final AssetCatalog catalog;
  late final ProjectManifest project;

  ProjectSnapshot snapshot(
      {ProjectManifest? manifest,
      List<MapData> maps = const [],
      Map<String, List<int>> extra = const {},
      Map<String, String> extraPaths = const {},
      bool inventoryComplete = true}) {
    final current = manifest ?? project;
    final base = catalogSnapshot(maps, project: current);
    final bytes = {
      'project': base.resourceBytes('project'),
      assetCatalogResourceIdentity: utf8.encode(jsonEncode(catalog.toJson())),
      assetBlobResourceIdentity(old.digest): oldBytes,
      if (!addressed) 'assetLogical:${asset.id}': oldBytes,
      for (final map in maps)
        'map:${map.id}': base.resourceBytes('map:${map.id}'),
      ...extra
    };
    final paths = {
      'project': 'project.json',
      assetCatalogResourceIdentity: assetCatalogStorageKey,
      assetBlobResourceIdentity(old.digest): assetBlobStorageKey(old),
      if (!addressed) 'assetLogical:${asset.id}': path,
      for (final map in maps) 'map:${map.id}': 'maps/${map.id}.json',
      ...extraPaths
    };
    return ProjectSnapshot(
        projectHandle: base.projectHandle,
        revision: base.revision,
        manifest: current,
        maps: maps,
        pokemonInventoryComplete: inventoryComplete,
        resourceFingerprints: {
          for (final key in bytes.keys)
            key: computeNarrativeProjectFingerprint([
              NarrativeProjectFingerprintEntry(
                  relativePath: paths[key]!, bytes: bytes[key]!)
            ])
        },
        resourceBytes: bytes,
        resourceStorageKeys: paths);
  }
}
