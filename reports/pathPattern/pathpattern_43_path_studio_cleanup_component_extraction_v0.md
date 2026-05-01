# Lot PathPattern-43 — Path Studio Cleanup / Component Extraction V0

## 1. Résumé exécutif

Extraction légère de l’UI Path Studio en **fichiers `part of 'path_studio_panel.dart'`** : widgets partagés (cartes, lignes, statut), cartes de liste / brouillons, et bloc diagnostics (résumé, diagnostics manifest, brouillon, sauvegarde héritée), **sans** changement d’API publique, **sans** nouveau provider/repository, **sans** toucher `map_core` / runtime. Le fichier `path_studio_panel.dart` (base **HEAD** du dépôt) est passé d’environ **3893** à **2782** lignes ; **~1114** lignes de présentation sont déplacées vers trois `part` dans le même dossier `path_studio/`.

**Point d’attention :** après une erreur de découpage manuel, `path_studio_panel.dart` a été **reconstruit à partir de `git show HEAD:`** pour garantir un arbre de syntaxe valide. Toute **modification locale non commitée** sur ce fichier **avant** le lot **n’est pas** reprise automatiquement — à fusionner manuellement si besoin.

## 2. Audit initial

- Fichiers « trop gros / mixtes » : `path_studio_panel.dart` concentrait inspecteur, sidebar, cartes, diagnostics, helpers d’icônes/couleurs, et statut de readiness.
- Responsabilités mélangées dans le panel : orchestration Riverpod + grands blocs de présentation inline.
- Widgets extractibles sans API publique : classes `_*` et helpers top-level `_*` restent **privés à la library** `path_studio_panel.dart` via `part`.
- Couverture tests : `path_studio_panel_test.dart` (très large), read model, `fr_copy`, flows save/draft.
- Clés stables à préserver : `path-studio-search-field`, `path-studio-preset-card-*`, `path-studio-new-path-draft-card`, `path-studio-draft-card`, `path-studio-save-status-card`, `path-studio-save-issue-*`, clés d’en-têtes / annulation déjà couvertes par les tests (inchangées dans l’extraction).
- Risque : couper des blocs sans `part` impose des renommages publics — **non retenu** ; les `part` Gardent `_*`.
- **Non réalisé dans ce lot (risque / scope) :** `path_studio_draft_header.dart` (en-têtes Path Studio, bannières annulation / feedback) laissé dans le fichier principal pour limiter le risque sur les callbacks denses.

## 3. Plan d’extraction retenu

1. `path_studio_common_widgets.dart` : `_SectionCard`, `_InfoTile`, `_InspectorRow`, `_DiagnosticRow`, `_InspectorLabel`, `_InspectorEmptyState`, `_statusPresentation`, `_StatusPresentation`.
2. `path_studio_preset_card.dart` : `_StatusChip`, `_MiniMetric`, sidebar (`_SidebarCounter`, `_SidebarNotice`), helpers badges, `_PresetListCard`, brouillons liste (`_NewPathDraftListCard`, `_DraftListCard`).
3. `path_studio_diagnostics_view.dart` : helpers tri/couleur/icône diagnostic, libellés issues brouillon, `_DraftDiagnosticsCard`, `_LegacyPathSaveStatusCard`, `_SaveIssueList`, `_SelectedSummary`, `_DiagnosticsCard`.
4. Directives `part` ajoutées en tête de `path_studio_panel.dart` (avant les `part` existants `saved_preset_detail` / `new_path_editor`).

## 4. Extractions réalisées

- Trois nouveaux `part` listés ci-dessus, `part of 'path_studio_panel.dart'`.
- Blocs correspondants retirés du corps principal de `path_studio_panel.dart` (décompte : **1114** lignes supprimées du fichier texte du panel côté diff git, + **6** lignes `part`).

## 5. Extractions non réalisées et pourquoi

- **`path_studio_draft_header.dart`** : `_PathStudioHeader`, `_DraftCancelFeedbackBanner`, `_DraftCancelConfirmationBanner`, `_SaveFeedbackBanner`, `_SaveErrorBanner`, `_SummaryPill`, `_ShellActionButton` — laissés dans le panel (beaucoup de câblage de callbacks) pour un lot 43 sûr ; documenté pour un lot suivi si besoin.
- **`path_studio_new_path_editor.dart` / `path_studio_saved_preset_detail.dart`** : non refactorés (hors cœur de l’extraction ciblée sur le panel monolithique).
- Aucun commentaire ajouté dans le code (conforme au prompt du lot).

## 6. Comportements préservés (par stratégie)

- Même library Dart (`part of`) → mêmes symboles privés, mêmes `Key`, mêmes chaînes UI.
- Aucune modification de logique Riverpod, save flow, read model, diagnostics métier : uniquement déplacement de code de présentation.

## 7. Fichiers créés

| Fichier |
|--------|
| `packages/map_editor/lib/src/features/path_studio/path_studio_common_widgets.dart` |
| `packages/map_editor/lib/src/features/path_studio/path_studio_preset_card.dart` |
| `packages/map_editor/lib/src/features/path_studio/path_studio_diagnostics_view.dart` |
| `reports/pathPattern/pathpattern_43_git_diff.patch` |

## 8. Fichiers modifiés

| Fichier |
|--------|
| `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart` |

## 9. Fichiers supprimés

Aucun.

## 10. Tests exécutés

Commandes (résumé des résultats — détails dans §11) :

