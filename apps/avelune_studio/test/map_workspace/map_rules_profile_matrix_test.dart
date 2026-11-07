import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_arrival_picker.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_destination_picker.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_warp_inspector.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_commands.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_selection_harness.dart';
import '../support/map_workspace_fixture.dart';

ProjectManifest _catalogue() => workspaceProject.copyWith(
  groups: const [
    ProjectMapGroup(id: 'johto', name: 'Johto', type: MapGroupType.special),
    ProjectMapGroup(
      id: 'geon',
      name: 'Bourg Géon',
      type: MapGroupType.city,
      parentGroupId: 'johto',
    ),
    ProjectMapGroup(id: 'kanto', name: 'Kanto', type: MapGroupType.special),
  ],
  maps: [
    ...workspaceEntries,
    const ProjectMapEntry(
      id: 'house-geon',
      name: 'Maison',
      relativePath: 'house-geon.json',
      groupId: 'geon',
    ),
    const ProjectMapEntry(
      id: 'house-kanto',
      name: 'Maison',
      relativePath: 'house-kanto.json',
      groupId: 'kanto',
    ),
  ],
);

void main() {
  test(
    'rules follow one availability matrix for 2D, 3D and exterior decor',
    () {
      const rules = [
        'map.zones',
        'map.collisions',
        'map.warps',
        'map.connections',
        'map.spawn',
        'map.story-zone',
      ];
      Map<String, bool> row(MapCommandContext context) => {
        for (final id in rules) id: mapCommandUnavailable(id, context) == null,
      };
      expect(row(const MapCommandContext(storyAvailable: true)), {
        'map.zones': true,
        'map.collisions': true,
        'map.warps': true,
        'map.connections': true,
        'map.spawn': true,
        'map.story-zone': true,
      });
      expect(
        row(const MapCommandContext(spatial: true, storyAvailable: true)),
        {
          'map.zones': false,
          'map.collisions': true,
          'map.warps': true,
          'map.connections': true,
          'map.spawn': true,
          'map.story-zone': false,
        },
      );
      expect(
        row(const MapCommandContext(exterior: true, storyAvailable: true))
            .values
            .every((available) => !available),
        isTrue,
      );
    },
  );

  test('destinations are searchable by folder and keep homonyms apart', () {
    final project = _catalogue();
    final all = mapDestinationChoices(project, excludeMapId: 'a');
    expect(all.map((choice) => choice.map.id), isNot(contains('a')));
    final houses = all.where((choice) => choice.map.name == 'Maison').toList();
    expect(houses.map((choice) => choice.folderPath).toSet(), {
      'Johto / Bourg Géon',
      'Kanto',
    });
    expect(
      mapDestinationChoices(
        project,
        excludeMapId: 'a',
        query: 'bourg geon',
      ).map((choice) => choice.map.id),
      ['house-geon'],
    );
    expect(
      mapDestinationChoices(
        project,
        excludeMapId: 'a',
        query: 'kanto maison',
      ).map((choice) => choice.map.id),
      ['house-kanto'],
    );
  });

  testWidgets(
    'a deleted destination keeps its reference until another map is chosen',
    (tester) async {
      final h = MapSelectionHarness.of(_catalogue());
      addTearDown(h.dispose);
      h.document.commit(
        addWarpToMap(
          h.document.current,
          warp: const MapWarp(
            id: 'door',
            pos: GridPos(x: 1, y: 1),
            targetMapId: 'ghost',
            targetPos: GridPos(x: 4, y: 5),
          ),
        ),
      );
      final commands = WarpEditingCommands(h.document, h.project);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SingleChildScrollView(
                child: MapWarpInspector(
                  document: h.document,
                  project: h.project,
                  warp: commands.selected('door')!,
                  onChanged: () => setState(() {}),
                  onDeleted: () {},
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('warp-destination-problem')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Référence conservée : ghost'),
        findsOneWidget,
      );
      expect(commands.selected('door')!.targetMapId, 'ghost');

      await tester.tap(find.byKey(const ValueKey('warp-destination-search')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('map-destination-search-field')),
        'bourg geon',
      );
      await tester.pump();
      expect(find.text('Johto / Bourg Géon'), findsOneWidget);
      expect(find.text('Kanto'), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('map-destination-house-geon')),
      );
      await tester.pumpAndSettle();

      final door = commands.selected('door')!;
      expect(door.targetMapId, 'house-geon');
      expect(door.targetPos, const GridPos(x: 4, y: 5));
      expect(
        find.byKey(const ValueKey('warp-destination-problem')),
        findsNothing,
      );
    },
  );

  MapData garden() => workspaceMap('b').copyWith(
    name: 'Jardin',
    entities: const [
      MapEntity(
        id: 'start',
        name: 'Départ',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 2, y: 3),
      ),
    ],
    warps: const [
      MapWarp(
        id: 'landing',
        pos: GridPos(x: 6, y: 7),
        targetMapId: 'b',
        targetPos: GridPos(x: 6, y: 7),
        triggerMode: MapWarpTriggerMode.sceneOnly,
      ),
      MapWarp(
        id: 'back',
        pos: GridPos(x: 9, y: 1),
        targetMapId: 'a',
        targetPos: GridPos(x: 1, y: 1),
      ),
      MapWarp(
        id: 'elsewhere',
        pos: GridPos(x: 4, y: 4),
        targetMapId: 'house-geon',
        targetPos: GridPos(x: 0, y: 0),
      ),
    ],
  );

  test('arrival points come from the destination map only', () {
    final choices = mapArrivalChoices(garden(), fromMapId: 'a');
    expect(choices.map((choice) => (choice.label, choice.pos)), [
      ('Départ du joueur', const GridPos(x: 2, y: 3)),
      ('Point d’arrivée', const GridPos(x: 6, y: 7)),
      ('Passage qui revient ici', const GridPos(x: 9, y: 1)),
    ]);
    expect(
      mapArrivalChoices(garden(), fromMapId: 'a', query: 'revient'),
      hasLength(1),
    );
    expect(mapArrivalProblem(garden(), const GridPos(x: 3, y: 3)), isNull);
    expect(
      mapArrivalProblem(garden(), const GridPos(x: 30, y: 2)),
      contains('hors de « Jardin » (20 × 16)'),
    );
  });

  testWidgets('the inspector picks an arrival point reading one map', (
    tester,
  ) async {
    final h = MapSelectionHarness.of(_catalogue());
    addTearDown(h.dispose);
    h.document.commit(
      addWarpToMap(
        h.document.current,
        warp: const MapWarp(
          id: 'door',
          pos: GridPos(x: 1, y: 1),
          targetMapId: 'b',
          targetPos: GridPos(x: 30, y: 2),
        ),
      ),
    );
    final commands = WarpEditingCommands(h.document, h.project);
    final loads = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: MapWarpInspector(
                document: h.document,
                project: h.project,
                warp: commands.selected('door')!,
                onChanged: () => setState(() {}),
                onDeleted: () {},
                loadDestination: (id) async {
                  loads.add(id);
                  return garden();
                },
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Arrivée : Jardin · case 30, 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('warp-arrival-picker')));
    await tester.pumpAndSettle();
    expect(loads, ['b']);
    expect(find.textContaining('hors de « Jardin »'), findsOneWidget);
    expect(commands.selected('door')!.targetPos, const GridPos(x: 30, y: 2));
    await tester.tap(find.byKey(const ValueKey('map-arrival-6-7')));
    await tester.pumpAndSettle();
    expect(commands.selected('door')!.targetPos, const GridPos(x: 6, y: 7));
    expect(commands.selected('door')!.targetMapId, 'b');
    expect(find.text('Arrivée : Jardin · case 6, 7'), findsOneWidget);
  });
}
