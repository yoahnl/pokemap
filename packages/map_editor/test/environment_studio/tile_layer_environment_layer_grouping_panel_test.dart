import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/panels/layers_panel.dart';
import 'package:map_editor/src/ui/design_system/pokemap_icon_button.dart';

void main() {
  group('TileLayer environment grouping LayersPanel', () {
    testWidgets('affiche le TileLayer avec badge et masque la row technique',
        (tester) async {
      final container = await _pumpLayersPanel(
        tester,
        activeLayerId: 'decor',
        map: _mapWithAttachedEnvironment(),
      );

      expect(find.text('Décor'), findsOneWidget);
      expect(find.text('Environnement actif'), findsOneWidget);
      expect(find.text('Environment — Décor'), findsNothing);
      expect(find.text('Objects'), findsOneWidget);
      expect(container.read(editorNotifierProvider).activeLayerId, 'decor');
    });

    testWidgets('EnvironmentLayer invalide reste visible avec warning',
        (tester) async {
      await _pumpLayersPanel(
        tester,
        activeLayerId: 'decor',
        map: _mapWithInvalidEnvironment(),
      );

      expect(find.text('Décor'), findsOneWidget);
      expect(find.text('Environment — Missing'), findsOneWidget);
      expect(find.text('Cible invalide'), findsOneWidget);
    });

    testWidgets('sélection du TileLayer fonctionne toujours', (tester) async {
      final container = await _pumpLayersPanel(
        tester,
        activeLayerId: 'objects',
        map: _mapWithAttachedEnvironment(),
      );

      await tester.tap(find.text('Décor'));
      await tester.pumpAndSettle();

      expect(container.read(editorNotifierProvider).activeLayerId, 'decor');
    });

    testWidgets('EnvironmentLayer attaché actif reste visible via le TileLayer',
        (tester) async {
      await _pumpLayersPanel(
        tester,
        activeLayerId: 'env_decor',
        map: _mapWithAttachedEnvironment(),
      );

      expect(find.text('Décor'), findsOneWidget);
      expect(find.text('Environment — Décor'), findsNothing);
      expect(
        find.text('Environnement technique sélectionné'),
        findsOneWidget,
      );
    });

    testWidgets('layers non-environment restent affichés', (tester) async {
      await _pumpLayersPanel(
        tester,
        activeLayerId: 'collision',
        map: _mapWithAttachedEnvironment(includeCollision: true),
      );

      expect(find.text('Collision'), findsOneWidget);
      expect(find.text('Décor'), findsOneWidget);
      expect(find.text('Objects'), findsOneWidget);
    });

    testWidgets('TileLayer avec EnvironmentLayer attaché protège delete',
        (tester) async {
      final container = await _pumpLayersPanel(
        tester,
        activeLayerId: 'decor',
        map: _mapWithAttachedEnvironment(),
      );

      final deleteButton = _deleteLayerButton(tester, 'decor');

      expect(deleteButton.onPressed, isNull);

      await tester.tap(find.byKey(const ValueKey('delete-layer-decor')));
      await tester.pumpAndSettle();

      expect(find.text('Supprimer le calque'), findsNothing);
      expect(
        container
            .read(editorNotifierProvider)
            .activeMap!
            .layers
            .map((layer) => layer.id),
        ['decor', 'env_decor', 'objects'],
      );
    });

    testWidgets('EnvironmentLayer invalide reste supprimable', (tester) async {
      final container = await _pumpLayersPanel(
        tester,
        activeLayerId: 'env_missing',
        map: _mapWithInvalidEnvironment(),
      );

      final deleteButton = _deleteLayerButton(tester, 'env_missing');

      expect(deleteButton.onPressed, isNotNull);

      await tester.tap(find.byKey(const ValueKey('delete-layer-env_missing')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      expect(
        container
            .read(editorNotifierProvider)
            .activeMap!
            .layers
            .map((layer) => layer.id),
        ['decor'],
      );
    });
  });
}

Future<ProviderContainer> _pumpLayersPanel(
  WidgetTester tester, {
  required MapData map,
  required String activeLayerId,
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(editorNotifierProvider.notifier).state = EditorState(
    activeMap: map,
    activeLayerId: activeLayerId,
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
              width: 420,
              height: 600,
              child: LayersPanel(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

MapData _mapWithAttachedEnvironment({bool includeCollision = false}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 3, height: 3),
    layers: [
      if (includeCollision)
        const CollisionLayer(
          id: 'collision',
          name: 'Collision',
          collisions: [
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false
          ],
        ),
      const TileLayer(
        id: 'decor',
        name: 'Décor',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      _environmentLayer(
        id: 'env_decor',
        name: 'Environment — Décor',
        targetLayerId: 'decor',
      ),
      const ObjectLayer(id: 'objects', name: 'Objects'),
    ],
  );
}

MapData _mapWithInvalidEnvironment() {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 3, height: 3),
    layers: [
      const TileLayer(
        id: 'decor',
        name: 'Décor',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      _environmentLayer(
        id: 'env_missing',
        name: 'Environment — Missing',
        targetLayerId: 'missing',
      ),
    ],
  );
}

EnvironmentLayer _environmentLayer({
  required String id,
  required String name,
  required String targetLayerId,
}) {
  return MapLayer.environment(
    id: id,
    name: name,
    content: EnvironmentLayerContent(targetTileLayerId: targetLayerId),
  ) as EnvironmentLayer;
}

PokeMapIconButton _deleteLayerButton(WidgetTester tester, String layerId) {
  return tester.widget<PokeMapIconButton>(
    find.byKey(ValueKey('delete-layer-$layerId')),
  );
}
