import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Event Builder read model', () {
    test('marks event without scene action as draft with missing action', () {
      final model = buildEventBuilderReadModel(
        events: [_event(page: const MapEventPage(pageNumber: 0))],
      );

      final summary = model.events.single;

      expect(summary.status, EventBuilderEventStatus.draft);
      expect(summary.sceneAction.isMissing, isTrue);
      expect(summary.sceneAction.label, 'Action principale manquante');
      expect(summary.diagnostics.single.kind,
          EventBuilderDiagnosticReadModelKind.missingSceneAction);
      expect(summary.diagnostics.single.title, 'Action principale manquante');
      expect(summary.diagnostics.single.sectionTarget, 'actions');
    });

    test('marks event with scene action and supported conditions as active',
        () {
      final model = buildEventBuilderReadModel(
        events: [
          _event(
            page: MapEventPage(
              pageNumber: 0,
              sceneTarget: const MapEventSceneTarget(sceneId: 'scene_rival'),
              condition: ScriptConditionFactory.allOf([
                ScriptConditionFactory.flagIsSet('fact_started'),
                ScriptConditionFactory.flagIsUnset('fact_blocked'),
              ]),
            ),
          ),
        ],
        sceneLabels: const {'scene_rival': 'Rencontre rival'},
        factLabels: const {
          'fact_started': 'Départ accepté',
          'fact_blocked': 'Passage bloqué',
        },
      );

      final summary = model.events.single;

      expect(summary.status, EventBuilderEventStatus.active);
      expect(summary.sceneAction.label, 'Jouer la scène "Rencontre rival"');
      expect(summary.conditions.map((condition) => condition.label), [
        'Fact "Départ accepté" est vrai',
        'Fact "Passage bloqué" est faux',
      ]);
      expect(summary.conditionEditingLocked, isFalse);
    });

    test('marks disabled page as inactive', () {
      final model = buildEventBuilderReadModel(
        events: [
          _event(
            page: const MapEventPage(
              pageNumber: 0,
              isDisabled: true,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_rival'),
            ),
          ),
        ],
      );

      expect(model.events.single.status, EventBuilderEventStatus.inactive);
      expect(model.events.single.statusLabel, 'Inactif');
    });

    test('marks event with no pages as invalid', () {
      final model = buildEventBuilderReadModel(
        events: [
          const MapEventDefinition(
            id: 'evt_empty',
            title: 'Event vide',
            position: EventPosition(layerId: 'events', x: 0, y: 0),
            pages: [],
          ),
        ],
      );

      final summary = model.events.single;

      expect(summary.status, EventBuilderEventStatus.invalid);
      expect(summary.diagnostics.single.kind,
          EventBuilderDiagnosticReadModelKind.eventPageMissing);
      expect(summary.diagnostics.single.title, 'Page événement manquante');
    });

    test('renders event consumed and not consumed condition labels', () {
      final model = buildEventBuilderReadModel(
        events: [
          _event(
            page: MapEventPage(
              pageNumber: 0,
              sceneTarget: const MapEventSceneTarget(sceneId: 'scene_rival'),
              condition: ScriptConditionFactory.allOf([
                ScriptConditionFactory.eventIsConsumed('evt_intro'),
                ScriptConditionFactory.not(
                  ScriptConditionFactory.eventIsConsumed('evt_rival'),
                ),
              ]),
            ),
          ),
        ],
        eventLabels: const {
          'evt_intro': 'Introduction',
          'evt_rival': 'Rival au port',
        },
      );

      expect(
          model.events.single.conditions.map((condition) => condition.label), [
        'Événement "Introduction" déjà consommé',
        'Événement "Rival au port" pas encore consommé',
      ]);
    });

    test('renders one-shot and reusable behavior labels', () {
      final model = buildEventBuilderReadModel(
        events: [
          _event(
            id: 'evt_once',
            title: 'Une fois',
            x: 0,
            page: const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_once'),
            ),
          ),
          _event(
            id: 'evt_reusable',
            title: 'Réutilisable',
            x: 1,
            page: const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_reusable'),
              metadata: {
                EventBuilderMetadataKeys.reusePolicy: 'reusable',
              },
            ),
          ),
        ],
      );

      expect(model.events[0].behavior.label, 'Une seule fois');
      expect(model.events[1].behavior.label, 'Réutilisable');
    });

    test('projects no scene target for missing action outcomes', () {
      final model = buildEventBuilderReadModel(
        events: [_event(page: const MapEventPage(pageNumber: 0))],
        scenes: {'scene_rival': _scene(id: 'scene_rival')},
      );

      final projection = model.events.single.sceneOutcomes;

      expect(
        projection.status,
        EventBuilderSceneOutcomesProjectionStatus.noSceneTarget,
      );
      expect(projection.outcomes, isEmpty);
      expect(projection.label, 'Aucune scène liée');
    });

    test('projects missing linked scene outcomes without inventing results',
        () {
      final model = buildEventBuilderReadModel(
        events: [
          _event(
            page: const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_missing'),
            ),
          ),
        ],
        scenes: const <String, SceneAsset>{},
      );

      final projection = model.events.single.sceneOutcomes;

      expect(
        projection.status,
        EventBuilderSceneOutcomesProjectionStatus.missingScene,
      );
      expect(projection.sceneId, 'scene_missing');
      expect(projection.outcomes, isEmpty);
      expect(projection.label, 'Scène introuvable');
    });

    test('projects linked scene with no declared outcomes', () {
      final model = buildEventBuilderReadModel(
        events: [
          _event(
            page: const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_quiet'),
            ),
          ),
        ],
        scenes: {'scene_quiet': _scene(id: 'scene_quiet')},
      );

      final projection = model.events.single.sceneOutcomes;

      expect(
        projection.status,
        EventBuilderSceneOutcomesProjectionStatus.noDeclaredOutcomes,
      );
      expect(projection.sceneId, 'scene_quiet');
      expect(projection.outcomes, isEmpty);
      expect(projection.label, 'Aucun résultat déclaré');
    });

    test('projects linked scene declared outcomes as read-only in order', () {
      final scene = _scene(
        id: 'scene_rival',
        declaredOutcomes: [
          SceneOutcome(
            id: 'victory',
            label: 'Victoire',
            description: 'Le rival est battu.',
          ),
          SceneOutcome(id: 'defeat', label: 'Défaite'),
        ],
      );
      final model = buildEventBuilderReadModel(
        events: [
          _event(
            page: const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_rival'),
            ),
          ),
        ],
        scenes: {'scene_rival': scene},
      );

      final projection = model.events.single.sceneOutcomes;

      expect(
        projection.status,
        EventBuilderSceneOutcomesProjectionStatus.hasDeclaredOutcomes,
      );
      expect(projection.label, '2 résultat(s) déclarés par la Scene');
      expect(
        projection.outcomes.map((outcome) => outcome.id),
        ['victory', 'defeat'],
      );
      expect(
        projection.outcomes.map((outcome) => outcome.label),
        ['Victoire', 'Défaite'],
      );
      expect(projection.outcomes.first.description, 'Le rival est battu.');
      expect(
        projection.outcomes.every((outcome) => outcome.isReadOnly),
        isTrue,
      );
      expect(projection.outcomes.first.sourceLabel, 'Scene déclarée');
    });

    test('does not create outcomes on the map event definition', () {
      final event = _event(
        page: const MapEventPage(
          pageNumber: 0,
          sceneTarget: MapEventSceneTarget(sceneId: 'scene_rival'),
        ),
      );

      buildEventBuilderReadModel(
        events: [event],
        scenes: {
          'scene_rival': _scene(
            id: 'scene_rival',
            declaredOutcomes: [SceneOutcome(id: 'victory', label: 'Victoire')],
          ),
        },
      );

      expect(event.toJson().containsKey('outcomes'), isFalse);
      expect(event.toJson().containsKey('reactions'), isFalse);
    });

    test('projects reusable lifecycle without consumption requirement', () {
      final model = buildEventBuilderReadModel(
        events: [
          _event(
            page: const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_rival'),
              metadata: {
                EventBuilderMetadataKeys.reusePolicy: 'reusable',
              },
            ),
          ),
        ],
        mapId: 'map_port',
        scenes: {
          'scene_rival': _sceneWithMarkEventConsumed(
            id: 'scene_rival',
            mapId: 'map_port',
            eventId: 'evt_rival',
          ),
        },
      );

      final lifecycle = model.events.single.lifecycle;

      expect(
        lifecycle.status,
        EventBuilderLifecycleProjectionStatus.reusableNoConsumptionNeeded,
      );
      expect(lifecycle.warningMessage, isNull);
      expect(lifecycle.isRuntimeGuaranteed, isTrue);
    });

    test('projects one-shot without scene target as not verifiable', () {
      final model = buildEventBuilderReadModel(
        events: [_event(page: const MapEventPage(pageNumber: 0))],
        mapId: 'map_port',
      );

      final lifecycle = model.events.single.lifecycle;

      expect(
        lifecycle.status,
        EventBuilderLifecycleProjectionStatus.oneShotNoSceneTarget,
      );
      expect(lifecycle.isRuntimeGuaranteed, isFalse);
      expect(lifecycle.warningMessage, contains('non vérifiable'));
    });

    test('projects one-shot with missing scene as not verifiable', () {
      final model = buildEventBuilderReadModel(
        events: [
          _event(
            page: const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_missing'),
            ),
          ),
        ],
        mapId: 'map_port',
        scenes: const <String, SceneAsset>{},
      );

      final lifecycle = model.events.single.lifecycle;

      expect(
        lifecycle.status,
        EventBuilderLifecycleProjectionStatus.oneShotMissingScene,
      );
      expect(lifecycle.isRuntimeGuaranteed, isFalse);
      expect(lifecycle.warningMessage, contains('Scene introuvable'));
    });

    test('projects one-shot without markEventConsumed as intent only', () {
      final model = buildEventBuilderReadModel(
        events: [
          _event(
            page: const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_rival'),
            ),
          ),
        ],
        mapId: 'map_port',
        scenes: {'scene_rival': _scene(id: 'scene_rival')},
      );

      final lifecycle = model.events.single.lifecycle;

      expect(
        lifecycle.status,
        EventBuilderLifecycleProjectionStatus.oneShotIntentOnly,
      );
      expect(lifecycle.warningMessage, 'Intention non garantie au runtime.');
      expect(lifecycle.isRuntimeGuaranteed, isFalse);
    });

    test(
        'projects one-shot with matching markEventConsumed as explicit scene compatibility',
        () {
      final model = buildEventBuilderReadModel(
        events: [
          _event(
            page: const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_rival'),
            ),
          ),
        ],
        mapId: 'map_port',
        scenes: {
          'scene_rival': _sceneWithMarkEventConsumed(
            id: 'scene_rival',
            mapId: 'map_port',
            eventId: 'evt_rival',
          ),
        },
      );

      final lifecycle = model.events.single.lifecycle;

      expect(
        lifecycle.status,
        EventBuilderLifecycleProjectionStatus
            .oneShotExplicitSceneConsequenceForThisEvent,
      );
      expect(lifecycle.isRuntimeGuaranteed, isTrue);
      expect(
        lifecycle.warningMessage,
        'Couvert par conséquence Scene explicite - compatible, '
        'mais fragile si la Scene est réutilisée.',
      );
    });

    test(
        'projects one-shot with markEventConsumed for another event as warning',
        () {
      final model = buildEventBuilderReadModel(
        events: [
          _event(
            page: const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_rival'),
            ),
          ),
        ],
        mapId: 'map_port',
        scenes: {
          'scene_rival': _sceneWithMarkEventConsumed(
            id: 'scene_rival',
            mapId: 'map_port',
            eventId: 'evt_other',
          ),
        },
      );

      final lifecycle = model.events.single.lifecycle;

      expect(
        lifecycle.status,
        EventBuilderLifecycleProjectionStatus
            .oneShotExplicitSceneConsequenceForAnotherEvent,
      );
      expect(lifecycle.isRuntimeGuaranteed, isFalse);
      expect(lifecycle.warningMessage, 'La Scene consomme un autre event.');
    });

    test('setFact-only scenes do not satisfy one-shot event consumption', () {
      final model = buildEventBuilderReadModel(
        events: [
          _event(
            page: const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_fact'),
            ),
          ),
        ],
        mapId: 'map_port',
        scenes: {
          'scene_fact': _sceneWithSetFact(id: 'scene_fact'),
        },
      );

      expect(
        model.events.single.lifecycle.status,
        EventBuilderLifecycleProjectionStatus.oneShotIntentOnly,
      );
    });

    test('projects linked scene setFact true as fact world impact', () {
      final model = buildEventBuilderReadModel(
        events: [
          _event(
            page: const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_fact'),
              metadata: {
                EventBuilderMetadataKeys.reusePolicy: 'reusable',
              },
            ),
          ),
        ],
        scenes: {
          'scene_fact': _sceneWithSetFact(
            id: 'scene_fact',
            factId: 'fact_seen_rival',
            value: true,
          ),
        },
        factLabels: const {'fact_seen_rival': 'Rival rencontré'},
      );

      expect(
        model.events.single.worldImpacts.map((impact) => impact.kind),
        [EventBuilderWorldImpactKind.fact],
      );
      expect(
          model.events.single.worldImpacts.single.sourceId, 'fact_seen_rival');
      expect(model.events.single.worldImpacts.single.label,
          'Fact : Rival rencontré');
      expect(model.events.single.worldImpacts.single.reason,
          'Fact modifié par la Scene liée.');
    });

    test('projects linked scene setFact false with factId fallback', () {
      final model = buildEventBuilderReadModel(
        events: [
          _event(
            page: const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_fact'),
              metadata: {
                EventBuilderMetadataKeys.reusePolicy: 'reusable',
              },
            ),
          ),
        ],
        scenes: {
          'scene_fact': _sceneWithSetFact(
            id: 'scene_fact',
            factId: 'fact_gate_open',
            value: false,
          ),
        },
      );

      expect(
        model.events.single.worldImpacts.map((impact) => impact.kind),
        [EventBuilderWorldImpactKind.fact],
      );
      expect(
          model.events.single.worldImpacts.single.sourceId, 'fact_gate_open');
      expect(model.events.single.worldImpacts.single.label,
          'Fact : fact_gate_open');
      expect(model.events.single.worldImpacts.single.reason,
          'Fact modifié par la Scene liée.');
    });

    test('projects linked scene markEventConsumed as consumed world impact',
        () {
      final model = buildEventBuilderReadModel(
        events: [
          _event(
            id: 'evt_rival',
            page: const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_rival'),
              metadata: {
                EventBuilderMetadataKeys.reusePolicy: 'reusable',
              },
            ),
          ),
        ],
        mapId: 'map_port',
        scenes: {
          'scene_rival': _sceneWithMarkEventConsumed(
            id: 'scene_rival',
            mapId: 'map_port',
            eventId: 'evt_rival',
          ),
        },
        eventLabels: const {'evt_rival': 'Rencontre rival'},
      );

      expect(
        model.events.single.worldImpacts.map((impact) => impact.kind),
        [EventBuilderWorldImpactKind.consumedEvent],
      );
      expect(model.events.single.worldImpacts.single.sourceId, 'evt_rival');
      expect(model.events.single.worldImpacts.single.label,
          'Événement consommé : Rencontre rival');
      expect(model.events.single.worldImpacts.single.reason,
          'La Scene liée marque cet événement comme joué.');
    });

    test('projects linked scene markEventConsumed for another event', () {
      final model = buildEventBuilderReadModel(
        events: [
          _event(
            id: 'evt_rival',
            page: const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_rival'),
              metadata: {
                EventBuilderMetadataKeys.reusePolicy: 'reusable',
              },
            ),
          ),
        ],
        mapId: 'map_port',
        scenes: {
          'scene_rival': _sceneWithMarkEventConsumed(
            id: 'scene_rival',
            mapId: 'map_route',
            eventId: 'evt_other',
          ),
        },
      );

      expect(
        model.events.single.worldImpacts.map((impact) => impact.kind),
        [EventBuilderWorldImpactKind.consumedEvent],
      );
      expect(model.events.single.worldImpacts.single.sourceId, 'evt_other');
      expect(model.events.single.worldImpacts.single.label,
          'Événement consommé : evt_other');
      expect(model.events.single.worldImpacts.single.reason,
          'La Scene liée marque cet événement comme joué.');
    });

    test('deduplicates one-shot preview when scene marks same event consumed',
        () {
      final model = buildEventBuilderReadModel(
        events: [
          _event(
            id: 'evt_rival',
            page: const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_rival'),
            ),
          ),
        ],
        mapId: 'map_port',
        scenes: {
          'scene_rival': _sceneWithMarkEventConsumed(
            id: 'scene_rival',
            mapId: 'map_port',
            eventId: 'evt_rival',
          ),
        },
      );

      expect(
        model.events.single.worldImpacts.where((impact) =>
            impact.kind == EventBuilderWorldImpactKind.consumedEvent &&
            impact.sourceId == 'evt_rival'),
        hasLength(1),
      );
      expect(model.events.single.worldImpacts.single.reason,
          'La Scene liée marque cet événement comme joué.');
    });

    test('orders scene consequences before event builder previews', () {
      final model = buildEventBuilderReadModel(
        events: [
          _event(
            id: 'evt_rival',
            page: const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_mixed'),
            ),
          ),
        ],
        mapId: 'map_port',
        scenes: {
          'scene_mixed': _scene(
            id: 'scene_mixed',
            extraNodes: [
              SceneNode(
                id: 'node_set_fact',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.consequence(
                  SceneConsequence.setFact(
                    factId: 'fact_seen_rival',
                    value: true,
                  ),
                ),
              ),
              SceneNode(
                id: 'node_mark_other_consumed',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.consequence(
                  SceneConsequence.markEventConsumed(
                    mapId: 'map_port',
                    eventId: 'evt_other',
                  ),
                ),
              ),
            ],
          ),
        },
      );

      expect(
        model.events.single.worldImpacts.map((impact) => impact.sourceId),
        ['fact_seen_rival', 'evt_other', 'evt_rival'],
      );
    });

    test('does not invent world impacts from missing scene or outcomes only',
        () {
      final missingSceneModel = buildEventBuilderReadModel(
        events: [
          _event(
            page: const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_missing'),
              metadata: {
                EventBuilderMetadataKeys.reusePolicy: 'reusable',
              },
            ),
          ),
        ],
        scenes: const <String, SceneAsset>{},
      );
      final outcomesOnlyModel = buildEventBuilderReadModel(
        events: [
          _event(
            page: const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_outcomes'),
              metadata: {
                EventBuilderMetadataKeys.reusePolicy: 'reusable',
              },
            ),
          ),
        ],
        scenes: {
          'scene_outcomes': _scene(
            id: 'scene_outcomes',
            declaredOutcomes: [SceneOutcome(id: 'victory', label: 'Victoire')],
          ),
        },
      );

      expect(missingSceneModel.events.single.worldImpacts, isEmpty);
      expect(outcomesOnlyModel.events.single.worldImpacts, isEmpty);
      expect(
        outcomesOnlyModel.events.single.worldImpacts.map(
          (impact) => impact.kind,
        ),
        isNot(contains(EventBuilderWorldImpactKind.storyStep)),
      );
    });

    test('locks mixed legacy condition while keeping supported labels visible',
        () {
      final original = ScriptConditionFactory.allOf([
        ScriptConditionFactory.flagIsSet('fact_started'),
        ScriptConditionFactory.variableEqualsString('legacy_variable', 'yes'),
      ]);
      final model = buildEventBuilderReadModel(
        events: [
          _event(
            page: MapEventPage(
              pageNumber: 0,
              sceneTarget: const MapEventSceneTarget(sceneId: 'scene_rival'),
              condition: original,
            ),
          ),
        ],
        factLabels: const {'fact_started': 'Départ accepté'},
      );

      final summary = model.events.single;

      expect(summary.conditionEditingLocked, isTrue);
      expect(
        summary.conditionEditingMessage,
        'Cette condition contient une partie avancée préservée. '
        'Elle ne peut pas être éditée partiellement.',
      );
      expect(summary.conditions.single.label, 'Fact "Départ accepté" est vrai');
      expect(
        summary.diagnostics.map((diagnostic) => diagnostic.kind),
        contains(
            EventBuilderDiagnosticReadModelKind.unsupportedLegacyCondition),
      );
    });

    test('maps malformed metadata to a no-code warning', () {
      final model = buildEventBuilderReadModel(
        events: [
          _event(
            page: const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_rival'),
              metadata: {
                EventBuilderMetadataKeys.reusePolicy: 'reuse-forever',
              },
            ),
          ),
        ],
      );

      final diagnostic = model.events.single.diagnostics.single;

      expect(diagnostic.kind,
          EventBuilderDiagnosticReadModelKind.metadataMalformed);
      expect(diagnostic.title, 'Réglage Event Builder illisible');
      expect(diagnostic.sectionTarget, 'behavior');
    });

    test('maps legacy script and message to readable warnings', () {
      final model = buildEventBuilderReadModel(
        events: [
          _event(
            page: const MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene_rival'),
              script: ScriptRef(scriptId: 'legacy_script'),
              message: 'Bonjour legacy',
            ),
          ),
        ],
      );

      expect(
          model.events.single.diagnostics.map((diagnostic) => diagnostic.kind),
          [
            EventBuilderDiagnosticReadModelKind.unsupportedLegacyScript,
            EventBuilderDiagnosticReadModelKind.unsupportedLegacyMessage,
          ]);
      expect(
          model.events.single.diagnostics.map((diagnostic) => diagnostic.title),
          [
            'Script legacy préservé',
            'Message legacy préservé',
          ]);
    });

    test('sorts events by y, x, then display name and id', () {
      final model = buildEventBuilderReadModel(
        events: [
          _event(id: 'evt_z', title: 'Zeta', x: 4, y: 1),
          _event(id: 'evt_b', title: 'Beta', x: 2, y: 0),
          _event(id: 'evt_a2', title: 'Alpha', x: 4, y: 1),
          _event(id: 'evt_a1', title: 'Alpha', x: 4, y: 1),
        ],
      );

      expect(model.events.map((event) => event.eventId), [
        'evt_b',
        'evt_a1',
        'evt_a2',
        'evt_z',
      ]);
    });
  });
}

