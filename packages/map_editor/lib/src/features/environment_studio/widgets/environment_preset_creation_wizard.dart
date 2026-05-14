import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/shared/cupertino_editor_widgets.dart';
import '../authoring/environment_preset_draft.dart';
import '../authoring/environment_preset_tileset_compatibility.dart';
import '../environment_preset_memory_write_kind.dart';
import 'environment_palette_item_draft_editor.dart';
import 'environment_preset_draft_validation_view.dart';

class EnvironmentPresetCreationWizard extends StatefulWidget {
  const EnvironmentPresetCreationWizard({
    super.key,
    required this.manifest,
    this.knownTemplateIds = const <String>{},
    required this.draft,
    required this.onChanged,
    required this.onCancel,
    required this.onReset,
    this.onEnvironmentPresetSaved,
  });

  final ProjectManifest manifest;
  final Set<String> knownTemplateIds;
  final EnvironmentPresetDraft draft;
  final ValueChanged<EnvironmentPresetDraft> onChanged;
  final VoidCallback onCancel;
  final VoidCallback onReset;
  final void Function(
    ProjectManifest nextManifest,
    EnvironmentPreset savedPreset,
    EnvironmentPresetMemoryWriteKind kind,
  )? onEnvironmentPresetSaved;

  @override
  State<EnvironmentPresetCreationWizard> createState() =>
      _EnvironmentPresetCreationWizardState();
}

