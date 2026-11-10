import 'package:avelune_studio/features/pokemon/application/pokemon_combat_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_combat_port.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_combat_context_panel.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_combat_references.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  const pidgey = ProjectEncounterEntry(
    speciesId: 'pidgey',
    minLevel: 2,
    maxLevel: 4,
    weight: 10,
  );
  const unassigned = ProjectEncounterTable(
    id: 'route_grass',
    name: 'Herbes de la route',
    encounterKind: EncounterKind.walk,
    entries: [pidgey],
  );
  const invalid = ProjectEncounterTable(
    id: 'empty',
    name: 'Table vide',
    encounterKind: EncounterKind.walk,
    entries: [],
  );
  const zoned = ProjectEncounterTable(
    id: 'cave',
    name: 'Grotte',
    encounterKind: EncounterKind.walk,
    entries: [pidgey],
  );
  const headbutt = ProjectEncounterTable(
    id: 'trees',
    name: 'Arbres',
    encounterKind: EncounterKind.headbutt,
    entries: [pidgey],
  );
  const trainer = ProjectTrainerEntry(
    id: 'youngster',
    name: 'Gamin',
    trainerClass: 'Gamin',
    team: [
      ProjectTrainerPokemonEntry(
        speciesId: 'pidgey',
        level: 5,
        moves: ['tackle'],
      ),
    ],
  );
  final map = MapData(
    id: 'route',
    name: 'Route 1',
    size: const GridSize(width: 10, height: 10),
    layers: const [],
    gameplayZones: const [
      MapGameplayZone(
        id: 'cave-zone',
        kind: GameplayZoneKind.encounter,
        area: MapRect(
          pos: GridPos(x: 0, y: 0),
          size: GridSize(width: 2, height: 2),
        ),
        encounter: EncounterZonePayload(
          encounterTableId: 'cave',
          encounterKind: EncounterKind.walk,
        ),
      ),
    ],
    entities: [
      MapEntity(
        id: 'tree',
        kind: MapEntityKind.custom,
        pos: const GridPos(x: 5, y: 5),
        interactiveEncounter: MapEntityInteractiveEncounterData(
          trigger: InteractiveEncounterTrigger.headbutt,
          encounterTableId: 'trees',
        ),
      ),
    ],
  );
  final snapshot = PokemonCombatSnapshot(
    project: ProjectManifest(
      name: 'Combats',
      maps: const [
        ProjectMapEntry(id: 'route', name: 'Route 1', relativePath: 'r.json'),
      ],
      tilesets: const [],
      encounterTables: const [unassigned, invalid, zoned, headbutt],
      trainers: const [trainer],
    ),
    maps: [map],
  );
  const index = PokemonWorkspaceIndex(
    enabled: true,
    entries: [
      PokemonSpeciesSummary(
        id: 'pidgey',
        name: 'Roucool',
        nationalDex: 16,
        generation: 1,
        types: ['normal', 'flying'],
        formIds: [],
        mediaRelativePath: '',
        enabled: true,
        relativePath: 'species/pidgey.json',
      ),
    ],
    types: [],
    items: {},
    moves: PokemonMovesCatalogView(entries: [], relativePath: 'moves.json'),
  );

  Future<PokemonCombatController> pump(
    WidgetTester tester,
    void Function(PokemonCombatController combat) select,
  ) async {
    final combat = PokemonCombatController(_Port(snapshot), changed: () {});
    await combat.load();
    select(combat);
    addTearDown(combat.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 900,
            child: PokemonCombatContextPanel(combat: combat, index: index),
          ),
        ),
      ),
    );
    return combat;
  }

  testWidgets('a valid table used nowhere warns apart from an invalid table', (
    tester,
  ) async {
    await pump(tester, (combat) => combat.selectTable(unassigned));
    expect(
      find.byKey(const ValueKey('combat-table-unassigned')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('combat-table-invalid')), findsNothing);

    await pump(tester, (combat) => combat.selectTable(invalid));
    expect(find.byKey(const ValueKey('combat-table-invalid')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('combat-table-invalid')),
        matching: find.textContaining('Ajoutez au moins une espèce'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a table used by a zone or a map object is not unassigned', (
    tester,
  ) async {
    await pump(tester, (combat) => combat.selectTable(zoned));
    expect(find.byKey(const ValueKey('combat-table-unassigned')), findsNothing);
    expect(find.textContaining('Route 1'), findsOneWidget);

    await pump(tester, (combat) => combat.selectTable(headbutt));
    expect(find.byKey(const ValueKey('combat-table-unassigned')), findsNothing);
    expect(find.textContaining('Route 1'), findsOneWidget);
  });

  testWidgets('a trainer placed nowhere says how to place it', (tester) async {
    final combat = PokemonCombatController(_Port(snapshot), changed: () {});
    await combat.load();
    addTearDown(combat.dispose);
    combat.setView(PokemonCombatView.trainers);
    combat.selectTrainer(trainer);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 900,
            child: PokemonCombatContextPanel(combat: combat, index: index),
          ),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('combat-trainer-unassigned')),
      findsOneWidget,
    );
  });

  test('trainer usages name the character and the battle block to open', () {
    final scene = SceneAsset(
      id: 'rival',
      name: 'Rival au pont',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'fight',
            kind: SceneNodeKind.battle,
            title: 'Combat du pont',
            payload: SceneBattlePayload(
              battleKind: 'trainer',
              trainerId: 'youngster',
            ),
          ),
        ],
        edges: const [],
      ),
    );
    final placed = PokemonCombatSnapshot(
      project: snapshot.project.copyWith(scenes: [scene]),
      maps: [
        map.copyWith(
          entities: [
            ...map.entities,
            const MapEntity(
              id: 'kid',
              name: 'Gamin du pont',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 1, y: 1),
              npc: MapEntityNpcData(characterId: 'kid', trainerId: 'youngster'),
            ),
          ],
        ),
      ],
    );
    final usages = combatUsages(placed, trainerId: 'youngster');
    expect(
      usages.map((usage) => (usage.kind, usage.id, usage.detailId)),
      [('map', 'route', 'kid'), ('scene', 'rival', 'fight')],
    );
    expect(usages.map((usage) => usage.label), [
      'Carte Route 1 · Gamin du pont',
      'Scène Rival au pont · Combat du pont',
    ]);
  });

  testWidgets('opening a trainer usage carries the block or the character', (
    tester,
  ) async {
    final scene = SceneAsset(
      id: 'rival',
      name: 'Rival au pont',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'fight',
            kind: SceneNodeKind.battle,
            payload: SceneBattlePayload(
              battleKind: 'trainer',
              trainerId: 'youngster',
            ),
          ),
        ],
        edges: const [],
      ),
    );
    final analysed = PokemonCombatSnapshot(
      project: snapshot.project.copyWith(scenes: [scene]),
      maps: [map],
    );
    final combat = PokemonCombatController(_Port(analysed), changed: () {});
    await combat.load();
    addTearDown(combat.dispose);
    combat.setView(PokemonCombatView.trainers);
    combat.selectTrainer(trainer);
    final opened = <(String, String, String?)>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 900,
            child: PokemonCombatContextPanel(
              combat: combat,
              index: index,
              onOpenReference: (kind, id, [detailId]) async =>
                  opened.add((kind, id, detailId)),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Scène Rival au pont · bloc Combat'));
    await tester.pump();
    expect(opened, [('scene', 'rival', 'fight')]);
  });

  test('table references include map objects that roll the table', () {
    expect(combatTableReferences(snapshot, headbutt), ['Carte Route 1']);
    expect(combatTableReferences(snapshot, unassigned), isEmpty);
  });
}

class _Port implements PokemonCombatPort {
  _Port(this.snapshot);
  final PokemonCombatSnapshot snapshot;
  @override
  Future<PokemonCombatSnapshot> load() async => snapshot;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
