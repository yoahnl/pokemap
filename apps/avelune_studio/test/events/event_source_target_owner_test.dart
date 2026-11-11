import 'package:avelune_studio/features/events/application/event_source_targets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test('a recorded entity or zone that the map no longer holds is reported as missing', () {
    expect(
      eventSourceTargetMissing(
        source: NarrativeEventSourceRef.entityInteract('station', 'chief'),
        map: _station,
        choosing: false,
      ),
      isFalse,
    );
    expect(
      eventSourceTargetMissing(
        source: NarrativeEventSourceRef.triggerEnter('station', 'platform'),
        map: _station,
        choosing: false,
      ),
      isFalse,
    );
    expect(
      eventSourceTargetMissing(
        source: NarrativeEventSourceRef.entityInteract('station', 'ghost'),
        map: _station,
        choosing: false,
      ),
      isTrue,
    );
    expect(
      eventSourceTargetMissing(
        source: NarrativeEventSourceRef.triggerEnter('station', 'ghost'),
        map: _station,
        choosing: false,
      ),
      isTrue,
    );
  });

  test('the missing target is not reported while choosing, for another map, or without a target', () {
    final ghost = NarrativeEventSourceRef.entityInteract('station', 'ghost');
    expect(
      eventSourceTargetMissing(source: ghost, map: _station, choosing: true),
      isFalse,
    );
    expect(
      eventSourceTargetMissing(
        source: NarrativeEventSourceRef.entityInteract('elsewhere', 'ghost'),
        map: _station,
        choosing: false,
      ),
      isFalse,
    );
    expect(
      eventSourceTargetMissing(source: null, map: _station, choosing: false),
      isFalse,
    );
    expect(
      eventSourceTargetMissing(
        source: NarrativeEventSourceRef.mapEnter('station'),
        map: _station,
        choosing: false,
      ),
      isFalse,
    );
  });

  test('a 3D model source is missing when the spatial scene lacks the instance', () {
    expect(
      eventSourceTargetMissing(
        source: NarrativeEventSourceRef.modelInteract('station', 'statue'),
        map: _station,
        choosing: false,
      ),
      isTrue,
    );
    expect(
      eventSourceTargetMissing(
        source: NarrativeEventSourceRef.modelInteract('station', 'statue'),
        map: _station,
        choosing: true,
      ),
      isFalse,
    );
  });

  test('only selectable spatial sources with an identity are offered while choosing', () {
    final chief = NarrativeEventSourceRef.entityInteract('station', 'chief');
    final map = NarrativeEventSourceRef.mapEnter('station');
    final catalog = NarrativeSpatialEventSourceCatalog(
      options: [
        _option(chief, NarrativeSpatialEventSourceAvailability.selectable),
        _option(map, NarrativeSpatialEventSourceAvailability.visibleButUnavailable),
      ],
      diagnostics: const [],
    );
    expect(selectableEventSources(catalog), {chief});
    expect(
      selectableEventSources(
        NarrativeSpatialEventSourceCatalog(options: const [], diagnostics: const []),
      ),
      isEmpty,
    );
  });

  test('only the kinds with a behaviour to explain carry a hint', () {
    expect(eventSourceKindHint(NarrativeEventSourceKind.triggerBump), contains('zone'));
    expect(
      eventSourceKindHint(NarrativeEventSourceKind.entityBump),
      contains('personnage bloquant'),
    );
    expect(
      eventSourceKindHint(NarrativeEventSourceKind.entityAutorun),
      contains('automatiquement'),
    );
    expect(eventSourceKindHint(NarrativeEventSourceKind.mapEnter), isNull);
    expect(eventSourceKindHint(null), isNull);
  });
}

NarrativeSpatialEventSourceOption _option(
  NarrativeEventSourceRef source,
  NarrativeSpatialEventSourceAvailability availability,
) => NarrativeSpatialEventSourceOption(
  source: source,
  humanLabel: 'Source',
  humanDescription: 'Source',
  mapId: 'station',
  mapLabel: 'Gare',
  sourceTypeLabel: source.kind.name,
  availability: availability,
  unavailableReason:
      availability == NarrativeSpatialEventSourceAvailability.selectable
      ? null
      : 'Source indisponible',
  origin: NarrativeSpatialEventSourceOrigin.canonical,
  debugTechnicalLabel: source.kind.name,
  geometry: source.kind == NarrativeEventSourceKind.mapEnter
      ? const NarrativeSpatialSourceGeometrySummary.mapWide()
      : const NarrativeSpatialSourceGeometrySummary.unavailable(),
  ownerKind: source.kind == NarrativeEventSourceKind.mapEnter
      ? NarrativeSpatialEventSourceOwnerKind.map
      : NarrativeSpatialEventSourceOwnerKind.entity,
  ownerId: source.kind == NarrativeEventSourceKind.mapEnter ? null : 'chief',
);

const _station = MapData(
  id: 'station',
  name: 'Gare',
  size: GridSize(width: 8, height: 8),
  layers: [],
  triggers: [
    MapTrigger(
      id: 'platform',
      name: 'Quai',
      type: TriggerType.event,
      area: MapRect(
        pos: GridPos(x: 3, y: 3),
        size: GridSize(width: 2, height: 2),
      ),
    ),
  ],
  entities: [
    MapEntity(
      id: 'chief',
      name: 'Chef',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 3, y: 3),
    ),
  ],
);
