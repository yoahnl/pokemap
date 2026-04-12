part of 'pokedex_workspace_page.dart';

// Barre d'outils locale du Pokédex.
//
// On sépare la recherche textuelle et le résumé des filtres pour que le haut du
// workspace reste lisible même quand la liste est vide ou très courte.

class _PokedexSimpleFiltersBar extends StatelessWidget {
  const _PokedexSimpleFiltersBar({
    required this.availableTypes,
    required this.selectedType,
    required this.onTypeChanged,
    required this.availableGenerations,
    required this.selectedGeneration,
    required this.onGenerationChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  final List<String> availableTypes;
  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final List<String> availableGenerations;
  final String selectedGeneration;
  final ValueChanged<String> onGenerationChanged;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const Key('pokedex-filters-panel'),
      spacing: 12,
      runSpacing: 12,
      children: [
        _PokedexFilterDropdown(
          label: 'Type',
          popupKey: const Key('pokedex-type-filter'),
          value: selectedType,
          onChanged: onTypeChanged,
          items: <String>[
            _PokedexFilterDropdown.allTypesValue,
            ...availableTypes,
          ],
          itemLabelBuilder: (value) {
            if (value == _PokedexFilterDropdown.allTypesValue) {
              return 'Tous types';
            }
            return value;
          },
        ),
        _PokedexFilterDropdown(
          label: 'Génération',
          popupKey: const Key('pokedex-generation-filter'),
          value: selectedGeneration,
          onChanged: onGenerationChanged,
          items: <String>[
            _PokedexFilterDropdown.allGenerationsValue,
            ...availableGenerations,
          ],
          itemLabelBuilder: (value) {
            if (value == _PokedexFilterDropdown.allGenerationsValue) {
              return 'Toutes gén.';
            }
            return 'Génération $value';
          },
        ),
        _PokedexFilterDropdown(
          label: 'Statut',
          popupKey: const Key('pokedex-status-filter'),
          value: selectedStatus,
          onChanged: onStatusChanged,
          items: const <String>[
            _PokedexFilterDropdown.allStatusesValue,
            _PokedexFilterDropdown.enabledOnlyValue,
            _PokedexFilterDropdown.disabledOnlyValue,
          ],
          itemLabelBuilder: (value) {
            switch (value) {
              case _PokedexFilterDropdown.allStatusesValue:
                return 'Toutes';
              case _PokedexFilterDropdown.enabledOnlyValue:
                return 'Activées';
              case _PokedexFilterDropdown.disabledOnlyValue:
                return 'Désactivées';
            }
            return value;
          },
        ),
      ],
    );
  }
}

class _PokedexSearchField extends StatefulWidget {
  const _PokedexSearchField({
    required this.query,
    required this.onChanged,
  });

  final String query;
  final ValueChanged<String> onChanged;

  @override
  State<_PokedexSearchField> createState() => _PokedexSearchFieldState();
}

class _PokedexSearchFieldState extends State<_PokedexSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _PokedexSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentWarm.withValues(alpha: 0.28);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.search,
              color: subtle,
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CupertinoTextField.borderless(
                key: const Key('pokedex-search-field'),
                controller: _controller,
                onChanged: widget.onChanged,
                clearButtonMode: OverlayVisibilityMode.editing,
                placeholder: 'Rechercher un Pokémon, un ID ou un numéro',
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
