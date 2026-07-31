import '../contracts/authoring_receipt.dart';
import '../contracts/resource_ref.dart';
import '../ports/idempotency_store.dart';
import '../ports/project_file_reader.dart';
import '../support/authoring_fingerprint.dart';
import 'revision_set.dart';

enum AuthoringTransactionStatus {
  preparing,
  staged,
  prepared,
  promoting,
  committed,
  compensating,
  compensated,
}

final class AuthoringTransactionJournalEntry {
  AuthoringTransactionJournalEntry({
    required this.resource,
    required String storageKey,
    required String? beforeRevision,
    required String? afterRevision,
    this.promoted = false,
    this.compensated = false,
  })  : storageKey = _storageKey(storageKey),
        beforeRevision = _optionalRevision(beforeRevision, 'beforeRevision'),
        afterRevision = _optionalRevision(afterRevision, 'afterRevision') {
    if (beforeRevision == null && afterRevision == null) {
      throw ArgumentError(
        'A transaction journal entry requires a before or after revision.',
      );
    }
  }

  factory AuthoringTransactionJournalEntry.fromJson(
    Map<String, dynamic> json,
  ) {
    const keys = {
      'resource',
      'storageKey',
      'beforeRevision',
      'afterRevision',
      'promoted',
      'compensated',
    };
    if (json.keys.any((key) => !keys.contains(key))) {
      throw const FormatException('Unknown transaction journal entry field.');
    }
    final rawResource = json['resource'];
    if (rawResource is! Map ||
        !json.containsKey('beforeRevision') ||
        !json.containsKey('afterRevision')) {
      throw const FormatException('Invalid transaction journal entry.');
    }
    final beforeRevision = json['beforeRevision'];
    final afterRevision = json['afterRevision'];
    if ((beforeRevision != null && beforeRevision is! String) ||
        (afterRevision != null && afterRevision is! String)) {
      throw const FormatException('Journal revisions must be strings or null.');
    }
    try {
      return AuthoringTransactionJournalEntry(
        resource: AuthoringResourceRef.fromJson(
          Map<String, dynamic>.from(rawResource),
        ),
        storageKey: _requiredString(json['storageKey'], 'storageKey'),
        beforeRevision: beforeRevision as String?,
        afterRevision: afterRevision as String?,
        promoted: _requiredBool(json['promoted'], 'promoted'),
        compensated: _requiredBool(json['compensated'], 'compensated'),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final AuthoringResourceRef resource;
  final String storageKey;
  final String? beforeRevision;
  final String? afterRevision;
  final bool promoted;
  final bool compensated;

  AuthoringTransactionJournalEntry copyWith({
    bool? promoted,
    bool? compensated,
  }) {
    return AuthoringTransactionJournalEntry(
      resource: resource,
      storageKey: storageKey,
      beforeRevision: beforeRevision,
      afterRevision: afterRevision,
      promoted: promoted ?? this.promoted,
      compensated: compensated ?? this.compensated,
    );
  }

  Map<String, Object?> toJson() => {
        'resource': resource.toJson(),
        'storageKey': storageKey,
        'beforeRevision': beforeRevision,
        'afterRevision': afterRevision,
        'promoted': promoted,
        'compensated': compensated,
      };
}

/// Durable intent and checkpoint record for one recoverable transaction.
final class AuthoringTransactionJournal {
  AuthoringTransactionJournal({
    required String operationId,
    required String planId,
    required this.scope,
    required this.status,
    required DateTime createdAt,
    required DateTime updatedAt,
    required Iterable<AuthoringTransactionJournalEntry> entries,
    required this.intendedReceipt,
    this.finalReceipt,
  })  : operationId = _safeIdentity(operationId, 'operationId'),
        planId = _safeIdentity(planId, 'planId'),
        createdAt = createdAt.toUtc(),
        updatedAt = updatedAt.toUtc(),
        entries = _sortedEntries(entries) {
    if (this.entries.isEmpty) {
      throw ArgumentError.value(entries, 'entries', 'must not be empty');
    }
    final resources = <String>{};
    final storageKeys = <String>{};
    for (final entry in this.entries) {
      if (!resources.add('${entry.resource.kind}\u0000${entry.resource.id}') ||
          !storageKeys.add(entry.storageKey)) {
        throw ArgumentError(
          'Transaction journal resources and storage keys must be unique.',
        );
      }
    }
    if (this.updatedAt.isBefore(this.createdAt)) {
      throw ArgumentError.value(
        updatedAt,
        'updatedAt',
        'must not precede createdAt',
      );
    }
    final isFinal = status == AuthoringTransactionStatus.committed ||
        status == AuthoringTransactionStatus.compensated;
    if (isFinal != (finalReceipt != null)) {
      throw ArgumentError(
        'Committed or compensated journals require exactly one final receipt.',
      );
    }
    _requireReceiptMatchesScope(intendedReceipt, scope);
    if (intendedReceipt.status != AuthoringReceiptStatus.applied) {
      throw ArgumentError(
        'The intended transaction receipt must have applied status.',
      );
    }
    final receiptResources = {
      for (final resource in intendedReceipt.affectedResources)
        '${resource.kind}\u0000${resource.id}',
    };
    if (receiptResources.length != resources.length ||
        !receiptResources.containsAll(resources)) {
      throw ArgumentError(
        'Journal entries must match the intended receipt resource set.',
      );
    }
    final beforeSet = AuthoringRevisionSet([
      for (final entry in this.entries)
        AuthoringResourceRevision(
          resource: entry.resource,
          revision: entry.beforeRevision,
        ),
    ]);
    final afterSet = AuthoringRevisionSet([
      for (final entry in this.entries)
        AuthoringResourceRevision(
          resource: entry.resource,
          revision: entry.afterRevision,
        ),
    ]);
    if (intendedReceipt.beforeRevision != beforeSet.fingerprint ||
        intendedReceipt.afterRevision != afterSet.fingerprint) {
      throw ArgumentError(
        'Intended receipt revisions must match journal resource revisions.',
      );
    }
    if (finalReceipt != null) {
      _requireReceiptMatchesScope(finalReceipt!, scope);
      if (finalReceipt!.receiptId != intendedReceipt.receiptId) {
        throw ArgumentError(
          'The final receipt must retain the intended receipt identity.',
        );
      }
      if (canonicalAuthoringJson(finalReceipt!.diff.toJson()) !=
          canonicalAuthoringJson(intendedReceipt.diff.toJson())) {
        throw ArgumentError(
          'The final receipt must retain the intended structured diff.',
        );
      }
      final expectedFinalRevision =
          status == AuthoringTransactionStatus.compensated
              ? beforeSet.fingerprint
              : afterSet.fingerprint;
      if (finalReceipt!.afterRevision != expectedFinalRevision) {
        throw ArgumentError(
          'The final receipt revision must match the final journal state.',
        );
      }
    }
  }

  factory AuthoringTransactionJournal.fromJson(Map<String, dynamic> json) {
    const keys = {
      'schemaVersion',
      'operationId',
      'planId',
      'scope',
      'status',
      'createdAtUtc',
      'updatedAtUtc',
      'entries',
      'intendedReceipt',
      'finalReceipt',
    };
    if (json.keys.any((key) => !keys.contains(key)) ||
        json['schemaVersion'] != 1) {
      throw const FormatException('Invalid transaction journal schema.');
    }
    final rawScope = json['scope'];
    final rawEntries = json['entries'];
    final rawIntended = json['intendedReceipt'];
    final rawFinal = json['finalReceipt'];
    if (rawScope is! Map ||
        rawEntries is! List ||
        rawIntended is! Map ||
        (rawFinal != null && rawFinal is! Map)) {
      throw const FormatException('Invalid transaction journal objects.');
    }
    final rawStatus = json['status'];
    if (rawStatus is! String) {
      throw const FormatException('Transaction status must be a string.');
    }
    final status = AuthoringTransactionStatus.values.firstWhere(
      (candidate) => candidate.name == rawStatus,
      orElse: () => throw const FormatException('Unknown transaction status.'),
    );
    try {
      return AuthoringTransactionJournal(
        operationId: _requiredString(json['operationId'], 'operationId'),
        planId: _requiredString(json['planId'], 'planId'),
        scope: AuthoringIdempotencyScope.fromJson(
          Map<String, dynamic>.from(rawScope),
        ),
        status: status,
        createdAt: _utcDate(json['createdAtUtc'], 'createdAtUtc'),
        updatedAt: _utcDate(json['updatedAtUtc'], 'updatedAtUtc'),
        entries: rawEntries.map((rawEntry) {
          if (rawEntry is! Map) {
            throw const FormatException('Journal entry must be an object.');
          }
          return AuthoringTransactionJournalEntry.fromJson(
            Map<String, dynamic>.from(rawEntry),
          );
        }),
        intendedReceipt: AuthoringReceipt.fromJson(
          Map<String, dynamic>.from(rawIntended),
        ),
        finalReceipt: rawFinal == null
            ? null
            : AuthoringReceipt.fromJson(
                Map<String, dynamic>.from(rawFinal),
              ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String operationId;
  final String planId;
  final AuthoringIdempotencyScope scope;
  final AuthoringTransactionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AuthoringTransactionJournalEntry> entries;
  final AuthoringReceipt intendedReceipt;
  final AuthoringReceipt? finalReceipt;

  AuthoringTransactionJournal copyWith({
    AuthoringTransactionStatus? status,
    DateTime? updatedAt,
    Iterable<AuthoringTransactionJournalEntry>? entries,
    Object? finalReceipt = _unchangedReceipt,
  }) {
    return AuthoringTransactionJournal(
      operationId: operationId,
      planId: planId,
      scope: scope,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      entries: entries ?? this.entries,
      intendedReceipt: intendedReceipt,
      finalReceipt: identical(finalReceipt, _unchangedReceipt)
          ? this.finalReceipt
          : finalReceipt as AuthoringReceipt?,
    );
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'operationId': operationId,
        'planId': planId,
        'scope': scope.toJson(),
        'status': status.name,
        'createdAtUtc': createdAt.toIso8601String(),
        'updatedAtUtc': updatedAt.toIso8601String(),
        'entries': [for (final entry in entries) entry.toJson()],
        'intendedReceipt': intendedReceipt.toJson(),
        if (finalReceipt != null) 'finalReceipt': finalReceipt!.toJson(),
      };
}

const Object _unchangedReceipt = Object();

List<AuthoringTransactionJournalEntry> _sortedEntries(
  Iterable<AuthoringTransactionJournalEntry> entries,
) {
  final sorted = entries.toList()
    ..sort((left, right) {
      final storageOrder = left.storageKey.compareTo(right.storageKey);
      if (storageOrder != 0) return storageOrder;
      final kindOrder = left.resource.kind.compareTo(right.resource.kind);
      return kindOrder != 0
          ? kindOrder
          : left.resource.id.compareTo(right.resource.id);
    });
  return List.unmodifiable(sorted);
}

void _requireReceiptMatchesScope(
  AuthoringReceipt receipt,
  AuthoringIdempotencyScope scope,
) {
  if (receipt.actionId != scope.actionId ||
      receipt.actionVersion != scope.actionVersion) {
    throw ArgumentError(
      'Transaction receipt action must match the idempotency scope.',
    );
  }
}

String _storageKey(String value) {
  final segments = validateProjectRelativePath(value);
  if (segments.join('/') != value || segments.first == '.pokemap') {
    throw ArgumentError.value(
      value,
      'storageKey',
      'must be a normalized project-relative resource key',
    );
  }
  return value;
}

String? _optionalRevision(String? value, String field) {
  if (value != null && !RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(value, field, 'must be a SHA-256 fingerprint');
  }
  return value;
}

String _safeIdentity(String value, String field) {
  final normalized = value.trim();
  if (normalized != value ||
      !RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.:-]*$').hasMatch(normalized)) {
    throw ArgumentError.value(value, field, 'must be a safe opaque identity');
  }
  return normalized;
}

String _requiredString(Object? value, String field) {
  if (value is! String) throw FormatException('$field must be a string.');
  return value;
}

bool _requiredBool(Object? value, String field) {
  if (value is! bool) throw FormatException('$field must be a boolean.');
  return value;
}

DateTime _utcDate(Object? value, String field) {
  final raw = _requiredString(value, field);
  final parsed = DateTime.tryParse(raw);
  if (parsed == null || !parsed.isUtc || !raw.endsWith('Z')) {
    throw FormatException('$field must be a UTC timestamp.');
  }
  return parsed;
}
