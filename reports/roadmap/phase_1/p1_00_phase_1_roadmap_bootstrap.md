# P1-00 — Phase 1 Roadmap Bootstrap

## 1. Résumé exécutif

P1-00 a créé la roadmap vivante dédiée à la Phase 1 :
`MVP Selbrume/road_map_phase_1.md`.

La Phase 1 est cadrée comme une phase documentaire et produit, centrée sur le
modèle canonique du futur Narrative Studio. Elle ne démarre pas P1-01, ne crée
pas de code, ne crée pas de modèle `map_core`, ne crée pas d’UI et ne génère pas
de contenu Selbrume.

Prochain lot exact : P1-01 — Canonical Narrative Product Model V1.

## 2. Scope du lot

Scope exécuté :

- lire les documents de roadmap et de contexte demandés ;
- créer `MVP Selbrume/road_map_phase_1.md` ;
- inscrire les lots Phase 1 de P1-00 à P1-CHECKPOINT-01 ;
- inscrire la règle permanente de maintenance ;
- fixer P1-01 comme prochain lot exact ;
- créer le présent rapport P1-00 ;
- fournir un Evidence Pack.

Non-objectifs respectés :

- aucun code modifié ;
- aucun test ajouté ;
- aucun package `map_core`, `map_runtime`, `map_editor`, `map_gameplay` ou
  `map_battle` modifié ;
- P1-01 non démarré ;
- NS-GS-19 non démarré ;
- aucune UI implémentée ;
- aucun modèle Storyline/Event/Reward créé ;
- aucun contenu final Selbrume créé ;
- aucun `project.json` créé.

## 3. Sources lues

Sources obligatoires lues :

- `AGENTS.md`
- `reports/roadmap/pokemap_full_product_phased_roadmap_v1.md`
- `MVP Selbrume/narrative_studio.md`
- `MVP Selbrume/selbrume.md`
- `MVP Selbrume/road_map.md`
- `reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md`

Inventaires lus :

- `find reports -maxdepth 4 -type f | sort`
- `find "MVP Selbrume" -maxdepth 2 -type f | sort`
- `find reports/roadmap -maxdepth 3 -type f | sort`

Constats de lecture :

- la roadmap globale existe dans
  `reports/roadmap/pokemap_full_product_phased_roadmap_v1.md` ;
- elle recommande Phase 1 — Canonical Product Model / Narrative Studio
  foundations ;
- elle recommande P1-01 — Canonical Narrative Product Model V1 comme prochain
  lot exact après la création d’une roadmap Phase 1 ;
- `MVP Selbrume/road_map_phase_1.md` était absent avant P1-00 ;
- aucun répertoire `reports/roadmap/phase_1` n’était présent avant P1-00.

## 4. Fichier road_map_phase_1.md créé

Fichier créé :

- `MVP Selbrume/road_map_phase_1.md`

Le fichier contient :

- le statut initial de la Phase 1 ;
- P1-00 marqué `✅ terminé` ;
- P1-01 marqué `🔜 prochain lot exact` ;
- l’objectif de Phase 1 ;
- les préconditions ;
- le périmètre ;
- les non-objectifs stricts ;
- les concepts à figer ;
- les frontières non négociables ;
- la roadmap détaillée Phase 1 ;
- la règle permanente de maintenance ;
- les décisions utilisateur intégrées ;
- les gaps reportés ;
- l’historique de mise à jour.

## 5. Structure de la roadmap Phase 1

Structure créée :

```md
# Phase 1 Roadmap — Canonical Product Model / Narrative Studio Foundations

## 1. Statut de la phase
## 2. Objectif de la Phase 1
## 3. Pourquoi cette phase existe
## 4. Préconditions
## 5. Périmètre
## 6. Non-objectifs stricts
## 7. Concepts à figer
## 8. Frontières non négociables
## 9. Roadmap détaillée Phase 1
## 10. Prochain lot exact
## 11. Critères de sortie de Phase 1
## 12. Règle permanente de maintenance de cette roadmap
## 13. Décisions utilisateur intégrées
## 14. Gaps et sujets reportés
## 15. Historique des mises à jour de Phase 1
```

## 6. Lots Phase 1 inscrits

Lots inscrits :

- ✅ P1-00 — Phase 1 Roadmap Bootstrap
- 🔜 P1-01 — Canonical Narrative Product Model V1
- P1-02 — Event / Scene / Cinematic Boundary Contract
- P1-03 — Fact & World Rule Product Grammar
- P1-04 — Storyline / Chapter / Story Step Structure
- P1-05 — Selbrume Reference Grammar Mapping
- P1-06 — No-code Workflow Specification
- P1-07 — Phase 2 Domain Contract Proposal
- P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision

Pour chaque lot, la roadmap indique :

- objectif ;
- type ;
- scope ;
- non-objectifs ;
- livrable attendu ;
- critères de validation.

## 7. Règle permanente de maintenance

La règle permanente suivante est inscrite dans `road_map_phase_1.md` :

