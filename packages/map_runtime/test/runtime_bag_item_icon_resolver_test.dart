import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/player/runtime_bag_item_icon_resolver.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('runtime-bag-icons-');
  });

  tearDown(() => root.delete(recursive: true));

  Future<File> write(String path, [String contents = 'image']) async {
    final file = File('${root.path}/$path');
    await file.parent.create(recursive: true);
    return file.writeAsString(contents);
  }

  RuntimeBagItemIconResolver resolver() => RuntimeBagItemIconResolver(
        projectRootDirectory: root.path,
        pokemonConfig: const ProjectPokemonConfig(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1),
      );

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
}
