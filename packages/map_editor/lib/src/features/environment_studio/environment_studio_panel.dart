import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'authoring/environment_preset_draft.dart';
import 'authoring/environment_preset_palette_use_cases.dart';
import 'authoring/environment_preset_tileset_compatibility.dart';
import 'environment_preset_memory_write_kind.dart';
import 'widgets/environment_palette_item_draft_editor.dart';
import 'widgets/environment_preset_detail.dart';
import 'widgets/environment_preset_draft_form.dart';
import 'widgets/environment_preset_list.dart';
import 'widgets/environment_preset_save_feedback.dart';

/// Modes locaux du panneau Environment Studio (Lot Environment-13, 18).
enum EnvironmentStudioPanelMode {
  /// Liste + détail des presets existants (non mutateur).
  browser,

  /// Formulaire de brouillon ; persistance manifest via callback parent (mémoire).
  createDraft,

  /// Brouillon prérempli depuis un preset existant ; id verrouillé (Lot 18).
  editDraft,
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

  /// Après validation sans erreur : manifest mis à jour + preset créé ou mis
  /// à jour ; le parent (ex. workspace) applique l’état éditeur ; pas d’I/O
  /// disque ici.
  final void Function(
    ProjectManifest nextManifest,
    EnvironmentPreset savedPreset,
    EnvironmentPresetMemoryWriteKind kind,
  )? onEnvironmentPresetSaved;

  @override
  State<EnvironmentStudioPanel> createState() => _EnvironmentStudioPanelState();
}

