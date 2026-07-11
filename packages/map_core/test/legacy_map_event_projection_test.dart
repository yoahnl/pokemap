import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NS-EVENT-V2 Phase C2 MapEvent read-only projection', () {
    test('explicit actor and object links are AUTO_SAFE and confirmed', () {
      for (final type in [MapEventType.actor, MapEventType.object]) {
        final event = _event(
          id: 'legacy_${type.name}',
          type: type,
          metadata: {
            LegacyMapEventCompatibilityMetadataKeys.entityId: 'entity_a',
          },
        );
        final map = _map(
          events: [event],
          entities: [_entity('entity_a', 1, 1)],
        );

        final projection = projectLegacyMapEventReadOnly(
          mapId: map.id,
          map: map,
          event: event,
          claimIndex: _emptyClaimIndex(),
        );

        expect(
            projection.classification, LegacyMigrationClassification.autoSafe);
        expect(projection.confirmedSource,
            NarrativeEventSourceRef.entityInteract(map.id, 'entity_a'));
        expect(projection.sourceCandidates.single.confirmed, isTrue);
      }
    });

    test('position-only evidence stays ASSISTED and never confirms a source',
        () {
      final event = _event(id: 'legacy_position_only');
      final map = _map(
        events: [event],
        entities: [_entity('entity_a', 1, 1)],
      );

      final projection = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: event,
        claimIndex: _emptyClaimIndex(),
      );

      expect(projection.classification, LegacyMigrationClassification.assisted);
      expect(projection.confirmedSource, isNull);
      expect(projection.sourceCandidates.single.source,
          NarrativeEventSourceRef.entityInteract(map.id, 'entity_a'));
      expect(projection.sourceCandidates.single.confirmed, isFalse);
      expect(
        projection.diagnostics.map((value) => value.code),
        contains(LegacyMapEventDiagnosticCodes.positionIsOnlyEvidence),
      );
    });

    test('ambiguous overlap and standalone Events remain BLOCKED', () {
      final event = _event(id: 'legacy_ambiguous');
      final ambiguousMap = _map(
        events: [event],
        entities: [
          _entity('entity_a', 1, 1),
          _entity('entity_b', 1, 1),
        ],
      );
      final ambiguous = projectLegacyMapEventReadOnly(
        mapId: ambiguousMap.id,
        map: ambiguousMap,
        event: event,
        claimIndex: _emptyClaimIndex(),
      );
      expect(ambiguous.classification, LegacyMigrationClassification.blocked);
      expect(ambiguous.sourceCandidates, hasLength(2));
      expect(ambiguous.confirmedSource, isNull);

      final standaloneMap = _map(events: [event]);
      final standalone = projectLegacyMapEventReadOnly(
        mapId: standaloneMap.id,
        map: standaloneMap,
        event: event,
        claimIndex: _emptyClaimIndex(),
      );
      expect(standalone.classification, LegacyMigrationClassification.blocked);
      expect(standalone.sourceCandidates, isEmpty);
    });

    test('trigger candidate stays LEGACY_ONLY until runtime parity is proven',
        () {
      final event = _event(
        id: 'legacy_trigger',
        type: MapEventType.triggerZone,
        metadata: {
          LegacyMapEventCompatibilityMetadataKeys.triggerId: 'trigger_a',
        },
      );
      final map = _map(
        events: [event],
        triggers: [_trigger('trigger_a', 1, 1)],
      );

      final projection = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: event,
        claimIndex: _emptyClaimIndex(),
      );

      expect(
          projection.classification, LegacyMigrationClassification.legacyOnly);
      expect(projection.confirmedSource,
          NarrativeEventSourceRef.triggerEnter(map.id, 'trigger_a'));
      expect(
        projection.diagnostics.map((value) => value.code),
        contains(LegacyMapEventDiagnosticCodes.triggerRuntimeParityUnproven),
      );
    });

    test('effect and opaque page payloads are UNSUPPORTED', () {
      final effect = _event(id: 'legacy_effect', type: MapEventType.effect);
      final script = _event(
        id: 'legacy_script',
        metadata: {
          LegacyMapEventCompatibilityMetadataKeys.entityId: 'entity_a',
        },
        pages: const [
          MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_a'),
            script: ScriptRef(scriptId: 'opaque_script'),
            message: 'legacy message',
          ),
        ],
      );
      final map = _map(
        events: [effect, script],
        entities: [_entity('entity_a', 1, 1)],
      );

      final effectProjection = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: effect,
        claimIndex: _emptyClaimIndex(),
      );
      final scriptProjection = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: script,
        claimIndex: _emptyClaimIndex(),
      );
      expect(effectProjection.classification,
          LegacyMigrationClassification.unsupported);
      expect(scriptProjection.classification,
          LegacyMigrationClassification.unsupported);
      expect(scriptProjection.unconvertibleDataPaths,
          containsAll(['pages[0].script', 'pages[0].message']));
    });

    test('multi-page order is preserved and never flattened', () {
      final event = _event(
        id: 'legacy_pages',
        pages: const [
          MapEventPage(pageNumber: 30),
          MapEventPage(pageNumber: 20, isDisabled: true),
          MapEventPage(pageNumber: 10, isHidden: true),
        ],
      );
      final map = _map(events: [event]);

      final projection = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: event,
        claimIndex: _emptyClaimIndex(),
      );

      expect(projection.classification, LegacyMigrationClassification.blocked);
      expect(projection.pages.map((page) => page.pageNumber), [30, 20, 10]);
      expect(projection.pages[1].isDisabled, isTrue);
      expect(projection.pages[2].isHidden, isTrue);
      expect(projection.manualActions, isNotEmpty);
    });

    test('invalid map, layer, position, and broken explicit source block', () {
      final event = _event(
        id: 'legacy_invalid',
        metadata: {
          LegacyMapEventCompatibilityMetadataKeys.entityId: 'missing_entity',
        },
        position: const EventPosition(layerId: 'missing_layer', x: 99, y: 99),
      );
      final map = _map(events: [event]);
      final projection = projectLegacyMapEventReadOnly(
        mapId: 'different_map',
        map: map,
        event: event,
        claimIndex: _emptyClaimIndex(),
      );

      expect(projection.classification, LegacyMigrationClassification.blocked);
      expect(
        projection.diagnostics.map((value) => value.code),
        containsAll({
          LegacyMapEventDiagnosticCodes.mapIdentityMismatch,
          LegacyMapEventDiagnosticCodes.layerMissing,
          LegacyMapEventDiagnosticCodes.positionOutOfBounds,
          LegacyMapEventDiagnosticCodes.explicitSourceMissing,
        }),
      );
    });

    test('claim lookup distinguishes valid claim, tombstone, and absence', () {
      final event = _event(
        id: 'legacy_claimed',
        metadata: {
          LegacyMapEventCompatibilityMetadataKeys.entityId: 'entity_a',
        },
      );
      final map = _map(
        events: [event],
        entities: [_entity('entity_a', 1, 1)],
      );
      final source = NarrativeEventSourceRef.entityInteract(map.id, 'entity_a');
      final valid = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: event,
        claimIndex: _claimIndex(
          mapId: map.id,
          event: event,
          source: source,
          validTarget: true,
        ),
      );
      final tombstone = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: event,
        claimIndex: _claimIndex(
          mapId: map.id,
          event: event,
          source: source,
          validTarget: false,
        ),
      );
      final absent = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: event,
        claimIndex: _emptyClaimIndex(),
      );

      expect(valid.claimStatus, LegacyProjectionClaimStatus.valid);
      expect(valid.existingClaim, isNotNull);
      expect(tombstone.claimStatus, LegacyProjectionClaimStatus.invalid);
      expect(tombstone.existingClaim, isNull);
      expect(tombstone.classification, LegacyMigrationClassification.blocked);
      expect(absent.claimStatus, LegacyProjectionClaimStatus.absent);
    });

    test('ambiguous and unresolved linked references block AUTO_SAFE', () {
      final event = _event(
        id: 'legacy_reference_collision',
        metadata: {
          LegacyMapEventCompatibilityMetadataKeys.entityId: 'entity_a',
        },
      );
      final map = _map(
        events: [event],
        entities: [_entity('entity_a', 1, 1)],
      );
      final provenance = LegacySourceRef.mapEvent(map.id, event.id);
      LegacyMapEventProjection project(List<LegacySourceRef> candidates) {
        return projectLegacyMapEventReadOnly(
          mapId: map.id,
          map: map,
          event: event,
          claimIndex: _emptyClaimIndex(),
          linkedReferences: [
            LegacyEventReference(
              kind: LegacyEventReferenceKind.consumedEventState,
              path: 'save.consumedEventIds[0]',
              legacyEventId: event.id,
              candidateProvenances: candidates,
            ),
          ],
        );
      }

      final ambiguous = project([
        provenance,
        LegacySourceRef.mapEvent('map_b', event.id),
      ]);
      final unresolved = project(const []);
      expect(ambiguous.classification, LegacyMigrationClassification.blocked);
      expect(unresolved.classification, LegacyMigrationClassification.blocked);
      expect(
        ambiguous.diagnostics.map((value) => value.code),
        contains(LegacyMapEventDiagnosticCodes.ambiguousLinkedReference),
      );
      expect(
        unresolved.diagnostics.map((value) => value.code),
        contains(LegacyMapEventDiagnosticCodes.unresolvedLinkedReference),
      );
    });

    test('stale or source-contradictory claims become local tombstones', () {
      final original = _event(
        id: 'legacy_stale_claim',
        metadata: {
          LegacyMapEventCompatibilityMetadataKeys.entityId: 'entity_a',
        },
      );
      final changed = original.copyWith(title: 'Changed after claim');
      final map = _map(
        events: [changed],
        entities: [
          _entity('entity_a', 1, 1),
          _entity('entity_b', 2, 2),
        ],
      );
      final sourceA =
          NarrativeEventSourceRef.entityInteract(map.id, 'entity_a');
      final stale = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: changed,
        claimIndex: _claimIndex(
          mapId: map.id,
          event: original,
          source: sourceA,
          validTarget: true,
        ),
      );
      final contradictory = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: changed,
        claimIndex: _claimIndex(
          mapId: map.id,
          event: changed,
          source: NarrativeEventSourceRef.entityInteract(map.id, 'entity_b'),
          validTarget: true,
        ),
      );

      expect(stale.claimStatus, LegacyProjectionClaimStatus.invalid);
      expect(stale.existingClaim, isNull);
      expect(stale.classification, LegacyMigrationClassification.blocked);
      expect(
        stale.diagnostics.map((value) => value.code),
        contains(LegacyMapEventDiagnosticCodes.claimFingerprintStale),
      );
      expect(contradictory.claimStatus, LegacyProjectionClaimStatus.invalid);
      expect(contradictory.existingClaim, isNull);
      expect(
        contradictory.diagnostics.map((value) => value.code),
        contains(LegacyMapEventDiagnosticCodes.claimSourceMismatch),
      );
    });

    test('raw unknown data is preserved and blocks conversion', () {
      final event = _event(
        id: 'legacy_unknown',
        metadata: {
          LegacyMapEventCompatibilityMetadataKeys.entityId: 'entity_a',
        },
      );
      final map = _map(
        events: [event],
        entities: [_entity('entity_a', 1, 1)],
      );
      final raw = Map<String, Object?>.from(event.toJson())
        ..['futureBehavior'] = {
          'opcode': 91,
          'payload': [1, 2, 3],
        };

      final projection = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: event,
        rawEventJson: raw,
        claimIndex: _emptyClaimIndex(),
      );

      expect(projection.classification, LegacyMigrationClassification.blocked);
      expect(projection.preservedEventJson['futureBehavior'], isNotNull);
      expect(
        () => projection.preservedEventJson['mutate'] = true,
        throwsUnsupportedError,
      );

      final nestedRaw = Map<String, Object?>.from(
        jsonDecode(jsonEncode(event.toJson())) as Map,
      );
      final rawPages = nestedRaw['pages']! as List;
      final rawPage = rawPages.single as Map;
      final rawScene = rawPage['sceneTarget'] as Map;
      rawScene['futureField'] = {'nested': true};
      final nestedProjection = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: event,
        rawEventJson: nestedRaw,
        claimIndex: _emptyClaimIndex(),
      );
      expect(
        nestedProjection.unconvertibleDataPaths,
        contains('event.pages[0].sceneTarget.futureField'),
      );
      expect(nestedProjection.classification,
          LegacyMigrationClassification.blocked);
    });

    test('sprite payload and non-exact metadata cannot remain AUTO_SAFE', () {
      final sprite = _event(
        id: 'legacy_sprite',
        metadata: {
          LegacyMapEventCompatibilityMetadataKeys.entityId: 'entity_a',
        },
        pages: const [
          MapEventPage(
            pageNumber: 0,
            spriteId: 'legacy_sprite_asset',
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_a'),
          ),
        ],
      );
      final spaced = _event(
        id: 'legacy_spaced_source',
        metadata: {
          LegacyMapEventCompatibilityMetadataKeys.entityId: ' entity_a ',
        },
      );
      final map = _map(
        events: [sprite, spaced],
        entities: [_entity('entity_a', 1, 1)],
      );
      final spriteProjection = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: sprite,
        claimIndex: _emptyClaimIndex(),
      );
      final spacedProjection = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: spaced,
        claimIndex: _emptyClaimIndex(),
      );

      expect(spriteProjection.classification,
          LegacyMigrationClassification.assisted);
      expect(spriteProjection.unconvertibleDataPaths,
          contains('pages[0].spriteId'));
      expect(spacedProjection.classification,
          LegacyMigrationClassification.blocked);
      expect(spacedProjection.confirmedSource, isNull);
    });

    test('projection is immutable deterministic and never mutates inputs', () {
      final event = _event(id: 'legacy_deterministic');
      final map = _map(
        events: [event],
        entities: [_entity('entity_a', 1, 1)],
      );
      final reference = LegacyEventReference(
        kind: LegacyEventReferenceKind.scriptCondition,
        path: 'maps.map_a.events.legacy_deterministic.pages[0].condition',
        legacyEventId: event.id,
        candidateProvenances: [LegacySourceRef.mapEvent(map.id, event.id)],
      );
      final before = canonicalizeNarrativeEventJson({
        'map': jsonDecode(jsonEncode(map.toJson())),
        'event': jsonDecode(jsonEncode(event.toJson())),
      });

      LegacyMapEventProjection run() => projectLegacyMapEventReadOnly(
            mapId: map.id,
            map: map,
            event: event,
            linkedReferences: [reference],
            claimIndex: _emptyClaimIndex(),
          );
      final first = run();
      final second = run();

      expect(canonicalizeNarrativeEventJson(first.toJson()),
          canonicalizeNarrativeEventJson(second.toJson()));
      expect(
        canonicalizeNarrativeEventJson({
          'map': jsonDecode(jsonEncode(map.toJson())),
          'event': jsonDecode(jsonEncode(event.toJson())),
        }),
        before,
      );
      expect(() => first.pages.add(first.pages.single), throwsUnsupportedError);
      expect(() => first.linkedReferences.clear(), throwsUnsupportedError);
      expect(() => first.diagnostics.clear(), throwsUnsupportedError);

      final callerRaw = <String, Object?>{
        'nested': <Object?>[1],
      };
      final manuallyBuilt = LegacyMapEventProjection(
        provenance: first.provenance,
        classification: first.classification,
        claimStatus: first.claimStatus,
        existingClaim: first.existingClaim,
        sourceFingerprint: first.sourceFingerprint,
        sourceCandidates: first.sourceCandidates,
        pages: first.pages,
        preservedEventJson: callerRaw,
        unconvertibleDataPaths: first.unconvertibleDataPaths,
        linkedReferences: first.linkedReferences,
        diagnostics: first.diagnostics,
        manualActions: first.manualActions,
      );
      callerRaw['changed'] = true;
      (callerRaw['nested']! as List<Object?>).add(2);
      expect(manuallyBuilt.preservedEventJson, isNot(contains('changed')));
      expect(manuallyBuilt.preservedEventJson['nested'], [1]);
      expect(
        () => (manuallyBuilt.preservedEventJson['nested']! as List).add(3),
        throwsUnsupportedError,
      );
    });
  });
}

