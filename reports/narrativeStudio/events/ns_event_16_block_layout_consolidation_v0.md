# NS-EVENT-16 — Event Builder Block Layout Consolidation V0

## 1. Résumé exécutif

NS-EVENT-16 consolide le workspace Événements sans ajouter de nouvelle fonctionnalité métier.

Le workspace passe d'un grand flux vertical à une structure plus lisible :

- colonne gauche : liste d'événements puis création de brouillon ;
- zone principale : builder d'événement en blocs ;
- blocs : Identité, Déclencheur, Conditions, Action principale, Comportement, Changements du monde, Diagnostics, Informations techniques.

Le wording obsolète indiquant que l'édition était verrouillée est remplacé par :

```text
Édition guidée : déclencheur, conditions, scène et comportement.
```

Toutes les actions existantes restent disponibles :

- création de draft depuis position explicite ;
- renommage ;
- changement de trigger type ;
- choix de Scene ;
- changement oneShot/reusable ;
- conditions Fact ;
- conditions Event consumed ;
- retrait de conditions supportées.

## 2. Problème UI initial

Après NS-EVENT-10 à NS-EVENT-15, le workspace proposait déjà plusieurs actions d'authoring, mais la liste affichait encore :

```text
Création de brouillon uniquement. L’édition reste verrouillée dans ce lot.
```

Ce wording était faux pour l'état produit actuel. Le position picker occupait aussi toute la largeur au-dessus de la liste et du détail, ce qui repoussait le contenu authorable.

## 3. Structure UI retenue

Structure retenue :

```text
Header Événements
Stats
Zone principale :
  gauche :
    Liste d’événements
    Créer un événement
  droite :
    Builder d’événement
    Identité
    Déclencheur
    Conditions
    Action principale
    Comportement
    Changements du monde
    Diagnostics
    Informations techniques
```

La colonne gauche garde la création accessible mais évite qu'elle bloque la lecture du builder.

## 4. Blocs consolidés

Fichier : `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`

Le détail sélectionné commence maintenant par :

```dart
Text(
  'Builder d’événement',
  style: TextStyle(
    color: context.pokeMapColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w900,
  ),
),
const SizedBox(height: 4),
Text(
  'Composez le Quand / Si / Alors sans ouvrir de script libre.',
  style: TextStyle(
    color: context.pokeMapColors.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.3,
  ),
),
```

Le titre/statut devient un bloc :

```dart
_DetailSection(
  title: 'Identité',
  summaryOverride: 'Titre humain, statut et ID technique.',
  children: [
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PokeMapIconTile(
          icon: CupertinoIcons.bolt_horizontal_circle,
          tone: PokeMapTone.quest,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildTitleBlock(context, selected),
        ),
        const SizedBox(width: 8),
        PokeMapBadge(
          label: selected.statusLabel,
          variant: _statusVariant(selected.status),
        ),
      ],
    ),
  ],
),
```

Les sections sont encadrées par `PokeMapCard` pour donner une vraie lecture en blocs :

```dart
return Padding(
  padding: const EdgeInsets.only(bottom: 14),
  child: PokeMapCard(
    borderRadius: 8,
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(...),
        if (summaryOverride != null || section != null) ...[
          const SizedBox(height: 5),
          Text(summaryOverride ?? section!.summary, ...),
        ],
        const SizedBox(height: 8),
        ...children,
      ],
    ),
  ),
);
```

## 5. Wording corrigé

Wording corrigé dans la liste :

```dart
Text(
  'Édition guidée : déclencheur, conditions, scène et comportement.',
  style: TextStyle(
    color: colors.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  ),
),
```

Le bloc de création s'appelle maintenant :

```text
Créer un événement
```

avec le sous-texte :

```text
Choisissez une position stable, puis utilisez le builder guidé.
```

La section `Changements du monde` indique clairement son statut V0 :

```text
Piloté par les conséquences de scène.
```

## 6. Fonctionnalités préservées

Fonctionnalités préservées et vérifiées :

- création draft depuis position picker ;
- reset de position après création ;
- sélection du draft créé ;
- renommage ;
- trigger type ;
- Scene action ;
- behavior ;
- Fact conditions ;
- Event consumed conditions ;
- locked legacy conditions ;
- visual gates précédentes.

## 7. Tests ajoutés/modifiés

Fichier : `packages/map_editor/test/event_builder_workspace_test.dart`

Test ajouté :

