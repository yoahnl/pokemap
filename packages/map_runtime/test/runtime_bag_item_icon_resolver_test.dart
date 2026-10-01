import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/player/runtime_bag_item_icon_resolver.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('runtime-bag-icons-');
  });

  tearDown(() async {
    await root.delete(recursive: true);
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
      );

  test('an empty project has no item icons or runtime bundle fallback',
      () async {
    final requestedAssets = <String>[];
    final messenger = binding.defaultBinaryMessenger;
    final originalHandler = messenger.allMessagesHandler;
    messenger.allMessagesHandler = (channel, handler, message) {
      if (channel == 'flutter/assets' && message != null) {
        requestedAssets.add(utf8.decode(message.buffer.asUint8List(
          message.offsetInBytes,
          message.lengthInBytes,
        )));
      }
      if (originalHandler != null) {
        return originalHandler(channel, handler, message);
      }
      return handler?.call(message) ??
          messenger.delegate.send(channel, message);
    };
    addTearDown(() => messenger.allMessagesHandler = originalHandler);
    final icons = resolver();
    for (final itemId in ['potion', 'poke_ball', 'ether']) {
      expect(await icons.resolve(itemId), isNull, reason: itemId);
    }
    expect(await icons.resolve('a_custom_story_item'), isNull);
    expect(requestedAssets, isEmpty);
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

  test('missing authored art uses only canonical assets from the project',
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
    expect(await icons.resolve('poke_ball'), isNull);
  });

  test('identical item paths resolve to distinct bytes in separate projects',
      () async {
    final otherRoot =
        await Directory.systemTemp.createTemp('other-runtime-bag-icons-');
    addTearDown(() => otherRoot.delete(recursive: true));
    final firstFile =
        await write('data/pokemon/assets/items/potion.png', 'first-project');
    final otherFile =
        File('${otherRoot.path}/data/pokemon/assets/items/potion.png');
    await otherFile.parent.create(recursive: true);
    await otherFile.writeAsString('second-project');
    final otherIcons = RuntimeBagItemIconResolver(
      projectRootDirectory: otherRoot.path,
      pokemonConfig: const ProjectPokemonConfig(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1),
    );
    final firstIcons = resolver();
    final paths = await Future.wait([
      firstIcons.resolve('potion'),
      otherIcons.resolve('potion'),
    ]);
    expect(paths, [
      await firstFile.resolveSymbolicLinks(),
      await otherFile.resolveSymbolicLinks(),
    ]);
    expect(await File(paths[0]!).readAsString(), 'first-project');
    expect(await File(paths[1]!).readAsString(), 'second-project');
    await firstFile.delete();
    expect(
      await Future.wait([
        firstIcons.resolve('potion'),
        otherIcons.resolve('potion'),
      ]),
      [null, await otherFile.resolveSymbolicLinks()],
    );
  });

  test('runtime bundle excludes item icons and retains cinematic emotes',
      () async {
    for (final fileName in ['icons.zip', 'manifest.json']) {
      final assetKey = 'packages/map_runtime/assets/menu/items/$fileName';
      await expectLater(() => rootBundle.load(assetKey), throwsFlutterError,
          reason: assetKey);
    }
    for (final fileName in ['emotions.png', 'emotions2.png']) {
      final bytes = await rootBundle
          .load('packages/map_runtime/assets/cinematics/emotes/$fileName');
      expect(bytes.lengthInBytes, greaterThan(0), reason: fileName);
    }
  });
}
