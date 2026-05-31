import 'package:flutter/material.dart';

import 'runtime_demo_party_seed.dart';

class RuntimePartyBuilderPanel extends StatefulWidget {
  const RuntimePartyBuilderPanel({
    super.key,
    required this.options,
    required this.members,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
  });

  final List<RuntimePartyBuilderPokemonOption> options;
  final List<RuntimeDemoPartyPokemonSeed> members;
  final bool enabled;
  final ValueChanged<RuntimeDemoPartyPokemonSeed> onAdd;
  final ValueChanged<int> onRemove;

  @override
  State<RuntimePartyBuilderPanel> createState() =>
      _RuntimePartyBuilderPanelState();
}

class _RuntimePartyBuilderPanelState extends State<RuntimePartyBuilderPanel> {
  final TextEditingController _levelController =
      TextEditingController(text: '$kRuntimeDemoSeedLevel');
  TextEditingController? _speciesTextController;
  RuntimePartyBuilderPokemonOption? _selectedOption;
  List<String?> _selectedMoveIds = List<String?>.filled(4, null);
  String? _error;

  @override
  void didUpdateWidget(RuntimePartyBuilderPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedOption = _selectedOption;
    if (selectedOption == null) {
      return;
    }
    final stillAvailable = widget.options.any(
      (option) => option.speciesId == selectedOption.speciesId,
    );
    if (!stillAvailable) {
      _selectedOption = null;
      _selectedMoveIds = List<String?>.filled(4, null);
      _speciesTextController?.clear();
      _error = null;
    }
  }

  @override
  void dispose() {
    _levelController.dispose();
    super.dispose();
  }

  int? get _parsedLevel {
    final parsed = int.tryParse(_levelController.text.trim());
    if (parsed == null || parsed < 1 || parsed > 100) {
      return null;
    }
    return parsed;
  }

  bool get _isFull => widget.members.length >= kRuntimeDemoMaxPartySize;

