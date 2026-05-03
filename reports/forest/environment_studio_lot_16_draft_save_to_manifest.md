# Environment Studio Lot 16 — Draft Save to Manifest V0

## 1. Résumé exécutif

Le brouillon Environment Studio peut être **enregistré dans le manifest projet en mémoire** : validation (`validateEnvironmentPresetDraft`), construction (`buildEnvironmentPresetFromDraft`), `upsertProjectEnvironmentPreset`, puis `EditorNotifier.applyInMemoryProjectManifest` avec **dirty** et **message de statut**. Retour automatique au **browser** avec le **nouveau preset sélectionné**. Aucune écriture disque, pas de `EnvironmentLayer`, pas de générateur. Tests dédiés + intégration `EditorCanvasHost`.

## 2. Périmètre du lot

- Branché : `EnvironmentPresetDraft` → validation → build → upsert → état éditeur.
- Hors lot : `map_core` / `map_runtime` / `map_gameplay` / `map_battle`, `build_runner`, persistance `project.json`, `EnvironmentLayer` / `EnvironmentArea`, édition preset existant.

## 3. Audit initial du flux manifest éditeur

Fichiers inspectés (spec lot + implémentation) : `environment_studio_workspace.dart`, `environment_studio_panel.dart`, `environment_preset_draft_form.dart`, `editor_notifier.dart`, `editor_state.freezed.dart` (sémantique `copyWith` sur `statusMessage`), `project_manifest_environment_preset_operations.dart` (`upsertProjectEnvironmentPreset`).

Constat : **`applyInMemoryProjectManifest` existait** sans `statusMessage` ni nettoyage d’`errorMessage`. Pattern Path Studio : workspace appelle le notifier après calcul du manifest côté panel. **Pas** de `replaceProjectManifestInMemory` séparé : extension minimale de la méthode existante.

## 4. Décisions d’architecture UI / state

- **`EnvironmentStudioPanel`** expose `onEnvironmentPresetSaved(nextManifest, savedPreset)?` ; le **formulaire** calcule `nextManifest` + preset (comme demandé côté panel testable) et appelle le callback ; le **panel** notifie le parent puis `setState` (browser, sélection, brouillon réinitialisé).
- Si `onEnvironmentPresetSaved == null`, le **formulaire** ne reçoit **pas** de closure interne : bouton désactivé + note (tests isolés sans Riverpod).
- **`knownTemplateIds`** du panel est propagé au formulaire et à la validation brouillon (alignement Lot 15 / diagnostics template).

## 5. Callback save manifest

`EnvironmentStudioWorkspace` branche :

```dart
ref.read(editorNotifierProvider.notifier).applyInMemoryProjectManifest(
  nextManifest,
  statusMessage: 'Preset d’environnement « ${preset.name} » ajouté au projet.',
);
```

## 6. Enregistrement brouillon valide

`_saveDraftToProject` : `_draftFromControllers()` → `validateEnvironmentPresetDraft` → si `!hasErrors` → `buildEnvironmentPresetFromDraft` → `upsertProjectEnvironmentPreset(widget.manifest, preset)` → callback.

## 7. Validation et blocage des brouillons invalides

- **Erreurs** : `onPressed` null, aide orange + texte imposé ; au clic, revalidation : si erreurs, **return** avant build/upsert/callback.
- **Warnings** (ex. `unknownTemplateId`) : `hasErrors` false → bouton actif.
- **`duplicateId`** : bloque ; pas d’upsert tant que le brouillon est invalide (le manifest modèle du test harness peut être synchronisé après succès uniquement).

## 8. Dirty state / feedback utilisateur

- `applyInMemoryProjectManifest` : `isProjectDirty: true`, `errorMessage: null`, `statusMessage` si fourni (sinon inchangé, comportement freezed).

## 9. Non-persistance disque garantie

Aucun appel à `FileProjectRepository`, `saveProject`, ou flux autosave dans ce chemin. Seul `applyInMemoryProjectManifest` côté notifier (hors `saveProjectManifest`).

## 10. Pourquoi aucun générateur / EnvironmentLayer dans ce lot

Conformité stricte au cahier : uniquement mutation `ProjectManifest.environmentPresets` en mémoire et UX Studio.

## 11. Fichiers modifiés

| Fichier | Rôle |
|---------|------|
| `packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart` | Callback → notifier |
| `packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart` | API callback + transition post-save |
| `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart` | Bouton FR + logique save |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` | `applyInMemoryProjectManifest` étendu |
| `packages/map_editor/test/shell_chrome_test_harness.dart` | `elements` sur `buildShellChromeProject` |
| `packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart` | **Nouveau** — tests Lot 16 |

**Fichier autorisé justifié** : `shell_chrome_test_harness.dart` — paramètre `elements` pour tests workspace réalistes sans dupliquer un second constructeur de projet shell.

## 12. Tests ajoutés ou modifiés

- **Nouveau** : `environment_preset_save_to_manifest_test.dart` (bouton désactivé, sans callback, flux valide avec `_ManifestSyncPanelHost`, duplicate id, élément inconnu, warning template, notifier, `EditorCanvasHost` + `surfaceSize: Size(960, 2200)`).

## 13. Commandes exécutées

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
dart format lib/src/features/environment_studio/environment_studio_workspace.dart \
  lib/src/features/environment_studio/environment_studio_panel.dart \
  lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart \
  lib/src/features/editor/state/editor_notifier.dart \
  test/environment_studio/environment_preset_save_to_manifest_test.dart \
  test/shell_chrome_test_harness.dart

flutter analyze lib/src/features/environment_studio/environment_studio_workspace.dart \
  lib/src/features/environment_studio/environment_studio_panel.dart \
  lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart \
  lib/src/features/editor/state/editor_notifier.dart \
  test/environment_studio/environment_preset_save_to_manifest_test.dart \
  test/shell_chrome_test_harness.dart

flutter test test/environment_studio/environment_preset_save_to_manifest_test.dart --reporter expanded

flutter test test/environment_studio --reporter expanded

flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart --reporter expanded

flutter test
```

## 14. Résultats des commandes

### `dart format`

Exit code **0** (fichiers listés formatés).

### `flutter analyze` (liste ciblée puis fichier test seul)

Après corrections `const` : **`No issues found!`** sur `environment_preset_save_to_manifest_test.dart`.

### `flutter test test/environment_studio/environment_preset_save_to_manifest_test.dart --reporter expanded`

**10 tests, tous passés.** Sortie complète :

```
00:00 +0: loading .../environment_preset_save_to_manifest_test.dart
00:00 +0: EnvironmentPresetDraftForm — Enregistrer dans le projet brouillon initial invalide : bouton désactivé + aide visible
00:00 +1: EnvironmentPresetDraftForm — Enregistrer dans le projet sans callback : bouton désactivé + note indisponible
00:00 +2: EnvironmentPresetDraftForm — Enregistrer dans le projet brouillon valide : callback reçoit manifest + preset, browser + sélection
00:01 +3: EnvironmentPresetDraftForm — Enregistrer dans le projet duplicate id : bouton désactivé, callback non invoqué
00:01 +4: EnvironmentPresetDraftForm — Enregistrer dans le projet élément palette inconnu : callback non invoqué
00:01 +5: EnvironmentPresetDraftForm — Enregistrer dans le projet warning template inconnu ne bloque pas l’enregistrement
00:01 +6: EditorNotifier — applyInMemoryProjectManifest (Lot 16) statusMessage optionnel et errorMessage effacé
00:01 +7: EditorNotifier — applyInMemoryProjectManifest (Lot 16) sans statusMessage : conserve le message de statut précédent
00:01 +8: EditorNotifier — applyInMemoryProjectManifest (Lot 16) ne modifie pas activeMap
00:01 +9: Environment Studio workspace — persistance mémoire EditorCanvasHost : enregistrement met à jour le projet et dirty
00:01 +10: All tests passed!
```

### `flutter test test/environment_studio --reporter expanded`

**96 tests, tous passés.** Dernière ligne : `00:05 +96: All tests passed!`

### `flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart --reporter expanded`

**14 tests, tous passés.** Dernière ligne : `00:01 +14: All tests passed!`

### `flutter test` (suite complète `map_editor`)

**Échec** : compteur final **`00:56 +929 -34: Some tests failed.`** — **34 échecs** hors périmètre Lot 16 (dettes / tests existants ; pas liés aux fichiers Environment-16).

## 15. Git status initial et final

**Initial (extrait fourni au début de session Cursor)** : modifications non commit incluant notamment `packages/map_core/...` et `packages/map_editor/...` (terrain / environment — hors Lot 16).

**Final** (commande `git status --short --untracked-files=all` à la racine du dépôt) :

```
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
 M packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
 M packages/map_editor/test/shell_chrome_test_harness.dart
?? packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart
?? reports/forest/environment_studio_lot_16_draft_save_to_manifest.md
```

Les changements `packages/map_core` / `map_runtime` / etc. visibles chez l’utilisateur en parallèle ne font **pas** partie de ce lot et n’ont pas été modifiés par cette passe Lot 16.

## 16. Contenu complet des fichiers créés ou modifiés

### `packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../editor/state/editor_notifier.dart';
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
    return EnvironmentStudioPanel(
      manifest: manifest,
      onEnvironmentPresetSaved: (nextManifest, preset) {
        ref.read(editorNotifierProvider.notifier).applyInMemoryProjectManifest(
              nextManifest,
              statusMessage:
                  'Preset d’environnement « ${preset.name} » ajouté au projet.',
            );
      },
    );
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

