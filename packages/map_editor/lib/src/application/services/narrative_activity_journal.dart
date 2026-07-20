import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'narrative_document_session.dart';

enum NarrativeActivityKind {
  edited,
  saved,
  recovered,
  saveFailed,
  conflicted,
}

enum NarrativeActivityDestination {
  overview,
  storylines,
  scenes,
  events,
  cinematics,
  dialogues,
  facts,
  worldRules,
  validator,
}

@immutable
final class NarrativeActivityEntry {
  const NarrativeActivityEntry({
    required this.id,
    required this.occurredAtUtc,
    required this.kind,
    required this.label,
    required this.destination,
    this.detail,
    this.operationId,
    this.assetId,
  });

  final String id;
  final DateTime occurredAtUtc;
  final NarrativeActivityKind kind;
  final String label;
  final String? detail;
  final NarrativeActivityDestination destination;
  final String? operationId;
  final String? assetId;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'occurredAtUtc': occurredAtUtc.toUtc().toIso8601String(),
        'kind': kind.name,
        'label': label,
        'detail': detail,
        'destination': destination.name,
        'operationId': operationId,
        'assetId': assetId,
      };

  factory NarrativeActivityEntry.fromJson(Object? value) {
    final json = _object(value, 'entry');
    final occurredAt = DateTime.tryParse(
      _text(json['occurredAtUtc'], 'entry.occurredAtUtc'),
    );
    if (occurredAt == null || !occurredAt.isUtc) {
      throw const FormatException(
        'entry.occurredAtUtc must be an ISO-8601 UTC timestamp.',
      );
    }
    return NarrativeActivityEntry(
      id: _text(json['id'], 'entry.id'),
      occurredAtUtc: occurredAt,
      kind: _enumValue(
        NarrativeActivityKind.values,
        json['kind'],
        'entry.kind',
      ),
      label: _text(json['label'], 'entry.label'),
      detail: _optionalText(json['detail'], 'entry.detail'),
      destination: _enumValue(
        NarrativeActivityDestination.values,
        json['destination'],
        'entry.destination',
      ),
      operationId: _optionalText(json['operationId'], 'entry.operationId'),
      assetId: _optionalText(json['assetId'], 'entry.assetId'),
    );
  }
}

@immutable
final class NarrativeActivityJournal {
  const NarrativeActivityJournal({
    required List<NarrativeActivityEntry> entries,
    this.schemaVersion = 1,
    this.maxEntries = 100,
  })  : assert(maxEntries > 0),
        _entries = entries;

  const NarrativeActivityJournal.empty({this.maxEntries = 100})
      : schemaVersion = 1,
        _entries = const <NarrativeActivityEntry>[];

  final int schemaVersion;
  final int maxEntries;
  final List<NarrativeActivityEntry> _entries;

  List<NarrativeActivityEntry> get entries =>
      UnmodifiableListView<NarrativeActivityEntry>(_entries);

  NarrativeActivityJournal append(NarrativeActivityEntry entry) {
    if (_entries.any((candidate) => candidate.id == entry.id)) return this;
    final next = <NarrativeActivityEntry>[entry, ..._entries]
      ..sort((left, right) {
        final byDate = right.occurredAtUtc.compareTo(left.occurredAtUtc);
        return byDate != 0 ? byDate : right.id.compareTo(left.id);
      });
    return NarrativeActivityJournal(
      entries: List<NarrativeActivityEntry>.unmodifiable(
        next.take(maxEntries),
      ),
      schemaVersion: schemaVersion,
      maxEntries: maxEntries,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'maxEntries': maxEntries,
        'entries': _entries.map((entry) => entry.toJson()).toList(),
      };

  factory NarrativeActivityJournal.fromJson(Object? value) {
    final json = _object(value, 'journal');
    final schemaVersion = _integer(json['schemaVersion'], 'schemaVersion');
    if (schemaVersion != 1) {
      throw FormatException(
        'Unsupported narrative activity schemaVersion: $schemaVersion.',
      );
    }
    final maxEntries = _integer(json['maxEntries'], 'maxEntries');
    if (maxEntries <= 0) {
      throw const FormatException('maxEntries must be greater than zero.');
    }
    final rawEntries = json['entries'];
    if (rawEntries is! List) {
      throw const FormatException('entries must be a JSON list.');
    }
    final entries =
        rawEntries.map(NarrativeActivityEntry.fromJson).toList(growable: false);
    if (entries.length > maxEntries) {
      throw const FormatException('entries exceeds maxEntries.');
    }
    final ids = entries.map((entry) => entry.id).toSet();
    if (ids.length != entries.length) {
      throw const FormatException('entries contains duplicate ids.');
    }
    for (var index = 1; index < entries.length; index++) {
      if (entries[index - 1]
          .occurredAtUtc
          .isBefore(entries[index].occurredAtUtc)) {
        throw const FormatException('entries must be newest first.');
      }
    }
    return NarrativeActivityJournal(
      entries: List<NarrativeActivityEntry>.unmodifiable(entries),
      schemaVersion: schemaVersion,
      maxEntries: maxEntries,
    );
  }
}

/// Converts product-visible NSC-13 session transitions into durable activity.
///
/// The service is deliberately opt-in: it cannot infer runtime activity and
/// emits nothing for transient `saving` publications or unchanged snapshots.
final class NarrativeActivityJournalService {
  const NarrativeActivityJournalService();