  bool get _canAdd {
    return widget.enabled &&
        !_isFull &&
        _selectedOption != null &&
        _parsedLevel != null &&
        _normalizedSelectedMoveIds().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Equipe de test combat',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  _isFull
                      ? 'Equipe pleine (6/6)'
                      : '${widget.members.length}/$kRuntimeDemoMaxPartySize',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: _isFull ? theme.colorScheme.error : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSpeciesAutocomplete(),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final useTwoColumns = constraints.maxWidth >= 560;
                final children = <Widget>[
                  _buildLevelField(),
                  ...List<Widget>.generate(4, _buildMoveDropdown),
                ];
                if (!useTwoColumns) {
                  return Column(
                    children: _withSpacing(children, vertical: 12),
                  );
                }
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: children
                      .map(
                        (child) => SizedBox(
                          width: (constraints.maxWidth - 12) / 2,
                          child: child,
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
            if (_selectedOption?.filteredMoveDiagnostics.isNotEmpty ??
                false) ...[
              const SizedBox(height: 12),
              _buildFilteredMoveDiagnostics(_selectedOption!),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('runtime-party-builder-add-button'),
              onPressed: _canAdd ? _addSelectedPokemon : null,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter a l equipe'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildCurrentPartyList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredMoveDiagnostics(
    RuntimePartyBuilderPokemonOption option,
  ) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.24),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.35),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.visibility_off_outlined,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Moves filtres',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: option.filteredMoveDiagnostics.map((diagnostic) {
                return Tooltip(
                  message: diagnostic.userFacingTooltip,
                  child: Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(
                      Icons.block,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                    label: Text(
                      '${diagnostic.moveId} - ${diagnostic.userFacingReason}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeciesAutocomplete() {
    return Autocomplete<RuntimePartyBuilderPokemonOption>(
      displayStringForOption: (option) => option.label,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        final options = query.isEmpty
            ? widget.options
            : widget.options.where((option) {
                return option.label.toLowerCase().contains(query) ||
                    option.speciesId.toLowerCase().contains(query);
              });
        return options.take(24);
      },
      onSelected: _selectOption,
      fieldViewBuilder: (
        context,
        textEditingController,
        focusNode,
        onFieldSubmitted,
      ) {
        _speciesTextController = textEditingController;
        return TextField(
          key: const Key('runtime-party-builder-species-field'),
          controller: textEditingController,
          focusNode: focusNode,
          enabled: widget.enabled && widget.options.isNotEmpty,
          decoration: InputDecoration(
            labelText: 'Pokemon',
            hintText: widget.options.isEmpty
                ? 'Aucune espece disponible'
                : 'Nom ou identifiant',
            border: const OutlineInputBorder(),
            suffixIcon: _selectedOption == null
                ? null
                : IconButton(
                    tooltip: 'Retirer la selection',
                    onPressed: widget.enabled ? _clearSelectedPokemon : null,
                    icon: const Icon(Icons.close),
                  ),
          ),
          onChanged: _handleSpeciesTextChanged,
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },
    );
  }

  Widget _buildLevelField() {
    return TextField(
      key: const Key('runtime-party-builder-level-field'),
      controller: _levelController,
      enabled: widget.enabled,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Niveau',
        border: OutlineInputBorder(),
      ),
      onChanged: (_) => setState(() => _error = null),
    );
  }

  Widget _buildMoveDropdown(int index) {
    final option = _selectedOption;
    final availableMoveIds = option?.availableMoveIds ?? const <String>[];
    final selectedValue = _selectedMoveIds[index];
    final normalizedValue =
        availableMoveIds.contains(selectedValue) ? selectedValue : null;

    return DropdownButtonFormField<String>(
      key: ValueKey<String>(
        'runtime-party-builder-move-$index-${option?.speciesId ?? 'none'}'
        '-${normalizedValue ?? 'none'}',
      ),
      initialValue: normalizedValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Move ${index + 1}',
        border: const OutlineInputBorder(),
      ),
      items: availableMoveIds
          .map(
            (moveId) => DropdownMenuItem<String>(
              value: moveId,
              child: Text(
                moveId,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(growable: false),
      onChanged: widget.enabled && option != null
          ? (moveId) {
              setState(() {
                _selectedMoveIds[index] = moveId;
                _error = null;
              });
            }
          : null,
    );
  }

  Widget _buildCurrentPartyList() {
    if (widget.members.isEmpty) {
      return Text(
        'Equipe vide',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List<Widget>.generate(widget.members.length, (index) {
        final member = widget.members[index];
        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              dense: true,
              title: Text('${member.speciesId} Nv.${member.level}'),
              subtitle: Text(
                member.knownMoveIds.join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                tooltip: 'Retirer',
                onPressed: widget.enabled ? () => widget.onRemove(index) : null,
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          ),
        );
      }),
    );
  }

  void _handleSpeciesTextChanged(String value) {
    final option = _findExactOption(value);
    if (option != null) {
      _selectOption(option);
      return;
    }
    if (_selectedOption != null) {
      setState(() {
        _selectedOption = null;
        _selectedMoveIds = List<String?>.filled(4, null);
        _error = null;
      });
    }
  }

  RuntimePartyBuilderPokemonOption? _findExactOption(String value) {
    final normalizedValue = value.trim().toLowerCase();
    if (normalizedValue.isEmpty) {
      return null;
    }
    for (final option in widget.options) {
      if (option.label.toLowerCase() == normalizedValue ||
          option.speciesId.toLowerCase() == normalizedValue ||
          option.displayName.toLowerCase() == normalizedValue) {
        return option;
      }
    }
    return null;
  }

  void _selectOption(RuntimePartyBuilderPokemonOption option) {
    setState(() {
      _selectedOption = option;
      _selectedMoveIds = _defaultMoveSelection(option);
      _error = null;
    });
  }

  List<String?> _defaultMoveSelection(RuntimePartyBuilderPokemonOption option) {
    final selected = <String?>[
      ...option.suggestedMoveIds
          .where(option.availableMoveIds.contains)
          .take(4),
    ];
    if (selected.isEmpty) {
      selected.addAll(option.availableMoveIds.take(4));
    }
    while (selected.length < 4) {
      selected.add(null);
    }
    return selected.take(4).toList(growable: false);
  }

  List<String> _normalizedSelectedMoveIds() {
    final moves = <String>[];
    final seen = <String>{};
    for (final moveId in _selectedMoveIds) {
      final normalized = moveId?.trim();
      if (normalized == null || normalized.isEmpty || !seen.add(normalized)) {
        continue;
      }
      moves.add(normalized);
    }
    return moves;
  }

  void _addSelectedPokemon() {
    final option = _selectedOption;
    if (_isFull) {
      setState(() => _error = 'Equipe limitee a 6 Pokemon.');
      return;
    }
    if (option == null) {
      setState(() => _error = 'Selectionnez un Pokemon.');
      return;
    }
    final level = _parsedLevel;
    if (level == null) {
      setState(() => _error = 'Le niveau doit etre entre 1 et 100.');
      return;
    }
    final moveIds = _normalizedSelectedMoveIds();
    if (moveIds.isEmpty) {
      setState(() => _error = 'Selectionnez au moins une attaque.');
      return;
    }

    widget.onAdd(
      RuntimeDemoPartyPokemonSeed(
        speciesId: option.speciesId,
        abilityId: option.abilityId,
        gender: option.gender,
        level: level,
        currentHp: _currentHpForLevel(level),
        knownMoveIds: moveIds,
      ),
    );
    setState(() => _error = null);
  }

  int _currentHpForLevel(int level) {
    final scaled = level * 4;
    return scaled < kRuntimeDemoSeedCurrentHp
        ? kRuntimeDemoSeedCurrentHp
        : scaled;
  }

  void _clearSelectedPokemon() {
    setState(() {
      _selectedOption = null;
      _selectedMoveIds = List<String?>.filled(4, null);
      _speciesTextController?.clear();
      _error = null;
    });
  }
}

List<Widget> _withSpacing(List<Widget> children, {required double vertical}) {
  if (children.isEmpty) {
    return const <Widget>[];
  }
  return <Widget>[
    for (var i = 0; i < children.length; i++) ...[
      if (i > 0) SizedBox(height: vertical),
      children[i],
    ],
  ];
}
