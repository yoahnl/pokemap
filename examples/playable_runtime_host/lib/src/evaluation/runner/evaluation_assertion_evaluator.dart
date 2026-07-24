import 'dart:convert';

import '../contracts/evaluation_scenario.dart';
import '../contracts/evaluation_state_snapshot.dart';

final class EvaluationAssertionResult {
  const EvaluationAssertionResult({
    required this.stepId,
    required this.path,
    required this.matcher,
    required this.expected,
    required this.actual,
    required this.passed,
  });

  final String stepId;
  final String path;
  final String matcher;
  final Object? expected;
  final Object? actual;
  final bool passed;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'stepId': stepId,
      'path': path,
      'matcher': matcher,
      'expected': expected,
      'actual': actual,
      'passed': passed,
    };
  }
}

final class EvaluationAssertionEvaluator {
  const EvaluationAssertionEvaluator();

  EvaluationAssertionResult evaluate(
    EvaluationAssertionStep assertion,
    EvaluationStateSnapshot snapshot,
  ) {
    final path = _canonicalPath(assertion.path);
    final actual = _resolvePath(snapshot.toJson(), path);
    final passed = switch (assertion.matcher) {
      'equals' => _jsonEquals(actual, assertion.expected),
      'notEquals' => !_jsonEquals(actual, assertion.expected),
      'contains' => _contains(actual, assertion.expected),
      'notContains' => !_contains(actual, assertion.expected),
      'greaterThan' => _compareNumbers(
          actual,
          assertion.expected,
          assertion.matcher,
          (left, right) => left > right,
        ),
      'lessThan' => _compareNumbers(
          actual,
          assertion.expected,
          assertion.matcher,
          (left, right) => left < right,
        ),
      'isTrue' => actual == true,
      'isFalse' => actual == false,
      'isNull' => actual == null,
      'isNotNull' => actual != null,
      final matcher => throw EvaluationAssertionDefinitionError(
          'Unsupported assertion matcher "$matcher".',
        ),
    };

    return EvaluationAssertionResult(
      stepId: assertion.id,
      path: assertion.path,
      matcher: assertion.matcher,
      expected: assertion.expected,
      actual: actual,
      passed: passed,
    );
  }
}

final class EvaluationAssertionDefinitionError implements Exception {
  const EvaluationAssertionDefinitionError(this.message);

  final String message;

  @override
  String toString() => 'Invalid evaluation assertion: $message';
}

const _pathAliases = <String, String>{
  'state.money': 'trainer.money',
  'state.currentMapId': 'world.mapId',
  'state.mapId': 'world.mapId',
  'state.x': 'world.position.x',
  'state.y': 'world.position.y',
  'state.movementMode': 'world.movementMode',
};

const _allowedRoots = <String>{
  'world',
  'facts',
  'eventLedger',
  'progression',
  'trainer',
  'bag',
  'shop',
  'party',
  'storage',
  'dialogue',
  'scene',
  'battle',
  'save',
};

String _canonicalPath(String requestedPath) {
  final path = _pathAliases[requestedPath] ?? requestedPath;
  final root = path.split('.').first;
  if (path.trim().isEmpty ||
      path == 'projectId' ||
      path == 'runId' ||
      !_allowedRoots.contains(root)) {
    throw EvaluationAssertionDefinitionError(
      'Snapshot path "$requestedPath" is not allowlisted.',
    );
  }
  return path;
}

Object? _resolvePath(Map<String, Object?> snapshot, String path) {
  Object? current = snapshot;
  for (final segment in path.split('.')) {
    if (segment == 'length' && current is Iterable) {
      current = current.length;
      continue;
    }
    if (current is Map) {
      if (!current.containsKey(segment)) {
        throw EvaluationAssertionDefinitionError(
          'Snapshot path "$path" does not exist.',
        );
      }
      current = current[segment];
      continue;
    }
    if (current is List) {
      final index = int.tryParse(segment);
      if (index == null || index < 0 || index >= current.length) {
        throw EvaluationAssertionDefinitionError(
          'Snapshot path "$path" has an invalid list index.',
        );
      }
      current = current[index];
      continue;
    }
    throw EvaluationAssertionDefinitionError(
      'Snapshot path "$path" traverses a scalar value.',
    );
  }
  return current;
}

bool _contains(Object? actual, Object? expected) {
  return switch (actual) {
    String value when expected is String => value.contains(expected),
    Map value => value.containsKey(expected),
    Iterable value => value.any((item) => _jsonEquals(item, expected)),
    _ => throw const EvaluationAssertionDefinitionError(
        'Matcher "contains" requires a string, map, or list value.',
      ),
  };
}

bool _compareNumbers(
  Object? actual,
  Object? expected,
  String matcher,
  bool Function(num left, num right) compare,
) {
  if (actual is! num || expected is! num) {
    throw EvaluationAssertionDefinitionError(
      'Matcher "$matcher" requires numeric actual and expected values.',
    );
  }
  return compare(actual, expected);
}

bool _jsonEquals(Object? left, Object? right) {
  return jsonEncode(_canonicalize(left)) == jsonEncode(_canonicalize(right));
}

Object? _canonicalize(Object? value) {
  return switch (value) {
    Map map => <String, Object?>{
        for (final key in map.keys.cast<String>().toList()..sort())
          key: _canonicalize(map[key]),
      },
    List list => list.map(_canonicalize).toList(growable: false),
    _ => value,
  };
}
