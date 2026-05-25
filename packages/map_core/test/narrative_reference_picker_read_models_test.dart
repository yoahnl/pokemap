import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Narrative reference picker read models', () {
    test('builds scenario picker options with stable labels and counts', () {
      final options = buildNarrativeScenarioPickerOptions(
        _manifest(
          scenarios: [
            _scenario(
              id: 'zeta_scene',
              name: 'Zeta Scene',
              description: 'Late scene',
              scope: ScenarioScope.globalStory,
              declaredOutcomes: const ['zeta.done'],
            ),
            _scenario(
              id: 'alpha_scene',
              name: ' ',
              description: 'Fallback label scene',
              declaredOutcomes: const ['alpha.done', 'alpha.done', ' '],
            ),
          ],
        ),
      );

      expect(options.map((option) => option.scenarioId), [
        'alpha_scene',
        'zeta_scene',
      ]);

      final alpha = options.first;
      expect(alpha.humanLabel, 'alpha_scene');
      expect(alpha.description, 'Fallback label scene');
      expect(alpha.scope, ScenarioScope.localEventFlow);
      expect(alpha.entryNodeId, 'source');
      expect(alpha.declaredOutcomeIds, ['alpha.done']);
      expect(alpha.nodeCount, 3);
      expect(alpha.edgeCount, 2);
      expect(alpha.debugTechnicalLabel, 'alpha_scene');

      final zeta = options.last;
      expect(zeta.humanLabel, 'Zeta Scene');
      expect(zeta.scope, ScenarioScope.globalStory);
    });

    test('builds outcome picker options from declared emitted and consumed ids',
        () {
      final options = buildNarrativeOutcomePickerOptions(
        _manifest(
          scenarios: [
            _scenario(
              id: 'local_scene',
              declaredOutcomes: const ['alpha.done', 'unused'],
              extraNodes: const [
                ScenarioNode(
                  id: 'emit_orphan',
                  type: ScenarioNodeType.action,
                  binding: ScenarioNodeBinding(outcomeId: 'orphan.emit'),
                  payload: ScenarioNodePayload(actionKind: 'emitOutcome'),
                ),
              ],
            ),
            _scenario(
              id: 'global_scene',
              scope: ScenarioScope.globalStory,
              declaredOutcomes: const ['trigger.ready'],
              nodes: const [
                ScenarioNode(
                  id: 'source_alpha',
                  type: ScenarioNodeType.reference,
                  binding: ScenarioNodeBinding(outcomeId: 'alpha.done'),
                  payload: ScenarioNodePayload(actionKind: 'sourceOutcome'),
                ),
                ScenarioNode(
                  id: 'emit_trigger',
                  type: ScenarioNodeType.action,
                  binding: ScenarioNodeBinding(outcomeId: 'trigger.ready'),
                  payload: ScenarioNodePayload(actionKind: 'emitOutcome'),
                ),
              ],
              edges: const [
                ScenarioEdge(
                  id: 'source_to_emit',
                  fromNodeId: 'source_alpha',
                  toNodeId: 'emit_trigger',
                ),
              ],
            ),
          ],
        ),
      );

      expect(options.map((option) => option.outcomeId), [
        'alpha.done',
        'orphan.emit',
        'trigger.ready',
        'unused',
      ]);

      final alpha = _byOutcomeId(options, 'alpha.done');
      expect(alpha.humanLabel, 'alpha done');
      expect(alpha.declaredByScenarioIds, ['local_scene']);
      expect(alpha.emittedByScenarioIds, ['local_scene']);
      expect(alpha.consumedByScenarioIds, ['global_scene']);
      expect(alpha.isDeclared, isTrue);
      expect(alpha.isEmitted, isTrue);
      expect(alpha.isConsumed, isTrue);
      expect(alpha.isOrphan, isFalse);
      expect(alpha.debugTechnicalLabel, 'alpha.done');

      final orphan = _byOutcomeId(options, 'orphan.emit');
      expect(orphan.isDeclared, isFalse);
      expect(orphan.isEmitted, isTrue);
      expect(orphan.isConsumed, isFalse);
      expect(orphan.isOrphan, isTrue);

      final unused = _byOutcomeId(options, 'unused');
      expect(unused.isDeclared, isTrue);
      expect(unused.isEmitted, isFalse);
      expect(unused.isConsumed, isFalse);
      expect(unused.isOrphan, isTrue);
    });

    test('builds battle reference picker options from trainer battle nodes',
        () {
      final options = buildNarrativeBattleReferencePickerOptions(
        _manifest(
          trainers: const [
            ProjectTrainerEntry(
              id: 'rival',
              name: 'Karim',
              trainerClass: 'Rival',
            ),
          ],
          scenarios: [
            _scenario(
              id: 'duel_scene',
              nodes: const [
                ScenarioNode(
                  id: 'battle_node',
                  type: ScenarioNodeType.action,
                  binding: ScenarioNodeBinding(
                    trainerId: 'rival',
                    entityId: 'rival_npc',
                  ),
                  payload: ScenarioNodePayload(
                    actionKind: 'startTrainerBattle',
                    params: {'battleId': 'port_duel'},
                  ),
                ),
              ],
              edges: const [],
            ),
            _scenario(
              id: 'unknown_scene',
              nodes: const [
                ScenarioNode(
                  id: 'unknown_battle',
                  type: ScenarioNodeType.action,
                  binding: ScenarioNodeBinding(
                    trainerId: 'missing_trainer',
                    entityId: 'ghost_npc',
                  ),
                  payload: ScenarioNodePayload(
                    actionKind: 'startTrainerBattle',
                  ),
                ),
              ],
              edges: const [],
            ),
          ],
        ),
      );

      expect(options.map((option) => option.battleReferenceId), [
        'unknown_scene:unknown_battle',
        'duel_scene:battle_node',
      ]);

      final known = _byBattleReferenceId(options, 'duel_scene:battle_node');
      expect(known.battleId, 'port_duel');
      expect(known.humanLabel, 'Rival Karim');
      expect(known.sourceScenarioId, 'duel_scene');
      expect(known.sourceNodeId, 'battle_node');
      expect(known.trainerId, 'rival');
      expect(known.trainerLabel, 'Karim');
      expect(known.trainerClass, 'Rival');
      expect(known.npcEntityId, 'rival_npc');
      expect(known.isTrainerKnown, isTrue);
      expect(known.supportedOutcomeKinds, [
        NarrativeBattleOutcomeKind.victory,
        NarrativeBattleOutcomeKind.defeat,
      ]);
      expect(known.debugTechnicalLabel, 'duel_scene:battle_node -> port_duel');

      final unknown =
          _byBattleReferenceId(options, 'unknown_scene:unknown_battle');
      expect(unknown.battleId, 'missing_trainer');
      expect(unknown.humanLabel, 'missing_trainer');
      expect(unknown.isTrainerKnown, isFalse);
      expect(unknown.trainerLabel, isNull);
      expect(unknown.trainerClass, isNull);
    });
  });
}

