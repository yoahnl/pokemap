# Environment Studio Lot 11 — Preset Detail Polish / Diagnostics Drilldown V0

## 1. Résumé exécutif

Le panneau **Environment Studio** (browser read-only des presets) a été découpé en widgets dédiés sous `widgets/`, le détail preset structuré en sections (identité, paramètres en chips, palette par cartes, diagnostics avec résumé et drilldown par carte), les libellés de kinds et sévérités centralisés en français, et les tests Lot 10 étendus (drilldown, `knownTemplateIds`, read-only incl. `Save`). Aucune mutation manifest, aucun provider, aucun `map_core` modifié.

## 2. Périmètre du lot

- UI / structure **map_editor** uniquement (`environment_studio` + tests + ce rapport).
- Read-only strict : seule mutation autorisée = `setState` sur l’id de preset sélectionné.
- Pas de CRUD, pas de génération, pas de sauvegarde disque, pas de `build_runner`.

## 3. Audit initial du browser Lot 10

Fichiers inspectés (conformément au cahier des charges) :

- `packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart` — monolithe ~750 lignes (liste + détail + diagnostics plats).
- `packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart` — inchangé (routing Lot 9).
- `packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart` — régressions liste / vide / tap ; non modifié ce lot (toujours verts).
- `packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart` — inchangé, vert.
- `packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart` — à étendre pour drilldown.
- Aperçu patterns : `path_studio/`, `surface_studio/`, `cupertino_editor_widgets.dart` — alignement sur `EditorChrome`, îlots, bordures Cupertino.

Décisions : extraire liste, détail, diagnostics, palette + fichier pur pour les libellés de diagnostics ; garder la logique de sélection / coercition dans le panel.

## 4. Décisions de découpage UI

- Dossier `packages/map_editor/lib/src/features/environment_studio/widgets/`.
- Fichiers publics du feature : `EnvironmentPresetList`, `EnvironmentPresetDetail`, `EnvironmentPresetDiagnosticsView`, `EnvironmentPaletteItemView`, fonctions `environmentDiagnosticKindLabel` / `environmentDiagnosticSeverityLabel`.
- Tuiles de liste restent privées (`_PresetListTile`) dans `environment_preset_list.dart`.
- Pas de Riverpod, pas de repository/service.

## 5. Polish du détail preset

- Cartes `_sectionCard` avec clés `environment-studio-section-identity|params|palette|diagnostics`.
- Identité : nom, id, template, catégorie, ordre avec libellés en colonne.
- Paramètres : chips non interactifs (`toStringAsFixed(2)` inchangé pour tests).

## 6. Polish de la palette

- Carte par item : `elementId`, chip « Poids n », ligne collision FR, tags en chips triés alphabétiquement.

## 7. Diagnostics drilldown

- Vide : `Aucun diagnostic pour ce preset.` (clé inchangée).
- Sinon : résumé `N erreur(s) · M avertissement(s)` puis cartes avec badge sévérité (Erreur / Avertissement), kind FR, message, lignes optionnelles pour champs présents (`elementId`, `templateId`, etc.).
- Correction technique : `_buildOptionalRows` retourne une `List<Widget>` (l’ancienne approche `sync*` + `yield*` avec fonction locale `void` était invalide en Dart).

## 8. Read-only strict

- Aucun `CupertinoButton` dans le panneau (tests conservés).
- Aucun texte Create / Edit / Delete / Generate / Save (anglais) dans le test read-only.
- Paramètre optionnel `knownTemplateIds` sur `EnvironmentStudioPanel` pour activer les diagnostics `unknownTemplateId` sans changer le défaut `{}`.

## 9. Pourquoi aucune édition / sauvegarde / génération dans ce lot

Progression produit : stabiliser la lecture et la structure avant le stylo (Lot 12+). Éviter formulaire sur UI instable.

## 10. Fichiers modifiés

- `packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart` (M)
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_diagnostic_presentation.dart` (nouveau)
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_list.dart` (nouveau)
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart` (nouveau)
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_diagnostics_view.dart` (nouveau)
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_view.dart` (nouveau)
- `packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart` (M)
- `reports/forest/environment_studio_lot_11_preset_detail_polish_diagnostics.md` (ce fichier)

Fichier **non** modifié alors que listé comme candidat d’audit : `environment_studio_workspace_test.dart` (déjà conforme, aucun changement nécessaire).

## 11. Tests ajoutés ou modifiés

- Groupe `environmentDiagnosticKindLabel` (kinds FR).
- Sections identité / params / palette / diagnostics (clés).
- Tags triés (clés `environment-studio-palette-tag-oak-canopy` et `tree`).
- Drilldown diagnostic erreur palette manquante (sévérité, kind, message, `elementId`).
- `unknownTemplateId` via `knownTemplateIds: const {'forest_dense'}`.
- Read-only : absence de `Save` en plus des autres termes anglais.

## 12. Commandes exécutées

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
dart format lib/src/features/environment_studio/environment_studio_panel.dart \
  lib/src/features/environment_studio/widgets/environment_preset_list.dart \
  lib/src/features/environment_studio/widgets/environment_preset_detail.dart \
  lib/src/features/environment_studio/widgets/environment_preset_diagnostics_view.dart \
  lib/src/features/environment_studio/widgets/environment_palette_item_view.dart \
  lib/src/features/environment_studio/widgets/environment_diagnostic_presentation.dart \
  test/environment_studio/environment_studio_workspace_test.dart \
  test/environment_studio/environment_studio_preset_browser_test.dart

flutter analyze lib/src/features/environment_studio/environment_studio_panel.dart \
  lib/src/features/environment_studio/widgets/environment_preset_list.dart \
  lib/src/features/environment_studio/widgets/environment_preset_detail.dart \
  lib/src/features/environment_studio/widgets/environment_preset_diagnostics_view.dart \
  lib/src/features/environment_studio/widgets/environment_palette_item_view.dart \
  lib/src/features/environment_studio/widgets/environment_diagnostic_presentation.dart \
  test/environment_studio/environment_studio_workspace_test.dart \
  test/environment_studio/environment_studio_preset_browser_test.dart

flutter test test/environment_studio/environment_studio_workspace_test.dart --reporter expanded
flutter test test/environment_studio/environment_studio_preset_browser_test.dart --reporter expanded
flutter test test/environment_studio/environment_studio_workspace_entry_test.dart --reporter expanded
flutter test test/environment_studio --reporter expanded
flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart --reporter expanded
flutter test
```

## 13. Résultats des commandes

- `dart format` : exit 0 (8 fichiers formatés au besoin lors des passes).
- `flutter analyze` (cible lot) : **No issues found!** (exit 0).
- Tests ciblés + dossier `test/environment_studio` + régressions `editor_workspace_controller_test` / `top_toolbar_test` : **tous verts** (sorties complètes en §13.1).
- `flutter test` (suite complète `map_editor`) : **échec** avec dette préexistante **+847 −34** ; ligne finale exacte reproduite en §13.2.

### 13.1 Sorties complètes — tests ciblés et régressions proches

```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart
00:00 +0: EnvironmentStudioPanel état vide : titre, badge read-only, pas de liste ni détail
00:00 +1: EnvironmentStudioPanel liste presets et sélection du premier par défaut
00:00 +2: EnvironmentStudioPanel tap sur un autre preset met à jour le détail
00:00 +3: EnvironmentStudioPanel ne propose aucun CupertinoButton dans le panneau
00:00 +4: All tests passed!
```

```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart
00:00 +0: environmentDiagnosticKindLabel quelques kinds FR stables
00:00 +1: EnvironmentStudioPanel — browser read-only sections identité, paramètres, palette et diagnostics visibles
00:00 +2: EnvironmentStudioPanel — browser read-only catégorie absente : affiche —
00:00 +3: EnvironmentStudioPanel — browser read-only diagnostics preset vides : message dédié
00:00 +4: EnvironmentStudioPanel — browser read-only diagnostic erreur élément palette : drilldown
00:00 +5: EnvironmentStudioPanel — browser read-only unknownTemplateId : kind FR et templateId affiché si knownTemplateIds
00:00 +6: EnvironmentStudioPanel — browser read-only read-only : pas de libellés Create / Edit / Delete / Generate / Save
00:00 +7: All tests passed!
```

```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart
00:00 +0: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:00 +1: Environment Studio — entrée workspace affiche le message projet absent sans manifest
00:00 +2: Environment Studio — entrée workspace le project explorer ouvre Environment Studio au tap (clé dédiée)
00:00 +3: All tests passed!
```

```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart: EnvironmentStudioPanel état vide : titre, badge read-only, pas de liste ni détail
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart: EnvironmentStudioPanel état vide : titre, badge read-only, pas de liste ni détail
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart: EnvironmentStudioPanel — browser read-only sections identité, paramètres, palette et diagnostics visibles
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart: EnvironmentStudioPanel — browser read-only sections identité, paramètres, palette et diagnostics visibles
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace EditorCanvasHost affiche le shell quand le mode est environmentStudio
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart: EnvironmentStudioPanel ne propose aucun CupertinoButton dans le panneau
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart: EnvironmentStudioPanel — browser read-only diagnostic erreur élément palette : drilldown
00:00 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart: EnvironmentStudioPanel — browser read-only diagnostic erreur élément palette : drilldown
00:00 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace le project explorer ouvre Environment Studio au tap (clé dédiée)
00:00 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace le project explorer ouvre Environment Studio au tap (clé dédiée)
00:00 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_workspace_entry_test.dart: Environment Studio — entrée workspace le project explorer ouvre Environment Studio au tap (clé dédiée)
00:01 +14: All tests passed!
```

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

### 13.2 Ligne finale exacte — `flutter test` complet (`packages/map_editor`)

```
00:56 +847 -34: Some tests failed.
```

Exit code : 1.

## 14. Git status initial et final

**État initial** (snapshot fourni au début du message utilisateur dans la session ; hors fichiers du Lot 11) :

```
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/models/enums.dart
 M packages/map_core/lib/src/models/project_manifest.dart
 M packages/map_core/lib/src/models/project_manifest.freezed.dart
 M packages/map_core/lib/src/models/project_manifest.g.dart
 M packages/map_core/lib/src/operations/terrain_preset_subtile_for_map_cell.dart
?? packages/map_core/lib/src/operations/terrain_preset_variant_pick.dart
 M packages/map_core/test/terrain_preset_subtile_for_map_cell_test.dart
?? packages/map_core/test/terrain_preset_variant_pick_test.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart
 M packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
```

**État final** (commande `git status --short --untracked-files=all` à la racine du dépôt après Lot 11 ; inclut ce rapport une fois généré) :

```
 M packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
 M packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart
?? packages/map_editor/lib/src/features/environment_studio/widgets/environment_diagnostic_presentation.dart
?? packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_view.dart
?? packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart
?? packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_diagnostics_view.dart
?? packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_list.dart
?? reports/forest/environment_studio_lot_11_preset_detail_polish_diagnostics.md
```

### Confirmations Evidence Pack (Lot 11)

