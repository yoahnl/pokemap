import 'package:avelune_studio/features/map_workspace/application/map_library_tree.dart';
import 'package:avelune_studio/features/regional_map/application/regional_map_choices.dart';
import 'package:avelune_studio/features/regional_map/application/regional_map_controller.dart';
import 'package:avelune_studio/features/regional_map/application/regional_map_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../application/regional_map_controller_test.dart'
    show MemoryRegionalMapPort;

void main() {
  final manifest = ProjectManifest(
    name: 'Regional',
    tilesets: [],
    maps: const [
      ProjectMapEntry(id: 'alpha', name: 'Alpha', relativePath: 'maps/alpha.json'),
      ProjectMapEntry(
        id: 'town',
        name: 'Town',
        relativePath: 'maps/town.json',
        groupId: 'bourg',
      ),
    ],
    groups: const [
      ProjectMapGroup(id: 'johto', name: 'Johto', type: MapGroupType.city),
      ProjectMapGroup(
        id: 'bourg',
        name: 'Bourg Geon',
        type: MapGroupType.village,
        parentGroupId: 'johto',
      ),
    ],
  );

  Future<RegionalMapController> open() async {
    final port = MemoryRegionalMapPort()..project = manifest;
    final controller = RegionalMapController(port, changed: () {});
    await controller.load();
    controller.createRegion('Johto');
    controller.editRegion(imagePath: 'assets/region.png');
    return controller;
  }

  Future<RegionalMapController> seeded() async {
    final port = MemoryRegionalMapPort();
    final controller = RegionalMapController(port, changed: () {});
    await controller.load();
    controller.createRegion('Johto');
    controller.editRegion(imagePath: 'assets/region.png');
    controller.createPoint('Bourg Geon', 'town');
    controller.editPoint(visibility: ProjectRegionPointVisibility.always);
    controller.createPoint('Grotte Noire', 'town');
    controller.editPoint(
      visibility: ProjectRegionPointVisibility.hidden,
      destination: ProjectRegionDestination(mapId: 'town', spawnId: 'arrival'),
    );
    controller.createPoint('Phare', 'town');
    return controller;
  }

  test('creating a place asks for its linked map instead of taking the first one', () async {
    final controller = await open();
    final folders = mapLibraryFolderLabels(manifest.groups);
    expect(
      regionalMapChoiceLabel(manifest.maps.last, folders),
      'Town · Johto / Bourg Geon',
    );
    expect(regionalMapChoiceLabel(manifest.maps.first, folders), 'Alpha');
    expect(
      regionalMapChoiceLabel(
        const ProjectMapEntry(
          id: 'lost',
          name: 'Lost',
          relativePath: 'maps/lost.json',
          groupId: 'unknown',
        ),
        folders,
      ),
      'Lost',
    );
    controller.createPoint('Bourg Geon', 'town');
    expect(controller.point!.label, 'Bourg Geon');
    expect(controller.point!.mapIds, ['town']);
  });

  test('creating a place ignores a blank name or an unknown map', () async {
    final controller = await open();
    controller.createPoint('Bourg Geon', 'ghost');
    controller.createPoint('   ', 'town');
    expect(controller.catalog.pointsOfInterest, isEmpty);
    expect(controller.point, isNull);
  });

  test('enabling Flight asks to confirm the arrival map and suggests the place map', () async {
    final controller = await open();
    controller.createPoint('Town', 'town');
    final point = controller.point!;
    expect(regionalSuggestedMapId(manifest, point.mapIds.firstOrNull), 'town');
    expect(point.destination, isNull);
    expect(regionalSuggestedMapId(manifest, 'ghost'), isNull);
    expect(regionalSuggestedMapId(manifest, null), isNull);
    controller.editPoint(destination: ProjectRegionDestination(mapId: 'town'));
    expect(controller.point!.destination!.mapId, 'town');
    expect(controller.point!.destination!.spawnId, isNull);
  });

  test('disabling Flight clears the destination', () async {
    final controller = await seeded();
    controller.selectPoint(
      controller.points.singleWhere((point) => point.label == 'Grotte Noire').id,
    );
    expect(controller.point!.destination, isNotNull);
    controller.editPoint(clearDestination: true);
    expect(controller.point!.destination, isNull);
  });

  test('arrival spawns are projected for the picker with name, position and facing', () async {
    final map = MemoryRegionalMapPort().source().maps['town'];
    expect(regionalSpawnOptions(map), {'arrival': 'Arrivée · (3, 4) · Sud'});
    expect(regionalSpawnOptions(null), isEmpty);
    expect(
      regionalSpawnOptions(
        MapData(id: 'plain', name: 'Plain', size: const GridSize(width: 2, height: 2)),
      ),
      isEmpty,
    );
  });

  test('a place is found by its name or its Flight arrival map', () async {
    final controller = await seeded();
    final points = controller.points;
    final cave = points.singleWhere((point) => point.label == 'Grotte Noire');
    final town = points.singleWhere((point) => point.label == 'Bourg Geon');
    final project = controller.source!.project;
    List<String> found(String query) => regionalPlaceMatches(
      points: points,
      project: project,
      query: query,
    ).map((point) => point.id).toList();

    expect(found('grot'), [cave.id]);
    expect(regionalPlaceVisibility(cave), 'Masqué sur la carte régionale');
    expect(regionalPlaceFlight(cave, project), 'Vol autorisé vers Town');
    expect(found('vol autorisé'), [cave.id]);
    expect(found('vol autorisé'), isNot(contains(town.id)));
    expect(found('   '), isEmpty);
    expect(found('introuvable-xyz'), isEmpty);
    expect(found(cave.id.toUpperCase()), [cave.id]);
    expect(found('vol non autorisé'), unorderedEquals([town.id, points.last.id]));
    expect(regionalPlaceFinderLimit, 12);
  });

  test('regional image dragging edits normalized draft coordinates and preserves undo', () async {
    final controller = await seeded();
    controller.selectPoint(
      controller.points.singleWhere((point) => point.label == 'Bourg Geon').id,
    );
    controller.placePoint(dx: 100, dy: 50, width: 400, height: 200);
    expect(controller.point!.u, .25);
    expect(controller.point!.v, .25);
    controller.dragPoint(dx: 100, dy: -25, width: 400, height: 200);
    expect(controller.point!.u, .5);
    expect(controller.point!.v, .125);
    expect(controller.dirty, isTrue);
    controller.dragPoint(dx: 1000, dy: 1000, width: 400, height: 200);
    expect(controller.point!.u, 1);
    expect(controller.point!.v, 1);
    controller.undo();
    expect(controller.point!.u, .5);
    expect(controller.point!.v, .125);
    controller.discard();
    expect(controller.catalog.regions, isEmpty);
  });

  test('dragging a place without selection changes nothing', () async {
    final controller = await open();
    controller.dragPoint(dx: 10, dy: 10, width: 100, height: 100);
    expect(controller.catalog.pointsOfInterest, isEmpty);
    expect(controller.dirty, isTrue);
  });
}
