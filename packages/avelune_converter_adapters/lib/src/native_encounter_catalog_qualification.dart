import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'generated/native_kanto_encounter_catalog_data.dart';
import 'native_project_writer.dart';
import 'native_psdk_catalog.dart';
import 'native_source_species_bindings.dart';
import 'native_psdk_trainer_bundle.dart';

const _bundleSha256 =
    'a55fef16c2e7df621688826faacb19afafa9c59c45f3eb7fbd6b87d51c780e0f';
const _attestationSha256 =
    'cd22de47d67a65395ecdd282d5fc5b3b742ff7176ef28e1948c4b07b6b86b787';
const _bundleCanonicalHash =
    '97da84da5448e2b950f327a27800150bfd395cb01707a7af7fa92fee55c9a1bd';
const _qualificationLimits = ContractLimits(
    maxNodes: 2000000, maxStringCodeUnits: 1048576, maxTextCodeUnits: 33554432);

final class NativeEncounterCatalogQualification {
  NativeEncounterCatalogQualification._(this._bundleBytes,
      this._attestationBytes, this._attestation, this.wildCases,
      [this._catalogFiles]);

  factory NativeEncounterCatalogQualification.builtinKantoV1() =>
      NativeEncounterCatalogQualification.kantoV1(
          bundleBytes: utf8.encode(nativeKantoEncounterBundleJson),
          attestationBytes: utf8.encode(nativeKantoEncounterQualificationJson));

  factory NativeEncounterCatalogQualification.kantoV1({
    required List<int> bundleBytes,
    required List<int> attestationBytes,
  }) {
    if (bundleBytes.length > 4194304 ||
        attestationBytes.length > 2097152 ||
        crypto.sha256.convert(bundleBytes).toString() != _bundleSha256 ||
        crypto.sha256.convert(attestationBytes).toString() !=
            _attestationSha256) {
      _invalid('release_witness',
          'The closed Kanto release requires its exact portable bundle and runtime attestation.');
    }
    final bundle = NativePsdkTrainerBundle.fromJson(
        (jsonDecode(utf8.decode(bundleBytes)) as Map).cast<String, dynamic>());
    final attestation = (jsonDecode(utf8.decode(attestationBytes)) as Map)
        .cast<String, Object?>();
    if (canonicalHashOf(bundle.toJson(), limits: _qualificationLimits).value !=
            _bundleCanonicalHash ||
        attestation['kind'] != 'aveluneNativeKantoV1Qualification' ||
        attestation['version'] != 1 ||
        attestation['bundleSha256'] != _bundleSha256 ||
        attestation['canonicalBundleHash'] != _bundleCanonicalHash ||
        bundle.evidence['runtimeBattleBuilderQualified'] != false ||
        bundle.evidence['activationRequiresExactRuntimeMoveQualification'] !=
            true) {
      _invalid('release_binding', 'Native release identities differ.');
    }
    final cases = <String, Map<String, Object?>>{};
    for (final raw in attestation['cases'] as List) {
      final row = Map<String, Object?>.from(raw as Map);
      final requested = (row['requestedMoveIds'] as List).cast<String>();
      final returned = (row['returnedMoveIds'] as List).cast<String>();
      final diagnostics = (row['diagnostics'] as List).cast<Map>();
      final key = '${row['baseId']}|${row['form']}|${row['level']}';
      if (row['caseKey'] != key ||
          row['form'] != 0 ||
          row['nativeSpeciesId'] != row['baseId'] ||
          requested.isEmpty ||
          requested.length > 4 ||
          canonicalJsonOf(requested) != canonicalJsonOf(returned) ||
          row['filteredDiagnosticsCount'] != 0 ||
          diagnostics.length != requested.length ||
          diagnostics.indexed.any((entry) =>
              entry.$2['moveId'] != requested[entry.$1] ||
              entry.$2['psdkBridgeable'] != true)) {
        _invalid('runtime_tuple',
            'Every exact ordered move requires its runtime PSDK diagnostic.');
      }
      final species = bundle.speciesById[row['nativeSpeciesId']];
      final learnset = bundle.learnsetsBySpeciesId[row['nativeSpeciesId']];
      if (species == null ||
          learnset == null ||
          canonicalJsonOf(
                  nativeTrainerDefaultMoveIds(learnset, row['level'] as int)) !=
              canonicalJsonOf(requested)) {
        _invalid('runtime_defaults',
            'Runtime tuples must match published native learnsets.');
      }
      if (row['kind'] == 'wild' && cases.containsKey(key)) {
        _invalid('runtime_tuple_duplicate', 'Wild tuples must be unique.');
      }
      if (row['kind'] == 'wild') {
        row['sourceSymbol'] = (attestation['sourceMappings'] as List)
            .cast<Map>()
            .singleWhere((mapping) =>
                mapping['nativeBaseId'] == row['baseId'])['sourceSymbol'];
        cases[key] = _freeze(row) as Map<String, Object?>;
      }
    }
    if (cases.length != 367) {
      _invalid('runtime_scope',
          'The closed release requires all 367 wild level tuples.');
    }
    return NativeEncounterCatalogQualification._(
        List.unmodifiable(bundleBytes),
        List.unmodifiable(attestationBytes),
        _freeze(attestation) as Map<String, Object?>,
        Map.unmodifiable(cases));
  }

