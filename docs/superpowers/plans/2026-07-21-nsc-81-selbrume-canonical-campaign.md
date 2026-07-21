# NSC-81 Selbrume Canonical Campaign Implementation Plan

**Goal:** Prouver que chaque beat de `MVP Selbrume/selbrume.md` est représenté
par une donnée canonique réellement authorable, persistée, validée et consommée
par le runtime, ou documenter précisément l'écart restant.

**Architecture:** Le seeder reste l'automatisation reproductible du snapshot
promu et le harness NSC-80 reste la preuve du workflow humain. Une matrice typée
dans le test du seed relie les beats de spécification à leurs assets physiques
et narratifs. Le test host exécute les convergences principales et secondaires.

## Task 1 — Baseline et drift du snapshot

- [x] Lancer le seeder en `--check` et consigner tout drift.
- [x] Régénérer `selbrume/project.json` et les Yarn uniquement via le seeder.
- [x] Inspecter le diff ; refuser toute modification hors campagne canonique.

## Task 2 — Matrice de couverture exécutable

- [x] Ajouter au test du seed une matrice des 12 Steps principales et des trois
  quêtes secondaires.
- [x] Pour chaque ligne, vérifier Storyline, Scene, Event actif, source physique,
  Facts/Rules et fichiers Yarn nécessaires.
- [x] Vérifier que les side quests ne sont pas requises par la progression
  principale et que victoire/défaite Lysa convergent.
- [x] Vérifier les diagnostics de domaine dans le test du seed ; réserver le
  verdict global, sa persistance et son budget symbolique à NSC-82.

## Task 3 — Polish narratif ciblé

- [x] Renforcer les quatre Yarn imposés par la roadmap : ton Lysa, défaite non
  bloquante, explication du boss non malveillant, épilogue/world state.
- [x] Mettre à jour la source `_canonicalYarnFiles`, jamais les fichiers promus
  seuls.
- [x] Conserver les outcomes déclarés et les nodes attendus par les Scenes.

## Task 4 — Preuve runtime campagne

- [x] Étendre `selbrume_canonical_narrative_campaign_test.dart` avec victoire et
  défaite Lysa, les trois quêtes secondaires et l'épilogue.
- [x] Prouver Facts, Step completion, World Rules projetées et récompenses sans
  simuler une donnée ignorée par le runtime.
- [x] Produire la matrice lisible dans
  `reports/gameplay/fg_selbrume_narrative_campaign_authoring_evidence.md`.

## Task 5 — Gate et commit

- [x] Seeder `--check`, tests Editor/Host ciblés et analyses ; le Validator CLI
  avec receipt/reload appartient au lot NSC-82 suivant.
- [x] Consigner le build disponible et les limites mécaniques hors NSC-81.
- [x] Commit isolé : `feat(narrative): complete Selbrume canonical campaign`.
