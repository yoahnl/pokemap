import 'package:avelune_studio/features/events/application/event_outcome_source_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  final lab = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.scene,
    producerId: 'bg-labo',
    outcomeId: 'oeuf-recu',
  );
  final scenes = [_scene('bg-labo'), _scene('autre')];

  NarrativeEventSourceRef received(NarrativeOutcomeRef outcome) =>
      NarrativeEventSourceRef.outcomeReceived(outcome);

  test('a source that is not an outcome shows the empty choice and opens nothing', () {
    final summary = summarizeEventOutcomeSource(
      source: NarrativeEventSourceRef.mapEnter('map'),
      catalog: _catalog([]),
      scenes: scenes,
    );
    expect(summary.outcome, isNull);
    expect(summary.title, 'Choisir un producteur');
    expect(summary.outcomeLabel, 'Résultat : à choisir');
    expect(summary.producerKindLabel, 'Producteur : à choisir');
    expect(summary.status, 'Résultat absent du catalogue');
    expect(summary.openableProducerId, isNull);
    expect(eventSourceOutcome(NarrativeEventSourceRef.mapEnter('map')), isNull);
    expect(eventSourceOutcome(null), isNull);
  });

  test('a selectable outcome names its producer and can open the scene that produces it', () {
    final summary = summarizeEventOutcomeSource(
      source: received(lab),
      catalog: _catalog([_option(lab, selectable: true)]),
      scenes: scenes,
    );
    expect(eventSourceOutcome(received(lab)), lab);
    expect(summary.title, 'Laboratoire');
    expect(summary.outcomeLabel, 'Résultat : oeuf-recu');
    expect(summary.producerKindLabel, 'Producteur : scene');
    expect(summary.status, 'Résultat disponible');
    expect(summary.openableProducerId, 'bg-labo');
  });

  test('an unavailable outcome states its reason', () {
    final summary = summarizeEventOutcomeSource(
      source: received(lab),
      catalog: _catalog([_option(lab, selectable: false)]),
      scenes: scenes,
    );
    expect(summary.status, 'Scène supprimée');
  });

  test('two producers for the same outcome are reported as ambiguous', () {
    final summary = summarizeEventOutcomeSource(
      source: received(lab),
      catalog: _catalog([
        _option(lab, selectable: true),
        _option(lab, selectable: true, technical: 'scene:bg-labo:oeuf-recu:bis'),
      ]),
      scenes: scenes,
    );
    expect(summary.status, 'Producteur ambigu');
    expect(summary.title, 'bg-labo');
  });

  test('an outcome absent from the catalog keeps its producer id and the absent status', () {
    final summary = summarizeEventOutcomeSource(
      source: received(lab),
      catalog: _catalog([]),
      scenes: scenes,
    );
    expect(summary.title, 'bg-labo');
    expect(summary.status, 'Résultat absent du catalogue');
  });

  test('the producer is not openable when its scene is missing or not a scene', () {
    final gone = summarizeEventOutcomeSource(
      source: received(lab),
      catalog: _catalog([_option(lab, selectable: true)]),
      scenes: [_scene('autre')],
    );
    expect(gone.openableProducerId, isNull);
    final battle = NarrativeOutcomeRef(
      producerKind: NarrativeOutcomeProducerKind.battle,
      producerId: 'bg-labo',
      outcomeId: 'oeuf-recu',
    );
    final other = summarizeEventOutcomeSource(
      source: received(battle),
      catalog: _catalog([]),
      scenes: scenes,
    );
    expect(other.openableProducerId, isNull);
  });
}

NarrativeOutcomeEventSourceCatalog _catalog(
  List<NarrativeOutcomeEventSourceOption> options,
) => NarrativeOutcomeEventSourceCatalog(options: options, diagnostics: const []);

NarrativeOutcomeEventSourceOption _option(
  NarrativeOutcomeRef outcome, {
  required bool selectable,
  String technical = 'scene:bg-labo:oeuf-recu',
}) => NarrativeOutcomeEventSourceOption(
  outcome: outcome,
  producerLabel: 'Laboratoire',
  outcomeLabel: 'Œuf reçu',
  humanSourceSentence: 'Quand le laboratoire émet un œuf',
  status: selectable
      ? NarrativeOutcomeReachabilityStatus.reachable
      : NarrativeOutcomeReachabilityStatus.producerMissing,
  selectable: selectable,
  unavailableReason: selectable ? null : 'Scène supprimée',
  origin: NarrativeOutcomeSourceOrigin.scene,
  debugTechnicalLabel: technical,
);

SceneAsset _scene(String id) => SceneAsset(
  id: id,
  name: id,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'first',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);