ProjectManifest _manifest({
  List<ScenarioAsset>? scenarios,
  List<ProjectTrainerEntry> trainers = const [],
}) {
  return ProjectManifest(
    name: 'Picker Test Project',
    maps: const [],
    tilesets: const [],
    scenarios: scenarios ?? const [],
    trainers: trainers,
  );
}

ScenarioAsset _scenario({
  required String id,
  String name = 'Test Scene',
  String description = '',
  ScenarioScope scope = ScenarioScope.localEventFlow,
  List<String> declaredOutcomes = const ['alpha.done'],
  List<ScenarioNode>? nodes,
  List<ScenarioNode> extraNodes = const [],
  List<ScenarioEdge>? edges,
}) {
  return ScenarioAsset(
    id: id,
    name: name,
    description: description,
    scope: scope,
    entryNodeId: 'source',
    declaredOutcomes: declaredOutcomes,
    nodes: nodes ??
        [
          const ScenarioNode(
            id: 'source',
            type: ScenarioNodeType.reference,
            binding: ScenarioNodeBinding(outcomeId: 'trigger.ready'),
            payload: ScenarioNodePayload(actionKind: 'sourceOutcome'),
          ),
          const ScenarioNode(
            id: 'emit',
            type: ScenarioNodeType.action,
            binding: ScenarioNodeBinding(outcomeId: 'alpha.done'),
            payload: ScenarioNodePayload(actionKind: 'emitOutcome'),
          ),
          const ScenarioNode(id: 'end', type: ScenarioNodeType.end),
          ...extraNodes,
        ],
    edges: edges ??
        const [
          ScenarioEdge(
              id: 'source_to_emit', fromNodeId: 'source', toNodeId: 'emit'),
          ScenarioEdge(id: 'emit_to_end', fromNodeId: 'emit', toNodeId: 'end'),
        ],
  );
}

NarrativeOutcomePickerOption _byOutcomeId(
  List<NarrativeOutcomePickerOption> options,
  String outcomeId,
) {
  return options.singleWhere((option) => option.outcomeId == outcomeId);
}

NarrativeBattleReferencePickerOption _byBattleReferenceId(
  List<NarrativeBattleReferencePickerOption> options,
  String battleReferenceId,
) {
  return options.singleWhere(
    (option) => option.battleReferenceId == battleReferenceId,
  );
}
