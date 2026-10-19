import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_design_system/avelune_design_system.dart';

import '../../../features/pokemon/application/pokemon_commerce_controller.dart';
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
  late final initial = widget.commerce.snapshot!.project.bagCapacity;
  late final pockets = <String>{
    for (final item
        in widget.commerce.snapshot!.catalog?.entries ??
            const <ProjectItemDefinition>[])
      item.pocketId,
    ...initial.pockets.keys,
  }.toList()..sort();
  late final drafts = {
    for (final id in pockets) id: _PocketDraft(initial.pockets[id]),
  };
  late String? selected = pockets.firstOrNull;
  bool saving = false;
  String? error;

  ProjectBagCapacity? get capacity {
    if (drafts.values.any((draft) => draft.invalid)) return null;
    return ProjectBagCapacity(
      pockets: {
        for (final entry in drafts.entries)
          entry.key: BagPocketCapacity(
            maxDistinctItems: entry.value.distinctLimited
                ? _positive(entry.value.distinct)
                : null,
            maxQuantityPerItem: entry.value.quantityLimited
                ? _positive(entry.value.quantity)
                : null,
          ),
      },
    ).normalized();
  }

  Future<void> save() async {
    final value = capacity;
    if (saving || value == null || value == initial) return;
    setState(() {
      saving = true;
      error = null;
    });
    final saved = await widget.commerce.saveBagCapacity(initial, value);
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context);
    } else {
      setState(() {
        saving = false;
        error =
            widget.commerce.error ??
            'Le projet ne peut pas être modifié pendant une autre opération.';
      });
    }
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
        onSecondaryAction: saving
            ? null
            : () => setState(() {
                for (final draft in drafts.values) {
                  draft.distinctLimited = false;
                  draft.quantityLimited = false;
                  draft.distinct = '';
                  draft.quantity = '';
                }
                error = null;
              }),
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
                options: {for (final id in pockets) id: id},
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

  Widget _limit(_PocketDraft draft, {required bool distinct}) {
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
            errorText: _positive(raw) == null
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

class _PocketDraft {
  _PocketDraft(BagPocketCapacity? capacity)
    : distinctLimited = capacity?.maxDistinctItems != null,
      quantityLimited = capacity?.maxQuantityPerItem != null,
      distinct = capacity?.maxDistinctItems?.toString() ?? '',
      quantity = capacity?.maxQuantityPerItem?.toString() ?? '';
  bool distinctLimited;
  bool quantityLimited;
  String distinct;
  String quantity;
  bool get invalid =>
      (distinctLimited && _positive(distinct) == null) ||
      (quantityLimited && _positive(quantity) == null);
}

int? _positive(String raw) {
  final text = raw.trim();
  final value = RegExp(r'^[0-9]+$').hasMatch(text) ? int.tryParse(text) : null;
  return value != null && value > 0 && value <= maximumBagEntryQuantity
      ? value
      : null;
}
