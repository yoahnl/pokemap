import 'package:freezed_annotation/freezed_annotation.dart';

import 'shop_state_definition.dart';

part 'shop_definition.freezed.dart';
part 'shop_definition.g.dart';

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

  const factory ShopEntryDefinition({
    required String itemId,
    @JsonKey(fromJson: _shopIntegerFromJson) required int price,
    @JsonKey(fromJson: _shopNullableIntegerFromJson) int? sellPrice,
    @JsonKey(fromJson: _shopNullableIntegerFromJson) int? stock,
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
    if (knownItemIds != null && !knownItemIds.contains(normalizedItemId)) {
      throw StateError(
        'ShopEntryDefinition references unknown item "$normalizedItemId"',
      );
    }
    return copyWith(itemId: normalizedItemId);
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
