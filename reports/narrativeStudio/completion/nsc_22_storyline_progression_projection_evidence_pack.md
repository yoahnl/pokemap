# Evidence Pack — NSC-22 — Projection de progression Storyline

Date : 2026-07-20  
Package : `packages/map_core`  
Roadmap : `docs/superpowers/plans/2026-07-19-narrative-studio-completion-roadmap.md`  
Verdict proposé : **DONE**

## 1. Résumé exécutif

NSC-22 définit le contrat pur que le graph Storyline devra consommer. Les nœuds et arêtes sont projetés depuis les champs canoniques existants : ownership et ordre des Chapters/Steps, effets `activateStep`/`completeStep` des outcomes, `StorylineRelationship` et conditions d’entrée/de complétion.

Aucun tableau d’edges, aucune coordonnée et aucun layout n’ont été ajoutés au schéma. Chaque arête expose sa source canonique précise et son niveau d’éditabilité. Une arête n’est réversible que lorsqu’une opération inverse atomique est prouvée ; les ordres, ownership, conditions composées et relations descriptives restent visibles avec une raison de lecture seule.

Les mutations réversibles couvrent connexion/déconnexion d’un effet d’outcome, d’une relation `requires`/`blocks`/`convergesTo` et d’une condition Fact simple. Elles refusent destination absente, doublon, cycle et écrasement d’une condition avancée. Les diagnostics de liens structurés couvrent désormais Scenario, outcome et Step cibles absents ainsi que les effets Step dupliqués.

Validation finale : **20 tests ciblés**, **3 169 tests `map_core` complets** et analyse statique complète sans erreur.

## 2. Audit initial

### Contrats trouvés

- `StorylineAsset` possédait déjà toutes les sources canoniques utiles.
- le graph editor existant construisait sa propre projection limitée à `contains`, `authorOrder` et side quests ; il ne possédait pas encore de contrat core.
- `StorylineSceneOutcomeLink.effects` imposait une liste non vide et devait être respecté lors d’une déconnexion.
- les conditions simples Fact étaient identifiables sans ambiguïté via `flagIsSet`/`flagIsUnset` ; les conditions composées ne possédaient pas d’inverse sûr.
- `StorylineRelationshipKind` mélange des relations de progression simples et des relations descriptives enrichies.

### Risques identifiés

- créer une seconde vérité sérialisée ;
- confondre position visuelle et ordre narratif ;
- inventer un inverse destructeur pour une condition composée ;
- masquer les destinations cassées ;
- autoriser un cycle de dépendances ou d’effets entre Steps ;
- laisser le graph modifier une relation descriptive en perdant anchor/availability/condition.

### Verdict Audit / Architecture

**PASS** : le schéma reste inchangé. Projection, validation et mutations sont dans `map_core`, sans Flutter ni runtime. Le futur graph NSC-23 pourra consommer ce contrat sans posséder de logique narrative parallèle.

## 3. État Git initial

HEAD initial : `c255239f feat(narrative): complete chapter and step authoring`.

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

Le test lighthouse était déjà indexé avant le lot et reste hors du commit NSC-22.

## 4. Contrat livré

| Source canonique | Arête projetée | Éditabilité | Mutation inverse |
|---|---|---:|---|
| ownership Storyline → Chapter / Chapter → Step | `contains` | lecture seule | opérations de structure NSC-21 |
| `Chapter.order` / `Step.order` | `authorOrder` | lecture seule | opérations de réordre NSC-21 |
| outcome effect `activateStep` | `outcomeActivatesStep` | réversible | ajout/retrait exact de l’effet |
| outcome effect `completeStep` | `outcomeCompletesStep` | réversible | ajout/retrait exact de l’effet |
| relationship `requires` | `requires` | réversible | ajout/retrait de la relation canonique |
| relationship `blocks` | `blocks` | réversible | ajout/retrait de la relation canonique |
| relationship `convergesTo` | `convergesTo` | réversible | ajout/retrait de la relation canonique |
| relation side quest enrichie | `sideQuestAvailability` | lecture seule | formulaire relation dédié requis |
| `flagIsSet` / `flagIsUnset` | `entryCondition` / `completionCondition` | réversible | set/clear du slot exact |
| condition composée | condition synthétique → Step | lecture seule | aucun inverse non ambigu |

Les identifiants de projection sont déterministes. Les destinations absentes restent des nœuds `isMissing` et génèrent un diagnostic. Le layout reste exclusivement une responsabilité éphémère de l’éditeur.

## 5. Inventaire complet des fichiers

### Fichiers créés

| Fichier | Contenu complet / responsabilité |
|---|---|
| `packages/map_core/lib/src/read_models/storyline_progression_projection.dart` | 699 lignes : enums du contrat, nœuds, sources, edges, diagnostics, projection pure des structures/outcomes/relations/conditions et détection de cycles. |
| `packages/map_core/lib/src/authoring/storyline_progression_operations.dart` | 683 lignes : requêtes typées, résultats atomiques, connect/disconnect, protections doublon/destination/cycle et reconstruction immutable. |
| `packages/map_core/test/storyline_progression_projection_test.dart` | 318 lignes : ownership, ordre, outcomes, relations, conditions, références absentes et cycles. |
| `packages/map_core/test/storyline_progression_operations_test.dart` | 342 lignes : mutations inverses, rejets atomiques, cycles, conditions et round-trip sans stockage de graph. |
| `reports/narrativeStudio/completion/nsc_22_storyline_progression_projection_evidence_pack.md` | présent document complet. |

Les quatre fichiers source/test ci-dessus sont eux-mêmes le contenu complet faisant autorité ; leurs responsabilités, lignes et zones sont exhaustivement listées ici sans recopier 2 042 lignes dans un second artefact divergent.

