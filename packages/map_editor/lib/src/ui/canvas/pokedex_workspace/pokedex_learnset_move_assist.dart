part of 'pokedex_workspace_page.dart';

const PokemonMovesCatalogLookupService _movesCatalogLookupService =
    PokemonMovesCatalogLookupService();

// Assistance "moves-first" du lot 5.
//
// Choix assumé :
// - on garde les textareas existantes comme source de vérité du learnset ;
// - on ajoute une aide locale pour chercher un move du catalogue et générer des
//   lignes valides plus facilement ;
// - on n'introduit donc ni second éditeur learnset, ni pipeline parallèle.

class _PokedexLearnsetMovesAssistBanner extends StatelessWidget {
  const _PokedexLearnsetMovesAssistBanner({
    required this.catalogView,
    required this.isCatalogLoading,
    required this.catalogLoadError,
  });

  final PokemonMovesCatalogView? catalogView;
  final bool isCatalogLoading;
  final String? catalogLoadError;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final accent = catalogLoadError != null ||
            (catalogView != null && !catalogView!.isAvailable)
        ? EditorChrome.inspectorJoyCoral
        : EditorChrome.accentJade;

    final message = switch ((isCatalogLoading, catalogView?.isAvailable)) {
      (true, _) =>
        'Chargement du catalogue local des attaques… La saisie brute reste possible pendant ce chargement.',
      (_, true) =>
        'Recherche locale active sur ${catalogView!.entries.length} moves. Les ids inconnus restent visibles et sont signalés comme absents du catalogue.',
      _ when catalogLoadError != null =>
        'Impossible de lire le catalogue local des attaques. Vous pouvez encore éditer les ids bruts, mais sans assistance locale.\n$catalogLoadError',
      _ when catalogView?.message != null =>
        'Catalogue local indisponible. Vous pouvez encore éditer les ids bruts, mais sans assistance locale.\n${catalogView!.message}',
      _ =>
        'Catalogue local indisponible. Vous pouvez encore éditer les ids bruts, mais sans assistance locale.',
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            children: [
              TextSpan(
                text: 'Assistance moves-first',
                style: TextStyle(
                  color: label,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(text: '\n'),
              TextSpan(text: message),
            ],
          ),
        ),
      ),
    );
  }
}

class _PokedexMoveCatalogPicker extends StatefulWidget {
  const _PokedexMoveCatalogPicker({
    required this.sectionKeyPrefix,
    required this.catalogView,
    required this.isCatalogLoading,
    required this.enabled,
    required this.onMoveSelected,
    this.searchPlaceholder = 'Chercher un move local',
  });

  final String sectionKeyPrefix;
  final PokemonMovesCatalogView? catalogView;
  final bool isCatalogLoading;
  final bool enabled;
  final ValueChanged<PokemonMoveCatalogEntryView> onMoveSelected;
  final String searchPlaceholder;

  @override
  State<_PokedexMoveCatalogPicker> createState() =>
      _PokedexMoveCatalogPickerState();
}

