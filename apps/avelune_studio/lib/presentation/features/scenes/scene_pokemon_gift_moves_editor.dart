import 'package:flutter/material.dart';

import '../../../features/scenes/application/scene_pokemon_gift_moves_draft.dart';

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
  late final ScenePokemonGiftMovesDraft draft;
  @override
  void initState() {
    super.initState();
    draft = ScenePokemonGiftMovesDraft(
      value: widget.value,
      catalogueScope: widget.catalogueScope,
      loadMoves: widget.loadMoves,
      changed: () {
        if (mounted) setState(() {});
      },
      onChanged: (value) => widget.onChanged(value),
      onValidityChanged: (value) => widget.onValidityChanged(value),
    );
  }

  @override
  void didUpdateWidget(ScenePokemonGiftMovesEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    draft.configure(
      value: widget.value,
      catalogueScope: widget.catalogueScope,
      loadMoves: widget.loadMoves,
    );
  }

  @override
  void dispose() {
    draft.dispose();
    super.dispose();
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
        onChanged: (value) => draft.change(value == 'automatic' ? null : ['']),
      ),
      if (widget.value != null) ...[
        const SizedBox(height: 8),
        const StudioNotice(
          'Choisissez 1 à 4 capacités dans l’ordre voulu. Elles remplacent toutes les capacités automatiques.',
        ),
        if (draft.loading) const StudioNotice('Chargement des capacités…'),
        if (draft.error != null) StudioNotice(draft.error!, isError: true),
        if (!draft.loading &&
            draft.error == null &&
            widget.value!.any(
              (id) => id.isNotEmpty && !draft.moves.containsKey(id),
            ))
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
              if (id.isNotEmpty && !draft.moves.containsKey(id))
                id: 'Référence introuvable : $id',
              for (final entry in draft.moves.entries)
                if (entry.key == id || !widget.value!.contains(entry.key))
                  entry.key: entry.value,
            },
            onChanged: draft.loading || draft.error != null
                ? null
                : (move) => draft.change([...widget.value!]..[index] = move),
          ),
          Wrap(
            spacing: 4,
            children: [
              StudioButton(
                key: ValueKey('scene-gift-move-up-$index'),
                label: 'Monter',
                secondary: true,
                onPressed: index == 0
                    ? null
                    : () => draft.swap(index, index - 1),
              ),
              StudioButton(
                key: ValueKey('scene-gift-move-down-$index'),
                label: 'Descendre',
                secondary: true,
                onPressed: index + 1 == widget.value!.length
                    ? null
                    : () => draft.swap(index, index + 1),
              ),
              StudioButton(
                key: ValueKey('scene-gift-move-remove-$index'),
                label: 'Retirer',
                secondary: true,
                onPressed: widget.value!.length <= 1
                    ? null
                    : () => draft.change([...widget.value!]..removeAt(index)),
              ),
            ],
          ),
        ],
        StudioButton(
          key: const ValueKey('scene-gift-move-add'),
          label: 'Ajouter une capacité',
          secondary: true,
          onPressed:
              widget.value!.length >= 4 || draft.loading || draft.error != null
              ? null
              : () => draft.change([...widget.value!, '']),
        ),
      ],
    ],
  );
}
