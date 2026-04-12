part of 'pokedex_workspace_page.dart';

// Onglet Évolutions.
//
// On garde l'édition texte structurée existante, mais dans un fichier dédié pour
// éviter qu'un seul widget monopolise toute la maintenance du workspace.

class _PokedexEvolutionTab extends StatefulWidget {
  const _PokedexEvolutionTab({
    required this.detail,
    required this.onSave,
  });

  final PokedexSpeciesDetail detail;
  final Future<void> Function(UpdatePokedexSpeciesEvolutionRequest request)
      onSave;

  @override
  State<_PokedexEvolutionTab> createState() => _PokedexEvolutionTabState();
}

class _PokedexEvolutionTabState extends State<_PokedexEvolutionTab> {
  late final TextEditingController _preEvolutionController;
  late final TextEditingController _entriesController;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _saveErrorMessage;

  @override
  void initState() {
    super.initState();
    _preEvolutionController = TextEditingController();
    _entriesController = TextEditingController();
    _replaceDraftFromDetail(widget.detail);
  }

  @override
  void didUpdateWidget(covariant _PokedexEvolutionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail != widget.detail) {
      _replaceDraftFromDetail(widget.detail);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    }
  }

  @override
  void dispose() {
    _preEvolutionController.dispose();
    _entriesController.dispose();
    super.dispose();
  }

  void _replaceDraftFromDetail(PokedexSpeciesDetail detail) {
    final evolution = detail.evolution;
    _preEvolutionController.text = evolution?.preEvolution ?? '';
    _entriesController.text =
        evolution == null ? '' : _formatEvolutionEntries(evolution.evolutions);
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
        UpdatePokedexSpeciesEvolutionRequest(
          speciesId: widget.detail.species.id,
          preEvolution: _preEvolutionController.text,
          evolutions: _parseEvolutionEntries(_entriesController.text),
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
      _replaceDraftFromDetail(widget.detail);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final evolution = widget.detail.evolution;
    final evolutionRef = widget.detail.species.refs.evolution.trim();

    return SingleChildScrollView(
      key: const Key('pokedex-evolutions-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isEditing) ...[
            _PokedexDetailSectionCard(
              title: 'Édition évolution locale',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PokedexPropertyLine(
                    label: 'Ref évolution',
                    value: evolutionRef.isEmpty ? 'Ref absente' : evolutionRef,
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Pré-évolution',
                    description:
                        'Laissez vide si l’espèce n’a pas de pré-évolution locale.',
                    fieldKey: const Key('pokedex-pre-evolution-field'),
                    controller: _preEvolutionController,
                    enabled: !_isSaving,
                    placeholder: 'bulbasaur',
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Évolutions suivantes',
                    description:
                        'Une entrée par ligne au format targetSpeciesId|method|minLevel|itemId|requiredMoveId|conditionFr|conditionEn.',
                    fieldKey: const Key('pokedex-evolution-entries-field'),
                    controller: _entriesController,
                    enabled: !_isSaving,
                    minLines: 3,
                    maxLines: 8,
                    placeholder:
                        'ivysaur|level_up|16|||Évolue au niveau 16|Evolves at level 16',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      CupertinoButton.filled(
                        key: const Key('pokedex-save-evolution-button'),
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
                        key: const Key('pokedex-cancel-evolution-button'),
                        onPressed: _isSaving ? null : _cancelEditing,
                        child: const Text('Annuler'),
                      ),
                    ],
                  ),
                  if (_saveErrorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _saveErrorMessage!,
                      key: const Key('pokedex-evolution-save-error'),
                      style: const TextStyle(
                        color: EditorChrome.inspectorJoyCoral,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            if (evolution == null)
              _PokedexMissingSection(
                key: const Key('pokedex-evolutions-missing'),
                title: 'Évolutions',
                message: evolutionRef.isEmpty
                    ? 'La ref évolution est vide dans l’espèce locale ; aucune évolution ne peut être éditée depuis cette fiche.'
                    : 'Aucune donnée d’évolution locale trouvée pour cette espèce. Vous pouvez en créer une depuis cet onglet.',
              )
            else ...[
              _PokedexDetailSectionCard(
                title: 'Pré-évolution',
                child: Text(evolution.preEvolution?.trim().isNotEmpty == true
                    ? evolution.preEvolution!
                    : 'Aucune'),
              ),
              const SizedBox(height: 12),
              _PokedexDetailSectionCard(
                title: 'Évolutions suivantes',
                child: evolution.evolutions.isEmpty
                    ? const Text('Aucune évolution déclarée.')
                    : Column(
                        children: evolution.evolutions
                            .map(
                              (entry) => _PokedexPropertyLine(
                                label: entry.targetSpeciesId,
                                value: _describeEvolution(entry),
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
            ],
            const SizedBox(height: 12),
            _PokedexDetailSectionCard(
              title: 'Édition locale',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evolutionRef.isEmpty
                        ? 'Impossible d’éditer cette chaîne tant que la ref locale est vide.'
                        : 'La chaîne d’évolution reste limitée au contrat déjà supporté par le modèle courant.',
                  ),
                  if (evolutionRef.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    CupertinoButton(
                      key: const Key('pokedex-edit-evolution-button'),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _replaceDraftFromDetail(widget.detail);
                          _isEditing = true;
                          _saveErrorMessage = null;
                        });
                      },
                      child: Text(
                        evolution == null ? 'Créer localement' : 'Modifier',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
