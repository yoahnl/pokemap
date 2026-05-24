# P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision

## 1. Résumé exécutif

Verdict :

```text
✅ Phase 1 clôturable avec réserves mineures.
```

La Phase 1 a produit la roadmap vivante, le modèle produit canonique, les
frontières Event / Scene / Cinematic, la grammaire Fact / World Rule, la
structure Storyline / Chapter / Story Step, le mapping conceptuel Selbrume, les
workflows no-code et la proposition de contrats Phase 2.

Concepts figés :

```text
Storyline, Chapter, Story Step, Event, Scene, Cinematic, Dialogue Yarn,
Fact, World Rule, Validator.
```

Éléments reportés :

```text
contrats map_core réels, JSON/persistence, runtime Flame, projet disque,
authoring minimal, UI moderne, rewards, Quest Journal/Engine et Selbrume réel.
```

La Phase 2 peut commencer par un lot audit-first, sans exécution dans ce
checkpoint.

Prochain lot exact recommandé :

```text
P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit
```

## 2. Scope du checkpoint

Inclus :

- audit des livrables P1-00 à P1-07 ;
- vérification des concepts et frontières ;
- décision de clôture Phase 1 ;
- mise à jour de `MVP Selbrume/road_map_phase_1.md` ;
- mise à jour de `MVP Selbrume/road_map_global.md` ;
- création de `MVP Selbrume/road_map_phase_2.md` ;
- recommandation du prochain lot exact.

Exclus :

- aucun code ;
- aucun modèle `map_core` ;
- aucun JSON ;
- aucun Freezed / JsonSerializable ;
- aucun `build_runner` ;
- aucune UI ;
- aucun test Dart/Flutter ;
- aucun contenu final Selbrume ;
- aucune exécution de P2-00.

## 3. Sources lues

Roadmaps et documents de cadrage :

| Source | Rôle |
|---|---|
| `MVP Selbrume/road_map_global.md` | Roadmap globale à mettre à jour au checkpoint. |
| `MVP Selbrume/road_map_phase_1.md` | Roadmap Phase 1 à clôturer. |
| `MVP Selbrume/road_map.md` | Roadmap historique NS-GS, contexte mechanics-first. |
| `MVP Selbrume/narrative_studio.md` | Vision Narrative Studio historique. |
| `MVP Selbrume/selbrume.md` | Scénario de référence conceptuel. |
| `reports/roadmap/pokemap_full_product_phased_roadmap_v1.md` | Roadmap stratégique globale par phases. |
| `reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md` | Bootstrap de la gouvernance globale. |

Rapports Phase 1 :

| Source | Rôle |
|---|---|
| `reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md` | Création de la roadmap Phase 1. |
| `reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md` | Modèle canonique Narrative Studio. |
| `reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md` | Frontière Event / Scene / Cinematic. |
| `reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md` | Grammaire Fact / World Rule. |
| `reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md` | Structure Storyline / Chapter / Story Step. |
| `reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md` | Mapping conceptuel Selbrume. |
| `reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md` | Workflows no-code, pickers, validations et diagnostics. |
| `reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md` | Proposition de contrats Phase 2. |

Rapports NS-GS lus pour qualifier les preuves :

| Source | Rôle |
|---|---|
| `reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md` | Synthèse Level 2 Application et limites Flame/disk. |
| `reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md` | Correction des labels de preuve Level 2 vs Level 3/4. |
| `reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md` | Validator V0, diagnostics statiques existants. |
| `reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md` | Side quest via facts/steps/scenes, pas Quest Engine. |
| `reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md` | Rewards item partiels, money/XP non cadrés. |

Aucun fichier obligatoire n’a été constaté absent.

## 4. Verdict global Phase 1

```text
✅ Phase 1 clôturable avec réserves mineures.
```

Justification :

- tous les rapports P1-00 à P1-07 existent ;
- les concepts demandés sont définis ;
- les frontières critiques sont explicitement fixées ;
- Selbrume est resté un banc d’essai conceptuel ;
- les workflows no-code sont décrits sans UI finale ;
- P1-07 propose une Phase 2 bornée ;
- les limites Level 3 Flame, Level 4 disk, UI, gameplay rewards et Selbrume réel
  sont clairement reportées.

Réserves mineures :

- la Phase 1 est volontairement documentaire et ne prouve pas le runtime ;
- certains lots répètent les mêmes frontières, mais cette répétition consolide
  la grammaire ;
- la roadmap globale était encore stale avant ce checkpoint et a été mise à
  jour ici ;
- la roadmap Phase 2 créée ici reste une roadmap documentaire, pas une décision
  d’exécuter P2-00 sans validation utilisateur.

## 5. Évaluation lot par lot

| Lot | Livrable | Statut | Valeur produite | Réserve éventuelle | Verdict |
|---|---|---|---|---|---|
| P1-00 | `p1_00_phase_1_roadmap_bootstrap.md` | terminé | Roadmap Phase 1 créée et gouvernance inscrite. | Phase 1 encore à exécuter à ce stade. | validé |
| P1-01 | `p1_01_canonical_narrative_product_model_v1.md` | terminé | Dictionnaire produit canonique. | Pas de modèle domaine, volontaire. | validé |
| P1-02 | `p1_02_event_scene_cinematic_boundary_contract.md` | terminé | Event déclenche / Scene orchestre / Cinematic met en scène. | Relation Scene/ScenarioAsset reportée. | validé |
| P1-03 | `p1_03_fact_world_rule_product_grammar.md` | terminé | Fact = vérité, World Rule = projection passive. | FactRegistry/WorldRuleRegistry non créés, volontaire. | validé |
| P1-04 | `p1_04_storyline_chapter_story_step_structure.md` | terminé | Storyline / Chapter / Story Step et side quest V0. | Statuts runtime non implémentés, volontaire. | validé |
| P1-05 | `p1_05_selbrume_reference_grammar_mapping.md` | terminé | Golden Slice Lysa au port mappé conceptuellement. | Ne prouve pas Flame/disk/editor. | validé avec réserve mineure |
| P1-06 | `p1_06_no_code_workflow_specification.md` | terminé | Workflows auteur, pickers, validations, diagnostics. | Pas d’UI, volontaire. | validé |
| P1-07 | `p1_07_phase_2_domain_contract_proposal.md` | terminé | Contrats Phase 2 proposés et bornés. | Proposition à valider au checkpoint/P2-00. | validé |

