# NS-EVENT-40 — Event Builder Shell-Level Pixel Polish & Real App Visual QA V0

Date : 2026-07-09

Repo : `/Users/karim/Project/pokemonProject`

Package concerné : `packages/map_editor`

## 1. Résumé exécutif

Pixel Polish : PASS, avec réserve de capture desktop réelle.

Ressemblance référence : moyenne à forte sur le shell Event Builder, moyenne sur le chrome global complet.

Ce qui a été rapproché :

- header Event Builder plus compact, avec métriques et CTA sur la même bande ;
- colonnes mieux alignées et moins larges côté liste/bibliothèque ;
- flow central plus dense ;
- connecteurs `+` plus compacts et testables ;
- conséquences projetées en grille pour l'événement existant ;
- fallback empilé pour le mode guidé post-création afin d'éviter les overflows ;
- bibliothèque plus compacte pour les items disponibles ;
- labels de boutons en golden plus fiables grâce à l'héritage de font family dans `PokeMapButton`.

Ce qui reste différent :

- le top chrome global exact de l'image de référence n'a pas été refait ;
- le flow central reste plus fonctionnel et plus haut que la maquette, car il expose de vrais contrôles d'édition no-code ;
- une seule capture ne peut pas montrer simultanément tout le flow à 1680x980, donc deux Visual Gates complémentaires sont produites ;
- aucune capture desktop réelle automatisée n'a été créée, faute de méthode déterministe dans ce lot.

Prochain lot recommandé : NS-EVENT-41 — Event Builder Full App Shell Capture & Top Chrome Alignment V0.

Blockers : aucun pour le lot widget/golden ; capture desktop réelle à traiter dans un lot dédié si elle devient obligatoire.

## 2. Image de référence utilisée

Image fournie par l'utilisateur et déjà utilisée par NS-EVENT-39 :

```text
/Users/karim/Downloads/ChatGPT Image Jul 8, 2026, 06_53_40 PM.png
```

Le prompt nomme `pokemap_rpg_event_editor_interface.png`, mais ce fichier n'était pas présent dans `Downloads`. La référence disponible et inspectée est donc l'image ci-dessus.

Signaux de référence retenus :

- dark premium ;
- sidebar Narrative Studio lisible ;
- header `Événements` compact ;
- métriques et CTA visibles en haut ;
- quatre colonnes : liste, bibliothèque, flow, inspecteur ;
- flow vertical avec connecteurs ;
- cartes colorées par type ;
- inspecteur factuel ;
- densité plus compacte que NS-EVENT-39.

## 3. Captures comparées

Référence :

```text
/Users/karim/Downloads/ChatGPT Image Jul 8, 2026, 06_53_40 PM.png
```

NS-EVENT-39 :

```text
reports/narrativeStudio/events/screenshots/ns_event_39_event_builder_reference_ui_redesign_v0.png
```

NS-EVENT-40 :

```text
reports/narrativeStudio/events/screenshots/ns_event_40_event_builder_pixel_polish_v0.png
reports/narrativeStudio/events/screenshots/ns_event_40_event_builder_diagnostics_pixel_polish_v0.png
```

Les deux captures NS-EVENT-40 font `1680 x 980`.

## 4. Usage du MCP Dart

MCP Dart utilisé.

Racine ajoutée :

```text
mcp__dart.roots add file:///Users/karim/Project/pokemonProject/packages/map_editor
Result: Success
```

Symboles résolus via LSP :

```text
EventBuilderWorkspace
NarrativeWorkspaceCanvas
EventBuilderElementLibrary
EventBuilderInspectorPanel
PokeMapMetricCard
```

Analyse MCP finale :

```text
mcp__dart.analyze_files
Paths:
- lib/src/ui/canvas/events/event_builder_workspace.dart
- lib/src/ui/canvas/events/event_builder_central_flow.dart
- lib/src/ui/canvas/events/event_builder_element_library.dart
- lib/src/ui/canvas/events/event_builder_flow_blocks.dart
- lib/src/ui/design_system/pokemap_button.dart
- test/event_builder_workspace_test.dart
- test/event_builder_draft_creation_notifier_test.dart

Result:
No errors
```

## 5. Sous-agents / passes utilisées

Orchestrateur principal : Codex.

