import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/narrative_event_source_dependency_guard.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_builder_v2_use_case.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_link_journal_models.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_authoring_sheets.dart';
import 'package:map_editor/src/theme/theme.dart';

void main() {
  test(
    'contact references protect the exact map and entity during authoring',
    () {
      const guard = NarrativeEventSourceDependencyGuard();
      final source = NarrativeEventSourceRef.entityBump('map', 'actor');
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: [
          NarrativeEventRecord.draft(
            NarrativeEventDraft(
              id: _eventId,
              name: 'Contact',
              source: source,
              conditions: const [],
              priority: 0,
              order: 0,
            ),
          ),
        ],
        legacyClaims: const [],
      );
      expect(
        guard
            .inspectEntityDelete(
              registry: registry,
              mapId: 'map',
              entityId: 'actor',
            )
            .isAllowed,
        isFalse,
      );
      expect(
        guard
            .inspectEntityDelete(
              registry: registry,
              mapId: 'other',
              entityId: 'actor',
            )
            .isAllowed,
        isTrue,
      );
      expect(
        guard
            .inspectEntityUpdate(
              registry: registry,
              mapId: 'map',
              current: _npc,
              next: _npc.copyWith(id: 'renamed'),
            )
            .isAllowed,
        isFalse,
      );
      expect(
        guard.inspectMapDelete(registry: registry, mapId: 'map').isAllowed,
        isFalse,
      );
    },
  );

  test('contact source cannot become a legacy physical-owner journal', () {
    final source = NarrativeEventSourceRef.entityBump('map', 'actor');
    expect(narrativeEventSpatialSourceMapId(source), isNull);
    expect(
      () => narrativeEventSpatialSourceOwnerId(source),
      throwsArgumentError,
    );
  });

  testWidgets(
    'legacy guided source sheet keeps contact separate and submits its exact identity',
    (tester) async {
      final catalog = buildNarrativeSpatialEventSourceCatalog(
        project: _project,
        maps: [_map],
      );
      final source = NarrativeEventSourceRef.entityBump('map', 'actor');
      final option = catalog.options.singleWhere((o) => o.source == source);
      expect(option.selectable, isTrue);
      final choices = eventBuilderV2SourceChoices(_snapshot(catalog));
      final selected = choices.singleWhere((choice) => choice.source == source);
      final interaction = choices.singleWhere(
        (choice) =>
            choice.source ==
            NarrativeEventSourceRef.entityInteract('map', 'actor'),
      );
      expect(selected.typeLabel, 'Contact du joueur');
      expect(selected.description, contains('marche contre'));
      expect(selected.id, isNot(interaction.id));
      NarrativeEventSourceRef? submitted;
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.light(),
          home: Scaffold(
            body: EventBuilderV2SourceSheet(
              snapshot: _snapshot(catalog),
              currentSource: source,
              onSubmit: (value) async {
                submitted = value;
                return 'Keep open for assertion';
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer le déclencheur'));
      await tester.pumpAndSettle();
      expect(submitted, source);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final entities in <List<MapEntity>>[
    [_npc.copyWith(blocksMovement: false)],
    [_npc, _npc],
    [
      const MapEntity(
        id: 'actor',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 1),
      ),
    ],
  ]) {
    test(
      'legacy catalog leaves unavailable contacts unselectable $entities',
      () {
        final options = buildNarrativeSpatialEventSourceCatalog(
          project: _project,
          maps: [_map.copyWith(entities: entities)],
        ).options;
        expect(
          options.where(
            (o) =>
                o.source?.kind == NarrativeEventSourceKind.entityBump &&
                o.selectable,
          ),
          isEmpty,
        );
      },
    );
  }
}

const _eventId = 'evt_00000000-0000-7000-8000-000000000777';
const _npc = MapEntity(
  id: 'actor',
  name: 'Original actor',
  kind: MapEntityKind.npc,
  pos: GridPos(x: 1, y: 1),
  npc: MapEntityNpcData(characterId: 'character'),
);
const _project = ProjectManifest(
  name: 'Original contact QA',
  maps: [
    ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
  ],
  tilesets: [
    ProjectTilesetEntry(
      id: 'sheet',
      name: 'Original sheet',
      relativePath: 'assets/sheet.png',
    ),
  ],
  characters: [
    ProjectCharacterEntry(
      id: 'character',
      name: 'Original character',
      tilesetId: 'sheet',
    ),
  ],
);
final _map = MapData(
  id: 'map',
  name: 'Map',
  size: const GridSize(width: 4, height: 4),
  entities: [_npc],
);
NarrativeEventBuilderV2EditorSnapshot _snapshot(
  NarrativeSpatialEventSourceCatalog catalog,
) => NarrativeEventBuilderV2EditorSnapshot(
  projectRevision: 'revision',
  record: NarrativeEventRecord.draft(
    NarrativeEventDraft(
      id: _eventId,
      name: 'Contact',
      source: NarrativeEventSourceRef.mapEnter('map'),
      conditions: const [],
      priority: 0,
      order: 0,
    ),
  ),
  spatialSources: catalog.options,
  outcomeSources: const [],
  scenes: const [],
  facts: const [],
  events: const [],
);
