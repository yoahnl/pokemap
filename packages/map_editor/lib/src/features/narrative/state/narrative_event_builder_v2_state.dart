import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import '../../../application/models/narrative_event_map_bridge_models.dart';
import 'narrative_event_map_bridge_state.dart';

/// Human-facing project-list filters for Event Builder V2.
///
/// The enum deliberately describes author concepts rather than registry or
/// migration implementation details. Filtering never reads debug IDs.
enum NarrativeEventBuilderV2Filter {
  all,
  active,
  drafts,
  attention,
  oldFormat,
}

extension NarrativeEventBuilderV2FilterLabel on NarrativeEventBuilderV2Filter {
  String get label => switch (this) {
        NarrativeEventBuilderV2Filter.all => 'Tous les événements',
        NarrativeEventBuilderV2Filter.active => 'Actifs',
        NarrativeEventBuilderV2Filter.drafts => 'Brouillons',
        NarrativeEventBuilderV2Filter.attention => 'À corriger',
        NarrativeEventBuilderV2Filter.oldFormat => 'Ancien format à convertir',
      };
}

@immutable
final class NarrativeEventLifecyclePresentation {
  const NarrativeEventLifecyclePresentation({
    required this.label,
    required this.description,
    required this.isDraft,
    required this.isRuntimeEnabled,
  });

  final String label;
  final String description;
  final bool isDraft;
  final bool isRuntimeEnabled;

  bool get isPublished => !isDraft;
}

NarrativeEventLifecyclePresentation narrativeEventLifecyclePresentation(
  NarrativeEventProjectSummary event,
) {
  if (event.status == NarrativeEventProjectStatus.draftIncomplete) {
    return const NarrativeEventLifecyclePresentation(
      label: 'Brouillon',
      description: 'Non publié et jamais joué par le runtime.',
      isDraft: true,
      isRuntimeEnabled: false,
    );
  }
  if (event.enabled == true) {
    return const NarrativeEventLifecyclePresentation(
      label: 'Publié · actif',
      description: 'Publié et joué par le runtime.',
      isDraft: false,
      isRuntimeEnabled: true,
    );
  }
  return const NarrativeEventLifecyclePresentation(
    label: 'Publié · inactif',
    description: 'Publié, mais ignoré par le runtime tant qu’il reste inactif.',
    isDraft: false,
    isRuntimeEnabled: false,
  );
}

typedef SelectNarrativeEventBuilderV2Event = bool Function({
  required String eventId,
  required NarrativeEventGroupContext groupContext,
});

/// Immutable UI projection of the canonical project-level read model.
///
/// It owns only list presentation state. In particular, Event selection is
/// not stored here: [NarrativeEventMapBridgeState] remains its single owner so
/// Map Editor round trips and the Event Builder cannot diverge.
@immutable
final class NarrativeEventBuilderV2State {
  const NarrativeEventBuilderV2State({
    required this.readModel,
    this.query = '',
    this.filter = NarrativeEventBuilderV2Filter.all,
    this.selectedCompatibilityStableKey,
  });

  final NarrativeEventBuilderProjectReadModel readModel;
  final String query;
  final NarrativeEventBuilderV2Filter filter;

  /// Local selection only for compatibility projections that have no V2
  /// Event identity and therefore cannot be owned by the Phase G bridge.
  final String? selectedCompatibilityStableKey;

  List<NarrativeEventProjectGroup> get visibleGroups {
    final normalizedQuery = _normalizeHumanSearch(query);
    final groups = <NarrativeEventProjectGroup>[];
    for (final group in readModel.groups) {
      final events = _visibleEventsIn(group, normalizedQuery);
      if (events.isEmpty) continue;
      groups.add(
        NarrativeEventProjectGroup(
          stableKey: group.stableKey,
          label: group.label,
          kind: group.kind,
          events: events,
        ),
      );
    }
    return List.unmodifiable(groups);
  }

  List<NarrativeEventProjectSummary> get visibleEvents => List.unmodifiable([
        for (final group in visibleGroups) ...group.events,
      ]);

  bool get isProjectEmpty => readModel.events.isEmpty;

  bool get hasNoMatchingEvents => !isProjectEmpty && visibleEvents.isEmpty;

  /// Fails closed for an invalid project snapshot and for compatibility-only
  /// projections. This never routes back to the legacy authoring surface.
  bool get isReadOnly =>
      readModel.diagnostics.any(
        (diagnostic) =>
            diagnostic.severity == NarrativeEventProjectSummarySeverity.error,
      ) ||
      (readModel.events.isNotEmpty &&
          readModel.events.every((event) => event.readOnly));