MapEventDefinition _event({
  required String id,
  MapEventType type = MapEventType.actor,
  Map<String, String> metadata = const {},
  EventPosition position = const EventPosition(layerId: 'events', x: 1, y: 1),
  List<MapEventPage> pages = const [
    MapEventPage(
      pageNumber: 0,
      sceneTarget: MapEventSceneTarget(sceneId: 'scene_a'),
    ),
  ],
}) {
  return MapEventDefinition(
    id: id,
    title: id,
    type: type,
    metadata: metadata,
    position: position,
    pages: pages,
  );
}

MapData _map({
  required List<MapEventDefinition> events,
  List<MapEntity> entities = const [],
  List<MapTrigger> triggers = const [],
}) {
  return MapData(
    id: 'map_a',
    name: 'Map A',
    size: const GridSize(width: 8, height: 8),
    layers: const [MapLayer.object(id: 'events', name: 'Events')],
    entities: entities,
    triggers: triggers,
    events: events,
  );
}

MapEntity _entity(String id, int x, int y) {
  return MapEntity(
    id: id,
    kind: MapEntityKind.custom,
    pos: GridPos(x: x, y: y),
  );
}

MapTrigger _trigger(String id, int x, int y) {
  return MapTrigger(
    id: id,
    type: TriggerType.event,
    area: MapRect(
      pos: GridPos(x: x, y: y),
      size: const GridSize(width: 1, height: 1),
    ),
  );
}

