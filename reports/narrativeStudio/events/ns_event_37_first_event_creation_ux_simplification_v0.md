# NS-EVENT-37 - Event Builder First Event Creation UX Simplification V0

Date: 2026-07-08

Package concerne: `packages/map_editor`

Verdict First Event UX: PASS

## Resume executif

First Event UX: PASS.

Cause UX: le premier evenement melangeait plusieurs actions visibles ou implicites: bouton d'entete, empty state, panneau de creation, notion de brouillon, choix de couche technique et choix de position. Pour un utilisateur no-code qui arrive sur une map sans evenement, le chemin n'etait pas assez lineaire.

Correction: le premier parcours est maintenant guide par le panneau gauche en 3 etapes visibles: `1. Destination`, `2. Position`, `3. Creation`. Le bouton d'entete ne cree plus d'evenement; il sert seulement a rouvrir le panneau quand celui-ci est replie et que la map contient deja des evenements. L'empty state central renvoie vers le panneau gauche et ne propose plus de CTA concurrent.

Ce qui est prouve: les tests widget couvrent l'empty state sans CTA concurrent, la creation positive, l'absence de couche evenement, le choix explicite quand plusieurs couches objet existent, et la capture visuelle. Les regressions NS-EVENT-33 et NS-EVENT-36 restent vertes. `flutter analyze` et `flutter build macos --debug` passent.

Ce qui reste a prouver: une capture depuis l'application desktop reelle avec rendu police natif pourrait completer la capture golden, car le renderer golden remplace quelques glyphes de boutons par des blocs sombres dans le PNG. Les assertions widget prouvent toutefois que le texte `Créer l’événement` est bien present dans l'arbre.

Prochain lot recommande: NS-EVENT-38 - clarifier l'etape post-creation: une fois l'evenement cree et selectionne, guider l'utilisateur vers le titre, le declencheur, la scene et le comportement sans introduire de logique runtime.

Blockers: aucun blocker fonctionnel. Un drift non lie est present dans `packages/map_editor/pubspec.lock`; il n'a pas ete modifie volontairement par ce lot.

## Confirmation du scope

Scope demande et respecte:

- Editeur uniquement: `packages/map_editor`.
- UX de creation du premier evenement uniquement.
- Aucun changement runtime, gameplay, battle, core, exemples, assets Selbrume, `pubspec.yaml`, generation ou commit.
- Aucun `git add`, `git commit`, `git push`, `git stash`, `git reset`, `git restore`, `git checkout` ou autre operation Git ecrivant l'etat.
- Pas de `build_runner`.

Controle anti-scope:

```text
Command: git diff --name-only -- examples assets selbrume pubspec.yaml packages/map_core packages/map_gameplay packages/map_battle packages/map_runtime
Result: exit 0, no output
```

## Critique du prompt et continuite de lot

Le prompt etait globalement coherent pour un lot map_editor. La seule tension trouvee vient du rapport NS-EVENT-36, qui recommandait un prochain lot plutot oriente runtime/handoff, alors que la demande attachee definit explicitement NS-EVENT-37 comme une simplification UX du premier evenement. L'instruction directe utilisateur prime: j'ai donc traite NS-EVENT-37 comme lot UX editor-only.

Autres tensions:

- `codex_rule.md` demande beaucoup de commentaires utiles dans le code, tandis que les consignes globales demandent des commentaires succincts et rares. J'ai privilegie la lisibilite du code et documente les decisions dans ce rapport.
- Le plugin Product Design aurait pu conduire a un audit visuel plus large. Le prompt demandait une implementation locale avec preuves et screenshot; j'ai garde ce perimetre.
- Le prompt demandait des subagents; l'environnement les a permis. J'ai utilise 5 passes specialisees plus un reviewer contradictoire.

## Audit initial

Etat Git initial:

```text
Command: pwd
Result:
/Users/karim/Project/pokemonProject

Command: git branch --show-current
Result:
main

Command: git status --short --untracked-files=all
Result: no output

Command: git diff --stat
Result: no output

Command: git diff --name-only
Result: no output
```

