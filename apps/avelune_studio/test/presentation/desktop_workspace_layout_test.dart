import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/resource_stress_fixture.dart';
import '../support/desktop_workspace_capture.dart';
import '../support/neutral_map_host_fixture.dart';

void main() {
  testWidgets('native stress viewport loads demand resources, retains selection and retries one diagnostic', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = (await tester.runAsync(ResourceStressFixture.create))!;
    final controller = MapWorkspaceController(fixture.session, LocalMapWorkspaceAdapter());
    StudioMapResources? resources;
    NeutralMapHostFixture? host;
    addTearDown(() async {
      if (host != null) {
        await host.dispose();
      } else {
        await resources?.dispose();
      }
      controller.dispose();
      await fixture.dispose();
    });
    await tester.runAsync(controller.initialize);
    resources = (await tester.runAsync(() => StudioMapResources.load(
      fixture.session, controller.visualProject!,
    )))!;
    expect(resources.store.decoder.reads, 0);
    resources.setActiveMap(controller.active!.current);
    host = await NeutralMapHostFixture.fromController(
      tester, controller, visuals: resources,
    );
    await settleDesktopWorkspace(tester, resources);
    expect(controller.active!.base.mapId, 'stress-a');
    expect(controller.error, isNull);
    expect(resources.images.containsKey(fixture.lateAtlasId), isTrue);
    expect(resources.diagnostics, isEmpty);
    expect(resources.images.length, lessThan(fixture.atlasCount));
    final document = controller.active!;
    final selected = document.current.placedElements.first;
    document.selectedId = selected.id;
    document.stackPosition = selected.pos;
    controller.notify();
    await settleDesktopWorkspace(tester, resources);

    final owner = Object();
    final tiles = [
      for (final atlas in fixture.manifest.tilesets.take(8))
        TileLayerPaletteEntry(tilesetId: atlas.id, localTileId: 0),
    ];
    expect(tiles, isNotEmpty);
    final ids = tiles.expand(resources.tileResourceIds).toSet();
    final reads = resources.store.decoder.reads;
    resources.retain(owner, ids);
    await settleDesktopWorkspace(tester, resources);
    expect(ids.every(resources.images.containsKey), isTrue);
    expect(resources.store.decoder.reads - reads, lessThanOrEqualTo(ids.length));
    resources.release(owner);

    await awaitDesktopIo(tester, controller.activate(
      fixture.manifest.maps.singleWhere((entry) => entry.id == 'stress-errors'),
    ));
    resources.setActiveMap(controller.active!.current);
    await settleDesktopWorkspace(tester, resources);
    expect(resources.diagnostics, hasLength(200));
    expect(controller.active!.base.mapId, 'stress-errors');
    expect(controller.documents['stress-a'], same(document));
    expect(document.selectedId, selected.id);
    expect(document.dirty, isFalse);
    expect(tester.takeException(), isNull);
    await tester.runAsync(fixture.makeMissingAvailable);
    await awaitDesktopIo(tester, resources.retryResources([stressIncidentId(0)]));
    await settleDesktopWorkspace(tester, resources);
    expect(resources.images.containsKey(stressIncidentId(0)), isTrue);
    expect(resources.diagnostics, hasLength(199));
    expect(tester.takeException(), isNull);
  });
}
