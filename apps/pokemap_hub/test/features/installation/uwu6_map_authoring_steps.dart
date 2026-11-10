import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_catalog_preparation.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_editing_viewport_2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../../../avelune_studio/test/support/map_catalogue_host_fixture.dart';
import '../../../../avelune_studio/test/support/real_test_io.dart';

class Uwu6MapAuthoringSteps {
  Uwu6MapAuthoringSteps(this.fixture);
  final MapCatalogueHostFixture fixture;
  WidgetTester get tester => fixture.tester;

  Future<void> select(String id) async {
    final entry = fixture.host.maps.project!.maps.singleWhere(
      (entry) => entry.id == id,
    );
    await RealTestIo.run(tester, () => fixture.host.maps.activate(entry));
    await fixture.host.pump();
  }

  Future<void> collision(GridPos position) async {
    fixture.view.recenter?.call();
    fixture.view.tool = StudioMapTool.collisionPaint;
    fixture.host.maps.notify();
    await fixture.host.pump();
    expect(
      tester
          .widget<MapEditingViewport2D>(find.byType(MapEditingViewport2D))
          .view
          .tool,
      StudioMapTool.collisionPaint,
    );
    final point = cell(position);
    expect(
      tester
          .getRect(find.byKey(const ValueKey('map-viewport')))
          .contains(point),
      isTrue,
    );
    final surface = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey('map-canvas')),
    );
    expect(
      tester.hitTestOnBinding(point).path.any((hit) => hit.target == surface),
      isTrue,
    );
    final before = fixture.host.maps.active!.current;
    await tester.tapAt(point);
    await fixture.host.pump();
    expect(
      fixture.host.maps.active!.current,
      isNot(before),
      reason: fixture.host.maps.active!.error,
    );
    expect(fixture.host.maps.active!.dirty, isTrue);
  }

  Future<ProjectMapEntry> duplicate(ProjectMapEntry source) =>
      fixture.duplicateMap(source.id, 'Île — copie jouable');

  Future<MapCatalogPreparation> resize(
    String id,
    GridSize size, {
    bool apply = true,
  }) async {
    final preparation = (await fixture.prepareResize(id, size))!;
    if (apply) {
      expect(preparation.canApply, isTrue);
      expect((await fixture.apply(preparation)).integrated, isTrue);
    }
    return preparation;
  }

  Offset cell(GridPos position) =>
      fixture.host.viewport!.cellAt(position.x, position.y);

  Future<void> passage(String destination, GridPos from, GridPos target) async {
    final entry = fixture.host.maps.project!.maps.singleWhere(
      (entry) => entry.id == destination,
    );
    fixture.view
      ..warpDestination = entry
      ..prepareWarpPlacement();
    fixture.view.recenter?.call();
    fixture.host.maps.notify();
    await fixture.host.pump();
    expect(
      tester
          .widget<MapEditingViewport2D>(find.byType(MapEditingViewport2D))
          .view
          .warpDestination
          ?.id,
      destination,
    );
    await tester.tapAt(cell(from));
    await fixture.host.pump();
    final document = fixture.host.maps.active!;
    final warp = document.current.warps.last;
    expect(warp.pos, from);
    expect(warp.targetMapId, destination);
    WarpEditingCommands(
      document,
      fixture.host.maps.project!,
    ).retarget(warp.id, targetPos: target);
    fixture.host.maps.notify();
    await fixture.saveActive();
    expect(document.dirty, isFalse);
    expect(document.current.warps.last.targetPos, target);
  }
}
