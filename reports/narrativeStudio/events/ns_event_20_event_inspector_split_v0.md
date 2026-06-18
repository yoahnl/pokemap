# NS-EVENT-20 — Event Inspector Split V0

## 1. Résumé exécutif

NS-EVENT-20 sépare l'écran Event Builder en trois zones lisibles :

- liste des événements à gauche ;
- builder central en blocs no-code ;
- inspecteur d'événement à droite.

Le lot ne crée pas de nouvelle capacité métier. Il déplace les informations techniques secondaires hors du builder central vers un inspecteur dédié, tout en gardant les contrôles déjà livrés dans le builder : titre, déclencheur, action Scene, conditions, comportement et diagnostics.

Verdict : DONE.

## 2. Décision UI

Le builder central reste la surface d'authoring principale. L'inspecteur droit est une surface de lecture structurée :

- résumé événement ;
- statut ;
- déclencheur ;
- action principale ;
- réutilisation ;
- nombre de conditions ;
- informations techniques secondaires : ID technique, groupe, position.

Cette décision rapproche l'écran de la cible Yoahn sans ouvrir la bibliothèque d'éléments, le drag/drop, les résultats, les réactions ou les World Rules.

## 3. Fichiers modifiés / créés

Fichiers NS-EVENT-20 :

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart` : nouveau panneau inspecteur droit.
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart` : split builder central + inspecteur, suppression du hint ID technique dans le builder central, ajustement responsive des lignes d'options Fact/Event.
- `packages/map_editor/test/event_builder_workspace_test.dart` : tests NS-EVENT-20, capture Visual Gate, rescope des tests historiques impactés par la duplication voulue des libellés dans l'inspecteur.
- `reports/narrativeStudio/events/screenshots/ns_event_20_event_inspector_split_v0.png` : Visual Gate.
- `reports/narrativeStudio/events/ns_event_20_event_inspector_split_v0.md` : présent rapport.

Contexte de worktree : NS-EVENT-17/18/19 ont laissé des fichiers non commités avant ce lot. Le status final les montre encore avec NS-EVENT-20.

## 4. Comportement ajouté

Le panneau détail d'un événement sélectionné rend maintenant :

- `EventBuilderCentralFlow` au centre ;
- `EventBuilderInspectorPanel` à droite.

Le builder central ne contient plus le bloc `Informations techniques`. Les informations techniques restent visibles, mais uniquement dans l'inspecteur et avec un rôle secondaire.

Les contrôles d'authoring existants restent dans le builder central :

- renommer le titre ;
- changer le type de déclencheur ;
- choisir une Scene ;
- ajouter une condition Fact ;
- changer la réutilisation.

## 5. Extraits importants

### Nouveau panneau inspecteur

```dart
class EventBuilderInspectorPanel extends StatelessWidget {
  const EventBuilderInspectorPanel({
    super.key,
    required this.event,
  });

  final EventBuilderEventSummary event;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      key: const ValueKey('event-builder-inspector-panel'),
      expandChild: true,
      padding: const EdgeInsets.all(14),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...
            PokeMapCard(
              borderRadius: 8,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Informations techniques', ...),
                  _InspectorLine(
                    label: 'ID technique',
                    value: event.technicalId,
                    secondary: true,
                  ),
                  _InspectorLine(
                    label: 'Groupe',
                    value: event.groupKey,
                    secondary: true,
                  ),
                  _InspectorLine(
                    label: 'Position',
                    value: 'x ${event.position.x}, y ${event.position.y}',
                    secondary: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Split central + inspecteur

```dart
final centralFlow = EventBuilderCentralFlow(
  title: 'Builder d’événement',
  subtitle: 'Composez le Quand / Si / Alors sans ouvrir de script libre.',
  eventHeader: ...,
  blocks: [...],
);
return Row(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    Expanded(child: centralFlow),
    const SizedBox(width: 12),
    SizedBox(
      width: 320,
      child: EventBuilderInspectorPanel(event: selected),
    ),
  ],
);
```

### Test renforcé

Le test NS-EVENT-20 vérifie maintenant que le split ne casse pas :

- titre ;
- déclencheur ;
- Scene action ;
- condition Fact ;
- comportement.

## 6. TDD / RED

Commande RED initiale :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-20"
```

Sortie utile :

```text
NS-EVENT-20 shows event inspector on the right
Expected: exactly one matching candidate
Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'event-builder-inspector-panel'>]>

NS-EVENT-20 keeps technical id secondary in inspector
Expected: exactly one matching candidate
Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'event-builder-inspector-panel'>]>
```

Après premier correctif, un RED supplémentaire a confirmé deux défauts :

```text
Expected: no matching candidates
Actual: Found 1 widget with text "ID technique" descending from widget with key [<'event-builder-central-flow'>]

type 'SingleChildScrollView' is not a subtype of type 'Scrollable' in type cast
```

Corrections appliquées :

- suppression du hint ID technique dans l'en-tête central ;
- helper de test ciblant le `Scrollable` descendant du builder central ;
- options Fact/Event en `Wrap` pour éviter l'overflow dans la colonne centrale plus étroite.

## 7. Tests GREEN

Commande ciblée :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-20"
```

Résultat :

```text
00:04 +4: All tests passed!
```

Commande complète :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart
```

Résultat :

```text
00:17 +59: All tests passed!
```

Régressions corrigées pendant le lot :

- assertions historiques globales sur `Déclencheur` / `Réutilisation` rescopées au builder central ;
- tap NS-EVENT-15 stabilisé après le nouveau split ;
- tap condition NS-EVENT-19 stabilisé avec scroll central explicite.

