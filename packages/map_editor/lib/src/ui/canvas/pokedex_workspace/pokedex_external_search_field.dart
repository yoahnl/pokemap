part of 'pokedex_workspace_page.dart';

/// Champ d'auto-complétion mono-espèce du wizard externe.
///
/// Ce widget reste volontairement présentation + interaction locale :
/// - il n'analyse pas la requête ;
/// - il ne parle pas au réseau ;
/// - il n'importe rien ;
/// - il reflète simplement le résultat applicatif reçu du use case.
///
/// On utilise `RawAutocomplete` pour une raison précise :
/// - navigation clavier honnête sans réinventer un mini-système focus ;
/// - sélection souris explicite ;
/// - aucune sélection implicite tant que l'utilisateur n'agit pas.
class _PokedexExternalSpeciesAutocompleteField extends StatefulWidget {
  const _PokedexExternalSpeciesAutocompleteField({
    required this.controller,
    required this.focusNode,
    required this.isBusy,
    required this.isSearching,
    required this.searchResult,
    required this.selectedSuggestion,
    required this.onQueryChanged,
    required this.onSuggestionSelected,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isBusy;
  final bool isSearching;
  final PokemonExternalSpeciesSearchResult searchResult;
  final PokemonExternalSpeciesSuggestion? selectedSuggestion;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<PokemonExternalSpeciesSuggestion> onSuggestionSelected;

  @override
  State<_PokedexExternalSpeciesAutocompleteField> createState() =>
      _PokedexExternalSpeciesAutocompleteFieldState();
}

class _PokedexExternalSpeciesAutocompleteFieldState
    extends State<_PokedexExternalSpeciesAutocompleteField> {
  int? _highlightedSuggestionIndex;

  List<PokemonExternalSpeciesSuggestion> get _visibleSuggestions =>
      widget.searchResult.hasSuggestions && widget.selectedSuggestion == null
          ? widget.searchResult.suggestions
          : const <PokemonExternalSpeciesSuggestion>[];

  @override
  void initState() {
    super.initState();
    _syncHighlightedSuggestion();
  }

  @override
  void didUpdateWidget(_PokedexExternalSpeciesAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchResult.kind != widget.searchResult.kind ||
        !listEquals(
          oldWidget.searchResult.suggestions,
          widget.searchResult.suggestions,
        ) ||
        oldWidget.selectedSuggestion != widget.selectedSuggestion) {
      _syncHighlightedSuggestion();
    }
  }

  void _syncHighlightedSuggestion() {
    final suggestions = _visibleSuggestions;
    if (suggestions.isEmpty) {
      _highlightedSuggestionIndex = null;
      return;
    }
    if (_highlightedSuggestionIndex == null ||
        _highlightedSuggestionIndex! >= suggestions.length) {
      _highlightedSuggestionIndex = 0;
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final suggestions = _visibleSuggestions;
    if (suggestions.isEmpty || widget.selectedSuggestion != null) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        final currentIndex = _highlightedSuggestionIndex ?? -1;
        _highlightedSuggestionIndex =
            (currentIndex + 1).clamp(0, suggestions.length - 1);
      });
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        final currentIndex = _highlightedSuggestionIndex ?? 0;
        _highlightedSuggestionIndex =
            (currentIndex - 1).clamp(0, suggestions.length - 1);
      });
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final selectedIndex = _highlightedSuggestionIndex ?? 0;
      widget.onSuggestionSelected(suggestions[selectedIndex]);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _visibleSuggestions;

    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CupertinoTextField(
            key: const Key('pokedex-import-external-query-field'),
            controller: widget.controller,
            focusNode: widget.focusNode,
            placeholder: 'Ex. pikachu, bulbasaur ou 25',
            enabled: !widget.isBusy,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            onChanged: widget.onQueryChanged,
            onSubmitted: (_) {
              final selectedIndex = _highlightedSuggestionIndex;
              if (selectedIndex == null ||
                  selectedIndex < 0 ||
                  selectedIndex >= suggestions.length) {
                return;
              }
              widget.onSuggestionSelected(suggestions[selectedIndex]);
            },
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              key: const Key('pokedex-import-external-suggestions-list'),
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 260),
              decoration: BoxDecoration(
                color: EditorChrome.islandFillElevated(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: EditorChrome.accentJade.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => Container(
                  height: 1,
                  color: EditorChrome.subtleSeparator(context),
                ),
                itemBuilder: (context, index) {
                  final option = suggestions[index];
                  final isHighlighted = _highlightedSuggestionIndex == index;
                  return MouseRegion(
                    onEnter: (_) {
                      if (_highlightedSuggestionIndex == index) {
                        return;
                      }
                      setState(() {
                        _highlightedSuggestionIndex = index;
                      });
                    },
                    child: GestureDetector(
                      key: Key(
                        'pokedex-import-external-suggestion-${option.speciesId}',
                      ),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onSuggestionSelected(option),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? EditorChrome.accentJade.withValues(alpha: 0.16)
                              : CupertinoColors.transparent,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Text(
                                '#${option.nationalDex.toString().padLeft(4, '0')}',
                                style: TextStyle(
                                  color: EditorChrome.subtleLabel(context),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option.primaryName,
                                      style: TextStyle(
                                        color: EditorChrome.primaryLabel(
                                          context,
                                        ),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      option.speciesId,
                                      style: TextStyle(
                                        color: EditorChrome.subtleLabel(
                                          context,
                                        ),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (option.generation != null)
                                Text(
                                  'Gen ${option.generation}',
                                  style: TextStyle(
                                    color: EditorChrome.subtleLabel(context),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (widget.selectedSuggestion != null) ...[
            Container(
              key: const Key('pokedex-import-external-selected-suggestion'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: EditorChrome.accentJade.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: EditorChrome.accentJade.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.check_mark_circled_solid,
                    size: 18,
                    color: EditorChrome.accentJade,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sélection retenue : #${widget.selectedSuggestion!.nationalDex.toString().padLeft(4, '0')} ${widget.selectedSuggestion!.primaryName} · ${widget.selectedSuggestion!.speciesId}',
                      style: TextStyle(
                        color: EditorChrome.primaryLabel(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (widget.isSearching)
            Row(
              key: const Key('pokedex-import-external-search-loading'),
              children: const [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: ProgressCircle(),
                ),
                SizedBox(width: 10),
                Text(
                  'Recherche des suggestions externes…',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          else
            _PokedexExternalSpeciesSearchMessage(
              searchResult: widget.searchResult,
              selectedSuggestion: widget.selectedSuggestion,
            ),
        ],
      ),
    );
  }
}

class _PokedexExternalSpeciesSearchMessage extends StatelessWidget {
  const _PokedexExternalSpeciesSearchMessage({
    required this.searchResult,
    required this.selectedSuggestion,
  });

  final PokemonExternalSpeciesSearchResult searchResult;
  final PokemonExternalSpeciesSuggestion? selectedSuggestion;

  @override
  Widget build(BuildContext context) {
    if (selectedSuggestion != null) {
      return Text(
        'La prévisualisation utilisera uniquement l’espèce explicitement sélectionnée ci-dessus.',
        style: TextStyle(
          color: EditorChrome.subtleLabel(context),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      );
    }

    if (searchResult.kind == PokemonExternalSpeciesSearchResultKind.empty) {
      return Text(
        'Tapez un nom, un slug ou un numéro dex, puis sélectionnez explicitement une suggestion.',
        key: const Key('pokedex-import-external-search-idle-message'),
        style: TextStyle(
          color: EditorChrome.subtleLabel(context),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      );
    }

    if (searchResult.kind ==
        PokemonExternalSpeciesSearchResultKind.suggestions) {
      return Text(
        'Choisissez explicitement une suggestion pour débloquer la prévisualisation.',
        key: const Key(
            'pokedex-import-external-search-pending-selection-message'),
        style: TextStyle(
          color: EditorChrome.subtleLabel(context),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      );
    }

    final isError = searchResult.kind ==
            PokemonExternalSpeciesSearchResultKind.invalidQuery ||
        searchResult.kind == PokemonExternalSpeciesSearchResultKind.error;
    final accent =
        isError ? EditorChrome.inspectorJoyCoral : EditorChrome.accentWarm;

    return Container(
      key: const Key('pokedex-import-external-search-message'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        searchResult.message ?? 'Aucune suggestion disponible.',
        style: TextStyle(
          color: CupertinoColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}
