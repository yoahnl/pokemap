# NS-EVENT-18 - Creation Panel Compact / Collapsible V0

## 1. Resume executif

NS-EVENT-18 est DONE.

Le lot rend le panneau de creation d'evenement secondaire et repliable quand un event existe deja. La grille de position reste disponible pour le flux V0 de creation, mais elle n'occupe plus le centre de l'Event Builder par defaut. Cela aligne l'ecran sur la trajectoire NS-EVENT-17 : preparer une structure liste + builder central + inspecteur, sans continuer a empiler la grille de position dans le flux principal.

Comportement livre :

- quand aucun event n'existe, le panneau de creation reste deploye pour permettre de creer le premier brouillon ;
- quand un event est selectionne, le panneau "Creer un evenement" est compact ;
- le bouton "Nouvel evenement" ouvre le panneau si aucune position n'est encore choisie ;
- la grille de position n'apparait qu'apres demande explicite de preparation ;
- apres creation d'un brouillon, le panneau se replie et l'event cree reste selectionne ;
- aucun trigger, condition, action, behavior, outcome, reaction ou world rule n'est ouvert dans ce lot.

## 2. Decision produit

La grille de position est conservee comme outil V0 temporaire. Elle sert a choisir une position explicite avant creation d'un brouillon. Elle ne devient pas le builder principal.

Decision UX :

- la creation est encapsulee dans un panneau "Creer un evenement" ;
- la grille est masquee tant que l'utilisateur ne prepare pas une creation ;
- l'event selectionne et ses blocs restent la surface principale ;
- la prochaine etape doit travailler le builder central, pas ajouter encore plus de controles dans la grille.

## 3. Audit initial

Regles lues pendant la sequence :

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- skill product-design `image-to-code`
- skill product-design `get-context`
- skill superpowers `executing-plans`
- skill superpowers `test-driven-development`

Gate 0 initial conserve :

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main
```

Changements preexistants identifies avant NS-EVENT-18 :

```text
?? reports/narrativeStudio/events/ns_event_17_target_layout_alignment_plan.md
?? reports/narrativeStudio/events/ns_event_v1_drag_drop_detailed_lot_plan.md
```

Ces deux rapports etaient deja non suivis avant les modifications NS-EVENT-18. Ils ne font pas partie du code de ce lot.

Log lu pendant le lot :

```text
54c59fba ns_event_16: Consolidation de la disposition des blocs et disponibilité de la création d'activation de carte
8b3866a8 ns_event_15: Ajout de l'auteur des types de déclencheurs pour les événements
8a5996be ns_event_14: Ajout des conditions de consommation d'événements
7f490b9e ns_event_13: Ajout de l'auteur des conditions de fait pour les événements
26bec474 ns_event_12: Ajout de l'auteur des comportements pour les événements
00698aea ns_event_11: Ajout de l'auteur des actions de scène pour les événements
fc0e0be0 ns_event_10: Ajout de la saisie du titre pour les brouillons d'événements
cdedbe6e ns_event_09: Fermeture du flux de création de brouillon
d3f1866f ns_event_08: Ajout du sélecteur de position explicite sur la carte pour la création de brouillon
30ae9429 ns_event_07: Ajout de l'entrée UI explicite pour la création de brouillon avec position
3bd06d2b ns_event_06: Ajout des opérations de création de brouillon pour l'éditeur d'événements
6fe430d9 ns_event_05: Polissage des détails en lecture seule et diagnostics
1a551f41 ns_event_04: Ajout de l'espace de travail pour l'éditeur d'événements en lecture seule
7eed36b2 FG-NS-EVENT-003: Ajout du read model et diagnostics pour le builder d'événements
93b655dd FG-NS-EVENT-002-BIS: Préservation des conditions legacy et corrections dans le builder d'événements
6279df74 Remove legacy Narrative Studio steps entry
f54a8243 FG-NS-EVENT-002: Ajout des contrats et opérations pour le builder d'événements (core + tests)
410be446 FG-NS-EVENT-001: Alignement des contrats existants pour le builder d'événements
7b3b2151 FG-NS-EVENT-001: Ajout du plan MVP v1 pour le builder d'événements Narrative Studio
05e70a57 NS-STUDIO-PRODUCT-BETA-READINESS — Audit de préparation pour la bêta de Narrative Studio
```

## 4. Fichiers modifies

Fichiers crees :

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_creation_panel.dart`
- `reports/narrativeStudio/events/ns_event_18_creation_panel_compact_collapsible_v0.md`
- `reports/narrativeStudio/events/screenshots/ns_event_18_creation_panel_compact_collapsible_v0.png`

Fichiers modifies :

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

Fichiers supprimes :

- aucun.

## 5. Code complet du nouveau widget