Historique recent consulte:

```text
786e86da NS-EVENT-36: Event Builder Real App Manual Creation Availability Fix / Layer Gate UX - PASS
fb440ae8 NS-EVENT-35: Event Builder Trigger Variants Runtime Handoff / Lifecycle Semantics Gate - PARTIAL
3f96204e NS-EVENT-34: Event Builder Runtime Handoff Smoke / Editor-authored Scene Target Gate - PASS
0b180895 NS-EVENT-33: Event Builder MVP Closure / End-to-End Authoring Readiness Gate - DONE
25cdf062 NS-EVENT-32: Event Builder World Rules Projection UX Closure / Validation Gate - DONE
972c73ad NS-EVENT-31: Implement Passive World Rules Projection UI V0
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
26bec474 ns_event_12: Ajout des comportements pour les événements
00698aea ns_event_11: Ajout des actions de scène pour les événements
fc0e0be0 ns_event_10: Ajout de la saisie du titre pour les brouillons d'événements
```

Fichiers et contrats audites:

- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_creation_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`
- `packages/map_editor/test/event_builder_draft_creation_notifier_test.dart`
- `reports/narrativeStudio/events/ns_event_36_manual_creation_availability_gate.md`
- `reports/narrativeStudio/events/ns_event_33_event_builder_mvp_closure_readiness_gate.md`
- `codex_rule.md`

Aucun `AGENTS.md` plus proche n'existe sous `packages/map_editor`; les instructions racine s'appliquent.

Risques identifies:

- casser le flux NS-EVENT-36 de creation reelle sur couche objet;
- conserver deux CTA concurrents;
- exposer des termes techniques comme `draft`, `layerId` ou `brouillon` dans le parcours principal;
- ajouter des couleurs hardcodees dans l'UI editeur;
- toucher runtime/core ou des fichiers generes.

## Usage du MCP Dart

MCP Dart utilise comme demande:

```text
roots add file:///Users/karim/Project/pokemonProject/packages/map_editor
Result: Success
```

Symboles resolus via LSP:

- `NarrativeWorkspaceCanvas`
- `EventBuilderWorkspace`
- `EventBuilderDraftCreationGate`
- `_DraftPositionPickerPanel`
- `_DraftDestinationLayerPanel`
- `_EventBuilderEmptyState`
- `EventBuilderCreationPanel`
- `EditorNotifier`
- `EditorState`
- `ensureEventBuilderObjectLayer`
- `createEventBuilderDraftEventAt`

Diagnostic MCP final:

```text
Command: mcp__dart.analyze_files
Paths:
lib/src/ui/canvas/events/event_builder_workspace.dart
lib/src/ui/canvas/events/event_builder_creation_panel.dart
lib/src/features/editor/state/editor_notifier.dart
test/event_builder_workspace_test.dart
test/event_builder_draft_creation_notifier_test.dart