### Fichiers modifiés — zones précises

| Fichier | Zone | Raison / impact |
|---|---|---|
| `packages/map_core/lib/map_core.dart` | exports authoring/read model | Rend le contrat public aux consommateurs editor. |
| `packages/map_core/lib/src/diagnostics/storyline_scene_link_diagnostics.dart` | enum, diagnostic metadata, boucle structured links | Valide Scenario/outcome/Step et doublons d’effets. |
| `packages/map_core/test/storyline_scene_link_diagnostics_test.dart` | trois scénarios structurés et fixture | Preuve des nouveaux diagnostics. |

Diff suivi avant ajout des quatre nouveaux fichiers et du présent rapport : **256 insertions** dans les trois fichiers modifiés. Nouveaux fichiers source/test : **2 042 lignes**.

## 6. Tests et garde-fous

Couverture positive : projection déterministe, source outcome exacte, relations réversibles, condition Fact simple, connect/disconnect symétrique, JSON round-trip.

Couverture négative : Storyline/destination absente, effet dupliqué, relation dupliquée, cycle de Storylines, cycle de Steps, slot condition occupé, condition composée non réversible, ordre dérivé non déconnectable, Scenario/outcome/Step structuré absent.

Garde-fous : rejet/no-op conserve la même instance de manifeste, aucune coordonnée sérialisée, aucun champ runtime inventé, aucun import Flutter/Flame.

## 7. Commandes et résultats exacts

### TDD initial

~~~text
cd packages/map_core
dart test test/storyline_progression_projection_test.dart test/storyline_progression_operations_test.dart
=> échec de compilation attendu : buildStorylineProgressionProjection,
   StorylineProgressionConnectRequest et opérations absents.

dart test test/storyline_scene_link_diagnostics_test.dart
=> échec de compilation attendu : nouveaux codes et métadonnées absents.
~~~

### Validation ciblée

~~~text
cd packages/map_core
dart test test/storyline_progression_projection_test.dart \
  test/storyline_progression_operations_test.dart \
  test/storyline_scene_link_diagnostics_test.dart
00:00 +20: All tests passed!

dart analyze lib/src/read_models/storyline_progression_projection.dart \
  lib/src/authoring/storyline_progression_operations.dart \
  lib/src/diagnostics/storyline_scene_link_diagnostics.dart \
  test/storyline_progression_projection_test.dart \
  test/storyline_progression_operations_test.dart \
  test/storyline_scene_link_diagnostics_test.dart
No issues found!
~~~

### Validation complète

~~~text
cd packages/map_core
dart test
00:09 +3169: All tests passed!

dart analyze
Analyzing map_core...
No issues found!

git diff --check
=> exit 0, aucune sortie
~~~

## 8. Verdict des cinq passes obligatoires

| Passe locale séparée | Verdict | Preuve |
|---|---|---|
| Audit / Architecture | **PASS** | Projection exclusivement dérivée du schéma existant. |
| Implémentation | **PASS** | Sources exactes, inverses atomiques et raisons read-only explicites. |
| Tests | **PASS** | 20 ciblés et 3 169 complets. |
| Build / Validation | **PASS** | `dart analyze` complet propre ; package pure Dart, aucun build Flutter pertinent. |
| Critique finale | **PASS après correction** | Attente d’ordre du fixture corrigée de 2 à 1 ; diagnostic structured links élargi. |

Les instructions actives interdisent les sub-agents sans demande explicite. Les contrôles de `codex_rule.md` ont donc été exécutés comme passes locales distinctes.

## 9. Limites et portée runtime

- `requires`, `blocks` et `convergesTo` expriment aujourd’hui une contrainte authoring/validation ; ce lot ne prétend pas leur ajouter un effet runtime inédit.
- les relations side quest avec anchor, availability ou condition sont volontairement read-only dans la projection simple afin de ne perdre aucune donnée enrichie.
- une condition composée reste éditable dans son formulaire dédié ; le graph la montre sans prétendre pouvoir la remplacer par un unique edge Fact.
- la suppression du dernier effet retire l’`outcomeLink` complet, car le modèle interdit un outcome link vide.
- NSC-23 devra brancher UI, clavier et undo sur ces opérations sans sérialiser le placement visuel.

## 10. Auto-critique finale

Le contrat est volontairement explicite, au prix de deux fichiers core conséquents. Cette taille évite cependant de laisser l’éditeur interpréter des champs canoniques de plusieurs façons. Une extraction future de helpers de parcours serait possible, mais n’est pas nécessaire au lot et risquerait un refactor hors scope.

La première assertion d’ordre supposait deux arêtes pour deux Chapters et une Step par Chapter. La projection adjacente correcte n’en produit qu’une ; le test a été rectifié plutôt que de fabriquer une arête d’ordre depuis un parent qui ferait doublon avec `contains`.

Les cycles sont conservativement interdits pour les relations réversibles et les effets Step. Les relations descriptives ne participent pas au solveur de cycle. Aucun pourcentage de couverture non mesuré ni garantie runtime non prouvée n’est revendiqué.

## 11. État Git final avant commit

Le commit doit inclure uniquement les huit chemins NSC-22 ci-dessus (sept code/test plus le présent rapport) au moyen de `git commit --only`. Les neuf changements préexistants doivent rester inchangés, et le test lighthouse déjà staged doit rester staged hors commit.

## 12. Prochaine étape

**NSC-23 — Graph Storyline sémantique et interactif** : remplacer la projection editor locale par `StorylineProgressionProjection`, connecter/déconnecter uniquement les arêtes réversibles, afficher les raisons read-only et brancher l’undo/session NSC-13.
