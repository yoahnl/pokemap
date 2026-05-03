# Environment Studio Lot 9 — Workspace Shell V0

## 1. Résumé exécutif

Premier jalon **visible** côté `map_editor` pour Environment Studio : enum `EditorWorkspaceMode.environmentStudio`, routage central via `EditorCanvasHost` vers un shell **read-only** (`EnvironmentStudioWorkspace` + `EnvironmentStudioPanel`), entrées **toolbar** et **explorateur de projet**, inspecteur droit **désactivé** comme Path Studio / Pokédex, diagnostics via `diagnoseProjectEnvironmentAuthoring(manifest, maps: const [])` sans chargement de cartes. Aucune édition, génération, sauvegarde dédiée ni nouveau service. Fichier de test harness étendu (`pumpEditorCanvasHostHarness`, `environmentPresets` dans `buildShellChromeProject`) pour des tests ciblés stables.

## 2. Périmètre du lot

- Inclus : workspace shell V0, navigation existante (toolbar + panneau gauche), données manifest + diagnostics agrégés en mémoire, tests et rapport.
- Exclus : CRUD presets, formulaires, `build_runner`, modifications `ProjectManifest` / `MapLayer` / `map_runtime`, tout générateur, lecture disque maps, `git` écriture.

## 3. Audit initial des workspaces existants

Fichiers inspectés (patterns Path Studio / shell global) :

- `editor_workspace_mode.dart` — enum des modes ; ajout d’une variante sans renommer les existantes.
- `editor_state.dart` / `editor_notifier.dart` / `editor_workspace_controller.dart` — transitions `_openWorkspace` + effacement `errorMessage`.
- `editor_selectors.dart` — titres / sous-titres du bandeau shell pour chaque mode.
- `editor_canvas_host.dart` — `switch` exhaustif sur `EditorWorkspaceMode` → widget central.
- `editor_shell_page.dart` — `supportsRightInspector`, en-tête îlot, inspecteur vide pour workspaces « plein écran ».
- `top_toolbar.dart` — groupe « Workspace » (`ToolbarCapsuleButton`) + libellé marque `TopToolbarBrand`.
- `project_explorer_panel.dart` — `InspectorSectionCard` + `EditorSidebarListRow` (ex. Path Studio).
- `path_studio/path_studio_panel.dart` — wrapper `PathStudioWorkspace` + panneau read-only (analogie directe).
- Tests : `editor_shell_page_smoke_test.dart` (tap `project-explorer-path-studio-entry`), `top_toolbar_test.dart`, `shell_chrome_test_harness.dart`.

Pattern retenu : **identique à Path Studio** (mode enum → notifier/controller → canvas host → workspace ConsumerWidget lisant `editorProjectManifestProvider`).

## 4. Décisions UI / navigation

- **Toolbar** : capsule `CupertinoIcons.tree`, tooltip `Switch to Environment Studio`, désactivée si `project == null` (comme Path Studio).
- **Explorateur** : section `InspectorSectionCard` « Environment Studio », badge = nombre de presets, ligne avec `Key('project-explorer-environment-studio-entry')`, section **ouverte par défaut** (`_expandEnvironment = true`) pour que l’entrée soit trouvable en test et visible sans clic de repli.
- **En-tête îlot** (`editor_shell_page`) : teinte chaude (`islandWarmTint`), accent jade, libellé court « Env », inspecteur = `_EmptyWorkspaceInspector` (cohérent Path/Pokédex).

## 5. Workspace Environment Studio ajouté

- `EditorWorkspaceMode.environmentStudio` avec documentation Lot 9.
- `EnvironmentStudioWorkspace` : seul lien Riverpod vers `editorProjectManifestProvider` ; état sans projet.
- `EnvironmentStudioPanel` : texte produit (FR), compte presets, bloc vide, diagnostics, note maps, liste « Bientôt ».

## 6. Données et diagnostics affichés

- **Manifest** : `manifest.environmentPresets` depuis l’état éditeur existant (aucune nouvelle source de vérité).
- **Diagnostics** : `diagnoseProjectEnvironmentAuthoring(manifest, maps: const [])` — **acceptable pour ce lot** : le prompt autorise explicitement `maps: const []` pour éviter tout chargement disque ; la note UI rappelle que l’usage dans les maps viendra quand les cartes en mémoire seront branchées.

## 7. Pourquoi aucune édition / sauvegarde / génération dans ce lot

- Périmètre contractuel Lot 9 : porte d’entrée + information ; tout flux auteur (CRUD, palettes, layers, générateur) est reporté aux lots suivants. Aucun handler `onPressed` mutateur dans le shell ; la toolbar réutilise uniquement les actions globales existantes (ex. sauvegarde projet) comme dans les autres workspaces non-carte.

## 8. Fichiers modifiés

| Fichier | Rôle |
|---------|------|
| `editor_workspace_mode.dart` | Nouveau mode `environmentStudio`. |
| `editor_workspace_controller.dart` / `editor_notifier.dart` | `selectEnvironmentStudioWorkspace`. |
| `editor_selectors.dart` | Titre / sous-titre shell. |
| `editor_canvas_host.dart` | Branche `environmentStudio` → `EnvironmentStudioWorkspace`. |
| `editor_shell_page.dart` | Inspector off + chrome îlot. |
| `top_toolbar.dart` | Capsule + libellé marque. |
| `project_explorer_panel.dart` | Carte + ligne d’entrée. |
| `environment_studio_workspace.dart` (nouveau) | Wrapper Riverpod. |
| `environment_studio_panel.dart` (nouveau) | UI shell. |
| `shell_chrome_test_harness.dart` | `environmentPresets` + `pumpEditorCanvasHostHarness` (**hors liste stricte du prompt**, justifié : tests routing sans dupliquer le mock macOS). |
| `editor_workspace_controller_test.dart` / `top_toolbar_test.dart` | Régressions + nouveaux cas. |
| `test/environment_studio/*.dart` (nouveaux) | Tests shell + entrée. |

