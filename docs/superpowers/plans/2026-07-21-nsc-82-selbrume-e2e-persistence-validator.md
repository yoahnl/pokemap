# NSC-82 Selbrume E2E Persistence / Validator Implementation Plan

**Goal:** Prouver sur le projet promu Selbrume les chemins victoire, défaite,
retry, sauvegarde/reload, non-double application et les quatre dimensions du
Validator, puis produire un receipt runtime frais.

**Architecture:** Le projet solver `map_core` conserve les corrélations de
branches mais ordonnance canoniquement les Events simultanément éligibles afin
de ne pas explorer leurs permutations équivalentes. Les tests runtime chargent
`selbrume/project.json` et ses vraies maps. Le host reste l'unique producteur du
receipt neutre consommé par l'éditeur.

## Task 1 — Baseline et RED Validator

- [x] Capturer le fingerprint promu devenu stale après NSC-81.
- [x] Ajouter une régression pure montrant que des Events indépendants ne
  doivent pas épuiser le budget par permutations.
- [x] Ajouter la matrice runtime Selbrume et constater le verdict symbolique
  `indeterminate` avant correction.

## Task 2 — Solveur borné sans permutations équivalentes

- [x] Exécuter un seul Event éligible par état selon priorité/order canonique ;
  conserver toutes les branches internes de sa Scene.
- [x] Prouver qu'un Event devenu éligible après un prédécesseur est encore
  exécuté.
- [x] Conserver budget dépassé = `indeterminate`, jamais `pass`.
- [x] Vérifier les tests map_core complets.

## Task 3 — Matrice promue persistence / défauts

- [x] Créer `selbrume_narrative_campaign_outcome_matrix_test.dart`.
- [x] Vérifier baseline structure, solvabilité et atteignabilité physique.
- [x] Injecter une Scene manquante et un trigger physique manquant ; vérifier
  que les dimensions se dégradent sans faux PASS.
- [x] Exécuter une Scene réelle suspendue : save avant acceptée, pendant
  refusée sans fichier, après End acceptée et reload identique.
- [x] Vérifier les politiques de fin et la non-double application déjà
  traversées par les tests retry/journey.

## Task 4 — Snapshot, receipt et gates existantes

- [x] Mettre à jour le fingerprint manifeste attendu après le changement
  canonique NSC-81.
- [x] Lancer promoted project, player journey, lighthouse retry, trigger battle,
  static boss, save/load et beta Validator.
- [x] Produire atomiquement un receipt `selbrume-release-v1` frais.
- [x] Vérifier que l'éditeur lit le receipt avec le même fingerprint.

## Task 5 — Evidence Pack et commit

- [x] Exécuter format/test/analyze ciblés puis suites package proportionnées.
- [x] Exécuter le smoke Phase A et le build macOS host avec Flutter compatible.
- [x] Produire `reports/gameplay/fg_selbrume_narrative_e2e_matrix_evidence.md`.
- [x] Commit isolé : `test(narrative): prove Selbrume persistence matrix`.