```dart
import 'package:flutter/cupertino.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

class EventBuilderCreationPanel extends StatelessWidget {
  const EventBuilderCreationPanel({
    super.key,
    required this.isExpanded,
    required this.controls,
    required this.onToggle,
    this.compactMessage,
  });

  final bool isExpanded;
  final List<Widget> controls;
  final VoidCallback? onToggle;
  final String? compactMessage;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                CupertinoIcons.plus_square,
                color: colors.brandPrimary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Créer un événement',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (isExpanded) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Choisissez une position, puis créez un brouillon.',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PokeMapButton(
                key: const ValueKey('event-builder-creation-panel-toggle'),
                onPressed: controls.isEmpty ? null : onToggle,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: Icon(
                  isExpanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                ),
                child: Text(isExpanded ? 'Replier' : 'Préparer'),
              ),
            ],
          ),
          if (isExpanded && controls.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...controls,
          ] else if (compactMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              compactMessage!,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

## 6. Changements importants

`EventBuilderWorkspace` :

- importe `event_builder_creation_panel.dart` ;
- ajoute `_isCreationPanelExpanded` ;
- remplace l'ancien rendu direct des controles de creation par `EventBuilderCreationPanel` ;
- conserve le panneau deploye quand la liste est vide ;
- replie le panneau apres creation d'un brouillon ;
- transforme le bouton "Nouvel evenement" en action d'ouverture du panneau si aucune position n'est selectionnee ;
- renomme le titre interne du picker de `Créer un événement` vers `Position de création` pour eviter le doublon visuel.

Tests widget :

- les tests existants NS-EVENT-08/09/11 ont ete ajustes pour ouvrir explicitement le panneau avant de toucher la grille ;
- un test NS-EVENT-18 verifie que la grille est masquee tant que la creation n'est pas demandee ;
- un test de capture NS-EVENT-18 produit la Visual Gate.

Hunks principaux :

```diff
+import 'event_builder_creation_panel.dart';
+  bool _isCreationPanelExpanded = false;
+    final newEventAction = _newEventAction(createDraftAction);
+                    onPressed: newEventAction,
+                        child: EventBuilderCreationPanel(
+                          key: const ValueKey('event-builder-creation-panel'),
+                          isExpanded: true,
+                          controls: creationControls,
+                          onToggle: null,
+                          compactMessage: _draftCreationFeedback,
+                        ),
+                              EventBuilderCreationPanel(
+                                key: const ValueKey(
+                                  'event-builder-creation-panel',
+                                ),
+                                isExpanded: _isCreationPanelExpanded,
+                                controls: creationControls,
+                                compactMessage: _draftCreationFeedback,
+                                onToggle: () {
+                                  setState(() {
+                                    _isCreationPanelExpanded =
+                                        !_isCreationPanelExpanded;
+                                  });
+                                },
+                              ),
+  VoidCallback? _newEventAction(VoidCallback? createDraftAction) {
+    if (createDraftAction != null) {
+      return createDraftAction;
+    }
+    if (_requiresMapActivation ||
+        _isCreationPanelExpanded ||
+        !widget.draftCreationGate.hasPositionPicker) {
+      return null;
+    }
+    return () {
+      setState(() {
+        _isCreationPanelExpanded = true;
+      });
+    };
+  }
+          _isCreationPanelExpanded = false;
-                  'Créer un événement',
+                  'Position de création',
```

## 7. TDD

Test RED ajoute avant implementation :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-18 keeps creation compact"
```

Sortie signal exacte :

```text
Expected: exactly one matching candidate
Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'event-builder-creation-panel'>]: []>
```

Test GREEN cible apres implementation :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-18"
```

Sortie utile exacte :

```text
All tests passed!
```

## 8. Visual Gate

Capture produite :

```text
reports/narrativeStudio/events/screenshots/ns_event_18_creation_panel_compact_collapsible_v0.png
```

Commande de generation :

```bash
cd packages/map_editor
flutter test --reporter=compact --update-goldens --dart-define=NS_EVENT_18_CAPTURE_WORKSPACE=true test/event_builder_workspace_test.dart --name "captures NS-EVENT-18"
```

Sortie utile exacte :

```text
All tests passed!
```

Fichier :

```text
PNG image data, 1440 x 1100, 8-bit/color RGBA, non-interlaced
sha256 ba8265d2f176dcd1ac4af08878ca1beff5649968370d8c71cdb3db5ef9553383
```

Observation visuelle :

- un event est selectionne ;
- le panneau de creation est compact en bas de colonne ;
- la grille de position n'est pas visible ;
- les blocs de detail de l'event restent la surface principale ;
- aucun flow editor, drag/drop, outcome ou world rule n'est ajoute.

## 9. Validations executees

Format :

```bash
cd packages/map_editor
dart format lib/src/ui/canvas/events/event_builder_workspace.dart lib/src/ui/canvas/events/event_builder_creation_panel.dart test/event_builder_workspace_test.dart
```

Sortie exacte :

```text
Formatted 3 files (0 changed) in 0.06 seconds.
```

Suite widget complete :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart
```

