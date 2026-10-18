import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;

enum BattleTransitionUsage { wild, trainer }

enum BattleTransitionEffect {
  flash,
  spriteZoom,
  spriteAngle,
  sheetCells,
  holdBlack,
  terrainSweep,
  interleavedBands,
  thresholdDissolve,
  fadeToBlack,
}

final class BattleTransitionPhaseDefinition {
  BattleTransitionPhaseDefinition._(this.effect, this.durationSeconds,
      Map<String, Object?> parameters)
      : parameters = Map.unmodifiable(parameters);

  factory BattleTransitionPhaseDefinition.fromJson(Object? value) {
    final json = _object(value);
    final effect = BattleTransitionEffect.values
        .where((entry) => entry.name == json['kind']).firstOrNull;
    if (effect == null) throw const FormatException('Unknown battle transition effect.');
    final fields = switch (effect) {
      BattleTransitionEffect.flash => {'factor'},
      BattleTransitionEffect.spriteZoom => {'zoomFrom'},
      BattleTransitionEffect.spriteAngle => {'angleFromDegrees', 'angleToDegrees'},
      BattleTransitionEffect.sheetCells => {'sheetName', 'columns', 'rows'},
      BattleTransitionEffect.terrainSweep => {'terrain'},
      BattleTransitionEffect.interleavedBands => {'bandHeight'},
      BattleTransitionEffect.thresholdDissolve => {'textureName', 'tFrom', 'tTo', 'fineThreshold'},
      BattleTransitionEffect.holdBlack || BattleTransitionEffect.fadeToBlack => <String>{},
    };
    _keys(json, {'kind', 'durationSeconds', ...fields});
    final duration = _number(json['durationSeconds'], 0.001, 60);
    switch (effect) {
      case BattleTransitionEffect.flash:
        _number(json['factor'], 0.001, 128);
      case BattleTransitionEffect.spriteZoom:
        _number(json['zoomFrom'], 0.001, 100);
      case BattleTransitionEffect.spriteAngle:
        _number(json['angleFromDegrees'], -360000, 360000);
        _number(json['angleToDegrees'], -360000, 360000);
      case BattleTransitionEffect.sheetCells:
        validateBattleTransitionAssetReference(json['sheetName']);
        for (final field in ['columns', 'rows']) {
          if (json[field] is! int || (json[field] as int) < 1 || (json[field] as int) > 256) {
            throw const FormatException('Invalid battle transition sheet grid.');
          }
        }
      case BattleTransitionEffect.terrainSweep:
        if (!const {'grass', 'water', 'dust'}.contains(json['terrain'])) {
          throw const FormatException('Invalid battle transition terrain.');
        }
      case BattleTransitionEffect.interleavedBands:
        _number(json['bandHeight'], 0.001, 4096);
      case BattleTransitionEffect.thresholdDissolve:
        validateBattleTransitionAssetReference(json['textureName']);
        _number(json['tFrom'], 0, 1);
        _number(json['tTo'], 0, 1);
        if (json['fineThreshold'] is! bool) {
          throw const FormatException('Invalid battle transition threshold precision.');
        }
      case BattleTransitionEffect.holdBlack || BattleTransitionEffect.fadeToBlack:
        break;
    }
    return BattleTransitionPhaseDefinition._(effect, duration,
        {for (final field in fields) field: json[field]});
  }

  final BattleTransitionEffect effect;
  final double durationSeconds;
  final Map<String, Object?> parameters;

  Map<String, Object?> toJson() => {
    'kind': effect.name, 'durationSeconds': durationSeconds, ...parameters,
  };

  @override
  bool operator ==(Object other) => other is BattleTransitionPhaseDefinition &&
      const DeepCollectionEquality().equals(toJson(), other.toJson());
  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

final class BattleTransitionDefinition {
  BattleTransitionDefinition._(this.id, this.label,
      List<BattleTransitionUsage> usages, List<BattleTransitionPhaseDefinition> phases)
      : usages = List.unmodifiable(usages), phases = List.unmodifiable(phases);

  factory BattleTransitionDefinition.fromJson(Object? value) {
    final json = _object(value);
    _keys(json, {'id', 'label', 'usages', 'phases'});
    final id = _text(json['id']);
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$').hasMatch(id)) {
      throw const FormatException('Invalid battle transition ID.');
    }
    final label = _text(json['label']);
    final sourceUsages = json['usages'];
    if (sourceUsages is! List || sourceUsages.isEmpty || sourceUsages.length > 2 ||
        sourceUsages.toSet().length != sourceUsages.length ||
        sourceUsages.any((entry) => !BattleTransitionUsage.values.any((usage) => usage.name == entry))) {
      throw const FormatException('Invalid battle transition usages.');
    }
    final sourcePhases = json['phases'];
    if (sourcePhases is! List || sourcePhases.isEmpty || sourcePhases.length > 64) {
      throw const FormatException('Invalid battle transition phase sequence.');
    }
    final phases = sourcePhases.map(BattleTransitionPhaseDefinition.fromJson).toList();
    if (phases.fold<double>(0, (sum, phase) => sum + phase.durationSeconds) > 120) {
      throw const FormatException('Battle transition duration exceeds its budget.');
    }
    if (phases.any((phase) => const {BattleTransitionEffect.spriteZoom, BattleTransitionEffect.spriteAngle}.contains(phase.effect)) &&
        !phases.any((phase) => phase.effect == BattleTransitionEffect.sheetCells)) {
      throw const FormatException('Sprite phases require a sheet phase.');
    }
    return BattleTransitionDefinition._(id, label,
        sourceUsages.map((entry) => BattleTransitionUsage.values.singleWhere((usage) => usage.name == entry)).toList(), phases);
  }

