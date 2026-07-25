import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/game_export.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:path/path.dart' as p;

import 'game_export_test_fixture.dart';

void main() {
  testWidgets('guides metadata entry and exports without JSON editing',
      (tester) async {
    late final Directory root;
    await tester.runAsync(() async {
      root = await createAuthorProject();
    });
    addTearDown(() => root.delete(recursive: true));
    final output = File(p.join(root.parent.path, 'dialog.pokemapgame'));
    addTearDown(() async {
      if (await output.exists()) await output.delete();
    });
    final controller = GamePackageExportController(
      projectRoot: root,
      projectName: 'Neutral Adventure',
      profileStore: GamePackageExportProfileStore(projectRoot: root),
    );
    addTearDown(controller.dispose);
    await tester.runAsync(controller.initialize);
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: GamePackageExportDialog(
            controller: controller,
            chooseOutputFile: (_) async => output,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Publier dans PokeMap Hub'), findsOneWidget);
    expect(find.byType(PokeMapTextField), findsWidgets);
    expect(find.text('Éditer du JSON'), findsNothing);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('game-export-game-id')),
          )
          .autofocus,
      isTrue,
    );
    expect(
      tester
          .widget<PokeMapButton>(
            find.widgetWithText(PokeMapButton, 'Exporter le jeu'),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('game-export-game-id')),
      'games.example.neutral',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('game-export-author')),
      'Example Studio',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('game-export-icon')),
      'assets/icon.png',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('game-export-license')),
      'LICENSE.txt',
    );
    await tester.pump();

    final exportButton = tester.widget<PokeMapButton>(
      find.widgetWithText(PokeMapButton, 'Exporter le jeu'),
    );
    expect(exportButton.onPressed, isNotNull);
    await tester.runAsync(() async {
      exportButton.onPressed!.call();
      for (var attempt = 0;
          attempt < 200 &&
              controller.snapshot.status != GamePackageExportStatus.succeeded &&
              controller.snapshot.status != GamePackageExportStatus.error;
          attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pump();

    expect(output.existsSync(), isTrue);
    expect(find.text('Package certifié'), findsOneWidget);
  });
}
