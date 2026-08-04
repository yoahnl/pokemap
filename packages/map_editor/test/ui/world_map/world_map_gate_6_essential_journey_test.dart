import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/editor/editor_asset_cache_providers.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_activation.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_family.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_toolbelt.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace_session.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/assets/editor_image_cache.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  for (final size in <Size>[
    const Size(800, 600),
    const Size(1280, 800),
  ]) {
    testWidgets(
      'Gate 6 essential journey stays one-click and transactional at '
      '${size.width.toInt()}×${size.height.toInt()}',
      (tester) async {
        final harness = await _pumpJourney(tester, size);
        final editor = harness.notifier;

        const criticalKeys = <String>[
          'world-map-command-save',
          'world-map-command-undo',
          'world-map-command-redo',
          'world-map-command-plus',
          'world-map-tool-selection',
          'world-map-tool-paint',
          'world-map-tool-erase',
          'world-map-tool-place',
          'world-map-tool-layers',
        ];
        final viewport = Offset.zero & size;
        for (final key in criticalKeys) {
          final finder = find.byKey(ValueKey<String>(key));
          expect(finder, findsOneWidget, reason: '$key must require no scroll');
          expect(finder.hitTestable(), findsOneWidget);
          final rect = tester.getRect(finder);
          expect(viewport.contains(rect.topLeft), isTrue, reason: key);
          expect(viewport.contains(rect.bottomRight), isTrue, reason: key);
        }
        expect(
          find.ancestor(
            of: find.byKey(const ValueKey<String>('world-map-tool-slot')),
            matching: find.byType(Scrollable),
          ),
          findsNothing,
          reason: 'the primary toolbelt must never require main scrolling',
        );

        var inspectorScrolls = 0;
        await _activateFamily(tester, harness, 'layers');
        inspectorScrolls += await _activateLayerIfNeeded(tester, 'collision');
        expect(editor.state.activeLayerId, 'collision');

        await _activateFamily(tester, harness, 'paint');
        expect(editor.state.activeTool, EditorToolType.collisionPaint);
        final paintCell = _cellCenter(tester, const GridPos(x: 0, y: 0));
        final canvasGesture = find.byKey(
          const ValueKey<String>('map-canvas-gesture-detector'),
        );
        final canvasRect = tester.getRect(canvasGesture);
        final canvasRenderObject = tester.renderObject(canvasGesture);
        final hitResult = tester.hitTestOnBinding(paintCell);
        final hitPath = hitResult.path.take(12).map((entry) {
          final target = entry.target;
          return target is RenderObject
              ? '${target.runtimeType}(${target.debugCreator})'
              : target.runtimeType.toString();
        }).join(' > ');
        printOnFailure(
          'paint target: surface=$size canvas=$canvasRect global=$paintCell '
          'pan=${editor.state.panOffset} zoom=${editor.state.zoom} '
          'hits=$hitPath',
        );
        expect(canvasRect.contains(paintCell), isTrue);
        expect(
          hitResult.path.any(
            (entry) => identical(entry.target, canvasRenderObject),
          ),
          isTrue,
          reason: 'the exact target cell must hit the map gesture surface',
        );
        await tester.tapAt(paintCell);
        await tester.pump();
        printOnFailure(
          'paint result: collision00=${_collisionAt(editor.state, 0, 0)} '
          'undo=${editor.state.mapUndoStack.length} '
          'stroke=${editor.state.mapStrokeStart != null} '
          'dirty=${editor.state.isDirty} error=${editor.state.errorMessage}',
        );
        expect(_collisionAt(editor.state, 0, 0), isTrue);
        expect(_collisionAt(editor.state, 1, 0), isTrue);
        expect(_collisionAt(editor.state, 0, 1), isTrue);
        expect(editor.state.mapUndoStack, hasLength(1));
        expect(editor.state.isDirty, isTrue);

        await _activateFamily(tester, harness, 'erase');
        expect(editor.state.activeTool, EditorToolType.eraser);
        await tester.tapAt(paintCell);
        await tester.pump();
        expect(_collisionAt(editor.state, 0, 0), isFalse);
        expect(
          _collisionCount(editor.state),
          2,
          reason: 'the erase footprint must remain exactly 1×1',
        );
        expect(_collisionAt(editor.state, 1, 0), isTrue);
        expect(_collisionAt(editor.state, 0, 1), isTrue);
        expect(editor.state.mapUndoStack, hasLength(2));
        expect(
          editor.state.isDirty,
          isFalse,
          reason: 'paint then exact erase restores the saved map',
        );

        await _activateFamily(tester, harness, 'layers');
        inspectorScrolls += await _activateLayerIfNeeded(tester, 'objects');
        expect(editor.state.activeLayerId, 'objects');

        await _activateFamily(tester, harness, 'place');
        expect(editor.state.activeTool, EditorToolType.tilePaint);
        editor.state = editor.state.copyWith(
          activeBrush: const EditorBrush.projectElement(elementId: 'tree'),
        );
        await tester.pump();
        final placementCell = _cellCenter(tester, const GridPos(x: 2, y: 2));
        await tester.tapAt(placementCell);
        await tester.pump();
        expect(editor.state.activeMap!.placedElements, hasLength(2));
        final placed = editor.state.activeMap!.placedElements.singleWhere(
          (entry) => entry.id != 'manual-tree',
        );
        expect(placed.elementId, 'tree');
        expect(placed.layerId, 'objects');
        expect(placed.pos, const GridPos(x: 2, y: 2));
        expect(editor.state.mapUndoStack, hasLength(3));
        expect(editor.state.isDirty, isTrue);

        await _activateFamily(tester, harness, 'selection');
        final manualCell = _cellCenter(tester, const GridPos(x: 4, y: 2));
        await tester.tapAt(manualCell);
        await tester.pump();
        expect(editor.state.selectedPlacedElementInstanceId, 'manual-tree');

        final selectedManualCell =
            _cellCenter(tester, const GridPos(x: 4, y: 2));
        final drag = await tester.startGesture(
          selectedManualCell,
          kind: ui.PointerDeviceKind.mouse,
        );
        await drag.moveBy(const Offset(20, 0));
        await tester.pump();
        await drag.moveBy(const Offset(12, 0));
        await tester.pump();
        final movePreview = find.byKey(
          const ValueKey<String>('map-canvas-object-move-preview'),
        );
        printOnFailure(
          'drag preview=${movePreview.evaluate().length} '
          'semantics=${tester.getSemantics(movePreview).label} '
          'selected=${editor.state.selectedPlacedElementInstanceId} '
          'status=${editor.state.statusMessage} '
          'error=${editor.state.errorMessage}',
        );
        expect(movePreview, findsOneWidget);
        await drag.up();
        await tester.pump();
        printOnFailure(
          'drag result=${_manualTree(editor.state).pos} '
          'undo=${editor.state.mapUndoStack.length} '
          'status=${editor.state.statusMessage} '
          'error=${editor.state.errorMessage}',
        );
        expect(
          _manualTree(editor.state).pos,
          const GridPos(x: 5, y: 2),
        );
        expect(editor.state.mapUndoStack, hasLength(4));
        expect(editor.state.isDirty, isTrue);

        const movedGridCell = GridPos(x: 5, y: 2);
        await _rightClickCell(tester, movedGridCell);
        await tester.tap(find.text('Rotation 90° horaire'));
        await tester.pump();
        expect(_manualTree(editor.state).quarterTurns, 1);
        expect(editor.state.mapUndoStack, hasLength(5));
        expect(editor.state.isDirty, isTrue);

        await tester.tap(
          find.byKey(const ValueKey<String>('world-map-command-undo')),
        );
        await tester.pump();
        expect(_manualTree(editor.state).quarterTurns, 0);
        expect(editor.state.mapUndoStack, hasLength(4));
        expect(editor.state.mapRedoStack, hasLength(1));
        expect(editor.state.isDirty, isTrue);

        await tester.tap(
          find.byKey(const ValueKey<String>('world-map-command-redo')),
        );
        await tester.pump();
        expect(_manualTree(editor.state).quarterTurns, 1);
        expect(editor.state.mapUndoStack, hasLength(5));
        expect(editor.state.mapRedoStack, isEmpty);
        expect(editor.state.isDirty, isTrue);

        await _rightClickCell(tester, movedGridCell);
        expect(find.text('Rotation 90° horaire'), findsOneWidget);
        expect(editor.state.mapUndoStack, hasLength(5));
        expect(editor.state.isDirty, isTrue);
        expect(
          inspectorScrolls,
          lessThanOrEqualTo(1),
          reason:
              'the essential journey allows at most one local inspector scroll',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'light preview label lets a valid canvas cell receive the pointer at '
    '1280×800',
    (tester) async {
      final harness = await _pumpJourney(tester, const Size(1280, 800));
      final editor = harness.notifier;
      await _activateFamily(tester, harness, 'layers');
      await _activateLayerIfNeeded(tester, 'collision');
      await _activateFamily(tester, harness, 'paint');

      final canvasGesture = find.byKey(
        const ValueKey<String>('map-canvas-gesture-detector'),
      );
      final canvasRect = tester.getRect(canvasGesture);
      final labelRect = tester.getRect(find.text('Aperçu lumière'));
      final cellRect = Rect.fromLTWH(
        canvasRect.left + editor.state.panOffset.dx,
        canvasRect.top + editor.state.panOffset.dy,
        32 * editor.state.zoom,
        32 * editor.state.zoom,
      );
      final overlap = labelRect.intersect(cellRect);
      expect(
        overlap.isEmpty,
        isFalse,
        reason: 'the regression requires the light label to cover cell 0,0',
      );
      final target = overlap.center;
      final canvasRenderObject = tester.renderObject(canvasGesture);
      final hitResult = tester.hitTestOnBinding(target);
      printOnFailure(
        'label target: label=$labelRect cell00=$cellRect overlap=$overlap '
        'global=$target hits=${hitResult.path.take(4).map(
              (entry) => entry.target.runtimeType,
            ).join(' > ')}',
      );
      expect(
        hitResult.path.any(
          (entry) => identical(entry.target, canvasRenderObject),
        ),
        isTrue,
        reason: 'the exact point inside the label must hit the map canvas',
      );

      expect(_collisionAt(editor.state, 0, 0), isFalse);
      await tester.tapAt(target);
      await tester.pump();
      expect(_collisionAt(editor.state, 0, 0), isTrue);
      expect(editor.state.mapUndoStack, hasLength(1));
      expect(editor.state.errorMessage, isNull);
    },
  );
}

