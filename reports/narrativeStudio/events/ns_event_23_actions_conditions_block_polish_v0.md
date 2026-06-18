# NS-EVENT-23 — Actions / Conditions Block Polish V0

## 1. Résumé exécutif

NS-EVENT-23 consolide visuellement les blocs `Conditions` et `Actions` du builder central Event Builder, sans ajouter de nouvelle capacité métier.

Verdict :

```text
NS-EVENT-23 : DONE
```

Le lot ajoute :

```text
- un slot vide no-code pour les conditions ;
- des lignes de condition typées : Fact / Événement / Étape ;
- des clés stables de lignes de conditions ;
- un slot Action principale no-code "Jouer une scène" ;
- une Visual Gate NS-EVENT-23 ;
- des tests widget dédiés ;
- une consolidation des gestes de tests historiques via un helper de scroll central.
```

Le lot ne modifie pas :

```text
- map_core ;
- map_runtime ;
- map_gameplay ;
- map_battle ;
- Selbrume ;
- project.json ;
- les contrats Event Builder ;
- les opérations d’authoring ;
- le runtime ;
- le flow editor ;
- les outcomes / réactions / world rules.
```

## 2. Confirmation du scope

Scope retenu :

```text
UI polish / widget tests uniquement dans map_editor.
```

Interprétation appliquée :

```text
Le lot rend les blocs existants plus lisibles et plus proches de la cible UI,
mais ne crée aucune nouvelle action, condition, outcome, réaction, règle du monde,
drag/drop ou écriture de modèle.
```

## 3. Audit initial

Fichiers audités :

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
packages/map_core/lib/src/read_models/event_builder_read_model.dart
```

Constats :

```text
- _buildConditionsBlock affichait les conditions via _ConditionDetailLine, avec le label générique "Condition".
- L’état vide des conditions était un simple texte "Aucune condition".
- _buildSceneActionBlock utilisait _DetailLine avec selected.sceneAction.label.
- EventBuilderConditionReadModel expose kind / referenceLabel / label / isSupported / isEditable.
- EventBuilderSceneActionReadModel expose sceneId / sceneLabel / label / isMissing.
- Les opérations d’ajout/retrait fonctionnaient déjà ; il fallait seulement améliorer la présentation.
```

Risques identifiés :

```text
- casser les tests historiques en augmentant la hauteur des blocs ;
- exposer des IDs techniques dans le bloc Actions ;
- laisser croire que drag/drop est supporté ;
- mélanger polish UI avec authoring de nouveaux blocs.
```

Décision :

```text
Ne modifier que la présentation widget et les tests de navigation.
```

## 4. État Git initial

Commandes initiales exécutées :

```bash
git status --short --untracked-files=all
git diff --stat
git diff --name-only
```

Sortie `git status --short --untracked-files=all` au début de la reprise NS-EVENT-23 :

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
?? reports/narrativeStudio/events/ns_event_22_add_by_click_from_library_v0.md
?? reports/narrativeStudio/events/ns_event_v1_drag_drop_detailed_lot_plan.md
?? reports/narrativeStudio/events/screenshots/ns_event_18_creation_panel_compact_collapsible_v0.png
?? reports/narrativeStudio/events/screenshots/ns_event_19_event_builder_central_blocks_layout_v0.png
?? reports/narrativeStudio/events/screenshots/ns_event_20_event_inspector_split_v0.png
?? reports/narrativeStudio/events/screenshots/ns_event_21_element_library_readonly_v0.png
?? reports/narrativeStudio/events/screenshots/ns_event_22_add_by_click_from_library_v0.png
```

Sortie initiale `git diff --stat` :

```text
 .../ui/canvas/events/event_builder_workspace.dart  |  709 +++++-----
 .../test/event_builder_workspace_test.dart         | 1368 +++++++++++++++++---
 2 files changed, 1583 insertions(+), 494 deletions(-)
```

Sortie initiale `git diff --name-only` :

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

Interprétation :

```text
Le worktree contenait déjà les lots NS-EVENT-17 à NS-EVENT-22.
NS-EVENT-23 ajoute uniquement des modifications supplémentaires dans les deux fichiers déjà touchés,
plus son rapport et sa capture.
```

## 5. Fichiers modifiés

Fichiers modifiés par NS-EVENT-23 :

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

Fichiers créés par NS-EVENT-23 :

