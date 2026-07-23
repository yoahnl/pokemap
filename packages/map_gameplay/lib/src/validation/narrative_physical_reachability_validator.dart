import 'dart:collection';

import 'package:map_core/map_core.dart';

import '../direction.dart';
import '../gameplay_connection.dart';
import '../gameplay_world_state.dart';
import '../player_spawn_resolver.dart';

enum NarrativePhysicalReachabilityVerdict { pass, fail, indeterminate }

enum NarrativePhysicalSourceStatus {
  reachable,
  progressionRequired,
  permanentlyBlocked,
  indeterminate,
  notApplicable,
}

enum NarrativePhysicalIssueCode {
  missingStartMap,
  invalidStartSpawn,
  missingSourceMap,
  missingSourceTarget,
  explorationBudgetExceeded,
  permanentlyBlocked,
}

final class NarrativePhysicalReachabilityIssue {
  const NarrativePhysicalReachabilityIssue({
    required this.code,
    required this.message,
    this.eventId,
    this.mapId,
  });

  final NarrativePhysicalIssueCode code;
  final String message;
  final String? eventId;
  final String? mapId;
}

final class NarrativePhysicalSourceResult {
  NarrativePhysicalSourceResult({
    required this.eventId,
    required this.source,
    required this.status,
    this.mapId,
    this.reachedCell,
    List<GridPos> path = const <GridPos>[],
    List<NarrativeSymbolicProvenance> provenance =
        const <NarrativeSymbolicProvenance>[],
  })  : path = List.unmodifiable(path),
        provenance = List.unmodifiable(provenance);

  final String eventId;
  final NarrativeEventSourceRef source;
  final NarrativePhysicalSourceStatus status;
  final String? mapId;
  final GridPos? reachedCell;
  final List<GridPos> path;
  final List<NarrativeSymbolicProvenance> provenance;
}

final class NarrativePhysicalReachabilityReport {
  NarrativePhysicalReachabilityReport({
    required this.verdict,
    required List<NarrativePhysicalSourceResult> results,
    required List<NarrativePhysicalReachabilityIssue> issues,
    required Set<String> reachableMapIds,
    required this.exploredStateCount,
  })  : results = List.unmodifiable(results),
        issues = List.unmodifiable(issues),
        reachableMapIds = Set.unmodifiable(reachableMapIds);

  final NarrativePhysicalReachabilityVerdict verdict;
  final List<NarrativePhysicalSourceResult> results;
  final List<NarrativePhysicalReachabilityIssue> issues;
  final Set<String> reachableMapIds;
  final int exploredStateCount;

  NarrativePhysicalSourceResult? resultForEvent(String eventId) {
    for (final result in results) {
      if (result.eventId == eventId) return result;
    }
    return null;
  }
}

