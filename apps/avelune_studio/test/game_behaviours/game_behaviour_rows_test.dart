import 'package:avelune_studio/features/events/application/behaviour/behaviour_reuse.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_groups.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_rows.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_summary.dart';
import 'package:avelune_studio/features/game_memory/domain/map_directory.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'game_behaviour_fakes.dart';

const _maps = [
  ProjectMapEntry(id: 'town', name: 'Bourg', relativePath: 'maps/town.json'),
  ProjectMapEntry(id: 'cave', name: 'Grotte', relativePath: 'maps/cave.json'),
];

NarrativeTitle _title(int index, [String title = '']) =>
    NarrativeTitle(id: behaviourId(index), title: title);

void main() {
  final records = [
    behaviour(
      1,
      'Parler à Léo',
      source: NarrativeEventSourceRef.entityInteract('town', 'npc'),
      enabled: true,
    ),
    behaviour(
      2,
      'Entrer',
      source: NarrativeEventSourceRef.triggerEnter('cave', 'door'),
      enabled: false,
    ),
    behaviour(3, 'Brouillon sans carte'),
    behaviour(
      4,
      'Carte perdue',
      source: NarrativeEventSourceRef.mapEnter('gone'),
      enabled: true,
    ),
    behaviour(
      5,
      'Supprimé ailleurs',
      source: NarrativeEventSourceRef.mapEnter('town'),
      enabled: true,
    ),
    behaviour(
      6,
      'Nouveau',
      source: NarrativeEventSourceRef.mapEnter('cave'),
      enabled: true,
    ),
  ];
  final source = FakeBehaviourSource(
    records: records,
    maps: _maps,
    touchedIds: {behaviourId(6)},
    names: {'town/entity:npc': 'Léo'},
  );
  final saved = [
    for (final index in [1, 2, 3, 4]) _title(index),
    _title(7, 'Créé par le MCP'),
  ];

  test('every saved and drafted behaviour becomes a named row', () {
    final rows = gameBehaviourRows(saved: saved, source: source);
    GameBehaviourRow row(int index) =>
        rows.singleWhere((row) => row.id == behaviourId(index));

    expect(rows, hasLength(7));
    expect(
      (row(1).name, row(1).mapName, row(1).elementName, row(1).target),
      ('Parler à Léo', 'Bourg', 'Léo', MapStoryElementTarget.entity),
    );
    expect((row(2).disabled, row(2).toRepair), (true, false));
    expect((row(3).withoutMap, row(3).toRepair), (true, true));
    expect((row(4).mapMissing, row(4).toRepair), (true, true));
    expect(row(5).presence, GameBehaviourPresence.deletedElsewhere);
    expect(
      (row(6).presence, row(6).unsaved),
      (GameBehaviourPresence.known, true),
    );
    expect(
      (row(7).name, row(7).presence),
      ('Créé par le MCP', GameBehaviourPresence.notLoaded),
    );
    expect(row(7).withoutMap, isFalse);
  });

  test('search reads names, maps and element labels; filters combine', () {
    final rows = gameBehaviourRows(saved: saved, source: source);
    List<int> ids(List<GameBehaviourRow> rows) => [
      for (final row in rows) int.parse(row.id.substring(row.id.length - 2)),
    ];

    expect(ids(filterGameBehaviours(rows, query: 'grotte')), [2, 6]);
    expect(
      ids(
        filterGameBehaviours(
          rows,
          query: 'léo',
          elementLabel: (row) => row.elementName ?? '',
        ),
      ),
      [1],
    );
    expect(
      ids(
        filterGameBehaviours(rows, filters: {GameBehaviourFilter.withoutMap}),
      ),
      [3],
    );
    expect(
      ids(filterGameBehaviours(rows, filters: {GameBehaviourFilter.toRepair})),
      [3, 4],
    );
    expect(
      ids(filterGameBehaviours(rows, filters: {GameBehaviourFilter.disabled})),
      [2],
    );
  });

  test('grouping by map follows the project order and isolates the rest', () {
    final groups = groupGameBehavioursByMap(
      gameBehaviourRows(saved: saved, source: source),
      ['town', 'cave'],
    );

    expect(
      [
        for (final group in groups)
          (group.kind, group.label, group.rows.length),
      ],
      [
        (GameBehaviourGroupKind.map, 'Bourg', 2),
        (GameBehaviourGroupKind.map, 'Grotte', 2),
        (GameBehaviourGroupKind.missingMap, null, 1),
        (GameBehaviourGroupKind.withoutMap, null, 1),
        (GameBehaviourGroupKind.notLoaded, null, 1),
      ],
    );
  });

  test('grouping by fact uses the behaviour and its scene usages', () {
    final rows = gameBehaviourRows(
      saved: saved,
      source: FakeBehaviourSource(
        records: [
          behaviour(
            1,
            'A',
            source: NarrativeEventSourceRef.mapEnter('town'),
            enabled: true,
            sceneId: 'gate',
          ),
          behaviour(
            2,
            'B',
            source: NarrativeEventSourceRef.mapEnter('town'),
            enabled: true,
            sceneId: 'other',
          ),
          behaviour(3, 'C'),
        ],
        maps: _maps,
      ),
    );
    final groups = groupGameBehavioursByFact(
      rows,
      facts: const [
        NarrativeTitle(id: 'met', title: 'Rencontre'),
        NarrativeTitle(id: 'idle', title: 'Inutile'),
      ],
      usages: {
        'met': NarrativeUsages(
          owners: [
            NarrativeOwner(
              kind: NarrativeOwnerKind.event,
              id: behaviourId(2),
              role: NarrativeFactRole.read,
            ),
            const NarrativeOwner(
              kind: NarrativeOwnerKind.scene,
              id: 'gate',
              role: NarrativeFactRole.write,
            ),
          ],
          notCovered: const [],
        ),
      },
    );

    expect(groups.map((group) => (group.kind, group.label)), [
      (GameBehaviourGroupKind.fact, 'Rencontre'),
      (GameBehaviourGroupKind.withoutFact, null),
    ]);
    expect(groups.first.rows.map((row) => row.name), ['A', 'B']);
    expect(groups.last.rows.map((row) => row.name), [
      'C',
      '',
      'Créé par le MCP',
    ]);
  });

  test('the summary reuses the behaviour readers of the map builder', () {
    final record = behaviour(
      1,
      'Parler',
      source: NarrativeEventSourceRef.entityInteract('town', 'npc'),
      enabled: true,
      sceneId: 'gate',
      conditions: [NarrativeEventCondition.fact('met', true)],
    );
    final summary = summarizeGameBehaviour(
      record,
      (id) => id == 'gate'
          ? SceneAsset(
              id: 'gate',
              name: 'Porte',
              graph: SceneGraph(
                startNodeId: 'start',
                nodes: [SceneNode(id: 'start', kind: SceneNodeKind.start)],
                edges: const [],
              ),
            )
          : null,
    );

    expect(summary.when, NarrativeEventSourceKind.entityInteract);
    expect(summary.conditions.items, hasLength(1));
    expect(
      (summary.scene?.name, summary.sceneChosen, summary.line),
      ('Porte', true, false),
    );
    expect(summary.after, BehaviourAfter.eachTime);
    expect(
      summarizeGameBehaviour(behaviour(2, 'X'), (_) => null).sceneChosen,
      isFalse,
    );
  });

  test('the open map wins over the saved directory of map elements', () {
    final talks = [
      behaviour(
        1,
        'Ajouté sans enregistrer',
        source: NarrativeEventSourceRef.entityInteract('town', 'fresh'),
        enabled: true,
      ),
      behaviour(
        2,
        'Retiré sans enregistrer',
        source: NarrativeEventSourceRef.entityInteract('town', 'npc'),
        enabled: true,
      ),
      behaviour(
        3,
        'Sur la carte entière',
        source: NarrativeEventSourceRef.mapEnter('town'),
        enabled: true,
      ),
    ];
    final rows = gameBehaviourRows(
      saved: [_title(1), _title(2), _title(3)],
      source: FakeBehaviourSource(
        records: talks,
        maps: _maps,
        present: {'town/entity:fresh': true, 'town/entity:npc': false},
      ),
      directory: {
        'town': MapDirectoryPage(
          mapId: 'town',
          name: 'Bourg',
          elements: const [
            MapDirectoryElement(
              id: 'npc',
              kind: MapDirectoryElementKind.entity,
              name: 'Léo',
            ),
          ],
        ),
      },
    );

    expect([for (final row in rows) row.elementMissing], [false, true, false]);
    expect(rows[1].elementName, 'Léo');
  });
}
