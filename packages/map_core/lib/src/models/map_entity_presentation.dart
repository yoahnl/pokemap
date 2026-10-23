import 'package:meta/meta.dart';
import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;

import 'enums.dart';
import 'geometry.dart';
import 'map_entity_payloads.dart';
import 'narrative_event_definition.dart';
import '../operations/map_entities.dart';
import '../exceptions/map_exceptions.dart';

enum MapEntityInteractionMode { front, overlap }

@immutable
final class MapEntityPresentation {
  MapEntityPresentation({required List<MapEntityPresentationVariant> variants})
    : variants = List.unmodifiable(variants) {
    if (variants.isEmpty ||
        variants.length > 256 ||
        variants.map((value) => value.id).toSet().length != variants.length) {
      throw ArgumentError(
        'Presentation requires 1–256 uniquely named variants.',
      );
    }
  }

  final List<MapEntityPresentationVariant> variants;

  factory MapEntityPresentation.fromJson(Map<String, dynamic> json) {
    if (json.length != 2 ||
        json['schemaVersion'] != 2 ||
        json['variants'] is! List) {
      throw const FormatException('Unsupported entity presentation contract.');
    }
    try {
      return MapEntityPresentation(
        variants: [
          for (final raw in json['variants'] as List)
            MapEntityPresentationVariant.fromJson(_object(raw)),
        ],
      );
    } on ArgumentError catch (error) {
      throw FormatException('Invalid entity presentation: $error');
    }
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 2,
    'variants': [for (final variant in variants) variant.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is MapEntityPresentation &&
      const DeepCollectionEquality().equals(toJson(), other.toJson());
  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

@immutable
final class MapEntityPresentationVariant {
  MapEntityPresentationVariant({
    required this.id,
    required NarrativeEventConditionExpression condition,
    this.characterId,
    this.facing = EntityFacing.south,
    this.interactionMode = MapEntityInteractionMode.front,
    this.movement = const MapEntityNpcMovementConfig(),
    this.startsOnNpcContact = false,
    required this.blocksMovement,
    this.size = const GridSize(width: 1, height: 1),
    List<EntityFacing> counterInteractionSides = const [],
  }) : condition = validateNarrativeEventConditionExpression(condition),
       counterInteractionSides = List.unmodifiable(counterInteractionSides) {
    if (id.isEmpty ||
        id.trim() != id ||
        (characterId != null &&
            (characterId!.isEmpty || characterId!.trim() != characterId)) ||
        size.width <= 0 ||
        size.height <= 0 ||
        size.width > 64 ||
        size.height > 64 ||
        counterInteractionSides.toSet().length !=
            counterInteractionSides.length) {
      throw ArgumentError('Invalid entity presentation variant.');
    }
    try {
      assertValidMapEntityNpcMovementConfig(movement);
    } on ValidationException catch (error) {
      throw ArgumentError('Invalid entity presentation movement: $error');
    }
  }

  final String id;
  final NarrativeEventConditionExpression condition;
  final String? characterId;
  final EntityFacing facing;
  final MapEntityInteractionMode interactionMode;
  final MapEntityNpcMovementConfig movement;
  final bool startsOnNpcContact;
  final bool blocksMovement;
  final GridSize size;
  final List<EntityFacing> counterInteractionSides;

  factory MapEntityPresentationVariant.fromJson(Map<String, dynamic> json) {
    const fields = {
      'id',
      'condition',
      'characterId',
      'facing',
      'interactionMode',
      'blocksMovement',
      'size',
      'counterInteractionSides',
      'movement',
      'startsOnNpcContact',
    };
    final rawSize = _object(json['size']);
    if (json.length != fields.length ||
        !json.keys.every(fields.contains) ||
        json['id'] is! String ||
        (json['characterId'] != null && json['characterId'] is! String) ||
        !EntityFacing.values.any((value) => value.name == json['facing']) ||
        !MapEntityInteractionMode.values.any(
          (value) => value.name == json['interactionMode'],
        ) ||
        json['blocksMovement'] is! bool ||
        json['movement'] is! Map ||
        json['startsOnNpcContact'] is! bool ||
        rawSize.length != 2 ||
        rawSize['width'] is! int ||
        rawSize['height'] is! int ||
        json['counterInteractionSides'] is! List ||
        (json['counterInteractionSides'] as List).any(
          (side) => !EntityFacing.values.any((value) => value.name == side),
        )) {
      throw const FormatException('Unsupported entity presentation variant.');
    }
    try {
      return MapEntityPresentationVariant(
        id: json['id'] as String,
        condition: NarrativeEventConditionExpression.fromJson(
          json['condition'],
        ),
        characterId: json['characterId'] as String?,
        facing: EntityFacing.values.byName(json['facing'] as String),
        interactionMode: MapEntityInteractionMode.values.byName(
          json['interactionMode'] as String,
        ),
        blocksMovement: json['blocksMovement'] as bool,
        movement: MapEntityNpcMovementConfig.fromJson(
          _object(json['movement']),
        ),
        startsOnNpcContact: json['startsOnNpcContact'] as bool,
        size: GridSize.fromJson(rawSize),
        counterInteractionSides: [
          for (final raw in json['counterInteractionSides'] as List)
            EntityFacing.values.byName(raw as String),
        ],
      );
    } on ArgumentError catch (error) {
      throw FormatException('Invalid entity presentation variant: $error');
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'condition': condition.toJson(),
    'characterId': characterId,
    'facing': facing.name,
    'blocksMovement': blocksMovement,
    'size': size.toJson(),
    'interactionMode': interactionMode.name,
    'movement': movement.toJson(),
    'startsOnNpcContact': startsOnNpcContact,
    'counterInteractionSides': counterInteractionSides
        .map((side) => side.name)
        .toList(),
  };
}

Map<String, dynamic> _object(Object? raw) {
  if (raw is! Map || raw.keys.any((key) => key is! String)) {
    throw const FormatException('Expected an entity presentation object.');
  }
  return Map<String, dynamic>.from(raw);
}