  static Future<NativeEncounterCatalogQualification> prepare({
    required SourceSnapshot snapshot,
    required SourcePbsProject source,
    required SourceFilePort files,
    required NativePsdkCatalog nativeCatalog,
    required Iterable<int> selectedSourceMapIds,
    ScanCancellation? cancellation,
  }) async {
    cancellation?.check();
    final maps = _selectedMaps(selectedSourceMapIds);
    if (source.sourceSnapshotHash != snapshot.canonicalHash ||
        source.logicalProjectNamespace != snapshot.logicalProjectNamespace ||
        source.profile != SourcePbsProfile.essentials21_1) {
      _invalid('source_binding',
          'Qualification requires its exact source snapshot, namespace and PBS profile.');
    }
    final sourceHash = source.canonicalHash.value;
    final encoded = _encodeCatalog(nativeCatalog);
    final slots = _selectedSlots(source, maps, cancellation);
    final symbols = slots.map((slot) => slot.species).toSet().toList()..sort();
    final binding = await const NativeSourceSpeciesBindings().bind(
        snapshot: snapshot,
        source: source,
        files: files,
        nativeCatalog: nativeCatalog,
        requestedSourceSymbols: symbols,
        cancellation: cancellation);
    cancellation?.check();
    if (!_sameFiles(encoded, _encodeCatalog(nativeCatalog))) {
      _invalid('qualification_integrity',
          'The native catalog changed during qualification.');
    }
    final requests = _requestsForSlots(slots, binding.mappings);
    final context = <String, Object?>{
      'kind': 'nativeEncounterGenericQualification',
      'version': 2,
      'sourceSnapshotHash': snapshot.canonicalHash.value,
      'sourcePbsHash': sourceHash,
      'logicalProjectNamespace': snapshot.logicalProjectNamespace.value,
      'sourceProfile': source.profile.name,
      'selectedSourceMapIds': maps,
      'nativeCatalogHash':
          canonicalHashOf(nativeCatalog.toJson(), limits: _qualificationLimits)
              .value,
      'sourceMappings': binding.rows,
      'speciesBindingEvidence': binding.evidence,
      'requests': requests,
    };
    return _generic(encoded, context, cancellation);
  }

  static Future<NativeEncounterCatalogQualification?> prepareAutomatic({
    required NormalizedSourceProject source,
    required SourceFilePort files,
    required Iterable<int> selectedSourceMapIds,
    SourcePbsProject? pbs,
    ScanCancellation? cancellation,
  }) async {
    cancellation?.check();
    if (source.interpretationProfile?.supports('encounters') != true ||
        source.interpretationProfile?.matchesArchive(SourceEventProfile.forProject(source).scriptsArchiveHash) != true) {
      return null;
    }
    final maps = _selectedMaps(selectedSourceMapIds);
    final catalogSource = pbs ??
        await const SourcePbsParser().read(
            snapshot: source.snapshot,
            files: files,
            profile: SourcePbsProfile.essentials21_1,
            cancellation: cancellation);
    if (!catalogSource.entries.any((entry) =>
        entry.family == SourcePbsFamily.encounters &&
        maps.contains(entry.identity?.sourceMapId))) {
      return null;
    }
    return prepare(
        snapshot: source.snapshot,
        source: catalogSource,
        files: files,
        nativeCatalog: NativePsdkCatalogManifest.builtin(),
        selectedSourceMapIds: maps,
        cancellation: cancellation);
  }

  bool admitsSourceScope(
      SourceSnapshot snapshot, Iterable<int> selectedSourceMapIds,
      {SourcePbsProject? source}) {
    if (!isGeneric) return true;
    if (!admitsAutomaticSource(snapshot) ||
        (source != null &&
            (source.canonicalHash.value != _attestation['sourcePbsHash'] ||
                source.sourceSnapshotHash != snapshot.canonicalHash ||
                source.profile.name != _attestation['sourceProfile'] ||
                source.logicalProjectNamespace !=
                    snapshot.logicalProjectNamespace))) {
      return false;
    }
    final selected = selectedSourceMapIds.toList();
    final scope =
        (_attestation['selectedSourceMapIds'] as List).cast<int>().toSet();
    if (source != null) {
      try {
        final required =
            _requestsForSlots(_selectedSlots(source, scope.toList(), null), {
          for (final row in sourceMappings) row['sourceSymbol'] as String: row,
        });
        if (canonicalJsonOf(required, limits: _qualificationLimits) !=
            canonicalJsonOf(_attestation['requests'],
                limits: _qualificationLimits)) {
          return false;
        }
      } on ContractError {
        return false;
      }
    }
    return selected.length <= 2048 &&
        selected.toSet().length == selected.length &&
        selected.every((id) => id > 0 && scope.contains(id));
  }

