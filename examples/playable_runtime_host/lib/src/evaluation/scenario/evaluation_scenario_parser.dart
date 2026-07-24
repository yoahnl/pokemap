import 'dart:convert';

import '../contracts/evaluation_policy.dart';
import '../contracts/evaluation_scenario.dart';
import 'evaluation_command_catalog.dart';

const _rootRequiredKeys = <String>{
  'schemaVersion',
  'id',
  'title',
  'projectId',
  'policy',
  'start',
  'steps',
};
const _rootOptionalKeys = <String>{'criteria'};
const _assertionMatchers = <String>{
  'equals',
  'notEquals',
  'contains',
  'notContains',
  'greaterThan',
  'lessThan',
  'isTrue',
  'isFalse',
  'isNull',
  'isNotNull',
};
const _markerMatchers = <String>{
  'isTrue',
  'isFalse',
  'isNull',
  'isNotNull',
};
const _stringArgumentKeys = <String>{
  'checkpointId',
  'entityId',
  'factId',
  'itemId',
  'mapId',
  'name',
  'pokemonId',
  'triggerId',
  'warpId',
};
const _nonNegativeIntegerArgumentKeys = <String>{
  'choiceIndex',
  'linesBeforeChoice',
  'moveIndex',
  'preferredAxis',
  'x',
  'y',
};
const _directions = <String>{'north', 'east', 'south', 'west'};
final _idPattern = RegExp(r'^[a-z0-9][a-z0-9._-]*$');
final _absolutePathPattern = RegExp(r'^(?:/|[A-Za-z]:[\\/]|file:)');

final class EvaluationScenarioParser {
  const EvaluationScenarioParser();

  EvaluationScenario parseString(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw EvaluationScenarioFormatException(
        r'$',
        'Invalid JSON: ${error.message}',
      );
    }

    final root = _object(decoded, r'$');
    _rejectAbsoluteStrings(root, r'$');
    _expectKeys(
      root,
      path: r'$',
      required: _rootRequiredKeys,
      optional: _rootOptionalKeys,
    );

    final schemaVersion = _integer(root['schemaVersion'], r'$.schemaVersion');
    final id = _id(root['id'], r'$.id');
    final title = _nonBlankString(root['title'], r'$.title');
    final projectId = _id(root['projectId'], r'$.projectId');
    final policy = _policy(root['policy'], r'$.policy');
    final start = _start(root['start'], r'$.start');
    final steps = _steps(root['steps'], r'$.steps');
    final criteria = root.containsKey('criteria')
        ? _criteria(root['criteria'], r'$.criteria')
        : const <EvaluationCriterionDefinition>[];

