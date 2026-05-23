# PokeMap UI Theme-6 — Map Workspace Empty State & Inspector Empty Shell Migration V0

## 1. Résumé
Le lot **Theme-6 — Map Workspace Empty State & Inspector Empty Shell Migration V0** a permis de migrer l'état vide du canvas de carte (`MapCanvas`) ainsi que l'état vide du panneau d'inspection droit (`MapInspectorPanel`) vers le design system PokeMap. Toutes les couleurs et styles qui dépendaient de `CupertinoColors` et de la classe obsolète `EditorChrome` ont été remplacés par les jetons sémantiques de couleur issus de `context.pokeMapColors`.

## 2. État Git initial réel
Avant de commencer, le dépôt Git était propre et contenait l'historique complet des lots précédents (Theme-5). Les fichiers `map_canvas.dart` et `map_inspector_panel.dart` présentaient des messages bruts en anglais avec des styles non conformes au design system.

## 3. Audit initial
* L'absence de map active est vérifiée par le test `activeMap == null`.
* Dans `MapCanvas`, cet état renvoyait un widget `Center(child: Text('No Map Loaded'))`.
* Dans `MapInspectorPanel`, cet état renvoyait un conteneur simple avec le texte `'Open a map to inspect layers and map systems'`.
* La logique de chargement de carte utilise `notifier.loadMap(relativePath)`.
* La création de carte utilise `showTopToolbarNewMapDialog(...)`.

## 4. Widgets responsables identifiés
1. `MapCanvas` (`packages/map_editor/lib/src/ui/canvas/map_canvas.dart`)
2. `MapInspectorPanel` (`packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`)

## 5. Option choisie : A ou B
L'**Option B — Créer des widgets d’état vide dédiés** a été choisie.

## 6. Justification du choix
Le rendu vide était auparavant géré de manière in-line et simpliste dans des méthodes de rendu ou d'arborescences volumineuses. Pour assurer une structure propre, réutilisable et facilement testable sans polluer la logique complexe du canvas ou de l'inspecteur, nous avons créé deux widgets dédiés :
* `MapWorkspaceEmptyState`
* `MapInspectorEmptyState`