## 6. Concepts figés

| Concept | Définition courte | Frontière principale | Livrable de référence |
|---|---|---|---|
| Storyline | Ligne narrative cohérente. | Organise une histoire, pas un Quest Engine. | P1-01, P1-04 |
| Chapter | Section d’une Storyline. | Organise la lecture, pas un état runtime obligatoire. | P1-01, P1-04 |
| Story Step | Jalon de progression. | Jalon validable, pas Scene ni flag brut. | P1-01, P1-04 |
| Event | Déclencheur contextualisé. | Lance une Scene, ne l’orchestre pas. | P1-01, P1-02 |
| Scene | Orchestration narrative. | Coordonne dialogue, battle, cinematic, Facts/Steps. | P1-01, P1-02 |
| Cinematic | Mise en scène linéaire. | Montre, attend, anime ; n’écrit pas la progression. | P1-01, P1-02 |
| Dialogue Yarn | Dialogue et outcomes. | Produit des outcomes ; Scene interprète. | P1-01, P1-02, P1-05 |
| Fact | Vérité lisible du monde. | Langage produit, pas flag technique exposé. | P1-01, P1-03 |
| World Rule | Projection passive de l’état. | Montre le monde, ne déclenche pas de Scene. | P1-01, P1-03 |
| Validator | Diagnostic statique. | Diagnostique, ne corrige pas automatiquement. | P1-01, P1-06, P1-07 |

## 7. Frontières validées

```text
Event déclenche.
Scene orchestre.
Cinematic met en scène.
Yarn produit des outcomes.
Battle résout.
Scene interprète.
Fact nomme ce qui est vrai.
World Rule projette passivement.
Storyline organise.
Chapter sectionne.
Story Step jalonne.
Validator diagnostique.
Side quest V0 = Storyline secondaire.
```

Conséquence produit :

- un Event ne devient pas une mini-Scene ;
- une Scene ne devient pas une Cinematic ;
- une Cinematic n’écrit pas librement la progression ;
- une World Rule ne lance pas de Scene et n’écrit pas de Fact ;
- Yarn et Battle ne décident pas seuls de la progression narrative ;
- le créateur ne manipule pas les flags techniques comme langage principal.

## 8. Décisions restantes

Décisions à trancher en Phase 2 :

- Scene = nom produit de `ScenarioAsset`, wrapper, ou adapter/read model ?
- FactRegistry ou d’abord FactDescriptor / Fact Presentation Layer ?
- WorldRuleRegistry ou d’abord World Rule Predicate Adapter ?
- Storyline/Chapter persistants ou metadata/descriptors légers ?
- Step Descriptor obligatoire en V0 ou metadata existante suffisante ?
- Battle defeat obligatoire en authoring ou policy configurable ?
- Rewards inclus Phase 2 ou reportés Phase 5 ?
- Availability explicite Storyline/Step ?
- Quand modifier `ProjectManifest` et avec quelle migration ?

## 9. Réserves et limites

Réserves honnêtes :

- `road_map_phase_1.md` indiquait encore “En préparation” avant ce checkpoint ;
- `road_map_global.md` pointait encore vers P1-01 avant ce checkpoint ;
- Phase 1 est très documentaire ;
- certains lots répètent les décisions, mais les rendent plus strictes ;
- aucun code n’est produit par cette phase ;
- aucune preuve runtime Flame ou projet disque n’est ajoutée ;
- la proposition Phase 2 reste à valider avant exécution.

Réserve Git observée :

Le premier `git status --short --untracked-files=all` capturé au début du
checkpoint a affiché des traces P1-07. Des commandes Git en lecture seule
immédiatement après ont rafraîchi l’état : `p1_07` est bien suivi par Git et le
worktree est redevenu propre avant les modifications du checkpoint. La sortie
initiale brute reste conservée en Evidence Pack.

## 10. Gaps reportés hors Phase 1

| Gap | Phase recommandée |
|---|---|
| Contrats `map_core` réels | Phase 2 |
| JSON / persistence / migration | Phase 2 si justifié |
| Diagnostics Validator domaine | Phase 2 |
| Picker read models | Phase 2 |
| Runtime Flame / PlayableMapGame | Phase 3 |
| Projet disque / save-load golden path | Phase 3 |
| Authoring minimal dans editor | Phase 4 |
| Validator intégré dans editor | Phase 4 puis Phase 7 |
| Reward Model | Phase 5 |
| Money / XP / level-up | Phase 5 |
| Static wild authoring | Phase 5 |
| Door/Warp complet | Phase 3 ou Phase 5 selon dépendance |
| Selbrume Golden Slice réel | Phase 6 |
| Scene Builder complet | Phase 7 |
| Cinematic Builder complet | Phase 7 |
| Quest Journal | Phase 7 ou décision ultérieure |
| Quest Engine complet | Refusé maintenant / à reconsidérer seulement avec consumers |
| UI moderne premium | Phase 7 |

## 11. Validation du passage vers Phase 2

Phase 2 peut commencer si l’utilisateur valide le passage.

Critères satisfaits :

- concepts figés ;
- frontières suffisamment claires ;
- workflows no-code décrits ;
- proposition de contrats Phase 2 existante ;
- gaps hors phase explicités ;
- aucun blocker documentaire restant identifié.

Le prochain lot doit rester :

```text
P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit
```

Ce checkpoint ne l’exécute pas.

## 12. Roadmap Phase 2 recommandée

Roadmap Phase 2 bornée :

| Lot | Objectif |
|---|---|
| P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit | Confirmer le découpage Phase 2 et auditer l’existant avant création. |
| P2-01 — Existing Narrative Domain Inventory | Inventorier modèles, metadata, validators, runtime sources et authoring projections. |
| P2-02 — Story Step Descriptor / Storyline Metadata Decision | Décider descriptor / metadata / adapter / report. |
| P2-03 — Event Authoring Source Contract | Formaliser les sources auteur d’Event sans dupliquer le runtime. |
| P2-04 — Scene / ScenarioAsset Adapter Contract | Stabiliser Scene comme vue produit ou adapter. |
| P2-05 — Outcome Reference Contracts | Rendre Yarn/scenario outcomes sélectionnables et diagnosticables. |
| P2-06 — Battle Reference / Outcome Contract | Stabiliser battle refs et outcomes victory/defeat. |
| P2-07 — Fact Descriptor / Presentation Layer | Labels humains et relations source/consumer sans dupliquer l’état. |
| P2-08 — World Rule Predicate Adapter Contract | Adapter les predicates existants à World Rule. |
| P2-09 — Narrative Validator Diagnostic Expansion | Ajouter les diagnostics domaine prioritaires. |
| P2-10 — Reference Picker Read Models | Préparer les sources de pickers Phase 4 sans UI. |
| P2-CHECKPOINT-01 — Domain Contracts Readiness Review | Clôturer Phase 2. |

