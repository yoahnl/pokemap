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