## 7. Fichiers modifiés
1. `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
2. `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`

## 8. Fichiers créés
1. `packages/map_editor/lib/src/ui/panels/map_inspector_empty_state.dart`
2. `packages/map_editor/lib/src/ui/shared/map_workspace_empty_state.dart`
3. `packages/map_editor/test/ui/shell/pokemap_workspace_empty_state_test.dart`

## 9. Ce qui change visuellement
### Workspace Central :
* **Arrière-plan et Cartes** : Le fond central utilise un panneau `PokeMapPanel` premium avec des coins arrondis de 12px et une bordure sémantique subtile.
* **Branding / Icône** : Une icône centrale (dossier ou map) entourée d'un badge circulaire avec une teinte douce de la marque (`colors.brandPrimarySoft` et bordure `colors.brandPrimaryBorder`).
* **Textes et Boutons** : Utilisation de titres et descriptions sémantiques en français. Boutons d'actions principaux `PokeMapButton` ("Créer une map", "Ouvrir une map") avec des icônes d'action sémantiques.
* **Liste de cartes existantes** : Si le projet contient des cartes, elles sont affichées dans une zone défilable sous forme de petites cartes interactives `PokeMapCard` avec leur icône correspondante selon le rôle de la carte (extérieur, intérieur, etc.).
* **Responsive** : Les boutons d'actions utilisent un layout `Wrap` responsive au lieu de `Row` pour éviter les débordements sur les petits écrans.

### Inspecteur Droit Vide :
* **Cartes de structure** : Affichage d'un panneau d'aide d'introduction sémantique ("Ouvrez une map").
* **Section Calques** : Une carte fermée `InspectorSectionCard` affichant "Aucun calque à afficher".
* **Section Propriétés** : Une carte étendue affichant une liste de propriétés de carte simulées et lisibles (Nom, Taille, Tileset, Mode, Grille, Version) stylisées avec `colors.textPrimary` et `colors.textSecondary`.
* **Section Systèmes** : Une carte fermée affichant "Aucun système détecté".

## 10. Ce qui ne change pas fonctionnellement
* Les raccourcis clavier (Cmd+S, Cmd+Z, Cmd+Y).
* La logique interne de chargement de carte (via `notifier.loadMap`).
* La logique de création de carte (via `showTopToolbarNewMapDialog`).
* La topbar et la sidebar migrées dans les phases précédentes.

## 11. Textes remplacés
* `"No Map Loaded"` &rarr; `"Aucune map ouverte"`
* `"Open a map to start building your world."` &rarr; `"Ouvrez une map existante ou créez-en une nouvelle pour commencer à éditer."`
* `"Open a map to inspect layers and map systems"` &rarr; `"Sélectionnez une map pour inspecter ses calques et ses systèmes."`
* `"Open a project to browse your world, maps and tilesets."` &rarr; `"Ouvrez un projet existant ou créez-en un nouveau pour commencer à travailler."`

## 12. Couleurs hardcodées restantes et justification
Aucune couleur de Material ou Cupertino n'est hardcodée dans les fichiers migrés (utilisation exclusive de `colors.textPrimary`, `colors.brandPrimarySoft`, `colors.divider`, etc.).

## 13. Tests ajoutés ou adaptés
Un nouveau fichier de test `pokemap_workspace_empty_state_test.dart` a été créé. Il couvre :
1. Le bon rendu de l'état vide du workspace central quand un projet est chargé (avec liste des cartes).
2. Le bon rendu de l'état vide de l'inspecteur droit (avec les placeholders de calques, propriétés et systèmes).
3. Le bon rendu du workspace central quand aucun projet n'est chargé.
4. L'absence des anciens libellés en anglais.

## 14. Commandes lancées avec résultats exacts
* **Analyse de code** :
  ```bash
  flutter analyze lib/src/ui/canvas/map_canvas.dart lib/src/ui/panels/map_inspector_panel.dart lib/src/ui/shared/map_workspace_empty_state.dart lib/src/ui/panels/map_inspector_empty_state.dart test/ui/shell/pokemap_workspace_empty_state_test.dart
  ```
  *Résultat* : `No issues found! (ran in 2.5s)`
* **Tests unitaires et widgets** :
  ```bash
  flutter test test/ui/shell/pokemap_workspace_empty_state_test.dart --timeout=180s
  ```
  *Résultat* : `All tests passed!`
* **Tests de non-régression du shell** :
  ```bash
  flutter test test/editor_shell_page_smoke_test.dart test/top_toolbar_test.dart --timeout=180s
  ```
  *Résultat* : `All tests passed!`

## 15. Validation visuelle effectuée ou non
La validation visuelle automatisée par tests de widgets a été menée avec succès (mise en page, présence des icônes, textes et boutons). La validation sur un poste physique avec simulateur interactif n'a pas pu être effectuée en mode headless.

## 16. Git status final
```text
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
?? packages/map_editor/lib/src/ui/panels/map_inspector_empty_state.dart
?? packages/map_editor/lib/src/ui/shared/map_workspace_empty_state.dart
?? packages/map_editor/test/ui/shell/pokemap_workspace_empty_state_test.dart
```

## 17. Git diff --stat
```text
 packages/map_editor/lib/src/ui/canvas/map_canvas.dart        |  3 ++-
 .../map_editor/lib/src/ui/panels/map_inspector_panel.dart    | 12 ++----------
 2 files changed, 4 insertions(+), 11 deletions(-)
```

## 18. Liste des fichiers untracked
* `packages/map_editor/lib/src/ui/panels/map_inspector_empty_state.dart`
* `packages/map_editor/lib/src/ui/shared/map_workspace_empty_state.dart`
* `packages/map_editor/test/ui/shell/pokemap_workspace_empty_state_test.dart`

## 19. Contenu complet des fichiers créés/modifiés

### `packages/map_editor/lib/src/ui/shared/map_workspace_empty_state.dart`
```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:map_core/map_core.dart';
import '../../theme/theme.dart';
import '../design_system/design_system.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_selectors.dart';
import 'top_toolbar/dialogs/top_toolbar_dialogs.dart';