  static NativeEncounterCatalogQualification _generic(
      Map<String, List<int>> encoded, Map<String, Object?> context,
      [ScanCancellation? cancellation]) {
    final catalog = _restoreCatalog(encoded);
    _validateContext(context, catalog);
    final cases = <String, Map<String, Object?>>{};
    for (final request in (context['requests'] as List).cast<Map>()) {
      cancellation?.check();
      final row = request.cast<String, Object?>();
      final key = row['caseKey'] as String;
      if (cases.containsKey(key)) {
        _invalid('tuple_duplicate', 'Native tuples must be unique.');
      }
      cases[key] = _qualifyTuple(catalog, row);
    }
    return NativeEncounterCatalogQualification._(
        const [],
        const [],
        _freeze(context) as Map<String, Object?>,
        Map.unmodifiable(cases),
        Map.unmodifiable({
          for (final file in encoded.entries)
            file.key: List<int>.unmodifiable(file.value)
        }));
  }

  NativeEncounterReleaseArtifacts _genericArtifacts(NativeWriteLimits limits) {
    limits.validate();
    final artifacts = <NativeArtifact>[];
    final files = <Map<String, Object?>>[];
    var total = 0;
    final encoded = {
      ..._catalogFiles!,
      'context': utf8
          .encode(canonicalJsonOf(_attestation, limits: _qualificationLimits))
    };
    for (final file in encoded.entries) {
      final bytes = file.value;
      final hash = crypto.sha256.convert(bytes).toString();
      final handles = <String>[];
      for (var offset = 0; offset < bytes.length; offset += 131072) {
        final end = (offset + 131072).clamp(0, bytes.length);
        final artifact = NativeArtifact(
            bytes: utf8.encode(canonicalJsonOf({
              'kind': 'nativeEncounterGenericByteChunk',
              'version': 2,
              'file': file.key,
              'sha256': hash,
              'byteLength': bytes.length,
              'offset': offset,
              'bytesBase64': base64Encode(bytes.sublist(offset, end)),
            }, limits: limits.jsonLimits)),
            mediaType: 'application/json',
            limits: limits);
        total += artifact.bytes.length;
        if (total > limits.maxTotalArtifactBytes ||
            artifacts.length >= limits.maxArtifacts) {
          _invalid('release_quota',
              'The portable qualification exceeds the configured artifact budget.');
        }
        artifacts.add(artifact);
        handles.add(artifact.handle);
      }
      files.add({
        'file': file.key,
        'sha256': hash,
        'byteLength': bytes.length,
        'chunks': handles
      });
    }
    return NativeEncounterReleaseArtifacts(artifacts: artifacts, evidence: {
      'kind': 'nativeEncounterGenericRelease',
      'version': 2,
      'files': files,
    });
  }

  static NativeEncounterCatalogQualification _restoreGenericArtifacts(
      Map<String, Object?> evidence,
      Iterable<NativeArtifact> artifacts,
      NativeWriteLimits limits) {
    try {
      limits.validate();
      if (evidence.length != 3 || evidence['version'] != 2) {
        _invalid('release_artifacts', 'Invalid generic release envelope.');
      }
      final supplied = <String, NativeArtifact>{};
      var total = 0;
      for (final artifact in artifacts) {
        total += artifact.bytes.length;
        if (supplied.length >= limits.maxArtifacts ||
            total > limits.maxTotalArtifactBytes ||
            supplied.containsKey(artifact.handle) ||
            artifact.bytes.length > limits.maxArtifactBytes) {
          _invalid('release_artifacts',
              'Duplicate, excessive or invalid portable artifacts.');
        }
        supplied[artifact.handle] = artifact;
      }
      final descriptors = evidence['files'];
      if (descriptors is! List ||
          descriptors.length < 2 ||
          descriptors.length > 130) {
        _invalid('release_artifacts',
            'Bounded portable file descriptors are required.');
      }
      final encoded = <String, List<int>>{};
      final used = <String>{};
      for (final raw in descriptors) {
        if (raw is! Map ||
            raw.length != 4 ||
            raw['file'] is! String ||
            raw['sha256'] is! String ||
            !RegExp(r'^[a-f0-9]{64}$').hasMatch(raw['sha256'] as String) ||
            raw['byteLength'] is! int ||
            (raw['byteLength'] as int) < 1 ||
            (raw['byteLength'] as int) > limits.maxTotalArtifactBytes ||
            raw['chunks'] is! List ||
            (raw['chunks'] as List).isEmpty ||
            (raw['chunks'] as List).length > 512) {
          _invalid('release_artifacts',
              'Invalid portable file identity or chunk budget.');
        }
        final file = raw['file'] as String;
        if (encoded.containsKey(file)) {
          _invalid('release_artifacts', 'Duplicate portable file identity.');
        }
        final bytes = <int>[];
        for (final handle in raw['chunks'] as List) {
          if (handle is! String || !used.add(handle)) {
            _invalid('release_artifacts', 'Duplicate portable chunk.');
          }
          final artifact = supplied[handle];
          if (artifact == null ||
              artifact.reference.mediaType != 'application/json') {
            _invalid('release_artifacts', 'A portable JSON chunk is missing.');
          }
          final chunk = jsonDecode(utf8.decode(artifact.bytes));
          if (chunk is! Map ||
              chunk.length != 7 ||
              chunk['kind'] != 'nativeEncounterGenericByteChunk' ||
              chunk['version'] != 2 ||
              chunk['file'] != file ||
              chunk['sha256'] != raw['sha256'] ||
              chunk['byteLength'] != raw['byteLength'] ||
              chunk['offset'] != bytes.length ||
              chunk['bytesBase64'] is! String) {
            _invalid('release_artifacts',
                'Portable chunks require exact ordered offsets and file identities.');
          }
          final decoded = base64Decode(chunk['bytesBase64'] as String);
          if (decoded.isEmpty ||
              decoded.length > 131072 ||
              bytes.length + decoded.length > (raw['byteLength'] as int) ||
              (bytes.length + decoded.length < (raw['byteLength'] as int) &&
                  decoded.length != 131072)) {
            _invalid('release_artifacts',
                'Portable chunks exceed their raw byte budget.');
          }
          bytes.addAll(decoded);
        }
        if (bytes.length != raw['byteLength'] ||
            crypto.sha256.convert(bytes).toString() != raw['sha256']) {
          _invalid(
              'release_artifacts', 'Portable file hash or length differs.');
        }
        encoded[file] = bytes;
      }
      if (supplied.values.any((artifact) {
            if (used.contains(artifact.handle) ||
                artifact.reference.mediaType != 'application/json') {
              return false;
            }
            final json = jsonDecode(utf8.decode(artifact.bytes));
            return json is Map &&
                json['kind'] == 'nativeEncounterGenericByteChunk';
          }) ||
          !encoded.containsKey('context')) {
        _invalid('release_artifacts',
            'Unexpected portable chunks or absent context.');
      }
      final context =
          (jsonDecode(utf8.decode(encoded.remove('context')!)) as Map)
              .cast<String, Object?>();
      return _generic(encoded, context);
    } on ContractError {
      rethrow;
    } catch (_) {
      _invalid('release_artifacts', 'Malformed portable qualification.');
    }
  }