NarrativePhysicalReachabilityReport validateNarrativePhysicalReachability({
  required ProjectManifest project,
  required List<MapData> maps,
  required NarrativeSymbolicReachabilityReport narrativeReport,
  int explorationBudget = 32768,
}) {
  if (explorationBudget < 1) {
    throw ArgumentError.value(
      explorationBudget,
      'explorationBudget',
      'must be positive',
    );
  }
  final records = (project.eventRegistry?.records ?? const [])
      .where((record) => record.enabledOrNull == true)
      .where((record) => record.definitionOrNull != null)
      .map((record) => record.definitionOrNull!)
      .toList()
    ..sort((left, right) {
      final byOrder = left.order.compareTo(right.order);
      return byOrder != 0 ? byOrder : left.id.compareTo(right.id);
    });
  final spatial = records
      .where((event) =>
          event.source.kind != NarrativeEventSourceKind.outcomeReceived)
      .toList(growable: false);
  final nonSpatial = records
      .where((event) =>
          event.source.kind == NarrativeEventSourceKind.outcomeReceived)
      .toList(growable: false);
  if (records.isEmpty) {
    return NarrativePhysicalReachabilityReport(
      verdict: NarrativePhysicalReachabilityVerdict.pass,
      results: const [],
      issues: const [],
      reachableMapIds: const {},
      exploredStateCount: 0,
    );
  }

  final mapsById = {for (final map in maps) map.id: map};
  final issues = <NarrativePhysicalReachabilityIssue>[];
  final referenceIssueByEventId =
      <String, NarrativePhysicalReachabilityIssue>{};
  for (final event in spatial) {
    final issue = _validateSourceReference(event, mapsById);
    if (issue != null) {
      referenceIssueByEventId[event.id] = issue;
      issues.add(issue);
    }
  }

  final startMapId = project.newGame.startMapId.trim();
  final startMap = mapsById[startMapId];
  if (!project.newGame.enabled || startMapId.isEmpty || startMap == null) {
    issues.add(
      NarrativePhysicalReachabilityIssue(
        code: NarrativePhysicalIssueCode.missingStartMap,
        mapId: startMapId.isEmpty ? null : startMapId,
        message: !project.newGame.enabled
            ? 'La configuration New Game n’est pas active.'
            : 'La map de départ "$startMapId" est absente du snapshot.',
      ),
    );
    return _indeterminateReport(
      spatial: spatial,
      nonSpatial: nonSpatial,
      issues: issues,
    );
  }

  GridPos startPos;
  try {
    startPos = resolveInitialPlayerSpawn(
      startMap,
      preferredSpawnId: project.newGame.startSpawnId,
    ).pos;
  } on Object catch (error) {
    issues.add(
      NarrativePhysicalReachabilityIssue(
        code: NarrativePhysicalIssueCode.invalidStartSpawn,
        mapId: startMapId,
        message: 'Le spawn New Game est invalide : $error',
      ),
    );
    return _indeterminateReport(
      spatial: spatial,
      nonSpatial: nonSpatial,
      issues: issues,
    );
  }

  final initialState = NarrativeSymbolicState(
    factValues: project.newGame.resolvedInitialFactValues,
  );
  final states = _canonicalStates(
    project,
    initialState,
    <NarrativeSymbolicState>[
      ...narrativeReport.exploredStates,
      ...narrativeReport.terminalStates,
    ],
  );
  final initialKey = initialState.semanticKey;
  final budget = _ExplorationBudget(explorationBudget);
  final evidenceByEventId = <String, _ReachabilityEvidence>{};
  final reachableMapIds = <String>{};
  var exploredStateCount = 0;
  var budgetExceeded = false;

  for (final state in states) {
    final exploration = _exploreSymbolicState(
      project: project,
      maps: maps,
      mapsById: mapsById,
      spatialEvents: spatial,
      startMapId: startMapId,
      startPos: startPos,
      symbolicState: state,
      budget: budget,
    );
    exploredStateCount += exploration.exploredMapEntries;
    reachableMapIds.addAll(exploration.reachableMapIds);
    budgetExceeded = budgetExceeded || exploration.budgetExceeded;
    for (final entry in exploration.evidenceByEventId.entries) {
      final existing = evidenceByEventId[entry.key];
      final isInitial = state.semanticKey == initialKey;
      final candidate = entry.value.copyWith(
        requiresProgression: !isInitial,
        indeterminateProgression: !isInitial && state.indeterminate,
        provenance: state.provenance,
      );
      if (existing == null || candidate.rank < existing.rank) {
        evidenceByEventId[entry.key] = candidate;
      }
    }
    if (exploration.budgetExceeded) break;
  }

  if (budgetExceeded) {
    issues.add(
      NarrativePhysicalReachabilityIssue(
        code: NarrativePhysicalIssueCode.explorationBudgetExceeded,
        message:
            'Le budget physique global de $explorationBudget recherches est dépassé.',
      ),
    );
  }

  final results = <NarrativePhysicalSourceResult>[];
  for (final event in records) {
    if (event.source.kind == NarrativeEventSourceKind.outcomeReceived) {
      results.add(
        NarrativePhysicalSourceResult(
          eventId: event.id,
          source: event.source,
          status: NarrativePhysicalSourceStatus.notApplicable,
        ),
      );
      continue;
    }
    final referenceIssue = referenceIssueByEventId[event.id];
    final evidence = evidenceByEventId[event.id];
    if (referenceIssue != null) {
      results.add(
        NarrativePhysicalSourceResult(
          eventId: event.id,
          source: event.source,
          status: NarrativePhysicalSourceStatus.indeterminate,
        ),
      );
      continue;
    }
    if (evidence != null && !evidence.indeterminateProgression) {
      results.add(
        NarrativePhysicalSourceResult(
          eventId: event.id,
          source: event.source,
          status: evidence.requiresProgression
              ? NarrativePhysicalSourceStatus.progressionRequired
              : NarrativePhysicalSourceStatus.reachable,
          mapId: evidence.mapId,
          reachedCell: evidence.reachedCell,
          path: evidence.path,
          provenance: evidence.provenance,
        ),
      );
      continue;
    }
    final isIndeterminate = budgetExceeded ||
        narrativeReport.verdict == NarrativeSymbolicVerdict.indeterminate ||
        evidence?.indeterminateProgression == true;
    final status = isIndeterminate
        ? NarrativePhysicalSourceStatus.indeterminate
        : NarrativePhysicalSourceStatus.permanentlyBlocked;
    results.add(
      NarrativePhysicalSourceResult(
        eventId: event.id,
        source: event.source,
        status: status,
        mapId: _sourceMapId(event.source),
        provenance: evidence?.provenance ?? const [],
      ),
    );
    if (!isIndeterminate) {
      issues.add(
        NarrativePhysicalReachabilityIssue(
          code: NarrativePhysicalIssueCode.permanentlyBlocked,
          eventId: event.id,
          mapId: _sourceMapId(event.source),
          message:
              'La source physique de l’Event ${event.id} reste inaccessible dans tous les états narratifs prouvés.',
        ),
      );
    }
  }

  return NarrativePhysicalReachabilityReport(
    verdict: _verdictFor(results),
    results: results,
    issues: issues,
    reachableMapIds: reachableMapIds,
    exploredStateCount: exploredStateCount,
  );
}

