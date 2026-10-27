import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';

import '../support/authoring_fingerprint.dart';
import '../workspace/catalog/catalog_metadata_documents.dart';
import '../workspace/catalog/catalog_narrative_event_documents.dart';
import 'catalog_storage_store.dart';

final class CatalogHistoryRootConversion {
  CatalogHistoryRootConversion({
    required this.source,
    required this.target,
    required this.additionalBytes,
    this.normalizationVersion = 1,
  }) {
    if (source == target ||
        additionalBytes < 1 ||
        additionalBytes > 1073741824 ||
        normalizationVersion != 1) {
      throw const FormatException('catalog.history_conversion: invalid record');
    }
  }

  final CatalogObjectReference source;
  final CatalogObjectReference target;
  final int additionalBytes;
  final int normalizationVersion;

  Map<String, Object?> toJson() => {
        'source': source.toJson(),
        'target': target.toJson(),
        'additionalBytes': additionalBytes,
        'normalizationVersion': normalizationVersion,
      };

  factory CatalogHistoryRootConversion.fromJson(Map<String, Object?> json) {
    if (json.length != 4 ||
        json['source'] is! Map ||
        json['target'] is! Map ||
        json['additionalBytes'] is! int ||
        json['normalizationVersion'] is! int) {
      throw const FormatException('catalog.history_conversion: invalid record');
    }
    return CatalogHistoryRootConversion(
      source: CatalogObjectReference.fromJson(
        Map<String, Object?>.from(json['source']! as Map),
      ),
      target: CatalogObjectReference.fromJson(
        Map<String, Object?>.from(json['target']! as Map),
      ),
      additionalBytes: json['additionalBytes']! as int,
      normalizationVersion: json['normalizationVersion']! as int,
    );
  }
}

final class CatalogPreparedHistoryConversion {
  CatalogPreparedHistoryConversion._(
    this._owner,
    this.sourceSnapshot,
    this.targetSnapshot,
    this.conversion,
    this.objects,
  );

  final CatalogStorageStore _owner;
  final CatalogSnapshot sourceSnapshot;
  final CatalogSnapshot targetSnapshot;
  final CatalogHistoryRootConversion conversion;
  final Map<String, List<int>> objects;

  void requireOwner(CatalogStorageStore store) {
    if (!identical(store, _owner)) {
      throw const CatalogStorageException('catalog.history_conversion_owner',
          'The conversion belongs to a different catalog store.');
    }
  }

  Future<void> publishUnderLock(CatalogStorageStore store,
      {bool metadataContextRequired = false,
      bool publishMetadataContext = true}) async {
    requireOwner(store);
    await store.publishObjectsUnderLock(objects);
    await store.publishIndexAdmissionUnderLock(targetSnapshot);
    await store.publishMetadataIndexAdmissionUnderLock(targetSnapshot);
    if (publishMetadataContext) {
      await store.publishMetadataContextTransitionUnderLock(
          before: sourceSnapshot,
          after: targetSnapshot,
          changedKeys: const [],
          metadataContextRequired: metadataContextRequired);
    }
    await store.publishHistoryConversionUnderLock(this);
  }
}

abstract final class CatalogHistoryCompatibility {
  static Future<void> recover({
    required CatalogStorageStore store,
    required CatalogHistoryRootConversion conversion,
  }) async {
    try {
      await store.requireHistoryConversion(conversion);
      return;
    } on CatalogStorageException catch (error) {
      if (error.code != 'catalog.preparation_required') rethrow;
    }
    final source = (await store.openRoot(conversion.source)).snapshot;
    final metadata = <CatalogDefinitionUnit>[];
    await source.objectReferences(onUnit: (unit) {
      if (unit.key.kind == CatalogDefinitionKind.catalogMetadata ||
          unit.key.kind == CatalogDefinitionKind.workspaceState) {
        metadata.add(unit);
      }
    });
    final prepared =
        await prepare(store: store, source: source, metadataUnits: metadata);
    if (prepared == null ||
        canonicalAuthoringJson(prepared.conversion.toJson()) !=
            canonicalAuthoringJson(conversion.toJson())) {
      throw const FormatException(
          'catalog.history_conversion: recovery differs from canonical conversion');
    }
    await store.publishIndexAdmissionUnderLock(source);
    await prepared.publishUnderLock(store);
  }

  static Future<CatalogPreparedHistoryConversion?> prepare({
    required CatalogStorageStore store,
    required CatalogSnapshot source,
    required Iterable<CatalogDefinitionUnit> metadataUnits,
  }) async {
    if (source.admittedStoredBytes == null ||
        !identical(source.limits, store.limits)) {
      throw const CatalogStorageException('catalog.preparation_required',
          'Validate the historical generation before preparing its conversion.');
    }
    final units = await _authenticate(source, metadataUnits);
    final expected = CatalogMetadataDocuments.initialize(units.values);
    final actual = {
      for (final unit in units.values)
        if (unit.key.kind == CatalogDefinitionKind.workspaceState &&
            unit.key.id != 'workspace')
          unit.key: unit,
    };
    if (_matches(actual, expected)) return null;
    var supported = false;
    for (final legacyFacts in [false, true]) {
      for (final eventsVersion in [0, 1, 2]) {
        if (!legacyFacts && eventsVersion == 2) continue;
        final candidate = _legacyProjection(
            units.values, expected, legacyFacts, eventsVersion);
        if (_matches(actual, candidate)) supported = true;
      }
    }
    if (!supported) return null;
    final patch = await source.patch(upserts: expected);
    final target = await patch.nextSnapshot(
      readObject: (reference) async =>
          patch.objects[reference.sha256] ?? await store.readObject(reference),
    );
    final delta = await target.deltaFrom(source);
    if (delta.removals.isNotEmpty ||
        delta.upserts.any((unit) =>
            unit.key.kind != CatalogDefinitionKind.workspaceState ||
            unit.key.id == 'workspace')) {
      throw const FormatException(
          'catalog.history_conversion: changed source definitions');
    }
    final objects = <String, List<int>>{};
    var additionalBytes = 0;
    for (final reference in delta.addedObjects) {
      additionalBytes += reference.byteLength;
      final bytes = patch.objects[reference.sha256];
      if (bytes == null) {
        throw const FormatException(
            'catalog.history_conversion: missing prepared object');
      }
      objects[reference.sha256] = List<int>.unmodifiable(bytes);
    }
    return CatalogPreparedHistoryConversion._(
      store,
      source,
      target,
      CatalogHistoryRootConversion(
        source: source.root,
        target: target.root,
        additionalBytes: additionalBytes,
      ),
      Map.unmodifiable(objects),
    );
  }

