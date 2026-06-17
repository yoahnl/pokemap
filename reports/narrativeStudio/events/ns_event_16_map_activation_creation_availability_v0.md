# NS-EVENT-16 — Event Builder Map Activation + Creation Availability V0

## 1. Résumé exécutif

NS-EVENT-16 Map Activation corrige le cas UX suivant :

```text
Projet chargé
→ Event Builder ouvert
→ aucune map active
→ l'utilisateur voit pourquoi la création est bloquée
→ l'utilisateur peut choisir une map du projet
→ la map est chargée par le mécanisme éditeur existant
→ le workspace reste dans Événements
→ le position picker devient disponible si la couche active est un ObjectLayer
```

Le lot ne crée aucun nouveau métier Event Builder. Il ajoute uniquement une passerelle UI/state pour activer une map depuis le workspace Événements.

Point de continuité :

```text
Un lot précédent utilise déjà le numéro NS-EVENT-16 pour "Block Layout Consolidation V0".
Ce rapport conserve le numéro demandé, mais distingue le lot par son intitulé complet :
NS-EVENT-16 — Event Builder Map Activation + Creation Availability V0.
```

Verdict :

```text
NS-EVENT-16 Map Activation — DONE
```

## 2. Problème UX initial

Avant ce lot, `NarrativeWorkspaceCanvas` construisait le read model Event Builder depuis `editor.activeMap`.

Quand `activeMap == null` :

```text
events = []
mapId = null
mapTitle = null
draftCreationGate = disabled
disabledReason = "Ouvrez une map active pour choisir la position de l’événement."
```

Le message était techniquement juste, mais ne proposait aucune action depuis le workspace Événements. Le KPI pouvait aussi afficher :

```text
Map active
```

alors qu'aucune map n'était active.

## 3. Audit du chargement / activation de map

Fichiers audités :

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/features/editor/application/project_session_controller.dart
packages/map_editor/lib/src/application/services/editor_map_session_coordinator.dart
packages/map_editor/lib/src/ui/shared/map_workspace_empty_state.dart
packages/map_editor/test/event_builder_workspace_test.dart
packages/map_editor/test/event_builder_draft_creation_notifier_test.dart
```

Réponses d'audit :

1. Une map est ouverte dans l'éditeur via `EditorNotifier.loadMap(relativePath)`.
2. Ce chemin passe par `LoadMapUseCase`, `ProjectWorkspace.resolveMapPath`, puis `ProjectSessionController.openMapDocument`.
3. `MapWorkspaceEmptyState` et l'arbre projet utilisent déjà `notifier.loadMap(map.relativePath)`.
4. Le Narrative Studio peut appeler ce mécanisme sans parser un JSON ni fabriquer `activeMap`.
5. `loadMap(...)` bascule normalement le workspace vers `EditorWorkspaceMode.map`; depuis Event Builder, le lot rappelle donc `selectEventsWorkspace()` après chargement pour conserver le contexte utilisateur.
6. Si le projet n'a aucune map, le workspace affiche une explication et ne crée rien.
7. Si la map ouverte n'a pas d'ObjectLayer actif, le gate existant reste bloqué et affiche le message de couche requise.

## 4. Décision d'architecture retenue

Décision :

```text
EventBuilderWorkspace reçoit des mapOptions no-code et un callback onOpenMap.
NarrativeWorkspaceCanvas construit ces options depuis ProjectManifest.maps.
Le callback retrouve le ProjectMapEntry par id, appelle EditorNotifier.loadMap(relativePath),
puis revient au workspace Événements avec selectEventsWorkspace().
```

Raisons :

- `ProjectMapEntry.relativePath` reste la source de chargement existante.
- L'UI ne lit pas de fichier map directement.
- Aucune `activeMap` factice n'est créée.
- Le flux Event Builder reste centré sur la création explicite par position.

Choix refusés :

- auto-ouvrir la première map sans action utilisateur ;
- créer une map ou une couche automatiquement ;
- fallback vers `map.layers.first` pour contourner une couche invalide ;
- créer un event sans map active.

## 5. UI Map Activation ajoutée

Nouveau type UI :

```dart
typedef EventBuilderMapOpenCallback = Future<void> Function(String mapId);

