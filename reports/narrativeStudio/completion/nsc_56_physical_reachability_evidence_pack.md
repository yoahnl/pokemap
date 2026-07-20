# NSC-56 — Atteignabilité physique narrative — Evidence Pack

## Résumé exécutif

NSC-56 ajoute dans `map_gameplay` une preuve physique pure des sources Event V2. L'exploration part du spawn New Game, réutilise `GameplayWorldState` pour les collisions et présences, `GridPathfinder` pour les chemins et `resolveConnectedMapTargetPos` pour les connexions. Elle suit les warps, cible les cellules réelles des triggers et exige une cellule cardinale adjacente pour les interactions.

Chaque source est qualifiée `reachable`, `progressionRequired`, `permanentlyBlocked`, `indeterminate` ou `notApplicable`. Les World Rules sont évaluées sur les états corrélés NSC-54 ; un budget dépassé ou un état narratif inconnu ne produit jamais de faux succès.

**Verdict proposé : DONE.**

## Scope et audit initial

- Lot : NSC-56, phase 5.
- État Git initial : branche `main`, HEAD `00271deb feat(narrative): add explicit scene outcome policies`, arbre propre.
- Contrats inspectés : `GameplayWorldState`, `GridPathfinder`, résolution de spawn, connections, warps, `projectWorldRuleEffects` et états/provenances NSC-54.
- Non-objectifs : aucune agrégation editor/runtime et aucun badge “jouable” dans ce lot ; NSC-57 en est propriétaire.

## Passes locales équivalentes aux sub-agents

Les sub-agents sont interdits par le mode actif ; les passes de `codex_rule.md` ont été réalisées localement et séparément.

| Passe | Verdict |
|---|---|
| Audit / Architecture | PASS — code pur dans map_gameplay, aucune dépendance Flutter/Flame ou retour map_core→map_gameplay. |
| Implémentation | PASS — mêmes caches de collision/présence, pathfinder et resolver de connection que le gameplay. |
| Tests | PASS — 7 tests ciblés et suite complète de 298 tests verts. |
| Build / Analyse | PASS — `dart analyze` sans issue. |
| Critique finale | PASS — budgets et preuves de progression inconnues restent indéterminés. |

## Inventaire des fichiers

| Fichier | Zone et impact |
|---|---|
| `packages/map_gameplay/lib/map_gameplay.dart` | Export public du contrat de preuve physique. |
| `packages/map_gameplay/lib/src/validation/narrative_physical_reachability_validator.dart` | Rapport, exploration multi-map, sources spatiales, World Rules, budget et provenance. |
| `packages/map_gameplay/test/narrative_physical_reachability_validator_test.dart` | Spawn, mur, zone, adjacency, warp, connection, progression et budget. |
| `docs/superpowers/plans/2026-07-20-nsc-56-physical-reachability.md` | Micro-plan TDD. |
| `reports/narrativeStudio/completion/nsc_56_physical_reachability_evidence_pack.md` | Présent rapport. |

## Décisions et zones précises

- Seuls les records Event V2 configurés et actifs entrent dans la preuve.
- `mapEnter` passe quand une entrée spawn/warp/connection est atteinte.
- `triggerEnter` cherche un chemin vers chaque cellule réelle du `MapRect`.
- `entityInteract` cherche une case cardinale adjacente au footprint, sans traverser l'entité bloquante.
- `outcomeReceived` est `notApplicable`, pas un faux pass physique.
- Les warps `onEnter` et `onBump` sont résolus via les caches de `GameplayWorldState`, y compris direction d'approche.
- Une entité masquée par la World Rule gagnante est retirée des caches exactement comme au gameplay.
- Une source atteinte seulement dans un état symbolique prouvé devient `progressionRequired`; un tel état marqué indéterminé ne suffit pas.
- Les références absentes, spawn invalide et budget dépassé donnent `indeterminate`.

## TDD et commandes exactes

La phase rouge a échoué avec l'API/les enums absents. Après implémentation, le gate est :