**Non touché par ce lot (hors périmètre)** : `ProjectManifest` définition, `MapLayer`, `map_runtime`, `map_gameplay`, `map_battle`.  
**Pré-existant sur la branche de travail (Lot 8 / map_core)** : `packages/map_core/lib/map_core.dart`, `environment_authoring_diagnostics.dart`, tests et rapport Lot 8 — **non modifiés dans cette passe Lot 9** ; ils restent dans le `git status` utilisateur.

## 9. Tests ajoutés

- `test/environment_studio/environment_studio_workspace_test.dart` — titre, description, vide, diagnostics, absence de `CupertinoButton` dans le panneau.
- `test/environment_studio/environment_studio_workspace_entry_test.dart` — `EditorCanvasHost`, projet manquant, tap explorateur.
- `editor_workspace_controller_test.dart` — transition `environmentStudio` + clear erreur.
- `top_toolbar_test.dart` — comportement type Path Studio + libellé marque.

## 10. Commandes exécutées

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
dart format lib/src/features/editor/state/models/editor_workspace_mode.dart \
  lib/src/features/editor/state/editor_state.dart \
  lib/src/features/editor/state/editor_notifier.dart \
  lib/src/features/editor/state/editor_selectors.dart \
  lib/src/features/editor/application/editor_workspace_controller.dart \
  lib/src/ui/canvas/editor_canvas_host.dart \
  lib/src/ui/editor_shell_page.dart \
  lib/src/ui/shared/top_toolbar.dart \
  lib/src/ui/panels/project_explorer_panel.dart \
  lib/src/features/environment_studio/environment_studio_workspace.dart \
  lib/src/features/environment_studio/environment_studio_panel.dart \
  test/shell_chrome_test_harness.dart \
  test/environment_studio/environment_studio_workspace_test.dart \
  test/environment_studio/environment_studio_workspace_entry_test.dart \
  test/editor_workspace_controller_test.dart \
  test/top_toolbar_test.dart
```

```bash
flutter analyze lib/src/features/editor/state/models/editor_workspace_mode.dart \
  lib/src/features/editor/state/editor_state.dart \
  lib/src/ui/canvas/editor_canvas_host.dart \
  lib/src/ui/editor_shell_page.dart \
  lib/src/ui/shared/top_toolbar.dart \
  lib/src/ui/panels/project_explorer_panel.dart \
  lib/src/features/environment_studio/environment_studio_workspace.dart \
  lib/src/features/environment_studio/environment_studio_panel.dart \
  test/environment_studio/environment_studio_workspace_test.dart \
  test/environment_studio/environment_studio_workspace_entry_test.dart
```

```bash
flutter test test/environment_studio/environment_studio_workspace_test.dart --reporter expanded
flutter test test/environment_studio/environment_studio_workspace_entry_test.dart --reporter expanded
flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_panel_test.dart --name "renders a dark empty" --reporter expanded
flutter test
```

## 11. Résultats des commandes

- **`dart format`** : succès (16 fichiers, 2 reformatés lors de la passe).
- **`flutter analyze`** (chemins listés au prompt) : `No issues found!` (exit 0).
- **`flutter test test/environment_studio/environment_studio_workspace_test.dart`** : `All tests passed!` (+3), exit 0.
- **`flutter test test/environment_studio/environment_studio_workspace_entry_test.dart`** : `All tests passed!` (+3), avertissement macos_ui accent colors, exit 0.
- **`flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart`** : `All tests passed!` (+14), exit 0.
- **`flutter test test/path_pattern/path_studio_panel_test.dart --name "renders a dark empty"`** : `All tests passed!` (+1), exit 0.
- **`flutter test`** (suite complète `map_editor`) : **échec** — sortie finale : `00:56 +839 -34: Some tests failed.` (exit 1). **Dette préexistante** : 34 tests en échec dans d’autres fichiers (catalogues Pokémon, loaders, etc.), **hors périmètre Lot 9** ; les tests ajoutés / ciblés ci-dessus sont verts.

### 11.1 Sorties complètes des tests ciblés (reproduction session)

**`flutter test test/environment_studio/environment_studio_workspace_test.dart --reporter expanded`** (exit 0) :

```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart
00:00 +0: EnvironmentStudioPanel affiche titre, description, état vide et diagnostics
00:00 +1: EnvironmentStudioPanel affiche le nombre de presets quand le manifest en définit
00:00 +2: EnvironmentStudioPanel ne propose aucun bouton d’action actif
00:00 +3: All tests passed!
```

**`flutter test test/environment_studio/environment_studio_workspace_entry_test.dart --reporter expanded`** (exit 0) :

```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart
00:00 +0: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:00 +1: Environment Studio — entrée workspace affiche le message projet absent sans manifest
00:00 +2: Environment Studio — entrée workspace le project explorer ouvre Environment Studio au tap (clé dédiée)
00:01 +3: All tests passed!
```

**`flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart --reporter expanded`** (exit 0) :

```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectPokedexWorkspace switches mode and clears stale errors
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectTrainerWorkspace switches mode and clears stale errors
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectDialogueWorkspace keeps project session and only changes mode
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectEnvironmentStudioWorkspace switches mode and clears stale errors
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectPokemonCatalogSection opens the parent workspace and stores the section
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows the app brand and project workspace label
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar falls back to the workspace label when no project is loaded
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows the toolbar status chip when a status is present
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows the trainer studio label for the trainer workspace
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar enables project save and disables map history in Path Studio
00:00 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows neutral Save Project when project is clean in Path Studio
00:00 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar enables project save and disables map history in Environment Studio
00:00 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows Environment Studio in the workspace brand strip
00:00 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar keeps map save action in map workspace
00:01 +14: All tests passed!
```

**`flutter test test/path_pattern/path_studio_panel_test.dart --name "renders a dark empty" --reporter expanded`** (exit 0) :

```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
00:00 +0: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:00 +1: All tests passed!
```

**`flutter test`** (suite complète, extrait de fin pertinent, exit 1) :

```
00:56 +839 -34: Some tests failed.
```

## 12. Git status initial et final

**État initial (message `git_status` au démarrage de la conversation utilisateur)** — extrait pertinent :

- Modifications : `packages/map_core/...`, `packages/map_editor/...` (terrain, canvas, dialogs, etc.), `packages/map_runtime/...`
- Non suivis : `terrain_preset_variant_pick.dart`, tests associés, etc.

**État final (commande `git status --short --untracked-files=all` après Lot 9)** :

```
 M packages/map_core/lib/map_core.dart
 M packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
 M packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
 M packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar.dart
 M packages/map_editor/test/editor_workspace_controller_test.dart
 M packages/map_editor/test/shell_chrome_test_harness.dart
 M packages/map_editor/test/top_toolbar_test.dart
