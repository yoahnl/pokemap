# NS-STORYLINES-11-bis — Roadmap Status Consistency / Pre-Checkpoint Cleanup

## 1. Executive summary

NS-STORYLINES-11-bis corrige uniquement la roadmap Storylines avant checkpoint.

Résultat :

- `NS-STORYLINES-11` est `DONE` dans l'overview.
- La section détaillée `NS-STORYLINES-11` n'est plus générique/TODO.
- `Current status` reste cohérent : lot courant NS11, statut DONE, prochain lot CHECKPOINT.
- Les notes `V1 Creation Readiness` restent présentes et précisent que la création relève de V1.
- Aucun code, test, screenshot, golden ou modèle n'a été modifié.

## 2. Inputs read

Fichiers lus :

- `reports/narrativeStudio/storylines/ns_storylines_11_interaction_wiring_v0.md`
- `reports/narrativeStudio/storylines/road_map_storylines.md`
- `reports/narrativeStudio/storylines/ns_storylines_10_visual_harmonization_visual_gate_v0.md`

## 3. Inconsistency found

Incohérences trouvées dans `road_map_storylines.md` :

- Roadmap overview : `NS-STORYLINES-11` était encore `TODO`.
- Detailed lot `NS-STORYLINES-11` : la section gardait les formulations génériques du lot prévu et `Statut : TODO`.

Sections déjà cohérentes avant ce bis :

- `Current lot: NS-STORYLINES-11`
- `Current lot status: DONE`
- `Next recommended lot: NS-STORYLINES-CHECKPOINT — Storylines V0 Acceptance Checkpoint`
- table de status courante : `NS-STORYLINES-11` déjà `DONE`
- notes `V1 Creation Readiness` déjà présentes
- changelog NS11 déjà présent

## 4. Roadmap corrections

Corrections appliquées :

- Overview : `NS-STORYLINES-11` passé de `TODO` à `DONE`.
- Detailed lot NS11 :
  - statut passé à `DONE` ;
  - résultat livré ajouté ;
  - fichiers modifiés/créés NS11 listés ;
  - tests exécutés listés ;
  - analyse ciblée listée ;
  - Visual Gate NS11 listé ;
  - Design System Gate confirmé ;
  - Fake data guardrails confirmés ;
  - prochain lot confirmé : `NS-STORYLINES-CHECKPOINT`.
- Changelog : entrée courte `2026-05-28 — NS-STORYLINES-11-bis` ajoutée.

## 5. V1 Creation Readiness preservation

La section `V1 Creation Readiness Notes` est conservée.

Elle confirme :

- pas de création Storyline en V0 ;
- modèle `StorylineAsset` ou `ScenarioAsset` enrichi à décider ;
- types futurs `main`, `sideQuest`, `tutorial`, `epilogue`, `episode` ;
- `localEventFlow` ne suffit pas pour faire une quête annexe ;
- création de storyline principale et quête annexe prévue pour V1 uniquement.

## 6. Commands run

Commandes initiales :

```text
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Commandes de lecture et vérification :

```text
rg -n "NS-STORYLINES-11|Current lot:|Current lot status:|Next recommended lot:|V1 Creation|Changelog|Storylines Interaction Wiring V0" reports/narrativeStudio/storylines/road_map_storylines.md
rg -n "^#|^##|NS-STORYLINES-11|V1 Creation|StorylineAsset|localEventFlow" reports/narrativeStudio/storylines/ns_storylines_11_interaction_wiring_v0.md
rg -n "NS-STORYLINES-10|Visual harmonization|Next recommended lot" reports/narrativeStudio/storylines/ns_storylines_10_visual_harmonization_visual_gate_v0.md
rg "NS-STORYLINES-11.*TODO|Current lot:|Current lot status:|Next recommended lot:|Storylines Interaction Wiring V0" reports/narrativeStudio/storylines/road_map_storylines.md
rg "NS-STORYLINES-09 \|.*TODO|NS-STORYLINES-10 \|.*TODO|NS-STORYLINES-11 \|.*TODO" reports/narrativeStudio/storylines/road_map_storylines.md
git diff -- reports/narrativeStudio/storylines/road_map_storylines.md
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Tests Flutter :