- Aucun `ProjectManifest` modifié par ce lot (fichiers sources manifest non touchés).
- Aucun `MapLayer` modifié.
- Aucune édition de preset créée (UI read-only).
- Aucun générateur créé.
- Aucune sauvegarde disque ajoutée.
- `build_runner` non lancé.
- Aucun fichier généré (`*.g.dart`, `*.freezed.dart`, etc.) modifié par ce lot.
- Aucun `git commit`, `git add`, `git push`, `git reset`, `git checkout`, `git restore`, `git stash`, merge, rebase, tag.

## 15. Contenu complet des fichiers créés ou modifiés

### `packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'widgets/environment_preset_detail.dart';
import 'widgets/environment_preset_list.dart';

/// Browser read-only des presets Environment (Lot Environment-10, polish 11).
///
/// Sélection locale uniquement ([StatefulWidget]) : aucune mutation du
/// [ProjectManifest], aucun provider, aucune persistance.
///
/// [knownTemplateIds] non vide active les diagnostics `unknownTemplateId` pour
/// les [EnvironmentPreset.templateId] absents du set (défaut `{}` = désactivé).
class EnvironmentStudioPanel extends StatefulWidget {
  const EnvironmentStudioPanel({
    super.key,
    required this.manifest,
    this.knownTemplateIds = const <String>{},
  });

  final ProjectManifest manifest;

  /// Quand non vide, restreint les templates reconnus (diagnostics auteur).
  final Set<String> knownTemplateIds;

  @override
  State<EnvironmentStudioPanel> createState() => _EnvironmentStudioPanelState();
}