class MapWorkspaceEmptyState extends ConsumerWidget {
  const MapWorkspaceEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.pokeMapColors;
    final project = ref.watch(editorProjectManifestProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final settings = project?.settings ?? const ProjectSettings();

    if (project == null) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(24),
          child: PokeMapPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.brandPrimarySoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.brandPrimaryBorder, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    CupertinoIcons.folder,
                    color: colors.brandPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Aucun projet ouvert',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ouvrez un projet existant ou créez-en un nouveau pour commencer à travailler.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    PokeMapButton(
                      variant: PokeMapButtonVariant.primary,
                      onPressed: () => showTopToolbarNewProjectDialog(context, notifier),
                      child: const Text('Créer un projet'),
                    ),
                    PokeMapButton(
                      variant: PokeMapButtonVariant.secondary,
                      onPressed: () async {
                        final selectedDirectory = await FilePicker.platform.getDirectoryPath();
                        if (selectedDirectory != null) {
                          final manifestPath = p.join(selectedDirectory, 'project.json');
                          await notifier.loadProject(manifestPath);
                        }
                      },
                      child: const Text('Ouvrir un projet'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final maps = project.maps;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.all(24),
        child: PokeMapPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.brandPrimarySoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.brandPrimaryBorder, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    CupertinoIcons.map,
                    color: colors.brandPrimary,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Aucune map ouverte',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Ouvrez une map existante ou créez-en une nouvelle pour commencer à éditer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  PokeMapButton(
                    variant: PokeMapButtonVariant.primary,
                    leading: const Icon(CupertinoIcons.plus, size: 16),
                    onPressed: () => showTopToolbarNewMapDialog(
                      context,
                      notifier,
                      defaultWidth: settings.defaultMapWidth,
                      defaultHeight: settings.defaultMapHeight,
                    ),
                    child: const Text('Créer une map'),
                  ),
                  if (maps.isNotEmpty)
                    PokeMapButton(
                      variant: PokeMapButtonVariant.secondary,
                      leading: const Icon(CupertinoIcons.folder_open, size: 16),
                      onPressed: () => _showMapsSelectionMenu(context, maps, notifier),
                      child: const Text('Ouvrir une map'),
                    ),
                ],
              ),
              if (maps.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  height: 1,
                  color: colors.divider,
                ),
                const SizedBox(height: 16),
                Text(
                  'Cartes existantes dans le projet :',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final map in maps)
                          PokeMapCard(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            onTap: () => notifier.loadMap(map.relativePath),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _roleIcon(map.role),
                                  size: 14,
                                  color: colors.brandPrimary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  map.name,
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'ou glissez-déposez un fichier ici',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _roleIcon(MapRole role) {
    return switch (role) {
      MapRole.exterior => CupertinoIcons.sun_max,
      MapRole.interior => CupertinoIcons.house,
      MapRole.basement => CupertinoIcons.arrow_down_circle,
      MapRole.upper_floor => CupertinoIcons.arrow_up_circle,
      MapRole.connector => CupertinoIcons.link,
      MapRole.gate => CupertinoIcons.square_arrow_right,
      MapRole.section => CupertinoIcons.square_split_2x1,
      MapRole.room => CupertinoIcons.square_grid_2x2,
      MapRole.sub_area => CupertinoIcons.layers_alt,
    };
  }

  void _showMapsSelectionMenu(BuildContext context, List<ProjectMapEntry> maps, EditorNotifier notifier) {
    final colors = context.pokeMapColors;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Choisir une map à ouvrir'),
        actions: <CupertinoActionSheetAction>[
          for (final map in maps)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                notifier.loadMap(map.relativePath);
              },
              child: Text(
                map.name,
                style: TextStyle(color: colors.brandPrimary),
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Annuler'),
        ),
      ),
    );
  }
}
```

### `packages/map_editor/lib/src/ui/panels/map_inspector_empty_state.dart`
```dart
import 'package:flutter/cupertino.dart';
import '../../theme/theme.dart';
import '../shared/inspector_section_card.dart';

