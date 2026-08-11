import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../../application/authoring_api/authoring_mutation_adapter.dart';
import '../../../application/authoring_api/authoring_query_adapter.dart';

final class ItemStudioOption {
  const ItemStudioOption({required this.id, required this.label});

  final String id;
  final String label;
}

final class ItemStudioDiagnostic {
  const ItemStudioDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    required this.path,
  });

  final String code;
  final String severity;
  final String message;
  final String path;
}

final class ItemStudioUsage {
  const ItemStudioUsage({
    required this.kind,
    required this.sourceKind,
    required this.sourceId,
    required this.editablePath,
    required this.blocksDeletion,
  });

  final String kind;
  final String sourceKind;
  final String sourceId;
  final String editablePath;
  final bool blocksDeletion;
}

final class ItemStudioReadiness {
  const ItemStudioReadiness({required this.ready, required this.diagnostics});

  final bool ready;
  final List<ItemStudioDiagnostic> diagnostics;
}

final class ItemStudioCatalogSnapshot {
  ItemStudioCatalogSnapshot({
    required this.definitions,
    required this.readinessByItemId,
    required this.usagesByItemId,
    required this.snapshotRevision,
    this.heldEffectOptions = const <ItemStudioOption>[],
    this.moveOptions = const <ItemStudioOption>[],
  });

  final List<ProjectItemDefinition> definitions;
  final Map<String, ItemStudioReadiness> readinessByItemId;
  final Map<String, List<ItemStudioUsage>> usagesByItemId;
  final String snapshotRevision;
  final List<ItemStudioOption> heldEffectOptions;
  final List<ItemStudioOption> moveOptions;
}

final class ItemStudioMutationReceipt {
  const ItemStudioMutationReceipt({required this.receiptId});

  final String receiptId;
}

abstract interface class ItemStudioGateway {
  Future<ItemStudioCatalogSnapshot> load(String projectRootPath);

  Future<ItemStudioMutationReceipt> save(
    String projectRootPath, {
    required ProjectItemDefinition definition,
    required String snapshotRevision,
    String? originalItemId,
  });

  Future<Map<String, Object?>> simulate(
    String projectRootPath, {
    required String itemId,
    required ProjectItemUseContext context,
  });

  Future<void> undo(String projectRootPath, {required String receiptId});
}

final class CanonicalItemStudioGateway implements ItemStudioGateway {
  CanonicalItemStudioGateway({
    required AuthoringQueryAdapter queries,
    required AuthoringMutationAdapter mutations,
  }) : _queries = queries,
       _mutations = mutations;

  final AuthoringQueryAdapter _queries;
  final AuthoringMutationAdapter _mutations;
  int _identitySequence = 0;

  @override
  Future<ItemStudioCatalogSnapshot> load(String projectRootPath) async {
    final session = await _queries.open(projectRootPath);
    final definitionRecords = _queryAll(
      session,
      resourceKind: 'itemDefinition',
    );
    final readinessRecords = _queryAll(session, resourceKind: 'itemReadiness');
    final usageRecords = _queryAll(session, resourceKind: 'itemUsage');
    final definitions = <ProjectItemDefinition>[
      for (final record in definitionRecords) _definition(record),
    ]..sort((left, right) => left.displayName.compareTo(right.displayName));
    final readinessByItemId = <String, ItemStudioReadiness>{
      for (final record in readinessRecords)
        _string(record, 'id'): _readiness(record),
    };
    final usagesByItemId = <String, List<ItemStudioUsage>>{};
    for (final record in usageRecords) {
      final itemId = _string(record, 'itemId');
      usagesByItemId
          .putIfAbsent(itemId, () => <ItemStudioUsage>[])
          .add(_usage(record));
    }
    return ItemStudioCatalogSnapshot(
      definitions: List<ProjectItemDefinition>.unmodifiable(definitions),
      readinessByItemId: Map<String, ItemStudioReadiness>.unmodifiable(
        readinessByItemId,
      ),
      usagesByItemId: Map<String, List<ItemStudioUsage>>.unmodifiable({
        for (final entry in usagesByItemId.entries)
          entry.key: List<ItemStudioUsage>.unmodifiable(entry.value),
      }),
      snapshotRevision: session.snapshotRevision,
      heldEffectOptions: _options(
        definitions.map((definition) => definition.heldEffectId),
      ),
      moveOptions: _options(
        definitions.map((definition) => definition.machine?.moveId),
      ),
    );
  }

