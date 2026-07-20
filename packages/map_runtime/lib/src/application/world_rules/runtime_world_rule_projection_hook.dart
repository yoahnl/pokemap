import 'package:map_core/map_core.dart';

final class RuntimeWorldRuleProjectionHook {
  const RuntimeWorldRuleProjectionHook();

  RuntimeWorldRuleProjectionState resolve({
    required ProjectManifest project,
    required GameState gameState,
    required MapData map,
  }) {
    final effects = projectWorldRuleEffects(
      project,
      gameState,
      maps: [map],
      mapId: map.id,
    );
    return RuntimeWorldRuleProjectionState.fromResolvedEffects(effects);
  }
}

final class RuntimeWorldRuleProjectionState {
  RuntimeWorldRuleProjectionState({
    Set<String> hiddenEntityIds = const <String>{},
    Set<String> visibleEntityIds = const <String>{},
    Set<String> disabledEventIds = const <String>{},
    Set<String> hiddenEventIds = const <String>{},
    Set<String> enabledEventIds = const <String>{},
    Set<String> disabledNarrativeEventIds = const <String>{},
    Set<String> hiddenNarrativeEventIds = const <String>{},
    Set<String> enabledNarrativeEventIds = const <String>{},
    Map<String, String> npcDialogueOverrides = const <String, String>{},
  })  : hiddenEntityIds = Set<String>.unmodifiable(hiddenEntityIds),
        visibleEntityIds = Set<String>.unmodifiable(visibleEntityIds),
        disabledEventIds = Set<String>.unmodifiable(disabledEventIds),
        hiddenEventIds = Set<String>.unmodifiable(hiddenEventIds),
        enabledEventIds = Set<String>.unmodifiable(enabledEventIds),
        disabledNarrativeEventIds =
            Set<String>.unmodifiable(disabledNarrativeEventIds),
        hiddenNarrativeEventIds =
            Set<String>.unmodifiable(hiddenNarrativeEventIds),
        enabledNarrativeEventIds =
            Set<String>.unmodifiable(enabledNarrativeEventIds),
        npcDialogueOverrides =
            Map<String, String>.unmodifiable(npcDialogueOverrides);

  const RuntimeWorldRuleProjectionState.empty()
      : hiddenEntityIds = const <String>{},
        visibleEntityIds = const <String>{},
        disabledEventIds = const <String>{},
        hiddenEventIds = const <String>{},
        enabledEventIds = const <String>{},
        disabledNarrativeEventIds = const <String>{},
        hiddenNarrativeEventIds = const <String>{},
        enabledNarrativeEventIds = const <String>{},
        npcDialogueOverrides = const <String, String>{};

