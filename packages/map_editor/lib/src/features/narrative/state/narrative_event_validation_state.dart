import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

@immutable
final class NarrativeEventValidationItem {
  const NarrativeEventValidationItem(this.diagnostic);

  final NarrativeEventValidationDiagnostic diagnostic;

  bool get actionable =>
      diagnostic.action != NarrativeEventValidationAction.none &&
      diagnostic.destination.kind !=
          NarrativeEventValidationDestinationKind.unavailable;
}

@immutable
final class NarrativeEventValidationState {
  NarrativeEventValidationState._({
    required Map<String, List<NarrativeEventValidationItem>> byEventId,
    required List<NarrativeEventValidationItem> global,
  })  : _byEventId =
            Map<String, List<NarrativeEventValidationItem>>.unmodifiable({
          for (final entry in byEventId.entries)
            entry.key:
                List<NarrativeEventValidationItem>.unmodifiable(entry.value),
        }),
        global = List<NarrativeEventValidationItem>.unmodifiable(global);

  factory NarrativeEventValidationState.fromReport(
    NarrativeEventValidationReport report,
  ) {
    final byEventId = <String, List<NarrativeEventValidationItem>>{};
    final global = <NarrativeEventValidationItem>[];
    for (final diagnostic in report.diagnostics) {
      final item = NarrativeEventValidationItem(diagnostic);
      final eventId = diagnostic.eventId;
      if (eventId == null) {
        global.add(item);
      } else {
        byEventId.putIfAbsent(eventId, () => []).add(item);
      }
    }
    return NarrativeEventValidationState._(
      byEventId: byEventId,
      global: global,
    );
  }

  final Map<String, List<NarrativeEventValidationItem>> _byEventId;
  final List<NarrativeEventValidationItem> global;

  List<NarrativeEventValidationItem> forEvent(String? eventId) {
    if (eventId == null) return const [];
    return _byEventId[eventId] ?? const [];
  }
}

@immutable
final class NarrativeEventValidationSnapshot {
  const NarrativeEventValidationSnapshot({
    required this.registry,
    required this.catalog,
    required this.report,
    required this.state,
    this.recalculatedEventIds = const {},
  });

  final NarrativeEventRegistry registry;
  final NarrativeEventProjectCatalog catalog;
  final NarrativeEventValidationReport report;
  final NarrativeEventValidationState state;
  final Set<String> recalculatedEventIds;
}
