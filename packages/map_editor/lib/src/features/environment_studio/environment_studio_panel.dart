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

  /// Formulaire de brouillon sans persistance manifest.
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
/// ([EnvironmentPresetDraft]) sans [upsertProjectEnvironmentPreset] ni
/// [buildEnvironmentPresetFromDraft] côté UI.
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
            knownTemplateIds: const <String>{},
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
                          draft: _draft,
                          validation: draftValidation!,
                          projectElements: widget.manifest.elements,
                          onChanged: (d) => setState(() => _draft = d),
                          onCancel: _closeDraftForm,
                          onReset: _resetDraft,
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
                ? 'Brouillon local — aucune écriture dans le projet. '
                    'Création réelle et palette éditables arrivent dans les prochains lots.'
                : 'Lecture seule sur les presets existants — édition manifest et '
                    'génération arrivent dans les prochains lots.',
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
            'Les presets seront enregistrés dans le projet dans un prochain lot.',
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
