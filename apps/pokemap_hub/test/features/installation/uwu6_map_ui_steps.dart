import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../../../avelune_studio/test/support/map_catalogue_host_fixture.dart';
import '../../../../avelune_studio/test/support/m2_ui_fixture.dart' show pumpIo;

class Uwu6MapUiSteps {
  Uwu6MapUiSteps(this.fixture);
  final MapCatalogueHostFixture fixture;
  WidgetTester get tester => fixture.tester;

  Future<void> select(String id) => fixture.tapKey('map-library-$id');

  Future<void> navigator({required bool visible}) async {
    final toggle = find.byTooltip(
      visible ? 'Afficher les cartes' : 'Masquer les cartes',
    );
    if (toggle.evaluate().isEmpty) return;
    await tester.tap(toggle);
    await pumpIo(tester, frames: 5);
  }

  Future<void> collision(GridPos position) async {
    await navigator(visible: false);
    await tester.tap(find.byTooltip('Recentrer'));
    await pumpIo(tester, frames: 4);
    await tester.ensureVisible(find.text('Collisions'));
    await pumpIo(tester, frames: 4);
    await tester.tap(find.text('Collisions'));
    await pumpIo(tester, frames: 4);
    expect(
      tester
          .widget<MapWorkspaceCanvas>(find.byType(MapWorkspaceCanvas))
          .view
          .tool,
      StudioMapTool.collisionPaint,
    );
    final point = cell(position);
    expect(
      tester
          .getRect(find.byKey(const ValueKey('map-viewport')))
          .contains(point),
      true,
    );
    final surface = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey('map-canvas')),
    );
    expect(
      tester.hitTestOnBinding(point).path.any((hit) => hit.target == surface),
      true,
      reason:
          'Canvas=${tester.getRect(find.byKey(const ValueKey('map-canvas')))};viewport=${tester.getRect(find.byKey(const ValueKey('map-viewport')))};point=$point;hit=${tester.hitTestOnBinding(point).path.map((hit) => hit.target.runtimeType).join(',')}',
    );
    final before = fixture.host.maps.active!.current;
    await tester.tapAt(point);
    await pumpIo(tester, frames: 6);
    expect(
      fixture.host.maps.active!.current,
      isNot(before),
      reason:
          'Collision drawn at $position: ${fixture.host.maps.active!.error}; $point',
    );
    expect(fixture.host.maps.active!.dirty, true);
    await navigator(visible: true);
  }

  Future<ProjectMapEntry> duplicate(ProjectMapEntry source) async {
    await fixture.mapAction(source.id, 'Dupliquer…');
    await fixture.field('duplicate-map-name', 'Île — copie jouable');
    await tester.tap(find.text('Dupliquer la carte').last);
    await pumpIo(tester, frames: 30);
    return fixture.host.maps.project!.maps.singleWhere(
      (entry) => entry.name == 'Île — copie jouable',
    );
  }

  Future<void> resize(String id, GridSize size, {bool apply = true}) async {
    await fixture.mapAction(id, 'Redimensionner…');
    await fixture.field('resize-map-width', '${size.width}');
    await fixture.field('resize-map-height', '${size.height}');
    await tester.tap(find.text('Analyser les conséquences'));
    await pumpIo(tester, frames: 20);
    if (apply) {
      await tester.tap(find.text('Appliquer le redimensionnement'));
      await pumpIo(tester, frames: 30);
    }
  }

  Offset cell(GridPos position) {
    final canvas = tester.widget<MapWorkspaceCanvas>(
      find.byType(MapWorkspaceCanvas),
    );
    final surface = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey('map-canvas')),
    );
    final settings = canvas.project.settings;
    return surface.localToGlobal(
      Offset(
        (position.x + .5) * settings.tileWidth * settings.displayScale,
        (position.y + .5) * settings.tileHeight * settings.displayScale,
      ),
    );
  }

  Future<void> passage(String destination, GridPos from, GridPos target) async {
    await navigator(visible: false);
    await tester.ensureVisible(find.text('Passages'));
    await pumpIo(tester, frames: 4);
    await tester.tap(find.text('Passages'));
    await pumpIo(tester, frames: 5);
    await tester.tap(find.byTooltip('Recentrer'));
    await pumpIo(tester, frames: 4);
    final choice = find.byKey(ValueKey('warp-destination-$destination'));
    await tester.ensureVisible(choice);
    await pumpIo(tester, frames: 5);
    await tester.tap(choice);
    await pumpIo(tester, frames: 5);
    expect(
      tester
          .widget<MapWorkspaceCanvas>(find.byType(MapWorkspaceCanvas))
          .view
          .warpDestination
          ?.id,
      destination,
    );
    await tester.tapAt(cell(from));
    await pumpIo(tester, frames: 6);
    final warp = fixture.host.maps.active!.current.warps.last;
    expect(warp.pos, from);
    expect(warp.targetMapId, destination);
    final owner = '${fixture.host.maps.active!.current.id}/${warp.id}';
    await fixture.field('warp-target-x-$owner', '${target.x}');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pumpIo(tester, frames: 3);
    await fixture.field('warp-target-y-$owner', '${target.y}');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pumpIo(tester, frames: 3);
    await fixture.tapKey('Enregistrer');
    expect(fixture.host.maps.active!.dirty, isFalse);
    expect(fixture.host.maps.active!.current.warps.last.targetPos, target);
    await navigator(visible: true);
  }
}
