part of 'pokedex_workspace_page.dart';

// Onglet Formes / classification.
//
// Le flux reste identique à celui déjà branché aux use cases existants. Ici on
// améliore surtout la lisibilité et le découpage du code UI.

class _PokedexFormsTab extends StatefulWidget {
  const _PokedexFormsTab({
    required this.detail,
    required this.onSave,
  });

  final PokedexSpeciesDetail detail;
  final Future<void> Function(
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) onSave;

  @override
  State<_PokedexFormsTab> createState() => _PokedexFormsTabState();
}

class _PokedexFormsTabState extends State<_PokedexFormsTab> {
  late final TextEditingController _baseFormIdController;
  late final TextEditingController _formIdController;
  late final TextEditingController _formNameController;
  late final TextEditingController _otherFormsController;
  late bool _isBaseForm;
  late bool _isObtainable;
  late bool _isLegendary;
  late bool _isMythical;
  late bool _isBaby;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _saveErrorMessage;

  @override
  void initState() {
    super.initState();
    _baseFormIdController = TextEditingController();
    _formIdController = TextEditingController();
    _formNameController = TextEditingController();
    _otherFormsController = TextEditingController();
    _replaceDraftFromSpecies(widget.detail.species);
  }

  @override
  void didUpdateWidget(covariant _PokedexFormsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail != widget.detail) {
      _replaceDraftFromSpecies(widget.detail.species);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    }
  }

  @override
  void dispose() {
    _baseFormIdController.dispose();
    _formIdController.dispose();
    _formNameController.dispose();
    _otherFormsController.dispose();
    super.dispose();
  }

  void _replaceDraftFromSpecies(PokemonSpeciesFile species) {
    final forms = species.forms;
    final classification = species.classification;
    _baseFormIdController.text =
        forms.baseFormId.trim().isEmpty ? species.id : forms.baseFormId;
    _formIdController.text = forms.formId;
    _formNameController.text = forms.formName ?? '';
    _otherFormsController.text = forms.otherForms.join('\n');
    _isBaseForm = forms.isBaseForm;
    _isObtainable = classification.isObtainable;
    _isLegendary = classification.isLegendary;
    _isMythical = classification.isMythical;
    _isBaby = classification.isBaby;
  }

  Future<void> _saveDraft() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _saveErrorMessage = null;
    });

    try {
      await widget.onSave(
        UpdatePokedexSpeciesFormsClassificationRequest(
          speciesId: widget.detail.species.id,
          baseFormId: _isBaseForm
              ? widget.detail.species.id
              : _baseFormIdController.text,
          isBaseForm: _isBaseForm,
          formId: _formIdController.text,
          formName: _formNameController.text,
          otherForms: _splitNonEmptyLines(_otherFormsController.text),
          isObtainable: _isObtainable,
          isLegendary: _isLegendary,
          isMythical: _isMythical,
          isBaby: _isBaby,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isEditing = false;
        _isSaving = false;
        _saveErrorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = switch (error) {
        final EditorApplicationException applicationError =>
          applicationError.message,
        _ => error.toString(),
      };
      setState(() {
        _isSaving = false;
        _saveErrorMessage = message;
      });
    }
  }

  void _cancelEditing() {
    setState(() {
      _replaceDraftFromSpecies(widget.detail.species);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final species = widget.detail.species;
    final forms = species.forms;
    final classification = species.classification;
    final currentFormId = forms.formId.isEmpty ? 'base' : forms.formId;
    final baseFormId = forms.baseFormId.isEmpty ? species.id : forms.baseFormId;

    return SingleChildScrollView(
      key: const Key('pokedex-forms-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PokedexDetailSectionCard(
            title: 'Formes et classification',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isEditing) ...[
                  _PokedexBooleanEditorRow(
                    key: const Key('pokedex-is-base-form-switch-row'),
                    label: 'Forme de base',
                    description:
                        'Quand ce flag est actif, la baseFormId suit automatiquement l’id de l’espèce.',
                    value: _isBaseForm,
                    switchKey: const Key('pokedex-is-base-form-switch'),
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _isBaseForm = value),
                  ),
                  const SizedBox(height: 12),
                  _PokedexEditorTextField(
                    label: 'Form ID',
                    description:
                        'Identifiant local simple de la forme courante.',
                    fieldKey: const Key('pokedex-form-id-field'),
                    controller: _formIdController,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Base form ID',
                    description:
                        'Référence locale de la forme de base. Verrouillée si cette espèce est la base.',
                    fieldKey: const Key('pokedex-base-form-id-field'),
                    controller: _baseFormIdController,
                    enabled: !_isSaving && !_isBaseForm,
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Nom de forme',
                    description:
                        'Valeur optionnelle affichée dans la fiche locale.',
                    fieldKey: const Key('pokedex-form-name-field'),
                    controller: _formNameController,
                    enabled: !_isSaving,
                    placeholder: 'Ex. Méga, Alola, Hisui…',
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Autres formes',
                    description:
                        'Une forme par ligne. Les valeurs vides, doublons et auto-références sont ignorés.',
                    fieldKey: const Key('pokedex-other-forms-field'),
                    controller: _otherFormsController,
                    enabled: !_isSaving,
                    minLines: 3,
                    maxLines: 6,
                    placeholder: 'mega\nalola\nhisui',
                  ),
                  const SizedBox(height: 12),
                  _PokedexBooleanEditorRow(
                    key: const Key('pokedex-is-obtainable-switch-row'),
                    label: 'Obtenable',
                    value: _isObtainable,
                    switchKey: const Key('pokedex-is-obtainable-switch'),
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _isObtainable = value),
                  ),
                  const SizedBox(height: 10),
                  _PokedexBooleanEditorRow(
                    key: const Key('pokedex-is-legendary-switch-row'),
                    label: 'Légendaire',
                    value: _isLegendary,
                    switchKey: const Key('pokedex-is-legendary-switch'),
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _isLegendary = value),
                  ),
                  const SizedBox(height: 10),
                  _PokedexBooleanEditorRow(
                    key: const Key('pokedex-is-mythical-switch-row'),
                    label: 'Mythique',
                    value: _isMythical,
                    switchKey: const Key('pokedex-is-mythical-switch'),
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _isMythical = value),
                  ),
                  const SizedBox(height: 10),
                  _PokedexBooleanEditorRow(
                    key: const Key('pokedex-is-baby-switch-row'),
                    label: 'Bébé',
                    value: _isBaby,
                    switchKey: const Key('pokedex-is-baby-switch'),
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _isBaby = value),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      CupertinoButton.filled(
                        key: const Key('pokedex-save-forms-button'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        onPressed: _isSaving ? null : _saveDraft,
                        child: Text(
                          _isSaving ? 'Enregistrement…' : 'Enregistrer',
                        ),
                      ),
                      const SizedBox(width: 10),
                      CupertinoButton(
                        key: const Key('pokedex-cancel-forms-button'),
                        onPressed: _isSaving ? null : _cancelEditing,
                        child: const Text('Annuler'),
                      ),
                    ],
                  ),
                  if (_saveErrorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _saveErrorMessage!,
                      key: const Key('pokedex-forms-save-error'),
                      style: const TextStyle(
                        color: EditorChrome.inspectorJoyCoral,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ] else ...[
                  _PokedexPropertyLine(
                    label: 'Forme courante',
                    value: forms.formName == null || forms.formName!.isEmpty
                        ? currentFormId
                        : '${forms.formName} ($currentFormId)',
                  ),
                  _PokedexPropertyLine(
                    label: 'Forme de base',
                    value: baseFormId,
                  ),
                  _PokedexPropertyLine(
                    label: 'Est la forme de base',
                    value: forms.isBaseForm ? 'Oui' : 'Non',
                  ),
                  _PokedexPropertyLine(
                    label: 'Autres formes',
                    value: forms.otherForms.isEmpty
                        ? 'Aucune autre forme locale'
                        : forms.otherForms.join(', '),
                  ),
                  _PokedexPropertyLine(
                    label: 'Statut projet',
                    value: classification.isEnabledInProject
                        ? 'Activée'
                        : 'Désactivée',
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FlagChip(
                        label: classification.isObtainable
                            ? 'Obtenable'
                            : 'Non obtenable',
                      ),
                      if (classification.isLegendary)
                        const _FlagChip(label: 'Légendaire'),
                      if (classification.isMythical)
                        const _FlagChip(label: 'Mythique'),
                      if (classification.isBaby) const _FlagChip(label: 'Bébé'),
                      if (!classification.isLegendary &&
                          !classification.isMythical &&
                          !classification.isBaby)
                        const _FlagChip(label: 'Aucun flag rare'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  CupertinoButton(
                    key: const Key('pokedex-edit-forms-button'),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _replaceDraftFromSpecies(widget.detail.species);
                        _isEditing = true;
                        _saveErrorMessage = null;
                      });
                    },
                    child: const Text('Modifier'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Flags gameplay simples',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (species.gameplayFlags.starterEligible)
                  const _FlagChip(label: 'Starter éligible'),
                if (species.gameplayFlags.giftOnly)
                  const _FlagChip(label: 'Obtenu par cadeau'),
                if (species.gameplayFlags.tradeOnly)
                  const _FlagChip(label: 'Échange uniquement'),
                if (!species.gameplayFlags.starterEligible &&
                    !species.gameplayFlags.giftOnly &&
                    !species.gameplayFlags.tradeOnly)
                  const _FlagChip(label: 'Aucun flag gameplay'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