class EventBuilderMapOption {
  const EventBuilderMapOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}
```

Nouvelle API workspace :

```dart
final List<EventBuilderMapOption> mapOptions;
final EventBuilderMapOpenCallback? onOpenMap;
```

Le panneau apparaît uniquement quand :

```dart
widget.readModel.mapId == null &&
!widget.draftCreationGate.hasPositionPicker
```

Wording visible :

```text
Aucune map active
Choisissez une map du projet pour créer des événements.
Ouvrir “<nom de la map>”
```

Projet sans map :

```text
Aucune map dans ce projet.
Créez une map avant d’ajouter des événements.
```

## 6. Wording corrigé

Correction du KPI `Portée` :

```diff
- value: widget.readModel.mapTitle ?? 'Map active',
+ value: widget.readModel.mapTitle ?? 'Aucune map',
```

Correction de l'état vide :

```dart
title: hasActiveMap ? 'Aucun événement sur cette map' : 'Map requise',
description: hasActiveMap
    ? 'Le Builder d’événements affichera ici les déclencheurs authorés depuis la carte active.'
    : 'Choisissez une map du projet avant de placer un brouillon.',
```

## 7. Création Event Builder préservée

Le lot ne modifie pas les invariants de création :

- pas de création sans map active ;
- pas de création sans position explicite ;
- pas de création sans `ObjectLayer` valide ;
- pas de fallback layer ;
- pas d'event auto-créé à l'ouverture de map ;
- le bouton `Nouvel événement` reste disabled tant que `_createDraftAction == null`.

Le test intégré prouve que :

```text
click "Ouvrir “Port Selbrume”"
→ EditorNotifier.loadMap("maps/port.json")
→ activeMap.id == "map_port"
→ workspaceMode == EditorWorkspaceMode.events
→ position picker visible
```

## 8. Tests ajoutés / modifiés

Fichier :

```text
packages/map_editor/test/event_builder_workspace_test.dart
```

Tests ajoutés :

```text
NS-EVENT-16 map activation explains missing active map and opens a project map
NS-EVENT-16 map activation handles project without maps
NS-EVENT-16 map activation from NarrativeWorkspaceCanvas opens map and keeps events workspace
captures NS-EVENT-16 map activation visual gate
```

Helpers ajoutés :

```text
_pumpNarrativeEventsShell(... startWithoutActiveMap, projectRootPath, project, providerOverrides)
_mapWithObjectLayerFirst()
_FakeWorkspaceFactory
_FakeWorkspace
_FakeMapRepository
```

## 9. Visual Gate

Capture créée :

```text
reports/narrativeStudio/events/screenshots/ns_event_16_map_activation_creation_availability_v0.png
```

Commande :

```bash
cd packages/map_editor && flutter test --no-pub --update-goldens --reporter=compact test/event_builder_workspace_test.dart --name "captures NS-EVENT-16 map activation" --dart-define=NS_EVENT_16_MAP_ACTIVATION_CAPTURE_WORKSPACE=true
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/event_builder_workspace_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/event_builder_workspace_test.dart
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/event_builder_workspace_test.dart
00:02 +0: captures NS-EVENT-16 map activation visual gate
00:03 +0: captures NS-EVENT-16 map activation visual gate
00:03 +1: captures NS-EVENT-16 map activation visual gate
00:03 +1: All tests passed!
```

Métadonnées :

```text
reports/narrativeStudio/events/screenshots/ns_event_16_map_activation_creation_availability_v0.png: PNG image data, 1440 x 1100, 8-bit/color RGBA, non-interlaced
a42eb93a84570a23e061c5f72559fe41421e27fa59a8fb852b450d968ebbca75  reports/narrativeStudio/events/screenshots/ns_event_16_map_activation_creation_availability_v0.png
pixelWidth: 1440
pixelHeight: 1100
```

Note : la capture provient d'un widget test Flutter ; la police de test peut rendre certains textes comme des blocs. Les tests widget valident les libellés exacts affichés.

## 10. Validations exécutées

### RED initial

Commande :

```bash
cd packages/map_editor && flutter test --no-pub --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-16 map activation"
```

Sortie :

```text
test/event_builder_workspace_test.dart:1789:8: Error: Type 'EventBuilderMapOption' not found.
test/event_builder_workspace_test.dart:1790:3: Error: Type 'EventBuilderMapOpenCallback' not found.
test/event_builder_workspace_test.dart:247:9: Error: Method not found: 'EventBuilderMapOption'.
test/event_builder_workspace_test.dart:1829:15: Error: No named parameter with the name 'mapOptions'.
lib/src/ui/canvas/events/event_builder_workspace.dart:75:9: Context: Found this candidate, but the arguments don't match.
00:03 +0 -1: Some tests failed.
```

### GREEN ciblé

Commande :

```bash
cd packages/map_editor && flutter test --no-pub --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-16 map activation"
```

Sortie :

```text
00:04 +0: NS-EVENT-16 map activation explains missing active map and opens a project map
00:05 +1: NS-EVENT-16 map activation handles project without maps
00:05 +2: NS-EVENT-16 map activation from NarrativeWorkspaceCanvas opens map and keeps events workspace
EditorNotifier: loadMap(maps/port.json)
00:05 +3: captures NS-EVENT-16 map activation visual gate
00:05 +4: All tests passed!
```

### Suite workspace complète

Commande :

```bash
cd packages/map_editor && flutter test --no-pub --reporter=compact test/event_builder_workspace_test.dart
```

Sortie :

```text
00:03 +0: NS-EVENT-04 shows a readable empty state
00:06 +9: NS-EVENT-16 map activation explains missing active map and opens a project map
00:06 +10: NS-EVENT-16 map activation handles project without maps
00:06 +11: NS-EVENT-16 map activation from NarrativeWorkspaceCanvas opens map and keeps events workspace
EditorNotifier: loadMap(maps/port.json)
00:11 +33: NS-EVENT-16 consolidates the workspace into guided blocks
00:11 +44: captures NS-EVENT-16 block layout consolidation visual gate
00:11 +45: captures NS-EVENT-16 map activation visual gate
00:11 +47: All tests passed!
```

### Tests notifier

Commande :

```bash
cd packages/map_editor && flutter test --no-pub --reporter=compact test/event_builder_draft_creation_notifier_test.dart
```

Sortie :

```text
00:04 +0: NS-EVENT-08 EditorNotifier draft event creation creates a draft event from an explicit position and valid layer
00:04 +25: NS-EVENT-15 EditorNotifier trigger type authoring updates actor object and triggerZone while preserving event fields
00:04 +26: NS-EVENT-15 EditorNotifier trigger type authoring rejects effect and unknown events without mutating the map
00:04 +27: All tests passed!
```

### Tests core Event Builder

Commande :

```bash
cd packages/map_core && dart test --reporter=compact test/event_builder_contract_test.dart test/event_builder_authoring_operations_test.dart test/event_builder_read_model_test.dart test/event_builder_draft_creation_operations_test.dart
```

Sortie :

```text
00:01 +0: loading test/event_builder_contract_test.dart
00:01 +8: test/event_builder_authoring_operations_test.dart: Event Builder authoring operations reads scene action from MapEventPage.sceneTarget
00:01 +21: test/event_builder_read_model_test.dart: Event Builder read model maps legacy script and message to readable warnings
00:01 +28: loading test/event_builder_draft_creation_operations_test.dart
00:01 +40: All tests passed!
```

### Analyse ciblée

Commande :

```bash
cd packages/map_editor && flutter analyze --no-pub --no-fatal-infos lib/src/ui/canvas/events/event_builder_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/event_builder_workspace_test.dart
```

Sortie :

```text
Analyzing 3 items...
No issues found! (ran in 8.5s)
```

### Build macOS debug

Commande :

```bash
cd packages/map_editor && flutter build macos --debug --no-pub
```

Sortie :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 11. Non-objectifs respectés

Confirmé :

- aucun `map_core` modifié ;
- aucun `map_runtime` modifié ;
- aucun `map_gameplay` modifié ;
- aucun `map_battle` modifié ;
- aucun `selbrume/**` modifié ;
- aucun `project.json` modifié ;
- aucun generated file modifié ;
- aucun flow editor ajouté ;
- aucun outcome / reaction / world rule authoring ajouté ;
- aucun event créé sans map active ;
- aucun event créé sans position explicite ;
- aucun fallback layer ajouté.

## 12. Impact sur NS-EVENT-17

NS-EVENT-17 peut supposer que le workspace Événements est utilisable même si l'utilisateur y arrive sans map active :

```text
il verra les maps projet ;
il pourra en ouvrir une ;
la création redeviendra disponible après activation + couche ObjectLayer + position.
```

NS-EVENT-17 ne doit pas réouvrir :

- chargement de map ;
- fallback layer ;
- auto-création de map ;
- auto-création d'event.

## 13. Limites restantes

- La map n'est pas ouverte automatiquement : action utilisateur obligatoire.
- Si le mécanisme éditeur sélectionne une couche non-ObjectLayer, la création reste bloquée comme prévu.
- La capture widget-test utilise la police de test Flutter ; les assertions textuelles prouvent les labels exacts.
- Le repo contenait déjà des changements non commités du lot NS-EVENT-16 Block Layout Consolidation au Gate 0.

## 14. Evidence Pack complet

### Gate 0

Commande :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 20
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/ns_event_16_block_layout_consolidation_v0.md
?? reports/narrativeStudio/events/screenshots/ns_event_16_block_layout_consolidation_v0.png
 .../ui/canvas/events/event_builder_workspace.dart  | 320 ++++++++++++++-------
 .../test/event_builder_workspace_test.dart         |  62 ++++
 2 files changed, 272 insertions(+), 110 deletions(-)
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
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

Préexistant au lot :

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
reports/narrativeStudio/events/ns_event_16_block_layout_consolidation_v0.md
reports/narrativeStudio/events/screenshots/ns_event_16_block_layout_consolidation_v0.png
```

Les deux fichiers Dart étaient déjà modifiés par le lot Block Layout Consolidation ; ce lot Map Activation ajoute des changements dans ces mêmes fichiers.

### Fichiers créés

```text
reports/narrativeStudio/events/ns_event_16_map_activation_creation_availability_v0.md
reports/narrativeStudio/events/screenshots/ns_event_16_map_activation_creation_availability_v0.png
```

### Fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

### Sections modifiées complètes

`event_builder_workspace.dart` :

```dart
typedef EventBuilderMapOpenCallback = Future<void> Function(String mapId);

class EventBuilderMapOption {
  const EventBuilderMapOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}
```

```dart
final List<EventBuilderMapOption> mapOptions;
final EventBuilderMapOpenCallback? onOpenMap;
```

```dart
PokeMapStatusTile(
  label: 'Portée',
  value: widget.readModel.mapTitle ?? 'Aucune map',
  icon: CupertinoIcons.map,
  tone: PokeMapTone.map,
),
```

```dart
if (_requiresMapActivation) {
  append(
    _MapActivationPanel(
      mapOptions: widget.mapOptions,
      onOpenMap: widget.onOpenMap,
    ),
  );
}
```

```dart
bool get _requiresMapActivation {
  return widget.readModel.mapId == null &&
      !widget.draftCreationGate.hasPositionPicker;
}
```

```dart
class _MapActivationPanel extends StatelessWidget {
  const _MapActivationPanel({
    required this.mapOptions,
    required this.onOpenMap,
  });

  final List<EventBuilderMapOption> mapOptions;
  final EventBuilderMapOpenCallback? onOpenMap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      key: const ValueKey('event-builder-map-activation-panel'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.map,
                color: colors.brandPrimary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aucune map active',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const PokeMapBadge(
                label: 'Map requise',
                variant: PokeMapBadgeVariant.warning,
                icon: Icon(CupertinoIcons.exclamationmark_triangle),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Choisissez une map du projet pour créer des événements.',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          if (mapOptions.isEmpty) ...[
            Text(
              'Aucune map dans ce projet.',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Créez une map avant d’ajouter des événements.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ] else
            for (final map in mapOptions) ...[
              PokeMapButton(
                key: ValueKey('event-builder-open-map-${map.id}'),
                onPressed:
                    onOpenMap == null ? null : () => onOpenMap!(map.id),
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.folder_open),
                child: Text('Ouvrir “${map.label}”'),
              ),
              if (map != mapOptions.last) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}
```

`narrative_workspace_canvas.dart` :

```dart
mapOptions: _buildEventBuilderMapOptions(editor.project),
onOpenMap: (mapId) async {
  final entry = _findProjectMapById(editor.project, mapId);
  if (entry == null) {
    return;
  }
  await editorNotifier.loadMap(entry.relativePath);
  editorNotifier.selectEventsWorkspace();
},
```

```dart
List<EventBuilderMapOption> _buildEventBuilderMapOptions(
  ProjectManifest? project,
) {
  return [
    for (final map in project?.maps ?? const <ProjectMapEntry>[])
      EventBuilderMapOption(
        id: map.id,
        label: map.name.trim().isEmpty ? map.id : map.name.trim(),
      ),
  ];
}

ProjectMapEntry? _findProjectMapById(ProjectManifest? project, String mapId) {
  final normalizedMapId = mapId.trim();
  if (project == null || normalizedMapId.isEmpty) {
    return null;
  }
  for (final map in project.maps) {
    if (map.id == normalizedMapId) {
      return map;
    }
  }
  return null;
}
```

`event_builder_workspace_test.dart` :

```dart
testWidgets(
    'NS-EVENT-16 map activation explains missing active map and opens a project map',
    (tester) async {
  String? openedMapId;
  await _pumpWorkspace(
    tester,
    buildEventBuilderReadModel(events: const []),
    draftCreationGate: const EventBuilderDraftCreationGate.disabled(
      disabledReason:
          'Ouvrez une map active pour choisir la position de l’événement.',
    ),
    mapOptions: const [
      EventBuilderMapOption(id: 'map_port', label: 'Port Selbrume'),
    ],
    onOpenMap: (mapId) async {
      openedMapId = mapId;
    },
  );

  expect(find.text('Aucune map active'), findsOneWidget);
  expect(
    find.text('Choisissez une map du projet pour créer des événements.'),
    findsOneWidget,
  );
  expect(find.text('Ouvrir “Port Selbrume”'), findsOneWidget);
  expect(find.text('Map active'), findsNothing);
  expect(find.text('Position requise'), findsOneWidget);
  expect(
    tester
        .widget<PokeMapButton>(
          find.byKey(const ValueKey('event-builder-new-event-button')),
        )
        .onPressed,
    isNull,
  );

  await tester.tap(find.text('Ouvrir “Port Selbrume”'));
  await tester.pumpAndSettle();

  expect(openedMapId, 'map_port');
});
```

```dart
testWidgets(
    'NS-EVENT-16 map activation from NarrativeWorkspaceCanvas opens map and keeps events workspace',
    (tester) async {
  final repo = _FakeMapRepository(
    mapsByPath: {
      '/project/maps/port.json': _mapWithObjectLayerFirst(),
    },
  );
  final container = await _pumpNarrativeEventsShell(
    tester,
    startWithoutActiveMap: true,
    projectRootPath: '/project',
    providerOverrides: [
      mapRepositoryProvider.overrideWith((ref) => repo),
      projectWorkspaceFactoryProvider.overrideWith(
        (ref) => const _FakeWorkspaceFactory(
          workspace: _FakeWorkspace(projectRoot: '/project'),
        ),
      ),
    ],
  );

  expect(find.text('Aucune map active'), findsOneWidget);
  expect(find.text('Ouvrir “Port Selbrume”'), findsOneWidget);

  await tester.tap(find.text('Ouvrir “Port Selbrume”'));
  await tester.pumpAndSettle();

  final state = container.read(editorNotifierProvider);
  expect(repo.loadedPaths, ['/project/maps/port.json']);
  expect(state.activeMap?.id, 'map_port');
  expect(state.workspaceMode, EditorWorkspaceMode.events);
  expect(find.text('Couche : Objets'), findsOneWidget);
  expect(
    find.byKey(const ValueKey('event-builder-position-grid')),
    findsOneWidget,
  );
});
```

### Statut git intermédiaire avant écriture finale du rapport

Commande :

```bash
git status --short --untracked-files=all && git diff --stat && git diff --name-only && git diff --check && git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_core examples assets selbrume pubspec.yaml
```

Sortie :

```text
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/ns_event_16_block_layout_consolidation_v0.md
?? reports/narrativeStudio/events/screenshots/ns_event_16_block_layout_consolidation_v0.png
?? reports/narrativeStudio/events/screenshots/ns_event_16_map_activation_creation_availability_v0.png
 .../ui/canvas/events/event_builder_workspace.dart  | 457 +++++++++++++++------
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  34 ++
 .../test/event_builder_workspace_test.dart         | 335 ++++++++++++++-
 3 files changed, 707 insertions(+), 119 deletions(-)
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

`git diff --check` n'a produit aucune ligne.

La commande anti-scope n'a produit aucune ligne.

### Gate final après rapport

Commande :

```bash
git status --short --untracked-files=all && git diff --stat && git diff --name-only && git diff --check
```

Sortie :

```text
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/ns_event_16_block_layout_consolidation_v0.md
?? reports/narrativeStudio/events/ns_event_16_map_activation_creation_availability_v0.md
?? reports/narrativeStudio/events/screenshots/ns_event_16_block_layout_consolidation_v0.png
?? reports/narrativeStudio/events/screenshots/ns_event_16_map_activation_creation_availability_v0.png
 .../ui/canvas/events/event_builder_workspace.dart  | 457 +++++++++++++++------
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  34 ++
 .../test/event_builder_workspace_test.dart         | 335 ++++++++++++++-
 3 files changed, 707 insertions(+), 119 deletions(-)
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

`git diff --check` n'a produit aucune ligne.

Commande anti-scope finale :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_core examples assets selbrume pubspec.yaml
```

Sortie :

```text
<vide>
```

Commande screenshots :

```bash
find reports/narrativeStudio/events/screenshots -maxdepth 1 -name '*ns_event_16_map_activation*' -print
find reports/narrativeStudio/events/screenshots -maxdepth 1 -name '*ns_event_17*' -print
```

Sortie :

```text
reports/narrativeStudio/events/screenshots/ns_event_16_map_activation_creation_availability_v0.png
```

La recherche `*ns_event_17*` n'a produit aucune ligne.

## 15. Auto-review critique

Sub-agent Audit / Architecture :

- Verdict : OK.
- `loadMap(relativePath)` est le chemin sûr existant.
- `loadMap` bascule le workspace vers `map`, donc `selectEventsWorkspace()` est nécessaire pour respecter le flux depuis Event Builder.

Sub-agent Implémentation :

- Verdict : OK.
- Pas d'activeMap inventée.
- Pas de fallback layer.
- Pas de nouveau modèle métier Event Builder.

Sub-agent Tests :

- Verdict : OK.
- Le RED initial a capturé l'absence d'API de map activation.
- Le test intégré prouve le chargement via repository et le retour au workspace Événements.

Sub-agent Build / Validation :

- Verdict : OK.
- Tests workspace, notifier, core, analyze ciblé et build macOS debug passent.

Sub-agent Critique finale :

- Verdict : OK avec réserve mineure.
- Le numéro de lot est ambigu car NS-EVENT-16 avait déjà été utilisé pour la consolidation de layout.
- La Visual Gate widget-test rend certains textes en blocs ; les assertions textuelles restent la preuve fonctionnelle principale.
- Le passage `loadMap → selectEventsWorkspace` est volontairement minimal, mais si d'autres workspaces ont besoin de ce pattern, un helper notifier dédié pourra devenir utile.

Critique du prompt :

- Le prompt est cohérent avec le problème UX réel.
- Le numéro de lot doublonné est discutable ; il serait préférable de nommer ce lot `NS-EVENT-16-bis` ou `NS-EVENT-17` dans une roadmap future.
- L'attente "map ouverte puis position picker" dépend de la couche active choisie par le mécanisme existant ; le test utilise une map dont l'ObjectLayer est la première couche pour prouver le cas positif sans ajouter de fallback.
