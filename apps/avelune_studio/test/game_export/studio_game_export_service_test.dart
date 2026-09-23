import 'dart:io';

import 'package:avelune_studio/presentation/features/game_export/studio_game_export_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';

import '../support/game_export_fixture.dart';
import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';
import '../support/m3_story_fixture.dart';
import '../support/map_host_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;

void main() {
  testWidgets('native destination failure is shown without losing the page', (
    tester,
  ) async {
    final f = await MapHostFixture.open(
      tester,
      prepareSource: prepareGameExportFixture,
      gameExportPicker: (_) async => throw const FileSystemException('Denied'),
    );
    await f.go('Exporter le jeu');
    await tester.tap(find.text('Choisir le fichier et exporter'));
    await pumpIo(tester, frames: 4);
    expect(
      find.textContaining('Sélection du fichier impossible'),
      findsOneWidget,
    );
    expect(find.byType(StudioGameExportPage), findsOneWidget);
  });

  testWidgets(
    'a rejected owner save keeps the interaction draft and blocks export',
    (tester) async {
      final output = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('as-exp-invalid-save-'),
      ))!;
      addTearDown(() => output.delete(recursive: true));
      final target = File('${output.path}/blocked.avelunegame');
      final f = await MapHostFixture.open(
        tester,
        prepareSource: prepareGameExportFixture,
        gameExportPicker: (_) async => target,
      );
      await tester.tap(find.byTooltip('Dessiner une zone d’histoire'));
      await pumpIo(tester, frames: 4);
      await f.drag(3, 11, 5, 13);
      await pumpIo(tester, frames: 10);
      await tester.enterText(
        find.widgetWithText(TextField, 'Nom de l’interaction'),
        'Brouillon invalide',
      );
      await f.go('Exporter le jeu');
      await tester.enterText(
        find.widgetWithText(TextField, 'Auteur'),
        'Avelune',
      );
      await tester.tap(find.text('Choisir le fichier et exporter'));
      await pumpIo(tester, frames: 8);
      expect(find.text('Enregistrer avant l’export ?'), findsOneWidget);
      await tester.tap(find.text('Enregistrer puis exporter'));
      await pumpIo(tester, frames: 20);
      expect(
        find.textContaining('Enregistrement préalable refusé'),
        findsOneWidget,
      );
      expect(await tester.runAsync(target.exists), isFalse);
      await f.go('Histoire');
      final narrative = await f.narrativeOwner();
      expect(narrative.dirty, isTrue);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'declining replacement preserves an existing package',
    (tester) async {
      final output = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('as-exp-existing-'),
      ))!;
      addTearDown(() => output.delete(recursive: true));
      final target = File('${output.path}/existing.avelunegame');
      await tester.runAsync(() => target.writeAsString('existing package'));
      final f = await MapHostFixture.open(
        tester,
        prepareSource: prepareGameExportFixture,
        gameExportPicker: (_) async => target,
      );
      await f.go('Exporter le jeu');
      await tester.enterText(
        find.widgetWithText(TextField, 'Auteur'),
        'Avelune',
      );
      await tester.tap(find.text('Choisir le fichier et exporter'));
      await pumpIo(tester, frames: 5);
      expect(find.text('Remplacer ce paquet ?'), findsOneWidget);
      await tester.tap(find.text('Conserver'));
      await pumpIo(tester, frames: 5);
      expect(await tester.runAsync(target.readAsString), 'existing package');
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'Studio exports the saved two-map story through its own page',
    (tester) async {
      await tester.runAsync(loadDesktopCaptureFonts);
      final output = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('as-exp-ui-output-'),
      ))!;
      addTearDown(() => output.delete(recursive: true));
      final target = File('${output.path}/depart.avelunegame');
      final captureKey = GlobalKey();
      final f = await MapHostFixture.open(
        tester,
        prepareSource: prepareGameExportFixture,
        gameExportPicker: (_) async => target,
        captureKey: captureKey,
      );
      final authorBefore = await f.disk();
      await f.go('Exporter le jeu');
      expect(find.byType(StudioGameExportPage), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Auteur'),
        'Avelune',
      );
      await tester.tap(find.text('Choisir le fichier et exporter'));
      await pumpIo(tester, frames: 120);
      final page = tester.widget<StudioGameExportPage>(
        find.byType(StudioGameExportPage),
      );
      expect(
        find.text('Paquet prêt'),
        findsOneWidget,
        reason: 'stage=${page.controller.stage} error=${page.controller.error}',
      );
      await captureM3Widget(tester, captureKey, 'export-ready');
      expect(await tester.runAsync(target.exists), isTrue);
      expect(await f.disk(), authorBefore);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'the two-map story fixture exports with the canonical service',
    () async {
      final fixture = await M3StoryFixture.create();
      final output = await Directory.systemTemp.createTemp('as-exp-output-');
      addTearDown(() async {
        await fixture.directory.delete(recursive: true);
        await output.delete(recursive: true);
      });
      await prepareGameExportFixture(fixture);
      final artifact = await const CanonicalGamePackageExportService()
          .exportToFile(
            projectRoot: fixture.directory,
            profile: GamePackageExportProfile(
              gameId: 'games.avelune.export-demo',
              gameVersion: '0.1.0',
              title: 'Départ Avelune',
              authorName: 'Avelune',
              defaultLocale: 'fr',
              supportedLocales: const ['fr'],
            ),
            outputFile: File('${output.path}/demo.avelunegame'),
            mode: GamePackageExportMode.publication,
          );
      expect(artifact.certification.isExportable, isTrue);
    },
  );
}
