import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_resource_placement.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_editing_viewport_2d.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';

import '../support/m2_ui_fixture.dart';
import '../support/uwu5_border_host.dart';

void main() {
  testWidgets('canonically prepared border stays visible over opaque ground after canvas drawing and disk reopen', (
    tester,
  ) async {
    final host = await openUwU5BorderHost(
      tester,
      configure: (fixture) async {
        final source = File('${fixture.root.path}/opaque-ground.png');
        final pixels = image.Image(width: 16, height: 24);
        image.fill(pixels, color: image.ColorRgb8(200, 60, 40));
        await source.writeAsBytes(image.encodePng(pixels));
        final imported = await fixture.resources.importImage(
          ResourceImageImport(
            sourcePath: source.path,
            name: 'Sol opaque',
            tileWidth: 16,
            tileHeight: 24,
          ),
        );
        final base = await fixture.loadMap();
        await fixture.maps.saveMap(
          fixture.session,
          base,
          base.map.copyWith(
            layers: [
              TileLayer(
                id: 'ground',
                name: 'Sol',
                cells: List.filled(16, 1),
                palette: [
                  TileLayerPaletteEntry(
                    tilesetId: imported.createdTilesetId!,
                    localTileId: 0,
                  ),
                ],
              ),
              CollisionLayer(
                id: 'collision',
                name: 'Collision témoin',
                collisions: List.generate(16, (index) => index == 15),
              ),
            ],
          ),
        );
      },
    );
    final fixture = host.fixture;
    expect(
      fixture.controller.active!.current.layers.whereType<BorderLayer>(),
      isEmpty,
    );
    await tester.tap(find.byTooltip('Carte').first);
    await pumpIo(tester, frames: 20);
    await tester.runAsync(() => fixture.visuals!.settled);
    await pumpIo(tester, frames: 6);
    final before = await _bluePixels(tester, fixture);
    expect(before, 0);
    final initial = fixture.controller.active!.current;
    await tester.tap(find.text('Bordures').first);
    await pumpIo(tester, frames: 6);
    await fixture.controller.ensureBorderProfiles();
    final view = tester
        .widget<MapEditingViewport2D>(find.byType(MapEditingViewport2D))
        .view;
    final item = resourceCatalog(fixture.controller.project!)
        .singleWhere((item) => item.border?.id == 'garden-fence');
    expect(
      await useMapResource(
        workspace: fixture.controller,
        item: item,
        view: () => view,
        isActive: () => true,
        chooseMap: (_) async => throw StateError('The map is already active'),
        chooseTile: (_) async =>
            throw StateError('A border needs no tile selection'),
      ),
      isTrue,
    );
    fixture.controller.notify();
    await pumpIo(tester, frames: 3);
    final canvas = tester.getRect(find.byKey(const ValueKey('map-canvas')));
    for (final x in [1, 2]) {
      await tester.tapAt(
        canvas.topLeft +
            Offset((x + .5) * canvas.width / 4, 1.5 * canvas.height / 4),
      );
      await pumpIo(tester, frames: 4);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpIo(tester, frames: 20);
    await tester.tap(find.byKey(const ValueKey('Sélectionner')));
    await pumpIo(tester, frames: 8);
    await tester.runAsync(() => fixture.visuals!.settled);
    await pumpIo(tester, frames: 8);
    final map = fixture.controller.active!.current;
    final layer = map.layers.whereType<BorderLayer>().single;
    final feature = layer.content.features.single;
    expect(feature.blueprintId, 'garden-fence');
    expect(feature.materialization, isNotNull);
    expect(
      feature.materialization!.receipt.blueprintRevision,
      fixture.controller.project!.borderCatalog
          .recordById('garden-fence')!
          .latestPublished!
          .revision,
    );
    expect(fixture.visuals!.borderPreviewIssue, isNull);
    final visiblePixels = await _bluePixels(tester, fixture);
    expect(visiblePixels, greaterThan(0));
    debugPrint('UwU6 first border: $before → $visiblePixels blue pixels');
    expect(
      map.layers.whereType<TileLayer>().single,
      initial.layers.whereType<TileLayer>().single,
    );
    expect(
      map.layers.whereType<CollisionLayer>().single,
      initial.layers.whereType<CollisionLayer>().single,
    );
    await fixture.capture(tester, 'uwu6-first-border-visible-1536');
    await tester.tap(find.byKey(const ValueKey('Enregistrer')));
    await pumpIo(tester, frames: 20);
    expect(fixture.controller.active!.dirty, isFalse);
    final saved = (await tester.runAsync(() async {
      final sessions = LocalProjectSessionAdapter();
      final reopened = await sessions.open(fixture.directory.path);
      try {
        final adapter = LocalMapWorkspaceAdapter();
        final project = await adapter.loadProject(reopened);
        return await adapter.loadMap(reopened, project.maps.single);
      } finally {
        await sessions.close(reopened);
      }
    }))!;
    expect(saved.map.layers.whereType<BorderLayer>().single, layer);
    expect(tester.takeException(), isNull);
  });
}

Future<int> _bluePixels(WidgetTester tester, M2UiFixture fixture) async {
  final canvas = tester.getRect(find.byKey(const ValueKey('map-canvas')));
  final boundary =
      fixture.captureKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final captured = await boundary.toImage();
    final bytes = (await captured.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!;
    var count = 0;
    for (var y = canvas.top.ceil(); y < canvas.bottom.floor(); y++) {
      for (var x = canvas.left.ceil(); x < canvas.right.floor(); x++) {
        final index = (y * captured.width + x) * 4;
        if (bytes.getUint8(index) == 80 &&
            bytes.getUint8(index + 1) == 150 &&
            bytes.getUint8(index + 2) == 200) {
          count++;
        }
      }
    }
    captured.dispose();
    return count;
  }))!;
}
