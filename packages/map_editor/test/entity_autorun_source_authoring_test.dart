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
    'automatic references protect the exact map and entity during authoring',
    () {
      const guard = NarrativeEventSourceDependencyGuard();
      final source = NarrativeEventSourceRef.entityAutorun('map', 'actor');
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: [
          NarrativeEventRecord.draft(
            NarrativeEventDraft(
              id: _eventId,
              name: 'Automatic',
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
              current: _owner,
              next: _owner.copyWith(id: 'renamed'),
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

  test('automatic source cannot become a legacy physical-owner journal', () {
    final source = NarrativeEventSourceRef.entityAutorun('map', 'actor');
    expect(narrativeEventSpatialSourceMapId(source), isNull);
    expect(
      () => narrativeEventSpatialSourceOwnerId(source),
      throwsArgumentError,
    );
  });

  test(
    'automatic history blocks removal and a spatial-only map conversion',
    () {
      const guard = NarrativeEventSourceDependencyGuard();
      final source = NarrativeEventSourceRef.entityAutorun('map', 'actor');
      for (final candidate in [
        _map.copyWith(entities: []),
        _map.copyWith(version: ProjectVersion.v9),
      ]) {
        expect(
          guard
              .inspectMapTransition(
                registry: _registry(source),
                current: _map,
                candidate: candidate,
                operation: 'history',
              )
              .isAllowed,
          isFalse,
        );
      }
    },
  );

  test(
    'automatic owner can keep its identity across a logical kind change',
    () {
      const guard = NarrativeEventSourceDependencyGuard();
      final decision = guard.inspectEntityUpdate(
        registry: _registry(
          NarrativeEventSourceRef.entityAutorun('map', 'actor'),
        ),
        mapId: 'map',
        current: _owner,
        next: _owner.copyWith(kind: MapEntityKind.spawn),
      );
      expect(decision.isAllowed, isTrue);
      expect(decision.requiresEventRevalidation, isTrue);
    },
  );

  testWidgets(
    'legacy guided source sheet keeps automatic separate and submits its exact identity',
    (tester) async {
      final catalog = buildNarrativeSpatialEventSourceCatalog(
        project: _project,
        maps: [_map],
      );
      final source = NarrativeEventSourceRef.entityAutorun('map', 'actor');
      final option = catalog.options.singleWhere((o) => o.source == source);
      expect(option.selectable, isTrue);
      final choices = eventBuilderV2SourceChoices(_snapshot(catalog));
      final selected = choices.singleWhere((choice) => choice.source == source);
      final interaction = choices.singleWhere(
        (choice) =>
            choice.source ==
            NarrativeEventSourceRef.entityInteract('map', 'actor'),
      );
      expect(selected.typeLabel, 'Automatique');
      expect(selected.description, contains('automatique'));
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
    [],
    [_owner, _owner],
  ]) {
    test(
      'legacy catalog refuses missing or ambiguous automatic owners $entities',
      () {
        final options = buildNarrativeSpatialEventSourceCatalog(
          project: _project,
          maps: [_map.copyWith(entities: entities)],
        ).options;
        expect(
          options.where(
            (option) =>
                option.source?.kind == NarrativeEventSourceKind.entityAutorun &&
                option.selectable,
          ),
          isEmpty,
        );
      },
    );
  }
}

const _eventId = 'evt_00000000-0000-7000-8000-000000000777';

NarrativeEventRegistry _registry(NarrativeEventSourceRef source) =>
    NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.legacyOnly,
      records: [
        NarrativeEventRecord.draft(
          NarrativeEventDraft(
            id: _eventId,
            name: 'Automatic',
            source: source,
            conditions: const [],
            priority: 0,
            order: 0,
          ),
        ),
      ],
      legacyClaims: const [],
    );
const _owner = MapEntity(
  id: 'actor',
  name: 'Original invisible owner',
  kind: MapEntityKind.custom,
  pos: GridPos(x: 1, y: 1),
  blocksMovement: false,
);
const _project = ProjectManifest(
  name: 'Original automatic QA',
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
);
final _map = MapData(
  id: 'map',
  name: 'Map',
  size: const GridSize(width: 4, height: 4),
  entities: [_owner],
);
NarrativeEventBuilderV2EditorSnapshot _snapshot(
  NarrativeSpatialEventSourceCatalog catalog,
) => NarrativeEventBuilderV2EditorSnapshot(
  projectRevision: 'revision',
  record: NarrativeEventRecord.draft(
    NarrativeEventDraft(
      id: _eventId,
      name: 'Automatic',
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
