import 'package:meta/meta.dart' show immutable;

import '../models/game_state.dart';
import '../models/narrative_event_source_ref.dart';
import '../operations/narrative_event_registry_codec.dart';
import '../operations/narrative_fact_runtime.dart';
import 'narrative_event_validation_read_model.dart';

enum NarrativeEventReachabilityStatus {
  reachable,
  unreachable,
  runtimeUnknown,
  blocked,
}

@immutable
final class NarrativeEventReachabilityRuntimeSnapshot {
  const NarrativeEventReachabilityRuntimeSnapshot.unknown()
      : isComplete = false,
        gameState = null,
        factResolver = null,
        claimIndex = null,
        inFlightNarrativeEventIds = const <String>{};

  NarrativeEventReachabilityRuntimeSnapshot.complete({
    required this.gameState,
    required this.factResolver,
    this.claimIndex,
    Set<String> inFlightNarrativeEventIds = const <String>{},
  })  : isComplete = true,
        inFlightNarrativeEventIds = Set.unmodifiable(inFlightNarrativeEventIds);

  final bool isComplete;
  final GameState? gameState;
  final NarrativeFactRuntimeResolver? factResolver;
  final ValidatedLegacyClaimIndex? claimIndex;
  final Set<String> inFlightNarrativeEventIds;
}

@immutable
final class NarrativeEventSourceReachability {
  NarrativeEventSourceReachability({
    required this.source,
    required List<String> orderedEventIds,
    required List<String> disabledEventIds,
    required List<String> draftEventIds,
    required List<String> claimedTargetEventIds,
    required this.hasOrderingConflict,
    required this.status,
    required List<String> reasons,
    this.selectedEventId,
  })  : orderedEventIds = List.unmodifiable(orderedEventIds),
        disabledEventIds = List.unmodifiable(disabledEventIds),
        draftEventIds = List.unmodifiable(draftEventIds),
        claimedTargetEventIds = List.unmodifiable(claimedTargetEventIds),
        reasons = List.unmodifiable(reasons);

  final NarrativeEventSourceRef source;
  final List<String> orderedEventIds;
  final List<String> disabledEventIds;
  final List<String> draftEventIds;
  final List<String> claimedTargetEventIds;
  final bool hasOrderingConflict;
  final NarrativeEventReachabilityStatus status;
  final List<String> reasons;
  final String? selectedEventId;

  Map<String, Object?> toDebugJson() => {
        'source': source.toJson(),
        'orderedEventIds': orderedEventIds,
        'disabledEventIds': disabledEventIds,
        'draftEventIds': draftEventIds,
        'claimedTargetEventIds': claimedTargetEventIds,
        'hasOrderingConflict': hasOrderingConflict,
        'status': status.name,
        'reasons': reasons,
        if (selectedEventId != null) 'selectedEventId': selectedEventId,
      };
}

@immutable
final class NarrativeEventReachabilityReport {
  NarrativeEventReachabilityReport({
    required List<NarrativeEventSourceReachability> sources,
    required List<NarrativeEventValidationDiagnostic> diagnostics,
  })  : sources = List.unmodifiable(sources),
        diagnostics = List.unmodifiable(diagnostics);

  final List<NarrativeEventSourceReachability> sources;
  final List<NarrativeEventValidationDiagnostic> diagnostics;

  Map<String, Object?> toDebugJson() => {
        'sources': [for (final source in sources) source.toDebugJson()],
        'diagnostics': [
          for (final diagnostic in diagnostics) diagnostic.toDebugJson(),
        ],
      };
}
