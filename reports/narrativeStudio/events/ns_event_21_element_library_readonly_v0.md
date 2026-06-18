# NS-EVENT-21 — Element Library Read-only V0

## 1. Résumé exécutif

NS-EVENT-21 est DONE.

Le workspace Événements affiche maintenant une colonne `Bibliothèque d’éléments` entre la liste d’événements et le builder central. Cette bibliothèque est strictement read-only : elle expose les familles de blocs visées par l’UI cible, distingue les éléments déjà authorables des éléments à venir, et ne déclenche aucune mutation quand l’utilisateur clique dessus.

La livraison reste volontairement bornée :

- pas d’ajout par clic ;
- pas de drag/drop ;
- pas de flow editor libre ;
- pas de runtime ;
- pas de modification `map_core`.

## 2. Décision UI

La bibliothèque est placée à gauche du builder central, après la liste d’événements.

Structure retenue :

- `Liste d’événements`
- `Bibliothèque d’éléments`
- `Builder d’événement`
- `Inspecteur d’événement`

La bibliothèque affiche les groupes attendus de l’UI cible :

- Déclencheurs
- Conditions
- Actions
- Résultats
- Réactions
- Monde

Les éléments actuellement disponibles sont marqués `Disponible`. Les éléments prévus mais non authorables dans ce lot sont marqués `À venir`.

## 3. Comportement ajouté

Éléments disponibles affichés :

- Interaction PNJ
- Interaction objet
- Entrée dans une zone
- Fact vrai / faux
- Événement consommé
- Jouer une scène

Éléments affichés comme futurs :

- Étape narrative
- Combat
- Victoire
- Définir un Fact
- Activer élément

Un clic sur un item de bibliothèque ne modifie pas :

- `event.id`
- `event.title`
- `event.type`
- `event.position`
- `event.metadata`
- `event.pages`
- `selectedMapEventId`

