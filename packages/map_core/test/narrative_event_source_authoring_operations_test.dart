import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Narrative event source authoring operations', () {
    test('converts picker options into source drafts', () {
      final options = _eventSourceOptions();

      final mapEnter =
          createNarrativeScenarioAuthoringSourceDraftFromEventSourceOption(
        _bySourceKind(options, NarrativeEventSourceKind.mapEnter),
      );
      expect(mapEnter.kind, NarrativeScenarioAuthoringSourceKind.mapEnter);
      expect(mapEnter.mapId, 'p4_map');

      final triggerEnter =
          createNarrativeScenarioAuthoringSourceDraftFromEventSourceOption(
        _bySourceKind(options, NarrativeEventSourceKind.triggerEnter),
      );
      expect(
          triggerEnter.kind, NarrativeScenarioAuthoringSourceKind.triggerEnter);
      expect(triggerEnter.mapId, 'p4_map');
      expect(triggerEnter.triggerId, 'p4_trigger');

      final entityInteract =
          createNarrativeScenarioAuthoringSourceDraftFromEventSourceOption(
        _bySourceKind(options, NarrativeEventSourceKind.entityInteract),
      );
      expect(
        entityInteract.kind,
        NarrativeScenarioAuthoringSourceKind.entityInteract,
      );
      expect(entityInteract.mapId, 'p4_map');
      expect(entityInteract.entityId, 'p4_npc');

      final outcomeReceived =
          createNarrativeScenarioAuthoringSourceDraftFromEventSourceOption(
        _bySourceKind(options, NarrativeEventSourceKind.outcomeReceived),
      );
      expect(
        outcomeReceived.kind,
        NarrativeScenarioAuthoringSourceKind.outcomeReceived,
      );
      expect(outcomeReceived.outcomeId, 'p4.outcome.ready');
    });

    test('calculates stable source ids aligned with picker options', () {
      expect(
        narrativeEventSourceIdForAuthoringSourceDraft(
          const NarrativeScenarioAuthoringSourceDraft.mapEnter(
            mapId: ' p4_map ',
          ),
        ),
        'mapEnter:p4_map',
      );
      expect(
        narrativeEventSourceIdForAuthoringSourceDraft(
          const NarrativeScenarioAuthoringSourceDraft.triggerEnter(
            mapId: ' p4_map ',
            triggerId: ' p4_trigger ',
          ),
        ),
        'triggerEnter:p4_map:p4_trigger',
      );
      expect(
        narrativeEventSourceIdForAuthoringSourceDraft(
          const NarrativeScenarioAuthoringSourceDraft.entityInteract(
            mapId: ' p4_map ',
            entityId: ' p4_npc ',
          ),
        ),
        'entityInteract:p4_map:p4_npc',
      );
      expect(
        narrativeEventSourceIdForAuthoringSourceDraft(
          const NarrativeScenarioAuthoringSourceDraft.outcomeReceived(
            outcomeId: ' p4.outcome.ready ',
          ),
        ),
        'outcomeReceived:p4.outcome.ready',
      );
    });

    test('finds matching picker options and returns null when unavailable', () {
      final options = _eventSourceOptions();
      final source = const NarrativeScenarioAuthoringSourceDraft.entityInteract(
        mapId: 'p4_map',
        entityId: 'p4_npc',
      );

      final found = findNarrativeEventSourcePickerOptionForAuthoringSourceDraft(
        source,
        options,
      );

      expect(found, isNotNull);
      expect(found!.sourceId, 'entityInteract:p4_map:p4_npc');

      final missing =
          findNarrativeEventSourcePickerOptionForAuthoringSourceDraft(
        const NarrativeScenarioAuthoringSourceDraft.entityInteract(
          mapId: 'p4_map',
          entityId: 'missing_npc',
        ),
        options,
      );
      expect(missing, isNull);
    });

    test('validates empty references and unavailable options', () {
      final missingReference =
          validateNarrativeScenarioAuthoringSourceDraftAgainstEventSourceOptions(
        const NarrativeScenarioAuthoringSourceDraft.triggerEnter(
          mapId: 'p4_map',
          triggerId: ' ',
        ),
        _eventSourceOptions(),
      );
      expect(
        _diagnosticKinds(missingReference),
        contains(
            NarrativeEventSourceAuthoringDiagnosticKind.missingSourceReference),
      );
      expect(missingReference.single.path, 'source.triggerId');

      final unavailable =
          validateNarrativeScenarioAuthoringSourceDraftAgainstEventSourceOptions(
        const NarrativeScenarioAuthoringSourceDraft.outcomeReceived(
          outcomeId: 'p4.outcome.missing',
        ),
        _eventSourceOptions(),
      );
      expect(
        _diagnosticKinds(unavailable),
        contains(
            NarrativeEventSourceAuthoringDiagnosticKind.sourceOptionNotFound),
      );
      expect(unavailable.single.referencedId,
          'outcomeReceived:p4.outcome.missing');
    });

    test('replaces draft source without mutating the original draft', () {
      final original = _draft(
        source: const NarrativeScenarioAuthoringSourceDraft.mapEnter(
          mapId: 'p4_map',
        ),
      );
      final nextSource =
          const NarrativeScenarioAuthoringSourceDraft.triggerEnter(
        mapId: 'p4_map',
        triggerId: 'p4_trigger',
      );

      final replaced =
          replaceNarrativeScenarioAuthoringDraftSource(original, nextSource);

      expect(
          original.source!.kind, NarrativeScenarioAuthoringSourceKind.mapEnter);
      expect(replaced.source!.kind,
          NarrativeScenarioAuthoringSourceKind.triggerEnter);
      expect(replaced.scenarioId, original.scenarioId);
      expect(replaced.name, original.name);
      expect(replaced.description, original.description);
      expect(replaced.scope, original.scope);
      expect(replaced.actions, original.actions);
      expect(replaced.declaredOutcomes, original.declaredOutcomes);
      expect(replaced.metadata, original.metadata);
      expect(identical(replaced, original), isFalse);
    });

    test(
        'compiles updated drafts with the correct source node for every source',
        () {
      final cases = <_CompiledSourceExpectation>[
        _CompiledSourceExpectation(
          source: const NarrativeScenarioAuthoringSourceDraft.mapEnter(
            mapId: 'p4_map',
          ),
          actionKind: 'sourceMapEnter',
          mapId: 'p4_map',
        ),
        _CompiledSourceExpectation(
          source: const NarrativeScenarioAuthoringSourceDraft.triggerEnter(
            mapId: 'p4_map',
            triggerId: 'p4_trigger',
          ),
          actionKind: 'sourceTriggerEnter',
          mapId: 'p4_map',
          triggerId: 'p4_trigger',
        ),
        _CompiledSourceExpectation(
          source: const NarrativeScenarioAuthoringSourceDraft.entityInteract(
            mapId: 'p4_map',
            entityId: 'p4_npc',
          ),
          actionKind: 'sourceEntityInteract',
          mapId: 'p4_map',
          entityId: 'p4_npc',
        ),
        _CompiledSourceExpectation(
          source: const NarrativeScenarioAuthoringSourceDraft.outcomeReceived(
            outcomeId: 'p4.outcome.ready',
          ),
          actionKind: 'sourceOutcome',
          outcomeId: 'p4.outcome.ready',
          scope: ScenarioScope.globalStory,
        ),
      ];

      for (final entry in cases) {
        final draft = replaceNarrativeScenarioAuthoringDraftSource(
          _draft(scope: entry.scope),
          entry.source,
        );
        final asset =
            compileNarrativeScenarioAuthoringDraftToScenarioAsset(draft);
        final sourceNode = asset.nodes.singleWhere(
          (node) => node.id == 'p4_authoring_event_source__source',
        );

        expect(sourceNode.type, ScenarioNodeType.reference);
        expect(sourceNode.payload.actionKind, entry.actionKind);
        expect(sourceNode.binding.mapId, entry.mapId);
        expect(sourceNode.binding.triggerId, entry.triggerId);
        expect(sourceNode.binding.entityId, entry.entityId);
        expect(sourceNode.binding.outcomeId, entry.outcomeId);
      }
    });

    test('does not hardcode Selbrume identifiers', () {
      final source =
          createNarrativeScenarioAuthoringSourceDraftFromEventSourceOption(
        _bySourceKind(_eventSourceOptions(), NarrativeEventSourceKind.mapEnter),
      );
      final asset = compileNarrativeScenarioAuthoringDraftToScenarioAsset(
        replaceNarrativeScenarioAuthoringDraftSource(_draft(), source),
      );

      final serialized = {
        narrativeEventSourceIdForAuthoringSourceDraft(source),
        asset.toJson().toString(),
      }.join('\n').toLowerCase();

      expect(serialized, isNot(contains('selbrume')));
      expect(serialized, isNot(contains('lysa')));
      expect(serialized, isNot(contains('mael')));
      expect(serialized, isNot(contains('maël')));
      expect(serialized, isNot(contains('mado')));
    });
  });
}

