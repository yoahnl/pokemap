import 'package:avelune_studio/presentation/features/regional_map/regional_map_linked_maps.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

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
}
