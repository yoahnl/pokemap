import 'dart:collection';

import 'package:flutter/foundation.dart';

/// One complete user intention captured as immutable before/after documents.
///
/// The session deliberately stores whole authoring documents at this boundary:
/// a graph edit or a preset application must undo as one product action, not as
/// a sequence of implementation-field mutations.
@immutable
final class NarrativeUndoEntry<T> {
  const NarrativeUndoEntry({
    required this.operationId,
    required this.label,
    required this.before,
    required this.after,
  });

  final String operationId;
  final String label;
  final T before;
  final T after;
}

/// Result of applying one undo or redo transition.
@immutable
final class NarrativeUndoTransition<T> {
  const NarrativeUndoTransition({
    required this.document,
    required this.stack,
    required this.entry,
  });

  final T document;
  final NarrativeUndoStack<T> stack;
  final NarrativeUndoEntry<T> entry;
}

/// Immutable, bounded undo/redo history for Narrative Studio documents.
///
/// Entries are ordered oldest to newest. Drift checks are intentionally strict:
/// applying an entry to an unexpected visible document would silently replace a
/// newer edit, so the stack fails closed with [StateError] instead.
@immutable
final class NarrativeUndoStack<T> {
  const NarrativeUndoStack({
    List<NarrativeUndoEntry<T>> undoEntries = const [],
    List<NarrativeUndoEntry<T>> redoEntries = const [],
    this.capacity = 100,
  })  : assert(capacity > 0),
        _undoEntries = undoEntries,
        _redoEntries = redoEntries;

  final List<NarrativeUndoEntry<T>> _undoEntries;
  final List<NarrativeUndoEntry<T>> _redoEntries;
  final int capacity;

  List<NarrativeUndoEntry<T>> get undoEntries =>
      UnmodifiableListView(_undoEntries);

  List<NarrativeUndoEntry<T>> get redoEntries =>
      UnmodifiableListView(_redoEntries);

  bool get canUndo => _undoEntries.isNotEmpty;
  bool get canRedo => _redoEntries.isNotEmpty;

  NarrativeUndoStack<T> record({
    required String operationId,
    required String label,
    required T before,
    required T after,
  }) {
    final normalizedOperationId = _requiredText(
      operationId,
      'operationId',
    );
    final normalizedLabel = _requiredText(label, 'label');
    if (before == after) {
      return this;
    }

    final nextUndo = <NarrativeUndoEntry<T>>[
      ..._undoEntries,
      NarrativeUndoEntry<T>(
        operationId: normalizedOperationId,
        label: normalizedLabel,
        before: before,
        after: after,
      ),
    ];
    final overflow = nextUndo.length - capacity;
    return NarrativeUndoStack<T>(
      undoEntries: overflow > 0 ? nextUndo.sublist(overflow) : nextUndo,
      // A new product intention creates a new history branch. Retaining redo
      // here would let users resurrect a document that no longer descends from
      // the visible state.
      redoEntries: const [],
      capacity: capacity,
    );
  }

  NarrativeUndoTransition<T>? undo(T current) {
    if (_undoEntries.isEmpty) {
      return null;
    }
    final entry = _undoEntries.last;
    if (current != entry.after) {
      throw StateError(
        'Cannot undo ${entry.operationId}: the visible document drifted.',
      );
    }
    return NarrativeUndoTransition<T>(
      document: entry.before,
      entry: entry,
      stack: NarrativeUndoStack<T>(
        undoEntries: _undoEntries.sublist(0, _undoEntries.length - 1),
        redoEntries: <NarrativeUndoEntry<T>>[..._redoEntries, entry],
        capacity: capacity,
      ),
    );
  }

  NarrativeUndoTransition<T>? redo(T current) {
    if (_redoEntries.isEmpty) {
      return null;
    }
    final entry = _redoEntries.last;
    if (current != entry.before) {
      throw StateError(
        'Cannot redo ${entry.operationId}: the visible document drifted.',
      );
    }
    final nextUndo = <NarrativeUndoEntry<T>>[..._undoEntries, entry];
    final overflow = nextUndo.length - capacity;
    return NarrativeUndoTransition<T>(
      document: entry.after,
      entry: entry,
      stack: NarrativeUndoStack<T>(
        undoEntries: overflow > 0 ? nextUndo.sublist(overflow) : nextUndo,
        redoEntries: _redoEntries.sublist(0, _redoEntries.length - 1),
        capacity: capacity,
      ),
    );
  }
}

String _requiredText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'must not be empty');
  }
  return normalized;
}