Future<void> _rightClickCell(WidgetTester tester, GridPos cell) async {
  final gesture = await tester.startGesture(
    _cellCenter(tester, cell),
    kind: ui.PointerDeviceKind.mouse,
    buttons: kSecondaryButton,
  );
  await gesture.up();
  await tester.pump();
}

Future<int> _activateLayerIfNeeded(
  WidgetTester tester,
  String layerId,
) async {
  final scrollable = find.descendant(
    of: find.byKey(const ValueKey<String>('world-map-layer-list')),
    // The layer filter contains an EditableText with its own horizontal
    // Scrollable. Gate 6 must exercise the inspector's vertical viewport,
    // never depend on the number of nested implementation scrollables.
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    ),
  );
  final position = tester.state<ScrollableState>(scrollable).position;
  final beforeOffset = position.pixels;
  Finder active() => find.byKey(
        ValueKey<String>('world-map-layer-active-$layerId'),
      );
  Finder activation() => find.byKey(
        ValueKey<String>('world-map-layer-activate-$layerId'),
      );
  var scrollGestures = 0;
  if (active().evaluate().isEmpty && activation().evaluate().isEmpty) {
    await tester.drag(scrollable, const Offset(0, -240));
    await tester.pumpAndSettle();
    scrollGestures += 1;
  }
  if (active().evaluate().isNotEmpty) {
    return scrollGestures;
  }
  expect(activation(), findsOneWidget);
  if (activation().hitTestable().evaluate().isEmpty) {
    expect(scrollGestures, 0, reason: 'one local scroll gesture is the budget');
    await tester.ensureVisible(activation());
    await tester.pumpAndSettle();
    scrollGestures += 1;
  }
  if (scrollGestures > 0) {
    expect(position.pixels, isNot(beforeOffset));
  }
  await tester.tap(activation());
  await tester.pump();
  return scrollGestures;
}

