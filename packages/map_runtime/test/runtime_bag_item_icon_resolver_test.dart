import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/player/runtime_bag_item_icon_resolver.dart';
import 'package:map_runtime/src/player/runtime_bundled_item_icons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late Directory cache;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('runtime-bag-icons-');
    cache = await Directory.systemTemp.createTemp('runtime-bag-icon-cache-');
  });

  tearDown(() async {
    await root.delete(recursive: true);
    await cache.delete(recursive: true);
  });

  Future<File> write(String path, [String contents = 'image']) async {
    final file = File('${root.path}/$path');
    await file.parent.create(recursive: true);
    return file.writeAsString(contents);
  }

  RuntimeBagItemIconResolver resolver() => RuntimeBagItemIconResolver(
        projectRootDirectory: root.path,
        pokemonConfig: const ProjectPokemonConfig(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1),
        bundledIcons:
            RuntimeBundledItemIcons(cacheDirectory: () async => cache),
      );

  test('provides offline canonical item art without project imports', () async {
    final icons = resolver();
    for (final itemId in [
      'potion',
      'super_potion',
      'poke_ball',
      'oran_berry'
    ]) {
      final path = await icons.resolve(itemId);
      expect(path, isNotNull, reason: itemId);
      expect(await File(path!).readAsBytes(), isNotEmpty);
    }
    expect(await icons.resolve('poke-ball'), await icons.resolve('poke_ball'));
    expect(await icons.resolve('a_custom_story_item'), isNull);
    expect(await root.list().toList(), isEmpty);
  });

  test('resolves authored local icons and the canonical item asset', () async {
    final authored = await write('assets/items/heal.png');
    final canonical = await write('data/pokemon/assets/items/key.png');
    await write(
      'data/pokemon/catalogs/items.json',
      jsonEncode({
        'entries': [
          {'id': 'potion', 'localSpritePath': 'assets/items/heal.png'},
        ],
      }),
    );
    final icons = resolver();
    expect(
        await icons.resolve('potion'), await authored.resolveSymbolicLinks());
    expect(await icons.resolve('key'), await canonical.resolveSymbolicLinks());
    expect(await icons.resolve('missing'), isNull);
  });

  test('rejects absolute, traversal, remote and escaping symbolic link icons',
      () async {
    final outside = await Directory.systemTemp.createTemp('outside-bag-icons-');
    addTearDown(() => outside.delete(recursive: true));
    final outsideIcon =
        await File('${outside.path}/icon.png').writeAsString('x');
    await Link('${root.path}/escape.png').create(outsideIcon.path);
    await write(
      'data/pokemon/catalogs/items.json',
      jsonEncode({
        'entries': [
          {'id': 'absolute', 'localSpritePath': outsideIcon.path},
          {'id': 'windows', 'localSpritePath': r'C:\outside\icon.png'},
          {'id': 'traversal', 'localSpritePath': '../icon.png'},
          {'id': 'remote', 'localSpritePath': 'https://example.com/icon.png'},
          {'id': 'linked', 'localSpritePath': 'escape.png'},
        ],
      }),
    );
    final icons = resolver();
    for (final itemId in [
      'absolute',
      'windows',
      'traversal',
      'remote',
      'linked'
    ]) {
      expect(await icons.resolve(itemId), isNull, reason: itemId);
    }
    expect(await icons.resolve('../potion'), isNull);
    expect(await icons.resolve('folder/potion'), isNull);
  });

  test('degrades malformed catalogs to missing or canonical local assets',
      () async {
    await write('data/pokemon/catalogs/items.json', '{invalid');
    final canonical = await write('data/pokemon/assets/items/potion.png');
    final icons = resolver();
    expect(
        await icons.resolve('potion'), await canonical.resolveSymbolicLinks());
    expect(await icons.resolve('missing'), isNull);
  });

  test('missing authored art falls back to canonical local then bundled art',
      () async {
    final canonical = await write('data/pokemon/assets/items/potion.png');
    await write(
      'data/pokemon/catalogs/items.json',
      jsonEncode({
        'entries': [
          {'id': 'potion', 'localSpritePath': 'missing/potion.png'},
          {'id': 'poke_ball', 'localSpritePath': 'missing/ball.png'},
        ],
      }),
    );
    final icons = resolver();
    expect(
        await icons.resolve('potion'), await canonical.resolveSymbolicLinks());
    expect(await icons.resolve('poke_ball'), isNotNull);
  });

  test('repairs a damaged cache and recreates a removed cached icon', () async {
    final icons = resolver();
    final path = (await icons.resolve('potion'))!;
    final original = await File(path).readAsBytes();
    await File(path).writeAsBytes(List.filled(original.length, 0));
    expect(await icons.resolve('potion'), path);
    expect(await File(path).readAsBytes(), original);
    await File(path).delete();
    final paths =
        await Future.wait(List.generate(6, (_) => icons.resolve('potion')));
    expect(paths.toSet(), {path});
    expect(await File(path).readAsBytes(), original);
  });

  test('never writes through a symbolic link in the item cache', () async {
    final icons = resolver();
    final path = (await icons.resolve('potion'))!;
    await File(path).delete();
    final outside = await write('outside.png', 'original');
    await Link(path).create(outside.path);
    expect(await icons.resolve('potion'), isNull);
    expect(await outside.readAsString(), 'original');
  });

  test('never creates directories through a linked cache parent', () async {
    final outside =
        await Directory.systemTemp.createTemp('outside-item-cache-');
    addTearDown(() => outside.delete(recursive: true));
    await Link('${cache.path}/pokemap-menu-item-icons').create(outside.path);
    expect(await resolver().resolve('potion'), isNull);
    expect(await outside.list().toList(), isEmpty);
  });

  test('resolves the explicitly verified Kings Rock canonical alias', () async {
    final icons = resolver();
    final canonical = await icons.resolve('kings-rock');
    expect(canonical, isNotNull);
    expect(await icons.resolve('king_s_rock'), canonical);
    expect(await icons.resolve('king_rock'), isNull);
  });

  test('preserves original illustration and pixel icon dimensions', () async {
    final icons = resolver();
    final source = jsonDecode(
      await File('tool/assets/menu_item_illustrations/manifest.json')
          .readAsString(),
    ) as Map<String, dynamic>;
    for (final entry in (source['items'] as Map<String, dynamic>).entries) {
      final metadata = entry.value as Map<String, dynamic>;
      final bytes = await File((await icons.resolve(entry.key))!).readAsBytes();
      expect(
        bytes,
        await File('tool/assets/menu_item_illustrations/${metadata['file']}')
            .readAsBytes(),
        reason: entry.key,
      );
      final illustration = image.decodePng(bytes)!;
      expect((
        illustration.width,
        illustration.height
      ), (
        metadata['width'],
        metadata['height']
      ), reason: entry.key);
      expect(illustration.hasAlpha, isTrue, reason: entry.key);
    }
    for (final item in ['poke_ball', 'oran_berry', 'pecha_berry']) {
      final sprite = image
          .decodePng(await File((await icons.resolve(item))!).readAsBytes())!;
      expect((sprite.width, sprite.height), (30, 30), reason: item);
      expect(sprite.hasAlpha, isTrue, reason: item);
    }
  });

  test('concurrent cache failures degrade to unavailable art', () async {
    final icons = RuntimeBundledItemIcons(
      cacheDirectory: () async =>
          throw const FileSystemException('Unavailable cache'),
    );
    expect(
      await Future.wait(List.generate(4, (_) => icons.resolve('potion'))),
      everyElement(isNull),
    );
  });
}
