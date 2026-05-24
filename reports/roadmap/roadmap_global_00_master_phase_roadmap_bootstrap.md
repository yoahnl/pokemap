# ROADMAP-GLOBAL-00 — Global Phase Roadmap Bootstrap

## 1. Résumé exécutif

ROADMAP-GLOBAL-00 a créé la roadmap globale vivante par phases :
`MVP Selbrume/road_map_global.md`.

Cette roadmap ne remplace pas la proposition stratégique longue
`reports/roadmap/pokemap_full_product_phased_roadmap_v1.md`. Elle devient la
source vivante courte pour suivre les phases, la phase courante, le prochain lot
exact, les gaps globaux et la règle permanente de mise à jour à chaque fin de
phase.

Le lot a aussi ajouté une référence minimale à `road_map_global.md` dans
`MVP Selbrume/road_map_phase_1.md`.

Prochain lot exact : P1-01 — Canonical Narrative Product Model V1.

## 2. Scope du lot

Scope exécuté :

- lire les documents de roadmap demandés ;
- créer `MVP Selbrume/road_map_global.md` ;
- préciser les rôles respectifs de `road_map_global.md`, `road_map_phase_1.md`,
  `road_map.md` et du rapport stratégique ;
- inscrire les phases 0 à 7 ;
- inscrire la règle permanente de maintenance globale ;
- modifier légèrement `MVP Selbrume/road_map_phase_1.md` pour référencer la
  roadmap globale ;
- créer le présent rapport ROADMAP-GLOBAL-00 ;
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
- `MVP Selbrume/road_map_phase_1.md`
- `reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md`
- `MVP Selbrume/road_map.md`
- `MVP Selbrume/narrative_studio.md`
- `MVP Selbrume/selbrume.md`

Inventaires lus :

- `find reports -maxdepth 4 -type f | sort`
- `find "MVP Selbrume" -maxdepth 2 -type f | sort`

Constats :

- `reports/roadmap/pokemap_full_product_phased_roadmap_v1.md` existe et
  recommande Phase 1 puis P1-01 ;
- `MVP Selbrume/road_map_phase_1.md` existe et fixe P1-01 comme prochain lot ;
- `MVP Selbrume/road_map_global.md` était absent avant ROADMAP-GLOBAL-00 ;
- `MVP Selbrume/road_map.md` reste la roadmap historique NS-GS clôturée.

## 4. Fichier road_map_global.md créé

Fichier créé :

- `MVP Selbrume/road_map_global.md`

Structure créée :

```md
# PokeMap Global Roadmap — Phased Product Roadmap

## 1. Statut global
## 2. Objectif final de PokeMap
## 3. Gouvernance par phases
## 4. Relation entre les roadmaps
## 5. Synthèse des phases
## 6. Phase 0 — Audit global & roadmap reset
## 7. Phase 1 — Canonical Product Model / Narrative Studio Foundations
## 8. Phase 2 — Domain Model & Contracts
## 9. Phase 3 — Runtime / Application / Flame / Disk Validation
## 10. Phase 4 — Authoring Workflows Minimal
## 11. Phase 5 — Gameplay Gaps Prioritaires
## 12. Phase 6 — Selbrume Golden Slice réel
## 13. Phase 7 — UI / UX moderne finale
## 14. Phase courante
## 15. Prochain lot exact
## 16. Critères de changement de phase
## 17. Règle permanente de maintenance de cette roadmap globale
## 18. Décisions utilisateur intégrées
## 19. Gaps globaux suivis
## 20. Historique des mises à jour globales
```

Statut global inscrit :

```text
Roadmap globale : active
Bloc NS-GS-01 → NS-GS-18 : ✅ terminé comme bloc mechanics-first Level 2 Application
Phase courante : Phase 1 — Canonical Product Model / Narrative Studio Foundations
Roadmap de phase courante : MVP Selbrume/road_map_phase_1.md
Lot courant : ROADMAP-GLOBAL-00 — Global Phase Roadmap Bootstrap
Prochain lot exact après ROADMAP-GLOBAL-00 : P1-01 — Canonical Narrative Product Model V1
ROADMAP-GLOBAL-00 : ✅ terminé
P1-01 : 🔜 prochain lot exact
```

## 5. Relation entre les roadmaps

Relation inscrite dans `road_map_global.md` :

- `MVP Selbrume/road_map_global.md` → source de vérité globale par phases.
- `MVP Selbrume/road_map_phase_1.md` → source de vérité détaillée pour la Phase 1.
- `MVP Selbrume/road_map.md` → roadmap historique NS-GS clôturée, conservée comme archive de preuves et contexte.
- `reports/roadmap/pokemap_full_product_phased_roadmap_v1.md` → rapport stratégique long qui a proposé cette gouvernance.
- `reports/roadmap/phase_1/*.md` → livrables et rapports des lots Phase 1.

