import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;

enum ProjectCaptureNumericField {
  catchRate,
  attackerLevel,
  targetLevel,
  targetBaseSpeed,
  targetWeightDecikilograms,
}

enum ProjectCaptureComparison {
  lessThan,
  lessThanOrEqual,
  equal,
  greaterThanOrEqual,
  greaterThan,
}

enum ProjectCaptureMatchField {
  targetSpecies,
  targetTypes,
  targetEvolutionItemIds,
  encounterOrigin,
}

enum ProjectCaptureEncounterOrigin {
  walking,
  surfing,
  fishing,
  headbutt,
  scripted,
  gift,
}

enum ProjectCaptureRelation { sameSpecies, differentSex }

enum ProjectCaptureGroup { all, any }

final class ProjectCaptureIntegerOperand {
  ProjectCaptureIntegerOperand.literal(int value)
    : literal = _bounded(value, 0, 0x7fffffff, 'literal'),
      field = null,
      divisor = 1;

  ProjectCaptureIntegerOperand.field(this.field, {int divisor = 1})
    : literal = null,
      divisor = _bounded(divisor, 1, 65535, 'divisor') {
    if (field == null) throw ArgumentError.notNull('field');
  }

  factory ProjectCaptureIntegerOperand.fromJson(Map<String, dynamic> json) {
    _keys(json, {'literal', 'field', 'divisor'});
    if (json.containsKey('literal')) {
      _keys(json, {'literal'});
      return ProjectCaptureIntegerOperand.literal(_integer(json, 'literal'));
    }
    return ProjectCaptureIntegerOperand.field(
      _enumValue(ProjectCaptureNumericField.values, json['field']),
      divisor: json.containsKey('divisor') ? _integer(json, 'divisor') : 1,
    );
  }

  final int? literal;
  final ProjectCaptureNumericField? field;
  final int divisor;

  Map<String, dynamic> toJson() => literal != null
      ? {'literal': literal}
      : {'field': field!.name, if (divisor != 1) 'divisor': divisor};
}

sealed class ProjectCaptureCondition {
  const ProjectCaptureCondition();

  factory ProjectCaptureCondition.fromJson(Map<String, dynamic> json) =>
      _condition(json, 0);

  Map<String, dynamic> toJson();
}

final class ProjectCaptureAlwaysCondition extends ProjectCaptureCondition {
  const ProjectCaptureAlwaysCondition();

  @override
  Map<String, dynamic> toJson() => {'kind': 'always'};
}

final class ProjectCaptureNumericCondition extends ProjectCaptureCondition {
  const ProjectCaptureNumericCondition({
    required this.left,
    required this.comparison,
    required this.right,
  });

  final ProjectCaptureIntegerOperand left;
  final ProjectCaptureComparison comparison;
  final ProjectCaptureIntegerOperand right;

  @override
  Map<String, dynamic> toJson() => {
    'kind': 'numeric',
    'left': left.toJson(),
    'comparison': comparison.name,
    'right': right.toJson(),
  };
}

final class ProjectCaptureMatchCondition extends ProjectCaptureCondition {
  ProjectCaptureMatchCondition({
    required this.field,
    required Set<String> values,
  }) : values = Set.unmodifiable(values) {
    if (values.isEmpty ||
        values.length > 1024 ||
        values.any((value) => value.isEmpty || value.trim() != value)) {
      throw ArgumentError.value(
        values,
        'values',
        'expected 1..1024 nonempty identities',
      );
    }
    if (field == ProjectCaptureMatchField.encounterOrigin &&
        values.any(
          (value) => !ProjectCaptureEncounterOrigin.values.any(
            (origin) => origin.name == value,
          ),
        )) {
      throw ArgumentError.value(values, 'values', 'unknown encounter origin');
    }
  }

  final ProjectCaptureMatchField field;
  final Set<String> values;

  @override
  Map<String, dynamic> toJson() => {
    'kind': 'match',
    'field': field.name,
    'values': values.toList()..sort(),
  };
}

final class ProjectCaptureRelationCondition extends ProjectCaptureCondition {
  const ProjectCaptureRelationCondition(this.relation);

  final ProjectCaptureRelation relation;

  @override
  Map<String, dynamic> toJson() => {
    'kind': 'relation',
    'relation': relation.name,
  };
}

