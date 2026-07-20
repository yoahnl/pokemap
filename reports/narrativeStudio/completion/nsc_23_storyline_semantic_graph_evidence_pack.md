# Evidence Pack — NSC-23 — Graph Storyline sémantique et interactif

Date : 2026-07-20  
Package : `packages/map_editor`  
Roadmap : `docs/superpowers/plans/2026-07-19-narrative-studio-completion-roadmap.md`  
Verdict proposé : **DONE**

## 1. Résumé exécutif

NSC-23 remplace la projection locale du graph Storyline par un adaptateur exclusif de `StorylineProgressionProjection` livré par NSC-22. Les nœuds et arêtes affichés possèdent donc une source canonique, un libellé sémantique et un niveau d’éditabilité explicite.

Le graph permet désormais la sélection clavier, une multi-sélection minimale, un déplacement strictement visuel et réinitialisable, la navigation vers l’inspecteur et la connexion guidée d’un effet d’outcome, d’une relation Storyline ou d’une condition Fact. Une déconnexion n’est proposée que pour une arête prouvée réversible par le core. Les relations en lecture seule restent visibles avec leur raison, sans dépendre uniquement de la couleur.

Les opérations passent par `EditorNotifier.applyNarrativeDocumentEdit`, donc par le journal et l’undo de NSC-13. Le placement du graph reste éphémère : aucune coordonnée, aucun ordre visuel et aucun edge parallèle ne sont sérialisés.

Validation finale : **7 tests NSC-23**, **285 tests Narrative Studio étendus**, **3 550 tests `map_editor` complets**, analyse statique complète propre et build macOS debug réussi.

## 2. Audit initial

### Contrats trouvés

- `StorylineProgressionProjection` exposait déjà l’unique liste ordonnée des nœuds et arêtes, leurs sources, leur libellé et leur éditabilité.
- le graph editor historique reconstruisait localement ownership, ordre et relations de side quest ; cette duplication pouvait diverger du core.
- la Structure restait l’éditeur canonique de l’ordre Chapters/Steps et devait demeurer une alternative complète.
- `EditorNotifier.applyNarrativeDocumentEdit` fournissait le journal transactionnel et l’undo, mais la passerelle de persistance durable NSC-13 est encore limitée au pilote Cinematics.
- le design system fournissait déjà side sheet, boutons, badges, surfaces, dropdowns et contrôles segmentés nécessaires.

### Risques identifiés

- sérialiser le placement visuel ou le confondre avec l’ordre auteur ;
- rendre déconnectable une relation dont l’inverse perdrait des données ;
- réinventer des edges dans le painter ;
- exposer des identifiants techniques dans les formulaires no-code ;
- masquer conditions et outcomes cassés ;
- provoquer des overflows dans le panneau central étroit ou avec un texte agrandi ;
- laisser une sélection d’edge obsolète après rechargement.

### Verdict Audit / Architecture

**PASS** : le graph est un adaptateur de lecture et un lanceur d’opérations core. Il ne possède aucune seconde vérité narrative et ne modifie pas le schéma.

## 3. État Git initial

HEAD initial : `fc57b1f8 feat(narrative): define storyline progression projection`.

Changements préexistants hors lot, conservés :

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

Le test lighthouse était déjà indexé avant le lot et reste hors du commit NSC-23.

## 4. Contrat livré

| Besoin | Comportement livré | Persistance |
|---|---|---|
| Projection | `StorylineGraphViewModel` adapte exactement les IDs ordonnés du core | aucune donnée parallèle |
| Ownership / ordre | visibles comme relations structurantes | lecture seule ; édition dans Structure |
| Outcomes | `activeStep` / `completeStep` sélectionnés via des libellés humains | opération core réversible |
| Relations Storyline | `requires`, `blocks`, `convergesTo` via pickers | opération core réversible |
| Conditions | Fact + valeur + slot entrée/complétion via pickers | opération core réversible si simple |
| Relations enrichies | visibles avec cadenas et raison | lecture seule, aucune perte |
| Position | drag d’un ou plusieurs nœuds et reset | état widget éphémère uniquement |
| Sélection | clic, appui long, Entrée/Espace, callback inspecteur | état UI uniquement |
| Edge obsolète | disparaît après rechargement canonique | aucune sélection fantôme |
| Undo | mutation via session NSC-13 et `EditorNotifier` | journalisée et annulable |

