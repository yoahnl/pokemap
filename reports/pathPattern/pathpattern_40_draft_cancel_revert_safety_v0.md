# Lot PathPattern-40 — Draft Cancel / Revert Safety V0

## 1. Résumé exécutif

Path Studio propose désormais une sortie explicite du brouillon (« Annuler la création » / « Annuler les modifications »). Si le brouillon est « dirty » (`PathStudioNewPathDraft.isDirty`), un bandeau de confirmation exige une confirmation avant abandon ; sinon l’annulation est immédiate. L’annulation ne touche jamais au `ProjectManifest`, n’appelle pas les callbacks `onNewPathSaveRequested` / `onEditPathSaveRequested`, et affiche un court feedback (« Brouillon annulé. » / « Modifications annulées. »). Le brouillon **création** démarre avec `isDirty: false` ; les mutations déjà codées dans `path_studio_new_path_draft.dart` repassent `isDirty: true`.

## 2. Audit initial (réponses ciblées)

| Question | Réponse |
|----------|---------|
| Create vs edit draft | Mode `PathStudioPathDraftMode.create` vs `edit`, draft edit via `createPathStudioEditDraftFromExistingPathPattern`. |
| Nettoyage après apply réussi | Inchangé : `didUpdateWidget` quand `manifest` change avec `_pendingSavedPathPatternId` résolu ; sinon reset complet liste + brouillon. |
| Bouton Annuler avant ce lot | Absent. |
| Sélection après apply | Inchangé (lot précédent). |
| Détection dirty V0 | Champ existant `PathStudioNewPathDraft.isDirty` ; création initiale passée à `false`. |
| Actions dirty | Déjà centralisées dans les fonctions `path_studio_new_path_draft.dart` (`copyWith(..., isDirty: true)`). |
| Assistant séquence Lot 39 | `generatePathStudioCenterAnimationSequence` met `isDirty: true` sur succès — inchangé, tests couverts. |
| Placement bouton | `_PathStudioHeader` : bouton avec clé `path-studio-cancel-draft-button`, avant « Sauvegarder ». |

## 3. Décision dirty draft V0

- **Création** : `createInitialPathStudioNewPathDraft()` → `isDirty: false`. Les valeurs par défaut ne comptent pas comme modification utilisateur ; la première action de mutation met `isDirty: true`.
- **Édition** : `createPathStudioEditDraftFromExistingPathPattern` → `isDirty: false` (déjà en place) ; toute mutation utilisateur existante force `isDirty: true`.

## 4. UX annulation création

- Libellé : **Annuler la création** (hint « sans appliquer au projet »).
- Si **non dirty** : abandon immédiat, message **Brouillon annulé.**
- Si **dirty** : bandeau `_DraftCancelConfirmationBanner` (clé `path-studio-cancel-draft-confirmation`) avec texte légal + boutons **Continuer l’édition** / confirmation (**Annuler la création** sur le bouton orange, clé `path-studio-cancel-draft-confirm-button`).

## 5. UX annulation édition

- Libellé : **Annuler les modifications**.
- Même schéma de confirmation si dirty ; second ligne d’aide spécifique édition : restauration du chemin sauvegardé.
- Feedback : **Modifications annulées.**

## 6. Confirmation / warning

Option **A** (recommandée) : bandeau inline avec deux actions explicites + libellé de confirmation distinct du simple premier clic.

## 7. Sélection restaurée

- **Création** : `_selectionSourceIndexBeforeNewPathDraft` capturé à l’ouverture du brouillon ; après annulation, `_selectedSourceIndex` reprend cette valeur (peut être `null` → aucune carte sélectionnée, liste visible).
- **Édition** : `_editCancelRestoreSourceIndex` fixé à l’ouverture de l’édition (`_findSourceIndexForPathPatternId`) ; après annulation, même preset en lecture seule.

## 8. Effet sur `isProjectDirty` / `ProjectManifest`

- Annulation : **aucune** mutation du manifest parent du widget ; **aucun** callback apply/save.
- `PathStudioPanel` ne reçoit pas `isProjectDirty` : la non-régression « projet déjà dirty » se raisonne au niveau **shell / EditorNotifier** ; ici on prouve que **les callbacks d’application ne sont pas invoqués** (donc pas de `applyInMemoryProjectManifest` via ce panneau).

## 9. Fichiers créés

