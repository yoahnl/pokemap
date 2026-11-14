import 'dart:async';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';

import 'gameplay_zone_kinds.dart';

export 'gameplay_zone_kinds.dart';

part 'gameplay_zone_field_action_commands.dart';
part 'gameplay_zone_payload_commands.dart';

class GameplayZoneEditingCommands {
  GameplayZoneEditingCommands(this.document, this.project);
  final EditableMapDocument document;
  final ProjectManifest project;
  static int _sequence = 0;

  void _commit(MapData next) {
    final publish = document.configureFieldTraversal;
    final changed = <String>{
      for (final zone in [
        ...document.current.gameplayZones,
        ...next.gameplayZones,
      ])
        if (findGameplayZoneById(document.current, zone.id) !=
            findGameplayZoneById(next, zone.id))
          zone.id,
    };
    if (publish != null && changed.length == 1) {
      final id = changed.single;
      final previous = findGameplayZoneById(document.current, id);
      final zone = findGameplayZoneById(next, id);
      final action = previous == null
          ? 'gameplay_zone.create'
          : zone == null
          ? 'gameplay_zone.delete'
          : 'gameplay_zone.update';
      final parameters = <String, Object?>{
        if (zone != null) 'zone': zone.toJson(),
        if (previous != null) 'zoneId': id,
      };
      if (TriggerZoneActions.isFieldTraversalMutation(
        document.current,
        action,
        parameters,
      )) {
        unawaited(publish(next));
        return;
      }
    }
    document.commit(next);
  }

  bool get supportsDarkness =>
      document.current.spatialScene == null &&
      document.current.version != ProjectVersion.v9;
  List<GameplayZoneKind> get availableKinds => studioGameplayZoneKinds;

  List<GameplayZoneKind> availableKindsFor(MapGameplayZone zone) =>
      availableKinds
          .where(
            (kind) =>
                (zone.smartTileProvenance == null ||
                    kind != GameplayZoneKind.fieldAction) &&
                (supportsDarkness ||
                    kind != GameplayZoneKind.fieldAction ||
                    fieldTraversalDirections(zone).isNotEmpty) &&
                (supportsDarkness ||
                    zone.kind != GameplayZoneKind.fieldAction ||
                    kind == GameplayZoneKind.fieldAction),
          )
          .toList(growable: false);

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
    if (zone.kind == GameplayZoneKind.fieldAction &&
        (document.current.spatialScene != null ||
            document.current.version == ProjectVersion.v9)) {
      final action = zone.fieldAction?.actionKind;
      if (action != FieldActionZoneKind.waterfall &&
          action != FieldActionZoneKind.whirlpool) {
        return 'Choisissez un passage Cascade ou Tourbillon sur une carte 3D.';
      }
    }
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
      fieldAction: kind == GameplayZoneKind.fieldAction
          ? _initialFieldAction(area)
          : null,
      hazard: kind == GameplayZoneKind.hazard
          ? const HazardZonePayload()
          : null,
      special: kind == GameplayZoneKind.special
          ? const SpecialZonePayload()
          : null,
    );
    _commit(
      const TriggerZoneActions().createZone(document.current, zone: zone),
    );
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
      _commit(
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
    _commit(addGameplayZoneToMap(document.current, zone: zone));
    return zone;
  }

  void retype(String id, GameplayZoneKind kind) {
    final zone = selected(id);
    if (zone == null || zone.kind == kind) return;
    _commit(
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
        fieldAction: kind == GameplayZoneKind.fieldAction
            ? (zone.fieldAction ?? _initialFieldAction(zone.area))
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

  void rename(String id, String name) => _commit(
    updateGameplayZoneOnMap(document.current, zoneId: id, name: name),
  );

  void setPriority(String id, int priority) => _commit(
    updateGameplayZoneOnMap(document.current, zoneId: id, priority: priority),
  );

  void move(String id, GridPos pos) {
    if (document.isElementUnavailable('zone', id)) return;
    _commit(moveGameplayZoneOnMap(document.current, zoneId: id, pos: pos));
  }

  void resize(String id, GridSize size) {
    if (document.isElementUnavailable('zone', id)) return;
    _commit(resizeGameplayZoneOnMap(document.current, zoneId: id, size: size));
  }

  void updateEncounter(
    String id, {
    String? tableId,
    EncounterKind? encounterKind,
  }) => _updateEncounter(id, tableId: tableId, encounterKind: encounterKind);

  void updateMovement(String id, {MovementMode? requiredMode}) =>
      _updateMovement(id, requiredMode: requiredMode);

  void updateMovementEffect(
    String id, {
    MovementEffectZoneKind? effectKind,
    int? movementCost,
  }) => _updateMovementEffect(
    id,
    effectKind: effectKind,
    movementCost: movementCost,
  );

  void delete(String id) {
    if (document.isElementUnavailable('zone', id)) return;
    _commit(removeGameplayZoneFromMap(document.current, zoneId: id));
  }
}
