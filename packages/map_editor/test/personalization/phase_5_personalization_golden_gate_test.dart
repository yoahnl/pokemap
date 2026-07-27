import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/game_export.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:path/path.dart' as p;

import '../game_export/game_export_test_fixture.dart';

void main() {
  testWidgets('Phase 5 golden fixture renders the editor preview',
      (tester) async {
    final presentationJson = await tester.runAsync(_readGoldenPresentation);
    final presentation = ProjectPresentationProfile.fromJson(presentationJson!);
    expect(validateProjectPresentationProfile(presentation), isEmpty);

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProjectSemanticThemeEditor(
              profile: presentation.theme!,
              onEditToken: (_) {},
              onUseSafeFallback: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('Contrastes validés'), findsOneWidget);
    expect(find.text('HUD combat'), findsOneWidget);
  });

  test('Phase 5 golden fixture packages every presentation category', () async {
    final presentationJson = await _readGoldenPresentation();
    final root = await createAuthorProject(withDialogue: false);
    addTearDown(() => root.delete(recursive: true));
    final assets = Directory(p.join(root.path, 'assets', 'presentation'));
    final intro = Directory(p.join(assets.path, 'intro'));
    final fonts = Directory(p.join(assets.path, 'fonts'));
    await intro.create(recursive: true);
    await fonts.create(recursive: true);
    for (final name in <String>['icon.png', 'cover.png', 'hero.png']) {
      await File(p.join(assets.path, name)).writeAsBytes(onePixelPng);
    }
    await File(p.join(assets.path, 'title.ogg'))
        .writeAsBytes(utf8.encode('OggS phase-5-title'));
    final introBytes = <int>[
      0,
      0,
      0,
      24,
      ...utf8.encode('ftypisom'),
      0,
      0,
      0,
      0,
      ...utf8.encode('isomavc1mp4a'),
    ];
    await File(p.join(intro.path, 'intro.mp4')).writeAsBytes(introBytes);
    await File(p.join(intro.path, 'poster.png')).writeAsBytes(onePixelPng);
    await File(p.join(intro.path, 'captions.vtt')).writeAsString(
      'WEBVTT\n\n00:00.000 --> 00:01.000\nBienvenue à Aube.\n',
    );
    await File(p.join(fonts.path, 'display.ttf'))
        .writeAsBytes(<int>[0, 1, 0, 0, 0, 0, 0, 0]);
    await File(p.join(fonts.path, 'display-license.txt'))
        .writeAsString('Redistribution permitted.');

    final projectFile = File(p.join(root.path, 'project.json'));
    final project =
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
    project['presentation'] = presentationJson;
    await projectFile.writeAsString(jsonEncode(project), flush: true);

    final built = await const GamePackageExportService().build(
      projectRoot: root,
      profile: neutralExportProfile(),
    );

    expect(
      built.manifest.presentation?.branding.layoutVariant,
      'cinematic',
    );
    expect(built.manifest.presentation?.intro?.allowReplay, isTrue);
    expect(
      built.manifest.presentation?.typography?.display.family,
      'Aube Display',
    );
    expect(
      built.manifest.presentation?.theme?.overworldHudSurface,
      '#FFFFFF',
    );
    expect(
      built.inspection.payloadPaths,
      containsAll(<String>[
        'presentation/icon.png',
        'presentation/cover.png',
        'presentation/hero.png',
        'presentation/intro/video.mp4',
        'presentation/intro/poster.png',
        'presentation/intro/captions.vtt',
        'presentation/fonts/display.ttf',
        'presentation/fonts/display-license.txt',
      ]),
    );
  });
}

Future<Map<String, dynamic>> _readGoldenPresentation() async {
  final fixture = File(
    p.join(
      Directory.current.path,
      '..',
      '..',
      'examples',
      'playable_runtime_host',
      'golden_personalization_slice',
      'presentation.json',
    ),
  );
  return jsonDecode(await fixture.readAsString()) as Map<String, dynamic>;
}
