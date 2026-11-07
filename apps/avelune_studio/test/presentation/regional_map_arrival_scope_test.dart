import 'dart:async';
import 'dart:typed_data';

import 'package:avelune_studio/features/regional_map/application/regional_map_controller.dart';
import 'package:avelune_studio/features/regional_map/domain/regional_map_port.dart';
import 'package:avelune_studio/presentation/features/regional_map/regional_map_linked_maps.dart';
import 'package:avelune_studio/presentation/features/regional_map/regional_map_page.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
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

  Future<List<List<String>>> pump(
    WidgetTester tester, {
    required List<String> linked,
    ProjectRegionPointDiscovery discovery =
        ProjectRegionPointDiscovery.onMapVisit,
  }) async {
    final changes = <List<String>>[];
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: RegionalMapLinkedMaps(
              project: project,
              mapIds: linked,
              discovery: discovery,
              busy: false,
              onChanged: changes.add,
            ),
          ),
        ),
      ),
    );
    return changes;
  }

  testWidgets('linked maps are summarized and added through a search', (
    tester,
  ) async {
    final changes = await pump(tester, linked: ['violet']);
    expect(
      find.byKey(const ValueKey('regional-linked-violet')),
      findsOneWidget,
    );
    expect(find.byType(Switch), findsNothing);
    expect(find.byKey(const ValueKey('regional-add-route_12')), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('regional-linked-search')),
      'route 12',
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('regional-add-route_12')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('regional-add-route_12')),
        matching: find.textContaining('Routes'),
      ),
      findsWidgets,
    );
    await tester.tap(find.byKey(const ValueKey('regional-add-route_12')));
    await tester.pump();
    expect(changes.single, ['violet', 'route_12']);
  });

  testWidgets('removing the last visited map is refused with its reason', (
    tester,
  ) async {
    final changes = await pump(tester, linked: ['violet']);
    expect(
      find.byKey(const ValueKey('regional-linked-last-reason')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('regional-remove-violet')));
    await tester.pump();
    expect(changes, isEmpty);

    final known = await pump(
      tester,
      linked: ['violet'],
      discovery: ProjectRegionPointDiscovery.always,
    );
    expect(
      find.byKey(const ValueKey('regional-linked-last-reason')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('regional-remove-violet')));
    await tester.pump();
    expect(known.single, isEmpty);
  });

  testWidgets('a missing linked map stays visible and removable', (
    tester,
  ) async {
    final changes = await pump(tester, linked: ['violet', 'ghost_town']);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('regional-linked-ghost_town')),
        matching: find.textContaining('introuvable'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('regional-remove-ghost_town')));
    await tester.pump();
    expect(changes.single, ['violet']);
  });

  Future<void> pumpRegion(
    WidgetTester tester,
    Future<Uint8List?> Function() readImage,
  ) async {
    final controller = RegionalMapController(
      _ForcedImagePort(readImage),
      changed: () {},
    );
    await controller.load();
    controller.createRegion('Johto');
    controller.editRegion(imagePath: 'assets/region.png');
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(body: RegionalMapPage(controller: controller)),
      ),
    );
    await tester.pump();
  }

  Future<void> settleImage(WidgetTester tester, Key expected) async {
    for (
      var attempt = 0;
      attempt < 40 && find.byKey(expected).evaluate().isEmpty;
      attempt++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump();
    }
  }

  testWidgets('a region image still loading says so, then reads as absent', (
    tester,
  ) async {
    final pending = Completer<Uint8List?>();
    await pumpRegion(tester, () => pending.future);
    expect(
      find.byKey(const ValueKey('regional-image-loading')),
      findsOneWidget,
    );
    expect(find.text('Chargement de l’image…'), findsOneWidget);
    expect(find.byKey(const ValueKey('regional-image-missing')), findsNothing);
    pending.complete(null);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('regional-image-loading')), findsNothing);
    expect(
      find.byKey(const ValueKey('regional-image-missing')),
      findsOneWidget,
    );
    expect(find.text('Image absente'), findsOneWidget);
  });

  testWidgets('an unreadable region image is told apart from a missing one', (
    tester,
  ) async {
    await pumpRegion(tester, () async => Uint8List.fromList([1, 2, 3, 4]));
    const error = ValueKey('regional-image-error');
    await settleImage(tester, error);
    expect(find.byKey(error), findsOneWidget);
    expect(find.text('Image illisible'), findsOneWidget);
    expect(find.byKey(const ValueKey('regional-image-missing')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed read is unreadable, not absent', (tester) async {
    await pumpRegion(
      tester,
      () async => throw const FormatException('permission refusée'),
    );
    const error = ValueKey('regional-image-error');
    await settleImage(tester, error);
    expect(find.byKey(error), findsOneWidget);
    expect(find.textContaining('permission refusée'), findsOneWidget);
  });
}

final class _ForcedImagePort implements RegionalMapPort {
  _ForcedImagePort(this.read);
  final Future<Uint8List?> Function() read;
  final _memory = MemoryRegionalMapPort();

  @override
  Future<RegionalMapSource> load() => _memory.load();

  @override
  Future<Uint8List?> readImage(String path) => read();

  @override
  Future<RegionalMapSource> publish({
    required RegionalMapSource base,
    required String actionId,
    required Map<String, Object?> parameters,
  }) => _memory.publish(base: base, actionId: actionId, parameters: parameters);
}
