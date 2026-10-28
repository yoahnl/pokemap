import 'script_conditions.dart';
import 'enums.dart';
import 'narrative_value.dart';

enum ProjectSurfAccessMode { progression, always, condition }

final class ProjectSurfSettings {
  const ProjectSurfSettings({
    this.enabled = true,
    this.requiresKnownMove = true,
    this.accessMode = ProjectSurfAccessMode.progression,
    this.condition,
    this.speedCellsPerSecond = 4,
  });

  final bool enabled;
  final bool requiresKnownMove;
  final ProjectSurfAccessMode accessMode;
  final ScriptCondition? condition;
  final double speedCellsPerSecond;

  factory ProjectSurfSettings.fromJson(Map<String, dynamic> json) {
    for (final key in json.keys) {
      if (!const {
        'enabled',
        'requiresKnownMove',
        'accessMode',
        'condition',
        'speedCellsPerSecond',
      }.contains(key)) {
        throw FormatException('Unknown Surf setting "$key".');
      }
    }
    bool boolean(String key, bool fallback) {
      if (!json.containsKey(key)) return fallback;
      final value = json[key];
      if (value is! bool) {
        throw FormatException('Surf $key must be a boolean.');
      }
      return value;
    }

    final rawMode = json.containsKey('accessMode')
        ? json['accessMode']
        : 'progression';
    final modes = ProjectSurfAccessMode.values.where(
      (mode) => mode.name == rawMode,
    );
    if (modes.isEmpty) {
      throw const FormatException('Unknown Surf access mode.');
    }
    final rawSpeed = json.containsKey('speedCellsPerSecond')
        ? json['speedCellsPerSecond']
        : 4;
    if (rawSpeed is! num) {
      throw const FormatException(
        'Surf speed must be a finite positive number.',
      );
    }
    final rawCondition = json['condition'];
    if (rawCondition != null &&
        (rawCondition is! Map ||
            rawCondition.keys.any((key) => key is! String))) {
      throw const FormatException('Surf condition must be an object.');
    }
    ScriptCondition? condition;
    if (rawCondition != null) {
      try {
        _validateConditionJson(Map<String, dynamic>.from(rawCondition as Map));
        condition = ScriptCondition.fromJson(
          Map<String, dynamic>.from(rawCondition),
        );
      } catch (error) {
        throw FormatException('Invalid Surf condition: $error');
      }
    }
    return ProjectSurfSettings(
      enabled: boolean('enabled', true),
      requiresKnownMove: boolean('requiresKnownMove', true),
      accessMode: modes.single,
      condition: condition,
      speedCellsPerSecond: rawSpeed.toDouble(),
    ).validated();
  }

  ProjectSurfSettings validated() {
    if (!speedCellsPerSecond.isFinite || speedCellsPerSecond <= 0) {
      throw const FormatException(
        'Surf speed must be a finite positive number.',
      );
    }
    if (accessMode == ProjectSurfAccessMode.condition && condition == null) {
      throw const FormatException(
        'Conditional Surf access requires a condition.',
      );
    }
    if (condition != null) _validateCondition(condition!);
    return this;
  }

