# Evidence Pack — NSC-21 — Authoring complet Chapter et Step

Date : 2026-07-20  
Packages : `packages/map_core`, `packages/map_editor`  
Roadmap : `docs/superpowers/plans/2026-07-19-narrative-studio-completion-roadmap.md`  
Verdict proposé : **DONE**

## 1. Résumé exécutif

NSC-21 permet désormais de construire et maintenir une Storyline multi-chapitres sans modifier `ProjectManifest` à la main. Les Chapters sont modifiables, duplicables, supprimables sous protection et réordonnables. Les Steps sont modifiables, duplicables, supprimables sous protection, réordonnables et déplaçables entre Chapters.

L'éditeur de Step expose les champs canoniques déjà présents dans `map_core` : titre, description, Chapter propriétaire, condition d'entrée, condition de complétion, Scenes liées, outcomes attendus, statut de cycle de vie et notes auteur. Facts, Scenes et outcomes proviennent exclusivement du projet courant ; une référence absente reste visible et retirable au lieu d'être masquée. Les suppressions utilisent `NarrativeDependencyIndex` et affichent les chemins consumers.

Les opérations sont pures et atomiques dans `map_core`. Les duplications profondes remappent Chapters, Steps, `StorylineSceneLink`, outcome links et effets `activateStep`/`completeStep`. Les déplacements mettent également à jour la propriété des liens structurés. Les données Storyline existantes conservent leur compatibilité JSON.

Validation finale : **50 tests core ciblés**, **17 tests UI ciblés**, **3 154 tests core complets**, **3 543 tests editor complets**, analyses statiques vertes, cinq goldens inspectés, build macOS debug propre, signature profonde valide et binaire arm64.

## 2. Confirmation et challenge du scope

Le scope NSC-21 est respecté avec trois décisions explicites :

- la suppression d'un Chapter contenant encore des Steps est refusée ; l'auteur doit d'abord déplacer ou supprimer les Steps ;
- la suppression d'un Step référencé est refusée et restitue les consumers plutôt que de cascader silencieusement ;
- `StorylineStatus` reste un statut de cycle de vie (`draft`, `active`, `archived`, `disabled`). Une Step « déjà complétée » est un état de partie dans `PlayerProgression.completedStepIds`, pas une valeur d'authoring à ajouter au manifeste. Le lot n'invente donc pas de statut `completed` parallèle.

Hors scope conservé : contrat formel des edges et mutation inverse (NSC-22), interactions directes dans le graph (NSC-23), journal durable Overview (NSC-24) et adoption complète des sessions documentaires NSC-13 par Storylines.

## 3. Audit initial

### Contrats trouvés

- `StorylineChapter` et `StorylineStep` possédaient déjà tous les champs utiles, l'égalité et le codec JSON, mais pas de `copyWith` permettant d'effacer proprement les nullable.
- `storyline_authoring_operations.dart` couvrait le cycle de vie Storyline et des liens Scene simples, mais pas les mutations Chapter/Step.
- `StorylinesWorkspace` créait et modifiait localement Chapters/Steps ; suppression et réordonnancement contournaient les protections du domaine.
- `StorylinesStructureView` rendait l'accordéon et le drag de Steps mais n'exposait ni duplication/réordre de Chapters, ni déplacement de Step.
- l'éditeur de Step ne couvrait que titre, description et Scenes.
- `NarrativeDependencyIndex` indexait déjà les cibles Chapter/Step dans les relations, liens structurés, conditions Facts et effets d'outcomes.

### Risques identifiés

- supprimer un Chapter/Step encore consommé ;
- dupliquer des IDs possédés ou laisser un effet d'outcome viser l'ancienne Step ;
- déplacer une Step sans déplacer la propriété de ses `StorylineSceneLink` ;
- perdre une condition avancée non éditable par le picker simple ;
- cacher un Fact, une Scene ou un outcome absent ;
- confondre statut d'authoring et progression d'une sauvegarde ;
- inclure les changements Selbrume préexistants dans le commit.

### Verdict Audit / Architecture