  NarrativeActivityJournal recordSessionTransition<T>({
    required NarrativeActivityJournal journal,
    required NarrativeDocumentSessionState<T> previous,
    required NarrativeDocumentSessionState<T> current,
    required DateTime occurredAtUtc,
    required NarrativeActivityDestination destination,
    String? assetId,
  }) {
    final activity = _activityForTransition(
      previous: previous,
      current: current,
      occurredAtUtc: occurredAtUtc.toUtc(),
      destination: destination,
      assetId: assetId,
    );
    return activity == null ? journal : journal.append(activity);
  }

  NarrativeActivityEntry? _activityForTransition<T>({
    required NarrativeDocumentSessionState<T> previous,
    required NarrativeDocumentSessionState<T> current,
    required DateTime occurredAtUtc,
    required NarrativeActivityDestination destination,
    required String? assetId,
  }) {
    final currentUndo = current.history.undoEntries;
    final previousUndo = previous.history.undoEntries;
    final latestIntent = currentUndo.isEmpty ? null : currentUndo.last;
    final previousIntent = previousUndo.isEmpty ? null : previousUndo.last;
    final hasNewIntent = latestIntent != null &&
        (previousIntent == null ||
            latestIntent.operationId != previousIntent.operationId ||
            currentUndo.length != previousUndo.length);

    if (current.status == NarrativeDocumentSessionStatus.dirty &&
        hasNewIntent) {
      return _entry(
        current: current,
        occurredAtUtc: occurredAtUtc,
        kind: NarrativeActivityKind.edited,
        label: latestIntent.label,
        detail: current.message,
        destination: destination,
        operationId: latestIntent.operationId,
        assetId: assetId,
      );
    }
    if (current.status == previous.status) return null;

    return switch (current.status) {
      NarrativeDocumentSessionStatus.saved => _entry(
          current: current,
          occurredAtUtc: occurredAtUtc,
          kind: NarrativeActivityKind.saved,
          label: 'Modifications narratives enregistrées',
          detail: current.message,
          destination: destination,
          operationId: latestIntent?.operationId,
          assetId: assetId,
        ),
      NarrativeDocumentSessionStatus.recovered => _entry(
          current: current,
          occurredAtUtc: occurredAtUtc,
          kind: NarrativeActivityKind.recovered,
          label: 'Modifications narratives récupérées',
          detail: current.message,
          destination: destination,
          operationId: latestIntent?.operationId,
          assetId: assetId,
        ),
      NarrativeDocumentSessionStatus.failed => _entry(
          current: current,
          occurredAtUtc: occurredAtUtc,
          kind: NarrativeActivityKind.saveFailed,
          label: 'Échec de l’enregistrement narratif',
          detail: current.message,
          destination: destination,
          operationId: latestIntent?.operationId,
          assetId: assetId,
        ),
      NarrativeDocumentSessionStatus.conflicted => _entry(
          current: current,
          occurredAtUtc: occurredAtUtc,
          kind: NarrativeActivityKind.conflicted,
          label: 'Conflit de version narrative',
          detail: current.message,
          destination: destination,
          operationId: latestIntent?.operationId,
          assetId: assetId,
        ),
      NarrativeDocumentSessionStatus.dirty ||
      NarrativeDocumentSessionStatus.saving =>
        null,
    };
  }

