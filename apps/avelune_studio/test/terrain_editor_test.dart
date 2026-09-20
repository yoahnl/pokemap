import 'dart:async';

import 'package:avelune_studio/presentation/features/terrains/terrain_editor_screen.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'terrain_creation_test.dart'
    show terrainDraft, assignAll, publishFixture;

void main() {
  testWidgets(
    'source assignment, scratch correction and publication activate the saved preset',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final model = terrainDraft();
      assignAll(model);
      final gate = Completer<void>();
      final actions = <String>[];
      ProjectSmartTilePreset? used;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: TerrainEditorScreen(
              controller: model,
              image: const ColoredBox(color: Color(0xff346a85)),
              frameBuilder: (frame, size) => SizedBox(
                width: size,
                height: size,
                child: Text(
                  '${frame.column},${frame.row}',
                  style: const TextStyle(fontSize: 7),
                ),
              ),
              onMutate: (action, parameters) async {
                actions.add(action);
                if (action.endsWith('upsert')) await gate.future;
                return publishFixture(model);
              },
              onUse: (preset) => used = preset,
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('terrain-rule-3')));
      await tester.pumpAndSettle();
      final source = tester.getRect(
        find.byKey(const ValueKey('atlas-selection')),
      );
      await tester.tapAt(
        source.topLeft +
            Offset(11 * source.width / 78, 16 * source.height / 110),
      );
      await tester.pump();
      expect(model.frameFor(3)!.column, 0);
      expect(model.frameFor(3)!.row, 0);
      final scratch = tester.getRect(
        find.byKey(const ValueKey('terrain-scratch')),
      );
      final cell = scratch.width / 17;
      await tester.tapAt(scratch.topLeft + Offset(cell * 14.5, cell * 14.5));
      await tester.pump();
      expect(model.selectedRule, 15);
      expect(find.text('Raccord sélectionné : Centre'), findsOneWidget);
      await tester.tap(find.text('Publier et peindre'));
      await tester.pump();
      expect(model.busy, isTrue);
      expect(used, isNull);
      final publishButton = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Publier et peindre'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(publishButton.onPressed, isNull);
      gate.complete();
      await tester.pumpAndSettle();
      expect(actions, [
        'smart_tile.preset.draft.upsert',
        'smart_tile.preset.publish',
      ]);
      expect(used!.id, model.draft.targetPresetId);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('small editor at enlarged text keeps all sections scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final model = terrainDraft();
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
          child: Scaffold(
            body: TerrainEditorScreen(
              controller: model,
              image: const SizedBox(),
              frameBuilder: (_, _) => const SizedBox(),
              onMutate: (_, _) async => model.manifest,
              onUse: (_) {},
              onClose: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Essayer'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Terrain d’essai'), findsOneWidget);
  });
}
