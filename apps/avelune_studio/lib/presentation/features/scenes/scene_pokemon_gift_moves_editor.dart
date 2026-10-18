import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show listEquals;

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_select.dart';

class ScenePokemonGiftMovesEditor extends StatefulWidget {
  const ScenePokemonGiftMovesEditor({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onValidityChanged,
    this.loadMoves,
    this.catalogueScope,
  });
  final List<String>? value;
  final ValueChanged<List<String>?> onChanged;
  final ValueChanged<bool> onValidityChanged;
  final Future<Map<String, String>> Function()? loadMoves;
  final Object? catalogueScope;
  @override
  State<ScenePokemonGiftMovesEditor> createState() =>
      _ScenePokemonGiftMovesEditorState();
}

class _ScenePokemonGiftMovesEditorState
    extends State<ScenePokemonGiftMovesEditor> {
  Map<String, String> _moves = const {};
  bool _loading = false;
  String? _error;
  int _request = 0;
  bool get _valid => _validValue(widget.value);
  bool _validValue(List<String>? value) =>
      value == null ||
      !_loading &&
          _error == null &&
          value.isNotEmpty &&
          value.length <= 4 &&
          value.toSet().length == value.length &&
          value.every(_moves.containsKey);
  @override
  void initState() {
    super.initState();
    if (widget.value != null) _load();
  }

  @override
  void didUpdateWidget(ScenePokemonGiftMovesEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadMoves != widget.loadMoves ||
        oldWidget.catalogueScope != widget.catalogueScope ||
        oldWidget.value == null && widget.value != null) {
      _load();
    } else if (!listEquals(oldWidget.value, widget.value)) {
      Future<void>.microtask(() {
        if (mounted) widget.onValidityChanged(_valid);
      });
    }
  }

  Future<void> _load() async {
    final token = ++_request;
    _loading = true;
    _error = null;
    await Future<void>.value();
    if (!mounted || token != _request) return;
    widget.onValidityChanged(widget.value == null);
    try {
      final load = widget.loadMoves;
      if (load == null) throw StateError('Unavailable');
      final moves = await load();
      if (!mounted || token != _request) return;
      setState(() => _moves = moves);
    } on Object {
      if (!mounted || token != _request) return;
      setState(
        () => _error = 'Catalogue des capacités indisponible. Les références enregistrées sont conservées.',
      );
    } finally {
      if (mounted && token == _request) {
        setState(() => _loading = false);
        widget.onValidityChanged(_valid);
      }
    }
  }

  void _change(List<String>? value) {
    widget.onChanged(value == null ? null : List.unmodifiable(value));
    widget.onValidityChanged(_validValue(value));
  }

  void _swap(int index, int target) {
    final value = [...widget.value!];
    final move = value[index];
    value[index] = value[target];
    value[target] = move;
    _change(value);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StudioSelect(
        key: const ValueKey('scene-gift-move-mode'),
        label: 'Capacités du Pokémon',
        value: widget.value == null ? 'automatic' : 'explicit',
        options: const {
          'automatic': 'Automatiques selon le niveau',
          'explicit': 'Capacités imposées',
        },
        onChanged: (value) => _change(value == 'automatic' ? null : ['']),
      ),
      if (widget.value != null) ...[
        const SizedBox(height: 8),
        const StudioNotice(
          'Choisissez 1 à 4 capacités dans l’ordre voulu. Elles remplacent toutes les capacités automatiques.',
        ),
        if (_loading) const StudioNotice('Chargement des capacités…'),
        if (_error != null) StudioNotice(_error!, isError: true),
        if (!_loading &&
            _error == null &&
            widget.value!.any((id) => id.isNotEmpty && !_moves.containsKey(id)))
          const StudioNotice(
            'Une capacité enregistrée est introuvable. Choisissez son remplacement ou retirez-la pour appliquer.',
            isError: true,
          ),
        for (final (index, id) in widget.value!.indexed) ...[
          const SizedBox(height: 8),
          StudioSelect(
            key: ValueKey('scene-gift-move-$index'),
            label: 'Capacité ${index + 1}',
            value: id,
            options: {
              '': 'Choisir une capacité',
              if (id.isNotEmpty && !_moves.containsKey(id))
                id: 'Référence introuvable : $id',
              for (final entry in _moves.entries)
                if (entry.key == id || !widget.value!.contains(entry.key))
                  entry.key: entry.value,
            },
            onChanged: _loading || _error != null
                ? null
                : (move) => _change([...widget.value!]..[index] = move),
          ),
          Wrap(
            spacing: 4,
            children: [
              StudioButton(
                key: ValueKey('scene-gift-move-up-$index'),
                label: 'Monter',
                secondary: true,
                onPressed: index == 0 ? null : () => _swap(index, index - 1),
              ),
              StudioButton(
                key: ValueKey('scene-gift-move-down-$index'),
                label: 'Descendre',
                secondary: true,
                onPressed: index + 1 == widget.value!.length
                    ? null
                    : () => _swap(index, index + 1),
              ),
              StudioButton(
                key: ValueKey('scene-gift-move-remove-$index'),
                label: 'Retirer',
                secondary: true,
                onPressed: widget.value!.length <= 1
                    ? null
                    : () => _change([...widget.value!]..removeAt(index)),
              ),
            ],
          ),
        ],
        StudioButton(
          key: const ValueKey('scene-gift-move-add'),
          label: 'Ajouter une capacité',
          secondary: true,
          onPressed: widget.value!.length >= 4 || _loading || _error != null
              ? null
              : () => _change([...widget.value!, '']),
        ),
      ],
    ],
  );
}
