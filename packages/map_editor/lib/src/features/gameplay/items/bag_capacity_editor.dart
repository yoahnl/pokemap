import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import 'item_studio_gateway.dart';

final class BagCapacityEditor extends StatefulWidget {
  const BagCapacityEditor({
    super.key,
    required this.initial,
    required this.pocketIds,
    required this.onSaved,
  });

  final ProjectBagCapacity initial;
  final Iterable<String> pocketIds;
  final Future<ItemStudioMutationReceipt> Function(ProjectBagCapacity) onSaved;

  @override
  State<BagCapacityEditor> createState() => _BagCapacityEditorState();
}

final class _BagCapacityEditorState extends State<BagCapacityEditor> {
  late final pockets = <String>{
    ...widget.pocketIds,
    ...widget.initial.pockets.keys,
  }.toList()..sort();
  late final drafts = {
    for (final id in pockets) id: _PocketDraft(widget.initial.pockets[id]),
  };
  late String? selected = pockets.firstOrNull;
  bool saving = false;
  String? error;

  @override
  void dispose() {
    for (final draft in drafts.values) {
      draft.distinct.dispose();
      draft.quantity.dispose();
    }
    super.dispose();
  }

  ProjectBagCapacity? get capacity {
    if (drafts.values.any((draft) => draft.invalid)) return null;
    return ProjectBagCapacity(
      pockets: {
        for (final entry in drafts.entries)
          entry.key: BagPocketCapacity(
            maxDistinctItems: entry.value.distinctLimited
                ? _positive(entry.value.distinct.text)
                : null,
            maxQuantityPerItem: entry.value.quantityLimited
                ? _positive(entry.value.quantity.text)
                : null,
          ),
      },
    ).normalized();
  }

  Future<void> save() async {
    final value = capacity;
    if (saving || value == null || value == widget.initial) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final receipt = await widget.onSaved(value);
      if (mounted) Navigator.pop(context, receipt);
    } on Object catch (failure) {
      if (mounted) setState(() => error = '$failure');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = drafts[selected];
    final value = capacity;
    return PopScope(
      canPop: !saving,
      child: PokeMapDialog(
        title: 'Capacité du sac',
        maxWidth: 600,
        footer: Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            PokeMapButton(
              key: const Key('bag-capacity-reset'),
              variant: PokeMapButtonVariant.ghost,
              onPressed: saving
                  ? null
                  : () => setState(() {
                      for (final draft in drafts.values) {
                        draft.distinctLimited = false;
                        draft.quantityLimited = false;
                        draft.distinct.clear();
                        draft.quantity.clear();
                      }
                      error = null;
                    }),
              child: const Text('Tout rendre illimité'),
            ),
            PokeMapButton(
              key: const Key('bag-capacity-cancel'),
              variant: PokeMapButtonVariant.secondary,
              onPressed: saving ? null : () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            PokeMapButton(
              key: const Key('bag-capacity-save'),
              isLoading: saving,
              onPressed: saving || value == null || value == widget.initial
                  ? null
                  : save,
              child: const Text('Enregistrer'),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .55,
          ),
          child: SingleChildScrollView(
            child: Column(
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
                  PokeMapDropdownField<String>(
                    key: const Key('bag-capacity-pocket'),
                    label: 'Poche',
                    value: selected!,
                    enabled: !saving,
                    items: [
                      for (final id in pockets)
                        PokeMapDropdownItem(value: id, label: id),
                    ],
                    onChanged: (id) => setState(() => selected = id),
                  ),
                  const SizedBox(height: 12),
                  _limit(draft, distinct: true),
                  const SizedBox(height: 12),
                  _limit(draft, distinct: false),
                ],
                if (value == null) ...[
                  const SizedBox(height: 12),
                  const PokeMapDiagnosticCallout(
                    severity: PokeMapDiagnosticSeverity.error,
                    title: 'Valeur invalide',
                    message: 'Chaque limite active doit être un entier positif. Vérifie aussi les autres poches avant d’enregistrer.',
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 12),
                  PokeMapDiagnosticCallout(
                    severity: PokeMapDiagnosticSeverity.error,
                    title: 'Enregistrement refusé',
                    message: error!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _limit(_PocketDraft draft, {required bool distinct}) {
    final limited = distinct ? draft.distinctLimited : draft.quantityLimited;
    final controller = distinct ? draft.distinct : draft.quantity;
    final id = distinct ? 'distinct' : 'quantity';
    final title = distinct
        ? 'Types d’objets différents'
        : 'Quantité par type d’objet';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PokeMapDropdownField<bool>(
          key: ValueKey('bag-capacity-$id-mode'),
          label: title,
          value: limited,
          enabled: !saving,
          items: const [
            PokeMapDropdownItem(value: false, label: 'Illimité'),
            PokeMapDropdownItem(value: true, label: 'Limité'),
          ],
          onChanged: (next) {
            if (next == limited) return;
            setState(() {
              if (distinct) {
                draft.distinctLimited = next;
              } else {
                draft.quantityLimited = next;
              }
              if (!next) controller.clear();
            });
          },
        ),
        if (limited) ...[
          const SizedBox(height: 6),
          PokeMapTextField(
            key: ValueKey('bag-capacity-$selected-$id'),
            fieldKey: ValueKey('bag-capacity-$id-value'),
            label: 'Maximum',
            controller: controller,
            enabled: !saving,
            keyboardType: TextInputType.number,
            errorText: _positive(controller.text) == null
                ? 'Saisis un entier entre 1 et $maximumBagEntryQuantity.'
                : null,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ],
    );
  }
}

final class _PocketDraft {
  _PocketDraft(BagPocketCapacity? capacity)
    : distinctLimited = capacity?.maxDistinctItems != null,
      quantityLimited = capacity?.maxQuantityPerItem != null,
      distinct = TextEditingController(
        text: capacity?.maxDistinctItems?.toString() ?? '',
      ),
      quantity = TextEditingController(
        text: capacity?.maxQuantityPerItem?.toString() ?? '',
      );
  bool distinctLimited;
  bool quantityLimited;
  final TextEditingController distinct;
  final TextEditingController quantity;
  bool get invalid =>
      (distinctLimited && _positive(distinct.text) == null) ||
      (quantityLimited && _positive(quantity.text) == null);
}

int? _positive(String raw) {
  final text = raw.trim();
  final value = RegExp(r'^[0-9]+$').hasMatch(text) ? int.tryParse(text) : null;
  return value != null && value > 0 && value <= maximumBagEntryQuantity
      ? value
      : null;
}