class MapInspectorEmptyState extends StatelessWidget {
  const MapInspectorEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;

    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Inspector Header Card / Intro
          Container(
            margin: const EdgeInsets.fromLTRB(10, 2, 10, 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceSubtle,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.borderSubtle,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colors.brandPrimarySoft,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: colors.brandPrimaryBorder,
                          width: 1.25,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        CupertinoIcons.layers,
                        color: colors.brandPrimary,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ouvrez une map',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sélectionnez une map pour inspecter ses calques et ses systèmes.',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Calques Card
          InspectorSectionCard(
            title: 'Calques',
            subtitle: 'Aucun calque à afficher',
            icon: CupertinoIcons.layers,
            expanded: false,
            onToggle: () {},
            expandedHeight: 40,
            accentColor: colors.brandPrimary,
            child: const Center(
              child: Text(
                'Aucun calque à afficher',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),

          // Propriétés de la map Card
          InspectorSectionCard(
            title: 'Propriétés de la map',
            subtitle: 'Informations générales',
            icon: CupertinoIcons.slider_horizontal_3,
            expanded: true,
            onToggle: () {},
            expandedHeight: 180,
            accentColor: colors.brandPrimary,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPropertyRow(context, 'Nom', '—'),
                  _buildPropertyRow(context, 'Taille', '—'),
                  _buildPropertyRow(context, 'Tanset', '—'),
                  _buildPropertyRow(context, 'Mode', 'Scène'),
                  _buildPropertyRow(context, 'Grille', '32 × 32'),
                  _buildPropertyRow(context, 'Version', '—'),
                ],
              ),
            ),
          ),

          // Systèmes de map Card
          InspectorSectionCard(
            title: 'Systèmes de map',
            subtitle: 'Aucun système détecté',
            icon: CupertinoIcons.gear,
            expanded: false,
            onToggle: () {},
            expandedHeight: 40,
            accentColor: colors.brandPrimary,
            child: const Center(
              child: Text(
                'Aucun système détecté',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyRow(BuildContext context, String label, String value) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
```

### `packages/map_editor/test/ui/shell/pokemap_workspace_empty_state_test.dart`
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/shared/map_workspace_empty_state.dart';
import 'package:map_editor/src/ui/panels/map_inspector_empty_state.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_core/map_core.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  group('PokeMap Workspace & Inspector Empty States Migration', () {
    testWidgets('Renders empty states with correct branding and actions when project is loaded but no map is active',
        (tester) async {
      final project = buildShellChromeProject(
        name: 'Empty State Project',
        maps: [
          buildShellChromeMap(id: 'map_1', name: 'Starting Town'),
          buildShellChromeMap(id: 'map_2', name: 'Route 101'),
        ].map((m) => ProjectMapEntry(
          id: m.id,
          name: m.name,
          relativePath: 'maps/${m.id}.json',
          role: MapRole.exterior,
        )).toList(),
      );

      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/theme_6_test_project',
          project: project,
          workspaceMode: EditorWorkspaceMode.map,
          activeMap: null,
        ),
      );

      // 1. Verify workspace central empty state is displayed
      expect(find.byType(MapWorkspaceEmptyState), findsOneWidget);
      expect(find.text('Aucune map ouverte'), findsOneWidget);
      expect(find.text('Ouvrez une map existante ou créez-en une nouvelle pour commencer à éditer.'), findsOneWidget);
      
      // Verify actions
      expect(find.widgetWithText(PokeMapButton, 'Créer une map'), findsOneWidget);
      expect(find.widgetWithText(PokeMapButton, 'Ouvrir une map'), findsOneWidget);
      expect(find.text('ou glissez-déposez un fichier ici'), findsOneWidget);

      // Verify that old texts do not exist
      expect(find.text('No Map Loaded'), findsNothing);

      // Verify listed existing maps inside workspace empty state
      expect(find.descendant(of: find.byType(MapWorkspaceEmptyState), matching: find.text('Starting Town')), findsOneWidget);
      expect(find.descendant(of: find.byType(MapWorkspaceEmptyState), matching: find.text('Route 101')), findsOneWidget);

      // 2. Verify right inspector empty state is displayed
      expect(find.byType(MapInspectorEmptyState), findsOneWidget);
      expect(find.text('Ouvrez une map'), findsOneWidget);
      expect(find.text('Sélectionnez une map pour inspecter ses calques et ses systèmes.'), findsOneWidget);
      
      // Verify sections are present
      expect(find.text('Calques'), findsOneWidget);
      expect(find.text('Aucun calque à afficher'), findsWidgets);
      
      expect(find.text('Propriétés de la map'), findsOneWidget);
      expect(find.text('Nom'), findsOneWidget);
      expect(find.text('Taille'), findsOneWidget);
      expect(find.text('Grille'), findsOneWidget);
      expect(find.text('32 × 32'), findsOneWidget);

      expect(find.text('Systèmes de map'), findsOneWidget);
      expect(find.text('Aucun système détecté'), findsWidgets);
    });

    testWidgets('Renders empty state when no project is loaded',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: const EditorState(
          projectRootPath: null,
          project: null,
          workspaceMode: EditorWorkspaceMode.map,
          activeMap: null,
        ),
      );

      // Verify workspace central empty state is displayed for no project
      expect(find.byType(MapWorkspaceEmptyState), findsOneWidget);
      expect(find.text('Aucun projet ouvert'), findsOneWidget);
      expect(find.text('Ouvrez un projet existant ou créez-en un nouveau pour commencer à travailler.'), findsOneWidget);
      
      // Verify actions
      expect(find.widgetWithText(PokeMapButton, 'Créer un projet'), findsOneWidget);
      expect(find.widgetWithText(PokeMapButton, 'Ouvrir un projet'), findsOneWidget);
    });
  });
}
```

## 20. Auto-review critique
* La migration de l'état vide isole l'affichage UI dans des fichiers propres et dédiés, augmentant la lisibilité de la base de code.
* Les tests de widgets mockent l'environnement macOS correctement (avec `_installMacosAccentColorMock`), ce qui évite les plantages système locaux.
* L'utilisation de `Wrap` résout proprement les contraintes d'overflow horizontales sur de petits viewports en mode test.

## 21. Limites restantes
* Le drag-and-drop de fichiers dans l'interface reste un indicateur textuel descriptif et n'a pas de logique de traitement d'événement actif à ce stade, comme demandé par les spécifications initiales.

## 22. Prochaine étape recommandée
* **Theme-7 — Project Explorer Module Cards Migration V0** : Poursuivre la migration de la sidebar gauche en remplaçant les en-têtes et cartes du World Explorer par des composants design-system.
