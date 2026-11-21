import 'dart:convert';

import '../contracts/evaluation_state_snapshot.dart';

enum EvaluationChangeKind {
  added,
  removed,
  changed,
  unchanged,
}

final class EvaluationStateChange {
  const EvaluationStateChange({
    required this.path,
    required this.kind,
    this.before,
    this.after,
  });

  final String path;
  final EvaluationChangeKind kind;
  final Object? before;
  final Object? after;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'path': path,
      'kind': kind.name,
      'before': before,
      'after': after,
    };
  }
}

final class EvaluationStateDiff {
  EvaluationStateDiff(List<EvaluationStateChange> changes)
      : changes = List<EvaluationStateChange>.unmodifiable(changes);

  final List<EvaluationStateChange> changes;

  EvaluationStateChange? changeAt(String path) {
    for (final change in changes) {
      if (change.path == path) return change;
    }
    return null;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'changes': changes.map((change) => change.toJson()).toList(),
    };
  }
}

final class EvaluationStateDiffer {
  const EvaluationStateDiffer({this.includeUnchanged = false});

  final bool includeUnchanged;

  EvaluationStateDiff compare(
    EvaluationStateSnapshot before,
    EvaluationStateSnapshot after,
  ) {
    final beforeValues = <String, Object?>{};
    final afterValues = <String, Object?>{};
    _flatten(before.toJson(), '', beforeValues);
    _flatten(after.toJson(), '', afterValues);

    final paths = <String>{
      ...beforeValues.keys,
      ...afterValues.keys,
    }.toList()
      ..sort();
    final changes = <EvaluationStateChange>[];
    for (final path in paths) {
      final existedBefore = beforeValues.containsKey(path);
      final existsAfter = afterValues.containsKey(path);
      final beforeValue = beforeValues[path];
      final afterValue = afterValues[path];
      final kind = switch ((existedBefore, existsAfter)) {
        (false, true) => EvaluationChangeKind.added,
        (true, false) => EvaluationChangeKind.removed,
        _ when _jsonEquals(beforeValue, afterValue) =>
          EvaluationChangeKind.unchanged,
        _ => EvaluationChangeKind.changed,
      };
      if (kind == EvaluationChangeKind.unchanged && !includeUnchanged) {
        continue;
      }
      changes.add(
        EvaluationStateChange(
          path: path,
          kind: kind,
          before: existedBefore ? beforeValue : null,
          after: existsAfter ? afterValue : null,
        ),
      );
    }
    return EvaluationStateDiff(changes);
  }
}

void _flatten(
  Object? value,
  String path,
  Map<String, Object?> target,
) {
  if (value is Map && value.isNotEmpty) {
    final keys = value.keys.cast<String>().toList()..sort();
    for (final key in keys) {
      _flatten(value[key], path.isEmpty ? key : '$path.$key', target);
    }
    return;
  }
  if (path.isNotEmpty) {
    target[path] = value;
  }
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
