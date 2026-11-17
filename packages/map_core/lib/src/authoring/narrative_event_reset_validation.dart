import '../models/narrative_event_definition.dart';
import '../models/narrative_event_source_ref.dart';
import 'narrative_event_authoring_contract.dart';

NarrativeEventAuthoringDiagnostic? validateNarrativeEventAuthoringReset({
  required NarrativeEventAuthoringContext context,
  required NarrativeEventResetPolicy policy,
  required NarrativeEventReusePolicy? reusePolicy,
  required NarrativeEventSourceRef? source,
}) {
  if (policy is NarrativeEventResetNever) return null;
  if (reusePolicy != NarrativeEventReusePolicy.oneShot) {
    return NarrativeEventAuthoringDiagnostic(
      code: 'resetRequiresOneShot',
      message: 'Le réarmement nécessite un événement à usage unique.',
      path: 'resetPolicy',
    );
  }
  if (policy is NarrativeEventResetOnMapReentry &&
      source?.kind == NarrativeEventSourceKind.outcomeReceived) {
    return NarrativeEventAuthoringDiagnostic(
      code: 'mapReentryRequiresSpatialSource',
      message: 'La réentrée de map nécessite une source spatiale.',
      path: 'resetPolicy',
    );
  }
  if (policy is NarrativeEventResetOnOutcomeReceived &&
      !context.catalog.outcomeSources.options.any(
        (option) => option.outcome == policy.outcome && option.selectable,
      )) {
    return NarrativeEventAuthoringDiagnostic(
      code: 'resetOutcomeMissing',
      message: 'Le résultat choisi pour réarmer cet événement est introuvable.',
      path: 'resetPolicy.outcome',
    );
  }
  return null;
}