```dart
testWidgets('NS-EVENT-16 consolidates the workspace into guided blocks',
    (tester) async {
  await _pumpNarrativeEventsShell(tester);

  expect(find.text('Créer un événement'), findsOneWidget);
  expect(
    find.text(
        'Édition guidée : déclencheur, conditions, scène et comportement.'),
    findsOneWidget,
  );
  expect(
    find.text(
      'Création de brouillon uniquement. L’édition reste verrouillée dans ce lot.',
    ),
    findsNothing,
  );

  expect(find.text('Builder d’événement'), findsOneWidget);
  expect(find.text('Identité'), findsOneWidget);
  expect(find.text('Déclencheur'), findsOneWidget);
  expect(find.text('Conditions'), findsOneWidget);
  expect(find.text('Action principale'), findsOneWidget);
  expect(find.text('Comportement'), findsOneWidget);
  expect(find.text('Changements du monde'), findsOneWidget);
  expect(find.text('Diagnostics'), findsWidgets);
  expect(find.text('Informations techniques'), findsOneWidget);
  expect(find.text('Piloté par les conséquences de scène.'), findsOneWidget);

  expect(find.text('Ajouter un résultat'), findsNothing);
  expect(find.text('Résultats possibles'), findsNothing);
  expect(find.text('Ajouter une réaction'), findsNothing);
  expect(find.text('Créer une règle'), findsNothing);
  expect(find.text('Flow editor'), findsNothing);
  expect(find.text('Drag/drop'), findsNothing);
});
```

Visual Gate ajoutée :

```dart
testWidgets('captures NS-EVENT-16 block layout consolidation visual gate',
    (tester) async {
  if (!const bool.fromEnvironment('NS_EVENT_16_CAPTURE_WORKSPACE')) {
    return;
  }

  await _loadScreenshotFont();
  await _pumpNarrativeEventsShell(
    tester,
    fontFamily: _screenshotFontFamily,
    surfaceSize: const Size(1440, 1100),
  );

  final screenshotFile = File(
    '../../reports/narrativeStudio/events/screenshots/'
    'ns_event_16_block_layout_consolidation_v0.png',
  );
  screenshotFile.parent.createSync(recursive: true);
  await expectLater(
    find.byKey(const ValueKey('event-builder-workspace')),
    matchesGoldenFile(screenshotFile.absolute.path),
  );

  expect(screenshotFile.existsSync(), isTrue);
});
```

## 8. Visual Gate

Capture créée :

```text
reports/narrativeStudio/events/screenshots/ns_event_16_block_layout_consolidation_v0.png
```

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --update-goldens --reporter=compact test/event_builder_workspace_test.dart --name "captures NS-EVENT-16" --dart-define=NS_EVENT_16_CAPTURE_WORKSPACE=true
```

Sortie :

```text
00:02 +0: captures NS-EVENT-16 block layout consolidation visual gate
00:03 +1: captures NS-EVENT-16 block layout consolidation visual gate
00:03 +1: All tests passed!
```

Métadonnées :

```text
reports/narrativeStudio/events/screenshots/ns_event_16_block_layout_consolidation_v0.png: PNG image data, 1440 x 1100, 8-bit/color RGBA, non-interlaced
23733d4b8c8bc425fbdddbf8263442b2a56ae7aff34eec60b512d0fa124c269e  reports/narrativeStudio/events/screenshots/ns_event_16_block_layout_consolidation_v0.png
pixelWidth: 1440
pixelHeight: 1100
```

## 9. Validations exécutées

### Gate 0

Commande :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 20
```

Sortie utile :

```text
/Users/karim/Project/pokemonProject
main
```

`git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` étaient vides au Gate 0.

Log :

```text
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
da9cce15 NS-SCENES-V1-138 — Selbrume Golden Slice Content Inventory Asset Gap Audit
```

### RED

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-16"
```

Sortie RED :

```text
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Créer un événement": []>
```

Le test échouait sur l'absence du nouveau bloc de création/consolidation.

### GREEN ciblé

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-08|NS-EVENT-09|NS-EVENT-16"
```

Sortie :

```text
00:04 +8: All tests passed!
```

### Régression workspace complète

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_workspace_test.dart
```

Sortie :

```text
00:06 +43: All tests passed!
```

### Régression notifier

Commande :

```bash
cd packages/map_editor
flutter test --no-pub --reporter=compact test/event_builder_draft_creation_notifier_test.dart
```

Sortie :

```text
00:02 +27: All tests passed!
```

### Régression core Event Builder

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/event_builder_contract_test.dart test/event_builder_authoring_operations_test.dart test/event_builder_read_model_test.dart test/event_builder_draft_creation_operations_test.dart
```

