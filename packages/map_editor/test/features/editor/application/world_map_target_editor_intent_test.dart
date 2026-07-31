import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/map_canvas_object_hit_test.dart';
import 'package:map_editor/src/features/editor/application/world_map_target_editor_intent.dart';

void main() {
  const resolver = WorldMapTargetEditorIntentResolver();
  const eventTarget = MapCanvasObjectTarget(
    kind: MapCanvasObjectKind.mapEvent,
    id: 'event',
    layerId: 'events',
    anchor: GridPos(x: 1, y: 1),
    size: GridSize(width: 1, height: 1),
  );

  group('WorldMapTargetEditorIntentResolver MapEvent', () {
    test('uses the legacy editor without a registry or in legacyOnly', () {
      for (final project in <ProjectManifest>[
        _projectWithoutRegistry,
        _project(EventSystemMode.legacyOnly),
      ]) {
        final resolution = resolver.resolve(
          target: eventTarget,
          map: _map,
          project: project,
          eventBuilderReadModel: null,
        );

        expect(
          resolution,
          isA<WorldMapTargetEditorReady>().having(
            (ready) => ready.intent,
            'intent',
            isA<OpenLegacyMapEventEditorIntent>().having(
              (intent) => intent.eventId,
              'eventId',
              'event',
            ),
          ),
        );
      }
    });

    test('blocks dualRead when the canonical read model is unavailable', () {
      final resolution = resolver.resolve(
        target: eventTarget,
        map: _map,
        project: _project(EventSystemMode.dualRead),
        eventBuilderReadModel: null,
      );

      expect(
        resolution,
        isA<WorldMapTargetEditorBlocked>()
            .having(
              (blocked) => blocked.code,
              'code',
              WorldMapTargetEditorBlockCode.eventBuilderReadModelUnavailable,
            )
            .having(
              (blocked) => blocked.reason,
              'reason',
              contains('Event Builder'),
            ),
      );
    });

    test('blocks zero compatibility matches without guessing a V2 id', () {
      final resolution = resolver.resolve(
        target: eventTarget,
        map: _map,
        project: _project(EventSystemMode.dualRead),
        eventBuilderReadModel: _readModel(
          EventSystemMode.dualRead,
          maps: const <MapData>[],
        ),
      );

      expect(
        resolution,
        isA<WorldMapTargetEditorBlocked>().having(
          (blocked) => blocked.code,
          'code',
          WorldMapTargetEditorBlockCode.missingCompatibilityEntry,
        ),
      );
    });

    test('opens the one canonical read-only compatibility summary', () {
      for (final mode in <EventSystemMode>[
        EventSystemMode.dualRead,
        EventSystemMode.v2Only,
      ]) {
        final readModel = _readModel(mode);
        final expected = readModel.events.singleWhere(
          (summary) => summary.compatibilityOrigins.any(
            (origin) =>
                origin.provenance == LegacySourceRef.mapEvent('map', 'event'),
          ),
        );

        final resolution = resolver.resolve(
          target: eventTarget,
          map: _map,
          project: _project(mode),
          eventBuilderReadModel: readModel,
        );

        expect(expected.readOnly, isTrue);
        expect(
          resolution,
          isA<WorldMapTargetEditorReady>().having(
            (ready) => ready.intent,
            'intent',
            isA<OpenNarrativeCompatibilityEventIntent>().having(
              (intent) => intent.stableKey,
              'stableKey',
              expected.stableKey,
            ),
          ),
        );
      }
    });

    test('blocks multiple compatibility matches deterministically', () {
      final base = _readModel(EventSystemMode.dualRead);
      final summary = base.events.singleWhere(
        (entry) => entry.compatibilityOrigins.isNotEmpty,
      );
      final readModel = NarrativeEventBuilderProjectReadModel(
        groups: <NarrativeEventProjectGroup>[
          _groupWith(<NarrativeEventProjectSummary>[
            summary,
            _copySummary(summary, stableKey: '${summary.stableKey}:duplicate'),
          ]),
        ],
        diagnostics: const <NarrativeEventProjectReadDiagnostic>[],
      );

      final resolution = resolver.resolve(
        target: eventTarget,
        map: _map,
        project: _project(EventSystemMode.dualRead),
        eventBuilderReadModel: readModel,
      );

      expect(
        resolution,
        isA<WorldMapTargetEditorBlocked>().having(
          (blocked) => blocked.code,
          'code',
          WorldMapTargetEditorBlockCode.ambiguousCompatibilityEntry,
        ),
      );
    });

    test('blocks writable or non-canonical compatibility summaries', () {
      final base = _readModel(EventSystemMode.dualRead);
      final summary = base.events.singleWhere(
        (entry) => entry.compatibilityOrigins.isNotEmpty,
      );
      final malformed = <NarrativeEventProjectSummary>[
        _copySummary(summary, readOnly: false),
        _copySummary(summary, stableKey: 'legacy:wrong-key'),
      ];

      for (final candidate in malformed) {
        final resolution = resolver.resolve(
          target: eventTarget,
          map: _map,
          project: _project(EventSystemMode.dualRead),
          eventBuilderReadModel: NarrativeEventBuilderProjectReadModel(
            groups: <NarrativeEventProjectGroup>[
              _groupWith(<NarrativeEventProjectSummary>[candidate]),
            ],
            diagnostics: const <NarrativeEventProjectReadDiagnostic>[],
          ),
        );

        expect(
          resolution,
          isA<WorldMapTargetEditorBlocked>().having(
            (blocked) => blocked.code,
            'code',
            WorldMapTargetEditorBlockCode.invalidCompatibilityEntry,
          ),
        );
      }
    });
  });

  test('all non-event families focus the adaptive object inspector', () {
    for (final kind in MapCanvasObjectKind.values) {
      if (kind == MapCanvasObjectKind.mapEvent) {
        continue;
      }
      final target = MapCanvasObjectTarget(
        kind: kind,
        id: kind.name,
        anchor: const GridPos(x: 0, y: 0),
        size: const GridSize(width: 1, height: 1),
      );

      final resolution = resolver.resolve(
        target: target,
        map: _map,
        project: _projectWithoutRegistry,
        eventBuilderReadModel: null,
      );

      expect(
        resolution,
        isA<WorldMapTargetEditorReady>().having(
          (ready) => ready.intent,
          'intent',
          isA<FocusWorldMapObjectInspectorIntent>().having(
            (intent) => intent.target,
            'target',
            target,
          ),
        ),
      );
    }
  });
}