Result:
No errors
```

Le LSP expose la resolution de symboles, pas une commande de references complete dans cette session. Les references ont donc ete completees avec `rg`.

## Sous-agents et verdicts

Sub-agent 1 - Audit UX / Architecture: PASS. Le flux existant etait partiel: plusieurs actions ressemblant a une creation coexistaient. Recommandation: etapes Destination, Position, Creation.

Sub-agent 2 - Layout / Interaction: PASS. Option retenue: panneau gauche comme chemin primaire; l'entete sert seulement de raccourci d'ouverture quand le panneau est replie; l'empty state central reste informatif.

Sub-agent 3 - Design system: PASS. Les widgets existants du design system suffisent. Aucun nouveau `Colors.*` ou `Color(0x...)` ajoute; les tokens `context.pokeMapColors` restent la source couleur.

Sub-agent 4 - Tests: PASS. Les tests doivent verifier un CTA structurel, les cas sans couche, avec couche unique, avec plusieurs couches, et la capture visuelle.

Sub-agent 5 - Wording no-code: PASS. Le libelle principal devient `Créer l’événement`; la destination est presentee comme `Couche utilisée`, pas comme identifiant technique; `draft/brouillon` disparait du chemin principal.

Reviewer contradictoire: PASS avec reserves. La contradiction NS-EVENT-36/runtime vs prompt UX-only est tranchee par la demande directe. Le reviewer demande de signaler la limite de capture visuelle golden, faite ici.

## Decision UX finale

Decision: un seul chemin primaire pour le premier evenement.

Avant:

- bouton d'entete `Nouvel événement` pouvant etre percu comme l'action principale;
- empty state central avec action concurrente ou wording ambigu selon etat;
- panneau de creation melangeant preparation, couche, position et creation;
- terme `brouillon` visible dans plusieurs endroits.

Apres:

- panneau gauche toujours visible pour le premier evenement;
- etapes numerotees: `1. Destination`, `2. Position`, `3. Création`;
- CTA final unique: `Créer l’événement`;
- empty state central sans bouton concurrent;
- bouton d'entete seulement si la liste contient deja des evenements et que le panneau est replie, avec libelle `Préparer un événement`.

## Fichiers modifies par ce lot

### `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`

Zones modifiees:

- Lignes 265 et 317-325: `showCreationShortcut` limite le bouton d'entete aux maps non vides avec panneau replie. Le bouton ouvre le panneau et ne cree plus directement.
- Lignes 571-622: composition du panneau de creation en trois etapes guidees.
- Lignes 665-673: wording de succes/echec remplace `brouillon` par `événement`.
- Lignes 733-749: empty state central informe et renvoie vers le panneau gauche, sans CTA concurrent.
- Lignes 849-951: destination clarifiee avec `Couche utilisée`, creation de couche quand aucune couche objet n'existe, choix explicite quand plusieurs couches existent.
- Lignes 954-1058: position clarifiee avec `Aucune position choisie` et `Position choisie : x N, y N`; cellules grille accessibles via semantics `Case x N, y N`.
- Lignes 1060-1100: nouveau panneau final `_DraftCreationActionPanel` avec CTA `Créer l’événement`.

Impact attendu: le premier utilisateur suit une sequence lineaire: choisir ou placer l'evenement, choisir la case, creer. Le flux NS-EVENT-36 conserve la creation de couche objet et la selection d'une couche destination.

### `packages/map_editor/lib/src/ui/canvas/events/event_builder_creation_panel.dart`

Zones modifiees:

- Lignes 56-58: helper du panneau: `Choisissez la destination, la position, puis créez l’événement.`
- Lignes 70-84: le bouton de repli/preparation n'est plus rendu quand `onToggle == null`, ce qui evite un controle inutile dans le premier parcours toujours ouvert.

Impact attendu: moins de bruit dans le panneau primaire et wording aligne avec le parcours en trois etapes.

### `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`

Zones modifiees:

- Lignes 2813 et 2818: messages d'etat/echec `Événement créé` et `Impossible de créer l’événement : ...`.

Impact attendu: la notification utilisateur ne parle plus de brouillon apres creation via Event Builder. Le nom interne `createEventBuilderDraftEventAt` et le titre par defaut `Nouvel événement` restent inchanges pour eviter un changement de contrat hors scope.

### `packages/map_editor/test/event_builder_workspace_test.dart`

Zones modifiees:

- Lignes 776-1012: nouveau groupe `NS-EVENT-37 first-event creation UX`.
- Tests ajoutes:
  - `empty state points to the creation panel without competing CTA`
  - `guided creation flow creates and selects a draft`
  - `missing event layer exposes one clear preparation action`
  - `multiple event layers use an explicit destination choice`
  - `captures first event creation UX visual gate`
- Attentes existantes NS-EVENT-04/07/08/09/16/33/36 ajustees au nouveau wording et au CTA final du panneau.

Impact attendu: couverture positive, negative, garde-fous CTA, non-regressions NS-EVENT-33/36, et screenshot.

### `packages/map_editor/test/event_builder_draft_creation_notifier_test.dart`

Zone modifiee:

- Ligne 53: attente de statut mise a jour vers `Événement créé`.

Impact attendu: les tests state/notifier restent alignes avec le nouveau wording utilisateur.

## Fichiers crees

### `reports/narrativeStudio/events/screenshots/ns_event_37_first_event_creation_ux_simplification_v0.png`

Fichier binaire PNG cree par la capture golden.

Metadonnees:

```text
reports/narrativeStudio/events/screenshots/ns_event_37_first_event_creation_ux_simplification_v0.png: PNG image data, 1440 x 1100, 8-bit/color RGBA, non-interlaced
-rw-r--r--  1 karim  staff   108K Jul  8 14:45 reports/narrativeStudio/events/screenshots/ns_event_37_first_event_creation_ux_simplification_v0.png
```

Contenu visuel: panneau gauche `Créer un événement`, etapes `1. Destination`, `2. Position`, `3. Création`, destination `Couche utilisée : Événements`, position `x 2, y 1`, empty state central sans CTA.

Limite de capture: le renderer golden montre quelques glyphes de boutons sous forme de blocs sombres. Les assertions widget de la meme capture verifient bien `Créer l’événement` avant ecriture du PNG.

### `reports/narrativeStudio/events/ns_event_37_first_event_creation_ux_simplification_v0.md`

Ce rapport est le contenu complet du fichier texte cree.

## Tests ajoutes ou modifies

Tests ajoutes sous NS-EVENT-37:

- cas positif: couche unique existante, position choisie, evenement cree et selectionne;
- cas negatif/garde-fou: aucun CTA concurrent en empty state, bouton final disabled tant que la position manque;
- cas preparation: map sans couche objet, une seule action claire pour creer la couche `Événements`;
- cas destination explicite: plusieurs couches objet, choix obligatoire avant position;
- non-regression visuelle: capture golden du premier parcours.

Tests modifies:

- attentes de wording dans `event_builder_workspace_test.dart`;
- attente de statut dans `event_builder_draft_creation_notifier_test.dart`.

## Validations executees

### TDD RED

```text
Command: cd packages/map_editor && flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-37"
Result: exit 1
Signal: 4 tests echouent comme attendu avant implementation, car les libelles/etapes/CTA NS-EVENT-37 n'existent pas encore.
```

### Capture visuelle

Premiere execution sans mise a jour golden:

```text
Command: flutter test --reporter=compact test/event_builder_workspace_test.dart --name "captures first event creation UX visual gate" --dart-define=NS_EVENT_37_CAPTURE_WORKSPACE=true
Result: exit 1
Signal: Could not be compared against non-existent file ...ns_event_37_first_event_creation_ux_simplification_v0.png
```

Ecriture de la capture:

```text
Command: flutter test --update-goldens --reporter=compact test/event_builder_workspace_test.dart --name "captures first event creation UX visual gate" --dart-define=NS_EVENT_37_CAPTURE_WORKSPACE=true
Result: exit 0
Final line: +1: All tests passed!
```

### Tests cibles finaux

```text
Command: flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-37"
Result: exit 0
Final line: 00:04 +5: All tests passed!
```

```text
Command: flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-36"
Result: exit 0
Final line: 00:04 +5: All tests passed!
```

```text
Command: flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-33"
Result: exit 0
Final line: 00:04 +4: All tests passed!
```

```text
Command: flutter test --reporter=compact test/event_builder_draft_creation_notifier_test.dart
Result: exit 0
Final line: 00:01 +28: All tests passed!
```

Suite fichier workspace:

```text
Command: flutter test --reporter=compact test/event_builder_workspace_test.dart
Result: exit 0
Final line: 00:13 +111: All tests passed!
Note: sortie console longue tronquee par l'interface, mais exit code 0 et ligne finale capturee.
```

### Analyse

```text
Command: flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/events/event_builder_workspace.dart lib/src/ui/canvas/events/event_builder_creation_panel.dart lib/src/features/editor/state/editor_notifier.dart test/event_builder_workspace_test.dart test/event_builder_draft_creation_notifier_test.dart
Result:
Analyzing 6 items...
No issues found! (ran in 8.7s)
```

```text
Command: rg -n "Color\(0x|Colors\." lib/src/ui/canvas/events/event_builder_workspace.dart lib/src/ui/canvas/events/event_builder_creation_panel.dart lib/src/features/editor/state/editor_notifier.dart test/event_builder_workspace_test.dart test/event_builder_draft_creation_notifier_test.dart
Result:
lib/src/ui/canvas/events/event_builder_workspace.dart:1158:            color: toneColors.icon,
lib/src/ui/canvas/events/event_builder_workspace.dart:3705:          color: toneColors.soft,
lib/src/ui/canvas/events/event_builder_workspace.dart:3707:          border: Border.all(color: toneColors.border),
lib/src/ui/canvas/events/event_builder_workspace.dart:3713:            Icon(CupertinoIcons.info_circle, size: 15, color: toneColors.icon),
Interpretation: aucun `Colors.*` ni `Color(0x...)`; les matches viennent de `toneColors`.
```

### Build

```text
Command: flutter build macos --debug
Result:
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