  final List<int> _bundleBytes;
  final List<int> _attestationBytes;
  final Map<String, Object?> _attestation;
  final Map<String, Map<String, Object?>> wildCases;

  final Map<String, List<int>>? _catalogFiles;

  bool get isGeneric => _catalogFiles != null;

  late final Sha256Hash evidenceHash =
      canonicalHashOf(evidence, limits: _qualificationLimits);

  NativePsdkCatalog get bundle => isGeneric
      ? _restoreCatalog(_catalogFiles!)
      : NativePsdkTrainerBundle.fromJson(
          (jsonDecode(utf8.decode(_bundleBytes)) as Map)
              .cast<String, dynamic>());

  List<Map<String, Object?>> get sourceMappings =>
      (_attestation['sourceMappings'] as List).cast<Map<String, Object?>>();

  bool admitsAutomaticSource(SourceSnapshot snapshot) => isGeneric
      ? snapshot.canonicalHash.value == _attestation['sourceSnapshotHash'] &&
          snapshot.logicalProjectNamespace.value ==
              _attestation['logicalProjectNamespace']
      : ['sourceEncounterPBS', 'compiledSpecies', 'sourceScriptArchive']
          .every((name) {
          final reference = _attestation[name];
          if (reference is! Map) return false;
          final entry = snapshot.entries
              .where((entry) => entry.relativePath == reference['relativePath'])
              .singleOrNull;
          return entry?.kind == SourceNodeKind.file &&
              entry?.sha256?.value == reference['sha256'] &&
              entry?.byteLength == reference['byteLength'];
        });

  NativeEncounterReleaseArtifacts artifacts(
      {NativeWriteLimits limits = const NativeWriteLimits()}) {
    if (isGeneric) return _genericArtifacts(limits);
    final artifacts = <NativeArtifact>[];
    List<String> chunks(String file, List<int> bytes) {
      final handles = <String>[];
      for (var offset = 0; offset < bytes.length; offset += 131072) {
        final end = (offset + 131072).clamp(0, bytes.length);
        final artifact = NativeArtifact(
            bytes: utf8.encode(canonicalJsonOf({
              'kind': 'nativeEncounterReleaseByteChunk',
              'version': 1,
              'file': file,
              'offset': offset,
              'bytesBase64': base64Encode(bytes.sublist(offset, end)),
            }, limits: limits.jsonLimits)),
            mediaType: 'application/json',
            limits: limits);
        artifacts.add(artifact);
        handles.add(artifact.handle);
      }
      return handles;
    }

    return NativeEncounterReleaseArtifacts(artifacts: artifacts, evidence: {
      'kind': 'nativeEncounterKantoV1Release',
      'version': 1,
      'bundleSha256': _bundleSha256,
      'attestationSha256': _attestationSha256,
      'bundleChunks': chunks('bundle', _bundleBytes),
      'attestationChunks': chunks('attestation', _attestationBytes),
    });
  }