  final String id;
  final String label;
  final List<BattleTransitionUsage> usages;
  final List<BattleTransitionPhaseDefinition> phases;
  double get totalSeconds => phases.fold(0, (sum, phase) => sum + phase.durationSeconds);
  Map<String, Object?> toJson() => {
    'id': id, 'label': label,
    'usages': usages.map((usage) => usage.name).toList(),
    'phases': phases.map((phase) => phase.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) => other is BattleTransitionDefinition &&
      const DeepCollectionEquality().equals(toJson(), other.toJson());
  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

void validateBattleTransitionAssetReference(Object? value) {
  final text = _text(value);
  final separator = text.indexOf(':');
  if (separator < 1 || !const {'project', 'embedded'}.contains(text.substring(0, separator))) {
    throw const FormatException('Battle transition assets require an explicit project or embedded source.');
  }
  final relative = text.substring(separator + 1);
  if (relative.isEmpty || relative.contains(RegExp(r'[%\\:\x00]')) ||
      relative.split('/').any((part) => part.isEmpty || part == '.' || part == '..') ||
      !relative.toLowerCase().endsWith('.png')) {
    throw const FormatException('Invalid battle transition asset path.');
  }
}

Map<String, Object?> _object(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw const FormatException('Expected a battle transition object.');
  }
  return Map<String, Object?>.from(value);
}

void _keys(Map<String, Object?> value, Set<String> fields) {
  if (value.length != fields.length || value.keys.any((key) => !fields.contains(key))) {
    throw const FormatException('Invalid battle transition fields.');
  }
}

String _text(Object? value) {
  if (value is! String || value.isEmpty || value.length > 256 || value.trim() != value ||
      value.codeUnits.any((unit) => unit < 32 || unit == 127)) {
    throw const FormatException('Expected bounded battle transition text.');
  }
  return value;
}

double _number(Object? value, double minimum, double maximum) {
  if (value is! num || !value.isFinite || value < minimum || value > maximum) {
    throw const FormatException('Invalid battle transition numerical parameter.');
  }
  return value.toDouble();
}

Map<String, Object?> get battleTransitionDefinitionJsonSchema => {
  'type': 'object',
  'additionalProperties': false,
  'required': ['id', 'label', 'usages', 'phases'],
  'properties': {
    'id': {'type': 'string', 'pattern': r'^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$'},
    'label': {'type': 'string', 'minLength': 1, 'maxLength': 256},
    'usages': {'type': 'array', 'minItems': 1, 'maxItems': 2, 'uniqueItems': true,
      'items': {'enum': BattleTransitionUsage.values.map((usage) => usage.name).toList()}},
    'phases': {'type': 'array', 'minItems': 1, 'maxItems': 64, 'items': {
      'oneOf': [for (final effect in BattleTransitionEffect.values) _phaseSchema(effect)],
    }},
  },
};

Map<String, Object?> _phaseSchema(BattleTransitionEffect effect) {
  const asset = {'type': 'string', 'pattern': r'^(project|embedded):.+\.png$', 'maxLength': 256};
  const number = {'type': 'number'};
  final parameters = switch (effect) {
    BattleTransitionEffect.flash => {'factor': number},
    BattleTransitionEffect.spriteZoom => {'zoomFrom': number},
    BattleTransitionEffect.spriteAngle => {'angleFromDegrees': number, 'angleToDegrees': number},
    BattleTransitionEffect.sheetCells => {'sheetName': asset,
      'columns': const {'type': 'integer', 'minimum': 1, 'maximum': 256},
      'rows': const {'type': 'integer', 'minimum': 1, 'maximum': 256}},
    BattleTransitionEffect.terrainSweep => {'terrain': const {'enum': ['grass', 'water', 'dust']}},
    BattleTransitionEffect.interleavedBands => {'bandHeight': number},
    BattleTransitionEffect.thresholdDissolve => {'textureName': asset, 'tFrom': number,
      'tTo': number, 'fineThreshold': const {'type': 'boolean'}},
    BattleTransitionEffect.holdBlack || BattleTransitionEffect.fadeToBlack => <String, Object?>{},
  };
  return {
    'type': 'object', 'additionalProperties': false,
    'required': ['kind', 'durationSeconds', ...parameters.keys],
    'properties': {'kind': {'const': effect.name},
      'durationSeconds': {'type': 'number', 'minimum': 0.001, 'maximum': 60},
      ...parameters},
  };
}
