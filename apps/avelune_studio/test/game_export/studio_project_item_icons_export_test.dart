import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:avelune_studio/features/game_export/data/studio_game_export_controller.dart';
import 'package:avelune_studio/features/game_export/data/studio_export_revision.dart';
import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/features/pokemon/data/studio_project_item_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:path/path.dart' as p;
import '../support/game_export_fixture.dart';
import '../support/m3_story_fixture.dart';
import 'studio_project_item_icons_export_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late M3StoryFixture source;
  late Directory destination;
  late File output;

  setUp(() async {
    source = await M3StoryFixture.create();
    await prepareGameExportFixture(source);
    destination = await Directory.systemTemp.createTemp('studio-item-export-');
    output = File(p.join(destination.path, 'game.avelunegame'));
  });

  tearDown(() async {
    await source.directory.delete(recursive: true);
    await destination.delete(recursive: true);
  });

  Future<bool> export(
    StudioGameExportController controller, {
    Future<bool> Function()? prepare,
  }) => controller.export(
    metadata: const StudioGameExportMetadata(
      gameId: 'games.avelune.item-icons',
      title: 'Project item icons',
      version: '0.1.0',
      author: 'Avelune',
      locale: 'fr',
      locales: 'fr',
    ),
    outputPath: output.path,
    overwriteConfirmed: false,
    publication: false,
    prepare: prepare ?? () async => true,
    hasPendingChanges: () => false,
    isCurrentProject: () => true,
  );

  test(
    'Studio provisions saved item icons before building the game package',
    () async {
      final icon = File(
        p.join(source.directory.path, 'data/pokemon/assets/items/potion.png'),
      );
      final controller = StudioGameExportController(
        projectRoot: source.directory,
        projectName: source.session.name,
        buildPackage: (root, profile, mode) async {
          expect(
            await icon.exists(),
            isTrue,
            reason: 'Item icons must exist before package construction.',
          );
          return CanonicalGamePackageExportService(
            pokemonValidator: acceptPokemonProjection,
          ).build(projectRoot: root, profile: profile, mode: mode);
        },
      );
      addTearDown(controller.dispose);

      final succeeded = await export(
        controller,
        prepare: () async {
          await enableItems(source.directory);
          return true;
        },
      );

      expect(succeeded, isTrue, reason: controller.error);
      expect(await output.exists(), isTrue);
      expect(controller.warning, isNull);
      final pack = await rootBundle.load('assets/pokemon/item_icons/icons.zip');
      final manifest = await rootBundle.loadString(
        'assets/pokemon/item_icons/manifest.json',
      );
      expect(jsonDecode(manifest)['items']['potion'], isNotNull);
      final sourceArchive = ZipDecoder().decodeBytes(
        pack.buffer.asUint8List(pack.offsetInBytes, pack.lengthInBytes),
      );
      final expectedPixels = sourceArchive.findFile('potion.png')!.content;
      final archive = ZipDecoder().decodeBytes(await output.readAsBytes());
      expect(await icon.readAsBytes(), expectedPixels);
      expect(
        archive
            .findFile('project/data/pokemon/assets/items/potion.png')!
            .content,
        expectedPixels,
      );
      final provenance = archive.files.singleWhere(
        (file) =>
            file.name.startsWith('project/data/pokemon/assets/items/source-') &&
            file.name.endsWith('.json'),
      );
      final metadata = jsonDecode(utf8.decode(provenance.content)) as Map;
      expect((metadata['icons'] as List).single['projectItemId'], 'potion');
      expect(metadata['licenseText'], isNotEmpty);
      expect(
        archive.files.where((file) => file.name.endsWith('icons.zip')),
        isEmpty,
      );
      final assets =
          jsonDecode(
                await File(
                  p.join(source.directory.path, 'assets/.pokemap-assets.json'),
                ).readAsString(),
              )
              as Map;
      expect(
        (assets['records'] as List).any(
          (entry) =>
              entry['logicalPath'] == 'data/pokemon/assets/items/potion.png',
        ),
        isTrue,
      );
    },
  );

  test(
    'Studio preserves custom item pixels in the project and game package',
    () async {
      await enableItems(source.directory);
      final customPixels = image.encodePng(image.Image(width: 3, height: 2));
      final icon = File(
        p.join(source.directory.path, 'data/pokemon/assets/items/potion.png'),
      );
      await icon.parent.create(recursive: true);
      await icon.writeAsBytes(customPixels);
      final controller = StudioGameExportController(
        projectRoot: source.directory,
        projectName: source.session.name,
        buildPackage: buildItemIconsPackage,
      );
      addTearDown(controller.dispose);

      expect(await export(controller), isTrue, reason: controller.error);

      final archive = ZipDecoder().decodeBytes(await output.readAsBytes());
      expect(await icon.readAsBytes(), customPixels);
      expect(
        archive
            .findFile('project/data/pokemon/assets/items/potion.png')!
            .content,
        customPixels,
      );
      expect(
        await File(
          p.join(source.directory.path, 'assets/.pokemap-assets.json'),
        ).exists(),
        isFalse,
      );
    },
  );

  test(
    'Studio exports neutral projects without loading or installing item art',
    () async {
      final bundle = ItemIconBundle(const {});
      final icons = StudioProjectItemIcons(bundle: bundle);
      final before = await sourceFingerprints(source.directory.path);
      final controller = StudioGameExportController(
        projectRoot: source.directory,
        projectName: source.session.name,
        prepareProjectAssets: icons.prepare,
        buildPackage: buildItemIconsPackage,
      );
      addTearDown(controller.dispose);

      expect(await export(controller), isTrue, reason: controller.error);

      expect(bundle.requests, isEmpty);
      expect(await sourceFingerprints(source.directory.path), before);
      expect(
        await Directory(
          p.join(source.directory.path, 'data/pokemon/assets/items'),
        ).exists(),
        isFalse,
      );
      final archive = ZipDecoder().decodeBytes(await output.readAsBytes());
      expect(
        archive.files.where(
          (file) => file.name.startsWith('project/data/pokemon/assets/items/'),
        ),
        isEmpty,
      );
    },
  );

  test(
    'Studio blocks export when the item icon pack cannot be verified',
    () async {
      await enableItems(source.directory);
      final bundle = ItemIconBundle({
        'assets/pokemon/item_icons/manifest.json': utf8.encode(
          jsonEncode({
            'schemaVersion': 1,
            'archiveSha256': 'invalid',
            'licensePath': 'LICENCE.txt',
          }),
        ),
        'assets/pokemon/item_icons/icons.zip': [1, 2, 3],
      });
      final icons = StudioProjectItemIcons(bundle: bundle);
      var builds = 0;
      var writes = 0;
      final before = await sourceFingerprints(source.directory.path);
      final controller = StudioGameExportController(
        projectRoot: source.directory,
        projectName: source.session.name,
        prepareProjectAssets: icons.prepare,
        buildPackage: (root, profile, mode) {
          builds++;
          return buildItemIconsPackage(root, profile, mode);
        },
        writePackage: (_, _) async {
          writes++;
        },
      );
      addTearDown(controller.dispose);

      expect(await export(controller), isFalse);

      expect(controller.stage, StudioExportStage.failed);
      expect(controller.error, contains('does not match its manifest'));
      expect(bundle.requests, [
        'assets/pokemon/item_icons/manifest.json',
        'assets/pokemon/item_icons/icons.zip',
      ]);
      expect(builds, 0);
      expect(writes, 0);
      expect(await output.exists(), isFalse);
      expect(await sourceFingerprints(source.directory.path), before);
    },
  );
}