NarrativePhysicalReachabilityIssue? _validateSourceReference(
  NarrativeEventDefinition event,
  Map<String, MapData> mapsById,
) {
  return event.source.when(
    mapEnter: (mapId) => mapsById.containsKey(mapId)
        ? null
        : NarrativePhysicalReachabilityIssue(
            code: NarrativePhysicalIssueCode.missingSourceMap,
            eventId: event.id,
            mapId: mapId,
            message: 'La map source "$mapId" est absente.',
          ),
    triggerEnter: (mapId, triggerId) {
      final map = mapsById[mapId];
      if (map == null) {
        return NarrativePhysicalReachabilityIssue(
          code: NarrativePhysicalIssueCode.missingSourceMap,
          eventId: event.id,
          mapId: mapId,
          message: 'La map source "$mapId" est absente.',
        );
      }
      if (map.triggers.any((trigger) => trigger.id == triggerId)) return null;
      return NarrativePhysicalReachabilityIssue(
        code: NarrativePhysicalIssueCode.missingSourceTarget,
        eventId: event.id,
        mapId: mapId,
        message: 'La zone source "$triggerId" est absente de "$mapId".',
      );
    },
    entityInteract: (mapId, entityId) {
      final map = mapsById[mapId];
      if (map == null) {
        return NarrativePhysicalReachabilityIssue(
          code: NarrativePhysicalIssueCode.missingSourceMap,
          eventId: event.id,
          mapId: mapId,
          message: 'La map source "$mapId" est absente.',
        );
      }
      if (map.entities.any((entity) => entity.id == entityId)) return null;
      return NarrativePhysicalReachabilityIssue(
        code: NarrativePhysicalIssueCode.missingSourceTarget,
        eventId: event.id,
        mapId: mapId,
        message: 'L’entité source "$entityId" est absente de "$mapId".',
      );
    },
    outcomeReceived: (_) => null,
  );
}

