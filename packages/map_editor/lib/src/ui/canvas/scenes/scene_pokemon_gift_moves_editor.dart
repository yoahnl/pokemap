import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show listEquals;

import '../../design_system/design_system.dart';

class ScenePokemonGiftMovesEditor extends StatefulWidget {
  const ScenePokemonGiftMovesEditor({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onValidityChanged,
    this.loadMoves,
  });

  final List<String>? value;
  final ValueChanged<List<String>?> onChanged;
  final ValueChanged<bool> onValidityChanged;
  final Future<Map<String, String>> Function()? loadMoves;

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

  bool get _valid =>
      widget.value == null ||
      !_loading &&
          _error == null &&
          widget.value!.isNotEmpty &&
          widget.value!.length <= 4 &&
          widget.value!.toSet().length == widget.value!.length &&
          widget.value!.every(_moves.containsKey);

  @override
  void initState() {
    super.initState();
    if (widget.value != null) _load();
  }

  @override
  void didUpdateWidget(ScenePokemonGiftMovesEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadMoves != widget.loadMoves ||
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
      final loader = widget.loadMoves;
      if (loader == null) throw StateError('Unavailable');
      final moves = await loader();
      if (!mounted || token != _request) return;
      setState(() => _moves = moves);
    } on Object {
      if (!mounted || token != _request) return;
      setState(
        () => _error =
            'Catalogue des capacités indisponible. Les références enregistrées sont conservées.',
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
    widget.onValidityChanged(
      value == null ||
          !_loading &&
              _error == null &&
              value.isNotEmpty &&
              value.length <= 4 &&
              value.toSet().length == value.length &&
              value.every(_moves.containsKey),
    );
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
      PokeMapDropdownField<String>(
        key: const ValueKey('scene-gift-move-mode'),
        label: 'Capacités du Pokémon',
        value: widget.value == null ? 'automatic' : 'explicit',
        items: const [
          PokeMapDropdownItem(
            value: 'automatic',
            label: 'Automatiques selon le niveau',
          ),
          PokeMapDropdownItem(value: 'explicit', label: 'Capacités imposées'),
        ],
        onChanged: (value) => _change(value == 'automatic' ? null : ['']),
      ),
      if (widget.value != null) ...[
        const SizedBox(height: 8),
        const Text(
          'Choisissez 1 à 4 capacités dans l’ordre voulu. Elles remplacent toutes les capacités automatiques.',
        ),
        if (_loading)
          const PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.info,
            message: 'Chargement des capacités…',
          ),
        if (_error != null)
          PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.warning,
            message: _error!,
          ),
        if (!_loading &&
            _error == null &&
            widget.value!.any((id) => id.isNotEmpty && !_moves.containsKey(id)))
          const PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.warning,
            message:
                'Une capacité enregistrée est introuvable. Choisissez son remplacement ou retirez-la pour appliquer.',
          ),
        for (final (index, id) in widget.value!.indexed) ...[
          const SizedBox(height: 8),
          PokeMapDropdownField<String>(
            key: ValueKey('scene-gift-move-$index'),
            label: 'Capacité ${index + 1}',
            value: id,
            items: [
              const PokeMapDropdownItem(
                value: '',
                label: 'Choisir une capacité',
              ),
              if (id.isNotEmpty && !_moves.containsKey(id))
                PokeMapDropdownItem(
                  value: id,
                  label: 'Référence introuvable : $id',
                ),
              for (final entry in _moves.entries)
                if (entry.key == id || !widget.value!.contains(entry.key))
                  PokeMapDropdownItem(value: entry.key, label: entry.value),
            ],
            enabled: !_loading && _error == null,
            onChanged: (move) => _change([...widget.value!]..[index] = move),
          ),
          Wrap(
            spacing: 4,
            children: [
              PokeMapButton(
                key: ValueKey('scene-gift-move-up-$index'),
                size: PokeMapButtonSize.small,
                variant: PokeMapButtonVariant.ghost,
                onPressed: index == 0 ? null : () => _swap(index, index - 1),
                child: const Text('Monter'),
              ),
              PokeMapButton(
                key: ValueKey('scene-gift-move-down-$index'),
                size: PokeMapButtonSize.small,
                variant: PokeMapButtonVariant.ghost,
                onPressed: index + 1 == widget.value!.length
                    ? null
                    : () => _swap(index, index + 1),
                child: const Text('Descendre'),
              ),
              PokeMapButton(
                key: ValueKey('scene-gift-move-remove-$index'),
                size: PokeMapButtonSize.small,
                variant: PokeMapButtonVariant.ghost,
                onPressed: widget.value!.length <= 1
                    ? null
                    : () => _change([...widget.value!]..removeAt(index)),
                child: const Text('Retirer'),
              ),
            ],
          ),
        ],
        PokeMapButton(
          key: const ValueKey('scene-gift-move-add'),
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          onPressed: widget.value!.length >= 4 || _loading || _error != null
              ? null
              : () => _change([...widget.value!, '']),
          child: const Text('Ajouter une capacité'),
        ),
      ],
    ],
  );
}