```text
Non lancés : lot documentation-only, aucun code Dart, test, screenshot ou golden modifié.
```

Analyse Dart :

```text
Non lancée : lot documentation-only, aucun code Dart modifié.
```

## 7. Evidence Pack

Git branch initiale :

```text
main
```

Git status initial exact :

```text
Sortie : <vide>
```

Git diff --stat initial :

```text
Sortie : <vide>
```

Git diff --name-only initial :

```text
Sortie : <vide>
```

Git diff --check initial :

```text
Sortie : <vide>
```

Git status final exact :

```text
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? reports/narrativeStudio/storylines/ns_storylines_11_bis_roadmap_status_consistency.md
```

Git diff --stat final :

```text
 .../storylines/road_map_storylines.md              | 27 ++++++++++++++--------
 1 file changed, 18 insertions(+), 9 deletions(-)
```

Git diff --name-only final :

```text
reports/narrativeStudio/storylines/road_map_storylines.md
```

Git diff --check final :

```text
Sortie : <vide>
```

Diff complet de `road_map_storylines.md` :

```diff
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index b79210a2..0507c003 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -299,7 +299,7 @@ Interprétation V0 :
 | NS-STORYLINES-08 | Chapters Tab Read-only V0 | editor UI | DONE | NS-STORYLINES-09 |
 | NS-STORYLINES-09 | Chapters Inspector / Step Ordering Read-only V0 | editor UI | DONE | NS-STORYLINES-10 |
 | NS-STORYLINES-10 | Storyline Visual Harmonization / Visual Gate V0 | visual gate | DONE | NS-STORYLINES-11 |
-| NS-STORYLINES-11 | Storylines Interaction Wiring V0 | editor UI / test | TODO | NS-STORYLINES-CHECKPOINT |
+| NS-STORYLINES-11 | Storylines Interaction Wiring V0 | editor UI / test | DONE | NS-STORYLINES-CHECKPOINT |
 | NS-STORYLINES-CHECKPOINT | Storylines V0 Acceptance Checkpoint | checkpoint | TODO | TBD |
 
 ## 9. Detailed lots
@@ -572,16 +572,17 @@ Interprétation V0 :
 
 - Type : editor UI / test.
 - Objectif : brancher uniquement les interactions honnêtes.
-- Fichiers probables : widgets Storylines, `NarrativeWorkspaceCanvas`, tests interaction.
-- Non-objectifs : pas de création Storyline, pas de validation globale, pas de graph editing.
+- Résultat : sélection locale de `globalStory` existante, synchronisation des zones read-only, actions futures non mutantes, V1 Creation Readiness documenté.
+- Fichiers modifiés/créés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`, `reports/narrativeStudio/storylines/ns_storylines_11_interaction_wiring_v0.md`, captures Visual Gate NS11.
+- Non-objectifs respectés : pas de création Storyline, pas de validation globale, pas de graph editing, pas de modèle `StorylineAsset`, pas de quête annexe fake.
 - Dépendances : NS-STORYLINES-10.
 - Critères d'acceptation : interactions réelles fonctionnent, futures disabled, aucune mutation non prévue.
-- Tests attendus : tabs, list selection, inspector, disabled actions.
-- Analyse attendue : `flutter analyze`, `git diff --check`.
-- Visual Gate : interaction focus.
-- Risques : activer trop tôt Nouvelle storyline, Valider, search ou graph.
-- Design system impact : préserver composants existants.
-- Statut : TODO.
+- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
+- Analyse exécutée : analyse ciblée Storylines avec `flutter analyze --no-fatal-infos`.
+- Visual Gate : `ns_storylines_11_interaction_default_graph.png`, `ns_storylines_11_interaction_selected_story_graph.png`, `ns_storylines_11_interaction_selected_story_chapters.png`.
+- Design System Gate : confirmé, aucun `Color(0x...)` / `Colors.*` ajouté.
+- Fake data : aucune donnée cible, aucune quête annexe fake, aucun `localEventFlow` promu.
+- Statut : DONE.
 - Prochain lot attendu : NS-STORYLINES-CHECKPOINT.
 
 ### NS-STORYLINES-CHECKPOINT — Storylines V0 Acceptance Checkpoint