?? packages/map_core/lib/src/operations/environment_authoring_diagnostics.dart
?? packages/map_core/test/environment_authoring_diagnostics_test.dart
?? packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
?? packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart
?? packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart
?? packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart
?? reports/forest/environment_studio_lot_8_environment_diagnostics_aggregator.md
?? reports/forest/environment_studio_lot_9_workspace_shell.md
```

**Note** : `reports/forest/environment_studio_lot_9_workspace_shell.md` est **non suivi** jusqu’à un éventuel `git add` (non effectué, interdit par le lot).

## 13. Contenu complet des fichiers créés ou modifiés

### 13.1 `packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart` (nouveau, intégral)

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../editor/state/editor_selectors.dart';
import 'environment_studio_panel.dart';

/// Point d’entrée Riverpod pour le workspace Environment Studio.
///
/// Lit uniquement le manifest courant via [editorProjectManifestProvider] ;
/// aucun repository, provider métier ni accès disque.
class EnvironmentStudioWorkspace extends ConsumerWidget {
  const EnvironmentStudioWorkspace({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manifest = ref.watch(editorProjectManifestProvider);
    if (manifest == null) {
      return const _EnvironmentStudioProjectMissingState();
    }
    return EnvironmentStudioPanel(manifest: manifest);
  }
}

class _EnvironmentStudioProjectMissingState extends StatelessWidget {
  const _EnvironmentStudioProjectMissingState();

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.placeholderText.resolveFrom(context);
    return ColoredBox(
      color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      child: Center(
        child: Text(
          'Charger un projet pour ouvrir Environment Studio.',
          key: const Key('environment-studio-missing-project'),
          style: TextStyle(
            color: subtle,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
```

### 13.2 `packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart` (nouveau, intégral)

