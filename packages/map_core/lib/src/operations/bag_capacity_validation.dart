import '../models/items/project_item_catalog.dart';
import '../models/project_bag_capacity.dart';
import '../models/save_data.dart';

final class BagCapacityIssue {
  const BagCapacityIssue({
    required this.code,
    required this.path,
    required this.message,
    this.itemId,
    this.pocketId,
  });

  final String code;
  final String path;
  final String message;
  final String? itemId;
  final String? pocketId;
}

List<BagCapacityIssue> validateBagCapacity({
  required Bag bag,
  required ProjectBagCapacity capacity,
  required ProjectItemCatalog? itemCatalog,
  String path = r'$.bag',
}) {
  ProjectBagCapacity normalizedCapacity;
  try {
    normalizedCapacity = capacity.normalized();
  } on FormatException catch (error) {
    return [
      BagCapacityIssue(
        code: 'bag.capacity.invalidConfiguration',
        path: path,
        message: error.message,
      ),
    ];
  }
  Bag normalizedBag;
  try {
    normalizedBag = bag.normalized();
  } on StateError catch (error) {
    return [
      BagCapacityIssue(
        code: 'bag.capacity.invalidBag',
        path: path,
        message: error.message,
      ),
    ];
  }
  if (normalizedCapacity.pockets.isEmpty || normalizedBag.entries.isEmpty) {
    return const [];
  }
  if (itemCatalog == null) {
    return [
      BagCapacityIssue(
        code: 'bag.capacity.missingItemCatalog',
        path: path,
        message: 'An item catalog is required to validate bag capacity.',
      ),
    ];
  }
  final itemIds = <String>{};
  for (final item in itemCatalog.entries) {
    final itemId = item.id.trim();
    if (!itemIds.add(itemId)) {
      return [
        BagCapacityIssue(
          code: 'bag.capacity.invalidItemCatalog',
          path: path,
          message: 'Item catalog contains duplicate item id "$itemId".',
          itemId: itemId,
        ),
      ];
    }
  }
  final definitions = {
    for (final item in itemCatalog.entries) item.id.trim(): item,
  };
  final issues = <BagCapacityIssue>[];
  final itemsByPocket = <String, Set<String>>{};
  final sourceIndexes = <String, int>{};
  for (final indexed in bag.entries.indexed) {
    sourceIndexes.putIfAbsent(indexed.$2.itemId.trim(), () => indexed.$1);
  }
  for (final entry in normalizedBag.entries) {
    final item = definitions[entry.itemId];
    final entryPath = '$path.entries[${sourceIndexes[entry.itemId]}]';
    if (item == null) {
      issues.add(
        BagCapacityIssue(
          code: 'bag.capacity.unknownItem',
          path: '$entryPath.itemId',
          message: 'Unknown bag item "${entry.itemId}".',
          itemId: entry.itemId,
        ),
      );
      continue;
    }
    final pocketId = item.pocketId.trim();
    (itemsByPocket[pocketId] ??= {}).add(entry.itemId);
    final maximum = normalizedCapacity.pockets[pocketId]?.maxQuantityPerItem;
    if (maximum != null && entry.quantity > maximum) {
      issues.add(
        BagCapacityIssue(
          code: 'bag.capacity.stackFull',
          path: '$entryPath.quantity',
          message:
              'Item "${entry.itemId}" quantity ${entry.quantity} exceeds pocket limit $maximum.',
          itemId: entry.itemId,
          pocketId: pocketId,
        ),
      );
    }
  }
  for (final entry in itemsByPocket.entries) {
    final maximum = normalizedCapacity.pockets[entry.key]?.maxDistinctItems;
    if (maximum != null && entry.value.length > maximum) {
      issues.add(
        BagCapacityIssue(
          code: 'bag.capacity.pocketFull',
          path: path,
          message:
              'Pocket "${entry.key}" has ${entry.value.length} distinct items; maximum $maximum.',
          pocketId: entry.key,
        ),
      );
    }
  }
  return List.unmodifiable(issues);
}
