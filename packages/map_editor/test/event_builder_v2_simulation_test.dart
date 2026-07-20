import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_builder_v2_use_case.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_simulation_sheet.dart';

const _eventId = 'evt_019abcde-0000-7000-8000-000000000001';
const _dependencyId = 'evt_019abcde-0000-7000-8000-000000000002';

void main() {
  testWidgets(
      'NSC-42 controls source facts and progress then explains authority trace',
      (tester) async {
    NarrativeEventSimulationInput? received;
    await tester.binding.setSurfaceSize(const Size(520, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: EventBuilderV2SimulationSheet(
            snapshot: _snapshot(),
            eventId: _eventId,
            onRun: (input) async {
              received = input;
              return _report(input);
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Même décision que le jeu'), findsOneWidget);
    expect(find.textContaining('(AND)'), findsOneWidget);
    expect(find.text('Port ouvert'), findsOneWidget);
    expect(find.text('Rencontre au port'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('event-builder-v2-simulation-fact-fact_open')),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-builder-v2-run-simulation')),
      240,
    );
    await tester.tap(
      find.byKey(const ValueKey('event-builder-v2-run-simulation')),
    );
    await tester.pumpAndSettle();

    expect(received, isNotNull);
    expect(received!.source, NarrativeEventSourceRef.mapEnter('map_port'));
    expect(received!.factValues['fact_open'], isTrue);
    expect(received!.consumedNarrativeEventIds, isEmpty);
    expect(
      find.byKey(const ValueKey('event-builder-v2-simulation-result')),
      findsOneWidget,
    );
    expect(find.text('Déclenchement accepté'), findsOneWidget);
    expect(find.textContaining('priorité 12 · ordre 2'), findsWidgets);
    expect(find.textContaining('Port ouvert : vrai, attendu vrai'),
        findsOneWidget);
    expect(find.text('Vraie'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

NarrativeEventBuilderV2EditorSnapshot _snapshot() {
  final source = NarrativeEventSourceRef.mapEnter('map_port');
  final target = _record(_eventId, 'Rencontre au port', source);
  final dependency = _record(
    _dependencyId,
    'Arrivée au port',
    NarrativeEventSourceRef.mapEnter('map_other'),
  );
  return NarrativeEventBuilderV2EditorSnapshot(
    projectRevision: 'revision',
    record: target,
    spatialSources: [
      NarrativeSpatialEventSourceOption(
        source: source,
        humanLabel: 'Entrée · Port Selbrume',
        humanDescription: 'Quand le joueur entre sur la map.',
        mapId: 'map_port',
        mapLabel: 'Port Selbrume',
        sourceTypeLabel: 'Entrée sur une map',
        availability: NarrativeSpatialEventSourceAvailability.selectable,
        origin: NarrativeSpatialEventSourceOrigin.canonical,
        debugTechnicalLabel: 'map_port',
        geometry: const NarrativeSpatialSourceGeometrySummary.mapWide(),
        ownerKind: NarrativeSpatialEventSourceOwnerKind.map,
      ),
    ],
    outcomeSources: const [],
    scenes: const [],
    facts: [
      NarrativeEventProjectFactEntry(
        NarrativeFactDefinition(
          id: 'fact_open',
          label: 'Port ouvert',
        ),
      ),
    ],
    events: [
      NarrativeEventProjectEventEntry(
        record: target,
        proposed: false,
        inDependencyCycle: false,
        contextuallyValid: true,
      ),
      NarrativeEventProjectEventEntry(
        record: dependency,
        proposed: false,
        inDependencyCycle: false,
        contextuallyValid: true,
      ),
    ],
  );
}

NarrativeEventRecord _record(
  String id,
  String name,
  NarrativeEventSourceRef source,
) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: name,
      source: source,
      conditions: [NarrativeEventCondition.fact('fact_open', true)],
      sceneId: 'scene_port',
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 12,
      order: 2,
    ),
    enabled: true,
  );
}

NarrativeEventSimulationReport _report(NarrativeEventSimulationInput input) {
  return NarrativeEventSimulationReport(
    status: NarrativeEventSimulationStatus.handled,
    targetEventId: _eventId,
    source: input.source,
    mode: EventSystemMode.v2Only,
    handledEventId: _eventId,
    sceneId: 'scene_port',
    legacyFallbackAllowed: false,
    reasons: const [],
    diagnostics: const [],
    candidates: [
      NarrativeEventSimulationCandidateTrace(
        eventId: _eventId,
        name: 'Rencontre au port',
        configured: true,
        enabled: true,
        sourceMatches: true,
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: 12,
        order: 2,
        selected: true,
        reasons: const [],
        conditions: [
          NarrativeEventSimulationConditionTrace(
            index: 0,
            kind: NarrativeEventSimulationConditionKind.fact,
            targetId: 'fact_open',
            expectedValue: true,
            actualValue: input.factValues['fact_open'],
            passed: input.factValues['fact_open'] == true,
            reason: null,
          ),
        ],
      ),
    ],
  );
}