```text
À chaque lot de Phase 1, l’agent doit :

1. Lire `MVP Selbrume/road_map_phase_1.md` avant toute modification.
2. Lire `reports/roadmap/pokemap_full_product_phased_roadmap_v1.md`.
3. Respecter le lot courant et le prochain lot exact.
4. Ne jamais démarrer un autre lot que celui demandé.
5. Mettre à jour le statut du lot exécuté.
6. Ajouter un résumé court du résultat.
7. Ajouter les fichiers créés ou modifiés.
8. Ajouter les commandes exécutées si applicable.
9. Ajouter les décisions utilisateur nouvelles.
10. Ajouter les changements de périmètre.
11. Mettre à jour la section “Prochain lot exact”.
12. Conserver un Evidence Pack dans le rapport du lot.
13. Ne jamais créer de contenu Selbrume final.
14. Ne jamais créer de project.json Selbrume.
15. Ne jamais implémenter de code pendant Phase 1 sauf demande explicite.
```

## 8. Prochain lot exact

P1-01 — Canonical Narrative Product Model V1

P1-01 devra définir Storyline, Chapter, Story Step, Event, Scene, Cinematic,
Dialogue Yarn, Fact, World Rule et Validator.

P1-01 ne doit pas créer de code, de modèles `map_core`, d’UI, de fixtures
Selbrume finales ou de `project.json`.

## 9. Fichiers créés / modifiés

Fichiers créés :

- `MVP Selbrume/road_map_phase_1.md`
- `reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md`

Fichiers modifiés :

- aucun fichier tracked modifié ;
- aucun code modifié ;
- aucun test modifié.

## 10. Commandes exécutées

Commandes exécutées :

```bash
git status --short --untracked-files=all
find reports -maxdepth 4 -type f | sort
find "MVP Selbrume" -maxdepth 2 -type f | sort
sed -n '1,260p' reports/roadmap/pokemap_full_product_phased_roadmap_v1.md
sed -n '1,260p' "MVP Selbrume/narrative_studio.md"
sed -n '1,220p' "MVP Selbrume/selbrume.md"
sed -n '1,260p' "MVP Selbrume/road_map.md"
sed -n '1,220p' AGENTS.md
sed -n '1,260p' reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md
sed -n '813,1035p' reports/roadmap/pokemap_full_product_phased_roadmap_v1.md
find reports/roadmap -maxdepth 3 -type f | sort
test -e "MVP Selbrume/road_map_phase_1.md" && sed -n '1,60p' "MVP Selbrume/road_map_phase_1.md" || printf 'road_map_phase_1.md missing\n'
mkdir -p reports/roadmap/phase_1
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --no-index --check /dev/null "MVP Selbrume/road_map_phase_1.md" || true
git diff --no-index --check /dev/null reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md || true
wc -l "MVP Selbrume/road_map_phase_1.md" reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md
```

## 11. Résultat git diff --check

Commande :

```bash
git diff --check
```

Sortie exacte :

```text

```

Résultat : OK, aucune erreur whitespace sur le diff tracked.

## 12. Résultat git diff --stat

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text

```

Résultat : sortie vide car les fichiers P1-00 sont encore untracked.
La preuve des fichiers créés est fournie par le `git status final`, les
line counts et les contrôles `git diff --no-index --check`.

## 13. Résultat git diff --name-only

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text

```

Résultat : sortie vide car les fichiers P1-00 sont encore untracked.
Le `git status final` liste les deux fichiers créés.

## 14. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
?? "MVP Selbrume/road_map_phase_1.md"
?? reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md
```

Résultat : seuls les deux fichiers attendus par P1-00 sont visibles.

## 15. Evidence Pack

Git status initial exact :

```text

```

Le statut initial était vide : aucun fichier tracked modifié et aucun untracked
visible avant P1-00.

Preuve que `road_map_phase_1.md` était absent avant création :

```text
road_map_phase_1.md missing
```

Preuve de contenu pour `MVP Selbrume/road_map_phase_1.md` :

```text
Le fichier créé contient les sections exactes 1 à 15 demandées, les lots
P1-00 à P1-CHECKPOINT-01, les non-objectifs stricts, les frontières
non négociables, la règle permanente de maintenance et P1-01 comme prochain
lot exact.
```

Preuve de contenu pour le présent rapport :

```text
Le présent fichier est le rapport P1-00 complet créé dans
reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md.
```

Preuve des fichiers créés :

```text
MVP Selbrume/road_map_phase_1.md
reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md
```

Commandes finales :

```text
git diff --check : sortie vide
git diff --stat : sortie vide
git diff --name-only : sortie vide
git status final :
?? "MVP Selbrume/road_map_phase_1.md"
?? reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md
```

Contrôle whitespace des fichiers untracked créés :

```bash
git diff --no-index --check /dev/null "MVP Selbrume/road_map_phase_1.md" || true
git diff --no-index --check /dev/null reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md || true
```

Sortie exacte :

```text

```

Line counts après création :

```text
     461 MVP Selbrume/road_map_phase_1.md
     363 reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md
     824 total
```

## 16. Auto-review critique

- P1-00 ne modifie aucun code.
- P1-00 n’ajoute aucun test.
- P1-00 ne démarre pas P1-01.
- P1-00 ne crée pas de modèle produit détaillé.
- P1-00 ne crée pas de modèle `map_core`.
- P1-00 ne modifie pas `ProjectManifest`.
- P1-00 ne lance pas `build_runner`.
- P1-00 ne crée pas de contenu final Selbrume.
- P1-00 ne crée pas de `project.json`.
- La roadmap Phase 1 est créée et fixe P1-01 comme prochain lot exact.
