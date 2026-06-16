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
