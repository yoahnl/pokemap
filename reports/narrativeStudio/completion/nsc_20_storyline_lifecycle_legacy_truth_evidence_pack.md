# Evidence Pack — NSC-20 — Cycle de vie Storyline et consolidation de la vérité legacy

Date : 2026-07-20  
Packages : `packages/map_core`, `packages/map_editor`  
Roadmap : `docs/superpowers/plans/2026-07-19-narrative-studio-completion-roadmap.md`  
Verdict proposé : **DONE**

## 1. Résumé exécutif

NSC-20 fait de `ProjectManifest.storylines` la vérité d'authoring visible dans le workspace Storylines. Le cycle de vie couvre maintenant création de tous les types déclarés, modification du titre/type/statut/notes, duplication profonde, archivage et suppression protégée par le `NarrativeDependencyIndex` de NSC-01.

Les anciennes `ScenarioAsset` de portée `globalStory` ne sont jamais promues à l'ouverture. Elles restent visibles dans la projection legacy et disposent d'une action d'import explicite, non destructive et idempotente. L'import conserve la Scenario source, refuse les collisions bloquantes, annule intégralement les échecs et marque la Storyline importée avec sa provenance. Une coexistence temporaire de plusieurs Storylines principales reste autorisée pendant une migration explicite ; l'UI de création normale continue d'empêcher l'ajout manuel d'une seconde principale.

Le lot fournit des tests core et widget positifs/négatifs, une caractérisation de la double représentation, une suite complète `map_core` à 3 145 tests, une suite complète `map_editor` à 3 538 tests, les analyses statiques vertes, des références visuelles mises à jour et un build macOS debug propre, signé ad hoc et vérifié.

## 2. Confirmation et challenge du scope

Le scope de la roadmap est respecté. Trois extensions strictement nécessaires ont été ajoutées :

- les goldens Storylines dépendants ont été mis à jour parce que les actions réelles occupent désormais l'inspecteur ;
- la création UI expose les sept `StorylineType`, pas seulement `main` et `sideQuest` ;
- le résultat de mutation porte `before`, `after`, diagnostic et consumers afin d'empêcher une publication partielle.

Une tentative de durcissement supplémentaire a été rejetée pendant la critique finale : interdire plusieurs Storylines `main` dans `map_core` cassait la caractérisation d'import explicite avec une Storyline canonique existante. La règle correcte est donc : création normale unique dans l'UI, coexistence migratoire permise dans le modèle canonique, aucune promotion silencieuse.

Hors scope conservé : édition complète Chapter/Step (NSC-21), sémantique des edges (NSC-22), graph interactif (NSC-23), suppression définitive des formats legacy (NSC-72) et adoption de la session documentaire NSC-13 par toutes les mutations Storylines.

## 3. Audit initial

### Contrats trouvés

- `StorylineAsset` possédait le modèle complet, l'égalité et le codec, mais pas de `copyWith` adapté aux champs nullable.
- `storyline_authoring_operations.dart` couvrait surtout les liens Scene/Step, sans enveloppe de cycle de vie Storyline.
- `buildLegacyGlobalStoryImportPreview` était read-only et diagnostiquait déjà collisions, références perdues et métadonnées invalides, mais ne proposait aucune application explicite.
- `StorylinesWorkspace` savait créer une principale/quête annexe et modifier Chapter/Step, mais n'exposait ni tous les types, ni rename/duplicate/archive/delete, ni action d'import legacy.
- `NarrativeDependencyIndex` de NSC-01 savait identifier les consumers de Storyline et devait rester l'unique source de protection de suppression.
- Les goldens du produit et les captures de gate Storylines couvrent Graph, Structure et route complète.

### Risques identifiés

- importer ou supprimer une donnée legacy à l'ouverture ;
- perdre la Scenario source lors d'une migration ;
- créer deux fois le même import après retry ;
- laisser un échec produire un manifeste partiellement modifié ;
- dupliquer des IDs de Chapter/Step/Link/Outcome internes ;
- supprimer une Storyline encore consommée ;
- afficher un statut fixe ou masquer des types existants ;
- régénérer des goldens sans inspection visuelle ;
- inclure les changements Selbrume préexistants dans le commit.

### Verdict Audit / Architecture

**PASS** : les modèles et l'index existants suffisaient. Aucune règle n'a été déplacée vers Flutter ou le runtime ; les opérations restent pures dans `map_core`, et l'UI publie uniquement un résultat `applied`.

