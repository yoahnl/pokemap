import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

void main() {
  for (final collision in [false, true]) {
    test('projects portable media and preserves sources; collision=$collision',
        () async {
      final root = await Directory.systemTemp.createTemp('manifest-copies-');
      addTearDown(() => root.delete(recursive: true));
      final project = ProjectManifest(
        name: 'Fixture',
        maps: const [
          ProjectMapEntry(
              id: 'start', name: 'Start', relativePath: 'maps/project 2.json')
        ],
        tilesets: const [
          ProjectTilesetEntry(
              id: 'npc', name: 'NPC', relativePath: 'characters/npc.png')
        ],
        cinematicMediaAssets: [
          CinematicMediaAsset(
              id: 'cry',
              label: 'Cry',
              kind: CinematicMediaAssetKind.sound,
              relativePath: 'audio/cry.ogg')
        ],
      );
      const map = MapData(
          id: 'start',
          name: 'Start',
          version: ProjectVersion.v8,
          size: GridSize(width: 2, height: 2),
          layers: [MapLayer.object(id: 'events', name: 'Events')]);
      final originalProject = jsonEncode(project.toJson());
      await File('${root.path}/project.json').writeAsString(originalProject);
      await Directory('${root.path}/maps').create();
      await File('${root.path}/maps/project 2.json')
          .writeAsString(jsonEncode(map.toJson()));
      await Directory('${root.path}/data').create();
      await File('${root.path}/data/project 2.json')
          .writeAsString('{"id":"quest"}');
      await Directory('${root.path}/characters').create();
      final pixels = image.encodePng(image.Image(width: 1, height: 1));
      await File('${root.path}/characters/npc.png').writeAsBytes(pixels);
      await File('${root.path}/characters/unused.png').writeAsBytes(pixels);
      await Directory('${root.path}/audio').create();
      final sound = Uint8List.fromList([0x4f, 0x67, 0x67, 0x53, 0x00]);
      await File('${root.path}/audio/cry.ogg').writeAsBytes(sound);
      final artifact =
          ContentArtifactRef.fromBytes(pixels, mediaType: 'image/png');
      final catalog = AssetCatalog(records: [
        AssetRecord(
            id: 'npc-source',
            logicalPath: 'characters/npc.png',
            artifact: artifact)
      ]);
      final catalogFile = File('${root.path}/$assetCatalogStorageKey');
      await catalogFile.parent.create(recursive: true);
      final originalCatalog = jsonEncode(catalog.toJson());
      await catalogFile.writeAsString(originalCatalog);
      final blob = File('${root.path}/${assetBlobStorageKey(artifact)}');
      await blob.parent.create(recursive: true);
      await blob.writeAsBytes(pixels);
      const names = ['project 2.json', 'project 10.json', 'project (2).json'];
      const backup = '{"sourcePath":"../../authoring-only.json"}';
      for (final name in names) {
        await File('${root.path}/$name').writeAsString(backup);
      }
      if (collision) {
        final target =
            File('${root.path}/assets/runtime-media/characters/npc.png');
        await target.parent.create(recursive: true);
        await target.writeAsBytes(pixels);
      }
      final build = const RuntimeProjectProjectionBuilder().build(
          projectRoot: root,
          profile: GamePackageExportProfile(
              gameId: 'games.example.manifest-copies',
              gameVersion: '0.1.0',
              title: 'Fixture',
              authorName: 'Fixture',
              defaultLocale: 'fr',
              supportedLocales: ['fr']));
      if (collision) {
        await expectLater(
            build,
            throwsA(isA<GamePackageExportException>().having(
                (error) => error.code, 'code', 'runtimeMediaAliasCollision')));
      } else {
        final projection = await build;
        for (final name in names) {
          expect(projection.payloadFiles, isNot(contains('project/$name')));
        }
        expect(projection.payloadFiles, contains('project/project.json'));
        expect(
            projection.payloadFiles, contains('project/maps/project 2.json'));
        expect(
            projection.payloadFiles, contains('project/data/project 2.json'));
        expect(
            projection.payloadFiles[
                'project/assets/runtime-media/characters/npc.png'],
            pixels);
        expect(
            projection
                .payloadFiles['project/assets/runtime-media/audio/cry.ogg'],
            sound);
        expect(projection.payloadFiles,
            isNot(contains('project/characters/npc.png')));
        expect(projection.payloadFiles,
            isNot(contains('project/characters/unused.png')));
        expect(
            projection.payloadFiles, isNot(contains('project/audio/cry.ogg')));
        expect(projection.project.tilesets.single.relativePath,
            'assets/runtime-media/characters/npc.png');
        expect(projection.project.cinematicMediaAssets.single.relativePath,
            'assets/runtime-media/audio/cry.ogg');
        final exportedCatalog = AssetCatalog.fromJson(jsonDecode(utf8.decode(
            projection.payloadFiles['project/$assetCatalogStorageKey']!)));
        expect(exportedCatalog.records.single.id, 'npc-source');
        expect(exportedCatalog.records.single.logicalPath,
            'assets/runtime-media/characters/npc.png');
        expect(exportedCatalog.records.single.artifact, artifact);
        const validator =
            GamePackageContentValidator(GamePackageSecurityPolicy());
        for (final entry in projection.payloadFiles.entries) {
          validator.validate(
              GamePackageFileEntry(
                  path: entry.key, size: entry.value.length, sha256: '0' * 64),
              Uint8List.fromList(entry.value));
        }
      }
      for (final name in names) {
        expect(await File('${root.path}/$name').readAsString(), backup);
      }
      expect(
          await File('${root.path}/characters/npc.png').readAsBytes(), pixels);
      expect(await File('${root.path}/audio/cry.ogg').readAsBytes(), sound);
      expect(await File('${root.path}/project.json').readAsString(),
          originalProject);
      expect(await catalogFile.readAsString(), originalCatalog);
    });
  }
}
