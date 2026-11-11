import 'package:map_core/map_core_domain.dart';

import '../domain/event_record_view.dart';
import 'event_labels.dart';

const eventAllOwnerPages = '';
const eventDefaultParallelCadenceMs = 1000;

String? eventResetNote(NarrativeEventRecord record) =>
    record.reusePolicy == NarrativeEventReusePolicy.reusable
    ? 'Sans effet : l’événement peut déjà se rejouer.'
    : null;

String eventResetChoice(NarrativeEventResetPolicy policy) => switch (policy) {
  NarrativeEventResetNever() => 'never',
  NarrativeEventResetOnMapReentry() => 'map',
  NarrativeEventResetOnOutcomeReceived() => 'outcome',
};

NarrativeEventResetPolicy? eventResetWithoutOutcome(String choice) =>
    switch (choice) {
      'never' => const NarrativeEventResetPolicy.never(),
      'map' => const NarrativeEventResetPolicy.onMapReentry(),
      _ => null,
    };

bool eventAllowsParallel(NarrativeEventRecord record) =>
    record.source?.kind == NarrativeEventSourceKind.entityAutorun ||
    record.source?.kind == NarrativeEventSourceKind.mapEnter;

NarrativeEventParallelPolicy? eventParallelChoice(String choice) =>
    choice == 'parallel'
    ? NarrativeEventParallelPolicy(cadenceMs: eventDefaultParallelCadenceMs)
    : null;

NarrativeEventParallelPolicy? eventParallelCadence(
  NarrativeEventParallelPolicy policy,
  String input,
) {
  final cadence = int.tryParse(input);
  if (cadence == null || cadence < 100 || cadence > 60000) return null;
  return NarrativeEventParallelPolicy(
    cadenceMs: cadence,
    ownerVariantId: policy.ownerVariantId,
  );
}

String eventParallelOwnerChoice(NarrativeEventParallelPolicy policy) =>
    policy.ownerVariantId ?? eventAllOwnerPages;

NarrativeEventParallelPolicy eventParallelOwnerPage(
  NarrativeEventParallelPolicy policy,
  String choice,
) => NarrativeEventParallelPolicy(
  cadenceMs: policy.cadenceMs,
  ownerVariantId: choice == eventAllOwnerPages ? null : choice,
);

Map<String, String> eventOwnerPages(
  NarrativeEventRecord record,
  Iterable<MapData> maps,
) {
  final source = record.source;
  if (source?.kind != NarrativeEventSourceKind.entityAutorun) return const {};
  final matches = maps.where((map) => map.id == eventMapId(source)).toList();
  if (matches.length != 1) return const {};
  final owners = matches.single.entities
      .where((entity) => entity.id == eventOwnerId(source))
      .toList();
  if (owners.length != 1) return const {};
  final variants =
      owners.single.presentation?.variants ??
      const <MapEntityPresentationVariant>[];
  return {
    for (var index = 0; index < variants.length; index++)
      variants[index].id: 'Page ${index + 1}',
  };
}
