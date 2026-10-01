import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/gameplay/project_capture_sprite_provisioning_service.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;
  late List<int> sprite;
  late ProjectCaptureSpritePack pack;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('capture-sprites-test-');
    sprite = image.encodePng(image.Image(width: 64, height: 2048));
    pack = _pack(sprite);
  });
  tearDown(() => root.delete(recursive: true));

  test('the CLI provisions only catalog Balls from the default Studio pack',
      () async {
    final project = await _project(
        root, 'cli-default', [_ball('poke_ball'), _ball('great_ball')]);
    final result = await Process.run(Platform.resolvedExecutable, [
      'run',
      'tool/import_project_capture_sprites.dart',
      '--project',
      project.path,
    ]);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    final output = jsonDecode(result.stdout as String) as Map;
    expect(output['importedItems'], ['poke_ball', 'great_ball']);
    expect(output['updatedItems'], ['poke_ball', 'great_ball']);
    expect(
        (output['receipts'] as List)
            .map((receipt) => (receipt as Map)['actionId']),
        ['asset.import_batch', 'item.update', 'item.update']);
    final archive = ZipDecoder().decodeBytes(await File(p.join(
            Directory.current.path,
            '..',
            '..',
            'apps',
            'avelune_studio',
            'assets',
            'pokemon',
            'capture_sprites',
            'sprites.zip'))
        .readAsBytes());
    expect(
        await File(p.join(project.path,
                'data/pokemon/assets/items/great_ball/animation.png'))
            .readAsBytes(),
        archive.findFile('ball_2.png')!.content);
    expect(
        (await _catalog(project))
            .entries
            .every((item) => item.capture!.rateNumerator == 1),
        isTrue);
    expect(
        await File(p.join(project.path,
                'data/pokemon/assets/items/ultra_ball/animation.png'))
            .exists(),
        isFalse);
  });

  test('imports the matched project Ball and updates its capture reference',
      () async {
    final project = await _project(
        root, 'matched', [_ball('poke_ball'), _ball('story_ball')]);

    final result = await provisionProjectCaptureSprites(
      projectPath: project.path,
      loadPack: () async => pack,
    );

    expect(result['importedItems'], ['poke_ball']);
    expect(result['unavailableItems'], ['story_ball']);
    final catalog = await _catalog(project);
    expect(catalog.entries.first.capture!.animationSpritePath,
        'data/pokemon/assets/items/poke_ball/animation.png');
    expect(catalog.entries.last.capture!.animationSpritePath, isNull);
    expect(
        await File(p.join(project.path,
                'data/pokemon/assets/items/poke_ball/animation.png'))
            .readAsBytes(),
        sprite);
    final assets = AssetCatalog.fromJson(jsonDecode(
        await File(p.join(project.path, assetCatalogStorageKey))
            .readAsString()) as Map<String, dynamic>);
    expect(assets.records, hasLength(2));
    expect(
        (result['receipts'] as List).map((entry) => (entry as Map)['actionId']),
        ['asset.import_batch', 'item.update']);
  });

  test('preserves explicit custom references without loading the pack',
      () async {
    final project = await _project(
        root, 'custom', [_ball('poke_ball', path: 'assets/art/custom.png')]);
    final before =
        await File(p.join(project.path, 'data/pokemon/catalogs/items.json'))
            .readAsBytes();
    final result = await provisionProjectCaptureSprites(
        projectPath: project.path,
        loadPack: () async => throw StateError('The pack must not load.'));
    expect(result['preservedItems'], ['poke_ball']);
    expect(result['receipts'], isEmpty);
    expect(
        await File(p.join(project.path, 'data/pokemon/catalogs/items.json'))
            .readAsBytes(),
        before);
    expect(await File(p.join(project.path, assetCatalogStorageKey)).exists(),
        isFalse);
  });

  test('does not inject assets into a Pokemon-disabled project', () async {
    final project =
        await _project(root, 'disabled', [_ball('poke_ball')], enabled: false);
    final result = await provisionProjectCaptureSprites(
        projectPath: project.path,
        loadPack: () async => throw StateError('The pack must not load.'));
    expect(result['skippedReason'], 'pokemon-disabled');
    expect(await File(p.join(project.path, assetCatalogStorageKey)).exists(),
        isFalse);
  });

  test('skips an absent catalog and rejects a malformed existing catalog',
      () async {
    final project = await _project(root, 'missing', [_ball('poke_ball')]);
    final file = File(p.join(project.path, 'data/pokemon/catalogs/items.json'));
    await file.delete();
    Future<ProjectCaptureSpritePack> absentPack() async =>
        throw StateError('The pack must not load.');
    final result = await provisionProjectCaptureSprites(
        projectPath: project.path, loadPack: absentPack);
    expect(result['skippedReason'], 'item-catalog-missing');
    await file.writeAsString('{"schemaVersion":1,"entries":[{}]}');
    await expectLater(
        provisionProjectCaptureSprites(
            projectPath: project.path, loadPack: absentPack),
        throwsFormatException);
  });

  test('does not assign animations to non-capture items', () async {
    final project = await _project(root, 'no-capture', [
      const ProjectItemDefinition(
          id: 'poke_ball', displayName: 'Object', pocketId: 'key'),
    ]);
    final result = await provisionProjectCaptureSprites(
        projectPath: project.path,
        loadPack: () async => throw StateError('The pack must not load.'));
    expect(result['receipts'], isEmpty);
    expect(result['importedItems'], isEmpty);
  });

  test('links an existing authored canonical sheet without overwriting it',
      () async {
    final project = await _project(root, 'existing', [_ball('poke_ball')]);
    final file = File(p.join(
        project.path, 'data/pokemon/assets/items/poke_ball/animation.png'));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(sprite);
    final result = await provisionProjectCaptureSprites(
        projectPath: project.path,
        loadPack: () async => throw StateError('The pack must not load.'));
    expect(result['importedItems'], isEmpty);
    expect(result['updatedItems'], ['poke_ball']);
    expect(result['preservedItems'], ['poke_ball']);
    expect(await file.readAsBytes(), sprite);
    expect(await File(p.join(project.path, assetCatalogStorageKey)).exists(),
        isFalse);
  });

  test(
      'reports a committed asset batch and resumes the remaining catalog update',
      () async {
    final project = await _project(root, 'interrupted', [_ball('poke_ball')]);
    final file = File(p.join(
        project.path, 'data/pokemon/assets/items/poke_ball/animation.png'));
    await expectLater(
        provisionProjectCaptureSprites(
            projectPath: project.path,
            loadPack: () async => pack,
            shouldContinue: () => !file.existsSync()),
        throwsA(isA<ProjectCaptureSpriteProvisioningPartialFailure>()
            .having(
                (error) => error.importedItems, 'importedItems', ['poke_ball'])
            .having((error) => error.updatedItems, 'updatedItems', isEmpty)
            .having((error) => error.receipts, 'receipts', hasLength(1))));
    expect(
        (await _catalog(project)).entries.single.capture!.animationSpritePath,
        isNull);
    await file.delete();
    final result = await provisionProjectCaptureSprites(
        projectPath: project.path,
        loadPack: () async => throw StateError('Managed bytes already exist.'));
    expect(result['updatedItems'], ['poke_ball']);
    expect(result['importedItems'], isEmpty);
  });

  test('validates hashes and sheet dimensions before importing anything',
      () async {
    for (final invalid in [
      _pack(sprite, digest: 'incorrect'),
      _pack(image.encodePng(image.Image(width: 32, height: 1024)),
          width: 32, height: 1024),
      _pack(sprite, sheet: 'ball_s1'),
    ]) {
      final project = await _project(
          root, 'invalid-${invalid.archiveBytes.length}', [_ball('poke_ball')]);
      await expectLater(
          provisionProjectCaptureSprites(
              projectPath: project.path, loadPack: () async => invalid),
          throwsFormatException);
      expect(await File(p.join(project.path, assetCatalogStorageKey)).exists(),
          isFalse);
    }
  });

  test('rejects symbolic links and unsafe item identifiers', () async {
    final project = await _project(root, 'linked', [_ball('poke_ball')]);
    final outside = await Directory(p.join(root.path, 'outside')).create();
    await Link(p.join(project.path, 'data/pokemon/assets'))
        .create(outside.path);
    await expectLater(
        provisionProjectCaptureSprites(
            projectPath: project.path, loadPack: () async => pack),
        throwsFormatException);
    expect(await outside.list().toList(), isEmpty);
    final unsafe = await _project(root, 'unsafe', [_ball('../poke_ball')]);
    await expectLater(
        provisionProjectCaptureSprites(
            projectPath: unsafe.path, loadPack: () async => pack),
        throwsFormatException);
  });

  test('cancels a superseded preparation before mutations', () async {
    final project = await _project(root, 'cancelled', [_ball('poke_ball')]);
    var current = true;
    await expectLater(
        provisionProjectCaptureSprites(
            projectPath: project.path,
            shouldContinue: () => current,
            loadPack: () async {
              current = false;
              return pack;
            }),
        throwsA(isA<ProjectCaptureSpriteProvisioningCancelled>()));
    expect(await File(p.join(project.path, assetCatalogStorageKey)).exists(),
        isFalse);
  });

  test('uses aliases only for source mapping and isolates different projects',
      () async {
    final first = await _project(root, 'first', [
      _ball('custom_ball', aliases: ['poke-ball'])
    ]);
    final second = await _project(root, 'second',
        [_ball('custom_ball', path: 'assets/art/personal.png')]);
    final result = await provisionProjectCaptureSprites(
        projectPath: first.path, loadPack: () async => pack);
    expect(result['importedItems'], ['custom_ball']);
    expect((await _catalog(first)).entries.single.capture!.animationSpritePath,
        'data/pokemon/assets/items/custom_ball/animation.png');
    await provisionProjectCaptureSprites(
        projectPath: second.path,
        loadPack: () async =>
            throw StateError('The second project has its own choice.'));
    expect((await _catalog(second)).entries.single.capture!.animationSpritePath,
        'assets/art/personal.png');
    final repeated = await provisionProjectCaptureSprites(
        projectPath: first.path,
        loadPack: () async =>
            throw StateError('Existing references are preserved.'));
    expect(repeated['receipts'], isEmpty);
  });
}