_StateExploration _exploreSymbolicState({
  required ProjectManifest project,
  required List<MapData> maps,
  required Map<String, MapData> mapsById,
  required List<NarrativeEventDefinition> spatialEvents,
  required String startMapId,
  required GridPos startPos,
  required NarrativeSymbolicState symbolicState,
  required _ExplorationBudget budget,
}) {
  final movementMode =
      symbolicState.unlockedFieldAbilities.contains(FieldAbility.surf)
          ? MovementMode.surf
          : MovementMode.walk;
  final gameState = GameState(
    saveId: 'narrative_physical_validation',
    currentMapId: startMapId,
    playerPosition: startPos,
    playerMovementMode: movementMode,
    trainerProfile: TrainerProfile(
      name: 'Validation',
      badgeIds: symbolicState.badgeIds.toList()..sort(),
    ),
    progression: PlayerProgression(
      completedStepIds: symbolicState.completedStepIds.toList()..sort(),
      unlockedFieldAbilities: symbolicState.unlockedFieldAbilities.toList()
        ..sort((left, right) => left.moveId.compareTo(right.moveId)),
    ),
    narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(
      valuesByFactId: symbolicState.factValues,
    ),
    consumedEventIds: symbolicState.consumedEventIds,
  );
  final visibilityByEntity = <String, bool>{};
  for (final effect in projectWorldRuleEffects(
    project,
    gameState,
    maps: maps,
  )) {
    if (effect.target.kind != WorldRuleTargetKind.mapEntity) continue;
    final entityId = effect.target.entityId;
    if (entityId == null) continue;
    switch (effect.effect.kind) {
      case WorldRuleEffectKind.entityHidden:
        visibilityByEntity['${effect.target.mapId}/$entityId'] = false;
      case WorldRuleEffectKind.entityVisible:
        visibilityByEntity['${effect.target.mapId}/$entityId'] = true;
      case WorldRuleEffectKind.npcDialogueOverride ||
            WorldRuleEffectKind.eventEnabled ||
            WorldRuleEffectKind.eventDisabled ||
            WorldRuleEffectKind.eventHidden:
        break;
    }
  }

  final queue = ListQueue<_MapEntry>()
    ..add(_MapEntry(mapId: startMapId, pos: startPos));
  final visited = <String>{};
  final worldByMapId = <String, GameplayWorldState>{};
  final componentIndexByMapId = <String, Map<GridPos, int>>{};
  final reachableMapIds = <String>{};
  final evidenceByEventId = <String, _ReachabilityEvidence>{};
  var budgetExceeded = false;

  while (queue.isNotEmpty) {
    final entry = queue.removeFirst();
    final map = mapsById[entry.mapId];
    if (map == null || !_inside(entry.pos, map.size)) continue;
    final world = worldByMapId.putIfAbsent(
      map.id,
      () => GameplayWorldState.initial(
        map: map,
        playerPos: entry.pos,
        project: project,
        tileWidth: project.settings.tileWidth,
        tileHeight: project.settings.tileHeight,
        playerMovementMode: movementMode,
        mapEntityPresencePredicate: (mapId, entity) =>
            visibilityByEntity['$mapId/${entity.id}'] ?? true,
      ),
    );
    final componentIndex = componentIndexByMapId.putIfAbsent(
      map.id,
      () => _walkableComponentIndex(world),
    );
    final componentId = componentIndex[entry.pos];
    final entryKey = componentId == null
        ? '${entry.mapId}:isolated:${entry.pos.x}:${entry.pos.y}'
        : '${entry.mapId}:component:$componentId';
    if (!visited.add(entryKey)) continue;
    reachableMapIds.add(map.id);

    for (final event in spatialEvents.where(
      (event) => _sourceMapId(event.source) == map.id,
    )) {
      if (evidenceByEventId.containsKey(event.id)) continue;
      final evidence = event.source.when<_ReachabilityEvidence?>(
        mapEnter: (_) => _ReachabilityEvidence(
          mapId: map.id,
          reachedCell: entry.pos,
          path: [entry.pos],
        ),
        triggerEnter: (_, triggerId) {
          final trigger =
              map.triggers.where((item) => item.id == triggerId).firstOrNull;
          if (trigger == null) return null;
          final search = _findPathToAny(
            world: world,
            start: entry.pos,
            goals: _rectCells(trigger.area, map.size),
            budget: budget,
          );
          budgetExceeded = budgetExceeded || search.budgetExceeded;
          return search.path == null
              ? null
              : _ReachabilityEvidence(
                  mapId: map.id,
                  reachedCell: search.path!.last,
                  path: search.path!,
                );
        },
        entityInteract: (_, entityId) {
          if (visibilityByEntity['${map.id}/$entityId'] == false) return null;
          final entity =
              map.entities.where((item) => item.id == entityId).firstOrNull;
          if (entity == null) return null;
          final search = _findPathToAny(
            world: world,
            start: entry.pos,
            goals: _adjacentCells(entity, map.size),
            budget: budget,
          );
          budgetExceeded = budgetExceeded || search.budgetExceeded;
          return search.path == null
              ? null
              : _ReachabilityEvidence(
                  mapId: map.id,
                  reachedCell: search.path!.last,
                  path: search.path!,
                );
        },
        outcomeReceived: (_) => null,
      );
      if (evidence != null) evidenceByEventId[event.id] = evidence;
      if (budgetExceeded) break;
    }
    if (budgetExceeded) break;

    for (final warp in map.warps) {
      final search = _findPathToWarp(
        world: world,
        start: entry.pos,
        warp: warp,
        budget: budget,
      );
      budgetExceeded = budgetExceeded || search.budgetExceeded;
      if (search.path != null && mapsById.containsKey(warp.targetMapId)) {
        queue.add(_MapEntry(mapId: warp.targetMapId, pos: warp.targetPos));
      }
      if (budgetExceeded) break;
    }
    if (budgetExceeded) break;

    for (final connection in map.connections) {
      final targetMap = mapsById[connection.targetMapId];
      if (targetMap == null) continue;
      final search = _findPathsToAll(
        world: world,
        start: entry.pos,
        goals: _borderCells(map.size, connection.direction),
        budget: budget,
      );
      budgetExceeded = budgetExceeded || search.budgetExceeded;
      final targetWorld = worldByMapId.putIfAbsent(
        targetMap.id,
        () => GameplayWorldState.initial(
          map: targetMap,
          playerPos: const GridPos(x: 0, y: 0),
          project: project,
          tileWidth: project.settings.tileWidth,
          tileHeight: project.settings.tileHeight,
          playerMovementMode: movementMode,
          mapEntityPresencePredicate: (mapId, entity) =>
              visibilityByEntity['$mapId/${entity.id}'] ?? true,
        ),
      );
      for (final path in search.paths) {
        final target = resolveConnectedMapTargetPos(
          sourcePos: path.last,
          sourceSize: map.size,
          targetSize: targetMap.size,
          direction: connection.direction,
          offset: connection.offset,
        );
        // The runtime rejects a connection before mounting the destination
        // whenever its authored landing cell is blocked. Explore every
        // aligned crossing instead of keeping the first reachable source
        // border cell: another authored crossing can be the valid entrance.
        if (target != null && !targetWorld.isBlocked(target.x, target.y)) {
          queue.add(_MapEntry(mapId: targetMap.id, pos: target));
        }
      }
      if (budgetExceeded) break;
    }
    if (budgetExceeded) break;
  }

  return _StateExploration(
    evidenceByEventId: evidenceByEventId,
    reachableMapIds: reachableMapIds,
    exploredMapEntries: visited.length,
    budgetExceeded: budgetExceeded,
  );
}