    try {
      return EvaluationScenario(
        schemaVersion: schemaVersion,
        id: id,
        title: title,
        projectId: projectId,
        policy: policy,
        start: start,
        steps: steps,
        criteria: criteria,
      );
    } on ArgumentError catch (error) {
      throw EvaluationScenarioFormatException(
        r'$',
        error.message?.toString() ?? error.toString(),
      );
    }
  }

  EvaluationPolicy _policy(Object? value, String path) {
    return switch (_nonBlankString(value, path)) {
      'probe' => EvaluationPolicy.probe,
      'certify' => EvaluationPolicy.certify,
      final policy => _fail(path, 'Unknown policy "$policy".'),
    };
  }

  EvaluationStart _start(Object? value, String path) {
    final start = _object(value, path);
    if (start.length != 1) {
      _fail(path, 'Start must declare exactly one start mode.');
    }
    if (start.containsKey('newGame')) {
      if (start['newGame'] != true) {
        _fail('$path.newGame', 'newGame must be true.');
      }
      return const EvaluationStart.newGame();
    }
    if (start.containsKey('checkpointId')) {
      return EvaluationStart.checkpoint(
        _id(start['checkpointId'], '$path.checkpointId'),
      );
    }
    _fail(path, 'Start must declare newGame or checkpointId.');
  }

  List<EvaluationStep> _steps(Object? value, String path) {
    final entries = _list(value, path);
    final steps = <EvaluationStep>[];
    final ids = <String>{};
    for (var index = 0; index < entries.length; index += 1) {
      final stepPath = '$path[$index]';
      final step = _step(_object(entries[index], stepPath), stepPath);
      if (!ids.add(step.id)) {
        _fail('$stepPath.id', 'Step id "${step.id}" is duplicated.');
      }
      steps.add(step);
    }
    return steps;
  }

  EvaluationStep _step(Map<String, Object?> step, String path) {
    final id = _id(step['id'], '$path.id');
    final hasCommand = step.containsKey('command');
    final hasAssertion = step.containsKey('assert');
    if (hasCommand == hasAssertion) {
      _fail(path, 'A step must declare exactly one command or assertion.');
    }
    return hasCommand
        ? _commandStep(step, path, id)
        : _assertionStep(step, path, id);
  }

  EvaluationCommandStep _commandStep(
    Map<String, Object?> step,
    String path,
    String id,
  ) {
    final operation = _nonBlankString(step['command'], '$path.command');
    final definition = evaluationCommandCatalog[operation];
    if (definition == null) {
      _fail('$path.command', 'Unknown command "$operation".');
    }

    final arguments = Map<String, Object?>.from(step)
      ..remove('id')
      ..remove('command');
    _expectKeys(
      arguments,
      path: path,
      required: definition.requiredKeys,
      optional: definition.optionalKeys,
    );
    for (final entry in arguments.entries) {
      _validateArgument(entry.key, entry.value, '$path.${entry.key}');
    }
    return EvaluationCommandStep(
      id: id,
      operation: operation,
      arguments: arguments,
    );
  }

  EvaluationAssertionStep _assertionStep(
    Map<String, Object?> step,
    String path,
    String id,
  ) {
    final statePath = _nonBlankString(step['assert'], '$path.assert');
    final candidateMatchers = step.keys
        .where((key) => key != 'id' && key != 'assert')
        .toList(growable: false);
    if (candidateMatchers.length != 1 ||
        !_assertionMatchers.contains(candidateMatchers.single)) {
      _fail(
        path,
        'Assertion must declare exactly one supported matcher.',
      );
    }
    final matcher = candidateMatchers.single;
    final expected = step[matcher];
    if (_markerMatchers.contains(matcher) && expected != true) {
      _fail('$path.$matcher', '$matcher must be declared as true.');
    }
    if ((matcher == 'greaterThan' || matcher == 'lessThan') &&
        expected is! num) {
      _fail('$path.$matcher', '$matcher requires a numeric value.');
    }
    return EvaluationAssertionStep(
      id: id,
      path: statePath,
      matcher: matcher,
      expected: _markerMatchers.contains(matcher) ? null : expected,
    );
  }

  List<EvaluationCriterionDefinition> _criteria(
    Object? value,
    String path,
  ) {
    final entries = _list(value, path);
    final criteria = <EvaluationCriterionDefinition>[];
    final ids = <String>{};
    for (var index = 0; index < entries.length; index += 1) {
      final criterionPath = '$path[$index]';
      final criterion = _object(entries[index], criterionPath);
      _expectKeys(
        criterion,
        path: criterionPath,
        required: const <String>{'id', 'stepIds'},
      );
      final id = _id(criterion['id'], '$criterionPath.id');
      if (!ids.add(id)) {
        _fail('$criterionPath.id', 'Criterion id "$id" is duplicated.');
      }
      final stepIds = _list(criterion['stepIds'], '$criterionPath.stepIds')
          .asMap()
          .entries
          .map(
            (entry) => _id(
              entry.value,
              '$criterionPath.stepIds[${entry.key}]',
            ),
          )
          .toList(growable: false);
      criteria.add(
        EvaluationCriterionDefinition(id: id, stepIds: stepIds),
      );
    }
    return criteria;
  }

  void _validateArgument(String key, Object? value, String path) {
    if (_stringArgumentKeys.contains(key)) {
      _nonBlankString(value, path);
      return;
    }
    if (_nonNegativeIntegerArgumentKeys.contains(key)) {
      final integer = _integer(value, path);
      if (integer < 0) {
        _fail(path, '$key must be non-negative.');
      }
      return;
    }
    switch (key) {
      case 'direction':
        final direction = _nonBlankString(value, path);
        if (!_directions.contains(direction)) {
          _fail(path, 'direction must be north, east, south, or west.');
        }
      case 'quantity':
        if (_integer(value, path) < 1) {
          _fail(path, 'quantity must be at least 1.');
        }
      case 'timeoutMilliseconds':
        final timeout = _integer(value, path);
        if (timeout < 1 || timeout > 300000) {
          _fail(path, 'timeoutMilliseconds must be between 1 and 300000.');
        }
      case 'value':
        if (value is Map || value is List) {
          _fail(path, 'value must be a JSON scalar.');
        }
        if (value is num && value.isNaN) {
          _fail(path, 'value must be finite.');
        }
      case 'quantities':
        final quantities = _object(value, path);
        for (final entry in quantities.entries) {
          _nonBlankString(entry.key, '$path.${entry.key}');
          if (_integer(entry.value, '$path.${entry.key}') < 0) {
            _fail('$path.${entry.key}', 'Bag quantities must be non-negative.');
          }
        }
      case 'pokemon':
        final pokemon = _list(value, path);
        if (pokemon.isEmpty) {
          _fail(path, 'pokemon must contain at least one entry.');
        }
        for (var index = 0; index < pokemon.length; index += 1) {
          _object(pokemon[index], '$path[$index]');
        }
    }
  }
}

