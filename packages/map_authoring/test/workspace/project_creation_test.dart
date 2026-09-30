import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory parent;
  setUp(
      () async => parent = await Directory.systemTemp.createTemp('creation_'));
  tearDown(() async => parent.delete(recursive: true));

  for (final tileSize in [16, 32, 48]) {
    test(
        'preview $tileSize reflects full map dimensions without creating files',
        () async {
      final bytes = await const LocalProjectCreationService().preview(
          ProjectCreationRequest(
              name: '',
              folderName: '',
              parentPath: '',
              tileSize: tileSize,
              mapWidth: 40,
              mapHeight: 20));
      final preview = image.decodePng(Uint8List.fromList(bytes!))!;
      expect(preview.width, 640);
      expect(preview.height, 320);
      expect(preview.getPixel(0, 0).r, 82);
      expect(preview.getPixel(0, 10 * 16).r, 194);
      expect(await parent.list().toList(), isEmpty);
    });
    test(
        'playable $tileSize preserves grid, atlas and spawn on independent reopen',
        () async {
      final phases = <ProjectCreationPhase>[];
      final receipt = await const LocalProjectCreationService().create(
          ProjectCreationRequest(
              name: 'Mon jeu épatant',
              folderName: 'Jeu été $tileSize',
              parentPath: parent.path,
              tileSize: tileSize,
              mapWidth: 31,
              mapHeight: 19),
          onPhase: phases.add);
      final source = receipt.projectPath;
      final manifest = ProjectManifest.fromJson(
          jsonDecode(await File(p.join(source, 'project.json')).readAsString())
              as Map<String, dynamic>);
      final map = MapData.fromJson(jsonDecode(
          await File(p.join(source, manifest.maps.single.relativePath))
              .readAsString()) as Map<String, dynamic>);
      final catalog = AssetCatalog.fromJson(jsonDecode(
              await File(p.join(source, assetCatalogStorageKey)).readAsString())
          as Map<String, dynamic>);
      final asset = catalog.require('starter');
      final atlas = image.decodePng(
          await File(p.join(source, assetBlobStorageKey(asset.artifact)))
              .readAsBytes())!;
      expect(asset.logicalPath, manifest.tilesets.single.relativePath);
      expect(
          await File(p.join(source, manifest.tilesets.single.relativePath))
              .readAsBytes(),
          await File(p.join(source, assetBlobStorageKey(asset.artifact)))
              .readAsBytes());
      expect(manifest.name, 'Mon jeu épatant');
      expect(manifest.settings.tileWidth, tileSize);
      expect(manifest.settings.tileHeight, tileSize);
      expect(manifest.settings.defaultMapWidth, 31);
      expect(map.size, const GridSize(width: 31, height: 19));
      expect(atlas.width, tileSize * 16);
      expect(atlas.height, tileSize * 4);
      final tileset =
          manifest.tilesets.single.source! as ProjectRegularAtlasTilesetSource;
      expect(tileset.tileWidth, tileSize);
      expect(tileset.pixelWidth, atlas.width);
      final character = manifest.characters.single;
      expect(character.frameWidth, 2);
      expect(character.frameHeight, 2);
      for (final animation in character.animations) {
        expect(animation.sourceAssetId, 'starter');
        for (final frame in animation.frames) {
          expect(frame.source.x + frame.source.width,
              lessThanOrEqualTo(atlas.width));
          expect(frame.source.y + frame.source.height,
              lessThanOrEqualTo(atlas.height));
        }
      }
      expect(manifest.newGame.enabled, true);
      expect(manifest.newGame.startMapId, map.id);
      expect(manifest.newGame.startSpawnId, map.entities.single.id);
      expect(map.entities.single.spawn!.role, EntitySpawnRole.playerStart);
      expect(manifest.settings.defaultPlayerCharacterId, character.id);
      expect(manifest.pokemon.enabled, false);
      expect(manifest.settings.mistralApiKey, isNull);
      ProjectValidator.validate(manifest, maps: [map]);
      MapValidator.validate(map, projectDialogueContext: manifest);
      final reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [parent.path], fileReader: reader);
      final opened = await ProjectOpenService(
              policy: policy,
              fileReader: reader,
              handles: WorkspaceHandleStore())
          .openProject(source);
      expect(opened.projectName, manifest.name);
      expect(phases, ProjectCreationPhase.values);
    });

    test('empty $tileSize is authoring-only with persisted future map defaults',
        () async {
      final receipt = await const LocalProjectCreationService().create(
          ProjectCreationRequest(
              name: 'Vide',
              folderName: 'empty',
              parentPath: parent.path,
              tileSize: tileSize,
              template: ProjectCreationTemplate.empty,
              mapWidth: 42,
              mapHeight: 27));
      final manifest = ProjectManifest.fromJson(jsonDecode(
          await File(p.join(receipt.projectPath, 'project.json'))
              .readAsString()) as Map<String, dynamic>);
      expect(manifest.maps, isEmpty);
      expect(manifest.tilesets, isEmpty);
      expect(manifest.characters, isEmpty);
      expect(manifest.newGame.enabled, false);
      expect(manifest.settings.tileWidth, tileSize);
      expect(manifest.settings.tileHeight, tileSize);
      expect(manifest.settings.defaultMapWidth, 42);
      expect(manifest.settings.defaultMapHeight, 27);
    });
  }

  test('empty preview is honest absence, never an invented playable map',
      () async {
    expect(
        await const LocalProjectCreationService().preview(
            const ProjectCreationRequest(
                name: '',
                folderName: '',
                parentPath: '',
                template: ProjectCreationTemplate.empty)),
        isNull);
  });

  test('destination with intentional whitespace identifies its exact parent',
      () async {
    final chosen = await Directory(p.join(parent.path, ' selected ')).create();
    final path = await const LocalProjectCreationService().validateDestination(
        ProjectCreationRequest(
            name: 'Jeu', folderName: 'jeu', parentPath: chosen.path));
    expect(path, p.join(await chosen.resolveSymbolicLinks(), 'jeu'));
    expect(await Directory(p.join(parent.path, 'selected')).exists(), false);
  });

  test(
      'validation does not allocate files and refuses invalid or existing destinations',
      () async {
    final service = const LocalProjectCreationService();
    for (final name in [
      '',
      '..',
      '../ailleurs',
      'CON',
      'com1.txt',
      'a/b',
      'a\\b',
      'fin.',
      'x '
    ]) {
      expect(
          () => ProjectCreationRequest(
                  name: 'Jeu', folderName: name, parentPath: parent.path)
              .validate(),
          throwsFormatException);
    }
    final existing = await Directory(p.join(parent.path, 'existing')).create();
    await File(p.join(existing.path, 'keep')).writeAsString('preserve');
    await expectLater(
        service.create(ProjectCreationRequest(
            name: 'Jeu', folderName: 'existing', parentPath: parent.path)),
        throwsA(isA<ProjectCreationException>()));
    expect(
        await File(p.join(existing.path, 'keep')).readAsString(), 'preserve');
    expect((await parent.list().toList()).length, 1);
  });
}
