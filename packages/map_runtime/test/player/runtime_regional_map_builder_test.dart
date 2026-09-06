import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  late Directory root;
  setUp(() async =>
      root = await Directory.systemTemp.createTemp('menu9-runtime-'));
  tearDown(() async => root.delete(recursive: true));

  test(
      'runtime resolves registered images offline and preserves normalized positions',
      () async {
    final artifact =
        ContentArtifactRef.fromBytes([137, 80, 78, 71], mediaType: 'image/png');
    final asset = AssetRecord(
        id: 'image', logicalPath: 'assets/map.png', artifact: artifact);
    final blob = File('${root.path}/${assetBlobStorageKey(artifact)}');
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes([137, 80, 78, 71]);
    await File('${root.path}/$assetCatalogStorageKey')
        .writeAsString(jsonEncode(AssetCatalog(records: [asset]).toJson()));
    final result = await const RuntimeRegionalMapBuilder().build(
        gameState: const GameState(saveId: 's', currentMapId: 'pension'),
        projectRootDirectory: root.path,
        locale: 'fr',
        catalog: _catalog(imagePath: asset.logicalPath));
    final region = result.regionalMap!.regions.single;
    expect(region.imageFilePath, await blob.resolveSymbolicLinks());
    expect(region.label, 'Le train de 17h42');
    expect(region.points.first.label, 'Hanazuki');
    expect(region.points.first.status, RuntimePlayerMapPointStatus.current);
    expect((region.points.first.u, region.points.first.v), (.25, .5));
    expect(region.points.map((point) => point.id), ['town', 'unknown']);
    final unknown = region.points.last;
    expect(unknown.label, '???');
    expect(unknown.description, isNull);
    expect(unknown.thumbnailFilePath, isNull);
    expect(result.withMessage('message').regionalMap, same(result.regionalMap));
  });

  test(
      'unavailable image preserves the list and configured empty map adds no fake location',
      () async {
    final builder = const RuntimeRegionalMapBuilder();
    final state = const GameState(saveId: 's', currentMapId: 'pension');
    final missing = await builder.build(
        gameState: state,
        projectRootDirectory: root.path,
        locale: 'en',
        catalog: _catalog(imagePath: 'assets/missing.png'));
    expect(missing.regionalMap!.regions.single.imageFilePath, isNull);
    expect(missing.entries, hasLength(2));
    expect(missing.entries.first.title, 'Hanazuki EN');
    final empty = await builder.build(
        gameState: state,
        projectRootDirectory: root.path,
        locale: 'en',
        catalog: ProjectRegionalMapCatalog());
    expect(empty.regionalMap!.regions, isEmpty);
    expect(empty.entries, isEmpty);
    expect(empty.emptyMessage, contains('No location'));
  });

  test('image resolution refuses escapes and symlinks outside the project',
      () async {
    final outside = await Directory.systemTemp.createTemp('menu9-outside-');
    addTearDown(() => outside.delete(recursive: true));
    final image = File('${outside.path}/private.png');
    await image.writeAsBytes([1, 2, 3]);
    await Directory('${root.path}/assets').create();
    await Link('${root.path}/assets/escape.png').create(image.path);
    for (final path in ['assets/escape.png']) {
      final result = await const RuntimeRegionalMapBuilder().build(
          gameState: const GameState(saveId: 's', currentMapId: 'pension'),
          projectRootDirectory: root.path,
          locale: 'fr',
          catalog: _catalog(imagePath: path));
      expect(result.regionalMap!.regions.single.imageFilePath, isNull,
          reason: path);
    }
    for (final path in [
      '../private.png',
      image.path,
      'https://example.test/map.png'
    ]) {
      expect(() => _catalog(imagePath: path), throwsFormatException);
    }
  });

  test('all authoring image media types resolve to their packaged blob',
      () async {
    for (final mime in ['image/png', 'image/jpeg', 'image/webp', 'image/gif']) {
      final artifact =
          ContentArtifactRef.fromBytes(utf8.encode(mime), mediaType: mime);
      final blob = File('${root.path}/${assetBlobStorageKey(artifact)}');
      await blob.parent.create(recursive: true);
      await blob.writeAsString(mime);
      await File('${root.path}/$assetCatalogStorageKey').writeAsString(
          jsonEncode(AssetCatalog(records: [
        AssetRecord(id: 'map', logicalPath: 'assets/map', artifact: artifact)
      ]).toJson()));
      final result = await const RuntimeRegionalMapBuilder().build(
          gameState: const GameState(saveId: 's', currentMapId: 'pension'),
          projectRootDirectory: root.path,
          locale: 'fr',
          catalog: _catalog(imagePath: 'assets/map'));
      expect(result.regionalMap!.regions.single.imageFilePath,
          await blob.resolveSymbolicLinks(),
          reason: mime);
    }
  });
}

ProjectRegionalMapCatalog _catalog({String? imagePath}) =>
    ProjectRegionalMapCatalog(
      regions: [
        ProjectRegionDefinition(
            id: 'train', label: 'Le train de 17h42', imagePath: imagePath)
      ],
      pointsOfInterest: [
        ProjectRegionPointOfInterest(
            id: 'town',
            regionId: 'train',
            label: 'Hanazuki',
            labels: const {'en': 'Hanazuki EN'},
            u: .25,
            v: .5,
            mapIds: const ['pension', 'village', 'station'],
            description: 'Le départ.'),
        ProjectRegionPointOfInterest(
            id: 'unknown',
            regionId: 'train',
            label: 'Secret name',
            u: .75,
            v: .5,
            mapIds: const ['later'],
            description: 'Secret description',
            thumbnailPath: 'assets/secret.png'),
        ProjectRegionPointOfInterest(
            id: 'hidden',
            regionId: 'train',
            label: 'Hidden name',
            u: .75,
            v: .5,
            visibility: ProjectRegionPointVisibility.hidden,
            mapIds: const ['pension']),
      ],
    );