## 4. État Git initial

HEAD initial : `487774de feat(narrative): add crash-safe document sessions`.

Changements préexistants explicitement hors lot :

~~~text
 M examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart
A  examples/playable_runtime_host/test/selbrume_lighthouse_retry_integration_test.dart
 M examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart
 M packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart
 M packages/map_editor/tool/seed_selbrume_canonical_narrative_content.dart
 M packages/map_runtime/test/selbrume_event_v2_trigger_battle_anchor_integration_test.dart
 M packages/map_runtime/test/selbrume_static_boss_playable_map_game_integration_test.dart
 M selbrume/project.json
?? reports/gameplay/fg_000_narrative_studio_selbrume_readiness_reaudit_2026-07-19.md
~~~

Le test lighthouse était déjà indexé et doit rester indexé hors du commit NSC-20.

## 5. Architecture livrée et invariants

### Mutation Storyline

1. l'appelant fournit un manifeste immutable et une intention ;
2. l'opération valide identité, cible et préconditions propres au cycle de vie ;
3. un succès retourne une nouvelle projection complète ;
4. un no-op ou rejet retourne exactement le manifeste initial ;
5. la suppression interroge l'index canonique et restitue tous les chemins consumers ;
6. la duplication remappe les IDs possédés et les références locales, passe en `draft`, retire la revendication legacy et ajoute `duplicatedFrom`.

### Import legacy

1. la prévisualisation reste pure et visible ;
2. seul le bouton `storylines-import-legacy-action` applique un candidat sélectionné ;
3. collision ou diagnostic bloquant produit un rollback exact ;
4. l'import conserve `manifest.scenarios` ;
5. une provenance déjà marquée `imported:true` produit un no-op ;
6. les sources déjà importées disparaissent de la prochaine action sans être supprimées.

## 6. Inventaire complet des fichiers du lot

### Fichier créé

| Fichier | Zone | Raison / impact |
|---|---|---|
| `reports/narrativeStudio/completion/nsc_20_storyline_lifecycle_legacy_truth_evidence_pack.md` | document courant | Audit, inventaire, preuves, verdicts et limites NSC-20. |

Le présent document constitue son contenu complet et n'est pas répété dans une annexe auto-référentielle. Aucun autre fichier source ou test n'a été créé.

### Fichiers modifiés — zones précises

| Fichier | Classes/fonctions/zones | Raison / impact |
|---|---|---|
| `packages/map_core/lib/src/models/storyline_asset.dart` | sentinel `_storylineCopyUnset`, `StorylineAsset.copyWith` | Édition immutable de tous les champs et effacement explicite des nullable. |
| `packages/map_core/lib/src/authoring/storyline_authoring_operations.dart` | `StorylineMutationDisposition`, `StorylineMutationResult`, `createStoryline`, `updateStoryline`, `duplicateStoryline`, `archiveStoryline`, `deleteStoryline`, remappage profond | Contrat pur et atomique du cycle de vie ; suppression sûre via NSC-01. |
| `packages/map_core/lib/src/authoring/storyline_legacy_import_preview.dart` | `StorylineLegacyImportDisposition`, résultat before/after, `applyLegacyGlobalStoryImport` | Application explicite, idempotente et non destructive d'un candidat preview. |
| `packages/map_core/test/storyline_asset_test.dart` | groupe `copyWith` | Préservation structurelle et effacement des champs nullable. |
| `packages/map_core/test/storyline_authoring_operations_test.dart` | groupe lifecycle | Tous les types, update atomique, clone indépendant, archive no-op, delete protégé et delete autorisé. |
| `packages/map_core/test/storyline_legacy_import_preview_test.dart` | groupe apply import | Import positif, retry idempotent, collision rollback, source absente no-op. |
| `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart` | header import ; create/edit dialogs ; handlers lifecycle ; inspector ; autres récits ; labels type/statut | Parcours no-code complet du lot, UI Design System, provenance legacy visible et aucune couleur ad hoc. |
| `packages/map_editor/test/storylines_current_global_story_characterization_test.dart` | caractérisation canonique/legacy | Prouve que preview ne mute rien et que l'import explicite conserve canonical et legacy source. |
| `packages/map_editor/test/storylines_workspace_shell_test.dart` | nouveaux parcours lifecycle/import/types/delete | Prouve l'action explicite, les sept types, edit/duplicate/archive/delete et l'affichage des consumers. |
| `packages/map_editor/test/goldens/narrative_studio/storylines/storylines_full_product_route_1672x941.png` | golden route Storylines | Référence avec import et actions lifecycle réelles. |
| `reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_bis_graph_full_layout.png` | capture graph seed | Inspecteur lifecycle actualisé. |
| `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_full_width_accordion.png` | capture Structure | Inspecteur lifecycle actualisé. |
| `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_graph_regression.png` | capture Graph regression | Non-régression visuelle après ajout des actions. |
| `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_empty_polished.png` | capture vide | Action legacy et état vide actualisés. |
| `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_main_polished.png` | capture principale | Actions lifecycle dans l'inspecteur. |
| `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_sidequest_attached_polished.png` | capture quête reliée | Actions lifecycle dans l'inspecteur. |
| `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_sidequest_standalone_polished.png` | capture quête indépendante | Actions lifecycle dans l'inspecteur. |