ProjectItemDefinition _ball(String id,
        {String? path, List<String> aliases = const []}) =>
    ProjectItemDefinition(
        id: id,
        displayName: id,
        pocketId: 'balls',
        aliases: aliases,
        capture: ProjectCaptureItemDefinition(
            rateNumerator: 1,
            rateDenominator: 1,
            allowedEncounterKinds: {EncounterKind.walk},
            animationSpritePath: path));

Future<Directory> _project(
    Directory root, String name, List<ProjectItemDefinition> entries,
    {bool enabled = true}) async {
  final project = await Directory(p.join(root.path, name)).create();
  await File(p.join(project.path, 'project.json')).writeAsString(jsonEncode(
    ProjectManifest(
            name: name,
            maps: const [],
            tilesets: const [],
            pokemon: ProjectPokemonConfig(
                enabled: enabled, ruleset: PokemonRulesetProfile.pokeMapBetaV1))
        .toJson(),
  ));
  final file = File(p.join(project.path, 'data/pokemon/catalogs/items.json'));
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(encodeProjectItemCatalog(
      ProjectItemCatalog(schemaVersion: 1, entries: entries))));
  return project;
}

Future<ProjectItemCatalog> _catalog(Directory project) async =>
    decodeProjectItemCatalog(jsonDecode(
        await File(p.join(project.path, 'data/pokemon/catalogs/items.json'))
            .readAsString()));

ProjectCaptureSpritePack _pack(List<int> sprite,
    {String sheet = 'ball_1',
    int width = 64,
    int height = 2048,
    String? digest}) {
  final archive = Archive()
    ..addFile(ArchiveFile('$sheet.png', sprite.length, sprite));
  final zip = ZipEncoder().encode(archive);
  return ProjectCaptureSpritePack(
      archiveBytes: zip,
      manifestBytes: utf8.encode(jsonEncode({
        'schemaVersion': 1,
        'source': 'Fixture PSDK project',
        'archiveSha256': sha256.convert(zip).toString(),
        'itemMappings': {'poke_ball': sheet},
        'files': {
          sheet: {
            'sourcePath': 'graphics/ball/$sheet.png',
            'sha256': digest ?? sha256.convert(sprite).toString(),
            'bytes': sprite.length,
            'width': width,
            'height': height
          }
        },
      })));
}
