import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editor_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_editor_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_elements_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets('dragging a lower handle upward sends front first decor IDs', (
    tester,
  ) async {
    final pending = Completer<bool>();
    final h = await _mount(tester, reorderCompletion: pending.future);
    await tester.tap(find.text('Superposition'));
    await tester.pumpAndSettle();
    final tree = find.byKey(const ValueKey('map-element-decor-tree'));
    final mist = find.byKey(const ValueKey('map-element-decor-mist'));
    final handle = find.descendant(
      of: tree,
      matching: find.byType(ReorderableDragStartListener),
    );
    expect(tester.getTopLeft(mist).dy, lessThan(tester.getTopLeft(tree).dy));
    await _dragAcross(tester, handle, mist, waitForDropAnimation: false);
    expect(h.reorders, hasLength(1));
    expect(h.reorders.single.kind, 'decor');
    expect(h.reorders.single.ids, ['tree', 'mist']);
    expect(h.reorders.single.layer, 'ground');
    expect(h.document.dirty, isFalse);
    expect(find.byType(SliverReorderableList), findsNothing);
    pending.complete(true);
    await tester.pumpAndSettle();
    expect(h.reorders, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'dropping a top handle downward applies the adjusted index once immediately',
    (tester) async {
      final h = await _mount(tester);
      await tester.tap(find.text('Superposition'));
      await tester.pumpAndSettle();
      final tree = find.byKey(const ValueKey('map-element-decor-tree'));
      final mist = find.byKey(const ValueKey('map-element-decor-mist'));
      final handle = find.descendant(
        of: mist,
        matching: find.byType(ReorderableDragStartListener),
      );
      await _dragAcross(
        tester,
        handle,
        tree,
        before: false,
        waitForDropAnimation: false,
      );
      expect(h.reorders, hasLength(1));
      expect(h.reorders.single.ids, ['tree', 'mist']);
      await tester.pumpAndSettle();
      expect(h.reorders, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'locked handles cannot drag and filtered rows do not expose reorder',
    (tester) async {
      final h = await _mount(
        tester,
        locked: MapEditorState(lockedElements: {'decor:tree'}),
      );
      await tester.tap(find.text('Superposition'));
      await tester.pumpAndSettle();
      final tree = find.byKey(const ValueKey('map-element-decor-tree'));
      final mist = find.byKey(const ValueKey('map-element-decor-mist'));
      final handle = find.descendant(
        of: tree,
        matching: find.byType(ReorderableDragStartListener),
      );
      expect(
        tester.widget<ReorderableDragStartListener>(handle).enabled,
        isFalse,
      );
      await _dragAcross(tester, handle, mist);
      expect(h.reorders, isEmpty);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('map-elements-search')),
          matching: find.byType(TextField),
        ),
        'brume',
      );
      await tester.pumpAndSettle();
      expect(find.byType(ReorderableDragStartListener), findsNothing);
      expect(tree, findsNothing);
      expect(mist, findsOneWidget);
      await tester.drag(mist, const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(h.reorders, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'inherited layer locks explain disabled controls and unlock all persists',
    (tester) async {
      final h = await _mount(
        tester,
        locked: MapEditorState(lockedElements: {'layer:ground'}),
      );
      final childTool = tester.widget<StudioTool>(
        find.byKey(const ValueKey('map-element-lock-decor-mist')),
      );
      expect(childTool.onPressed, isNull);
      expect(childTool.label, contains('Verrouillé par son calque'));
      final groupTool = tester
          .widgetList<StudioTool>(find.byType(StudioTool))
          .firstWhere(
            (tool) => tool.label.startsWith('Ce groupe est verrouillé'),
          );
      expect(groupTool.onPressed, isNull);
      expect(groupTool.label, contains('Tout déverrouiller'));
      expect(find.byTooltip(childTool.label), findsWidgets);
      expect(find.byTooltip(groupTool.label), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('map-element-decor-mist')));
      await tester.pump();
      expect(h.document.selectedId, isNull);
      final before = h.document.current;
      await tester.tap(find.text('Tout déverrouiller'));
      await tester.pumpAndSettle();
      expect(h.document.isElementLocked('decor', 'mist'), isFalse);
      expect(h.port.state.lockedElements, isEmpty);
      expect(h.port.state.lockedFamilies, isEmpty);
      expect(h.port.writes, 1);
      expect(h.document.current, same(before));
      final reopened = await MapEditorController.open(
        workspaceSession,
        'a',
        h.port,
      );
      addTearDown(reopened.dispose);
      expect(reopened.current.lockedElements, isEmpty);
      await tester.tap(find.byKey(const ValueKey('map-element-decor-mist')));
      await tester.pump();
      expect(h.document.selectedId, 'mist');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('panel remains usable at 360 by 600 with enlarged text', (
    tester,
  ) async {
    await _mount(
      tester,
      size: const Size(360, 600),
      scale: 1.5,
      locked: MapEditorState(lockedElements: {'layer:ground'}),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Superposition'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(CustomScrollView)).height,
      greaterThan(32),
    );
    await tester.tap(find.text('Tout déverrouiller'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _dragAcross(
  WidgetTester tester,
  Finder handle,
  Finder target, {
  bool waitForDropAnimation = true,
  bool before = true,
}) async {
  final start = tester.getCenter(handle);
  final destination = Offset(
    start.dx,
    before
        ? tester.getTopLeft(target).dy - 4
        : tester.getBottomRight(target).dy + 4,
  );
  final gesture = await tester.startGesture(start);
  await tester.pump(const Duration(milliseconds: 100));
  for (var step = 1; step <= 12; step++) {
    await gesture.moveTo(Offset.lerp(start, destination, step / 12)!);
    await tester.pump(const Duration(milliseconds: 20));
  }
  await tester.pump(const Duration(milliseconds: 300));
  await gesture.up();
  await tester.pump(const Duration(milliseconds: 16));
  if (waitForDropAnimation) await tester.pumpAndSettle();
}

typedef _Reorder = ({String kind, List<String> ids, String? layer});

final class _Harness {
  _Harness(this.document, this.port);
  final EditableMapDocument document;
  final _Port port;
  final reorders = <_Reorder>[];
}

Future<_Harness> _mount(
  WidgetTester tester, {
  Size size = const Size(400, 800),
  double scale = 1,
  MapEditorState? locked,
  Future<bool>? reorderCompletion,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final port = _Port(locked ?? MapEditorState());
  final document = EditableMapDocument(
    MapWorkspaceDocument(
      map: workspaceMap('a').copyWith(
        placedElements: const [
          MapPlacedElement(
            id: 'tree',
            layerId: 'ground',
            elementId: 'tree',
            pos: GridPos(x: 4, y: 4),
          ),
          MapPlacedElement(
            id: 'mist',
            layerId: 'ground',
            elementId: 'mist',
            pos: GridPos(x: 4, y: 4),
            visualOrder: 10,
          ),
        ],
      ),
      revision: 'base',
      mapId: 'a',
    ),
  );
  document.editor = await MapEditorController.open(workspaceSession, 'a', port);
  final h = _Harness(document, port);
  final view = MapWorkspaceViewState();
  addTearDown(view.dispose);
  addTearDown(document.editor!.dispose);
  final project = workspaceProject.copyWith(
    elements: [
      workspaceElement,
      workspaceElement.copyWith(
        id: 'mist',
        name: 'Brume arrière',
        categoryId: 'effects',
      ),
    ],
    elementCategories: const [
      ProjectElementCategory(id: 'effects', name: 'Effets'),
    ],
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: MapElementsPanel(
          document: document,
          project: project,
          view: view,
          onChanged: () {},
          onReorder: (kind, ids, layer) async {
            h.reorders.add((kind: kind, ids: ids, layer: layer));
            if (reorderCompletion != null) return await reorderCompletion;
            return true;
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return h;
}

final class _Port implements MapEditorPort {
  _Port(this.state);
  MapEditorState state;
  var writes = 0;
  @override
  Future<MapEditorWorkspaceState> loadEditorState(
    ProjectSession session,
    String mapId,
  ) async => MapEditorWorkspaceState(state: state, revision: 'e$writes');
  @override
  Future<MapEditorWorkspaceState> saveEditorState(
    ProjectSession session,
    String mapId,
    MapEditorState next,
    String expectedRevision,
  ) async {
    writes++;
    state = next;
    return MapEditorWorkspaceState(state: state, revision: 'e$writes');
  }
}