class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
  String? _selectedPresetId;
  EnvironmentStudioPanelMode _panelMode = EnvironmentStudioPanelMode.browser;
  EnvironmentPresetDraft _draft = EnvironmentPresetDraft.empty();
  int _draftFormEpoch = 0;

  /// Lot 18 : id du preset en cours d’édition (brouillon) ; `null` en création.
  String? _editingPresetId;

  /// Lot 17–18 : message local browser après écriture mémoire (pas au 1er chargement).
  String? _localSaveFeedbackPresetName;

  /// Lot 18 : dernier type d’écriture pour le feedback local (create/update).
  EnvironmentPresetMemoryWriteKind? _lastMemoryWriteKind;
  String? _paletteDraftPresetId;
  List<EnvironmentPaletteItemDraft> _paletteDraft = const [];
  String? _paletteSaveFeedbackPresetName;
  String? _paletteSaveErrorMessage;

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
      setState(() {
        _selectedPresetId = next;
        _clearPaletteDraft();
      });
    } else if (_paletteDraftPresetId != null &&
        !widget.manifest.environmentPresets.any(
          (preset) => preset.id == _paletteDraftPresetId,
        )) {
      setState(_clearPaletteDraft);
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
      _lastMemoryWriteKind = null;
      _paletteSaveFeedbackPresetName = null;
      _clearPaletteDraft();
      _editingPresetId = null;
      _panelMode = EnvironmentStudioPanelMode.createDraft;
      _draft = EnvironmentPresetDraft.empty();
      _draftFormEpoch++;
    });
  }

  void _openEditDraftFromPreset(EnvironmentPreset preset) {
    setState(() {
      _localSaveFeedbackPresetName = null;
      _lastMemoryWriteKind = null;
      _paletteSaveFeedbackPresetName = null;
      _clearPaletteDraft();
      _panelMode = EnvironmentStudioPanelMode.editDraft;
      _editingPresetId = preset.id;
      _draft = EnvironmentPresetDraft.fromPreset(preset);
      _draftFormEpoch++;
    });
  }

  void _closeDraftForm() {
    setState(() {
      _panelMode = EnvironmentStudioPanelMode.browser;
      _editingPresetId = null;
    });
  }

  void _resetDraft() {
    setState(() {
      if (_panelMode == EnvironmentStudioPanelMode.editDraft &&
          _editingPresetId != null) {
        EnvironmentPreset? source;
        for (final p in widget.manifest.environmentPresets) {
          if (p.id == _editingPresetId) {
            source = p;
            break;
          }
        }
        _draft = source != null
            ? EnvironmentPresetDraft.fromPreset(source)
            : EnvironmentPresetDraft.empty();
      } else {
        _draft = EnvironmentPresetDraft.empty();
      }
      _draftFormEpoch++;
    });
  }

  void _onEnvironmentPresetSavedInMemory(
    ProjectManifest nextManifest,
    EnvironmentPreset savedPreset,
    EnvironmentPresetMemoryWriteKind kind,
  ) {
    widget.onEnvironmentPresetSaved!.call(nextManifest, savedPreset, kind);
    setState(() {
      _panelMode = EnvironmentStudioPanelMode.browser;
      _selectedPresetId = savedPreset.id;
      _draft = EnvironmentPresetDraft.empty();
      _editingPresetId = null;
      _draftFormEpoch++;
      _localSaveFeedbackPresetName = savedPreset.name;
      _lastMemoryWriteKind = kind;
      _paletteSaveFeedbackPresetName = null;
    });
  }

  void _clearPaletteDraft() {
    _paletteDraftPresetId = null;
    _paletteDraft = const [];
    _paletteSaveErrorMessage = null;
  }

  void _openPaletteDraft(EnvironmentPreset preset) {
    setState(() {
      _paletteDraftPresetId = preset.id;
      _paletteDraft = _paletteDraftFromPreset(preset);
      _paletteSaveErrorMessage = null;
      _paletteSaveFeedbackPresetName = null;
      _localSaveFeedbackPresetName = null;
      _lastMemoryWriteKind = null;
    });
  }

  void _replacePaletteDraftItem(int index, EnvironmentPaletteItemDraft item) {
    setState(() {
      _paletteSaveErrorMessage = null;
      final next = List<EnvironmentPaletteItemDraft>.from(_paletteDraft);
      next[index] = item;
      _paletteDraft = List<EnvironmentPaletteItemDraft>.unmodifiable(next);
    });
  }

  void _removePaletteDraftItem(int index) {
    setState(() {
      _paletteSaveErrorMessage = null;
      final next = List<EnvironmentPaletteItemDraft>.from(_paletteDraft)
        ..removeAt(index);
      _paletteDraft = List<EnvironmentPaletteItemDraft>.unmodifiable(next);
    });
  }

  void _addPaletteDraftItem() {
    setState(() {
      _paletteSaveErrorMessage = null;
      _paletteDraft = List<EnvironmentPaletteItemDraft>.unmodifiable([
        ..._paletteDraft,
        EnvironmentPaletteItemDraft(elementId: '', weight: 1),
      ]);
    });
  }

  void _cancelPaletteDraft() {
    setState(_clearPaletteDraft);
  }

  void _savePaletteDraft(EnvironmentPreset preset) {
    final save = widget.onEnvironmentPresetSaved;
    if (save == null) {
      return;
    }
    final issues = _paletteDraftIssues(_paletteDraft, widget.manifest.elements);
    if (issues.isNotEmpty) {
      return;
    }
    try {
      final palette = _paletteItemsFromDraft(_paletteDraft);
      final result = const UpdateEnvironmentPresetPaletteUseCase()(
        manifest: widget.manifest,
        presetId: preset.id,
        palette: palette,
      );
      save(
        result.manifest,
        result.updatedPreset,
        EnvironmentPresetMemoryWriteKind.update,
      );
      setState(() {
        _selectedPresetId = result.updatedPreset.id;
        _clearPaletteDraft();
        _paletteSaveFeedbackPresetName = result.updatedPreset.name;
      });
    } catch (_) {
      setState(() {
        _paletteSaveErrorMessage =
            'Impossible d’enregistrer la palette dans le projet en mémoire.';
      });
    }
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

    final isDraftMode = _panelMode == EnvironmentStudioPanelMode.createDraft ||
        _panelMode == EnvironmentStudioPanelMode.editDraft;
    final draftValidation = isDraftMode
        ? validateEnvironmentPresetDraft(
            _draft,
            manifest: widget.manifest,
            knownTemplateIds: widget.knownTemplateIds,
            existingPresetId: _panelMode == EnvironmentStudioPanelMode.editDraft
                ? _editingPresetId
                : null,
          )
        : null;

    return DecoratedBox(
      key: const Key('environment-studio-shell'),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.accentJade.withValues(alpha: 0.05),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, label, subtle, n),
              const SizedBox(height: 12),
              _buildInfoBanner(context),
              const SizedBox(height: 14),
              if (_panelMode == EnvironmentStudioPanelMode.browser && n == 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: _newPresetButton(),
                ),
              if (_panelMode == EnvironmentStudioPanelMode.browser && n == 0)
                const SizedBox(height: 10),
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
                      s,
                    ),
                  )
              else
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: EditorChrome.chipFill(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CupertinoColors.separator.resolveFrom(context),
                      ),
                    ),
                    child: EnvironmentPresetDraftForm(
                      key: ValueKey<int>(_draftFormEpoch),
                      manifest: widget.manifest,
                      knownTemplateIds: widget.knownTemplateIds,
                      draft: _draft,
                      existingPresetId: _editingPresetId,
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
            ],
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
    return Row(
      key: const Key('environment-studio-header'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: EditorChrome.accentJade.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: EditorChrome.accentJade.withValues(alpha: 0.42),
            ),
          ),
          child: const Icon(
            CupertinoIcons.tree,
            color: EditorChrome.accentJade,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Environment Studio',
                key: const Key('environment-studio-title'),
                style: TextStyle(
                  color: label,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Presets d’environnements réutilisables',
                style: TextStyle(
                  color: subtle,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          key: const Key('environment-studio-preset-count'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: EditorChrome.badgeFill(context),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: EditorChrome.accentWarm.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            presetCount == 1 ? '1 preset' : '$presetCount presets',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    return Container(
      key: const Key('environment-studio-info-banner'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: EditorChrome.accentJade.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.accentJade.withValues(alpha: 0.35),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            CupertinoIcons.info_circle_fill,
            color: EditorChrome.accentJade,
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Les presets se préparent ici. La peinture et la génération se font dans l’éditeur de carte.',
              style: TextStyle(
                color: EditorChrome.accentJade,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _newPresetButton() {
    return CupertinoButton(
      key: const Key('environment-studio-open-draft'),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      onPressed: _openDraftForm,
      child: const Text('Nouveau preset'),
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
            'Utilisez « Nouveau preset », puis « Ajouter au projet en mémoire » '
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
    EnvironmentAuthoringDiagnosticsSummary summary,
  ) {
    final selected = _selectedPreset(presets);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_localSaveFeedbackPresetName != null &&
            _lastMemoryWriteKind != null) ...[
          EnvironmentPresetSaveFeedback(
            presetName: _localSaveFeedbackPresetName!,
            writeKind: _lastMemoryWriteKind!,
          ),
          const SizedBox(height: 12),
        ],
        if (_paletteSaveFeedbackPresetName != null) ...[
          _buildPaletteSaveFeedback(context, _paletteSaveFeedbackPresetName!),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: Row(
            key: const Key('environment-studio-main-layout'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 320,
                child: DecoratedBox(
                  key: const Key('environment-studio-preset-column'),
                  decoration: BoxDecoration(
                    color: EditorChrome.chipFill(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CupertinoColors.separator.resolveFrom(context),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Presets',
                                style: TextStyle(
                                  color: label,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            _newPresetButton(),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: EnvironmentPresetList(
                            presets: presets,
                            selectedPresetId: _selectedPresetId,
                            report: report,
                            onSelect: (id) => setState(() {
                              _selectedPresetId = id;
                              _clearPaletteDraft();
                              _paletteSaveFeedbackPresetName = null;
                            }),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildGlobalDiagnostics(
                            context, label, subtle, summary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DecoratedBox(
                  key: const Key('environment-studio-editor-panel'),
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
                          child: _paletteDraftPresetId == selected.id
                              ? _buildPaletteDraftDetail(
                                  context,
                                  selected,
                                  label,
                                  subtle,
                                )
                              : EnvironmentPresetDetail(
                                  preset: selected,
                                  projectElements: widget.manifest.elements,
                                  report: report,
                                  labelColor: label,
                                  subtleColor: subtle,
                                  onEditAsDraft: widget
                                              .onEnvironmentPresetSaved ==
                                          null
                                      ? null
                                      : () =>
                                          _openEditDraftFromPreset(selected),
                                  onEditPalette:
                                      widget.onEnvironmentPresetSaved == null
                                          ? null
                                          : () => _openPaletteDraft(selected),
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

  Widget _buildPaletteSaveFeedback(BuildContext context, String presetName) {
    return Container(
      key: const Key('environment-studio-palette-save-feedback'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.accentJade.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.accentJade.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        'Palette enregistrée dans le projet en mémoire. Preset : $presetName.',
        style: const TextStyle(
          color: EditorChrome.accentJade,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildPaletteDraftDetail(
    BuildContext context,
    EnvironmentPreset preset,
    Color label,
    Color subtle,
  ) {
    final sourceDraft = _paletteDraftFromPreset(preset);
    final isDirty = !_paletteDraftEquals(_paletteDraft, sourceDraft);
    final issues = _paletteDraftIssues(_paletteDraft, widget.manifest.elements);
    final compatibility = buildEnvironmentPresetTilesetCompatibility(
      paletteElementIds: [
        for (final item in _paletteDraft) item.elementId,
      ],
      projectElements: widget.manifest.elements,
    );
    final canSave = widget.onEnvironmentPresetSaved != null &&
        isDirty &&
        issues.isEmpty &&
        _paletteDraft.isNotEmpty;
    final canCancel = isDirty;

    return Column(
      key: const Key('environment-studio-palette-draft-root'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Palette du preset',
          style: TextStyle(
            color: label,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isDirty
              ? 'Palette modifiée — enregistrez pour appliquer au projet.'
              : 'Brouillon non enregistré',
          style: TextStyle(
            color: isDirty ? EditorChrome.accentWarm : subtle,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _buildPaletteDraftTilesetBlock(context, compatibility, label, subtle),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: CupertinoButton(
            key: const Key('environment-studio-draft-palette-add-item'),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            onPressed: _addPaletteDraftItem,
            child: const Text('Ajouter un élément'),
          ),
        ),
        const SizedBox(height: 10),
        if (_paletteDraft.isEmpty)
          Text(
            'Aucun item pour l’instant.',
            key: const Key('environment-studio-draft-palette-no-items'),
            style: TextStyle(color: subtle, fontSize: 13),
          )
        else
          for (var i = 0; i < _paletteDraft.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i < _paletteDraft.length - 1 ? 12 : 0,
              ),
              child: EnvironmentPaletteItemDraftEditor(
                key: ValueKey('palette-draft-slot-$i'),
                index: i,
                item: _paletteDraft[i],
                projectElements: compatibility.availableCompatibleElements,
                onChanged: (item) => _replacePaletteDraftItem(i, item),
                onRemove: () => _removePaletteDraftItem(i),
              ),
            ),
        if (issues.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildPaletteDraftIssues(context, issues),
        ],
        if (_paletteSaveErrorMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            _paletteSaveErrorMessage!,
            key: const Key('environment-studio-palette-save-error'),
            style: TextStyle(
              color: CupertinoColors.systemRed.resolveFrom(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            CupertinoButton(
              key: const Key('environment-studio-palette-save'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              onPressed: canSave ? () => _savePaletteDraft(preset) : null,
              child: const Text('Enregistrer la palette'),
            ),
            CupertinoButton(
              key: const Key('environment-studio-palette-cancel'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              onPressed: canCancel ? _cancelPaletteDraft : null,
              child: const Text('Annuler les changements'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaletteDraftTilesetBlock(
    BuildContext context,
    EnvironmentPresetTilesetCompatibility compatibility,
    Color label,
    Color subtle,
  ) {
    final source = compatibility.sourceTilesetId;
    return DecoratedBox(
      key: const Key('environment-studio-palette-draft-tileset-source'),
      decoration: BoxDecoration(
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tileset source',
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              source ?? 'Tileset source non défini',
              key: const Key('environment-studio-palette-draft-source-value'),
              style: TextStyle(
                color: label,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              source == null
                  ? 'Ajoutez un premier élément : il définira la source du brouillon.'
                  : 'Seuls les éléments compatibles avec ce tileset sont proposés.',
              style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
            ),
            const SizedBox(height: 8),
            const Text(
              'Protection anti-mélange de tilesets activée',
              style: TextStyle(
                color: EditorChrome.accentWarm,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (compatibility.hasMixedTilesets) ...[
              const SizedBox(height: 8),
              Text(
                'Ce preset contient des éléments provenant de plusieurs tilesets.',
                style: TextStyle(
                  color: CupertinoColors.systemOrange.resolveFrom(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaletteDraftIssues(BuildContext context, List<String> issues) {
    return DecoratedBox(
      key: const Key('environment-studio-palette-draft-issues'),
      decoration: BoxDecoration(
        color: CupertinoColors.systemOrange
            .resolveFrom(context)
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: CupertinoColors.systemOrange
              .resolveFrom(context)
              .withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final issue in issues)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  issue,
                  style: TextStyle(
                    color: CupertinoColors.systemOrange.resolveFrom(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
          ],
        ),
      ),
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
}

List<EnvironmentPaletteItemDraft> _paletteDraftFromPreset(
  EnvironmentPreset preset,
) {
  return List<EnvironmentPaletteItemDraft>.unmodifiable([
    for (final item in preset.palette)
      EnvironmentPaletteItemDraft(
        elementId: item.elementId,
        weight: item.weight,
        collisionMode: item.collisionMode,
        tags: item.tags,
      ),
  ]);
}

List<EnvironmentPaletteItem> _paletteItemsFromDraft(
  List<EnvironmentPaletteItemDraft> draft,
) {
  return [
    for (final item in draft)
      EnvironmentPaletteItem(
        elementId: item.elementId,
        weight: item.weight,
        collisionMode: item.collisionMode,
        tags: item.tags,
      ),
  ];
}

bool _paletteDraftEquals(
  List<EnvironmentPaletteItemDraft> a,
  List<EnvironmentPaletteItemDraft> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

List<String> _paletteDraftIssues(
  List<EnvironmentPaletteItemDraft> draft,
  List<ProjectElementEntry> projectElements,
) {
  final issues = <String>[];
  if (draft.isEmpty) {
    issues.add('Palette vide');
  }
  final elementsById = <String, ProjectElementEntry>{
    for (final element in projectElements) element.id: element,
  };
  final seen = <String>{};
  final duplicateIds = <String>{};
  for (final item in draft) {
    final elementId = item.elementId.trim();
    if (elementId.isEmpty) {
      issues.add('Élément de palette vide');
    } else {
      if (!seen.add(elementId)) {
        duplicateIds.add(elementId);
      }
      if (!elementsById.containsKey(elementId)) {
        issues.add('Élément introuvable : $elementId');
      }
    }
    if (item.weight < 1) {
      issues.add('Poids invalide');
    }
    for (final tag in item.tags) {
      if (tag.trim().isEmpty) {
        issues.add('Tag vide');
      }
    }
  }
  for (final id in duplicateIds) {
    issues.add('Élément dupliqué : $id');
  }
  final compatibility = buildEnvironmentPresetTilesetCompatibility(
    paletteElementIds: [
      for (final item in draft) item.elementId,
    ],
    projectElements: projectElements,
  );
  for (final elementId in compatibility.unknownTilesetElementIds) {
    issues.add('Tileset source introuvable : $elementId');
  }
  if (compatibility.hasMixedTilesets) {
    issues.add(
      'Tilesets mélangés : ce preset mélange plusieurs tilesets.',
    );
  }
  return List<String>.unmodifiable(issues.toSet());
}
