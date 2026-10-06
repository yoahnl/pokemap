import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/presentation/features/resources/resource_image_import.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'm2_ui_fixture.dart';
import 'uwu_resource_host.dart';
import 'widget_resource_journey_map_port.dart';
import 'widget_resource_management_port.dart';

Future<void> tapResourceAdministrationText(
  WidgetTester tester,
  String label,
) async {
  final target = find.text(label).last;
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await pumpIo(tester);
}

Future<void> prepareResourceAdministrationAtlas(
  WidgetTester tester,
  M2UiFixture fixture,
) async {
  final project = fixture.controller.project!;
  await tester.runAsync(
    () => File('${fixture.directory.path}/project.json').writeAsString(
      jsonEncode(
        project
            .copyWith(
              tilesets: [
                project.tilesets.single.copyWith(
                  source: const ProjectTilesetSource.regularAtlas(
                    assetId: 'atelier',
                    pixelWidth: 160,
                    pixelHeight: 64,
                    tileWidth: 16,
                    tileHeight: 16,
                  ),
                ),
              ],
            )
            .toJson(),
      ),
    ),
  );
}

Future<UwUResourceHost> reopenResourceAdministrationHost(
  WidgetTester tester,
  M2UiFixture original, {
  PickResourceImage? imagePicker,
}) async {
  final sessions = LocalProjectSessionAdapter();
  final fixture = (await tester.runAsync(() async {
    final session = await sessions.open(original.directory.path);
    final maps = LocalMapWorkspaceAdapter();
    final mapPort = WidgetResourceJourneyMapPort(maps, tester);
    final controller = WidgetMapController(session, mapPort, tester);
    await controller.initialize();
    mapPort.active = true;
    return M2UiFixture(
      original.directory,
      session,
      maps,
      controller,
      LocalResourceAdapter(session: session, mapAdapter: maps),
    );
  }))!;
  addTearDown(() async {
    fixture.controller.dispose();
    await fixture.resources.dispose();
    await sessions.close(fixture.session);
  });
  await tester.pumpWidget(
    fixture.app(
      tester,
      imagePicker: imagePicker,
      resourcePort: WidgetResourceManagementPort(fixture.resources, tester),
    ),
  );
  await pumpIo(tester);
  await tester.tap(find.byTooltip('Ressources').first);
  await pumpIo(tester);
  return UwUResourceHost(tester, fixture);
}

Future<MapWorkspaceDocument> readResourceAdministrationMap(
  M2UiFixture fixture,
  String mapId,
) async {
  final sessions = LocalProjectSessionAdapter();
  final session = await sessions.open(fixture.directory.path);
  try {
    final reader = LocalMapWorkspaceAdapter();
    final manifest = await reader.loadProject(session);
    return await reader.loadMap(
      session,
      manifest.maps.singleWhere((item) => item.id == mapId),
    );
  } finally {
    await sessions.close(session);
  }
}
