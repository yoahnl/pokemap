import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';

import 'native_project_writer.dart';

const _batchActions = {
  'element.upsert': ('element.batch_upsert', 'elements', 'element', 512),
  'asset.import': ('asset.import_batch', 'entries', '', 200),
};

({List<NativeMutation> mutations, List<Map<String, Object?>> evidence})
    batchNativeMutations(List<NativeMutation> mutations,
        {required String actionId, required NativeWriteLimits limits}) {
  final contract = _batchActions[actionId]!;
  final result = <NativeMutation>[];
  final evidence = <Map<String, Object?>>[];
  var pending = <Map<String, Object?>>[];
  var originals = <NativeMutation>[];
  void flush() {
    if (originals.length == 1) {
      result.add(originals.single);
    } else if (originals.isNotEmpty) {
      final batch = _makeBatch(pending, actionId, limits)!;
      result.add(batch);
      evidence
          .add({'operationId': batch.operationId.value, 'components': pending});
    }
    originals = [];
    pending = [];
  }

  for (var index = 0; index < mutations.length; index++) {
    final mutation = mutations[index];
    if (mutation.actionId != actionId) {
      flush();
      result.add(mutation);
      continue;
    }
    if (actionId == 'element.upsert' && originals.isNotEmpty) {
      final previous = originals.last;
      final before = previous.parameters['element'] as Map;
      final next = mutation.parameters['element'] as Map;
      if (canonicalJsonOf(
                  previous.sourceEntityIds.map((id) => id.value).toList()) !=
              canonicalJsonOf(
                  mutation.sourceEntityIds.map((id) => id.value).toList()) ||
          before['categoryId'] != next['categoryId'] ||
          before['tilesetId'] != next['tilesetId']) {
        flush();
      }
    }
    final component = mutation.toJson(index);
    if (pending.length == contract.$4 ||
        _makeBatch([...pending, component], actionId, limits) == null) {
      flush();
    }
    if (_makeBatch([component], actionId, limits) == null) {
      throw const NativeWriteException('native.batch.quota',
          'A component cannot fit the bounded canonical batch envelope');
    }
    pending.add(component);
    originals.add(mutation);
  }
  flush();
  return (mutations: result, evidence: evidence);
}

NativeMutation? _makeBatch(List<Map<String, Object?>> components,
    String actionId, NativeWriteLimits limits) {
  final contract = _batchActions[actionId]!;
  final owners = <ConverterId>{};
  final targets = <ConverterId>{};
  final values = <Object?>[];
  final ids = <Object?>{};
  final operationIds = <Object?>{};
  final paths = <Object?>{};
  for (final component in components) {
    owners.addAll((component['sourceEntityIds'] as List)
        .cast<String>()
        .map(ConverterId.new));
    targets.addAll((component['targetEntityIds'] as List)
        .cast<String>()
        .map(ConverterId.new));
    final parameters = component['parameters'] as Map;
    final value = contract.$3.isEmpty ? parameters : parameters[contract.$3];
    final id =
        contract.$3.isEmpty ? parameters['assetId'] : (value as Map)['id'];
    if (!operationIds.add(component['operationId']) ||
        !ids.add(id) ||
        (contract.$3.isEmpty && !paths.add(parameters['logicalPath']))) {
      throw const NativeWriteException('native.batch.duplicate',
          'Batch components require unique identities and logical paths');
    }
    values.add(value);
  }
  if (owners.length > limits.maxMutations ||
      targets.length > limits.maxMutations ||
      (contract.$3.isEmpty && components.length * 2 + 1 > 500)) {
    return null;
  }
  try {
    final parameters = <String, Object?>{contract.$2: values};
    if (utf8
            .encode(canonicalJsonOf(parameters, limits: limits.jsonLimits))
            .length >
        1048576 - 4096) {
      return null;
    }
    final id = ConverterId(
        'native-batch-${canonicalHashOf(components, limits: limits.jsonLimits).value}');
    return NativeMutation(
        operationId: id,
        actionId: contract.$1,
        sourceEntityIds: owners.toList(),
        targetEntityIds: targets.toList(),
        parameters: parameters,
        limits: limits);
  } on ContractError {
    return null;
  }
}