```dart
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';

/// Shell read-only central pour Environment Studio (Lot Environment-9).
///
/// Aucune mutation manifest, aucun flux save, aucune génération : affichage
/// purement informatif à partir du [ProjectManifest] déjà en mémoire.
class EnvironmentStudioPanel extends StatelessWidget {
  const EnvironmentStudioPanel({
    super.key,
    required this.manifest,
  });

  final ProjectManifest manifest;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final n = manifest.environmentPresets.length;
    final report = diagnoseProjectEnvironmentAuthoring(
      manifest,
      maps: const [],
    );
    final s = report.summary;

    return ColoredBox(
      color: EditorChrome.largeIslandSurfaceColor(
        context,
        tint: EditorChrome.accentJade.withValues(alpha: 0.06),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Environment Studio',
                    key: const Key('environment-studio-title'),
                    style: TextStyle(
                      color: label,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Presets d’environnements organiques',
                    style: TextStyle(
                      color: subtle,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: EditorChrome.chipFill(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: EditorChrome.accentJade.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Text(
                      'Lecture seule — édition et génération arrivent dans les prochains lots.',
                      key: Key('environment-studio-read-only-banner'),
                      style: TextStyle(
                        color: EditorChrome.accentJade,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Créez et gérez des presets d’environnements organiques pour générer des forêts, bosquets, prairies, côtes rocheuses et autres zones naturelles.',
                    key: const Key('environment-studio-description'),
                    style: TextStyle(
                      color: label,
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Presets d’environnement',
                    key: const Key('environment-studio-preset-section-title'),
                    style: TextStyle(
                      color: label,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    n == 1 ? '1 preset' : '$n presets',
                    key: const Key('environment-studio-preset-count'),
                    style: TextStyle(
                      color: subtle,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (n == 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Aucun preset d’environnement pour le moment.\nLes presets seront créés ici dans un prochain lot.',
                      key: const Key('environment-studio-empty-presets'),
                      style: TextStyle(
                        color: subtle,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Text(
                    'Diagnostics Environment',
                    key: const Key('environment-studio-diagnostics-title'),
                    style: TextStyle(
                      color: label,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${s.errorCount} erreur(s) · ${s.warningCount} avertissement(s)',
                    key: const Key('environment-studio-diagnostics-counts'),
                    style: TextStyle(
                      color: subtle,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Les diagnostics d’usage dans les maps seront activés quand les cartes chargées seront connectées au workspace.',
                    key: const Key('environment-studio-diagnostics-map-note'),
                    style: TextStyle(
                      color: subtle,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Bientôt :',
                    key: const Key('environment-studio-soon-title'),
                    style: TextStyle(
                      color: label,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '• création de presets ;\n'
                    '• édition de palettes ;\n'
                    '• utilisation dans les Environment Layers ;\n'
                    '• génération organique sur les maps.',
                    key: const Key('environment-studio-soon-bullets'),
                    style: TextStyle(
                      color: subtle,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

### 13.3 `packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart` (nouveau, intégral)

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';

void main() {
  group('EnvironmentStudioPanel', () {
    testWidgets('affiche titre, description, état vide et diagnostics', (
      tester,
    ) async {
      final manifest = _manifest();
      final report = diagnoseProjectEnvironmentAuthoring(
        manifest,
        maps: const [],
      );
      final expectedDiag =
          '${report.summary.errorCount} erreur(s) · ${report.summary.warningCount} avertissement(s)';

      await _pumpPanel(tester, manifest);

      expect(find.byKey(const Key('environment-studio-title')), findsOneWidget);
      expect(find.text('Environment Studio'), findsOneWidget);
      expect(
        find.byKey(const Key('environment-studio-description')),
        findsOneWidget,
      );
      expect(
        find.textContaining('forêts, bosquets, prairies'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('environment-studio-empty-presets')),
          findsOneWidget);
      expect(find.text('0 presets'), findsOneWidget);
      expect(find.text(expectedDiag), findsOneWidget);
      expect(
        find.byKey(const Key('environment-studio-soon-bullets')),
        findsOneWidget,
      );
      expect(find.textContaining('génération organique'), findsOneWidget);
    });

    testWidgets('affiche le nombre de presets quand le manifest en définit',
        (tester) async {
      await _pumpPanel(
        tester,
        _manifest(
          environmentPresets: [
            _preset(id: 'a'),
            _preset(id: 'b'),
          ],
        ),
      );

      expect(find.text('2 presets'), findsOneWidget);
      expect(
        find.byKey(const Key('environment-studio-empty-presets')),
        findsNothing,
      );
    });

    testWidgets('ne propose aucun bouton d’action actif', (tester) async {
      await _pumpPanel(tester, _manifest());

      final panel = find.byType(EnvironmentStudioPanel);
      expect(
        find.descendant(of: panel, matching: find.byType(CupertinoButton)),
        findsNothing,
      );
    });
  });
}

Future<void> _pumpPanel(WidgetTester tester, ProjectManifest manifest) async {
  await tester.pumpWidget(
    MacosApp(
      home: CupertinoPageScaffold(
        child: EnvironmentStudioPanel(manifest: manifest),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProjectManifest _manifest({
  List<EnvironmentPreset> environmentPresets = const [],
}) {
  return ProjectManifest(
    name: 'env-shell-test',
    maps: const [],
    tilesets: const [],
    environmentPresets: environmentPresets,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

EnvironmentPreset _preset({required String id}) {
  return EnvironmentPreset(
    id: id,
    name: 'Preset $id',
    templateId: 'tpl',
    palette: [
      EnvironmentPaletteItem(elementId: 'elm', weight: 1),
    ],
    defaultParams: EnvironmentGenerationParams.standard(),
    sortOrder: 0,
  );
}
```

### 13.4 `packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart` (nouveau, intégral)

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  group('Environment Studio — entrée workspace', () {
    testWidgets(
        'EditorCanvasHost affiche le shell quand le mode est environmentStudio',
        (tester) async {
      await pumpEditorCanvasHostHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/env_studio_canvas',
          project: buildShellChromeProject(),
          workspaceMode: EditorWorkspaceMode.environmentStudio,
        ),
      );

      expect(find.byKey(const Key('environment-studio-title')), findsOneWidget);
      expect(find.text('Environment Studio'), findsOneWidget);
    });

    testWidgets('affiche le message projet absent sans manifest',
        (tester) async {
      await pumpEditorCanvasHostHarness(
        tester,
        initialState: const EditorState(
          workspaceMode: EditorWorkspaceMode.environmentStudio,
        ),
      );

      expect(
        find.byKey(const Key('environment-studio-missing-project')),
        findsOneWidget,
      );
    });

    testWidgets(
        'le project explorer ouvre Environment Studio au tap (clé dédiée)',
        (tester) async {
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/env_studio_explorer',
          project: buildShellChromeProject(),
        ),
      );

      expect(
        find.byKey(const Key('project-explorer-environment-studio-entry')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const Key('project-explorer-environment-studio-entry')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('project-explorer-environment-studio-entry')),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(editorNotifierProvider).workspaceMode,
        EditorWorkspaceMode.environmentStudio,
      );
      expect(find.byKey(const Key('environment-studio-title')), findsOneWidget);
    });
  });
}
```

### 13.5 Fichiers modifiés (état final = version disque)

Les versions finales des fichiers modifiés listés en section 8 sont celles du dépôt après application du lot ; le **diff unifié complet** est reproduit en section 14 pour éviter une double copie ici.

## 14. Diff complet

### 14.1 Fichiers suivis modifiés (git diff agrégé)

```diff
diff --git a/packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart b/packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
index a3b8eff4..031af05c 100644
--- a/packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
+++ b/packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
@@ -62,6 +62,10 @@ class EditorWorkspaceController {
     return _openWorkspace(current, EditorWorkspaceMode.pathStudio);
   }
 