```text
reports/narrativeStudio/events/ns_event_23_actions_conditions_block_polish_v0.md
reports/narrativeStudio/events/screenshots/ns_event_23_actions_conditions_block_polish_v0.png
```

## 6. Zones modifiées

### `event_builder_workspace.dart`

Zones modifiées :

```text
_buildConditionsBlock
_buildSceneActionBlock
_EmptyConditionSlot
_SceneActionSlot
_ConditionDetailLine
_conditionCategoryLabel
```

Extraits complets des zones NS-EVENT-23 :

```dart
if (selected.conditions.isEmpty)
  const _EmptyConditionSlot()
else
  for (var i = 0; i < selected.conditions.length; i++)
    _ConditionDetailLine(
      key: ValueKey('event-builder-condition-row-$i'),
      condition: selected.conditions[i],
      onRemove: canRemoveCondition &&
              _isEditableConditionKind(selected.conditions[i].kind)
          ? () => _removeCondition(selected, i)
          : null,
      removeKey: ValueKey('event-builder-remove-condition-$i'),
    ),
```

```dart
_SceneActionSlot(sceneAction: selected.sceneAction),
```

```dart
class _EmptyConditionSlot extends StatelessWidget {
  const _EmptyConditionSlot();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: PokeMapCard(
        key: const ValueKey('event-builder-empty-condition-slot'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        borderRadius: 8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aucune condition',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ajoutez une condition depuis la bibliothèque ou les boutons ci-dessous.',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

```dart
class _SceneActionSlot extends StatelessWidget {
  const _SceneActionSlot({
    required this.sceneAction,
  });

