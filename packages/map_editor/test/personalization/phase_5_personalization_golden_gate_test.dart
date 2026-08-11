import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_editor/game_export.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:path/path.dart' as p;

import '../game_export/game_export_test_fixture.dart';

void main() {
  testWidgets('Phase 5 golden fixture renders the editor preview', (
    tester,
  ) async {
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
    expect(find.text('Combat'), findsOneWidget);
  });

  test('Phase 5 golden fixture packages every presentation category', () async {
    final presentationJson = await _readGoldenPresentation();
    final presentation = ProjectPresentationProfile.fromJson(presentationJson);
    final root = await createAuthorProject(withDialogue: false);
    addTearDown(() => root.delete(recursive: true));
    await _copyAcceptanceAssets(root);

    final projectFile = File(p.join(root.path, 'project.json'));
    final project =
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
    project['presentation'] = presentationJson;
    await projectFile.writeAsString(jsonEncode(project), flush: true);

    final built = await const GamePackageExportService().build(
      projectRoot: root,
      profile: neutralExportProfile(),
    );

    expect(built.manifest.presentation?.branding.layoutVariant, 'cinematic');
    expect(built.manifest.presentation?.intro?.allowReplay, isTrue);
    expect(
      built.manifest.presentation?.typography?.display.family,
      'Aube Display',
    );
    expect(built.manifest.presentation?.theme?.overworldHudSurface, '#FFFFFF');
    expect(
      built.manifest.presentation?.schemaVersion,
      ProjectPresentationProfile.supportedSchemaVersion,
    );
    expect(
      built.manifest.presentation?.windows?.pauseMenuStyleId,
      'pause-menu',
    );
    expect(
      built.manifest.presentation?.layouts?.title.expanded.slot,
      'bottomLeft',
    );
    expect(
      built.manifest.presentation?.windows?.styles
          .singleWhere((style) => style.id == 'dialogue')
          .cornerRadius,
      8,
    );
    expect(
      built.inspection.payloadPaths,
      containsAll(<String>[
        'presentation/icon.png',
        'presentation/cover.png',
        'presentation/hero.png',
        'presentation/intro/landscape/video.mp4',
        'presentation/intro/landscape/poster.png',
        'presentation/intro/landscape/captions.vtt',
        'presentation/fonts/display.ttf',
        'presentation/fonts/display-license.txt',
      ]),
    );
    expect(
      built.personalizationPreflight.configuredCategories,
      <GamePackagePersonalizationCategory>[
        GamePackagePersonalizationCategory.branding,
        GamePackagePersonalizationCategory.intro,
        GamePackagePersonalizationCategory.titleMotion,
        GamePackagePersonalizationCategory.typography,
        GamePackagePersonalizationCategory.theme,
        GamePackagePersonalizationCategory.pause,
        GamePackagePersonalizationCategory.windows,
        GamePackagePersonalizationCategory.layouts,
      ],
    );
    expect(
      built.manifest.presentation?.pause?.actions
          ?.firstWhere((action) => action.id == 'pokedex')
          .label,
      'Carnet de route',
    );
    expect(
      built.manifest.presentation?.titleMotion?.promptLoop?.landscape.video,
      'presentation/title/prompt/landscape/video.mp4',
    );
    expect(built.personalizationPreflight.packageSha256, built.packageSha256);
    expect(
      built.personalizationPreflight.assetSha256,
      containsPair('presentation/fonts/display-license.txt', isA<String>()),
    );

    final preview = PersonalizationPreviewProjection(presentation);
    final packaged = built.manifest.presentation!;
    final packagedTheme = packaged.theme!;
    final packagedTypography = packaged.typography!;
    expect(preview.titleLayoutVariant, packaged.branding.layoutVariant);
    expect(
      preview.surface(PersonalizationStudioScene.title).backgroundHex,
      packagedTheme.titleSurface,
    );
    expect(
      preview.surface(PersonalizationStudioScene.dialogue).backgroundHex,
      packagedTheme.dialogueSurface,
    );
    expect(
      preview.surface(PersonalizationStudioScene.pause).backgroundHex,
      packagedTheme.menuSurface,
    );
    expect(
      preview.surface(PersonalizationStudioScene.globalStyle).backgroundHex,
      packagedTheme.background,
    );
    expect(
      preview.surface(PersonalizationStudioScene.battle).backgroundHex,
      packagedTheme.battleHudSurface,
    );
    expect(
      preview.surface(PersonalizationStudioScene.title).fontFamily,
      packagedTypography.display.family,
    );
    expect(
      preview.surface(PersonalizationStudioScene.dialogue).fontFamily,
      packagedTypography.dialogue.fallbackFamilies.single,
    );
    expect(
      preview.surface(PersonalizationStudioScene.battle).fontFamily,
      packagedTypography.numbers.fallbackFamilies.single,
    );
  });
}

Future<Map<String, dynamic>> _readGoldenPresentation() async {
  final fixture = File(p.join(_acceptanceFixture.path, 'project.json'));
  final project =
      jsonDecode(await fixture.readAsString()) as Map<String, dynamic>;
  return Map<String, dynamic>.from(project['presentation'] as Map);
}

Future<void> _copyAcceptanceAssets(Directory projectRoot) async {
  for (final relativePath in <String>[
    'assets/presentation/icon.png',
    'assets/presentation/cover.png',
    'assets/presentation/hero.png',
    'assets/presentation/intro/intro.mp4',
    'assets/presentation/intro/poster.png',
    'assets/presentation/intro/captions.vtt',
    'assets/presentation/fonts/display.ttf',
    'assets/presentation/fonts/display-license.txt',
  ]) {
    final target = File(p.join(projectRoot.path, relativePath));
    await target.parent.create(recursive: true);
    await File(p.join(_acceptanceFixture.path, relativePath)).copy(target.path);
  }
}

final _acceptanceFixture = Directory(
  p.join(
    Directory.current.path,
    '..',
    '..',
    'examples',
    'playable_runtime_host',
    'golden_personalization_v3',
  ),
);