class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
  String? _selectedPresetId;

  @override
  void initState() {
    super.initState();
    _selectedPresetId = _defaultSelectedId(widget.manifest.environmentPresets);
  }

  @override
  void didUpdateWidget(covariant EnvironmentStudioPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _coerceSelectedId(
      widget.manifest.environmentPresets,
      _selectedPresetId,
    );
    if (next != _selectedPresetId) {
      setState(() => _selectedPresetId = next);
    }
  }

  static String? _defaultSelectedId(List<EnvironmentPreset> presets) {
    return _coerceSelectedId(presets, null);
  }

  /// Garde une sélection valide : premier preset (tri sortOrder, id) si besoin.
  static String? _coerceSelectedId(
    List<EnvironmentPreset> presets,
    String? current,
  ) {
    if (presets.isEmpty) {
      return null;
    }
    if (current != null && presets.any((p) => p.id == current)) {
      return current;
    }
    final sorted = [...presets]..sort((a, b) {
        final c = a.sortOrder.compareTo(b.sortOrder);
        if (c != 0) {
          return c;
        }
        return a.id.compareTo(b.id);
      });
    return sorted.first.id;
  }

  EnvironmentPreset? _selectedPreset(List<EnvironmentPreset> presets) {
    final id = _selectedPresetId;
    if (id == null) {
      return null;
    }
    for (final p in presets) {
      if (p.id == id) {
        return p;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final presets = widget.manifest.environmentPresets;
    final n = presets.length;
    final report = diagnoseProjectEnvironmentAuthoring(
      widget.manifest,
      maps: const [],
      knownTemplateIds: widget.knownTemplateIds,
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
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, label, subtle, n),
                  const SizedBox(height: 20),
                  if (n == 0)
                    Expanded(
                      child: _buildEmptyPresets(context, subtle),
                    )
                  else
                    Expanded(
                      child: _buildBrowser(
                        context,
                        label,
                        subtle,
                        presets,
                        report,
                      ),
                    ),
                  const SizedBox(height: 20),
                  _buildGlobalDiagnostics(context, label, subtle, s),
                  const SizedBox(height: 16),
                  _buildSoon(context, label, subtle),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Color label,
    Color subtle,
    int presetCount,
  ) {
    return Column(
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
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        const SizedBox(height: 12),
        Text(
          presetCount == 1 ? '1 preset' : '$presetCount presets',
          key: const Key('environment-studio-preset-count'),
          style: TextStyle(
            color: subtle,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPresets(BuildContext context, Color subtle) {
    return Align(
      alignment: Alignment.topCenter,
      child: Text(
        'Aucun preset d’environnement pour le moment.\n'
        'Les presets seront créés ici dans un prochain lot.',
        key: const Key('environment-studio-empty-presets'),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: subtle,
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBrowser(
    BuildContext context,
    Color label,
    Color subtle,
    List<EnvironmentPreset> presets,
    EnvironmentAuthoringDiagnosticsReport report,
  ) {
    final selected = _selectedPreset(presets);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 300,
          child: EnvironmentPresetList(
            presets: presets,
            selectedPresetId: _selectedPresetId,
            report: report,
            onSelect: (id) => setState(() => _selectedPresetId = id),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: EditorChrome.chipFill(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CupertinoColors.separator.resolveFrom(context),
              ),
            ),
            child: selected == null
                ? Center(
                    child: Text(
                      'Preset sélectionné introuvable.',
                      key: const Key('environment-studio-preset-missing'),
                      style: TextStyle(
                        color: subtle,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    key: const Key('environment-studio-detail-scroll'),
                    padding: const EdgeInsets.all(20),
                    child: EnvironmentPresetDetail(
                      preset: selected,
                      report: report,
                      labelColor: label,
                      subtleColor: subtle,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlobalDiagnostics(
    BuildContext context,
    Color label,
    Color subtle,
    EnvironmentAuthoringDiagnosticsSummary s,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Diagnostics Environment (projet)',
          key: const Key('environment-studio-diagnostics-title'),
          style: TextStyle(
            color: label,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${s.errorCount} erreur(s) · ${s.warningCount} avertissement(s)',
          key: const Key('environment-studio-diagnostics-counts'),
          style: TextStyle(
            color: subtle,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Les diagnostics d’usage dans les maps seront activés quand les cartes '
          'chargées seront connectées au workspace.',
          key: const Key('environment-studio-diagnostics-map-note'),
          style: TextStyle(
            color: subtle,
            fontSize: 11,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildSoon(BuildContext context, Color label, Color subtle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Bientôt :',
          key: const Key('environment-studio-soon-title'),
          style: TextStyle(
            color: label,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '• création de presets ;\n'
          '• édition de palettes ;\n'
          '• utilisation dans les Environment Layers ;\n'
          '• génération organique sur les maps.',
          key: const Key('environment-studio-soon-bullets'),
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

```

### `packages/map_editor/lib/src/features/environment_studio/widgets/environment_diagnostic_presentation.dart`

```dart
import 'package:map_core/map_core.dart';

/// Libellés FR stables pour l’UI auteur (Lot Environment-11).
String environmentDiagnosticKindLabel(EnvironmentAuthoringDiagnosticKind kind) {
  return switch (kind) {
    EnvironmentAuthoringDiagnosticKind.duplicatePresetId => 'Preset dupliqué',
    EnvironmentAuthoringDiagnosticKind.missingPaletteElement =>
      'Élément introuvable',
    EnvironmentAuthoringDiagnosticKind.unknownTemplateId => 'Template inconnu',
    EnvironmentAuthoringDiagnosticKind.forcedCollisionWithoutProfile =>
      'Collision forcée sans profil',
    EnvironmentAuthoringDiagnosticKind.missingAreaPreset =>
      'Preset de zone introuvable',
    EnvironmentAuthoringDiagnosticKind.missingTargetTileLayerId =>
      'Layer cible manquant',
    EnvironmentAuthoringDiagnosticKind.unknownTargetTileLayer =>
      'Layer cible introuvable',
    EnvironmentAuthoringDiagnosticKind.targetLayerIsNotTileLayer =>
      'Layer cible invalide',
    EnvironmentAuthoringDiagnosticKind.areaMaskSizeMismatch =>
      'Taille de zone incohérente',
    EnvironmentAuthoringDiagnosticKind.emptyAreaMask => 'Zone vide',
    EnvironmentAuthoringDiagnosticKind.missingGeneratedPlacement =>
      'Placement généré introuvable',
  };
}

String environmentDiagnosticSeverityLabel(
  EnvironmentAuthoringDiagnosticSeverity severity,
) {
  return switch (severity) {
    EnvironmentAuthoringDiagnosticSeverity.error => 'Erreur',
    EnvironmentAuthoringDiagnosticSeverity.warning => 'Avertissement',
  };
}

```

### `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_list.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/shared/cupertino_editor_widgets.dart';

/// Liste read-only des presets Environment avec sélection visuelle.
class EnvironmentPresetList extends StatelessWidget {
  const EnvironmentPresetList({
    super.key,
    required this.presets,
    required this.selectedPresetId,
    required this.report,
    required this.onSelect,
  });

  final List<EnvironmentPreset> presets;
  final String? selectedPresetId;
  final EnvironmentAuthoringDiagnosticsReport report;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: ListView.builder(
        key: const Key('environment-studio-preset-list'),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: presets.length,
        itemBuilder: (context, index) {
          final p = presets[index];
          final isSelected = p.id == selectedPresetId;
          final diag = report.diagnosticsForPreset(p.id);
          var err = 0;
          var warn = 0;
          for (final d in diag) {
            switch (d.severity) {
              case EnvironmentAuthoringDiagnosticSeverity.error:
                err++;
              case EnvironmentAuthoringDiagnosticSeverity.warning:
                warn++;
            }
          }
          return _PresetListTile(
            preset: p,
            selected: isSelected,
            errorCount: err,
            warningCount: warn,
            onTap: () => onSelect(p.id),
          );
        },
      ),
    );
  }
}

class _PresetListTile extends StatelessWidget {
  const _PresetListTile({
    required this.preset,
    required this.selected,
    required this.errorCount,
    required this.warningCount,
    required this.onTap,
  });

  final EnvironmentPreset preset;
  final bool selected;
  final int errorCount;
  final int warningCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    const accent = EditorChrome.accentJade;
    final nPalette = preset.palette.length;
    final badge = StringBuffer();
    if (errorCount > 0) {
      badge.write('$errorCount erreur${errorCount > 1 ? 's' : ''}');
    }
    if (warningCount > 0) {
      if (badge.isNotEmpty) {
        badge.write(' · ');
      }
      badge.write(
        '$warningCount avertissement${warningCount > 1 ? 's' : ''}',
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: GestureDetector(
        key: Key('environment-studio-preset-row-${preset.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.14)
                : CupertinoColors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.65)
                  : CupertinoColors.separator.resolveFrom(context),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      preset.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: label,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      CupertinoIcons.check_mark_circled_solid,
                      size: 16,
                      color: accent,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${preset.id} · $nPalette items · ${preset.templateId}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtle,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (badge.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  badge.toString(),
                  key: Key('environment-studio-preset-row-diag-${preset.id}'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: errorCount > 0
                        ? CupertinoColors.systemRed.resolveFrom(context)
                        : CupertinoColors.systemOrange.resolveFrom(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

```

### `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/shared/cupertino_editor_widgets.dart';
import 'environment_palette_item_view.dart';
import 'environment_preset_diagnostics_view.dart';

/// Détail read-only d’un preset : identité, paramètres, palette, diagnostics.
class EnvironmentPresetDetail extends StatelessWidget {
  const EnvironmentPresetDetail({
    super.key,
    required this.preset,
    required this.report,
    required this.labelColor,
    required this.subtleColor,
  });

  final EnvironmentPreset preset;
  final EnvironmentAuthoringDiagnosticsReport report;
  final Color labelColor;
  final Color subtleColor;

  @override
  Widget build(BuildContext context) {
    final p = preset;
    final diag = report.diagnosticsForPreset(p.id);
    final fill = EditorChrome.chipFill(context);
    final border = CupertinoColors.separator.resolveFrom(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      key: const Key('environment-studio-detail-root'),
      children: [
        Text(
          'Détail du preset',
          style: TextStyle(
            color: labelColor,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        _sectionCard(
          context,
          key: const Key('environment-studio-section-identity'),
          title: 'Identité',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _detailLine(
                  'Nom', p.name, const Key('environment-studio-detail-name')),
              _detailLine(
                  'Id', p.id, const Key('environment-studio-detail-id')),
              _detailLine(
                'Template',
                p.templateId,
                const Key('environment-studio-detail-template'),
              ),
              _detailLine(
                'Catégorie',
                p.categoryId ?? '—',
                const Key('environment-studio-detail-category'),
              ),
              _detailLine(
                'Ordre d’affichage',
                '${p.sortOrder}',
                const Key('environment-studio-detail-sort'),
              ),
            ],
          ),
          fill: fill,
          border: border,
        ),
        const SizedBox(height: 14),
        _sectionCard(
          context,
          key: const Key('environment-studio-section-params'),
          title: 'Paramètres par défaut',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _paramChip(
                context,
                label: 'Densité',
                value: _formatDouble(p.defaultParams.density),
                valueKey: const Key('environment-studio-detail-param-density'),
              ),
              _paramChip(
                context,
                label: 'Variation',
                value: _formatDouble(p.defaultParams.variation),
                valueKey:
                    const Key('environment-studio-detail-param-variation'),
              ),
              _paramChip(
                context,
                label: 'Densité des bords',
                value: _formatDouble(p.defaultParams.edgeDensity),
                valueKey: const Key('environment-studio-detail-param-edge'),
              ),
              _paramChip(
                context,
                label: 'Espacement min. (cases)',
                value: '${p.defaultParams.minSpacingCells}',
                valueKey: const Key('environment-studio-detail-param-spacing'),
              ),
            ],
          ),
          fill: fill,
          border: border,
        ),
        const SizedBox(height: 14),
        _sectionCard(
          context,
          key: const Key('environment-studio-section-palette'),
          title: 'Palette',
          child: p.palette.isEmpty
              ? Text(
                  'Palette vide.',
                  key: const Key('environment-studio-palette-empty'),
                  style: TextStyle(color: subtleColor, fontSize: 13),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in p.palette)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: EnvironmentPaletteItemView(
                          item: item,
                          subtleColor: subtleColor,
                        ),
                      ),
                  ],
                ),
          fill: fill,
          border: border,
        ),
        const SizedBox(height: 14),
        _sectionCard(
          context,
          key: const Key('environment-studio-section-diagnostics'),
          title: 'Diagnostics (preset)',
          child: EnvironmentPresetDiagnosticsView(
            diagnostics: diag,
            labelColor: labelColor,
            subtleColor: subtleColor,
          ),
          fill: fill,
          border: border,
        ),
      ],
    );
  }

  static String _formatDouble(double v) => v.toStringAsFixed(2);

  Widget _sectionCard(
    BuildContext context, {
    required Key key,
    required String title,
    required Widget child,
    required Color fill,
    required Color border,
  }) {
    return DecoratedBox(
      key: key,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                color: labelColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _detailLine(String title, String value, Key valueKey) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              title,
              style: TextStyle(
                color: subtleColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              key: valueKey,
              style: TextStyle(
                color: labelColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paramChip(
    BuildContext context, {
    required String label,
    required String value,
    required Key valueKey,
  }) {
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.accentJade.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.accentJade.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: subtle,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            key: valueKey,
            style: TextStyle(
              color: labelColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

```

### `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_diagnostics_view.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/shared/cupertino_editor_widgets.dart';
import 'environment_diagnostic_presentation.dart';

/// Drilldown read-only des diagnostics filtrés sur un preset.
class EnvironmentPresetDiagnosticsView extends StatelessWidget {
  const EnvironmentPresetDiagnosticsView({
    super.key,
    required this.diagnostics,
    required this.labelColor,
    required this.subtleColor,
  });

  final List<EnvironmentAuthoringDiagnostic> diagnostics;
  final Color labelColor;
  final Color subtleColor;

  @override
  Widget build(BuildContext context) {
    if (diagnostics.isEmpty) {
      return Text(
        'Aucun diagnostic pour ce preset.',
        key: const Key('environment-studio-preset-diagnostics-empty'),
        style: TextStyle(
          color: subtleColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    var err = 0;
    var warn = 0;
    for (final d in diagnostics) {
      switch (d.severity) {
        case EnvironmentAuthoringDiagnosticSeverity.error:
          err++;
        case EnvironmentAuthoringDiagnosticSeverity.warning:
          warn++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      key: const Key('environment-studio-preset-diagnostics-root'),
      children: [
        Text(
          '$err erreur${err == 1 ? '' : 's'} · '
          '$warn avertissement${warn == 1 ? '' : 's'}',
          key: const Key('environment-studio-preset-diagnostics-summary'),
          style: TextStyle(
            color: subtleColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ...diagnostics.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DiagnosticCard(
                  index: e.key,
                  diagnostic: e.value,
                  labelColor: labelColor,
                  subtleColor: subtleColor,
                ),
              ),
            ),
      ],
    );
  }
}

class _DiagnosticCard extends StatelessWidget {
  const _DiagnosticCard({
    required this.index,
    required this.diagnostic,
    required this.labelColor,
    required this.subtleColor,
  });

  final int index;
  final EnvironmentAuthoringDiagnostic diagnostic;
  final Color labelColor;
  final Color subtleColor;

  @override
  Widget build(BuildContext context) {
    final d = diagnostic;
    final isError = d.severity == EnvironmentAuthoringDiagnosticSeverity.error;
    final badgeColor = isError
        ? CupertinoColors.systemRed.resolveFrom(context)
        : CupertinoColors.systemOrange.resolveFrom(context);
    final fill = EditorChrome.chipFill(context);

    return DecoratedBox(
      key: Key('environment-studio-diag-card-$index'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
        color: fill,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Text(
                    environmentDiagnosticSeverityLabel(d.severity),
                    key: Key('environment-studio-diag-severity-$index'),
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    environmentDiagnosticKindLabel(d.kind),
                    key: Key('environment-studio-diag-kind-$index'),
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              d.message,
              key: Key('environment-studio-diag-message-$index'),
              style: TextStyle(
                color: labelColor,
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_hasOptionalFields(d)) ...[
              const SizedBox(height: 10),
              ..._buildOptionalRows(d, index, subtleColor),
            ],
          ],
        ),
      ),
    );
  }

  static bool _hasOptionalFields(EnvironmentAuthoringDiagnostic d) {
    return d.elementId != null ||
        d.templateId != null ||
        d.mapId != null ||
        d.layerId != null ||
        d.areaId != null ||
        d.targetTileLayerId != null ||
        d.generatedPlacementId != null;
  }

  static List<Widget> _buildOptionalRows(
    EnvironmentAuthoringDiagnostic d,
    int index,
    Color subtle,
  ) {
    final out = <Widget>[];
    void add(String title, String? value, String field) {
      if (value == null || value.isEmpty) {
        return;
      }
      out.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  title,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  key: Key('environment-studio-diag-field-$field-$index'),
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    add('elementId', d.elementId, 'elementId');
    add('templateId', d.templateId, 'templateId');
    add('mapId', d.mapId, 'mapId');
    add('layerId', d.layerId, 'layerId');
    add('areaId', d.areaId, 'areaId');
    add('targetTileLayerId', d.targetTileLayerId, 'targetTileLayerId');
    add('generatedPlacementId', d.generatedPlacementId, 'generatedPlacementId');
    return out;
  }
}

```

### `packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_view.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/shared/cupertino_editor_widgets.dart';

/// Carte d’un item de palette Environment (read-only).
class EnvironmentPaletteItemView extends StatelessWidget {
  const EnvironmentPaletteItemView({
    super.key,
    required this.item,
    required this.subtleColor,
  });

  final EnvironmentPaletteItem item;
  final Color subtleColor;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final fill = EditorChrome.chipFill(context);
    final border = CupertinoColors.separator.resolveFrom(context);
    final tags = item.tags.toList()..sort();

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
        color: fill,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.elementId,
                    key: Key(
                        'environment-studio-palette-item-${item.elementId}'),
                    style: TextStyle(
                      color: label,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                _miniChip(
                  context,
                  label: 'Poids ${item.weight}',
                  key: Key(
                      'environment-studio-palette-weight-${item.elementId}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _collisionLabel(item.collisionMode),
              key: Key(
                'environment-studio-palette-collision-${item.elementId}',
              ),
              style: TextStyle(
                color: subtleColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in tags)
                    _miniChip(
                      context,
                      label: t,
                      key: Key(
                        'environment-studio-palette-tag-${item.elementId}-$t',
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _collisionLabel(EnvironmentCollisionMode m) {
    return switch (m) {
      EnvironmentCollisionMode.useElementDefault => 'Défaut élément',
      EnvironmentCollisionMode.forceEnabled => 'Collision forcée',
      EnvironmentCollisionMode.forceDisabled => 'Collision désactivée',
    };
  }

  Widget _miniChip(
    BuildContext context, {
    required String label,
    Key? key,
  }) {
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: EditorChrome.accentJade.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: EditorChrome.accentJade.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: subtle,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

```

### `packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';
import 'package:map_editor/src/features/environment_studio/widgets/environment_diagnostic_presentation.dart';

void main() {
  group('environmentDiagnosticKindLabel', () {
    test('quelques kinds FR stables', () {
      expect(
        environmentDiagnosticKindLabel(
          EnvironmentAuthoringDiagnosticKind.missingPaletteElement,
        ),
        'Élément introuvable',
      );
      expect(
        environmentDiagnosticKindLabel(
          EnvironmentAuthoringDiagnosticKind.unknownTemplateId,
        ),
        'Template inconnu',
      );
      expect(
        environmentDiagnosticKindLabel(
          EnvironmentAuthoringDiagnosticKind.duplicatePresetId,
        ),
        'Preset dupliqué',
      );
    });
  });

  group('EnvironmentStudioPanel — browser read-only', () {
    testWidgets(
        'sections identité, paramètres, palette et diagnostics visibles',
        (tester) async {
      await _pump(
        tester,
        _manifest(
          environmentPresets: [
            EnvironmentPreset(
              id: 'p1',
              name: 'Forêt test',
              templateId: 'forest_dense',
              categoryId: 'bio',
              palette: [
                EnvironmentPaletteItem(
                  elementId: 'oak',
                  weight: 5,
                  collisionMode: EnvironmentCollisionMode.forceDisabled,
                  tags: {'tree', 'canopy'},
                ),
              ],
              defaultParams: EnvironmentGenerationParams(
                density: 0.25,
                variation: 0.75,
                edgeDensity: 0.1,
                minSpacingCells: 2,
              ),
              sortOrder: 3,
            ),
          ],
          elements: [_element(id: 'oak')],
        ),
      );

      expect(
        find.byKey(const Key('environment-studio-section-identity')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-studio-section-params')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-studio-section-palette')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-studio-section-diagnostics')),
        findsOneWidget,
      );

      expect(find.byKey(const Key('environment-studio-detail-id')),
          findsOneWidget);
      expect(find.text('p1'), findsWidgets);
      expect(find.text('Forêt test'), findsWidgets);
      expect(find.text('forest_dense'), findsWidgets);
      expect(find.text('bio'), findsWidgets);
      expect(find.text('3'), findsWidgets);
      expect(find.text('0.25'), findsOneWidget);
      expect(find.text('0.75'), findsOneWidget);
      expect(find.text('0.10'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
      expect(find.byKey(const Key('environment-studio-palette-item-oak')),
          findsOneWidget);
      expect(
        find.byKey(const Key('environment-studio-palette-weight-oak')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Poids 5'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-studio-palette-collision-oak')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Collision désactivée'),
        findsOneWidget,
      );
      // Tags triés alphabétiquement : canopy puis tree
      expect(
        find.byKey(const Key('environment-studio-palette-tag-oak-canopy')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-studio-palette-tag-oak-tree')),
        findsOneWidget,
      );
    });

    testWidgets('catégorie absente : affiche —', (tester) async {
      await _pump(
        tester,
        _manifest(
          environmentPresets: [
            EnvironmentPreset(
              id: 'solo',
              name: 'Solo',
              templateId: 'tpl',
              palette: [
                EnvironmentPaletteItem(elementId: 'e1', weight: 1),
              ],
              defaultParams: EnvironmentGenerationParams.standard(),
              sortOrder: 0,
            ),
          ],
          elements: [_element(id: 'e1')],
        ),
      );

      expect(
        (tester.widget<Text>(
                find.byKey(const Key('environment-studio-detail-category'))))
            .data,
        '—',
      );
    });

    testWidgets('diagnostics preset vides : message dédié', (tester) async {
      await _pump(
        tester,
        _manifest(
          environmentPresets: [
            EnvironmentPreset(
              id: 'ok',
              name: 'OK',
              templateId: 'tpl',
              palette: [
                EnvironmentPaletteItem(elementId: 'e1', weight: 1),
              ],
              defaultParams: EnvironmentGenerationParams.standard(),
              sortOrder: 0,
            ),
          ],
          elements: [_element(id: 'e1')],
        ),
      );

      expect(
        find.byKey(const Key('environment-studio-preset-diagnostics-empty')),
        findsOneWidget,
      );
      expect(find.text('Aucun diagnostic pour ce preset.'), findsOneWidget);
    });

    testWidgets('diagnostic erreur élément palette : drilldown',
        (tester) async {
      await _pump(
        tester,
        _manifest(
          environmentPresets: [
            EnvironmentPreset(
              id: 'bad',
              name: 'Bad',
              templateId: 'tpl',
              palette: [
                EnvironmentPaletteItem(elementId: 'missing_tree', weight: 1),
              ],
              defaultParams: EnvironmentGenerationParams.standard(),
              sortOrder: 0,
            ),
          ],
          elements: const [],
        ),
      );

      expect(
        find.byKey(const Key('environment-studio-preset-diagnostics-empty')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('environment-studio-preset-diagnostics-summary')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-studio-diag-severity-0')),
        findsOneWidget,
      );
      expect(
        (tester.widget<Text>(
                find.byKey(const Key('environment-studio-diag-severity-0'))))
            .data,
        'Erreur',
      );
      expect(
        find.byKey(const Key('environment-studio-diag-kind-0')),
        findsOneWidget,
      );
      expect(
        (tester.widget<Text>(
                find.byKey(const Key('environment-studio-diag-kind-0'))))
            .data,
        'Élément introuvable',
      );
      expect(
        find.byKey(const Key('environment-studio-diag-message-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-studio-diag-field-elementId-0')),
        findsOneWidget,
      );
      expect(
        (tester.widget<Text>(find
                .byKey(const Key('environment-studio-diag-field-elementId-0'))))
            .data,
        'missing_tree',
      );
      expect(
        find.byKey(const Key('environment-studio-preset-row-diag-bad')),
        findsOneWidget,
      );
    });

    testWidgets(
        'unknownTemplateId : kind FR et templateId affiché si knownTemplateIds',
        (tester) async {
      await tester.pumpWidget(
        MacosApp(
          home: CupertinoPageScaffold(
            child: EnvironmentStudioPanel(
              manifest: _manifest(
                environmentPresets: [
                  EnvironmentPreset(
                    id: 'u1',
                    name: 'U',
                    templateId: 'not_in_set',
                    palette: [
                      EnvironmentPaletteItem(elementId: 'e1', weight: 1),
                    ],
                    defaultParams: EnvironmentGenerationParams.standard(),
                    sortOrder: 0,
                  ),
                ],
                elements: [_element(id: 'e1')],
              ),
              knownTemplateIds: const {'forest_dense'},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        (tester.widget<Text>(
                find.byKey(const Key('environment-studio-diag-kind-0'))))
            .data,
        'Template inconnu',
      );
      expect(
        find.byKey(const Key('environment-studio-diag-field-templateId-0')),
        findsOneWidget,
      );
      expect(
        (tester.widget<Text>(find.byKey(
                const Key('environment-studio-diag-field-templateId-0'))))
            .data,
        'not_in_set',
      );
      expect(
        (tester.widget<Text>(
                find.byKey(const Key('environment-studio-diag-severity-0'))))
            .data,
        'Avertissement',
      );
    });

    testWidgets(
        'read-only : pas de libellés Create / Edit / Delete / Generate / Save',
        (tester) async {
      await _pump(
        tester,
        _manifest(
          environmentPresets: [
            EnvironmentPreset(
              id: 'x',
              name: 'X',
              templateId: 'tpl',
              palette: [
                EnvironmentPaletteItem(elementId: 'e1', weight: 1),
              ],
              defaultParams: EnvironmentGenerationParams.standard(),
              sortOrder: 0,
            ),
          ],
          elements: [_element(id: 'e1')],
        ),
      );

      expect(find.textContaining('Create'), findsNothing);
      expect(find.textContaining('Edit'), findsNothing);
      expect(find.textContaining('Delete'), findsNothing);
      expect(find.textContaining('Generate'), findsNothing);
      expect(find.textContaining('Save'), findsNothing);
    });
  });
}

Future<void> _pump(WidgetTester tester, ProjectManifest manifest) async {
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
  required List<EnvironmentPreset> environmentPresets,
  List<ProjectElementEntry> elements = const [],
}) {
  return ProjectManifest(
    name: 'browser-test',
    maps: const [],
    tilesets: const [],
    environmentPresets: environmentPresets,
    elements: elements,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectElementEntry _element({required String id}) {
  return ProjectElementEntry(
    id: id,
    name: 'El $id',
    tilesetId: 'ts',
    categoryId: 'cat',
    frames: const [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0),
      ),
    ],
  );
}

```

## 16. Diff complet

### `environment_studio_panel.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart b/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
index 61c9ab3c..01977da6 100644
--- a/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
@@ -2,19 +2,28 @@ import 'package:flutter/cupertino.dart';
 import 'package:map_core/map_core.dart';
 
 import '../../ui/shared/cupertino_editor_widgets.dart';
+import 'widgets/environment_preset_detail.dart';
+import 'widgets/environment_preset_list.dart';
 
-/// Browser read-only des presets Environment (Lot Environment-10).
+/// Browser read-only des presets Environment (Lot Environment-10, polish 11).
 ///
 /// Sélection locale uniquement ([StatefulWidget]) : aucune mutation du
 /// [ProjectManifest], aucun provider, aucune persistance.
+///
+/// [knownTemplateIds] non vide active les diagnostics `unknownTemplateId` pour
+/// les [EnvironmentPreset.templateId] absents du set (défaut `{}` = désactivé).
 class EnvironmentStudioPanel extends StatefulWidget {
   const EnvironmentStudioPanel({
     super.key,
     required this.manifest,
+    this.knownTemplateIds = const <String>{},
   });
 
   final ProjectManifest manifest;
 
+  /// Quand non vide, restreint les templates reconnus (diagnostics auteur).
+  final Set<String> knownTemplateIds;
+
   @override
   State<EnvironmentStudioPanel> createState() => _EnvironmentStudioPanelState();
 }
@@ -87,6 +96,7 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
     final report = diagnoseProjectEnvironmentAuthoring(
       widget.manifest,
       maps: const [],
+      knownTemplateIds: widget.knownTemplateIds,
     );
     final s = report.summary;
 
@@ -227,41 +237,11 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
       children: [
         SizedBox(
           width: 300,
-          child: DecoratedBox(
-            decoration: BoxDecoration(
-              color: EditorChrome.chipFill(context),
-              borderRadius: BorderRadius.circular(12),
-              border: Border.all(
-                color: CupertinoColors.separator.resolveFrom(context),
-              ),
-            ),
-            child: ListView.builder(
-              key: const Key('environment-studio-preset-list'),
-              padding: const EdgeInsets.symmetric(vertical: 8),
-              itemCount: presets.length,
-              itemBuilder: (context, index) {
-                final p = presets[index];
-                final isSelected = p.id == _selectedPresetId;
-                final diag = report.diagnosticsForPreset(p.id);
-                var err = 0;
-                var warn = 0;
-                for (final d in diag) {
-                  switch (d.severity) {
-                    case EnvironmentAuthoringDiagnosticSeverity.error:
-                      err++;
-                    case EnvironmentAuthoringDiagnosticSeverity.warning:
-                      warn++;
-                  }
-                }
-                return _PresetListTile(
-                  preset: p,
-                  selected: isSelected,
-                  errorCount: err,
-                  warningCount: warn,
-                  onTap: () => setState(() => _selectedPresetId = p.id),
-                );
-              },
-            ),
+          child: EnvironmentPresetList(
+            presets: presets,
+            selectedPresetId: _selectedPresetId,
+            report: report,
+            onSelect: (id) => setState(() => _selectedPresetId = id),
           ),
         ),
         const SizedBox(width: 16),
@@ -289,7 +269,7 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
                 : SingleChildScrollView(
                     key: const Key('environment-studio-detail-scroll'),
                     padding: const EdgeInsets.all(20),
-                    child: _PresetDetail(
+                    child: EnvironmentPresetDetail(
                       preset: selected,
                       report: report,
                       labelColor: label,
@@ -375,381 +355,3 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
     );
   }
 }
-
-class _PresetListTile extends StatelessWidget {
-  const _PresetListTile({
-    required this.preset,
-    required this.selected,
-    required this.errorCount,
-    required this.warningCount,
-    required this.onTap,
-  });
-
-  final EnvironmentPreset preset;
-  final bool selected;
-  final int errorCount;
-  final int warningCount;
-  final VoidCallback onTap;
-
-  @override
-  Widget build(BuildContext context) {
-    final label = EditorChrome.primaryLabel(context);
-    final subtle = EditorChrome.subtleLabel(context);
-    const accent = EditorChrome.accentJade;
-    final nPalette = preset.palette.length;
-    final badge = StringBuffer();
-    if (errorCount > 0) {
-      badge.write('$errorCount erreur${errorCount > 1 ? 's' : ''}');
-    }
-    if (warningCount > 0) {
-      if (badge.isNotEmpty) {
-        badge.write(' · ');
-      }
-      badge.write(
-        '$warningCount avertissement${warningCount > 1 ? 's' : ''}',
-      );
-    }
-
-    return Padding(
-      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
-      child: GestureDetector(
-        key: Key('environment-studio-preset-row-${preset.id}'),
-        behavior: HitTestBehavior.opaque,
-        onTap: onTap,
-        child: AnimatedContainer(
-          duration: const Duration(milliseconds: 160),
-          curve: Curves.easeOutCubic,
-          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
-          decoration: BoxDecoration(
-            color: selected
-                ? accent.withValues(alpha: 0.14)
-                : CupertinoColors.transparent,
-            borderRadius: BorderRadius.circular(10),
-            border: Border.all(
-              color: selected
-                  ? accent.withValues(alpha: 0.65)
-                  : CupertinoColors.separator.resolveFrom(context),
-            ),
-          ),
-          child: Column(
-            crossAxisAlignment: CrossAxisAlignment.stretch,
-            children: [
-              Row(
-                children: [
-                  Expanded(
-                    child: Text(
-                      preset.name,
-                      maxLines: 2,
-                      overflow: TextOverflow.ellipsis,
-                      style: TextStyle(
-                        color: label,
-                        fontSize: 14,
-                        fontWeight: FontWeight.w700,
-                      ),
-                    ),
-                  ),
-                  if (selected)
-                    const Icon(
-                      CupertinoIcons.check_mark_circled_solid,
-                      size: 16,
-                      color: accent,
-                    ),
-                ],
-              ),
-              const SizedBox(height: 4),
-              Text(
-                '${preset.id} · $nPalette items · ${preset.templateId}',
-                maxLines: 2,
-                overflow: TextOverflow.ellipsis,
-                style: TextStyle(
-                  color: subtle,
-                  fontSize: 11.5,
-                  fontWeight: FontWeight.w600,
-                ),
-              ),
-              if (badge.isNotEmpty) ...[
-                const SizedBox(height: 4),
-                Text(
-                  badge.toString(),
-                  key: Key('environment-studio-preset-row-diag-${preset.id}'),
-                  maxLines: 2,
-                  overflow: TextOverflow.ellipsis,
-                  style: TextStyle(
-                    color: errorCount > 0
-                        ? CupertinoColors.systemRed.resolveFrom(context)
-                        : CupertinoColors.systemOrange.resolveFrom(context),
-                    fontSize: 11,
-                    fontWeight: FontWeight.w600,
-                  ),
-                ),
-              ],
-            ],
-          ),
-        ),
-      ),
-    );
-  }
-}
-
-class _PresetDetail extends StatelessWidget {
-  const _PresetDetail({
-    required this.preset,
-    required this.report,
-    required this.labelColor,
-    required this.subtleColor,
-  });
-
-  final EnvironmentPreset preset;
-  final EnvironmentAuthoringDiagnosticsReport report;
-  final Color labelColor;
-  final Color subtleColor;
-
-  @override
-  Widget build(BuildContext context) {
-    final p = preset;
-    final diag = report.diagnosticsForPreset(p.id);
-    var err = 0;
-    var warn = 0;
-    for (final d in diag) {
-      switch (d.severity) {
-        case EnvironmentAuthoringDiagnosticSeverity.error:
-          err++;
-        case EnvironmentAuthoringDiagnosticSeverity.warning:
-          warn++;
-      }
-    }
-
-    return Column(
-      crossAxisAlignment: CrossAxisAlignment.stretch,
-      key: const Key('environment-studio-detail-root'),
-      children: [
-        Text(
-          'Détail du preset',
-          style: TextStyle(
-            color: labelColor,
-            fontSize: 17,
-            fontWeight: FontWeight.w800,
-          ),
-        ),
-        const SizedBox(height: 14),
-        _detailLine('Nom', p.name, const Key('environment-studio-detail-name')),
-        _detailLine('Id', p.id, const Key('environment-studio-detail-id')),
-        _detailLine(
-          'Template',
-          p.templateId,
-          const Key('environment-studio-detail-template'),
-        ),
-        _detailLine(
-          'Catégorie',
-          p.categoryId ?? '—',
-          const Key('environment-studio-detail-category'),
-        ),
-        _detailLine(
-          'Ordre d’affichage',
-          '${p.sortOrder}',
-          const Key('environment-studio-detail-sort'),
-        ),
-        const SizedBox(height: 16),
-        Text(
-          'Paramètres par défaut',
-          style: TextStyle(
-            color: labelColor,
-            fontSize: 15,
-            fontWeight: FontWeight.w700,
-          ),
-        ),
-        const SizedBox(height: 8),
-        _detailLine(
-          'Densité',
-          _formatDouble(p.defaultParams.density),
-          const Key('environment-studio-detail-param-density'),
-        ),
-        _detailLine(
-          'Variation',
-          _formatDouble(p.defaultParams.variation),
-          const Key('environment-studio-detail-param-variation'),
-        ),
-        _detailLine(
-          'Densité des bords',
-          _formatDouble(p.defaultParams.edgeDensity),
-          const Key('environment-studio-detail-param-edge'),
-        ),
-        _detailLine(
-          'Espacement minimal (cases)',
-          '${p.defaultParams.minSpacingCells}',
-          const Key('environment-studio-detail-param-spacing'),
-        ),
-        const SizedBox(height: 16),
-        Text(
-          'Palette',
-          style: TextStyle(
-            color: labelColor,
-            fontSize: 15,
-            fontWeight: FontWeight.w700,
-          ),
-        ),
-        const SizedBox(height: 8),
-        if (p.palette.isEmpty)
-          Text(
-            'Palette vide.',
-            key: const Key('environment-studio-palette-empty'),
-            style: TextStyle(color: subtleColor, fontSize: 13),
-          )
-        else
-          ...p.palette.map(
-            (item) => Padding(
-              padding: const EdgeInsets.only(bottom: 10),
-              child: _PaletteItemBlock(item: item, subtle: subtleColor),
-            ),
-          ),
-        const SizedBox(height: 18),
-        Text(
-          'Diagnostics (preset)',
-          style: TextStyle(
-            color: labelColor,
-            fontSize: 15,
-            fontWeight: FontWeight.w700,
-          ),
-        ),
-        const SizedBox(height: 8),
-        if (diag.isEmpty)
-          Text(
-            'Aucun diagnostic pour ce preset.',
-            key: const Key('environment-studio-preset-diagnostics-empty'),
-            style: TextStyle(
-              color: subtleColor,
-              fontSize: 13,
-              fontWeight: FontWeight.w600,
-            ),
-          )
-        else ...[
-          Text(
-            '$err erreur${err == 1 ? '' : 's'} · '
-            '$warn avertissement${warn == 1 ? '' : 's'}',
-            key: const Key('environment-studio-preset-diagnostics-summary'),
-            style: TextStyle(
-              color: subtleColor,
-              fontSize: 13,
-              fontWeight: FontWeight.w600,
-            ),
-          ),
-          const SizedBox(height: 8),
-          ...diag.asMap().entries.map(
-                (e) => Padding(
-                  padding: const EdgeInsets.only(bottom: 6),
-                  child: Text(
-                    e.value.message,
-                    key: Key('environment-studio-preset-diag-line-${e.key}'),
-                    style: TextStyle(
-                      color: e.value.severity ==
-                              EnvironmentAuthoringDiagnosticSeverity.error
-                          ? CupertinoColors.systemRed.resolveFrom(context)
-                          : CupertinoColors.systemOrange.resolveFrom(context),
-                      fontSize: 12.5,
-                      height: 1.35,
-                    ),
-                  ),
-                ),
-              ),
-        ],
-      ],
-    );
-  }
-
-  static String _formatDouble(double v) => v.toStringAsFixed(2);
-
-  Widget _detailLine(String title, String value, Key valueKey) {
-    return Padding(
-      padding: const EdgeInsets.only(bottom: 6),
-      child: Row(
-        crossAxisAlignment: CrossAxisAlignment.start,
-        children: [
-          SizedBox(
-            width: 150,
-            child: Text(
-              title,
-              style: TextStyle(
-                color: subtleColor,
-                fontSize: 12,
-                fontWeight: FontWeight.w600,
-              ),
-            ),
-          ),
-          Expanded(
-            child: Text(
-              value,
-              key: valueKey,
-              style: TextStyle(
-                color: labelColor,
-                fontSize: 13,
-                fontWeight: FontWeight.w600,
-              ),
-            ),
-          ),
-        ],
-      ),
-    );
-  }
-}
-
-class _PaletteItemBlock extends StatelessWidget {
-  const _PaletteItemBlock({
-    required this.item,
-    required this.subtle,
-  });
-
-  final EnvironmentPaletteItem item;
-  final Color subtle;
-
-  @override
-  Widget build(BuildContext context) {
-    final label = EditorChrome.primaryLabel(context);
-    final tagStr =
-        item.tags.isEmpty ? '—' : (item.tags.toList()..sort()).join(', ');
-
-    return DecoratedBox(
-      decoration: BoxDecoration(
-        borderRadius: BorderRadius.circular(8),
-        border: Border.all(
-          color: CupertinoColors.separator.resolveFrom(context),
-        ),
-      ),
-      child: Padding(
-        padding: const EdgeInsets.all(10),
-        child: Column(
-          crossAxisAlignment: CrossAxisAlignment.stretch,
-          children: [
-            Text(
-              item.elementId,
-              key: Key('environment-studio-palette-item-${item.elementId}'),
-              style: TextStyle(
-                color: label,
-                fontSize: 13,
-                fontWeight: FontWeight.w700,
-              ),
-            ),
-            const SizedBox(height: 4),
-            Text(
-              'Poids ${item.weight} · ${_collisionLabel(item.collisionMode)} · tags: $tagStr',
-              key:
-                  Key('environment-studio-palette-item-meta-${item.elementId}'),
-              style: TextStyle(
-                color: subtle,
-                fontSize: 12,
-                height: 1.35,
-              ),
-            ),
-          ],
-        ),
-      ),
-    );
-  }
-
-  static String _collisionLabel(EnvironmentCollisionMode m) {
-    return switch (m) {
-      EnvironmentCollisionMode.useElementDefault => 'Défaut élément',
-      EnvironmentCollisionMode.forceEnabled => 'Collision forcée',
-      EnvironmentCollisionMode.forceDisabled => 'Collision désactivée',
-    };
-  }
-}

```

### `environment_studio_preset_browser_test.dart`

```diff
diff --git a/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart b/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart
index 101a6eec..05c7eeef 100644
--- a/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart
+++ b/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart
@@ -3,10 +3,35 @@ import 'package:flutter_test/flutter_test.dart';
 import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
 import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';
+import 'package:map_editor/src/features/environment_studio/widgets/environment_diagnostic_presentation.dart';
 
 void main() {
+  group('environmentDiagnosticKindLabel', () {
+    test('quelques kinds FR stables', () {
+      expect(
+        environmentDiagnosticKindLabel(
+          EnvironmentAuthoringDiagnosticKind.missingPaletteElement,
+        ),
+        'Élément introuvable',
+      );
+      expect(
+        environmentDiagnosticKindLabel(
+          EnvironmentAuthoringDiagnosticKind.unknownTemplateId,
+        ),
+        'Template inconnu',
+      );
+      expect(
+        environmentDiagnosticKindLabel(
+          EnvironmentAuthoringDiagnosticKind.duplicatePresetId,
+        ),
+        'Preset dupliqué',
+      );
+    });
+  });
+
   group('EnvironmentStudioPanel — browser read-only', () {
-    testWidgets('détail : id, nom, template, catégorie, tri, params, palette',
+    testWidgets(
+        'sections identité, paramètres, palette et diagnostics visibles',
         (tester) async {
       await _pump(
         tester,
@@ -21,7 +46,7 @@ void main() {
                 EnvironmentPaletteItem(
                   elementId: 'oak',
                   weight: 5,
-                  collisionMode: EnvironmentCollisionMode.forceEnabled,
+                  collisionMode: EnvironmentCollisionMode.forceDisabled,
                   tags: {'tree', 'canopy'},
                 ),
               ],
@@ -38,6 +63,23 @@ void main() {
         ),
       );
 
+      expect(
+        find.byKey(const Key('environment-studio-section-identity')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const Key('environment-studio-section-params')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const Key('environment-studio-section-palette')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const Key('environment-studio-section-diagnostics')),
+        findsOneWidget,
+      );
+
       expect(find.byKey(const Key('environment-studio-detail-id')),
           findsOneWidget);
       expect(find.text('p1'), findsWidgets);
@@ -52,7 +94,7 @@ void main() {
       expect(find.byKey(const Key('environment-studio-palette-item-oak')),
           findsOneWidget);
       expect(
-        find.byKey(const Key('environment-studio-palette-item-meta-oak')),
+        find.byKey(const Key('environment-studio-palette-weight-oak')),
         findsOneWidget,
       );
       expect(
@@ -60,11 +102,20 @@ void main() {
         findsOneWidget,
       );
       expect(
-        find.textContaining('Collision forcée'),
+        find.byKey(const Key('environment-studio-palette-collision-oak')),
+        findsOneWidget,
+      );
+      expect(
+        find.textContaining('Collision désactivée'),
         findsOneWidget,
       );
+      // Tags triés alphabétiquement : canopy puis tree
       expect(
-        find.textContaining('canopy'),
+        find.byKey(const Key('environment-studio-palette-tag-oak-canopy')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const Key('environment-studio-palette-tag-oak-tree')),
         findsOneWidget,
       );
     });
@@ -124,7 +175,8 @@ void main() {
       expect(find.text('Aucun diagnostic pour ce preset.'), findsOneWidget);
     });
 
-    testWidgets('diagnostic erreur élément palette manquant', (tester) async {
+    testWidgets('diagnostic erreur élément palette : drilldown',
+        (tester) async {
       await _pump(
         tester,
         _manifest(
@@ -153,16 +205,100 @@ void main() {
         findsOneWidget,
       );
       expect(
-        find.byKey(const Key('environment-studio-preset-diag-line-0')),
+        find.byKey(const Key('environment-studio-diag-severity-0')),
+        findsOneWidget,
+      );
+      expect(
+        (tester.widget<Text>(
+                find.byKey(const Key('environment-studio-diag-severity-0'))))
+            .data,
+        'Erreur',
+      );
+      expect(
+        find.byKey(const Key('environment-studio-diag-kind-0')),
+        findsOneWidget,
+      );
+      expect(
+        (tester.widget<Text>(
+                find.byKey(const Key('environment-studio-diag-kind-0'))))
+            .data,
+        'Élément introuvable',
+      );
+      expect(
+        find.byKey(const Key('environment-studio-diag-message-0')),
         findsOneWidget,
       );
+      expect(
+        find.byKey(const Key('environment-studio-diag-field-elementId-0')),
+        findsOneWidget,
+      );
+      expect(
+        (tester.widget<Text>(find
+                .byKey(const Key('environment-studio-diag-field-elementId-0'))))
+            .data,
+        'missing_tree',
+      );
       expect(
         find.byKey(const Key('environment-studio-preset-row-diag-bad')),
         findsOneWidget,
       );
     });
 
-    testWidgets('read-only : pas de libellés Create / Edit / Delete / Generate',
+    testWidgets(
+        'unknownTemplateId : kind FR et templateId affiché si knownTemplateIds',
+        (tester) async {
+      await tester.pumpWidget(
+        MacosApp(
+          home: CupertinoPageScaffold(
+            child: EnvironmentStudioPanel(
+              manifest: _manifest(
+                environmentPresets: [
+                  EnvironmentPreset(
+                    id: 'u1',
+                    name: 'U',
+                    templateId: 'not_in_set',
+                    palette: [
+                      EnvironmentPaletteItem(elementId: 'e1', weight: 1),
+                    ],
+                    defaultParams: EnvironmentGenerationParams.standard(),
+                    sortOrder: 0,
+                  ),
+                ],
+                elements: [_element(id: 'e1')],
+              ),
+              knownTemplateIds: const {'forest_dense'},
+            ),
+          ),
+        ),
+      );
+      await tester.pumpAndSettle();
+
+      expect(
+        (tester.widget<Text>(
+                find.byKey(const Key('environment-studio-diag-kind-0'))))
+            .data,
+        'Template inconnu',
+      );
+      expect(
+        find.byKey(const Key('environment-studio-diag-field-templateId-0')),
+        findsOneWidget,
+      );
+      expect(
+        (tester.widget<Text>(find.byKey(
+                const Key('environment-studio-diag-field-templateId-0'))))
+            .data,
+        'not_in_set',
+      );
+      expect(
+        (tester.widget<Text>(
+                find.byKey(const Key('environment-studio-diag-severity-0'))))
+            .data,
+        'Avertissement',
+      );
+    });
+
+    testWidgets(
+        'read-only : pas de libellés Create / Edit / Delete / Generate / Save',
         (tester) async {
       await _pump(
         tester,
@@ -187,6 +323,7 @@ void main() {
       expect(find.textContaining('Edit'), findsNothing);
       expect(find.textContaining('Delete'), findsNothing);
       expect(find.textContaining('Generate'), findsNothing);
+      expect(find.textContaining('Save'), findsNothing);
     });
   });
 }

```

### Fichiers nouveaux (équivalent `git diff /dev/null`)

#### `packages/map_editor/lib/src/features/environment_studio/widgets/environment_diagnostic_presentation.dart`

```diff
+import 'package:map_core/map_core.dart';
+
+/// Libellés FR stables pour l’UI auteur (Lot Environment-11).
+String environmentDiagnosticKindLabel(EnvironmentAuthoringDiagnosticKind kind) {
+  return switch (kind) {
+    EnvironmentAuthoringDiagnosticKind.duplicatePresetId => 'Preset dupliqué',
+    EnvironmentAuthoringDiagnosticKind.missingPaletteElement =>
+      'Élément introuvable',
+    EnvironmentAuthoringDiagnosticKind.unknownTemplateId => 'Template inconnu',
+    EnvironmentAuthoringDiagnosticKind.forcedCollisionWithoutProfile =>
+      'Collision forcée sans profil',
+    EnvironmentAuthoringDiagnosticKind.missingAreaPreset =>
+      'Preset de zone introuvable',
+    EnvironmentAuthoringDiagnosticKind.missingTargetTileLayerId =>
+      'Layer cible manquant',
+    EnvironmentAuthoringDiagnosticKind.unknownTargetTileLayer =>
+      'Layer cible introuvable',
+    EnvironmentAuthoringDiagnosticKind.targetLayerIsNotTileLayer =>
+      'Layer cible invalide',
+    EnvironmentAuthoringDiagnosticKind.areaMaskSizeMismatch =>
+      'Taille de zone incohérente',
+    EnvironmentAuthoringDiagnosticKind.emptyAreaMask => 'Zone vide',
+    EnvironmentAuthoringDiagnosticKind.missingGeneratedPlacement =>
+      'Placement généré introuvable',
+  };
+}
+
+String environmentDiagnosticSeverityLabel(
+  EnvironmentAuthoringDiagnosticSeverity severity,
+) {
+  return switch (severity) {
+    EnvironmentAuthoringDiagnosticSeverity.error => 'Erreur',
+    EnvironmentAuthoringDiagnosticSeverity.warning => 'Avertissement',
+  };
+}

```

#### `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_list.dart`

```diff
+import 'package:flutter/cupertino.dart';
+import 'package:map_core/map_core.dart';
+
+import '../../../ui/shared/cupertino_editor_widgets.dart';
+
+/// Liste read-only des presets Environment avec sélection visuelle.
+class EnvironmentPresetList extends StatelessWidget {
+  const EnvironmentPresetList({
+    super.key,
+    required this.presets,
+    required this.selectedPresetId,
+    required this.report,
+    required this.onSelect,
+  });
+
+  final List<EnvironmentPreset> presets;
+  final String? selectedPresetId;
+  final EnvironmentAuthoringDiagnosticsReport report;
+  final ValueChanged<String> onSelect;
+
+  @override
+  Widget build(BuildContext context) {
+    return DecoratedBox(
+      decoration: BoxDecoration(
+        color: EditorChrome.chipFill(context),
+        borderRadius: BorderRadius.circular(12),
+        border: Border.all(
+          color: CupertinoColors.separator.resolveFrom(context),
+        ),
+      ),
+      child: ListView.builder(
+        key: const Key('environment-studio-preset-list'),
+        padding: const EdgeInsets.symmetric(vertical: 8),
+        itemCount: presets.length,
+        itemBuilder: (context, index) {
+          final p = presets[index];
+          final isSelected = p.id == selectedPresetId;
+          final diag = report.diagnosticsForPreset(p.id);
+          var err = 0;
+          var warn = 0;
+          for (final d in diag) {
+            switch (d.severity) {
+              case EnvironmentAuthoringDiagnosticSeverity.error:
+                err++;
+              case EnvironmentAuthoringDiagnosticSeverity.warning:
+                warn++;
+            }
+          }
+          return _PresetListTile(
+            preset: p,
+            selected: isSelected,
+            errorCount: err,
+            warningCount: warn,
+            onTap: () => onSelect(p.id),
+          );
+        },
+      ),
+    );
+  }
+}
+
+class _PresetListTile extends StatelessWidget {
+  const _PresetListTile({
+    required this.preset,
+    required this.selected,
+    required this.errorCount,
+    required this.warningCount,
+    required this.onTap,
+  });
+
+  final EnvironmentPreset preset;
+  final bool selected;
+  final int errorCount;
+  final int warningCount;
+  final VoidCallback onTap;
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+    const accent = EditorChrome.accentJade;
+    final nPalette = preset.palette.length;
+    final badge = StringBuffer();
+    if (errorCount > 0) {
+      badge.write('$errorCount erreur${errorCount > 1 ? 's' : ''}');
+    }
+    if (warningCount > 0) {
+      if (badge.isNotEmpty) {
+        badge.write(' · ');
+      }
+      badge.write(
+        '$warningCount avertissement${warningCount > 1 ? 's' : ''}',
+      );
+    }
+
+    return Padding(
+      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
+      child: GestureDetector(
+        key: Key('environment-studio-preset-row-${preset.id}'),
+        behavior: HitTestBehavior.opaque,
+        onTap: onTap,
+        child: AnimatedContainer(
+          duration: const Duration(milliseconds: 160),
+          curve: Curves.easeOutCubic,
+          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
+          decoration: BoxDecoration(
+            color: selected
+                ? accent.withValues(alpha: 0.14)
+                : CupertinoColors.transparent,
+            borderRadius: BorderRadius.circular(10),
+            border: Border.all(
+              color: selected
+                  ? accent.withValues(alpha: 0.65)
+                  : CupertinoColors.separator.resolveFrom(context),
+            ),
+          ),
+          child: Column(
+            crossAxisAlignment: CrossAxisAlignment.stretch,
+            children: [
+              Row(
+                children: [
+                  Expanded(
+                    child: Text(
+                      preset.name,
+                      maxLines: 2,
+                      overflow: TextOverflow.ellipsis,
+                      style: TextStyle(
+                        color: label,
+                        fontSize: 14,
+                        fontWeight: FontWeight.w700,
+                      ),
+                    ),
+                  ),
+                  if (selected)
+                    const Icon(
+                      CupertinoIcons.check_mark_circled_solid,
+                      size: 16,
+                      color: accent,
+                    ),
+                ],
+              ),
+              const SizedBox(height: 4),
+              Text(
+                '${preset.id} · $nPalette items · ${preset.templateId}',
+                maxLines: 2,
+                overflow: TextOverflow.ellipsis,
+                style: TextStyle(
+                  color: subtle,
+                  fontSize: 11.5,
+                  fontWeight: FontWeight.w600,
+                ),
+              ),
+              if (badge.isNotEmpty) ...[
+                const SizedBox(height: 4),
+                Text(
+                  badge.toString(),
+                  key: Key('environment-studio-preset-row-diag-${preset.id}'),
+                  maxLines: 2,
+                  overflow: TextOverflow.ellipsis,
+                  style: TextStyle(
+                    color: errorCount > 0
+                        ? CupertinoColors.systemRed.resolveFrom(context)
+                        : CupertinoColors.systemOrange.resolveFrom(context),
+                    fontSize: 11,
+                    fontWeight: FontWeight.w600,
+                  ),
+                ),
+              ],
+            ],
+          ),
+        ),
+      ),
+    );
+  }
+}

```

#### `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart`

```diff
+import 'package:flutter/cupertino.dart';
+import 'package:map_core/map_core.dart';
+
+import '../../../ui/shared/cupertino_editor_widgets.dart';
+import 'environment_palette_item_view.dart';
+import 'environment_preset_diagnostics_view.dart';
+
+/// Détail read-only d’un preset : identité, paramètres, palette, diagnostics.
+class EnvironmentPresetDetail extends StatelessWidget {
+  const EnvironmentPresetDetail({
+    super.key,
+    required this.preset,
+    required this.report,
+    required this.labelColor,
+    required this.subtleColor,
+  });
+
+  final EnvironmentPreset preset;
+  final EnvironmentAuthoringDiagnosticsReport report;
+  final Color labelColor;
+  final Color subtleColor;
+
+  @override
+  Widget build(BuildContext context) {
+    final p = preset;
+    final diag = report.diagnosticsForPreset(p.id);
+    final fill = EditorChrome.chipFill(context);
+    final border = CupertinoColors.separator.resolveFrom(context);
+
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      key: const Key('environment-studio-detail-root'),
+      children: [
+        Text(
+          'Détail du preset',
+          style: TextStyle(
+            color: labelColor,
+            fontSize: 17,
+            fontWeight: FontWeight.w800,
+          ),
+        ),
+        const SizedBox(height: 14),
+        _sectionCard(
+          context,
+          key: const Key('environment-studio-section-identity'),
+          title: 'Identité',
+          child: Column(
+            crossAxisAlignment: CrossAxisAlignment.stretch,
+            children: [
+              _detailLine(
+                  'Nom', p.name, const Key('environment-studio-detail-name')),
+              _detailLine(
+                  'Id', p.id, const Key('environment-studio-detail-id')),
+              _detailLine(
+                'Template',
+                p.templateId,
+                const Key('environment-studio-detail-template'),
+              ),
+              _detailLine(
+                'Catégorie',
+                p.categoryId ?? '—',
+                const Key('environment-studio-detail-category'),
+              ),
+              _detailLine(
+                'Ordre d’affichage',
+                '${p.sortOrder}',
+                const Key('environment-studio-detail-sort'),
+              ),
+            ],
+          ),
+          fill: fill,
+          border: border,
+        ),
+        const SizedBox(height: 14),
+        _sectionCard(
+          context,
+          key: const Key('environment-studio-section-params'),
+          title: 'Paramètres par défaut',
+          child: Wrap(
+            spacing: 8,
+            runSpacing: 8,
+            children: [
+              _paramChip(
+                context,
+                label: 'Densité',
+                value: _formatDouble(p.defaultParams.density),
+                valueKey: const Key('environment-studio-detail-param-density'),
+              ),
+              _paramChip(
+                context,
+                label: 'Variation',
+                value: _formatDouble(p.defaultParams.variation),
+                valueKey:
+                    const Key('environment-studio-detail-param-variation'),
+              ),
+              _paramChip(
+                context,
+                label: 'Densité des bords',
+                value: _formatDouble(p.defaultParams.edgeDensity),
+                valueKey: const Key('environment-studio-detail-param-edge'),
+              ),
+              _paramChip(
+                context,
+                label: 'Espacement min. (cases)',
+                value: '${p.defaultParams.minSpacingCells}',
+                valueKey: const Key('environment-studio-detail-param-spacing'),
+              ),
+            ],
+          ),
+          fill: fill,
+          border: border,
+        ),
+        const SizedBox(height: 14),
+        _sectionCard(
+          context,
+          key: const Key('environment-studio-section-palette'),
+          title: 'Palette',
+          child: p.palette.isEmpty
+              ? Text(
+                  'Palette vide.',
+                  key: const Key('environment-studio-palette-empty'),
+                  style: TextStyle(color: subtleColor, fontSize: 13),
+                )
+              : Column(
+                  crossAxisAlignment: CrossAxisAlignment.stretch,
+                  children: [
+                    for (final item in p.palette)
+                      Padding(
+                        padding: const EdgeInsets.only(bottom: 10),
+                        child: EnvironmentPaletteItemView(
+                          item: item,
+                          subtleColor: subtleColor,
+                        ),
+                      ),
+                  ],
+                ),
+          fill: fill,
+          border: border,
+        ),
+        const SizedBox(height: 14),
+        _sectionCard(
+          context,
+          key: const Key('environment-studio-section-diagnostics'),
+          title: 'Diagnostics (preset)',
+          child: EnvironmentPresetDiagnosticsView(
+            diagnostics: diag,
+            labelColor: labelColor,
+            subtleColor: subtleColor,
+          ),
+          fill: fill,
+          border: border,
+        ),
+      ],
+    );
+  }
+
+  static String _formatDouble(double v) => v.toStringAsFixed(2);
+
+  Widget _sectionCard(
+    BuildContext context, {
+    required Key key,
+    required String title,
+    required Widget child,
+    required Color fill,
+    required Color border,
+  }) {
+    return DecoratedBox(
+      key: key,
+      decoration: BoxDecoration(
+        color: fill,
+        borderRadius: BorderRadius.circular(12),
+        border: Border.all(color: border),
+      ),
+      child: Padding(
+        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.stretch,
+          children: [
+            Text(
+              title,
+              style: TextStyle(
+                color: labelColor,
+                fontSize: 13,
+                fontWeight: FontWeight.w800,
+                letterSpacing: -0.1,
+              ),
+            ),
+            const SizedBox(height: 10),
+            child,
+          ],
+        ),
+      ),
+    );
+  }
+
+  Widget _detailLine(String title, String value, Key valueKey) {
+    return Padding(
+      padding: const EdgeInsets.only(bottom: 8),
+      child: Row(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          SizedBox(
+            width: 132,
+            child: Text(
+              title,
+              style: TextStyle(
+                color: subtleColor,
+                fontSize: 12,
+                fontWeight: FontWeight.w600,
+              ),
+            ),
+          ),
+          Expanded(
+            child: Text(
+              value,
+              key: valueKey,
+              style: TextStyle(
+                color: labelColor,
+                fontSize: 13,
+                fontWeight: FontWeight.w600,
+              ),
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+
+  Widget _paramChip(
+    BuildContext context, {
+    required String label,
+    required String value,
+    required Key valueKey,
+  }) {
+    final subtle = EditorChrome.subtleLabel(context);
+    return Container(
+      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
+      decoration: BoxDecoration(
+        color: EditorChrome.accentJade.withValues(alpha: 0.1),
+        borderRadius: BorderRadius.circular(10),
+        border: Border.all(
+          color: EditorChrome.accentJade.withValues(alpha: 0.32),
+        ),
+      ),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        mainAxisSize: MainAxisSize.min,
+        children: [
+          Text(
+            label,
+            style: TextStyle(
+              color: subtle,
+              fontSize: 10,
+              fontWeight: FontWeight.w700,
+            ),
+          ),
+          const SizedBox(height: 2),
+          Text(
+            value,
+            key: valueKey,
+            style: TextStyle(
+              color: labelColor,
+              fontSize: 13,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}

```

#### `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_diagnostics_view.dart`

```diff
+import 'package:flutter/cupertino.dart';
+import 'package:map_core/map_core.dart';
+
+import '../../../ui/shared/cupertino_editor_widgets.dart';
+import 'environment_diagnostic_presentation.dart';
+
+/// Drilldown read-only des diagnostics filtrés sur un preset.
+class EnvironmentPresetDiagnosticsView extends StatelessWidget {
+  const EnvironmentPresetDiagnosticsView({
+    super.key,
+    required this.diagnostics,
+    required this.labelColor,
+    required this.subtleColor,
+  });
+
+  final List<EnvironmentAuthoringDiagnostic> diagnostics;
+  final Color labelColor;
+  final Color subtleColor;
+
+  @override
+  Widget build(BuildContext context) {
+    if (diagnostics.isEmpty) {
+      return Text(
+        'Aucun diagnostic pour ce preset.',
+        key: const Key('environment-studio-preset-diagnostics-empty'),
+        style: TextStyle(
+          color: subtleColor,
+          fontSize: 13,
+          fontWeight: FontWeight.w600,
+        ),
+      );
+    }
+
+    var err = 0;
+    var warn = 0;
+    for (final d in diagnostics) {
+      switch (d.severity) {
+        case EnvironmentAuthoringDiagnosticSeverity.error:
+          err++;
+        case EnvironmentAuthoringDiagnosticSeverity.warning:
+          warn++;
+      }
+    }
+
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      key: const Key('environment-studio-preset-diagnostics-root'),
+      children: [
+        Text(
+          '$err erreur${err == 1 ? '' : 's'} · '
+          '$warn avertissement${warn == 1 ? '' : 's'}',
+          key: const Key('environment-studio-preset-diagnostics-summary'),
+          style: TextStyle(
+            color: subtleColor,
+            fontSize: 13,
+            fontWeight: FontWeight.w600,
+          ),
+        ),
+        const SizedBox(height: 10),
+        ...diagnostics.asMap().entries.map(
+              (e) => Padding(
+                padding: const EdgeInsets.only(bottom: 10),
+                child: _DiagnosticCard(
+                  index: e.key,
+                  diagnostic: e.value,
+                  labelColor: labelColor,
+                  subtleColor: subtleColor,
+                ),
+              ),
+            ),
+      ],
+    );
+  }
+}
+
+class _DiagnosticCard extends StatelessWidget {
+  const _DiagnosticCard({
+    required this.index,
+    required this.diagnostic,
+    required this.labelColor,
+    required this.subtleColor,
+  });
+
+  final int index;
+  final EnvironmentAuthoringDiagnostic diagnostic;
+  final Color labelColor;
+  final Color subtleColor;
+
+  @override
+  Widget build(BuildContext context) {
+    final d = diagnostic;
+    final isError = d.severity == EnvironmentAuthoringDiagnosticSeverity.error;
+    final badgeColor = isError
+        ? CupertinoColors.systemRed.resolveFrom(context)
+        : CupertinoColors.systemOrange.resolveFrom(context);
+    final fill = EditorChrome.chipFill(context);
+
+    return DecoratedBox(
+      key: Key('environment-studio-diag-card-$index'),
+      decoration: BoxDecoration(
+        borderRadius: BorderRadius.circular(12),
+        border: Border.all(
+          color: CupertinoColors.separator.resolveFrom(context),
+        ),
+        color: fill,
+      ),
+      child: Padding(
+        padding: const EdgeInsets.all(12),
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.stretch,
+          children: [
+            Row(
+              crossAxisAlignment: CrossAxisAlignment.start,
+              children: [
+                Container(
+                  padding:
+                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
+                  decoration: BoxDecoration(
+                    color: badgeColor.withValues(alpha: 0.15),
+                    borderRadius: BorderRadius.circular(8),
+                    border: Border.all(
+                      color: badgeColor.withValues(alpha: 0.55),
+                    ),
+                  ),
+                  child: Text(
+                    environmentDiagnosticSeverityLabel(d.severity),
+                    key: Key('environment-studio-diag-severity-$index'),
+                    style: TextStyle(
+                      color: badgeColor,
+                      fontSize: 11,
+                      fontWeight: FontWeight.w800,
+                    ),
+                  ),
+                ),
+                const SizedBox(width: 10),
+                Expanded(
+                  child: Text(
+                    environmentDiagnosticKindLabel(d.kind),
+                    key: Key('environment-studio-diag-kind-$index'),
+                    style: TextStyle(
+                      color: labelColor,
+                      fontSize: 13,
+                      fontWeight: FontWeight.w700,
+                    ),
+                  ),
+                ),
+              ],
+            ),
+            const SizedBox(height: 8),
+            Text(
+              d.message,
+              key: Key('environment-studio-diag-message-$index'),
+              style: TextStyle(
+                color: labelColor,
+                fontSize: 12.5,
+                height: 1.35,
+                fontWeight: FontWeight.w500,
+              ),
+            ),
+            if (_hasOptionalFields(d)) ...[
+              const SizedBox(height: 10),
+              ..._buildOptionalRows(d, index, subtleColor),
+            ],
+          ],
+        ),
+      ),
+    );
+  }
+
+  static bool _hasOptionalFields(EnvironmentAuthoringDiagnostic d) {
+    return d.elementId != null ||
+        d.templateId != null ||
+        d.mapId != null ||
+        d.layerId != null ||
+        d.areaId != null ||
+        d.targetTileLayerId != null ||
+        d.generatedPlacementId != null;
+  }
+
+  static List<Widget> _buildOptionalRows(
+    EnvironmentAuthoringDiagnostic d,
+    int index,
+    Color subtle,
+  ) {
+    final out = <Widget>[];
+    void add(String title, String? value, String field) {
+      if (value == null || value.isEmpty) {
+        return;
+      }
+      out.add(
+        Padding(
+          padding: const EdgeInsets.only(top: 4),
+          child: Row(
+            crossAxisAlignment: CrossAxisAlignment.start,
+            children: [
+              SizedBox(
+                width: 140,
+                child: Text(
+                  title,
+                  style: TextStyle(
+                    color: subtle,
+                    fontSize: 11,
+                    fontWeight: FontWeight.w600,
+                  ),
+                ),
+              ),
+              Expanded(
+                child: Text(
+                  value,
+                  key: Key('environment-studio-diag-field-$field-$index'),
+                  style: TextStyle(
+                    color: subtle,
+                    fontSize: 11.5,
+                    fontWeight: FontWeight.w600,
+                  ),
+                ),
+              ),
+            ],
+          ),
+        ),
+      );
+    }
+
+    add('elementId', d.elementId, 'elementId');
+    add('templateId', d.templateId, 'templateId');
+    add('mapId', d.mapId, 'mapId');
+    add('layerId', d.layerId, 'layerId');
+    add('areaId', d.areaId, 'areaId');
+    add('targetTileLayerId', d.targetTileLayerId, 'targetTileLayerId');
+    add('generatedPlacementId', d.generatedPlacementId, 'generatedPlacementId');
+    return out;
+  }
+}

```

#### `packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_view.dart`

```diff
+import 'package:flutter/cupertino.dart';
+import 'package:map_core/map_core.dart';
+
+import '../../../ui/shared/cupertino_editor_widgets.dart';
+
+/// Carte d’un item de palette Environment (read-only).
+class EnvironmentPaletteItemView extends StatelessWidget {
+  const EnvironmentPaletteItemView({
+    super.key,
+    required this.item,
+    required this.subtleColor,
+  });
+
+  final EnvironmentPaletteItem item;
+  final Color subtleColor;
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final fill = EditorChrome.chipFill(context);
+    final border = CupertinoColors.separator.resolveFrom(context);
+    final tags = item.tags.toList()..sort();
+
+    return DecoratedBox(
+      decoration: BoxDecoration(
+        borderRadius: BorderRadius.circular(12),
+        border: Border.all(color: border),
+        color: fill,
+      ),
+      child: Padding(
+        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.stretch,
+          children: [
+            Row(
+              children: [
+                Expanded(
+                  child: Text(
+                    item.elementId,
+                    key: Key(
+                        'environment-studio-palette-item-${item.elementId}'),
+                    style: TextStyle(
+                      color: label,
+                      fontSize: 14,
+                      fontWeight: FontWeight.w800,
+                      letterSpacing: -0.2,
+                    ),
+                  ),
+                ),
+                _miniChip(
+                  context,
+                  label: 'Poids ${item.weight}',
+                  key: Key(
+                      'environment-studio-palette-weight-${item.elementId}'),
+                ),
+              ],
+            ),
+            const SizedBox(height: 8),
+            Text(
+              _collisionLabel(item.collisionMode),
+              key: Key(
+                'environment-studio-palette-collision-${item.elementId}',
+              ),
+              style: TextStyle(
+                color: subtleColor,
+                fontSize: 12,
+                fontWeight: FontWeight.w600,
+              ),
+            ),
+            if (tags.isNotEmpty) ...[
+              const SizedBox(height: 8),
+              Wrap(
+                spacing: 6,
+                runSpacing: 6,
+                children: [
+                  for (final t in tags)
+                    _miniChip(
+                      context,
+                      label: t,
+                      key: Key(
+                        'environment-studio-palette-tag-${item.elementId}-$t',
+                      ),
+                    ),
+                ],
+              ),
+            ],
+          ],
+        ),
+      ),
+    );
+  }
+
+  static String _collisionLabel(EnvironmentCollisionMode m) {
+    return switch (m) {
+      EnvironmentCollisionMode.useElementDefault => 'Défaut élément',
+      EnvironmentCollisionMode.forceEnabled => 'Collision forcée',
+      EnvironmentCollisionMode.forceDisabled => 'Collision désactivée',
+    };
+  }
+
+  Widget _miniChip(
+    BuildContext context, {
+    required String label,
+    Key? key,
+  }) {
+    final subtle = EditorChrome.subtleLabel(context);
+    return Container(
+      key: key,
+      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
+      decoration: BoxDecoration(
+        color: EditorChrome.accentJade.withValues(alpha: 0.12),
+        borderRadius: BorderRadius.circular(999),
+        border: Border.all(
+          color: EditorChrome.accentJade.withValues(alpha: 0.35),
+        ),
+      ),
+      child: Text(
+        label,
+        style: TextStyle(
+          color: subtle,
+          fontSize: 11,
+          fontWeight: FontWeight.w700,
+        ),
+      ),
+    );
+  }
+}

```

## 17. Auto-review

- **Points solides** : découpage clair ; diagnostics réutilisables ; `knownTemplateIds` optionnel pour tests sans bruit en prod ; correction du bug Dart sur `_optionalRows`.
- **Points discutables** : le fichier `environment_diagnostic_presentation.dart` en plus des quatre fichiers nommés dans le prompt (justification : centraliser les libellés FR et les tester unitairement sans dupliquer des `switch` dans la vue).
- **Corrections après auto-review** : test palette passé en `forceDisabled` pour éviter collision de sous-chaîne avec le kind « Collision forcée sans profil » ; `prefer_const_literals` sur `knownTemplateIds`.
- **Risques restants** : libellés FR des kinds couplés à l’enum `map_core` — tout nouvel kind exige une mise à jour ici (comportement voulu pour l’instant).
- **Regard critique sur le prompt** : le drilldown V0 reste raisonnable ; la densité augmente légèrement mais reste scrollable ; découper le panel maintenant réduit la dette avant le CRUD.

## 18. Verdict

Statut du lot :

- [x] Validé

Résumé :

```
Lot Environment-11 livré : panel découpé, UI polish, drilldown diagnostics, tests verts sur le périmètre exigé ; suite complète map_editor +847 -34 inchangée (hors lot).
```

Prochain lot recommandé :

```
Environment-12 — Environment Preset Creation Draft Model V0
```