### Checks Git et scope

```text
Command: git diff --check
Result: exit 0, no output
```

```text
Command: git diff --name-only -- examples assets selbrume pubspec.yaml packages/map_core packages/map_gameplay packages/map_battle packages/map_runtime
Result: exit 0, no output
```

### Incident non final

Une tentative de tests Flutter en parallele a echoue a cause du verrou de demarrage/native assets:

```text
Waiting for another flutter command to release the startup lock...
Failed to code sign binary: exit code: 1 ... build/native_assets/macos/objective_c.dylib: No such file or directory
```

Interpretation: incident d'orchestration des commandes paralleles, non lie au code. Les memes tests ont ensuite ete relances sequentiellement et passent.

## Etat Git final verifie

```text
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_creation_panel.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/pubspec.lock
 M packages/map_editor/test/event_builder_draft_creation_notifier_test.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/ns_event_37_first_event_creation_ux_simplification_v0.md
?? reports/narrativeStudio/events/screenshots/ns_event_37_first_event_creation_ux_simplification_v0.png
```

Note: `packages/map_editor/pubspec.lock` contient un drift de versions transitive (`matcher`, `meta`, `test_api`, `vector_math`) apparu apres l'audit initial. Il n'a pas ete edite volontairement et n'appartient pas au lot.

