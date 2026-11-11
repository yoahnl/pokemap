import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_map_tree.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

const _groups = [
  ProjectMapGroup(id: 'johto', name: 'Johto', type: MapGroupType.route),
  ProjectMapGroup(
    id: 'bourg',
    name: 'Bourg Geon',
    type: MapGroupType.village,
    parentGroupId: 'johto',
  ),
  ProjectMapGroup(
    id: 'routes',
    name: 'Routes',
    type: MapGroupType.route,
    parentGroupId: 'johto',
  ),
];

const _maps = [
  ProjectMapEntry(
    id: 'bourg-ext',
    name: 'Bourg Geon',
    relativePath: 'a.json',
    groupId: 'bourg',
  ),
  ProjectMapEntry(
    id: 'chambre',
    name: 'Chambre du joueur',
    relativePath: 'b.json',
    groupId: 'bourg',
    role: MapRole.interior,
  ),
  ProjectMapEntry(
    id: 'route29',
    name: 'Route 29',
    relativePath: 'c.json',
    groupId: 'routes',
  ),
  ProjectMapEntry(id: 'test', name: 'Carte de test', relativePath: 'd.json'),
];

void main() {
  late List<ProjectMapEntry> selected;

  Future<void> pumpTree(WidgetTester tester, {String? active}) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    selected = [];
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: MapBuilderMapTree(
            groups: _groups,
            maps: _maps,
            activeMapId: active,
            onSelect: selected.add,
          ),
        ),
      ),
    );
  }

  Finder map(String id) => find.byKey(ValueKey('map-library-map-$id'));
  Finder folder(String id) => find.byKey(ValueKey('map-library-folder-$id'));

  testWidgets('maps live in nested folders that open and close', (
    tester,
  ) async {
    await pumpTree(tester);

    expect(folder('johto'), findsOneWidget);
    expect(folder('bourg'), findsNothing);
    expect(map('bourg-ext'), findsNothing);

    await tester.tap(folder('johto'));
    await tester.pump();
    expect(folder('bourg'), findsOneWidget);
    expect(folder('routes'), findsOneWidget);
    expect(map('bourg-ext'), findsNothing);

    await tester.tap(folder('bourg'));
    await tester.pump();
    expect(map('bourg-ext'), findsOneWidget);
    expect(map('chambre'), findsOneWidget);
    expect(map('route29'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Chambre du joueur')).dx,
      greaterThan(tester.getTopLeft(find.text('Routes')).dx),
    );

    await tester.tap(folder('johto'));
    await tester.pump();
    expect(folder('bourg'), findsNothing);
    expect(map('chambre'), findsNothing);
  });

  testWidgets('the active map is revealed inside its folders', (tester) async {
    await pumpTree(tester, active: 'route29');

    expect(map('route29'), findsOneWidget);
    expect(map('bourg-ext'), findsNothing);
    expect(map('test'), findsNothing);
    expect(folder('unfiled'), findsOneWidget);
  });

  testWidgets('search shows matching maps with their folders', (tester) async {
    await pumpTree(tester);
    await tester.enterText(
      find.byKey(const ValueKey('map-library-search')),
      'chambre',
    );
    await tester.pump();

    expect(folder('johto'), findsOneWidget);
    expect(folder('bourg'), findsOneWidget);
    expect(map('chambre'), findsOneWidget);
    expect(map('bourg-ext'), findsNothing);
    expect(folder('routes'), findsNothing);

    await tester.tap(map('chambre'));
    expect(selected.single.id, 'chambre');
  });
}