  factory NativeEncounterCatalogQualification.fromArtifacts({
    required Map<String, Object?> evidence,
    required Iterable<NativeArtifact> artifacts,
    NativeWriteLimits limits = const NativeWriteLimits(),
  }) {
    if (evidence['kind'] == 'nativeEncounterGenericRelease') {
      return _restoreGenericArtifacts(evidence, artifacts, limits);
    }
    if (evidence['kind'] != 'nativeEncounterKantoV1Release' ||
        evidence['version'] != 1 ||
        evidence['bundleSha256'] != _bundleSha256 ||
        evidence['attestationSha256'] != _attestationSha256 ||
        evidence.length != 6) {
      _invalid('release_artifacts', 'The native release envelope differs.');
    }
    final supplied = {
      for (final artifact in artifacts) artifact.handle: artifact
    };
    List<int> restore(String file) {
      final references = evidence['${file}Chunks'];
      if (references is! List || references.isEmpty || references.length > 48) {
        _invalid('release_artifacts',
            'A release requires bounded ordered byte chunks.');
      }
      final bytes = <int>[];
      for (final reference in references) {
        final artifact = supplied[reference];
        if (artifact == null ||
            artifact.reference.mediaType != 'application/json') {
          _invalid(
              'release_artifacts', 'A native release byte chunk is missing.');
        }
        final chunk = jsonDecode(utf8.decode(artifact.bytes));
        if (chunk is! Map ||
            chunk.length != 5 ||
            chunk['kind'] != 'nativeEncounterReleaseByteChunk' ||
            chunk['version'] != 1 ||
            chunk['file'] != file ||
            chunk['offset'] != bytes.length ||
            chunk['bytesBase64'] is! String) {
          _invalid('release_artifacts',
              'Release byte chunks differ from their exact envelope.');
        }
        final decoded = base64Decode(chunk['bytesBase64'] as String);
        if (decoded.isEmpty ||
            decoded.length > 131072 ||
            bytes.length + decoded.length > 4194304) {
          _invalid('release_artifacts',
              'Native release byte chunks exceed their budget.');
        }
        bytes.addAll(decoded);
      }
      return bytes;
    }

    return NativeEncounterCatalogQualification.kantoV1(
        bundleBytes: restore('bundle'),
        attestationBytes: restore('attestation'));
  }

  Map<String, Object?> get evidence => isGeneric
      ? _freeze({
          ..._attestation,
          'qualifiedWildLevelTupleCount': wildCases.length,
          'pureNativeWildGeneratorQualified': true,
          'canonicalPsdkMoveProjectorQualified': true,
          'runtimeBattleBuilderQualified': false,
          'completeBattleSetupQualified': false,
          'studioPlayerQualified': false,
          'allMoveEffectFidelityQualified': false,
          'progressionMovesQualified': false,
        }) as Map<String, Object?>
      : {
          'kind': 'nativeEncounterKantoV1Qualification',
          'version': 1,
          'nativeBundleHash': _bundleCanonicalHash,
          'bundleSha256': _bundleSha256,
          'attestationSha256': _attestationSha256,
          'qualifiedWildLevelTupleCount': wildCases.length,
          'runtimeBattleBuilderQualified': false,
          'completeBattleSetupQualified': false,
          'progressionMovesQualified': false,
        };
}

final class NativeEncounterReleaseArtifacts {
  NativeEncounterReleaseArtifacts(
      {required List<NativeArtifact> artifacts,
      required Map<String, Object?> evidence})
      : artifacts = List.unmodifiable(artifacts),
        evidence = _freeze(evidence) as Map<String, Object?>;
  final List<NativeArtifact> artifacts;
  final Map<String, Object?> evidence;
}

Never _invalid(String code, String message) =>
    throw ContractError('native_encounter.$code', r'$', message);

Object? _freeze(Object? value) => switch (value) {
      Map v => Map<String, Object?>.unmodifiable(
          v.map((key, value) => MapEntry(key as String, _freeze(value)))),
      List v => List<Object?>.unmodifiable(v.map(_freeze)),
      _ => value,
    };

List<int> _selectedMaps(Iterable<int> selected) {
  final maps = <int>{};
  for (final id in selected) {
    if (id < 1 || maps.length >= 2048 || !maps.add(id)) {
      _invalid('source_scope',
          'Selected source map IDs must be unique positive IDs bounded to 2048.');
    }
  }
  return maps.toList()..sort();
}

List<SourcePbsEncounterSlot> _selectedSlots(
    SourcePbsProject source, List<int> maps, ScanCancellation? cancellation) {
  final selected = maps.toSet();
  final seen = <int>{};
  final slots = <SourcePbsEncounterSlot>[];
  for (final entry in source.entries.where((entry) =>
      entry.family == SourcePbsFamily.encounters &&
      selected.contains(entry.identity?.sourceMapId))) {
    cancellation?.check();
    final identity = entry.identity!;
    if (entry.isBlocked ||
        source.lookup(identity) == null ||
        identity.version != 0 ||
        !seen.add(identity.sourceMapId!)) {
      _invalid('table_identity',
          'Selected encounters require unique nonblocked version-zero identities.');
    }
    final methods = <String>{};
    for (final method in entry.methods) {
      if (!methods.add(method.name)) {
        _invalid('table_identity', 'Encounter methods must be unique.');
      }
      for (final slot in method.slots) {
        cancellation?.check();
        if (slot.weight <= 0 ||
            slot.minimumLevel < 1 ||
            slot.maximumLevel > 100 ||
            slot.minimumLevel > slot.maximumLevel) {
          _invalid('slot_bounds',
              'Every selected slot requires positive weight and inclusive levels 1 through 100.');
        }
        slots.add(slot);
        if (slots.length > 32768) {
          _invalid('slot_quota', 'Selected source slots exceed 32768.');
        }
      }
    }
  }
  return slots;
}

