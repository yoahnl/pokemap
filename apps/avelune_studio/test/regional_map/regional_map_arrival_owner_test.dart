import 'package:avelune_studio/features/map_workspace/application/map_library_tree.dart';
import 'package:avelune_studio/features/regional_map/application/regional_map_choices.dart';
import 'package:avelune_studio/features/regional_map/application/regional_map_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../application/regional_map_controller_test.dart'
    show MemoryRegionalMapPort;

void main() {
  final project = ProjectManifest(
    name: 'Johto',
    tilesets: const [],
    groups: const [
      ProjectMapGroup(id: 'routes', name: 'Routes', type: MapGroupType.route),
    ],
    maps: [
      for (var index = 1; index <= 40; index++)
        ProjectMapEntry(
          id: 'route_$index',
          name: 'Route $index',
          relativePath: 'maps/route_$index.json',
          groupId: 'routes',
        ),
      const ProjectMapEntry(
        id: 'violet',
        name: 'Mauville',
        relativePath: 'maps/violet.json',
      ),
    ],
  );
  final folders = mapLibraryFolderLabels(project.groups);

  Future<RegionalMapController> controllerFor(
    ProjectManifest manifest, {
    List<String> linked = const ['violet'],
    ProjectRegionPointDiscovery discovery =
        ProjectRegionPointDiscovery.onMapVisit,
  }) async {
    final port = MemoryRegionalMapPort()..project = manifest;
    final controller = RegionalMapController(port, changed: () {});
    await controller.load();
    controller.createRegion('Johto');
    controller.editRegion(imagePath: 'assets/region.png');
    controller.createPoint('Lieu', manifest.maps.first.id);
    controller.editPoint(mapIds: linked, discovery: discovery);
    return controller;
  }

  test('linked maps are summarized and added through a search', () async {
    final controller = await controllerFor(project);
    final linked = controller.point!.mapIds;
    expect(linked, ['violet']);
    expect(
      regionalLinkCandidates(
        project: project,
        linked: linked,
        folders: folders,
        query: '',
      ),
      isEmpty,
    );
    final candidates = regionalLinkCandidates(
      project: project,
      linked: linked,
      folders: folders,
      query: 'route 12',
    );
    expect(candidates.map((map) => map.id), ['route_12']);
    expect(regionalMapChoiceLabel(candidates.single, folders), contains('Routes'));
    expect(folders[candidates.single.groupId], 'Routes');
    controller.editPoint(mapIds: [...linked, candidates.single.id]);
    expect(controller.error, isNull);
    expect(controller.point!.mapIds, ['violet', 'route_12']);
    expect(
      regionalLinkCandidates(
        project: project,
        linked: controller.point!.mapIds,
        folders: folders,
        query: 'route 12',
      ),
      isEmpty,
    );
    expect(
      regionalLinkCandidates(
        project: project,
        linked: const [],
        folders: folders,
        query: 'ROUTES',
      ),
      hasLength(40),
    );
    expect(regionalLinkCandidateLimit, 20);
    expect(
      regionalLinkCandidates(
        project: project,
        linked: const [],
        folders: folders,
        query: 'route_3',
      ).map((map) => map.id),
      containsAll(['route_3', 'route_30', 'route_39']),
    );
  });

  test('removing the last visited map is refused with its reason', () async {
    final controller = await controllerFor(project);
    expect(
      regionalLastLinkedLocked(
        controller.point!.mapIds,
        ProjectRegionPointDiscovery.onMapVisit,
      ),
      isTrue,
    );
    controller.editPoint(mapIds: const []);
    expect(controller.error, contains('Choisissez au moins une carte'));
    expect(controller.point!.mapIds, ['violet']);

    expect(
      regionalLastLinkedLocked(
        controller.point!.mapIds,
        ProjectRegionPointDiscovery.always,
      ),
      isFalse,
    );
    expect(
      regionalLastLinkedLocked(const [
        'violet',
        'route_1',
      ], ProjectRegionPointDiscovery.onMapVisit),
      isFalse,
    );
    controller.editPoint(discovery: ProjectRegionPointDiscovery.always);
    controller.editPoint(mapIds: const []);
    expect(controller.error, isNull);
    expect(controller.point!.mapIds, isEmpty);
  });

  test('a missing linked map stays visible and removable', () async {
    final controller = await controllerFor(project);
    controller.editPoint(mapIds: ['violet', 'ghost_town']);
    expect(controller.point!.mapIds, ['violet', 'ghost_town']);
    expect(project.maps.any((map) => map.id == 'ghost_town'), isFalse);
    expect(
      regionalLinkCandidates(
        project: project,
        linked: controller.point!.mapIds,
        folders: folders,
        query: 'ghost',
      ),
      isEmpty,
    );
    controller.editPoint(
      mapIds: [
        for (final id in controller.point!.mapIds)
          if (id != 'ghost_town') id,
      ],
    );
    expect(controller.point!.mapIds, ['violet']);
    expect(controller.error, isNull);
  });
}
