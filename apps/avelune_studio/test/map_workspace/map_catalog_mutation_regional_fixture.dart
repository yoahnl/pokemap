import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'map_catalog_fixture.dart';

Future<MapWorkspaceController> regionalController(
  MapCatalogFixture fixture,
) async {
  final project = fixture.controller.project!;
  final regional = ProjectRegionalMapCatalog(
    regions: [ProjectRegionDefinition(id: 'region', label: 'Region')],
    pointsOfInterest: [
      ProjectRegionPointOfInterest(
        id: 'poi',
        regionId: 'region',
        label: 'Town',
        u: 0.25,
        v: 0.5,
        mapIds: [project.maps.first.id],
        destination: ProjectRegionDestination(
          mapId: project.maps.first.id,
          spawnId: 'depart',
        ),
      ),
    ],
  );
  await File(
    p.join(fixture.root.path, 'project.json'),
  ).writeAsString(jsonEncode(project.copyWith(regionalMap: regional).toJson()));
  final controller = MapWorkspaceController(
    fixture.session,
    fixture.adapter,
    catalogPort: fixture.catalog,
  );
  await controller.initialize();
  expect(controller.error, isNull);
  return controller;
}