  static Future<Map<CatalogDefinitionKey, CatalogDefinitionUnit>> _authenticate(
      CatalogSnapshot snapshot,
      Iterable<CatalogDefinitionUnit> metadataUnits) async {
    final supplied = <CatalogDefinitionKey, CatalogDefinitionUnit>{};
    for (final unit in metadataUnits) {
      if (!const {
            CatalogDefinitionKind.catalogMetadata,
            CatalogDefinitionKind.workspaceState,
          }.contains(unit.key.kind) ||
          supplied.containsKey(unit.key)) {
        throw const FormatException(
            'catalog.history_conversion: invalid metadata evidence');
      }
      supplied[unit.key] = unit;
    }
    var count = 0;
    for (final kind in [
      CatalogDefinitionKind.catalogMetadata,
      CatalogDefinitionKind.workspaceState,
    ]) {
      String? cursor;
      final cursors = <String>{};
      do {
        final page = await snapshot.page(
            kind: kind, limit: snapshot.limits.indexPageSize, cursor: cursor);
        for (final entry in page.items) {
          count++;
          final unit = supplied[entry.key];
          if (unit == null) {
            throw const FormatException(
                'catalog.history_conversion: incomplete metadata evidence');
          }
          final bytes = utf8.encode(canonicalAuthoringJson(unit.toJson()));
          if (bytes.length != entry.reference.byteLength ||
              crypto.sha256.convert(bytes).toString() !=
                  entry.reference.sha256) {
            throw const FormatException(
                'catalog.history_conversion: mismatched metadata evidence');
          }
        }
        cursor = page.nextCursor;
        if (cursor != null && !cursors.add(cursor)) {
          throw const FormatException(
              'catalog.history_conversion: repeated index cursor');
        }
      } while (cursor != null);
    }
    if (count != supplied.length) {
      throw const FormatException(
          'catalog.history_conversion: unrelated metadata evidence');
    }
    return supplied;
  }

  static bool _matches(Map<CatalogDefinitionKey, CatalogDefinitionUnit> actual,
      Iterable<CatalogDefinitionUnit> expected) {
    final byKey = {for (final unit in expected) unit.key: unit};
    return actual.length == byKey.length &&
        byKey.entries.every((entry) =>
            actual[entry.key] != null &&
            canonicalAuthoringJson(actual[entry.key]!.toJson()) ==
                canonicalAuthoringJson(entry.value.toJson()));
  }

  static List<CatalogDefinitionUnit> _legacyProjection(
      Iterable<CatalogDefinitionUnit> source,
      List<CatalogDefinitionUnit> expected,
      bool legacyFacts,
      int eventsVersion) {
    final result = <CatalogDefinitionUnit>[];
    for (final unit in expected) {
      final id = unit.key.id;
      if (legacyFacts && id.startsWith('["factRuntimeIdentity",')) continue;
      if (legacyFacts &&
          unit.key == CatalogMetadataDocuments.fieldKey('facts')) {
        final payload = {...unit.payload}
          ..remove('factRuntimeIdentitiesVersion');
        result.add(CatalogDefinitionUnit(
            key: unit.key, payload: payload, references: unit.references));
      } else if (eventsVersion != 2 &&
          (unit.key == CatalogNarrativeEventDocuments.indexKey ||
              id.startsWith('["narrativeEventDocument",') ||
              id.startsWith('["narrativeEventDocumentChunk",'))) {
        if (eventsVersion == 1 &&
            unit.key == CatalogNarrativeEventDocuments.indexKey) {
          result.add(CatalogDefinitionUnit(
              key: unit.key,
              payload: {...unit.payload, 'indexVersion': 1},
              references: unit.references));
        }
      } else {
        result.add(unit);
      }
    }
    if (eventsVersion == 1) {
      final shell = source
          .where((unit) =>
              unit.key.kind == CatalogDefinitionKind.catalogMetadata &&
              unit.key.id == 'publication-shell')
          .singleOrNull;
      final raw = PortableCatalogPublication.decodeProjectMetadataAggregate(
          field: 'eventRegistry',
          shellValue: (shell?.payload['value'] as Map?)?['eventRegistry'],
          units: source.where((unit) =>
              unit.key.kind == CatalogDefinitionKind.catalogMetadata &&
              (unit.key.id == '["projectAggregateHeader","eventRegistry"]' ||
                  unit.key.id.startsWith(
                      '["projectAggregateChunk","eventRegistry",'))));
      for (final record in raw?['records'] as List? ?? const []) {
        final id = NarrativeEventRecord.fromJson(record).id;
        final key = CatalogNarrativeEventDocuments.recordKey(id);
        result.add(CatalogDefinitionUnit(key: key, payload: {
          'id': key.id,
          'eventId': id,
          'record': record,
        }));
      }
    }
    return result;
  }
}