_PathSearch _findPathToAny({
  required GameplayWorldState world,
  required GridPos start,
  required Iterable<GridPos> goals,
  required _ExplorationBudget budget,
}) {
  final search = _findPathsToAll(
    world: world,
    start: start,
    goals: goals,
    budget: budget,
  );
  if (search.budgetExceeded) return const _PathSearch.budgetExceeded();
  if (search.paths.isNotEmpty) return _PathSearch.path(search.paths.first);
  return const _PathSearch.notFound();
}

_ReachablePathsSearch _findPathsToAll({
  required GameplayWorldState world,
  required GridPos start,
  required Iterable<GridPos> goals,
  required _ExplorationBudget budget,
}) {
  if (!budget.consume()) return const _ReachablePathsSearch.budgetExceeded();
  final orderedGoals = goals
      .where((goal) => _inside(goal, world.map.size))
      .toList(growable: false);
  if (orderedGoals.isEmpty) return const _ReachablePathsSearch.notFound();
  final pendingGoals = orderedGoals.toSet();
  final reachedGoals = <GridPos>{};
  final queue = ListQueue<GridPos>()..add(start);
  final visited = <GridPos>{start};
  final parentByCell = <GridPos, GridPos>{};
  if (pendingGoals.remove(start)) reachedGoals.add(start);

  while (queue.isNotEmpty && pendingGoals.isNotEmpty) {
    final current = queue.removeFirst();
    for (final direction in const <Direction>[
      Direction.north,
      Direction.east,
      Direction.south,
      Direction.west,
    ]) {
      final next = GridPos(
        x: current.x + direction.dx,
        y: current.y + direction.dy,
      );
      if (!_inside(next, world.map.size) || !visited.add(next)) continue;
      // Canonical projects can use pixel collision masks whose visual
      // footprint spans several cells while leaving a walkable corridor.
      // The coarse `isBlocked` cache intentionally reserves the complete
      // authored footprint and would therefore report false negatives here.
      // The centre projection reads the same pixel cache and tile metrics as
      // runtime movement, which keeps this static proof aligned with play.
      if (!_isProjectedWalkable(world, next)) {
        continue;
      }
      parentByCell[next] = current;
      queue.add(next);
      if (pendingGoals.remove(next)) reachedGoals.add(next);
    }
  }

  List<GridPos> rebuild(GridPos goal) {
    final reversed = <GridPos>[goal];
    var cursor = goal;
    while (cursor != start) {
      cursor = parentByCell[cursor]!;
      reversed.add(cursor);
    }
    return reversed.reversed.toList(growable: false);
  }

  return _ReachablePathsSearch.paths(<List<GridPos>>[
    for (final goal in orderedGoals)
      if (reachedGoals.contains(goal)) rebuild(goal),
  ]);
}