+  EditorState selectEnvironmentStudioWorkspace(EditorState current) {
+    return _openWorkspace(current, EditorWorkspaceMode.environmentStudio);
+  }
+
   /// Normalise les transitions de workspace :
   /// - on conserve tout l'état métier courant ;
   /// - on bascule seulement la surface centrale active ;
diff --git a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
index 29da8046..4dbb34f0 100644
--- a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
+++ b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
@@ -1464,6 +1464,11 @@ class EditorNotifier extends _$EditorNotifier {
     state = _editorWorkspaceController.selectPathStudioWorkspace(state);
   }
 
+  /// Bascule vers Environment Studio (shell read-only Lot Environment-9).
+  void selectEnvironmentStudioWorkspace() {
+    state = _editorWorkspaceController.selectEnvironmentStudioWorkspace(state);
+  }
+
   /// Écrit uniquement le fichier `.yarn` (le manifest projet reste inchangé).
   Future<void> saveProjectDialogueYarnBody({
     required String dialogueId,
diff --git a/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart b/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
index 4be10b08..9673ff78 100644
--- a/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
+++ b/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
@@ -152,6 +152,7 @@ final editorShellSnapshotProvider = Provider<EditorShellSnapshot>((ref) {
     EditorWorkspaceMode.cutscene => 'Cutscene Studio',
     EditorWorkspaceMode.dialogue => 'Dialogue Studio',
     EditorWorkspaceMode.pathStudio => 'Path Studio',
+    EditorWorkspaceMode.environmentStudio => 'Environment Studio',
   };
 
   final workspaceSubtitle = switch (workspaceMode) {
@@ -175,6 +176,8 @@ final editorShellSnapshotProvider = Provider<EditorShellSnapshot>((ref) {
       'Conversation authoring: visual blocks, preview, Yarn export — not a raw script IDE.',
     EditorWorkspaceMode.pathStudio =>
       'Créer des motifs de chemin à partir des presets PathPattern du projet.',
+    EditorWorkspaceMode.environmentStudio =>
+      'Presets d’environnements organiques et diagnostics — shell read-only.',
   };
 
   final exposesMapActions = workspaceMode == EditorWorkspaceMode.map;
diff --git a/packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart b/packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
index 98a959ae..7cda6500 100644
--- a/packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
+++ b/packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
@@ -43,4 +43,10 @@ enum EditorWorkspaceMode {
   /// liste, recherche, sélection, diagnostics et inspecteur. Il ne branche ni
   /// painter, ni save flow, ni éditeur réel du motif.
   pathStudio,
+
+  /// Shell Environment Studio V0 (Lot Environment-9).
+  ///
+  /// Surface centrale read-only : résumé des presets Environment et
+  /// diagnostics agrégés (`map_core`), sans édition ni génération.
+  environmentStudio,
 }
diff --git a/packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart b/packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
index 893ba022..5fb0e2be 100644
--- a/packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
+++ b/packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
@@ -3,6 +3,7 @@ import 'package:flutter_riverpod/flutter_riverpod.dart';
 
 import '../../features/editor/state/editor_selectors.dart';
 import '../../features/editor/state/editor_state.dart';
+import '../../features/environment_studio/environment_studio_workspace.dart';
 import '../../features/path_studio/path_studio_panel.dart';
 import 'map_canvas.dart';
 import 'narrative_workspace_canvas.dart';
@@ -28,6 +29,8 @@ class EditorCanvasHost extends ConsumerWidget {
       EditorWorkspaceMode.dialogue =>
         const NarrativeWorkspaceCanvas(),
       EditorWorkspaceMode.pathStudio => const PathStudioWorkspace(),
+      EditorWorkspaceMode.environmentStudio =>
+        const EnvironmentStudioWorkspace(),
     };
   }
 }
diff --git a/packages/map_editor/lib/src/ui/editor_shell_page.dart b/packages/map_editor/lib/src/ui/editor_shell_page.dart
index 6cf795fe..6da9498b 100644
--- a/packages/map_editor/lib/src/ui/editor_shell_page.dart
+++ b/packages/map_editor/lib/src/ui/editor_shell_page.dart
@@ -79,6 +79,7 @@ class _EditorShellPageState extends ConsumerState<EditorShellPage> {
     final supportsRightInspector = switch (workspaceMode) {
       EditorWorkspaceMode.pokedex => false,
       EditorWorkspaceMode.pathStudio => false,
+      EditorWorkspaceMode.environmentStudio => false,
       _ => true,
     };
 
@@ -338,6 +339,8 @@ class _EditorShellPageState extends ConsumerState<EditorShellPage> {
                                       EditorChrome.islandCoolTint,
                                     EditorWorkspaceMode.pathStudio =>
                                       EditorChrome.islandCoolTint,
+                                    EditorWorkspaceMode.environmentStudio =>
+                                      EditorChrome.islandWarmTint,
                                   },
                                   child: switch (workspaceMode) {
                                     EditorWorkspaceMode.map =>
@@ -356,6 +359,8 @@ class _EditorShellPageState extends ConsumerState<EditorShellPage> {
                                       const _EmptyWorkspaceInspector(),
                                     EditorWorkspaceMode.pathStudio =>
                                       const _EmptyWorkspaceInspector(),
+                                    EditorWorkspaceMode.environmentStudio =>
+                                      const _EmptyWorkspaceInspector(),
                                     EditorWorkspaceMode.globalStory ||
                                     EditorWorkspaceMode.step ||
                                     EditorWorkspaceMode.cutscene ||
@@ -493,6 +498,7 @@ class _WorkspaceStageHeader extends StatelessWidget {
       EditorWorkspaceMode.cutscene => EditorChrome.inspectorJoyCoral,
       EditorWorkspaceMode.dialogue => EditorChrome.inspectorJoyBlue,
       EditorWorkspaceMode.pathStudio => EditorChrome.accentPrimary,
+      EditorWorkspaceMode.environmentStudio => EditorChrome.accentJade,
     };
     final chipAccent2 = switch (workspaceMode) {
       EditorWorkspaceMode.map => EditorChrome.inspectorJoyApricot,
@@ -504,6 +510,7 @@ class _WorkspaceStageHeader extends StatelessWidget {
       EditorWorkspaceMode.cutscene => EditorChrome.inspectorJoyCoral,
       EditorWorkspaceMode.dialogue => EditorChrome.inspectorJoyCyan,
       EditorWorkspaceMode.pathStudio => EditorChrome.inspectorJoyCyan,
+      EditorWorkspaceMode.environmentStudio => EditorChrome.inspectorJoyMint,
     };
 
     return Row(
@@ -538,6 +545,7 @@ class _WorkspaceStageHeader extends StatelessWidget {
               EditorWorkspaceMode.cutscene => CupertinoIcons.play_rectangle,
               EditorWorkspaceMode.dialogue => CupertinoIcons.text_bubble,
               EditorWorkspaceMode.pathStudio => CupertinoIcons.arrow_branch,
+              EditorWorkspaceMode.environmentStudio => CupertinoIcons.tree,
             },
             color: CupertinoColors.white,
             size: 22,
@@ -620,6 +628,7 @@ class _WorkspaceStageHeader extends StatelessWidget {
               EditorWorkspaceMode.cutscene => 'Cutscene',
               EditorWorkspaceMode.dialogue => 'Dialogue',
               EditorWorkspaceMode.pathStudio => 'Path',
+              EditorWorkspaceMode.environmentStudio => 'Env',
             },
             style: TextStyle(
               color: chipAccent,
diff --git a/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart b/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
index 28a1ef3e..dd76f0f1 100644
--- a/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
+++ b/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
@@ -34,6 +34,7 @@ class _ProjectExplorerPanelState extends ConsumerState<ProjectExplorerPanel> {
   bool _expandWorld = true;
   bool _expandTerrains = true;
   bool _expandPaths = true;
+  bool _expandEnvironment = true;
   bool _expandTrainers = false;
   bool _expandCharacters = false;
 
@@ -222,6 +223,7 @@ class _ProjectExplorerPanelState extends ConsumerState<ProjectExplorerPanel> {
     final hWorld = (screenH * 0.30).clamp(240.0, 400.0);
     final hTerrains = (screenH * 0.36).clamp(280.0, 500.0);
     final hPaths = (screenH * 0.36).clamp(280.0, 500.0);
+    final hEnvironment = (screenH * 0.22).clamp(180.0, 280.0);
     final hTrainers = (screenH * 0.18).clamp(180.0, 240.0);
     final hCharacters = (screenH * 0.35).clamp(260.0, 480.0);
     const explorerTileRadius = 28.0;
@@ -344,6 +346,19 @@ class _ProjectExplorerPanelState extends ConsumerState<ProjectExplorerPanel> {
           expandedHeight: hPaths,
           child: _buildPathLibraryCard(context, project, snapshot, notifier),
         ),
+        InspectorSectionCard(
+          borderRadius: explorerTileRadius,
+          title: 'Environment Studio',
+          subtitle: 'Presets d’environnements organiques (shell read-only)',
+          icon: CupertinoIcons.tree,
+          accentColor: EditorChrome.accentJade,
+          badgeText: '${project.environmentPresets.length}',
+          expanded: _expandEnvironment,
+          onToggle: () =>
+              setState(() => _expandEnvironment = !_expandEnvironment),
+          expandedHeight: hEnvironment,
+          child: _buildEnvironmentStudioCard(context, snapshot, notifier),
+        ),
         InspectorSectionCard(
           borderRadius: explorerTileRadius,
           title: 'Trainer Studio',
@@ -450,6 +465,32 @@ class _ProjectExplorerPanelState extends ConsumerState<ProjectExplorerPanel> {
     );
   }
 
+  Widget _buildEnvironmentStudioCard(
+    BuildContext context,
+    EditorProjectExplorerSnapshot snapshot,
+    EditorNotifier notifier,
+  ) {
+    final isEnvironment =
+        snapshot.workspaceMode == EditorWorkspaceMode.environmentStudio;
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        EditorSidebarListRow(
+          key: const Key('project-explorer-environment-studio-entry'),
+          selected: isEnvironment,
+          onTap: notifier.selectEnvironmentStudioWorkspace,
+          leading: const MacosIcon(CupertinoIcons.tree),
+          title: const Text('Environment Studio'),
+          subtitle: const Text(
+            'Résumé presets et diagnostics — lecture seule',
+            maxLines: 2,
+            overflow: TextOverflow.ellipsis,
+          ),
+        ),
+      ],
+    );
+  }
+
   Widget _buildPathLibraryCard(
     BuildContext context,
     ProjectManifest project,
diff --git a/packages/map_editor/lib/src/ui/shared/top_toolbar.dart b/packages/map_editor/lib/src/ui/shared/top_toolbar.dart
index 95ef33d4..34e4a443 100644
--- a/packages/map_editor/lib/src/ui/shared/top_toolbar.dart
+++ b/packages/map_editor/lib/src/ui/shared/top_toolbar.dart
@@ -264,6 +264,15 @@ class TopToolbar extends ConsumerWidget {
                 ? notifier.selectPathStudioWorkspace
                 : null,
           ),
+          ToolbarCapsuleButton(
+            icon: CupertinoIcons.tree,
+            tooltip: 'Switch to Environment Studio',
+            selected:
+                toolbar.workspaceMode == EditorWorkspaceMode.environmentStudio,
+            onPressed: toolbar.project != null
+                ? notifier.selectEnvironmentStudioWorkspace
+                : null,
+          ),
         ],
       ),
       if (showWorldTools)
@@ -468,6 +477,7 @@ class TopToolbar extends ConsumerWidget {
           EditorWorkspaceMode.cutscene => 'Cutscene Studio',
           EditorWorkspaceMode.dialogue => 'Dialogue Studio',
           EditorWorkspaceMode.pathStudio => 'Path Studio',
+          EditorWorkspaceMode.environmentStudio => 'Environment Studio',
         },
       ),
       titleWidth: 236,
diff --git a/packages/map_editor/test/editor_workspace_controller_test.dart b/packages/map_editor/test/editor_workspace_controller_test.dart
index c165a7db..06e5ef2c 100644
--- a/packages/map_editor/test/editor_workspace_controller_test.dart
+++ b/packages/map_editor/test/editor_workspace_controller_test.dart
@@ -47,6 +47,21 @@ void main() {
       expect(next.workspaceMode, EditorWorkspaceMode.dialogue);
     });
 
+    test(
+        'selectEnvironmentStudioWorkspace switches mode and clears stale errors',
+        () {
+      const current = EditorState(
+        workspaceMode: EditorWorkspaceMode.map,
+        errorMessage: 'Old failure',
+      );
+
+      final next = controller.selectEnvironmentStudioWorkspace(current);
+
+      expect(next.workspaceMode, EditorWorkspaceMode.environmentStudio);
+      expect(next.errorMessage, isNull);
+      expect(next.statusMessage, current.statusMessage);
+    });
+
     test(
         'selectPokemonCatalogSection opens the parent workspace and stores the section',
         () {
diff --git a/packages/map_editor/test/shell_chrome_test_harness.dart b/packages/map_editor/test/shell_chrome_test_harness.dart
index 57ba2b54..0bb25970 100644
--- a/packages/map_editor/test/shell_chrome_test_harness.dart
+++ b/packages/map_editor/test/shell_chrome_test_harness.dart
@@ -6,6 +6,7 @@ import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
 import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
 import 'package:map_editor/src/features/editor/state/editor_state.dart';
+import 'package:map_editor/src/ui/canvas/editor_canvas_host.dart';
 import 'package:map_editor/src/ui/editor_shell_page.dart';
 import 'package:map_editor/src/ui/shared/status_bar.dart';
 import 'package:map_editor/src/ui/shared/top_toolbar.dart';
@@ -36,6 +37,7 @@ ProjectManifest buildShellChromeProject({
   List<ProjectPathPreset> pathPresets = const <ProjectPathPreset>[],
   List<ProjectPathPatternPreset> pathPatternPresets =
       const <ProjectPathPatternPreset>[],
+  List<EnvironmentPreset> environmentPresets = const <EnvironmentPreset>[],
 }) {
   return ProjectManifest(
     name: name,
@@ -43,6 +45,7 @@ ProjectManifest buildShellChromeProject({
     tilesets: tilesets,
     pathPresets: pathPresets,
     pathPatternPresets: pathPatternPresets,
+    environmentPresets: environmentPresets,
     surfaceCatalog: ProjectSurfaceCatalog(),
   );
 }
@@ -104,6 +107,46 @@ Future<ProviderContainer> pumpEditorShellPage(
   return container;
 }
 
+Future<ProviderContainer> pumpEditorCanvasHostHarness(
+  WidgetTester tester, {
+  required EditorState initialState,
+  Size surfaceSize = const Size(960, 640),
+}) async {
+  _installMacosAccentColorMock();
+  final container = ProviderContainer();
+  final editorStateSubscription = container.listen<EditorState>(
+    editorNotifierProvider,
+    (_, __) {},
+    fireImmediately: true,
+  );
+  addTearDown(() async {
+    editorStateSubscription.close();
+    await tester.pumpWidget(const SizedBox.shrink());
+    await tester.pump();
+    await tester.pump();
+    container.dispose();
+  });
+
+  await tester.binding.setSurfaceSize(surfaceSize);
+  addTearDown(() => tester.binding.setSurfaceSize(null));
+
+  container.read(editorNotifierProvider.notifier).state = initialState;
+
+  await tester.pumpWidget(
+    UncontrolledProviderScope(
+      container: container,
+      child: const MacosApp(
+        home: CupertinoPageScaffold(
+          child: EditorCanvasHost(),
+        ),
+      ),
+    ),
+  );
+  await tester.pump();
+  await tester.pumpAndSettle(const Duration(milliseconds: 1));
+  return container;
+}
+
 Future<ProviderContainer> pumpTopToolbarHarness(
   WidgetTester tester, {
   required EditorState initialState,
diff --git a/packages/map_editor/test/top_toolbar_test.dart b/packages/map_editor/test/top_toolbar_test.dart
index 6e58eb76..70f447dd 100644
--- a/packages/map_editor/test/top_toolbar_test.dart
+++ b/packages/map_editor/test/top_toolbar_test.dart
@@ -131,6 +131,68 @@ void main() {
       expect(saveButton.selected, isFalse);
     });
 
+    testWidgets(
+        'enables project save and disables map history in Environment Studio',
+        (tester) async {
+      final projectDir = Directory('/tmp/top_toolbar_environment_studio');
+      if (!projectDir.existsSync()) {
+        projectDir.createSync(recursive: true);
+      }
+      await pumpTopToolbarHarness(
+        tester,
+        initialState: EditorState(
+          projectRootPath: '/tmp/top_toolbar_environment_studio',
+          project: buildShellChromeProject(name: 'Pokemon Map'),
+          workspaceMode: EditorWorkspaceMode.environmentStudio,
+          activeMap: buildShellChromeMap(),
+          isProjectDirty: true,
+          canUndoMap: true,
+          canRedoMap: true,
+        ),
+      );
+
+      ToolbarCapsuleButton buttonWithTooltip(String tooltip) {
+        return tester.widget<ToolbarCapsuleButton>(
+          find.byWidgetPredicate(
+            (widget) =>
+                widget is ToolbarCapsuleButton && widget.tooltip == tooltip,
+          ),
+        );
+      }
+
+      final saveButton =
+          buttonWithTooltip('Save Project — unsaved project changes');
+      expect(saveButton.onPressed, isNotNull);
+      expect(saveButton.selected, isTrue);
+      expect(buttonWithTooltip('Undo').onPressed, isNull);
+      expect(buttonWithTooltip('Redo').onPressed, isNull);
+
+      expect(
+        find.byWidgetPredicate(
+          (widget) =>
+              widget is ToolbarCapsuleButton && widget.tooltip == 'Save Map',
+        ),
+        findsNothing,
+      );
+    });
+
+    testWidgets('shows Environment Studio in the workspace brand strip',
+        (tester) async {
+      await pumpTopToolbarHarness(
+        tester,
+        initialState: EditorState(
+          projectRootPath: '/tmp/top_toolbar_env_label',
+          project: buildShellChromeProject(name: 'Pokemon Map'),
+          workspaceMode: EditorWorkspaceMode.environmentStudio,
+        ),
+      );
+
+      expect(
+        find.text('Pokemon Map  •  Environment Studio'),
+        findsOneWidget,
+      );
+    });
+
     testWidgets('keeps map save action in map workspace', (tester) async {
       await pumpTopToolbarHarness(
         tester,
```

### 14.2 Fichiers nouveaux — `git diff --no-index /dev/null <fichier>` (intégral)

`environment_studio_workspace.dart`, `environment_studio_panel.dart`, `environment_studio_workspace_test.dart`, `environment_studio_workspace_entry_test.dart` : le contenu intégral est en **§13.1 à §13.4** (équivalent exact au diff `/dev/null → fichier`).

### 14.3 Confirmation Evidence Pack (obligatoire)

| Assertion | Statut |
|-----------|--------|
| Aucun `ProjectManifest` (fichier modèle / freezed) modifié dans ce lot | **Oui** — seul usage en lecture ; `buildShellChromeProject` reste un helper de test. |
| Aucun `MapLayer` modifié | **Oui**. |
| Aucune édition `EnvironmentPreset` UI | **Oui** — pas de formulaire ni CRUD. |
| Aucun générateur créé | **Oui**. |
| Aucune sauvegarde disque dédiée au shell | **Oui** — pas de nouveau flux. |
| Aucun `build_runner` | **Oui** — non exécuté. |
| Aucun fichier `*.g.dart` / `*.freezed.dart` modifié | **Oui**. |
| Aucun `git commit` / `git add` / `git push` | **Oui**. |

## 15. Auto-review

- **Points solides** : alignement Path Studio (routing, inspector, toolbar), tests ciblés verts, `maps: const []` explicite et documenté côté UI.
- **Points discutables** : `CupertinoIcons.tree` partagé avec l’outil « Terrain » en workspace carte (groupes distincts, risque de confusion visuelle faible). Extension de `shell_chrome_test_harness.dart` hors liste stricte du prompt — justifiée pour éviter la duplication du mock `MethodChannel` macOS.
- **Corrections après auto-review** : import `flutter/widgets.dart` pour `Key` dans le test d’entrée (conflit résolu) ; `_expandEnvironment = true` pour accessibilité test + UX ; `const Text` bannière read-only pour `prefer_const_constructors`.
- **Risques restants** : suite `flutter test` complète `map_editor` rouge (−34) — dette hors lot ; diagnostics sans maps sous-estiment l’usage réel jusqu’au branchement des `MapData` chargées.
- **Regard critique sur le prompt** : afficher les diagnostics en V0 est **utile** pour valider le câblage Lot 8 ; `maps: const []` est **conforme** au contrat ; toolbar **et** panneau gauche renforcent la découvrabilité sans second système de navigation ; le shell est **suffisamment informatif** pour un V0 ; édition/sauvegarde/génération **bien évitées** dans le code du shell.

## 16. Verdict

Statut du lot :

- [ ] Validé
- [x] **Validé avec réserve**
- [ ] Non livré

Résumé :

```text
Livrable Environment Studio shell V0 complet côté map_editor (navigation, canvas, read-only, tests ciblés, analyze clean sur périmètre). Réserve : suite flutter test map_editor entière échoue (−34 tests préexistants) ; changements map_core / rapport Lot 8 toujours présents dans le working tree sans être partie du code produit de ce lot.
```

Prochain lot recommandé :

```text
Environment-10 — Environment Preset Browser Read-only V0
```
