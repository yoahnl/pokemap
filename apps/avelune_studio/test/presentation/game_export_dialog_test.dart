import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/game_export/game_export_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/game_export_ui_probe.dart';

Finder control(String name) => find.byKey(ValueKey('export-$name'));
StudioButton button(WidgetTester tester, String name) =>
    tester.widget(control(name));

Future<void> openExport(
  WidgetTester tester,
  GameExportUiProbe port, {
  PickGameExportFile? picker,
  Future<bool> Function()? prepare,
  bool Function()? current,
  String language = 'fr',
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  addTearDown(port.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => GameExportDialog(
                port: port,
                pickFile:
                    picker ??
                    (_) async => const StudioGameExportDestination(
                      '/output/game.avelunegame',
                      exists: false,
                    ),
                prepare: prepare ?? () async => true,
                hasPendingChanges: () => false,
                isCurrentProject: current ?? () => true,
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('validation preserves input and prevents the picker and export', (
    tester,
  ) async {
    var picks = 0;
    final port = GameExportUiProbe()
      ..problem = const StudioGameIdentityProblem(
        StudioGameIdentityField.version,
        'Version invalide',
      );
    await openExport(
      tester,
      port,
      picker: (_) async {
        picks++;
        return null;
      },
    );
    await tester.enterText(
      find.descendant(of: control('version'), matching: find.byType(TextField)),
      'oops',
    );
    await tester.tap(control('submit'));
    await tester.pumpAndSettle();
    expect(picks, 0);
    expect(port.exports, 0);
    expect(find.text('oops'), findsOneWidget);
    expect(find.text('Version invalide'), findsWidgets);
  });

  testWidgets(
    'picker cancellation and errors preserve metadata without saving',
    (tester) async {
      var picks = 0;
      final port = GameExportUiProbe();
      await openExport(
        tester,
        port,
        picker: (name) async {
          expect(name, 'Mon jeu');
          if (++picks == 1) return null;
          throw StateError('picker unavailable');
        },
      );
      await tester.enterText(
        find.descendant(of: control('title'), matching: find.byType(TextField)),
        'Mon jeu',
      );
      await tester.tap(control('submit'));
      await tester.pumpAndSettle();
      expect(port.exports, 0);
      expect(find.text('Mon jeu'), findsOneWidget);
      await tester.tap(control('submit'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Impossible de choisir le fichier de destination. Réessayez.',
        ),
        findsOneWidget,
      );
      expect(port.preparations, 0);
    },
  );

  testWidgets('replacement must be confirmed before saving and exporting', (
    tester,
  ) async {
    final port = GameExportUiProbe();
    await openExport(
      tester,
      port,
      picker: (_) async => const StudioGameExportDestination(
        '/output/old.avelunegame',
        exists: true,
      ),
    );
    await tester.tap(control('submit'));
    await tester.pumpAndSettle();
    expect(port.exports, 0);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(port.preparations, 0);
    await tester.tap(control('submit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remplacer et exporter'));
    await tester.pumpAndSettle();
    expect(port.overwrite, isTrue);
    expect(port.publicationMode, isFalse);
    expect(port.preparations, 1);
    expect(find.text('/output/old.avelunegame'), findsOneWidget);
    expect(control('submit'), findsNothing);
    await tester.tap(control('close'));
    await tester.pumpAndSettle();
    expect(find.byType(GameExportDialog), findsNothing);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text(port.metadata!.version), findsOneWidget);
  });

  testWidgets('failed save keeps the form editable and reports failure', (
    tester,
  ) async {
    final port = GameExportUiProbe();
    await openExport(tester, port, prepare: () async => false);
    await tester.tap(control('submit'));
    await tester.pumpAndSettle();
    expect(port.outputPath, isNull);
    expect(find.text('Enregistrement préalable refusé'), findsWidgets);
    expect(button(tester, 'submit').onPressed, isNotNull);
    expect(find.text('Yoahn'), findsOneWidget);
  });

  testWidgets('an unreadable profile cannot be replaced with silent defaults', (
    tester,
  ) async {
    final port = GameExportUiProbe()..loadFailed = true;
    await openExport(tester, port);
    expect(control('title'), findsNothing);
    expect(button(tester, 'submit').onPressed, isNull);
    port.loadFailed = false;
    await tester.tap(find.text('Recharger le profil'));
    await tester.pumpAndSettle();
    expect(port.loads, 2);
    expect(find.text('Yoahn'), findsOneWidget);
    expect(button(tester, 'submit').onPressed, isNotNull);
  });

  testWidgets('shows export steps and the percentage of completed steps', (
    tester,
  ) async {
    final gate = Completer<void>();
    final port = GameExportUiProbe()..gate = gate;
    await openExport(tester, port, scale: 1.4);
    await tester.tap(control('submit'));
    await tester.pump();
    expect(find.text('4 étapes sur 10 terminées · 40 %'), findsOneWidget);
    expect(find.text('Rassembler les fichiers du jeu'), findsOneWidget);
    expect(find.text('Écrire le paquet'), findsOneWidget);
    expect(tester.takeException(), isNull);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('10 étapes sur 10 terminées · 100 %'), findsOneWidget);
  });

  testWidgets('a project switch while picking prevents any late export', (
    tester,
  ) async {
    var current = true;
    final selection = Completer<StudioGameExportDestination?>();
    final port = GameExportUiProbe();
    await openExport(
      tester,
      port,
      current: () => current,
      picker: (_) => selection.future,
    );
    await tester.tap(control('submit'));
    await tester.pump();
    current = false;
    selection.complete(
      const StudioGameExportDestination(
        '/output/late.avelunegame',
        exists: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(port.exports, 0);
    expect(button(tester, 'submit').onPressed, isNull);
  });

  testWidgets(
    'cancellation waits for the active operation before close or retry',
    (tester) async {
      final gate = Completer<void>();
      final port = GameExportUiProbe()..gate = gate;
      await openExport(tester, port);
      await tester.tap(control('submit'));
      await tester.pump();
      expect(button(tester, 'close').onPressed, isNull);
      await tester.tap(control('cancel'));
      await tester.pump();
      expect(button(tester, 'submit').onPressed, isNull);
      expect(button(tester, 'close').onPressed, isNull);
      expect(control('cancel'), findsNothing);
      gate.complete();
      await tester.pumpAndSettle();
      expect(port.outputPath, isNull);
      expect(button(tester, 'submit').onPressed, isNotNull);
      expect(button(tester, 'close').onPressed, isNotNull);
    },
  );

  testWidgets(
    'writing disables cancellation, repeated submit and back navigation',
    (tester) async {
      final gate = Completer<void>();
      final port = GameExportUiProbe()
        ..gate = gate
        ..heldStage = StudioExportStage.writing;
      await openExport(tester, port);
      await tester.tap(control('submit'));
      await tester.pump();
      expect(control('cancel'), findsNothing);
      expect(button(tester, 'submit').onPressed, isNull);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(GameExportDialog), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();
      expect(port.exports, 1);
      expect(find.text('/output/game.avelunegame'), findsOneWidget);
    },
  );

  for (final language in ['fr', 'en']) {
    testWidgets('long paths and scaled text fit the $language dialog', (
      tester,
    ) async {
      final port = GameExportUiProbe();
      await openExport(
        tester,
        port,
        language: language,
        scale: 1.5,
        picker: (_) async => StudioGameExportDestination(
          '/${List.filled(120, 'long').join('/')}.avelunegame',
          exists: false,
        ),
      );
      await tester.tap(control('submit'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(control('close').hitTestable(), findsOneWidget);
    });
  }
}
