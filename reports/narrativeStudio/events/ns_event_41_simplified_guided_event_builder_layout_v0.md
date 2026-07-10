# NS-EVENT-41 — Event Builder Simplified Guided Configuration Layout V0

Date : 2026-07-09

Repo : `/Users/karim/Project/pokemonProject`

Package concerne : `packages/map_editor`

## 1. Resume executif

Simplified Guided Layout : PASS avec reserve de densite.

Charge cognitive : reduite.

Ce qui a ete simplifie :

- suppression de la colonne permanente `Bibliotheque d'elements` / Actions rapides ;
- passage a 3 zones principales : liste, configuration guidee centrale, inspecteur resume ;
- ajout d'un stepper horizontal `Position choisie / Declencheur / Conditions / Action / Comportement` ;
- transformation du flow central en sections de configuration numerotees ;
- consequences, regles et diagnostics resumes par defaut ;
- inspecteur reduit aux faits utiles no-code ;
- details historiques de Scene outcomes / World Rules gardes en lecture seule mais retires du parcours principal.

Ce qui reste complexe :

- a `1680 x 980`, la Visual Gate montre encore un scroll central : les sections sont lisibles et ordonnees, mais tout le detail des 5 sections ne tient pas entierement dans une seule capture ;
- les glyphes d'icones Flutter golden restent rendus comme carres dans certaines captures, comme sur les lots precedents ;
- le shell global superieur exact de l'image n'a pas ete refait.

Prochain lot recommande : `NS-EVENT-42 — Event Builder Full-Viewport Density & Section Collapse Polish V0`.

Blockers : aucun.

## 2. Image de reference utilisee

Image prioritaire fournie par l'utilisateur :

```text
/Users/karim/Downloads/ChatGPT Image Jul 9, 2026, 02_43_45 PM.png
```

Inspection locale :

```text
PNG image data, 1672 x 941, 8-bit/color RGB, non-interlaced
```

Le prompt nomme `pokemap_event_builder_ui_design.png`. Ce nom n'existe pas comme fichier dans le workspace, mais l'image jointe ci-dessus etait accessible et a ete utilisee comme reference reelle.

Signaux retenus :

- 3 zones principales apres la sidebar : evenements, configuration guidee, inspecteur ;
- pas de colonne bibliotheque permanente ;
- stepper horizontal visible ;
- sections `Declencheur`, `Conditions`, `Action principale`, `Comportement`, `Consequences projetees` ;
- inspecteur compact ;
- consequences et diagnostics resumes.

## 3. Observation utilisateur

Apres NS-EVENT-40, l'Event Builder etait plus proche d'un flow-based editor, mais l'ecran restait trop charge :

- trop de colonnes visibles ;
- bibliotheque / actions rapides en pilier visuel permanent ;
- flow central trop long ;
- consequences, diagnostics et projections trop detailles ;
- inspecteur encore massif ;
- utilisateur force a scanner une architecture plutot qu'un assistant.

NS-EVENT-41 repond en priorisant la configuration guidee d'un evenement selectionne.

## 4. Usage du MCP Dart

MCP Dart utilise partiellement.

Action realisee avant implementation :

```text
mcp__dart.roots add file:///Users/karim/Project/pokemonProject/packages/map_editor
Result: Success
```

Limite constatee : dans cette session, seul l'outil `roots` etait disponible cote MCP Dart. Les inspections de symboles plus fines ont donc ete compensees par `rg`, lectures de fichiers, tests Flutter et `flutter analyze`.

## 5. Sous-agents / passes utilisees

Sous-agents reels utilises en lecture/audit :

| Passe | Type | Verdict | Synthese |
|---|---|---|---|
| A — UX Simplification Reviewer | Sous-agent reel Hypatia | PASS avec reserve | A confirme que la bibliotheque permanente et les projections detaillees entretenaient l'effet cockpit. |
| B — Information Architecture Reviewer | Sous-agent reel Sagan | PASS | A recommande le layout 3 zones, la configuration centrale prioritaire et l'inspecteur compact. |
| C — Flutter Layout / Overflow Reviewer | Sous-agent reel Sagan | PARTIAL | A signale le risque de hauteur du flow central et la necessite de verifier les captures. |
| D — Design System Reviewer | Sous-agent reel Bernoulli | PASS | A confirme la contrainte tokens/primitives PokeMap et l'absence de bricolage couleur. |
| E — Tests / Golden Reviewer | Sous-agent reel Bernoulli | PASS | A recommande les assertions NS-EVENT-41 et la Visual Gate dediee. |
| F — Scope Reviewer | Sous-agent reel Bernoulli | PASS | A refuse runtime, map_core, gameplay, battle, Event-owned outcomes/reactions, World Rule editor, drag/drop. |
| G — Orchestrateur | Codex principal | PASS | A implemente, migre les tests, valide, build et documente. |