Future<void> _activateFamily(
  WidgetTester tester,
  _JourneyHarness harness,
  String family,
) async {
  await tester.tap(
    find.byKey(ValueKey<String>('world-map-tool-$family')),
  );
  await tester.pumpAndSettle();
  expect(
    harness.container.read(worldMapWorkspaceSessionProvider).activeFamily.name,
    family,
    reason: '$family must activate in one click',
  );
}

Offset _cellCenter(WidgetTester tester, GridPos cell) {
  final origin = tester.getTopLeft(
    find.byKey(const ValueKey<String>('map-canvas-gesture-detector')),
  );
  return origin + Offset(cell.x * 32 + 16, cell.y * 32 + 16);
}

bool _collisionAt(EditorState state, int x, int y) {
  final layer = state.activeMap!.layers
      .whereType<CollisionLayer>()
      .singleWhere((candidate) => candidate.id == 'collision');
  return layer.collisions[y * state.activeMap!.size.width + x];
}

int _collisionCount(EditorState state) {
  final layer = state.activeMap!.layers
      .whereType<CollisionLayer>()
      .singleWhere((candidate) => candidate.id == 'collision');
  return layer.collisions.where((value) => value).length;
}

MapPlacedElement _manualTree(EditorState state) =>
    state.activeMap!.placedElements
        .singleWhere((entry) => entry.id == 'manual-tree');

