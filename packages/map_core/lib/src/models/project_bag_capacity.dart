import 'save_data.dart';

final class BagPocketCapacity {
  const BagPocketCapacity({this.maxDistinctItems, this.maxQuantityPerItem});

  factory BagPocketCapacity.fromJson(Map<String, dynamic> json) {
    for (final key in json.keys) {
      if (key != 'maxDistinctItems' && key != 'maxQuantityPerItem') {
        throw FormatException('Unknown bag pocket capacity field "$key".');
      }
    }
    return BagPocketCapacity(
      maxDistinctItems: _readLimit(json, 'maxDistinctItems'),
      maxQuantityPerItem: _readLimit(json, 'maxQuantityPerItem'),
    );
  }

  final int? maxDistinctItems;
  final int? maxQuantityPerItem;

  bool get isUnlimited =>
      maxDistinctItems == null && maxQuantityPerItem == null;

  BagPocketCapacity validated() {
    _validateLimit(maxDistinctItems, 'maxDistinctItems');
    _validateLimit(maxQuantityPerItem, 'maxQuantityPerItem');
    return this;
  }

  Map<String, dynamic> toJson() {
    validated();
    return {
      if (maxDistinctItems != null) 'maxDistinctItems': maxDistinctItems,
      if (maxQuantityPerItem != null) 'maxQuantityPerItem': maxQuantityPerItem,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BagPocketCapacity &&
          other.maxDistinctItems == maxDistinctItems &&
          other.maxQuantityPerItem == maxQuantityPerItem;

  @override
  int get hashCode => Object.hash(maxDistinctItems, maxQuantityPerItem);
}

final class ProjectBagCapacity {
  const ProjectBagCapacity({this.pockets = const {}});

  const ProjectBagCapacity.unlimited() : pockets = const {};

  factory ProjectBagCapacity.fromJson(Map<String, dynamic> json) {
    for (final key in json.keys) {
      if (key != 'pockets') {
        throw FormatException('Unknown bag capacity field "$key".');
      }
    }
    if (!json.containsKey('pockets')) {
      return const ProjectBagCapacity.unlimited();
    }
    final raw = json['pockets'];
    if (raw is! Map || raw.keys.any((key) => key is! String)) {
      throw const FormatException('Bag capacity pockets must be an object.');
    }
    final pockets = <String, BagPocketCapacity>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is! Map || value.keys.any((key) => key is! String)) {
        throw FormatException(
          'Bag capacity pocket "${entry.key}" must be an object.',
        );
      }
      pockets[entry.key as String] = BagPocketCapacity.fromJson(
        Map<String, dynamic>.from(value),
      );
    }
    return ProjectBagCapacity(pockets: pockets).normalized();
  }

  final Map<String, BagPocketCapacity> pockets;

  bool get isUnlimited => normalized().pockets.isEmpty;

  ProjectBagCapacity normalized() {
    final normalized = <String, BagPocketCapacity>{};
    for (final entry in pockets.entries) {
      if (entry.key.isEmpty || entry.key.trim() != entry.key) {
        throw FormatException(
          'Invalid bag capacity pocket identifier "${entry.key}".',
        );
      }
      final capacity = entry.value.validated();
      if (!capacity.isUnlimited) normalized[entry.key] = capacity;
    }
    return normalized.isEmpty
        ? const ProjectBagCapacity.unlimited()
        : ProjectBagCapacity(pockets: Map.unmodifiable(normalized));
  }

  Map<String, dynamic> toJson() => {
    'pockets': {
      for (final entry in normalized().pockets.entries)
        entry.key: entry.value.toJson(),
    },
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ProjectBagCapacity) return false;
    final left = normalized().pockets;
    final right = other.normalized().pockets;
    return left.length == right.length &&
        left.entries.every((entry) => right[entry.key] == entry.value);
  }

  @override
  int get hashCode => Object.hashAllUnordered(
    normalized().pockets.entries.map(
      (entry) => Object.hash(entry.key, entry.value),
    ),
  );
}

int? _readLimit(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! int) {
    throw FormatException('Bag capacity $key must be an integer or null.');
  }
  _validateLimit(value, key);
  return value;
}

void _validateLimit(int? value, String key) {
  if (value != null && (value <= 0 || value > maximumBagEntryQuantity)) {
    throw FormatException(
      'Bag capacity $key must be between 1 and $maximumBagEntryQuantity.',
    );
  }
}