Diff stat hors Evidence Pack : **17 fichiers, 1 705 insertions, 91 suppressions**. Les fichiers binaires correspondent uniquement aux références visuelles attendues.

## 7. Tests créés ou modifiés

Couverture positive : création des sept types, rename/type/status/notes, duplication profonde, archivage, suppression non référencée, import d'un candidat, coexistence migratoire explicite et sélection UI.

Couverture négative : ID existant, cible absente/ambiguë, changement d'ID, duplicate ID vide/existant, consumer externe, collision legacy, candidat absent, diagnostic bloquant et confirmation de suppression.

Garde-fous : manifeste initial inchangé sur échec/no-op, source Scenario conservée, retry sans double import, `localEventFlow` jamais promu, liens et IDs internes remappés, raw colors absentes, goldens comparés en mode normal.

## 8. Commandes et résultats exacts

### TDD initial

Les nouveaux tests ont d'abord échoué sur les APIs et keys absentes (`copyWith`, opérations lifecycle, import explicite et actions UI), puis sont devenus verts après implémentation. Une hypothèse tardive d'unicité `main` au niveau domaine a également été testée ; la caractérisation existante a prouvé qu'elle cassait la coexistence migratoire voulue, donc cette tentative a été retirée avant le diff final.

### `map_core`

~~~text
cd packages/map_core
dart format lib/src/authoring/storyline_authoring_operations.dart lib/src/authoring/storyline_legacy_import_preview.dart lib/src/models/storyline_asset.dart
Formatted 3 files (0 changed)

dart test test/storyline_asset_test.dart test/storyline_authoring_operations_test.dart test/storyline_legacy_import_preview_test.dart
00:00 +54: All tests passed!

dart analyze
Analyzing map_core...
No issues found!

dart test
00:08 +3145: All tests passed!
~~~

### `map_editor` ciblé et visuel

~~~text
cd packages/map_editor
flutter test test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/storylines_seed_graph_usability_test.dart test/storylines_structure_layout_test.dart test/ui/canvas/narrative_studio_workspace_visual_test.dart
00:06 +114: All tests passed!

flutter analyze
Analyzing map_editor...
No issues found! (ran in 4.7s)
~~~

Les trois premières défaillances de la suite complète étaient exactement des écarts de golden introduits par le nouvel inspecteur :

~~~text
storylines_seed_graph_usability_test.dart: writes seed fix bis visual gate screenshots
storylines_structure_layout_test.dart: writes Structure accordion bis visual gate screenshots
narrative_studio_workspace_visual_test.dart: matches the full storylines product route at 1672x941
~~~

Après mise à jour ciblée, inspection visuelle et relance sans `--update-goldens`, les 114 tests ciblés ci-dessus passent.

### Suite complète `map_editor`

~~~text
cd packages/map_editor && flutter test
03:21 +3538: All tests passed!
~~~

Cette suite complète a été lancée avant l'ajout final de commentaires documentaires uniquement. Les tests ciblés et analyses ont été relancés après ces commentaires.

### Hygiène Design System et diff

~~~text
git diff -U0 -- packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart | rg '^\+.*(Color\(0x|Colors\.)'
=> aucune sortie

git diff --check
=> exit 0, aucune sortie
~~~

### Build macOS propre final

~~~text
cd packages/map_editor
flutter clean
flutter pub get
Got dependencies!
37 packages have newer versions incompatible with dependency constraints.