  NarrativeEventBuilderV2State withQuery(String value) {
    return NarrativeEventBuilderV2State(
      readModel: readModel,
      query: value,
      filter: filter,
      selectedCompatibilityStableKey: selectedCompatibilityStableKey,
    );
  }

  NarrativeEventBuilderV2State withFilter(
    NarrativeEventBuilderV2Filter value,
  ) {
    return NarrativeEventBuilderV2State(
      readModel: readModel,
      query: query,
      filter: value,
      selectedCompatibilityStableKey: selectedCompatibilityStableKey,
    );
  }

  NarrativeEventBuilderV2State withReadModel(
    NarrativeEventBuilderProjectReadModel value,
  ) {
    final compatibilityKey = selectedCompatibilityStableKey;
    final compatibilitySelection = compatibilityKey == null
        ? null
        : value.eventByStableKey(compatibilityKey)?.readOnly == true
            ? compatibilityKey
            : null;
    return NarrativeEventBuilderV2State(
      readModel: value,
      query: query,
      filter: filter,
      selectedCompatibilityStableKey: compatibilitySelection,
    );
  }

  NarrativeEventBuilderV2State withCompatibilitySelection(String? stableKey) {
    return NarrativeEventBuilderV2State(
      readModel: readModel,
      query: query,
      filter: filter,
      selectedCompatibilityStableKey: stableKey,
    );
  }

  List<NarrativeEventProjectSummary> _visibleEventsIn(
    NarrativeEventProjectGroup group,
    String normalizedQuery,
  ) {
    return List.unmodifiable([
      for (final event in group.events)
        if (_matchesFilter(event) &&
            _matchesHumanQuery(event, group, normalizedQuery))
          event,
    ]);
  }

  bool _matchesFilter(NarrativeEventProjectSummary event) {
    return switch (filter) {
      NarrativeEventBuilderV2Filter.all => true,
      NarrativeEventBuilderV2Filter.active => event.enabled == true,
      NarrativeEventBuilderV2Filter.drafts =>
        event.origin == NarrativeEventProjectOrigin.v2 &&
            event.status == NarrativeEventProjectStatus.draftIncomplete,
      NarrativeEventBuilderV2Filter.attention =>
        event.origin == NarrativeEventProjectOrigin.v2 &&
            _requiresAttention(event.status),
      NarrativeEventBuilderV2Filter.oldFormat =>
        event.origin != NarrativeEventProjectOrigin.v2,
    };
  }
}

/// Ephemeral list controller. Registry writes and the selected Event stay
/// outside this controller.
final class NarrativeEventBuilderV2Controller {
  NarrativeEventBuilderV2Controller({
    required NarrativeEventBuilderProjectReadModel readModel,
    required SelectNarrativeEventBuilderV2Event selectEvent,
  })  : _selectEvent = selectEvent,
        state = NarrativeEventBuilderV2State(readModel: readModel);

  final SelectNarrativeEventBuilderV2Event _selectEvent;
  NarrativeEventBuilderV2State state;

  void replaceReadModel(NarrativeEventBuilderProjectReadModel readModel) {
    state = state.withReadModel(readModel);
  }

  void setQuery(String query) {
    state = state.withQuery(query);
  }

  void setFilter(NarrativeEventBuilderV2Filter filter) {
    state = state.withFilter(filter);
  }

  void resetFilters() {
    state = state.withQuery('').withFilter(NarrativeEventBuilderV2Filter.all);
  }

  /// Requests selection through the Phase G bridge and never mirrors the
  /// result locally.
  bool selectEvent(
    String stableKey, {
    NarrativeEventGroupContext? groupContext,
  }) {
    final event = state.readModel.eventByStableKey(stableKey);
    final eventId = event?.eventId;
    if (event == null) return false;
    if (event.readOnly || eventId == null) {
      if (!event.readOnly) return false;
      state = state.withCompatibilitySelection(event.stableKey);
      return true;
    }
    if (state.isReadOnly) return false;

    final derivedContext = narrativeEventGroupContextForSummary(event);
    final requestedContext = groupContext ?? derivedContext;
    if (event.source.source != null && requestedContext != derivedContext) {
      return false;
    }
    final selected = _selectEvent(
      eventId: eventId,
      groupContext: requestedContext,
    );
    if (selected) {
      state = state.withCompatibilitySelection(null);
    }
    return selected;
  }
}

