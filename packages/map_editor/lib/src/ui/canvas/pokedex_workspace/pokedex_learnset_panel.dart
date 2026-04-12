part of 'pokedex_workspace_page.dart';

// Onglet Learnset.
//
// Cette vue expose les sections déjà supportées par l'application sans modifier
// le contrat métier. L'objectif de ce réalignement est de rendre l'écran plus
// facile à relire et à maintenir, pas de changer la logique d'édition.

class _PokedexLearnsetTab extends StatefulWidget {
  const _PokedexLearnsetTab({
    required this.detail,
    required this.onSave,
    required this.loadMovesCatalog,
    required this.previewMovesCatalogSync,
    required this.syncMovesCatalog,
  });

  final PokedexSpeciesDetail detail;
  final Future<void> Function(UpdatePokedexSpeciesLearnsetRequest request)
      onSave;
  final Future<PokemonMovesCatalogView> Function() loadMovesCatalog;
  final Future<PokemonMovesCatalogSyncResult> Function()
      previewMovesCatalogSync;
  final Future<PokemonMovesCatalogSyncResult> Function() syncMovesCatalog;

  @override
  State<_PokedexLearnsetTab> createState() => _PokedexLearnsetTabState();
}

class _PokedexLearnsetTabState extends State<_PokedexLearnsetTab> {
  late final TextEditingController _startingMovesController;
  late final TextEditingController _relearnMovesController;
  late final TextEditingController _levelUpController;
  late final TextEditingController _tmController;
  late final TextEditingController _tutorController;
  late final TextEditingController _eggController;
  late final TextEditingController _eventController;
  late final TextEditingController _transferController;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _saveErrorMessage;

  @override
  void initState() {
    super.initState();
    _startingMovesController = TextEditingController();
    _relearnMovesController = TextEditingController();
    _levelUpController = TextEditingController();
    _tmController = TextEditingController();
    _tutorController = TextEditingController();
    _eggController = TextEditingController();
    _eventController = TextEditingController();
    _transferController = TextEditingController();
    _replaceDraftFromDetail(widget.detail);
  }

  @override
  void didUpdateWidget(covariant _PokedexLearnsetTab oldWidget) {
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
    _startingMovesController.dispose();
    _relearnMovesController.dispose();
    _levelUpController.dispose();
    _tmController.dispose();
    _tutorController.dispose();
    _eggController.dispose();
    _eventController.dispose();
    _transferController.dispose();
    super.dispose();
  }

  void _replaceDraftFromDetail(PokedexSpeciesDetail detail) {
    final learnset = detail.learnset;
    _startingMovesController.text =
        learnset == null ? '' : _formatLineList(learnset.startingMoves);
    _relearnMovesController.text =
        learnset == null ? '' : _formatLineList(learnset.relearnMoves);
    _levelUpController.text =
        learnset == null ? '' : _formatLearnsetLevelUpEntries(learnset.levelUp);
    _tmController.text =
        learnset == null ? '' : _formatLearnsetMoveEntries(learnset.tm);
    _tutorController.text =
        learnset == null ? '' : _formatLearnsetMoveEntries(learnset.tutor);
    _eggController.text =
        learnset == null ? '' : _formatLearnsetMoveEntries(learnset.egg);
    _eventController.text =
        learnset == null ? '' : _formatLearnsetMoveEntries(learnset.event);
    _transferController.text =
        learnset == null ? '' : _formatLearnsetMoveEntries(learnset.transfer);
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
        UpdatePokedexSpeciesLearnsetRequest(
          speciesId: widget.detail.species.id,
          startingMoves: _splitNonEmptyLines(_startingMovesController.text),
          relearnMoves: _splitNonEmptyLines(_relearnMovesController.text),
          levelUp: _parseLearnsetLevelUpEntries(_levelUpController.text),
          tm: _parseLearnsetMoveEntries(_tmController.text, label: 'tm'),
          tutor: _parseLearnsetMoveEntries(
            _tutorController.text,
            label: 'tutor',
          ),
          egg: _parseLearnsetMoveEntries(_eggController.text, label: 'egg'),
          event: _parseLearnsetMoveEntries(
            _eventController.text,
            label: 'event',
          ),
          transfer: _parseLearnsetMoveEntries(
            _transferController.text,
            label: 'transfer',
          ),
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
    final learnset = widget.detail.learnset;
    final learnsetRef = widget.detail.species.refs.learnset.trim();

    return SingleChildScrollView(
      key: const Key('pokedex-learnset-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PokedexMovesCatalogSection(
            loadCatalog: widget.loadMovesCatalog,
            previewSync: widget.previewMovesCatalogSync,
            syncCatalog: widget.syncMovesCatalog,
          ),
          const SizedBox(height: 12),
          if (_isEditing) ...[
            _PokedexLearnsetEditSection(
              learnsetRef: learnsetRef,
              isSaving: _isSaving,
              saveErrorMessage: _saveErrorMessage,
              startingMovesController: _startingMovesController,
              relearnMovesController: _relearnMovesController,
              levelUpController: _levelUpController,
              tmController: _tmController,
              tutorController: _tutorController,
              eggController: _eggController,
              eventController: _eventController,
              transferController: _transferController,
              onSave: _saveDraft,
              onCancel: _cancelEditing,
            ),
          ] else ...[
            _PokedexLearnsetReadOnlySection(
              learnset: learnset,
              learnsetRef: learnsetRef,
              onEditRequested: learnsetRef.isEmpty
                  ? null
                  : () {
                      setState(() {
                        _replaceDraftFromDetail(widget.detail);
                        _isEditing = true;
                        _saveErrorMessage = null;
                      });
                    },
            ),
          ],
        ],
      ),
    );
  }
}
