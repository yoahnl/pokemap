import 'dart:collection';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'project_model3d.dart';

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
      _ModelEntriesTree(
        values.isEmpty ? null : _ModelEntryNode.build(values, 0, values.length),
      ),
      Map.unmodifiable(positions),
    );
  }

  final _ModelEntriesTree _tree;
  final Map<String, int> _positions;

  @override
  Iterator<ProjectModel3dEntry> get iterator => _tree.iterator;

  @override
  Iterable<T> map<T>(T Function(ProjectModel3dEntry) f) =>
      (_tree.root?.values ?? const <ProjectModel3dEntry>[]).map(f);

  ProjectModel3dEntry? lookup(String id) {
    final position = _positions[id];
    return position == null ? null : _tree[position];
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
    var root = _tree.root;
    for (final change in changes.entries) {
      root = root!.replace(change.key, change.value, onNodeCopied);
    }
    return identical(root, _tree.root)
        ? this
        : ProjectModel3dEntries._(_ModelEntriesTree(root), _positions);
  }
}

final class _ModelEntriesTree extends ListBase<ProjectModel3dEntry> {
  _ModelEntriesTree(this.root);

  final _ModelEntryNode? root;

  @override
  int get length => root?.length ?? 0;

  @override
  set length(int value) =>
      throw UnsupportedError('Model entries are immutable.');

  @override
  ProjectModel3dEntry operator [](int index) {
    RangeError.checkValidIndex(index, this);
    return root!.at(index);
  }

  @override
  void operator []=(int index, ProjectModel3dEntry value) =>
      throw UnsupportedError('Model entries are immutable.');

  @override
  Iterator<ProjectModel3dEntry> get iterator =>
      (root?.values ?? const <ProjectModel3dEntry>[]).iterator;
}

final class _ModelEntryNode {
  _ModelEntryNode.leaf(this.value) : left = null, right = null, length = 1;

  _ModelEntryNode.branch(_ModelEntryNode this.left, _ModelEntryNode this.right)
    : value = null,
      length = left.length + right.length;

  static _ModelEntryNode build(
    List<ProjectModel3dEntry> values,
    int start,
    int end,
  ) {
    if (end - start == 1) return _ModelEntryNode.leaf(values[start]);
    final middle = (start + end) ~/ 2;
    return _ModelEntryNode.branch(
      build(values, start, middle),
      build(values, middle, end),
    );
  }

  final ProjectModel3dEntry? value;
  final _ModelEntryNode? left;
  final _ModelEntryNode? right;
  final int length;

  ProjectModel3dEntry at(int index) {
    final first = left;
    if (first == null) return value!;
    return index < first.length
        ? first.at(index)
        : right!.at(index - first.length);
  }

  _ModelEntryNode replace(
    int index,
    ProjectModel3dEntry model,
    void Function()? onCopied,
  ) {
    final first = left;
    if (first == null) {
      if (value == model) return this;
      onCopied?.call();
      return _ModelEntryNode.leaf(model);
    }
    final second = right!;
    final nextLeft = index < first.length
        ? first.replace(index, model, onCopied)
        : first;
    final nextRight = index < first.length
        ? second
        : second.replace(index - first.length, model, onCopied);
    if (identical(first, nextLeft) && identical(second, nextRight)) return this;
    onCopied?.call();
    return _ModelEntryNode.branch(nextLeft, nextRight);
  }

  Iterable<ProjectModel3dEntry> get values sync* {
    final pending = <_ModelEntryNode>[this];
    while (pending.isNotEmpty) {
      final node = pending.removeLast();
      if (node.left == null) {
        yield node.value!;
      } else {
        pending.add(node.right!);
        pending.add(node.left!);
      }
    }
  }
}