NarrativeEventBuilderProjectReadModel _readModel(
  EventSystemMode mode, {
  List<MapData> maps = const <MapData>[_map],
}) {
  return buildNarrativeEventBuilderProjectReadModel(
    project: _project(mode),
    maps: maps,
  );
}

NarrativeEventProjectGroup _groupWith(
  List<NarrativeEventProjectSummary> events,
) {
  return NarrativeEventProjectGroup(
    stableKey: 'legacy:compatibility',
    label: 'Compatibilité',
    kind: NarrativeEventProjectGroupKind.legacyCompatibility,
    events: events,
  );
}

NarrativeEventProjectSummary _copySummary(
  NarrativeEventProjectSummary source, {
  String? stableKey,
  bool? readOnly,
}) {
  return NarrativeEventProjectSummary(
    stableKey: stableKey ?? source.stableKey,
    eventId: source.eventId,
    title: source.title,
    origin: source.origin,
    readOnly: readOnly ?? source.readOnly,
    enabled: source.enabled,
    group: source.group,
    groupKey: source.groupKey,
    groupLabel: source.groupLabel,
    status: source.status,
    severity: source.severity,
    source: source.source,
    scene: source.scene,
    conditions: source.conditions,
    lifecycle: source.lifecycle,
    migration: source.migration,
    projection: source.projection,
    compatibilityOrigins: source.compatibilityOrigins,
    diagnostics: source.diagnostics,
    debug: source.debug,
  );
}

const _map = MapData(
  id: 'map',
  name: 'Map',
  version: ProjectVersion.v3,
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    ObjectLayer(id: 'events', name: 'Events'),
  ],
  events: <MapEventDefinition>[
    MapEventDefinition(
      id: 'event',
      pages: <MapEventPage>[
        MapEventPage(pageNumber: 0),
      ],
      position: EventPosition(layerId: 'events', x: 1, y: 1),
    ),
  ],
);

const _projectWithoutRegistry = ProjectManifest(
  name: 'Context intent',
  version: ProjectVersion.v3,
  maps: <ProjectMapEntry>[
    ProjectMapEntry(
      id: 'map',
      name: 'Map',
      relativePath: 'maps/map.json',
    ),
  ],
  tilesets: <ProjectTilesetEntry>[],
);

ProjectManifest _project(EventSystemMode mode) {
  return ProjectManifest(
    name: 'Context intent',
    version: ProjectVersion.v3,
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map',
        name: 'Map',
        relativePath: 'maps/map.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: mode,
      records: const <NarrativeEventRecord>[],
      legacyClaims: const <LegacySourceClaim>[],
    ),
  );
}