## 4. Fichiers créés

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart
reports/narrativeStudio/events/ns_event_21_element_library_readonly_v0.md
reports/narrativeStudio/events/screenshots/ns_event_21_element_library_readonly_v0.png
```

## 5. Fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_creation_panel.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

Note : `event_builder_creation_panel.dart` et `event_builder_flow_blocks.dart` ont reçu de petits ajustements de stabilité layout/test pendant la stabilisation de NS-EVENT-21 : scroll de création ciblable et badges diagnostics wrappés pour éviter les débordements dans le split list/library/builder/inspector.

## 6. Extrait complet du nouveau widget bibliothèque

```dart
class EventBuilderElementLibrary extends StatelessWidget {
  const EventBuilderElementLibrary({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final groups = _libraryGroups();
    return PokeMapPanel(
      key: const ValueKey('event-builder-element-library'),
      expandChild: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bibliothèque d’éléments',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Catalogue read-only. L’ajout par clic arrive au prochain lot.',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final group = groups[index];
                return _ElementLibraryGroupCard(group: group);
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

Groupes déclarés :

```dart
_ElementLibraryGroup(id: 'triggers', title: 'Déclencheurs', ...)
_ElementLibraryGroup(id: 'conditions', title: 'Conditions', ...)
_ElementLibraryGroup(id: 'actions', title: 'Actions', ...)
_ElementLibraryGroup(id: 'results', title: 'Résultats', ...)
_ElementLibraryGroup(id: 'reactions', title: 'Réactions', ...)
_ElementLibraryGroup(id: 'world', title: 'Monde', ...)
```

## 7. Tests ajoutés/modifiés

Tests NS-EVENT-21 ajoutés dans `packages/map_editor/test/event_builder_workspace_test.dart` :

```text
NS-EVENT-21 shows read-only element library groups
NS-EVENT-21 marks unsupported elements as coming later
NS-EVENT-21 clicking read-only library item does not mutate event
NS-EVENT-21 does not expose raw metadata keys
captures NS-EVENT-21 element library read-only visual gate
```

Régressions adaptées :

- les tests historiques qui scrollent le builder ciblent maintenant le scrollable central ;
- les tests de création de brouillon utilisent `ensureVisible` avant de taper la position ;
- les attentes de résultats/réactions sont limitées au builder central, car la bibliothèque peut maintenant citer des éléments futurs en read-only.

## 8. Visual Gate

Capture créée :

```text
reports/narrativeStudio/events/screenshots/ns_event_21_element_library_readonly_v0.png
```

Propriétés :

```text
PNG image data, 1440 x 1100, 8-bit/color RGBA, non-interlaced
sha256: 0b73f103f5021be06f80e34c3095b5f7cb563ea6df31c9de74c79d43d6d6db69
```

La capture montre :

- la liste d’événements ;
- la bibliothèque d’éléments read-only ;
- les badges `Disponible` / `À venir` ;
- le builder central ;
- l’inspecteur ;
- aucun état add-by-click ou drag/drop.

## 9. Validations exécutées

### RED ciblé

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-21"
```

Résultat utile initial :

```text
Expected: exactly one matching candidate
Actual: Found 0 widgets with key [<'event-builder-element-library'>]
```

### GREEN ciblé

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-04 renders|NS-EVENT-09 creates|NS-EVENT-11 selects|NS-EVENT-18 keeps|NS-EVENT-20 title|NS-EVENT-21"
```

Résultat :

```text
00:08 +10: All tests passed!
```

### Suite complète Event Builder workspace

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart
```

Résultat :

```text
00:10 +64: All tests passed!
```

### Analyse ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos \
  lib/src/ui/canvas/events/event_builder_workspace.dart \
  lib/src/ui/canvas/events/event_builder_central_flow.dart \
  lib/src/ui/canvas/events/event_builder_flow_blocks.dart \
  lib/src/ui/canvas/events/event_builder_creation_panel.dart \
  lib/src/ui/canvas/events/event_builder_inspector_panel.dart \
  lib/src/ui/canvas/events/event_builder_element_library.dart \
  test/event_builder_workspace_test.dart
```

Résultat :

```text
Analyzing 7 items...
No issues found! (ran in 2.2s)
```

### Build macOS debug

Commande :

```bash
cd packages/map_editor
flutter build macos --debug
```

Résultat :

```text
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 10. Gate 0 / état git

État observé pendant la reprise NS-EVENT-21 :

```text
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart
?? packages/map_editor/lib/src/ui/canvas/events/event_builder_creation_panel.dart
?? packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart
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
?? reports/narrativeStudio/events/screenshots/ns_event_21_element_library_readonly_v0.png
```

Les fichiers NS-EVENT-17 à NS-EVENT-20 listés ici sont des artefacts déjà présents dans la série de lots UI en cours. NS-EVENT-21 ajoute spécifiquement le widget bibliothèque, les tests associés, la capture NS-EVENT-21 et ce rapport.

## 11. Non-objectifs respectés

Confirmé :

- pas d’add-by-click ;
- pas de drag/drop ;
- pas de mutation depuis la bibliothèque ;
- pas de modification `map_core` ;
- pas de modification runtime/gameplay/battle ;
- pas de modification Selbrume ;
- pas de champ JSON ;
- pas de metadata brute exposée dans la bibliothèque.

## 12. Impact sur NS-EVENT-22

NS-EVENT-22 peut se concentrer sur `Add-by-click From Library V0`.

Le prérequis UX est maintenant en place :

- les groupes existent ;
- les items supportés sont identifiables ;
- les items hors scope sont déjà visibles comme `À venir` ;
- les tests prouvent que l’état NS-EVENT-21 est passif.

NS-EVENT-22 devra transformer seulement les items `Disponible` en actions guidées, sans activer les items `À venir`.

## 13. Limites restantes

- La bibliothèque est statique dans ce lot.
- Les items ne sont pas encore reliés aux opérations d’authoring.
- Les descriptions sont volontairement courtes pour tenir dans le layout V0.
- Les groupes `Résultats`, `Réactions` et `Monde` restent des promesses visuelles read-only, pas des capacités produit.

## 14. Auto-review critique

Checklist relue :

- La bibliothèque ne mute pas le projet : OK, test `clicking read-only library item does not mutate event`.
- L’UI ne lance pas d’ajout par clic : OK, aucun callback d’action n’est branché dans `EventBuilderElementLibrary`.
- L’UI n’expose pas `eventBuilder`, `reusePolicy`, `MapEventType` ni `ScriptCondition` : OK, test dédié.
- Les groupes correspondent à la cible fournie : OK.
- Les éléments non authorables sont distingués : OK, badge `À venir`.
- Les validations workspace restent vertes : OK.
- Aucun runtime/Flame/GameState n’est touché : OK.

Réserve : la bibliothèque est aujourd’hui une liste statique. C’est acceptable pour NS-EVENT-21, mais NS-EVENT-22 devra décider précisément quels items deviennent cliquables et comment éviter que la colonne ressemble à un menu mort.

## 15. Gate final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart
?? packages/map_editor/lib/src/ui/canvas/events/event_builder_creation_panel.dart
?? packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart
?? packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart
?? packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
?? reports/narrativeStudio/events/ns_event_17_target_layout_alignment_plan.md
?? reports/narrativeStudio/events/ns_event_18_creation_panel_compact_collapsible_v0.md
?? reports/narrativeStudio/events/ns_event_19_event_builder_central_blocks_layout_v0.md
?? reports/narrativeStudio/events/ns_event_20_event_inspector_split_v0.md
?? reports/narrativeStudio/events/ns_event_21_element_library_readonly_v0.md
?? reports/narrativeStudio/events/ns_event_v1_drag_drop_detailed_lot_plan.md
?? reports/narrativeStudio/events/screenshots/ns_event_18_creation_panel_compact_collapsible_v0.png
?? reports/narrativeStudio/events/screenshots/ns_event_19_event_builder_central_blocks_layout_v0.png
?? reports/narrativeStudio/events/screenshots/ns_event_20_event_inspector_split_v0.png
?? reports/narrativeStudio/events/screenshots/ns_event_21_element_library_readonly_v0.png
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../ui/canvas/events/event_builder_workspace.dart  | 607 ++++++++--------
 .../test/event_builder_workspace_test.dart         | 775 ++++++++++++++++++++-
 2 files changed, 1020 insertions(+), 362 deletions(-)
```

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

Commande :

```bash
git diff --check
```

Sortie :

```text

```

Commande anti-scope :

```bash
git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples assets selbrume pubspec.yaml
```

Sortie :

```text

```

Commande screenshots :

```bash
find reports/narrativeStudio/events/screenshots -maxdepth 1 -name '*ns_event_21*' -print
find reports/narrativeStudio/events/screenshots -maxdepth 1 -name '*ns_event_22*' -print
```

Sortie :

```text
reports/narrativeStudio/events/screenshots/ns_event_21_element_library_readonly_v0.png
```

La deuxième commande ne retourne aucune capture NS-EVENT-22.