MapEventDefinition _event({
  String id = 'evt_rival',
  String title = 'Rival au port',
  int x = 4,
  int y = 5,
  MapEventType type = MapEventType.actor,
  MapEventPage page = const MapEventPage(
    pageNumber: 0,
    sceneTarget: MapEventSceneTarget(sceneId: 'scene_rival'),
  ),
}) {
  return MapEventDefinition(
    id: id,
    title: title,
    position: EventPosition(layerId: 'events', x: x, y: y),
    type: type,
    pages: [page],
  );
}

SceneAsset _scene({
  required String id,
  List<SceneOutcome> declaredOutcomes = const <SceneOutcome>[],
  List<SceneNode> extraNodes = const <SceneNode>[],
}) {
  return SceneAsset(
    id: id,
    name: id,
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        ...extraNodes,
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
    ),
    declaredOutcomes: declaredOutcomes,
  );
}

SceneAsset _sceneWithMarkEventConsumed({
  required String id,
  required String mapId,
  required String eventId,
}) {
  return _scene(
    id: id,
    extraNodes: [
      SceneNode(
        id: 'node_mark_consumed',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.markEventConsumed(
            mapId: mapId,
            eventId: eventId,
          ),
        ),
      ),
    ],
  );
}

SceneAsset _sceneWithSetFact({
  required String id,
  String factId = 'fact_seen_rival',
  bool value = true,
}) {
  return _scene(
    id: id,
    extraNodes: [
      SceneNode(
        id: 'node_set_fact',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.setFact(factId: factId, value: value),
        ),
      ),
    ],
  );
}
