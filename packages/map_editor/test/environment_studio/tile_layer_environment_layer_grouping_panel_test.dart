import 'dart:ui' show Tristate;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    testWidgets('flèche haut déplace Tile et Environment comme un bloc',
        (tester) async {
      final container = await _pumpLayersPanel(
        tester,
        activeLayerId: 'decor',
        map: _mapWithReorderableEnvironment(),
      );

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('decor')),
          matching: find.byTooltip('Monter le calque'),
        ),
      );
      await tester.pumpAndSettle();

      final state = container.read(editorNotifierProvider);
      expect(
        state.activeMap!.layers.map((layer) => layer.id),
        ['decor', 'env_decor', 'top', 'bottom'],
      );
      expect(state.mapUndoStack, hasLength(1));
    });

    testWidgets('flèche bas déplace le même groupe sans séparer Environment',
        (tester) async {
      final container = await _pumpLayersPanel(
        tester,
        activeLayerId: 'decor',
        map: _mapWithReorderableEnvironment(),
      );

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('decor')),
          matching: find.byTooltip('Descendre le calque'),
        ),
      );
      await tester.pumpAndSettle();

      final state = container.read(editorNotifierProvider);
      expect(
        state.activeMap!.layers.map((layer) => layer.id),
        ['top', 'bottom', 'decor', 'env_decor'],
      );
      expect(state.mapUndoStack, hasLength(1));
    });

    testWidgets(
        'bornes visibles désactivent Haut et Bas sans créer d’historique',
        (tester) async {
      final container = await _pumpLayersPanel(
        tester,
        activeLayerId: 'decor',
        map: _mapWithReorderableEnvironment(),
      );

      expect(_moveUpButton(tester, 'top').onPressed, isNull);
      expect(_moveDownButton(tester, 'bottom').onPressed, isNull);
      expect(_moveUpButton(tester, 'decor').onPressed, isNotNull);
      expect(_moveDownButton(tester, 'decor').onPressed, isNotNull);

      await tester.tap(find.byKey(const ValueKey('move-layer-up-top')));
      await tester.tap(find.byKey(const ValueKey('move-layer-down-bottom')));
      await tester.pumpAndSettle();

      final state = container.read(editorNotifierProvider);
      expect(
        state.activeMap!.layers.map((layer) => layer.id),
        ['top', 'decor', 'env_decor', 'bottom'],
      );
      expect(state.mapUndoStack, isEmpty);
    });

    testWidgets(
        'sélection Environment technique survit au mouvement et à undo redo',
        (tester) async {
      final container = await _pumpLayersPanel(
        tester,
        activeLayerId: 'env_decor',
        map: _mapWithReorderableEnvironment(),
      );
      final notifier = container.read(editorNotifierProvider.notifier);

      await tester.tap(find.byKey(const ValueKey('move-layer-up-decor')));
      await tester.pumpAndSettle();

      expect(
        container
            .read(editorNotifierProvider)
            .activeMap!
            .layers
            .map((layer) => layer.id),
        ['decor', 'env_decor', 'top', 'bottom'],
      );
      expect(
        container.read(editorNotifierProvider).activeLayerId,
        'env_decor',
      );
      expect(
        container.read(editorNotifierProvider).mapUndoStack,
        hasLength(1),
      );

      notifier.undoMap();
      await tester.pumpAndSettle();
      expect(
        container
            .read(editorNotifierProvider)
            .activeMap!
            .layers
            .map((layer) => layer.id),
        ['top', 'decor', 'env_decor', 'bottom'],
      );
      expect(
        container.read(editorNotifierProvider).activeLayerId,
        'env_decor',
      );

      notifier.redoMap();
      await tester.pumpAndSettle();
      expect(
        container
            .read(editorNotifierProvider)
            .activeMap!
            .layers
            .map((layer) => layer.id),
        ['decor', 'env_decor', 'top', 'bottom'],
      );
      expect(
        container.read(editorNotifierProvider).activeLayerId,
        'env_decor',
      );
    });

    testWidgets('clavier active la flèche et déplace le groupe entier',
        (tester) async {
      final container = await _pumpLayersPanel(
        tester,
        activeLayerId: 'decor',
        map: _mapWithReorderableEnvironment(),
      );
      final moveUp = find.byKey(const ValueKey('move-layer-up-decor'));

      expect(await _focusWithTab(tester, moveUp), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      final state = container.read(editorNotifierProvider);
      expect(
        state.activeMap!.layers.map((layer) => layer.id),
        ['decor', 'env_decor', 'top', 'bottom'],
      );
      expect(state.mapUndoStack, hasLength(1));
    });

    testWidgets(
        'drag avant une row déplace le groupe entier en une transaction',
        (tester) async {
      final container = await _pumpLayersPanel(
        tester,
        activeLayerId: 'decor',
        map: _mapWithReorderableEnvironment(),
      );

      await _dragLayerGroup(
        tester,
        layerId: 'bottom',
        targetKey: 'drop-layer-group-before-decor',
      );

      final state = container.read(editorNotifierProvider);
      expect(
        state.activeMap!.layers.map((layer) => layer.id),
        ['top', 'bottom', 'decor', 'env_decor'],
      );
      expect(state.mapUndoStack, hasLength(1));
    });

    testWidgets('drag en fin conserve le groupe et un undo restaure tout',
        (tester) async {
      final container = await _pumpLayersPanel(
        tester,
        activeLayerId: 'decor',
        map: _mapWithReorderableEnvironment(),
      );

      await _dragLayerGroup(
        tester,
        layerId: 'decor',
        targetKey: 'drop-layer-group-at-end',
      );

      expect(
        container
            .read(editorNotifierProvider)
            .activeMap!
            .layers
            .map((layer) => layer.id),
        ['top', 'bottom', 'decor', 'env_decor'],
      );
      expect(
        container.read(editorNotifierProvider).mapUndoStack,
        hasLength(1),
      );

      container.read(editorNotifierProvider.notifier).undoMap();
      await tester.pumpAndSettle();
      expect(
        container
            .read(editorNotifierProvider)
            .activeMap!
            .layers
            .map((layer) => layer.id),
        ['top', 'decor', 'env_decor', 'bottom'],
      );
    });

    testWidgets('Environment invalide reste un groupe autonome réordonnable',
        (tester) async {
      final container = await _pumpLayersPanel(
        tester,
        activeLayerId: 'env_missing',
        map: _mapWithInvalidEnvironment(),
      );

      await tester.tap(
        find.byKey(const ValueKey('move-layer-up-env_missing')),
      );
      await tester.pumpAndSettle();

      final state = container.read(editorNotifierProvider);
      expect(
        state.activeMap!.layers.map((layer) => layer.id),
        ['env_missing', 'decor'],
      );
      expect(state.mapUndoStack, hasLength(1));
    });

    testWidgets('deux Environment invalides restent réordonnables entre eux',
        (tester) async {
      final container = await _pumpLayersPanel(
        tester,
        activeLayerId: 'env_b',
        map: _mapWithTwoInvalidEnvironments(),
      );

      await tester.tap(find.byKey(const ValueKey('move-layer-up-env_b')));
      await tester.pumpAndSettle();

      final state = container.read(editorNotifierProvider);
      expect(
        state.activeMap!.layers.map((layer) => layer.id),
        ['decor', 'env_b', 'env_a'],
      );
      expect(state.activeLayerId, 'env_b');
      expect(state.mapUndoStack, hasLength(1));
    });

    testWidgets(
        'sémantique annonce sélection position et composition du groupe',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _pumpLayersPanel(
          tester,
          activeLayerId: 'env_decor',
          map: _mapWithReorderableEnvironment(),
        );

        final node = tester.getSemantics(
          find.byKey(const ValueKey('layer-row-semantics-decor')),
        );
        expect(node.flagsCollection.isSelected, Tristate.isTrue);
        expect(node.label, contains('Décor'));
        expect(node.label, contains('position 2 sur 3'));
        expect(node.label, contains('groupe avec 1 environnement attaché'));
        expect(node.label, contains('Environnement technique sélectionné'));
      } finally {
        semantics.dispose();
      }
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

MapData _mapWithTwoInvalidEnvironments() {
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
        id: 'env_a',
        name: 'Environment — A',
        targetLayerId: 'missing_a',
      ),
      _environmentLayer(
        id: 'env_b',
        name: 'Environment — B',
        targetLayerId: 'missing_b',
      ),
    ],
  );
}