Cette roadmap évite une Phase 2 infinie : elle cible les contrats et diagnostics
nécessaires avant runtime/disk, authoring UI et Selbrume réel.

## 13. Roadmap Phase 2 vivante

Décision du checkpoint :

```text
Créer MVP Selbrume/road_map_phase_2.md.
```

Justification :

- Phase 1 est clôturable ;
- la gouvernance demande une roadmap détaillée pour la phase active ;
- la création de la roadmap Phase 2 ne démarre pas P2-00 ;
- le prochain lot exact reste explicitement borné.

La roadmap créée contient :

- statut Phase 2 ;
- objectif Phase 2 ;
- non-objectifs ;
- lots Phase 2 proposés ;
- prochain lot exact ;
- règle permanente de maintenance ;
- rappels anti-scope : pas de Selbrume final, pas d’UI premium, pas de runtime
  Flame hors lot dédié.

## 14. Mise à jour de road_map_phase_1.md

Mise à jour effectuée :

```text
P1-CHECKPOINT-01 : ✅ terminé
Phase 1 : ✅ clôturée avec réserves mineures
Prochain lot exact : P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit
```

La roadmap Phase 1 signale aussi la création documentaire de
`MVP Selbrume/road_map_phase_2.md`.

## 15. Mise à jour de road_map_global.md

Mise à jour effectuée :

```text
Phase 1 : ✅ clôturée avec réserves mineures
Phase courante : Phase 2 — Domain Model & Contracts
Roadmap de phase courante : MVP Selbrume/road_map_phase_2.md
Prochain lot exact : P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit
```

Résumé Phase 1 ajouté :

```text
Phase 1 a figé la grammaire produit du Narrative Studio :
Storyline, Chapter, Story Step, Event, Scene, Cinematic, Dialogue Yarn, Fact,
World Rule, Validator, mapping Selbrume, workflows no-code et proposition
Phase 2.
```

L’historique NS-GS est conservé.

## 16. Décisions à valider par l’utilisateur

Décisions à valider avant ou pendant P2-00 :

- validation de la roadmap Phase 2 ;
- priorité audit-first vs création directe de contrats ;
- statut Scene = `ScenarioAsset` adapter, wrapper ou nom produit ;
- FactDescriptor / Fact Presentation Layer vs FactRegistry ;
- WorldRule predicate adapter vs WorldRuleRegistry ;
- Storyline/Chapter persistence ou metadata ;
- rewards reportés à Phase 5 ;
- Quest Journal reporté ;
- UI premium reportée à Phase 7.

## 17. Evidence Pack

### 17.1 git status initial

```text
 M "MVP Selbrume/road_map_phase_1.md"
?? reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md
```

Note honnête :

```text
Cette sortie est la première sortie brute capturée au démarrage du checkpoint.
Des commandes Git read-only immédiatement après ont confirmé que
reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md est suivi par
Git et que le worktree était propre avant les modifications P1-CHECKPOINT-01.
```

### 17.2 Fichiers lus

```text
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_1.md
MVP Selbrume/road_map.md
MVP Selbrume/narrative_studio.md
MVP Selbrume/selbrume.md
reports/roadmap/pokemap_full_product_phased_roadmap_v1.md
reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md
reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md
reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md
reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md
reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md
reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md
reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md
reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md
reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md
reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md
reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md
```

### 17.3 Fichiers créés

```text
reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md
MVP Selbrume/road_map_phase_2.md
```

### 17.4 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_1.md
MVP Selbrume/road_map_global.md
```

### 17.5 Commandes exécutées

```text
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md && git status --short --untracked-files=all
git diff -- "MVP Selbrume/road_map_phase_1.md"
wc -l reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md "MVP Selbrume/road_map_phase_1.md" "MVP Selbrume/road_map_global.md"
test -f reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md && printf 'p1_07 report present\n'; test -f "MVP Selbrume/road_map_phase_2.md" && printf 'road_map_phase_2.md present\n' || printf 'road_map_phase_2.md absent\n'
git status --short --untracked-files=all && git diff --stat && git diff --name-only
git ls-files -- reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md "MVP Selbrume/road_map_phase_1.md"
git status --short --untracked-files=all --ignored
sed -n '1,760p' "MVP Selbrume/road_map_global.md" && sed -n '1,680p' "MVP Selbrume/road_map_phase_1.md"
sed -n '1,260p' "MVP Selbrume/road_map.md"
sed -n '1,260p' "MVP Selbrume/narrative_studio.md"
sed -n '1,260p' "MVP Selbrume/selbrume.md"
rg -n "^(#|## 1\.|## [0-9]+\.|Statut|Prochain lot exact|Phase 1|Phase 2|P1-|Verdict|Résumé|Aucun code|Non exécutés|clôtur|Fact|World Rule|Storyline|Chapter|Story Step|Event|Scene|Cinematic|Validator)" reports/roadmap/pokemap_full_product_phased_roadmap_v1.md reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
rg -n "^(#|## 1\.|## [0-9]+\.|Statut|Prochain lot exact|Phase 1|Phase 2|P1-|Verdict|Résumé|Aucun code|Non exécutés|clôtur|Fact|World Rule|Storyline|Chapter|Story Step|Event|Scene|Cinematic|Validator)" reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md
rg -n "^(#|##|###|Level|Niveau|Verdict|Résumé|Status|Statut|Conclusion|Limite|Evidence|Validator|World Rule|side quest|reward|money|XP|Fact|Story|Step|Scene|Battle)" reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md
sed -n '1,220p' reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md && sed -n '890,960p' reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md && sed -n '969,1040p' reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md
sed -n '1,180p' "MVP Selbrume/road_map_phase_1.md" && sed -n '500,640p' "MVP Selbrume/road_map_phase_1.md"
sed -n '1,170p' "MVP Selbrume/road_map_global.md" && sed -n '560,660p' "MVP Selbrume/road_map_global.md"
sed -n '3,55p' reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md && sed -n '70,125p' reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md && sed -n '968,1035p' reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
sed -n '3,70p' reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md && sed -n '519,580p' reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md && sed -n '968,1045p' reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md
git status --short --untracked-files=all
rg -n "^## 10\.|^## 11\.|^## 15\.|P1-CHECKPOINT|Prochain lot exact|Historique" "MVP Selbrume/road_map_phase_1.md"
rg -n "^## 7\.|^## 8\.|^## 14\.|^## 15\.|^## 19\.|^## 20\.|Phase courante|Prochain lot exact|FactRegistry|WorldRuleRegistry" "MVP Selbrume/road_map_global.md"
sed -n '350,580p' "MVP Selbrume/road_map_phase_1.md" && sed -n '120,260p' "MVP Selbrume/road_map_global.md" && sed -n '260,580p' "MVP Selbrume/road_map_global.md"
sed -n '1,28p' "MVP Selbrume/road_map_global.md"
sed -n '80,250p' "MVP Selbrume/road_map_global.md"
sed -n '520,645p' "MVP Selbrume/road_map_global.md"
sed -n '250,340p' "MVP Selbrume/road_map_global.md"
git diff --check
git diff --no-index --check /dev/null reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md || true
git diff --no-index --check /dev/null "MVP Selbrume/road_map_phase_2.md" || true
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff -- "MVP Selbrume/road_map_phase_1.md"
git diff -- "MVP Selbrume/road_map_global.md"
git diff --name-only -- packages examples/playable_runtime_host
```

### 17.6 git diff --check

```text
```

Sortie vide — aucune erreur whitespace détectée.

### 17.7 git diff --stat

```text
 MVP Selbrume/road_map_global.md  | 90 +++++++++++++++++++++++++++-------------
 MVP Selbrume/road_map_phase_1.md | 63 +++++++++++++++++++++-------
 2 files changed, 109 insertions(+), 44 deletions(-)
