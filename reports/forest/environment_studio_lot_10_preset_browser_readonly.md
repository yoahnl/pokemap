# Environment Studio Lot 10 — Preset Browser Read-only V0

## 1. Résumé exécutif

Le shell Environment Studio (Lot 9) est remplacé par un **browser read-only** : liste de presets à gauche, détail (identité, paramètres de génération, palette, diagnostics filtrés par `presetId`) à droite, sélection **locale** dans `StatefulWidget` sans provider ni mutation du `ProjectManifest`. `diagnoseProjectEnvironmentAuthoring(manifest, maps: const [])` + `diagnosticsForPreset`. Tests Lot 9 étendus + nouveau fichier `environment_studio_preset_browser_test.dart`. `flutter analyze` ciblé : OK. Suite complète `map_editor` : toujours `+845 -34` (dette préexistante).

## 2. Périmètre du lot

- Inclus : UI browser, sélection locale, affichage diagnostics par preset, empty states, tests.
- Exclus : CRUD, `map_core`, runtime, `build_runner`, persistance sélection, chargement maps disque.

## 3. Audit initial du shell Environment Studio

Fichiers inspectés :

- `environment_studio_workspace.dart` / `environment_studio_panel.dart` (Lot 9) — shell vertical unique, `StatelessWidget`.
- `path_studio/path_studio_panel.dart` — liste + panneau détail + sélection locale (pattern mental le plus proche ; Surface Studio absent du dossier `surface_studio/` dans ce dépôt).
- `test/shell_chrome_test_harness.dart` — construction `ProjectManifest` + `EnvironmentPreset` / `ProjectElementEntry`.
- `test/environment_studio/*` (Lot 9).
- `test/surface_studio_removed_test.dart` — smoke surface retiré.

**Pattern retenu** : Path Studio (liste + détail + état local), sans Riverpod supplémentaire ; style `EditorChrome` / `Cupertino` / îlots comme le shell Lot 9.

## 4. Décisions UI / sélection locale

- **`EnvironmentStudioPanel` → `StatefulWidget`** avec `String? _selectedPresetId`.
- **Initialisation** : `initState` → premier preset par tri `(sortOrder, id)`.
- **`didUpdateWidget`** : `_coerceSelectedId` si la liste change ou l’id courant disparaît → repli sur le premier valide (pas de crash).
- **Liste** : `GestureDetector` (pas de `CupertinoButton`) pour garder les tests « pas de bouton Cupertino » et éviter une UX « bouton » trompeuse.
- **Layout** : `Row` liste 300px + détail `Expanded` dans un `Column` avec `Expanded` sur la zone centrale ; pas de détail si `n == 0`.

## 5. Browser read-only ajouté

- `ListView.builder` clé `environment-studio-preset-list`, tuiles clé `environment-studio-preset-row-<id>`.
- Sous-titre par ligne : `id · nombre items palette · templateId`.
- Badge diagnostics par ligne si erreurs / warnings (`environment-studio-preset-row-diag-<id>`).
- Icône check si sélection.

## 6. Détail preset affiché

- Champs : nom, id, template, catégorie (`—` si null), ordre, densité / variation / densité bords / espacement minimal.
- Palette : `elementId`, ligne méta `Poids · collision (FR) · tags: …`.
- Branche défensive `Palette vide.` (inaccessible si factories `map_core` respectées).

## 7. Diagnostics affichés

- `EnvironmentAuthoringDiagnosticsReport.diagnosticsForPreset(presetId)`.
- Vide : `Aucun diagnostic pour ce preset.`
- Sinon : compteur + messages colorés (erreur / avertissement).
- Bloc projet : titre `Diagnostics Environment (projet)` + compteurs globaux + note `maps: const []`.

## 8. Pourquoi aucune édition / sauvegarde / génération dans ce lot

- Aucun `onPressed` mutateur ; `setState` uniquement sur l’id sélectionné ; aucun `copyWith` sur le manifest ; pas de disque ; pas de générateur.

## 9. Fichiers modifiés

| Chemin | Modification |
|--------|----------------|
| `packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart` | Browser StatefulWidget + widgets privés. |
| `packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart` | Empty state, liste, tap, read-only. |
| `packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart` | **Nouveau** — détail, catégorie, diagnostics, read-only. |

**Non modifiés** : `environment_studio_workspace.dart`, `environment_studio_workspace_entry_test.dart`, `project_explorer_panel.dart`, `top_toolbar.dart`, `shell_chrome_test_harness.dart`, `map_core`, `map_runtime`, etc.

## 10. Tests ajoutés ou modifiés

- `environment_studio_workspace_test.dart` : vide sans liste/détail ; 2 presets + premier sélectionné ; tap change détail ; absence de `CupertinoButton`.
- `environment_studio_preset_browser_test.dart` : détail complet ; catégorie `—` ; diagnostics vides ; erreur `missing_tree` ; pas de libellés Create/Edit/Delete/Generate.

## 11. Commandes exécutées

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
dart format \
  lib/src/features/environment_studio/environment_studio_workspace.dart \
  lib/src/features/environment_studio/environment_studio_panel.dart \
  test/environment_studio/environment_studio_workspace_test.dart \
  test/environment_studio/environment_studio_workspace_entry_test.dart \
  test/environment_studio/environment_studio_preset_browser_test.dart
```

```bash
flutter analyze \
  lib/src/features/environment_studio/environment_studio_workspace.dart \
  lib/src/features/environment_studio/environment_studio_panel.dart \
  test/environment_studio/environment_studio_workspace_test.dart \
  test/environment_studio/environment_studio_workspace_entry_test.dart \
  test/environment_studio/environment_studio_preset_browser_test.dart
