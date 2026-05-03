# Environment Studio Lot 17 — Save Flow UX Hardening V0

## 1. Résumé exécutif

Durcissement UX du flux Lot 16 : libellé **« Ajouter au projet en mémoire »**, aides (erreurs / warnings / callback absent), **feedback local** dans le browser après succès, **try/catch** sur build/upsert/callback avec message d’erreur et maintien du brouillon, **effacement du feedback** à l’ouverture d’un nouveau brouillon. Aucun changement `map_core`, `editor_notifier`, disque, `EnvironmentLayer`.

## 2. Périmètre du lot

- `EnvironmentStudioPanel`, `EnvironmentPresetDraftForm`, widget `EnvironmentPresetSaveFeedback`, tests `environment_preset_save_to_manifest_test.dart`.
- Hors lot : persistance disque, générateur, édition preset existant, `map_core`, `editor_notifier` (non modifié).

## 3. Audit initial du flux save Lot 16

Fichiers relus : panel (callback `_onEnvironmentPresetSavedInMemory`, retour browser, sélection), formulaire (`_saveDraftToProject` linéaire sans catch), `environment_preset_draft_validation_view` / `environment_preset_draft_presentation` (libellés d’issues inchangés), tests save existants. Constats : libellé « Enregistrer dans le projet » ambigu ; pas de feedback in-panel ; exception callback = transition partielle impossible à tester sans catch côté formulaire.

## 4. Décisions UX save flow

- **Bouton** : « Ajouter au projet en mémoire » (pas « Sauvegarder » seul).
- **Feedback** : `_localSaveFeedbackPresetName` dans le panel + widget dédié sous le bandeau browser (pas de provider).
- **Erreurs callback** : `String? _saveErrorMessage` dans le formulaire ; catch englobe `build` + `upsert` + `save` après validation sans erreurs ; effacement de l’erreur locale lors d’une nouvelle émission de brouillon (`_emit`).
- **Warnings** : ligne d’aide jaune uniquement si `hasWarnings && !hasErrors`.

## 5. Clarification du bouton d’ajout au projet

Texte du bouton : **Ajouter au projet en mémoire**. Textes d’aide : erreurs → « Corrigez les erreurs du brouillon pour l’ajouter au projet. » ; sans callback → « Ajout au projet indisponible dans ce contexte. » ; warnings → « Les avertissements ne bloquent pas l’ajout au projet. »

## 6. Feedback local post-save

Widget [`EnvironmentPresetSaveFeedback`](packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_save_feedback.dart) : deux lignes (preset en mémoire ; rappel sauvegarde projet pour disque). Affiché au-dessus de la liste/détail en mode browser si `_localSaveFeedbackPresetName != null`. Réinitialisé dans `_openDraftForm`.

## 7. Gestion d’erreur callback

`try/catch` dans `_saveDraftToProject` : message fixe « Impossible d’ajouter le preset au projet en mémoire. », `debugPrint` du détail + stack pour le développeur. En cas d’échec, pas d’appel à la suite du handler panel (le `setState` browser du panel n’est pas atteint si le throw vient du callback parent).

## 8. Sélection du preset créé

Comportement Lot 16 conservé ; tests renforcés : clés `environment-studio-detail-id` / `environment-studio-detail-name` après save.

## 9. Non-persistance disque garantie

Aucun fichier sous `lib/src/features/environment_studio` n’appelle `FileProjectRepository` ni `saveProject` / `saveProjectManifest`. Le grep ciblé (voir §14) ne remonte que `editor_notifier.dart` hors dossier Environment Studio.

## 10. Pourquoi aucun générateur / EnvironmentLayer dans ce lot

Conformité stricte au cahier : uniquement UX et robustesse du flux brouillon → manifest mémoire.

## 11. Fichiers modifiés

| Chemin | Action |
|--------|--------|
| `packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart` | Feedback local, bannières, layout browser |
| `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart` | Libellés, hints, try/catch, erreur locale |
| `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_save_feedback.dart` | **Nouveau** |
| `packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart` | Tests Lot 17 |

## 12. Tests ajoutés ou modifiés

- Libellé + absence Save/Create/Generate + aide erreurs.
- Note callback absent (texte exact).
- Warnings : hint + save OK.
- Succès : feedback local + détail id/nom.
- Ouverture brouillon : feedback effacé.
- Callback `throw` : formulaire + message erreur, pas de liste browser.

## 13. Commandes exécutées

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
dart format lib/src/features/environment_studio/environment_studio_panel.dart \
  lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart \
  lib/src/features/environment_studio/widgets/environment_preset_save_feedback.dart \
  test/environment_studio/environment_preset_save_to_manifest_test.dart

flutter analyze lib/src/features/environment_studio/environment_studio_panel.dart \
  lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart \
  lib/src/features/environment_studio/widgets/environment_preset_save_feedback.dart \
  test/environment_studio/environment_preset_save_to_manifest_test.dart

grep -R "FileProjectRepository\|saveProject\|saveProjectManifest" -n \
  lib/src/features/environment_studio \
  lib/src/features/editor/state/editor_notifier.dart || true

flutter test test/environment_studio/environment_preset_save_to_manifest_test.dart --reporter expanded
flutter test test/environment_studio/environment_studio_preset_creation_form_test.dart --reporter expanded
flutter test test/environment_studio/environment_preset_palette_draft_editor_test.dart --reporter expanded
flutter test test/environment_studio/environment_generation_params_draft_editor_test.dart --reporter expanded
flutter test test/environment_studio/environment_preset_draft_test.dart --reporter expanded
flutter test test/environment_studio --reporter expanded
flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart --reporter expanded
flutter test
```

## 14. Résultats des commandes

### `dart format`

Exit code **0**.

### `flutter analyze` (4 fichiers)

```
Analyzing 4 items...

