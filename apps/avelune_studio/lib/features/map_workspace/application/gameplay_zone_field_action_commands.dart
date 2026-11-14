part of 'gameplay_zone_editing_commands.dart';

extension GameplayZoneFieldActionCommands on GameplayZoneEditingCommands {
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
}