  @override
  Future<ItemStudioMutationReceipt> save(
    String projectRootPath, {
    required ProjectItemDefinition definition,
    required String snapshotRevision,
    String? originalItemId,
  }) async {
    final identity = _identity('item_save');
    final plan = await _mutations.plan(
      projectRootPath,
      actionId: originalItemId == null ? 'item.create' : 'item.update',
      parameters: <String, Object?>{
        'itemId': ?originalItemId,
        'definition': definition.normalized().toJson(),
      },
      idempotencyKey: identity,
      requestId: '${identity}_request',
      expectedRevision: snapshotRevision,
    );
    final result = await _mutations.apply(
      plan,
      operationId: '${identity}_apply',
    );
    return ItemStudioMutationReceipt(receiptId: result.receipt.receiptId);
  }

  @override
  Future<Map<String, Object?>> simulate(
    String projectRootPath, {
    required String itemId,
    required ProjectItemUseContext context,
  }) async {
    final session = await _queries.open(projectRootPath);
    final response = session.query(
      AuthoringQueryRequest(
        resourceKind: 'itemDefinition',
        operation: AuthoringQueryOperation.get,
        ids: <String>[itemId],
        view: AuthoringQueryView.detail,
        extensions: <String, Object?>{
          'actionId': 'item.simulate',
          'parameters': <String, Object?>{
            'itemId': itemId,
            'context': context.name,
          },
        },
      ),
    );
    final records = _records(response);
    if (records.isEmpty) return const <String, Object?>{};
    return _map(records.single['simulation']);
  }

  @override
  Future<void> undo(String projectRootPath, {required String receiptId}) async {
    await _mutations.undo(
      projectRootPath,
      entryId: receiptId,
      idempotencyKey: _identity('item_undo'),
    );
  }

  List<Map<String, Object?>> _queryAll(
    EditorAuthoringReadSession session, {
    required String resourceKind,
  }) {
    final records = <Map<String, Object?>>[];
    String? cursor;
    do {
      final response = session.query(
        AuthoringQueryRequest(
          resourceKind: resourceKind,
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
          pageSize: 200,
          cursor: cursor,
        ),
      );
      records.addAll(_records(response));
      cursor = response['nextCursor'] as String?;
    } while (cursor != null);
    return records;
  }

  String _identity(String prefix) {
    _identitySequence++;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_identitySequence';
  }
}

List<Map<String, Object?>> _records(Map<String, Object?> response) {
  final raw = response['items'];
  if (raw is! List) return const <Map<String, Object?>>[];
  return <Map<String, Object?>>[for (final value in raw) _map(value)];
}

ProjectItemDefinition _definition(Map<String, Object?> record) {
  return ProjectItemDefinition.fromJson(<String, dynamic>{
    'id': record['id'],
    'displayName': record['displayName'] ?? record['name'],
    'aliases': record['aliases'] ?? const <Object?>[],
    'pocketId': record['pocketId'],
    'description': record['description'],
    'buyPrice': record['buyPrice'],
    'sellPrice': record['sellPrice'],
    'tags': record['tags'] ?? const <Object?>[],
    'uses': record['uses'] ?? const <Object?>[],
    'capture': record['capture'],
    'machine': record['machine'],
    'heldEffectId': record['heldEffectId'],
  });
}

ItemStudioReadiness _readiness(Map<String, Object?> record) {
  final diagnostics = record['diagnostics'];
  return ItemStudioReadiness(
    ready: record['ready'] == true,
    diagnostics: <ItemStudioDiagnostic>[
      if (diagnostics is List)
        for (final diagnostic in diagnostics)
          ItemStudioDiagnostic(
            code: _string(_map(diagnostic), 'code'),
            severity: _string(_map(diagnostic), 'severity'),
            message: _string(_map(diagnostic), 'message'),
            path: _string(_map(diagnostic), 'path'),
          ),
    ],
  );
}

ItemStudioUsage _usage(Map<String, Object?> record) {
  return ItemStudioUsage(
    kind: _string(record, 'kind'),
    sourceKind: _string(record, 'sourceKind'),
    sourceId: _string(record, 'sourceId'),
    editablePath: _string(record, 'editablePath'),
    blocksDeletion: record['blocksDeletion'] == true,
  );
}

List<ItemStudioOption> _options(Iterable<String?> ids) {
  final unique = ids.whereType<String>().where((id) => id.isNotEmpty).toSet();
  return <ItemStudioOption>[
    for (final id in unique) ItemStudioOption(id: id, label: _label(id)),
  ]..sort((left, right) => left.label.compareTo(right.label));
}

String _label(String id) {
  return id
      .split(RegExp(r'[_\-.]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map) return const <String, Object?>{};
  return <String, Object?>{
    for (final entry in value.entries)
      if (entry.key is String) entry.key! as String: entry.value,
  };
}

String _string(Map<String, Object?> values, String key) {
  final value = values[key];
  return value is String ? value : '';
}
