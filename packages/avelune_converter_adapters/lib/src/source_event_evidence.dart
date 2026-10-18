import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;

import 'native_project_writer.dart';
import 'source_semantic_study_composer.dart';

final class SourceEventEvidenceArtifacts {
  SourceEventEvidenceArtifacts._(this.root, this.chunks);

  final NativeArtifact root;
  final List<NativeArtifact> chunks;
  List<NativeArtifact> get artifacts => [...chunks, root];

  static SourceEventEvidenceArtifacts pack(Map<String, Object?> evidence,
      {required NativeWriteLimits limits, ScanCancellation? cancellation}) {
    limits.validate();
    cancellation?.check();
    final bytes =
        utf8.encode(canonicalJsonOf(evidence, limits: limits.jsonLimits));
    final byteLimit =
        limits.maxArtifactBytes < 1048576 ? limits.maxArtifactBytes : 1048576;
    if (bytes.length <= byteLimit) {
      final artifact = NativeArtifact(
          bytes: bytes, mediaType: 'application/json', limits: limits);
      _checkBudget([artifact], limits);
      return SourceEventEvidenceArtifacts._(artifact, const []);
    }
    final overhead = canonicalJsonOf({
      'kind': 'sourceEventProjectionByteChunk',
      'version': 1,
      'offset': bytes.length,
      'bytesBase64': '',
    }, limits: limits.jsonLimits)
        .length;
    var maxCharacters = byteLimit < limits.jsonLimits.maxTextCodeUnits
        ? byteLimit
        : limits.jsonLimits.maxTextCodeUnits;
    maxCharacters -= overhead;
    if (maxCharacters > limits.jsonLimits.maxStringCodeUnits) {
      maxCharacters = limits.jsonLimits.maxStringCodeUnits;
    }
    final rawCapacity = (maxCharacters ~/ 4) * 3;
    final chunkSize = rawCapacity < SourceSemanticWitnessFiles.chunkSize
        ? rawCapacity
        : SourceSemanticWitnessFiles.chunkSize;
    if (chunkSize < 1) {
      throw const NativeWriteException('native.quota.artifact',
          'Event evidence chunk metadata exceeds the artifact budget');
    }
    final chunks = <NativeArtifact>[];
    final descriptors = <Map<String, Object?>>[];
    for (var offset = 0; offset < bytes.length; offset += chunkSize) {
      cancellation?.check();
      final end =
          offset + chunkSize < bytes.length ? offset + chunkSize : bytes.length;
      final artifact = NativeArtifact(
          bytes: utf8.encode(canonicalJsonOf({
            'kind': 'sourceEventProjectionByteChunk',
            'version': 1,
            'offset': offset,
            'bytesBase64': base64Encode(bytes.sublist(offset, end)),
          }, limits: limits.jsonLimits)),
          mediaType: 'application/json',
          limits: limits);
      final id =
          'ac13_events_chunk_${artifact.rawSha256.value.substring(0, 24)}';
      descriptors.add({
        'artifactHandle': artifact.handle,
        'offset': offset,
        'byteLength': end - offset,
        'assetId': id,
        'logicalPath': 'assets/converter/$id.json'
      });
      chunks.add(artifact);
      _checkBudget(chunks, limits);
    }
    final root = NativeArtifact(
        bytes: utf8.encode(canonicalJsonOf({
          'kind': 'sourceEventProjectionChunks',
          'version': 1,
          'encoding': 'canonicalJsonBase64Chunks',
          'sha256': crypto.sha256.convert(bytes).toString(),
          'byteLength': bytes.length,
          'chunks': descriptors,
        }, limits: limits.jsonLimits)),
        mediaType: 'application/json',
        limits: limits);
    _checkBudget([...chunks, root], limits);
    return SourceEventEvidenceArtifacts._(root, List.unmodifiable(chunks));
  }

  static void _checkBudget(
      List<NativeArtifact> artifacts, NativeWriteLimits limits) {
    if (artifacts.length > limits.maxArtifacts ||
        artifacts.fold<int>(0, (sum, a) => sum + a.bytes.length) >
            limits.maxTotalArtifactBytes) {
      throw const NativeWriteException('native.quota.artifact',
          'Event evidence artifacts exceed the resource budget');
    }
  }
}

final class SourceEventEvidenceEncoding {
  SourceEventEvidenceEncoding({required this.enabled, required this.limits});

  final bool enabled;
  final NativeWriteLimits limits;
  final _pageReferences = <String, int>{};
  final _tables = <String, Map<String, Object?>>{
    'nativeBindings': {},
    'mapAutonomyPages': {},
    'mapAutonomyPageLists': {},
    'witnesses': {},
  };
  static const _bindingKeys = [
    'sourceSnapshotHash',
    'normalizationHash',
    'sourceProfileHash',
    'baseDraftHash',
    'mapIds',
    'mapHashes'
  ];

  String _intern(String table, Object? value) {
    final text = canonicalJsonOf(value, limits: limits.jsonLimits);
    final hash = crypto.sha256.convert(utf8.encode(text)).toString();
    _tables[table]!.putIfAbsent(hash, () => jsonDecode(text));
    return hash;
  }