## 6. Phases inscrites

Phases inscrites :

- ✅ Phase 0 — Audit global & roadmap reset
- 🔜 Phase 1 — Canonical Product Model / Narrative Studio Foundations
- Phase 2 — Domain Model & Contracts
- Phase 3 — Runtime / Application / Flame / Disk Validation
- Phase 4 — Authoring Workflows Minimal
- Phase 5 — Gameplay Gaps Prioritaires
- Phase 6 — Selbrume Golden Slice réel
- Phase 7 — UI / UX moderne finale

Pour chaque phase, `road_map_global.md` indique :

- objectif ;
- pourquoi ;
- préconditions ;
- périmètre ;
- non-objectifs ;
- livrables ;
- critères de sortie ;
- checkpoint final ;
- statut.

## 7. Règle permanente de maintenance globale

Règle inscrite :

```text
À chaque checkpoint de fin de phase, l’agent doit :

1. Lire `MVP Selbrume/road_map_global.md`.
2. Lire la roadmap vivante de la phase en cours.
3. Lire le rapport checkpoint de la phase.
4. Mettre à jour le statut de la phase terminée.
5. Ajouter un résumé court du résultat de phase.
6. Ajouter les livrables principaux produits pendant la phase.
7. Ajouter les preuves principales et limites restantes.
8. Mettre à jour les gaps globaux.
9. Choisir ou confirmer la phase suivante.
10. Créer ou mettre à jour la roadmap vivante de la phase suivante.
11. Mettre à jour la section “Phase courante”.
12. Mettre à jour la section “Prochain lot exact”.
13. Signaler toute décision utilisateur nouvelle.
14. Ne jamais démarrer la phase suivante sans validation utilisateur.
15. Ne jamais créer de contenu Selbrume final sauf demande explicite.
16. Ne jamais traiter cette roadmap globale comme une liste infinie de lots.
```

Règle complémentaire inscrite :

```text
À chaque lot de phase, l’agent lit `road_map_global.md` pour contexte,
mais il ne la modifie pas sauf si le lot est un checkpoint de fin de phase
ou si l’utilisateur le demande explicitement.
```

## 8. Modification de road_map_phase_1.md

Modifications ciblées :

- ajout de la précondition :
  `La roadmap globale vivante existe dans MVP Selbrume/road_map_global.md`.
- ajout de la lecture obligatoire de `MVP Selbrume/road_map_global.md` dans la
  règle permanente Phase 1 ;
- ajout de l’obligation pour P1-CHECKPOINT-01 de mettre à jour
  `MVP Selbrume/road_map_global.md` avant transition vers Phase 2.

Hunks appliqués :

```diff
@@
 - La roadmap globale par phases existe dans
   `reports/roadmap/pokemap_full_product_phased_roadmap_v1.md`.
+- La roadmap globale vivante existe dans
+  `MVP Selbrume/road_map_global.md`.
```

```diff
@@
 1. Lire `MVP Selbrume/road_map_phase_1.md` avant toute modification.
-2. Lire `reports/roadmap/pokemap_full_product_phased_roadmap_v1.md`.
+2. Lire `MVP Selbrume/road_map_global.md`.
+3. Lire `reports/roadmap/pokemap_full_product_phased_roadmap_v1.md`.
```

```diff
+P1-CHECKPOINT-01 devra aussi mettre à jour
+`MVP Selbrume/road_map_global.md` avant toute transition vers la Phase 2.
```

## 9. Prochain lot exact

P1-01 — Canonical Narrative Product Model V1

ROADMAP-GLOBAL-00 ne démarre pas P1-01.

P1-01 devra rester documentaire/design-first et définir Storyline, Chapter,
Story Step, Event, Scene, Cinematic, Dialogue Yarn, Fact, World Rule et Validator.

## 10. Fichiers créés / modifiés

Fichiers créés :

- `MVP Selbrume/road_map_global.md`
- `reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md`

Fichiers modifiés :

- `MVP Selbrume/road_map_phase_1.md`

Fichiers de code modifiés :

- aucun.

Tests ajoutés :

- aucun.

## 11. Commandes exécutées

Commandes exécutées :