  NarrativeActivityEntry _entry<T>({
    required NarrativeDocumentSessionState<T> current,
    required DateTime occurredAtUtc,
    required NarrativeActivityKind kind,
    required String label,
    required String? detail,
    required NarrativeActivityDestination destination,
    required String? operationId,
    required String? assetId,
  }) {
    final discriminator =
        operationId ?? current.code ?? current.baselineRevision;
    final suffix = _identifier(discriminator ?? current.documentId);
    return NarrativeActivityEntry(
      id: 'activity-${occurredAtUtc.microsecondsSinceEpoch}-${kind.name}-$suffix',
      occurredAtUtc: occurredAtUtc,
      kind: kind,
      label: label,
      detail: _normalizedOptional(detail),
      destination: destination,
      operationId: _normalizedOptional(operationId),
      assetId: _normalizedOptional(assetId),
    );
  }
}

abstract interface class NarrativeActivityJournalStore {
  Future<NarrativeActivityJournal> load();

  Future<void> save(NarrativeActivityJournal journal);
}

/// Observes one NSC-13 document session and serializes meaningful activity.
final class NarrativeActivitySessionRecorder<T> {
  NarrativeActivitySessionRecorder({
    required NarrativeDocumentSession<T> session,
    required NarrativeActivityJournalStore store,
    required NarrativeActivityDestination destination,
    DateTime Function()? nowUtc,
    VoidCallback? onPersisted,
    ValueChanged<Object>? onError,
  })  : _session = session,
        _store = store,
        _destination = destination,
        _nowUtc = nowUtc ?? (() => DateTime.now().toUtc()),
        _onPersisted = onPersisted,
        _onError = onError,
        _previous = session.state {
    _session.addListener(_recordCurrentTransition);
  }

  final NarrativeDocumentSession<T> _session;
  final NarrativeActivityJournalStore _store;
  final NarrativeActivityDestination _destination;
  final DateTime Function() _nowUtc;
  final VoidCallback? _onPersisted;
  final ValueChanged<Object>? _onError;
  final NarrativeActivityJournalService _service =
      const NarrativeActivityJournalService();

  NarrativeDocumentSessionState<T> _previous;
  NarrativeActivityJournal? _journal;
  Future<void> _writeTail = Future<void>.value();
  bool _disposed = false;

  Future<void> get settled => _writeTail;

  void _recordCurrentTransition() {
    if (_disposed) return;
    final current = _session.state;
    final previous = _previous;
    _previous = current;
    _writeTail = _writeTail.then((_) async {
      try {
        final loaded = _journal ?? await _store.load();
        final next = _service.recordSessionTransition(
          journal: loaded,
          previous: previous,
          current: current,
          occurredAtUtc: _nowUtc().toUtc(),
          destination: _destination,
        );
        _journal = next;
        if (identical(next, loaded)) return;
        await _store.save(next);
        _onPersisted?.call();
      } on Object catch (error) {
        _onError?.call(error);
      }
    });
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _session.removeListener(_recordCurrentTransition);
  }
}

String _identifier(String value) {
  final normalized = value.trim().toLowerCase().replaceAll(
        RegExp('[^a-z0-9_-]+'),
        '-',
      );
  return normalized.isEmpty ? 'narrative' : normalized;
}

Map<String, Object?> _object(Object? value, String field) {
  if (value is! Map) {
    throw FormatException('$field must be a JSON object.');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('$field contains a non-string key.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

String _text(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-empty string.');
  }
  return value.trim();
}

String? _optionalText(Object? value, String field) {
  if (value == null) return null;
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be null or a non-empty string.');
  }
  return value.trim();
}

String? _normalizedOptional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

int _integer(Object? value, String field) {
  if (value is! int) {
    throw FormatException('$field must be an integer.');
  }
  return value;
}

T _enumValue<T extends Enum>(List<T> values, Object? value, String field) {
  final name = _text(value, field);
  for (final candidate in values) {
    if (candidate.name == name) return candidate;
  }
  throw FormatException('$field contains the unsupported value "$name".');
}