@@ -752,6 +753,7 @@ Pré-requis recommandés pour activer la création Storylines V1 :
 - Validation anti-duplicate : empêcher les ids/titres conflictuels, les types incompatibles et les liens de steps orphelins.
 - Compatibilité : décider comment migrer ou projeter le `ScenarioAsset globalStory` actuel sans casser les projets existants.
 - Quêtes annexes : les afficher uniquement quand le modèle existe ; `localEventFlow` ne suffit pas et ne doit jamais devenir une quête annexe par défaut.
+- Création : storyline principale et quête annexe prévues pour V1 uniquement, pas en V0.
 - Boutons activables plus tard : `Nouvelle storyline`, `+`, `Nouveau chapitre`, validation narrative et création de quête annexe après contrat modèle + tests anti-fake.
 
 Suite V1 documentaire possible, sans démarrage dans V0 :
@@ -765,6 +767,13 @@ Suite V1 documentaire possible, sans démarrage dans V0 :
 
 ## 15. Changelog
 
+### 2026-05-28 — NS-STORYLINES-11-bis
+
+- Correction de cohérence documentaire de la roadmap.
+- `NS-STORYLINES-11` est maintenant `DONE` dans toutes les sections structurantes.
+- Le prochain lot reste `NS-STORYLINES-CHECKPOINT`.
+- Aucun code, test, screenshot ou modèle modifié.
+
 ### 2026-05-28 — NS-STORYLINES-11
 
 - Câblage d'une sélection locale de `globalStory` existante depuis le panneau secondaire Storylines.
```

Sortie exacte de la recherche roadmap principale :

```text
| NS-STORYLINES-11 | Storylines Interaction Wiring V0 | editor UI / test | DONE | NS-STORYLINES-CHECKPOINT |
### NS-STORYLINES-11 — Storylines Interaction Wiring V0
Current lot: NS-STORYLINES-11
Current lot status: DONE
Next recommended lot: NS-STORYLINES-CHECKPOINT — Storylines V0 Acceptance Checkpoint
- Prochain lot recommandé : `NS-STORYLINES-11 — Storylines Interaction Wiring V0`.
```

Note : la dernière ligne est historique dans le changelog NS10. Aucune ligne structurante ne garde NS11 en TODO.

Sortie exacte de la recherche TODO NS09/NS10/NS11 :

```text
Sortie : <vide>
```

Justification de l'absence de tests Flutter :

```text
Lot documentation-only. Seul road_map_storylines.md et le rapport bis sont concernés. Aucun code Dart, test, screenshot ou golden modifié.
```

Auto-review critique :

```text
- Le changelog NS10 conserve naturellement une mention historique "Prochain lot recommandé : NS-STORYLINES-11". Elle n'est pas une incohérence, car elle décrit l'état au moment de NS10.
- Les sections structurantes sont cohérentes : overview, detailed lot, current status, current status table.
- Le checkpoint reste TODO et n'a pas été démarré.
```

## 8. Self-review

Critères relus :

- Aucun code modifié : oui.
- Aucun test modifié : oui.
- Aucun screenshot modifié : oui.
- `road_map_storylines.md` cohérent : oui.
- `NS-STORYLINES-11` DONE dans les sections structurantes : oui.
- `NS-STORYLINES-CHECKPOINT` prochain lot : oui.
- V1 Creation Readiness Notes présent : oui.
- Rapport bis créé : oui.
- `git diff --check` propre : oui.
- Evidence Pack complet : oui.
