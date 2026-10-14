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
    'trigger contact references protect the exact map and entity during authoring',
    () {
      const guard = NarrativeEventSourceDependencyGuard();
      final source = NarrativeEventSourceRef.triggerBump('map', 'actor');
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
            .inspectTriggerDelete(
              registry: registry,
              mapId: 'map',
              triggerId: 'actor',
            )
            .isAllowed,
        isFalse,
      );
      expect(
        guard
            .inspectTriggerDelete(
              registry: registry,
              mapId: 'other',
              triggerId: 'actor',
            )
            .isAllowed,
        isTrue,
      );
      expect(
        guard
            .inspectTriggerUpdate(
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
      expect(
        guard
            .inspectTriggerUpdate(
              registry: registry,
              mapId: 'map',
              current: _owner,
              next: _owner.copyWith(type: TriggerType.custom),
            )
            .isAllowed,
        isFalse,
      );
      expect(
        guard
            .inspectMapTransition(
              registry: registry,
              current: _map,
              operation: 'dimension',
              candidate: _map.copyWith(version: ProjectVersion.v9),
            )
            .isAllowed,
        isFalse,
      );
      expect(
        guard
            .inspectMapTransition(
              registry: registry,
              current: _map,
              operation: 'type',
              candidate: _map.copyWith(
                triggers: [_owner.copyWith(type: TriggerType.custom)],
              ),
            )
            .isAllowed,
        isFalse,
      );
    },
  );
  test(
    'trigger contact source cannot become a legacy physical-owner journal',
    () {
      final source = NarrativeEventSourceRef.triggerBump('map', 'actor');
      expect(narrativeEventSpatialSourceMapId(source), isNull);
      expect(
        () => narrativeEventSpatialSourceOwnerId(source),
        throwsArgumentError,
      );
    },
  );
  testWidgets(
    'legacy guided source sheet keeps trigger contact separate and submits its exact identity',
    (tester) async {
      final catalog = buildNarrativeSpatialEventSourceCatalog(
        project: _project,
        maps: [_map],
      );
      final source = NarrativeEventSourceRef.triggerBump('map', 'actor');
      final option = catalog.options.singleWhere((o) => o.source == source);
      expect(option.selectable, isTrue);
      final choices = eventBuilderV2SourceChoices(_snapshot(catalog));
      final selected = choices.singleWhere((choice) => choice.source == source);
      final interaction = choices.singleWhere(
        (choice) =>
            choice.source ==
            NarrativeEventSourceRef.triggerEnter('map', 'actor'),
      );
      expect(selected.typeLabel, 'Contact de zone');
      expect(selected.description, contains('bloquée'));
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
}

const _eventId = 'evt_00000000-0000-7000-8000-000000000777';

const _owner = MapTrigger(
  id: 'actor',
  name: 'Exit',
  type: TriggerType.event,
  area: MapRect(pos: GridPos(x: 1, y: 1), size: GridSize(width: 1, height: 1)),
);
const _project = ProjectManifest(
  name: 'Original trigger contact QA',
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
  triggers: [_owner],
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
