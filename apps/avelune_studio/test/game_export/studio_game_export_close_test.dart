import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/game_export/data/studio_game_export_controller.dart';
import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/presentation/features/game_export/studio_game_export_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shell/studio_home_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:path/path.dart' as p;

import '../support/game_export_fixture.dart';
import '../support/map_host_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;

void main() {
  testWidgets(
    'unreadable profile permits workspace and window exit without a draft',
    (tester) async {
      Future<bool> Function()? windowGuard;
      var closes = 0;
      final home = StudioHomeNavigation();
      addTearDown(home.dispose);
      final f = await MapHostFixture.open(
        tester,
        home: home,
        prepareSource: (source) async {
          await prepareGameExportFixture(source);
          final file = File(
            p.join(source.directory.path, '.pokemap', 'export-profile-v1.json'),
          );
          await file.parent.create(recursive: true);
          await file.writeAsString('{invalid', flush: true);
        },
        onClose: () async => closes++,
        registerExitGuard: (guard) => windowGuard = guard,
      );
      await f.openExport();
      expect(find.textContaining('Profil d’export illisible'), findsOneWidget);
      expect(f.gameExport.canStart, isFalse);
      expect(f.gameExport.operationActive, isFalse);
      expect(await windowGuard!(), isTrue);
      expect(await home.allowSwitch!(), isTrue);
      await tester.tap(find.text('Retour à l’accueil'));
      await pumpIo(tester, frames: 16);
      await tester.tap(find.byKey(const ValueKey('Fermer le projet')));
      await pumpIo(tester, frames: 4);
      expect(closes, 1);
      expect(
        await tester.runAsync(
          () => File(
            p.join(
              f.source.directory.path,
              '.pokemap',
              'export-profile-v1.json',
            ),
          ).readAsString(),
        ),
        '{invalid',
      );
    },
  );

  testWidgets('unreadable profile retains the normal draft confirmation', (
    tester,
  ) async {
    Future<bool> Function()? windowGuard;
    final home = StudioHomeNavigation();
    addTearDown(home.dispose);
    final f = await MapHostFixture.open(
      tester,
      home: home,
      prepareSource: (source) async {
        await prepareGameExportFixture(source);
        final file = File(
          p.join(source.directory.path, '.pokemap', 'export-profile-v1.json'),
        );
        await file.parent.create(recursive: true);
        await file.writeAsString('{invalid', flush: true);
      },
      registerExitGuard: (guard) => windowGuard = guard,
    );
    await f.openExport();
    final document = f.document;
    document.commit(document.current.copyWith(name: 'Brouillon conservé'));
    final pending = windowGuard!();
    await pumpIo(tester, frames: 4);
    expect(find.text('Conserver vos modifications ?'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await pumpIo(tester, frames: 4);
    expect(await pending, isFalse);
    expect(document.dirty, isTrue);
    expect(document.current.name, 'Brouillon conservé');
    final switching = home.allowSwitch!();
    await pumpIo(tester, frames: 4);
    expect(find.text('Conserver vos modifications ?'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await pumpIo(tester, frames: 4);
    expect(await switching, isFalse);
    expect(document.dirty, isTrue);
    expect(
      await tester.runAsync(
        () => File(
          p.join(f.source.directory.path, '.pokemap', 'export-profile-v1.json'),
        ).readAsString(),
      ),
      '{invalid',
    );
  });

  testWidgets('cancelled export keeps every exit guard until cleanup finishes', (
    tester,
  ) async {
    Future<bool> Function()? windowGuard;
    var closes = 0;
    final reading = Completer<void>();
    final release = Completer<void>();
    var reads = 0;
    late GamePackageExportArtifact artifact;
    final home = StudioHomeNavigation();
    addTearDown(home.dispose);
    final f = await MapHostFixture.open(
      tester,
      home: home,
      prepareSource: prepareGameExportFixture,
      createGameExport: (source) => StudioGameExportController(
        projectRoot: source.directory,
        projectName: source.session.name,
        buildPackage: (_, _, _) async => artifact,
        readFingerprints: (root) async {
          if (++reads == 2) {
            reading.complete();
            await release.future;
          }
          return const {'project.json': 'unchanged'};
        },
      ),
      onClose: () async => closes++,
      registerExitGuard: (guard) => windowGuard = guard,
    );
    await f.openExport();
    artifact = (await tester.runAsync(
      () => const CanonicalGamePackageExportService().build(
        projectRoot: f.source.directory,
        profile: GamePackageExportProfile(
          gameId: 'games.avelune.exit-test',
          gameVersion: '0.1.0',
          title: 'Exit test',
          authorName: 'Avelune',
          defaultLocale: 'fr',
          supportedLocales: ['fr'],
        ),
      ),
    ))!;
    final target = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('as-exp-close-'),
    ))!;
    addTearDown(() => target.delete(recursive: true));
    final exporting = f.gameExport.export(
      metadata: StudioGameExportMetadata(
        gameId: 'games.avelune.exit-test',
        title: 'Exit test',
        version: '0.1.0',
        author: 'Avelune',
        locale: 'fr',
        locales: 'fr',
      ),
      outputPath: p.join(target.path, 'demo.avelunegame'),
      overwriteConfirmed: false,
      publication: true,
      prepare: () async => true,
      hasPendingChanges: () => false,
      isCurrentProject: () => true,
    );
    for (var i = 0; i < 60 && !reading.isCompleted; i++) {
      await pumpIo(tester, frames: 1);
    }
    expect(
      reading.isCompleted,
      isTrue,
      reason:
          'stage=${f.gameExport.stage} error=${f.gameExport.error} reads=$reads',
    );
    f.gameExport.cancel();
    expect(f.gameExport.stage, StudioExportStage.cancelled);
    expect(f.gameExport.operationActive, isTrue);
    expect(await windowGuard!(), isFalse);
    expect(await home.allowSwitch!(), isFalse);
    await tester.pump();
    expect(
      tester
          .widget<StudioButton>(
            find.widgetWithText(StudioButton, 'Retour à l’accueil'),
          )
          .onPressed,
      isNull,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.tapAt(const Offset(500, 400));
    await pumpIo(tester, frames: 4);
    expect(find.byType(StudioGameExportPage), findsOneWidget);
    expect(closes, 0);
    release.complete();
    expect(await tester.runAsync(() => exporting), isFalse);
    await pumpIo(tester, frames: 4);
    expect(f.gameExport.operationActive, isFalse);
    expect(await windowGuard!(), isTrue);
    expect(await home.allowSwitch!(), isTrue);
    await tester.tap(find.text('Retour à l’accueil'));
    await pumpIo(tester, frames: 16);
    await tester.tap(find.byKey(const ValueKey('Fermer le projet')));
    await pumpIo(tester, frames: 4);
    expect(closes, 1);
  });
}
