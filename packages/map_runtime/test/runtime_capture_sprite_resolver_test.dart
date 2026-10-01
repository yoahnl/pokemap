import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/player/runtime_capture_sprite_resolver.dart';
import 'package:path/path.dart' as p;

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('runtime-capture-sprites-');
  });

  tearDown(() => root.delete(recursive: true));

  RuntimeCaptureSpriteResolver resolver({ProjectPokemonConfig? config}) =>
      RuntimeCaptureSpriteResolver(
        projectRootDirectory: root.path,
        pokemonConfig: config ??
            const ProjectPokemonConfig(
              ruleset: PokemonRulesetProfile.pokeMapBetaV1,
            ),
      );

  test('resolves the capture sprite declared by the selected project item',
      () async {
    await _catalog(root, {
      'aurora-orb': 'assets/capture/aurora.png',
      'poke-ball': 'assets/capture/standard.png',
    });
    final custom = await _sheet(root, 'assets/capture/aurora.png', 10);
    final standard = await _sheet(root, 'assets/capture/standard.png', 20);

    final sprites = resolver();

    expect(await sprites.resolve('aurora-orb'),
        await custom.resolveSymbolicLinks());
    expect(await sprites.resolve('poke-ball'),
        await standard.resolveSymbolicLinks());
    expect(await sprites.resolve('unknown-orb'), isNull);
  });

  test('missing capture art never reads a runtime bundle or invents a path',
      () async {
    final assets = <String>[];
    final messenger = binding.defaultBinaryMessenger;
    final original = messenger.allMessagesHandler;
    messenger.allMessagesHandler = (channel, handler, message) {
      if (channel == 'flutter/assets' && message != null) {
        assets.add(utf8.decode(message.buffer.asUint8List(
          message.offsetInBytes,
          message.lengthInBytes,
        )));
      }
      if (original != null) return original(channel, handler, message);
      return handler?.call(message) ??
          messenger.delegate.send(channel, message);
    };
    addTearDown(() => messenger.allMessagesHandler = original);
    expect(await resolver().resolve('poke-ball'), isNull);
    await _catalog(root, {'poke-ball': null});
    await _sheet(root, 'data/pokemon/assets/items/poke-ball.png', 10);
    await _sheet(root, 'assets/battle/balls/ball_1.png', 20);

    expect(await resolver().resolve('poke-ball'), isNull);
    expect(await resolver().resolve('ball_1'), isNull);
    expect(assets, isEmpty);
  });

  test('rejects malformed catalogs and unsafe capture sprite references',
      () async {
    final catalog = await _catalog(root, {'poke-ball': 'assets/ball.png'});
    await _sheet(root, 'assets/ball.png', 10);
    for (final invalid in [
      '{invalid',
      jsonEncode({'entries': []}),
      jsonEncode({
        ..._catalogJson({'poke-ball': 'assets/ball.png'}),
        'unexpected': true,
      }),
    ]) {
      await catalog.writeAsString(invalid);
      expect(await resolver().resolve('poke-ball'), isNull);
    }
    for (final path in [
      '/tmp/ball.png',
      r'C:\outside\ball.png',
      '../ball.png',
      'art/../ball.png',
      'https://example.invalid/ball.png',
      r'art\ball.png',
      'art/ball.png',
      'ball.png',
      'Assets/ball.png',
      'database/ball.png',
    ]) {
      await _catalog(root, {'poke-ball': path});
      expect(await resolver().resolve('poke-ball'), isNull, reason: path);
    }
  });

  test('rejects symbolic links escaping the project for sprites and catalogs',
      () async {
    final outside =
        await Directory.systemTemp.createTemp('outside-capture-sprites-');
    addTearDown(() => outside.delete(recursive: true));
    final outsideSheet = await _sheet(outside, 'ball.png', 10);
    await Directory(p.join(root.path, 'assets')).create();
    await Link(p.join(root.path, 'assets/linked.png'))
        .create(outsideSheet.path);
    await _catalog(root, {'poke-ball': 'assets/linked.png'});

    expect(await resolver().resolve('poke-ball'), isNull);

    final outsideCatalog =
        await _catalog(outside, {'poke-ball': 'assets/ball.png'});
    await _sheet(root, 'assets/ball.png', 20);
    await Link(p.join(root.path, 'linked.json')).create(outsideCatalog.path);
    expect(
      await resolver(
        config: const ProjectPokemonConfig(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          catalogFiles: {'items': 'linked.json'},
        ),
      ).resolve('poke-ball'),
      isNull,
    );
  });

  test('rejects missing, corrupted and incorrectly sized PNG sheets', () async {
    await _catalog(root, {'poke-ball': 'assets/ball.png'});
    expect(await resolver().resolve('poke-ball'), isNull);
    final file = File(p.join(root.path, 'assets/ball.png'));
    await file.parent.create(recursive: true);
    await file.writeAsBytes([1, 2, 3]);
    expect(await resolver().resolve('poke-ball'), isNull);
    await _sheet(root, 'assets/ball.png', 10);
    await file.writeAsBytes((await file.readAsBytes()).take(40).toList());
    expect(await resolver().resolve('poke-ball'), isNull);
    await _sheet(root, 'assets/ball.png', 10, width: 63);
    expect(await resolver().resolve('poke-ball'), isNull);
    await _sheet(root, 'assets/ball.png', 10, height: 64);
    expect(await resolver().resolve('poke-ball'), isNull);
    await file
        .writeAsBytes(image.encodeJpg(image.Image(width: 64, height: 2048)));
    expect(await resolver().resolve('poke-ball'), isNull);
  });

  test('keeps the same item isolated between projects and rechecks its file',
      () async {
    final other =
        await Directory.systemTemp.createTemp('other-capture-sprites-');
    addTearDown(() => other.delete(recursive: true));
    const path = 'assets/capture/ball.png';
    await _catalog(root, {'poke-ball': path});
    await _catalog(other, {'poke-ball': path});
    final firstFile = await _sheet(root, path, 10);
    final secondFile = await _sheet(other, path, 20);
    final first = resolver();
    final second = RuntimeCaptureSpriteResolver(
      projectRootDirectory: other.path,
      pokemonConfig: const ProjectPokemonConfig(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      ),
    );
    final paths = await Future.wait([
      first.resolve('poke-ball'),
      second.resolve('poke-ball'),
    ]);

    expect(paths, [
      await firstFile.resolveSymbolicLinks(),
      await secondFile.resolveSymbolicLinks(),
    ]);
    expect(await File(paths.first!).readAsBytes(),
        isNot(await File(paths.last!).readAsBytes()));
    await firstFile.delete();
    expect(await first.resolve('poke-ball'), isNull);
    expect(await second.resolve('poke-ball'),
        await secondFile.resolveSymbolicLinks());
  });

  test('does not resolve capture sprites when Pokemon is disabled', () async {
    await _catalog(root, {'poke-ball': 'assets/ball.png'});
    await _sheet(root, 'assets/ball.png', 10);

    expect(
      await resolver(
          config: const ProjectPokemonConfig(
        enabled: false,
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      )).resolve('poke-ball'),
      isNull,
    );
  });
}

Map<String, Object?> _catalogJson(Map<String, String?> paths) => {
      'schemaVersion': 1,
      'entries': [
        for (final entry in paths.entries)
          {
            'id': entry.key,
            'displayName': entry.key,
            'pocketId': 'balls',
            'capture': {
              'rateNumerator': 1,
              'rateDenominator': 1,
              'allowedEncounterKinds': ['walk'],
              if (entry.value != null) 'animationSpritePath': entry.value,
            },
          },
      ],
    };

Future<File> _catalog(Directory root, Map<String, String?> paths) async {
  final file = File(p.join(root.path, 'data/pokemon/catalogs/items.json'));
  await file.parent.create(recursive: true);
  return file.writeAsString(jsonEncode(_catalogJson(paths)));
}

Future<File> _sheet(Directory root, String path, int red,
    {int width = 64, int height = 2048}) async {
  final pixels = image.Image(width: width, height: height);
  pixels.setPixelRgba(0, 0, red, 1, 2, 255);
  final file = File(p.join(root.path, path));
  await file.parent.create(recursive: true);
  return file.writeAsBytes(image.encodePng(pixels));
}
