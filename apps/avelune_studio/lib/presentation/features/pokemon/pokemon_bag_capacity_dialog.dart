import '../../../features/pokemon/application/pokemon_bag_capacity_controller.dart';

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_design_system/avelune_design_system.dart';

import '../../../features/pokemon/application/pokemon_commerce_controller.dart';
import '../../../features/pokemon/application/pokemon_pocket_label.dart';
import 'pokemon_ui_parts.dart';

Future<void> showPokemonBagCapacityDialog(
  BuildContext context,
  PokemonCommerceController commerce,
) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => PokemonBagCapacityDialog(commerce: commerce),
);

class PokemonBagCapacityDialog extends StatefulWidget {
  const PokemonBagCapacityDialog({super.key, required this.commerce});
  final PokemonCommerceController commerce;

  @override
  State<PokemonBagCapacityDialog> createState() =>
      _PokemonBagCapacityDialogState();
}

class _PokemonBagCapacityDialogState extends State<PokemonBagCapacityDialog> {
  late final _draft = PokemonBagCapacityController(widget.commerce);
  ProjectBagCapacity get initial => _draft.initial;
  List<String> get pockets => _draft.pockets;
  Map<String, PokemonPocketCapacityDraft> get drafts => _draft.drafts;
  late String? selected = pockets.firstOrNull;
  bool get saving => _draft.saving;
  String? get error => _draft.error;
  ProjectBagCapacity? get capacity => _draft.capacity;

  Future<void> save() async {
    final saving = _draft.save();
    setState(() {});
    final saved = await saving;
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context);
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = drafts[selected];
    final value = capacity;
    return PopScope(
      canPop: !saving,
      child: StudioReviewDialog(
        title: 'Capacité du sac',
        confirmLabel: saving ? 'Enregistrement…' : 'Enregistrer',
        onConfirmed: saving || value == null || value == initial ? null : save,
        onCancelled: () {
          if (!saving) Navigator.pop(context);
        },
        secondaryActionLabel: 'Tout rendre illimité',
        onSecondaryAction: saving ? null : () => setState(_draft.unlimitAll),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Chaque type d’objet occupe une place. Les limites sont indépendantes pour chaque poche. Sans limite, la poche reste illimitée.',
            ),
            const SizedBox(height: 12),
            if (draft == null)
              const Text(
                'Aucune poche disponible. Crée un objet pour configurer sa poche.',
              ),
            if (draft != null) ...[
              StudioSelect(
                key: const Key('bag-capacity-pocket'),
                label: 'Poche',
                value: selected!,
                options: {for (final id in pockets) id: pokemonPocketLabel(id)},
                onChanged: saving
                    ? null
                    : (id) => setState(() => selected = id),
              ),
              const SizedBox(height: 12),
              _limit(draft, distinct: true),
              const SizedBox(height: 12),
              _limit(draft, distinct: false),
            ],
            if (value == null) ...[
              const SizedBox(height: 12),
              const PokemonSurface(
                child: Text(
                  'Chaque limite active doit être un entier positif. Vérifie aussi les autres poches avant d’enregistrer.',
                ),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 12),
              PokemonSurface(child: Text(error!)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _limit(PokemonPocketCapacityDraft draft, {required bool distinct}) {
    final limited = distinct ? draft.distinctLimited : draft.quantityLimited;
    final raw = distinct ? draft.distinct : draft.quantity;
    final id = distinct ? 'distinct' : 'quantity';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSelect(
          key: ValueKey('bag-capacity-$id-mode'),
          label: distinct
              ? 'Types d’objets différents'
              : 'Quantité par type d’objet',
          value: limited ? 'limited' : 'unlimited',
          options: const {'unlimited': 'Illimité', 'limited': 'Limité'},
          onChanged: saving
              ? null
              : (mode) {
                  final next = mode == 'limited';
                  if (next == limited) return;
                  setState(() {
                    if (distinct) {
                      draft.distinctLimited = next;
                      if (!next) draft.distinct = '';
                    } else {
                      draft.quantityLimited = next;
                      if (!next) draft.quantity = '';
                    }
                  });
                },
        ),
        if (limited) ...[
          const SizedBox(height: 8),
          StudioDraftField(
            key: ValueKey('bag-capacity-$selected-$id-value'),
            label: 'Maximum',
            value: raw,
            enabled: !saving,
            keyboardType: TextInputType.number,
            errorText: positiveBagCapacityInput(raw) == null
                ? 'Saisis un entier entre 1 et $maximumBagEntryQuantity.'
                : null,
            onChanged: (text) => setState(() {
              if (distinct) {
                draft.distinct = text;
              } else {
                draft.quantity = text;
              }
            }),
          ),
        ],
      ],
    );
  }
}