Sortie :

```text
00:00 +40: All tests passed!
```

### Analyse ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze --no-pub --no-fatal-infos lib/src/ui/canvas/events/event_builder_workspace.dart test/event_builder_workspace_test.dart
```

Sortie :

```text
Analyzing 2 items...
No issues found! (ran in 1.9s)
```

### Build macOS debug

Commande :

```bash
cd packages/map_editor
flutter build macos --debug --no-pub
```

Sortie :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 10. Non-objectifs respectés

Confirmé :

- aucune nouvelle fonctionnalité métier ;
- aucune modification `map_core` ;
- aucune modification runtime/gameplay/battle ;
- aucun changement GameState ;
- aucune modification Selbrume ;
- aucune modification `project.json` ;
- pas de drag/drop ;
- pas de palette de blocs ;
- pas d'outcomes ;
- pas de reactions ;
- pas de World Rules authoring ;
- pas de Story Step conditions ;
- pas de conditions avancées ;
- pas de nouveau modèle Event ;
- pas de persistence ;
- pas de build_runner ;
- pas de generated files ;
- pas de commit.

## 11. Impact sur NS-EVENT-17

NS-EVENT-17 peut s'appuyer sur une structure plus proche de la cible :

- la colonne gauche peut accueillir progressivement une bibliothèque ou des filtres, mais ce lot ne les démarre pas ;
- le builder central est prêt pour un polish de bloc ou un futur sous-bloc précis ;
- le position picker est maintenant hors du chemin principal, mais reste visible et fonctionnel.

Recommandation : NS-EVENT-17 devrait rester ciblé, par exemple sur un polish du bloc `Conditions` ou sur la source/cible du déclencheur, pas sur le flow editor complet.

## 12. Limites restantes

- Pas de vrai flow editor.
- Pas de drag/drop.
- Pas de palette de blocs.
- Pas d'outcomes/réactions.
- Pas de World Rules authoring.
- Les changements du monde restent dérivés des conséquences de scène.
- La section `Informations techniques` reste disponible, mais secondaire.
- Le wording `Lecture seule dans ce lot` existe encore uniquement pour des conditions réellement non éditables ; il n'est plus présenté comme statut global du workspace.

## 13. Evidence Pack complet

### Règles lues

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`