**PASS** : le schéma existant était suffisant. Aucun tableau d'edges, aucune coordonnée de graph et aucun état runtime n'ont été ajoutés. Les règles restent dans `map_core`; Flutter ne fait que construire une intention et publier un résultat appliqué.

## 4. État Git initial

HEAD initial NSC-21 : `47af6341 feat(narrative): complete storyline lifecycle and legacy import`.

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

Le test lighthouse était déjà indexé avant le lot et doit rester indexé hors du commit NSC-21.

## 5. Architecture livrée et invariants

### Mutations Chapter

1. identité Storyline/Chapter validée avant mutation ;
2. l'ID stable ne peut pas changer lors d'un update ;
3. duplicate remappe toutes les Steps possédées, les liens structurés et les effets locaux ;
4. delete refuse un Chapter non vide ou référencé ;
5. reorder exige exactement tous les IDs une fois et normalise les ordres `0..n-1` ;
6. rejet/no-op restitue exactement le manifeste initial.

### Mutations Step

1. tous les champs authorables sont remplacés atomiquement ;
2. duplicate conserve conditions, Scenes, outcomes, statut et notes mais crée des IDs indépendants ;
3. delete interroge l'index canonique ;
4. reorder exige une projection exhaustive sans doublon ;
5. move normalise source et destination et réattribue les `StorylineSceneLink` structurés ;
6. aucun move ou duplicate ne marque implicitement une Step comme complétée dans une partie.

### UI no-code

- Fact vrai/faux via boutons guidés ;
- Scene depuis le catalogue projet existant ;
- outcome depuis `SceneAsset.declaredOutcomes` ;
- Chapter cible depuis la Storyline courante ;
- condition avancée existante conservée tant que l'auteur ne la remplace pas ;
- références absentes affichées en warning avec leur ID exact ;
- aucun raw JSON, aucune saisie d'ID et aucune couleur produit ad hoc.

## 6. Inventaire complet des fichiers du lot

### Fichier créé

| Fichier | Zone | Raison / impact |
|---|---|---|
| `reports/narrativeStudio/completion/nsc_21_chapter_step_authoring_evidence_pack.md` | document courant | Audit, inventaire, preuves, verdicts, limites et état Git NSC-21. |

Le présent document constitue son contenu complet et n'est pas répété dans une annexe auto-référentielle. Aucun autre fichier source ou test n'a été créé.

### Fichiers modifiés — zones précises

| Fichier | Classes/fonctions/zones | Raison / impact |
|---|---|---|
| `packages/map_core/lib/src/models/storyline_asset.dart` | `StorylineChapter.copyWith`, `StorylineStep.copyWith` | Copie immutable, IDs stables par défaut et effacement explicite des nullable. |
| `packages/map_core/lib/src/authoring/storyline_authoring_operations.dart` | `StorylineMutationResult`; opérations Chapter lignes 229-434 ; opérations Step lignes 437-750 ; helpers clone/projection | Contrat pur update/duplicate/delete/reorder/move, rollback et remappage profond. |
| `packages/map_core/test/storyline_asset_test.dart` | tests `copyWith` Chapter/Step | Préservation d'identité et effacement nullable. |
| `packages/map_core/test/storyline_authoring_operations_test.dart` | groupe `Storyline Chapter and Step authoring operations` | Mutations positives, protections, remappage effects et round-trip JSON. |
| `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart` | handlers lignes 674-1040 ; `_StorylineStepEditorDialog` lignes 2822-3427 ; Chapter dialog lifecycle | Raccordement aux opérations core et formulaire guidé complet. |
| `packages/map_editor/lib/src/ui/canvas/storylines/storylines_structure_view.dart` | callbacks Chapter ; header lignes 412-535 ; notice lignes 771-807 | Duplicate/move Chapter avec composants Design System et aide actualisée. |
| `packages/map_editor/test/storylines_structure_layout_test.dart` | parcours Chapter/Step | Edit lifecycle, suppressions protégées, duplicate/reorder/move et non-mutation du fixture disque. |
| `packages/map_editor/test/storylines_workspace_scene_links_test.dart` | parcours formulaire Step | Facts, conditions, Scenes, outcomes, move, refs cassées et quête secondaire. |
| `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_29_storyline_step_scene_link_v0.png` | golden formulaire Step | Nouvelle composition scrollable avec métadonnées et pickers. |
| `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_full_width_accordion.png` | golden Structure complet | Actions Chapter réelles. |
| `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_expanded_chapter_steps.png` | golden Chapter ouvert | Contrôles Chapter et Steps. |
| `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_collapsed_chapter.png` | golden Chapter fermé | Contrôles Chapter cohérents. |
| `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_authoring_actions.png` | golden actions | Création et édition avec le layout final. |