### `packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'authoring/environment_preset_draft.dart';
import 'widgets/environment_preset_detail.dart';
import 'widgets/environment_preset_draft_form.dart';
import 'widgets/environment_preset_list.dart';

/// Modes locaux du panneau Environment Studio (Lot Environment-13).
enum EnvironmentStudioPanelMode {
  /// Liste + détail des presets existants (non mutateur).
  browser,

  /// Formulaire de brouillon ; persistance manifest via callback parent (mémoire).
  createDraft,
}

/// Browser read-only des presets Environment (Lot Environment-10, polish 11).
///
/// Sélection locale uniquement ([StatefulWidget]) : aucune mutation du
/// [ProjectManifest], aucun provider, aucune persistance.
///
/// [knownTemplateIds] non vide active les diagnostics `unknownTemplateId` pour
/// les [EnvironmentPreset.templateId] absents du set (défaut `{}` = désactivé).
///
/// Le mode [EnvironmentStudioPanelMode.createDraft] permet un brouillon local
/// ([EnvironmentPresetDraft]) ; l’enregistrement manifest mémoire passe par
/// [onEnvironmentPresetSaved] (Lot Environment-16, sans disque).
class EnvironmentStudioPanel extends StatefulWidget {
  const EnvironmentStudioPanel({
    super.key,
    required this.manifest,
    this.knownTemplateIds = const <String>{},
    this.onEnvironmentPresetSaved,
  });

  final ProjectManifest manifest;

  /// Quand non vide, restreint les templates reconnus (diagnostics auteur).
  final Set<String> knownTemplateIds;

  /// Après validation sans erreur : manifest mis à jour + preset créé ;
  /// le parent (ex. workspace) applique l’état éditeur ; pas d’I/O disque ici.
  final void Function(
          ProjectManifest nextManifest, EnvironmentPreset savedPreset)?
      onEnvironmentPresetSaved;

  @override
  State<EnvironmentStudioPanel> createState() => _EnvironmentStudioPanelState();
}