Le rail sémantique donne un texte à chaque relation. Le painter n’utilise la couleur qu’en renfort et ne fabrique aucune relation canonique.

## 5. Inventaire complet des fichiers

### Fichiers créés

| Fichier | Contenu complet / responsabilité |
|---|---|
| `packages/map_editor/test/storylines_graph_authoring_test.dart` | 549 lignes : parité projection/adaptateur, libellés et raisons read-only, refus de déconnexion, clavier, multi-sélection, déplacement/reset, formulaire guidé, reload stale-safe, journal et undo. |
| `reports/narrativeStudio/completion/nsc_23_storyline_semantic_graph_evidence_pack.md` | présent document complet. |

Le fichier de test ci-dessus constitue le contenu complet faisant autorité ; ses scénarios et responsabilités sont listés exhaustivement ici sans recopier 549 lignes dans un second artefact divergent.

### Fichiers modifiés — zones précises

| Fichier | Zone | Raison / impact |
|---|---|---|
| `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_model.dart` | enums, factory `fromProject`, adaptation nodes/edges | Consomme exclusivement la projection NSC-22 et transporte source/éditabilité. |
| `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_painter.dart` | styles d’edges et flèches | Rend les catégories sémantiques via tokens, pointillés et direction. |
| `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart` | état du graph, toolbar, rail, side sheet, canvas et interactions | Sélection, déplacement éphémère, connexion guidée et déconnexion sûre. |
| `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart` | callbacks graph et mutations documentaires | Branche connect/disconnect sur core, journal et undo ; synchronise l’inspecteur. |
| `packages/map_editor/test/storylines_workspace_shell_test.dart` | contrat toolbar/geometry | Remplace l’ancien libellé read-only par le contrat sémantique. |
| `packages/map_editor/test/goldens/narrative_studio/storylines/storylines_full_product_route_1672x941.png` | golden produit | Référence du graph sémantique sur la route réelle. |
| `reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_bis_graph_focus_canvas.png` | Visual Gate | Projection canonique focalisée. |
| `reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_bis_graph_full_layout.png` | Visual Gate | Route complète avec relations sémantiques. |
| `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_graph_regression.png` | Visual Gate | Non-régression Structure → Graph. |
| `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_empty_polished.png` | Visual Gate | État sans chapitre. |
| `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_main_polished.png` | Visual Gate | Storyline principale. |
| `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_sidequest_attached_polished.png` | Visual Gate | Quête annexe attachée. |
| `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_sidequest_standalone_polished.png` | Visual Gate | Quête annexe autonome. |

Diff textuel suivi avant ajout du test et du présent rapport : **1 345 insertions, 171 suppressions** dans 13 fichiers suivis, plus huit images binaires actualisées.

## 6. Tests et garde-fous

Couverture positive : parité exacte projection/UI, sélection souris/clavier, multi-sélection minimale, mouvement/reset, création guidée d’une relation typée, déconnexion journalisée, undo et rechargement canonique.

Couverture négative : relation read-only non déconnectable, sélection d’edge obsolète, aucune mutation projet lors d’un drag, aucun ID technique demandé, aucun overflow sur la matrice desktop et texte agrandi.

Garde-fous : design system uniquement, couleurs issues des tokens, `Structure` conservée, aucune coordonnée sérialisée, aucune règle narrative Flutter, aucune mutation directe du manifeste depuis la vue.

## 7. Commandes et résultats exacts

### TDD et validation ciblée

~~~text
cd packages/map_editor
flutter test test/storylines_graph_authoring_test.dart
00:06 +7: All tests passed!

flutter test --reporter compact \
  test/storylines_graph_authoring_test.dart \
  test/storylines_workspace_shell_test.dart \
  test/storylines_seed_graph_usability_test.dart \
  test/storylines_structure_layout_test.dart \
  test/storylines_current_global_story_characterization_test.dart
00:08 +68: All tests passed!

flutter analyze <7 fichiers ciblés>
Analyzing 7 items...
No issues found! (ran in 4.3s)
~~~

### Régressions détectées puis corrigées

~~~text
flutter test --reporter compact <4 suites Storylines historiques>
=> 57 tests passés ; ancien libellé toolbar et 7 goldens obsolètes.