Diff lockfile observe:

```text
matcher 0.12.19 -> 0.12.20
meta 1.18.0 -> 1.18.3
test_api 0.7.11 -> 0.7.12
vector_math 2.2.0 -> 2.4.0
```

## Non-objectifs respectes

- Pas de runtime handoff.
- Pas de gameplay/core/battle.
- Pas de schema model.
- Pas de migration.
- Pas de generation.
- Pas de refactor design-system.
- Pas de changement du titre interne par defaut `Nouvel événement`.
- Pas de renommage de l'API interne `createEventBuilderDraftEventAt`.

## Risques residuels

- Le code contient encore des noms internes historiques avec `Draft`; ils sont hors UI principale et conserves pour limiter le blast radius.
- La capture golden a un rendu imparfait des glyphes de certains boutons; les tests structurels compensent ce risque.
- Le drift `pubspec.lock` doit etre decide separement: conserver si accepte par l'equipe, ou restaurer explicitement dans un lot dedie si l'utilisateur le demande.

## Auto-critique finale

Ce lot est suffisamment petit et prouve par tests. La principale faiblesse est la capture golden imparfaite, mais le screenshot montre bien la structure du flux et les assertions widget prouvent les libelles critiques. La seconde faiblesse est le lockfile modifie hors scope; je ne l'ai pas restaure car les instructions Git interdisent les operations destructrices ou de restauration sans demande explicite, et la modification n'est pas necessaire au lot.

Le comportement ne ment pas sur le runtime: il dit seulement qu'un evenement editeur est cree et selectionne. Aucun support runtime non prouve n'est annonce.

## Verdict

First Event UX: PASS.

Le parcours du premier evenement a maintenant une source d'action unique, un ordre visible, des libelles no-code et des preuves de non-regression sur les lots voisins NS-EVENT-33 et NS-EVENT-36.