class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
  String? _selectedPresetId;
  EnvironmentStudioPanelMode _panelMode = EnvironmentStudioPanelMode.browser;
  EnvironmentPresetDraft _draft = EnvironmentPresetDraft.empty();
  int _draftFormEpoch = 0;

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

  void _openDraftForm() {
    setState(() {
      _panelMode = EnvironmentStudioPanelMode.createDraft;
      _draft = EnvironmentPresetDraft.empty();
      _draftFormEpoch++;
    });
  }

  void _closeDraftForm() {
    setState(() {
      _panelMode = EnvironmentStudioPanelMode.browser;
    });
  }

  void _resetDraft() {
    setState(() {
      _draft = EnvironmentPresetDraft.empty();
      _draftFormEpoch++;
    });
  }

  void _onEnvironmentPresetSavedInMemory(
    ProjectManifest nextManifest,
    EnvironmentPreset savedPreset,
  ) {
    widget.onEnvironmentPresetSaved?.call(nextManifest, savedPreset);
    setState(() {
      _panelMode = EnvironmentStudioPanelMode.browser;
      _selectedPresetId = savedPreset.id;
      _draft = EnvironmentPresetDraft.empty();
      _draftFormEpoch++;
    });
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

    final draftValidation = _panelMode == EnvironmentStudioPanelMode.createDraft
        ? validateEnvironmentPresetDraft(
            _draft,
            manifest: widget.manifest,
            knownTemplateIds: widget.knownTemplateIds,
          )
        : null;

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
                  const SizedBox(height: 12),
                  if (_panelMode == EnvironmentStudioPanelMode.browser)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CupertinoButton(
                        key: const Key('environment-studio-open-draft'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        onPressed: _openDraftForm,
                        child: const Text('Préparer un preset'),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (_panelMode == EnvironmentStudioPanelMode.browser)
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
                      )
                  else
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: EditorChrome.chipFill(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                CupertinoColors.separator.resolveFrom(context),
                          ),
                        ),
                        child: EnvironmentPresetDraftForm(
                          key: ValueKey<int>(_draftFormEpoch),
                          manifest: widget.manifest,
                          knownTemplateIds: widget.knownTemplateIds,
                          draft: _draft,
                          validation: draftValidation!,
                          projectElements: widget.manifest.elements,
                          onChanged: (d) => setState(() => _draft = d),
                          onCancel: _closeDraftForm,
                          onReset: _resetDraft,
                          onEnvironmentPresetSaved:
                              widget.onEnvironmentPresetSaved == null
                                  ? null
                                  : _onEnvironmentPresetSavedInMemory,
                        ),
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
    final isDraft = _panelMode == EnvironmentStudioPanelMode.createDraft;
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
          child: Text(
            isDraft
                ? 'Brouillon : vous pouvez enregistrer le preset dans le projet '
                    '(mémoire de l’éditeur uniquement, pas de fichier project.json). '
                    'La sauvegarde disque et la génération sur carte restent à venir.'
                : 'Lecture seule sur les presets existants — édition d’un preset '
                    'existant et génération sur carte arrivent dans les prochains lots.',
            key: const Key('environment-studio-read-only-banner'),
            style: const TextStyle(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Aucun preset d’environnement pour le moment.\n'
            'Utilisez « Préparer un preset », puis « Enregistrer dans le projet » '
            '(mémoire de session, sans écriture disque automatique).',
            key: const Key('environment-studio-empty-presets'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subtle,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
          '• sauvegarde disque du manifest projet ;\n'
          '• édition des presets existants ;\n'
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

### `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/shared/cupertino_editor_widgets.dart';
import '../authoring/environment_preset_draft.dart';
import 'environment_generation_params_draft_editor.dart';
import 'environment_palette_item_draft_editor.dart';
import 'environment_preset_draft_validation_view.dart';

/// Formulaire local de brouillon ; enregistrement manifest mémoire via
/// [onEnvironmentPresetSaved] (Lot Environment-16, sans disque).
class EnvironmentPresetDraftForm extends StatefulWidget {
  const EnvironmentPresetDraftForm({
    super.key,
    required this.manifest,
    this.knownTemplateIds = const <String>{},
    required this.draft,
    required this.validation,
    required this.projectElements,
    required this.onChanged,
    required this.onCancel,
    required this.onReset,
    this.onEnvironmentPresetSaved,
  });

  /// Manifest courant (validation + upsert avant callback).
  final ProjectManifest manifest;

  /// Aligné sur [EnvironmentStudioPanel.knownTemplateIds].
  final Set<String> knownTemplateIds;

  /// Éléments du projet (`manifest.elements`) pour le picker de palette.
  final List<ProjectElementEntry> projectElements;

  final EnvironmentPresetDraft draft;
  final EnvironmentPresetDraftValidationReport validation;
  final ValueChanged<EnvironmentPresetDraft> onChanged;
  final VoidCallback onCancel;
  final VoidCallback onReset;

  /// `null` : enregistrement indisponible (bouton désactivé + note).
  final void Function(
          ProjectManifest nextManifest, EnvironmentPreset savedPreset)?
      onEnvironmentPresetSaved;

  @override
  State<EnvironmentPresetDraftForm> createState() =>
      _EnvironmentPresetDraftFormState();
}

class _EnvironmentPresetDraftFormState
    extends State<EnvironmentPresetDraftForm> {
  late final TextEditingController _idCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _templateCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _sortCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _idCtrl = TextEditingController(text: d.id);
    _nameCtrl = TextEditingController(text: d.name);
    _templateCtrl = TextEditingController(text: d.templateId);
    _categoryCtrl = TextEditingController(text: d.categoryId ?? '');
    _sortCtrl = TextEditingController(text: d.sortOrder.toString());
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _templateCtrl.dispose();
    _categoryCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  EnvironmentPresetDraft _draftFromControllers() {
    final so = int.tryParse(_sortCtrl.text.trim());
    return EnvironmentPresetDraft(
      id: _idCtrl.text,
      name: _nameCtrl.text,
      templateId: _templateCtrl.text,
      palette: widget.draft.palette,
      defaultParams: widget.draft.defaultParams,
      categoryId: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text,
      sortOrder: so ?? widget.draft.sortOrder,
    );
  }

  void _emit({
    List<EnvironmentPaletteItemDraft>? palette,
    EnvironmentGenerationParamsDraft? defaultParams,
  }) {
    final so = int.tryParse(_sortCtrl.text.trim());
    widget.onChanged(
      EnvironmentPresetDraft(
        id: _idCtrl.text,
        name: _nameCtrl.text,
        templateId: _templateCtrl.text,
        palette: palette ?? widget.draft.palette,
        defaultParams: defaultParams ?? widget.draft.defaultParams,
        categoryId:
            _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text,
        sortOrder: so ?? widget.draft.sortOrder,
      ),
    );
  }

  void _addPaletteItem() {
    final next = [
      ...widget.draft.palette,
      EnvironmentPaletteItemDraft(elementId: '', weight: 1),
    ];
    _emit(palette: next);
  }

  void _replacePaletteItem(int index, EnvironmentPaletteItemDraft item) {
    final next = List<EnvironmentPaletteItemDraft>.from(widget.draft.palette);
    next[index] = item;
    _emit(palette: next);
  }

  void _removePaletteItem(int index) {
    final next = List<EnvironmentPaletteItemDraft>.from(widget.draft.palette)
      ..removeAt(index);
    _emit(palette: next);
  }

  void _saveDraftToProject() {
    final save = widget.onEnvironmentPresetSaved;
    if (save == null) {
      return;
    }
    final draft = _draftFromControllers();
    final validation = validateEnvironmentPresetDraft(
      draft,
      manifest: widget.manifest,
      knownTemplateIds: widget.knownTemplateIds,
    );
    if (validation.hasErrors) {
      return;
    }
    final preset = buildEnvironmentPresetFromDraft(draft);
    final nextManifest = upsertProjectEnvironmentPreset(
      widget.manifest,
      preset,
    );
    save(nextManifest, preset);
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final canSaveToProject =
        widget.onEnvironmentPresetSaved != null && !widget.validation.hasErrors;

    return SingleChildScrollView(
      key: const Key('environment-studio-draft-form-scroll'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nouveau preset d’environnement',
            key: const Key('environment-studio-draft-form-title'),
            style: TextStyle(
              color: label,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: EditorChrome.accentWarm.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: EditorChrome.accentWarm.withValues(alpha: 0.45),
              ),
            ),
            child: const Text(
              'Brouillon local non sauvegardé',
              key: Key('environment-studio-draft-local-badge'),
              style: TextStyle(
                color: EditorChrome.accentWarm,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Remplissez le brouillon puis « Enregistrer dans le projet » pour '
            'l’ajouter au manifest en mémoire (marque le projet modifié ; '
            'aucune écriture disque automatique).',
            key: const Key('environment-studio-draft-form-intro'),
            style: TextStyle(
              color: subtle,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _fieldLabel(context, 'Id'),
          const SizedBox(height: 4),
          CupertinoTextField(
            key: const Key('environment-studio-draft-field-id'),
            controller: _idCtrl,
            placeholder: 'Identifiant unique',
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 14),
          _fieldLabel(context, 'Nom'),
          const SizedBox(height: 4),
          CupertinoTextField(
            key: const Key('environment-studio-draft-field-name'),
            controller: _nameCtrl,
            placeholder: 'Nom affiché',
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 14),
          _fieldLabel(context, 'Template'),
          const SizedBox(height: 4),
          CupertinoTextField(
            key: const Key('environment-studio-draft-field-template'),
            controller: _templateCtrl,
            placeholder: 'Ex. forest_dense',
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 14),
          _fieldLabel(context, 'Catégorie (optionnel)'),
          const SizedBox(height: 4),
          CupertinoTextField(
            key: const Key('environment-studio-draft-field-category'),
            controller: _categoryCtrl,
            placeholder: 'Laisser vide si sans catégorie',
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 14),
          _fieldLabel(context, 'Ordre d’affichage'),
          const SizedBox(height: 4),
          CupertinoTextField(
            key: const Key('environment-studio-draft-field-sort'),
            controller: _sortCtrl,
            placeholder: '0',
            keyboardType: TextInputType.number,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 22),
          EnvironmentGenerationParamsDraftEditor(
            key: const Key('environment-studio-draft-params-editor'),
            params: widget.draft.defaultParams,
            onChanged: (p) => _emit(defaultParams: p),
          ),
          const SizedBox(height: 22),
          Text(
            'Palette du brouillon',
            key: const Key('environment-studio-draft-palette-section-title'),
            style: TextStyle(
              color: label,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les éléments doivent exister dans le projet ; ils sont copiés dans le '
            'preset lors de l’enregistrement.',
            key: const Key('environment-studio-draft-palette-local-note'),
            style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: CupertinoButton(
              key: const Key('environment-studio-draft-palette-add-item'),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              onPressed: _addPaletteItem,
              child: const Text('Ajouter un item de palette'),
            ),
          ),
          const SizedBox(height: 10),
          if (widget.draft.palette.isEmpty)
            Text(
              'Aucun item pour l’instant.',
              key: const Key('environment-studio-draft-palette-no-items'),
              style: TextStyle(color: subtle, fontSize: 13),
            )
          else ...[
            for (var i = 0; i < widget.draft.palette.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i < widget.draft.palette.length - 1 ? 12 : 0,
                ),
                child: EnvironmentPaletteItemDraftEditor(
                  key: ValueKey('palette-draft-slot-$i'),
                  index: i,
                  item: widget.draft.palette[i],
                  projectElements: widget.projectElements,
                  onChanged: (it) => _replacePaletteItem(i, it),
                  onRemove: () => _removePaletteItem(i),
                ),
              ),
          ],
          const SizedBox(height: 22),
          Text(
            'Validation du brouillon',
            style: TextStyle(
              color: label,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          EnvironmentPresetDraftValidationView(
            report: widget.validation,
            labelColor: label,
            subtleColor: subtle,
          ),
          if (widget.validation.hasErrors) ...[
            const SizedBox(height: 10),
            Text(
              'Corrigez les erreurs du brouillon pour l’enregistrer dans le projet.',
              key: const Key('environment-studio-draft-save-disabled-hint'),
              style: TextStyle(
                color: CupertinoColors.systemOrange.resolveFrom(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CupertinoButton(
                key: const Key('environment-studio-draft-cancel'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                onPressed: widget.onCancel,
                child: const Text('Retour au browser'),
              ),
              CupertinoButton(
                key: const Key('environment-studio-draft-reset'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                onPressed: widget.onReset,
                child: const Text('Réinitialiser brouillon'),
              ),
              CupertinoButton(
                key: const Key('environment-studio-draft-save-project'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                onPressed: canSaveToProject ? _saveDraftToProject : null,
                child: const Text('Enregistrer dans le projet'),
              ),
            ],
          ),
          if (widget.onEnvironmentPresetSaved == null) ...[
            const SizedBox(height: 8),
            Text(
              'Enregistrement indisponible dans ce contexte.',
              key: const Key('environment-studio-draft-save-unavailable-note'),
              style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fieldLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        color: EditorChrome.subtleLabel(context),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
```

### `packages/map_editor/test/shell_chrome_test_harness.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/editor_canvas_host.dart';
import 'package:map_editor/src/ui/editor_shell_page.dart';
import 'package:map_editor/src/ui/shared/status_bar.dart';
import 'package:map_editor/src/ui/shared/top_toolbar.dart';

const _appkitUiElementColorsChannel = MethodChannel('appkit_ui_element_colors');

void _installMacosAccentColorMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_appkitUiElementColorsChannel, (call) async {
    switch (call.method) {
      case 'getColorComponents':
        return <String, double>{'hueComponent': 0.58};
      case 'getColor':
        return 0xFF0A84FF;
    }
    return null;
  });
  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_appkitUiElementColorsChannel, null);
  });
}

ProjectManifest buildShellChromeProject({
  String name = 'Demo Project',
  List<ProjectMapEntry> maps = const <ProjectMapEntry>[],
  List<ProjectTilesetEntry> tilesets = const <ProjectTilesetEntry>[],
  List<ProjectPathPreset> pathPresets = const <ProjectPathPreset>[],
  List<ProjectPathPatternPreset> pathPatternPresets =
      const <ProjectPathPatternPreset>[],
  List<EnvironmentPreset> environmentPresets = const <EnvironmentPreset>[],
  List<ProjectElementEntry> elements = const <ProjectElementEntry>[],
}) {
  return ProjectManifest(
    name: name,
    maps: maps,
    tilesets: tilesets,
    pathPresets: pathPresets,
    pathPatternPresets: pathPatternPresets,
    environmentPresets: environmentPresets,
    elements: elements,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

MapData buildShellChromeMap({
  String id = 'route_1',
  String name = 'Route 1',
  int width = 20,
  int height = 15,
  List<MapLayer> layers = const <MapLayer>[],
}) {
  return MapData(
    id: id,
    name: name,
    size: GridSize(width: width, height: height),
    layers: layers,
  );
}

Future<ProviderContainer> pumpEditorShellPage(
  WidgetTester tester, {
  required EditorState initialState,
  Size surfaceSize = const Size(1600, 1000),
  List<Override> overrides = const <Override>[],
}) async {
  _installMacosAccentColorMock();
  final container = ProviderContainer(overrides: overrides);
  final editorStateSubscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() async {
    editorStateSubscription.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump();
    container.dispose();
  });

  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  // The shell auto-restore schedules a post-frame call into the notifier.
  // Tests seed a concrete editor state up front so the restore path exits
  // immediately and the shell stays focused on UI contracts only.
  container.read(editorNotifierProvider.notifier).state = initialState;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MacosApp(
        home: EditorShellPage(),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle(const Duration(milliseconds: 1));
  return container;
}

Future<ProviderContainer> pumpEditorCanvasHostHarness(
  WidgetTester tester, {
  required EditorState initialState,
  Size surfaceSize = const Size(960, 640),
}) async {
  _installMacosAccentColorMock();
  final container = ProviderContainer();
  final editorStateSubscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() async {
    editorStateSubscription.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump();
    container.dispose();
  });

  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  container.read(editorNotifierProvider.notifier).state = initialState;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MacosApp(
        home: CupertinoPageScaffold(
          child: EditorCanvasHost(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle(const Duration(milliseconds: 1));
  return container;
}

Future<ProviderContainer> pumpTopToolbarHarness(
  WidgetTester tester, {
  required EditorState initialState,
  Size surfaceSize = const Size(1280, 220),
}) async {
  _installMacosAccentColorMock();
  final container = ProviderContainer();
  final editorStateSubscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() async {
    editorStateSubscription.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump();
    container.dispose();
  });

  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  container.read(editorNotifierProvider.notifier).state = initialState;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MacosApp(
        home: _TopToolbarHarness(),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle(const Duration(milliseconds: 1));
  return container;
}

Future<ProviderContainer> pumpStatusBarHarness(
  WidgetTester tester, {
  required EditorState initialState,
  Size surfaceSize = const Size(900, 180),
}) async {
  _installMacosAccentColorMock();
  final container = ProviderContainer();
  final editorStateSubscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() async {
    editorStateSubscription.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump();
    container.dispose();
  });

  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  container.read(editorNotifierProvider.notifier).state = initialState;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MacosApp(
        home: _StatusBarHarness(),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle(const Duration(milliseconds: 1));
  return container;
}

class _TopToolbarHarness extends ConsumerWidget {
  const _TopToolbarHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const CupertinoPageScaffold(
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 1200,
          child: TopToolbar(
            key: Key('top-toolbar-under-test'),
          ),
        ),
      ),
    );
  }
}

class _StatusBarHarness extends StatelessWidget {
  const _StatusBarHarness();

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: 860,
          child: StatusBar(),
        ),
      ),
    );
  }
}
```

### `packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  group('EnvironmentPresetDraftForm — Enregistrer dans le projet', () {
    testWidgets(
      'brouillon initial invalide : bouton désactivé + aide visible',
      (tester) async {
        await _pumpPanel(
          tester,
          manifest: _manifest(elements: [_element(id: 'e1')]),
          onSaved: (_, __) {},
        );
        await tester
            .tap(find.byKey(const Key('environment-studio-open-draft')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('environment-studio-draft-save-project')),
          findsOneWidget,
        );
        final saveBtn = tester.widget<CupertinoButton>(
          find.byKey(const Key('environment-studio-draft-save-project')),
        );
        expect(saveBtn.onPressed, isNull);
        expect(
          find.byKey(const Key('environment-studio-draft-save-disabled-hint')),
          findsOneWidget,
        );
        expect(
          find.text(
            'Corrigez les erreurs du brouillon pour l’enregistrer dans le projet.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'sans callback : bouton désactivé + note indisponible',
      (tester) async {
        await _pumpPanel(
          tester,
          manifest: _manifest(elements: [_element(id: 'e1')]),
        );
        await tester
            .tap(find.byKey(const Key('environment-studio-open-draft')));
        await tester.pumpAndSettle();

        final saveBtn = tester.widget<CupertinoButton>(
          find.byKey(const Key('environment-studio-draft-save-project')),
        );
        expect(saveBtn.onPressed, isNull);
        expect(
          find.byKey(
              const Key('environment-studio-draft-save-unavailable-note')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'brouillon valide : callback reçoit manifest + preset, browser + sélection',
      (tester) async {
        ProjectManifest? receivedManifest;
        EnvironmentPreset? receivedPreset;

        final initial = _manifest(elements: [_element(id: 'e1')]);
        await _pumpPanel(
          tester,
          manifest: initial,
          onSaved: (m, p) {
            receivedManifest = m;
            receivedPreset = p;
          },
        );
        await tester
            .tap(find.byKey(const Key('environment-studio-open-draft')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('environment-studio-draft-field-id')),
          'meadow_new',
        );
        await tester.enterText(
          find.byKey(const Key('environment-studio-draft-field-name')),
          'Prairie test',
        );
        await tester.enterText(
          find.byKey(const Key('environment-studio-draft-field-template')),
          'prairie_tpl',
        );
        await tester.tap(
          find.byKey(const Key('environment-studio-draft-palette-add-item')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('environment-studio-palette-draft-element-0')),
          'e1',
        );
        await tester.pumpAndSettle();

        final saveBtn = tester.widget<CupertinoButton>(
          find.byKey(const Key('environment-studio-draft-save-project')),
        );
        expect(saveBtn.onPressed, isNotNull);

        await tester.tap(
          find.byKey(const Key('environment-studio-draft-save-project')),
        );
        await tester.pumpAndSettle();

        expect(receivedManifest, isNotNull);
        expect(receivedPreset, isNotNull);
        expect(receivedPreset!.id, 'meadow_new');
        expect(receivedPreset!.name, 'Prairie test');
        expect(receivedPreset!.templateId, 'prairie_tpl');
        expect(receivedPreset!.palette.single.elementId, 'e1');
        expect(
          receivedManifest!.environmentPresets.map((e) => e.id).toList(),
          contains('meadow_new'),
        );

        expect(find.byKey(const Key('environment-studio-preset-list')),
            findsOneWidget);
        expect(find.text('Prairie test'), findsWidgets);
      },
    );

    testWidgets('duplicate id : bouton désactivé, callback non invoqué',
        (tester) async {
      var calls = 0;
      await _pumpPanel(
        tester,
        manifest: _manifest(
          environmentPresets: [_preset(id: 'forest')],
          elements: [_element(id: 'e1')],
        ),
        onSaved: (_, __) => calls++,
      );
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-id')),
        'forest',
      );
      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-name')),
        'Doublon',
      );
      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-template')),
        't',
      );
      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('environment-studio-palette-draft-element-0')),
        'e1',
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Id déjà utilisé'), findsOneWidget);
      final saveBtn = tester.widget<CupertinoButton>(
        find.byKey(const Key('environment-studio-draft-save-project')),
      );
      expect(saveBtn.onPressed, isNull);
      await tester.tap(
        find.byKey(const Key('environment-studio-draft-save-project')),
      );
      await tester.pumpAndSettle();
      expect(calls, 0);
    });

    testWidgets('élément palette inconnu : callback non invoqué',
        (tester) async {
      var calls = 0;
      await _pumpPanel(
        tester,
        manifest: _manifest(elements: [_element(id: 'e1')]),
        onSaved: (_, __) => calls++,
      );
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-id')),
        'x',
      );
      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-name')),
        'Nom',
      );
      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-template')),
        't',
      );
      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('environment-studio-palette-draft-element-0')),
        'introuvable',
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Élément introuvable'), findsOneWidget);
      expect(
        tester
            .widget<CupertinoButton>(
              find.byKey(const Key('environment-studio-draft-save-project')),
            )
            .onPressed,
        isNull,
      );
      expect(calls, 0);
    });

    testWidgets('warning template inconnu ne bloque pas l’enregistrement',
        (tester) async {
      var calls = 0;
      await _pumpPanel(
        tester,
        manifest: _manifest(elements: [_element(id: 'e1')]),
        knownTemplateIds: {'only_this'},
        onSaved: (_, __) => calls++,
      );
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-id')),
        'warn_tpl',
      );
      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-name')),
        'W',
      );
      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-template')),
        'not_in_set',
      );
      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('environment-studio-palette-draft-element-0')),
        'e1',
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Template inconnu'), findsOneWidget);
      expect(
        tester
            .widget<CupertinoButton>(
              find.byKey(const Key('environment-studio-draft-save-project')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(
        find.byKey(const Key('environment-studio-draft-save-project')),
      );
      await tester.pumpAndSettle();
      expect(calls, 1);
    });
  });

  group('EditorNotifier — applyInMemoryProjectManifest (Lot 16)', () {
    test('statusMessage optionnel et errorMessage effacé', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = notifier.state.copyWith(
        project: _manifest(elements: const []),
        errorMessage: 'erreur précédente',
        statusMessage: 'ancien',
      );

      notifier.applyInMemoryProjectManifest(
        _manifest(name: 'Après', elements: const []),
        statusMessage: 'Preset d’environnement « X » ajouté au projet.',
      );

      expect(notifier.state.errorMessage, isNull);
      expect(
        notifier.state.statusMessage,
        'Preset d’environnement « X » ajouté au projet.',
      );
      expect(notifier.state.isProjectDirty, isTrue);
    });

    test('sans statusMessage : conserve le message de statut précédent', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = notifier.state.copyWith(
        project: _manifest(elements: const []),
        statusMessage: 'conservé',
      );
      notifier.applyInMemoryProjectManifest(
        _manifest(name: 'N', elements: const []),
      );
      expect(notifier.state.statusMessage, 'conservé');
    });

    test('ne modifie pas activeMap', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      const map = MapData(
        id: 'm1',
        name: 'M',
        size: GridSize(width: 4, height: 4),
        layers: <MapLayer>[],
      );
      notifier.state = notifier.state.copyWith(
        project: _manifest(elements: const []),
        activeMap: map,
        activeMapPath: 'maps/m1.json',
      );

      notifier.applyInMemoryProjectManifest(
        _manifest(name: 'Touch', elements: const []),
        statusMessage: 'ok',
      );

      expect(notifier.state.activeMap!.id, 'm1');
      expect(notifier.state.activeMapPath, 'maps/m1.json');
    });
  });

  group('Environment Studio workspace — persistance mémoire', () {
    testWidgets(
      'EditorCanvasHost : enregistrement met à jour le projet et dirty',
      (tester) async {
        final container = await pumpEditorCanvasHostHarness(
          tester,
          surfaceSize: const Size(960, 2200),
          initialState: EditorState(
            projectRootPath: '/tmp/lot16_env',
            project: buildShellChromeProject(
              elements: const [
                ProjectElementEntry(
                  id: 'tree_a',
                  name: 'Arbre',
                  tilesetId: 'ts',
                  categoryId: 'c',
                  frames: [
                    TilesetVisualFrame(
                      source: TilesetSourceRect(x: 0, y: 0),
                    ),
                  ],
                ),
              ],
            ),
            workspaceMode: EditorWorkspaceMode.environmentStudio,
          ),
        );

        await tester
            .tap(find.byKey(const Key('environment-studio-open-draft')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('environment-studio-draft-field-id')),
          'lot16_ws',
        );
        await tester.enterText(
          find.byKey(const Key('environment-studio-draft-field-name')),
          'Depuis workspace',
        );
        await tester.enterText(
          find.byKey(const Key('environment-studio-draft-field-template')),
          'tpl_ws',
        );
        await tester.tap(
          find.byKey(const Key('environment-studio-draft-palette-add-item')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('environment-studio-palette-draft-element-0')),
          'tree_a',
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('environment-studio-draft-save-project')),
        );
        await tester.pumpAndSettle();

        final snap = container.read(editorNotifierProvider);
        expect(snap.isProjectDirty, isTrue);
        expect(
          snap.project!.environmentPresets.map((e) => e.id),
          contains('lot16_ws'),
        );
        expect(
          snap.statusMessage,
          'Preset d’environnement « Depuis workspace » ajouté au projet.',
        );
        expect(find.byKey(const Key('environment-studio-preset-list')),
            findsOneWidget);
      },
    );
  });
}

/// Rejoue le rafraîchissement Riverpod du manifest après enregistrement mémoire.
class _ManifestSyncPanelHost extends StatefulWidget {
  const _ManifestSyncPanelHost({
    required this.initialManifest,
    this.knownTemplateIds = const {},
    this.onSaved,
  });

  final ProjectManifest initialManifest;
  final Set<String> knownTemplateIds;
  final void Function(ProjectManifest, EnvironmentPreset)? onSaved;

  @override
  State<_ManifestSyncPanelHost> createState() => _ManifestSyncPanelHostState();
}

class _ManifestSyncPanelHostState extends State<_ManifestSyncPanelHost> {
  late ProjectManifest _manifest;

  @override
  void initState() {
    super.initState();
    _manifest = widget.initialManifest;
  }

  @override
  void didUpdateWidget(covariant _ManifestSyncPanelHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.initialManifest, widget.initialManifest)) {
      _manifest = widget.initialManifest;
    }
  }

  @override
  Widget build(BuildContext context) {
    return EnvironmentStudioPanel(
      manifest: _manifest,
      knownTemplateIds: widget.knownTemplateIds,
      onEnvironmentPresetSaved: widget.onSaved == null
          ? null
          : (next, preset) {
              widget.onSaved!(next, preset);
              setState(() => _manifest = next);
            },
    );
  }
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required ProjectManifest manifest,
  Set<String> knownTemplateIds = const {},
  void Function(ProjectManifest, EnvironmentPreset)? onSaved,
}) async {
  tester.view.physicalSize = const Size(900, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MacosApp(
      home: CupertinoPageScaffold(
        child: _ManifestSyncPanelHost(
          initialManifest: manifest,
          knownTemplateIds: knownTemplateIds,
          onSaved: onSaved,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProjectManifest _manifest({
  List<EnvironmentPreset> environmentPresets = const [],
  List<ProjectElementEntry> elements = const [],
  String name = 't-save',
}) {
  return ProjectManifest(
    name: name,
    maps: const [],
    tilesets: const [],
    environmentPresets: environmentPresets,
    elements: elements,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

EnvironmentPreset _preset({required String id}) {
  return EnvironmentPreset(
    id: id,
    name: 'P $id',
    templateId: 'tpl',
    palette: [
      EnvironmentPaletteItem(elementId: 'e1', weight: 1),
    ],
    defaultParams: EnvironmentGenerationParams.standard(),
    sortOrder: 0,
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

### `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`

Fichier monolithique (>6k lignes) : seules les lignes **412–434** (méthode `applyInMemoryProjectManifest`) ont été modifiées pour le Lot 16. Le **diff complet** de cette méthode figure en section 17.

```dart
  /// Remplace le manifest projet en mémoire (aucune écriture disque).
  ///
  /// Lot Environment-16 : [statusMessage] optionnel pour feedback shell ;
  /// [errorMessage] est effacé sur succès pour éviter un message obsolète.
  void applyInMemoryProjectManifest(
    ProjectManifest manifest, {
    String? statusMessage,
  }) {
    state = statusMessage == null
        ? state.copyWith(
            project: manifest,
            isProjectDirty: true,
            errorMessage: null,
          )
        : state.copyWith(
            project: manifest,
            isProjectDirty: true,
            errorMessage: null,
            statusMessage: statusMessage,
          );
  }
```

## 17. Diff complet

### Fichiers suivis modifiés

```diff
diff --git a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
index 4dbb34f0..4eef4fce 100644
--- a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
+++ b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
@@ -412,11 +412,26 @@ class EditorNotifier extends _$EditorNotifier {
     }
   }
 
-  void applyInMemoryProjectManifest(ProjectManifest manifest) {
-    state = state.copyWith(
-      project: manifest,
-      isProjectDirty: true,
-    );
+  /// Remplace le manifest projet en mémoire (aucune écriture disque).
+  ///
+  /// Lot Environment-16 : [statusMessage] optionnel pour feedback shell ;
+  /// [errorMessage] est effacé sur succès pour éviter un message obsolète.
+  void applyInMemoryProjectManifest(
+    ProjectManifest manifest, {
+    String? statusMessage,
+  }) {
+    state = statusMessage == null
+        ? state.copyWith(
+            project: manifest,
+            isProjectDirty: true,
+            errorMessage: null,
+          )
+        : state.copyWith(
+            project: manifest,
+            isProjectDirty: true,
+            errorMessage: null,
+            statusMessage: statusMessage,
+          );
   }
 
   Future<bool> saveProjectManifest() async {
diff --git a/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart b/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
index c21f38a8..b123cc65 100644
--- a/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
@@ -12,7 +12,7 @@ enum EnvironmentStudioPanelMode {
   /// Liste + détail des presets existants (non mutateur).
   browser,
 
-  /// Formulaire de brouillon sans persistance manifest.
+  /// Formulaire de brouillon ; persistance manifest via callback parent (mémoire).
   createDraft,
 }
 
@@ -25,13 +25,14 @@ enum EnvironmentStudioPanelMode {
 /// les [EnvironmentPreset.templateId] absents du set (défaut `{}` = désactivé).
 ///
 /// Le mode [EnvironmentStudioPanelMode.createDraft] permet un brouillon local
-/// ([EnvironmentPresetDraft]) sans [upsertProjectEnvironmentPreset] ni
-/// [buildEnvironmentPresetFromDraft] côté UI.
+/// ([EnvironmentPresetDraft]) ; l’enregistrement manifest mémoire passe par
+/// [onEnvironmentPresetSaved] (Lot Environment-16, sans disque).
 class EnvironmentStudioPanel extends StatefulWidget {
   const EnvironmentStudioPanel({
     super.key,
     required this.manifest,
     this.knownTemplateIds = const <String>{},
+    this.onEnvironmentPresetSaved,
   });
 
   final ProjectManifest manifest;
@@ -39,6 +40,12 @@ class EnvironmentStudioPanel extends StatefulWidget {
   /// Quand non vide, restreint les templates reconnus (diagnostics auteur).
   final Set<String> knownTemplateIds;
 
+  /// Après validation sans erreur : manifest mis à jour + preset créé ;
+  /// le parent (ex. workspace) applique l’état éditeur ; pas d’I/O disque ici.
+  final void Function(
+          ProjectManifest nextManifest, EnvironmentPreset savedPreset)?
+      onEnvironmentPresetSaved;
+
   @override
   State<EnvironmentStudioPanel> createState() => _EnvironmentStudioPanelState();
 }
@@ -126,6 +133,19 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
     });
   }
 
+  void _onEnvironmentPresetSavedInMemory(
+    ProjectManifest nextManifest,
+    EnvironmentPreset savedPreset,
+  ) {
+    widget.onEnvironmentPresetSaved?.call(nextManifest, savedPreset);
+    setState(() {
+      _panelMode = EnvironmentStudioPanelMode.browser;
+      _selectedPresetId = savedPreset.id;
+      _draft = EnvironmentPresetDraft.empty();
+      _draftFormEpoch++;
+    });
+  }
+
   @override
   Widget build(BuildContext context) {
     final label = EditorChrome.primaryLabel(context);
@@ -143,7 +163,7 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
         ? validateEnvironmentPresetDraft(
             _draft,
             manifest: widget.manifest,
-            knownTemplateIds: const <String>{},
+            knownTemplateIds: widget.knownTemplateIds,
           )
         : null;
 
@@ -205,12 +225,18 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
                         ),
                         child: EnvironmentPresetDraftForm(
                           key: ValueKey<int>(_draftFormEpoch),
+                          manifest: widget.manifest,
+                          knownTemplateIds: widget.knownTemplateIds,
                           draft: _draft,
                           validation: draftValidation!,
                           projectElements: widget.manifest.elements,
                           onChanged: (d) => setState(() => _draft = d),
                           onCancel: _closeDraftForm,
                           onReset: _resetDraft,
+                          onEnvironmentPresetSaved:
+                              widget.onEnvironmentPresetSaved == null
+                                  ? null
+                                  : _onEnvironmentPresetSavedInMemory,
                         ),
                       ),
                     ),
@@ -268,10 +294,11 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
           ),
           child: Text(
             isDraft
-                ? 'Brouillon local — aucune écriture dans le projet. '
-                    'Création réelle et palette éditables arrivent dans les prochains lots.'
-                : 'Lecture seule sur les presets existants — édition manifest et '
-                    'génération arrivent dans les prochains lots.',
+                ? 'Brouillon : vous pouvez enregistrer le preset dans le projet '
+                    '(mémoire de l’éditeur uniquement, pas de fichier project.json). '
+                    'La sauvegarde disque et la génération sur carte restent à venir.'
+                : 'Lecture seule sur les presets existants — édition d’un preset '
+                    'existant et génération sur carte arrivent dans les prochains lots.',
             key: const Key('environment-studio-read-only-banner'),
             style: const TextStyle(
               color: EditorChrome.accentJade,
@@ -302,7 +329,8 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
         children: [
           Text(
             'Aucun preset d’environnement pour le moment.\n'
-            'Les presets seront enregistrés dans le projet dans un prochain lot.',
+            'Utilisez « Préparer un preset », puis « Enregistrer dans le projet » '
+            '(mémoire de session, sans écriture disque automatique).',
             key: const Key('environment-studio-empty-presets'),
             textAlign: TextAlign.center,
             style: TextStyle(
@@ -434,8 +462,8 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
         ),
         const SizedBox(height: 8),
         Text(
-          '• création de presets ;\n'
-          '• édition de palettes ;\n'
+          '• sauvegarde disque du manifest projet ;\n'
+          '• édition des presets existants ;\n'
           '• utilisation dans les Environment Layers ;\n'
           '• génération organique sur les maps.',
           key: const Key('environment-studio-soon-bullets'),
diff --git a/packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart b/packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart
index 36f9bfe2..155563b5 100644
--- a/packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart
+++ b/packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart
@@ -1,6 +1,7 @@
 import 'package:flutter/cupertino.dart';
 import 'package:flutter_riverpod/flutter_riverpod.dart';
 
+import '../editor/state/editor_notifier.dart';
 import '../editor/state/editor_selectors.dart';
 import 'environment_studio_panel.dart';
 
@@ -17,7 +18,16 @@ class EnvironmentStudioWorkspace extends ConsumerWidget {
     if (manifest == null) {
       return const _EnvironmentStudioProjectMissingState();
     }
-    return EnvironmentStudioPanel(manifest: manifest);
+    return EnvironmentStudioPanel(
+      manifest: manifest,
+      onEnvironmentPresetSaved: (nextManifest, preset) {
+        ref.read(editorNotifierProvider.notifier).applyInMemoryProjectManifest(
+              nextManifest,
+              statusMessage:
+                  'Preset d’environnement « ${preset.name} » ajouté au projet.',
+            );
+      },
+    );
   }
 }
 
diff --git a/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart b/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
index 4277e270..746ee2b2 100644
--- a/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
+++ b/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
@@ -7,18 +7,28 @@ import 'environment_generation_params_draft_editor.dart';
 import 'environment_palette_item_draft_editor.dart';
 import 'environment_preset_draft_validation_view.dart';
 
-/// Formulaire local de brouillon (aucune persistance manifest).
+/// Formulaire local de brouillon ; enregistrement manifest mémoire via
+/// [onEnvironmentPresetSaved] (Lot Environment-16, sans disque).
 class EnvironmentPresetDraftForm extends StatefulWidget {
   const EnvironmentPresetDraftForm({
     super.key,
+    required this.manifest,
+    this.knownTemplateIds = const <String>{},
     required this.draft,
     required this.validation,
     required this.projectElements,
     required this.onChanged,
     required this.onCancel,
     required this.onReset,
+    this.onEnvironmentPresetSaved,
   });
 
+  /// Manifest courant (validation + upsert avant callback).
+  final ProjectManifest manifest;
+
+  /// Aligné sur [EnvironmentStudioPanel.knownTemplateIds].
+  final Set<String> knownTemplateIds;
+
   /// Éléments du projet (`manifest.elements`) pour le picker de palette.
   final List<ProjectElementEntry> projectElements;
 
@@ -28,6 +38,11 @@ class EnvironmentPresetDraftForm extends StatefulWidget {
   final VoidCallback onCancel;
   final VoidCallback onReset;
 
+  /// `null` : enregistrement indisponible (bouton désactivé + note).
+  final void Function(
+          ProjectManifest nextManifest, EnvironmentPreset savedPreset)?
+      onEnvironmentPresetSaved;
+
   @override
   State<EnvironmentPresetDraftForm> createState() =>
       _EnvironmentPresetDraftFormState();
@@ -62,6 +77,19 @@ class _EnvironmentPresetDraftFormState
     super.dispose();
   }
 
+  EnvironmentPresetDraft _draftFromControllers() {
+    final so = int.tryParse(_sortCtrl.text.trim());
+    return EnvironmentPresetDraft(
+      id: _idCtrl.text,
+      name: _nameCtrl.text,
+      templateId: _templateCtrl.text,
+      palette: widget.draft.palette,
+      defaultParams: widget.draft.defaultParams,
+      categoryId: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text,
+      sortOrder: so ?? widget.draft.sortOrder,
+    );
+  }
+
   void _emit({
     List<EnvironmentPaletteItemDraft>? palette,
     EnvironmentGenerationParamsDraft? defaultParams,
@@ -101,10 +129,34 @@ class _EnvironmentPresetDraftFormState
     _emit(palette: next);
   }
 
+  void _saveDraftToProject() {
+    final save = widget.onEnvironmentPresetSaved;
+    if (save == null) {
+      return;
+    }
+    final draft = _draftFromControllers();
+    final validation = validateEnvironmentPresetDraft(
+      draft,
+      manifest: widget.manifest,
+      knownTemplateIds: widget.knownTemplateIds,
+    );
+    if (validation.hasErrors) {
+      return;
+    }
+    final preset = buildEnvironmentPresetFromDraft(draft);
+    final nextManifest = upsertProjectEnvironmentPreset(
+      widget.manifest,
+      preset,
+    );
+    save(nextManifest, preset);
+  }
+
   @override
   Widget build(BuildContext context) {
     final label = EditorChrome.primaryLabel(context);
     final subtle = EditorChrome.subtleLabel(context);
+    final canSaveToProject =
+        widget.onEnvironmentPresetSaved != null && !widget.validation.hasErrors;
 
     return SingleChildScrollView(
       key: const Key('environment-studio-draft-form-scroll'),
@@ -143,8 +195,9 @@ class _EnvironmentPresetDraftFormState
           ),
           const SizedBox(height: 10),
           Text(
-            'Ce formulaire prépare un preset. L’enregistrement dans le projet sera '
-            'ajouté dans un prochain lot.',
+            'Remplissez le brouillon puis « Enregistrer dans le projet » pour '
+            'l’ajouter au manifest en mémoire (marque le projet modifié ; '
+            'aucune écriture disque automatique).',
             key: const Key('environment-studio-draft-form-intro'),
             style: TextStyle(
               color: subtle,
@@ -221,8 +274,8 @@ class _EnvironmentPresetDraftFormState
           ),
           const SizedBox(height: 8),
           Text(
-            'Les éléments ajoutés ici restent dans le brouillon local tant que la '
-            'création réelle n’est pas branchée.',
+            'Les éléments doivent exister dans le projet ; ils sont copiés dans le '
+            'preset lors de l’enregistrement.',
             key: const Key('environment-studio-draft-palette-local-note'),
             style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
           ),
@@ -274,6 +327,19 @@ class _EnvironmentPresetDraftFormState
             labelColor: label,
             subtleColor: subtle,
           ),
+          if (widget.validation.hasErrors) ...[
+            const SizedBox(height: 10),
+            Text(
+              'Corrigez les erreurs du brouillon pour l’enregistrer dans le projet.',
+              key: const Key('environment-studio-draft-save-disabled-hint'),
+              style: TextStyle(
+                color: CupertinoColors.systemOrange.resolveFrom(context),
+                fontSize: 12,
+                fontWeight: FontWeight.w600,
+                height: 1.35,
+              ),
+            ),
+          ],
           const SizedBox(height: 24),
           Wrap(
             spacing: 8,
@@ -293,8 +359,23 @@ class _EnvironmentPresetDraftFormState
                 onPressed: widget.onReset,
                 child: const Text('Réinitialiser brouillon'),
               ),
+              CupertinoButton(
+                key: const Key('environment-studio-draft-save-project'),
+                padding:
+                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
+                onPressed: canSaveToProject ? _saveDraftToProject : null,
+                child: const Text('Enregistrer dans le projet'),
+              ),
             ],
           ),
+          if (widget.onEnvironmentPresetSaved == null) ...[
+            const SizedBox(height: 8),
+            Text(
+              'Enregistrement indisponible dans ce contexte.',
+              key: const Key('environment-studio-draft-save-unavailable-note'),
+              style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
+            ),
+          ],
         ],
       ),
     );
diff --git a/packages/map_editor/test/shell_chrome_test_harness.dart b/packages/map_editor/test/shell_chrome_test_harness.dart
index 0bb25970..836d4c90 100644
--- a/packages/map_editor/test/shell_chrome_test_harness.dart
+++ b/packages/map_editor/test/shell_chrome_test_harness.dart
@@ -38,6 +38,7 @@ ProjectManifest buildShellChromeProject({
   List<ProjectPathPatternPreset> pathPatternPresets =
       const <ProjectPathPatternPreset>[],
   List<EnvironmentPreset> environmentPresets = const <EnvironmentPreset>[],
+  List<ProjectElementEntry> elements = const <ProjectElementEntry>[],
 }) {
   return ProjectManifest(
     name: name,
@@ -46,6 +47,7 @@ ProjectManifest buildShellChromeProject({
     pathPresets: pathPresets,
     pathPatternPresets: pathPatternPresets,
     environmentPresets: environmentPresets,
+    elements: elements,
     surfaceCatalog: ProjectSurfaceCatalog(),
   );
 }
```

### Nouveau fichier (git diff --no-index /dev/null …)

```diff
diff --git a/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart b/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart
new file mode 100644
index 00000000..659c8ebe
--- /dev/null
+++ b/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart
@@ -0,0 +1,536 @@
+import 'package:flutter/cupertino.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:flutter_riverpod/flutter_riverpod.dart';
+import 'package:macos_ui/macos_ui.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
+import 'package:map_editor/src/features/editor/state/editor_state.dart';
+import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';
+
+import '../shell_chrome_test_harness.dart';
+
+void main() {
+  group('EnvironmentPresetDraftForm — Enregistrer dans le projet', () {
+    testWidgets(
+      'brouillon initial invalide : bouton désactivé + aide visible',
+      (tester) async {
+        await _pumpPanel(
+          tester,
+          manifest: _manifest(elements: [_element(id: 'e1')]),
+          onSaved: (_, __) {},
+        );
+        await tester
+            .tap(find.byKey(const Key('environment-studio-open-draft')));
+        await tester.pumpAndSettle();
+
+        expect(
+          find.byKey(const Key('environment-studio-draft-save-project')),
+          findsOneWidget,
+        );
+        final saveBtn = tester.widget<CupertinoButton>(
+          find.byKey(const Key('environment-studio-draft-save-project')),
+        );
+        expect(saveBtn.onPressed, isNull);
+        expect(
+          find.byKey(const Key('environment-studio-draft-save-disabled-hint')),
+          findsOneWidget,
+        );
+        expect(
+          find.text(
+            'Corrigez les erreurs du brouillon pour l’enregistrer dans le projet.',
+          ),
+          findsOneWidget,
+        );
+      },
+    );
+
+    testWidgets(
+      'sans callback : bouton désactivé + note indisponible',
+      (tester) async {
+        await _pumpPanel(
+          tester,
+          manifest: _manifest(elements: [_element(id: 'e1')]),
+        );
+        await tester
+            .tap(find.byKey(const Key('environment-studio-open-draft')));
+        await tester.pumpAndSettle();
+
+        final saveBtn = tester.widget<CupertinoButton>(
+          find.byKey(const Key('environment-studio-draft-save-project')),
+        );
+        expect(saveBtn.onPressed, isNull);
+        expect(
+          find.byKey(
+              const Key('environment-studio-draft-save-unavailable-note')),
+          findsOneWidget,
+        );
+      },
+    );
+
+    testWidgets(
+      'brouillon valide : callback reçoit manifest + preset, browser + sélection',
+      (tester) async {
+        ProjectManifest? receivedManifest;
+        EnvironmentPreset? receivedPreset;
+
+        final initial = _manifest(elements: [_element(id: 'e1')]);
+        await _pumpPanel(
+          tester,
+          manifest: initial,
+          onSaved: (m, p) {
+            receivedManifest = m;
+            receivedPreset = p;
+          },
+        );
+        await tester
+            .tap(find.byKey(const Key('environment-studio-open-draft')));
+        await tester.pumpAndSettle();
+
+        await tester.enterText(
+          find.byKey(const Key('environment-studio-draft-field-id')),
+          'meadow_new',
+        );
+        await tester.enterText(
+          find.byKey(const Key('environment-studio-draft-field-name')),
+          'Prairie test',
+        );
+        await tester.enterText(
+          find.byKey(const Key('environment-studio-draft-field-template')),
+          'prairie_tpl',
+        );
+        await tester.tap(
+          find.byKey(const Key('environment-studio-draft-palette-add-item')),
+        );
+        await tester.pumpAndSettle();
+        await tester.enterText(
+          find.byKey(const Key('environment-studio-palette-draft-element-0')),
+          'e1',
+        );
+        await tester.pumpAndSettle();
+
+        final saveBtn = tester.widget<CupertinoButton>(
+          find.byKey(const Key('environment-studio-draft-save-project')),
+        );
+        expect(saveBtn.onPressed, isNotNull);
+
+        await tester.tap(
+          find.byKey(const Key('environment-studio-draft-save-project')),
+        );
+        await tester.pumpAndSettle();
+
+        expect(receivedManifest, isNotNull);
+        expect(receivedPreset, isNotNull);
+        expect(receivedPreset!.id, 'meadow_new');
+        expect(receivedPreset!.name, 'Prairie test');
+        expect(receivedPreset!.templateId, 'prairie_tpl');
+        expect(receivedPreset!.palette.single.elementId, 'e1');
+        expect(
+          receivedManifest!.environmentPresets.map((e) => e.id).toList(),
+          contains('meadow_new'),
+        );
+
+        expect(find.byKey(const Key('environment-studio-preset-list')),
+            findsOneWidget);
+        expect(find.text('Prairie test'), findsWidgets);
+      },
+    );
+
+    testWidgets('duplicate id : bouton désactivé, callback non invoqué',
+        (tester) async {
+      var calls = 0;
+      await _pumpPanel(
+        tester,
+        manifest: _manifest(
+          environmentPresets: [_preset(id: 'forest')],
+          elements: [_element(id: 'e1')],
+        ),
+        onSaved: (_, __) => calls++,
+      );
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-draft-field-id')),
+        'forest',
+      );
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-draft-field-name')),
+        'Doublon',
+      );
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-draft-field-template')),
+        't',
+      );
+      await tester.tap(
+        find.byKey(const Key('environment-studio-draft-palette-add-item')),
+      );
+      await tester.pumpAndSettle();
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-palette-draft-element-0')),
+        'e1',
+      );
+      await tester.pumpAndSettle();
+
+      expect(find.textContaining('Id déjà utilisé'), findsOneWidget);
+      final saveBtn = tester.widget<CupertinoButton>(
+        find.byKey(const Key('environment-studio-draft-save-project')),
+      );
+      expect(saveBtn.onPressed, isNull);
+      await tester.tap(
+        find.byKey(const Key('environment-studio-draft-save-project')),
+      );
+      await tester.pumpAndSettle();
+      expect(calls, 0);
+    });
+
+    testWidgets('élément palette inconnu : callback non invoqué',
+        (tester) async {
+      var calls = 0;
+      await _pumpPanel(
+        tester,
+        manifest: _manifest(elements: [_element(id: 'e1')]),
+        onSaved: (_, __) => calls++,
+      );
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-draft-field-id')),
+        'x',
+      );
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-draft-field-name')),
+        'Nom',
+      );
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-draft-field-template')),
+        't',
+      );
+      await tester.tap(
+        find.byKey(const Key('environment-studio-draft-palette-add-item')),
+      );
+      await tester.pumpAndSettle();
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-palette-draft-element-0')),
+        'introuvable',
+      );
+      await tester.pumpAndSettle();
+
+      expect(find.textContaining('Élément introuvable'), findsOneWidget);
+      expect(
+        tester
+            .widget<CupertinoButton>(
+              find.byKey(const Key('environment-studio-draft-save-project')),
+            )
+            .onPressed,
+        isNull,
+      );
+      expect(calls, 0);
+    });
+
+    testWidgets('warning template inconnu ne bloque pas l’enregistrement',
+        (tester) async {
+      var calls = 0;
+      await _pumpPanel(
+        tester,
+        manifest: _manifest(elements: [_element(id: 'e1')]),
+        knownTemplateIds: {'only_this'},
+        onSaved: (_, __) => calls++,
+      );
+      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
+      await tester.pumpAndSettle();
+
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-draft-field-id')),
+        'warn_tpl',
+      );
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-draft-field-name')),
+        'W',
+      );
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-draft-field-template')),
+        'not_in_set',
+      );
+      await tester.tap(
+        find.byKey(const Key('environment-studio-draft-palette-add-item')),
+      );
+      await tester.pumpAndSettle();
+      await tester.enterText(
+        find.byKey(const Key('environment-studio-palette-draft-element-0')),
+        'e1',
+      );
+      await tester.pumpAndSettle();
+
+      expect(find.textContaining('Template inconnu'), findsOneWidget);
+      expect(
+        tester
+            .widget<CupertinoButton>(
+              find.byKey(const Key('environment-studio-draft-save-project')),
+            )
+            .onPressed,
+        isNotNull,
+      );
+      await tester.tap(
+        find.byKey(const Key('environment-studio-draft-save-project')),
+      );
+      await tester.pumpAndSettle();
+      expect(calls, 1);
+    });
+  });
+
+  group('EditorNotifier — applyInMemoryProjectManifest (Lot 16)', () {
+    test('statusMessage optionnel et errorMessage effacé', () {
+      final container = ProviderContainer();
+      addTearDown(container.dispose);
+      final notifier = container.read(editorNotifierProvider.notifier);
+      notifier.state = notifier.state.copyWith(
+        project: _manifest(elements: const []),
+        errorMessage: 'erreur précédente',
+        statusMessage: 'ancien',
+      );
+
+      notifier.applyInMemoryProjectManifest(
+        _manifest(name: 'Après', elements: const []),
+        statusMessage: 'Preset d’environnement « X » ajouté au projet.',
+      );
+
+      expect(notifier.state.errorMessage, isNull);
+      expect(
+        notifier.state.statusMessage,
+        'Preset d’environnement « X » ajouté au projet.',
+      );
+      expect(notifier.state.isProjectDirty, isTrue);
+    });
+
+    test('sans statusMessage : conserve le message de statut précédent', () {
+      final container = ProviderContainer();
+      addTearDown(container.dispose);
+      final notifier = container.read(editorNotifierProvider.notifier);
+      notifier.state = notifier.state.copyWith(
+        project: _manifest(elements: const []),
+        statusMessage: 'conservé',
+      );
+      notifier.applyInMemoryProjectManifest(
+        _manifest(name: 'N', elements: const []),
+      );
+      expect(notifier.state.statusMessage, 'conservé');
+    });
+
+    test('ne modifie pas activeMap', () async {
+      final container = ProviderContainer();
+      addTearDown(container.dispose);
+      final notifier = container.read(editorNotifierProvider.notifier);
+      const map = MapData(
+        id: 'm1',
+        name: 'M',
+        size: GridSize(width: 4, height: 4),
+        layers: <MapLayer>[],
+      );
+      notifier.state = notifier.state.copyWith(
+        project: _manifest(elements: const []),
+        activeMap: map,
+        activeMapPath: 'maps/m1.json',
+      );
+
+      notifier.applyInMemoryProjectManifest(
+        _manifest(name: 'Touch', elements: const []),
+        statusMessage: 'ok',
+      );
+
+      expect(notifier.state.activeMap!.id, 'm1');
+      expect(notifier.state.activeMapPath, 'maps/m1.json');
+    });
+  });
+
+  group('Environment Studio workspace — persistance mémoire', () {
+    testWidgets(
+      'EditorCanvasHost : enregistrement met à jour le projet et dirty',
+      (tester) async {
+        final container = await pumpEditorCanvasHostHarness(
+          tester,
+          surfaceSize: const Size(960, 2200),
+          initialState: EditorState(
+            projectRootPath: '/tmp/lot16_env',
+            project: buildShellChromeProject(
+              elements: const [
+                ProjectElementEntry(
+                  id: 'tree_a',
+                  name: 'Arbre',
+                  tilesetId: 'ts',
+                  categoryId: 'c',
+                  frames: [
+                    TilesetVisualFrame(
+                      source: TilesetSourceRect(x: 0, y: 0),
+                    ),
+                  ],
+                ),
+              ],
+            ),
+            workspaceMode: EditorWorkspaceMode.environmentStudio,
+          ),
+        );
+
+        await tester
+            .tap(find.byKey(const Key('environment-studio-open-draft')));
+        await tester.pumpAndSettle();
+
+        await tester.enterText(
+          find.byKey(const Key('environment-studio-draft-field-id')),
+          'lot16_ws',
+        );
+        await tester.enterText(
+          find.byKey(const Key('environment-studio-draft-field-name')),
+          'Depuis workspace',
+        );
+        await tester.enterText(
+          find.byKey(const Key('environment-studio-draft-field-template')),
+          'tpl_ws',
+        );
+        await tester.tap(
+          find.byKey(const Key('environment-studio-draft-palette-add-item')),
+        );
+        await tester.pumpAndSettle();
+        await tester.enterText(
+          find.byKey(const Key('environment-studio-palette-draft-element-0')),
+          'tree_a',
+        );
+        await tester.pumpAndSettle();
+
+        await tester.tap(
+          find.byKey(const Key('environment-studio-draft-save-project')),
+        );
+        await tester.pumpAndSettle();
+
+        final snap = container.read(editorNotifierProvider);
+        expect(snap.isProjectDirty, isTrue);
+        expect(
+          snap.project!.environmentPresets.map((e) => e.id),
+          contains('lot16_ws'),
+        );
+        expect(
+          snap.statusMessage,
+          'Preset d’environnement « Depuis workspace » ajouté au projet.',
+        );
+        expect(find.byKey(const Key('environment-studio-preset-list')),
+            findsOneWidget);
+      },
+    );
+  });
+}
+
+/// Rejoue le rafraîchissement Riverpod du manifest après enregistrement mémoire.
+class _ManifestSyncPanelHost extends StatefulWidget {
+  const _ManifestSyncPanelHost({
+    required this.initialManifest,
+    this.knownTemplateIds = const {},
+    this.onSaved,
+  });
+
+  final ProjectManifest initialManifest;
+  final Set<String> knownTemplateIds;
+  final void Function(ProjectManifest, EnvironmentPreset)? onSaved;
+
+  @override
+  State<_ManifestSyncPanelHost> createState() => _ManifestSyncPanelHostState();
+}
+
+class _ManifestSyncPanelHostState extends State<_ManifestSyncPanelHost> {
+  late ProjectManifest _manifest;
+
+  @override
+  void initState() {
+    super.initState();
+    _manifest = widget.initialManifest;
+  }
+
+  @override
+  void didUpdateWidget(covariant _ManifestSyncPanelHost oldWidget) {
+    super.didUpdateWidget(oldWidget);
+    if (!identical(oldWidget.initialManifest, widget.initialManifest)) {
+      _manifest = widget.initialManifest;
+    }
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    return EnvironmentStudioPanel(
+      manifest: _manifest,
+      knownTemplateIds: widget.knownTemplateIds,
+      onEnvironmentPresetSaved: widget.onSaved == null
+          ? null
+          : (next, preset) {
+              widget.onSaved!(next, preset);
+              setState(() => _manifest = next);
+            },
+    );
+  }
+}
+
+Future<void> _pumpPanel(
+  WidgetTester tester, {
+  required ProjectManifest manifest,
+  Set<String> knownTemplateIds = const {},
+  void Function(ProjectManifest, EnvironmentPreset)? onSaved,
+}) async {
+  tester.view.physicalSize = const Size(900, 2200);
+  tester.view.devicePixelRatio = 1.0;
+  addTearDown(() {
+    tester.view.resetPhysicalSize();
+    tester.view.resetDevicePixelRatio();
+  });
+  await tester.pumpWidget(
+    MacosApp(
+      home: CupertinoPageScaffold(
+        child: _ManifestSyncPanelHost(
+          initialManifest: manifest,
+          knownTemplateIds: knownTemplateIds,
+          onSaved: onSaved,
+        ),
+      ),
+    ),
+  );
+  await tester.pumpAndSettle();
+}
+
+ProjectManifest _manifest({
+  List<EnvironmentPreset> environmentPresets = const [],
+  List<ProjectElementEntry> elements = const [],
+  String name = 't-save',
+}) {
+  return ProjectManifest(
+    name: name,
+    maps: const [],
+    tilesets: const [],
+    environmentPresets: environmentPresets,
+    elements: elements,
+    surfaceCatalog: ProjectSurfaceCatalog(),
+  );
+}
+
+EnvironmentPreset _preset({required String id}) {
+  return EnvironmentPreset(
+    id: id,
+    name: 'P $id',
+    templateId: 'tpl',
+    palette: [
+      EnvironmentPaletteItem(elementId: 'e1', weight: 1),
+    ],
+    defaultParams: EnvironmentGenerationParams.standard(),
+    sortOrder: 0,
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

## 18. Auto-review

**Points solides** : flux strict validate → build → upsert ; pas de Riverpod dans le formulaire ; tests couvrant duplicate / missing / warning / notifier / canvas ; `errorMessage` nettoyé sur succès manifest mémoire.

**Points discutables** : `applyInMemoryProjectManifest` efface désormais `errorMessage` même sans `statusMessage` (changement de comportement pour Path Studio et autres appelants — probablement souhaitable). Le libellé « Enregistrer dans le projet » peut laisser croire à une sauvegarde disque : le bandeau + intro + statut précisent « mémoire » / pas de `project.json` automatique.

**Corrections après auto-review** : hôte test `_ManifestSyncPanelHost` pour refléter le rafraîchissement manifest Riverpod ; `surfaceSize` plus grand pour le test canvas ; libellés validation `textContaining` (préfixe « Erreur — »).

**Risques restants** : `_draftFromControllers` lit la palette depuis `widget.draft` (cohérent avec les éditeurs enfants) ; si un jour les contrôleurs de palette diverge sans `onChanged`, un hardening serait possible (hors lot).

**Regard critique sur le prompt** : le panel « calcule » surtout via le **formulaire** — cohérent avec la testabilité ; retour browser + sélection automatique conforme au brief UX.

---

## Confirmations Evidence Pack (lot 16)

| Affirmation | Preuve |
|-------------|--------|
| Aucun `ProjectManifest` modèle / fixture canon modifié | `git diff` limité à `map_editor` + test harness ; pas de `examples/` ni `project.json` template |
| Aucun `MapLayer` modifié | Idem ; pas de fichiers `map_layer` dans le diff |
| `upsertProjectEnvironmentPreset` uniquement après `!validation.hasErrors` | Code `_saveDraftToProject` + tests duplicate / missing |
| Pas de sauvegarde disque dans ce flux | Pas d’appel `saveProject` / repository dans le chemin ; tests documentés |
| Pas de `FileProjectRepository` / `saveProject` dans ce flux | Revue grep + implémentation |
| Pas de générateur | Aucun fichier générateur |
| Pas de `EnvironmentLayer` / `EnvironmentArea` | Aucun import ni fichier couche map |
| Pas de `build_runner` | Non exécuté |
| Aucun fichier generated modifié | `git status` sans `.g.dart` / `.freezed.dart` |
| Aucun commit / git add / push | Opérations git write interdites ; non exécutées |

---

## 19. Verdict

Statut du lot :

- [x] **Validé**

Résumé :

```text
Lot Environment-16 livré : enregistrement brouillon → manifest mémoire + dirty + statusMessage,
retour browser et sélection, tests et analyze ciblés verts, suite environment_studio verte.
flutter test complet map_editor : 929 passés, 34 échecs préexistants / hors périmètre.
```

Prochain lot recommandé :

```text
Environment-17 — Environment Preset Save Flow UX Hardening V0
```