MapData _mapWithReorderableEnvironment() {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 3, height: 3),
    layers: [
      const ObjectLayer(id: 'top', name: 'Top'),
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
      const ObjectLayer(id: 'bottom', name: 'Bottom'),
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

PokeMapIconButton _moveUpButton(WidgetTester tester, String layerId) {
  return tester.widget<PokeMapIconButton>(
    find.byKey(ValueKey('move-layer-up-$layerId')),
  );
}

PokeMapIconButton _moveDownButton(WidgetTester tester, String layerId) {
  return tester.widget<PokeMapIconButton>(
    find.byKey(ValueKey('move-layer-down-$layerId')),
  );
}

Future<void> _dragLayerGroup(
  WidgetTester tester, {
  required String layerId,
  required String targetKey,
}) async {
  final source = find.byKey(ValueKey('drag-layer-group-$layerId'));
  final target = find.byKey(ValueKey(targetKey));
  final gesture = await tester.startGesture(tester.getCenter(source));
  await tester.pump();
  await gesture.moveTo(tester.getCenter(target));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

Future<bool> _focusWithTab(WidgetTester tester, Finder target) async {
  FocusManager.instance.primaryFocus?.unfocus();
  for (var attempt = 0; attempt < 32; attempt += 1) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    if (_primaryFocusIsInside(target)) {
      return true;
    }
  }
  return false;
}

bool _primaryFocusIsInside(Finder finder) {
  final target = finder.evaluate().single;
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext == null) {
    return false;
  }

  Element? current = focusContext as Element;
  while (current != null) {
    if (identical(current, target)) {
      return true;
    }
    Element? parent;
    current.visitAncestorElements((ancestor) {
      parent = ancestor;
      return false;
    });
    current = parent;
  }
  return false;
}
