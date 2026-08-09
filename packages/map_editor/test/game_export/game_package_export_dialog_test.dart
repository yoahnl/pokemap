import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/game_export.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:path/path.dart' as p;

import 'game_export_test_fixture.dart';

void main() {
  testWidgets('guides metadata entry and exports without JSON editing', (
    tester,
  ) async {
    late final Directory root;
    await tester.runAsync(() async {
      root = await createAuthorProject();
    });
    addTearDown(() => root.delete(recursive: true));
    final output = File(p.join(root.parent.path, 'dialog.avelunegame'));
    addTearDown(() async {
      if (await output.exists()) await output.delete();
    });
    final controller = GamePackageExportController(
      projectRoot: root,
      projectName: 'Neutral Adventure',
      profileStore: GamePackageExportProfileStore(projectRoot: root),
      localGameIdGenerator: () => 'games.local.dialog',
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
            chooseProjectFile: (type) async => switch (type) {
              GamePackageProjectFileType.image => File(
                p.join(root.path, 'assets', 'icon.png'),
              ),
              GamePackageProjectFileType.audio => null,
              GamePackageProjectFileType.text => File(
                p.join(root.path, 'LICENSE.txt'),
              ),
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Publier dans PokeMap Hub'), findsOneWidget);
    expect(find.text('Export rapide'), findsOneWidget);
    expect(find.text('Publication complète'), findsOneWidget);
    expect(find.text('Game ID stable'), findsNothing);
    expect(
      tester
          .widget<PokeMapButton>(
            find.widgetWithText(PokeMapButton, 'Exporter pour tester'),
          )
          .onPressed,
      isNotNull,
    );

    tester
        .widget<PokeMapSegmentedTabs>(find.byType(PokeMapSegmentedTabs))
        .tabs
        .last
        .onTap!
        .call();
    await tester.pump();

    expect(
      find.textContaining(
        'Laissez vide tout fichier que vous ne fournissez pas',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('doivent déjà exister dans le dossier du projet'),
      findsOneWidget,
    );
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
    final iconPicker = find.byKey(
      const ValueKey<String>('game-export-icon-picker'),
    );
    await tester.ensureVisible(iconPicker);
    await tester.tap(iconPicker);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    final licensePicker = find.byKey(
      const ValueKey<String>('game-export-license-picker'),
    );
    await tester.ensureVisible(licensePicker);
    await tester.tap(licensePicker);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('game-export-icon')),
          )
          .controller
          ?.text,
      'assets/icon.png',
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('game-export-license')),
          )
          .controller
          ?.text,
      'LICENSE.txt',
    );

    final exportButton = tester.widget<PokeMapButton>(
      find.widgetWithText(PokeMapButton, 'Exporter le jeu'),
    );
    expect(exportButton.onPressed, isNotNull);
    await tester.runAsync(() async {
      exportButton.onPressed!.call();
      for (
        var attempt = 0;
        attempt < 200 &&
            controller.snapshot.status != GamePackageExportStatus.succeeded &&
            controller.snapshot.status != GamePackageExportStatus.error;
        attempt++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pump();

    expect(output.existsSync(), isTrue);
    expect(find.text('Package certifié'), findsOneWidget);
  });

  testWidgets('exports a local test package without publication metadata', (
    tester,
  ) async {
    late final Directory root;
    await tester.runAsync(() async {
      root = await createAuthorProject(withDialogue: false);
    });
    addTearDown(() => root.delete(recursive: true));
    final output = File(p.join(root.parent.path, 'quick-dialog.avelunegame'));
    addTearDown(() async {
      if (await output.exists()) await output.delete();
    });
    final controller = GamePackageExportController(
      projectRoot: root,
      projectName: 'Neutral Adventure',
      profileStore: GamePackageExportProfileStore(projectRoot: root),
      localGameIdGenerator: () => 'games.local.quickdialog',
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
            chooseProjectFile: (_) async => null,
          ),
        ),
      ),
    );
    await tester.pump();

    final exportButton = tester.widget<PokeMapButton>(
      find.widgetWithText(PokeMapButton, 'Exporter pour tester'),
    );
    await tester.runAsync(() async {
      exportButton.onPressed!.call();
      for (
        var attempt = 0;
        attempt < 200 &&
            controller.snapshot.status != GamePackageExportStatus.succeeded &&
            controller.snapshot.status != GamePackageExportStatus.error;
        attempt++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pump();

    expect(controller.snapshot.status, GamePackageExportStatus.succeeded);
    expect(output.existsSync(), isTrue);
  });

  testWidgets(
    'shows creator diagnostics instead of certification when blocked',
    (tester) async {
      late final Directory root;
      await tester.runAsync(() async {
        root = await createAuthorProject(withDialogue: false);
        final projectFile = File(p.join(root.path, 'project.json'));
        final project =
            jsonDecode(await projectFile.readAsString())
                as Map<String, dynamic>;
        (project['newGame'] as Map<String, dynamic>)['enabled'] = false;
        await projectFile.writeAsString(jsonEncode(project), flush: true);
      });
      addTearDown(() => root.delete(recursive: true));
      final output = File(p.join(root.parent.path, 'blocked-game.avelunegame'));
      addTearDown(() async {
        if (await output.exists()) await output.delete();
      });
      final controller = GamePackageExportController(
        projectRoot: root,
        projectName: 'Neutral Adventure',
        profileStore: GamePackageExportProfileStore(projectRoot: root),
        localGameIdGenerator: () => 'games.local.blocked',
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
              chooseProjectFile: (_) async => null,
            ),
          ),
        ),
      );
      await tester.pump();

      final exportButton = tester.widget<PokeMapButton>(
        find.widgetWithText(PokeMapButton, 'Exporter pour tester'),
      );
      await tester.runAsync(() async {
        exportButton.onPressed!.call();
        for (
          var attempt = 0;
          attempt < 200 &&
              controller.snapshot.status != GamePackageExportStatus.error;
          attempt++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pump();

      expect(find.text('Diagnostics de jouabilité'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>(
              'game-export-gameplay-readiness-diagnostics',
            ),
          ),
          matching: find.textContaining('Activez Nouvelle Partie'),
        ),
        findsOneWidget,
      );
      expect(find.text('Package certifié'), findsNothing);
      expect(output.existsSync(), isFalse);
    },
  );

  testWidgets('shows a copyable technical diagnostic and persistent log path', (
    tester,
  ) async {
    late final Directory root;
    await tester.runAsync(() async {
      root = await createAuthorProject(withDialogue: false);
    });
    final outputDirectory = Directory(
      p.join(root.parent.path, 'dialog-blocked.avelunegame'),
    );
    final diagnosticLog = File(
      p.join(root.parent.path, 'logs', 'game-export.log'),
    );
    await tester.runAsync(outputDirectory.create);
    addTearDown(() async {
      await root.delete(recursive: true);
      if (await outputDirectory.exists()) {
        await outputDirectory.delete(recursive: true);
      }
      if (await diagnosticLog.parent.exists()) {
        await diagnosticLog.parent.delete(recursive: true);
      }
    });
    final controller = GamePackageExportController(
      projectRoot: root,
      projectName: 'Neutral Adventure',
      profileStore: GamePackageExportProfileStore(projectRoot: root),
      diagnosticLogFile: diagnosticLog,
      localGameIdGenerator: () => 'games.local.diagnostic',
      exportService: GamePackageExportService(
        atomicFileWriter:
            ({
              required outputFile,
              required packageBytes,
              required packageSha256,
            }) async {
              throw FileSystemException(
                'Operation not permitted',
                '${outputFile.path}.sandbox-stage.tmp',
                const OSError('Operation not permitted', 1),
              );
            },
      ),
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
            chooseOutputFile: (_) async => File(outputDirectory.path),
            chooseProjectFile: (_) async => null,
          ),
        ),
      ),
    );
    await tester.pump();

    final exportButton = tester.widget<PokeMapButton>(
      find.widgetWithText(PokeMapButton, 'Exporter pour tester'),
    );
    await tester.runAsync(() async {
      exportButton.onPressed!.call();
      for (
        var attempt = 0;
        attempt < 200 &&
            controller.snapshot.status != GamePackageExportStatus.error;
        attempt++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pump();

    expect(find.text('Détails techniques'), findsOneWidget);
    expect(find.text('Copier le diagnostic'), findsOneWidget);
    expect(find.textContaining('game-export.log'), findsOneWidget);
    expect(find.textContaining('Operation not permitted'), findsOneWidget);
  });
}