Map<GridPos, int> _walkableComponentIndex(GameplayWorldState world) {
  final componentByCell = <GridPos, int>{};
  var nextComponentId = 0;
  for (var y = 0; y < world.map.size.height; y++) {
    for (var x = 0; x < world.map.size.width; x++) {
      final seed = GridPos(x: x, y: y);
      if (componentByCell.containsKey(seed) ||
          !_isProjectedWalkable(world, seed)) {
        continue;
      }
      final componentId = nextComponentId++;
      final queue = ListQueue<GridPos>()..add(seed);
      componentByCell[seed] = componentId;
      while (queue.isNotEmpty) {
        final current = queue.removeFirst();
        for (final direction in const <Direction>[
          Direction.north,
          Direction.east,
          Direction.south,
          Direction.west,
        ]) {
          final next = GridPos(
            x: current.x + direction.dx,
            y: current.y + direction.dy,
          );
          if (!_inside(next, world.map.size) ||
              componentByCell.containsKey(next) ||
              !_isProjectedWalkable(world, next)) {
            continue;
          }
          componentByCell[next] = componentId;
          queue.add(next);
        }
      }
    }
  }
  return componentByCell;
}

bool _isProjectedWalkable(GameplayWorldState world, GridPos cell) =>
    !world.isCellCenterBlockedLegacyForGridIndexedSystems(cell.x, cell.y) &&
    (!world.isWaterCell(cell.x, cell.y) ||
        world.player.movementMode == MovementMode.surf);

_PathSearch _findPathToWarp({
  required GameplayWorldState world,
  required GridPos start,
  required MapWarp warp,
  required _ExplorationBudget budget,
}) {
  for (var y = 0; y < world.map.size.height; y++) {
    for (var x = 0; x < world.map.size.width; x++) {
      final triggerCell = GridPos(x: x, y: y);
      for (final direction in Direction.values) {
        final predecessor = GridPos(
          x: triggerCell.x - direction.dx,
          y: triggerCell.y - direction.dy,
        );
        if (!_inside(predecessor, world.map.size)) continue;
        final resolves = warp.triggerMode == MapWarpTriggerMode.onEnter
            ? world.warpOnEnterAt(x, y, direction)?.id == warp.id
            : world.warpOnBumpAt(x, y, direction)?.id == warp.id;
        if (!resolves) continue;
        final search = _findPathToAny(
          world: world,
          start: start,
          goals: [predecessor],
          budget: budget,
        );
        if (search.budgetExceeded) return search;
        if (search.path == null) continue;
        if (warp.triggerMode == MapWarpTriggerMode.onBump) return search;
        if (world.isBlocked(x, y)) continue;
        return _PathSearch.path([...search.path!, triggerCell]);
      }
    }
  }
  return const _PathSearch.notFound();
}

Iterable<GridPos> _rectCells(MapRect rect, GridSize bounds) sync* {
  for (var y = rect.pos.y; y < rect.pos.y + rect.size.height; y++) {
    for (var x = rect.pos.x; x < rect.pos.x + rect.size.width; x++) {
      final cell = GridPos(x: x, y: y);
      if (_inside(cell, bounds)) yield cell;
    }
  }
}

Iterable<GridPos> _adjacentCells(MapEntity entity, GridSize bounds) sync* {
  final left = entity.pos.x;
  final top = entity.pos.y;
  final right = left + entity.size.width - 1;
  final bottom = top + entity.size.height - 1;
  for (var x = left; x <= right; x++) {
    final cell = GridPos(x: x, y: top - 1);
    if (_inside(cell, bounds)) yield cell;
  }
  for (var y = top; y <= bottom; y++) {
    final cell = GridPos(x: right + 1, y: y);
    if (_inside(cell, bounds)) yield cell;
  }
  for (var x = right; x >= left; x--) {
    final cell = GridPos(x: x, y: bottom + 1);
    if (_inside(cell, bounds)) yield cell;
  }
  for (var y = bottom; y >= top; y--) {
    final cell = GridPos(x: left - 1, y: y);
    if (_inside(cell, bounds)) yield cell;
  }
}