flutter build macos --debug
✓ Built build/macos/Build/Products/Debug/map_editor.app

codesign --verify --deep --strict --verbose=2 build/macos/Build/Products/Debug/map_editor.app
build/macos/Build/Products/Debug/map_editor.app: valid on disk
build/macos/Build/Products/Debug/map_editor.app: satisfies its Designated Requirement

file build/macos/Build/Products/Debug/map_editor.app/Contents/MacOS/map_editor
Mach-O 64-bit executable arm64
~~~

Warnings préexistants : enfant AppIcon 1024 non assigné et phase `Flutter Assemble` sans outputs. Un build incrémental a aussi reproduit un sceau externe périmé pour `objective_c.framework`; le rebuild propre final ci-dessus est la preuve retenue et restaure une signature profonde valide.

## 9. Verdict des cinq passes obligatoires

| Passe locale séparée | Verdict | Preuve / décision |
|---|---|---|
| Audit / Architecture | **PASS** | Réutilisation de `StorylineAsset`, preview legacy et `NarrativeDependencyIndex`; logique pure dans core. |
| Implémentation | **PASS** | Enveloppes before/after, clone profond, import non destructif et UI uniquement sur résultat appliqué. |
| Tests | **PASS** | 54 ciblés core, 114 ciblés editor, 3 145 core complets et 3 538 editor complets. |
| Build / Validation | **PASS avec warnings connus** | Analyses vertes, diff propre, build macOS produit, signature profonde valide, arm64. |
| Critique finale | **PASS après challenge** | Goldens inspectés ; aucun raw color ; hypothèse d'unicité domaine retirée car contraire à la migration caractérisée. |

Les instructions d'environnement interdisaient les sub-agents sans demande explicite. Conformément à `codex_rule.md`, les cinq contrôles ont donc été exécutés comme passes locales séparées et nommées.

## 10. État Git final avant commit et isolement

Le working tree contient les 18 chemins NSC-20 de la section 6, plus exactement les neuf chemins préexistants de la section 4. Le commit doit utiliser `git commit --only` avec les chemins NSC-20 afin de préserver le test lighthouse déjà indexé.

Après commit isolé attendu : aucun fichier NSC-20 ne reste modifié ; les neuf chemins préexistants restent identiques et le test lighthouse demeure staged.

## 11. Limites et risques restants

- Les mutations Storylines utilisent encore `applyInMemoryProjectManifest` puis la sauvegarde générale ; l'adoption directe de la session documentaire NSC-13 reste à planifier pour le workspace.
- Une duplication de Storyline `main` est permise par l'opération pure pour ne pas inventer un invariant absent du modèle et nécessaire à certaines migrations ; la création UI normale reste limitée à une principale.
- La suppression protège les consumers indexés par NSC-01 ; tout futur type de référence devra étendre l'index dans son propre lot.
- Les conditions, outcomes, statuts de Step et déplacements entre Chapters ne sont pas ajoutés ici : NSC-21 les possède.
- Le legacy est conservé volontairement. Son retrait physique et le cutover définitif appartiennent à NSC-72.
- Le graph demeure une projection read-only enrichie jusqu'à NSC-22/23.

## 12. Auto-critique finale

La surface UI modifiée reste volumineuse et monolithique. Extraire prématurément les dialogs aurait élargi le lot ; NSC-21 devra éviter d'empiler de nouveaux contrôles dans ce fichier sans examiner `storylines_structure_view.dart`.

Le premier build incrémental après tests a montré une signature imbriquée périmée, déjà observée au lot précédent. Un `flutter clean` complet produit systématiquement un artefact valide ; cela ressemble au cache Xcode/Flutter local, mais reste un coût de validation à surveiller.

La tentative de rendre l'unicité `main` globale était séduisante mais fausse pour la migration caractérisée. Son retrait constitue un garde-fou important : le code final ne prétend pas imposer un invariant que le schéma et le parcours legacy ne déclarent pas.

Aucun fichier gameplay, runtime ou Selbrume préexistant n'a été modifié par ce lot. Aucun pourcentage de couverture non mesuré n'est revendiqué.

## 13. Prochaine étape proposée, non implémentée

Le prochain lot est **NSC-21 — Authoring complet Chapter et Step** : rename/duplicate/delete/reorder Chapter, rename/duplicate/delete/reorder/move Step, conditions, Scenes/outcomes, statuts, notes, pickers et références cassées, dans un commit séparé.
