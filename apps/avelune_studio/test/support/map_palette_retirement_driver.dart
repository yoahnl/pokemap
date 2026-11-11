import 'package:avelune_studio/features/map_workspace/coordination/map_resource_placement.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_layout.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> selectMapDecorForTest(WidgetTester tester, String id) async {
  final layout = tester.widget<MapWorkspaceLayout>(
    find.byType(MapWorkspaceLayout),
  );
  final maps = layout.controller;
  final item = resourceCatalog(maps.project!)
      .singleWhere((item) => item.element?.id == id);
  final source = maps.active!.current;
  final history = maps.active!.undoCount;
  expect(
    await useMapResource(
      workspace: maps,
      item: item,
      view: () => layout.view,
      isActive: () => !maps.isDisposed,
      chooseMap: (_) async => null,
      chooseTile: (_) async => null,
    ),
    isTrue,
  );
  expect(layout.view!.brush?.id, id);
  expect(maps.active!.current, same(source));
  expect(maps.active!.undoCount, history);
  layout.onToolChanged();
  await tester.pump();
}
