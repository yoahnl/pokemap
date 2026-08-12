import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/personalization/presentation/personalization_studio_workspace.dart';

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