flutter test --fail-fast --reporter expanded
=> overflow de la toolbar à 664 px dans la route réelle 1440x900.

flutter test test/storylines_workspace_scene_links_test.dart \
  --plain-name 'StorylineStep scene links authoring preserves an optional side quest Step lifecycle status'
=> overflow d'une side quest chargée à 808 px.
~~~

Corrections : toolbar compacte sous 840 px, Visual Gates régénérées et inspectées une par une, assertions historiques mises à jour uniquement lorsque le contrat avait réellement changé.

### Validation Narrative Studio étendue

~~~text
cd packages/map_editor
flutter test --reporter compact \
  test/storylines*.dart \
  test/ui/canvas/narrative_studio*.dart \
  test/features/narrative/application/overview/narrative_overview_read_model_test.dart
00:16 +285: All tests passed!
~~~

### Validation complète et build

~~~text
cd packages/map_editor
flutter analyze
Analyzing map_editor...
No issues found! (ran in 9.7s)

flutter test --reporter compact
03:20 +3550: All tests passed!

flutter build macos --debug
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app

dart format <6 fichiers Dart du lot>
Formatted 6 files (0 changed) in 0.05 seconds.
~~~

## 8. Verdict des cinq passes obligatoires

| Passe locale séparée | Verdict | Preuve |
|---|---|---|
| Audit / Architecture | **PASS** | Adaptateur pur de NSC-22 ; aucune seconde vérité. |
| Implémentation | **PASS** | Connexions guidées, déconnexion sûre, mouvement éphémère et inspecteur. |
| Tests | **PASS** | 7 NSC-23, 285 Narrative Studio, 3 550 complets. |
| Build / Validation | **PASS** | Analyse complète propre et app macOS debug construite. |
| Critique finale | **PASS après correction** | Seuil responsive élargi de 620 à 840 px après deux cas d’overflow réels. |

Les instructions actives interdisent les sub-agents sans demande explicite. Les contrôles de `codex_rule.md` ont donc été exécutés comme passes locales distinctes.

## 9. Limites et portée runtime

- la passerelle de persistance durable de `NarrativeDocumentSession` reste le pilote Cinematics. Le graph utilise bien journal et undo NSC-13, mais la sauvegarde Storyline durable via cette passerelle doit être généralisée dans un lot de session ultérieur ; ce lot n’invente pas une seconde voie d’écriture.
- les relations side quest enrichies et les conditions composées restent volontairement en lecture seule dans le graph ; leurs formulaires spécialisés conservent l’autorité.
- le déplacement des nœuds est volontairement perdu au remontage/rechargement. Il ne représente jamais l’ordre narratif.
- les relations sémantiques sont listées dans un rail horizontal pour rester accessibles même lorsqu’un endpoint n’est pas dessiné dans la portion visible du canvas.
- aucun nouveau comportement runtime n’est revendiqué : NSC-23 est un lot d’authoring et de projection.

## 10. Auto-critique finale

La vue du graph devient substantielle, principalement à cause du formulaire guidé et des représentations spécialisées des nœuds. Une extraction future du formulaire en fichier dédié améliorerait la navigation, mais la réaliser maintenant élargirait le diff sans modifier le contrat livré.

Le premier seuil compact de 620 px reproduisait le comportement historique mais ne couvrait plus la nouvelle toolbar. Un test produit à 664 px puis une side quest à 808 px ont prouvé la limite ; le seuil 840 px est couvert par la matrice responsive complète plutôt que choisi uniquement visuellement.

Les images actualisées ont été inspectées : elles montrent les libellés sémantiques, les cadenas/relations et une hiérarchie stable. Le canvas de très grandes storylines conserve son défilement ; aucun cadrage automatique global n’est ajouté par ce lot.

## 11. État Git final avant commit

Le commit doit inclure uniquement les quinze chemins NSC-23 ci-dessus (six code/test, huit images et le présent rapport) au moyen de `git commit --only`. Les changements Selbrume préexistants, dont le test lighthouse déjà staged, doivent rester inchangés et hors commit.

## 12. Prochaine étape

**NSC-24 — Overview opérationnelle et activité durable** : dériver les compteurs, alertes, reprise d’édition et raccourcis depuis les sources canoniques, le journal NSC-13 et les diagnostics du Validator, sans inventer d’activité runtime.
