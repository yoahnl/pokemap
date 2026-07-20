# NSC-57 — Rapport quatre dimensions et receipt runtime

## Objectif

Définir un contrat neutre et versionné qui agrège validation structurelle,
solvabilité narrative, atteignabilité physique et smoke runtime, sans créer de
dépendance editor → runtime.

## Contrat

- Chaque dimension vaut `pass`, `fail`, `indeterminate` ou `notRun`.
- Le projet n'est jouable que si les quatre dimensions sont `pass`.
- Le fingerprint canonique est calculé dans `map_core` à partir de couples
  `relativePath + bytes` normalisés et triés.
- Le reçu runtime contient profil/version, suites, fixture, résultat, date et
  limites ; absent, stale ou incomplet devient `notRun`.
- Le host écrit le sidecar atomiquement et conserve le reçu précédent si le
  nouveau run échoue avant le rename.
- L'éditeur lit le sidecar et agrège, mais n'importe jamais `map_runtime`.

## Plan TDD

1. RED/GREEN core — rapport, receipt et fingerprint.
2. RED/GREEN gameplay/editor — coordinator quatre dimensions et repository de
   freshness.
3. RED/GREEN runtime/host — evidence, profils obligatoires et écriture
   atomique.
4. Gate ciblé de chaque package, production du reçu Selbrume et Evidence Pack.
