import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final reference in ['region', 'thumbnail']) {
    test(
        'export retains $reference source shared with unused presentation media',
        () async {
      final root =
          await Directory.systemTemp.createTemp('regional-shared-export-');
      addTearDown(() => root.delete(recursive: true));
      final bytes = image.encodePng(image.Image(width: 3, height: 2));
      final unusedBytes = image.encodePng(image.Image(width: 4, height: 2));
      final asset = AssetRecord(
          id: 'regional-image',
          logicalPath: 'assets/region.png',
          artifact:
              ContentArtifactRef.fromBytes(bytes, mediaType: 'image/png'));
      final unused = AssetRecord(
          id: 'unused-image',
          logicalPath: 'assets/unused.png',
          artifact: ContentArtifactRef.fromBytes(unusedBytes,
              mediaType: 'image/png'));
      for (final entry in [(asset, bytes), (unused, unusedBytes)]) {
        final blob =
            File('${root.path}/${assetBlobStorageKey(entry.$1.artifact)}');
        await blob.parent.create(recursive: true);
        await blob.writeAsBytes(entry.$2);
      }
      await File('${root.path}/$assetCatalogStorageKey').writeAsString(
          jsonEncode(AssetCatalog(records: [asset, unused]).toJson()));
      await File('${root.path}/$projectMediaCatalogStorageKey').writeAsBytes(
          encodeProjectMediaCatalogBytes(ProjectMediaCatalog(entries: [
        for (final entry in [asset, unused])
          ProjectMediaAsset(
              id: 'media-${entry.id}',
              label: entry.id,
              kind: ProjectMediaKind.image,
              sourceAssetId: entry.id)
      ])));
      final catalog = ProjectRegionalMapCatalog(regions: [
        ProjectRegionDefinition(
            id: 'r',
            label: 'Region',
            imagePath: reference == 'region' ? asset.logicalPath : null)
      ], pointsOfInterest: [
        ProjectRegionPointOfInterest(
            id: 'p',
            regionId: 'r',
            label: 'Place',
            u: 0.3,
            v: 0.7,
            discovery: ProjectRegionPointDiscovery.always,
            thumbnailPath: reference == 'thumbnail' ? asset.logicalPath : null)
      ]);
      final project = ProjectManifest(
          name: 'Region export',
          maps: const [],
          tilesets: const [],
          regionalMap: catalog);
      await File('${root.path}/project.json')
          .writeAsString(jsonEncode(project.toJson()));
      final result = await const RuntimeProjectProjectionBuilder().build(
          projectRoot: root,
          profile: GamePackageExportProfile(
              gameId: 'games.test.region',
              gameVersion: '0.1.0',
              title: 'Region',
              authorName: 'Tester',
              defaultLocale: 'en',
              supportedLocales: const ['en']));
      final exportedCatalog = AssetCatalog.fromJson(jsonDecode(utf8
              .decode(result.payloadFiles['project/$assetCatalogStorageKey']!))
          as Map<String, dynamic>);
      final exportedManifest = ProjectManifest.fromJson(
          jsonDecode(utf8.decode(result.payloadFiles['project/project.json']!))
              as Map<String, dynamic>);
      expect(exportedManifest.regionalMap!.toJson(), catalog.toJson());
      expect(exportedCatalog.find(asset.id), isNotNull);
      expect(
          result.payloadFiles['project/${assetBlobStorageKey(asset.artifact)}'],
          bytes);
      expect(exportedCatalog.find(unused.id), isNull);
      expect(
          result
              .payloadFiles['project/${assetBlobStorageKey(unused.artifact)}'],
          isNull);
      final exportedMedia = ProjectMediaCatalog.fromJson(jsonDecode(utf8.decode(
              result.payloadFiles['project/$projectMediaCatalogStorageKey']!))
          as Map<String, dynamic>);
      expect(exportedMedia.entries, isEmpty);
    });
  }
  test('export retains regional semantics and portable image bytes', () async {
    final root = await Directory.systemTemp.createTemp('regional-export-');
    addTearDown(() => root.delete(recursive: true));
    final bytes = image.encodePng(image.Image(width: 3, height: 2));
    final artifact =
        ContentArtifactRef.fromBytes(bytes, mediaType: 'image/png');
    final asset = AssetRecord(
        id: 'regional-image',
        logicalPath: 'assets/region.png',
        artifact: artifact);
    final blob = File('${root.path}/${assetBlobStorageKey(artifact)}');
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes(bytes);
    await File('${root.path}/$assetCatalogStorageKey')
        .writeAsString(jsonEncode(AssetCatalog(records: [asset]).toJson()));
    final catalog = ProjectRegionalMapCatalog(regions: [
      ProjectRegionDefinition(
          id: 'r', label: 'Region', imagePath: asset.logicalPath)
    ], pointsOfInterest: [
      ProjectRegionPointOfInterest(
          id: 'p',
          regionId: 'r',
          label: 'Place',
          u: 0.3,
          v: 0.7,
          discovery: ProjectRegionPointDiscovery.always)
    ]);
    final project = ProjectManifest(
        name: 'Region export',
        maps: const [],
        tilesets: const [],
        regionalMap: catalog);
    final file = File('${root.path}/project.json');
    await file.writeAsString(jsonEncode(project.toJson()));
    final profile = GamePackageExportProfile(
        gameId: 'games.test.region',
        gameVersion: '0.1.0',
        title: 'Region',
        authorName: 'Tester',
        defaultLocale: 'en',
        supportedLocales: const ['en']);
    final result = await const RuntimeProjectProjectionBuilder()
        .build(projectRoot: root, profile: profile);
    final decoded = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(result.payloadFiles['project/project.json']!))
            as Map<String, dynamic>);
    expect(decoded.regionalMap!.toJson(), catalog.toJson());
    expect(
        result.payloadFiles['project/${assetBlobStorageKey(artifact)}'], bytes);
    await file.writeAsString(jsonEncode(project
        .copyWith(
            regionalMap: ProjectRegionalMapCatalog(regions: [
          ProjectRegionDefinition(
              id: 'r', label: 'Region', imagePath: 'assets/missing.png')
        ]))
        .toJson()));
    await expectLater(
        const RuntimeProjectProjectionBuilder()
            .build(projectRoot: root, profile: profile),
        throwsA(isA<GamePackageExportException>()
            .having((e) => e.code, 'code', 'regional_map.image_missing')));
    final invalidArtifact =
        ContentArtifactRef.fromBytes([1, 2, 3], mediaType: 'image/png');
    await File('${root.path}/${assetBlobStorageKey(invalidArtifact)}')
        .writeAsBytes([1, 2, 3]);
    await File('${root.path}/$assetCatalogStorageKey')
        .writeAsString(jsonEncode(AssetCatalog(records: [
      AssetRecord(
          id: asset.id,
          logicalPath: asset.logicalPath,
          artifact: invalidArtifact)
    ]).toJson()));
    await file.writeAsString(jsonEncode(project.toJson()));
    await expectLater(
        const RuntimeProjectProjectionBuilder()
            .build(projectRoot: root, profile: profile),
        throwsA(isA<GamePackageExportException>()
            .having((e) => e.code, 'code', 'regional_map.image_invalid')));
  });
}