No issues found! (ran in 1.5s)
```

### `grep -R "FileProjectRepository|saveProject|saveProjectManifest" ...`

Sortie exacte :

```
lib/src/features/editor/state/editor_notifier.dart:437:  Future<bool> saveProjectManifest() async {
lib/src/features/editor/state/editor_notifier.dart:446:    debugPrint('EditorNotifier: saveProjectManifest()');
lib/src/features/editor/state/editor_notifier.dart:448:      await ref.read(projectRepositoryProvider).saveProject(
lib/src/features/editor/state/editor_notifier.dart:1488:  Future<void> saveProjectDialogueYarnBody({
lib/src/features/editor/state/editor_notifier.dart:1492:      state = await _projectContentController.saveProjectDialogueYarnBody(
```

Aucune occurrence sous `lib/src/features/environment_studio/`.

### `flutter test test/environment_studio/environment_preset_save_to_manifest_test.dart --reporter expanded`

Sortie complète :

```
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart
00:00 +0: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon initial invalide : libellé bouton, aide, pas Save/Create/Generate
00:00 +1: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) sans callback : bouton désactivé + note indisponible
00:00 +2: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) brouillon valide : callback reçoit manifest + preset, browser + sélection
00:00 +3: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) duplicate id : bouton désactivé, callback non invoqué
00:01 +4: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) élément palette inconnu : callback non invoqué
00:01 +5: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) warning template inconnu ne bloque pas l’ajout au projet
00:01 +6: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) ouvrir un nouveau brouillon efface le feedback local post-save
00:01 +7: EnvironmentPresetDraftForm — ajout mémoire (Lot 17) callback qui lève : formulaire visible, erreur locale, pas de browser
EnvironmentPresetDraftForm: ajout mémoire impossible: Bad state: simulé
#0      main.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart:381:31)
#1      _ManifestSyncPanelHostState.build.<anonymous closure> (file:///Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart:631:30)
#2      _EnvironmentStudioPanelState._onEnvironmentPresetSavedInMemory (package:map_editor/src/features/environment_studio/environment_studio_panel.dart:145:38)
#3      _EnvironmentPresetDraftFormState._saveDraftToProject (package:map_editor/src/features/environment_studio/widgets/environment_preset_draft_form.dart:159:11)
#4      _CupertinoButtonState._handleTap (package:flutter/src/cupertino/button.dart:421:24)
#5      _CupertinoButtonState._handleTapUp (package:flutter/src/cupertino/button.dart:393:7)
#6      TapGestureRecognizer.handleTapUp.<anonymous closure> (package:flutter/src/gestures/tap.dart:755:57)
#7      GestureRecognizer.invokeCallback (package:flutter/src/gestures/recognizer.dart:345:24)
#8      TapGestureRecognizer.handleTapUp (package:flutter/src/gestures/tap.dart:755:11)
#9      BaseTapGestureRecognizer._checkUp (package:flutter/src/gestures/tap.dart:383:5)
#10     BaseTapGestureRecognizer.handlePrimaryPointer (package:flutter/src/gestures/tap.dart:314:7)
#11     PrimaryPointerGestureRecognizer.handleEvent (package:flutter/src/gestures/recognizer.dart:721:9)
#12     PointerRouter._dispatch (package:flutter/src/gestures/pointer_router.dart:97:12)
#13     PointerRouter._dispatchEventToRoutes.<anonymous closure> (package:flutter/src/gestures/pointer_router.dart:142:9)
#14     _LinkedHashMapMixin.forEach (dart:_compact_hash:765:13)
#15     PointerRouter._dispatchEventToRoutes (package:flutter/src/gestures/pointer_router.dart:140:18)
#16     PointerRouter.route (package:flutter/src/gestures/pointer_router.dart:130:7)
#17     GestureBinding.handleEvent (package:flutter/src/gestures/binding.dart:528:19)
#18     GestureBinding.dispatchEvent (package:flutter/src/gestures/binding.dart:498:22)
#19     RendererBinding.dispatchEvent (package:flutter/src/rendering/binding.dart:473:11)
#20     GestureBinding._handlePointerEventImmediately (package:flutter/src/gestures/binding.dart:437:7)
#21     GestureBinding.handlePointerEvent (package:flutter/src/gestures/binding.dart:394:5)
#22     TestWidgetsFlutterBinding.handlePointerEventForSource.<anonymous closure> (package:flutter_test/src/binding.dart:678:42)
#23     TestWidgetsFlutterBinding.withPointerEventSource (package:flutter_test/src/binding.dart:688:11)
#24     TestWidgetsFlutterBinding.handlePointerEventForSource (package:flutter_test/src/binding.dart:678:5)
#25     WidgetTester.sendEventToBinding.<anonymous closure> (package:flutter_test/src/widget_tester.dart:869:15)
#26     _rootRun (dart:async/zone.dart:1525:13)
#27     _CustomZone.run (dart:async/zone.dart:1422:19)
#28     TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#29     WidgetTester.sendEventToBinding (package:flutter_test/src/widget_tester.dart:868:27)
#30     TestGesture.up.<anonymous closure> (package:flutter_test/src/test_pointer.dart:538:26)
#31     _rootRun (dart:async/zone.dart:1525:13)
#32     _CustomZone.run (dart:async/zone.dart:1422:19)
#33     TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#34     TestGesture.up (package:flutter_test/src/test_pointer.dart:531:27)
#35     WidgetController.tapAt.<anonymous closure> (package:flutter_test/src/controller.dart:1117:21)
<asynchronous suspension>
#36     TestAsyncUtils.guard.<anonymous closure> (package:flutter_test/src/test_async_utils.dart:130:27)
<asynchronous suspension>
#37     main.<anonymous closure>.<anonymous closure> (file:///Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart:408:9)
<asynchronous suspension>
#38     testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#39     TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
#40     StackZoneSpecification._registerCallback.<anonymous closure> (package:stack_trace/src/stack_zone_specification.dart:114:42)
<asynchronous suspension>