## 6. Audit UX initial

Gate 0 exact avant modification :

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
88314c22 NS-EVENT-40: Event Builder Shell-Level Pixel Polish & Real App Visual QA V0
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
```

Drift preexistant :

```text
packages/map_editor/pubspec.lock
```

Il n'a pas ete revendique ni volontairement modifie par ce lot.

Grille d'audit UX :

| Zone | Etat NS-EVENT-40 | Probleme utilisateur | Nouvelle cible NS-EVENT-41 | Action | Statut final |
|---|---|---|---|---|---|
| Actions rapides / bibliotheque | Colonne permanente | Bruit visuel | Contextuel / absent | Colonne retiree | PASS |
| Liste evenements | Presente, compacte | OK mais plus etroite que cible | Colonne gauche ~300 px | Largeur liste 300 | PASS |
| Configuration centrale | Flow long avec details | Tunnel d'informations | Assistant de configuration | Stepper + sections | PASS |
| Checklist d'avancement | Absente | Prochain geste peu clair | Stepper visible | `_GuidedConfigurationStepper` | PASS |
| Declencheur | Details Type/Source + boutons | Trop redondant | Choix direct | Details techniques retires | PASS |
| Conditions | Details et actions | Lisible mais haut | Section simple | Boutons contextuels | PASS |
| Action principale | Controle dans flow | OK mais haut | Section guidee | Bouton `Modifier`, picker local | PASS |
| Comportement | Section separee tardive | Souvent hors ecran | Etape explicite | Bloc principal 4 | PASS |
| Consequences projetees | Detail sources/regles | Trop lourd | Resume compact | 3 mini cards | PASS |
| Diagnostics | Bloc dedie | Anxiogene | Resume integre | Tuile diagnostic | PASS |
| Inspecteur | Factuel mais massif | Repete trop | Resume court | ID/Cible/Portee retires | PASS |
| Scroll global | Central long | Tunnel partiel | Moins haut | Densite reduite | PARTIAL |
| Densite generale | 4 colonnes | Bordelique | 3 zones | Bibliotheque retiree | PASS |

Pourquoi l'ecran etait trop complexe : il exposait en meme temps le catalogue d'elements, le builder, les projections detaillees et l'inspecteur. L'utilisateur voyait l'architecture interne avant le prochain geste.

Informations masquees ou resumees : IDs techniques, cible/portee du declencheur, details Scene outcomes, details World Rules, diagnostics detailles, bibliotheque permanente.

Prochain geste utilisateur : choisir ou modifier une section centrale, ou creer un evenement depuis la liste ; les boutons contextuels remplacent le catalogue permanent.

## 7. Decision d'architecture d'information

Decision livree :

```text
[Sidebar Narrative Studio]
[Liste d'evenements]
[Configurer l'evenement]
[Inspecteur d'evenement compact]
```

La bibliotheque reste dans le code (`EventBuilderElementLibrary`) pour compatibilite, mais elle n'est plus montee comme colonne permanente dans `EventBuilderWorkspace`.

Les anciennes actions de bibliotheque sont remplacees par des actions locales :

- `Ajouter une condition Fact` ;
- `Ajouter une condition d'evenement` ;
- `Choisir / Changer la scene` ;
- boutons de type de declencheur ;
- boutons de comportement.

## 8. Ce qui est rendu visible / resume / replie

Visible :

- liste d'evenements ;
- carte evenement selectionnee ;
- stepper horizontal ;
- sections `Declencheur`, `Conditions`, `Action principale`, `Comportement`, `Consequences projetees` ;
- inspecteur compact ;
- CTA `Preparer un evenement` ;
- creation d'evenement en bas de liste.

Resume :

- sources projetees ;
- regles monde liees ;
- diagnostics ;
- details de Scene outcomes ;
- legacy diagnostics.

Replie / contextuel :

- bibliotheque d'elements ;
- choix de Facts ;
- choix d'evenements consommés ;
- choix de scene ;
- details World Rules.

## 9. Corrections UI appliquees

### `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`

Zones modifiees :

- constantes de layout : liste 300 px, inspecteur 320 px, suppression des largeurs bibliotheque ;
- body principal : keys `event-builder-simplified-*`, suppression de `EventBuilderElementLibrary` comme colonne ;
- nouveau `_GuidedConfigurationStepper` et `_GuidedStepperTile` ;
- `_EventDetailsPanel` renomme visuellement en `Configurer l'evenement` ;
- sections centrales reorganisees avec `Declencheur`, `Conditions`, `Action principale`, `Comportement`, `Consequences projetees` ;
- details Type/Source retires du declencheur pour eviter le doublon ;
- `_GuidedProjectedConsequencesSummary` ajoute ;
- suppression des anciens blocs de projection detaillee du parcours principal ;
- empty state condition renomme sans mention de bibliotheque ;
- actions contextuelles conservees.

Impact attendu :

- 3 zones au lieu de 4 ;
- moins de charge cognitive ;
- parcours de configuration plus evident ;
- aucun changement de contrat metier.

### `packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart`

Zones modifiees :

- header et eventHeader fixes dans le panneau ;
- seuls les blocs centraux scrollent ;
- connecteurs reduits de 18 px a 12 px.

Impact attendu :

- stepper et titre restent visibles ;
- reduction du tunnel vertical.

### `packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart`

Zones modifiees :

- ajout des champs `description` et `trailing` ;
- bouton `Modifier` possible a droite ;
- padding et icones compactes.

Impact attendu :

- sections plus proches de l'image simplifiee ;
- actions locales sans colonne bibliotheque.

### `packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart`

Zones modifiees :

- retrait de `ID technique`, `Cible`, `Portee`, `Issues de la scene`, `Changements du monde`, `Regles concernees` comme gros libelles ;
- maintien de `Nom`, `Statut`, `Type de declencheur`, `Scene liee`, `Comportement`, `Conditions`, `Position sur la carte` ;
- ajout d'un resume compact `Resume projete` / `Regles liees`.

Impact attendu :

- inspecteur vraiment secondaire ;
- moins de repetition avec la configuration centrale.

### `packages/map_editor/test/event_builder_workspace_test.dart`

Zones modifiees :

- ajout du groupe `NS-EVENT-41 simplified guided configuration layout` ;
- adaptation des tests NS-EVENT-40/39/38/36/33 ;
- adaptation prudente des tests historiques NS-EVENT-04/05/10-28/31/32 pour ne plus exiger l'ancien cockpit ;
- maintien des tests comportementaux de creation, conditions, scene, reuse policy, trigger et guardrails.

Impact attendu :

- tests alignes avec la nouvelle IA ;
- conservation des garanties metier.

## 10. Comparaison NS-EVENT-40 vs image simplifiee vs NS-EVENT-41

| Zone | NS-EVENT-40 | Image simplifiee | NS-EVENT-41 |
|---|---|---|---|
| Colonnes | 4 colonnes | 3 zones apres sidebar | 3 zones livrees |
| Bibliotheque | Permanente | Absente | Absente comme colonne |
| Stepper | Absent | Visible | Visible |
| Central | Flow long | Assistant | Assistant avec scroll central |
| Consequences | Details/grille | Resume | Resume compact |
| Diagnostics | Bloc fort | Tuile compacte | Tuile compacte |
| Inspecteur | Factuel mais dense | Compact | Compact |
| Densite | Mieux que NS39 mais charge | Claire | Reduite, reserve hauteur |

## 11. Tests ajoutes / modifies

Ajoute :

```text
NS-EVENT-41 simplified guided configuration layout renders simplified three-zone event builder layout
NS-EVENT-41 simplified guided configuration layout renders guided configuration stepper
NS-EVENT-41 simplified guided configuration layout renders compact main sections without cockpit overflow
NS-EVENT-41 simplified guided configuration layout keeps projected consequences compact and read-only
NS-EVENT-41 simplified guided configuration layout keeps inspector summary compact
NS-EVENT-41 simplified guided configuration layout keeps map placement creation flow working
NS-EVENT-41 simplified guided configuration layout keeps forbidden authoring absent
NS-EVENT-41 simplified guided configuration layout captures simplified guided layout visual gate
```

Modifie :

- tests NS-EVENT-40/39 : layout simplifie successeur au lieu de 4 colonnes ;
- tests NS-EVENT-38/36/33 : guided stepper et inspecteur compact ;
- tests NS-EVENT-04/05/10-28/31/32 : retrait des attentes sur ID technique, bibliotheque permanente, outcomes/regles detaillees et diagnostics longs.

## 12. Visual Gate

Capture creee :

```text
reports/narrativeStudio/events/screenshots/ns_event_41_simplified_guided_event_builder_v0.png
```

Inspection locale :

```text
PNG image data, 1680 x 980, 8-bit/color RGBA, non-interlaced
```

Ce que la capture prouve :

- pas de colonne Actions rapides / Bibliotheque permanente ;
- liste evenements a gauche ;
- configuration guidee centrale ;
- stepper visible ;
- inspecteur resume a droite ;
- consequences et diagnostics compactes dans l'inspecteur et le flow.

Reserve visuelle : la capture montre le haut du flow et le debut de `Comportement`; `Consequences projetees` reste accessible par scroll central. La structure est simplifiee, mais la densite full-viewport merite un lot de polish si l'objectif devient "les 5 sections entierement visibles sans aucun scroll" sur 1680x980.

## 13. Validations executees

Tests cibles :

```text
Command:
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-41"

Result:
+8 All tests passed!
```

Regressions :

```text
Command:
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-40"
Result:
+7 All tests passed!

Command:
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-39"
Result:
+7 All tests passed!

Command:
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-38"
Result:
+6 All tests passed!

Command:
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-37"
Result:
+5 All tests passed!

Command:
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-36"
Result:
+5 All tests passed!

Command:
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-33"
Result:
+4 All tests passed!
```

Suites completes :

```text
Command:
flutter test --reporter=compact test/event_builder_workspace_test.dart

Result:
+139 All tests passed!

Command:
flutter test --reporter=compact test/event_builder_draft_creation_notifier_test.dart

Result:
+28 All tests passed!
```

Visual Gate :

```text
Command:
flutter test --update-goldens --reporter=compact --dart-define=NS_EVENT_41_CAPTURE_WORKSPACE=true test/event_builder_workspace_test.dart --name "NS-EVENT-41 simplified guided configuration layout captures simplified guided layout visual gate"

Result:
+1 All tests passed!
```

Analyse ciblee :

```text
Command:
flutter analyze --no-fatal-infos \
  lib/src/ui/canvas/events/event_builder_workspace.dart \
  lib/src/ui/canvas/events/event_builder_central_flow.dart \
  lib/src/ui/canvas/events/event_builder_element_library.dart \
  lib/src/ui/canvas/events/event_builder_inspector_panel.dart \
  lib/src/ui/canvas/events/event_builder_creation_panel.dart \
  lib/src/ui/canvas/events/event_builder_flow_blocks.dart \
  test/event_builder_workspace_test.dart \
  test/event_builder_draft_creation_notifier_test.dart

Result:
Analyzing 8 items...
No issues found! (ran in 3.2s)
```

Build :

```text
Command:
flutter build macos --debug

Result:
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 14. Verdict Simplified Guided Layout

Verdict Simplified Guided Layout : PASS avec reserve de densite.

Justification :

- la bibliotheque permanente est retiree ;
- le layout est bien en 3 zones ;
- la configuration centrale est guidee ;
- le stepper reste visible ;
- les consequences et diagnostics sont resumes ;
- l'inspecteur est compact ;
- le flux de placement carte reste teste ;
- aucun runtime/core/gameplay/battle n'a ete modifie.

Reserve : le flow central peut encore necessiter un scroll pour voir toutes les sections a 1680x980. Le tunnel est reduit, pas totalement elimine.

## 15. Non-objectifs respectes

Non modifies :

```text
packages/map_core/**
packages/map_runtime/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
assets/**
selbrume/**
pubspec.yaml
generated files
```

Non ajoutes :

- Event-owned outcomes ;
- Event-owned reactions ;
- World Rule editor ;
- runtime simulation ;
- drag/drop fonctionnel ;
- nouveau modele map_core ;
- nouveau SceneConsequenceKind.

## 16. Risques residuels

- Densite centrale : `Comportement` et `Consequences projetees` ne sont pas entierement visibles ensemble dans la Visual Gate 1680x980.
- Golden font/icons : certains glyphes apparaissent comme carres en capture Flutter.
- La bibliotheque reste dans le code mais n'est plus exposee dans ce layout ; un futur menu secondaire pourrait clarifier son acces.
- Les tests historiques ont ete migres vers le resume compact ; ils ne prouvent plus les details visibles de Scene outcomes/World Rules dans le parcours principal, volontairement hors cible NS-EVENT-41.

## 17. Prochain lot recommande

```text
NS-EVENT-42 — Event Builder Full-Viewport Density & Section Collapse Polish V0
```

Objectif recommande :

- rendre les 5 sections entierement visibles ou quasi visibles sur 1680x980 ;
- ajouter un detail secondaire clair (`Voir le detail`) si necessaire ;
- traiter les glyphes golden si la capture doit devenir pixel QA stricte ;
- eventuellement offrir un menu secondaire pour la bibliotheque sans redevenir une colonne permanente.

## 18. Evidence Pack

Fichiers modifies :

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

Fichiers crees :

```text
reports/narrativeStudio/events/screenshots/ns_event_41_simplified_guided_event_builder_v0.png
reports/narrativeStudio/events/ns_event_41_simplified_guided_event_builder_layout_v0.md
```

Fichier preexistant non revendique :

```text
packages/map_editor/pubspec.lock
```

Diff stat avant creation de ce rapport :

```text
 packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart | 107 +-
 packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart  |  34 +-
 packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart | 74 +-
 packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart | 1362 +++++---------------
 packages/map_editor/pubspec.lock | 16 +-
 packages/map_editor/test/event_builder_workspace_test.dart | 1111 +++++++++-------
 6 files changed, 1084 insertions(+), 1620 deletions(-)
```

Zones de diff principales :

- `event_builder_workspace.dart` : retrait colonne bibliotheque, stepper, sections guidees, resume consequences, retrait details techniques.
- `event_builder_central_flow.dart` : header fixe, scroll interne, connecteurs compactes.
- `event_builder_flow_blocks.dart` : descriptions, trailing `Modifier`, densite reduite.
- `event_builder_inspector_panel.dart` : inspecteur resume.
- `event_builder_workspace_test.dart` : groupe NS-EVENT-41 et migration des attentes historiques.

Contenu complet des fichiers crees :

- ce rapport est le contenu complet de `reports/narrativeStudio/events/ns_event_41_simplified_guided_event_builder_layout_v0.md` ;
- le PNG `ns_event_41_simplified_guided_event_builder_v0.png` est un artefact binaire de 1680 x 980 et n'est pas inline dans ce Markdown.

Gate final exact apres creation du rapport :

```text
Command:
git status --short --untracked-files=all

Result:
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/pubspec.lock
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/ns_event_41_simplified_guided_event_builder_layout_v0.md
?? reports/narrativeStudio/events/screenshots/ns_event_41_simplified_guided_event_builder_v0.png
```

```text
Command:
git diff --stat

Result:
 .../canvas/events/event_builder_central_flow.dart  |  107 +-
 .../canvas/events/event_builder_flow_blocks.dart   |   34 +-
 .../events/event_builder_inspector_panel.dart      |   74 +-
 .../ui/canvas/events/event_builder_workspace.dart  | 1362 +++++---------------
 packages/map_editor/pubspec.lock                   |   16 +-
 .../test/event_builder_workspace_test.dart         | 1111 +++++++++-------
 6 files changed, 1084 insertions(+), 1620 deletions(-)
```

```text
Command:
git diff --name-only

Result:
packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/pubspec.lock
packages/map_editor/test/event_builder_workspace_test.dart
```

```text
Command:
git diff --check

Result:
<empty>

Command:
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_core examples assets selbrume pubspec.yaml

Result:
<empty>
```

## 19. Auto-review critique

Points positifs :

- scope respecte : `packages/map_editor` uniquement plus rapports/capture ;
- aucune derive runtime/metier ;
- bibliotheque permanente retiree ;
- tests NS-EVENT-41 et regressions passent ;
- build macOS debug passe ;
- design system conserve.

Points critiques :

- le prompt demandait idealement des sections visibles sans tunnel ; la solution reduit fortement le tunnel mais ne l'annule pas completement a 1680x980 ;
- les tests historiques ont ete adaptes a l'absence de details visibles, ce qui est coherent UX mais reduit la couverture de rendu detaille dans le parcours principal ;
- la capture golden garde des glyphes carres ;
- `pubspec.lock` reste en drift preexistant dans le working tree.

## 20. Critique du prompt

Le prompt est coherent avec NS-EVENT-40 et avec l'observation utilisateur.

Points de tension detectes :

- il demande "sections principales visibles sans tunnel" tout en conservant de vrais controles no-code dans chaque section. Dans l'UI Flutter actuelle, les 5 sections entierement developpees ne tiennent pas toutes dans 980 px de hauteur sans soit replier des details, soit ajouter un comportement de collapse plus explicite.
- il nomme `pokemap_event_builder_ui_design.png`, mais le fichier accessible est l'image jointe `/Users/karim/Downloads/ChatGPT Image Jul 9, 2026, 02_43_45 PM.png`.
- le skill `product-design:image-to-code` recommande normalement un prototype frontend autonome et un `design-qa.md`; cette exigence a ete adaptee au contexte repo, car le lot demande explicitement une implementation Flutter existante, un rapport NS-EVENT et une Visual Gate.

Interpretation appliquee :

- implementation directe dans `packages/map_editor` ;
- rapport NS-EVENT comme artefact de QA ;
- pas de prototype separe ;
- verdict PASS avec reserve sur la densite full-viewport.
