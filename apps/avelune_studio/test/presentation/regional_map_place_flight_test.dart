import 'package:avelune_studio/features/regional_map/application/regional_map_controller.dart';
import 'package:avelune_studio/presentation/features/regional_map/regional_map_page.dart';
import 'package:avelune_studio/presentation/features/regional_map/regional_map_place_summary.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../application/regional_map_controller_test.dart'
    show MemoryRegionalMapPort;

void main() {
  VoidCallback refresh = () {};
  setUp(() => refresh = () {});

  Future<RegionalMapController> regional(MemoryRegionalMapPort port) async {
    final controller = RegionalMapController(port, changed: () => refresh());
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

  Future<void> show(
    WidgetTester tester,
    RegionalMapController controller,
  ) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, rebuild) {
              refresh = () => rebuild(() {});
              return RegionalMapPage(controller: controller);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a place is found by its name or its Flight arrival map', (
    tester,
  ) async {
    final controller = await seeded(MemoryRegionalMapPort());
    await show(tester, controller);
    final search = find.byKey(const ValueKey('regional-place-search'));
    await tester.enterText(search, 'grot');
    await tester.pump();
    final cave = controller.points.singleWhere(
      (point) => point.label == 'Grotte Noire',
    );
    final choice = find.byKey(ValueKey('regional-place-${cave.id}'));
    expect(choice, findsOneWidget);
    expect(
      find.text('Masqué sur la carte régionale · Vol autorisé vers Town'),
      findsWidgets,
    );
    await tester.enterText(search, 'vol autorisé');
    await tester.pump();
    expect(find.byKey(ValueKey('regional-place-${cave.id}')), findsOneWidget);
    final town = controller.points.singleWhere(
      (point) => point.label == 'Bourg Geon',
    );
    expect(find.byKey(ValueKey('regional-place-${town.id}')), findsNothing);
    await tester.enterText(search, 'grot');
    await tester.pump();
    await tester.tap(find.byKey(ValueKey('regional-place-${cave.id}')));
    await tester.pump();
    expect(controller.point!.id, cave.id);
    expect(tester.takeException(), isNull);
  });

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

  testWidgets('a missing arrival is shown as a problem on the page', (
    tester,
  ) async {
    final controller = await seeded(MemoryRegionalMapPort());
    controller.editPoint(
      destination: ProjectRegionDestination(mapId: 'town', spawnId: 'gone'),
    );
    await show(tester, controller);
    final notice = find.byKey(const ValueKey('regional-flight-arrival'));
    expect(notice, findsOneWidget);
    expect(
      find.descendant(
        of: notice,
        matching: find.textContaining('« gone » n’existe plus sur Town'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
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