Future<_JourneyHarness> _pumpJourney(
  WidgetTester tester,
  Size size,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 64, 32),
    Paint()..color = const Color(0xFF5D8D36),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(64, 32);
  picture.dispose();
  final harness = _JourneyHarness(image);
  addTearDown(harness.dispose);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  final session = harness.container.read(
    worldMapWorkspaceSessionProvider.notifier,
  );
  harness.notifier.state = harness.notifier.state.copyWith(
    activeLayerId: 'collision',
  );
  expect(
    session
        .activateTool(
          harness.notifier,
          const ActivateWorldMapPaint(WorldMapPaintSubtool.collision),
        )
        .accepted,
    isTrue,
  );
  harness.notifier.state = harness.notifier.state.copyWith(
    activeLayerId: 'objects',
  );
  expect(
    session
        .activateTool(
          harness.notifier,
          const ActivateWorldMapPlacement(WorldMapPlacementSubtool.object),
        )
        .accepted,
    isTrue,
  );
  expect(
    session
        .activateTool(harness.notifier, const ActivateWorldMapSelection())
        .accepted,
    isTrue,
  );
  harness.notifier.state = harness.notifier.state.copyWith(
    activeLayerId: 'objects',
    activeBrush: const EditorBrush.projectElement(elementId: 'tree'),
    selectedPlacedElementInstanceId: 'manual-tree',
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: harness.container,
      child: MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Material(
          child: WorldMapWorkspace(
            onTargetEditorRequested: (_) async {},
            toolSlot: WorldMapToolbelt(
              onSave: () {},
              onUndo: harness.notifier.undoMap,
              onRedo: harness.notifier.redoMap,
              onNewProject: () {},
              onOpenProject: () {},
              onProjectSettings: () {},
              onExportGame: () {},
              onNewMap: () {},
              onResizeMap: () {},
            ),
            stageHeaderSlot: const SizedBox(height: 36),
            explorerBuilder: (context, onCollapse) => Align(
              alignment: Alignment.topLeft,
              child: PokeMapButton(
                onPressed: onCollapse,
                size: PokeMapButtonSize.compact,
                child: const Text('Réduire'),
              ),
            ),
            explorerRailBuilder: (context, onReopen) => PokeMapIconButton(
              onPressed: onReopen,
              size: 36,
              tooltip: 'Rouvrir',
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return harness;
}

final class _JourneyHarness {
  _JourneyHarness(ui.Image image)
      : container = ProviderContainer(
          overrides: <Override>[
            editorImageCacheProvider.overrideWith(
              (ref, projectRoot) => _ImmediateEditorImageCache(
                projectRoot,
                image,
              ),
            ),
          ],
        ),
        _image = image {
    keepAlive = container.listen<EditorState>(
      editorNotifierProvider,
      (_, __) {},
      fireImmediately: true,
    );
    notifier.state = _initialState;
  }

  final ProviderContainer container;
  final ui.Image _image;
  late final ProviderSubscription<EditorState> keepAlive;

  EditorNotifier get notifier =>
      container.read(editorNotifierProvider.notifier);

  void dispose() {
    keepAlive.close();
    container.dispose();
    _image.dispose();
  }
}

final class _ImmediateEditorImageCache extends EditorImageCache {
  _ImmediateEditorImageCache(String sessionKey, this._image)
      : super(sessionKey: sessionKey);

  final ui.Image _image;

  @override
  Future<EditorImageLoadResult> load(
    String? path, {
    String variantKey = 'original',
    int? targetWidth,
    int? targetHeight,
    bool allowUpscaling = true,
    EditorImageBytesTransform? transformBytes,
  }) {
    return Future<EditorImageLoadResult>.value(
      EditorImageLoadResult.success(_image.clone()),
    );
  }
}

final _map = MapData(
  id: 'gate-6-map',
  name: 'Gate 6 realistic map',
  version: ProjectVersion.v6,
  visualStack: MapVisualStackConfig.canonicalV1,
  size: const GridSize(width: 8, height: 8),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Sol',
      palette: <TileLayerPaletteEntry>[
        const TileLayerPaletteEntry(tilesetId: 'village', localTileId: 0),
      ],
      cells: List<int>.filled(64, 0, growable: false),
    ),
    TileLayer(
      id: 'objects',
      name: 'Éléments',
      palette: <TileLayerPaletteEntry>[
        const TileLayerPaletteEntry(tilesetId: 'village', localTileId: 0),
      ],
      cells: List<int>.filled(64, 0, growable: false),
    ),
    CollisionLayer(
      id: 'collision',
      name: 'Collisions',
      collisions: <bool>[
        for (var index = 0; index < 64; index += 1) index == 1 || index == 8,
      ],
    ),
  ],
  placedElements: const <MapPlacedElement>[
    MapPlacedElement(
      id: 'manual-tree',
      layerId: 'objects',
      elementId: 'tree',
      pos: GridPos(x: 4, y: 2),
    ),
  ],
);

final _initialState = EditorState(
  projectRootPath: '/tmp/pokemap-gate-6-certification',
  activeMapPath: '/tmp/pokemap-gate-6-certification/maps/gate-6-map.json',
  project: const ProjectManifest(
    name: 'Gate 6 certification',
    version: ProjectVersion.v6,
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'gate-6-map',
        name: 'Gate 6 realistic map',
        relativePath: 'maps/gate-6-map.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'village',
        name: 'Village',
        relativePath: 'assets/village.png',
        source: ProjectTilesetSource.regularAtlas(
          assetId: 'village',
          pixelWidth: 64,
          pixelHeight: 32,
          tileWidth: 32,
          tileHeight: 32,
        ),
      ),
    ],
    elements: <ProjectElementEntry>[
      ProjectElementEntry(
        id: 'tree',
        name: 'Arbre défini',
        tilesetId: 'village',
        categoryId: 'vegetation',
        frames: <TilesetVisualFrame>[
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 1),
          ),
        ],
      ),
    ],
  ),
  workspaceMode: EditorWorkspaceMode.map,
  activeMap: _map,
  activeLayerId: 'objects',
  activeBrush: const EditorBrush.projectElement(elementId: 'tree'),
  selectedPlacedElementInstanceId: 'manual-tree',
  savedMapSnapshot: _map,
);