```

### 17.8 git diff --name-only

```text
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_1.md
```

### 17.9 git status final

```text
 M "MVP Selbrume/road_map_global.md"
 M "MVP Selbrume/road_map_phase_1.md"
?? "MVP Selbrume/road_map_phase_2.md"
?? reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md
```

### 17.10 Tests / analyze

```text
Non exécutés — P1-CHECKPOINT-01 est documentaire et ne modifie aucun code.
```

### 17.11 Contrôles no-index des fichiers créés

Rapport checkpoint :

```text
```

Roadmap Phase 2 :

```text
```

Les deux sorties sont vides — aucune erreur détectée par `git diff --no-index --check`.

### 17.12 Diff complet de road_map_phase_1.md

```diff
diff --git a/MVP Selbrume/road_map_phase_1.md b/MVP Selbrume/road_map_phase_1.md
index 16605e61..552c7b5a 100644
--- a/MVP Selbrume/road_map_phase_1.md
+++ b/MVP Selbrume/road_map_phase_1.md
@@ -4,11 +4,11 @@

 Phase 1 — Canonical Product Model / Narrative Studio Foundations

-Statut : 🔜 En préparation
+Statut : ✅ Clôturée avec réserves mineures

-Lot courant : P1-07 — Phase 2 Domain Contract Proposal
+Lot courant : P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision

-Prochain lot exact après P1-07 : P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision
+Prochain lot exact après P1-CHECKPOINT-01 : P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit

 Suivi des lots :

@@ -20,7 +20,7 @@ Suivi des lots :
 - ✅ P1-05 — Selbrume Reference Grammar Mapping
 - ✅ P1-06 — No-code Workflow Specification
 - ✅ P1-07 — Phase 2 Domain Contract Proposal
-- 🔜 P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision
+- ✅ P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision

 P1-00 : ✅ terminé

@@ -38,7 +38,7 @@ P1-06 : ✅ terminé

 P1-07 : ✅ terminé

-P1-CHECKPOINT-01 : 🔜 prochain lot exact
+P1-CHECKPOINT-01 : ✅ terminé

 ## 2. Objectif de la Phase 1

@@ -371,7 +371,7 @@ Critères de validation :
 - les risques de migration sont listés ;
 - les modèles à reporter sont explicitement justifiés.

-### 🔜 P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision
+### ✅ P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision

 Objectif :
 Vérifier que Phase 1 a fermé les ambiguïtés et recommander la roadmap détaillée
@@ -402,20 +402,23 @@ Critères de validation :

 ## 10. Prochain lot exact

-P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision
+P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit

 Objectif du prochain lot :
-Auditer tous les livrables Phase 1, vérifier les ambiguïtés restantes,
-décider la transition vers Phase 2 et recommander ou préparer la roadmap de
-phase suivante.
+Auditer les modèles, metadata, validators, conventions et contrats narratifs
+existants avant de créer ou modifier des contrats Phase 2.

-P1-CHECKPOINT-01 est le seul lot Phase 1 autorisé à décider la transition de
-phase. Il ne doit pas démarrer Phase 2 ni créer de contenu Selbrume final sans
-validation utilisateur.
+P2-00 doit rester audit-first. Il peut préparer la Phase 2, mais ne doit pas
+créer de modèle `map_core`, de schéma JSON, de migration, d’UI ou de contenu
+Selbrume final sans lot explicite.
+
+Roadmap de phase courante après clôture :
+
+- `MVP Selbrume/road_map_phase_2.md`

 ## 11. Critères de sortie de Phase 1

-La Phase 1 pourra être fermée uniquement si :
+La Phase 1 est clôturée avec réserves mineures si :

 - les concepts Storyline, Chapter, Story Step, Event, Scene, Cinematic, Dialogue
   Yarn, Fact, World Rule et Validator sont définis ;
@@ -429,6 +432,19 @@ La Phase 1 pourra être fermée uniquement si :
 - les non-objectifs Phase 1 sont respectés ;
 - P1-CHECKPOINT-01 recommande explicitement la suite.