Map<String, List<int>> _encodeCatalog(NativePsdkCatalog catalog) {
  try {
    final json = catalog.toJson();
    final files = <String, List<int>>{
      'catalog': utf8.encode(
          canonicalJsonOf(json, limits: nativePsdkCatalogShardJsonLimits)),
    };
    if (catalog is NativePsdkCatalogManifest) {
      for (final shard in catalog.shards.entries) {
        files['shard:${shard.key}'] = utf8.encode(canonicalJsonOf(
            shard.value.toJson(),
            limits: nativePsdkCatalogShardJsonLimits));
      }
    } else if (catalog is! NativePsdkTrainerBundle) {
      _invalid('catalog_shape',
          'Qualification requires a native bundle or hash-addressed manifest.');
    }
    final restored = _restoreCatalog(files);
    if (_publishedHash(catalog) != _publishedHash(restored)) {
      _invalid('catalog_integrity',
          'Published native catalog models differ from their exact serialized contents.');
    }
    return files;
  } on ContractError catch (error) {
    _invalid(
        'catalog_integrity', 'Native catalog integrity failed: ${error.code}.');
  }
}

bool _sameFiles(Map<String, List<int>> a, Map<String, List<int>> b) =>
    a.length == b.length &&
    a.entries.every((entry) {
      final other = b[entry.key];
      return other != null &&
          crypto.sha256.convert(entry.value) == crypto.sha256.convert(other);
    });

NativePsdkCatalog _restoreCatalog(Map<String, List<int>> files) {
  final bytes = files['catalog'];
  if (bytes == null) {
    _invalid('catalog_shape', 'The exact portable native catalog is missing.');
  }
  final json = (jsonDecode(utf8.decode(bytes)) as Map).cast<String, dynamic>();
  if (json['kind'] == 'nativePsdkTrainerBundle' && files.length == 1) {
    return NativePsdkTrainerBundle.fromJson(json);
  }
  if (json['kind'] == 'nativePsdkCatalogManifest' &&
      files.keys.every((key) =>
          key == 'catalog' || RegExp(r'^shard:[a-f0-9]{64}$').hasMatch(key))) {
    return NativePsdkCatalogManifest.fromJson(json, shards: {
      for (final entry
          in files.entries.where((entry) => entry.key != 'catalog'))
        entry.key.substring(6): (jsonDecode(utf8.decode(entry.value)) as Map)
            .cast<String, Object?>(),
    });
  }
  _invalid('catalog_shape',
      'Portable native catalog shape or shard identities differ.');
}

