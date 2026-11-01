import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_pokemon_sprite_resolver.dart';
import 'package:path/path.dart' as p;

ProjectManifest _manifest({String? mediaDir}) {
  const project = ProjectManifest(name: 'media', maps: [], tilesets: []);
  return mediaDir == null
      ? project
      : project.copyWith(pokemon: project.pokemon.copyWith(mediaDir: mediaDir));
}

Future<void> _media(
  File file, {
  String front = 'assets/front.png',
  String? cry,
}) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(
    jsonEncode({
      'defaultFormId': 'base',
      'variants': {
        'base': {'frontStatic': front, 'cry': ?cry},
      },
    }),
  );
}

void main() {
  late Directory qaDirectory;
  late Directory fixture;
  late Directory project;
  late Directory outside;
  var createdQaDirectory = false;

  setUpAll(() async {
    final supplied = Platform.environment['AVELUNE_QA_ROOT'];
    final home = Platform.environment['HOME'];
    if (supplied != null && supplied.isNotEmpty) {
      if (!p.isAbsolute(supplied)) {
        throw ArgumentError('AVELUNE_QA_ROOT must be an absolute directory.');
      }
      qaDirectory = Directory(supplied);
      if (!await qaDirectory.exists()) {
        throw ArgumentError('AVELUNE_QA_ROOT must already exist.');
      }
    } else if (Platform.isMacOS) {
      if (home == null || home.isEmpty) {
        throw StateError(
          'HOME is required to locate the Avelune QA directory.',
        );
      }
      qaDirectory = Directory(
        p.join(home, 'Library', 'Caches', 'AveluneQA', 'battle-media-security'),
      );
      if (!await qaDirectory.exists()) {
        await qaDirectory.create(recursive: true);
        createdQaDirectory = true;
      }
    } else {
      qaDirectory = Directory.systemTemp;
    }
    if (Platform.isMacOS) {
      if (home == null || home.isEmpty) {
        throw StateError(
          'HOME is required to locate the Avelune QA directory.',
        );
      }
      final root = await Directory(
        p.join(home, 'Library', 'Caches', 'AveluneQA'),
      ).resolveSymbolicLinks();
      final selected = await qaDirectory.resolveSymbolicLinks();
      if (!p.isWithin(root, selected)) {
        throw ArgumentError('AVELUNE_QA_ROOT must be inside AveluneQA.');
      }
    }
  });

  tearDownAll(() async {
    if (createdQaDirectory) {
      try {
        await qaDirectory.delete();
      } on FileSystemException {
        return;
      }
    }
  });

  setUp(() async {
    fixture = await qaDirectory.createTemp('battle-media-security-');
    project = await Directory('${fixture.path}/project').create();
    outside = await Directory('${fixture.path}/outside').create();
  });

  tearDown(() async {
    if (await fixture.exists()) await fixture.delete(recursive: true);
  });

  test(
    'rejects traversing and absolute species identifiers before reading',
    () async {
      await _media(File('${outside.path}/probe.json'));
      final resolver = BattlePokemonSpriteResolver(
        manifest: _manifest(),
        projectRootDirectory: project.path,
      );
      for (final id in [
        '../../../../outside/probe',
        '${outside.path}/probe',
        r'C:\outside\probe',
        '..',
        '.',
      ]) {
        final result = await resolver.resolve(
          speciesId: id,
          isPlayerSide: false,
        );
        expect(result.hasExplicitImage, isFalse, reason: id);
        expect(await resolver.resolveCry(id), isNull, reason: id);
      }
      expect(resolver.debugActualMediaReadCount, 0);
    },
  );

  test('rejects media directories outside the project', () async {
    await _media(File('${outside.path}/probe.json'));
    for (final directory in ['../outside', outside.path, r'C:\outside']) {
      final resolver = BattlePokemonSpriteResolver(
        manifest: _manifest(mediaDir: directory),
        projectRootDirectory: project.path,
      );
      final result = await resolver.resolve(
        speciesId: 'probe',
        isPlayerSide: false,
      );
      expect(result.hasExplicitImage, isFalse, reason: directory);
      expect(resolver.debugActualMediaReadCount, 0);
    }
  });

  test(
    'rejects media files and media directories linked outside the project',
    () async {
      await _media(File('${outside.path}/probe.json'));
      final mediaDir = Directory('${project.path}/data/pokemon/media');
      await mediaDir.create(recursive: true);
      await Link('${mediaDir.path}/probe.json')
          .create('${outside.path}/probe.json');
      final fileResolver = BattlePokemonSpriteResolver(
        manifest: _manifest(),
        projectRootDirectory: project.path,
      );
      expect(
        (await fileResolver.resolve(
          speciesId: 'probe',
          isPlayerSide: false,
        )).hasExplicitImage,
        isFalse,
      );
      expect(fileResolver.debugActualMediaReadCount, 0);

      await Link('${project.path}/linked-media').create(outside.path);
      final directoryResolver = BattlePokemonSpriteResolver(
        manifest: _manifest(mediaDir: 'linked-media'),
        projectRootDirectory: project.path,
      );
      expect(
        (await directoryResolver.resolve(
          speciesId: 'probe',
          isPlayerSide: false,
        )).hasExplicitImage,
        isFalse,
      );
      expect(directoryResolver.debugActualMediaReadCount, 0);
    },
    skip: Platform.isWindows
        ? 'Symbolic link creation may require elevated privileges.'
        : false,
  );

  test(
    'rejects linked sprites and cries outside the project',
    () async {
      await File('${outside.path}/sprite.png').writeAsBytes([1]);
      await File('${outside.path}/cry.wav').writeAsBytes([1]);
      final assets = await Directory('${project.path}/assets').create();
      await Link('${assets.path}/sprite.png')
          .create('${outside.path}/sprite.png');
      await Link('${assets.path}/cry.wav').create('${outside.path}/cry.wav');
      await _media(
        File('${project.path}/data/pokemon/media/probe.json'),
        front: 'assets/sprite.png',
        cry: 'assets/cry.wav',
      );
      final resolver = BattlePokemonSpriteResolver(
        manifest: _manifest(),
        projectRootDirectory: project.path,
      );
      expect(
        (await resolver.resolve(
          speciesId: 'probe',
          isPlayerSide: false,
        )).hasExplicitImage,
        isFalse,
      );
      expect(await resolver.resolveCry('probe'), isNull);
    },
    skip: Platform.isWindows
        ? 'Symbolic link creation may require elevated privileges.'
        : false,
  );

  test(
    'keeps existing internal links and missing authored assets usable',
    () async {
      final assets = await Directory('${project.path}/assets').create();
      await File('${assets.path}/inside.png').writeAsBytes([1]);
      await Link('${assets.path}/alias.png')
          .create('${assets.path}/inside.png');
      await _media(
        File('${project.path}/data/pokemon/media/probe.json'),
        front: 'assets/alias.png',
        cry: 'assets/missing.wav',
      );
      final resolver = BattlePokemonSpriteResolver(
        manifest: _manifest(),
        projectRootDirectory: project.path,
      );
      expect(
        (await resolver.resolve(
          speciesId: 'probe',
          isPlayerSide: false,
        )).explicitImageAbsolutePath,
        '${assets.path}/inside.png',
      );
      expect(await resolver.resolveCry('probe'), '${assets.path}/missing.wav');
    },
    skip: Platform.isWindows
        ? 'Symbolic link creation may require elevated privileges.'
        : false,
  );

  test(
    'rejects a fallback cry linked outside the project',
    () async {
      await File('${outside.path}/cry.ogg').writeAsBytes([1]);
      final directory = await Directory('${project.path}/assets/pokemon/cries')
          .create(recursive: true);
      await Link('${directory.path}/probe.ogg')
          .create('${outside.path}/cry.ogg');
      final resolver = BattlePokemonSpriteResolver(
        manifest: _manifest(),
        projectRootDirectory: project.path,
      );
      expect(await resolver.resolveCry('probe'), isNull);
      await File('${directory.path}/probe.wav').writeAsBytes([1]);
      expect(await resolver.resolveCry('probe'), '${directory.path}/probe.wav');
    },
    skip: Platform.isWindows
        ? 'Symbolic link creation may require elevated privileges.'
        : false,
  );

  test(
    'rejects missing authored assets beneath a directory linked outside',
    () async {
      final assets = await Directory('${project.path}/assets').create();
      await Link('${assets.path}/outside').create(outside.path);
      await _media(
        File('${project.path}/data/pokemon/media/probe.json'),
        front: 'assets/outside/missing.png',
        cry: 'assets/outside/missing.wav',
      );
      final resolver = BattlePokemonSpriteResolver(
        manifest: _manifest(),
        projectRootDirectory: project.path,
      );
      expect(
        (await resolver.resolve(
          speciesId: 'probe',
          isPlayerSide: false,
        )).hasExplicitImage,
        isFalse,
      );
      expect(await resolver.resolveCry('probe'), isNull);
    },
    skip: Platform.isWindows
        ? 'Symbolic link creation may require elevated privileges.'
        : false,
  );

  for (final directory in ['', '.']) {
    test(
      'loads a media file at the project root with directory "$directory"',
      () async {
        await _media(File('${project.path}/probe.json'));
        final resolver = BattlePokemonSpriteResolver(
          manifest: _manifest(mediaDir: directory),
          projectRootDirectory: project.path,
        );
        final result = await resolver.resolve(
          speciesId: 'probe',
          isPlayerSide: false,
        );
        expect(
          result.explicitImageAbsolutePath,
          '${project.path}/assets/front.png',
        );
        expect(resolver.debugActualMediaReadCount, 1);
      },
    );
  }
}
