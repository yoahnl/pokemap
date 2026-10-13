import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/pokemap_guided_slider.dart';
import 'package:map_editor/src/ui/panels/map_properties_panel.dart';

void main() {
  testWidgets(
    'editing another property preserves exact gain through save and reopen',
    (tester) async {
      final container = await _pump(tester, 0.375);
      await tester.enterText(
        find.byType(CupertinoTextField).first,
        'Route renommée',
      );
      await tester.ensureVisible(find.text('Enregistrer les propriétés'));
      await tester.tap(find.text('Enregistrer les propriétés'));
      await tester.pump();
      final state = container.read(editorNotifierProvider);
      expect(state.errorMessage, isNull);
      expect(state.activeMap!.mapMetadata.displayName, 'Route renommée');
      expect(state.activeMap!.mapMetadata.musicVolume, 0.375);
      final reopened = await _saveAndReopen(state.activeMap!);
      expect(reopened.mapMetadata.musicVolume, 0.375);
      expect(reopened.mapMetadata.musicPath, 'assets/music/route.ogg');
    },
  );

  testWidgets(
    'guided volume control authors silence and explicit native default',
    (tester) async {
      final container = await _pump(tester, 0.8);
      expect(find.byType(PokeMapGuidedSlider), findsOneWidget);
      final slider = find.descendant(
        of: find.byType(PokeMapGuidedSlider),
        matching: find.byType(CupertinoSlider),
      );
      await tester.ensureVisible(slider);
      await tester.drag(slider, const Offset(-600, 0));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Enregistrer les propriétés'));
      await tester.tap(find.text('Enregistrer les propriétés'));
      await tester.pump();
      final silent = container.read(editorNotifierProvider).activeMap!;
      expect(silent.mapMetadata.musicVolume, 0);
      expect((await _saveAndReopen(silent)).mapMetadata.musicVolume, 0);
      await tester.ensureVisible(find.text('Volume par défaut (80 %)'));
      await tester.tap(find.text('Volume par défaut (80 %)'));
      await tester.pump();
      await tester.ensureVisible(find.text('Enregistrer les propriétés'));
      await tester.tap(find.text('Enregistrer les propriétés'));
      await tester.pump();
      final defaults = container.read(editorNotifierProvider).activeMap!;
      expect(defaults.mapMetadata.musicVolume, isNull);
      expect((await _saveAndReopen(defaults)).mapMetadata.musicVolume, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<ProviderContainer> _pump(WidgetTester tester, double? volume) async {
  await tester.binding.setSurfaceSize(const Size(700, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final container = ProviderContainer();
  final subscription = container.listen(
    editorNotifierProvider,
    (_, _) {},
    fireImmediately: true,
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    subscription.close();
    container.dispose();
  });
  container.read(editorNotifierProvider.notifier).state = EditorState(
    activeMap: MapData(
      id: 'route',
      name: 'Route',
      size: const GridSize(width: 2, height: 2),
      mapMetadata: MapMetadata(
        displayName: 'Route',
        musicPath: 'assets/music/route.ogg',
        musicVolume: volume,
        tags: const ['outdoor'],
      ),
    ),
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.dark(),
        builder: (context, child) => PokeMapMacosCompatibilityBridge(
          child: child ?? const SizedBox.shrink(),
        ),
        home: const Scaffold(body: MapPropertiesPanel()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<MapData> _saveAndReopen(MapData map) async {
  final directory = await Directory.systemTemp.createTemp(
    'map-properties-gain-',
  );
  try {
    final repository = FileMapRepository();
    final path = '${directory.path}/route.json';
    await repository.saveMap(map, path);
    return await repository.loadMap(path);
  } finally {
    await directory.delete(recursive: true);
  }
}