+Verdict checkpoint :
+
+```text
+✅ Phase 1 clôturable avec réserves mineures.
+```
+
+Réserves principales :
+
+- Phase 1 reste documentaire et conceptuelle ;
+- les preuves Level 3 Flame et Level 4 projet disque restent hors Phase 1 ;
+- les contrats `map_core`, JSON, migrations et UI sont reportés ;
+- la roadmap Phase 2 doit commencer par audit avant création de modèles.
+
 ## 12. Règle permanente de maintenance de cette roadmap

 À chaque lot de Phase 1, l’agent doit :
@@ -467,7 +483,8 @@ P1-CHECKPOINT-01 devra aussi mettre à jour

 - Modèles `map_core` Storyline / Chapter / Story Step / Event : reportés à la
   Phase 2 si validés par la Phase 1.
-- FactRegistry et WorldRuleRegistry : reportés à la Phase 2.
+- FactDescriptor / Fact Presentation Layer et World Rule Predicate Adapter :
+  reportés à la Phase 2, sans présumer un registre lourd.
 - Validation Flame Level 3 et projet disque Level 4 : reportés à une phase de
   validation runtime / disk.
 - Reward Model, money, XP et level-up : reportés à une sous-roadmap gameplay
@@ -568,3 +585,19 @@ P1-CHECKPOINT-01 devra aussi mettre à jour
   Décisions utilisateur nouvelles : aucune.
   Changements de périmètre : aucun.
   Prochain lot exact fixé à P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision.
+- 2026-05-24 — P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision terminé.
+  Résultat : Phase 1 clôturée avec réserves mineures ; concepts et frontières
+  Narrative Studio figés ; gaps Phase 2+ classés ; roadmap globale mise à jour
+  vers Phase 2 ; roadmap vivante Phase 2 créée sans exécuter P2-00.
+  Fichiers créés : `reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md`,
+  `MVP Selbrume/road_map_phase_2.md`.
+  Fichiers modifiés : `MVP Selbrume/road_map_phase_1.md`,
+  `MVP Selbrume/road_map_global.md`.
+  Commandes exécutées : lectures Markdown ciblées, `rg`, `sed`, `wc -l`,
+  `git status --short --untracked-files=all`, `git diff --check`,
+  `git diff --stat`, `git diff --name-only`, `git diff --no-index --check`.
+  Décisions utilisateur nouvelles : validation de la roadmap Phase 2 et des
+  décisions ouvertes à effectuer avant ou pendant P2-00.
+  Changements de périmètre : création documentaire de
+  `MVP Selbrume/road_map_phase_2.md` justifiée par la clôture Phase 1.
+  Prochain lot exact fixé à P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit.
```

### 17.13 Diff complet de road_map_global.md

```diff
diff --git a/MVP Selbrume/road_map_global.md b/MVP Selbrume/road_map_global.md
index 556ee63d..f6006f2e 100644
--- a/MVP Selbrume/road_map_global.md
+++ b/MVP Selbrume/road_map_global.md
@@ -6,18 +6,20 @@ Roadmap globale : active

 Bloc NS-GS-01 → NS-GS-18 : ✅ terminé comme bloc mechanics-first Level 2 Application

-Phase courante : Phase 1 — Canonical Product Model / Narrative Studio Foundations
+Phase courante : Phase 2 — Domain Model & Contracts

-Roadmap de phase courante : `MVP Selbrume/road_map_phase_1.md`
+Roadmap de phase courante : `MVP Selbrume/road_map_phase_2.md`

-Lot courant : ROADMAP-GLOBAL-00 — Global Phase Roadmap Bootstrap
+Lot courant : P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit

-Prochain lot exact après ROADMAP-GLOBAL-00 : P1-01 — Canonical Narrative Product Model V1
+Prochain lot exact : P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit

 Suivi global :

 - ROADMAP-GLOBAL-00 : ✅ terminé
-- P1-01 : 🔜 prochain lot exact
+- Phase 1 — Canonical Product Model / Narrative Studio Foundations : ✅ clôturée avec réserves mineures
+- Phase 2 — Domain Model & Contracts : 🔜 phase courante
+- P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit : 🔜 prochain lot exact

 ## 2. Objectif final de PokeMap

@@ -100,8 +102,8 @@ Chaque phase doit produire un checkpoint de fermeture indiquant :
 ## 5. Synthèse des phases

 - ✅ Phase 0 — Audit global & roadmap reset
-- 🔜 Phase 1 — Canonical Product Model / Narrative Studio Foundations
-- Phase 2 — Domain Model & Contracts
+- ✅ Phase 1 — Canonical Product Model / Narrative Studio Foundations
+- 🔜 Phase 2 — Domain Model & Contracts
 - Phase 3 — Runtime / Application / Flame / Disk Validation
 - Phase 4 — Authoring Workflows Minimal
 - Phase 5 — Gameplay Gaps Prioritaires
@@ -223,14 +225,30 @@ Checkpoint final :
 - P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision

 Statut :
-🔜 phase courante.
+✅ clôturée avec réserves mineures.
+
+Résultat checkpoint :
+
+```text
+Phase 1 a figé la grammaire produit du Narrative Studio :
+Storyline, Chapter, Story Step, Event, Scene, Cinematic, Dialogue Yarn, Fact,
+World Rule, Validator, mapping Selbrume, workflows no-code et proposition
+Phase 2.
+```
+
+Réserves :
+
+- Phase 1 reste documentaire, pas runtime ;
+- les preuves Level 3 Flame et Level 4 projet disque restent reportées ;
+- les contrats domaine, JSON, migrations, authoring minimal et UI restent à
+  traiter dans les phases suivantes.

 ## 8. Phase 2 — Domain Model & Contracts

 Objectif :
-Définir ou stabiliser dans `map_core` les contrats nécessaires : Storyline,
-Chapter, StoryStep, Event, SceneGraph, FactRegistry, WorldRuleRegistry,
-Cinematic metadata et diagnostics.
+Définir ou stabiliser les contrats, descriptors, adapters, read models et
+diagnostics nécessaires au Narrative Studio, en partant de l’existant avant de
+créer de nouveaux modèles.

 Pourquoi :
 Les concepts Phase 1 devront devenir des contrats stables, testables et
@@ -244,10 +262,12 @@ Préconditions :

 Périmètre :

