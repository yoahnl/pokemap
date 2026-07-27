// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_definition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ShopEntryDefinitionImpl _$$ShopEntryDefinitionImplFromJson(
        Map<String, dynamic> json) =>
    _$ShopEntryDefinitionImpl(
      itemId: json['itemId'] as String,
      price: _shopIntegerFromJson(json['price']),
      sellPrice: _shopNullableIntegerFromJson(json['sellPrice']),
      stock: _shopNullableIntegerFromJson(json['stock']),
    );

Map<String, dynamic> _$$ShopEntryDefinitionImplToJson(
        _$ShopEntryDefinitionImpl instance) =>
    <String, dynamic>{
      'itemId': instance.itemId,
      'price': instance.price,
      'sellPrice': instance.sellPrice,
      'stock': instance.stock,
    };

_$ShopDefinitionImpl _$$ShopDefinitionImplFromJson(Map<String, dynamic> json) =>
    _$ShopDefinitionImpl(
      id: json['id'] as String,
      label: json['label'] as String,
      entries: (json['entries'] as List<dynamic>?)
              ?.map((e) =>
                  ShopEntryDefinition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      states: (json['states'] as List<dynamic>?)
              ?.map((e) =>
                  ShopStateDefinition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ShopDefinitionImplToJson(
        _$ShopDefinitionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'entries': instance.entries.map((e) => e.toJson()).toList(),
      'states': instance.states.map((e) => e.toJson()).toList(),
    };
