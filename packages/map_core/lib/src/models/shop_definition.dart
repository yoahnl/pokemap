import 'package:freezed_annotation/freezed_annotation.dart';

import 'shop_state_definition.dart';

part 'shop_definition.freezed.dart';
part 'shop_definition.g.dart';

enum ShopSellPolicy { listedEntries, catalogPrices }

final class ShopPurchaseBonus {
  const ShopPurchaseBonus({
    required this.itemId,
    required this.everyQuantity,
    required this.quantity,
    this.maximumOwnedQuantity,
  });

  final String itemId;
  final int everyQuantity, quantity;
  final int? maximumOwnedQuantity;

  factory ShopPurchaseBonus.fromJson(Map<String, dynamic> json) =>
      ShopPurchaseBonus(
        itemId: json['itemId'] as String,
        everyQuantity: _shopIntegerFromJson(json['everyQuantity']),
        quantity: _shopIntegerFromJson(json['quantity']),
        maximumOwnedQuantity: _shopNullableIntegerFromJson(
          json['maximumOwnedQuantity'],
        ),
      ).normalized();

  ShopPurchaseBonus normalized({Set<String>? knownItemIds}) {
    if (itemId.trim().isEmpty ||
        everyQuantity <= 0 ||
        quantity <= 0 ||
        (maximumOwnedQuantity != null && maximumOwnedQuantity! <= 0) ||
        (knownItemIds != null && !knownItemIds.contains(itemId.trim()))) {
      throw StateError(
        'Shop purchase bonus requires a known item and positive quantities',
      );
    }
    return ShopPurchaseBonus(
      itemId: itemId.trim(),
      everyQuantity: everyQuantity,
      quantity: quantity,
      maximumOwnedQuantity: maximumOwnedQuantity,
    );
  }

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'everyQuantity': everyQuantity,
    'quantity': quantity,
    'maximumOwnedQuantity': maximumOwnedQuantity,
  };

  @override
  bool operator ==(Object other) =>
      other is ShopPurchaseBonus &&
      other.itemId == itemId &&
      other.everyQuantity == everyQuantity &&
      other.quantity == quantity &&
      other.maximumOwnedQuantity == maximumOwnedQuantity;

  @override
  int get hashCode =>
      Object.hash(itemId, everyQuantity, quantity, maximumOwnedQuantity);
}

int _shopIntegerFromJson(Object? value) {
  if (value is! int) {
    throw FormatException('Shop numeric values must be integers', value);
  }
  return value;
}

int? _shopNullableIntegerFromJson(Object? value) {
  if (value == null) return null;
  return _shopIntegerFromJson(value);
}

@freezed
abstract class ShopEntryDefinition with _$ShopEntryDefinition {
  const ShopEntryDefinition._();

  @JsonSerializable(explicitToJson: true)
  const factory ShopEntryDefinition({
    required String itemId,
    @JsonKey(fromJson: _shopIntegerFromJson) required int price,
    @JsonKey(fromJson: _shopNullableIntegerFromJson) int? sellPrice,
    @JsonKey(fromJson: _shopNullableIntegerFromJson) int? stock,
    @JsonKey(fromJson: _shopNullableIntegerFromJson) int? maximumOwnedQuantity,
    ShopPurchaseBonus? purchaseBonus,
  }) = _ShopEntryDefinition;

  factory ShopEntryDefinition.fromJson(Map<String, dynamic> json) =>
      _$ShopEntryDefinitionFromJson(json).normalized();

  ShopEntryDefinition normalized({Set<String>? knownItemIds}) {
    final normalizedItemId = itemId.trim();
    if (normalizedItemId.isEmpty) {
      throw StateError('ShopEntryDefinition itemId must not be empty');
    }
    if (price <= 0) {
      throw StateError('ShopEntryDefinition price must be positive');
    }
    if (sellPrice != null && sellPrice! <= 0) {
      throw StateError('ShopEntryDefinition sellPrice must be positive');
    }
    if (stock != null && stock! < 0) {
      throw StateError('ShopEntryDefinition stock must be non-negative');
    }
    if (maximumOwnedQuantity != null && maximumOwnedQuantity! <= 0) {
      throw StateError(
        'ShopEntryDefinition maximumOwnedQuantity must be positive',
      );
    }
    if (knownItemIds != null && !knownItemIds.contains(normalizedItemId)) {
      throw StateError(
        'ShopEntryDefinition references unknown item "$normalizedItemId"',
      );
    }
    return copyWith(
      itemId: normalizedItemId,
      purchaseBonus: purchaseBonus?.normalized(knownItemIds: knownItemIds),
    );
  }
}

@freezed
abstract class ShopDefinition with _$ShopDefinition {
  const ShopDefinition._();

  @JsonSerializable(explicitToJson: true)
  const factory ShopDefinition({
    required String id,
    required String label,
    @Default([]) List<ShopEntryDefinition> entries,
    @Default([]) List<ShopStateDefinition> states,
    @Default(ShopSellPolicy.listedEntries) ShopSellPolicy sellPolicy,
  }) = _ShopDefinition;

  factory ShopDefinition.fromJson(Map<String, dynamic> json) =>
      _$ShopDefinitionFromJson(json).normalized();

  ShopDefinition normalized({Set<String>? knownItemIds}) {
    final normalizedId = id.trim();
    final normalizedLabel = label.trim();
    if (normalizedId.isEmpty) {
      throw StateError('ShopDefinition id must not be empty');
    }
    if (normalizedLabel.isEmpty) {
      throw StateError('ShopDefinition label must not be empty');
    }
    final normalizedEntries = entries
        .map((entry) => entry.normalized(knownItemIds: knownItemIds))
        .toList(growable: false);
    final itemIds = <String>{};
    for (final entry in normalizedEntries) {
      if (!itemIds.add(entry.itemId)) {
        throw StateError(
          'ShopDefinition entries must not repeat item "${entry.itemId}"',
        );
      }
    }
    final normalizedStates = states
        .map((state) => state.normalized(knownItemIds: knownItemIds))
        .toList(growable: false);
    final stateIds = <String>{};
    for (final state in normalizedStates) {
      if (!stateIds.add(state.id)) {
        throw StateError(
          'ShopDefinition states must not repeat id "${state.id}"',
        );
      }
    }
    return copyWith(
      id: normalizedId,
      label: normalizedLabel,
      entries: normalizedEntries,
      states: normalizedStates,
    );
  }
}