  final EventBuilderSceneActionReadModel sceneAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final value =
        sceneAction.isMissing ? 'Aucune scène choisie' : sceneAction.sceneLabel;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: PokeMapCard(
        key: const ValueKey('event-builder-scene-action-slot'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        borderRadius: 8,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              CupertinoIcons.play_rectangle,
              size: 16,
              color: colors.info,
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 116,
              child: Text(
                'Jouer une scène',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: sceneAction.isMissing
                      ? colors.textMuted
                      : colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

```dart
String _conditionCategoryLabel(EventBuilderConditionKind kind) {
  return switch (kind) {
    EventBuilderConditionKind.factIsTrue ||
    EventBuilderConditionKind.factIsFalse =>
      'Fact',
    EventBuilderConditionKind.eventConsumed ||
    EventBuilderConditionKind.eventNotConsumed =>
      'Événement',
    EventBuilderConditionKind.storyStepCompleted ||
    EventBuilderConditionKind.storyStepNotCompleted =>
      'Étape',
  };
}
```

### `event_builder_workspace_test.dart`

Zones modifiées :

```text
Tests NS-EVENT-13 / NS-EVENT-14 / NS-EVENT-19 / NS-EVENT-22
Nouveaux tests NS-EVENT-23
Nouvelle Visual Gate NS-EVENT-23
Helper _tapCentralBuilderTarget
```

Extraits complets des nouveaux tests NS-EVENT-23 :

```dart
testWidgets('NS-EVENT-23 condition rows remain removable', (tester) async {
  final container = await _pumpNarrativeEventsShell(
    tester,
    activeMap: _mapWithEventConditionTargets(),
    surfaceSize: const Size(1440, 1100),
  );

  await _tapEventCard(tester, 'Événement existant');
  await tester.tap(
    find.byKey(const ValueKey('event-builder-library-item-condition-fact')),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(
    find.byKey(const ValueKey('event-builder-fact-true-fact_started')),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const ValueKey('event-builder-fact-true-fact_started')),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(
      const ValueKey('event-builder-library-item-condition-event-consumed'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(
    find.byKey(const ValueKey('event-builder-event-consumed-evt_rival')),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const ValueKey('event-builder-event-consumed-evt_rival')),
  );
  await tester.pumpAndSettle();

  final factRow = find.byKey(const ValueKey('event-builder-condition-row-0'));
  final eventRow =
      find.byKey(const ValueKey('event-builder-condition-row-1'));
  expect(factRow, findsOneWidget);
  expect(eventRow, findsOneWidget);
  expect(find.descendant(of: factRow, matching: find.text('Fact')),
      findsOneWidget);
  expect(find.descendant(of: eventRow, matching: find.text('Événement')),
      findsOneWidget);
  expect(
    find.descendant(
      of: factRow,
      matching: find.text('Fact "Départ accepté" est vrai'),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: eventRow,
      matching: find.text('Événement "Rival au port" déjà consommé'),
    ),
    findsOneWidget,
  );

  await tester.ensureVisible(
    find.byKey(const ValueKey('event-builder-remove-condition-0')),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byKey(const ValueKey('event-builder-remove-condition-0')),
      matching: find.text('Retirer'),
    ),
  );
  await tester.pumpAndSettle();

  final event = container
      .read(editorNotifierProvider)
      .activeMap!
      .events
      .singleWhere((event) => event.id == 'evt_existing');
  expect(event.pages.single.condition,
      ScriptConditionFactory.eventIsConsumed('evt_rival'));
  expect(find.text('Condition retirée.'), findsOneWidget);
});
```

```dart
testWidgets(
    'NS-EVENT-23 empty condition slot is visible without promising drag/drop',
    (tester) async {
  await _pumpNarrativeEventsShell(
    tester,
    surfaceSize: const Size(1440, 1100),
  );

  final emptySlot =
      find.byKey(const ValueKey('event-builder-empty-condition-slot'));
  expect(emptySlot, findsOneWidget);
  expect(
      find.descendant(of: emptySlot, matching: find.text('Aucune condition')),
      findsOneWidget);
  expect(
    find.descendant(
      of: emptySlot,
      matching: find.text(
        'Ajoutez une condition depuis la bibliothèque ou les boutons ci-dessous.',
      ),
    ),
    findsOneWidget,
  );
  expect(find.textContaining('Déposez'), findsNothing);
  expect(find.text('Drag/drop'), findsNothing);
});
```

```dart
testWidgets('NS-EVENT-23 scene action block remains no-code', (tester) async {
  await _pumpNarrativeEventsShell(
    tester,
    surfaceSize: const Size(1440, 1100),
  );

  final actionsBlock = find.byKey(
    const ValueKey('event-builder-flow-block-actions'),
  );
  final sceneSlot =
      find.byKey(const ValueKey('event-builder-scene-action-slot'));

  expect(sceneSlot, findsOneWidget);
  expect(
      find.descendant(of: sceneSlot, matching: find.text('Jouer une scène')),
      findsOneWidget);
  expect(
      find.descendant(of: sceneSlot, matching: find.text('Scène existante')),
      findsOneWidget);
  expect(
    find.descendant(of: actionsBlock, matching: find.text('scene_existing')),
    findsNothing,
  );
  expect(
    find.descendant(of: actionsBlock, matching: find.text('sceneTarget')),
    findsNothing,
  );
});
```

Helper de test ajouté :

```dart
Future<void> _tapCentralBuilderTarget(
  WidgetTester tester,
  Finder finder,
) async {
  await tester.scrollUntilVisible(
    finder,
    160,
    scrollable: _eventBuilderCentralScrollable(),
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
```

## 7. Tests RED

Commande RED :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-23"
```

Sortie utile RED :

```text
Expected: exactly one matching candidate
Actual: Found 0 widgets with key [<'event-builder-condition-row-0'>]

Expected: exactly one matching candidate
Actual: Found 0 widgets with key [<'event-builder-empty-condition-slot'>]

Expected: exactly one matching candidate
Actual: Found 0 widgets with key [<'event-builder-scene-action-slot'>]

00:04 +0 -3: Some tests failed.
```

Interprétation :

```text
Le RED validait bien l’absence des nouveaux affordances visuels,
pas une erreur de contrat core.
```

## 8. Tests GREEN et régressions

Commande ciblée GREEN :

```bash
cd packages/map_editor
dart format test/event_builder_workspace_test.dart
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-23"
```

Sortie :

```text
00:04 +4: All tests passed!
```

Commande Visual Gate :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "captures NS-EVENT-23" --update-goldens --dart-define=NS_EVENT_23_CAPTURE_WORKSPACE=true
```

Sortie :

```text
00:03 +1: All tests passed!
```

Commande régression suite complète :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart
```

Sortie :

```text
00:13 +73: All tests passed!
```

Note :

```text
La première relance complète a exposé des taps directs fragiles dans NS-EVENT-13/14/19/22,
car les blocs sont plus hauts après le polish. Ces tests ont été corrigés en utilisant le
scroll central sans affaiblir leurs assertions métier.
```

## 9. Analyse et build

Commande analyse :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos \
  lib/src/ui/canvas/events/event_builder_workspace.dart \
  lib/src/ui/canvas/events/event_builder_central_flow.dart \
  lib/src/ui/canvas/events/event_builder_creation_panel.dart \
  lib/src/ui/canvas/events/event_builder_element_library.dart \
  lib/src/ui/canvas/events/event_builder_flow_blocks.dart \
  lib/src/ui/canvas/events/event_builder_inspector_panel.dart \
  lib/src/ui/canvas/narrative_workspace_canvas.dart \
  test/event_builder_workspace_test.dart
```

Sortie :

```text
Analyzing 8 items...
No issues found! (ran in 1.7s)
```

Commande build :

```bash
cd packages/map_editor
flutter build macos --debug
```

Sortie :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 10. Visual Gate

Capture créée :

```text
reports/narrativeStudio/events/screenshots/ns_event_23_actions_conditions_block_polish_v0.png
```

Métadonnées :

```text
pixelWidth: 1440
pixelHeight: 1100
sha256: 7b600c28c31ad6fb495c2595965fd5efe69b937ab6ccd28c329062968cd8d1e5
```

Contenu visuel vérifié :

```text
- event sélectionné ;
- conditions Fact et Événement visibles ;
- action principale Scene visible ;
- panneau inspecteur conservé ;
- bibliothèque conservée ;
- aucun drag/drop annoncé ;
- aucun flow editor d’outcome/réaction ouvert.
```

## 11. Sub-agents / passes séparées

Sub-agent Audit / Architecture :

```text
Verdict : GO.
Le read model expose déjà tout ce qu’il faut : condition.kind, condition.label,
sceneAction.sceneLabel. Aucun map_core nécessaire.
```

Sub-agent Implémentation :

```text
Verdict : GO.
Patch limité à des widgets privés de présentation dans EventBuilderWorkspace.
Pas de mutation notifier, pas de contrat core, pas de runtime.
```

Sub-agent Tests :

```text
Verdict : GO.
Nouveaux tests NS-EVENT-23 ajoutés. Tests historiques 13/14/19/22 gardent leurs
assertions métier et deviennent scroll-safe.
```

Sub-agent Build / Validation :

```text
Verdict : GO.
Suite widget complète, analyse ciblée, build macOS debug et Visual Gate passent.
```

Sub-agent Critique finale :

```text
Verdict : GO avec réserve mineure.
La capture a un rendu textuel étroit dans les rows de conditions ; c’est acceptable
pour V0 mais NS-EVENT-24 devrait traiter le polish général de densité/hiérarchie.
```

## 12. Non-objectifs respectés

Confirmé :

```text
- aucun nouveau modèle ;
- aucun changement map_core ;
- aucun changement runtime ;
- aucun flow editor ;
- aucun drag/drop ;
- aucun outcome / réaction / world rule authorable ;
- aucun stockage supplémentaire ;
- aucune donnée Selbrume modifiée ;
- aucun code généré ;
- aucune couleur hardcodée ajoutée dans la feature.
```

## 13. Impact sur NS-EVENT-24

NS-EVENT-24 peut maintenant se concentrer sur une clôture UX / Visual Gate MVP :

```text
- vérifier la hiérarchie globale liste / bibliothèque / builder / inspecteur ;
- lisser la densité des blocs centraux ;
- vérifier les messages empty / unsupported ;
- capturer un état final MVP agréable.
```

NS-EVENT-24 ne devrait pas démarrer :

```text
- drag/drop ;
- outcomes complets ;
- réactions riches ;
- world rules inline ;
- battle actions ;
- multi-actions.
```

## 14. Limites restantes

Limites assumées :

```text
- les rows longues peuvent encore wrapper fortement dans la colonne centrale ;
- les options de bibliothèque restent principalement add-by-click, pas drag/drop ;
- les résultats/réactions/monde restent "à venir" ;
- le builder ne fait pas encore de slots droppables réels ;
- l’action principale reste Scene-only.
```

## 15. Evidence Pack

Commandes exécutées :

```bash
git status --short --untracked-files=all
git diff --stat
git diff --name-only
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-23"
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "captures NS-EVENT-23" --update-goldens --dart-define=NS_EVENT_23_CAPTURE_WORKSPACE=true
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-19 keeps condition authoring working from the block|NS-EVENT-22 clicking Fact condition library item opens fact choice|NS-EVENT-22 clicking Event condition library item opens event choice"
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-13 adds and removes Fact conditions from details|NS-EVENT-14 adds and removes Event consumed conditions"
flutter test --reporter=compact test/event_builder_workspace_test.dart
flutter analyze --no-fatal-infos lib/src/ui/canvas/events/event_builder_workspace.dart lib/src/ui/canvas/events/event_builder_central_flow.dart lib/src/ui/canvas/events/event_builder_creation_panel.dart lib/src/ui/canvas/events/event_builder_element_library.dart lib/src/ui/canvas/events/event_builder_flow_blocks.dart lib/src/ui/canvas/events/event_builder_inspector_panel.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/event_builder_workspace_test.dart
flutter build macos --debug
shasum -a 256 reports/narrativeStudio/events/screenshots/ns_event_23_actions_conditions_block_polish_v0.png
sips -g pixelWidth -g pixelHeight reports/narrativeStudio/events/screenshots/ns_event_23_actions_conditions_block_polish_v0.png
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples assets selbrume pubspec.yaml
find reports/narrativeStudio/events/screenshots -maxdepth 1 -name '*ns_event_24*' -print
```

Sorties exactes utiles :

```text
NS-EVENT-23 RED : 00:04 +0 -3: Some tests failed.
NS-EVENT-23 GREEN : 00:04 +4: All tests passed!
Visual Gate NS-EVENT-23 : 00:03 +1: All tests passed!
Régression NS-EVENT-13/14 : 00:04 +2: All tests passed!
Régression NS-EVENT-19/22 : 00:05 +3: All tests passed!
Suite complète workspace : 00:13 +73: All tests passed!
Analyse ciblée : No issues found! (ran in 1.7s)
Build macOS debug : ✓ Built build/macos/Build/Products/Debug/map_editor.app
```

État Git final :

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
?? reports/narrativeStudio/events/ns_event_22_add_by_click_from_library_v0.md
?? reports/narrativeStudio/events/ns_event_23_actions_conditions_block_polish_v0.md
?? reports/narrativeStudio/events/ns_event_v1_drag_drop_detailed_lot_plan.md
?? reports/narrativeStudio/events/screenshots/ns_event_18_creation_panel_compact_collapsible_v0.png
?? reports/narrativeStudio/events/screenshots/ns_event_19_event_builder_central_blocks_layout_v0.png
?? reports/narrativeStudio/events/screenshots/ns_event_20_event_inspector_split_v0.png
?? reports/narrativeStudio/events/screenshots/ns_event_21_element_library_readonly_v0.png
?? reports/narrativeStudio/events/screenshots/ns_event_22_add_by_click_from_library_v0.png
?? reports/narrativeStudio/events/screenshots/ns_event_23_actions_conditions_block_polish_v0.png
```

Diff stat final :

```text
 .../ui/canvas/events/event_builder_workspace.dart  |  811 ++++++-----
 .../test/event_builder_workspace_test.dart         | 1467 +++++++++++++++++---
 2 files changed, 1780 insertions(+), 498 deletions(-)
```

Diff name-only final :

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

Sortie `git diff --check` :

```text
<vide>
```

Anti-scope runtime/core/gameplay/battle/examples/assets/selbrume/pubspec :

```text
<vide>
```

Recherche capture NS-EVENT-24 :

```text
<vide>
```

## 16. Auto-review critique

Checklist :

```text
- UI ne crée aucune nouvelle capacité métier : OK.
- Conditions supportées restent retirables : OK.
- Empty state ne promet pas drag/drop : OK.
- Action Scene reste no-code : OK.
- IDs techniques non affichés dans le bloc Actions : OK.
- Tests historiques restent significatifs : OK.
- Aucun runtime / gameplay / battle / core modifié : OK.
- Visual Gate créée : OK.
```

Réserve :

```text
La densité visuelle des rows de conditions est acceptable pour V0, mais la colonne
centrale mérite un polish de largeur / hierarchy dans NS-EVENT-24.
```

## 17. Critique du prompt

Le lot est bien dimensionné pour une passe polish. Le point fragile réel n’était pas le code produit mais les tests widget qui supposaient encore que certains boutons restaient directement hittables. Cette hypothèse devient moins fiable à mesure que l’UI se rapproche d’un builder central scrollable.

Décision adaptée :

```text
Ajouter _tapCentralBuilderTarget dans les tests pour refléter le vrai layout scrollable,
au lieu de réduire artificiellement la hauteur UI ou de retirer des assertions.
```
