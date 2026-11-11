import 'package:map_core/map_core_domain.dart';

typedef EventOutcomeSourceSummary = ({
  NarrativeOutcomeRef? outcome,
  String title,
  String outcomeLabel,
  String producerKindLabel,
  String status,
  String? openableProducerId,
});

NarrativeOutcomeRef? eventSourceOutcome(NarrativeEventSourceRef? source) =>
    source?.when<NarrativeOutcomeRef?>(
      entityAutorun: (_, _) => null,
      entityBump: (_, _) => null,
      entityInteract: (_, _) => null,
      modelInteract: (_, _) => null,
      triggerBump: (_, _) => null,
      triggerEnter: (_, _) => null,
      mapEnter: (_) => null,
      outcomeReceived: (o) => o,
    );

EventOutcomeSourceSummary summarizeEventOutcomeSource({
  required NarrativeEventSourceRef? source,
  required NarrativeOutcomeEventSourceCatalog catalog,
  required List<SceneAsset> scenes,
}) {
  final outcome = eventSourceOutcome(source);
  final options = outcome == null
      ? <NarrativeOutcomeEventSourceOption>[]
      : catalog.optionsForOutcome(outcome);
  final option = options.length == 1 ? options.single : null;
  return (
    outcome: outcome,
    title:
        option?.producerLabel ?? outcome?.producerId ?? 'Choisir un producteur',
    outcomeLabel: 'Résultat : ${outcome?.outcomeId ?? 'à choisir'}',
    producerKindLabel:
        'Producteur : ${outcome?.producerKind.name ?? 'à choisir'}',
    status: options.length > 1
        ? 'Producteur ambigu'
        : option?.unavailableReason ??
              (option?.selectable == true
                  ? 'Résultat disponible'
                  : 'Résultat absent du catalogue'),
    openableProducerId:
        outcome != null &&
            outcome.producerKind == NarrativeOutcomeProducerKind.scene &&
            scenes.where((s) => s.id == outcome.producerId).length == 1
        ? outcome.producerId
        : null,
  );
}
