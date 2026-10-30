import '../contracts/map_edit_operation.dart';
import '../catalog_storage/catalog_history_transition.dart';
import '../catalog_storage/catalog_storage_store.dart';
import '../contracts/authoring_receipt.dart';
import '../contracts/resource_ref.dart';
import '../history/authoring_history.dart';
import '../ports/idempotency_store.dart';
import '../ports/project_file_reader.dart';
import '../support/authoring_fingerprint.dart';
import 'revision_set.dart';
import '../security/resource_pack_bulk_capability.dart';
import '../workspace/native_project_creation.dart';

enum AuthoringTransactionCheckpointProfile { perResource, phaseOnly }

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
    this.bulkCapability,
    this.nativeCreationCapability,
  })  : operationId = _safeIdentity(operationId, 'operationId'),
        planId = _safeIdentity(planId, 'planId'),
        createdAt = createdAt.toUtc(),
        updatedAt = updatedAt.toUtc(),
        entries = _sortedEntries(entries) {
    final bindingJson = intendedReceipt.extensions['mapEdit'];
    final binding = bindingJson is Map
        ? MapEditBinding.fromJson(Map<String, dynamic>.from(bindingJson))
        : null;
    if (binding != null &&
        (scope.actionId != 'map3d.edit_batch' ||
            scope.actionVersion != 1 ||
            binding.operationId != this.operationId ||
            binding.unchanged != this.entries.isEmpty ||
            (finalReceipt != null &&
                canonicalAuthoringJson(finalReceipt!.extensions['mapEdit']) !=
                    canonicalAuthoringJson(binding.toJson())))) {
      throw const FormatException('Invalid journal map edit binding.');
    }
    if (this.entries.isEmpty && binding == null) {
      throw ArgumentError.value(entries, 'entries', 'must not be empty');
    }
    _requireCatalogHistoryBinding();
    final nativeCapability = nativeCreationCapability;
    if (nativeCapability != null) {
      if (bulkCapability != null) {
        throw const FormatException(
            'A transaction cannot have two bulk capabilities.');
      }
      nativeCapability.requireBinding(
          actorId: scope.actorId,
          projectId: scope.projectId,
          planId: this.planId,
          operationId: this.operationId,
          actionId: scope.actionId,
          actionVersion: scope.actionVersion,
          diff: intendedReceipt.diff,
          entries: [
            for (final entry in this.entries)
              (
                storageKey: entry.storageKey,
                beforeRevision: entry.beforeRevision,
                afterRevision: entry.afterRevision
              )
          ]);
    }
    final capability = bulkCapability;
    if (capability != null) {
      capability.requireBinding(
          actorId: scope.actorId,
          projectId: scope.projectId,
          planId: this.planId,
          operationId: this.operationId,
          actionId: scope.actionId,
          actionVersion: scope.actionVersion,
          diff: intendedReceipt.diff,
          actualInventory: [
            for (final entry in this.entries)
              ResourcePackBulkInventoryEntry(
                  resource: entry.resource,
                  storageKey: entry.storageKey,
                  beforeRevision: entry.beforeRevision,
                  afterRevision: entry.afterRevision,
                  role: capability.roleFor(entry.storageKey))
          ]);
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
          resource: AuthoringResourceRef(
            kind: entry.resource.kind,
            id: entry.resource.id,
            extensions: entry.resource.extensions,
          ),
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

  void _requireCatalogHistoryBinding() {
    final record = intendedReceipt.extensions['catalogHistory'];
    final bulkHistory = bulkCapability?.catalogHistory;
    if (record == null && bulkHistory == null) return;
    if (record is! Map ||
        (bulkCapability != null &&
            canonicalAuthoringJson(record) !=
                canonicalAuthoringJson(bulkHistory?.toJson())) ||
        (finalReceipt != null &&
            canonicalAuthoringJson(record) !=
                canonicalAuthoringJson(
                    finalReceipt!.extensions['catalogHistory']))) {
      throw const FormatException(
          'catalog.history: journal conversion proofs differ');
    }
    final transition = CatalogHistoryTransitionAttestation.fromJournalJson(
        Map<String, dynamic>.from(record));
    final context =
        AuthoringHistoryContext.fromExtensions(intendedReceipt.extensions);
    final undo = context.kind == AuthoringHistoryKind.undo;
    final heads = entries.where(
        (entry) => entry.storageKey == CatalogStorageStore.headStorageKey);
    if (!const {AuthoringHistoryKind.undo, AuthoringHistoryKind.redo}
            .contains(context.kind) ||
        context.expectedHeadEntryId == null ||
        (bulkCapability != null &&
            context.targetEntryId != bulkCapability!.originEntryId) ||
        intendedReceipt.actionId != 'history.${context.kind.wireName}' ||
        scope.actionId != intendedReceipt.actionId ||
        heads.length != 1 ||
        heads.single.resource.kind != 'catalogHead' ||
        heads.single.resource.id != 'catalog' ||
        heads.single.beforeRevision !=
            (undo
                ? transition.effectiveAfterRevision
                : transition.effectiveBeforeRevision) ||
        heads.single.afterRevision !=
            (undo
                ? transition.effectiveBeforeRevision
                : transition.effectiveAfterRevision)) {
      throw const FormatException(
          'catalog.history: journal HEAD differs from its conversion proof');
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
      'checkpointProfile',
      'bulkCapability',
      'nativeCreationCapability',
    };
    if (json.keys.any((key) => !keys.contains(key)) ||
        json['schemaVersion'] != 2) {
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
      final capability = json['bulkCapability'] == null
          ? null
          : ResourcePackBulkCapability.fromJournalJson(
              Map<String, dynamic>.from(json['bulkCapability'] as Map));
      final nativeCapability = json['nativeCreationCapability'] == null
          ? null
          : NativeProjectCreationCapability.fromJournalJson(
              Map<String, dynamic>.from(
                  json['nativeCreationCapability'] as Map));
      final expectedProfile = capability == null && nativeCapability == null
          ? 'perResource'
          : 'phaseOnly';
      if (json['checkpointProfile'] != expectedProfile) {
        throw const FormatException('Invalid checkpoint profile.');
      }
      return AuthoringTransactionJournal(
        bulkCapability: capability,
        nativeCreationCapability: nativeCapability,
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
    } on TypeError {
      throw const FormatException('Invalid transaction journal objects.');
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
  final ResourcePackBulkCapability? bulkCapability;
  final NativeProjectCreationCapability? nativeCreationCapability;
  AuthoringTransactionCheckpointProfile get checkpointProfile =>
      bulkCapability == null && nativeCreationCapability == null
          ? AuthoringTransactionCheckpointProfile.perResource
          : AuthoringTransactionCheckpointProfile.phaseOnly;

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
      bulkCapability: bulkCapability,
      nativeCreationCapability: nativeCreationCapability,
      finalReceipt: identical(finalReceipt, _unchangedReceipt)
          ? this.finalReceipt
          : finalReceipt as AuthoringReceipt?,
    );
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': 2,
        'checkpointProfile': checkpointProfile.name,
        if (bulkCapability != null) 'bulkCapability': bulkCapability!.toJson(),
        if (nativeCreationCapability != null)
          'nativeCreationCapability': nativeCreationCapability!.toJson(),
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