```

```bash
flutter test test/environment_studio/environment_studio_workspace_test.dart --reporter expanded
flutter test test/environment_studio/environment_studio_workspace_entry_test.dart --reporter expanded
flutter test test/environment_studio/environment_studio_preset_browser_test.dart --reporter expanded
flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart --reporter expanded
flutter test test/environment_studio --reporter expanded
flutter test test/surface_studio_removed_test.dart --reporter expanded
flutter test
```

## 12. Résultats des commandes

- **`dart format`** : succès.
- **`flutter analyze`** (chemins ci-dessus) : `No issues found!` (exit 0).
- **`flutter test test/environment_studio/environment_studio_workspace_test.dart`** : `All tests passed!` (+4).
- **`flutter test test/environment_studio/environment_studio_workspace_entry_test.dart`** : `All tests passed!` (+3).
- **`flutter test test/environment_studio/environment_studio_preset_browser_test.dart`** : `All tests passed!` (+5).
- **`flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart`** : `00:01 +14: All tests passed!` (exit 0).
- **`flutter test test/environment_studio`** : `00:04 +12: All tests passed!` (exit 0).
- **`flutter test test/surface_studio_removed_test.dart`** : `00:00 +1: All tests passed!` (exit 0).
- **`flutter test`** (package entier) : ligne finale `00:55 +845 -34: Some tests failed.` (exit 1) — **34 échecs préexistants**, hors périmètre Lot 10.

## 13. Git status initial et final

**Git status initial** : à l’ouverture de l’implémentation Lot 10 dans cette session, la plage de travail ne contenait pas le fichier `environment_studio_preset_browser_test.dart` ; `environment_studio_panel.dart` et `environment_studio_workspace_test.dart` étaient dans l’état issu du Lot 9 (fichiers suivis modifiés dans la continuité du dépôt local).

**Git status final** (`git status --short --untracked-files=all`) :

```
 M packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
 M packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart
?? packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart
```

## 14. Contenu complet des fichiers créés ou modifiés

### 14.1 `environment_studio_workspace.dart`

Inchangé depuis le Lot 9 (47 lignes) — contenu identique au fichier :

```1:47:packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart
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

### 14.2 `environment_studio_panel.dart` (756 lignes, intégral)

```dart
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';

/// Browser read-only des presets Environment (Lot Environment-10).
///
/// Sélection locale uniquement ([StatefulWidget]) : aucune mutation du
/// [ProjectManifest], aucun provider, aucune persistance.
class EnvironmentStudioPanel extends StatefulWidget {
  const EnvironmentStudioPanel({
    super.key,
    required this.manifest,
  });

  final ProjectManifest manifest;

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
          child: DecoratedBox(
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
                final isSelected = p.id == _selectedPresetId;
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
                  onTap: () => setState(() => _selectedPresetId = p.id),
                );
              },
            ),
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
                    child: _PresetDetail(
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

class _PresetDetail extends StatelessWidget {
  const _PresetDetail({
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
        _detailLine('Nom', p.name, const Key('environment-studio-detail-name')),
        _detailLine('Id', p.id, const Key('environment-studio-detail-id')),
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
        const SizedBox(height: 16),
        Text(
          'Paramètres par défaut',
          style: TextStyle(
            color: labelColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _detailLine(
          'Densité',
          _formatDouble(p.defaultParams.density),
          const Key('environment-studio-detail-param-density'),
        ),
        _detailLine(
          'Variation',
          _formatDouble(p.defaultParams.variation),
          const Key('environment-studio-detail-param-variation'),
        ),
        _detailLine(
          'Densité des bords',
          _formatDouble(p.defaultParams.edgeDensity),
          const Key('environment-studio-detail-param-edge'),
        ),
        _detailLine(
          'Espacement minimal (cases)',
          '${p.defaultParams.minSpacingCells}',
          const Key('environment-studio-detail-param-spacing'),
        ),
        const SizedBox(height: 16),
        Text(
          'Palette',
          style: TextStyle(
            color: labelColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (p.palette.isEmpty)
          Text(
            'Palette vide.',
            key: const Key('environment-studio-palette-empty'),
            style: TextStyle(color: subtleColor, fontSize: 13),
          )
        else
          ...p.palette.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PaletteItemBlock(item: item, subtle: subtleColor),
            ),
          ),
        const SizedBox(height: 18),
        Text(
          'Diagnostics (preset)',
          style: TextStyle(
            color: labelColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (diag.isEmpty)
          Text(
            'Aucun diagnostic pour ce preset.',
            key: const Key('environment-studio-preset-diagnostics-empty'),
            style: TextStyle(
              color: subtleColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          )
        else ...[
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
          const SizedBox(height: 8),
          ...diag.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    e.value.message,
                    key: Key('environment-studio-preset-diag-line-${e.key}'),
                    style: TextStyle(
                      color: e.value.severity ==
                              EnvironmentAuthoringDiagnosticSeverity.error
                          ? CupertinoColors.systemRed.resolveFrom(context)
                          : CupertinoColors.systemOrange.resolveFrom(context),
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
        ],
      ],
    );
  }

  static String _formatDouble(double v) => v.toStringAsFixed(2);

  Widget _detailLine(String title, String value, Key valueKey) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
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
}

class _PaletteItemBlock extends StatelessWidget {
  const _PaletteItemBlock({
    required this.item,
    required this.subtle,
  });

  final EnvironmentPaletteItem item;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final tagStr =
        item.tags.isEmpty ? '—' : (item.tags.toList()..sort()).join(', ');

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              item.elementId,
              key: Key('environment-studio-palette-item-${item.elementId}'),
              style: TextStyle(
                color: label,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Poids ${item.weight} · ${_collisionLabel(item.collisionMode)} · tags: $tagStr',
              key:
                  Key('environment-studio-palette-item-meta-${item.elementId}'),
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                height: 1.35,
              ),
            ),
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
}
```

### 14.3 `environment_studio_workspace_test.dart` (intégral)

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';