final class EvaluationScenarioFormatException implements FormatException {
  const EvaluationScenarioFormatException(this.path, this.message);

  final String path;

  @override
  final String message;

  @override
  int? get offset => null;

  @override
  Object? get source => null;

  @override
  String toString() => 'Invalid PokeMap Eval scenario at $path: $message';
}

Map<String, Object?> _object(Object? value, String path) {
  if (value is! Map) {
    _fail(path, 'Expected a JSON object.');
  }
  try {
    return Map<String, Object?>.from(value);
  } on TypeError {
    _fail(path, 'Object keys must be strings.');
  }
}

List<Object?> _list(Object? value, String path) {
  if (value is! List) {
    _fail(path, 'Expected a JSON array.');
  }
  return List<Object?>.from(value);
}

String _nonBlankString(Object? value, String path) {
  if (value is! String || value.trim().isEmpty) {
    _fail(path, 'Expected a non-blank string.');
  }
  return value;
}

String _id(Object? value, String path) {
  final id = _nonBlankString(value, path);
  if (!_idPattern.hasMatch(id)) {
    _fail(
      path,
      'Expected a lowercase id containing letters, digits, ".", "_", or "-".',
    );
  }
  return id;
}

int _integer(Object? value, String path) {
  if (value is! int) {
    _fail(path, 'Expected an integer.');
  }
  return value;
}

void _expectKeys(
  Map<String, Object?> value, {
  required String path,
  required Set<String> required,
  Set<String> optional = const <String>{},
}) {
  for (final key in required) {
    if (!value.containsKey(key)) {
      _fail('$path.$key', 'Missing required field "$key".');
    }
  }
  final allowed = <String>{...required, ...optional};
  for (final key in value.keys) {
    if (!allowed.contains(key)) {
      _fail('$path.$key', 'Unknown field "$key".');
    }
  }
}

void _rejectAbsoluteStrings(Object? value, String path) {
  switch (value) {
    case String string when _absolutePathPattern.hasMatch(string):
      _fail(path, 'Absolute paths and file URIs are forbidden.');
    case Map map:
      for (final entry in map.entries) {
        _rejectAbsoluteStrings(entry.value, '$path.${entry.key}');
      }
    case List list:
      for (var index = 0; index < list.length; index += 1) {
        _rejectAbsoluteStrings(list[index], '$path[$index]');
      }
  }
}

Never _fail(String path, String message) {
  throw EvaluationScenarioFormatException(path, message);
}