  factory RuntimeWorldRuleProjectionState.fromResolvedEffects(
    List<WorldRuleResolvedEffect> effects,
  ) {
    final hiddenEntityIds = <String>{};
    final visibleEntityIds = <String>{};
    final disabledEventIds = <String>{};
    final hiddenEventIds = <String>{};
    final enabledEventIds = <String>{};
    final disabledNarrativeEventIds = <String>{};
    final hiddenNarrativeEventIds = <String>{};
    final enabledNarrativeEventIds = <String>{};
    final npcDialogueOverrides = <String, String>{};

    for (final effect in effects) {
      switch (effect.effect.kind) {
        case WorldRuleEffectKind.entityVisible:
          final entityId = effect.target.entityId;
          if (entityId == null || entityId.trim().isEmpty) {
            continue;
          }
          hiddenEntityIds.remove(entityId);
          visibleEntityIds.add(entityId);
        case WorldRuleEffectKind.entityHidden:
          final entityId = effect.target.entityId;
          if (entityId == null || entityId.trim().isEmpty) {
            continue;
          }
          visibleEntityIds.remove(entityId);
          hiddenEntityIds.add(entityId);
        case WorldRuleEffectKind.eventEnabled:
          final eventId = effect.target.eventId;
          if (eventId == null || eventId.trim().isEmpty) {
            continue;
          }
          if (effect.target.kind == WorldRuleTargetKind.narrativeEvent) {
            disabledNarrativeEventIds.remove(eventId);
            hiddenNarrativeEventIds.remove(eventId);
            enabledNarrativeEventIds.add(eventId);
          } else {
            disabledEventIds.remove(eventId);
            hiddenEventIds.remove(eventId);
            enabledEventIds.add(eventId);
          }
        case WorldRuleEffectKind.eventDisabled:
          final eventId = effect.target.eventId;
          if (eventId == null || eventId.trim().isEmpty) {
            continue;
          }
          if (effect.target.kind == WorldRuleTargetKind.narrativeEvent) {
            enabledNarrativeEventIds.remove(eventId);
            hiddenNarrativeEventIds.remove(eventId);
            disabledNarrativeEventIds.add(eventId);
          } else {
            enabledEventIds.remove(eventId);
            hiddenEventIds.remove(eventId);
            disabledEventIds.add(eventId);
          }
        case WorldRuleEffectKind.eventHidden:
          final eventId = effect.target.eventId;
          if (eventId == null || eventId.trim().isEmpty) {
            continue;
          }
          if (effect.target.kind == WorldRuleTargetKind.narrativeEvent) {
            enabledNarrativeEventIds.remove(eventId);
            disabledNarrativeEventIds.remove(eventId);
            hiddenNarrativeEventIds.add(eventId);
          } else {
            enabledEventIds.remove(eventId);
            disabledEventIds.remove(eventId);
            hiddenEventIds.add(eventId);
          }
        case WorldRuleEffectKind.npcDialogueOverride:
          final entityId = effect.target.entityId;
          final dialogueId = effect.effect.dialogueId;
          if (entityId == null ||
              entityId.trim().isEmpty ||
              dialogueId == null ||
              dialogueId.trim().isEmpty) {
            continue;
          }
          npcDialogueOverrides[entityId] = dialogueId;
      }
    }

    return RuntimeWorldRuleProjectionState(
      hiddenEntityIds: hiddenEntityIds,
      visibleEntityIds: visibleEntityIds,
      disabledEventIds: disabledEventIds,
      hiddenEventIds: hiddenEventIds,
      enabledEventIds: enabledEventIds,
      disabledNarrativeEventIds: disabledNarrativeEventIds,
      hiddenNarrativeEventIds: hiddenNarrativeEventIds,
      enabledNarrativeEventIds: enabledNarrativeEventIds,
      npcDialogueOverrides: npcDialogueOverrides,
    );
  }

  final Set<String> hiddenEntityIds;
  final Set<String> visibleEntityIds;
  final Set<String> disabledEventIds;
  final Set<String> hiddenEventIds;
  final Set<String> enabledEventIds;
  final Set<String> disabledNarrativeEventIds;
  final Set<String> hiddenNarrativeEventIds;
  final Set<String> enabledNarrativeEventIds;
  final Map<String, String> npcDialogueOverrides;

  bool get isEmpty =>
      hiddenEntityIds.isEmpty &&
      visibleEntityIds.isEmpty &&
      disabledEventIds.isEmpty &&
      hiddenEventIds.isEmpty &&
      enabledEventIds.isEmpty &&
      disabledNarrativeEventIds.isEmpty &&
      hiddenNarrativeEventIds.isEmpty &&
      enabledNarrativeEventIds.isEmpty &&
      npcDialogueOverrides.isEmpty;

  bool isMapEntityVisible(
    MapEntity entity, {
    bool defaultVisible = true,
  }) {
    if (hiddenEntityIds.contains(entity.id)) {
      return false;
    }
    if (visibleEntityIds.contains(entity.id)) {
      return true;
    }
    return defaultVisible;
  }

  bool isMapEventHidden(
    MapEventDefinition event, {
    bool defaultHidden = false,
  }) {
    if (hiddenEventIds.contains(event.id)) {
      return true;
    }
    if (enabledEventIds.contains(event.id)) {
      return false;
    }
    return defaultHidden;
  }

  bool canTriggerMapEvent(
    MapEventDefinition event, {
    bool defaultEnabled = true,
  }) {
    if (hiddenEventIds.contains(event.id)) {
      return false;
    }
    if (disabledEventIds.contains(event.id)) {
      return false;
    }
    if (enabledEventIds.contains(event.id)) {
      return true;
    }
    return defaultEnabled;
  }

  String? dialogueOverrideForEntity(String entityId) {
    return npcDialogueOverrides[entityId];
  }

  bool canDispatchNarrativeEvent(
    String eventId, {
    bool defaultEnabled = true,
  }) {
    if (hiddenNarrativeEventIds.contains(eventId) ||
        disabledNarrativeEventIds.contains(eventId)) {
      return false;
    }
    if (enabledNarrativeEventIds.contains(eventId)) return true;
    return defaultEnabled;
  }
}