```bash
git status --short --untracked-files=all
find reports -maxdepth 4 -type f | sort
find "MVP Selbrume" -maxdepth 2 -type f | sort
sed -n '1,260p' reports/roadmap/pokemap_full_product_phased_roadmap_v1.md
sed -n '1,260p' "MVP Selbrume/road_map_phase_1.md"
sed -n '1,220p' reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md
sed -n '1,260p' "MVP Selbrume/road_map.md"
sed -n '1,220p' "MVP Selbrume/narrative_studio.md"
sed -n '1,180p' "MVP Selbrume/selbrume.md"
sed -n '1,220p' AGENTS.md
rg -n "Préconditions|Règle permanente|P1-CHECKPOINT|Historique|Prochain lot exact" "MVP Selbrume/road_map_phase_1.md"
test -e "MVP Selbrume/road_map_global.md" && sed -n '1,60p' "MVP Selbrume/road_map_global.md" || printf 'road_map_global.md missing\n'
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --no-index --check /dev/null "MVP Selbrume/road_map_global.md" || true
git diff --no-index --check /dev/null reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md || true
wc -l "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md
```

## 12. Résultat git diff --check

Commande :

```bash
git diff --check
```

Sortie exacte :

```text

```

Résultat : OK, aucune erreur whitespace sur le diff tracked.

## 13. Résultat git diff --stat

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 MVP Selbrume/road_map_phase_1.md | 34 ++++++++++++++++++++--------------
 1 file changed, 20 insertions(+), 14 deletions(-)
```

Note : les deux fichiers créés par ROADMAP-GLOBAL-00 sont untracked ; ils sont
prouvés par `git status final` et les contrôles `git diff --no-index --check`.

## 14. Résultat git diff --name-only

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
MVP Selbrume/road_map_phase_1.md
```

Note : les fichiers créés untracked sont listés dans le `git status final`.

## 15. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M "MVP Selbrume/road_map_phase_1.md"
?? "MVP Selbrume/road_map_global.md"
?? reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md
```

Résultat : seuls les fichiers attendus par ROADMAP-GLOBAL-00 sont visibles.

## 16. Evidence Pack

Git status initial exact :

```text

```

Le statut initial était vide : aucun fichier tracked modifié et aucun fichier
untracked visible au début de ROADMAP-GLOBAL-00.

Preuve que `road_map_global.md` était absent avant création :

```text
road_map_global.md missing
```

Fichiers lus :

- `AGENTS.md`
- `reports/roadmap/pokemap_full_product_phased_roadmap_v1.md`
- `MVP Selbrume/road_map_phase_1.md`
- `reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md`
- `MVP Selbrume/road_map.md`
- `MVP Selbrume/narrative_studio.md`
- `MVP Selbrume/selbrume.md`

Preuve de contenu pour `road_map_global.md` :

- la structure complète du fichier est reproduite en section 4 ;
- les phases inscrites sont reproduites en section 6 ;
- la règle permanente est reproduite en section 7 ;
- les décisions utilisateur intégrées sont présentes dans le fichier créé ;
- les gaps globaux suivis sont présents dans le fichier créé.

Preuve de modification de `road_map_phase_1.md` :

- les hunks ciblés sont reproduits en section 8.

Preuve de contenu pour le présent rapport :

```text
Le présent fichier est le rapport ROADMAP-GLOBAL-00 complet créé dans
reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md.
```

Commandes finales :

```text
git diff --check : sortie vide
git diff --stat :
 MVP Selbrume/road_map_phase_1.md | 34 ++++++++++++++++++++--------------
 1 file changed, 20 insertions(+), 14 deletions(-)
git diff --name-only :
MVP Selbrume/road_map_phase_1.md
git status final :
 M "MVP Selbrume/road_map_phase_1.md"
?? "MVP Selbrume/road_map_global.md"
?? reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md
```

Contrôle whitespace des fichiers untracked créés :

```bash
git diff --no-index --check /dev/null "MVP Selbrume/road_map_global.md" || true
git diff --no-index --check /dev/null reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md || true
```

Sortie exacte :

```text

```

Line counts après création :

```text
     638 MVP Selbrume/road_map_global.md
     467 MVP Selbrume/road_map_phase_1.md
     438 reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md
    1543 total
```

## 17. Auto-review critique

- ROADMAP-GLOBAL-00 ne modifie aucun code.
- ROADMAP-GLOBAL-00 n’ajoute aucun test.
- ROADMAP-GLOBAL-00 ne démarre pas P1-01.
- ROADMAP-GLOBAL-00 ne démarre pas NS-GS-19.
- ROADMAP-GLOBAL-00 ne crée pas de modèle produit.
- ROADMAP-GLOBAL-00 ne crée pas de modèle `map_core`.
- ROADMAP-GLOBAL-00 ne modifie pas `ProjectManifest`.
- ROADMAP-GLOBAL-00 ne lance pas `build_runner`.
- ROADMAP-GLOBAL-00 ne crée pas de contenu final Selbrume.
- ROADMAP-GLOBAL-00 ne crée pas de `project.json`.
- `road_map_global.md` décrit les phases, ne devient pas une liste infinie de lots,
  et conserve P1-01 comme prochain lot exact.