| Fichier | Rôle |
|---------|------|
| `reports/pathPattern/pathpattern_40_draft_cancel_revert_safety_v0.md` | Ce rapport. |
| `reports/pathPattern/pathpattern_40_git_diff.patch` | Diff git complet `packages/map_editor` (annexe Evidence Pack). |

## 10. Fichiers modifiés

- `packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`
- `packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart`
- `packages/map_editor/test/path_pattern/path_studio_panel_test.dart`

## 11. Fichiers supprimés

Aucun.

## 12. Tests exécutés

Commandes (répertoire indiqué) :

```bash
cd packages/map_editor && flutter test test/path_pattern/path_studio_new_path_draft_test.dart test/path_pattern/path_studio_panel_test.dart --reporter expanded
```

→ **All tests passed** (92 tests pour ces deux fichiers).

```bash
cd packages/map_editor && flutter test test/path_pattern/path_studio_new_path_build_request_test.dart test/path_pattern/path_studio_new_path_save_flow_test.dart test/path_pattern/path_studio_edit_path_save_flow_test.dart test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart test/path_pattern/path_pattern_editor_read_model_test.dart test/path_pattern/path_pattern_editor_render_resolution_test.dart --reporter expanded
```

→ **All tests passed** (62 tests).

```bash
cd packages/map_editor && flutter test test/map_grid_painter_test.dart test/top_toolbar_test.dart test/status_bar_test.dart --reporter expanded
```

→ **All tests passed** (19 tests).

```bash
cd packages/map_editor && flutter test test/path_pattern/ --reporter compact
```

→ **All tests passed!** (message final compact ; **209 tests** au total pour ce dossier).

```bash
cd packages/map_core && dart test test/project_manifest_path_pattern_save_reload_test.dart test/path_pattern_water_animated_golden_slice_test.dart test/path_pattern_visual_resolution_test.dart --reporter expanded --no-color
```

→ **All tests passed** (14 tests).

```bash
cd packages/map_runtime && flutter test test/path_pattern_water_animated_runtime_golden_slice_test.dart test/path_pattern_runtime_render_resolution_test.dart --reporter expanded
```

→ **All tests passed** (11 tests).

## 13. Résultats des validations

### Analyse statique (bornée au lot)

```bash
cd packages/map_editor && flutter analyze \
  lib/src/features/path_studio/path_studio_new_path_draft.dart \
  lib/src/features/path_studio/path_studio_panel.dart \
  test/path_pattern/path_studio_new_path_draft_test.dart \
  test/path_pattern/path_studio_panel_test.dart
```

Sortie : **No issues found! (exit 0).**

```bash
cd packages/map_core && dart analyze lib/src/models lib/src/operations test/project_manifest_path_pattern_save_reload_test.dart
```

Sortie : **No issues found! (exit 0).**

## 14. Git status final

```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
 M packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
 M packages/map_editor/test/path_pattern/path_studio_panel_test.dart
?? reports/pathPattern/pathpattern_40_draft_cancel_revert_safety_v0.md
?? reports/pathPattern/pathpattern_40_git_diff.patch
```

*(Fichiers sous `reports/` : livrables du lot ; pas de `git add` exécuté, conformément aux règles.)*

## 15. `git diff --stat`

```text
 .../path_studio/path_studio_new_path_draft.dart    |   3 +-
 .../features/path_studio/path_studio_panel.dart    | 302 ++++++++++++++++++++-
 .../path_studio_new_path_draft_test.dart           | 113 +++++++-
 .../test/path_pattern/path_studio_panel_test.dart  | 251 +++++++++++++++++
 4 files changed, 657 insertions(+), 12 deletions(-)
```

## 16. `git diff --name-status`

