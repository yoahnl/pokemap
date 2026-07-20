# NSC-54 — Solveur symbolique narratif corrélé

## Objectif

Produire une preuve conservative de solvabilité qui garde chaque branche dans un état distinct et ne transforme jamais une feature inconnue ou un budget dépassé en succès.

## Frontières

- Le solveur est pur et vit dans `map_core`.
- Les Facts, Steps, Events consommés, outcomes et événements exécutés composent la clé d’état.
- Une branche Dialogue, Condition, Battle ou Outcome conserve sa provenance.
- Une commande sans descriptor/backend publiable produit `indeterminate`.
- Une quête secondaire active peut échouer sans bloquer le parcours obligatoire, mais son issue reste visible.
- Les diagnostics historiques restent présents pendant la migration ; le verdict corrélé devient un gate supplémentaire du Validator.

## Plan TDD

1. Prouver que deux branches exclusives ne satisfont pas artificiellement A et B.
2. Prouver la convergence d’états identiques.
3. Tester cycle, chemin sans sortie, budget et commande inconnue.
4. Tester une quête secondaire active non bloquante.
5. Explorer les Events V2 et leurs expressions avec état/provenance.
6. Exposer pass/fail/indeterminate dans le rapport projet.
7. Adapter les diagnostics auteur et exécuter le gate core.

## Gate

Le Validator refuse une conjonction impossible, expose un résultat reproductible et distingue explicitement preuve, réfutation et indétermination.
