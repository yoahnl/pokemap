part of 'map_builder_gameplay_panel.dart';

extension _MapBuilderGameplayRubrics on _MapBuilderGameplayPanelState {
  List<Widget> _movement(MapBuilderGameplayBinding binding, TextStyle? muted) {
    final l10n = context.l10n;
    final zones = binding.movementZones;
    final selected = binding.selectedZone?.id;
    final enabled = widget.enabled;
    return [
      _Section(title: l10n.movementObstacles, count: binding.blockedCells),
      StudioChoice(
        key: const ValueKey('map-gameplay-collision-paint'),
        leading: const Icon(Icons.block, size: 18),
        label: l10n.movementPaint,
        selected: binding.tool == StudioMapTool.collisionPaint,
        onTap: enabled ? () => binding.armCollisions(erase: false) : null,
      ),
      StudioChoice(
        key: const ValueKey('map-gameplay-collision-erase'),
        leading: const Icon(Icons.crop_square, size: 18),
        label: l10n.movementErase,
        selected: binding.tool == StudioMapTool.collisionErase,
        onTap: enabled ? () => binding.armCollisions(erase: true) : null,
      ),
      Text(l10n.movementBlockedCount(binding.blockedCells), style: muted),
      if (binding.spatial) Text(l10n.movementDecorBlocks, style: muted),
      const SizedBox(height: StudioSpacing.l),
      MenuAnchor(
        menuChildren: [
          for (final (kind, label, icon) in [
            (
              GameplayZoneKind.movement,
              l10n.movementAddRequired,
              Icons.directions_walk,
            ),
            (
              GameplayZoneKind.movementEffect,
              l10n.movementAddEffect,
              Icons.ac_unit,
            ),
          ])
            MenuItemButton(
              key: ValueKey('map-gameplay-add-zone-${kind.name}'),
              leadingIcon: Icon(icon, size: 18),
              onPressed: () => binding.armZone(kind),
              child: Text(label),
            ),
        ],
        builder: (context, menu, _) => StudioButton(
          key: const ValueKey('map-gameplay-add-zone'),
          label: l10n.movementAddZone,
          icon: Icons.add,
          onPressed: enabled
              ? () => menu.isOpen ? menu.close() : menu.open()
              : null,
        ),
      ),
      _Section(title: l10n.movementZones, count: zones.length),
      if (zones.isEmpty) Text(l10n.movementNoZone, style: muted),
      for (final zone in zones)
        StudioChoice(
          key: ValueKey('map-gameplay-zone-${zone.id}'),
          leading: Icon(
            zone.kind == GameplayZoneKind.movement
                ? Icons.directions_walk
                : Icons.ac_unit,
            size: 18,
          ),
          label: zone.name,
          subtitle: switch ((zone.movement, zone.movementEffect)) {
            (final movement?, _) =>
              '${l10n.zoneKindMovement} · '
                  '${l10n.movementMode(movement.requiredMode)}',
            (_, final effect?) =>
              '${l10n.zoneKindMovementEffect} · '
                  '${l10n.movementEffect(effect.effectKind)}',
            _ => null,
          },
          selected: zone.id == selected,
          onTap: () => binding.selectZone(zone.id),
        ),
    ];
  }

  List<Widget> _encounters(
    MapBuilderGameplayBinding binding,
    TextStyle? muted,
  ) {
    final l10n = context.l10n;
    final zones = binding.encounterZones;
    final selected = binding.selectedZone?.id;
    final enabled = widget.enabled;
    final tables = {
      for (final table in binding.encounterTables) table.id: table.name,
    };
    return [
      if (binding.paintsEncounters)
        StudioChoice(
          key: const ValueKey('map-gameplay-encounter-paint'),
          leading: const Icon(Icons.brush_outlined, size: 18),
          label: l10n.encounterPaintNew,
          selected:
              binding.tool == StudioMapTool.encounterPaint && selected == null,
          onTap: enabled
              ? () => binding.armEncounterBrush(erase: false, fresh: true)
              : null,
        )
      else
        Text(l10n.encounterPaint2dOnly, style: muted),
      StudioChoice(
        key: const ValueKey('map-gameplay-encounter-rectangle'),
        leading: const Icon(Icons.crop_free, size: 18),
        label: l10n.encounterDrawRect,
        selected: binding.draftingZone,
        onTap: enabled
            ? () => binding.armZone(GameplayZoneKind.encounter)
            : null,
      ),
      if (binding.encounterTablesError case final error?) ...[
        const SizedBox(height: StudioSpacing.m),
        StudioNotice(error, isError: true),
      ] else if (!binding.encounterTablesReady) ...[
        const SizedBox(height: StudioSpacing.m),
        Text(l10n.encounterTablesLoading, style: muted),
      ] else if (tables.isEmpty) ...[
        const SizedBox(height: StudioSpacing.m),
        StudioNotice(l10n.encounterNoTable),
      ],
      _Section(title: l10n.encounterZones, count: zones.length),
      if (zones.isEmpty) Text(l10n.encounterNoZone, style: muted),
      for (final zone in zones)
        StudioChoice(
          key: ValueKey('map-gameplay-zone-${zone.id}'),
          leading: const Icon(Icons.grass, size: 18),
          label: zone.name,
          subtitle: [
            l10n.encounterKindName(
              zone.encounter?.encounterKind ?? EncounterKind.walk,
            ),
            tables[zone.encounter?.encounterTableId] ??
                l10n.encounterNoTableChosen,
          ].join(' · '),
          selected: zone.id == selected,
          onTap: () => binding.selectZone(zone.id),
        ),
    ];
  }