final class ProjectCaptureGroupCondition extends ProjectCaptureCondition {
  ProjectCaptureGroupCondition({
    required this.group,
    required List<ProjectCaptureCondition> conditions,
  }) : conditions = List.unmodifiable(conditions) {
    if (conditions.isEmpty || conditions.length > 64) {
      throw ArgumentError.value(
        conditions.length,
        'conditions',
        'expected 1..64 conditions',
      );
    }
    _validateTree(this, 0);
  }

  final ProjectCaptureGroup group;
  final List<ProjectCaptureCondition> conditions;

  @override
  Map<String, dynamic> toJson() => {
    'kind': group.name,
    'conditions': conditions.map((condition) => condition.toJson()).toList(),
  };
}

sealed class ProjectCaptureRateAdjustment {
  const ProjectCaptureRateAdjustment();

  factory ProjectCaptureRateAdjustment.fromJson(Map<String, dynamic> json) {
    switch (json['kind']) {
      case 'add':
        _keys(json, {'kind', 'amount'});
        return ProjectCaptureRateAdd(_integer(json, 'amount'));
      case 'multiply':
        _keys(json, {'kind', 'numerator', 'denominator'});
        return ProjectCaptureRateMultiply(
          numerator: _integer(json, 'numerator'),
          denominator: _integer(json, 'denominator'),
        );
      default:
        throw FormatException(
          'Unknown capture adjustment kind: ${json['kind']}',
        );
    }
  }

  Map<String, dynamic> toJson();
}

final class ProjectCaptureRateAdd extends ProjectCaptureRateAdjustment {
  ProjectCaptureRateAdd(int amount)
    : amount = _bounded(amount, -65535, 65535, 'amount');

  final int amount;

  @override
  Map<String, dynamic> toJson() => {'kind': 'add', 'amount': amount};
}

final class ProjectCaptureRateMultiply extends ProjectCaptureRateAdjustment {
  ProjectCaptureRateMultiply({required int numerator, required int denominator})
    : numerator = _bounded(numerator, 1, 65535, 'numerator'),
      denominator = _bounded(denominator, 1, 65535, 'denominator');

  final int numerator;
  final int denominator;

  @override
  Map<String, dynamic> toJson() => {
    'kind': 'multiply',
    'numerator': numerator,
    'denominator': denominator,
  };
}

final class ProjectCaptureRateRule {
  ProjectCaptureRateRule({required this.when, required this.adjustment}) {
    _validateTree(when, 0);
  }

  factory ProjectCaptureRateRule.fromJson(Map<String, dynamic> json) {
    _keys(json, {'when', 'adjustment'});
    return ProjectCaptureRateRule(
      when: ProjectCaptureCondition.fromJson(_object(json['when'])),
      adjustment: ProjectCaptureRateAdjustment.fromJson(
        _object(json['adjustment']),
      ),
    );
  }

  final ProjectCaptureCondition when;
  final ProjectCaptureRateAdjustment adjustment;

  Map<String, dynamic> toJson() => {
    'when': when.toJson(),
    'adjustment': adjustment.toJson(),
  };
}

sealed class ProjectCaptureSuccessEffect {
  const ProjectCaptureSuccessEffect();

  factory ProjectCaptureSuccessEffect.fromJson(Map<String, dynamic> json) {
    _keys(json, {'kind', 'value'});
    if (json['kind'] != 'setFriendship') {
      throw FormatException('Unknown capture success effect: ${json['kind']}');
    }
    return ProjectCaptureSetFriendship(_integer(json, 'value'));
  }

  Map<String, dynamic> toJson();
}

final class ProjectCaptureSetFriendship extends ProjectCaptureSuccessEffect {
  ProjectCaptureSetFriendship(int value)
    : value = _bounded(value, 0, 255, 'value');

  final int value;

  @override
  Map<String, dynamic> toJson() => {'kind': 'setFriendship', 'value': value};
}

final class ProjectContextualCapturePolicy {
  ProjectContextualCapturePolicy({
    List<ProjectCaptureRateRule> rateRules = const [],
    List<ProjectCaptureSuccessEffect> successEffects = const [],
  }) : rateRules = List.unmodifiable(rateRules),
       successEffects = List.unmodifiable(successEffects) {
    if (rateRules.length > 64 || successEffects.length > 1) {
      throw ArgumentError(
        'Capture policy accepts at most 64 rate rules and one friendship effect',
      );
    }
  }