class _PokedexMoveCatalogPickerState extends State<_PokedexMoveCatalogPicker> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()..addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  void _selectMove(PokemonMoveCatalogEntryView entry) {
    widget.onMoveSelected(entry);
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final view = widget.catalogView;
    final canSearch = widget.enabled &&
        !widget.isCatalogLoading &&
        view != null &&
        view.isAvailable &&
        view.entries.isNotEmpty;
    final suggestions = canSearch
        ? _movesCatalogLookupService.search(
            view.entries,
            _searchController.text,
            limit: 8,
          )
        : const <PokemonMoveCatalogEntryView>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoTextField(
          key: Key('${widget.sectionKeyPrefix}-search-field'),
          controller: _searchController,
          enabled: canSearch,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          placeholder: widget.isCatalogLoading
              ? 'Chargement du catalogue local…'
              : widget.searchPlaceholder,
          onSubmitted: (_) {
            if (suggestions.isNotEmpty) {
              _selectMove(suggestions.first);
            }
          },
        ),
        const SizedBox(height: 6),
        Text(
          canSearch
              ? 'Recherche locale par id ou nom. Entrée sur le premier résultat, clic pour sélectionner.'
              : 'La recherche assistée reste indisponible tant que le catalogue local ne peut pas être lu.',
          style: TextStyle(
            color: subtle,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        if (_searchController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          if (!canSearch)
            Text(
              'Aucune suggestion locale disponible pour le moment.',
              key: Key('${widget.sectionKeyPrefix}-search-unavailable'),
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (suggestions.isEmpty)
            Text(
              'Aucun move local ne correspond à cette recherche.',
              key: Key('${widget.sectionKeyPrefix}-search-empty'),
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Container(
              key: Key('${widget.sectionKeyPrefix}-suggestions'),
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final entry = suggestions[index];
                  return _PokedexMoveSuggestionTile(
                    key: Key(
                        '${widget.sectionKeyPrefix}-suggestion-${entry.id}'),
                    entry: entry,
                    onTap: widget.enabled ? () => _selectMove(entry) : null,
                  );
                },
              ),
            ),
        ],
      ],
    );
  }
}

class _PokedexMoveSuggestionTile extends StatelessWidget {
  const _PokedexMoveSuggestionTile({
    super.key,
    required this.entry,
    required this.onTap,
  });

  final PokemonMoveCatalogEntryView entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onPressed: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.name} • ${entry.id}',
                    style: TextStyle(
                      color: label,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (entry.type != null) entry.type!,
                      if (entry.category != null) entry.category!,
                      if (entry.pp != null) 'PP ${entry.pp}',
                    ].join(' • '),
                    style: TextStyle(
                      color: subtle,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Sélectionner',
              style: TextStyle(
                color: label,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PokedexSimpleMoveAssistEditor extends StatelessWidget {
  const _PokedexSimpleMoveAssistEditor({
    required this.title,
    required this.description,
    required this.fieldKey,
    required this.controller,
    required this.enabled,
    required this.placeholder,
    required this.sectionKeyPrefix,
    required this.catalogView,
    required this.isCatalogLoading,
  });

  final String title;
  final String description;
  final Key fieldKey;
  final TextEditingController controller;
  final bool enabled;
  final String placeholder;
  final String sectionKeyPrefix;
  final PokemonMovesCatalogView? catalogView;
  final bool isCatalogLoading;

  @override
  Widget build(BuildContext context) {
    return _PokedexDetailSectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description),
          const SizedBox(height: 10),
          _PokedexMoveCatalogPicker(
            sectionKeyPrefix: sectionKeyPrefix,
            catalogView: catalogView,
            isCatalogLoading: isCatalogLoading,
            enabled: enabled,
            onMoveSelected: (entry) {
              _appendLearnsetLine(
                controller,
                entry.id,
                deduplicateExact: true,
              );
            },
            searchPlaceholder: 'Chercher un move pour cette section',
          ),
          const SizedBox(height: 10),
          _PokedexSimpleMovePreview(
            key: Key('$sectionKeyPrefix-preview'),
            controller: controller,
            catalogView: catalogView,
            emptyLabel: 'Aucun move saisi pour cette section.',
          ),
          const SizedBox(height: 10),
          _PokedexEditorTextField(
            label: 'Saisie brute',
            description:
                'Les ids legacy restent visibles. L’assistance ajoute simplement des move ids existants sans masquer le texte brut.',
            fieldKey: fieldKey,
            controller: controller,
            enabled: enabled,
            minLines: 2,
            maxLines: 5,
            placeholder: placeholder,
          ),
        ],
      ),
    );
  }
}

class _PokedexMoveEntryAssistEditor extends StatefulWidget {
  const _PokedexMoveEntryAssistEditor({
    required this.title,
    required this.description,
    required this.fieldKey,
    required this.controller,
    required this.enabled,
    required this.placeholder,
    required this.sectionKeyPrefix,
    required this.catalogView,
    required this.isCatalogLoading,
  });