| Passe | Type | Verdict | Synthèse |
|---|---|---|---|
| A — Visual Reference Reviewer | Sous-agent réel | PASS avec réserve | A identifié le manque de full shell/top chrome et la nécessité de compacter header, métriques, colonnes et flow. |
| B — Flutter Layout / Overflow Reviewer | Sous-agent réel | PASS | A détecté le conflit initial `LayoutBuilder` + `IntrinsicHeight`, l'overflow potentiel et l'avertissement analyzer `colors` inutilisé. |
| C — Design System Reviewer | Sous-agent réel | PASS | A confirmé l'absence de `Color(0x...)` / `Colors.*` dans Event Builder et recommandé de rester sur les primitives PokeMap. |
| D — Tests / Golden Reviewer | Sous-agent réel | PASS | A proposé le groupe NS-EVENT-40, les assertions de layout, les guardrails et les captures. |
| E — Scope Reviewer | Sous-agent réel combiné D/E | PASS | A refusé runtime, `map_core`, gameplay, battle, Event-owned outcomes/reactions, World Rule editor et drag/drop. |
| F — Orchestrateur | Principal | PASS | A intégré les corrections, relancé tests, analyse, build et écrit le rapport. |

## 6. Audit visuel initial

Gate 0 avant modification :

```text
Command: pwd
Result:
/Users/karim/Project/pokemonProject

Command: git branch --show-current
Result:
main

Command: git status --short --untracked-files=all
Result:
 M packages/map_editor/pubspec.lock

Command: git diff --stat
Result:
 packages/map_editor/pubspec.lock | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)

Command: git diff --name-only
Result:
packages/map_editor/pubspec.lock

Command: git log --oneline -n 20
Result:
89b81e47 NS-EVENT-39: Event Builder Reference UI Redesign / Flow-Based Layout V0
6fab98e4 NS-EVENT-38: Event Builder Map Placement & Post-Creation Guided Setup UX V0
c017dc8f NS-EVENT-37: Event Builder First Event Creation UX Simplification V0
786e86da NS-EVENT-36: Event Builder Real App Manual Creation Availability Fix / Layer Gate UX - PASS
fb440ae8 NS-EVENT-35: Event Builder Trigger Variants Runtime Handoff / Lifecycle Semantics Gate - PARTIAL
3f96204e NS-EVENT-34: Event Builder Runtime Handoff Smoke / Editor-authored Scene Target Gate - PASS
0b180895 NS-EVENT-33: Event Builder MVP Closure / End-to-End Authoring Readiness Gate - DONE
25cdf062 NS-EVENT-32: Event Builder World Rules Projection UX Closure / Validation Gate - DONE
972c73ad NS-EVENT-31: Implement Passive World Rules Projection UI V0 - DONE
a1480aeb NS-EVENT-30: Implement Passive World Rules Projection Read Model V0
3502ca74 NS-EVENT-29: Implement Linked Scene Consequences World Impact Projection Read Model V0
906809bb NS-EVENT-28: Polish Event Builder World Changes Read-only Projection UI
e13ebb6e NS-EVENT-27: Implement Event Builder Scene Outcomes and Lifecycle Projection UI V0
b7fce79e NS-EVENT-26: Implement Event Builder Scene Outcomes and Lifecycle Projection Read Model V0
36a8f362 NS-EVENT-25: Add outcomes, reactions, and consequences contract alignment audit report
8c2bb4b2 ns_event_v1: Ajout des composants de l'éditeur d'événements et rapports associés
54c59fba ns_event_16: Consolidation de la disposition des blocs et disponibilité de la création d'activation de carte
8b3866a8 ns_event_15: Ajout de l'auteur des types de déclencheurs pour les événements
8a5996be ns_event_14: Ajout des conditions de consommation d'événements
7f490b9e ns_event_13: Ajout de l'auteur des conditions de fait pour les événements
```

Drift préexistant :

```text
packages/map_editor/pubspec.lock
```

Il est resté hors scope : non revendiqué, non volontairement modifié.

Prompt audit :

- le lot est cohérent avec la réserve NS-EVENT-39 ;
- la demande de capture desktop réelle est formulée "si possible", donc non bloquante ;
- le top chrome global complet exigerait une refonte plus large de `EditorShellPage`, refusée dans ce lot ;
- l'image nommée par le prompt n'était pas trouvable, mais la référence utilisateur disponible a été utilisée.

## 7. Grille de comparaison référence vs NS-EVENT-39 vs NS-EVENT-40