  Map<String, dynamic> toJson() {
    validated();
    return {
      'enabled': enabled,
      'requiresKnownMove': requiresKnownMove,
      'accessMode': accessMode.name,
      if (condition != null) 'condition': condition!.toJson(),
      'speedCellsPerSecond': speedCellsPerSecond,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is ProjectSurfSettings &&
      enabled == other.enabled &&
      requiresKnownMove == other.requiresKnownMove &&
      accessMode == other.accessMode &&
      condition == other.condition &&
      speedCellsPerSecond == other.speedCellsPerSecond;

  @override
  int get hashCode => Object.hash(
    enabled,
    requiresKnownMove,
    accessMode,
    condition,
    speedCellsPerSecond,
  );
}

void _validateConditionJson(Map<String, dynamic> json) {
  if (json.keys.any(
    (key) => !const {'type', 'params', 'children'}.contains(key),
  )) {
    throw const FormatException('Unknown Surf condition field.');
  }
  if (json.containsKey('params') && json['params'] is! Map) {
    throw const FormatException('Surf condition params must be an object.');
  }
  if (json.containsKey('children')) {
    final children = json['children'];
    if (children is! List) {
      throw const FormatException('Surf condition children must be an array.');
    }
    for (final child in children) {
      if (child is! Map || child.keys.any((key) => key is! String)) {
        throw const FormatException('Surf condition children must be objects.');
      }
      _validateConditionJson(Map<String, dynamic>.from(child));
    }
  }
}

void _validateCondition(ScriptCondition condition) {
  final type = condition.type;
  final logical =
      type == ScriptConditionType.allOf ||
      type == ScriptConditionType.anyOf ||
      type == ScriptConditionType.not;
  if (logical) {
    if (condition.params.isNotEmpty ||
        condition.children.isEmpty ||
        type == ScriptConditionType.not && condition.children.length != 1) {
      throw const FormatException('Invalid Surf logical condition.');
    }
    for (final child in condition.children) {
      _validateCondition(child);
    }
    return;
  }
  if (condition.children.isNotEmpty) {
    throw const FormatException('Surf leaf conditions cannot have children.');
  }
  final requiredKeys = switch (type) {
    ScriptConditionType.flagIsSet ||
    ScriptConditionType.flagIsUnset => {'flagName'},
    ScriptConditionType.factEquals => {'factId', 'valueType', 'value'},
    ScriptConditionType.stepCompleted => {'stepId'},
    ScriptConditionType.badgeOwned => {'badgeId'},
    ScriptConditionType.itemQuantityAtLeast => {'itemId', 'quantity'},
    ScriptConditionType.moneyAtLeast => {'amount'},
    ScriptConditionType.variableEquals ||
    ScriptConditionType.variableGreaterThan ||
    ScriptConditionType.variableLessThan => {'variableName', 'value'},
    ScriptConditionType.fieldAbilityUnlocked => {'ability'},
    ScriptConditionType.partyHasMove ||
    ScriptConditionType.partyHasUsableMove => {'moveId'},
    ScriptConditionType.eventIsConsumed => {'eventId'},
    ScriptConditionType.playerOnMap => {'mapId'},
    _ => <String>{},
  };
  if (condition.params.length != requiredKeys.length ||
      !condition.params.keys.toSet().containsAll(requiredKeys)) {
    throw const FormatException('Invalid Surf condition parameters.');
  }
  for (final entry in condition.params.entries) {
    if (entry.value.trim().isEmpty &&
        !(type == ScriptConditionType.factEquals && entry.key == 'value')) {
      throw const FormatException('Surf condition parameters cannot be empty.');
    }
  }
  final integerKey = switch (type) {
    ScriptConditionType.itemQuantityAtLeast => 'quantity',
    ScriptConditionType.moneyAtLeast => 'amount',
    ScriptConditionType.variableGreaterThan ||
    ScriptConditionType.variableLessThan => 'value',
    _ => null,
  };
  if (integerKey != null) {
    final raw = condition.params[integerKey]!;
    final number = int.tryParse(raw);
    if (number == null ||
        number.toString() != raw ||
        integerKey != 'value' && number < 0) {
      throw const FormatException('Invalid Surf condition integer.');
    }
  }
  if (type == ScriptConditionType.fieldAbilityUnlocked &&
      !FieldAbility.values.any(
        (ability) => ability.name == condition.params['ability'],
      )) {
    throw const FormatException('Unknown Surf condition field ability.');
  }
  if (type == ScriptConditionType.factEquals) {
    final kind = NarrativeValueKind.fromWireName(
      condition.params['valueType']!,
    );
    final raw = condition.params['value']!;
    switch (kind) {
      case NarrativeValueKind.boolean:
        if (raw != 'true' && raw != 'false') {
          throw const FormatException('Invalid Surf condition boolean value.');
        }
      case NarrativeValueKind.integer:
        final number = int.tryParse(raw);
        if (number == null || number.toString() != raw) {
          throw const FormatException('Invalid Surf condition integer value.');
        }
        try {
          NarrativeValue.integer(number);
        } on ArgumentError {
          throw const FormatException(
            'Surf condition integer is outside JSON range.',
          );
        }
      case NarrativeValueKind.string:
        break;
    }
  }
}