void _validateContext(Map<String, Object?> context, NativePsdkCatalog catalog) {
  const keys = {
    'kind',
    'version',
    'sourceSnapshotHash',
    'sourcePbsHash',
    'logicalProjectNamespace',
    'sourceProfile',
    'selectedSourceMapIds',
    'nativeCatalogHash',
    'sourceMappings',
    'speciesBindingEvidence',
    'requests'
  };
  if (context.length != keys.length ||
      !context.keys.every(keys.contains) ||
      context['kind'] != 'nativeEncounterGenericQualification' ||
      context['version'] != 2 ||
      context['sourceProfile'] != SourcePbsProfile.essentials21_1.name ||
      context['logicalProjectNamespace'] is! String ||
      (context['logicalProjectNamespace'] as String).isEmpty ||
      (context['logicalProjectNamespace'] as String).length > 192 ||
      ['sourceSnapshotHash', 'sourcePbsHash', 'nativeCatalogHash'].any((key) =>
          context[key] is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(context[key] as String)) ||
      context['nativeCatalogHash'] !=
          canonicalHashOf(catalog.toJson(), limits: _qualificationLimits)
              .value ||
      context['selectedSourceMapIds'] is! List ||
      context['sourceMappings'] is! List ||
      (context['sourceMappings'] as List).length > 2048 ||
      context['requests'] is! List ||
      (context['requests'] as List).length > 8192 ||
      context['speciesBindingEvidence'] is! Map) {
    _invalid('qualification_context',
        'The bounded exact qualification context is invalid.');
  }
  final maps = (context['selectedSourceMapIds'] as List).cast<int>();
  if (canonicalJsonOf(_selectedMaps(maps)) != canonicalJsonOf(maps)) {
    _invalid('source_scope', 'Selected map scope requires canonical ordering.');
  }
  final mappings = <String, Map>{};
  for (final raw in context['sourceMappings'] as List) {
    if (raw is! Map ||
        !_boundedIdentity(raw['sourceSymbol'], 192) ||
        !_boundedIdentity(raw['sourceBaseSymbol'], 192) ||
        raw['sourceForm'] is! int ||
        (raw['sourceForm'] as int) < 0 ||
        (raw['sourceForm'] as int) > 2048 ||
        !_boundedIdentity(raw['nativeBaseId'], 256) ||
        raw['nativeForm'] is! int ||
        (raw['nativeForm'] as int) < 0 ||
        (raw['nativeForm'] as int) > 2048 ||
        raw['nativeSpeciesId'] !=
            nativePsdkFormSpeciesId(
                raw['nativeBaseId'] as String, raw['nativeForm'] as int) ||
        !catalog.speciesById.containsKey(raw['nativeSpeciesId']) ||
        mappings.containsKey(raw['sourceSymbol'])) {
      _invalid('species_identity',
          'Portable source mappings require unique exact native identities.');
    }
    mappings[raw['sourceSymbol'] as String] = raw;
  }
  final used = <String>{};
  String? previous;
  for (final raw in context['requests'] as List) {
    if (raw is! Map ||
        raw.length != 6 ||
        raw['nativeBaseId'] is! String ||
        raw['nativeForm'] is! int ||
        raw['level'] is! int ||
        (raw['level'] as int) < 1 ||
        (raw['level'] as int) > 100 ||
        raw['caseKey'] !=
            '${raw['nativeBaseId']}|${raw['nativeForm']}|${raw['level']}' ||
        raw['nativeSpeciesId'] !=
            nativePsdkFormSpeciesId(
                raw['nativeBaseId'] as String, raw['nativeForm'] as int) ||
        raw['sourceSymbols'] is! List ||
        (raw['sourceSymbols'] as List).isEmpty ||
        (raw['sourceSymbols'] as List).length > 2048 ||
        (raw['sourceSymbols'] as List).toSet().length !=
            (raw['sourceSymbols'] as List).length) {
      _invalid('qualification_context',
          'Portable tuple requests require exact bounded identities and source witnesses.');
    }
    final key = raw['caseKey'] as String;
    if (previous != null && previous.compareTo(key) >= 0) {
      _invalid(
          'tuple_duplicate', 'Tuple requests require unique canonical order.');
    }
    previous = key;
    for (final symbol in raw['sourceSymbols'] as List) {
      final mapping = mappings[symbol];
      if (mapping == null ||
          mapping['nativeSpeciesId'] != raw['nativeSpeciesId'] ||
          mapping['nativeBaseId'] != raw['nativeBaseId'] ||
          mapping['nativeForm'] != raw['nativeForm']) {
        _invalid('species_identity',
            'Every tuple requires its exact source mapping witness.');
      }
      used.add(symbol as String);
    }
  }
  if (used.length != mappings.length) {
    _invalid('qualification_context',
        'Portable source mappings require selected tuple witnesses.');
  }
}