| Zone | Référence | État NS-EVENT-39 | Écart | Action NS-EVENT-40 | Statut final |
|---|---|---|---|---|---|
| Global shell | Full app avec top chrome et status bar | Capture widget Event Builder | Top chrome absent | Documenté hors scope ; build macOS validé | PARTIAL |
| Narrative sidebar | Compacte, lisible | Présente mais style repo | Peu proche pixel-perfect | Non modifiée pour éviter refonte shell | PARTIAL |
| Header Événements | Compact, CTA même bande | Header + métriques en deux bandes | Trop haut | `_EventBuilderShellHeader` compact | PASS |
| Metric cards | Alignées à droite du header | Ligne séparée sous titre | Grosse hauteur | Métriques intégrées au header | PASS |
| CTA Préparer un événement | Haut droite | Présent mais moins intégré | Placement moins référence | CTA dans header compact | PASS |
| Liste événements | Dense | Correcte, colonne trop large | Légèrement massive | Largeur réduite à 264 | PASS |
| Bibliothèque | Dense, badges à droite | Items plus hauts | Trop vertical | Items disponibles avec badge inline, read-only longs sous item | PASS |
| Flow central | Large, vertical | Structure correcte, trop haute | Scroll fort | Padding, icônes et connecteurs compactés | PARTIAL |
| Connecteurs | Petits `+` entre blocs | Présents mais non testés | Pas de key dédiée | `event-builder-flow-connector` ajouté | PASS |
| Bloc Déclencheur | Carte compacte | Fonctionnel, haut | Contrôles réels plus hauts | Flow block compacté | PARTIAL |
| Bloc Conditions | Carte compacte | Fonctionnel, haut | Contrôles réels plus hauts | Flow block compacté | PARTIAL |
| Bloc Action principale | Carte compacte | Fonctionnel, haut | Plus haut que référence | Flow block compacté | PARTIAL |
| Bloc Conséquences projetées | Grille lisible | Bloc vertical | Trop bas/long | Grille deux colonnes hors mode guidé ; empilé en mode guidé | PASS |
| Bloc Diagnostics | Visible dans référence | Hors écran en haut de scroll | Une capture ne suffit pas | Deuxième capture Diagnostics | PASS |
| Inspecteur | Factuel et compact | Factuel, cartes internes | Plus imbriqué | Largeur 340, reste factuel | PARTIAL |
| Footer/status bar | Présent full app | Non capturé | Hors widget | Documenté hors scope | PARTIAL |
| Densité générale | Compacte | Plus scaffold | Trop d'espace perdu | Header, colonnes, flow, library compactés | PASS |

## 8. Corrections UI appliquées

### `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`

Zones modifiées :

- constantes `_eventBuilderShellPadding`, `_eventBuilderColumnGap`, largeurs de colonnes ;
- nouveau widget privé `_EventBuilderShellHeader` ;
- intégration des métriques et du CTA dans le header ;
- réduction des largeurs list/library et augmentation inspecteur ;
- `_ProjectedConsequencesBlock` en mode grille pour l'événement existant ;
- `_ProjectedConsequencesBlock` empilé en mode guidé post-création pour éviter les overflows ;
- en-tête `Issues de la scène liée` rendu vertical pour les colonnes étroites ;
- wording du sous-titre aligné sur la référence.

Impact attendu :

- moins d'espace vertical perdu ;
- colonnes alignées ;
- visual gate plus proche de la référence ;
- mode guidé NS-EVENT-38 conservé ;
- aucune modification métier.

### `packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart`

Zones modifiées :

- padding réduit ;
- header interne plus dense ;
- connecteur compact ;
- key `event-builder-flow-connector`.

Impact attendu :

- flow moins haut ;
- connecteurs testables ;
- alignement plus proche de la référence.

### `packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart`

Zones modifiées :

- padding interne réduit ;
- icône et typographie légèrement compactées ;
- espacement summary/children réduit.

Impact attendu :

- meilleure densité sans supprimer de contrôles.

### `packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart`

Zones modifiées :

- items disponibles avec statut `Disponible` inline ;
- items read-only / à venir conservent le badge sous l'item pour éviter les débordements ;
- libellés longs gardés honnêtes.

Impact attendu :

- bibliothèque plus dense sans mentir sur `Lecture seule`, `Défini dans la scène`, `À venir`.

### `packages/map_editor/lib/src/ui/design_system/pokemap_button.dart`

Zones modifiées :

