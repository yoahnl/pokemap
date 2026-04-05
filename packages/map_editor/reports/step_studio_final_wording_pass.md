# Step Studio — passe finale wording / micro-UX (strict, petit scope)

## Résumé exécutif

Alignement **surface uniquement** du vocabulaire Step Studio sur la cible produit : **résultat** partout à la place d’**issue**, **Transition** au lieu de **Note de transition**, **Résultats possibles** sur le canvas, **Texte affiché au centre** au lieu du parcours, types **Résultat de cette étape** / **Résultat pour l’histoire** / **État du monde**, palette **Résultats** + **Carte** + actions **Ajouter un résultat** / **pour l’histoire** / **changement**. **Aucun** changement de schéma JSON, **aucune** nouvelle logique runtime, **aucun** nouveau champ. **`flowUnlocksStepId`** reste **mémo uniquement** (inspecteur) ; **toujours absent du canvas**.

## Wordings avant → après (précis)

| Emplacement | Avant | Après |
|-------------|--------|--------|
| Canvas — bloc local | Issues possibles | **Résultats possibles** |
| Canvas — hint local | … issues … | **… résultats …** |
| Canvas — sortie | Note de transition | **Transition** |
| Canvas — intro | ordre du parcours | **ordre au centre** |
| `stepStudioOutcomeScopeLabel` (local) | Issue de cette étape | **Résultat de cette étape** |
| Legacy description parse | Step issue du… | **Étape dérivée du…** (évite la confusion avec « issue » produit) |
| Inspecteur — liste locale | Issues possibles | **Résultats possibles** |
| Inspecteur — sous-titre liste | Issues enregistrées… | **Résultats de cette étape…** |
| Inspecteur — CTA liste | Ajouter une issue | **Ajouter un résultat** |
| Inspecteur — mauvais scope local | … issue … Issues possibles … parcours | **… résultat … Résultats possibles … au centre** |
| Inspecteur — mauvais scope prog. | … parcours au centre | **… au centre** |
| Inspecteur — flow* champs | Texte … parcours | **Texte affiché au centre** (+ sous-titres alignés) |
| Inspecteur — transition | Note de transition | **Transition** |
| Inspecteur — monde CTA | Ajouter un changement sur la carte | **Ajouter un changement** |
| Palette — nav | Issues | **Résultats** (sous-titre **Résultats possibles pour cette étape**) |
| Palette — nav carte | Changements sur la carte | **Carte** (sous-titre **Changements sur la carte**) |
| Palette — transition sous-titre | Note de transition — … | **Mémo seulement — rien d’automatique** |
| Palette — section actions | Ajouter | **Résultats possibles** (puis boutons résultats) |
| Palette — actions | Ajouter une issue / d’histoire / changement sur… | **Ajouter un résultat** / **pour l’histoire** / **changement** (+ scène réordonnée après) |
| Gabarit défaut outcome local | Nouvelle issue | **Nouveau résultat** |
| Footnote workspace | … parcours… issues… | **… au centre… résultats…** |
| Commentaire code gabarit | … validation | **condition de fin** |

## Conservé tel quel (déjà conforme ou hors cible)

- Titres canvas déjà verrouillés : **Cette étape**, **Quand ça commence**, **Objectif**, **Scènes liées**, **Quand l’étape se termine**, **Résultats pour l’histoire**, **Changements sur la carte**.
- **Condition de fin** / **Condition de fin enregistrée** / **Règle actuelle** dans l’inspecteur (condition de fin).
- **Type de résultat** sur le dropdown des outcomes (pas de retour à « Portée »).
- **Scène liée**, **Rôle de la scène**, **Référence de la scène**, renvoi **Cutscene Studio** où pertinent.
- **Étape associée (mémo uniquement)** pour `flowUnlocksStepId`.
- Tuile palette **Fin** (accès condition de fin) : **non supprimée** — absent de ta liste courte navigation mais **indispensable** au workflow existant ; wording déjà clair.
- **Repères & ajouts** en tête de palette (non repris dans la liste cible ; inchangé pour rester conservateur).

## Refus / non-faits (conscients)

- **Pas** de second libellé de section du type « Scène et carte » sous les actions : évite un concept produit nouveau ; **espacement** seul entre blocs d’actions.
- **Pas** de renommage d’enums Dart, de clés JSON, ni de `flowValidationLabel` (nom de champ technique inchangé).
- **Pas** de tests élargis hors `step_flow_canvas_test.dart` (scope demandé).

## Justification UX / honnêteté

- **Résultat** remplace **issue** : même objet métier (outcome local), vocabulaire plus naturel pour un créateur et moins « ticket technique ».
- **Transition** + **N’active rien automatiquement** + **Étape associée (mémo uniquement)** : pas d’ambiguïté sur le fait qu’**aucune** autre étape ne s’active toute seule via ce mémo.
- **Au centre** au lieu de **parcours** : ancrage spatial dans l’UI (colonne centrale) sans jargon « parcours ».
- **Cutscene Studio** nommé explicitement là où on renvoie vers la mise en scène ; Step Studio reste sur la **logique d’étape**.

## Fichiers touchés

- `lib/src/features/narrative/application/step_studio_authoring.dart`
- `lib/src/ui/canvas/step_studio_workspace.dart`
- `lib/src/ui/canvas/step_studio/step_flow_canvas.dart`
- `lib/src/ui/canvas/step_studio/step_flow_palette.dart`
- `lib/src/ui/canvas/step_studio/step_flow_focus.dart`
- `test/step_flow_canvas_test.dart`
- `reports/step_studio_final_wording_pass.md`

## Tests exécutés

```bash
cd packages/map_editor && flutter test test/step_flow_canvas_test.dart
cd packages/map_editor && flutter test test/step_studio_authoring_test.dart
```

Résultat : **OK** (titres finaux canvas, absence de `flowUnlocksStepId` sur le canvas, anti-régressions **Note de transition** / **Issues possibles** / **Portée** / **Validation** ; authoring inchangé côté schéma).

## Rappels obligatoires

- **Runtime** : rien de nouveau n’a été branché ; seules des chaînes affichées ont changé.
- **`flowUnlocksStepId`** : **mémo uniquement** ; pas de déblocage / enchaînement / graphe runtime suggéré par le wording ; **toujours masqué du canvas**.

## Limites / risques résiduels

- La tuile **Fin** en palette n’était pas dans la liste des 6 libellés navigation ; elle reste pour ne pas casser le flux. On pourra la renommer plus tard si le workflow est revu.
- Les **IDs techniques** (`outcomeId`, `cutsceneId`, etc.) restent visibles là où utile — ce n’est pas du « wording créateur » mais de l’information de projet.

---

**Git** : aucune opération Git d’écriture effectuée dans le cadre de cette passe.
