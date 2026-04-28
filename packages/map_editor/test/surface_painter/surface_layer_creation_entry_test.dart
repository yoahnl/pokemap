import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/panels/layers_panel.dart';

void main() {
  group('Surface layer creation entry', () {
    testWidgets('layer type picker can create an explicit SurfaceLayer',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        activeMap: MapData(
          id: 'map_1',
          name: 'Map 1',
          size: GridSize(width: 3, height: 3),
        ),
      );

      await tester.binding.setSurfaceSize(const Size(900, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: const MaterialApp(
              home: CupertinoPageScaffold(
                child: SizedBox(
                  width: 360,
                  height: 520,
                  child: LayersPanel(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is MacosTooltip && widget.message == 'Add Layer',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Add Layer'), findsOneWidget);

      await tester.tap(find.text('Type: Tile Layer'));
      await tester.pumpAndSettle();
      expect(find.text('Layer type'), findsOneWidget);
      expect(find.text('Surface Layer'), findsOneWidget);

      await tester.tap(find.text('Surface Layer'));
      await tester.pumpAndSettle();
      expect(find.text('Type: Surface Layer'), findsOneWidget);
      expect(find.text('Surfaces'), findsOneWidget);

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      final state = container.read(editorNotifierProvider);
      final layer = state.activeMap!.layers.single;
      expect(layer, isA<SurfaceLayer>());
      final surfaceLayer = layer as SurfaceLayer;
      expect(surfaceLayer.id, 'surface-main');
      expect(surfaceLayer.name, 'Surfaces');
      expect(surfaceLayer.placements, isEmpty);
      expect(state.activeLayerId, 'surface-main');
    });

    test('explicit surface layer ids and default names stay unique', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = const EditorState(
        activeMap: MapData(
          id: 'map_1',
          name: 'Map 1',
          size: GridSize(width: 3, height: 3),
        ),
      );

      notifier.addSurfaceLayer();
      notifier.addSurfaceLayer();

      final surfaceLayers = container
          .read(editorNotifierProvider)
          .activeMap!
          .layers
          .whereType<SurfaceLayer>();
      expect(surfaceLayers.map((layer) => layer.id).toSet(), {
        'surface-main',
        'surface-2',
      });
      expect(surfaceLayers.map((layer) => layer.name).toSet(), {
        'Surfaces',
        'Surfaces 2',
      });
    });
  });
}
