import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_shortcuts.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

const _root = 'test/fixtures/spatial_first_map';

class _Host {
  _Host(this.controller, this.view);
  final MapWorkspaceController controller;
  final MapEditingViewportSession view;
  EditableMapDocument get document => controller.active!;

  List<SpatialModelInstance> get oaks => document
      .current
      .spatialScene!
      .instances
      .where((item) => item.modelId == 'house')
      .toList();

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              const TextField(key: ValueKey('field')),
              Expanded(
                child: CallbackShortcuts(
                  bindings: mapEditingShortcuts(controller, view, (action) {
                    action();
                    setState(() {});
                  }),
                  child: const Focus(
                    key: ValueKey('canvas'),
                    autofocus: true,
                    child: SizedBox.expand(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<_Host> _open(WidgetTester tester) async {
  final project = ProjectManifest.fromJson(
    jsonDecode(File('$_root/project.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  final source = MapData.fromJson(
    jsonDecode(File('$_root/maps/first-map.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  final map = source.copyWith(
    spatialScene: source.spatialScene!.copyWith(
      instances: [
        SpatialModelInstance(
          id: 'oak_a',
          modelId: 'house',
          position: Model3dVector3(x: 3.5, y: 0, z: 3.5),
        ),
        SpatialModelInstance(
          id: 'oak_b',
          modelId: 'house',
          position: Model3dVector3(x: 5.5, y: 0, z: 4.5),
        ),
      ],
    ),
    entities: const [],
  );
  final document = EditableMapDocument(
    MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r'),
  );
  final controller =
      MapWorkspaceController(workspaceSession, WorkspaceMemoryPort())
        ..project = project
        ..active = document;
  final view = MapEditingViewportSession()
    ..select(document, MapSelectionFamily.decor, 'oak_a')
    ..toggleInSelection(document, MapSelectionFamily.decor, 'oak_b');
  addTearDown(view.dispose);
  addTearDown(controller.dispose);
  final host = _Host(controller, view);
  await host.pump(tester);
  await tester.pump();
  return host;
}

Future<void> _command(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
  await tester.pump();
}

void main() {
  testWidgets('copy then paste at the pointer selects the pasted group', (
    tester,
  ) async {
    final host = await _open(tester);
    await _command(tester, LogicalKeyboardKey.keyC);
    expect(host.controller.clipboard?.items, hasLength(2));
    host.view.pointer = (
      mapId: host.document.current.id,
      cell: const GridPos(x: 8, y: 8),
    );
    await _command(tester, LogicalKeyboardKey.keyV);
    expect(host.oaks, hasLength(4));
    expect(host.document.undoCount, 1);
    final selection = host.view.selectionIn(host.document.current.id);
    expect(selection, hasLength(2));
    expect(selection.map((target) => target.id), isNot(contains('oak_a')));
    final pasted = host.oaks.where(
      (item) => selection.any((target) => target.id == item.id),
    );
    expect(pasted.map((item) => (item.position.x, item.position.z)).toSet(), {
      (8.5, 8.5),
      (10.5, 9.5),
    });
  });

  testWidgets('cut then paste puts the group back and survives a map change', (
    tester,
  ) async {
    final host = await _open(tester);
    await _command(tester, LogicalKeyboardKey.keyX);
    expect(host.oaks, isEmpty);
    expect(host.view.selectionIn(host.document.current.id), isEmpty);
    final other = EditableMapDocument(
      MapWorkspaceDocument(
        map: host.document.current.copyWith(id: 'second-map'),
        mapId: 'second-map',
        revision: 'r',
      ),
    );
    host.controller.active = other;
    await host.pump(tester);
    await _command(tester, LogicalKeyboardKey.keyV);
    expect(
      host.oaks.map((item) => (item.position.x, item.position.z)).toSet(),
      {(3.5, 3.5), (5.5, 4.5)},
    );
    expect(host.view.selectionIn('second-map'), hasLength(2));
  });

  testWidgets('duplicate, delete and arrows act on the whole selection', (
    tester,
  ) async {
    final host = await _open(tester);
    await _command(tester, LogicalKeyboardKey.keyD);
    expect(host.oaks, hasLength(4));
    expect(host.document.undoCount, 1);
    final copies = host.view.selectionIn(host.document.current.id);
    expect(
      copies.map((target) => target.id).toSet().intersection({
        'oak_a',
        'oak_b',
      }),
      isEmpty,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(host.document.undoCount, 2);
    final moved = host.oaks.where(
      (item) => copies.any((target) => target.id == item.id),
    );
    expect(moved.map((item) => (item.position.x, item.position.z)).toSet(), {
      (5.5, 4.5),
      (7.5, 5.5),
    });
    await _command(tester, LogicalKeyboardKey.arrowUp);
    expect(host.document.undoCount, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(host.oaks.map((item) => item.id).toSet(), {'oak_a', 'oak_b'});
    expect(host.document.undoCount, 3);
    expect(host.view.selectionIn(host.document.current.id), isEmpty);
  });

  testWidgets('escape clears the selection only once no tool is engaged', (
    tester,
  ) async {
    final host = await _open(tester);
    host.view.tool = StudioMapTool.place;
    await host.pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(host.view.tool, StudioMapTool.select);
    expect(host.view.selectionIn(host.document.current.id), hasLength(2));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(host.view.selectionIn(host.document.current.id), isEmpty);
  });

  testWidgets('shortcuts stay inert while typing in a field', (tester) async {
    final host = await _open(tester);
    await tester.tap(find.byKey(const ValueKey('field')));
    await tester.pump();
    await _command(tester, LogicalKeyboardKey.keyC);
    await _command(tester, LogicalKeyboardKey.keyD);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(host.controller.clipboard, isNull);
    expect(host.oaks, hasLength(2));
    expect(host.document.undoCount, 0);
  });
}
