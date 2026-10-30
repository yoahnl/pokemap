import 'dart:collection';
import 'dart:math' as math;

final class ProjectEntryTree<T> extends ListBase<T> {
  ProjectEntryTree._(this._root);

  factory ProjectEntryTree.prepare(Iterable<T> entries) {
    final values = entries is List<T>
        ? entries
        : entries.toList(growable: false);
    return ProjectEntryTree._(
      values.isEmpty ? null : _EntryNode.build(values, 0, values.length),
    );
  }

  final _EntryNode<T>? _root;
  @override
  int get length => _root?.length ?? 0;
  @override
  set length(int value) =>
      throw UnsupportedError('Project entries are immutable.');
  @override
  T operator [](int index) {
    RangeError.checkValidIndex(index, this);
    return _root!.at(index);
  }

  @override
  void operator []=(int index, T value) =>
      throw UnsupportedError('Project entries are immutable.');
  @override
  Iterator<T> get iterator => (_root?.values ?? Iterable<T>.empty()).iterator;

  @override
  Iterable<R> map<R>(R Function(T) f) =>
      (_root?.values ?? Iterable<T>.empty()).map(f);

  ProjectEntryTree<T> replace(
    int index,
    T value, {
    void Function()? onNodeCopied,
  }) {
    RangeError.checkValidIndex(index, this);
    final root = _root!.replace(index, value, onNodeCopied);
    return identical(root, _root) ? this : ProjectEntryTree._(root);
  }

  ProjectEntryTree<T> inserted(
    int index,
    T value, {
    void Function()? onNodeCopied,
  }) {
    RangeError.checkValueInInterval(index, 0, length);
    if (_root == null) {
      onNodeCopied?.call();
      return ProjectEntryTree._(_EntryNode.leaf(value));
    }
    return ProjectEntryTree._(_root.insert(index, value, onNodeCopied));
  }

  ProjectEntryTree<T> removed(int index, {void Function()? onNodeCopied}) {
    RangeError.checkValidIndex(index, this);
    return ProjectEntryTree._(_root!.remove(index, onNodeCopied));
  }

  List<T> changesSince(
    ProjectEntryTree<T> previous, {
    void Function()? onNodeVisited,
  }) {
    final changes = <T>[];
    void visit(_EntryNode<T>? before, _EntryNode<T>? after) {
      if (identical(before, after)) return;
      onNodeVisited?.call();
      if (after!.left == null) {
        changes.add(after.value as T);
      } else {
        visit(before!.left, after.left);
        visit(before.right, after.right);
      }
    }

    visit(previous._root, _root);
    return changes;
  }
}

final class _EntryNode<T> {
  _EntryNode.leaf(T this.value)
    : left = null,
      right = null,
      length = 1,
      height = 1;
  _EntryNode.branch(_EntryNode<T> this.left, _EntryNode<T> this.right)
    : value = null,
      length = left.length + right.length,
      height = math.max(left.height, right.height) + 1;
  final T? value;
  final _EntryNode<T>? left, right;
  final int length, height;

  static _EntryNode<T> build<T>(List<T> values, int start, int end) {
    if (end - start == 1) return _EntryNode.leaf(values[start]);
    final middle = (start + end) ~/ 2;
    return _EntryNode.branch(
      build(values, start, middle),
      build(values, middle, end),
    );
  }

  T at(int index) {
    final first = left;
    if (first == null) return value as T;
    return index < first.length
        ? first.at(index)
        : right!.at(index - first.length);
  }

  _EntryNode<T> replace(int index, T value, void Function()? copied) {
    final first = left;
    if (first == null) {
      if (this.value == value) return this;
      copied?.call();
      return _EntryNode.leaf(value);
    }
    final second = right!;
    final nextLeft = index < first.length
        ? first.replace(index, value, copied)
        : first;
    final nextRight = index < first.length
        ? second
        : second.replace(index - first.length, value, copied);
    if (identical(first, nextLeft) && identical(second, nextRight)) return this;
    return _branch(nextLeft, nextRight, copied);
  }

  _EntryNode<T> insert(int index, T value, void Function()? copied) {
    final first = left;
    if (first == null) {
      copied?.call();
      final added = _EntryNode.leaf(value);
      return index == 0
          ? _branch(added, this, copied)
          : _branch(this, added, copied);
    }
    return index <= first.length
        ? _join(first.insert(index, value, copied), right!, copied)
        : _join(
            first,
            right!.insert(index - first.length, value, copied),
            copied,
          );
  }

  _EntryNode<T>? remove(int index, void Function()? copied) {
    final first = left;
    if (first == null) return null;
    final second = right!;
    if (index < first.length) {
      final next = first.remove(index, copied);
      return next == null ? second : _join(next, second, copied);
    }
    final next = second.remove(index - first.length, copied);
    return next == null ? first : _join(first, next, copied);
  }

  static _EntryNode<T> _branch<T>(
    _EntryNode<T> left,
    _EntryNode<T> right,
    void Function()? copied,
  ) {
    copied?.call();
    return _EntryNode.branch(left, right);
  }

  static _EntryNode<T> _join<T>(
    _EntryNode<T> left,
    _EntryNode<T> right,
    void Function()? copied,
  ) {
    if (left.height > right.height + 1) {
      final inner = _join(left.right!, right, copied);
      return _balance(left.left!, inner, copied);
    }
    if (right.height > left.height + 1) {
      final inner = _join(left, right.left!, copied);
      return _balance(inner, right.right!, copied);
    }
    return _branch(left, right, copied);
  }

  static _EntryNode<T> _balance<T>(
    _EntryNode<T> left,
    _EntryNode<T> right,
    void Function()? copied,
  ) {
    if (left.height > right.height + 1) {
      if (left.left!.height >= left.right!.height) {
        return _branch(left.left!, _branch(left.right!, right, copied), copied);
      }
      final middle = left.right!;
      return _branch(
        _branch(left.left!, middle.left!, copied),
        _branch(middle.right!, right, copied),
        copied,
      );
    }
    if (right.height > left.height + 1) {
      if (right.right!.height >= right.left!.height) {
        return _branch(
          _branch(left, right.left!, copied),
          right.right!,
          copied,
        );
      }
      final middle = right.left!;
      return _branch(
        _branch(left, middle.left!, copied),
        _branch(middle.right!, right.right!, copied),
        copied,
      );
    }
    return _branch(left, right, copied);
  }

  Iterable<T> get values sync* {
    final pending = <_EntryNode<T>>[this];
    while (pending.isNotEmpty) {
      final node = pending.removeLast();
      if (node.left == null) {
        yield node.value as T;
      } else {
        pending.add(node.right!);
        pending.add(node.left!);
      }
    }
  }
}