00:01 +8: EditorNotifier — applyInMemoryProjectManifest (Lot 16) statusMessage optionnel et errorMessage effacé
00:01 +9: EditorNotifier — applyInMemoryProjectManifest (Lot 16) sans statusMessage : conserve le message de statut précédent
00:01 +10: EditorNotifier — applyInMemoryProjectManifest (Lot 16) ne modifie pas activeMap
00:01 +11: Environment Studio workspace — persistance mémoire EditorCanvasHost : enregistrement met à jour le projet et dirty
00:01 +12: All tests passed!
```

### `flutter test test/environment_studio --reporter expanded`

Dernière ligne : **`00:05 +98: All tests passed!`**

### `flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart`

Dernière ligne : **`00:03 +14: All tests passed!`**

### `flutter test` (package `map_editor` entier)

Dernière ligne : **`00:53 +931 -34: Some tests failed.`** — **34 échecs** hors périmètre Lot 17 (dettes existantes).

## 15. Git status initial et final

**Initial (début de passe Lot 17 sur cette machine)** :

```
 M packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
 M packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart
?? packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_save_feedback.dart
```

**Final** :

```
 M packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
 M packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart
?? packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_save_feedback.dart
?? reports/forest/environment_studio_lot_17_save_flow_ux_hardening.md
```

## 16. Contenu complet des fichiers créés ou modifiés

### `packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'authoring/environment_preset_draft.dart';
import 'widgets/environment_preset_detail.dart';
import 'widgets/environment_preset_draft_form.dart';
import 'widgets/environment_preset_list.dart';
import 'widgets/environment_preset_save_feedback.dart';

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

  /// Lot 17 : message local browser après ajout mémoire (pas au 1er chargement).
  String? _localSaveFeedbackPresetName;

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
      _localSaveFeedbackPresetName = null;
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
    widget.onEnvironmentPresetSaved!.call(nextManifest, savedPreset);
    setState(() {
      _panelMode = EnvironmentStudioPanelMode.browser;
      _selectedPresetId = savedPreset.id;
      _draft = EnvironmentPresetDraft.empty();
      _draftFormEpoch++;
      _localSaveFeedbackPresetName = savedPreset.name;
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
                ? 'Brouillon : utilisez « Ajouter au projet en mémoire » pour intégrer '
                    'le preset au manifest en session. Aucune sauvegarde disque automatique. '
                    'La génération sur carte reste à venir.'
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
            'Utilisez « Préparer un preset », puis « Ajouter au projet en mémoire » '
            '(aucune écriture disque tant que vous n’avez pas sauvegardé le projet).',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_localSaveFeedbackPresetName != null) ...[
          EnvironmentPresetSaveFeedback(
            presetName: _localSaveFeedbackPresetName!,
          ),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: Row(
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

  /// Lot 17 : échec du callback parent ou exception build/upsert après validation.
  String? _saveErrorMessage;

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
    if (_saveErrorMessage != null) {
      setState(() => _saveErrorMessage = null);
    }
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
    setState(() => _saveErrorMessage = null);
    final draft = _draftFromControllers();
    final validation = validateEnvironmentPresetDraft(
      draft,
      manifest: widget.manifest,
      knownTemplateIds: widget.knownTemplateIds,
    );
    if (validation.hasErrors) {
      return;
    }
    try {
      final preset = buildEnvironmentPresetFromDraft(draft);
      final nextManifest = upsertProjectEnvironmentPreset(
        widget.manifest,
        preset,
      );
      save(nextManifest, preset);
    } catch (e, st) {
      debugPrint('EnvironmentPresetDraftForm: ajout mémoire impossible: $e');
      debugPrint('$st');
      setState(() {
        _saveErrorMessage =
            'Impossible d’ajouter le preset au projet en mémoire.';
      });
    }
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
            'Remplissez le brouillon puis « Ajouter au projet en mémoire » pour '
            'l’intégrer au manifest de la session (projet marqué modifié ; '
            'aucune sauvegarde disque automatique).',
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
            'preset lors de l’ajout en mémoire.',
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
              'Corrigez les erreurs du brouillon pour l’ajouter au projet.',
              key: const Key('environment-studio-draft-save-disabled-hint'),
              style: TextStyle(
                color: CupertinoColors.systemOrange.resolveFrom(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
          if (widget.validation.hasWarnings &&
              !widget.validation.hasErrors) ...[
            const SizedBox(height: 10),
            Text(
              'Les avertissements ne bloquent pas l’ajout au projet.',
              key: const Key('environment-studio-draft-save-warnings-hint'),
              style: TextStyle(
                color: CupertinoColors.systemYellow.resolveFrom(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
          if (_saveErrorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _saveErrorMessage!,
              key: const Key('environment-studio-draft-save-error-message'),
              style: TextStyle(
                color: CupertinoColors.systemRed.resolveFrom(context),
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
                child: const Text('Ajouter au projet en mémoire'),
              ),
            ],
          ),
          if (widget.onEnvironmentPresetSaved == null) ...[
            const SizedBox(height: 8),
            Text(
              'Ajout au projet indisponible dans ce contexte.',
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

### `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_save_feedback.dart`

```dart
import 'package:flutter/cupertino.dart';

import '../../../ui/shared/cupertino_editor_widgets.dart';

/// Retour visuel local après ajout d’un preset au manifest en mémoire (Lot 17).
///
/// Complète le [statusMessage] du shell sans le remplacer ; reste dans le panel.
class EnvironmentPresetSaveFeedback extends StatelessWidget {
  const EnvironmentPresetSaveFeedback({
    super.key,
    required this.presetName,
  });

  final String presetName;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return DecoratedBox(
      key: const Key('environment-studio-post-save-local-feedback'),
      decoration: BoxDecoration(
        color: EditorChrome.accentJade.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.accentJade.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Preset « $presetName » ajouté au projet en mémoire.',
              key: const Key('environment-studio-post-save-line-1'),
              style: TextStyle(
                color: label,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Projet modifié — pensez à sauvegarder le projet pour écrire sur disque.',
              key: const Key('environment-studio-post-save-line-2'),
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
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
  group('EnvironmentPresetDraftForm — ajout mémoire (Lot 17)', () {
    testWidgets(
      'brouillon initial invalide : libellé bouton, aide, pas Save/Create/Generate',
      (tester) async {
        await _pumpPanel(
          tester,
          manifest: _manifest(elements: [_element(id: 'e1')]),
          onSaved: (_, __) {},
        );
        await tester
            .tap(find.byKey(const Key('environment-studio-open-draft')));
        await tester.pumpAndSettle();

        expect(find.text('Ajouter au projet en mémoire'), findsOneWidget);
        expect(find.textContaining('Save'), findsNothing);
        expect(find.textContaining('Create'), findsNothing);
        expect(find.textContaining('Generate'), findsNothing);
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
            'Corrigez les erreurs du brouillon pour l’ajouter au projet.',
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
        expect(
          find.text('Ajout au projet indisponible dans ce contexte.'),
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

        expect(
          find.byKey(const Key('environment-studio-post-save-local-feedback')),
          findsOneWidget,
        );
        expect(
          find.textContaining('ajouté au projet en mémoire'),
          findsOneWidget,
        );
        expect(
          find.textContaining('sauvegarder le projet'),
          findsOneWidget,
        );
        expect(
          (tester.widget<Text>(
                  find.byKey(const Key('environment-studio-detail-id'))))
              .data,
          'meadow_new',
        );
        expect(
          (tester.widget<Text>(
                  find.byKey(const Key('environment-studio-detail-name'))))
              .data,
          'Prairie test',
        );
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
        find.byKey(const Key('environment-studio-draft-save-warnings-hint')),
        findsOneWidget,
      );
      expect(
        find.text('Les avertissements ne bloquent pas l’ajout au projet.'),
        findsOneWidget,
      );
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

    testWidgets(
      'ouvrir un nouveau brouillon efface le feedback local post-save',
      (tester) async {
        await _pumpPanel(
          tester,
          manifest: _manifest(elements: [_element(id: 'e1')]),
          onSaved: (_, __) {},
        );
        await tester
            .tap(find.byKey(const Key('environment-studio-open-draft')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('environment-studio-draft-field-id')),
          'fb_clear',
        );
        await tester.enterText(
          find.byKey(const Key('environment-studio-draft-field-name')),
          'NomFb',
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
        await tester.tap(
          find.byKey(const Key('environment-studio-draft-save-project')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('environment-studio-post-save-local-feedback')),
          findsOneWidget,
        );

        await tester
            .tap(find.byKey(const Key('environment-studio-open-draft')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('environment-studio-post-save-local-feedback')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'callback qui lève : formulaire visible, erreur locale, pas de browser',
      (tester) async {
        await _pumpPanel(
          tester,
          manifest: _manifest(elements: [_element(id: 'e1')]),
          onSaved: (_, __) => throw StateError('simulé'),
        );
        await tester
            .tap(find.byKey(const Key('environment-studio-open-draft')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('environment-studio-draft-field-id')),
          'boom_id',
        );
        await tester.enterText(
          find.byKey(const Key('environment-studio-draft-field-name')),
          'Boom',
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

        await tester.tap(
          find.byKey(const Key('environment-studio-draft-save-project')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('environment-studio-draft-form-title')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('environment-studio-draft-save-error-message')),
          findsOneWidget,
        );
        expect(
          find.text(
            'Impossible d’ajouter le preset au projet en mémoire.',
          ),
          findsOneWidget,
        );
        expect(
          (tester.widget<CupertinoTextField>(
                  find.byKey(const Key('environment-studio-draft-field-id'))))
              .controller
              ?.text,
          'boom_id',
        );
        expect(
          find.byKey(const Key('environment-studio-preset-list')),
          findsNothing,
        );
      },
    );
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
        expect(
          find.byKey(const Key('environment-studio-post-save-local-feedback')),
          findsOneWidget,
        );
        expect(
          find.textContaining('ajouté au projet en mémoire'),
          findsOneWidget,
        );
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



## 17. Diff complet

```diff
diff --git a/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart b/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
index b123cc65..37adb49d 100644
--- a/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
@@ -6,6 +6,7 @@ import 'authoring/environment_preset_draft.dart';
 import 'widgets/environment_preset_detail.dart';
 import 'widgets/environment_preset_draft_form.dart';
 import 'widgets/environment_preset_list.dart';
+import 'widgets/environment_preset_save_feedback.dart';
 
 /// Modes locaux du panneau Environment Studio (Lot Environment-13).
 enum EnvironmentStudioPanelMode {
@@ -56,6 +57,9 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
   EnvironmentPresetDraft _draft = EnvironmentPresetDraft.empty();
   int _draftFormEpoch = 0;
 
+  /// Lot 17 : message local browser après ajout mémoire (pas au 1er chargement).
+  String? _localSaveFeedbackPresetName;
+
   @override
   void initState() {
     super.initState();
@@ -114,6 +118,7 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
 
   void _openDraftForm() {
     setState(() {
+      _localSaveFeedbackPresetName = null;
       _panelMode = EnvironmentStudioPanelMode.createDraft;
       _draft = EnvironmentPresetDraft.empty();
       _draftFormEpoch++;
@@ -137,12 +142,13 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
     ProjectManifest nextManifest,
     EnvironmentPreset savedPreset,
   ) {
-    widget.onEnvironmentPresetSaved?.call(nextManifest, savedPreset);
+    widget.onEnvironmentPresetSaved!.call(nextManifest, savedPreset);
     setState(() {
       _panelMode = EnvironmentStudioPanelMode.browser;
       _selectedPresetId = savedPreset.id;
       _draft = EnvironmentPresetDraft.empty();
       _draftFormEpoch++;
+      _localSaveFeedbackPresetName = savedPreset.name;
     });
   }
 
@@ -294,9 +300,9 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
           ),
           child: Text(
             isDraft
-                ? 'Brouillon : vous pouvez enregistrer le preset dans le projet '
-                    '(mémoire de l’éditeur uniquement, pas de fichier project.json). '
-                    'La sauvegarde disque et la génération sur carte restent à venir.'
+                ? 'Brouillon : utilisez « Ajouter au projet en mémoire » pour intégrer '
+                    'le preset au manifest en session. Aucune sauvegarde disque automatique. '
+                    'La génération sur carte reste à venir.'
                 : 'Lecture seule sur les presets existants — édition d’un preset '
                     'existant et génération sur carte arrivent dans les prochains lots.',
             key: const Key('environment-studio-read-only-banner'),
@@ -329,8 +335,8 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
         children: [
           Text(
             'Aucun preset d’environnement pour le moment.\n'
-            'Utilisez « Préparer un preset », puis « Enregistrer dans le projet » '
-            '(mémoire de session, sans écriture disque automatique).',
+            'Utilisez « Préparer un preset », puis « Ajouter au projet en mémoire » '
+            '(aucune écriture disque tant que vous n’avez pas sauvegardé le projet).',
             key: const Key('environment-studio-empty-presets'),
             textAlign: TextAlign.center,
             style: TextStyle(
@@ -354,50 +360,63 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
   ) {
     final selected = _selectedPreset(presets);
 
-    return Row(
+    return Column(
       crossAxisAlignment: CrossAxisAlignment.stretch,
       children: [
-        SizedBox(
-          width: 300,
-          child: EnvironmentPresetList(
-            presets: presets,
-            selectedPresetId: _selectedPresetId,
-            report: report,
-            onSelect: (id) => setState(() => _selectedPresetId = id),
+        if (_localSaveFeedbackPresetName != null) ...[
+          EnvironmentPresetSaveFeedback(
+            presetName: _localSaveFeedbackPresetName!,
           ),
-        ),
-        const SizedBox(width: 16),
+          const SizedBox(height: 12),
+        ],
         Expanded(
-          child: DecoratedBox(
-            decoration: BoxDecoration(
-              color: EditorChrome.chipFill(context),
-              borderRadius: BorderRadius.circular(12),
-              border: Border.all(
-                color: CupertinoColors.separator.resolveFrom(context),
+          child: Row(
+            crossAxisAlignment: CrossAxisAlignment.stretch,
+            children: [
+              SizedBox(
+                width: 300,
+                child: EnvironmentPresetList(
+                  presets: presets,
+                  selectedPresetId: _selectedPresetId,
+                  report: report,
+                  onSelect: (id) => setState(() => _selectedPresetId = id),
+                ),
               ),
-            ),
-            child: selected == null
-                ? Center(
-                    child: Text(
-                      'Preset sélectionné introuvable.',
-                      key: const Key('environment-studio-preset-missing'),
-                      style: TextStyle(
-                        color: subtle,
-                        fontSize: 14,
-                        fontWeight: FontWeight.w600,
-                      ),
-                    ),
-                  )
-                : SingleChildScrollView(
-                    key: const Key('environment-studio-detail-scroll'),
-                    padding: const EdgeInsets.all(20),
-                    child: EnvironmentPresetDetail(
-                      preset: selected,
-                      report: report,
-                      labelColor: label,
-                      subtleColor: subtle,
+              const SizedBox(width: 16),
+              Expanded(
+                child: DecoratedBox(
+                  decoration: BoxDecoration(
+                    color: EditorChrome.chipFill(context),
+                    borderRadius: BorderRadius.circular(12),
+                    border: Border.all(
+                      color: CupertinoColors.separator.resolveFrom(context),
                     ),
                   ),
+                  child: selected == null
+                      ? Center(
+                          child: Text(
+                            'Preset sélectionné introuvable.',
+                            key: const Key('environment-studio-preset-missing'),
+                            style: TextStyle(
+                              color: subtle,
+                              fontSize: 14,
+                              fontWeight: FontWeight.w600,
+                            ),
+                          ),
+                        )
+                      : SingleChildScrollView(
+                          key: const Key('environment-studio-detail-scroll'),
+                          padding: const EdgeInsets.all(20),
+                          child: EnvironmentPresetDetail(
+                            preset: selected,
+                            report: report,
+                            labelColor: label,
+                            subtleColor: subtle,
+                          ),
+                        ),
+                ),
+              ),
+            ],
           ),
         ),
       ],
diff --git a/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart b/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
index 746ee2b2..73d1e885 100644
--- a/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
+++ b/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
@@ -56,6 +56,9 @@ class _EnvironmentPresetDraftFormState
   late final TextEditingController _categoryCtrl;
   late final TextEditingController _sortCtrl;
 
+  /// Lot 17 : échec du callback parent ou exception build/upsert après validation.
+  String? _saveErrorMessage;
+
   @override
   void initState() {
     super.initState();
@@ -94,6 +97,9 @@ class _EnvironmentPresetDraftFormState
     List<EnvironmentPaletteItemDraft>? palette,
     EnvironmentGenerationParamsDraft? defaultParams,
   }) {
+    if (_saveErrorMessage != null) {
+      setState(() => _saveErrorMessage = null);
+    }
     final so = int.tryParse(_sortCtrl.text.trim());
     widget.onChanged(
       EnvironmentPresetDraft(
@@ -134,6 +140,7 @@ class _EnvironmentPresetDraftFormState
     if (save == null) {
       return;
     }
+    setState(() => _saveErrorMessage = null);
     final draft = _draftFromControllers();
     final validation = validateEnvironmentPresetDraft(
       draft,
@@ -143,12 +150,21 @@ class _EnvironmentPresetDraftFormState
     if (validation.hasErrors) {
       return;
     }
-    final preset = buildEnvironmentPresetFromDraft(draft);
-    final nextManifest = upsertProjectEnvironmentPreset(
-      widget.manifest,
-      preset,
-    );
-    save(nextManifest, preset);
+    try {
+      final preset = buildEnvironmentPresetFromDraft(draft);
+      final nextManifest = upsertProjectEnvironmentPreset(
+        widget.manifest,
+        preset,
+      );
+      save(nextManifest, preset);
+    } catch (e, st) {
+      debugPrint('EnvironmentPresetDraftForm: ajout mémoire impossible: $e');
+      debugPrint('$st');
+      setState(() {
+        _saveErrorMessage =
+            'Impossible d’ajouter le preset au projet en mémoire.';
+      });
+    }
   }
 
   @override
@@ -195,9 +211,9 @@ class _EnvironmentPresetDraftFormState
           ),
           const SizedBox(height: 10),
           Text(
-            'Remplissez le brouillon puis « Enregistrer dans le projet » pour '
-            'l’ajouter au manifest en mémoire (marque le projet modifié ; '
-            'aucune écriture disque automatique).',
+            'Remplissez le brouillon puis « Ajouter au projet en mémoire » pour '
+            'l’intégrer au manifest de la session (projet marqué modifié ; '
+            'aucune sauvegarde disque automatique).',
             key: const Key('environment-studio-draft-form-intro'),
             style: TextStyle(
               color: subtle,
@@ -275,7 +291,7 @@ class _EnvironmentPresetDraftFormState
           const SizedBox(height: 8),
           Text(
             'Les éléments doivent exister dans le projet ; ils sont copiés dans le '
-            'preset lors de l’enregistrement.',
+            'preset lors de l’ajout en mémoire.',
             key: const Key('environment-studio-draft-palette-local-note'),
             style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
           ),
@@ -330,7 +346,7 @@ class _EnvironmentPresetDraftFormState
           if (widget.validation.hasErrors) ...[
             const SizedBox(height: 10),
             Text(
-              'Corrigez les erreurs du brouillon pour l’enregistrer dans le projet.',
+              'Corrigez les erreurs du brouillon pour l’ajouter au projet.',
               key: const Key('environment-studio-draft-save-disabled-hint'),
               style: TextStyle(
                 color: CupertinoColors.systemOrange.resolveFrom(context),
@@ -340,6 +356,33 @@ class _EnvironmentPresetDraftFormState
               ),
             ),
           ],
+          if (widget.validation.hasWarnings &&
+              !widget.validation.hasErrors) ...[
+            const SizedBox(height: 10),
+            Text(
+              'Les avertissements ne bloquent pas l’ajout au projet.',
+              key: const Key('environment-studio-draft-save-warnings-hint'),
+              style: TextStyle(
+                color: CupertinoColors.systemYellow.resolveFrom(context),
+                fontSize: 12,
+                fontWeight: FontWeight.w600,
+                height: 1.35,
+              ),
+            ),
+          ],
+          if (_saveErrorMessage != null) ...[
+            const SizedBox(height: 10),
+            Text(
+              _saveErrorMessage!,
+              key: const Key('environment-studio-draft-save-error-message'),
+              style: TextStyle(
+                color: CupertinoColors.systemRed.resolveFrom(context),
+                fontSize: 12,
+                fontWeight: FontWeight.w600,
+                height: 1.35,
+              ),
+            ),
+          ],
           const SizedBox(height: 24),
           Wrap(
             spacing: 8,
@@ -364,14 +407,14 @@ class _EnvironmentPresetDraftFormState
                 padding:
                     const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                 onPressed: canSaveToProject ? _saveDraftToProject : null,
-                child: const Text('Enregistrer dans le projet'),
+                child: const Text('Ajouter au projet en mémoire'),
               ),
             ],
           ),
           if (widget.onEnvironmentPresetSaved == null) ...[
             const SizedBox(height: 8),
             Text(
-              'Enregistrement indisponible dans ce contexte.',
+              'Ajout au projet indisponible dans ce contexte.',
               key: const Key('environment-studio-draft-save-unavailable-note'),
               style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
             ),
diff --git a/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart b/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart
index 659c8ebe..60edeefa 100644
--- a/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart
+++ b/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart
@@ -10,9 +10,9 @@ import 'package:map_editor/src/features/environment_studio/environment_studio_pa
 import '../shell_chrome_test_harness.dart';
 
 void main() {
-  group('EnvironmentPresetDraftForm — Enregistrer dans le projet', () {
+  group('EnvironmentPresetDraftForm — ajout mémoire (Lot 17)', () {
     testWidgets(
-      'brouillon initial invalide : bouton désactivé + aide visible',
+      'brouillon initial invalide : libellé bouton, aide, pas Save/Create/Generate',
       (tester) async {
         await _pumpPanel(
           tester,
@@ -23,6 +23,10 @@ void main() {
             .tap(find.byKey(const Key('environment-studio-open-draft')));
         await tester.pumpAndSettle();
 
+        expect(find.text('Ajouter au projet en mémoire'), findsOneWidget);
+        expect(find.textContaining('Save'), findsNothing);
+        expect(find.textContaining('Create'), findsNothing);
+        expect(find.textContaining('Generate'), findsNothing);
         expect(
           find.byKey(const Key('environment-studio-draft-save-project')),
           findsOneWidget,
@@ -37,7 +41,7 @@ void main() {
         );
         expect(
           find.text(
-            'Corrigez les erreurs du brouillon pour l’enregistrer dans le projet.',
+            'Corrigez les erreurs du brouillon pour l’ajouter au projet.',
           ),
           findsOneWidget,
         );
@@ -64,6 +68,10 @@ void main() {
               const Key('environment-studio-draft-save-unavailable-note')),
           findsOneWidget,
         );
+        expect(
+          find.text('Ajout au projet indisponible dans ce contexte.'),
+          findsOneWidget,
+        );
       },
     );
 
@@ -132,6 +140,31 @@ void main() {
         expect(find.byKey(const Key('environment-studio-preset-list')),
             findsOneWidget);
         expect(find.text('Prairie test'), findsWidgets);
+
+        expect(
+          find.byKey(const Key('environment-studio-post-save-local-feedback')),
+          findsOneWidget,
+        );
+        expect(
+          find.textContaining('ajouté au projet en mémoire'),
+          findsOneWidget,
+        );
+        expect(
+          find.textContaining('sauvegarder le projet'),
+          findsOneWidget,
+        );
+        expect(
+          (tester.widget<Text>(
+                  find.byKey(const Key('environment-studio-detail-id'))))
+              .data,
+          'meadow_new',
+        );
+        expect(
+          (tester.widget<Text>(
+                  find.byKey(const Key('environment-studio-detail-name'))))
+              .data,
+          'Prairie test',
+        );
       },
     );
 
@@ -263,6 +296,14 @@ void main() {
       await tester.pumpAndSettle();
 
       expect(find.textContaining('Template inconnu'), findsOneWidget);
+      expect(
+        find.byKey(const Key('environment-studio-draft-save-warnings-hint')),
+        findsOneWidget,
+      );
+      expect(
+        find.text('Les avertissements ne bloquent pas l’ajout au projet.'),
+        findsOneWidget,
+      );
       expect(
         tester
             .widget<CupertinoButton>(
@@ -277,6 +318,125 @@ void main() {
       await tester.pumpAndSettle();
       expect(calls, 1);
     });
+
+    testWidgets(
+      'ouvrir un nouveau brouillon efface le feedback local post-save',
+      (tester) async {
+        await _pumpPanel(
+          tester,
+          manifest: _manifest(elements: [_element(id: 'e1')]),
+          onSaved: (_, __) {},
+        );
+        await tester
+            .tap(find.byKey(const Key('environment-studio-open-draft')));
+        await tester.pumpAndSettle();
+        await tester.enterText(
+          find.byKey(const Key('environment-studio-draft-field-id')),
+          'fb_clear',
+        );
+        await tester.enterText(
+          find.byKey(const Key('environment-studio-draft-field-name')),
+          'NomFb',
+        );
+        await tester.enterText(
+          find.byKey(const Key('environment-studio-draft-field-template')),
+          't',
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
+        await tester.tap(
+          find.byKey(const Key('environment-studio-draft-save-project')),
+        );
+        await tester.pumpAndSettle();
+
+        expect(
+          find.byKey(const Key('environment-studio-post-save-local-feedback')),
+          findsOneWidget,
+        );
+
+        await tester
+            .tap(find.byKey(const Key('environment-studio-open-draft')));
+        await tester.pumpAndSettle();
+
+        expect(
+          find.byKey(const Key('environment-studio-post-save-local-feedback')),
+          findsNothing,
+        );
+      },
+    );
+
+    testWidgets(
+      'callback qui lève : formulaire visible, erreur locale, pas de browser',
+      (tester) async {
+        await _pumpPanel(
+          tester,
+          manifest: _manifest(elements: [_element(id: 'e1')]),
+          onSaved: (_, __) => throw StateError('simulé'),
+        );
+        await tester
+            .tap(find.byKey(const Key('environment-studio-open-draft')));
+        await tester.pumpAndSettle();
+        await tester.enterText(
+          find.byKey(const Key('environment-studio-draft-field-id')),
+          'boom_id',
+        );
+        await tester.enterText(
+          find.byKey(const Key('environment-studio-draft-field-name')),
+          'Boom',
+        );
+        await tester.enterText(
+          find.byKey(const Key('environment-studio-draft-field-template')),
+          't',
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
+        await tester.tap(
+          find.byKey(const Key('environment-studio-draft-save-project')),
+        );
+        await tester.pumpAndSettle();
+
+        expect(
+          find.byKey(const Key('environment-studio-draft-form-title')),
+          findsOneWidget,
+        );
+        expect(
+          find.byKey(const Key('environment-studio-draft-save-error-message')),
+          findsOneWidget,
+        );
+        expect(
+          find.text(
+            'Impossible d’ajouter le preset au projet en mémoire.',
+          ),
+          findsOneWidget,
+        );
+        expect(
+          (tester.widget<CupertinoTextField>(
+                  find.byKey(const Key('environment-studio-draft-field-id'))))
+              .controller
+              ?.text,
+          'boom_id',
+        );
+        expect(
+          find.byKey(const Key('environment-studio-preset-list')),
+          findsNothing,
+        );
+      },
+    );
   });
 
   group('EditorNotifier — applyInMemoryProjectManifest (Lot 16)', () {
@@ -414,6 +574,14 @@ void main() {
         );
         expect(find.byKey(const Key('environment-studio-preset-list')),
             findsOneWidget);
+        expect(
+          find.byKey(const Key('environment-studio-post-save-local-feedback')),
+          findsOneWidget,
+        );
+        expect(
+          find.textContaining('ajouté au projet en mémoire'),
+          findsOneWidget,
+        );
       },
     );
   });
diff --git a/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_save_feedback.dart b/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_save_feedback.dart
new file mode 100644
index 00000000..3b107f45
--- /dev/null
+++ b/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_save_feedback.dart
@@ -0,0 +1,60 @@
+import 'package:flutter/cupertino.dart';
+
+import '../../../ui/shared/cupertino_editor_widgets.dart';
+
+/// Retour visuel local après ajout d’un preset au manifest en mémoire (Lot 17).
+///
+/// Complète le [statusMessage] du shell sans le remplacer ; reste dans le panel.
+class EnvironmentPresetSaveFeedback extends StatelessWidget {
+  const EnvironmentPresetSaveFeedback({
+    super.key,
+    required this.presetName,
+  });
+
+  final String presetName;
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+    return DecoratedBox(
+      key: const Key('environment-studio-post-save-local-feedback'),
+      decoration: BoxDecoration(
+        color: EditorChrome.accentJade.withValues(alpha: 0.1),
+        borderRadius: BorderRadius.circular(10),
+        border: Border.all(
+          color: EditorChrome.accentJade.withValues(alpha: 0.4),
+        ),
+      ),
+      child: Padding(
+        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.stretch,
+          children: [
+            Text(
+              'Preset « $presetName » ajouté au projet en mémoire.',
+              key: const Key('environment-studio-post-save-line-1'),
+              style: TextStyle(
+                color: label,
+                fontSize: 13,
+                fontWeight: FontWeight.w700,
+                height: 1.35,
+              ),
+            ),
+            const SizedBox(height: 6),
+            Text(
+              'Projet modifié — pensez à sauvegarder le projet pour écrire sur disque.',
+              key: const Key('environment-studio-post-save-line-2'),
+              style: TextStyle(
+                color: subtle,
+                fontSize: 12,
+                fontWeight: FontWeight.w600,
+                height: 1.35,
+              ),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}

```

## 18. Auto-review

**Points solides** : distinction mémoire / disque sur trois niveaux (intro, bannière, feedback) ; catch borné ; tests couvrant throw et clear feedback.

**Points discutables** : libellé long ; `debugPrint` + stack en test (bruit contrôlé) ; `widget.onEnvironmentPresetSaved!.call` exige que le formulaire ne reçoive le handler que si le parent fournit un callback (inchangé Lot 16).

**Corrections après auto-review** : diff combiné dédoublonné pour le rapport ; bannière brouillon sans double phrase « sauvegarde disque ».

**Risques restants** : masquer une erreur de programmation dans le catch — acceptable ici pour robustesse UX ; en prod le `debugPrint` reste la trace.

**Regard critique sur le prompt** : le feedback local complète utilement le `statusMessage` sans le remplacer ; « Ajouter au projet en mémoire » est long mais conforme au brief ; clear du feedback à l’ouverture du brouillon évite les messages obsolètes.

### Réponses imposées (prompt §16)

- Libellé long mais nécessaire pour lever l’ambiguïté disque.
- Le feedback local ne remplace pas le `statusMessage` ; il cible l’espace Environment Studio.
- Le `catch` peut masquer des bugs : mitigé par `debugPrint` ; périmètre UX demandé.
- Clear du feedback à l’ouverture d’un nouveau brouillon : **oui**, règle retenue.
- Sauvegarde disque / générateur / EnvironmentLayer : **non touchés**.

## 19. Verdict

Statut du lot :

- [x] **Validé**

Résumé :

```text
Lot 17 livré : UX save clarifiée, feedback browser, erreurs callback, tests renforcés,
analyze vert, suite environment_studio 98 tests verts, flutter test map_editor 931 avec 34 échecs préexistants.
```

Prochain lot recommandé :

```text
Environment-18 — Environment Preset Edit Existing Draft V0
```

## Confirmations Evidence Pack

| Affirmation | Preuve |
|-------------|--------|
| Aucun `ProjectManifest` modèle modifié | `git diff` limité aux chemins Lot 17 |
| Aucun `MapLayer` modifié | Idem |
| `upsertProjectEnvironmentPreset` après validation sans erreurs | Inchangé ; try après `if (validation.hasErrors) return` |
| Pas de sauvegarde disque dans le flux Environment Studio | Grep §14 sans hit dans `environment_studio/` |
| Pas de `FileProjectRepository` / `saveProject` dans ce flux UI | Idem |
| Pas de générateur / `EnvironmentLayer` | Aucun fichier ajouté hors UX |
| Pas de `build_runner` / generated | Non exécuté |
| Pas de commit / git add / push | Non exécutés |