```text
cd packages/map_gameplay
/opt/homebrew/bin/dart test test/narrative_physical_reachability_validator_test.dart
+7: All tests passed!

/opt/homebrew/bin/dart format --output=none --set-exit-if-changed lib/map_gameplay.dart lib/src/validation/narrative_physical_reachability_validator.dart test/narrative_physical_reachability_validator_test.dart
Formatted 3 files (0 changed)

/opt/homebrew/bin/dart test --reporter compact
+298: All tests passed!

/opt/homebrew/bin/dart analyze
No issues found!

cd repository-root
git diff --check
aucune sortie
```

## État Git final avant commit

- Seuls les fichiers NSC-56 listés sont modifiés/créés.
- Aucun cache ni artefact de build n'est ajouté.
- `git diff --check` est propre.

## Limites et auto-critique

- Le pathfinder valide la traversabilité en mode marche. Les parcours exigeant Surf ou une autre capacité devront fournir un état de mouvement explicite dans une extension future ; ils ne doivent pas être promus implicitement.
- Les preuves sont bornées globalement. Un grand projet peut obtenir `indeterminate`, volontairement préférable à un faux pass.
- La preuve conserve le chemin local qui atteint la source ; l'itinéraire inter-map complet est représenté par les maps atteintes et pourra devenir une evidence ref détaillée dans NSC-57.
- Les événements legacy restent couverts par les validateurs legacy, pas par ce nouveau rapport Event V2.

## Prochaine étape

NSC-57 — agréger structure, solvabilité narrative, physique et smoke runtime dans un rapport neutre et frais.

## Contenu complet des fichiers créés

Le présent rapport ne s'inclut pas récursivement. Les autres fichiers créés sont reproduits ci-dessous.

<details>
<summary>Contenu complet — docs/superpowers/plans/2026-07-20-nsc-56-physical-reachability.md</summary>

```markdown
# NSC-56 — Atteignabilité physique narrative

## Objectif

Prouver, dans `map_gameplay`, qu'une source Event V2 spatiale est atteignable
depuis le spawn New Game en utilisant les collisions, entités, warps,
connexions et règles de présence du gameplay.

## Contrat

- Le verdict est `pass`, `fail` ou `indeterminate`.
- Une source est `reachable`, `progressionRequired`, `permanentlyBlocked`,
  `indeterminate` ou `notApplicable`.
- `entityInteract` exige une case cardinale adjacente et passable.
- `triggerEnter` utilise les cellules réelles de la zone.
- `mapEnter` exige une entrée prouvée par spawn, warp ou connection.
- `outcomeReceived` n'est pas une source physique et reste `notApplicable`.
- Les World Rules sont évaluées sur les états corrélés NSC-54 ; un état
  symbolique indéterminé ne prouve jamais une libération par progression.
- Budget dépassé, map/target manquant ou spawn invalide ne deviennent jamais
  un succès.

## Plan TDD

1. RED — écrire les tests spawn, mur, zone, adjacency, warp, connection,
   World Rule et budget.
2. GREEN — ajouter le rapport pur et explorer les maps avec
   `GameplayWorldState`, `GridPathfinder` et `resolveConnectedMapTargetPos`.
3. REFACTOR — stabiliser ordre, provenance et diagnostics.
4. GATE — tests ciblés, suite et analyzer `map_gameplay`, Evidence Pack puis
   commit isolé.
```
</details>
<details>
<summary>Contenu complet — packages/map_gameplay/lib/src/validation/narrative_physical_reachability_validator.dart</summary>

