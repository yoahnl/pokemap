import 'package:map_core/map_core.dart';

import 'item_catalog_snapshot.dart';

enum ItemUseCapabilityFailure {
  unknownDefinition,
  unavailableInContext,
}

enum ItemUsabilityState {
  usable,
  passive,
  unavailableInContext,
  invalidDefinition,
  unsupportedCapability,
}

final class ItemUseCapabilityResolution {
  const ItemUseCapabilityResolution._({
    required this.item,
    required this.use,
    required this.failure,
  });

  const ItemUseCapabilityResolution.available({
    required ProjectItemDefinition item,
    required ProjectItemUseDefinition use,
  }) : this._(item: item, use: use, failure: null);

  const ItemUseCapabilityResolution.failed({
    required ProjectItemDefinition? item,
    required ItemUseCapabilityFailure failure,
  }) : this._(item: item, use: null, failure: failure);

  final ProjectItemDefinition? item;
  final ProjectItemUseDefinition? use;
  final ItemUseCapabilityFailure? failure;

  bool get isAvailable => failure == null;
}

final class ItemCapabilityResolver {
  const ItemCapabilityResolver(this.snapshot);

  final ItemCatalogSnapshot snapshot;

  ProjectItemDefinition? definitionFor(String itemId) =>
      snapshot.definitionFor(itemId);

  ItemUseCapabilityResolution resolveUse({
    required String itemId,
    required ProjectItemUseContext context,
  }) {
    final item = snapshot.definitionFor(itemId);
    if (item == null) {
      return const ItemUseCapabilityResolution.failed(
        item: null,
        failure: ItemUseCapabilityFailure.unknownDefinition,
      );
    }
    for (final use in item.uses) {
      if (use.contexts.contains(context)) {
        return ItemUseCapabilityResolution.available(item: item, use: use);
      }
    }
    return ItemUseCapabilityResolution.failed(
      item: item,
      failure: ItemUseCapabilityFailure.unavailableInContext,
    );
  }

  ItemUsabilityState classifyUse({
    required String itemId,
    required ProjectItemUseContext context,
  }) {
    final item = snapshot.definitionFor(itemId);
    if (item == null) {
      return ItemUsabilityState.invalidDefinition;
    }
    if (item.uses.any((use) => use.contexts.contains(context))) {
      return ItemUsabilityState.usable;
    }
    if (item.uses.isNotEmpty || item.capture != null) {
      return ItemUsabilityState.unavailableInContext;
    }
    return ItemUsabilityState.passive;
  }
}