Iterable<GridPos> _borderCells(
  GridSize bounds,
  MapConnectionDirection direction,
) sync* {
  switch (direction) {
    case MapConnectionDirection.north:
      for (var x = 0; x < bounds.width; x++) {
        yield GridPos(x: x, y: 0);
      }
    case MapConnectionDirection.east:
      for (var y = 0; y < bounds.height; y++) {
        yield GridPos(x: bounds.width - 1, y: y);
      }
    case MapConnectionDirection.south:
      for (var x = 0; x < bounds.width; x++) {
        yield GridPos(x: x, y: bounds.height - 1);
      }
    case MapConnectionDirection.west:
      for (var y = 0; y < bounds.height; y++) {
        yield GridPos(x: 0, y: y);
      }
  }
}

List<NarrativeSymbolicState> _canonicalStates(
  ProjectManifest project,
  NarrativeSymbolicState initial,
  List<NarrativeSymbolicState> candidates,
) {
  // Physical reachability only changes when a World Rule can alter map-entity
  // visibility. Scene provenance, emitted outcomes, executed Event IDs and
  // unrelated Facts must not trigger another full pathfinding pass.
  final physicalRules = project.worldRules.where(
    (rule) =>
        rule.target.kind == WorldRuleTargetKind.mapEntity &&
        (rule.effect.kind == WorldRuleEffectKind.entityHidden ||
            rule.effect.kind == WorldRuleEffectKind.entityVisible),
  );
  final relevantFactIds = <String>{};
  final relevantStepIds = <String>{};
  final relevantConsumedEventIds = <String>{};
  for (final rule in physicalRules) {
    switch (rule.source.kind) {
      case WorldRuleSourceKind.fact:
        relevantFactIds.add(rule.source.sourceId);
      case WorldRuleSourceKind.storyStepCompletion:
        relevantStepIds.add(rule.source.sourceId);
      case WorldRuleSourceKind.consumedEvent:
        relevantConsumedEventIds.add(rule.source.sourceId);
    }
  }

  String physicalKey(NarrativeSymbolicState state) {
    final facts = <String>[
      for (final factId in relevantFactIds)
        if (state.factValues[factId] case final value?)
          '$factId=${value.kind.wireName}:${value.toJson()}',
    ]..sort();
    final steps = state.completedStepIds
        .intersection(relevantStepIds)
        .toList(growable: false)
      ..sort();
    final consumed = state.consumedEventIds
        .intersection(relevantConsumedEventIds)
        .toList(growable: false)
      ..sort();
    final fieldAbilities = state.unlockedFieldAbilities
        .map((ability) => ability.moveId)
        .toList(growable: false)
      ..sort();
    return '${facts.join('|')}|steps=${steps.join(',')}|'
        'consumed=${consumed.join(',')}|'
        'fieldAbilities=${fieldAbilities.join(',')}';
  }

  final byKey = <String, NarrativeSymbolicState>{
    physicalKey(initial): initial,
  };
  for (final candidate in candidates) {
    final merged = NarrativeSymbolicState(
      factValues: {
        ...initial.factValues,
        ...candidate.factValues,
      },
      completedStepIds: candidate.completedStepIds,
      consumedEventIds: candidate.consumedEventIds,
      badgeIds: candidate.badgeIds,
      unlockedFieldAbilities: candidate.unlockedFieldAbilities,
      emittedOutcomeKeys: candidate.emittedOutcomeKeys,
      executedEventIds: candidate.executedEventIds,
      provenance: candidate.provenance,
      indeterminate: candidate.indeterminate,
    );
    final key = physicalKey(merged);
    final existing = byKey[key];
    if (existing == null || existing.indeterminate && !merged.indeterminate) {
      byKey[key] = merged;
    }
  }
  return List.unmodifiable(byKey.values);
}

String? _sourceMapId(NarrativeEventSourceRef source) => source.when(
      mapEnter: (mapId) => mapId,
      triggerEnter: (mapId, _) => mapId,
      entityInteract: (mapId, _) => mapId,
      outcomeReceived: (_) => null,
    );

bool _inside(GridPos pos, GridSize bounds) =>
    pos.x >= 0 && pos.y >= 0 && pos.x < bounds.width && pos.y < bounds.height;

