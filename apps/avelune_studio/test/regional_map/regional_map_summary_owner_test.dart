import 'package:avelune_studio/features/regional_map/application/regional_map_controller.dart';
import 'package:avelune_studio/features/regional_map/application/regional_map_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../application/regional_map_controller_test.dart'
    show MemoryRegionalMapPort;

void main() {
  Future<RegionalMapController> regional(MemoryRegionalMapPort port) async {
    final controller = RegionalMapController(port, changed: () {});
    await controller.load();
    return controller;
  }

  Future<RegionalMapController> seeded(MemoryRegionalMapPort port) async {
    final controller = await regional(port);
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

  test('visibility and Flight are summarised separately', () {
    final project = MemoryRegionalMapPort().project;
    ProjectRegionPointOfInterest place({
      ProjectRegionPointVisibility visibility =
          ProjectRegionPointVisibility.discoveredOnly,
      ProjectRegionPointDiscovery discovery =
          ProjectRegionPointDiscovery.onMapVisit,
      ProjectRegionDestination? destination,
    }) => ProjectRegionPointOfInterest(
      id: 'place',
      regionId: 'johto',
      label: 'Lieu',
      u: .25,
      v: .5,
      visibility: visibility,
      discovery: discovery,
      mapIds: const ['town'],
      destination: destination,
    );
    expect(
      regionalPlaceVisibility(place()),
      'Visible après la visite d’une carte liée',
    );
    expect(
      regionalPlaceVisibility(
        place(discovery: ProjectRegionPointDiscovery.always),
      ),
      'Visible dès le départ sur la carte régionale',
    );
    expect(regionalPlaceFlight(place(), project), 'Vol non autorisé');
    expect(
      regionalPlaceFlight(
        place(
          visibility: ProjectRegionPointVisibility.hidden,
          destination: ProjectRegionDestination(mapId: 'ghost'),
        ),
        project,
      ),
      'Vol vers une carte introuvable : ghost',
    );
    expect(
      regionalPlacePosition(place()),
      'Position : 25 % depuis la gauche, 50 % depuis le haut',
    );
  });

  test('the Flight arrival preview names every incomplete destination', () {
    final port = MemoryRegionalMapPort();
    final map = port.source().maps['town'];
    ({String text, bool problem}) arrival(ProjectRegionDestination value) =>
        regionalFlightArrival(
          destination: value,
          project: port.project,
          map: value.mapId == 'town' ? map : null,
          loading: false,
        );
    expect(arrival(ProjectRegionDestination(mapId: 'ghost')).problem, isTrue);
    expect(
      arrival(ProjectRegionDestination(mapId: 'ghost')).text,
      contains('« ghost » n’existe plus'),
    );
    expect(
      arrival(ProjectRegionDestination(mapId: 'town')).text,
      startsWith('Choisissez le point d’arrivée'),
    );
    final gone = arrival(
      ProjectRegionDestination(mapId: 'town', spawnId: 'gone'),
    );
    expect(gone.problem, isTrue);
    expect(gone.text, contains('« gone » n’existe plus sur Town'));
    final ready = arrival(
      ProjectRegionDestination(mapId: 'town', spawnId: 'arrival'),
    );
    expect(ready.problem, isFalse);
    expect(
      ready.text,
      'Arrivée de Vol : Town, à « Arrivée » (3, 4), regard vers le sud.',
    );
  });

  test('an existing destination survives a save and a fresh reopen', () async {
    final port = MemoryRegionalMapPort();
    final controller = await seeded(port);
    expect(await controller.saveAll(), isTrue, reason: controller.error);
    final reopened = await regional(port);
    final cave = reopened.catalog.pointsOfInterest.singleWhere(
      (point) => point.label == 'Grotte Noire',
    );
    expect(cave.visibility, ProjectRegionPointVisibility.hidden);
    expect(cave.destination!.mapId, 'town');
    expect(cave.destination!.spawnId, 'arrival');
    expect(
      reopened.catalog.pointsOfInterest
          .singleWhere((point) => point.label == 'Bourg Geon')
          .destination,
      isNull,
    );
  });
}