- `PokeMapButton` conserve désormais le `DefaultTextStyle` hérité via `copyWith`.

Impact attendu :

- les captures avec police de test rendent mieux les labels de boutons ;
- pas de couleur brute ajoutée ;
- primitive design-system corrigée au lieu de bricoler localement.

### `packages/map_editor/test/event_builder_workspace_test.dart`

Zones modifiées :

- groupe `NS-EVENT-40 shell pixel polish visual QA` ajouté ;
- assertion NS-EVENT-04 du sous-titre mise à jour ;
- capture NS-EVENT-40 principale ;
- capture NS-EVENT-40 diagnostics ;
- assertions de colonnes, connecteurs, read-only, placement carte, absence de features interdites.

## 9. Écarts restants

- Le top chrome global de la référence n'est pas reproduit pixel-perfect.
- La capture est une golden widget, pas une capture desktop réelle.
- Le flow central reste plus haut que la référence, car les vrais contrôles d'édition restent visibles.
- La sidebar Narrative Studio n'a pas été redessinée.
- L'inspecteur reste légèrement plus card-based que la référence.

## 10. Tests ajoutés / modifiés

Groupe ajouté :

```text
NS-EVENT-40 shell pixel polish visual QA
```

Tests ajoutés :

```text
keeps reference layout shell visible
keeps event builder columns aligned and sized
keeps central flow visually ordered
keeps read-only projections honest
keeps map placement flow working
keeps forbidden authoring absent
captures polished real-reference visual gate
```

Test modifié :

```text
NS-EVENT-04 shows a readable empty state
```

Motif : le sous-titre du header a été aligné avec la référence.

## 11. Visual Gate

Captures créées :

```text
reports/narrativeStudio/events/screenshots/ns_event_40_event_builder_pixel_polish_v0.png
reports/narrativeStudio/events/screenshots/ns_event_40_event_builder_diagnostics_pixel_polish_v0.png
```

Dimensions :

```text
1680 x 980
1680 x 980
```

Commande :

```bash
cd packages/map_editor
flutter test --update-goldens --reporter=compact --dart-define=NS_EVENT_40_CAPTURE_WORKSPACE=true test/event_builder_workspace_test.dart --name "NS-EVENT-40 shell pixel polish visual QA captures polished real-reference visual gate"
```

Résultat exact :

```text
NS-EVENT-40 shell pixel polish visual QA captures polished real-reference visual gate
All tests passed!
```

Capture desktop réelle :

```text
Non créée.
```

Raison : le build macOS debug est validé, mais le lot n'a pas ajouté d'automatisation fiable pour charger le projet, ouvrir l'Event Builder et capturer une fenêtre desktop réelle sans intervention. Le prochain lot recommandé couvre ce point.

## 12. Validations exécutées

