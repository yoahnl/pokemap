import 'dart:async';

import 'package:avelune_studio/app/di/project_session_providers.dart';
import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/presentation/features/game_export/game_export_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/game_export_ui_probe.dart';
import 'map_builder_selection_harness.dart';
import 'story_memory_harness.dart';

void main() {
  testWidgets(
    'export commits a focused Histoire name before locking the draft',
    (tester) async {
      final probe = GameExportUiProbe();
      addTearDown(probe.dispose);
      await openMemoryStudio(tester, memoryIndex(), exportPort: probe);
      await openHistoire(tester);
      await tester.tap(find.byKey(const ValueKey('memory-fact-coins')));
      await settleMemory(tester);
      final field = find.descendant(
        of: find.byKey(const ValueKey('memory-fact-name-coins')),
        matching: find.byType(TextField),
      );
      await tester.enterText(field, 'Pièces pour UwU');
      final export = tester.widget<IconButton>(
        find.descendant(
          of: find.byKey(const ValueKey('studio-export-game')),
          matching: find.byType(IconButton),
        ),
      );
      export.onPressed!();
      await tester.pumpAndSettle();
      expect(find.byType(GameExportDialog), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('export-close')));
      await tester.pumpAndSettle();
      expect(find.text('Pièces pour UwU'), findsWidgets);
    },
  );

  testWidgets('native exit is refused until the export dialog is closed', (
    tester,
  ) async {
    final gate = Completer<void>();
    final probe = GameExportUiProbe()
      ..gate = gate
      ..heldStage = StudioExportStage.writing;
    addTearDown(probe.dispose);
    final host = await openSelectionHost(
      tester,
      exportPort: probe,
      exportPicker: (_) async => const StudioGameExportDestination(
        '/output/shell.avelunegame',
        exists: false,
      ),
    );
    final guard = host.container.read(studioExitGuardProvider);
    expect(await guard.confirmLeave(), isTrue);
    await tester.tap(find.byKey(const ValueKey('studio-export-game')));
    await tester.pumpAndSettle();
    expect(await guard.confirmLeave(), isFalse);
    await tester.tap(find.byKey(const ValueKey('export-submit')));
    await tester.pump();
    expect(await guard.confirmLeave(), isFalse);
    gate.complete();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('export-close')));
    await tester.pumpAndSettle();
    expect(await guard.confirmLeave(), isTrue);
  });

  testWidgets('export remains accessible in Histoire without an active map', (
    tester,
  ) async {
    final probe = GameExportUiProbe();
    addTearDown(probe.dispose);
    final host = await openSelectionHost(
      tester,
      manifest: selectionProject().copyWith(maps: []),
      exportPort: probe,
      exportPicker: (_) async => null,
    );
    expect(host.maps.active, isNull);
    await tester.tap(find.byKey(const ValueKey('studio-rail-story')));
    await host.settle();
    await tester.tap(find.byKey(const ValueKey('studio-export-game')));
    await tester.pumpAndSettle();
    expect(find.byType(GameExportDialog), findsOneWidget);
  });

  for (final failSave in [false, true]) {
    testWidgets('shell export saves all map drafts, save failure=$failSave', (
      tester,
    ) async {
      final probe = GameExportUiProbe();
      addTearDown(probe.dispose);
      final host = await openSelectionHost(
        tester,
        exportPort: probe,
        exportPicker: (_) async => const StudioGameExportDestination(
          '/output/shell.avelunegame',
          exists: false,
        ),
      );
      await host.click('oak_1');
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await host.settle();
      await host.maps.activate(host.maps.project!.maps.last);
      await host.settle();
      expect(host.maps.dirty, isTrue);
      host.port.failSave = failSave;
      await tester.tap(find.byKey(const ValueKey('studio-export-game')));
      await tester.pumpAndSettle();
      expect(find.byType(GameExportDialog), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('export-submit')));
      await tester.pumpAndSettle();
      expect(probe.preparations, 1);
      if (failSave) {
        expect(host.maps.dirty, isTrue);
        expect(probe.outputPath, isNull);
        expect(
          host.port.saved['a']!.spatialScene!.instances.map((e) => e.id),
          contains('oak_1'),
        );
      } else {
        expect(host.maps.dirty, isFalse);
        expect(probe.outputPath, '/output/shell.avelunegame');
        expect(
          host.port.saved['a']!.spatialScene!.instances.map((e) => e.id),
          isNot(contains('oak_1')),
        );
      }
    });
  }
}
