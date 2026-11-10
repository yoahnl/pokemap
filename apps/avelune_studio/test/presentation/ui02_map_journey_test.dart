import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/authoring_resource_fixture.dart';
import '../support/neutral_map_host_fixture.dart';

void main() {
  testWidgets(
    'UI02 native overlap, history and responsive viewport retain their editing session',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final source = (await tester.runAsync(AuthoringResourceFixture.create))!;
      addTearDown(() => tester.runAsync(source.dispose));
      final imported = (await tester.runAsync(
        () => source.resources.importImage(
          ResourceImageImport(
            sourcePath: '${source.directory.path}/assets/atelier.png',
            name: 'Atlas de l’atelier',
            tileWidth: 16,
            tileHeight: 16,
          ),
        ),
      ))!;
      final controller = source.workspace;
      controller.acceptResources(imported.before, imported.manifest);
      final visuals = (await tester.runAsync(
        () => StudioMapResources.load(source.session, controller.project!),
      ))!;
      final host = await NeutralMapHostFixture.fromController(
        tester,
        controller,
        visuals: visuals,
      );
      final document = controller.active!;
      final view = host.nativeView;
      final commands = MapEditingCommands(document, controller.project!);
      const position = GridPos(x: 8, y: 6);
      final decor = controller.project!.elements.firstWhere(
        (entry) => entry.id == 'arbre',
      );
      for (var i = 0; i < 3; i++) {
        commands.place(decor, position);
      }
      document.selectedId = null;
      controller.notify();
      await host.pump();
      final stack = commands.stack(position);
      expect(stack.length, greaterThanOrEqualTo(3));
      await host.tapCell(position.x, position.y);
      document.stackPosition = position;
      document.selectedId = stack[1].id;
      controller.notify();
      await host.pump();
      final before = document.current;
      expect(commands.canReorder(forward: true), isTrue);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await host.key(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      expect(commands.stack(position).first.id, document.selectedId);
      expect(commands.canReorder(forward: true), isFalse);
      expect(commands.canReorder(forward: false), isTrue);
      expect(document.current.entities, before.entities);
      expect(document.current.layers, before.layers);
      expect(
        document.current.placedElements.map((entry) => entry.pos),
        before.placedElements.map((entry) => entry.pos),
      );
      for (final instance in document.current.placedElements) {
        final original = before.placedElements.firstWhere(
          (entry) => entry.id == instance.id,
        );
        expect(instance.copyWith(visualOrder: original.visualOrder), original);
      }
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await host.key(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      expect(document.current.placedElements, before.placedElements);
      expect(
        controller.project!.tilesets,
        contains(
          imported.manifest.tilesets.singleWhere(
            (entry) => entry.id == imported.createdTilesetId,
          ),
        ),
      );
      expect(visuals.diagnostics, isEmpty);
      view.tool = StudioMapTool.pan;
      controller.notify();
      await host.pump();
      final fitted = view.transform.value.clone();
      await tester.drag(
        find.byKey(const ValueKey('map-viewport')),
        const Offset(-60, -40),
      );
      await host.pump();
      expect(view.transform.value, isNot(fitted));
      final matrix = view.transform.value.clone();
      for (final size in [
        const Size(1440, 900),
        const Size(1280, 800),
        const Size(1024, 640),
      ]) {
        tester.view.physicalSize = size;
        await host.pump();
        expect(controller.active, same(document));
        expect(host.nativeView, same(view));
        expect(document.dirty, isTrue);
        expect(view.transform.value, matrix);
        expect(tester.takeException(), isNull);
      }
      view.brush = decor;
      view.tool = StudioMapTool.place;
      controller.notify();
      await host.pump();
      await host.tapCell(4, 4);
      expect(document.selected!.pos, const GridPos(x: 4, y: 4));
      final beforeZoom = view.scale;
      view.viewport.zoomBy(1.25);
      await host.pump();
      expect(view.scale, closeTo(beforeZoom * 1.25, .001));
      view.tool = StudioMapTool.pan;
      controller.notify();
      await host.pump();
      final beforePan = view.transform.value.clone();
      await tester.drag(
        find.byKey(const ValueKey('map-viewport')),
        const Offset(-80, -80),
      );
      await host.pump();
      expect(view.transform.value, isNot(beforePan));
      view.tool = StudioMapTool.place;
      controller.notify();
      await host.pump();
      await host.tapCell(6, 5);
      expect(document.selected!.pos, const GridPos(x: 6, y: 5));
      expect(tester.takeException(), isNull);
      await host.dispose();
    },
  );
}
