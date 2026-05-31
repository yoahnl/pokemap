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
    Map<String, String> npcDialogueOverrides = const <String, String>{},
  })  : hiddenEntityIds = Set<String>.unmodifiable(hiddenEntityIds),
        visibleEntityIds = Set<String>.unmodifiable(visibleEntityIds),
        disabledEventIds = Set<String>.unmodifiable(disabledEventIds),
        hiddenEventIds = Set<String>.unmodifiable(hiddenEventIds),
        enabledEventIds = Set<String>.unmodifiable(enabledEventIds),
        npcDialogueOverrides =
            Map<String, String>.unmodifiable(npcDialogueOverrides);

  const RuntimeWorldRuleProjectionState.empty()
      : hiddenEntityIds = const <String>{},
        visibleEntityIds = const <String>{},
        disabledEventIds = const <String>{},
        hiddenEventIds = const <String>{},
        enabledEventIds = const <String>{},
        npcDialogueOverrides = const <String, String>{};

  factory RuntimeWorldRuleProjectionState.fromResolvedEffects(
    List<WorldRuleResolvedEffect> effects,
  ) {
    final hiddenEntityIds = <String>{};
    final visibleEntityIds = <String>{};
    final disabledEventIds = <String>{};
    final hiddenEventIds = <String>{};
    final enabledEventIds = <String>{};
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
          disabledEventIds.remove(eventId);
          hiddenEventIds.remove(eventId);
          enabledEventIds.add(eventId);
        case WorldRuleEffectKind.eventDisabled:
          final eventId = effect.target.eventId;
          if (eventId == null || eventId.trim().isEmpty) {
            continue;
          }
          enabledEventIds.remove(eventId);
          hiddenEventIds.remove(eventId);
          disabledEventIds.add(eventId);
        case WorldRuleEffectKind.eventHidden:
          final eventId = effect.target.eventId;
          if (eventId == null || eventId.trim().isEmpty) {
            continue;
          }
          enabledEventIds.remove(eventId);
          disabledEventIds.remove(eventId);
          hiddenEventIds.add(eventId);
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
      npcDialogueOverrides: npcDialogueOverrides,
    );
  }

  final Set<String> hiddenEntityIds;
  final Set<String> visibleEntityIds;
  final Set<String> disabledEventIds;
  final Set<String> hiddenEventIds;
  final Set<String> enabledEventIds;
  final Map<String, String> npcDialogueOverrides;

  bool get isEmpty =>
      hiddenEntityIds.isEmpty &&
      visibleEntityIds.isEmpty &&
      disabledEventIds.isEmpty &&
      hiddenEventIds.isEmpty &&
      enabledEventIds.isEmpty &&
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
}