## 8. Analyse / build

Commande analyse :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos \
  lib/src/ui/canvas/events/event_builder_workspace.dart \
  lib/src/ui/canvas/events/event_builder_central_flow.dart \
  lib/src/ui/canvas/events/event_builder_flow_blocks.dart \
  lib/src/ui/canvas/events/event_builder_creation_panel.dart \
  lib/src/ui/canvas/events/event_builder_inspector_panel.dart \
  test/event_builder_workspace_test.dart
```

Résultat :

```text
Analyzing 6 items...
No issues found! (ran in 3.4s)
```

Commande build :

```bash
cd packages/map_editor
flutter build macos --debug
```

Résultat :

```text
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 9. Visual Gate

Chemin :

```text
reports/narrativeStudio/events/screenshots/ns_event_20_event_inspector_split_v0.png
```

Capture :

- dimensions : 1440 x 1100 ;
- format : PNG RGBA ;
- shasum SHA-256 : `aeb20451ee94e6fd0f79e6578d1490a3d154b7af56bc121de285b8aeccf74f14`.

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact --update-goldens \
  --dart-define=NS_EVENT_20_CAPTURE_WORKSPACE=true \
  test/event_builder_workspace_test.dart \
  --name "captures NS-EVENT-20"
```

Résultat :

```text
00:11 +1: All tests passed!
```

## 10. Review indépendante

Reviewer : Turing.

Verdict :

```text
Go avec réserve mineure : acceptable pour NS-EVENT-20 si la suite complète event_builder_workspace_test.dart passe.
```

Findings traités :

- test NS-EVENT-20 incomplet pour Scene/conditions : corrigé en ajoutant la sélection de Scene et l'ajout d'une condition Fact dans le test NS-EVENT-20 ;
- breakpoint responsive absent : documenté comme limite restante, non bloquant pour ce lot desktop.

## 11. Non-objectifs respectés

Non ouvert :

- bibliothèque d'éléments ;
- add-by-click depuis bibliothèque ;
- drag/drop ;
- outcomes/résultats ;
- réactions ;
- World Rules inline ;
- runtime ;
- map_core ;
- map_gameplay ;
- map_battle ;
- map_runtime ;
- Selbrume.

Anti-scope :

```bash
git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples assets selbrume pubspec.yaml
```

Résultat :

```text
<vide>
```

## 12. Limites restantes

- L'inspecteur a une largeur fixe desktop de 320 px. C'est aligné avec la cible UI actuelle, mais un comportement responsive plus fin devra être traité si l'écran devient plus étroit.
- L'inspecteur est encore global à l'événement. Il ne devient pas encore un inspecteur de sous-bloc.
- Les informations de l'inspecteur restent read-only dans ce lot.

## 13. Impact sur NS-EVENT-21

NS-EVENT-21 peut démarrer la bibliothèque d'éléments read-only sans devoir réorganiser à nouveau le panneau détail. La structure attendue devient :

- gauche : liste + création compacte ;
- centre : builder en blocs ;
- droite : inspecteur ;
- prochain ajout : bibliothèque read-only entre liste et builder, ou en colonne compacte selon plan final.

## 14. Gate final

Commande :

```bash
git status --short --untracked-files=all
```

Résultat :

```text
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart
?? packages/map_editor/lib/src/ui/canvas/events/event_builder_creation_panel.dart
?? packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart
?? packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
?? reports/narrativeStudio/events/ns_event_17_target_layout_alignment_plan.md
?? reports/narrativeStudio/events/ns_event_18_creation_panel_compact_collapsible_v0.md
?? reports/narrativeStudio/events/ns_event_19_event_builder_central_blocks_layout_v0.md
?? reports/narrativeStudio/events/ns_event_20_event_inspector_split_v0.md
?? reports/narrativeStudio/events/ns_event_v1_drag_drop_detailed_lot_plan.md
?? reports/narrativeStudio/events/screenshots/ns_event_18_creation_panel_compact_collapsible_v0.png
?? reports/narrativeStudio/events/screenshots/ns_event_19_event_builder_central_blocks_layout_v0.png
?? reports/narrativeStudio/events/screenshots/ns_event_20_event_inspector_split_v0.png
```

Commande :

```bash
git diff --stat
```

Résultat :

```text
 .../ui/canvas/events/event_builder_workspace.dart  | 581 +++++++++------------
 .../test/event_builder_workspace_test.dart         | 571 ++++++++++++++++++--
 2 files changed, 793 insertions(+), 359 deletions(-)
```

Commande :

```bash
git diff --name-only
```

Résultat :

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

Commande :

```bash
git diff --check
```

Résultat :

```text
<vide>
```

Commande screenshots :

```bash
find reports/narrativeStudio/events/screenshots -maxdepth 1 -name '*ns_event_20*' -print
find reports/narrativeStudio/events/screenshots -maxdepth 1 -name '*ns_event_21*' -print
```

Résultat :

```text
reports/narrativeStudio/events/screenshots/ns_event_20_event_inspector_split_v0.png
<vide>
```

## 15. Auto-review critique

Points vérifiés :

- le builder central reste la source de l'authoring ;
- l'inspecteur ne crée aucune capacité métier ;
- les infos techniques ne sont plus dans le workflow principal ;
- les anciens tests restent verts après rescope ;
- la capture montre bien les trois zones ;
- aucune modification runtime/core/Selbrume.

Réserve assumée :

- la largeur fixe de l'inspecteur est suffisante pour le desktop actuel, pas encore une stratégie responsive complète.
