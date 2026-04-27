# Lots 67–69 — Surface Studio Atlas Edit + Delete Guard V0

## Résumé exécutif

Mise en place d’un **mode édition local** des atlas (brouillon prérempli, id verrouillé, application au catalogue de travail sans changer l’ordre des entrées), d’une **suppression en deux étapes** réservée aux atlas **non référencés** par une frame d’animation (`frame.tileRef.atlasId`), et d’une **sélection UI** cohérente après mutation du catalogue (préservation animation/preset lorsque pertinent). Aucun changement `map_core` ni `ProjectManifest` : logique d’aide pure dans `map_editor` + réutilisation du flux existant `onSurfaceCatalogSaveRequested` / `SurfaceStudioPanelFromManifest`.

## Périmètre

- **Inclus** : `packages/map_editor` — Surface Studio (`surface_studio_panel`, `surface_studio_atlas_authoring_prep`, `surface_studio_selection_inspector`, `surface_studio_atlas_editing` + tests).
- **Exclus** (non modifié par ce lot) : `map_core`, `map_runtime`, `map_gameplay`, `map_battle`, `build_runner`, providers Surface dédiés, I/O `project.json` direct, runtime Flame.

## Gate 0 — Status initial avant modification

Capturé au début de l’implémentation de la main courante (branche de travail, état partiel) :

```text
/Users/karim/Project/pokemonProject
codex/psdk-fight-next-move-wave
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_selection_inspector.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_editing.dart
```

```text
 .../surface_studio_atlas_authoring_prep.dart       | 246 +++++++++++++++++++--
 .../surface_studio/surface_studio_panel.dart       |  54 ++++-
 .../surface_studio_selection_inspector.dart        | 125 ++++++++++-
 3 files changed, 398 insertions(+), 27 deletions(-)
```

```text
9ae28e89 chore(ios): ajuster LaunchAction Runner (launcher éphemère)
e9f46ce1 feat(map_editor): Lot 66 Surface Studio UX layout, rapports 65-bis et 66
…
```

*Note : d’éventuels changements `map_core` / rapports lot 15 listés dans le `git status` initial utilisateur n’entrent pas dans le diff livré 67–69 (hors branche de travail au moment de la clôture).*

## Audit initial

- **Lecture** : `ProjectSurfaceCatalog`, `frame.tileRef.atlasId` via `map_core` ; alignement avec `usedByAnimationIds` côté read model (décompte par animation, pas par frame).
- **Flux** : mutations uniquement sur le catalogue de travail (`_workReadModel`) puis prép sauvegarde / `FromManifest` inchangés.
- **Risque** : perte de sélection ou saut vers le dernier atlas à chaque changement de catalogue — corrigé en préservant sélection **animation** et **preset** quand l’entité existe encore dans le catalogue mis à jour.

## Implémentation Lot 67 — Edit Prep

- `SurfaceStudioAtlasAuthoringPrep` : `_isEditMode`, `_editingAtlasId`, `requestEditSignal`, entrée via « Modifier cet atlas » (préparation) ; libellé « Édition locale de l’atlas » ; champs `readOnly` sur l’id en édition ; boutons **Annuler l’édition** / **Appliquer les modifications au catalogue de travail** ; annulation / sortie si la sélection ne correspond plus à l’atlas édité.
- `SurfaceStudioSelectionInspector` : **Modifier cet atlas** si `onRequestEditSelectedAtlas` fourni (même gating que la création : panneau avec callback de sauvegarde Surface).
- `SurfaceStudioPanel` : `_atlasEditSignal`, bump pour synchroniser l’entrée en édition depuis l’inspecteur.

## Implémentation Lot 68 — Edit Atlas

- `validateSurfaceStudioAtlasDraft(..., editingExistingAtlasId: …)` : exemption doublon d’id pour l’atlas en cours d’édition.
- `replaceAtlasInCatalogInPlace` (`surface_studio_atlas_editing.dart`) : remplace l’entrée par **même id**, conserve l’ordre de `atlases`, copie `animations` et `presets` sans les modifier.
- **Interdiction** de changement d’id côté logique (champ read-only + garde `draft.id != _editingAtlasId` → pas d’application).

## Implémentation Lot 69 — Delete Guard

- `countAnimationsReferencingAtlasId` : une animation compte **une fois** si au moins une frame référence l’`atlasId` (équivalent sémantique au blocage « utilisé par N animation(s) »).
- UI : message bloquant si `nAnim > 0` ; sinon texte **Atlas inutilisé — suppression possible.** + **Préparer la suppression de l’atlas** puis **Confirmer la suppression de l’atlas** (deux clics, pas de modal).
- `removeAtlasIdFromWorkCatalog` + `SurfaceStudioPanel._onConfirmDeleteSelectedAtlas` : retrait, sélection = **none**, dirty.
- **Blocage sémantique** : si l’atlas est utilisé, `nAnim > 0` → pas de bouton Préparer.

## Fichiers créés

| Fichier |
|--------|
| `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_editing.dart` |
| `packages/map_editor/test/surface_studio/surface_studio_atlas_editing_test.dart` |
| `reports/surface/surface_engine_lot_67_68_69_surface_studio_atlas_edit_delete.md` |

## Fichiers modifiés

| Fichier | Motif |
|--------|--------|
| `surface_studio_atlas_authoring_prep.dart` | Mode édition, validation, apply, UI |
| `surface_studio_panel.dart` | Signaux édition, delete, ` _selectionAfterCatalogChanged` |
| `surface_studio_selection_inspector.dart` | Modifier + zone suppression, messages |
| `surface_studio_*_test.dart` (3) + nouveau test | Couverture lots 67–69 |

