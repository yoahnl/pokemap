// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_state_definition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShopStateDefinition _$ShopStateDefinitionFromJson(Map<String, dynamic> json) =>
    _ShopStateDefinition(
      id: json['id'] as String,
      label: json['label'] as String,
      priority: json['priority'] == null
          ? 0
          : _shopStateIntegerFromJson(json['priority']),
      activation: ScriptCondition.fromJson(
        json['activation'] as Map<String, dynamic>,
      ),
      isOpen: json['isOpen'] as bool? ?? true,
      storefrontLabel: json['storefrontLabel'] as String?,
      welcomeMessage: json['welcomeMessage'] as String? ?? '',
      closedMessage: json['closedMessage'] as String? ?? '',
      entries:
          (json['entries'] as List<dynamic>?)
              ?.map(
                (e) => ShopEntryDefinition.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <ShopEntryDefinition>[],
    );

Map<String, dynamic> _$ShopStateDefinitionToJson(
  _ShopStateDefinition instance,
) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'priority': instance.priority,
  'activation': instance.activation.toJson(),
  'isOpen': instance.isOpen,
  'storefrontLabel': instance.storefrontLabel,
  'welcomeMessage': instance.welcomeMessage,
  'closedMessage': instance.closedMessage,
  'entries': instance.entries.map((e) => e.toJson()).toList(),
};