  final String title;
  final String description;
  final Key fieldKey;
  final TextEditingController controller;
  final bool enabled;
  final String placeholder;
  final String sectionKeyPrefix;
  final PokemonMovesCatalogView? catalogView;
  final bool isCatalogLoading;

  @override
  State<_PokedexMoveEntryAssistEditor> createState() =>
      _PokedexMoveEntryAssistEditorState();
}

class _PokedexMoveEntryAssistEditorState
    extends State<_PokedexMoveEntryAssistEditor> {
  late final TextEditingController _versionGroupController;
  PokemonMoveCatalogEntryView? _selectedMove;

  @override
  void initState() {
    super.initState();
    _versionGroupController = TextEditingController()
      ..addListener(_onComposerFieldChanged);
  }

  @override
  void dispose() {
    _versionGroupController
      ..removeListener(_onComposerFieldChanged)
      ..dispose();
    super.dispose();
  }

  void _onComposerFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _canAdd {
    return widget.enabled &&
        _selectedMove != null &&
        _versionGroupController.text.trim().isNotEmpty;
  }

  void _addSelectedMove() {
    final selectedMove = _selectedMove;
    if (selectedMove == null) {
      return;
    }

    final versionGroup = _versionGroupController.text.trim();
    if (versionGroup.isEmpty) {
      return;
    }

    _appendLearnsetLine(
      widget.controller,
      '${selectedMove.id}|$versionGroup',
    );

    setState(() {
      _selectedMove = null;
      _versionGroupController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _PokedexDetailSectionCard(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.description),
          const SizedBox(height: 10),
          _PokedexMoveCatalogPicker(
            sectionKeyPrefix: widget.sectionKeyPrefix,
            catalogView: widget.catalogView,
            isCatalogLoading: widget.isCatalogLoading,
            enabled: widget.enabled,
            onMoveSelected: (entry) {
              setState(() {
                _selectedMove = entry;
              });
            },
            searchPlaceholder: 'Chercher un move à insérer',
          ),
          const SizedBox(height: 10),
          _PokedexSelectedMoveComposer(
            title: 'Ajout assisté',
            selectedMove: _selectedMove,
            enabled: widget.enabled,
            children: [
              Expanded(
                child: _PokedexCompactEditorField(
                  label: 'Version group',
                  fieldKey: Key('${widget.sectionKeyPrefix}-version-group'),
                  controller: _versionGroupController,
                  enabled: widget.enabled,
                  placeholder: 'scarlet-violet',
                ),
              ),
              const SizedBox(width: 10),
              CupertinoButton.filled(
                key: Key('${widget.sectionKeyPrefix}-add-button'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                onPressed: _canAdd ? _addSelectedMove : null,
                child: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PokedexStructuredMovePreview(
            key: Key('${widget.sectionKeyPrefix}-preview'),
            controller: widget.controller,
            catalogView: widget.catalogView,
            emptyLabel: 'Aucune entrée déclarée pour cette section.',
            parser: (raw) => _parseLearnsetMoveEntries(raw,
                label: widget.title.toLowerCase()),
            lineBuilder: (entry, resolvedMove) => _ResolvedLearnsetMoveLine(
              moveId: entry.moveId,
              catalogAvailable: widget.catalogView?.isAvailable == true,
              resolvedMove: resolvedMove,
              subtitle: entry.versionGroup,
            ),
          ),
          const SizedBox(height: 10),
          _PokedexEditorTextField(
            label: 'Saisie brute',
            description:
                'Le texte reste la source de vérité. L’ajout assisté prépare simplement des lignes valides.',
            fieldKey: widget.fieldKey,
            controller: widget.controller,
            enabled: widget.enabled,
            minLines: 2,
            maxLines: 6,
            placeholder: widget.placeholder,
          ),
        ],
      ),
    );
  }
}

class _PokedexLevelUpAssistEditor extends StatefulWidget {
  const _PokedexLevelUpAssistEditor({
    required this.title,
    required this.description,
    required this.fieldKey,
    required this.controller,
    required this.enabled,
    required this.placeholder,
    required this.sectionKeyPrefix,
    required this.catalogView,
    required this.isCatalogLoading,
  });

  final String title;
  final String description;
  final Key fieldKey;
  final TextEditingController controller;
  final bool enabled;
  final String placeholder;
  final String sectionKeyPrefix;
  final PokemonMovesCatalogView? catalogView;
  final bool isCatalogLoading;

  @override
  State<_PokedexLevelUpAssistEditor> createState() =>
      _PokedexLevelUpAssistEditorState();
}

class _PokedexLevelUpAssistEditorState
    extends State<_PokedexLevelUpAssistEditor> {
  late final TextEditingController _levelController;
  late final TextEditingController _sourceController;
  late final TextEditingController _versionGroupController;
  PokemonMoveCatalogEntryView? _selectedMove;

  @override
  void initState() {
    super.initState();
    _levelController = TextEditingController()..addListener(_onFieldChanged);
    _sourceController = TextEditingController(text: 'level_up')
      ..addListener(_onFieldChanged);
    _versionGroupController = TextEditingController()
      ..addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _levelController
      ..removeListener(_onFieldChanged)
      ..dispose();
    _sourceController
      ..removeListener(_onFieldChanged)
      ..dispose();
    _versionGroupController
      ..removeListener(_onFieldChanged)
      ..dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _hasValidLevel {
    final level = int.tryParse(_levelController.text.trim());
    return level != null && level >= 1;
  }

  bool get _canAdd {
    return widget.enabled &&
        _selectedMove != null &&
        _hasValidLevel &&
        _sourceController.text.trim().isNotEmpty &&
        _versionGroupController.text.trim().isNotEmpty;
  }

  void _addSelectedMove() {
    final selectedMove = _selectedMove;
    final level = int.tryParse(_levelController.text.trim());
    final source = _sourceController.text.trim();
    final versionGroup = _versionGroupController.text.trim();
    if (selectedMove == null ||
        level == null ||
        level < 1 ||
        source.isEmpty ||
        versionGroup.isEmpty) {
      return;
    }

    _appendLearnsetLine(
      widget.controller,
      '${selectedMove.id}|$level|$source|$versionGroup',
    );

    setState(() {
      _selectedMove = null;
      _levelController.clear();
      _versionGroupController.clear();
      _sourceController.text = 'level_up';
    });
  }

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return _PokedexDetailSectionCard(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.description),
          const SizedBox(height: 10),
          _PokedexMoveCatalogPicker(
            sectionKeyPrefix: widget.sectionKeyPrefix,
            catalogView: widget.catalogView,
            isCatalogLoading: widget.isCatalogLoading,
            enabled: widget.enabled,
            onMoveSelected: (entry) {
              setState(() {
                _selectedMove = entry;
              });
            },
            searchPlaceholder: 'Chercher un move level-up',
          ),
          const SizedBox(height: 10),
          _PokedexSelectedMoveComposer(
            title: 'Ajout assisté',
            selectedMove: _selectedMove,
            enabled: widget.enabled,
            children: [
              Expanded(
                child: _PokedexCompactEditorField(
                  label: 'Niveau',
                  fieldKey: Key('${widget.sectionKeyPrefix}-level'),
                  controller: _levelController,
                  enabled: widget.enabled,
                  placeholder: '7',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PokedexCompactEditorField(
                  label: 'Source',
                  fieldKey: Key('${widget.sectionKeyPrefix}-source'),
                  controller: _sourceController,
                  enabled: widget.enabled,
                  placeholder: 'level_up',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PokedexCompactEditorField(
                  label: 'Version group',
                  fieldKey: Key('${widget.sectionKeyPrefix}-version-group'),
                  controller: _versionGroupController,
                  enabled: widget.enabled,
                  placeholder: 'scarlet-violet',
                ),
              ),
              const SizedBox(width: 10),
              CupertinoButton.filled(
                key: Key('${widget.sectionKeyPrefix}-add-button'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                onPressed: _canAdd ? _addSelectedMove : null,
                child: const Text('Ajouter'),
              ),
            ],
          ),
          if (_levelController.text.trim().isNotEmpty && !_hasValidLevel) ...[
            const SizedBox(height: 6),
            Text(
              'Le niveau doit être un entier supérieur ou égal à 1.',
              key: Key('${widget.sectionKeyPrefix}-level-error'),
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'Le picker ajoute une ligne complète, mais la saisie brute reste disponible pour les cas plus atypiques.',
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 10),
          _PokedexStructuredMovePreview(
            key: Key('${widget.sectionKeyPrefix}-preview'),
            controller: widget.controller,
            catalogView: widget.catalogView,
            emptyLabel: 'Aucune entrée level-up déclarée.',
            parser: _parseLearnsetLevelUpEntries,
            lineBuilder: (entry, resolvedMove) => _ResolvedLearnsetMoveLine(
              moveId: entry.moveId,
              catalogAvailable: widget.catalogView?.isAvailable == true,
              resolvedMove: resolvedMove,
              subtitle:
                  'Niveau ${entry.level} • ${entry.source} • ${entry.versionGroup}',
            ),
          ),
          const SizedBox(height: 10),
          _PokedexEditorTextField(
            label: 'Saisie brute',
            description:
                'Le texte reste la source de vérité. L’ajout assisté génère une ligne valide sans masquer les ids legacy déjà présents.',
            fieldKey: widget.fieldKey,
            controller: widget.controller,
            enabled: widget.enabled,
            minLines: 3,
            maxLines: 8,
            placeholder: widget.placeholder,
          ),
        ],
      ),
    );
  }
}

class _PokedexSelectedMoveComposer extends StatelessWidget {
  const _PokedexSelectedMoveComposer({
    required this.title,
    required this.selectedMove,
    required this.enabled,
    required this.children,
  });

  final String title;
  final PokemonMoveCatalogEntryView? selectedMove;
  final bool enabled;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: EditorChrome.primaryLabel(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              selectedMove == null
                  ? 'Sélectionnez d’abord un move du catalogue local pour préparer une nouvelle ligne.'
                  : 'Move sélectionné : ${selectedMove!.name} • ${selectedMove!.id}',
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            IgnorePointer(
              ignoring: !enabled,
              child: Row(children: children),
            ),
          ],
        ),
      ),
    );
  }
}

