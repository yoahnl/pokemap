import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';

class GameplayZoneEditingCommands {
  GameplayZoneEditingCommands(this.document, this.project);
  final EditableMapDocument document;
  final ProjectManifest project;
  static int _sequence = 0;

  String _id() {
    String id;
    do {
      id = 'zone-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';
    } while (document.current.gameplayZones.any((zone) => zone.id == id));
    return id;
  }

  MapGameplayZone? selected(String? id) =>
      document.current.gameplayZones.where((zone) => zone.id == id).firstOrNull;

  List<MapGameplayZone> at(GridPos position) =>
      findAllGameplayZonesAtPos(document.current, position);

  List<ProjectEncounterTable> encounterTables() => project.encounterTables
      .where((table) => !table.tags.contains('studio:unique'))
      .toList(growable: false);

  ProjectEncounterTable? tableOf(MapGameplayZone zone) {
    final id = zone.encounter?.encounterTableId;
    if (id == null || id.isEmpty) return null;
    return project.encounterTables.where((t) => t.id == id).firstOrNull;
  }

  String? coverageProblem(MapGameplayZone zone) {
    if (zone.kind != GameplayZoneKind.encounter) return null;
    final id = zone.encounter?.encounterTableId;
    if (id == null || id.isEmpty) {
      return 'Sans table de rencontres, cette zone ne déclenche rien.';
    }
    final table = tableOf(zone);
    if (table == null) {
      return 'La table de rencontres n’existe plus dans le projet.';
    }
    if (table.tags.contains('studio:unique')) {
      return 'Une rencontre unique doit être déclenchée depuis Histoire.';
    }
    if (table.encounterKind != zone.encounter?.encounterKind) {
      return 'Le type de cette zone ne correspond pas à sa table.';
    }
    return null;
  }

  MapGameplayZone place(GameplayZoneKind kind, MapRect area) {
    final zone = MapGameplayZone(
      id: _id(),
      name: defaultZoneName(kind),
      kind: kind,
      area: area,
      encounter: kind == GameplayZoneKind.encounter
          ? const EncounterZonePayload()
          : null,
      movement: kind == GameplayZoneKind.movement
          ? const MovementZonePayload()
          : null,
      movementEffect: kind == GameplayZoneKind.movementEffect
          ? const MovementEffectZonePayload()
          : null,
      hazard: kind == GameplayZoneKind.hazard
          ? const HazardZonePayload()
          : null,
      special: kind == GameplayZoneKind.special
          ? const SpecialZonePayload()
          : null,
    );
    document.commit(addGameplayZoneToMap(document.current, zone: zone));
    return zone;
  }

  MapGameplayZone? paintEncounterCells(
    Iterable<GridPos> cells, {
    required bool erase,
    String? selectedZoneId,
  }) {
    final positions = cells.toSet();
    if (positions.isEmpty) return null;
    final selectedZone = selectedZoneId == null
        ? null
        : selected(selectedZoneId);
    if (selectedZone != null &&
        selectedZone.kind == GameplayZoneKind.encounter) {
      document.commit(
        paintEncounterZoneCells(
          document.current,
          zoneId: selectedZone.id,
          cells: positions,
          erase: erase,
        ),
      );
      return selected(selectedZone.id);
    }
    if (erase) return null;
    final area = paintedEncounterBounds(positions);
    final zone = MapGameplayZone(
      id: _id(),
      name: defaultZoneName(GameplayZoneKind.encounter),
      kind: GameplayZoneKind.encounter,
      area: area,
      cellMask: paintedEncounterMask(positions, area),
      encounter: const EncounterZonePayload(),
    );
    document.commit(addGameplayZoneToMap(document.current, zone: zone));
    return zone;
  }

  void retype(String id, GameplayZoneKind kind) {
    final zone = selected(id);
    if (zone == null || zone.kind == kind) return;
    document.commit(
      updateGameplayZoneOnMap(
        document.current,
        zoneId: id,
        kind: kind,
        cellMask: kind == GameplayZoneKind.encounter ? zone.cellMask : null,
        name: zone.name == defaultZoneName(zone.kind)
            ? defaultZoneName(kind)
            : zone.name,
        encounter: kind == GameplayZoneKind.encounter
            ? (zone.encounter ?? const EncounterZonePayload())
            : null,
        movement: kind == GameplayZoneKind.movement
            ? (zone.movement ?? const MovementZonePayload())
            : null,
        movementEffect: kind == GameplayZoneKind.movementEffect
            ? (zone.movementEffect ?? const MovementEffectZonePayload())
            : null,
        hazard: kind == GameplayZoneKind.hazard
            ? (zone.hazard ?? const HazardZonePayload())
            : null,
        special: kind == GameplayZoneKind.special
            ? (zone.special ?? const SpecialZonePayload())
            : null,
      ),
    );
  }

  void rename(String id, String name) => document.commit(
    updateGameplayZoneOnMap(document.current, zoneId: id, name: name),
  );

  void setPriority(String id, int priority) => document.commit(
    updateGameplayZoneOnMap(document.current, zoneId: id, priority: priority),
  );

  void move(String id, GridPos pos) => document.commit(
    moveGameplayZoneOnMap(document.current, zoneId: id, pos: pos),
  );

  void resize(String id, GridSize size) => document.commit(
    resizeGameplayZoneOnMap(document.current, zoneId: id, size: size),
  );

  void delete(String id) =>
      document.commit(removeGameplayZoneFromMap(document.current, zoneId: id));

  void updateEncounter(
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
    document.commit(
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

  void updateMovement(String id, {MovementMode? requiredMode}) {
    final payload = selected(id)?.movement;
    if (payload == null) return;
    document.commit(
      updateGameplayZoneOnMap(
        document.current,
        zoneId: id,
        movement: payload.copyWith(
          requiredMode: requiredMode ?? payload.requiredMode,
        ),
      ),
    );
  }

  void updateMovementEffect(
    String id, {
    MovementEffectZoneKind? effectKind,
    int? movementCost,
  }) {
    final payload = selected(id)?.movementEffect;
    if (payload == null) return;
    document.commit(
      updateGameplayZoneOnMap(
        document.current,
        zoneId: id,
        movementEffect: payload.copyWith(
          effectKind: effectKind ?? payload.effectKind,
          movementCost: movementCost ?? payload.movementCost,
        ),
      ),
    );
  }

  void updateHazard(String id, {HazardKind? hazardKind, int? damagePerStep}) {
    final payload = selected(id)?.hazard;
    if (payload == null) return;
    document.commit(
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

String defaultZoneName(GameplayZoneKind kind) => switch (kind) {
  GameplayZoneKind.encounter => 'Zone de rencontres',
  GameplayZoneKind.movement => 'Zone de déplacement',
  GameplayZoneKind.movementEffect => 'Zone à effet',
  GameplayZoneKind.hazard => 'Zone dangereuse',
  GameplayZoneKind.special => 'Zone spéciale',
  GameplayZoneKind.custom => 'Zone héritée',
};

const studioGameplayZoneKinds = [
  GameplayZoneKind.encounter,
  GameplayZoneKind.movement,
  GameplayZoneKind.movementEffect,
  GameplayZoneKind.hazard,
  GameplayZoneKind.special,
];
