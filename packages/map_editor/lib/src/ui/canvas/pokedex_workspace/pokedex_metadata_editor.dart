part of 'pokedex_workspace_page.dart';

// Édition locale des métadonnées simples.
//
// Cette section réutilise le use case métier déjà en place. Le composant garde
// seulement le draft d'écran, pour permettre modifier / annuler / enregistrer
// sans dupliquer la source de vérité persistée.

class _PokedexEditableMetadataSection extends StatefulWidget {
  const _PokedexEditableMetadataSection({
    required this.species,
    required this.onSave,
  });

  final PokemonSpeciesFile species;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSave;

  @override
  State<_PokedexEditableMetadataSection> createState() =>
      _PokedexEditableMetadataSectionState();
}

class _PokedexEditableMetadataSectionState
    extends State<_PokedexEditableMetadataSection> {
  final Map<String, TextEditingController> _nameControllers =
      <String, TextEditingController>{};
  final List<TextEditingController> _typeControllers =
      <TextEditingController>[];
  late TextEditingController _flavorTextController;
  late List<String> _orderedLocales;
  late bool _isEnabledInProject;
  late bool _starterEligible;
  late bool _giftOnly;
  late bool _tradeOnly;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _saveErrorMessage;

  @override
  void initState() {
    super.initState();
    _flavorTextController = TextEditingController();
    _replaceDraftFromSpecies(widget.species);
  }

  @override
  void didUpdateWidget(covariant _PokedexEditableMetadataSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.species != widget.species) {
      // Dès qu'une nouvelle espèce est relue depuis le workspace, on considère
      // qu'elle devient la nouvelle vérité locale :
      // - après sélection d'une autre ligne ;
      // - après sauvegarde réussie et rechargement ;
      // - après changement de filtres qui force une nouvelle fiche.
      //
      // On jette donc proprement tout draft local restant.
      _replaceDraftFromSpecies(widget.species);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    }
  }

  @override
  void dispose() {
    _disposeNameControllers();
    _disposeTypeControllers();
    _flavorTextController.dispose();
    super.dispose();
  }

  void _replaceDraftFromSpecies(PokemonSpeciesFile species) {
    _disposeNameControllers();
    _disposeTypeControllers();

    _orderedLocales = _orderedLocaleKeys(species.names);
    for (final locale in _orderedLocales) {
      _nameControllers[locale] = TextEditingController(
        text: species.names[locale] ?? '',
      );
    }
    final sourceTypes = species.typing.types.isEmpty
        ? const <String>['']
        : species.typing.types;
    for (final type in sourceTypes) {
      _typeControllers.add(TextEditingController(text: type));
    }

    _flavorTextController.value = TextEditingValue(
      text: species.dexContent.flavorText ?? '',
      selection: TextSelection.collapsed(
        offset: (species.dexContent.flavorText ?? '').length,
      ),
    );
    _isEnabledInProject = species.classification.isEnabledInProject;
    _starterEligible = species.gameplayFlags.starterEligible;
    _giftOnly = species.gameplayFlags.giftOnly;
    _tradeOnly = species.gameplayFlags.tradeOnly;
  }

  void _disposeNameControllers() {
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    _nameControllers.clear();
  }

  void _disposeTypeControllers() {
    for (final controller in _typeControllers) {
      controller.dispose();
    }
    _typeControllers.clear();
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
        UpdatePokedexSpeciesMetadataRequest(
          speciesId: widget.species.id,
          isEnabledInProject: _isEnabledInProject,
          names: <String, String>{
            for (final locale in _orderedLocales)
              locale: _nameControllers[locale]?.text ?? '',
          },
          types: _typeControllers.map((controller) => controller.text).toList(),
          flavorText: _flavorTextController.text,
          starterEligible: _starterEligible,
          giftOnly: _giftOnly,
          tradeOnly: _tradeOnly,
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

  void _addTypeField() {
    setState(() {
      _typeControllers.add(TextEditingController());
    });
  }

  void _removeTypeField(int index) {
    if (_typeControllers.length <= 1) {
      return;
    }
    setState(() {
      final controller = _typeControllers.removeAt(index);
      controller.dispose();
    });
  }

  void _cancelEditing() {
    setState(() {
      _replaceDraftFromSpecies(widget.species);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final species = widget.species;

    return _PokedexDetailSectionCard(
      title: 'Métadonnées locales',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditing) ...[
            _PokedexBooleanEditorRow(
              key: const Key('pokedex-enabled-switch-row'),
              label: 'Activée dans le projet',
              description:
                  'Le filtre liste et le statut local utilisent ce booléen persistant.',
              value: _isEnabledInProject,
              switchKey: const Key('pokedex-enabled-switch'),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _isEnabledInProject = value),
            ),
            const SizedBox(height: 12),
            for (final locale in _orderedLocales) ...[
              _PokedexEditorTextField(
                label: 'Nom (${locale.toUpperCase()})',
                fieldKey: Key('pokedex-name-field-$locale'),
                controller: _nameControllers[locale]!,
                enabled: !_isSaving,
              ),
              const SizedBox(height: 10),
            ],
            _PokedexEditableTypeFields(
              controllers: _typeControllers,
              enabled: !_isSaving,
              onAddType: _isSaving ? null : _addTypeField,
              onRemoveType: _isSaving ? null : _removeTypeField,
            ),
            const SizedBox(height: 12),
            _PokedexEditorTextField(
              label: 'Texte Pokédex',
              fieldKey: const Key('pokedex-flavor-text-field'),
              controller: _flavorTextController,
              enabled: !_isSaving,
              minLines: 3,
              maxLines: 6,
              placeholder: 'Texte local affiché dans la fiche Pokédex',
            ),
            const SizedBox(height: 12),
            _PokedexBooleanEditorRow(
              key: const Key('pokedex-starter-eligible-switch-row'),
              label: 'Starter éligible',
              value: _starterEligible,
              switchKey: const Key('pokedex-starter-eligible-switch'),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _starterEligible = value),
            ),
            const SizedBox(height: 10),
            _PokedexBooleanEditorRow(
              key: const Key('pokedex-gift-only-switch-row'),
              label: 'Obtenu par cadeau',
              value: _giftOnly,
              switchKey: const Key('pokedex-gift-only-switch'),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _giftOnly = value),
            ),
            const SizedBox(height: 10),
            _PokedexBooleanEditorRow(
              key: const Key('pokedex-trade-only-switch-row'),
              label: 'Échange uniquement',
              value: _tradeOnly,
              switchKey: const Key('pokedex-trade-only-switch'),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _tradeOnly = value),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                CupertinoButton.filled(
                  key: const Key('pokedex-save-metadata-button'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  onPressed: _isSaving ? null : _saveDraft,
                  child: Text(_isSaving ? 'Enregistrement…' : 'Enregistrer'),
                ),
                const SizedBox(width: 10),
                CupertinoButton(
                  key: const Key('pokedex-cancel-metadata-button'),
                  onPressed: _isSaving ? null : _cancelEditing,
                  child: const Text('Annuler'),
                ),
              ],
            ),
            if (_saveErrorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _saveErrorMessage!,
                key: const Key('pokedex-metadata-save-error'),
                style: const TextStyle(
                  color: EditorChrome.inspectorJoyCoral,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ] else ...[
            _PokedexPropertyLine(
              label: 'Statut projet',
              value: species.classification.isEnabledInProject
                  ? 'Activée'
                  : 'Désactivée',
            ),
            for (final locale in _orderedLocaleKeys(species.names))
              _PokedexPropertyLine(
                label: 'Nom (${locale.toUpperCase()})',
                value: (species.names[locale]?.trim().isNotEmpty ?? false)
                    ? species.names[locale]!.trim()
                    : 'Valeur vide',
              ),
            _PokedexPropertyLine(
              label: 'Texte Pokédex',
              value: species.dexContent.flavorText?.trim().isNotEmpty == true
                  ? species.dexContent.flavorText!.trim()
                  : 'Aucun texte local',
            ),
            _PokedexPropertyLine(
              label: 'Types',
              value: species.typing.types.isEmpty
                  ? 'Aucun type'
                  : species.typing.types.join(', '),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FlagChip(
                  label: species.gameplayFlags.starterEligible
                      ? 'Starter éligible'
                      : 'Starter non éligible',
                ),
                _FlagChip(
                  label: species.gameplayFlags.giftOnly
                      ? 'Obtenu par cadeau'
                      : 'Pas cadeau uniquement',
                ),
                _FlagChip(
                  label: species.gameplayFlags.tradeOnly
                      ? 'Échange uniquement'
                      : 'Pas échange uniquement',
                ),
              ],
            ),
            const SizedBox(height: 14),
            CupertinoButton(
              key: const Key('pokedex-edit-metadata-button'),
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  _replaceDraftFromSpecies(widget.species);
                  _isEditing = true;
                  _saveErrorMessage = null;
                });
              },
              child: const Text('Modifier'),
            ),
          ],
        ],
      ),
    );
  }
}