class _PokedexCompactEditorField extends StatelessWidget {
  const _PokedexCompactEditorField({
    required this.label,
    required this.fieldKey,
    required this.controller,
    required this.enabled,
    this.placeholder,
  });

  final String label;
  final Key fieldKey;
  final TextEditingController controller;
  final bool enabled;
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    final labelColor = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          key: fieldKey,
          controller: controller,
          enabled: enabled,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          placeholder: placeholder,
          placeholderStyle: TextStyle(
            color: subtle,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PokedexSimpleMovePreview extends StatelessWidget {
  const _PokedexSimpleMovePreview({
    super.key,
    required this.controller,
    required this.catalogView,
    required this.emptyLabel,
  });

  final TextEditingController controller;
  final PokemonMovesCatalogView? catalogView;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final moveIds = _splitNonEmptyLines(value.text);
        if (moveIds.isEmpty) {
          return Text(emptyLabel);
        }

        return _PokedexResolvedMoveList(
          rows: moveIds
              .map(
                (moveId) => _ResolvedLearnsetMoveLine(
                  moveId: moveId,
                  catalogAvailable: catalogView?.isAvailable == true,
                  resolvedMove: _resolveMove(catalogView, moveId),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _PokedexStructuredMovePreview<T> extends StatelessWidget {
  const _PokedexStructuredMovePreview({
    super.key,
    required this.controller,
    required this.catalogView,
    required this.emptyLabel,
    required this.parser,
    required this.lineBuilder,
  });

  final TextEditingController controller;
  final PokemonMovesCatalogView? catalogView;
  final String emptyLabel;
  final List<T> Function(String raw) parser;
  final _ResolvedLearnsetMoveLine Function(
    T entry,
    PokemonMoveCatalogEntryView? resolvedMove,
  ) lineBuilder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final rawText = value.text.trimRight();
        if (rawText.trim().isEmpty) {
          return Text(emptyLabel);
        }

        try {
          final entries = parser(rawText);
          if (entries.isEmpty) {
            return Text(emptyLabel);
          }

          return _PokedexResolvedMoveList(
            rows: entries
                .map(
                  (entry) => lineBuilder(
                    entry,
                    _resolveMove(
                      catalogView,
                      _extractLearnsetMoveId(entry as Object),
                    ),
                  ),
                )
                .toList(growable: false),
          );
        } on EditorApplicationException catch (error) {
          return Text(
            error.message,
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          );
        }
      },
    );
  }
}

class _PokedexResolvedMoveList extends StatelessWidget {
  const _PokedexResolvedMoveList({
    required this.rows,
  });

  final List<_ResolvedLearnsetMoveLine> rows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: rows
              .map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: row,
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _ResolvedLearnsetMoveLine extends StatelessWidget {
  const _ResolvedLearnsetMoveLine({
    required this.moveId,
    required this.catalogAvailable,
    this.resolvedMove,
    this.subtitle,
  });

  final String moveId;
  final bool catalogAvailable;
  final PokemonMoveCatalogEntryView? resolvedMove;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final isUnknown = catalogAvailable && resolvedMove == null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resolvedMove == null
                    ? moveId
                    : '${resolvedMove!.name} • ${resolvedMove!.id}',
                style: TextStyle(
                  color: label,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: !catalogAvailable
                ? EditorChrome.accentWarm.withValues(alpha: 0.12)
                : isUnknown
                    ? EditorChrome.inspectorJoyCoral.withValues(alpha: 0.12)
                    : EditorChrome.accentJade.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: (!catalogAvailable
                      ? EditorChrome.accentWarm
                      : isUnknown
                          ? EditorChrome.inspectorJoyCoral
                          : EditorChrome.accentJade)
                  .withValues(alpha: 0.28),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              !catalogAvailable
                  ? 'Résolution indisponible'
                  : isUnknown
                      ? 'Absent du catalogue local'
                      : 'Résolu localement',
              style: TextStyle(
                color: !catalogAvailable
                    ? EditorChrome.accentWarm
                    : isUnknown
                        ? EditorChrome.inspectorJoyCoral
                        : EditorChrome.accentJade,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

PokemonMoveCatalogEntryView? _resolveMove(
  PokemonMovesCatalogView? catalogView,
  String moveId,
) {
  if (catalogView == null || !catalogView.isAvailable) {
    return null;
  }
  return _movesCatalogLookupService.findById(catalogView.entries, moveId);
}

String _extractLearnsetMoveId(Object entry) {
  return switch (entry) {
    final PokemonLearnsetLevelUpEntry levelUpEntry => levelUpEntry.moveId,
    final PokemonLearnsetMoveEntry moveEntry => moveEntry.moveId,
    _ => throw StateError('Unsupported learnset preview entry type: $entry'),
  };
}

void _appendLearnsetLine(
  TextEditingController controller,
  String line, {
  bool deduplicateExact = false,
}) {
  final trimmedLine = line.trim();
  if (trimmedLine.isEmpty) {
    return;
  }

  final currentLines = LineSplitter.split(controller.text)
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: true);

  if (deduplicateExact && currentLines.contains(trimmedLine)) {
    return;
  }

  currentLines.add(trimmedLine);
  final nextText = currentLines.join('\n');
  controller.value = TextEditingValue(
    text: nextText,
    selection: TextSelection.collapsed(offset: nextText.length),
  );
}
