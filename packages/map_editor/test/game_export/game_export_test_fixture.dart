import 'dart:convert';
import 'dart:io';

import 'package:map_editor/game_export.dart';
import 'package:path/path.dart' as p;

Future<Directory> createAuthorProject({
  bool withDialogue = true,
  String name = 'Neutral Adventure',
}) async {
  final root = await Directory.systemTemp.createTemp('pokemap_author_export_');
  final project = <String, Object?>{
    'name': name,
    'version': 'v2',
    'maps': <Object?>[
      <String, Object?>{
        'id': 'map.start',
        'name': 'Start',
        'relativePath': 'maps/start.json',
      },
    ],
    'tilesets': <Object?>[],
    'dialogues': withDialogue
        ? <Object?>[
            <String, Object?>{
              'id': 'dialogue.intro',
              'name': 'Introduction',
              'relativePath': 'dialogues/intro.yarn',
              'defaultStartNode': 'Start',
            },
          ]
        : <Object?>[],
    'settings': <String, Object?>{
      'tileWidth': 16,
      'tileHeight': 16,
      'mistralApiKey': 'fixture-secret-that-must-not-ship',
    },
    'globalProperties': <String, Object?>{
      'apiKey': 'another-author-secret',
      'weather': 'clear',
    },
  };
  await File(p.join(root.path, 'project.json')).writeAsString(
    jsonEncode(project),
    flush: true,
  );
  await Directory(p.join(root.path, 'maps')).create(recursive: true);
  await File(p.join(root.path, 'maps', 'start.json')).writeAsString(
    jsonEncode(<String, Object?>{
      'id': 'map.start',
      'dialogue': <String, Object?>{
        'dialogueId': 'dialogue.intro',
        'scriptPathRelative': 'dialogues/intro.yarn',
      },
    }),
    flush: true,
  );
  if (withDialogue) {
    await Directory(p.join(root.path, 'dialogues')).create(recursive: true);
    await File(p.join(root.path, 'dialogues', 'intro.yarn')).writeAsString(
      '''
title: Start
---
Guide: Bienvenue.
-> Continuer
  <<outcome continue>>
  En route.
===
''',
      flush: true,
    );
  }
  await Directory(p.join(root.path, 'assets')).create(recursive: true);
  await File(p.join(root.path, 'assets', 'icon.png')).writeAsBytes(
    onePixelPng,
    flush: true,
  );
  await Directory(p.join(root.path, 'data', 'pokemon', 'media'))
      .create(recursive: true);
  await File(
    p.join(root.path, 'data', 'pokemon', 'media', 'creature.png'),
  ).writeAsBytes(onePixelPng, flush: true);
  await File(p.join(root.path, 'LICENSE.txt')).writeAsString(
    'Example license',
    flush: true,
  );
  await File(p.join(root.path, 'CREDITS.txt')).writeAsString(
    'Example credits',
    flush: true,
  );
  await File(p.join(root.path, 'runtime_host_launch_save.json')).writeAsString(
    '{}',
    flush: true,
  );
  await Directory(p.join(root.path, 'saves')).create(recursive: true);
  await File(p.join(root.path, 'saves', 'slot.json')).writeAsString(
    '{}',
    flush: true,
  );
  await Directory(p.join(root.path, '.dart_tool')).create(recursive: true);
  await File(p.join(root.path, '.dart_tool', 'cache.json')).writeAsString(
    '{}',
    flush: true,
  );
  return root;
}

GamePackageExportProfile neutralExportProfile({
  String gameId = 'games.example.neutral',
  String title = 'Neutral Adventure',
  String version = '1.2.0',
}) =>
    GamePackageExportProfile(
      gameId: gameId,
      gameVersion: version,
      title: title,
      description: 'A neutral exported game.',
      authorName: 'Example Studio',
      defaultLocale: 'fr',
      supportedLocales: const <String>['fr', 'en'],
      iconPath: 'assets/icon.png',
      coverPath: 'assets/icon.png',
      licensePath: 'LICENSE.txt',
      creditsPath: 'CREDITS.txt',
    );

final List<int> onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
  '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
