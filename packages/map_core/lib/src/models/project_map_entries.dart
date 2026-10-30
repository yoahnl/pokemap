import 'dart:collection';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'project_entry_tree.dart';
import 'project_manifest.dart';

final class ProjectMapEntries
    extends EqualUnmodifiableListView<ProjectMapEntry> {
  ProjectMapEntries._(
    this._ordered,
    this._identities,
    this._nextPosition,
    this._onEntryRead,
  ) : super(_MapEntryList(_ordered, _onEntryRead));

  factory ProjectMapEntries.prepare(
    Iterable<ProjectMapEntry> entries, {
    void Function()? onEntryRead,
  }) {
    if (entries is ProjectMapEntries) return entries;
    final ordered = <({int position, ProjectMapEntry value})>[];
    final identities = <({String id, int position})>[];
    final seen = <String>{};
    for (final entry in entries) {
      if (!seen.add(entry.id)) {
        throw ArgumentError.value(
          entry.id,
          'entries',
          'Duplicate map identity.',
        );
      }
      identities.add((id: entry.id, position: ordered.length));
      ordered.add((position: ordered.length, value: entry));
    }
    identities.sort((a, b) => a.id.compareTo(b.id));
    return ProjectMapEntries._(
      ProjectEntryTree.prepare(ordered),
      ProjectEntryTree.prepare(identities),
      ordered.length,
      onEntryRead,
    );
  }

  final ProjectEntryTree<({int position, ProjectMapEntry value})> _ordered;
  final ProjectEntryTree<({String id, int position})> _identities;
  final int _nextPosition;
  final void Function()? _onEntryRead;

  static int _lowerBound<T>(ProjectEntryTree<T> tree, int Function(T) compare) {
    var lower = 0;
    var upper = tree.length;
    while (lower < upper) {
      final middle = (lower + upper) ~/ 2;
      if (compare(tree[middle]) < 0) {
        lower = middle + 1;
      } else {
        upper = middle;
      }
    }
    return lower;
  }

  ProjectMapEntry? lookup(String id) {
    final identity = _lowerBound(
      _identities,
      (entry) => entry.id.compareTo(id),
    );
    if (identity == _identities.length || _identities[identity].id != id) {
      return null;
    }
    final slot = _identities[identity].position;
    final position = _lowerBound(
      _ordered,
      (entry) => entry.position.compareTo(slot),
    );
    _onEntryRead?.call();
    return _ordered[position].value;
  }

  @override
  bool contains(Object? element) =>
      element is ProjectMapEntry && lookup(element.id) == element;

  ProjectMapEntries applySelected({
    Iterable<ProjectMapEntry> upserts = const [],
    Set<String> removedIds = const {},
    Map<String, int> positions = const {},
    void Function()? onNodeCopied,
  }) {
    var ordered = _ordered;
    var identities = _identities;
    var nextPosition = _nextPosition;
    final removedSlots = <int>{};
    for (final id in removedIds) {
      final identity = _lowerBound(
        identities,
        (entry) => entry.id.compareTo(id),
      );
      if (identity == identities.length || identities[identity].id != id) {
        continue;
      }
      final slot = identities[identity].position;
      removedSlots.add(slot);
      final position = _lowerBound(
        ordered,
        (entry) => entry.position.compareTo(slot),
      );
      ordered = ordered.removed(position, onNodeCopied: onNodeCopied);
      identities = identities.removed(identity, onNodeCopied: onNodeCopied);
    }
    final availableSlots = removedSlots.toList()..sort();
    final selected = upserts.toList(growable: false);
    if (positions.isNotEmpty) {
      final originalOrder = {
        for (var index = 0; index < selected.length; index++)
          selected[index].id: index,
      };
      selected.sort((a, b) {
        final comparison = (positions[a.id] ?? ordered.length).compareTo(
          positions[b.id] ?? ordered.length,
        );
        return comparison != 0
            ? comparison
            : originalOrder[a.id]!.compareTo(originalOrder[b.id]!);
      });
    }
    final seen = <String>{};
    for (final entry in selected) {
      if (!seen.add(entry.id) || removedIds.contains(entry.id)) {
        throw ArgumentError.value(
          entry.id,
          'upserts',
          'Duplicate or removed map identity.',
        );
      }
      final identity = _lowerBound(
        identities,
        (value) => value.id.compareTo(entry.id),
      );
      if (identity == identities.length ||
          identities[identity].id != entry.id) {
        final target = positions[entry.id] ?? ordered.length;
        final reused = availableSlots
            .where(
              (slot) =>
                  _lowerBound(
                    ordered,
                    (value) => value.position.compareTo(slot),
                  ) ==
                  target,
            )
            .firstOrNull;
        if (reused == null && target != ordered.length) {
          throw ArgumentError.value(
            target,
            'positions',
            'A new map must append or replace a removed position.',
          );
        }
        final slot = reused ?? nextPosition++;
        availableSlots.remove(slot);
        identities = identities.inserted(identity, (
          id: entry.id,
          position: slot,
        ), onNodeCopied: onNodeCopied);
        ordered = ordered.inserted(target, (
          position: slot,
          value: entry,
        ), onNodeCopied: onNodeCopied);
      } else {
        final slot = identities[identity].position;
        final position = _lowerBound(
          ordered,
          (value) => value.position.compareTo(slot),
        );
        ordered = ordered.replace(position, (
          position: slot,
          value: entry,
        ), onNodeCopied: onNodeCopied);
      }
    }
    return identical(ordered, _ordered) && identical(identities, _identities)
        ? this
        : ProjectMapEntries._(ordered, identities, nextPosition, _onEntryRead);
  }
}

final class _MapEntryList extends ListBase<ProjectMapEntry> {
  _MapEntryList(this.tree, this.onEntryRead);
  final ProjectEntryTree<({int position, ProjectMapEntry value})> tree;
  final void Function()? onEntryRead;
  @override
  int get length => tree.length;
  @override
  set length(int value) => throw UnsupportedError('Map entries are immutable.');
  @override
  ProjectMapEntry operator [](int index) {
    onEntryRead?.call();
    return tree[index].value;
  }

  @override
  void operator []=(int index, ProjectMapEntry value) =>
      throw UnsupportedError('Map entries are immutable.');
  @override
  Iterator<ProjectMapEntry> get iterator => tree.map((entry) {
    onEntryRead?.call();
    return entry.value;
  }).iterator;
  @override
  Iterable<T> map<T>(T Function(ProjectMapEntry) f) => tree.map((entry) {
    onEntryRead?.call();
    return f(entry.value);
  });
}
