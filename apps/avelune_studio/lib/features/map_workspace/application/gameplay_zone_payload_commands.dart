part of 'gameplay_zone_editing_commands.dart';

extension GameplayZonePayloadCommands on GameplayZoneEditingCommands {
  void _updateEncounter(
    String id, {
    String? tableId,
    EncounterKind? encounterKind,
  }) {
    final payload = selected(id)?.encounter;
    if (payload == null) return;
    final selectedTable = tableId == null
        ? null
        : encounterTables().where((table) => table.id == tableId).firstOrNull;
    if (tableId != null && selectedTable == null) return;
    _commit(
      updateGameplayZoneOnMap(
        document.current,
        zoneId: id,
        encounter: payload.copyWith(
          encounterTableId: tableId ?? payload.encounterTableId,
          encounterKind:
              encounterKind ??
              selectedTable?.encounterKind ??
              payload.encounterKind,
        ),
      ),
    );
  }

  void _updateMovement(String id, {MovementMode? requiredMode}) {
    final payload = selected(id)?.movement;
    if (payload == null) return;
    _commit(
      const TriggerZoneActions().setMovementPayload(
        document.current,
        zoneId: id,
        payload: payload.copyWith(
          requiredMode: requiredMode ?? payload.requiredMode,
        ),
      ),
    );
  }

  void _updateMovementEffect(
    String id, {
    MovementEffectZoneKind? effectKind,
    int? movementCost,
  }) {
    final payload = selected(id)?.movementEffect;
    if (payload == null) return;
    _commit(
      const TriggerZoneActions().setMovementEffectPayload(
        document.current,
        zoneId: id,
        payload: payload.copyWith(
          effectKind: effectKind ?? payload.effectKind,
          movementCost: movementCost ?? payload.movementCost,
        ),
      ),
    );
  }

  void updateHazard(String id, {HazardKind? hazardKind, int? damagePerStep}) {
    final payload = selected(id)?.hazard;
    if (payload == null) return;
    _commit(
      updateGameplayZoneOnMap(
        document.current,
        zoneId: id,
        hazard: payload.copyWith(
          hazardKind: hazardKind ?? payload.hazardKind,
          damagePerStep: damagePerStep ?? payload.damagePerStep,
        ),
      ),
    );
  }
}
