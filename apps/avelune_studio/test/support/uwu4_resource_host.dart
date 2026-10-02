import 'package:avelune_studio/presentation/features/resources/resource_image_import.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import '../resource_io/resource_fixture.dart';
import 'm2_ui_fixture.dart';
import 'uwu_resource_host.dart';
import 'widget_resource_management_port.dart';
import 'copy_uwu4_native_fixture.dart';
import 'load_desktop_capture_fonts.dart';

Future<UwUResourceHost> openUwU4ResourceHost(
  WidgetTester tester, {
  bool placed = false,
  Size size = const Size(1536, 1024),
  double textScale = 1,
  PickResourceImage? imagePicker,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  late ResourceFixture resources;
  final fixture = (await tester.runAsync(() async {
    await loadDesktopCaptureFonts();
    resources = await ResourceFixture.create();
    final receipt = await resources.import();
    final id = receipt.createdTilesetId!;
    await resources.resources.mutate('element_category.upsert', {
      'category': {'id': 'nature', 'name': 'Nature'},
    });
    await resources.resources.saveElement(
      resources.element(id).copyWith(categoryId: 'nature'),
    );
    if (placed) {
      final document = await resources.loadMap();
      await resources.maps.saveMap(
        resources.session,
        document,
        document.map.copyWith(
          placedElements: const [
            MapPlacedElement(
              id: 'placed-tree',
              layerId: 'ground',
              elementId: 'tree',
              pos: GridPos(x: 1, y: 1),
            ),
          ],
        ),
      );
    }
    final controller = WidgetMapController(
      resources.session,
      resources.maps,
      tester,
    );
    await controller.initialize();
    await copyUwU4NativeFixture(resources.root);
    return M2UiFixture(
      resources.root,
      resources.session,
      resources.maps,
      controller,
      resources.resources,
    );
  }))!;
  addTearDown(() async {
    fixture.controller.dispose();
    await resources.dispose();
  });
  await tester.pumpWidget(
    fixture.app(
      tester,
      textScale: textScale,
      imagePicker:
          imagePicker ??
          () async {
            final bytes = (await WidgetResourcePort.serial(
              tester,
              resources.source.readAsBytes,
            ))!;
            return PickedResourceImage(
              resources.source.path,
              'Source compatible',
              bytes,
              64,
              48,
            );
          },
      resourcePort: WidgetResourceManagementPort(resources.resources, tester),
    ),
  );
  await pumpIo(tester);
  await tester.tap(find.byTooltip('Ressources').first);
  await pumpIo(tester);
  return UwUResourceHost(tester, fixture);
}