NarrativePhysicalReachabilityVerdict _verdictFor(
  List<NarrativePhysicalSourceResult> results,
) {
  if (results.any(
    (result) =>
        result.status == NarrativePhysicalSourceStatus.permanentlyBlocked,
  )) {
    return NarrativePhysicalReachabilityVerdict.fail;
  }
  if (results.any(
    (result) => result.status == NarrativePhysicalSourceStatus.indeterminate,
  )) {
    return NarrativePhysicalReachabilityVerdict.indeterminate;
  }
  return NarrativePhysicalReachabilityVerdict.pass;
}

NarrativePhysicalReachabilityReport _indeterminateReport({
  required List<NarrativeEventDefinition> spatial,
  required List<NarrativeEventDefinition> nonSpatial,
  required List<NarrativePhysicalReachabilityIssue> issues,
}) {
  return NarrativePhysicalReachabilityReport(
    verdict: spatial.isEmpty
        ? NarrativePhysicalReachabilityVerdict.pass
        : NarrativePhysicalReachabilityVerdict.indeterminate,
    results: [
      for (final event in spatial)
        NarrativePhysicalSourceResult(
          eventId: event.id,
          source: event.source,
          status: NarrativePhysicalSourceStatus.indeterminate,
        ),
      for (final event in nonSpatial)
        NarrativePhysicalSourceResult(
          eventId: event.id,
          source: event.source,
          status: NarrativePhysicalSourceStatus.notApplicable,
        ),
    ],
    issues: issues,
    reachableMapIds: const {},
    exploredStateCount: 0,
  );
}

final class _ExplorationBudget {
  _ExplorationBudget(this.limit);

  final int limit;
  int used = 0;

  bool consume() {
    if (used >= limit) return false;
    used++;
    return true;
  }
}

final class _MapEntry {
  const _MapEntry({required this.mapId, required this.pos});

  final String mapId;
  final GridPos pos;
}

final class _PathSearch {
  const _PathSearch.path(this.path) : budgetExceeded = false;
  const _PathSearch.notFound()
      : path = null,
        budgetExceeded = false;
  const _PathSearch.budgetExceeded()
      : path = null,
        budgetExceeded = true;

  final List<GridPos>? path;
  final bool budgetExceeded;
}

final class _ReachablePathsSearch {
  const _ReachablePathsSearch.paths(this.paths) : budgetExceeded = false;
  const _ReachablePathsSearch.notFound()
      : paths = const <List<GridPos>>[],
        budgetExceeded = false;
  const _ReachablePathsSearch.budgetExceeded()
      : paths = const <List<GridPos>>[],
        budgetExceeded = true;

  final List<List<GridPos>> paths;
  final bool budgetExceeded;
}

final class _ReachabilityEvidence {
  _ReachabilityEvidence({
    required this.mapId,
    required this.reachedCell,
    required List<GridPos> path,
    this.requiresProgression = false,
    this.indeterminateProgression = false,
    List<NarrativeSymbolicProvenance> provenance =
        const <NarrativeSymbolicProvenance>[],
  })  : path = List.unmodifiable(path),
        provenance = List.unmodifiable(provenance);

  final String mapId;
  final GridPos reachedCell;
  final List<GridPos> path;
  final bool requiresProgression;
  final bool indeterminateProgression;
  final List<NarrativeSymbolicProvenance> provenance;

  int get rank => indeterminateProgression
      ? 2
      : requiresProgression
          ? 1
          : 0;

  _ReachabilityEvidence copyWith({
    bool? requiresProgression,
    bool? indeterminateProgression,
    List<NarrativeSymbolicProvenance>? provenance,
  }) =>
      _ReachabilityEvidence(
        mapId: mapId,
        reachedCell: reachedCell,
        path: path,
        requiresProgression: requiresProgression ?? this.requiresProgression,
        indeterminateProgression:
            indeterminateProgression ?? this.indeterminateProgression,
        provenance: provenance ?? this.provenance,
      );
}

final class _StateExploration {
  const _StateExploration({
    required this.evidenceByEventId,
    required this.reachableMapIds,
    required this.exploredMapEntries,
    required this.budgetExceeded,
  });

  final Map<String, _ReachabilityEvidence> evidenceByEventId;
  final Set<String> reachableMapIds;
  final int exploredMapEntries;
  final bool budgetExceeded;
}