  List<Widget> _fieldObjects(
    MapBuilderGameplayBinding binding,
    TextStyle? muted,
  ) {
    final l10n = context.l10n;
    final obstacles = binding.obstacles;
    final instance = binding.selectedInstance?.entityId;
    final selected = binding.selectedObstacle?.id ?? instance;
    return [
      if (binding.spatial)
        Text(l10n.obstacle3dHint, style: muted)
      else
        MenuAnchor(
          menuChildren: [
            for (final kind in FieldObstacleKind.values)
              MenuItemButton(
                key: ValueKey('map-gameplay-add-obstacle-${kind.name}'),
                onPressed: () => binding.draftObstacle(kind),
                child: Text(l10n.obstacleKindName(kind)),
              ),
          ],
          builder: (context, menu, _) => StudioButton(
            key: const ValueKey('map-gameplay-add-obstacle'),
            label: l10n.obstaclePlace,
            icon: Icons.add,
            onPressed: widget.enabled
                ? () => menu.isOpen ? menu.close() : menu.open()
                : null,
          ),
        ),
      _Section(title: l10n.obstacleSection, count: obstacles.length),
      if (obstacles.isEmpty) Text(l10n.obstacleNone, style: muted),
      for (final obstacle in obstacles)
        StudioChoice(
          key: ValueKey('map-gameplay-obstacle-${obstacle.id}'),
          leading: const Icon(Icons.park_outlined, size: 18),
          label: obstacle.name,
          subtitle: [
            l10n.obstacleKindName(obstacle.fieldObstacle!.kind),
            l10n.warpCell(obstacle.pos.x, obstacle.pos.y),
          ].join(' · '),
          selected: obstacle.id == selected,
          onTap: () => binding.selectObstacle(obstacle),
        ),
    ];
  }

  List<Widget> _spawns(MapBuilderGameplayBinding binding, TextStyle? muted) {
    final l10n = context.l10n;
    final spawns = binding.spawns;
    final selected = binding.selectedSpawn?.id;
    final commands = binding.entities;
    return [
      StudioButton(
        key: const ValueKey('map-gameplay-add-spawn'),
        label: l10n.spawnPlace,
        icon: Icons.add,
        onPressed: widget.enabled ? binding.armSpawn : null,
      ),
      if (binding.startsNowhere) ...[
        const SizedBox(height: StudioSpacing.m),
        StudioNotice(l10n.spawnMissing),
      ],
      _Section(title: l10n.spawnSection, count: spawns.length),
      if (spawns.isEmpty) Text(l10n.spawnNone, style: muted),
      for (final spawn in spawns)
        StudioChoice(
          key: ValueKey('map-gameplay-spawn-${spawn.id}'),
          leading: const Icon(Icons.flag_outlined, size: 18),
          label: spawn.name,
          subtitle: [
            l10n.spawnRoleName(spawn.spawn?.role ?? EntitySpawnRole.other),
            l10n.warpCell(spawn.pos.x, spawn.pos.y),
            if (commands?.isDefaultSpawn(spawn.id) ?? false)
              l10n.spawnDefaultBadge,
          ].join(' · '),
          selected: spawn.id == selected,
          onTap: () => binding.selectSpawn(spawn.id),
        ),
    ];
  }
}