### Fichiers lus

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_panel.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_card.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`

### Fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

### Fichiers créés

```text
reports/narrativeStudio/events/ns_event_16_block_layout_consolidation_v0.md
reports/narrativeStudio/events/screenshots/ns_event_16_block_layout_consolidation_v0.png
```

Le contenu complet du rapport est le présent document.

### Fichiers supprimés

```text
<aucun>
```

### Diffs/zones modifiées

Zones modifiées dans `event_builder_workspace.dart` :

- `_EventBuilderWorkspaceState.build` : déplacement du bloc création dans la colonne gauche.
- `_creationControlWidgets` : nouveau helper local pour composer le bloc création sans dupliquer les callbacks.
- `_EventCreationColumn` : nouveau widget local de colonne de création.
- `_DraftPositionPickerPanel` : titre et sous-texte mis à jour, hauteur de grille bornée à 166.
- `_EventListPanel` : wording de liste corrigé.
- `_EventDetailsPanelState.build` : ajout du header `Builder d’événement` et du bloc `Identité`.
- `_DetailSection` : rendu en `PokeMapCard` pour lecture en blocs.
- `Changements du monde` : wording V0 honnête.

Hunk principal :

```diff
-          if (widget.draftCreationGate.hasPositionPicker) ...[
-            const SizedBox(height: 12),
-            _DraftPositionPickerPanel(...)
-          ],
-          if (_draftCreationFeedback != null) ...[
-            const SizedBox(height: 12),
-            _DraftCreationFeedbackNotice(...)
-          ],
-          if (createDraftAction == null) ...[
-            const SizedBox(height: 12),
-            _DraftCreationGateNotice(message: _creationDisabledReason),
-          ],
           const SizedBox(height: 16),
           Expanded(
             child: widget.readModel.events.isEmpty
-                ? _EventBuilderEmptyState(onCreateDraft: createDraftAction)
+                ? Row(...)
                 : Row(
                     crossAxisAlignment: CrossAxisAlignment.stretch,
                     children: [
                       SizedBox(
                         width: 360,
-                        child: _EventListPanel(...)
+                        child: Column(
+                          children: [
+                            Expanded(child: _EventListPanel(...)),
+                            if (creationControls.isNotEmpty) ...[
+                              const SizedBox(height: 12),
+                              ...creationControls,
+                            ],
+                          ],
+                        ),
                       ),
```

Wording hunk :

```diff
-            'Création de brouillon uniquement. L’édition reste verrouillée '
-            'dans ce lot.',
+            'Édition guidée : déclencheur, conditions, scène et comportement.',
```

Test hunk :

```diff
+  testWidgets('NS-EVENT-16 consolidates the workspace into guided blocks',
+      (tester) async {
+    await _pumpNarrativeEventsShell(tester);
+    expect(find.text('Créer un événement'), findsOneWidget);
+    expect(
+      find.text(
+          'Édition guidée : déclencheur, conditions, scène et comportement.'),
+      findsOneWidget,
+    );
+    expect(find.text('Builder d’événement'), findsOneWidget);
+    expect(find.text('Identité'), findsOneWidget);
+    expect(find.text('Piloté par les conséquences de scène.'), findsOneWidget);
+    expect(find.text('Flow editor'), findsNothing);
+  });
```

### Anti-scope intermédiaire

Commande :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_core examples assets selbrume pubspec.yaml
```

Sortie :

```text
<vide>
```

### `git diff --check` intermédiaire

Commande :

```bash
git diff --check
```

Sortie :

```text
<vide>
```

### Gate final

Commande :

```bash
git status --short --untracked-files=all && git diff --stat && git diff --name-only && git diff --check
```

Sortie :

```text
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/ns_event_16_block_layout_consolidation_v0.md
?? reports/narrativeStudio/events/screenshots/ns_event_16_block_layout_consolidation_v0.png
 .../ui/canvas/events/event_builder_workspace.dart  | 320 ++++++++++++++-------
 .../test/event_builder_workspace_test.dart         |  62 ++++
 2 files changed, 272 insertions(+), 110 deletions(-)
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

`git diff --check` n'a produit aucune ligne.

Commande anti-scope :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_core examples assets selbrume pubspec.yaml
```

Sortie :

```text
<vide>
```

Commande screenshots :

```bash
find reports/narrativeStudio/events/screenshots -maxdepth 1 -name '*ns_event_16*' -print
find reports/narrativeStudio/events/screenshots -maxdepth 1 -name '*ns_event_17*' -print
```

Sortie :

```text
reports/narrativeStudio/events/screenshots/ns_event_16_block_layout_consolidation_v0.png
```

La recherche `*ns_event_17*` n'a produit aucune ligne.

## 14. Auto-review critique

Sub-agent Audit / Architecture :

- Verdict : OK.
- Le lot reste dans `map_editor`.
- Aucune donnée métier, runtime, core ou Selbrume n'est modifiée.

Sub-agent Implémentation :

- Verdict : OK.
- Le layout est consolidé sans ajouter de nouvelle action.
- Le position picker a été déplacé au lieu d'être supprimé.

Sub-agent Tests :

- Verdict : OK.
- RED observé avant implémentation.
- Régression détectée sur la grille de position trop compacte, corrigée par hauteur 166.
- Régression détectée sur la visibilité du draft créé, corrigée en donnant priorité à la liste dans la colonne gauche.

Sub-agent Build / Validation :

- Verdict : OK.
- Tests widget, tests notifier, tests core, analyze et build macOS debug passent.

Sub-agent Critique finale :

- Verdict : OK avec réserve mineure.
- `PokeMapCard` encadre désormais chaque section ; c'est lisible, mais il faudra éviter d'empiler des sous-cartes trop nombreuses lors des futurs lots.
- Le bloc création est encore visible avec grille V0 ; un accordéon pourra être envisagé plus tard si l'écran devient dense.
- Le test garde une assertion sur l'ancien wording verrouillé pour éviter une régression de vocabulaire.

Critique du prompt :

- Le prompt est cohérent avec l'état du repo.
- La demande de "builder central" aurait pu inciter à créer un flow editor ; le lot a volontairement choisi une consolidation visuelle en blocs.
- Le point "Diagnostics visibles ou accessibles" est partiellement dépendant du scroll : la Visual Gate montre le début du builder, mais la section diagnostics complète reste plus bas dans le scroll. Les tests prouvent sa présence.

Verdict :

```text
NS-EVENT-16 — DONE
```