ValidatedLegacyClaimIndex _emptyClaimIndex() {
  return buildValidatedLegacyClaimIndex(
    NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.legacyOnly,
      records: const [],
      legacyClaims: const [],
    ),
  );
}

ValidatedLegacyClaimIndex _claimIndex({
  required String mapId,
  required MapEventDefinition event,
  required NarrativeEventSourceRef source,
  required bool validTarget,
}) {
  final provenance = LegacySourceRef.mapEvent(mapId, event.id);
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: computeMapEventSourceFingerprint(
      mapId: mapId,
      event: event,
    ),
  );
  final cohortId = computeLegacySourceCohortId(source, [provenance]);
  const targetId = 'evt_018f1234-5678-7abc-8def-0123456789ab';
  final claim = LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: [member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(cohortId, [member]),
    targetEventIds: const [targetId],
    migrationReceiptId: 'receipt_c2',
  );
  return buildValidatedLegacyClaimIndex(
    NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.legacyOnly,
      records: validTarget
          ? [
              NarrativeEventRecord.configuredStructurallyUnchecked(
                NarrativeEventDefinition(
                  id: targetId,
                  name: 'C2 target',
                  source: source,
                  conditions: const [],
                  sceneId: 'scene_a',
                  reusePolicy: NarrativeEventReusePolicy.oneShot,
                  priority: 0,
                  order: 0,
                ),
                enabled: false,
              ),
            ]
          : const [],
      legacyClaims: [claim],
    ),
  );
}