-- modèles pure Dart si nécessaires ;
+- audit de l’existant narratif ;
+- contrats pure Dart si nécessaires ;
+- adapters/read models lorsque le stockage existe déjà ;
 - diagnostics et validators associés ;
 - compatibilité avec `ScenarioAsset` existant ;
-- tests JSON / validation ciblés.
+- stratégie persistence / JSON / migration explicite.

 Non-objectifs :

@@ -258,8 +278,8 @@ Non-objectifs :

 Livrables :

-- roadmap vivante Phase 2 ;
-- contrats domaine validés ou explicitement reportés ;
+- `MVP Selbrume/road_map_phase_2.md` ;
+- contrats domaine validés, adaptés ou explicitement reportés ;
 - tests ciblés ;
 - rapport checkpoint Phase 2.

@@ -274,7 +294,7 @@ Checkpoint final :
 - P2-CHECKPOINT-01 — Domain Contracts Readiness Review

 Statut :
-future.
+🔜 phase courante.

 ## 9. Phase 3 — Runtime / Application / Flame / Disk Validation

@@ -537,26 +557,29 @@ future tardive.
 ## 14. Phase courante

 Phase courante :
-Phase 1 — Canonical Product Model / Narrative Studio Foundations
+Phase 2 — Domain Model & Contracts

 Roadmap de phase :
-`MVP Selbrume/road_map_phase_1.md`
+`MVP Selbrume/road_map_phase_2.md`

 Prochain lot de la phase :
-P1-01 — Canonical Narrative Product Model V1
+P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit

 Note :
-ROADMAP-GLOBAL-00 a créé la présente roadmap globale. Il ne démarre pas P1-01.
+P1-CHECKPOINT-01 a clôturé Phase 1 et créé la roadmap vivante Phase 2. Il ne
+démarre pas P2-00.

 ## 15. Prochain lot exact

-P1-01 — Canonical Narrative Product Model V1
+P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit

-P1-01 doit rester documentaire/design-first et définir Storyline, Chapter,
-Story Step, Event, Scene, Cinematic, Dialogue Yarn, Fact, World Rule et Validator.
+P2-00 doit rester audit-first et documentaire / cadrage domaine. Il doit
+inventorier précisément les modèles, metadata, validators, runtime source events,
+authoring projections et conventions existantes avant toute création de contrat.

-P1-01 ne doit pas créer de code, de modèles `map_core`, d’UI, de fixtures
-Selbrume finales ou de `project.json`.
+P2-00 ne doit pas créer de contenu Selbrume final, ne doit pas lancer l’UI
+premium, et ne doit pas modifier le runtime Flame sauf si un lot dédié ultérieur
+le demande explicitement.

 ## 16. Critères de changement de phase

@@ -620,10 +643,11 @@ ou si l’utilisateur le demande explicitement.
 - Level 3 Flame / PlayableMapGame Golden Slice complet : non entièrement prouvé.
 - Level 4 projet disque / vrai projet créé dans l’éditeur : non prouvé pour le
   Golden Slice narratif complet.
-- Storyline / Chapter / Story Step model canonique : Phase 1 puis Phase 2.
-- Event model canonique : Phase 1 puis Phase 2.
-- Scene vs Cinematic boundary : Phase 1.
-- FactRegistry / WorldRuleRegistry : Phase 1 puis Phase 2.
+- Storyline / Chapter / Story Step contract ou descriptor : Phase 2.
+- Event authoring source contract : Phase 2.
+- Scene / ScenarioAsset adapter : Phase 2.
+- FactDescriptor / Fact Presentation Layer : Phase 2.
+- World Rule Predicate Adapter : Phase 2.
 - Validator UI et intégration authoring : Phase 4 puis Phase 7.
 - Reward Model, money, XP, level-up : Phase 5.
 - Static wild encounter authorable réel : Phase 5.
@@ -636,3 +660,11 @@ ou si l’utilisateur le demande explicitement.
   courante fixée à Phase 1 — Canonical Product Model / Narrative Studio
   Foundations. Prochain lot exact fixé à P1-01 — Canonical Narrative Product
   Model V1.
