# PERF-000C — baseline Map Editor

Date : 2026-08-12  
Branche : `codex/perf-000a-hermetic-harness`  
Base auditée : `557b0fc9067602ee5e4b92450c3be4549c2847ab`  
Statut proposé : `DONE`

## Verdict

PERF-000C complète le dispositif de mesure interactif initié par PERF-000A et PERF-000B. Les journeys profile macOS couvrent désormais les latences P50/P95/P99, les allocations VM, le heap après GC, les tailles 128 à 1024, les volumétrie 100 à 10 000 éléments, les traits de collision 1 à 1 000 cellules et les masques 64² à 1024².

Les trois budgets interactifs sont verts sur la machine de calibration : placement local P95 inférieur à 16 ms, pointeur vers dispatch P95 inférieur à 8 ms et repaint P95 inférieur à 16,7 ms. Le placement canonique d'un élément reste volontairement une frontière asynchrone plan/apply/persistence ; il est mesuré séparément et n'est pas présenté comme une mutation locale sous 16 ms.

## Audit initial et décisions

- Les anciens benchmarks CI ne couvraient que 128 et 256 alors que les exécutables canoniques acceptaient déjà 128, 256, 512 et 1024.
- Le journey projet mesurait des frames mais n'exposait ni allocations VM ni heap après GC.
- Les phases authoring `snapshot`, `plan` et `apply` n'étaient pas observables depuis la mutation canonique réelle.
- Les tests de contrat pouvaient accepter un reçu incomplet : absence d'une taille de masque, d'une volumétrie de collision ou d'un scénario canvas non détectée.
- Le painter est mesuré sur le thread UI pendant l'enregistrement de la picture. Le raster GPU reste hors périmètre et est déclaré comme tel dans le reçu.

## Baseline profile macOS

Les valeurs ci-dessous proviennent des reçus de calibration générés par `flutter drive --profile -d macos` dans le worktree dédié.

| Mesure | P50 | P95 | P99 | Budget | Verdict |
|---|---:|---:|---:|---:|---|
| Placement local, 90 échantillons | 444 µs | 771 µs | 3 612 µs | P95 < 16 000 µs | PASS |
| Pointeur vers dispatch, 90 mouvements | 22 µs | 99 µs | 581 µs | P95 < 8 000 µs | PASS |
| Repaint combiné, extent 1024 | — | 1 405 µs | — | P95 < 16 700 µs | PASS |
| Repaint standard, extent 1024 | — | 185 µs | — | contrôle | PASS |

Le ratio du repaint combiné entre 128 et 1024 est de 1,082. Les placements projetés à extent 1024 restent à 103 µs P95 pour 100 éléments, 92 µs pour 1 000 et 180 µs pour 10 000.

| Masque collision | P50 | P95 | P99 |
|---|---:|---:|---:|
| 64 × 64 | 32 µs | 41 µs | 41 µs |
| 256 × 256 | 805 µs | 845 µs | 845 µs |
| 512 × 512 | 4 433 µs | 9 010 µs | 9 010 µs |
| 1024 × 1024 | 18 151 µs | 22 118 µs | 22 118 µs |

| Journey | Octets alloués | Allocations | Heap avant GC | Heap après GC |
|---|---:|---:|---:|---:|
| Projet interactif | 104 858 544 | 585 765 | 68 223 968 | 50 198 304 |
| Projection canvas | 35 651 536 | 450 014 | 31 564 112 | 5 505 072 |

Le journey canonique d'élément a pris 593 660 µs pendant la calibration. Il a produit quatre snapshots, deux plans et deux applies : le premier couple plan/apply vide la carte locale devenue dirty avant l'opération canonique, le second applique le placement. Cette séparation confirme que la boucle pointeur locale ne fait aucune lecture/écriture filesystem, aucun JSON et aucun base64.

## Benchmarks d'échelle complémentaires

- Résolution viewport Smart Tiles 1024 : P50 4 456 µs, P95/P99 6 797 µs.
- Roundtrip JSON de la carte riche 1024 : P95 577 541 µs.
- Import authoring riche 1024 : plan P95 2 628 498 µs, apply P95 8 195 099 µs.
- Snapshot cold du projet Selbrume : P50 293 822 µs, P95 328 475 µs.
- Snapshot cold synthétique 10 MiB : P50 517 740 µs, P95 548 085 µs.

Ces chiffres Dart JIT qualifient les opérations batch et ne sont pas comparés aux budgets UI profile.

## Fichiers et zones modifiés

- Workflow et contrat Hub : matrice complète 128/256/512/1024 et collecte du journey canvas.
- `map_authoring` : observation réelle des frontières snapshot, plan et apply, avec tests de cycle de vie.
- `map_editor` : probe VM service, allocations/heap après GC, fixtures interactives, matrices collision/masque/canvas et budgets.
- Driver performance : validation exhaustive des scénarios, catalogues, compteurs, mémoire et gates.
- Dépendances editor : `vm_service` devient une dépendance de développement directe.

## Validation

- Tests ciblés `map_editor` : PASS.
- Suite complète `map_authoring` : PASS.
- `flutter analyze --no-pub` dans `map_editor` : `No issues found!`.
- `dart analyze` dans `map_authoring` : `No issues found!`.
- Contrat workflow Hub : 2 tests, `All tests passed!`.
- Journeys macOS profile projet et canvas : PASS, applications Profile construites et reçus JSON générés.

## Auto-critique et limites

- Les timings GitHub-hosted restent observationnels jusqu'au lot PERF-009 ; les contrats de structure et de work-count sont déterministes, le mur-clock d'un runner mutualisé ne l'est pas.
- Le GC est demandé via le VM service et attesté par son timestamp. Le résultat ne permet pas d'attribuer précisément les allocations natives d'un plugin.
- La mesure canvas couvre le travail UI de build/paint, pas le raster GPU. Une régression GPU nécessitera une trace raster dédiée.
- Les seuils sont des budgets absolus de non-régression, pas une promesse de performance identique sur toute machine.

## Verdict des passes

- Audit/Architecture : PASS, frontières locales et canoniques explicitement séparées.
- Implémentation : PASS, instrumentation branchée sur les appels de production.
- Tests : PASS, reçus incomplets rejetés.
- Build/Validation : PASS, deux builds profile macOS et matrices complètes.
- Critique : PASS avec les limites ci-dessus conservées comme non-objectifs du lot.
