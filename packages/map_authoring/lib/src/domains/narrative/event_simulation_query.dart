import 'package:map_core/map_core.dart';

import '../../contracts/query_page.dart';
import '../../contracts/query_request.dart';
import '../../workspace/project_snapshot.dart';
import '../assets/project_media_store.dart';
import 'narrative_authoring_exception.dart';

AuthoringQueryPage queryEventSimulation(
  ProjectSnapshot snapshot,
  AuthoringQueryRequest request,
) {
  Never reject() => throw NarrativeAuthoringException(
        'event_v2.simulation_invalid',
        'Event simulation requires one unfiltered event get query with typed facts, retained map instances and consumed or in-flight event IDs.',
      );
  if (request.resourceKind != 'eventV2' ||
      request.operation != AuthoringQueryOperation.get ||
      request.ids.length != 1 ||
      request.cursor != null ||
      request.filters.isNotEmpty ||
      request.fieldMask.isNotEmpty ||
      request.sort.isNotEmpty ||
      request.searchTerm != null ||
      request.extensions.keys
          .any((key) => key != 'actionId' && key != 'parameters')) {
    reject();
  }
  final raw = request.extensions['parameters'] ?? const {};
  const fields = {
    'factNarrativeValues',
    'mapInstanceWorldState',
    'consumedNarrativeEventIds',
    'inFlightNarrativeEventIds'
  };
  if (raw is! Map || raw.keys.any((key) => !fields.contains(key))) reject();
  if (raw.containsKey('mapInstanceWorldState') &&
      raw['mapInstanceWorldState'] is! Map) reject();
  final values = raw['factNarrativeValues'] ?? const {};
  if (values is! Map || values.entries.any((entry) => entry.key is! String))
    reject();
  Set<String> identities(String field) {
    final ids = raw[field] ?? const [];
    if (ids is! List ||
        ids.any((id) => id is! String || id.isEmpty || id.trim() != id) ||
        ids.toSet().length != ids.length) reject();
    return ids.cast<String>().toSet();
  }

  final registry = snapshot.manifest.eventRegistry;
  try {
    final mediaBytes =
        snapshot.findResourceBytes(projectMediaCatalogResourceIdentity);
    final presentationMediaCatalog =
        mediaBytes == null ? null : decodeProjectMediaCatalogBytes(mediaBytes);
    final report = simulateNarrativeEventDispatch(
      registryResult: registry == null
          ? EventRegistryDecodeResult.absent()
          : EventRegistryDecodeResult.decoded(registry),
      projectCatalog: buildNarrativeEventProjectCatalog(
          project: snapshot.manifest, maps: snapshot.maps,
          presentationMediaCatalog: presentationMediaCatalog),
      project: snapshot.manifest,
      maps: snapshot.maps,
      facts: snapshot.manifest.facts,
      input: NarrativeEventSimulationInput(
        targetEventId: request.ids.single,
        factNarrativeValues: {
          for (final entry in values.entries)
            entry.key as String: NarrativeValue.fromJson(entry.value)
        },
        mapInstanceWorldState: raw['mapInstanceWorldState'] == null
            ? const MapInstanceWorldState.empty()
            : MapInstanceWorldState.fromJson(
                Map<String, dynamic>.from(raw['mapInstanceWorldState'] as Map)),
        consumedNarrativeEventIds: identities('consumedNarrativeEventIds'),
        inFlightNarrativeEventIds: identities('inFlightNarrativeEventIds'),
      ),
      legacyClaimIndex: registry?.mode == EventSystemMode.dualRead
          ? buildValidatedLegacyClaimIndex(registry!)
          : null,
    );
    return AuthoringQueryPage(
        snapshotRevision: snapshot.revision,
        items: [
          {
            'id': request.ids.single,
            'proofKind': 'simulation',
            'mountedPlayer': false,
            'effects': 'none',
            'simulation': report.toJson()
          }
        ],
        totalAvailable: 1);
  } on FormatException {
    reject();
  } on ArgumentError {
    reject();
  } on TypeError {
    reject();
  }
}