```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
M	packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
M	packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

## 17. Evidence Pack

### Git status initial (capture session)

Au début de la session agent : modifications préexistantes signalées sur `examples/playable_runtime_host/ios/Runner.xcodeproj/project.pbxproj`, `path_pattern_diagnostics.dart` non suivi, etc. **Le travail PathPattern-40 se limite aux quatre fichiers `map_editor` listés ci-dessus.**

### Diff complet

Fichier **verbatim** : `reports/pathPattern/pathpattern_40_git_diff.patch` (généré par `git diff packages/map_editor` à la racine du dépôt).

### Preuves comportementales (tests)

- **Création → dirty (tileset) → annuler → pas d’apply** : test `cancel new path draft after tileset change asks confirmation then discards` ; `applyNewCount == 0`.
- **Édition → rename → annuler → read-only + valeurs d’origine** : test `cancel edit draft after rename restores read-only and does not apply` ; `applyEditCount == 0`, texte « Mer 2x2 » présent, « Nom hack lot40 » absent.
- **Callbacks** : compteurs `onNewPathSaveRequested` / `onEditPathSaveRequested` à 0 sur annulation.
- **Assistant séquence** : suite `generatePathStudioCenterAnimationSequence` et tests panel « sequence assistant » inchangés fonctionnellement ; non-régression via tests existants + groupe dirty « sequence assistant marks dirty ».

### Analyse

Voir section 13 — **0 issues** sur les fichiers bornés.

## 18. Auto-review

- **Prouvé** : flux UI annulation ; confirmation dirty ; restauration sélection édition ; absence de callbacks apply ; `isDirty` cohérent sur modèle ; tests unitaires dirty edit ; suite `map_editor` `test/path_pattern/` verte.
- **Non prouvé par widget test** : bascule réelle de `isProjectDirty` global dans `EditorNotifier` lors d’un annulation (le panneau n’expose pas cet état). Argument : annulation ne déclenche aucun callback vers `PathStudioWorkspace`, donc pas d’`applyInMemoryProjectManifest` depuis ce flux.
- **Style** : `_ShellActionButton` étendu avec `backgroundColor` / `foregroundColor` optionnels pour le bouton d’annulation (surface + accent warning), sans nouveau provider/service.

## 19. Critique du prompt

Le périmètre « ne pas toucher au manifest » est respecté en gardant toute persistance derrière les callbacks existants. La demande de preuve « isProjectDirty inchangé si déjà true » aurait idéalement nécessité un test d’intégration shell minimal ; ici on documente la limite et on renforce par absence de callbacks.

## 20. Conclusion

Le lot PathPattern-40 est livré : sortie de brouillon sûre, avertissement si perte de travail local, pas d’effet de bord manifest/disque via ce panneau, tests et analyse bornée verts.

---

## Checklist finale

- [x] Audit initial réalisé.
- [x] AGENTS.md et agent_rules.md lus (conformité dépôt / preuves).
- [x] Aucun faux test.
- [x] Aucun provider inventé.
- [x] Aucun repository/service ajouté.
- [x] Aucun map_core modifié.
- [x] Aucun runtime modifié.
- [x] Aucun format JSON modifié.
- [x] Aucun build_runner.
- [x] Bouton Annuler la création ajouté.
- [x] Bouton Annuler les modifications ajouté.
- [x] Draft dirty détecté (`PathStudioNewPathDraft.isDirty`).
- [x] Annulation sans changement fonctionne.
- [x] Annulation avec changements → confirmation inline.
- [x] Annulation création nettoie le draft.
- [x] Annulation édition revient au read-only du PathPattern initial.
- [x] Annulation ne modifie pas ProjectManifest (via parent du widget).
- [x] Annulation n’appelle pas apply/save callbacks.
- [x] Annulation ne met pas `isProjectDirty` via ce panneau (aucun callback apply — preuve test + absence d’appel `applyInMemory` depuis `PathStudioWorkspace` pour ce flux).
- [ ] « Si `isProjectDirty` était déjà true, annuler ne le remet pas à false » : **non couvert par test widget** (notifier non branché sur `PathStudioPanel`) ; **argument** : annulation n’invoque aucun callback, donc pas de mutation manifest ni reset dirty côté shell pour cette action.
- [x] Sequence assistant Lot 39 non régressé (tests pass).
- [x] Save/apply normal non régressé (tests pass).
- [x] Diagnostics / read model non régressés (tests pass).
- [x] Tests ciblés passent.
- [x] Analyze bornée passe.
- [x] Rapport final complet créé.
- [x] Auto-review faite.

## Verdict des passes

| Passe | Verdict |
|-------|---------|
| Audit / Architecture | **OK** — périmètre `map_editor` Path Studio uniquement. |
| Implémentation | **OK** — UI + état local + réutilisation `isDirty`. |
| Tests | **OK** — nouveaux tests + suites demandées vertes. |
| Build / Validation | **OK** — `flutter analyze` borné sans issue ; pas de build_runner. |
| Critique finale | **OK** — limite documentée sur `isProjectDirty` global. |
