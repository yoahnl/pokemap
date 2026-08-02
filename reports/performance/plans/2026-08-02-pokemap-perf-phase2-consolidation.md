# Plan d’exécution — Consolidation de la phase 2 performance

Date : 2 août 2026
Lots : `PERF-RM-05`, `PERF-RM-08`, `PERF-RM-09A`, `PERF-RM-09B`

## Objectif

Fermer les preuves encore partielles de la phase 2 sans affaiblir les
frontières workspace, les contrôles de concurrence, l’ownership des images ou
la parité PokeMap MCP.

## Critères de sortie

- `RM-09A` : Selbrume moyen/p50 sous 400 ms, p95 au plus 1 s, pic RSS réduit
  d’au moins 30 % contre la baseline canonique, checksum et double observation
  inchangés.
- `RM-09B` : sauvegarde éditeur 10 Mio au plus 250 ms sur le chemin lifecycle
  de production, heartbeat UI au plus 16,667 ms, bytes et fingerprint stables,
  conflits avant/après préparation toujours rejetés.
- `RM-08` : trois processus `flutter drive --profile -d macos`, 100 assets,
  huit demandeurs concurrents, dix erreurs, dix cycles A/B, cache précédent
  détruit, diagnostics/frame timings/RSS complets et mémoire native déclarée
  indisponible plutôt qu’inventée.
- `RM-05` : aucune régression du lifecycle de session constatée par les tests
  ciblés et les validations larges.

## Étapes

1. Capturer les mesures fraîches et attribuer les coûts dominants.
2. Poser les portes RED de `RM-09B`, optimiser la validation JSON et remplacer
   les SHA de contrôle redondants par une comparaison byte-exacte off-isolate.
3. Réutiliser sous lock le snapshot lifecycle déjà vérifié et mesurer trois
   sauvegardes 10 Mio sur le câblage production.
4. Ajouter une seconde observation `RM-09A` qui compare les bytes sans créer un
   deuxième conteneur possédé, puis mesurer trois processus AOT Selbrume avec
   `/usr/bin/time -l`.
5. Créer le journey macOS profile `RM-08`, rendre le driver multi-cible et
   produire trois receipts isolés avec le même fingerprint source/fixture.
6. Rejouer les tests ciblés, suites de packages, analyses, build macOS et
   preuves de parité API/JSONL/éditeur/MCP.
7. Faire une revue indépendante, consolider les Evidence Packs et proposer les
   statuts finaux sans effectuer d’écriture Git.

## Non-objectifs

- aucune modification des cinq fichiers world-map préexistants ;
- aucune suppression d’une fenêtre de cohérence ou de récupération ;
- aucun seuil frame arbitraire ajouté après mesure ;
- aucune estimation RGBA présentée comme mémoire native réelle ;
- aucun `git add`, commit, push, stash, reset ou changement de branche.