Tests ciblés :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-40"
```

Résultat :

```text
NS-EVENT-40 shell pixel polish visual QA captures polished real-reference visual gate
All tests passed!
```

Régressions :

```bash
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-39"
```

Résultat :

```text
NS-EVENT-39 reference UI redesign captures reference UI visual gate
All tests passed!
```

```bash
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-38"
```

Résultat :

```text
NS-EVENT-38 map placement and guided setup UX captures map placement and guided setup visual gate
All tests passed!
```

```bash
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-37"
```

Résultat :

```text
NS-EVENT-37 first-event creation UX captures first event creation UX visual gate
All tests passed!
```

```bash
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-36"
```

Résultat :

```text
captures NS-EVENT-36 manual creation availability visual gate
All tests passed!
```

```bash
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-33"
```

Résultat :

```text
captures NS-EVENT-33 event builder MVP closure visual gate
All tests passed!
```

Suite complète :

```bash
flutter test --reporter=compact test/event_builder_workspace_test.dart
```

Résultat :

```text
All tests passed!
```

Notifier :

```bash
flutter test --reporter=compact test/event_builder_draft_creation_notifier_test.dart
```

Résultat :

```text
All tests passed!
```

Analyse ciblée :

```bash
flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/events/event_builder_workspace.dart lib/src/ui/canvas/events/event_builder_central_flow.dart lib/src/ui/canvas/events/event_builder_element_library.dart lib/src/ui/canvas/events/event_builder_inspector_panel.dart lib/src/ui/canvas/events/event_builder_creation_panel.dart lib/src/ui/canvas/events/event_builder_flow_blocks.dart lib/src/ui/design_system/pokemap_button.dart test/event_builder_workspace_test.dart test/event_builder_draft_creation_notifier_test.dart
```

Résultat :

```text
Analyzing 10 items...
No issues found! (ran in 3.2s)
```

Build :

```bash
flutter build macos --debug
```

Résultat :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 13. Verdict Pixel Polish

Verdict Pixel Polish : PASS.

Justification :

- les écarts majeurs NS-EVENT-39 ont été réduits ;
- le header est plus proche de la référence ;
- les colonnes sont alignées et testées ;
- le flow central est plus dense ;
- les projections read-only restent honnêtes ;
- les régressions NS-EVENT-39/38/37/36/33 passent ;
- la suite complète workspace passe ;
- analyse et build passent.

Réserve :

```text
La ressemblance full-app complète reste PARTIAL tant que le top chrome global et une vraie capture desktop ne sont pas traités.
```

## 14. Non-objectifs respectés

Respecté :

- pas de modification `packages/map_core/**` ;
- pas de modification `packages/map_runtime/**` ;
- pas de modification `packages/map_gameplay/**` ;
- pas de modification `packages/map_battle/**` ;
- pas de modification `examples/**` ;
- pas de modification `assets/**` ;
- pas de modification `selbrume/**` ;
- pas de modification `pubspec.yaml` ;
- pas de runtime simulation ;
- pas de drag/drop fonctionnel ;
- pas de Event-owned outcomes ;
- pas de Event-owned reactions ;
- pas de World Rule editor ;
- pas de nouveau modèle métier.

Vérification anti-scope :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_core examples assets selbrume pubspec.yaml
```

Résultat :

```text
<empty>
```

Design system :

```bash
rg -n "Color\(0x|Colors\.red|Colors\.green|Colors\.blue|Colors\.white|Colors\.black|Colors\.grey|Colors\.transparent|Colors\." packages/map_editor/lib/src/ui/canvas/events packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/lib/src/ui/design_system/pokemap_button.dart
```

Résultat : aucun usage direct `Color(0x...)` ou `Colors.*`; les seules lignes retournées contiennent `toneColors.*`, donc des tokens déjà résolus par le design system.

## 15. Risques résiduels

- La capture réelle desktop n'est pas prouvée.
- Le top chrome global de l'image de référence reste hors scope.
- Le flow central peut encore sembler plus long que la maquette à cause des vrais contrôles.
- `PokeMapButton` est une primitive partagée : le changement de font inheritance est volontairement petit, mais touche plusieurs surfaces potentielles.
- `packages/map_editor/pubspec.lock` reste un drift préexistant.

## 16. Prochain lot recommandé

```text
NS-EVENT-41 — Event Builder Full App Shell Capture & Top Chrome Alignment V0
```

Objectif recommandé :

- automatiser une capture desktop réelle ou full `EditorShellPage` ;
- comparer top toolbar, status bar, sidebar et Event Builder dans la même image ;
- décider si le top chrome doit être aligné sur la référence ou rester dans le style PokeMap actuel.

## 17. Evidence Pack

Fichiers modifiés :

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/design_system/pokemap_button.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

Fichier préexistant modifié hors scope :

```text
packages/map_editor/pubspec.lock
```

Fichiers créés :

```text
reports/narrativeStudio/events/screenshots/ns_event_40_event_builder_pixel_polish_v0.png
reports/narrativeStudio/events/screenshots/ns_event_40_event_builder_diagnostics_pixel_polish_v0.png
reports/narrativeStudio/events/ns_event_40_event_builder_shell_pixel_polish_visual_qa_v0.md
```

Contenu complet des fichiers créés :

- les deux captures sont des binaires PNG, non incluses inline ;
- le contenu complet du rapport est ce fichier Markdown.

Diff / zones précises :

```text
event_builder_workspace.dart:
- ajout des constantes de largeur/padding de shell ;
- ajout de _EventBuilderShellHeader ;
- remplacement du header + métriques séparées par un header compact ;
- ajustement des largeurs des quatre colonnes ;
- ajout de _ProjectedConsequencesBlock.stacked ;
- en-tête Scene outcomes verticalisé.

event_builder_central_flow.dart:
- padding réduit ;
- key event-builder-flow-connector ;
- connecteur compact.

event_builder_flow_blocks.dart:
- padding, icon sizes et espacements réduits.

event_builder_element_library.dart:
- layout item disponible inline ;
- layout read-only en colonne pour éviter overflow.

pokemap_button.dart:
- reprise du DefaultTextStyle hérité.

event_builder_workspace_test.dart:
- groupe NS-EVENT-40 ;
- assertions layout/garde-fous ;
- captures NS-EVENT-40 ;
- sous-titre NS-EVENT-04 mis à jour.
```

État git collecté avant création du rapport :

```text
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/lib/src/ui/design_system/pokemap_button.dart
 M packages/map_editor/pubspec.lock
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/screenshots/ns_event_40_event_builder_diagnostics_pixel_polish_v0.png
?? reports/narrativeStudio/events/screenshots/ns_event_40_event_builder_pixel_polish_v0.png
```

Diff stat avant création du rapport :

```text
 .../canvas/events/event_builder_central_flow.dart  |  29 +-
 .../events/event_builder_element_library.dart      |  63 ++--
 .../canvas/events/event_builder_flow_blocks.dart   |  22 +-
 .../ui/canvas/events/event_builder_workspace.dart  | 405 +++++++++++++--------
 .../lib/src/ui/design_system/pokemap_button.dart   |   4 +-
 packages/map_editor/pubspec.lock                   |  16 +-
 .../test/event_builder_workspace_test.dart         | 264 +++++++++++++-
 7 files changed, 596 insertions(+), 207 deletions(-)
```

`git diff --check` :

```text
<empty>
```

Gate final après création du rapport :

```text
Command: git status --short --untracked-files=all
Result:
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/lib/src/ui/design_system/pokemap_button.dart
 M packages/map_editor/pubspec.lock
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/ns_event_40_event_builder_shell_pixel_polish_visual_qa_v0.md
?? reports/narrativeStudio/events/screenshots/ns_event_40_event_builder_diagnostics_pixel_polish_v0.png
?? reports/narrativeStudio/events/screenshots/ns_event_40_event_builder_pixel_polish_v0.png

Command: git diff --stat
Result:
 .../canvas/events/event_builder_central_flow.dart  |  29 +-
 .../events/event_builder_element_library.dart      |  63 ++--
 .../canvas/events/event_builder_flow_blocks.dart   |  22 +-
 .../ui/canvas/events/event_builder_workspace.dart  | 405 +++++++++++++--------
 .../lib/src/ui/design_system/pokemap_button.dart   |   4 +-
 packages/map_editor/pubspec.lock                   |  16 +-
 .../test/event_builder_workspace_test.dart         | 264 +++++++++++++-
 7 files changed, 596 insertions(+), 207 deletions(-)

Command: git diff --name-only
Result:
packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/design_system/pokemap_button.dart
packages/map_editor/pubspec.lock
packages/map_editor/test/event_builder_workspace_test.dart

Command: git diff --check
Result:
<empty>

Command: git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_core examples assets selbrume pubspec.yaml
Result:
<empty>
```

## 18. Auto-review critique

Points positifs :

- le lot reste borné à `map_editor` ;
- le runtime et les packages métier ne sont pas touchés ;
- le nouveau polish est couvert par tests et Visual Gates ;
- les corrections de layout ont été validées contre NS-EVENT-38/36 après détection d'overflows ;
- la bibliothèque conserve les statuts read-only explicites.

Critiques :

- la modification de `PokeMapButton` est partagée et mérite surveillance, même si elle est faible et utile ;
- le flow central n'atteint pas le pixel-perfect de la référence ;
- les captures goldens restent des captures widget, pas une preuve desktop réelle ;
- deux captures sont nécessaires pour montrer Conséquences et Diagnostics, ce qui prouve que la densité n'est pas encore parfaite.

## 19. Critique du prompt

Le prompt est globalement cohérent avec NS-EVENT-39.

Limites détectées :

- il demande une capture desktop réelle "si possible", mais ne fournit pas de protocole d'ouverture projet / workspace / screenshot macOS ;
- il nomme une image `pokemap_rpg_event_editor_interface.png` absente de l'environnement ;
- il pousse vers une référence full-shell alors que le scope interdit de refaire tout `EditorChrome`.

Interprétation appliquée :

- utiliser la référence disponible fournie par l'utilisateur ;
- polir principalement Event Builder et le shell Narrative Studio visible ;
- documenter le top chrome global comme restant hors scope ;
- produire deux captures widget fiables plutôt que prétendre à une capture desktop réelle non automatisée.