```dart
import 'dart:collection';

import 'package:map_core/map_core.dart';

import '../direction.dart';
import '../gameplay_connection.dart';
import '../gameplay_world_state.dart';
import '../grid_pathfinder.dart';
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
  final gameState = GameState(
    saveId: 'narrative_physical_validation',
    currentMapId: startMapId,
    playerPosition: startPos,
    progression: PlayerProgression(
      completedStepIds: symbolicState.completedStepIds.toList()..sort(),
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
  final reachableMapIds = <String>{};
  final evidenceByEventId = <String, _ReachabilityEvidence>{};
  var budgetExceeded = false;

  while (queue.isNotEmpty) {
    final entry = queue.removeFirst();
    final entryKey = '${entry.mapId}:${entry.pos.x}:${entry.pos.y}';
    if (!visited.add(entryKey)) continue;
    final map = mapsById[entry.mapId];
    if (map == null || !_inside(entry.pos, map.size)) continue;
    reachableMapIds.add(map.id);
    final world = GameplayWorldState.initial(
      map: map,
      playerPos: entry.pos,
      project: project,
      mapEntityPresencePredicate: (mapId, entity) =>
          visibilityByEntity['$mapId/${entity.id}'] ?? true,
    );

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
      final search = _findPathToAny(
        world: world,
        start: entry.pos,
        goals: _borderCells(map.size, connection.direction),
        budget: budget,
      );
      budgetExceeded = budgetExceeded || search.budgetExceeded;
      if (search.path != null) {
        final target = resolveConnectedMapTargetPos(
          sourcePos: search.path!.last,
          sourceSize: map.size,
          targetSize: targetMap.size,
          direction: connection.direction,
          offset: connection.offset,
        );
        if (target != null) {
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
  for (final goal in goals) {
    if (!budget.consume()) return const _PathSearch.budgetExceeded();
    final result = const GridPathfinder().findPath(
      bounds: world.map.size,
      start: start,
      goal: goal,
      isPassable: (x, y) => !world.isBlocked(x, y),
    );
    if (result.foundPath) return _PathSearch.path(result.path);
  }
  return const _PathSearch.notFound();
}

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
  NarrativeSymbolicState initial,
  List<NarrativeSymbolicState> candidates,
) {
  final byKey = <String, NarrativeSymbolicState>{initial.semanticKey: initial};
  for (final candidate in candidates) {
    final merged = NarrativeSymbolicState(
      factValues: {
        ...initial.factValues,
        ...candidate.factValues,
      },
      completedStepIds: candidate.completedStepIds,
      consumedEventIds: candidate.consumedEventIds,
      emittedOutcomeKeys: candidate.emittedOutcomeKeys,
      executedEventIds: candidate.executedEventIds,
      provenance: candidate.provenance,
      indeterminate: candidate.indeterminate,
    );
    byKey.putIfAbsent(merged.semanticKey, () => merged);
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
```
</details>

<details>
<summary>Contenu complet — packages/map_gameplay/test/narrative_physical_reachability_validator_test.dart</summary>

```dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

const _eventA = 'evt_019abcde-0000-7000-8000-000000000101';
const _eventB = 'evt_019abcde-0000-7000-8000-000000000102';

void main() {
  group('narrative physical reachability', () {
    test('proves mapEnter and trigger cells from the authored spawn', () {
      final map = _map(
        id: 'start',
        width: 5,
        height: 3,
        triggers: [
          const MapTrigger(
            id: 'gate_zone',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 3, y: 1),
              size: GridSize(width: 2, height: 1),
            ),
          ),
        ],
      );
      final report = validateNarrativePhysicalReachability(
        project: _project([
          _event(_eventA, NarrativeEventSourceRef.mapEnter('start')),
          _event(
            _eventB,
            NarrativeEventSourceRef.triggerEnter('start', 'gate_zone'),
          ),
        ]),
        maps: [map],
        narrativeReport: _symbolicReport(),
      );

      expect(report.verdict, NarrativePhysicalReachabilityVerdict.pass);
      expect(
        report.resultForEvent(_eventA)?.status,
        NarrativePhysicalSourceStatus.reachable,
      );
      expect(
        report.resultForEvent(_eventB)?.status,
        NarrativePhysicalSourceStatus.reachable,
      );
      expect(
          report.resultForEvent(_eventB)?.path.last, const GridPos(x: 3, y: 1));
    });

    test('reports a permanent blocker instead of crossing a wall', () {
      final collisions = List<bool>.filled(15, false);
      for (final y in [0, 1, 2]) {
        collisions[y * 5 + 2] = true;
      }
      final map = _map(
        id: 'start',
        width: 5,
        height: 3,
        collisions: collisions,
        triggers: [
          const MapTrigger(
            id: 'sealed_zone',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 4, y: 1),
              size: GridSize(width: 1, height: 1),
            ),
          ),
        ],
      );

      final report = validateNarrativePhysicalReachability(
        project: _project([
          _event(
            _eventA,
            NarrativeEventSourceRef.triggerEnter('start', 'sealed_zone'),
          ),
        ]),
        maps: [map],
        narrativeReport: _symbolicReport(),
      );

      expect(report.verdict, NarrativePhysicalReachabilityVerdict.fail);
      expect(
        report.resultForEvent(_eventA)?.status,
        NarrativePhysicalSourceStatus.permanentlyBlocked,
      );
    });

    test('interacts with a blocking entity from a cardinal adjacent cell', () {
      final map = _map(
        id: 'start',
        width: 5,
        height: 3,
        entities: [
          _spawn(),
          const MapEntity(
            id: 'npc_guard',
            name: 'Garde',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 3, y: 1),
          ),
        ],
      );

      final report = validateNarrativePhysicalReachability(
        project: _project([
          _event(
            _eventA,
            NarrativeEventSourceRef.entityInteract('start', 'npc_guard'),
          ),
        ]),
        maps: [map],
        narrativeReport: _symbolicReport(),
      );

      final result = report.resultForEvent(_eventA)!;
      expect(result.status, NarrativePhysicalSourceStatus.reachable);
      expect(result.path.last, const GridPos(x: 3, y: 0));
      expect(result.path, isNot(contains(const GridPos(x: 3, y: 1))));
    });

    test('follows authored on-enter warps between maps', () {
      final start = _map(
        id: 'start',
        width: 3,
        height: 1,
        warps: [
          const MapWarp(
            id: 'to_cave',
            pos: GridPos(x: 2, y: 0),
            targetMapId: 'cave',
            targetPos: GridPos(x: 0, y: 0),
          ),
        ],
      );
      final cave = _map(id: 'cave', width: 3, height: 1, withSpawn: false);

      final report = validateNarrativePhysicalReachability(
        project: _project([
          _event(_eventA, NarrativeEventSourceRef.mapEnter('cave')),
        ]),
        maps: [start, cave],
        narrativeReport: _symbolicReport(),
      );

      expect(
        report.resultForEvent(_eventA)?.status,
        NarrativePhysicalSourceStatus.reachable,
      );
      expect(report.reachableMapIds, containsAll(<String>{'start', 'cave'}));
    });

    test('follows authored map connections with the gameplay resolver', () {
      final start = _map(
        id: 'start',
        width: 3,
        height: 1,
        connections: [
          const MapConnection(
            direction: MapConnectionDirection.east,
            targetMapId: 'route',
          ),
        ],
      );
      final route = _map(id: 'route', width: 3, height: 1, withSpawn: false);

      final report = validateNarrativePhysicalReachability(
        project: _project([
          _event(_eventA, NarrativeEventSourceRef.mapEnter('route')),
        ]),
        maps: [start, route],
        narrativeReport: _symbolicReport(),
      );

      expect(
        report.resultForEvent(_eventA)?.status,
        NarrativePhysicalSourceStatus.reachable,
      );
    });

    test('qualifies a World Rule barrier as releasable by proven progression',
        () {
      final map = _map(
        id: 'start',
        width: 5,
        height: 1,
        entities: [
          _spawn(y: 0),
          const MapEntity(
            id: 'barrier',
            name: 'Barrière',
            kind: MapEntityKind.sign,
            pos: GridPos(x: 2, y: 0),
          ),
          const MapEntity(
            id: 'goal',
            name: 'But',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 4, y: 0),
          ),
        ],
      );
      final project = _project(
        [
          _event(
            _eventA,
            NarrativeEventSourceRef.entityInteract('start', 'goal'),
          ),
        ],
        storylines: [
          StorylineAsset(
            id: 'story',
            type: StorylineType.main,
            status: StorylineStatus.active,
            title: 'Story',
            chapters: [
              StorylineChapter(
                id: 'chapter',
                title: 'Chapter',
                order: 0,
                steps: [
                  StorylineStep(id: 'open_gate', title: 'Open', order: 0),
                ],
              ),
            ],
          ),
        ],
        worldRules: [
          WorldRuleDefinition(
            id: 'hide_barrier',
            label: 'Ouvrir le passage',
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.storyStepCompletion,
              sourceId: 'open_gate',
              predicate: WorldRuleSourcePredicate.completed,
            ),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEntity,
              mapId: 'start',
              entityId: 'barrier',
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityHidden,
            ),
          ),
        ],
      );
      final progressed = NarrativeSymbolicState(
        completedStepIds: const {'open_gate'},
        provenance: const [
          NarrativeSymbolicProvenance(
            sceneId: 'scene_open',
            nodeId: 'complete_gate',
            description: 'Étape open_gate terminée.',
          ),
        ],
      );

      final report = validateNarrativePhysicalReachability(
        project: project,
        maps: [map],
        narrativeReport: _symbolicReport(extraStates: [progressed]),
      );

      final result = report.resultForEvent(_eventA)!;
      expect(result.status, NarrativePhysicalSourceStatus.progressionRequired);
      expect(result.provenance.single.nodeId, 'complete_gate');
    });

    test('keeps exhausted exploration and unknown progression indeterminate',
        () {
      final map = _map(
        id: 'start',
        width: 4,
        height: 1,
        triggers: [
          const MapTrigger(
            id: 'first',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 2, y: 0),
              size: GridSize(width: 1, height: 1),
            ),
          ),
          const MapTrigger(
            id: 'second',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 3, y: 0),
              size: GridSize(width: 1, height: 1),
            ),
          ),
        ],
      );

      final report = validateNarrativePhysicalReachability(
        project: _project([
          _event(
            _eventA,
            NarrativeEventSourceRef.triggerEnter('start', 'first'),
          ),
          _event(
            _eventB,
            NarrativeEventSourceRef.triggerEnter('start', 'second'),
          ),
        ]),
        maps: [map],
        narrativeReport: _symbolicReport(
          verdict: NarrativeSymbolicVerdict.indeterminate,
        ),
        explorationBudget: 1,
      );

      expect(
          report.verdict, NarrativePhysicalReachabilityVerdict.indeterminate);
      expect(report.issues, isNotEmpty);
      expect(
        report.results.any(
          (result) =>
              result.status == NarrativePhysicalSourceStatus.indeterminate,
        ),
        isTrue,
      );
    });
  });
}

MapData _map({
  required String id,
  required int width,
  required int height,
  bool withSpawn = true,
  List<bool>? collisions,
  List<MapEntity>? entities,
  List<MapTrigger> triggers = const [],
  List<MapWarp> warps = const [],
  List<MapConnection> connections = const [],
}) {
  return MapData(
    id: id,
    name: id,
    size: GridSize(width: width, height: height),
    layers: [
      MapLayer.collision(
        id: 'collision',
        name: 'Collision',
        collisions: collisions ?? List<bool>.filled(width * height, false),
      ),
    ],
    entities:
        entities ?? (withSpawn ? [_spawn(y: height > 1 ? 1 : 0)] : const []),
    triggers: triggers,
    warps: warps,
    connections: connections,
  );
}

MapEntity _spawn({int y = 1}) => MapEntity(
      id: 'spawn',
      name: 'Spawn',
      kind: MapEntityKind.spawn,
      pos: GridPos(x: 0, y: y),
      spawn: const MapEntitySpawnData(role: EntitySpawnRole.playerStart),
      blocksMovement: false,
    );

NarrativeEventRecord _event(String id, NarrativeEventSourceRef source) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: id,
      source: source,
      conditions: const [],
      sceneId: 'scene',
      reusePolicy: NarrativeEventReusePolicy.reusable,
      priority: 0,
      order: int.parse(id.substring(id.length - 3)),
    ),
    enabled: true,
  );
}

ProjectManifest _project(
  List<NarrativeEventRecord> records, {
  List<StorylineAsset> storylines = const [],
  List<WorldRuleDefinition> worldRules = const [],
}) {
  return ProjectManifest(
    name: 'Physical reachability',
    maps: const [],
    tilesets: const [],
    newGame: const ProjectNewGameConfig(
      enabled: true,
      startMapId: 'start',
      startSpawnId: 'spawn',
    ),
    storylines: storylines,
    worldRules: worldRules,
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: records,
      legacyClaims: const [],
    ),
  );
}

NarrativeSymbolicReachabilityReport _symbolicReport({
  NarrativeSymbolicVerdict verdict = NarrativeSymbolicVerdict.pass,
  List<NarrativeSymbolicState> extraStates = const [],
}) {
  final initial = NarrativeSymbolicState();
  return NarrativeSymbolicReachabilityReport(
    verdict: verdict,
    terminalStates: [initial, ...extraStates],
    exploredStates: [initial, ...extraStates],
    issues: const [],
    reachableSceneIds: const {'scene'},
    exploredStateCount: 1 + extraStates.length,
  );
}
```
</details>
