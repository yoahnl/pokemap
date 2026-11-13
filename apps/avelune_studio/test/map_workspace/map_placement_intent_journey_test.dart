import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/environment_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../support/neutral_map_host_fixture.dart';
import '../support/spatial_environment_fixture.dart';

class _PlacementFixture {
  _PlacementFixture.of(this.project)
    : document = EditableMapDocument(
        MapWorkspaceDocument(
          map: workspaceMap('a'),
          mapId: 'a',
          revision: 'base',
        ),
      );
  final ProjectManifest project;
  final EditableMapDocument document;
  final view = MapEditingViewportSession();
  void dispose() => view.dispose();
}

void main() {
  test('two placements keep two identities and the first survives', () {
    final h = _PlacementFixture.of(workspaceProject);
    addTearDown(h.dispose);
    final commands = MapEditingCommands(h.document, h.project);
    final first = commands.place(workspaceElement, const GridPos(x: 1, y: 1));
    final second = commands.place(workspaceElement, const GridPos(x: 3, y: 1));
    expect(first, isNotNull);
    expect(second, isNotNull);
    expect(first, isNot(second));
    h.view.tool = StudioMapTool.select;
    final ids = h.document.current.placedElements.map((e) => e.id).toSet();
    expect(ids, containsAll([first, second]));
    expect(
      h.document.current.placedElements
          .where((element) => element.id == first)
          .single
          .elementId,
      workspaceElement.id,
    );
  });

  testWidgets('native preview, cancel, resume, save and reopen keep decors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final port = WorkspaceMemoryPort();
    Future<NeutralMapHostFixture> open() async {
      final controller = MapWorkspaceController(workspaceSession, port);
      await controller.initialize();
      addTearDown(controller.dispose);
      return NeutralMapHostFixture.fromController(tester, controller);
    }

    var host = await open();
    host.nativeView
      ..brush = workspaceElement
      ..tool = StudioMapTool.place;
    host.maps.notify();
    await host.pump();
    await host.tapCell(2, 2);
    final document = host.document;
    final first = document.current.placedElements.single;
    expect(first.elementId, 'tree');
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: host.cellAt(6, 3));
    await mouse.moveTo(host.cellAt(6, 4));
    await host.pump();
    final preview = find.byKey(const ValueKey('decor-placement-preview'));
    expect(preview, findsOneWidget);
    await host.key(LogicalKeyboardKey.escape);
    expect(preview, findsNothing);
    expect(document.current.placedElements, [first]);
    host.nativeView.tool = StudioMapTool.place;
    host.maps.notify();
    await host.pump();
    await host.tapCell(6, 4);
    expect(
      document.current.placedElements.map((item) => item.id).toSet(),
      hasLength(2),
    );
    expect(await host.maps.save(document), isTrue, reason: document.error);
    expect(document.dirty, isFalse);
    await mouse.removePointer();
    await host.dispose();
    host = await open();
    expect(
      host.document.current.placedElements.map(
        (item) => (item.elementId, item.pos),
      ),
      [
        ('tree', const GridPos(x: 2, y: 2)),
        ('tree', const GridPos(x: 6, y: 4)),
      ],
    );
    expect(port.saved['a']!.placedElements.first.id, first.id);
  });

  test('a zone edit stays within the zone and leaves other decors as is', () {
    final project = spatialEnvironmentProject();
    final base = spatialEnvironmentMap();
    final far = SpatialModelInstance(
      id: 'far_statue',
      modelId: 'oak',
      position: Model3dVector3(x: 11.5, y: 0, z: .5),
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(
        map: base.copyWith(
          spatialScene: base.spatialScene!.copyWith(instances: [far]),
        ),
        revision: 'r',
        mapId: 'a',
      ),
    );
    final commands = EnvironmentEditingCommands(document, project);
    final session = commands.create(project.environmentPresets.single);
    commands.paintRectangle(
      session,
      const GridPos(x: 1, y: 1),
      const GridPos(x: 2, y: 2),
    );
    commands.preview(session);
    final generation = session.generation!;
    expect(generation.requestedRegion.width, 2);
    expect(generation.requestedRegion.height, 2);
    expect(
      generation.resolutionRegion.width,
      lessThanOrEqualTo(2 + generation.haloCells * 2),
    );
    commands.apply(session);
    final instances = document.current.spatialScene!.instances;
    expect(
      instances.where((item) => item.id == 'far_statue').single,
      same(far),
    );
    expect(instances.length, greaterThan(1));
    expect(project.models3d.single.id, 'oak');
  });
}
