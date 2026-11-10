import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workflow.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../support/neutral_map_host_fixture.dart';

void main() {
  late WorkspaceMemoryPort port;
  late MapWorkspaceController controller;
  late WorkspaceTestVisuals visuals;
  late NeutralMapHostFixture host;
  late WorkspaceWorkflow actions;
  var runtimeStarts = 0;
  var choice = WorkspaceCloseChoice.cancel;
  Completer<void>? runtimeEntered, runtimeReturn;

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    port = WorkspaceMemoryPort();
    controller = MapWorkspaceController(workspaceSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    visuals = WorkspaceTestVisuals();
    runtimeStarts = 0;
    choice = WorkspaceCloseChoice.cancel;
    runtimeEntered = null;
    runtimeReturn = null;
    actions = WorkspaceWorkflow(
      controller: controller,
      isActive: () => !controller.isDisposed,
      changed: controller.notify,
      resources: () => null,
      narrative: () => null,
      confirmClose: () async => choice,
      flushFocus: () {},
      launchMap: (_, _) async {
        runtimeStarts++;
        runtimeEntered?.complete();
        await runtimeReturn?.future;
      },
    );
    host = await NeutralMapHostFixture.fromController(
      tester, controller, visuals: visuals, isBusy: () => actions.busy,
    );
  }

  Future<void> place(int x, int y) async {
    host.nativeView.tool = StudioMapTool.place;
    host.nativeView.brush = controller.project!.elements.first;
    visuals.setBrush(host.nativeView.brush, null);
    controller.notify();
    await host.pump();
    await host.tapCell(x, y);
  }

  testWidgets('preparing runtime refuses a changed active document', (tester) async {
    await open(tester);
    await place(2, 2);
    port.saveGate = Completer<void>();
    final running = actions.test();
    await tester.pump();
    expect(actions.testing, isTrue);
    await controller.activate(workspaceEntries.last);
    port.saveGate!.complete();
    await running;
    expect(runtimeStarts, 0);
    expect(controller.active!.base.mapId, 'b');
    expect(port.saved['a']!.placedElements, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('an active playtest blocks viewport placement until it returns', (tester) async {
    await open(tester);
    host.nativeView.tool = StudioMapTool.place;
    host.nativeView.brush = controller.project!.elements.first;
    runtimeEntered = Completer<void>();
    runtimeReturn = Completer<void>();
    late Future<void> running;
    await tester.runAsync(() async {
      running = actions.test();
    });
    await host.pump();
    expect(runtimeEntered!.isCompleted, isTrue);
    final before = controller.active!.current;
    try {
      expect(actions.testing, isTrue);
      await host.tapCell(2, 2);
      expect(controller.active!.current, same(before));
    } finally {
      runtimeReturn!.complete();
      await tester.pump();
      await tester.runAsync(() => running);
    }
    await host.pump();
    await host.tapCell(2, 2);
    expect(controller.active!.current.placedElements, hasLength(1));
  });

  testWidgets('place move stack undo redo save and runtime return preserve document', (tester) async {
    await open(tester);
    await place(3, 3);
    await host.tapCell(3, 3);
    final document = controller.active!;
    expect(document.current.placedElements, hasLength(2));
    expect(document.undoCount, 2);
    final first = document.current.placedElements.first.id;
    final second = document.current.placedElements.last.id;
    await host.key(LogicalKeyboardKey.escape);
    await host.tapCell(3, 3);
    expect(document.selectedId, second);
    host.nativeView.select(document, MapSelectionFamily.decor, first);
    document.stackPosition = const GridPos(x: 3, y: 3);
    MapEditingCommands(document, controller.project!).reorder(forward: true);
    expect(document.current.placedElements.first.visualOrder,
      greaterThan(document.current.placedElements.last.visualOrder));
    controller.notify();
    await host.pump();
    await host.drag(3, 3, 5, 4);
    expect(document.current.placedElements.first.pos.x, 5);
    expect(document.undoCount, 4);
    document.restore(redo: false);
    expect(document.current.placedElements.first.pos.x, 3);
    document.restore(redo: true);
    expect(document.current.placedElements.first.pos.x, 5);
    expect(await controller.save(document), isTrue);
    expect(document.dirty, isFalse);
    expect(port.saved['a'], document.current);
    await actions.test();
    expect(runtimeStarts, 1);
    expect(controller.active, same(document));
    expect(port.catalogs, 1);
    expect(port.reads, 1);
    await host.dispose();
    expect(visuals.disposed, isTrue);
  });

  testWidgets('dirty close supports cancel discard save and a conflict prevents runtime', (tester) async {
    await open(tester);
    await place(2, 2);
    expect(await actions.allowClose(), isFalse);
    expect(controller.dirty, isTrue);
    port.failSave = true;
    await actions.test();
    expect(runtimeStarts, 0);
    expect(controller.active!.error, isNotNull);
    expect(controller.dirty, isTrue);
    choice = WorkspaceCloseChoice.discard;
    expect(await actions.allowClose(), isTrue);
    expect(port.writes, 0);
    expect(controller.active!.current.placedElements, hasLength(1));
    port.failSave = false;
    choice = WorkspaceCloseChoice.save;
    expect(await actions.allowClose(), isTrue);
    expect(controller.dirty, isFalse);
    expect(port.writes, 1);
  });

  testWidgets('a tile paint gesture is one history step', (tester) async {
    await open(tester);
    await place(2, 2);
    final document = controller.active!;
    host.nativeView.tool = StudioMapTool.paint;
    host.nativeView.tile = const TileLayerPaletteEntry(tilesetId: 'atlas', localTileId: 0);
    host.nativeView.brush = null;
    controller.notify();
    await host.pump();
    await host.drag(6, 6, 9, 6);
    expect(document.undoCount, 2);
    document.restore(redo: false);
    expect(document.undoCount, 1);
    expect(document.current.placedElements, hasLength(1));
  });

  testWidgets('failed navigation preserves its target and warm navigation preserves zoom', (tester) async {
    await open(tester);
    final view = host.nativeView;
    view.transform.value = Matrix4.identity()..scaleByDouble(1.5, 1.5, 1, 1);
    final zoom = view.transform.value.clone();
    expect(controller.dirty, isFalse);
    port.failedMap = 'b';
    await controller.activate(workspaceEntries.last);
    await host.pump();
    expect(controller.active!.base.mapId, 'a');
    expect(controller.error, contains('Carte indisponible'));
    expect(host.nativeView, same(view));
    port.failedMap = null;
    await controller.activate(workspaceEntries.last);
    await host.pump();
    await controller.activate(workspaceEntries.first);
    await host.pump();
    expect(host.nativeView, same(view));
    expect(view.transform.value, zoom);
    expect(port.catalogs, 1);
    expect(port.reads, 3);
  });

  testWidgets('eraser reaches ground beneath empty decor', (tester) async {
    await open(tester);
    final document = controller.active!;
    final ground = (document.current.layers.single as TileLayer).copyWith(
      cells: List.filled(320, 1),
    );
    document.commit(document.current.copyWith(layers: [
      MapLayer.tile(id: 'decor', name: 'Décors', cells: List.filled(320, 0)),
      ground,
    ]));
    host.nativeView.tool = StudioMapTool.erase;
    controller.notify();
    await host.pump();
    final history = document.undoCount;
    await host.tapCell(4, 4);
    final erased = document.current.layers.whereType<TileLayer>().firstWhere((layer) => layer.id == 'ground');
    expect(resolveTileLayerCell(erased, 4 * 20 + 4), isNull);
    expect(document.undoCount, history + 1);
    document.restore(redo: false);
    expect(document.current.layers.last, ground);
  });
}