Diff stat hors Evidence Pack : **13 fichiers, 2 467 insertions, 278 suppressions**. Les cinq fichiers binaires sont exclusivement les références visuelles attendues.

## 7. Tests créés ou modifiés

Couverture positive : metadata Chapter, duplicate/reorder Chapter, update complet Step, duplicate/reorder/move Step, clone de SceneLink/outcome/effects, Facts vrai/faux, Scenes, outcomes, status, notes, side quest optionnelle et JSON round-trip.

Couverture négative : Chapter non vide, Chapter/Step référencé, liste d'ordre invalide, ID absent/dupliqué, Scene inconnue, Fact absent, outcome absent, condition avancée et confirmation de suppression.

Garde-fous : IDs stables, ordre contigu, original immutable, effet `completeStep` remappé, fixture Selbrume disque inchangée, références cassées visibles, aucun raw ID demandé et aucun statut runtime inventé.

## 8. Commandes et résultats exacts

### TDD initial

Les tests core ont d'abord échoué à compiler sur les `copyWith` et opérations Chapter/Step absents. Après implémentation, les premiers tests UI ont exposé trois écarts utiles : contrôles Scene hors viewport dans le nouveau formulaire, anciennes attentes de suppression incompatibles avec les protections du domaine et goldens obsolètes. Les tests ont été corrigés pour scroller explicitement, vérifier les consumers et comparer les nouvelles références visuelles.

### `map_core`

~~~text
cd packages/map_core
dart test test/storyline_asset_test.dart test/storyline_authoring_operations_test.dart
00:00 +50: All tests passed!

dart analyze
Analyzing map_core...
No issues found!

dart test
00:08 +3154: All tests passed!
~~~

### `map_editor` ciblé et visuel

~~~text
cd packages/map_editor
flutter test --update-goldens test/storylines_workspace_scene_links_test.dart test/storylines_structure_layout_test.dart
00:05 +16: All tests passed!

flutter test test/storylines_workspace_scene_links_test.dart test/storylines_structure_layout_test.dart
00:05 +17: All tests passed!

flutter analyze --no-pub lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/storylines/storylines_structure_view.dart test/storylines_workspace_scene_links_test.dart test/storylines_structure_layout_test.dart
No issues found! (ran in 5.1s)
~~~

Les cinq fichiers PNG de la section 6 ont été ouverts et inspectés après régénération. La structure reste lisible, sans débordement ni collision des nouvelles actions Chapter. La suite ciblée normale, sans `--update-goldens`, confirme ensuite la stabilité des références.

### Suite complète `map_editor`

~~~text
cd packages/map_editor
flutter test
03:18 +3543: All tests passed!

flutter analyze
Analyzing map_editor...
No issues found! (ran in 11.3s)
~~~

### Hygiène Design System et diff

~~~text
git diff --check
=> exit 0, aucune sortie

git diff -U0 -- [deux fichiers UI] | rg '^\+.*(Color\(0x|Colors\.)'
=> aucune sortie
~~~

### Build macOS propre final

Un build incrémental a reproduit le sceau périmé déjà documenté sur `App.framework` et `objective_c.framework`. La preuve finale est donc le rebuild propre :

~~~text
cd packages/map_editor
flutter clean && flutter pub get && flutter build macos --debug
Got dependencies!
37 packages have newer versions incompatible with dependency constraints.
✓ Built build/macos/Build/Products/Debug/map_editor.app

