import 'package:freezed_annotation/freezed_annotation.dart';

import 'project_model3d.dart';
import 'project_entry_tree.dart';

final class ProjectModel3dEntries
    extends EqualUnmodifiableListView<ProjectModel3dEntry> {
  ProjectModel3dEntries._(this._tree, this._positions) : super(_tree);

  factory ProjectModel3dEntries.prepare(Iterable<ProjectModel3dEntry> entries) {
    if (entries is ProjectModel3dEntries) return entries;
    final values = entries.toList(growable: false);
    final positions = <String, int>{};
    for (var index = 0; index < values.length; index++) {
      if (positions.containsKey(values[index].id)) {
        throw ArgumentError.value(
          values[index].id,
          'entries',
          'Duplicate model identity.',
        );
      }
      positions[values[index].id] = index;
    }
    return ProjectModel3dEntries._(
      ProjectEntryTree.prepare(values),
      Map.unmodifiable(positions),
    );
  }

  final ProjectEntryTree<ProjectModel3dEntry> _tree;
  final Map<String, int> _positions;

  @override
  Iterator<ProjectModel3dEntry> get iterator => _tree.iterator;

  @override
  Iterable<T> map<T>(T Function(ProjectModel3dEntry) f) => _tree.map(f);

  ProjectModel3dEntry? lookup(String id) {
    final position = _positions[id];
    return position == null ? null : _tree[position];
  }

  List<ProjectModel3dEntry>? changesSince(
    ProjectModel3dEntries previous, {
    void Function()? onNodeVisited,
  }) {
    if (!identical(_positions, previous._positions)) return null;
    return _tree.changesSince(previous._tree, onNodeVisited: onNodeVisited);
  }

  ProjectModel3dEntries replaceSelected(
    Iterable<ProjectModel3dEntry> selected, {
    void Function()? onNodeCopied,
  }) {
    final changes = <int, ProjectModel3dEntry>{};
    for (final model in selected) {
      final position = _positions[model.id];
      if (position == null || changes.containsKey(position)) {
        throw ArgumentError.value(
          model.id,
          'selected',
          'Model identity is absent or duplicated.',
        );
      }
      changes[position] = model;
    }
    var tree = _tree;
    for (final change in changes.entries) {
      tree = tree.replace(change.key, change.value, onNodeCopied: onNodeCopied);
    }
    return identical(tree, _tree)
        ? this
        : ProjectModel3dEntries._(tree, _positions);
  }
}