  int _internPage(Object? page) {
    final text = canonicalJsonOf(page, limits: limits.jsonLimits);
    final hash = crypto.sha256.convert(utf8.encode(text)).toString();
    return _pageReferences.putIfAbsent(hash, () {
      final reference = _pageReferences.length;
      _tables['mapAutonomyPages']!['$reference'] = {
        'sha256': hash,
        'page': jsonDecode(text),
      };
      return reference;
    });
  }

  Map<String, Object?>? encodeContext(Map<String, Object?>? original) {
    if (!enabled || original == null) return original;
    final context = Map<String, Object?>.from(original);
    final binding = <String, Object?>{
      for (final key in _bindingKeys)
        if (context.containsKey(key)) key: context.remove(key)
    };
    context['nativeBindingRef'] = _intern('nativeBindings', binding);
    context['expandedSha256'] =
        canonicalHashOf(original, limits: limits.jsonLimits).value;
    final rawProof = context['proof'];
    if (rawProof is Map) {
      final proof = Map<String, Object?>.from(rawProof);
      final rawAudit = proof['mapAutonomyAudit'];
      if (rawAudit is Map && rawAudit['pages'] is List) {
        final audit = Map<String, Object?>.from(rawAudit);
        audit['pageListRef'] = _intern('mapAutonomyPageLists', [
          for (final page in audit.remove('pages') as List)
            _internPage(page)
        ]);
        proof['mapAutonomyAudit'] = audit;
      }
      if (proof['witnesses'] is List) {
        proof['witnessRefs'] = [
          for (final witness in proof.remove('witnesses') as List)
            _intern('witnesses', witness)
        ];
      }
      context['proof'] = proof;
    }
    return context;
  }

  Map<String, Object?>? get tables =>
      !enabled || _tables['nativeBindings']!.isEmpty
          ? null
          : {
              'contract': 'source-event-execution-context-tables-v2',
              ..._tables
            };

  static List<Map<String, Object?>?> restoreContexts(
      List<Map<String, Object?>?> contexts, Map<String, Object?> tables,
      {required NativeWriteLimits limits}) {
    Never invalid() => throw const NativeWriteException(
        'events.evidence.binding',
        'Execution context evidence tables require exact hashes and references');
    if (tables['contract'] != 'source-event-execution-context-tables-v2' ||
        tables.length != 5) {
      invalid();
    }
    final used = <String, Set<String>>{};
    Object? resolve(String table, Object? ref) {
      final entries = tables[table];
      if (entries is! Map ||
          ref is! String ||
          !entries.containsKey(ref) ||
          canonicalHashOf(entries[ref], limits: limits.jsonLimits).value !=
              ref) {
        invalid();
      }
      used.putIfAbsent(table, () => {}).add(ref);
      return jsonDecode(
          canonicalJsonOf(entries[ref], limits: limits.jsonLimits));
    }

    Object? resolvePage(Object? reference) {
      final entries = tables['mapAutonomyPages'];
      if (entries is! Map ||
          reference is! int ||
          reference < 0 ||
          reference >= entries.length) {
        invalid();
      }
      final key = reference.toString();
      final entry = entries[key];
      if (entry is! Map ||
          entry.length != 2 ||
          !entry.containsKey('page') ||
          entry['sha256'] is! String ||
          canonicalHashOf(entry['page'], limits: limits.jsonLimits).value !=
              entry['sha256']) {
        invalid();
      }
      used.putIfAbsent('mapAutonomyPages', () => {}).add(key);
      return jsonDecode(
          canonicalJsonOf(entry['page'], limits: limits.jsonLimits));
    }

    final restored = <Map<String, Object?>?>[];
    for (final encoded in contexts) {
      if (encoded == null) {
        restored.add(null);
        continue;
      }
      final context = Map<String, Object?>.from(encoded);
      final hash = context.remove('expandedSha256');
      final binding =
          resolve('nativeBindings', context.remove('nativeBindingRef'));
      if (binding is! Map ||
          binding.keys.any((key) => !_bindingKeys.contains(key)) ||
          binding.keys.any(context.containsKey)) {
        invalid();
      }
      context.addAll(Map<String, Object?>.from(binding));
      final rawProof = context['proof'];
      if (rawProof is Map) {
        final proof = Map<String, Object?>.from(rawProof);
        final rawAudit = proof['mapAutonomyAudit'];
        if (rawAudit is Map && rawAudit.containsKey('pageListRef')) {
          final audit = Map<String, Object?>.from(rawAudit);
          final refs =
              resolve('mapAutonomyPageLists', audit.remove('pageListRef'));
          if (refs is! List || audit.containsKey('pages')) {
            invalid();
          }
          audit['pages'] = [
            for (final ref in refs) resolvePage(ref)
          ];
          proof['mapAutonomyAudit'] = audit;
        }
        if (proof.containsKey('witnessRefs')) {
          final refs = proof.remove('witnessRefs');
          if (refs is! List || proof.containsKey('witnesses')) {
            invalid();
          }
          proof['witnesses'] = [
            for (final ref in refs) resolve('witnesses', ref)
          ];
        }
        context['proof'] = proof;
      }
      if (canonicalHashOf(context, limits: limits.jsonLimits).value != hash) {
        invalid();
      }
      restored.add(context);
    }
    for (final table in [
      'nativeBindings',
      'mapAutonomyPages',
      'mapAutonomyPageLists',
      'witnesses'
    ]) {
      final entries = tables[table];
      if (entries is! Map || entries.length != (used[table]?.length ?? 0)) {
        invalid();
      }
    }
    return restored;
  }
}
