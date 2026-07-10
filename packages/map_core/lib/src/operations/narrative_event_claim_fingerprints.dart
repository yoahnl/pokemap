import '../models/map_event_definition.dart';
import '../models/narrative_event_registry.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/scenario_asset.dart';
import 'narrative_event_canonical_json.dart';

String computeMapEventSourceFingerprint({
  required String mapId,
  required MapEventDefinition event,
}) {
  _validateOpaqueIdentity(mapId, 'mapId');
  return 'sha256:${narrativeEventCanonicalSha256({
        'kind': 'mapEvent',
        'mapId': mapId,
        'event': event.toJson(),
      })}';
}

String computeScenarioSourceFingerprint({
  required String scenarioId,
  required String nodeId,
  required ScenarioAsset scenario,
}) {
  _validateOpaqueIdentity(scenarioId, 'scenarioId');
  _validateOpaqueIdentity(nodeId, 'nodeId');
  return 'sha256:${narrativeEventCanonicalSha256({
        'kind': 'scenarioSourceNode',
        'scenarioId': scenarioId,
        'nodeId': nodeId,
        'scenario': scenario.toJson(),
      })}';
}

String computeLegacySourceCohortId(
  NarrativeEventSourceRef source,
  Iterable<LegacySourceRef> provenances,
) {
  final sorted = provenances.toList()..sort(compareLegacySourceRefs);
  return 'lsc_${narrativeEventCanonicalSha256({
        'source': source.toJson(),
        'provenances': [
          for (final provenance in sorted) provenance.toJson(),
        ],
      })}';
}

String computeLegacySourceCohortFingerprint(
  String cohortId,
  Iterable<LegacySourceClaimMember> members,
) {
  _validateOpaqueIdentity(cohortId, 'cohortId');
  final sorted = members.toList()
    ..sort((left, right) {
      final provenance = compareLegacySourceRefs(
        left.provenance,
        right.provenance,
      );
      if (provenance != 0) return provenance;
      return compareNarrativeEventUtf16(
        left.sourceFingerprint,
        right.sourceFingerprint,
      );
    });
  return 'sha256:${narrativeEventCanonicalSha256({
        'cohortId': cohortId,
        'members': [for (final member in sorted) member.toJson()],
      })}';
}

void _validateOpaqueIdentity(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(
        value, name, 'must be non-empty and already trimmed');
  }
}