+- 2026-05-24 — P1-CHECKPOINT-01 — Phase 1 clôturée avec réserves mineures.
+  La grammaire produit du Narrative Studio est figée : Storyline, Chapter,
+  Story Step, Event, Scene, Cinematic, Dialogue Yarn, Fact, World Rule,
+  Validator, mapping Selbrume, workflows no-code et proposition Phase 2.
+  Phase courante mise à jour vers Phase 2 — Domain Model & Contracts.
+  Roadmap de phase courante fixée à `MVP Selbrume/road_map_phase_2.md`.
+  Prochain lot exact fixé à P2-00 — Phase 2 Roadmap Bootstrap / Domain
+  Contract Audit.
```

### 17.14 Contenu complet de road_map_phase_2.md

````md
# Phase 2 Roadmap — Domain Model & Contracts

## 1. Statut de la phase

Phase 2 — Domain Model & Contracts

Statut : 🔜 Prête à démarrer

Lot courant : P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit

Prochain lot exact : P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit

Suivi des lots :

- 🔜 P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit
- P2-01 — Existing Narrative Domain Inventory
- P2-02 — Story Step Descriptor / Storyline Metadata Decision
- P2-03 — Event Authoring Source Contract
- P2-04 — Scene / ScenarioAsset Adapter Contract
- P2-05 — Outcome Reference Contracts
- P2-06 — Battle Reference / Outcome Contract
- P2-07 — Fact Descriptor / Presentation Layer
- P2-08 — World Rule Predicate Adapter Contract
- P2-09 — Narrative Validator Diagnostic Expansion
- P2-10 — Reference Picker Read Models
- P2-CHECKPOINT-01 — Domain Contracts Readiness Review

P2-00 : 🔜 prochain lot exact

## 2. Objectif de la Phase 2

Transformer la grammaire produit Phase 1 en socle domaine minimal, testable et
utilisable par les phases suivantes.

La Phase 2 doit construire ou stabiliser seulement les contrats qui ont des
consumers explicites :

- `map_core` diagnostics / contracts / read models ;
- `map_gameplay` condition et GameState si nécessaire ;
- `map_runtime` adapters d’exécution plus tard ;
- `map_editor` authoring workflows et picker sources plus tard ;
- save/load et project disk si un besoin persistant est prouvé.

Règle centrale :

```text
Pas de modèle sans consumer clair.
Pas de registry sans usage clair.
Pas de JSON/migration si le besoin n’est pas justifié.
```

## 3. Pourquoi cette phase existe

La Phase 1 a fermé la grammaire produit :

```text
Storyline organise.
Chapter sectionne.
Story Step jalonne.
Event déclenche.
Scene orchestre.
Cinematic met en scène.
Yarn produit des outcomes.
Battle résout.
Scene interprète.
Fact nomme ce qui est vrai.
World Rule projette passivement.
Validator diagnostique.
```

La Phase 2 doit maintenant vérifier comment cette grammaire se raccorde aux
structures existantes : `ScenarioAsset`, metadata editor, `completedStepIds`,
`storyFlags`, predicates runtime, `ProjectManifest`, `NarrativeValidator` et
sources de picker futures.

## 4. Préconditions

- Phase 1 clôturée avec réserves mineures.
- `reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md`
  existe.
- `MVP Selbrume/road_map_global.md` pointe vers la Phase 2.
- Selbrume reste une référence conceptuelle.

## 5. Périmètre Phase 2

Inclus :

- audit de l’existant narratif ;
- décisions descriptor / adapter / contrat / report ;
- contrats domaine pure Dart si nécessaires ;
- diagnostics Validator prioritaires ;
- read models et sources de picker sans UI ;
- stratégie persistence / JSON / migration ;
- package boundaries.

Exclus :

- UI moderne ou premium ;
- Scene Builder complet ;
- Cinematic Builder complet ;
- runtime Flame Golden Slice ;
- projet disque Selbrume ;
- contenu Selbrume final ;
- Reward Model unifié ;
- Quest Engine ;
- Quest Journal ;
- money / XP / level-up ;
- static wild authoring complet ;
- Door/Warp Engine complet.

## 6. Non-objectifs stricts

- Ne pas créer Selbrume final.
- Ne pas créer de `project.json` Selbrume.
- Ne pas lancer Phase 3 runtime/disk.
- Ne pas lancer Phase 4 authoring UI.
- Ne pas lancer Phase 7 UI premium.
- Ne pas coupler `map_battle` au Narrative Studio.
- Ne pas faire de `map_editor` la source de vérité domaine.
- Ne pas modifier `ProjectManifest` sans décision explicite et migration
  documentée.

## 7. Lots Phase 2 proposés

### 🔜 P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit

Objectif :
Vérifier le découpage Phase 2, auditer précisément les structures existantes et
confirmer les premiers lots de contrats.

Fichiers probables à auditer :

- `reports/roadmap/phase_1/*`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_2.md`
- `packages/map_core/lib/src/models/*`
- `packages/map_core/lib/src/operations/narrative_validator.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/*`
- `packages/map_editor/lib/src/features/narrative/*`

Risque :
Créer trop tôt des modèles au lieu de caractériser l’existant.

Tests probables :
Pas de test obligatoire si le lot reste audit/documentaire. Si un audit outillé
est ajouté, il doit rester borné et justifié.

Non-objectifs :
Pas de contrat codé, pas de modèle `map_core`, pas de JSON, pas de migration,
pas de Selbrume final.

Dépendances :
P1-CHECKPOINT-01.

### P2-01 — Existing Narrative Domain Inventory

Objectif :
Inventorier `ScenarioAsset`, metadata narrative, validators, runtime source
events, predicates, save state et authoring projections.

Risque :
Sous-estimer les conventions déjà présentes dans metadata editor.

Tests probables :
Caractérisation si des read models d’inventaire sont créés.

Non-objectifs :
Pas de nouveau modèle persistant.

Dépendances :
P2-00.

### P2-02 — Story Step Descriptor / Storyline Metadata Decision

Objectif :
Décider si Storyline / Chapter / Story Step démarrent comme descriptors,
metadata légère, adapter, ou report partiel.

Risque :
Dupliquer `completedStepIds` ou transformer Story Step en flag technique brut.

Tests probables :
Diagnostics pure Dart sur steps inconnus, orphelins ou jamais complétés si un
contrat est créé.

Non-objectifs :
Pas de Quest Engine, pas de Quest Journal.

Dépendances :
P2-01.

### P2-03 — Event Authoring Source Contract

Objectif :
Formaliser les sources auteur d’Event sans dupliquer inutilement les runtime
source events.

Risque :
Transformer Event en mini-Scene.

Tests probables :
Validation de références source / target si contrat créé.

Non-objectifs :
Pas de runtime Flame.

Dépendances :
P2-01.

### P2-04 — Scene / ScenarioAsset Adapter Contract

Objectif :
Décider si Scene est le nom produit de `ScenarioAsset`, un wrapper, ou un
adapter/read model.

Risque :
Casser `ScenarioAsset` ou créer un modèle parallèle inutile.

Tests probables :
Adapter/read model et diagnostics de nodes/outcomes si contrat créé.

Non-objectifs :
Pas de Scene Builder complet.

Dépendances :
P2-01.

### P2-05 — Outcome Reference Contracts

Objectif :
Rendre les outcomes Yarn / Scenario sélectionnables et validables sans exposer
`scenario.outcome.*` comme UX principale.

Risque :
Créer un OutcomeRegistry trop tôt.

Tests probables :
Outcomes déclarés / émis / consommés / orphelins.

Non-objectifs :
Pas de parser Yarn complet.

Dépendances :
P2-04.

### P2-06 — Battle Reference / Outcome Contract

Objectif :
Stabiliser un contrat minimal de référence battle et outcomes `victory` /
`defeat`.

Risque :
Aspirer money, XP, static wild et rewards dans Phase 2.

Tests probables :
Référence trainer/battle absente, outcome non géré, branch post-battle absente.

Non-objectifs :
Pas de static wild complet, pas de money/XP, pas de Reward Model unifié.

Dépendances :
P2-04.

### P2-07 — Fact Descriptor / Presentation Layer

Objectif :
Fournir des labels humains et relations de source/consumer pour les vérités du
monde, sans dupliquer le GameState.

Risque :
Créer un FactRegistry lourd ou exposer des flags bruts avec un label cosmétique.

Tests probables :
Fact inconnu, jamais écrit, jamais lu, technique sans label humain.

Non-objectifs :
Pas de duplication automatique de state.

Dépendances :
P2-02, P2-05.

### P2-08 — World Rule Predicate Adapter Contract

Objectif :
Adapter les predicates et projections conditionnelles existantes à la grammaire
World Rule.

Risque :
Créer un WorldRuleRegistry prématuré ou laisser World Rule déclencher des
Scenes.

Tests probables :
Condition absente, target absent, conflit de rules, rule utilisée comme Event.

Non-objectifs :
Pas de World Rule qui écrit des Facts ou complète des Steps.

Dépendances :
P2-07.

### P2-09 — Narrative Validator Diagnostic Expansion

Objectif :
Étendre les diagnostics narratifs prioritaires par domaine : Story Step, Event,
Scene, outcomes, Battle, Fact, World Rule et side quest.

Risque :
Produire trop de diagnostics non actionnables.

Tests probables :
Tests unitaires ciblés par diagnostic.

Non-objectifs :
Pas d’auto-correction.

Dépendances :
P2-02 à P2-08.

### P2-10 — Reference Picker Read Models

Objectif :
Préparer les sources pures de pickers Phase 4 sans créer de widgets UI.

Risque :
Confondre read model et widget Flutter.

Tests probables :
Tri stable, labels humains, références cassées, listes filtrées.

Non-objectifs :
Pas d’UI Flutter, pas de design system.

Dépendances :
P2-09.

### P2-CHECKPOINT-01 — Domain Contracts Readiness Review

Objectif :
Clôturer Phase 2, vérifier les contrats créés/adaptés/reportés, les diagnostics
et les package boundaries.

Risque :
Clôturer avec des migrations ou duplications d’état cachées.

Tests probables :
Commandes ciblées selon les packages réellement modifiés en Phase 2.

Non-objectifs :
Pas de Phase 3 démarrée.

Dépendances :
P2-10.

## 8. Critères de sortie Phase 2

Phase 2 pourra être clôturée si :

- les contrats domaine nécessaires au Narrative Studio sont créés, adaptés ou
  explicitement reportés ;
- les diagnostics essentiels sont présents ou reportés avec justification ;
- les pickers Phase 4 disposent de sources de données propres ;
- les package boundaries restent respectées ;
- tout modèle persistant a une justification claire ;
- aucune migration `ProjectManifest` inutile n’est introduite ;
- aucun contenu Selbrume final n’est créé ;
- Phase 3 peut valider runtime/disk sur une base stable.

## 9. Règle permanente de maintenance

À chaque lot Phase 2, l’agent doit :

1. Lire `MVP Selbrume/road_map_global.md`.
2. Lire `MVP Selbrume/road_map_phase_2.md`.
3. Lire les rapports Phase 1 pertinents.
4. Respecter le prochain lot exact.
5. Ne pas démarrer un autre lot.
6. Distinguer création, adaptation et report.
7. Justifier chaque nouveau contrat par des consumers explicites.
8. Fournir un Evidence Pack complet.
9. Mettre à jour cette roadmap vivante.
10. Ne modifier `road_map_global.md` qu’au checkpoint ou sur demande explicite.

## 10. Décisions à valider avant ou pendant P2-00

- Valider la roadmap Phase 2 proposée.
- Confirmer audit-first avant création directe de contrats.
- Décider si Scene est `ScenarioAsset`, wrapper ou adapter/read model.
- Décider FactDescriptor / Fact Presentation Layer avant FactRegistry.
- Décider World Rule Predicate Adapter avant WorldRuleRegistry.
- Décider si Storyline / Chapter deviennent persistants dès Phase 2.
- Confirmer que rewards, Quest Journal et UI premium restent reportés.

## 11. Rappels permanents

```text
Phase 2 construit les contrats utiles.
Phase 2 ne construit pas Selbrume.
Phase 2 ne construit pas l’UI premium.
Phase 2 ne prouve pas le runtime Flame complet.
```

Le prochain lot exact est :

```text
P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit
```
````

### 17.15 Preuve qu’aucun package code n’est modifié

```text
```

Sortie vide — aucun fichier sous `packages/` ou `examples/playable_runtime_host/`
n’est modifié.

## 18. Auto-review critique

Le checkpoint a-t-il modifié uniquement ce qui était autorisé ?

- Oui. Les modifications prévues sont documentaires : rapport checkpoint,
  roadmap Phase 1, roadmap globale et roadmap Phase 2.

Le rapport checkpoint existe-t-il au bon chemin ?

- Oui : `reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md`.

`road_map_phase_1.md` a-t-elle été mise à jour ?

- Oui. P1-CHECKPOINT-01 est marqué terminé et P2-00 devient le prochain lot.

`road_map_global.md` a-t-elle été mise à jour ?

- Oui. Elle pointe maintenant vers Phase 2 et `road_map_phase_2.md`.

`road_map_phase_2.md` a-t-elle été créée seulement si justifié ?

- Oui. Le verdict de clôture Phase 1 justifie la roadmap vivante Phase 2.

Aucun code n’a-t-il été modifié ?

- Oui. Aucun fichier sous `packages/` ou `examples/playable_runtime_host/` n’est
  modifié.

Aucun test/analyze Dart/Flutter n’a-t-il été lancé inutilement ?

- Oui. Aucun `dart test`, `flutter test`, `dart analyze` ou `flutter analyze`
  n’a été lancé.

Phase 2 n’a-t-elle pas été exécutée ?

- Oui. P2-00 est seulement fixé comme prochain lot exact.

Selbrume est-il resté une référence conceptuelle seulement ?

- Oui. Aucun contenu Selbrume final, fixture ou `project.json` n’a été créé.

Les réserves sont-elles honnêtes ?

- Oui. Le rapport distingue preuves conceptuelles, Level 2 historique, et gaps
  Level 3/4, runtime, disk, authoring, UI et gameplay.

Les décisions utilisateur restantes sont-elles explicites ?

- Oui. Elles sont listées en section 16.

Le prochain lot exact est-il clair ?

- Oui : P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit.

### Regard critique sur le prompt

Le prompt est cohérent avec la gouvernance par phases et force une clôture
propre. La seule tension est qu’il autorise la création de `road_map_phase_2.md`
dans le checkpoint tout en rappelant de ne pas démarrer Phase 2. Le rapport et
la roadmap résolvent cette tension en créant uniquement un document de cadrage
et en laissant P2-00 non exécuté.