Map<String, Object?> _qualifyTuple(
    NativePsdkCatalog catalog, Map<String, Object?> request) {
  final id = request['nativeSpeciesId'] as String;
  final level = request['level'] as int;
  final species = catalog.speciesById[id];
  final learnset = catalog.learnsetsBySpeciesId[id];
  if (species == null ||
      learnset == null ||
      species.forms.formId != '${request['nativeForm']}' ||
      species.forms.baseFormId != request['nativeBaseId']) {
    _invalid('native_tuple',
        'Every tuple requires its exact native species, form and learnset.');
  }
  final requested = nativeTrainerDefaultMoveIds(learnset, level);
  if (requested.isEmpty || requested.length > 4) {
    _invalid('native_defaults',
        'Native defaults require one through four exact moves.');
  }
  final diagnostics = <Map<String, Object?>>[];
  final pp = <String, int>{};
  for (final moveId in requested) {
    final move = catalog.movesById[moveId];
    if (move == null || move.id != moveId || move.pp <= 0) {
      _invalid('native_move_missing',
          'Every native default move requires its exact catalog move and positive PP.');
    }
    try {
      final projected = const CanonicalPsdkMoveProjector().project(move: move);
      if (projected.id != moveId || projected.pp != move.pp) {
        _invalid(
            'native_move_projection', 'Canonical move identity or PP differs.');
      }
      diagnostics.add({
        'moveId': moveId,
        'psdkBridgeable': true,
        'battleEngineMethod': projected.battleEngineMethod,
        'psdkRegistryStatus': const CanonicalPsdkMoveProjector()
            .registryStatusFor(projected.battleEngineMethod),
        'engineSupportLevel': move.engineSupportLevel.name,
        'unsupportedReasons': move.unsupportedReasons,
        'rawMoveHash':
            canonicalHashOf(move.toJson(), limits: _qualificationLimits).value
      });
      pp[moveId] = projected.pp;
    } on CanonicalPsdkMoveProjectionException catch (error) {
      _invalid('native_move_projection',
          'Canonical projection rejected $moveId: ${error.reason}.');
    } on ArgumentError catch (error) {
      _invalid('native_move_projection',
          'Canonical projection rejected $moveId: $error.');
    }
  }
  final primary = species.abilities.primary;
  final standard = {
    primary,
    if (species.abilities.secondary case final ability?) ability
  }.toList();
  final allowed = {
    ...standard,
    if (species.abilities.hidden case final ability?) ability
  }.toList();
  final stats = species.baseStats;
  PlayerPokemon generate(int seed) => const WildPlayerPokemonGenerator()
      .generate(
          seed: seed,
          species: WildPokemonGenerationSpecies(
              id: id,
              formId: species.forms.formId,
              baseStats: PokemonBaseStats(
                  hp: stats.hp,
                  attack: stats.atk,
                  defense: stats.def,
                  specialAttack: stats.spa,
                  specialDefense: stats.spd,
                  speed: stats.spe),
              primaryAbilityId: primary,
              standardAbilityIds: standard,
              allowedAbilityIds: allowed,
              genderRatio: species.breeding.genderRatio,
              growthRateId: species.progression.growthRateId,
              baseFriendship: species.progression.baseFriendship),
          learnset: WildPokemonGenerationLearnset(
              startingMoves: learnset.startingMoves,
              relearnMoves: learnset.relearnMoves,
              levelUp: [
                for (final row in learnset.levelUp)
                  WildPokemonLevelUpMove(moveId: row.moveId, level: row.level)
              ]),
          maxPpByMoveId: pp,
          level: level,
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          context: WildPokemonGenerationContext(
              mapId: 'native-qualification',
              sourceId: request['caseKey'] as String,
              individualKey: 'native-wild'),
          overrides: ProjectEncounterPokemonOverrides(abilityId: primary))
      .pokemon;
  final generations = <Map<String, Object?>>[];
  for (final seed in [17, 83]) {
    try {
      final pokemon = generate(seed);
      final json = pokemon.toJson();
      if (pokemon.speciesId != id ||
          pokemon.formId != species.forms.formId ||
          pokemon.level != level ||
          pokemon.abilityId != primary ||
          pokemon.currentHp <= 0 ||
          canonicalJsonOf(pokemon.knownMoveIds) != canonicalJsonOf(requested) ||
          pokemon.currentPpByMoveId?.length != requested.length ||
          requested
              .any((move) => pokemon.currentPpByMoveId?[move] != pp[move]) ||
          canonicalJsonOf(json) != canonicalJsonOf(generate(seed).toJson())) {
        _invalid('native_generation',
            'Native wild generation lost identity, ordered defaults, PP, HP or determinism.');
      }
      generations.add(
          {'seed': seed, 'pokemon': json, 'deterministicRepeatMatched': true});
    } on FormatException catch (error) {
      _invalid('native_generation',
          'Native wild generation rejected $id at $level: ${error.message}.');
    } on RangeError catch (error) {
      _invalid('native_generation',
          'Native wild generation rejected $id at $level: $error.');
    }
  }
  return _freeze({
    ...request,
    'baseId': request['nativeBaseId'],
    'form': request['nativeForm'],
    'kind': 'wild',
    'requestedMoveIds': requested,
    'returnedMoveIds': requested,
    'filteredDiagnosticsCount': 0,
    'diagnostics': diagnostics,
    'generations': generations,
    'nativeAbilityPolicy': 'speciesPrimary'
  }) as Map<String, Object?>;
}

String _publishedHash(NativePsdkCatalog catalog) => canonicalHashOf({
      'species': {
        for (final e in catalog.speciesById.entries) e.key: e.value.toJson()
      },
      'learnsets': {
        for (final e in catalog.learnsetsBySpeciesId.entries)
          e.key: e.value.toJson()
      },
      'moves': {
        for (final e in catalog.movesById.entries) e.key: e.value.toJson()
      },
      'evolutions': {
        for (final e in catalog.evolutionsBySpeciesId.entries)
          e.key: e.value.toJson()
      },
      'media': {
        for (final e in catalog.mediaBySpeciesId.entries)
          e.key: e.value.toJson()
      },
      'fallbackMedia': catalog.fallbackMedia,
      'catalogs': {
        for (final e in catalog.catalogs.entries) e.key: e.value.toJson()
      },
      'evidence': catalog.evidence,
    },
            limits: const ContractLimits(
                maxNodes: 8000000,
                maxStringCodeUnits: 1398104,
                maxTextCodeUnits: 134217728))
        .value;

List<Map<String, Object?>> _requestsForSlots(List<SourcePbsEncounterSlot> slots,
    Map<String, Map<String, Object?>> mappings) {
  final requests = <String, Map<String, Object?>>{};
  for (final slot in slots) {
    final mapping = mappings[slot.species] ??
        (_invalid('species_identity',
            'Every source slot requires its exact mapping.'));
    for (var level = slot.minimumLevel; level <= slot.maximumLevel; level++) {
      final key = '${mapping['nativeBaseId']}|${mapping['nativeForm']}|$level';
      final request = requests.putIfAbsent(
          key,
          () => {
                'caseKey': key,
                'nativeBaseId': mapping['nativeBaseId'],
                'nativeForm': mapping['nativeForm'],
                'nativeSpeciesId': mapping['nativeSpeciesId'],
                'level': level,
                'sourceSymbols': <String>[],
              });
      final witnesses = request['sourceSymbols'] as List<String>;
      if (!witnesses.contains(slot.species)) witnesses.add(slot.species);
      if (requests.length > 8192) {
        _invalid('tuple_quota',
            'At most 8192 unique native tuples may be qualified.');
      }
    }
  }

  return [for (final key in requests.keys.toList()..sort()) requests[key]!];
}

bool _boundedIdentity(Object? value, int limit) =>
    value is String && value.isNotEmpty && value.length <= limit;
