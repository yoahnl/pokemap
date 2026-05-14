import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/shared/cupertino_editor_widgets.dart';
import '../authoring/environment_preset_draft.dart';
import '../authoring/environment_preset_tileset_compatibility.dart';
import '../environment_preset_memory_write_kind.dart';
import 'environment_generation_params_draft_editor.dart';
import 'environment_element_thumbnail.dart';
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
    this.existingPresetId,
    required this.validation,
    required this.projectElements,
    required this.onChanged,
    required this.onCancel,
    required this.onReset,
    this.resolveTilesetPathById,
    this.onEnvironmentPresetSaved,
  });

  /// Manifest courant (validation + upsert avant callback).
  final ProjectManifest manifest;

  /// Aligné sur [EnvironmentStudioPanel.knownTemplateIds].
  final Set<String> knownTemplateIds;

  /// Éléments du projet (`manifest.elements`) pour le picker de palette.
  final List<ProjectElementEntry> projectElements;
  final EnvironmentTilesetPathResolver? resolveTilesetPathById;

  final EnvironmentPresetDraft draft;

  /// Lot 18 : si non null, id verrouillé + validation `existingPresetId`.
  final String? existingPresetId;

  final EnvironmentPresetDraftValidationReport validation;
  final ValueChanged<EnvironmentPresetDraft> onChanged;
  final VoidCallback onCancel;
  final VoidCallback onReset;

  /// `null` : enregistrement indisponible (bouton désactivé + note).
  final void Function(
    ProjectManifest nextManifest,
    EnvironmentPreset savedPreset,
    EnvironmentPresetMemoryWriteKind kind,
  )? onEnvironmentPresetSaved;

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

  String _lockedIdText() {
    final id = widget.existingPresetId?.trim();
    return (id == null || id.isEmpty) ? '' : id;
  }

  String _effectiveIdForDraft() {
    final locked = _lockedIdText();
    if (locked.isNotEmpty) {
      return locked;
    }
    return _idCtrl.text;
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
      id: _effectiveIdForDraft(),
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
        id: _effectiveIdForDraft(),
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
      existingPresetId: widget.existingPresetId,
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
      final kind = widget.existingPresetId != null
          ? EnvironmentPresetMemoryWriteKind.update
          : EnvironmentPresetMemoryWriteKind.create;
      save(nextManifest, preset, kind);
    } catch (e, st) {
      debugPrint('EnvironmentPresetDraftForm: ajout mémoire impossible: $e');
      debugPrint('$st');
      setState(() {
        _saveErrorMessage =
            'Impossible d’appliquer le preset au projet en mémoire.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final canSaveToProject =
        widget.onEnvironmentPresetSaved != null && !widget.validation.hasErrors;
    final isEdit = widget.existingPresetId != null;
    final tilesetCompatibility = buildEnvironmentPresetTilesetCompatibility(
      paletteElementIds: [
        for (final item in widget.draft.palette) item.elementId,
      ],
      projectElements: widget.projectElements,
    );

    return SingleChildScrollView(
      key: const Key('environment-studio-draft-form-scroll'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isEdit
                ? 'Modifier un preset d’environnement'
                : 'Nouveau preset d’environnement',
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
            child: Text(
              isEdit
                  ? 'Brouillon de modification non sauvegardé'
                  : 'Brouillon local non sauvegardé',
              key: Key(
                isEdit
                    ? 'environment-studio-draft-edit-badge'
                    : 'environment-studio-draft-local-badge',
              ),
              style: const TextStyle(
                color: EditorChrome.accentWarm,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isEdit
                ? 'Modifiez ce preset en brouillon, puis mettez à jour le projet en mémoire. '
                    'Aucune sauvegarde disque automatique.'
                : 'Remplissez le brouillon puis « Ajouter au projet en mémoire » pour '
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
            enabled: !isEdit,
            placeholder: 'Identifiant unique',
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onChanged: (_) => _emit(),
          ),
          if (isEdit) ...[
            const SizedBox(height: 6),
            Text(
              'L’id est verrouillé dans cette version pour préserver les références des maps.',
              key: const Key('environment-studio-draft-id-locked-hint'),
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
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
            'Palette du preset',
            key: const Key('environment-studio-draft-palette-section-title'),
            style: TextStyle(
              color: label,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les éléments doivent exister dans le projet et partager le même tileset source.',
            key: const Key('environment-studio-draft-palette-local-note'),
            style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          _buildTilesetSourceBlock(context, tilesetCompatibility),
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
              'Aucun élément sélectionné.',
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
                  manifest: widget.manifest,
                  resolveTilesetPathById: widget.resolveTilesetPathById,
                  projectElements:
                      tilesetCompatibility.availableCompatibleElements,
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
              'Corrigez les erreurs du brouillon pour appliquer au projet en mémoire.',
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
              'Les avertissements ne bloquent pas l’application au projet en mémoire.',
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
                child: const Text('Retour aux presets'),
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
                child: Text(
                  isEdit
                      ? 'Mettre à jour le projet en mémoire'
                      : 'Ajouter au projet en mémoire',
                ),
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

  Widget _buildTilesetSourceBlock(
    BuildContext context,
    EnvironmentPresetTilesetCompatibility compatibility,
  ) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final source = compatibility.sourceTilesetId;
    return DecoratedBox(
      key: const Key('environment-studio-draft-tileset-source'),
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
              key: const Key('environment-studio-draft-tileset-source-value'),
              style: TextStyle(
                color: label,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              source == null
                  ? 'Ajoutez un premier élément ou choisissez un tileset source.'
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
}