Sortie utile exacte :

```text
All tests passed!
```

Regression cible NS-EVENT-18 :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-18"
```

Sortie utile exacte :

```text
All tests passed!
```

Analyse ciblee :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos lib/src/ui/canvas/events/event_builder_workspace.dart lib/src/ui/canvas/events/event_builder_creation_panel.dart test/event_builder_workspace_test.dart
```

Sortie exacte :

```text
No issues found! (ran in 3.8s)
```

Build macOS debug :

```bash
cd packages/map_editor
flutter build macos --debug
```

Sortie utile exacte :

```text
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

Note : une execution parallele d'un test cible pendant une suite Flutter deja lancee a produit un conflit de lock de demarrage Flutter. La commande a ete relancee sequentiellement ensuite et a passe. Ce n'etait pas une regression du code.

## 10. Non-objectifs respectes

Non-objectifs confirmes :

- aucun drag/drop ;
- aucun flow editor ;
- aucune edition de trigger ;
- aucune edition de condition ;
- aucune edition de scene action ;
- aucune edition de behavior ;
- aucun outcome ;
- aucune reaction ;
- aucune world rule ;
- aucun runtime ;
- aucun changement `map_core` ;
- aucun changement `map_runtime` ;
- aucun changement `map_gameplay` ;
- aucun changement `map_battle` ;
- aucun changement Selbrume.

## 11. Anti-scope

Commande :

```bash
git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples assets selbrume pubspec.yaml
```

Sortie exacte :

```text
```

## 12. Gate final

Etat final :

```text
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? packages/map_editor/lib/src/ui/canvas/events/event_builder_creation_panel.dart
?? reports/narrativeStudio/events/ns_event_17_target_layout_alignment_plan.md
?? reports/narrativeStudio/events/ns_event_18_creation_panel_compact_collapsible_v0.md
?? reports/narrativeStudio/events/ns_event_v1_drag_drop_detailed_lot_plan.md
?? reports/narrativeStudio/events/screenshots/ns_event_18_creation_panel_compact_collapsible_v0.png
```

`ns_event_17_target_layout_alignment_plan.md` et `ns_event_v1_drag_drop_detailed_lot_plan.md` sont des fichiers preexistants au lot NS-EVENT-18.

Diff stat final :

```text
 .../ui/canvas/events/event_builder_workspace.dart  | 71 ++++++++++++--------
 .../test/event_builder_workspace_test.dart         | 78 ++++++++++++++++++++--
 2 files changed, 117 insertions(+), 32 deletions(-)
```

Diff name-only final :

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

`git diff --check` :

```text
```

Screenshot NS-EVENT-18 trouve :

```text
reports/narrativeStudio/events/screenshots/ns_event_18_creation_panel_compact_collapsible_v0.png
```

## 13. Impact sur NS-EVENT-19

NS-EVENT-19 peut commencer sur une base plus propre :

- la grille de creation n'est plus la piece visuelle dominante ;
- la colonne gauche peut rester consacree a la liste + creation compacte ;
- le prochain lot peut travailler le builder central en blocs sans devoir d'abord deplacer le picker de position ;
- le composant `EventBuilderCreationPanel` peut rester local a la feature tant qu'il ne duplique pas une primitive design system.

Prochain lot recommande :

```text
NS-EVENT-19 - Event Builder Central Blocks Layout V0
```

## 14. Limites restantes

- Le panneau compact reste dans la colonne de liste ; il n'est pas encore integre a une bibliotheque d'elements.
- Le builder central n'a pas encore la structure cible complete "Declencheur / Conditions / Actions / Resultats / Reactions / Monde".
- L'inspecteur droit n'est pas encore separe.
- La creation par clic sur map ou canvas n'est pas ouverte.
- Le drag/drop reste volontairement hors scope.

## 15. Auto-review critique

Points verifies :

- le lot n'a pas ajoute de nouvelle capacite metier ;
- la grille de position reste disponible mais secondaire ;
- les tests existants ont ete adaptes a l'interaction explicite, sans supprimer la verification de creation ;
- le widget utilise les primitives PokeMap et les tokens via `context.pokeMapColors` ;
- aucun package runtime/core/gameplay/battle n'est touche ;
- aucune donnee Selbrume n'est touchee ;
- la Visual Gate montre bien l'etat compact.

Reserve :

Le rapport documente le Gate 0 initial a partir des preuves conservees au debut de la sequence et des commandes revalidees apres reprise de session. Les fichiers preexistants non suivis sont identifies explicitement pour eviter de les attribuer a NS-EVENT-18.
