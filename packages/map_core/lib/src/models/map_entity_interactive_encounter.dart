import 'package:meta/meta.dart';
import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;

import 'enums.dart';
import 'map_gameplay_zone_payloads.dart';
import 'script_conditions.dart';

enum InteractiveEncounterTrigger { headbutt, afterRockSmash }

enum InteractiveEncounterReusePolicy { repeatable, oncePerMapInstance }

@immutable
final class MapEntityInteractiveEncounterData {
  MapEntityInteractiveEncounterData({
    required this.trigger,
    required this.encounterTableId,
    this.reusePolicy = InteractiveEncounterReusePolicy.repeatable,
    List<ScriptCondition> conditions = const [],
    EncounterZonePayload? presentation,
  }) : conditions = List.unmodifiable(conditions),
       presentation =
           presentation ??
           EncounterZonePayload(
             encounterTableId: encounterTableId,
             encounterKind: trigger == InteractiveEncounterTrigger.headbutt
                 ? EncounterKind.headbutt
                 : EncounterKind.special,
           ) {
    if (encounterTableId.isEmpty ||
        encounterTableId.trim() != encounterTableId ||
        this.presentation.encounterTableId != encounterTableId ||
        this.presentation.encounterKind != encounterKind) {
      throw ArgumentError(
        'Interactive encounter table and source must match its trigger.',
      );
    }
  }

  final InteractiveEncounterTrigger trigger;
  final String encounterTableId;
  final InteractiveEncounterReusePolicy reusePolicy;
  final List<ScriptCondition> conditions;
  final EncounterZonePayload presentation;
  EncounterKind get encounterKind =>
      trigger == InteractiveEncounterTrigger.headbutt
      ? EncounterKind.headbutt
      : EncounterKind.special;

  factory MapEntityInteractiveEncounterData.fromJson(
    Map<String, dynamic> json,
  ) {
    const keys = {
      'trigger',
      'encounterTableId',
      'reusePolicy',
      'conditions',
      'presentation',
    };
    if (json.length != keys.length ||
        !json.keys.every(keys.contains) ||
        !InteractiveEncounterTrigger.values.any(
          (value) => value.name == json['trigger'],
        ) ||
        !InteractiveEncounterReusePolicy.values.any(
          (value) => value.name == json['reusePolicy'],
        ) ||
        json['encounterTableId'] is! String ||
        json['conditions'] is! List) {
      throw const FormatException(
        'Unsupported interactive encounter contract.',
      );
    }
    Map<String, dynamic> object(Object? value) {
      if (value is! Map || value.keys.any((key) => key is! String)) {
        throw const FormatException('Expected a typed object.');
      }
      return Map<String, dynamic>.from(value);
    }

    ScriptCondition condition(Object? value) {
      final raw = object(value);
      if (raw.length != 3 ||
          !raw.keys.every(const {'type', 'params', 'children'}.contains) ||
          raw['children'] is! List) {
        throw const FormatException('Unsupported encounter condition.');
      }
      for (final child in raw['children'] as List) {
        condition(child);
      }
      return ScriptCondition.fromJson(raw);
    }

    final rawPresentation = object(json['presentation']);
    const presentationKeys = {
      'encounterTableId',
      'encounterKind',
      'battleBackgroundRelativePath',
      'battleMusicPath',
      'encounterMusicPath',
      'battleTransitionIds',
    };
    if (rawPresentation.length != presentationKeys.length ||
        !rawPresentation.keys.every(presentationKeys.contains)) {
      throw const FormatException('Unsupported encounter presentation.');
    }
    try {
      return MapEntityInteractiveEncounterData(
        trigger: InteractiveEncounterTrigger.values.singleWhere(
          (value) => value.name == json['trigger'],
        ),
        encounterTableId: json['encounterTableId'] as String,
        reusePolicy: InteractiveEncounterReusePolicy.values.singleWhere(
          (value) => value.name == json['reusePolicy'],
        ),
        conditions: (json['conditions'] as List).map(condition).toList(),
        presentation: EncounterZonePayload.fromJson(rawPresentation),
      );
    } on Object catch (error) {
      throw FormatException('Invalid interactive encounter: $error');
    }
  }

  Map<String, dynamic> toJson() => {
    'trigger': trigger.name,
    'encounterTableId': encounterTableId,
    'reusePolicy': reusePolicy.name,
    'conditions': conditions.map((condition) => condition.toJson()).toList(),
    'presentation': presentation.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapEntityInteractiveEncounterData &&
          trigger == other.trigger &&
          encounterTableId == other.encounterTableId &&
          reusePolicy == other.reusePolicy &&
          const DeepCollectionEquality().equals(conditions, other.conditions) &&
          presentation == other.presentation;
  @override
  int get hashCode => Object.hash(
    trigger,
    encounterTableId,
    reusePolicy,
    const DeepCollectionEquality().hash(conditions),
    presentation,
  );
}
