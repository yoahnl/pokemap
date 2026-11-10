import 'package:map_core/map_core_domain.dart';

import 'pokemon_commerce_controller.dart';

class PokemonBagCapacityController {
  PokemonBagCapacityController(this.commerce) {
    initial = commerce.snapshot!.project.bagCapacity;
    pockets = <String>{
      for (final item
          in commerce.snapshot!.catalog?.entries ??
              const <ProjectItemDefinition>[])
        item.pocketId,
      ...initial.pockets.keys,
    }.toList()..sort();
    drafts = {
      for (final id in pockets)
        id: PokemonPocketCapacityDraft(initial.pockets[id]),
    };
    selected = pockets.firstOrNull;
  }

  final PokemonCommerceController commerce;
  late final ProjectBagCapacity initial;
  late final List<String> pockets;
  late final Map<String, PokemonPocketCapacityDraft> drafts;
  String? selected;
  bool saving = false;
  bool completed = false;
  String? error;
  bool _disposed = false;

  ProjectBagCapacity? get capacity {
    if (drafts.values.any((draft) => draft.invalid)) return null;
    return ProjectBagCapacity(
      pockets: {
        for (final entry in drafts.entries)
          entry.key: BagPocketCapacity(
            maxDistinctItems: entry.value.distinctLimited
                ? positiveBagCapacityInput(entry.value.distinct)
                : null,
            maxQuantityPerItem: entry.value.quantityLimited
                ? positiveBagCapacityInput(entry.value.quantity)
                : null,
          ),
      },
    ).normalized();
  }

  bool get canSave =>
      !_disposed &&
      !saving &&
      !completed &&
      capacity != null &&
      capacity != initial;
  bool get canClose => !saving;

  void select(String id) {
    if (!_disposed && !saving && drafts.containsKey(id)) selected = id;
  }

  void setLimited(
    String pocket, {
    required bool distinct,
    required bool limited,
  }) {
    if (_disposed || saving) return;
    final draft = drafts[pocket]!;
    if (distinct) {
      if (draft.distinctLimited == limited) return;
      draft.distinctLimited = limited;
      if (!limited) draft.distinct = '';
    } else {
      if (draft.quantityLimited == limited) return;
      draft.quantityLimited = limited;
      if (!limited) draft.quantity = '';
    }
  }

  void setRaw(String pocket, String text, {required bool distinct}) {
    if (_disposed || saving) return;
    if (distinct) {
      drafts[pocket]!.distinct = text;
    } else {
      drafts[pocket]!.quantity = text;
    }
  }

  void unlimitAll() {
    if (_disposed || saving) return;
    for (final draft in drafts.values) {
      draft.distinctLimited = false;
      draft.quantityLimited = false;
      draft.distinct = '';
      draft.quantity = '';
    }
    error = null;
  }

  Future<bool> save() async {
    final value = capacity;
    if (_disposed || saving || completed || value == null || value == initial) {
      return false;
    }
    saving = true;
    error = null;
    final saved = await commerce.saveBagCapacity(initial, value);
    if (_disposed) return false;
    saving = false;
    if (saved) {
      completed = true;
    } else {
      error =
          commerce.error ??
          'Le projet ne peut pas être modifié pendant une autre opération.';
    }
    return saved;
  }

  void dispose() => _disposed = true;
}

class PokemonPocketCapacityDraft {
  PokemonPocketCapacityDraft(BagPocketCapacity? capacity)
    : distinctLimited = capacity?.maxDistinctItems != null,
      quantityLimited = capacity?.maxQuantityPerItem != null,
      distinct = capacity?.maxDistinctItems?.toString() ?? '',
      quantity = capacity?.maxQuantityPerItem?.toString() ?? '';

  bool distinctLimited;
  bool quantityLimited;
  String distinct;
  String quantity;
  bool get invalid =>
      (distinctLimited && positiveBagCapacityInput(distinct) == null) ||
      (quantityLimited && positiveBagCapacityInput(quantity) == null);
}

int? positiveBagCapacityInput(String raw) {
  final text = raw.trim();
  final value = RegExp(r'^[0-9]+$').hasMatch(text) ? int.tryParse(text) : null;
  return value != null && value > 0 && value <= maximumBagEntryQuantity
      ? value
      : null;
}