class _EnvironmentPresetCreationWizardState
    extends State<EnvironmentPresetCreationWizard> {
  late final TextEditingController _idCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _templateCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _sortCtrl;
  late final TextEditingController _densityCtrl;
  late final TextEditingController _variationCtrl;
  late final TextEditingController _edgeDensityCtrl;
  late final TextEditingController _minSpacingCtrl;
  late final TextEditingController _filterCtrl;

  int _step = 0;
  String? _selectedTilesetId;
  String? _tilesetChangeMessage;
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
    _densityCtrl = TextEditingController(
      text: _formatDouble(d.defaultParams.density),
    );
    _variationCtrl = TextEditingController(
      text: _formatDouble(d.defaultParams.variation),
    );
    _edgeDensityCtrl = TextEditingController(
      text: _formatDouble(d.defaultParams.edgeDensity),
    );
    _minSpacingCtrl = TextEditingController(
      text: d.defaultParams.minSpacingCells.toString(),
    );
    _filterCtrl = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant EnvironmentPresetCreationWizard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft != widget.draft) {
      _syncControllers(widget.draft);
    }
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _templateCtrl.dispose();
    _categoryCtrl.dispose();
    _sortCtrl.dispose();
    _densityCtrl.dispose();
    _variationCtrl.dispose();
    _edgeDensityCtrl.dispose();
    _minSpacingCtrl.dispose();
    _filterCtrl.dispose();
    super.dispose();
  }

  void _syncControllers(EnvironmentPresetDraft draft) {
    _syncText(_idCtrl, draft.id);
    _syncText(_nameCtrl, draft.name);
    _syncText(_templateCtrl, draft.templateId);
    _syncText(_categoryCtrl, draft.categoryId ?? '');
    _syncText(_sortCtrl, draft.sortOrder.toString());
    _syncText(_densityCtrl, _formatDouble(draft.defaultParams.density));
    _syncText(_variationCtrl, _formatDouble(draft.defaultParams.variation));
    _syncText(_edgeDensityCtrl, _formatDouble(draft.defaultParams.edgeDensity));
    _syncText(_minSpacingCtrl, draft.defaultParams.minSpacingCells.toString());
  }

  void _syncText(TextEditingController controller, String value) {
    if (controller.text != value) {
      controller.text = value;
    }
  }

  static String _formatDouble(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  static String _slug(String value) {
    final lower = value.trim().toLowerCase();
    final normalized = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final trimmed = normalized.replaceAll(RegExp(r'^_+|_+$'), '');
    return trimmed.isEmpty ? 'environment_preset' : trimmed;
  }

  EnvironmentPresetDraft _draftFromControllers({
    List<EnvironmentPaletteItemDraft>? palette,
    EnvironmentGenerationParamsDraft? defaultParams,
  }) {
    final sort = int.tryParse(_sortCtrl.text.trim());
    return EnvironmentPresetDraft(
      id: _idCtrl.text,
      name: _nameCtrl.text,
      templateId: _templateCtrl.text,
      palette: palette ?? widget.draft.palette,
      defaultParams: defaultParams ?? widget.draft.defaultParams,
      categoryId: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text,
      sortOrder: sort ?? widget.draft.sortOrder,
    );
  }

  void _emit({
    List<EnvironmentPaletteItemDraft>? palette,
    EnvironmentGenerationParamsDraft? defaultParams,
  }) {
    if (_saveErrorMessage != null) {
      setState(() => _saveErrorMessage = null);
    }
    widget.onChanged(
      _draftFromControllers(palette: palette, defaultParams: defaultParams),
    );
  }

  List<ProjectTilesetEntry> _sortedTilesets() {
    final sorted = [...widget.manifest.tilesets]..sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        if (order != 0) {
          return order;
        }
        return a.id.compareTo(b.id);
      });
    return sorted;
  }

  List<ProjectElementEntry> _compatibleElements(String tilesetId) {
    final elements = [
      for (final element in widget.manifest.elements)
        if (resolveEnvironmentPresetElementTilesetId(element) == tilesetId)
          element,
    ]..sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        if (order != 0) {
          return order;
        }
        return a.id.compareTo(b.id);
      });
    return elements;
  }

  void _selectTileset(ProjectTilesetEntry tileset) {
    final previous = _selectedTilesetId;
    final changed = previous != null && previous != tileset.id;
    final shouldClearPalette = changed && widget.draft.palette.isNotEmpty;
    final slug = _slug(tileset.id.isNotEmpty ? tileset.id : tileset.name);
    setState(() {
      _selectedTilesetId = tileset.id;
      _tilesetChangeMessage = shouldClearPalette
          ? 'Le changement de tileset a vidé la palette du brouillon pour éviter tout mélange.'
          : null;
      _saveErrorMessage = null;
    });
    if (_idCtrl.text.trim().isEmpty) {
      _idCtrl.text = '${slug}_environment';
    }
    if (_nameCtrl.text.trim().isEmpty) {
      _nameCtrl.text =
          tileset.name.trim().isEmpty ? 'Preset ${tileset.id}' : tileset.name;
    }
    if (_templateCtrl.text.trim().isEmpty) {
      _templateCtrl.text = '${slug}_environment';
    }
    if (shouldClearPalette) {
      widget.onChanged(_draftFromControllers(palette: const []));
    } else {
      _emit();
    }
  }

  void _goToElementsStep() {
    if (_selectedTilesetId == null) {
      return;
    }
    setState(() => _step = 1);
  }

  void _goToTilesetStep() {
    setState(() => _step = 0);
  }

  void _addPaletteItem(ProjectElementEntry element) {
    if (_selectedTilesetId == null) {
      return;
    }
    if (resolveEnvironmentPresetElementTilesetId(element) !=
        _selectedTilesetId) {
      return;
    }
    if (widget.draft.palette.any((item) => item.elementId == element.id)) {
      return;
    }
    final next = [
      ...widget.draft.palette,
      EnvironmentPaletteItemDraft(
        elementId: element.id,
        weight: 1,
        collisionMode: EnvironmentCollisionMode.useElementDefault,
        tags: element.tags.toSet(),
      ),
    ];
    _emit(palette: next);
  }

  void _addEmptyPaletteItem() {
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

  List<String> _sourceGuardIssues(EnvironmentPresetDraft draft) {
    final source = _selectedTilesetId;
    if (source == null) {
      return const ['Choisissez un tileset source.'];
    }
    final elementsById = {
      for (final element in widget.manifest.elements) element.id: element,
    };
    final issues = <String>[];
    for (final item in draft.palette) {
      final elementId = item.elementId.trim();
      if (elementId.isEmpty) {
        continue;
      }
      final element = elementsById[elementId];
      if (element == null) {
        continue;
      }
      final tilesetId = resolveEnvironmentPresetElementTilesetId(element);
      if (tilesetId == null) {
        issues.add('Élément sans tileset source fiable : $elementId.');
      } else if (tilesetId != source) {
        issues.add(
          'Élément incompatible avec le tileset source "$source" : $elementId.',
        );
      }
    }
    return issues;
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
    final sourceIssues = _sourceGuardIssues(draft);
    if (validation.hasErrors || sourceIssues.isNotEmpty) {
      return;
    }
    try {
      final preset = buildEnvironmentPresetFromDraft(draft);
      final nextManifest = upsertProjectEnvironmentPreset(
        widget.manifest,
        preset,
      );
      save(nextManifest, preset, EnvironmentPresetMemoryWriteKind.create);
    } catch (_) {
      setState(() {
        _saveErrorMessage =
            'Impossible d’appliquer le preset au projet en mémoire.';
      });
    }
  }

  void _emitDensity(String raw) {
    final value = double.tryParse(raw.trim());
    if (value == null) {
      return;
    }
    _emit(defaultParams: widget.draft.defaultParams.copyWith(density: value));
  }

  void _emitVariation(String raw) {
    final value = double.tryParse(raw.trim());
    if (value == null) {
      return;
    }
    _emit(defaultParams: widget.draft.defaultParams.copyWith(variation: value));
  }

  void _emitEdgeDensity(String raw) {
    final value = double.tryParse(raw.trim());
    if (value == null) {
      return;
    }
    _emit(
      defaultParams: widget.draft.defaultParams.copyWith(edgeDensity: value),
    );
  }

  void _emitMinSpacing(String raw) {
    final value = int.tryParse(raw.trim());
    if (value == null) {
      return;
    }
    _emit(
      defaultParams:
          widget.draft.defaultParams.copyWith(minSpacingCells: value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return SingleChildScrollView(
      key: const Key('environment-studio-creation-wizard'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWizardHeader(context, label, subtle),
          const SizedBox(height: 16),
          if (_step == 0)
            _buildTilesetStep(context, label, subtle)
          else
            _buildElementsStep(context, label, subtle),
        ],
      ),
    );
  }

  Widget _buildWizardHeader(BuildContext context, Color label, Color subtle) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Nouveau preset d’environnement',
                    key: const Key('environment-studio-draft-form-title'),
                    style: TextStyle(
                      color: label,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                CupertinoButton(
                  key: const Key('environment-studio-draft-cancel'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  onPressed: widget.onCancel,
                  child: const Text('Retour au browser'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                key: const Key('environment-studio-draft-local-badge'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: EditorChrome.accentWarm.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: EditorChrome.accentWarm.withValues(alpha: 0.45),
                  ),
                ),
                child: const Text(
                  'Brouillon local non sauvegardé',
                  style: TextStyle(
                    color: EditorChrome.accentWarm,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Choisissez un tileset source, composez une palette compatible, puis ajoutez le preset au projet en mémoire.',
              key: const Key('environment-studio-draft-form-intro'),
              style: TextStyle(color: subtle, fontSize: 12.5, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTilesetStep(BuildContext context, Color label, Color subtle) {
    final tilesets = _sortedTilesets();
    return Column(
      key: const Key('environment-studio-creation-step-tileset'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepTitle(
          context,
          '1',
          'Étape 1 sur 2 — Choisir le tileset source',
          'Choisissez le tileset contenant les éléments que ce preset pourra utiliser.',
        ),
        const SizedBox(height: 12),
        Text(
          'Les éléments proposés à l’étape suivante seront filtrés automatiquement.',
          style: TextStyle(color: subtle, fontSize: 12.5, height: 1.35),
        ),
        if (_tilesetChangeMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            _tilesetChangeMessage!,
            style: const TextStyle(
              color: EditorChrome.accentWarm,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        const SizedBox(height: 14),
        if (tilesets.isEmpty)
          _buildEmptyTilesets(context, subtle)
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final tileset in tilesets)
                _buildTilesetCard(context, tileset, label, subtle),
            ],
          ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            CupertinoButton(
              key: const Key('environment-studio-draft-reset'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              minimumSize: Size.zero,
              onPressed: () {
                setState(() {
                  _selectedTilesetId = null;
                  _tilesetChangeMessage = null;
                  _step = 0;
                });
                widget.onReset();
              },
              child: const Text('Réinitialiser brouillon'),
            ),
            CupertinoButton(
              key: const Key('environment-studio-creation-continue'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              onPressed: _selectedTilesetId == null ? null : _goToElementsStep,
              child: const Text('Continuer'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTilesetCard(
    BuildContext context,
    ProjectTilesetEntry tileset,
    Color label,
    Color subtle,
  ) {
    final selected = _selectedTilesetId == tileset.id;
    final count = _compatibleElements(tileset.id).length;
    return SizedBox(
      width: 250,
      child: CupertinoButton(
        key: Key('environment-studio-creation-tileset-${tileset.id}'),
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: () => _selectTileset(tileset),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? EditorChrome.accentJade.withValues(alpha: 0.14)
                : EditorChrome.chipFill(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? EditorChrome.accentJade.withValues(alpha: 0.85)
                  : CupertinoColors.separator.resolveFrom(context),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tileset.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: label,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tileset.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  count == 0
                      ? 'Aucun élément compatible trouvé pour ce tileset'
                      : '$count éléments compatibles',
                  style: TextStyle(
                    color: count == 0
                        ? CupertinoColors.systemOrange.resolveFrom(context)
                        : EditorChrome.accentJade,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tileset.relativePath,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: subtle, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Text(
                  selected ? 'Tileset sélectionné' : 'Choisir ce tileset',
                  style: TextStyle(
                    color: selected ? EditorChrome.accentJade : label,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTilesets(BuildContext context, Color subtle) {
    return DecoratedBox(
      key: const Key('environment-studio-creation-empty-tilesets'),
      decoration: BoxDecoration(
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          'Aucun tileset disponible dans le projet. Importez un tileset avant de créer un preset d’environnement.',
          style: TextStyle(color: subtle, fontSize: 13, height: 1.35),
        ),
      ),
    );
  }

  Widget _buildElementsStep(BuildContext context, Color label, Color subtle) {
    final selectedTilesetId = _selectedTilesetId;
    final compatibleElements = selectedTilesetId == null
        ? const <ProjectElementEntry>[]
        : _compatibleElements(selectedTilesetId);
    final filter = _filterCtrl.text.trim().toLowerCase();
    final visibleElements = filter.isEmpty
        ? compatibleElements
        : [
            for (final element in compatibleElements)
              if (element.id.toLowerCase().contains(filter) ||
                  element.name.toLowerCase().contains(filter) ||
                  element.tags.any((tag) => tag.toLowerCase().contains(filter)))
                element,
          ];
    final draft = _draftFromControllers();
    final validation = validateEnvironmentPresetDraft(
      draft,
      manifest: widget.manifest,
      knownTemplateIds: widget.knownTemplateIds,
    );
    final sourceIssues = _sourceGuardIssues(draft);
    final canSave = widget.onEnvironmentPresetSaved != null &&
        !validation.hasErrors &&
        sourceIssues.isEmpty;

    return Column(
      key: const Key('environment-studio-creation-step-elements'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepTitle(
          context,
          '2',
          'Étape 2 sur 2 — Choisir les éléments du preset',
          selectedTilesetId == null
              ? 'Revenez à l’étape 1 pour choisir un tileset source.'
              : 'Seuls les éléments compatibles avec "$selectedTilesetId" sont proposés.',
        ),
        const SizedBox(height: 12),
        _buildIdentitySection(context, label, subtle),
        const SizedBox(height: 12),
        _buildParamsSection(context, label, subtle),
        const SizedBox(height: 12),
        _buildCompatibleElementPicker(
          context,
          visibleElements,
          compatibleElements,
          label,
          subtle,
        ),
        const SizedBox(height: 12),
        _buildPaletteDraftSection(
          context,
          compatibleElements,
          validation,
          sourceIssues,
          canSave,
          label,
          subtle,
        ),
      ],
    );
  }

  Widget _buildStepTitle(
    BuildContext context,
    String number,
    String title,
    String helper,
  ) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: EditorChrome.accentJade.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: EditorChrome.accentJade.withValues(alpha: 0.75),
            ),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: EditorChrome.accentJade,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: label,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                helper,
                style: TextStyle(color: subtle, fontSize: 12.5, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIdentitySection(
    BuildContext context,
    Color label,
    Color subtle,
  ) {
    return _panel(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Informations du preset',
            style: TextStyle(
              color: label,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            key: const Key('environment-studio-creation-identity-grid'),
            spacing: 10,
            runSpacing: 10,
            children: [
              _field(context, 'Id', 'Identifiant unique',
                  const Key('environment-studio-draft-field-id'), _idCtrl,
                  onChanged: (_) => _emit()),
              _field(context, 'Nom', 'Nom affiché',
                  const Key('environment-studio-draft-field-name'), _nameCtrl,
                  onChanged: (_) => _emit()),
              _field(
                  context,
                  'Template',
                  'Template',
                  const Key('environment-studio-draft-field-template'),
                  _templateCtrl,
                  onChanged: (_) => _emit()),
              _field(
                  context,
                  'Catégorie',
                  'Optionnel',
                  const Key('environment-studio-draft-field-category'),
                  _categoryCtrl,
                  onChanged: (_) => _emit()),
              _field(context, 'Ordre d’affichage', '0',
                  const Key('environment-studio-draft-field-sort'), _sortCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _emit()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParamsSection(
    BuildContext context,
    Color label,
    Color subtle,
  ) {
    return _panel(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Paramètres par défaut',
            key: const Key('environment-studio-draft-params-section-title'),
            style: TextStyle(
              color: label,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _field(
                context,
                'Densité',
                '0.0 – 1.0',
                const Key('environment-studio-draft-params-density'),
                _densityCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: _emitDensity,
              ),
              _field(
                context,
                'Variation',
                '0.0 – 1.0',
                const Key('environment-studio-draft-params-variation'),
                _variationCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: _emitVariation,
              ),
              _field(
                context,
                'Densité des bords',
                '0.0 – 1.0',
                const Key('environment-studio-draft-params-edge-density'),
                _edgeDensityCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: _emitEdgeDensity,
              ),
              _field(
                context,
                'Espacement min.',
                '0',
                const Key('environment-studio-draft-params-min-spacing'),
                _minSpacingCtrl,
                keyboardType: TextInputType.number,
                onChanged: _emitMinSpacing,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibleElementPicker(
    BuildContext context,
    List<ProjectElementEntry> visibleElements,
    List<ProjectElementEntry> compatibleElements,
    Color label,
    Color subtle,
  ) {
    return _panel(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Éléments compatibles',
                  style: TextStyle(
                    color: label,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(
                width: 260,
                child: CupertinoTextField(
                  key: const Key('environment-studio-creation-element-filter'),
                  controller: _filterCtrl,
                  placeholder: 'Filtrer éléments compatibles...',
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (compatibleElements.isEmpty)
            Text(
              'Aucun élément compatible trouvé pour ce tileset.',
              style: TextStyle(color: subtle, fontSize: 13),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final element in visibleElements)
                  _buildElementCard(context, element, label, subtle),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildElementCard(
    BuildContext context,
    ProjectElementEntry element,
    Color label,
    Color subtle,
  ) {
    final alreadyAdded =
        widget.draft.palette.any((item) => item.elementId == element.id);
    return SizedBox(
      key: Key('environment-studio-creation-compatible-element-${element.id}'),
      width: 260,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EditorChrome.chipFill(context),
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
                element.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: label,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                element.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: subtle, fontSize: 11),
              ),
              if (element.tags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  element.tags.join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: subtle, fontSize: 11),
                ),
              ],
              const SizedBox(height: 8),
              CupertinoButton(
                key: Key(
                    'environment-studio-creation-add-element-${element.id}'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                onPressed: alreadyAdded ? null : () => _addPaletteItem(element),
                child: Text(alreadyAdded ? 'Déjà ajouté' : 'Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaletteDraftSection(
    BuildContext context,
    List<ProjectElementEntry> compatibleElements,
    EnvironmentPresetDraftValidationReport validation,
    List<String> sourceIssues,
    bool canSave,
    Color label,
    Color subtle,
  ) {
    return _panel(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Palette du preset',
                  key: const Key(
                    'environment-studio-draft-palette-section-title',
                  ),
                  style: TextStyle(
                    color: label,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              CupertinoButton(
                key: const Key('environment-studio-draft-palette-add-item'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                onPressed: _addEmptyPaletteItem,
                child: const Text('Ajouter un élément'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPaletteHeader(context, subtle),
          const SizedBox(height: 6),
          if (widget.draft.palette.isEmpty)
            Text(
              'Aucun item pour l’instant.',
              key: const Key('environment-studio-draft-palette-no-items'),
              style: TextStyle(color: subtle, fontSize: 13),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 884,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < widget.draft.palette.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: i < widget.draft.palette.length - 1 ? 6 : 0,
                        ),
                        child: EnvironmentPaletteItemDraftEditor(
                          key: ValueKey('palette-draft-slot-$i'),
                          index: i,
                          item: widget.draft.palette[i],
                          projectElements: compatibleElements,
                          onChanged: (item) => _replacePaletteItem(i, item),
                          onRemove: () => _removePaletteItem(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          EnvironmentPresetDraftValidationView(
            report: validation,
            labelColor: label,
            subtleColor: subtle,
          ),
          if (sourceIssues.isNotEmpty) ...[
            const SizedBox(height: 10),
            DecoratedBox(
              key: const Key('environment-studio-creation-source-guard'),
              decoration: BoxDecoration(
                color: CupertinoColors.systemRed
                    .resolveFrom(context)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: CupertinoColors.systemRed
                      .resolveFrom(context)
                      .withValues(alpha: 0.25),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final issue in sourceIssues)
                      Text(
                        issue,
                        style: TextStyle(
                          color: CupertinoColors.systemRed.resolveFrom(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (validation.hasErrors) ...[
            const SizedBox(height: 10),
            Text(
              'Corrigez les erreurs du brouillon pour appliquer au projet en mémoire.',
              key: const Key('environment-studio-draft-save-disabled-hint'),
              style: TextStyle(
                color: CupertinoColors.systemOrange.resolveFrom(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
          if (validation.hasWarnings && !validation.hasErrors) ...[
            const SizedBox(height: 10),
            Text(
              'Les avertissements ne bloquent pas l’application au projet en mémoire.',
              key: const Key('environment-studio-draft-save-warnings-hint'),
              style: TextStyle(
                color: CupertinoColors.systemYellow.resolveFrom(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
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
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              CupertinoButton(
                key: const Key('environment-studio-creation-back-to-tilesets'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                minimumSize: Size.zero,
                onPressed: _goToTilesetStep,
                child: const Text('Retour au choix du tileset'),
              ),
              CupertinoButton(
                key: const Key('environment-studio-draft-reset'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                minimumSize: Size.zero,
                onPressed: widget.onReset,
                child: const Text('Réinitialiser brouillon'),
              ),
              CupertinoButton(
                key: const Key('environment-studio-draft-save-project'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                onPressed: canSave ? _saveDraftToProject : null,
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

  Widget _buildPaletteHeader(BuildContext context, Color subtle) {
    Text header(String text) {
      return Text(
        text,
        style: TextStyle(
          color: subtle,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 884,
        child: Row(
          children: [
            SizedBox(width: 306, child: header('Élément')),
            SizedBox(width: 86, child: header('Poids')),
            SizedBox(width: 230, child: header('Collision')),
            SizedBox(width: 180, child: header('Tags')),
            SizedBox(width: 58, child: header('Actions')),
          ],
        ),
      ),
    );
  }

  Widget _panel(BuildContext context, {required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }

  Widget _field(
    BuildContext context,
    String label,
    String placeholder,
    Key key,
    TextEditingController controller, {
    TextInputType? keyboardType,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      width: 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          CupertinoTextField(
            key: key,
            controller: controller,
            placeholder: placeholder,
            keyboardType: keyboardType,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
