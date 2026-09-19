import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_runtime/map_runtime.dart'
    show characterAnimationRuntimeImageId;
import 'package:map_runtime/map_runtime_authoring.dart';
import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import '../../tool/create_example_project.dart';
import '../../tool/example_project_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'dedicated Character Studio asset uses canonical pixel source and shared image budget',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'studio_m3_asset_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final bytes = exampleAtlasPng();
      final artifact = ContentArtifactRef.fromBytes(
        bytes,
        mediaType: 'image/png',
      );
      final blob = File('${directory.path}/${assetBlobStorageKey(artifact)}');
      await blob.parent.create(recursive: true);
      await blob.writeAsBytes(bytes);
      final catalog = AssetCatalog(
        records: [
          AssetRecord(
            id: 'prepared',
            logicalPath: 'characters/prepared.png',
            artifact: artifact,
          ),
        ],
      );
      final catalogFile = File('${directory.path}/$assetCatalogStorageKey');
      await catalogFile.parent.create(recursive: true);
      await catalogFile.writeAsString(jsonEncode(catalog.toJson()));
      const character = ProjectCharacterEntry(
        id: 'prepared',
        name: 'Préparé',
        tilesetId: '',
        frameWidth: 2,
        frameHeight: 2,
        animations: [
          CharacterAnimation(
            state: CharacterAnimationState.idle,
            direction: EntityFacing.south,
            sourceAssetId: 'prepared',
            frames: [
              CharacterAnimationFrame(
                source: TilesetSourceRect(x: 128, y: 0, width: 32, height: 32),
              ),
            ],
          ),
        ],
      );
      const manifest = ProjectManifest(
        name: 'Assets',
        maps: [],
        tilesets: [],
        characters: [character],
      );
      final session = ProjectSession(
        sessionId: 'asset',
        name: 'Assets',
        directoryPath: await directory.resolveSymbolicLinks(),
      );
      final resources = await StudioMapResources.load(
        session,
        manifest,
        maximumBytes: 60000,
      );
      addTearDown(resources.dispose);
      expect(resources.images, isEmpty);
      resources.setCharacterBrush(character);
      await resources.settled;
      expect(resources.images.keys, [
        characterAnimationRuntimeImageId('prepared'),
      ]);
      expect(resources.store.decoder.decodes, 1);
      final renderer = RuntimeAuthoringCharacterRenderer(
        character: character,
        settings: manifest.settings,
        images: resources.images,
      );
      expect(renderer.hasVisual, isTrue);
      final recorder = ui.PictureRecorder();
      renderer.paintThumbnail(
        ui.Canvas(recorder),
        const ui.Rect.fromLTWH(0, 0, 64, 64),
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(64, 64);
      picture.dispose();
      final rgba = (await image.toByteData())!.buffer.asUint8List();
      image.dispose();
      final offset = (30 * 64 + 32) * 4;
      expect(rgba.sublist(offset, offset + 4), [103, 158, 207, 255]);
      final retained = resources.images.values.single;
      await resources.dispose();
      expect(retained.debugDisposed, isTrue);
    },
  );
  test(
    'existing sprite pixels render on map and instance survives canonical save/reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'studio_m3_character_',
      );
      addTearDown(() => directory.delete(recursive: true));
      await writeExampleProject(directory);
      final session = ProjectSession(
        sessionId: 'characters',
        name: 'Characters',
        directoryPath: await directory.resolveSymbolicLinks(),
      );
      final adapter = LocalMapWorkspaceAdapter();
      final manifest = await adapter.loadProject(session);
      final document = EditableMapDocument(
        await adapter.loadMap(session, manifest.maps.first),
      );
      final commands = CharacterEditingCommands(document, manifest);
      final instance = commands.place(
        manifest.characters.single,
        const GridPos(x: 8, y: 8),
      );
      commands.update(
        instance.id,
        name: 'Chef de gare',
        facing: EntityFacing.west,
        blocks: false,
      );
      final resources = await StudioMapResources.load(session, manifest);
      addTearDown(resources.dispose);
      resources.setCharacterBrush(manifest.characters.single);
      resources.setActiveMap(document.current);
      await resources.settled;
      expect(resources.store.decoder.decodes, 1);
      final recorder = ui.PictureRecorder();
      resources.renderer(document.current).paint(ui.Canvas(recorder));
      final picture = recorder.endRecording();
      final image = await picture.toImage(768, 512);
      picture.dispose();
      final bytes = (await image.toByteData())!.buffer.asUint8List();
      image.dispose();
      var shirtPixels = 0;
      for (var y = 224; y < 288; y++) {
        for (var x = 240; x < 304; x++) {
          final offset = (y * 768 + x) * 4;
          if (bytes[offset] == 103 &&
              bytes[offset + 1] == 158 &&
              bytes[offset + 2] == 207) {
            shirtPixels++;
          }
        }
      }
      expect(shirtPixels, greaterThan(40));
      final revision = await adapter.saveMap(
        session,
        document.base,
        document.current,
      );
      document.acceptSave(document.current, revision);
      final reopened = LocalMapWorkspaceAdapter();
      await reopened.loadProject(session);
      final fromDisk = await reopened.loadMap(session, manifest.maps.first);
      expect(fromDisk.map, document.current);
      final saved = fromDisk.map.entities.firstWhere(
        (entity) => entity.id == instance.id,
      );
      expect(saved.npc!.displayName, 'Chef de gare');
      expect(saved.npc!.characterId, manifest.characters.single.id);
      expect(saved.npc!.facing, EntityFacing.west);
      expect(saved.blocksMovement, isFalse);
      final projectBytes = await File(
        '${directory.path}/project.json',
      ).readAsString();
      expect(
        ProjectManifest.fromJson(
          jsonDecode(projectBytes) as Map<String, dynamic>,
        ),
        manifest,
      );
      resources.setCharacterBrush(null);
      expect(resources.images, isNotEmpty);
      final retained = resources.images.values.single;
      await resources.dispose();
      expect(retained.debugDisposed, isTrue);
      expect(resources.decodedBytes, 0);
    },
  );
}