  factory ProjectContextualCapturePolicy.fromJson(Map<String, dynamic> json) {
    _keys(json, {'policyId', 'rateRules', 'successEffects'});
    if (json['policyId'] != algorithmId) {
      throw FormatException(
        'Unsupported contextual capture policy: ${json['policyId']}',
      );
    }
    return ProjectContextualCapturePolicy(
      rateRules: _list(
        json['rateRules'],
        64,
      ).map((rule) => ProjectCaptureRateRule.fromJson(_object(rule))).toList(),
      successEffects: _list(json['successEffects'], 1)
          .map(
            (effect) => ProjectCaptureSuccessEffect.fromJson(_object(effect)),
          )
          .toList(),
    );
  }

  static const String algorithmId = 'pokemap-contextual-capture-v1';
  static const String randomPolicyId = 'pokemap-capture-single-draw-v1';
  static const String shakePolicyId = 'pokemap-capture-shakes-v1';

  final List<ProjectCaptureRateRule> rateRules;
  final List<ProjectCaptureSuccessEffect> successEffects;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectContextualCapturePolicy &&
          const DeepCollectionEquality().equals(toJson(), other.toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());

  Map<String, dynamic> toJson() => {
    'policyId': algorithmId,
    'rateRules': rateRules.map((rule) => rule.toJson()).toList(),
    'successEffects': successEffects.map((effect) => effect.toJson()).toList(),
  };
}

ProjectCaptureCondition _condition(Map<String, dynamic> json, int depth) {
  if (depth > 8) {
    throw const FormatException('Capture condition depth exceeds 8');
  }
  switch (json['kind']) {
    case 'always':
      _keys(json, {'kind'});
      return const ProjectCaptureAlwaysCondition();
    case 'numeric':
      _keys(json, {'kind', 'left', 'comparison', 'right'});
      return ProjectCaptureNumericCondition(
        left: ProjectCaptureIntegerOperand.fromJson(_object(json['left'])),
        comparison: _enumValue(
          ProjectCaptureComparison.values,
          json['comparison'],
        ),
        right: ProjectCaptureIntegerOperand.fromJson(_object(json['right'])),
      );
    case 'match':
      _keys(json, {'kind', 'field', 'values'});
      final values = _list(json['values'], 1024);
      if (values.any((value) => value is! String) ||
          values.toSet().length != values.length) {
        throw const FormatException(
          'Capture match values must be distinct strings',
        );
      }
      return ProjectCaptureMatchCondition(
        field: _enumValue(ProjectCaptureMatchField.values, json['field']),
        values: values.cast<String>().toSet(),
      );
    case 'relation':
      _keys(json, {'kind', 'relation'});
      return ProjectCaptureRelationCondition(
        _enumValue(ProjectCaptureRelation.values, json['relation']),
      );
    case 'all':
    case 'any':
      _keys(json, {'kind', 'conditions'});
      return ProjectCaptureGroupCondition(
        group: _enumValue(ProjectCaptureGroup.values, json['kind']),
        conditions: _list(
          json['conditions'],
          64,
        ).map((value) => _condition(_object(value), depth + 1)).toList(),
      );
    default:
      throw FormatException('Unknown capture condition kind: ${json['kind']}');
  }
}

void _validateTree(ProjectCaptureCondition condition, int depth) {
  if (depth > 8) throw ArgumentError('Capture condition depth exceeds 8');
  if (condition is ProjectCaptureGroupCondition) {
    for (final child in condition.conditions) {
      _validateTree(child, depth + 1);
    }
  }
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw const FormatException('Expected capture JSON object');
  }
  return Map<String, dynamic>.from(value);
}

List<dynamic> _list(Object? value, int maximum) {
  if (value is! List || value.length > maximum) {
    throw FormatException(
      'Expected capture list with at most $maximum entries',
    );
  }
  return value;
}

void _keys(Map<String, dynamic> json, Set<String> allowed) {
  for (final key in json.keys) {
    if (!allowed.contains(key)) {
      throw FormatException('Unexpected capture field: $key');
    }
  }
}

int _integer(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('Capture $key must be an integer');
  return value;
}

T _enumValue<T extends Enum>(List<T> values, Object? value) {
  for (final candidate in values) {
    if (candidate.name == value) return candidate;
  }
  throw FormatException('Unsupported capture value: $value');
}

int _bounded(int value, int minimum, int maximum, String name) {
  if (value < minimum || value > maximum) {
    throw RangeError.range(value, minimum, maximum, name);
  }
  return value;
}
