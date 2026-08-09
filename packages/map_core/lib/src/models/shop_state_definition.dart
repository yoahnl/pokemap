import 'package:freezed_annotation/freezed_annotation.dart';

import 'script_conditions.dart';
import 'shop_definition.dart';

part 'shop_state_definition.freezed.dart';
part 'shop_state_definition.g.dart';

int _shopStateIntegerFromJson(Object? value) {
  if (value is! int) {
    throw FormatException('Shop state numeric values must be integers', value);
  }
  return value;
}

@freezed
abstract class ShopStateDefinition with _$ShopStateDefinition {
  const ShopStateDefinition._();

  @JsonSerializable(explicitToJson: true)
  const factory ShopStateDefinition({
    required String id,
    required String label,
    @JsonKey(fromJson: _shopStateIntegerFromJson) @Default(0) int priority,
    required ScriptCondition activation,
    @Default(true) bool isOpen,
    String? storefrontLabel,
    @Default('') String welcomeMessage,
    @Default('') String closedMessage,
    @Default(<ShopEntryDefinition>[]) List<ShopEntryDefinition> entries,
  }) = _ShopStateDefinition;

  factory ShopStateDefinition.fromJson(Map<String, dynamic> json) =>
      _$ShopStateDefinitionFromJson(json).normalized();

  ShopStateDefinition normalized({Set<String>? knownItemIds}) {
    final normalizedId = id.trim();
    final normalizedLabel = label.trim();
    final normalizedStorefrontLabel = storefrontLabel?.trim();
    if (normalizedId.isEmpty) {
      throw StateError('ShopStateDefinition id must not be empty');
    }
    if (normalizedLabel.isEmpty) {
      throw StateError('ShopStateDefinition label must not be empty');
    }
    final normalizedEntries = entries
        .map((entry) => entry.normalized(knownItemIds: knownItemIds))
        .toList(growable: false);
    final itemIds = <String>{};
    for (final entry in normalizedEntries) {
      if (!itemIds.add(entry.itemId)) {
        throw StateError(
          'ShopStateDefinition entries must not repeat item '
          '"${entry.itemId}"',
        );
      }
    }
    return copyWith(
      id: normalizedId,
      label: normalizedLabel,
      storefrontLabel:
          normalizedStorefrontLabel == null || normalizedStorefrontLabel.isEmpty
              ? null
              : normalizedStorefrontLabel,
      welcomeMessage: welcomeMessage.trim(),
      closedMessage: closedMessage.trim(),
      entries: normalizedEntries,
    );
  }
}