int nativeLogicalMutationCount(Iterable<NativeMutation> mutations) {
  var total = 0;
  for (final mutation in mutations) {
    final contract = _batchActions.values
        .where((value) => value.$1 == mutation.actionId)
        .singleOrNull;
    if (contract == null) {
      total++;
      continue;
    }
    final entries = mutation.parameters[contract.$2];
    if (mutation.parameters.length != 1 ||
        entries is! List ||
        entries.isEmpty ||
        entries.length > contract.$4) {
      throw const NativeWriteException(
          'native.batch.shape', 'Invalid bounded batch entries');
    }
    total += entries.length;
  }
  return total;
}

Iterable<NativeMutation> expandNativeMutationBatches(
    NativeProjectDraft draft, NativeWriteLimits limits) sync* {
  final rows = <String, Map>{};
  for (final kind in ['sourceSemantics', 'sourceCatalogs']) {
    final marker = draft.compositionEvidence[kind];
    if (marker is! Map) continue;
    for (final row in marker['mutationBatches'] as List? ?? const []) {
      if (row is! Map ||
          row['operationId'] is! String ||
          rows.containsKey(row['operationId'])) {
        throw const NativeWriteException('native.batch.binding',
            'Batch provenance requires unique exact components');
      }
      rows[row['operationId'] as String] = row;
    }
  }
  for (final mutation in draft.mutations) {
    final contract = _batchActions.entries
        .where((entry) => entry.value.$1 == mutation.actionId)
        .singleOrNull;
    if (contract == null) {
      yield mutation;
      continue;
    }
    final row = rows.remove(mutation.operationId.value);
    if (row == null || row['components'] is! List) {
      throw const NativeWriteException(
          'native.batch.binding', 'Batch provenance is required');
    }
    final components = (row['components'] as List)
        .map((value) => Map<String, Object?>.from(value as Map))
        .toList();
    final expected = _makeBatch(components, contract.key, limits);
    if (expected == null ||
        canonicalJsonOf(expected.toJson(0), limits: limits.jsonLimits) !=
            canonicalJsonOf(mutation.toJson(0), limits: limits.jsonLimits)) {
      throw const NativeWriteException('native.batch.binding',
          'Batch differs from its ordered component provenance');
    }
    var ordinal = -1;
    for (final component in components) {
      if (component['actionId'] != contract.key ||
          component['actionVersion'] != 1 ||
          component['ordinal'] is! int ||
          (component['ordinal'] as int) <= ordinal) {
        throw const NativeWriteException(
            'native.batch.binding', 'Batch component order or action differs');
      }
      ordinal = component['ordinal'] as int;
      yield NativeMutation(
          operationId: ConverterId(component['operationId'] as String),
          actionId: contract.key,
          sourceEntityIds: (component['sourceEntityIds'] as List)
              .cast<String>()
              .map(ConverterId.new)
              .toList(),
          targetEntityIds: (component['targetEntityIds'] as List)
              .cast<String>()
              .map(ConverterId.new)
              .toList(),
          parameters: Map<String, Object?>.from(component['parameters'] as Map),
          limits: limits);
    }
  }
  if (rows.isNotEmpty) {
    throw const NativeWriteException(
        'native.batch.binding', 'Unused batch provenance is not admitted');
  }
}

Iterable<Map<String, Object?>> nativeImportParameters(
    NativeMutation mutation) sync* {
  if (mutation.actionId == 'asset.import_batch') {
    for (final entry in mutation.parameters['entries'] as List) {
      if (entry is! Map) {
        throw const NativeWriteException(
            'native.batch.shape', 'Asset imports require parameter objects');
      }
      yield Map<String, Object?>.from(entry);
    }
  } else if (mutation.actionId == 'asset.import' ||
      mutation.actionId == 'tileset.import_image') {
    yield mutation.parameters;
  }
}