## Fichiers supprimés

Aucun.

## Tests lancés

```bash
cd packages/map_editor && flutter test test/surface_studio/surface_studio_panel_test.dart
cd packages/map_editor && flutter test test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
cd packages/map_editor && flutter test test/surface_studio/surface_studio_selection_inspector_test.dart
cd packages/map_editor && flutter test test/surface_studio/surface_studio_atlas_editing_test.dart
cd packages/map_editor && flutter test test/surface_studio
cd packages/map_core && dart test test/surface_studio_read_model_test.dart
```

## Analyse lancée

```bash
cd packages/map_editor && flutter analyze lib/src/features/surface_studio test/surface_studio
```

**Résultat** : `No issues found!`

## Résultats

- **`flutter test test/surface_studio`** : **281 tests** — **All tests passed!** (ligne finale exacte)
- **`dart test test/surface_studio_read_model_test.dart` (map_core)** : **All tests passed!** (30 tests)

## Evidence Pack

### Status final (extrait)

```text
 M packages/map_editor/.../surface_studio_atlas_authoring_prep.dart
 M packages/map_editor/.../surface_studio_panel.dart
 M packages/map_editor/.../surface_studio_selection_inspector.dart
 M packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart
?? packages/map_editor/.../surface_studio_atlas_editing.dart
?? packages/map_editor/test/surface_studio/surface_studio_atlas_editing_test.dart
?? reports/surface/surface_engine_lot_67_68_69_surface_studio_atlas_edit_delete.md
```

### Diff

Diff principal : répertoires `lib/.../surface_studio/` et `test/surface_studio/` concernés (≈690 lignes pour les chemins `surface_studio` — détail versionné par Git).

## Git status final

Voir section Evidence Pack ; le rapport `??` apparaît après création de ce fichier.

## Changements préexistants

Modifications `surface_studio_*` déjà amorcées au Gate 0 (édition + inspection) : ce lot les **complète** (tests, `surface_studio_atlas_editing`, sélection, analyse verte, rapport).

## Changements du lot groupé 67–69

- Helper `surface_studio_atlas_editing.dart` (comptage, remplacement in-place, retrait).
- Édition / suppression intégrées au panneau et tests associés.
- Ajustement `_selectionAfterCatalogChanged` pour ne pas remplacer la sélection animation/preset par le dernier atlas lors d’une mutation catalogue.

## Périmètre explicitement non touché

- `map_core` **non modifié**
- `ProjectManifest` / fichiers générés **non modifiés**
- `build_runner` **non lancé**
- Aucun provider / repository / service Surface **nouveau**
- Aucune écriture directe `project.json` par ce lot (flux Lot 64/65/66 inchangé côté éditeur)
- Aucun runtime / gameplay / battle
- Pas de `SurfaceLayer`, painter map, import atlas vertical

## Vérification fichiers temporaires

```bash
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
```

Aucun fichier temporaire **créé** par ce lot (la commande peut lister des artefacts préexistants hors scope ; rien d’ajouté dans `packages/map_editor` pour 67–69).

## Vérification mojibake

Chaînes UI françaises (apostrophes typographiques, `animation(s)`) vérifiées en source et via tests d’or ; pas de caractères « cassés » introduits.

## Auto-review

| Question | Réponse |
|----------|---------|
| Id atlas modifiable en édition ? | **Non** (readOnly + logique) |
| Édition remplace l’atlas existant sans changer l’ordre de la liste ? | **Oui** |
| Animations / presets préservés à l’apply ? | **Oui** |
| Atlas référencé par une animation supprimable ? | **Non** (UI + pas d’action Préparer) |
| Atlas inutilisé supprimable après confirmation ? | **Oui** |
| Suppression nettoie la sélection ? | **Oui** |
| Créer atlas toujours OK ? | **Oui** (tests non régressés) |
| Save flow existant toujours OK ? | **Oui** (tests workspace / Lot 64–65) |
| `map_core` modifié ? | **Non** |
| Tests ciblés + suite Surface Studio ? | **Oui** (281) |
| `flutter analyze` ? | **Oui** |
| Fichier initial disparu du status final sans explication ? | **Non** (ajouts `??` attendus) |
| Fichier hors périmètre modifié ? | **Non** |
| 67/68/69-bis nécessaire ? | **Non** — périmètre V0 couvert ; améliorations UX (copie exacte de tous les textes cahier) possibles en lot optionnel. |

## Critique du prompt

- Exigence **GATE 0** avant toute modif : respectée en conservant un snapshot au tout début de l’exécution (voir section).
- Cohabitation **deux points d’entrée** « Modifier cet atlas » (préparation + inspection) : acceptable ; les deux appartiennent à la zone auteur et partagent le même signal.

---

## Verdict des passes (Audit / Implémentation / Tests / Build / Critique)

| Passe | Verdict |
|------|---------|
| Audit / architecture | **OK** — modèles `map_core` vérifiés, pas d’invention de noms. |
| Implémentation | **OK** — découpage `surface_studio_atlas_editing`, pas de fuite manifest. |
| Tests | **OK** — 281 tests `test/surface_studio` + 30 `map_core` read model. |
| Analyse | **OK** — `flutter analyze` sur chemins requis, 0 issues. |
| Critique finale | **OK** — V0 complète, bis non requis pour le cahier minimal. |
