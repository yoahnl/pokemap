import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/app/providers/core_providers.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:map_editor/src/ui/editor_shell_page.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  setUpAll(_loadGoldenFonts);

  for (final size in <Size>[
    const Size(1440, 900),
    const Size(1024, 768),
    const Size(720, 900),
  ]) {
    testWidgets('certifies the complete Personalization shell at '
        '${size.width.toInt()}x${size.height.toInt()} with 200 percent text', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final projectRoot = Directory.systemTemp.createTempSync(
        'pokemap-personalization-shell-golden-',
      );
      addTearDown(() => projectRoot.deleteSync(recursive: true));
      _copyDirectory(_fixtureDirectory(), projectRoot);
      final project = ProjectManifest.fromJson(
        jsonDecode(File('${projectRoot.path}/project.json').readAsStringSync())
            as Map<String, dynamic>,
      );

      await pumpEditorCanvasHostHarness(
        tester,
        initialState: EditorState(
          projectRootPath: projectRoot.path,
          project: project,
          workspaceMode: EditorWorkspaceMode.personalizationStudio,
        ),
        surfaceSize: size,
      );
      await tester.pumpAndSettle();

      final shell = find.byType(PersonalizationStudioWorkspace);
      expect(shell, findsOneWidget);
      expect(
        find.text('Sauvegarde automatique', findRichText: true),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        shell,
        matchesGoldenFile(
          'goldens/personalization_shell/'
          '${size.width.toInt()}x${size.height.toInt()}_text_200.png',
        ),
      );
      if (size.width <= 1024) {
        final settingsScroll = find
            .descendant(
              of: find.byKey(
                const ValueKey<String>(
                  'personalization-preview-settings-scroll',
                ),
              ),
              matching: find.byType(Scrollable),
            )
            .first;
        final secondaryToggle = find.byKey(
          const ValueKey<String>('personalization-preview-secondary-toggle'),
        );
        await tester.scrollUntilVisible(
          secondaryToggle,
          160,
          scrollable: settingsScroll,
        );
        await tester.tap(secondaryToggle);
        await tester.pumpAndSettle();
        final reducedMotion = find.byKey(
          const ValueKey<String>('personalization-preview-reduced-motion'),
        );
        await tester.scrollUntilVisible(
          reducedMotion,
          160,
          scrollable: settingsScroll,
        );
        expect(reducedMotion.hitTestable(), findsOneWidget);
      }
      if (size.width == 720) {
        final navigationScroll = find
            .descendant(
              of: find.byKey(
                const ValueKey<String>(
                  'personalization-studio-navigation-horizontal',
                ),
              ),
              matching: find.byType(Scrollable),
            )
            .first;
        final battle = find.byKey(
          const ValueKey<String>('personalization-studio-scene-battle'),
        );
        await tester.scrollUntilVisible(
          battle,
          300,
          scrollable: navigationScroll,
        );
        expect(battle.hitTestable(), findsOneWidget);
      }
    });
  }

  testWidgets('captures the complete Dialogue Studio at the target viewport', (
    tester,
  ) async {
    final projectRoot = Directory.systemTemp.createTempSync(
      'pokemap-personalization-target-review-',
    );
    addTearDown(() => projectRoot.deleteSync(recursive: true));
    _copyDirectory(_fixtureDirectory(), projectRoot);
    final project = ProjectManifest.fromJson(
      jsonDecode(File('${projectRoot.path}/project.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    await tester.runAsync(() => _seedFixtureImages(projectRoot));
    final queries = AuthoringQueryAdapter(
      fileReader: const EditorProjectFileReader(),
    );
    addTearDown(queries.closeAll);
    final contexts = await tester.runAsync(
      () => AuthoringPersonalizationPreviewContextSource(
        queries: queries,
      ).load(projectRoot.path),
    );

    await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: projectRoot.path,
        project: project,
        workspaceMode: EditorWorkspaceMode.personalizationStudio,
      ),
      surfaceSize: const Size(1672, 941),
      overrides: [
        personalizationPreviewContextSourceProvider.overrideWithValue(
          _FixedPreviewContextSource(contexts!),
        ),
      ],
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-studio-scene-dialogue'),
      ),
    );
    for (var attempt = 0; attempt < 20; attempt += 1) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      if (find
          .byKey(const ValueKey<String>('personalization-project-map-renderer'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
    await tester.pumpAndSettle();

    final editor = find.byType(EditorShellPage);
    expect(editor, findsOneWidget);
    final preview = find.byKey(
      const ValueKey<String>('personalization-studio-preview-pane'),
    );
    expect(tester.getSize(preview).width, greaterThanOrEqualTo(700));
    expect(find.textContaining('Chargement des cartes'), findsNothing);
    expect(find.textContaining('Bienvenue à Vermeil'), findsWidgets);
    expect(
      find.byKey(
        const ValueKey<String>('personalization-project-map-renderer'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('personalization-dialogue-portrait')),
      findsWidgets,
    );
    expect(find.text('Aperçu uniquement'), findsOneWidget);
    expect(find.text('Réglage de test'), findsNothing);
    expect(tester.takeException(), isNull);
    await expectLater(
      editor,
      matchesGoldenFile(
        'goldens/personalization_shell/'
        '1672x941_dialogue_target_review.png',
      ),
    );
  });
}

final class _FixedPreviewContextSource
    implements PersonalizationPreviewContextSource {
  const _FixedPreviewContextSource(this.contexts);

  final List<PersonalizationPreviewContextOption> contexts;

  @override
  Future<List<PersonalizationPreviewContextOption>> load(
    String projectRoot, {
    PersonalizationPreviewContextScope scope =
        PersonalizationPreviewContextScope.all,
  }) async => contexts;
}

Future<void> _seedFixtureImages(Directory projectRoot) async {
  for (final relativePath in <String>[
    'assets/presentation/icon.png',
    'assets/presentation/cover.png',
    'assets/presentation/hero.png',
    'assets/presentation/intro/poster.png',
    'assets/characters/leo-happy.png',
    'assets/battle/battle-clearing.png',
    'assets/maps/vermeil-village-stage.png',
  ]) {
    final provider = FileImage(File('${projectRoot.path}/$relativePath'));
    final codec = await ui.instantiateImageCodec(
      await provider.file.readAsBytes(),
    );
    final frame = await codec.getNextFrame();
    PaintingBinding.instance.imageCache.putIfAbsent(
      provider,
      () => OneFrameImageStreamCompleter(
        SynchronousFuture<ImageInfo>(ImageInfo(image: frame.image)),
      ),
    );
    codec.dispose();
  }
}

Future<void> _loadGoldenFonts() async {
  final fontBytes = File(
    '${_fixtureDirectory().path}/assets/presentation/fonts/display.ttf',
  ).readAsBytesSync();
  for (final family in <String>[
    'Aube Display',
    'Avenir Next',
    'Roboto',
    'Arial',
    'Inter',
    '.SF Pro Text',
    'SF Pro Text',
  ]) {
    final loader = FontLoader(family)
      ..addFont(Future<ByteData>.value(ByteData.sublistView(fontBytes)));
    await loader.load();
  }
  final iconBytes = File(
    '${_flutterCacheDirectory().path}/artifacts/material_fonts/'
    'MaterialIcons-Regular.otf',
  ).readAsBytesSync();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(Future<ByteData>.value(ByteData.sublistView(iconBytes)))).load();
}

Directory _flutterCacheDirectory() {
  var current = File(Platform.resolvedExecutable).parent;
  while (current.parent.path != current.path) {
    if (current.path.endsWith('${Platform.pathSeparator}cache')) return current;
    current = current.parent;
  }
  throw StateError('Flutter cache directory not found.');
}

Directory _fixtureDirectory() => Directory(
  '${Directory.current.parent.parent.path}/examples/playable_runtime_host/'
  'golden_personalization_v3',
);

void _copyDirectory(Directory source, Directory destination) {
  for (final entity in source.listSync(recursive: true)) {
    final relativePath = entity.path.substring(source.path.length + 1);
    final targetPath = '${destination.path}/$relativePath';
    if (entity is Directory) {
      Directory(targetPath).createSync(recursive: true);
    } else if (entity is File) {
      File(targetPath)
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(entity.readAsBytesSync());
    }
  }
}
