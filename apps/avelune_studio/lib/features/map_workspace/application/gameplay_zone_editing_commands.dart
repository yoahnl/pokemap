import 'dart:async';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';

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

  FieldActionZonePayload _initialFieldAction(MapRect area) {
    if (supportsDarkness) {
      return const FieldActionZonePayload(
        actionKind: FieldActionZoneKind.darkness,
        darkness: DarknessZonePayload(opacity: .7),
      );
    }
    final horizontal = area.size.width >= 3;
    if (!horizontal && area.size.height < 3) {
      throw const ValidationException(
        'Dessinez au moins trois cases pour un passage Cascade ou Tourbillon.',
      );
    }
    return FieldActionZonePayload(
      actionKind: FieldActionZoneKind.waterfall,
      waterfall: WaterfallZonePayload(
        entry: const GridPos(x: 0, y: 0),
        path: [
          horizontal ? const GridPos(x: 1, y: 0) : const GridPos(x: 0, y: 1),
        ],
        exit: horizontal
            ? const GridPos(x: 2, y: 0)
            : const GridPos(x: 0, y: 2),
        direction: horizontal
            ? MapConnectionDirection.east
            : MapConnectionDirection.south,
      ),
    );
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

  void delete(String id) {
    if (document.isElementUnavailable('zone', id)) return;
    _commit(removeGameplayZoneFromMap(document.current, zoneId: id));
  }

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

  void updateMovement(String id, {MovementMode? requiredMode}) {
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

  void updateMovementEffect(
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

  List<MapConnectionDirection> fieldTraversalDirections(MapGameplayZone zone) =>
      [
        if (zone.area.size.height >= 3) ...[
          MapConnectionDirection.north,
          MapConnectionDirection.south,
        ],
        if (zone.area.size.width >= 3) ...[
          MapConnectionDirection.east,
          MapConnectionDirection.west,
        ],
      ];

  void configureWaterfall(
    String id, {
    MapConnectionDirection? direction,
    bool? requiresSurf,
    int? line,
    int? entryIndex,
    int? exitIndex,
  }) => _configureFieldTraversal(
    id,
    FieldActionZoneKind.waterfall,
    direction: direction,
    requiresSurf: requiresSurf,
    line: line,
    entryIndex: entryIndex,
    exitIndex: exitIndex,
  );

  void configureWhirlpool(
    String id, {
    MapConnectionDirection? direction,
    int? line,
    int? entryIndex,
    int? exitIndex,
  }) => _configureFieldTraversal(
    id,
    FieldActionZoneKind.whirlpool,
    direction: direction,
    line: line,
    entryIndex: entryIndex,
    exitIndex: exitIndex,
  );

  void _configureFieldTraversal(
    String id,
    FieldActionZoneKind kind, {
    MapConnectionDirection? direction,
    bool? requiresSurf,
    int? line,
    int? entryIndex,
    int? exitIndex,
  }) {
    final zone = selected(id);
    if (zone == null) return;
    final waterfall = kind == FieldActionZoneKind.waterfall
        ? zone.fieldAction?.waterfall
        : null;
    final whirlpool = kind == FieldActionZoneKind.whirlpool
        ? zone.fieldAction?.whirlpool
        : null;
    final previousDirection = waterfall?.direction ?? whirlpool?.direction;
    final previousEntry = waterfall?.entry ?? whirlpool?.entry;
    final previousExit = waterfall?.exit ?? whirlpool?.exit;
    final facing =
        direction ??
        previousDirection ??
        fieldTraversalDirections(zone).firstOrNull;
    if (facing == null || !fieldTraversalDirections(zone).contains(facing)) {
      throw const ValidationException(
        'Dessinez au moins trois cases dans le sens du passage.',
      );
    }
    final vertical =
        facing == MapConnectionDirection.north ||
        facing == MapConnectionDirection.south;
    final forward =
        facing == MapConnectionDirection.south ||
        facing == MapConnectionDirection.east;
    final length = vertical ? zone.area.size.height : zone.area.size.width;
    final preserve = previousDirection == facing;
    final cross =
        line ??
        (preserve ? (vertical ? previousEntry!.x : previousEntry!.y) : 0);
    final start =
        entryIndex ??
        (preserve
            ? (vertical ? previousEntry!.y : previousEntry!.x)
            : forward
            ? 0
            : length - 1);
    final end =
        exitIndex ??
        (preserve
            ? (vertical ? previousExit!.y : previousExit!.x)
            : forward
            ? (length > 258 ? 257 : length - 1)
            : (length > 258 ? length - 258 : 0));
    if ((end - start) * (forward ? 1 : -1) < 2 || (end - start).abs() > 257) {
      throw const ValidationException(
        'Le passage exige une entrée, un trajet et une sortie distincts (256 cases de trajet maximum).',
      );
    }
    GridPos cell(int along) =>
        vertical ? GridPos(x: cross, y: along) : GridPos(x: along, y: cross);
    final path = [
      for (var i = start + (forward ? 1 : -1); i != end; i += forward ? 1 : -1)
        cell(i),
    ];
    _commit(
      const TriggerZoneActions().setFieldActionPayload(
        document.current,
        zoneId: id,
        payload: FieldActionZonePayload(
          actionKind: kind,
          waterfall: kind == FieldActionZoneKind.waterfall
              ? WaterfallZonePayload(
                  entry: cell(start),
                  path: path,
                  exit: cell(end),
                  direction: facing,
                  requiresSurf: requiresSurf ?? waterfall?.requiresSurf ?? true,
                )
              : null,
          whirlpool: kind == FieldActionZoneKind.whirlpool
              ? WhirlpoolZonePayload(
                  entry: cell(start),
                  path: path,
                  exit: cell(end),
                  direction: facing,
                )
              : null,
        ),
      ),
    );
  }

  void configureDive(String id, {DiveZoneRole? role, String? arrivalSpawnId}) {
    final zone = selected(id);
    if (zone == null) return;
    final previous = zone.fieldAction?.dive;
    if (previous?.link != null) {
      throw const ValidationException(
        'Déliez les deux points avant de modifier leur configuration.',
      );
    }
    _commit(
      const TriggerZoneActions().setFieldActionPayload(
        document.current,
        zoneId: id,
        payload: FieldActionZonePayload(
          actionKind: FieldActionZoneKind.dive,
          dive: DiveZonePayload(
            role: role ?? previous?.role ?? DiveZoneRole.surface,
            arrivalSpawnId: arrivalSpawnId ?? previous?.arrivalSpawnId,
          ),
        ),
      ),
    );
  }

  void configureDarkness(String id) {
    _commit(
      const TriggerZoneActions().setFieldActionPayload(
        document.current,
        zoneId: id,
        payload: const FieldActionZonePayload(
          actionKind: FieldActionZoneKind.darkness,
          darkness: DarknessZonePayload(opacity: .7),
        ),
      ),
    );
  }

  void updateDarkness(String id, {required double opacity}) {
    final payload = selected(id)?.fieldAction;
    if (payload == null) return;
    _commit(
      const TriggerZoneActions().setFieldActionPayload(
        document.current,
        zoneId: id,
        payload: payload.copyWith(
          darkness: DarknessZonePayload(opacity: opacity),
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

String defaultZoneName(GameplayZoneKind kind) => switch (kind) {
  GameplayZoneKind.encounter => 'Zone de rencontres',
  GameplayZoneKind.movement => 'Zone de déplacement',
  GameplayZoneKind.movementEffect => 'Zone à effet',
  GameplayZoneKind.fieldAction => 'Action de terrain',
  GameplayZoneKind.hazard => 'Zone dangereuse',
  GameplayZoneKind.special => 'Zone spéciale',
  GameplayZoneKind.custom => 'Zone héritée',
};

const studioGameplayZoneKinds = [
  GameplayZoneKind.encounter,
  GameplayZoneKind.movement,
  GameplayZoneKind.movementEffect,
  GameplayZoneKind.fieldAction,
  GameplayZoneKind.hazard,
  GameplayZoneKind.special,
];
