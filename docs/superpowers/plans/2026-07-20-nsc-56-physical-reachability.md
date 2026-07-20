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
