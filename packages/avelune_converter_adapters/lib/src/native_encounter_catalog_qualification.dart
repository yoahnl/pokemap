import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;

import 'generated/native_kanto_encounter_catalog_data.dart';
import 'native_project_writer.dart';
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
      this._attestationBytes, this._attestation, this.wildCases);

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

  final List<int> _bundleBytes;
  final List<int> _attestationBytes;
  final Map<String, Object?> _attestation;
  final Map<String, Map<String, Object?>> wildCases;

  NativePsdkTrainerBundle get bundle => NativePsdkTrainerBundle.fromJson(
      (jsonDecode(utf8.decode(_bundleBytes)) as Map).cast<String, dynamic>());

  List<Map<String, Object?>> get sourceMappings =>
      (_attestation['sourceMappings'] as List).cast<Map<String, Object?>>();

  bool admitsAutomaticSource(SourceSnapshot snapshot) => [
        'sourceEncounterPBS',
        'compiledSpecies',
        'sourceScriptArchive'
      ].every((name) {
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
  }) {
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

  Map<String, Object?> get evidence => {
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