List<NarrativeEventSourcePickerOption> _eventSourceOptions() {
  return buildNarrativeEventSourcePickerOptions(
    ProjectManifest(
      name: 'P4 Event Source Operations Test',
      maps: const [
        ProjectMapEntry(
          id: 'p4_map',
          name: 'P4 Map',
          relativePath: 'maps/p4_map.json',
        ),
      ],
      tilesets: const [],
      scenarios: const [
        ScenarioAsset(
          id: 'p4_outcome_provider',
          name: 'P4 Outcome Provider',
          entryNodeId: 'source',
          declaredOutcomes: ['p4.outcome.ready'],
          nodes: [
            ScenarioNode(
              id: 'source',
              type: ScenarioNodeType.reference,
              payload: ScenarioNodePayload(actionKind: 'sourceMapEnter'),
            ),
            ScenarioNode(
              id: 'emit',
              type: ScenarioNodeType.action,
              binding: ScenarioNodeBinding(outcomeId: 'p4.outcome.ready'),
              payload: ScenarioNodePayload(actionKind: 'emitOutcome'),
            ),
          ],
          edges: [
            ScenarioEdge(
                id: 'source_to_emit', fromNodeId: 'source', toNodeId: 'emit'),
          ],
        ),
      ],
    ),
    maps: const [
      MapData(
        id: 'p4_map',
        name: 'P4 Runtime Map',
        size: GridSize(width: 8, height: 8),
        entities: [
          MapEntity(
            id: 'p4_npc',
            name: 'P4 NPC',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 2, y: 3),
            npc: MapEntityNpcData(displayName: 'P4 NPC'),
          ),
        ],
        triggers: [
          MapTrigger(
            id: 'p4_trigger',
            name: 'P4 Trigger',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 1, y: 1),
              size: GridSize(width: 2, height: 2),
            ),
          ),
        ],
      ),
    ],
  );
}

