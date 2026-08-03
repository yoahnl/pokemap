import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/panels/placed_element_properties_panel.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

void main() {
  testWidgets(
    'public panel reuses placed-element forms and existing notifier commands',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final keepAlive = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);
      final notifier = container.read(editorNotifierProvider.notifier)
        ..state = const EditorState(
          project: _project,
          activeMap: _map,
          activeLayerId: 'ground',
          savedMapSnapshot: _map,
        );

      await tester.binding.setSurfaceSize(const Size(700, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: const MaterialApp(
              home: CupertinoPageScaffold(
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: 520,
                    child: PlacedElementPropertiesPanel(
                      instanceId: 'placed-lamp',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
          find.text("Propriétés de l'instance sélectionnée"), findsOneWidget);
      expect(find.text('Lamp (lamp)'), findsOneWidget);
      expect(find.text('Collision'), findsOneWidget);
      expect(find.text('Opacité'), findsOneWidget);
      expect(find.text('Ombre de cette instance'), findsOneWidget);
      expect(find.text('Animation'), findsOneWidget);
      expect(
          find.text('Aperçu indisponible pour le tileset actuellement chargé.'),
          findsOneWidget);
      expect(find.textContaining('Rotation'), findsNothing);
      expect(find.textContaining('Dupliquer'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('placed-element-collision-switch')),
      );
      await tester.pump();
      expect(
        notifier.state.activeMap!.placedElements.single.applyCollision,
        isFalse,
      );

      final slider = tester.widget<PokeMapGuidedSlider>(
        find.byKey(const ValueKey('placed-instance-opacity-slider')),
      );
      slider.onChangeStart?.call(slider.value);
      slider.onChanged(45);
      slider.onChangeEnd?.call(45);
      await tester.pump();
      expect(
        notifier.state.activeMap!.placedElements.single.opacity,
        0.45,
      );
    },
  );

  testWidgets('missing instance is read-only guidance', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final keepAlive = container.listen(editorNotifierProvider, (_, __) {});
    addTearDown(keepAlive.close);
    final notifier = container.read(editorNotifierProvider.notifier)
      ..state = const EditorState(
        project: _project,
        activeMap: _map,
        activeLayerId: 'ground',
        savedMapSnapshot: _map,
      );
    final before = notifier.state;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 520,
                height: 400,
                child: PlacedElementPropertiesPanel(
                  instanceId: 'missing',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Instance introuvable'), findsOneWidget);
    expect(notifier.state, same(before));
  });

  testWidgets(
    'delete confirmation never targets a same-id instance after map identity changes',
    (tester) async {
      final mapB = _map.copyWith(
        placedElements: <MapPlacedElement>[
          _map.placedElements.single.copyWith(opacity: 0.75),
        ],
      );
      expect(mapB, _map);
      expect(identical(mapB, _map), isFalse);
      expect(
        identical(mapB.placedElements.single, _map.placedElements.single),
        isFalse,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final keepAlive = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);
      final notifier = container.read(editorNotifierProvider.notifier)
        ..state = const EditorState(
          project: _project,
          activeMap: _map,
          activeLayerId: 'ground',
          selectedPlacedElementInstanceId: 'placed-lamp',
          savedMapSnapshot: _map,
        );

      await tester.binding.setSurfaceSize(const Size(700, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: const MaterialApp(
              home: CupertinoPageScaffold(
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: 520,
                    child: PlacedElementPropertiesPanel(
                      instanceId: 'placed-lamp',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final delete = find.text('Supprimer cette instance');
      await tester.ensureVisible(delete);
      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(find.text('Supprimer l’instance'), findsOneWidget);

      notifier.state = notifier.state.copyWith(
        activeMap: mapB,
        savedMapSnapshot: mapB,
        mapUndoStack: const [],
        mapRedoStack: const [],
        mapStrokeStart: null,
      );
      await tester.tap(find.widgetWithText(PushButton, 'Supprimer'));
      await tester.pumpAndSettle();

      expect(notifier.state.activeMap, same(mapB));
      expect(notifier.state.activeMap!.placedElements, hasLength(1));
      expect(
        notifier.state.activeMap!.placedElements.single,
        same(mapB.placedElements.single),
      );
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(notifier.state.mapRedoStack, isEmpty);
      expect(notifier.state.mapStrokeStart, isNull);
    },
  );

  testWidgets(
    'opacity drag closes one exact transaction with undo and redo',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final keepAlive = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);
      final notifier = container.read(editorNotifierProvider.notifier)
        ..state = const EditorState(
          project: _project,
          activeMap: _map,
          activeLayerId: 'ground',
          selectedPlacedElementInstanceId: 'placed-lamp',
          savedMapSnapshot: _map,
        );

      await tester.binding.setSurfaceSize(const Size(700, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: const MaterialApp(
              home: CupertinoPageScaffold(
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: 520,
                    child: PlacedElementPropertiesPanel(
                      instanceId: 'placed-lamp',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final control = find.byKey(
        const ValueKey('placed-instance-opacity-slider'),
      );
      await tester.ensureVisible(control);
      await tester.pump();
      final slider = find.descendant(
        of: control,
        matching: find.byType(CupertinoSlider),
      );
      final rect = tester.getRect(slider);
      final thumbX = rect.left + 22 + (rect.width - 44) * 0.75;
      final gesture = await tester.startGesture(
        Offset(thumbX, rect.center.dy),
      );
      await gesture.moveTo(
        Offset(rect.left + rect.width * 0.6, rect.center.dy),
      );
      await tester.pump();
      await gesture.moveTo(
        Offset(rect.left + rect.width * 0.4, rect.center.dy),
      );
      await tester.pump();
      await gesture.moveTo(
        Offset(rect.left + rect.width * 0.2, rect.center.dy),
      );
      await tester.pump();

      final finalOpacity =
          notifier.state.activeMap!.placedElements.single.opacity;
      expect(finalOpacity, lessThan(0.75));
      expect(notifier.state.mapStrokeStart, isNotNull);
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(notifier.state.mapRedoStack, isEmpty);

      await gesture.up();
      await tester.pump();

      expect(notifier.state.mapStrokeStart, isNull);
      expect(notifier.state.mapUndoStack, hasLength(1));
      expect(notifier.state.mapRedoStack, isEmpty);

      notifier.undoMap();
      expect(notifier.state.activeMap!.placedElements.single.opacity, 0.75);
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(notifier.state.mapRedoStack, hasLength(1));

      notifier.redoMap();
      expect(
        notifier.state.activeMap!.placedElements.single.opacity,
        finalOpacity,
      );
      expect(notifier.state.mapUndoStack, hasLength(1));
      expect(notifier.state.mapRedoStack, isEmpty);
      expect(notifier.state.mapStrokeStart, isNull);
    },
  );

  testWidgets(
    'cancelled opacity drag closes before the next distinct gesture',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final keepAlive = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);
      final notifier = container.read(editorNotifierProvider.notifier)
        ..state = const EditorState(
          project: _project,
          activeMap: _map,
          activeLayerId: 'ground',
          selectedPlacedElementInstanceId: 'placed-lamp',
          savedMapSnapshot: _map,
        );

      await tester.binding.setSurfaceSize(const Size(700, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: const MaterialApp(
              home: CupertinoPageScaffold(
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: 520,
                    child: PlacedElementPropertiesPanel(
                      instanceId: 'placed-lamp',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final control = find.byKey(
        const ValueKey('placed-instance-opacity-slider'),
      );
      await tester.ensureVisible(control);
      await tester.pump();
      var slider = find.descendant(
        of: control,
        matching: find.byType(CupertinoSlider),
      );
      var rect = tester.getRect(slider);
      var thumbX = rect.left + 22 + (rect.width - 44) * 0.75;
      final cancelled = await tester.startGesture(
        Offset(thumbX, rect.center.dy),
      );
      await cancelled.moveBy(const Offset(-60, 0));
      await tester.pump();

      expect(notifier.state.mapStrokeStart, isNotNull);
      expect(notifier.state.mapUndoStack, isEmpty);

      await cancelled.cancel();
      await tester.pump();

      final opacityAfterCancel =
          notifier.state.activeMap!.placedElements.single.opacity;
      expect(opacityAfterCancel, lessThan(0.75));
      expect(notifier.state.mapStrokeStart, isNull);
      expect(notifier.state.mapUndoStack, hasLength(1));

      slider = find.descendant(
        of: control,
        matching: find.byType(CupertinoSlider),
      );
      rect = tester.getRect(slider);
      thumbX = rect.left + 22 + (rect.width - 44) * opacityAfterCancel;
      final next = await tester.startGesture(
        Offset(thumbX, rect.center.dy),
      );
      await next.moveBy(const Offset(-40, 0));
      await tester.pump();
      await next.up();
      await tester.pump();

      expect(notifier.state.mapStrokeStart, isNull);
      expect(notifier.state.mapUndoStack, hasLength(2));
      expect(notifier.state.mapRedoStack, isEmpty);
    },
  );
}

const _project = ProjectManifest(
  name: 'Placed properties',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
  elementCategories: <ProjectElementCategory>[
    ProjectElementCategory(id: 'decor', name: 'Décor'),
  ],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'lamp',
      name: 'Lamp',
      tilesetId: 'world',
      categoryId: 'decor',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2),
        ),
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 1, y: 0, width: 1, height: 2),
        ),
      ],
    ),
  ],
  settings: ProjectSettings(tileWidth: 16, tileHeight: 16),
);

const _map = MapData(
  id: 'map',
  name: 'Map',
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Ground',
      tilesetId: 'world',
      tiles: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ),
  ],
  placedElements: <MapPlacedElement>[
    MapPlacedElement(
      id: 'placed-lamp',
      layerId: 'ground',
      elementId: 'lamp',
      pos: GridPos(x: 1, y: 2),
      applyCollision: true,
      opacity: 0.75,
    ),
  ],
);