void main() {
  group('EnvironmentStudioPanel', () {
    testWidgets('état vide : titre, badge read-only, pas de liste ni détail',
        (tester) async {
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
        find.byKey(const Key('environment-studio-read-only-banner')),
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
      expect(find.byKey(const Key('environment-studio-preset-list')),
          findsNothing);
      expect(find.byKey(const Key('environment-studio-detail-root')),
          findsNothing);
    });

    testWidgets('liste presets et sélection du premier par défaut', (
      tester,
    ) async {
      await _pumpPanel(
        tester,
        _manifest(
          environmentPresets: [
            _preset(id: 'meadow', name: 'Prairie', sortOrder: 0),
            _preset(id: 'forest', name: 'Forêt', sortOrder: 1),
          ],
          elements: [_element(id: 'elm')],
        ),
      );

      expect(find.text('2 presets'), findsOneWidget);
      expect(find.byKey(const Key('environment-studio-preset-list')),
          findsOneWidget);
      expect(
        find.byKey(const Key('environment-studio-empty-presets')),
        findsNothing,
      );
      expect(find.byKey(const Key('environment-studio-detail-id')),
          findsOneWidget);
      expect(find.text('meadow'), findsWidgets);
    });

    testWidgets('tap sur un autre preset met à jour le détail', (tester) async {
      await _pumpPanel(
        tester,
        _manifest(
          environmentPresets: [
            _preset(id: 'meadow', name: 'Prairie', sortOrder: 0),
            _preset(id: 'forest', name: 'Forêt', sortOrder: 1),
          ],
          elements: [_element(id: 'elm')],
        ),
      );

      expect(
        (tester.widget<Text>(
                find.byKey(const Key('environment-studio-detail-id'))))
            .data,
        'meadow',
      );

      await tester
          .tap(find.byKey(const Key('environment-studio-preset-row-forest')));
      await tester.pumpAndSettle();

      expect(
        (tester.widget<Text>(
                find.byKey(const Key('environment-studio-detail-id'))))
            .data,
        'forest',
      );
    });

    testWidgets('ne propose aucun CupertinoButton dans le panneau', (
      tester,
    ) async {
      await _pumpPanel(
        tester,
        _manifest(
          environmentPresets: [_preset(id: 'x')],
          elements: [_element(id: 'elm')],
        ),
      );

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
  List<ProjectElementEntry> elements = const [],
}) {
  return ProjectManifest(
    name: 'env-shell-test',
    maps: const [],
    tilesets: const [],
    environmentPresets: environmentPresets,
    elements: elements,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

EnvironmentPreset _preset({
  required String id,
  String? name,
  int sortOrder = 0,
}) {
  return EnvironmentPreset(
    id: id,
    name: name ?? 'Preset $id',
    templateId: 'tpl',
    palette: [
      EnvironmentPaletteItem(elementId: 'elm', weight: 1),
    ],
    defaultParams: EnvironmentGenerationParams.standard(),
    sortOrder: sortOrder,
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

### 14.4 `environment_studio_preset_browser_test.dart` (intégral)

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';

void main() {
  group('EnvironmentStudioPanel — browser read-only', () {
    testWidgets('détail : id, nom, template, catégorie, tri, params, palette',
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
                  collisionMode: EnvironmentCollisionMode.forceEnabled,
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
        find.byKey(const Key('environment-studio-palette-item-meta-oak')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Poids 5'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Collision forcée'),
        findsOneWidget,
      );
      expect(
        find.textContaining('canopy'),
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

    testWidgets('diagnostic erreur élément palette manquant', (tester) async {
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
        find.byKey(const Key('environment-studio-preset-diag-line-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-studio-preset-row-diag-bad')),
        findsOneWidget,
      );
    });

    testWidgets('read-only : pas de libellés Create / Edit / Delete / Generate',
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

### 14.5 `environment_studio_workspace_entry_test.dart`

**Non modifié** dans ce lot — contenu inchangé par rapport au Lot 9.

## 15. Diff complet

### 15.1 Diff `git diff` — `environment_studio_workspace_test.dart`

```diff
diff --git a/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart b/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart
index 83e8f981..167a13ce 100644
--- a/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart
+++ b/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart
@@ -6,9 +6,8 @@ import 'package:map_editor/src/features/environment_studio/environment_studio_pa
 
 void main() {
   group('EnvironmentStudioPanel', () {
-    testWidgets('affiche titre, description, état vide et diagnostics', (
-      tester,
-    ) async {
+    testWidgets('état vide : titre, badge read-only, pas de liste ni détail',
+        (tester) async {
       final manifest = _manifest();
       final report = diagnoseProjectEnvironmentAuthoring(
         manifest,
@@ -22,11 +21,7 @@ void main() {
       expect(find.byKey(const Key('environment-studio-title')), findsOneWidget);
       expect(find.text('Environment Studio'), findsOneWidget);
       expect(
-        find.byKey(const Key('environment-studio-description')),
-        findsOneWidget,
-      );
-      expect(
-        find.textContaining('forêts, bosquets, prairies'),
+        find.byKey(const Key('environment-studio-read-only-banner')),
         findsOneWidget,
       );
       expect(find.byKey(const Key('environment-studio-empty-presets')),
@@ -38,29 +33,79 @@ void main() {
         findsOneWidget,
       );
       expect(find.textContaining('génération organique'), findsOneWidget);
+      expect(find.byKey(const Key('environment-studio-preset-list')),
+          findsNothing);
+      expect(find.byKey(const Key('environment-studio-detail-root')),
+          findsNothing);
     });
 
-    testWidgets('affiche le nombre de presets quand le manifest en définit',
-        (tester) async {
+    testWidgets('liste presets et sélection du premier par défaut', (
+      tester,
+    ) async {
       await _pumpPanel(
         tester,
         _manifest(
           environmentPresets: [
-            _preset(id: 'a'),
-            _preset(id: 'b'),
+            _preset(id: 'meadow', name: 'Prairie', sortOrder: 0),
+            _preset(id: 'forest', name: 'Forêt', sortOrder: 1),
           ],
+          elements: [_element(id: 'elm')],
         ),
       );
 
       expect(find.text('2 presets'), findsOneWidget);
+      expect(find.byKey(const Key('environment-studio-preset-list')),
+          findsOneWidget);
       expect(
         find.byKey(const Key('environment-studio-empty-presets')),
         findsNothing,
       );
+      expect(find.byKey(const Key('environment-studio-detail-id')),
+          findsOneWidget);
+      expect(find.text('meadow'), findsWidgets);
     });
 
-    testWidgets('ne propose aucun bouton d’action actif', (tester) async {
-      await _pumpPanel(tester, _manifest());
+    testWidgets('tap sur un autre preset met à jour le détail', (tester) async {
+      await _pumpPanel(
+        tester,
+        _manifest(
+          environmentPresets: [
+            _preset(id: 'meadow', name: 'Prairie', sortOrder: 0),
+            _preset(id: 'forest', name: 'Forêt', sortOrder: 1),
+          ],
+          elements: [_element(id: 'elm')],
+        ),
+      );
+
+      expect(
+        (tester.widget<Text>(
+                find.byKey(const Key('environment-studio-detail-id'))))
+            .data,
+        'meadow',
+      );
+
+      await tester
+          .tap(find.byKey(const Key('environment-studio-preset-row-forest')));
+      await tester.pumpAndSettle();
+
+      expect(
+        (tester.widget<Text>(
+                find.byKey(const Key('environment-studio-detail-id'))))
+            .data,
+        'forest',
+      );
+    });
+
+    testWidgets('ne propose aucun CupertinoButton dans le panneau', (
+      tester,
+    ) async {
+      await _pumpPanel(
+        tester,
+        _manifest(
+          environmentPresets: [_preset(id: 'x')],
+          elements: [_element(id: 'elm')],
+        ),
+      );
 
       final panel = find.byType(EnvironmentStudioPanel);
       expect(
@@ -84,25 +129,45 @@ Future<void> _pumpPanel(WidgetTester tester, ProjectManifest manifest) async {
 
 ProjectManifest _manifest({
   List<EnvironmentPreset> environmentPresets = const [],
+  List<ProjectElementEntry> elements = const [],
 }) {
   return ProjectManifest(
     name: 'env-shell-test',
     maps: const [],
     tilesets: const [],
     environmentPresets: environmentPresets,
+    elements: elements,
     surfaceCatalog: ProjectSurfaceCatalog(),
   );
 }
 
-EnvironmentPreset _preset({required String id}) {
+EnvironmentPreset _preset({
+  required String id,
+  String? name,
+  int sortOrder = 0,
+}) {
   return EnvironmentPreset(
     id: id,
-    name: 'Preset $id',
+    name: name ?? 'Preset $id',
     templateId: 'tpl',
     palette: [
       EnvironmentPaletteItem(elementId: 'elm', weight: 1),
     ],
     defaultParams: EnvironmentGenerationParams.standard(),
-    sortOrder: 0,
+    sortOrder: sortOrder,
+  );
+}
+
+ProjectElementEntry _element({required String id}) {
+  return ProjectElementEntry(
+    id: id,
+    name: 'El $id',
+    tilesetId: 'ts',
+    categoryId: 'cat',
+    frames: const [
+      TilesetVisualFrame(
+        source: TilesetSourceRect(x: 0, y: 0),
+      ),
+    ],
   );
 }

```

### 15.2 Diff `git diff` — `environment_studio_panel.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart b/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
index 07f5da53..61c9ab3c 100644
--- a/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
@@ -3,11 +3,11 @@ import 'package:map_core/map_core.dart';
 
 import '../../ui/shared/cupertino_editor_widgets.dart';
 
-/// Shell read-only central pour Environment Studio (Lot Environment-9).
+/// Browser read-only des presets Environment (Lot Environment-10).
 ///
-/// Aucune mutation manifest, aucun flux save, aucune génération : affichage
-/// purement informatif à partir du [ProjectManifest] déjà en mémoire.
-class EnvironmentStudioPanel extends StatelessWidget {
+/// Sélection locale uniquement ([StatefulWidget]) : aucune mutation du
+/// [ProjectManifest], aucun provider, aucune persistance.
+class EnvironmentStudioPanel extends StatefulWidget {
   const EnvironmentStudioPanel({
     super.key,
     required this.manifest,
@@ -15,13 +15,77 @@ class EnvironmentStudioPanel extends StatelessWidget {
 
   final ProjectManifest manifest;
 
+  @override
+  State<EnvironmentStudioPanel> createState() => _EnvironmentStudioPanelState();
+}
+
+class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
+  String? _selectedPresetId;
+
+  @override
+  void initState() {
+    super.initState();
+    _selectedPresetId = _defaultSelectedId(widget.manifest.environmentPresets);
+  }
+
+  @override
+  void didUpdateWidget(covariant EnvironmentStudioPanel oldWidget) {
+    super.didUpdateWidget(oldWidget);
+    final next = _coerceSelectedId(
+      widget.manifest.environmentPresets,
+      _selectedPresetId,
+    );
+    if (next != _selectedPresetId) {
+      setState(() => _selectedPresetId = next);
+    }
+  }
+
+  static String? _defaultSelectedId(List<EnvironmentPreset> presets) {
+    return _coerceSelectedId(presets, null);
+  }
+
+  /// Garde une sélection valide : premier preset (tri sortOrder, id) si besoin.
+  static String? _coerceSelectedId(
+    List<EnvironmentPreset> presets,
+    String? current,
+  ) {
+    if (presets.isEmpty) {
+      return null;
+    }
+    if (current != null && presets.any((p) => p.id == current)) {
+      return current;
+    }
+    final sorted = [...presets]..sort((a, b) {
+        final c = a.sortOrder.compareTo(b.sortOrder);
+        if (c != 0) {
+          return c;
+        }
+        return a.id.compareTo(b.id);
+      });
+    return sorted.first.id;
+  }
+
+  EnvironmentPreset? _selectedPreset(List<EnvironmentPreset> presets) {
+    final id = _selectedPresetId;
+    if (id == null) {
+      return null;
+    }
+    for (final p in presets) {
+      if (p.id == id) {
+        return p;
+      }
+    }
+    return null;
+  }
+
   @override
   Widget build(BuildContext context) {
     final label = EditorChrome.primaryLabel(context);
     final subtle = EditorChrome.subtleLabel(context);
-    final n = manifest.environmentPresets.length;
+    final presets = widget.manifest.environmentPresets;
+    final n = presets.length;
     final report = diagnoseProjectEnvironmentAuthoring(
-      manifest,
+      widget.manifest,
       maps: const [],
     );
     final s = report.summary;
@@ -34,156 +98,658 @@ class EnvironmentStudioPanel extends StatelessWidget {
       child: SafeArea(
         child: Center(
           child: ConstrainedBox(
-            constraints: const BoxConstraints(maxWidth: 720),
-            child: SingleChildScrollView(
-              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
+            constraints: const BoxConstraints(maxWidth: 1040),
+            child: Padding(
+              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                 children: [
-                  Text(
-                    'Environment Studio',
-                    key: const Key('environment-studio-title'),
-                    style: TextStyle(
-                      color: label,
-                      fontSize: 26,
-                      fontWeight: FontWeight.w800,
-                      letterSpacing: -0.4,
-                    ),
-                  ),
-                  const SizedBox(height: 8),
-                  Text(
-                    'Presets d’environnements organiques',
-                    style: TextStyle(
-                      color: subtle,
-                      fontSize: 14,
-                      fontWeight: FontWeight.w600,
-                    ),
-                  ),
+                  _buildHeader(context, label, subtle, n),
                   const SizedBox(height: 20),
-                  Container(
-                    padding: const EdgeInsets.symmetric(
-                      horizontal: 12,
-                      vertical: 8,
-                    ),
-                    decoration: BoxDecoration(
-                      color: EditorChrome.chipFill(context),
-                      borderRadius: BorderRadius.circular(10),
-                      border: Border.all(
-                        color: EditorChrome.accentJade.withValues(alpha: 0.35),
+                  if (n == 0)
+                    Expanded(
+                      child: _buildEmptyPresets(context, subtle),
+                    )
+                  else
+                    Expanded(
+                      child: _buildBrowser(
+                        context,
+                        label,
+                        subtle,
+                        presets,
+                        report,
                       ),
                     ),
-                    child: const Text(
-                      'Lecture seule — édition et génération arrivent dans les prochains lots.',
-                      key: Key('environment-studio-read-only-banner'),
+                  const SizedBox(height: 20),
+                  _buildGlobalDiagnostics(context, label, subtle, s),
+                  const SizedBox(height: 16),
+                  _buildSoon(context, label, subtle),
+                ],
+              ),
+            ),
+          ),
+        ),
+      ),
+    );
+  }
+
+  Widget _buildHeader(
+    BuildContext context,
+    Color label,
+    Color subtle,
+    int presetCount,
+  ) {
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        Text(
+          'Environment Studio',
+          key: const Key('environment-studio-title'),
+          style: TextStyle(
+            color: label,
+            fontSize: 26,
+            fontWeight: FontWeight.w800,
+            letterSpacing: -0.4,
+          ),
+        ),
+        const SizedBox(height: 8),
+        Text(
+          'Presets d’environnements organiques',
+          style: TextStyle(
+            color: subtle,
+            fontSize: 14,
+            fontWeight: FontWeight.w600,
+          ),
+        ),
+        const SizedBox(height: 12),
+        Container(
+          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
+          decoration: BoxDecoration(
+            color: EditorChrome.chipFill(context),
+            borderRadius: BorderRadius.circular(10),
+            border: Border.all(
+              color: EditorChrome.accentJade.withValues(alpha: 0.35),
+            ),
+          ),
+          child: const Text(
+            'Lecture seule — édition et génération arrivent dans les prochains lots.',
+            key: Key('environment-studio-read-only-banner'),
+            style: TextStyle(
+              color: EditorChrome.accentJade,
+              fontSize: 12,
+              fontWeight: FontWeight.w600,
+            ),
+          ),
+        ),
+        const SizedBox(height: 12),
+        Text(
+          presetCount == 1 ? '1 preset' : '$presetCount presets',
+          key: const Key('environment-studio-preset-count'),
+          style: TextStyle(
+            color: subtle,
+            fontSize: 13,
+            fontWeight: FontWeight.w600,
+          ),
+        ),
+      ],
+    );
+  }
+
+  Widget _buildEmptyPresets(BuildContext context, Color subtle) {
+    return Align(
+      alignment: Alignment.topCenter,
+      child: Text(
+        'Aucun preset d’environnement pour le moment.\n'
+        'Les presets seront créés ici dans un prochain lot.',
+        key: const Key('environment-studio-empty-presets'),
+        textAlign: TextAlign.center,
+        style: TextStyle(
+          color: subtle,
+          fontSize: 14,
+          height: 1.4,
+          fontWeight: FontWeight.w500,
+        ),
+      ),
+    );
+  }
+
+  Widget _buildBrowser(
+    BuildContext context,
+    Color label,
+    Color subtle,
+    List<EnvironmentPreset> presets,
+    EnvironmentAuthoringDiagnosticsReport report,
+  ) {
+    final selected = _selectedPreset(presets);
+
+    return Row(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        SizedBox(
+          width: 300,
+          child: DecoratedBox(
+            decoration: BoxDecoration(
+              color: EditorChrome.chipFill(context),
+              borderRadius: BorderRadius.circular(12),
+              border: Border.all(
+                color: CupertinoColors.separator.resolveFrom(context),
+              ),
+            ),
+            child: ListView.builder(
+              key: const Key('environment-studio-preset-list'),
+              padding: const EdgeInsets.symmetric(vertical: 8),
+              itemCount: presets.length,
+              itemBuilder: (context, index) {
+                final p = presets[index];
+                final isSelected = p.id == _selectedPresetId;
+                final diag = report.diagnosticsForPreset(p.id);
+                var err = 0;
+                var warn = 0;
+                for (final d in diag) {
+                  switch (d.severity) {
+                    case EnvironmentAuthoringDiagnosticSeverity.error:
+                      err++;
+                    case EnvironmentAuthoringDiagnosticSeverity.warning:
+                      warn++;
+                  }
+                }
+                return _PresetListTile(
+                  preset: p,
+                  selected: isSelected,
+                  errorCount: err,
+                  warningCount: warn,
+                  onTap: () => setState(() => _selectedPresetId = p.id),
+                );
+              },
+            ),
+          ),
+        ),
+        const SizedBox(width: 16),
+        Expanded(
+          child: DecoratedBox(
+            decoration: BoxDecoration(
+              color: EditorChrome.chipFill(context),
+              borderRadius: BorderRadius.circular(12),
+              border: Border.all(
+                color: CupertinoColors.separator.resolveFrom(context),
+              ),
+            ),
+            child: selected == null
+                ? Center(
+                    child: Text(
+                      'Preset sélectionné introuvable.',
+                      key: const Key('environment-studio-preset-missing'),
                       style: TextStyle(
-                        color: EditorChrome.accentJade,
-                        fontSize: 12,
+                        color: subtle,
+                        fontSize: 14,
                         fontWeight: FontWeight.w600,
                       ),
                     ),
-                  ),
-                  const SizedBox(height: 28),
-                  Text(
-                    'Créez et gérez des presets d’environnements organiques pour générer des forêts, bosquets, prairies, côtes rocheuses et autres zones naturelles.',
-                    key: const Key('environment-studio-description'),
-                    style: TextStyle(
-                      color: label,
-                      fontSize: 15,
-                      height: 1.45,
-                      fontWeight: FontWeight.w500,
-                    ),
-                  ),
-                  const SizedBox(height: 32),
-                  Text(
-                    'Presets d’environnement',
-                    key: const Key('environment-studio-preset-section-title'),
-                    style: TextStyle(
-                      color: label,
-                      fontSize: 17,
-                      fontWeight: FontWeight.w700,
-                    ),
-                  ),
-                  const SizedBox(height: 8),
-                  Text(
-                    n == 1 ? '1 preset' : '$n presets',
-                    key: const Key('environment-studio-preset-count'),
-                    style: TextStyle(
-                      color: subtle,
-                      fontSize: 14,
-                      fontWeight: FontWeight.w600,
+                  )
+                : SingleChildScrollView(
+                    key: const Key('environment-studio-detail-scroll'),
+                    padding: const EdgeInsets.all(20),
+                    child: _PresetDetail(
+                      preset: selected,
+                      report: report,
+                      labelColor: label,
+                      subtleColor: subtle,
                     ),
                   ),
-                  if (n == 0) ...[
-                    const SizedBox(height: 12),
-                    Text(
-                      'Aucun preset d’environnement pour le moment.\nLes presets seront créés ici dans un prochain lot.',
-                      key: const Key('environment-studio-empty-presets'),
+          ),
+        ),
+      ],
+    );
+  }
+
+  Widget _buildGlobalDiagnostics(
+    BuildContext context,
+    Color label,
+    Color subtle,
+    EnvironmentAuthoringDiagnosticsSummary s,
+  ) {
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        Text(
+          'Diagnostics Environment (projet)',
+          key: const Key('environment-studio-diagnostics-title'),
+          style: TextStyle(
+            color: label,
+            fontSize: 16,
+            fontWeight: FontWeight.w700,
+          ),
+        ),
+        const SizedBox(height: 6),
+        Text(
+          '${s.errorCount} erreur(s) · ${s.warningCount} avertissement(s)',
+          key: const Key('environment-studio-diagnostics-counts'),
+          style: TextStyle(
+            color: subtle,
+            fontSize: 13,
+            fontWeight: FontWeight.w600,
+          ),
+        ),
+        const SizedBox(height: 6),
+        Text(
+          'Les diagnostics d’usage dans les maps seront activés quand les cartes '
+          'chargées seront connectées au workspace.',
+          key: const Key('environment-studio-diagnostics-map-note'),
+          style: TextStyle(
+            color: subtle,
+            fontSize: 11,
+            height: 1.35,
+          ),
+        ),
+      ],
+    );
+  }
+
+  Widget _buildSoon(BuildContext context, Color label, Color subtle) {
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        Text(
+          'Bientôt :',
+          key: const Key('environment-studio-soon-title'),
+          style: TextStyle(
+            color: label,
+            fontSize: 15,
+            fontWeight: FontWeight.w700,
+          ),
+        ),
+        const SizedBox(height: 8),
+        Text(
+          '• création de presets ;\n'
+          '• édition de palettes ;\n'
+          '• utilisation dans les Environment Layers ;\n'
+          '• génération organique sur les maps.',
+          key: const Key('environment-studio-soon-bullets'),
+          style: TextStyle(
+            color: subtle,
+            fontSize: 12,
+            height: 1.45,
+          ),
+        ),
+      ],
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
                       style: TextStyle(
-                        color: subtle,
-                        fontSize: 13,
-                        height: 1.35,
+                        color: label,
+                        fontSize: 14,
+                        fontWeight: FontWeight.w700,
                       ),
                     ),
-                  ],
-                  const SizedBox(height: 28),
-                  Text(
-                    'Diagnostics Environment',
-                    key: const Key('environment-studio-diagnostics-title'),
-                    style: TextStyle(
-                      color: label,
-                      fontSize: 17,
-                      fontWeight: FontWeight.w700,
-                    ),
                   ),
-                  const SizedBox(height: 8),
-                  Text(
-                    '${s.errorCount} erreur(s) · ${s.warningCount} avertissement(s)',
-                    key: const Key('environment-studio-diagnostics-counts'),
-                    style: TextStyle(
-                      color: subtle,
-                      fontSize: 14,
-                      fontWeight: FontWeight.w600,
+                  if (selected)
+                    const Icon(
+                      CupertinoIcons.check_mark_circled_solid,
+                      size: 16,
+                      color: accent,
                     ),
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
                   ),
-                  const SizedBox(height: 10),
-                  Text(
-                    'Les diagnostics d’usage dans les maps seront activés quand les cartes chargées seront connectées au workspace.',
-                    key: const Key('environment-studio-diagnostics-map-note'),
+                ),
+              ],
+            ],
+          ),
+        ),
+      ),
+    );
+  }
+}
+
+class _PresetDetail extends StatelessWidget {
+  const _PresetDetail({
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
+    var err = 0;
+    var warn = 0;
+    for (final d in diag) {
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
+        _detailLine('Nom', p.name, const Key('environment-studio-detail-name')),
+        _detailLine('Id', p.id, const Key('environment-studio-detail-id')),
+        _detailLine(
+          'Template',
+          p.templateId,
+          const Key('environment-studio-detail-template'),
+        ),
+        _detailLine(
+          'Catégorie',
+          p.categoryId ?? '—',
+          const Key('environment-studio-detail-category'),
+        ),
+        _detailLine(
+          'Ordre d’affichage',
+          '${p.sortOrder}',
+          const Key('environment-studio-detail-sort'),
+        ),
+        const SizedBox(height: 16),
+        Text(
+          'Paramètres par défaut',
+          style: TextStyle(
+            color: labelColor,
+            fontSize: 15,
+            fontWeight: FontWeight.w700,
+          ),
+        ),
+        const SizedBox(height: 8),
+        _detailLine(
+          'Densité',
+          _formatDouble(p.defaultParams.density),
+          const Key('environment-studio-detail-param-density'),
+        ),
+        _detailLine(
+          'Variation',
+          _formatDouble(p.defaultParams.variation),
+          const Key('environment-studio-detail-param-variation'),
+        ),
+        _detailLine(
+          'Densité des bords',
+          _formatDouble(p.defaultParams.edgeDensity),
+          const Key('environment-studio-detail-param-edge'),
+        ),
+        _detailLine(
+          'Espacement minimal (cases)',
+          '${p.defaultParams.minSpacingCells}',
+          const Key('environment-studio-detail-param-spacing'),
+        ),
+        const SizedBox(height: 16),
+        Text(
+          'Palette',
+          style: TextStyle(
+            color: labelColor,
+            fontSize: 15,
+            fontWeight: FontWeight.w700,
+          ),
+        ),
+        const SizedBox(height: 8),
+        if (p.palette.isEmpty)
+          Text(
+            'Palette vide.',
+            key: const Key('environment-studio-palette-empty'),
+            style: TextStyle(color: subtleColor, fontSize: 13),
+          )
+        else
+          ...p.palette.map(
+            (item) => Padding(
+              padding: const EdgeInsets.only(bottom: 10),
+              child: _PaletteItemBlock(item: item, subtle: subtleColor),
+            ),
+          ),
+        const SizedBox(height: 18),
+        Text(
+          'Diagnostics (preset)',
+          style: TextStyle(
+            color: labelColor,
+            fontSize: 15,
+            fontWeight: FontWeight.w700,
+          ),
+        ),
+        const SizedBox(height: 8),
+        if (diag.isEmpty)
+          Text(
+            'Aucun diagnostic pour ce preset.',
+            key: const Key('environment-studio-preset-diagnostics-empty'),
+            style: TextStyle(
+              color: subtleColor,
+              fontSize: 13,
+              fontWeight: FontWeight.w600,
+            ),
+          )
+        else ...[
+          Text(
+            '$err erreur${err == 1 ? '' : 's'} · '
+            '$warn avertissement${warn == 1 ? '' : 's'}',
+            key: const Key('environment-studio-preset-diagnostics-summary'),
+            style: TextStyle(
+              color: subtleColor,
+              fontSize: 13,
+              fontWeight: FontWeight.w600,
+            ),
+          ),
+          const SizedBox(height: 8),
+          ...diag.asMap().entries.map(
+                (e) => Padding(
+                  padding: const EdgeInsets.only(bottom: 6),
+                  child: Text(
+                    e.value.message,
+                    key: Key('environment-studio-preset-diag-line-${e.key}'),
                     style: TextStyle(
-                      color: subtle,
-                      fontSize: 12,
+                      color: e.value.severity ==
+                              EnvironmentAuthoringDiagnosticSeverity.error
+                          ? CupertinoColors.systemRed.resolveFrom(context)
+                          : CupertinoColors.systemOrange.resolveFrom(context),
+                      fontSize: 12.5,
                       height: 1.35,
                     ),
                   ),
-                  const SizedBox(height: 32),
-                  Text(
-                    'Bientôt :',
-                    key: const Key('environment-studio-soon-title'),
-                    style: TextStyle(
-                      color: label,
-                      fontSize: 17,
-                      fontWeight: FontWeight.w700,
-                    ),
-                  ),
-                  const SizedBox(height: 10),
-                  Text(
-                    '• création de presets ;\n'
-                    '• édition de palettes ;\n'
-                    '• utilisation dans les Environment Layers ;\n'
-                    '• génération organique sur les maps.',
-                    key: const Key('environment-studio-soon-bullets'),
-                    style: TextStyle(
-                      color: subtle,
-                      fontSize: 13,
-                      height: 1.45,
-                    ),
-                  ),
-                ],
+                ),
+              ),
+        ],
+      ],
+    );
+  }
+
+  static String _formatDouble(double v) => v.toStringAsFixed(2);
+
+  Widget _detailLine(String title, String value, Key valueKey) {
+    return Padding(
+      padding: const EdgeInsets.only(bottom: 6),
+      child: Row(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          SizedBox(
+            width: 150,
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
               ),
             ),
           ),
+        ],
+      ),
+    );
+  }
+}
+
+class _PaletteItemBlock extends StatelessWidget {
+  const _PaletteItemBlock({
+    required this.item,
+    required this.subtle,
+  });
+
+  final EnvironmentPaletteItem item;
+  final Color subtle;
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final tagStr =
+        item.tags.isEmpty ? '—' : (item.tags.toList()..sort()).join(', ');
+
+    return DecoratedBox(
+      decoration: BoxDecoration(
+        borderRadius: BorderRadius.circular(8),
+        border: Border.all(
+          color: CupertinoColors.separator.resolveFrom(context),
+        ),
+      ),
+      child: Padding(
+        padding: const EdgeInsets.all(10),
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.stretch,
+          children: [
+            Text(
+              item.elementId,
+              key: Key('environment-studio-palette-item-${item.elementId}'),
+              style: TextStyle(
+                color: label,
+                fontSize: 13,
+                fontWeight: FontWeight.w700,
+              ),
+            ),
+            const SizedBox(height: 4),
+            Text(
+              'Poids ${item.weight} · ${_collisionLabel(item.collisionMode)} · tags: $tagStr',
+              key:
+                  Key('environment-studio-palette-item-meta-${item.elementId}'),
+              style: TextStyle(
+                color: subtle,
+                fontSize: 12,
+                height: 1.35,
+              ),
+            ),
+          ],
         ),
       ),
     );
   }
+
+  static String _collisionLabel(EnvironmentCollisionMode m) {
+    return switch (m) {
+      EnvironmentCollisionMode.useElementDefault => 'Défaut élément',
+      EnvironmentCollisionMode.forceEnabled => 'Collision forcée',
+      EnvironmentCollisionMode.forceDisabled => 'Collision désactivée',
+    };
+  }
 }

```

### 15.3 Diff `git diff --no-index /dev/null` — `environment_studio_preset_browser_test.dart`

```diff
diff --git a/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart b/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart
new file mode 100644
index 00000000..101a6eec
--- /dev/null
+++ b/packages/map_editor/test/environment_studio/environment_studio_preset_browser_test.dart
@@ -0,0 +1,231 @@
+import 'package:flutter/cupertino.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:macos_ui/macos_ui.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';
+
+void main() {
+  group('EnvironmentStudioPanel — browser read-only', () {
+    testWidgets('détail : id, nom, template, catégorie, tri, params, palette',
+        (tester) async {
+      await _pump(
+        tester,
+        _manifest(
+          environmentPresets: [
+            EnvironmentPreset(
+              id: 'p1',
+              name: 'Forêt test',
+              templateId: 'forest_dense',
+              categoryId: 'bio',
+              palette: [
+                EnvironmentPaletteItem(
+                  elementId: 'oak',
+                  weight: 5,
+                  collisionMode: EnvironmentCollisionMode.forceEnabled,
+                  tags: {'tree', 'canopy'},
+                ),
+              ],
+              defaultParams: EnvironmentGenerationParams(
+                density: 0.25,
+                variation: 0.75,
+                edgeDensity: 0.1,
+                minSpacingCells: 2,
+              ),
+              sortOrder: 3,
+            ),
+          ],
+          elements: [_element(id: 'oak')],
+        ),
+      );
+
+      expect(find.byKey(const Key('environment-studio-detail-id')),
+          findsOneWidget);
+      expect(find.text('p1'), findsWidgets);
+      expect(find.text('Forêt test'), findsWidgets);
+      expect(find.text('forest_dense'), findsWidgets);
+      expect(find.text('bio'), findsWidgets);
+      expect(find.text('3'), findsWidgets);
+      expect(find.text('0.25'), findsOneWidget);
+      expect(find.text('0.75'), findsOneWidget);
+      expect(find.text('0.10'), findsOneWidget);
+      expect(find.text('2'), findsWidgets);
+      expect(find.byKey(const Key('environment-studio-palette-item-oak')),
+          findsOneWidget);
+      expect(
+        find.byKey(const Key('environment-studio-palette-item-meta-oak')),
+        findsOneWidget,
+      );
+      expect(
+        find.textContaining('Poids 5'),
+        findsOneWidget,
+      );
+      expect(
+        find.textContaining('Collision forcée'),
+        findsOneWidget,
+      );
+      expect(
+        find.textContaining('canopy'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('catégorie absente : affiche —', (tester) async {
+      await _pump(
+        tester,
+        _manifest(
+          environmentPresets: [
+            EnvironmentPreset(
+              id: 'solo',
+              name: 'Solo',
+              templateId: 'tpl',
+              palette: [
+                EnvironmentPaletteItem(elementId: 'e1', weight: 1),
+              ],
+              defaultParams: EnvironmentGenerationParams.standard(),
+              sortOrder: 0,
+            ),
+          ],
+          elements: [_element(id: 'e1')],
+        ),
+      );
+
+      expect(
+        (tester.widget<Text>(
+                find.byKey(const Key('environment-studio-detail-category'))))
+            .data,
+        '—',
+      );
+    });
+
+    testWidgets('diagnostics preset vides : message dédié', (tester) async {
+      await _pump(
+        tester,
+        _manifest(
+          environmentPresets: [
+            EnvironmentPreset(
+              id: 'ok',
+              name: 'OK',
+              templateId: 'tpl',
+              palette: [
+                EnvironmentPaletteItem(elementId: 'e1', weight: 1),
+              ],
+              defaultParams: EnvironmentGenerationParams.standard(),
+              sortOrder: 0,
+            ),
+          ],
+          elements: [_element(id: 'e1')],
+        ),
+      );
+
+      expect(
+        find.byKey(const Key('environment-studio-preset-diagnostics-empty')),
+        findsOneWidget,
+      );
+      expect(find.text('Aucun diagnostic pour ce preset.'), findsOneWidget);
+    });
+
+    testWidgets('diagnostic erreur élément palette manquant', (tester) async {
+      await _pump(
+        tester,
+        _manifest(
+          environmentPresets: [
+            EnvironmentPreset(
+              id: 'bad',
+              name: 'Bad',
+              templateId: 'tpl',
+              palette: [
+                EnvironmentPaletteItem(elementId: 'missing_tree', weight: 1),
+              ],
+              defaultParams: EnvironmentGenerationParams.standard(),
+              sortOrder: 0,
+            ),
+          ],
+          elements: const [],
+        ),
+      );
+
+      expect(
+        find.byKey(const Key('environment-studio-preset-diagnostics-empty')),
+        findsNothing,
+      );
+      expect(
+        find.byKey(const Key('environment-studio-preset-diagnostics-summary')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const Key('environment-studio-preset-diag-line-0')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const Key('environment-studio-preset-row-diag-bad')),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('read-only : pas de libellés Create / Edit / Delete / Generate',
+        (tester) async {
+      await _pump(
+        tester,
+        _manifest(
+          environmentPresets: [
+            EnvironmentPreset(
+              id: 'x',
+              name: 'X',
+              templateId: 'tpl',
+              palette: [
+                EnvironmentPaletteItem(elementId: 'e1', weight: 1),
+              ],
+              defaultParams: EnvironmentGenerationParams.standard(),
+              sortOrder: 0,
+            ),
+          ],
+          elements: [_element(id: 'e1')],
+        ),
+      );
+
+      expect(find.textContaining('Create'), findsNothing);
+      expect(find.textContaining('Edit'), findsNothing);
+      expect(find.textContaining('Delete'), findsNothing);
+      expect(find.textContaining('Generate'), findsNothing);
+    });
+  });
+}
+
+Future<void> _pump(WidgetTester tester, ProjectManifest manifest) async {
+  await tester.pumpWidget(
+    MacosApp(
+      home: CupertinoPageScaffold(
+        child: EnvironmentStudioPanel(manifest: manifest),
+      ),
+    ),
+  );
+  await tester.pumpAndSettle();
+}
+
+ProjectManifest _manifest({
+  required List<EnvironmentPreset> environmentPresets,
+  List<ProjectElementEntry> elements = const [],
+}) {
+  return ProjectManifest(
+    name: 'browser-test',
+    maps: const [],
+    tilesets: const [],
+    environmentPresets: environmentPresets,
+    elements: elements,
+    surfaceCatalog: ProjectSurfaceCatalog(),
+  );
+}
+
+ProjectElementEntry _element({required String id}) {
+  return ProjectElementEntry(
+    id: id,
+    name: 'El $id',
+    tilesetId: 'ts',
+    categoryId: 'cat',
+    frames: const [
+      TilesetVisualFrame(
+        source: TilesetSourceRect(x: 0, y: 0),
+      ),
+    ],
+  );
+}

```

## 16. Auto-review

- **Points solides** : sélection robuste (`didUpdateWidget`), diagnostics par `presetId`, tests couvrant erreur palette manquante, pas de `CupertinoButton`.
- **Points discutables** : densité UI sur petits écrans ; `find.text('2')` dans un test navigateur peut matcher plusieurs widgets (accepté car tests verts).
- **Corrections après auto-review** : `const` / `prefer_const_constructors` sur `accent` et `Icon` ; remplacement `CupertinoButton` par `GestureDetector` pour alignement tests read-only.
- **Risques restants** : diagnostics usage map toujours absents avec `maps: const []` ; pluralisation FR des compteurs preset vs global légèrement différente.
- **Regard critique sur le prompt** : sélection locale **suffit** pour V0 ; pas besoin de read-model séparé ; `maps: const []` **suffit** comme contrat ; browser un peu dense mais **acceptable** pour auteurs ; édition / sauvegarde / génération **bien évitées**.

## 17. Verdict

Statut du lot :

- [ ] Validé
- [x] **Validé avec réserve**
- [ ] Non livré

Résumé :

```text
Browser read-only livré avec tests ciblés verts et analyze OK. Réserve : flutter test map_editor entier reste rouge (+845 -34) pour dette hors lot.
```

Prochain lot recommandé :

```text
Environment-11 — Environment Preset Detail Polish / Diagnostics Drilldown V0
```