codesign --verify --deep --strict --verbose=2 build/macos/Build/Products/Debug/map_editor.app
build/macos/Build/Products/Debug/map_editor.app: valid on disk
build/macos/Build/Products/Debug/map_editor.app: satisfies its Designated Requirement

file build/macos/Build/Products/Debug/map_editor.app/Contents/MacOS/map_editor
Mach-O 64-bit executable arm64
~~~

Warnings Xcode préexistants : enfant AppIcon 1024 non assigné et phase `Flutter Assemble` sans outputs.

## 9. Verdict des cinq passes obligatoires

| Passe locale séparée | Verdict | Preuve / décision |
|---|---|---|
| Audit / Architecture | **PASS** | Réutilisation du schéma et de l'index ; aucune logique parallèle ou coordonnée ajoutée. |
| Implémentation | **PASS** | Neuf opérations pures, remappage profond, UI guidée et publication uniquement sur succès. |
| Tests | **PASS** | 50 core ciblés, 17 editor ciblés, 3 154 core complets et 3 543 editor complets. |
| Build / Validation | **PASS avec warnings connus** | Analyses vertes, goldens inspectés, diff propre, build signé arm64 valide. |
| Critique finale | **PASS après challenge** | Completion runtime séparée du lifecycle ; effects locaux remappés ; suppressions destructives remplacées par protections visibles. |

Les instructions d'environnement interdisaient les sub-agents sans demande explicite. Conformément à `codex_rule.md`, les cinq contrôles ont donc été exécutés comme passes locales séparées et nommées.

## 10. État Git final avant commit et isolement

Le working tree contient les 14 chemins NSC-21 de la section 6, plus exactement les neuf chemins préexistants de la section 4. Le commit doit utiliser `git commit --only` avec les chemins NSC-21 afin de préserver le test lighthouse déjà indexé.

Après commit isolé attendu : aucun fichier NSC-21 ne reste modifié ; les neuf chemins préexistants restent identiques et le test lighthouse demeure staged.

## 11. Limites et risques restants

- Le formulaire Step est volontairement riche et scrollable ; une extraction future en sous-composants dédiés réduirait la taille de `storylines_workspace.dart`, sans changer le contrat.
- Le picker condition édite directement les conditions Fact simples. Une condition composée/avancée existante est conservée et signalée, pas dégradée silencieusement.
- `expectedOutcomeIds` ne porte qu'un ID d'outcome ; si deux Scenes déclarent le même ID, le picker déduplique par ID conformément au schéma actuel. NSC-22 devra diagnostiquer les ambiguïtés de projection.
- Les mutations utilisent encore `applyInMemoryProjectManifest`; l'undo/session NSC-13 du graph appartient à NSC-23.
- La complétion effective d'une Step reste `PlayerProgression.completedStepIds`. NSC-22/23 pourront projeter cet état en preview sans le sérialiser dans la Storyline.

## 12. Auto-critique finale

Le diff UI est volumineux parce que l'ancien dialog générique ne pouvait plus exprimer conditions, références cassées, outcomes et déplacement. La logique métier n'a toutefois pas été déplacée dans le widget : il produit un draft, puis appelle les opérations pures.

La première version du clone de SceneLink copiait les effets d'outcome sans remapper une cible Step locale. La passe critique l'a détecté ; `activateStep` et `completeStep` ciblant la Step source sont maintenant réécrits vers la Step clonée et couverts par test.

L'ancienne suite UI supposait que supprimer un Chapter/Step Selbrume réussissait même avec des consumers. Ce comportement était contraire à la roadmap. Les nouvelles assertions prouvent le refus, le maintien du manifeste et l'affichage des chemins concernés.

Aucun fichier gameplay, runtime, seed ou manifeste Selbrume préexistant n'a été modifié par ce lot. Aucun pourcentage de couverture non mesuré n'est revendiqué.

## 13. Prochaine étape proposée, non implémentée

Le prochain lot est **NSC-22 — Contrat de projection de progression Storyline** : projeter chaque edge visible depuis l'ordre, les relationships, les Scene outcome effects et les conditions, puis fournir uniquement les opérations inverses prouvées et réversibles.