/// Converts one canonical summary into the exact Phase G navigation context.
/// A present spatial source owns its map; all non-spatial and unconfigured
/// Events use the global context unless a caller supplies a creation context.
NarrativeEventGroupContext narrativeEventGroupContextForSummary(
  NarrativeEventProjectSummary event,
) {
  final mapId = event.source.mapId?.trim();
  if (mapId != null && mapId.isNotEmpty) {
    return NarrativeEventGroupContext.map(mapId);
  }
  return const NarrativeEventGroupContext.global();
}

/// Resolves the bridge-owned selection against the latest project snapshot.
///
/// Rebuilding the read model therefore preserves selection by stable V2 Event
/// identity without copying that identity into another state object.
NarrativeEventProjectSummary? selectedNarrativeEventBuilderV2Event({
  required NarrativeEventBuilderV2State state,
  required NarrativeEventMapBridgeState bridgeState,
}) {
  final compatibilityKey = state.selectedCompatibilityStableKey;
  if (compatibilityKey != null) {
    final compatibility = state.readModel.eventByStableKey(compatibilityKey);
    if (compatibility?.readOnly == true) return compatibility;
  }

  final selectedId = bridgeState.selectedNarrativeEventV2Id;
  if (selectedId == null) return null;
  NarrativeEventProjectSummary? selected;
  for (final event in state.readModel.events) {
    if (event.eventId == selectedId) {
      selected = event;
      break;
    }
  }
  if (selected == null) return null;

  final selectedGroup = bridgeState.selectedGroupContext;
  if (selectedGroup != null &&
      selected.source.source != null &&
      selectedGroup != narrativeEventGroupContextForSummary(selected)) {
    return null;
  }
  return selected;
}

bool _matchesHumanQuery(
  NarrativeEventProjectSummary event,
  NarrativeEventProjectGroup group,
  String normalizedQuery,
) {
  if (normalizedQuery.isEmpty) return true;
  final humanText = <String>[
    group.label,
    event.title,
    event.source.humanSentence,
    event.source.sourceTypeLabel,
    if (event.source.mapLabel != null) event.source.mapLabel!,
    event.scene.humanLabel,
    event.conditions.humanLabel,
    event.lifecycle.humanLabel,
    event.migration.humanLabel,
    _statusLabel(event.status),
    for (final diagnostic in event.diagnostics) diagnostic.message,
  ].join(' ');
  return _normalizeHumanSearch(humanText).contains(normalizedQuery);
}

bool _requiresAttention(NarrativeEventProjectStatus status) => switch (status) {
      NarrativeEventProjectStatus.attentionRequired ||
      NarrativeEventProjectStatus.sourceMissing ||
      NarrativeEventProjectStatus.referenceInvalid ||
      NarrativeEventProjectStatus.unsupported =>
        true,
      _ => false,
    };

String _statusLabel(NarrativeEventProjectStatus status) => switch (status) {
      NarrativeEventProjectStatus.draftIncomplete => 'Brouillon à configurer',
      NarrativeEventProjectStatus.configuredDisabledReady => 'Prêt et inactif',
      NarrativeEventProjectStatus.configuredEnabledReady => 'Actif',
      NarrativeEventProjectStatus.attentionRequired => 'À corriger',
      NarrativeEventProjectStatus.sourceMissing =>
        'Élément déclencheur manquant',
      NarrativeEventProjectStatus.referenceInvalid => 'Référence à corriger',
      NarrativeEventProjectStatus.migrationAssistanceRequired =>
        'Ancien format à convertir',
      NarrativeEventProjectStatus.migrationBlocked => 'Conversion bloquée',
      NarrativeEventProjectStatus.legacyOnly => 'Ancien format à convertir',
      NarrativeEventProjectStatus.unsupported =>
        'Non disponible dans cette version',
      NarrativeEventProjectStatus.claimInvalid => 'Conversion à corriger',
    };

String _normalizeHumanSearch(String value) {
  var normalized = value.trim().toLowerCase();
  const replacements = <String, String>{
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'ç': 'c',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'ô': 'o',
    'ö': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ÿ': 'y',
    'œ': 'oe',
  };
  for (final entry in replacements.entries) {
    normalized = normalized.replaceAll(entry.key, entry.value);
  }
  return normalized;
}
