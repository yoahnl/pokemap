import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  for (final reference in ['model', 'sourceAsset', 'blob']) {
    test('catalog-backed Pokémon media retains a $reference reference',
        () async {
      final root =
          await Directory.systemTemp.createTemp('model-pokemon-media-');
      addTearDown(() => root.delete(recursive: true));
      final files = spatialPayload();
      final project = ProjectManifest.fromJson(
          jsonDecode(utf8.decode(files['project/project.json']!)));
      final map = MapData.fromJson(
          jsonDecode(utf8.decode(files['project/maps/map.json']!)));
      final assets = AssetCatalog.fromJson(
          jsonDecode(utf8.decode(files['project/$assetCatalogStorageKey']!)));
      final model = project.models3d.single;
      final source = assets.require(model.sourceAssetId);
      final blob = assetBlobStorageKey(source.artifact);
      const mediaDir = 'assets/pokemon/media';
      final media = PokemonMediaFile(
          speciesId: 'synthetic',
          defaultFormId: 'base',
          variants: {
            'base': PokemonMediaVariant(unrecognizedFields: {
              'overworldDecoration': switch (reference) {
                'model' => {'modelId': model.id},
                'sourceAsset' => {'sourceAssetId': source.id},
                _ => {'sourcePath': blob},
              },
            })
          });
      final mediaBytes = utf8.encode(jsonEncode(media.toJson()));
      final mediaRecord = AssetRecord(
          id: 'synthetic-media',
          logicalPath: '$mediaDir/synthetic.json',
          artifact: ContentArtifactRef.fromBytes(mediaBytes,
              mediaType: 'application/json'));
      files['project/project.json'] = utf8.encode(jsonEncode(project
          .copyWith(
              pokemon:
                  project.pokemon.copyWith(enabled: true, mediaDir: mediaDir))
          .toJson()));
      files['project/maps/map.json'] = utf8.encode(jsonEncode(map
          .copyWith(spatialScene: map.spatialScene!.copyWith(instances: []))
          .toJson()));
      files['project/$assetCatalogStorageKey'] = utf8.encode(jsonEncode(
          AssetCatalog(records: [...assets.records, mediaRecord]).toJson()));
      files['project/${assetBlobStorageKey(mediaRecord.artifact)}'] =
          mediaBytes;
      for (final entry in files.entries) {
        final file =
            File('${root.path}/${entry.key.substring('project/'.length)}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value);
      }
      final projection = await const RuntimeProjectProjectionBuilder().build(
          projectRoot: root,
          profile: GamePackageExportProfile(
              gameId: 'games.example.document',
              gameVersion: '1.0.0',
              title: 'Documents',
              authorName: 'Yoahn',
              defaultLocale: 'fr',
              supportedLocales: ['fr']));
      final exported = projection.payloadFiles;
      expect(projection.project.models3d.map((item) => item.id),
          reference == 'model' ? [model.id] : isEmpty);
      expect(
          jsonDecode(
              utf8.decode(exported['project/${mediaRecord.logicalPath}']!)),
          media.toJson());
      expect(exported['project/$blob'], files['project/$blob']);
      if (reference == 'sourceAsset') {
        final catalog = AssetCatalog.fromJson(jsonDecode(
            utf8.decode(exported['project/$assetCatalogStorageKey']!)));
        expect(catalog.require(source.id).toJson(), source.toJson());
      }
    });
  }
}