NarrativeScenarioAuthoringDraft _draft({
  NarrativeScenarioAuthoringSourceDraft source =
      const NarrativeScenarioAuthoringSourceDraft.mapEnter(mapId: 'p4_map'),
  ScenarioScope scope = ScenarioScope.localEventFlow,
}) {
  return NarrativeScenarioAuthoringDraft(
    scenarioId: 'p4_authoring_event_source',
    name: 'P4 Authoring Event Source',
    description: 'Technical source replacement draft.',
    scope: scope,
    source: source,
    actions: const [
      NarrativeScenarioAuthoringActionDraft.setFlag(
        flagName: 'p4.authoring.source.executed',
      ),
    ],
    declaredOutcomes: const [],
    metadata: const {'authoring.test': 'p4-03'},
  );
}

NarrativeEventSourcePickerOption _bySourceKind(
  List<NarrativeEventSourcePickerOption> options,
  NarrativeEventSourceKind kind,
) {
  return options.singleWhere((option) => option.sourceKind == kind);
}

List<NarrativeEventSourceAuthoringDiagnosticKind> _diagnosticKinds(
  List<NarrativeEventSourceAuthoringDiagnostic> diagnostics,
) {
  return diagnostics.map((diagnostic) => diagnostic.kind).toList();
}

final class _CompiledSourceExpectation {
  const _CompiledSourceExpectation({
    required this.source,
    required this.actionKind,
    this.mapId,
    this.triggerId,
    this.entityId,
    this.outcomeId,
    this.scope = ScenarioScope.localEventFlow,
  });

  final NarrativeScenarioAuthoringSourceDraft source;
  final String actionKind;
  final String? mapId;
  final String? triggerId;
  final String? entityId;
  final String? outcomeId;
  final ScenarioScope scope;
}