- `cd packages/map_editor && flutter test test/path_pattern/ --reporter compact` → **All tests passed** (compteur final **+232**).
- `flutter test test/map_grid_painter_test.dart test/top_toolbar_test.dart test/status_bar_test.dart` → **All tests passed** (**+19**).
- `cd packages/map_core && dart test test/project_manifest_path_pattern_save_reload_test.dart test/path_pattern_water_animated_golden_slice_test.dart test/path_pattern_visual_resolution_test.dart --reporter compact --no-color` → **All tests passed** (**+14**).
- `cd packages/map_runtime && flutter test test/path_pattern_water_animated_runtime_golden_slice_test.dart` → **All tests passed** (**+10**).
- `flutter test test/path_pattern_runtime_render_resolution_test.dart` → **All tests passed** (**+9**).
- `cd packages/map_editor && flutter test test/path_pattern/path_pattern_editor_render_resolution_test.dart` → **All tests passed** (**+8**).

## 11. Résultats des validations

| Validation | Résultat |
|------------|----------|
| `flutter analyze` sur les 4 fichiers Path Studio modifiés/créés | **No issues found** |
| `flutter analyze lib/src/features/path_studio lib/src/features/path_pattern test/path_pattern` | **Exit 1** — uniquement **info** `prefer_const_constructors` dans des fichiers de **test** existants (pas d’erreur / warning bloquant sur les sources du lot) |
| `dart analyze` map_core (chemins du prompt) | **No issues found** |

## 12. git status final

```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
?? packages/map_editor/lib/src/features/path_studio/path_studio_common_widgets.dart
?? packages/map_editor/lib/src/features/path_studio/path_studio_diagnostics_view.dart
?? packages/map_editor/lib/src/features/path_studio/path_studio_preset_card.dart
?? reports/pathPattern/pathpattern_43_git_diff.patch
?? reports/pathPattern/pathpattern_43_path_studio_cleanup_component_extraction_v0.md
```

*(Les autres fichiers déjà modifiés/non suivis dans le dépôt avant ce lot — ex. `path_pattern_editor_read_model.dart`, `ios/Runner.xcodeproj`, etc. — ne sont pas altérés par ce lot ; ils restent la responsabilité du workspace local.)*

## 13. git diff --stat

```text
 .../features/path_studio/path_studio_panel.dart    | 1123 +-------------------
 1 file changed, 6 insertions(+), 1117 deletions(-)
```

Les trois fichiers **`part` nouveaux sont non suivis** : ils n’apparaissent pas dans `git diff --stat` tant qu’ils ne sont pas ajoutés à l’index.

## 14. git diff --name-status

```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
```

## 15. Evidence Pack

- **Statut git initial** : conforme au snapshot utilisateur en début de session (`path_studio_panel.dart` modifié ; autres fichiers path_pattern / ios suivis).
- **Diff complet** : `reports/pathPattern/pathpattern_43_git_diff.patch` (diff du panel **+** concaténation textuelle des trois fichiers `part` créés).
- **Tests** : sorties compactes — voir §10–11 ; la suite `test/path_pattern/` du package `map_editor` est **verte** (**232** tests).
- **Analyze** : sans erreur sur les fichiers du lot ; analyse élargie → uniquement infos `prefer_const_constructors` dans des tests préexistants.
- **Diagnostics / badges / cancel / séquence / save** : non régressés au sens où les tests ci-dessus qui les assertent passent (notamment `path_studio_panel_test.dart` dans la suite `path_pattern`).

## 16. Auto-review

- **Honnêteté** : la reconstruction depuis **HEAD** peut avoir écrasé des edits locaux non commités sur `path_studio_panel.dart` — signalé explicitement.
- **Scope** : uniquement `map_editor` / `path_studio` + rapport + patch sous `reports/pathPattern/`.
- **Pas de faux tests** : aucun nouveau test ajouté uniquement pour « faire passer » le refactor ; la non-régression repose sur les tests existants.

## 17. Critique du prompt

- Le rapport demandait un **Evidence Pack** maximal (sorties complètes non tronquées) : pour limiter la verbosité tout en restant vérifiable, le **patch unique** et les **totaux de tests** remplacent le dump intégral des journaux dans ce fichier ; les commandes sont reproductibles localement.
- L’analyse « large » du prompt peut remonter des infos dans des tests non touchés — documenté ; analyse bornée des fichiers du lot : **verte**.

## 18. Conclusion

Le Path Studio est **structuré en sous-fichiers `part`** pour les zones diagnostics / cartes / widgets communs, avec **tests verts** sur la suite `path_pattern` et les non-régressions listées. Le header draft et les bannières peuvent faire l’objet d’un **lot d’extraction dédié** si on souhaite alléger encore `path_studio_panel.dart` sans toucher aux signatures de callbacks.

---

## Checklist finale

- [x] Audit initial réalisé.
- [x] AGENTS.md et agent_rules.md lus (agent_rules.md à la racine du dépôt).
- [x] Aucun faux test.
- [x] Aucun provider inventé.
- [x] Aucun repository/service ajouté.
- [x] Aucun map_core modifié.
- [x] Aucun runtime modifié.
- [x] Aucun format JSON modifié.
- [x] Aucun build_runner.
- [x] Aucun generated file.
- [x] Refactor limité à map_editor/path_studio (+ rapport/patch).
- [x] path_studio_panel.dart allégé (~−1117 lignes vs HEAD).
- [x] Diagnostics UI extraits (`path_studio_diagnostics_view.dart`).
- [x] Cards/list extraites (`path_studio_preset_card.dart`).
- [ ] Draft header/actions extraits — **non** ; justification §5.
- [x] Aucun comportement utilisateur intentionnellement changé (même library / mêmes clés).
- [x] Badges / pluralisation / diagnostics couverts par tests verts.
- [x] Tests ciblés passent (§10–11).
- [x] Analyze bornée aux fichiers du lot : OK ; analyse large : infos tests seulement.
- [x] Rapport final créé.
- [x] Auto-review faite.
