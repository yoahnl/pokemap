part of 'pokedex_workspace_page.dart';

// Onglet Médias.
//
// Même approche que le reste du workspace : l'UI reste un reflet lisible du
// modèle existant, sans créer de pipeline parallèle pour les assets.

class _PokedexMediaTab extends StatefulWidget {
  const _PokedexMediaTab({
    required this.detail,
    required this.onSave,
  });

  final PokedexSpeciesDetail detail;
  final Future<void> Function(UpdatePokedexSpeciesMediaRequest request) onSave;

  @override
  State<_PokedexMediaTab> createState() => _PokedexMediaTabState();
}

class _PokedexMediaTabState extends State<_PokedexMediaTab> {
  late final TextEditingController _defaultFormIdController;
  late final TextEditingController _variantEntriesController;
  late final TextEditingController _animationEntriesController;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _saveErrorMessage;

  @override
  void initState() {
    super.initState();
    _defaultFormIdController = TextEditingController();
    _variantEntriesController = TextEditingController();
    _animationEntriesController = TextEditingController();
    _replaceDraftFromDetail(widget.detail);
  }

  @override
  void didUpdateWidget(covariant _PokedexMediaTab oldWidget) {
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
    _defaultFormIdController.dispose();
    _variantEntriesController.dispose();
    _animationEntriesController.dispose();
    super.dispose();
  }

  void _replaceDraftFromDetail(PokedexSpeciesDetail detail) {
    final media = detail.media;
    _defaultFormIdController.text = media?.defaultFormId ?? '';
    _variantEntriesController.text =
        media == null ? '' : _formatMediaVariantEntries(media.variants);
    _animationEntriesController.text =
        media == null ? '' : _formatMediaAnimationEntries(media.variants);
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
      final variants = _parseMediaVariants(_variantEntriesController.text);
      _applyMediaAnimationEntries(
        variants,
        _animationEntriesController.text,
      );

      await widget.onSave(
        UpdatePokedexSpeciesMediaRequest(
          speciesId: widget.detail.species.id,
          defaultFormId: _defaultFormIdController.text,
          variants: variants,
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
    final media = widget.detail.media;
    final mediaRef = widget.detail.species.refs.media.trim();

    return SingleChildScrollView(
      key: const Key('pokedex-media-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isEditing) ...[
            _PokedexDetailSectionCard(
              title: 'Édition média locale',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PokedexPropertyLine(
                    label: 'Ref média',
                    value: mediaRef.isEmpty ? 'Ref absente' : mediaRef,
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Forme par défaut',
                    description:
                        'La forme par défaut doit exister dans la liste des variantes.',
                    fieldKey: const Key('pokedex-media-default-form-field'),
                    controller: _defaultFormIdController,
                    enabled: !_isSaving,
                    placeholder: 'base',
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Variantes média',
                    description:
                        'Une ligne par variante : variantId|front|back|frontShiny|backShiny|icon|party|overworld|portrait|cry.',
                    fieldKey: const Key('pokedex-media-variants-field'),
                    controller: _variantEntriesController,
                    enabled: !_isSaving,
                    minLines: 4,
                    maxLines: 10,
                    placeholder:
                        'base|assets/pokemon/sprites/bulbasaur/front.png|assets/pokemon/sprites/bulbasaur/back.png|||assets/pokemon/sprites/bulbasaur/icon.png|assets/pokemon/sprites/bulbasaur/party.png||assets/pokemon/portraits/bulbasaur.png|assets/pokemon/cries/bulbasaur.ogg',
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Animations',
                    description:
                        'Une ligne par animation : variantId|animationKey|sheet|animationId.',
                    fieldKey: const Key('pokedex-media-animations-field'),
                    controller: _animationEntriesController,
                    enabled: !_isSaving,
                    minLines: 3,
                    maxLines: 8,
                    placeholder:
                        'base|battleFront|assets/pokemon/sprites/bulbasaur/battle_front_sheet.png|battle_front',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      CupertinoButton.filled(
                        key: const Key('pokedex-save-media-button'),
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
                        key: const Key('pokedex-cancel-media-button'),
                        onPressed: _isSaving ? null : _cancelEditing,
                        child: const Text('Annuler'),
                      ),
                    ],
                  ),
                  if (_saveErrorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _saveErrorMessage!,
                      key: const Key('pokedex-media-save-error'),
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
            if (media == null)
              _PokedexMissingSection(
                key: const Key('pokedex-media-missing'),
                title: 'Médias',
                message: mediaRef.isEmpty
                    ? 'La ref média est vide dans l’espèce locale ; aucun média ne peut être édité depuis cette fiche.'
                    : 'Aucune donnée média locale trouvée pour cette espèce. Vous pouvez en créer une depuis cet onglet.',
              )
            else ...[
              _PokedexDetailSectionCard(
                title: 'Variante par défaut',
                child: Column(
                  children: [
                    _PokedexPropertyLine(
                      label: 'Forme par défaut',
                      value: media.defaultFormId,
                    ),
                    _PokedexPropertyLine(
                      label: 'Variantes déclarées',
                      value: media.variants.keys.join(', '),
                    ),
                  ],
                ),
              ),
              for (final entry in media.variants.entries) ...[
                const SizedBox(height: 12),
                _PokedexDetailSectionCard(
                  title: entry.key == media.defaultFormId
                      ? 'Variante ${entry.key} (défaut)'
                      : 'Variante ${entry.key}',
                  child: Column(
                    children: [
                      _PokedexPropertyLine(
                        label: 'front',
                        value: entry.value.frontStatic ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'back',
                        value: entry.value.backStatic ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'front shiny',
                        value: entry.value.frontShinyStatic ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'back shiny',
                        value: entry.value.backShinyStatic ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'icon',
                        value: entry.value.icon ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'party',
                        value: entry.value.party ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'overworld',
                        value: entry.value.overworld ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'portrait',
                        value: entry.value.portrait ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'cry',
                        value: entry.value.cry ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'Animations',
                        value: entry.value.animations.isEmpty
                            ? 'Aucune animation locale déclarée.'
                            : entry.value.animations.entries
                                .map(
                                  (animation) =>
                                      '${animation.key}: ${animation.value.animationId}',
                                )
                                .join(', '),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const _PokedexDetailSectionCard(
                title: 'Contrat média',
                child: Text(
                  'Les médias Pokémon restent de simples références locales vers assets/pokemon/... et n’utilisent jamais de GIF.',
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
                    mediaRef.isEmpty
                        ? 'Impossible d’éditer ces médias tant que la ref locale est vide.'
                        : 'Les chemins restent de simples refs locales cohérentes avec le contrat média actuel.',
                  ),
                  if (mediaRef.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    CupertinoButton(
                      key: const Key('pokedex-edit-media-button'),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _replaceDraftFromDetail(widget.detail);
                          _isEditing = true;
                          _saveErrorMessage = null;
                        });
                      },
                      child:
                          Text(media == null ? 'Créer localement' : 'Modifier'),
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
