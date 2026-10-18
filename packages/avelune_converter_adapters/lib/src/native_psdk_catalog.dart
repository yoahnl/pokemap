import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';

import 'native_psdk_trainer_bundle.dart';

const nativePsdkCatalogShardJsonLimits = ContractLimits(
  maxNodes: 2000000,
  maxStringCodeUnits: 1398104,
  maxTextCodeUnits: 33554432,
);

final class NativePsdkCatalogLimits {
  const NativePsdkCatalogLimits({
    this.maxShards = 128,
    this.maxRequests = 8192,
    this.maxSpecies = 2048,
    this.maxMoves = 4096,
    this.maxSourceFiles = 16384,
    this.maxSourceBytes = 134217728,
    this.maxEncodedBytes = 134217728,
  });

  final int maxShards;
  final int maxRequests;
  final int maxSpecies;
  final int maxMoves;
  final int maxSourceFiles;
  final int maxSourceBytes;
  final int maxEncodedBytes;

  void _validate() {
    for (final (value, ceiling) in [
      (maxShards, 128),
      (maxRequests, 8192),
      (maxSpecies, 2048),
      (maxMoves, 4096),
      (maxSourceFiles, 16384),
      (maxSourceBytes, 134217728),
      (maxEncodedBytes, 134217728),
    ]) {
      if (value < 1 || value > ceiling) _invalid('limits');
    }
  }
}

final class NativePsdkCatalogManifest implements NativePsdkCatalog {
  NativePsdkCatalogManifest._({
    required this.shards,
    required this.speciesById,
    required this.learnsetsBySpeciesId,
    required this.movesById,
    required this.evolutionsBySpeciesId,
    required this.mediaBySpeciesId,
    required this.fallbackMedia,
    required this.catalogs,
    required this.evidence,
    required NativePsdkCatalogLimits limits,
  }) : _limits = limits;

  factory NativePsdkCatalogManifest.compose(
    List<NativePsdkTrainerBundle> shards, {
    NativePsdkCatalogLimits limits = const NativePsdkCatalogLimits(),
  }) {
    final documents = <String, Map<String, Object?>>{};
    limits._validate();
    if (shards.isEmpty || shards.length > limits.maxShards) _invalid('quota');
    for (final shard in shards) {
      final json = shard.toJson();
      final hash =
          canonicalHashOf(json, limits: nativePsdkCatalogShardJsonLimits).value;
      if (documents.containsKey(hash)) _invalid('duplicate_shard');
      documents[hash] = json;
    }
    return NativePsdkCatalogManifest.fromJson({
      'kind': 'nativePsdkCatalogManifest',
      'version': 1,
      'shards': documents.keys.toList()..sort(),
    }, shards: documents, limits: limits);
  }

  factory NativePsdkCatalogManifest.fromJson(
    Map<String, dynamic> json, {
    required Map<String, Map<String, Object?>> shards,
    NativePsdkCatalogLimits limits = const NativePsdkCatalogLimits(),
  }) {
    limits._validate();
    final hashes = json['shards'];
    if (json['kind'] != 'nativePsdkCatalogManifest' ||
        json['version'] != 1 ||
        json.keys
            .any((key) => !const {'kind', 'version', 'shards'}.contains(key)) ||
        hashes is! List ||
        hashes.any((hash) =>
            hash is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash))) {
      _invalid('manifest');
    }
    if (hashes.isEmpty || hashes.length > limits.maxShards) _invalid('quota');
    final unique = hashes.cast<String>().toSet();
    if (unique.length != hashes.length) _invalid('duplicate_shard');
    if (shards.keys.any((key) => !unique.contains(key))) {
      _invalid('unexpected_shard');
    }
    final admitted = <String, NativePsdkTrainerBundle>{};
    var encodedBytes = 0;
    for (final hash in unique.toList()..sort()) {
      final raw = shards[hash];
      if (raw == null) _invalid('missing_shard');
      final bytes = utf8.encode(
          canonicalJsonOf(raw, limits: nativePsdkCatalogShardJsonLimits));
      encodedBytes += bytes.length;
      if (bytes.length > 33554432 || encodedBytes > limits.maxEncodedBytes) {
        _invalid('quota');
      }
      if (canonicalHashOf(raw, limits: nativePsdkCatalogShardJsonLimits)
              .value !=
          hash) {
        _invalid('shard_hash');
      }
      final shard = NativePsdkTrainerBundle.fromJson(raw);
      _validateShard(shard);
      admitted[hash] = shard;
    }
    final species = _merge(admitted.values.map((s) => s.speciesById),
        (v) => v.toJson(), 'species');
    final learnsets = _merge(admitted.values.map((s) => s.learnsetsBySpeciesId),
        (v) => v.toJson(), 'learnsets');
    final moves = _merge(
        admitted.values.map((s) => s.movesById), (v) => v.toJson(), 'moves');
    final evolutions = _merge(
        admitted.values.map((s) => s.evolutionsBySpeciesId),
        (v) => v.toJson(),
        'evolutions');
    final media = _merge(admitted.values.map((s) => s.mediaBySpeciesId),
        (v) => v.toJson(), 'media');
    final fallback = _merge(admitted.values.map((s) => s.fallbackMedia),
        (v) => v, 'fallback_media');
    final catalogNames =
        {for (final s in admitted.values) ...s.catalogs.keys}.toList()..sort();
    final catalogs = <String, PokemonCatalogFile>{};
    for (final name in catalogNames) {
      final parts = [
        for (final s in admitted.values)
          if (s.catalogs[name] != null) s.catalogs[name]!
      ];
      final metadata = _merge([
        for (final part in parts)
          {
            'metadata': {...part.toJson()}..remove('entries')
          }
      ], (v) => v, 'catalog_metadata:$name');
      final entries = _merge([
        for (final part in parts)
          {for (final row in part.entries) row['id'] as String: row}
      ], (v) => v, 'catalog:$name');
      if (entries.length > 4096) _invalid('quota');
      catalogs[name] = PokemonCatalogFile.fromJson(
          {...metadata['metadata']!, 'entries': entries.values.toList()});
    }
    final evidence = _mergeEvidence(admitted.values, limits);
    if (species.length > limits.maxSpecies || moves.length > limits.maxMoves) {
      _invalid('quota');
    }
    final catalog = NativePsdkCatalogManifest._(
      shards: Map.unmodifiable(admitted),
      speciesById: species,
      learnsetsBySpeciesId: learnsets,
      movesById: moves,
      evolutionsBySpeciesId: evolutions,
      mediaBySpeciesId: media,
      fallbackMedia: fallback,
      catalogs: Map.unmodifiable(catalogs),
      evidence: evidence,
      limits: limits,
    );
    catalog._expectedPublishedFingerprint = catalog._publishedFingerprint();
    return catalog;
  }

  final Map<String, NativePsdkTrainerBundle> shards;
  @override
  final Map<String, PokemonSpeciesFile> speciesById;
  @override
  final Map<String, PokemonLearnsetFile> learnsetsBySpeciesId;
  @override
  final Map<String, PokemonMove> movesById;
  @override
  final Map<String, PokemonEvolutionFile> evolutionsBySpeciesId;
  @override
  final Map<String, PokemonMediaFile> mediaBySpeciesId;
  @override
  final Map<String, Map<String, Object?>> fallbackMedia;
  @override
  final Map<String, PokemonCatalogFile> catalogs;
  @override
  final Map<String, Object?> evidence;
  final NativePsdkCatalogLimits _limits;
  late final String _expectedPublishedFingerprint;

  @override
  Map<String, Object?> toJson() {
    _attestIntegrity();
    return {
      'kind': 'nativePsdkCatalogManifest',
      'version': 1,
      'shards': shards.keys.toList(),
    };
  }

  void _attestIntegrity() {
    try {
      var encodedBytes = 0;
      for (final entry in shards.entries) {
        final (hash, bytes) = _fingerprint(
            entry.value.toJson(), nativePsdkCatalogShardJsonLimits, 33554432);
        encodedBytes += bytes;
        if (hash != entry.key || encodedBytes > _limits.maxEncodedBytes) {
          _invalid('integrity_mutation');
        }
      }
      if (_publishedFingerprint() != _expectedPublishedFingerprint) {
        _invalid('integrity_mutation');
      }
    } catch (_) {
      _invalid('integrity_mutation');
    }
  }

  String _publishedFingerprint() {
    final content = {
      'species': {
        for (final entry in speciesById.entries) entry.key: entry.value.toJson()
      },
      'sourceLearnsets': {
        for (final entry in learnsetsBySpeciesId.entries)
          entry.key: entry.value.toJson()
      },
      'moves': {
        for (final entry in movesById.entries) entry.key: entry.value.toJson()
      },
      'evolutions': {
        for (final entry in evolutionsBySpeciesId.entries)
          entry.key: entry.value.toJson()
      },
      'media': {
        for (final entry in mediaBySpeciesId.entries)
          entry.key: entry.value.toJson()
      },
      'fallbackMedia': fallbackMedia,
      'catalogs': {
        for (final entry in catalogs.entries) entry.key: entry.value.toJson()
      },
      'evidence': evidence,
    };
    final jsonLimits = ContractLimits(
      maxNodes: 8000000,
      maxStringCodeUnits: 1398104,
      maxTextCodeUnits: _limits.maxEncodedBytes,
    );
    return _fingerprint(content, jsonLimits, _limits.maxEncodedBytes).$1;
  }
}

(String, int) _fingerprint(
    Object? value, ContractLimits jsonLimits, int maxBytes) {
  final bytes = utf8.encode(canonicalJsonOf(value, limits: jsonLimits));
  if (bytes.length > maxBytes) _invalid('quota');
  return (crypto.sha256.convert(bytes).toString(), bytes.length);
}

final class NativePsdkCatalogBuilder {
  const NativePsdkCatalogBuilder();

  Future<NativePsdkCatalogManifest> build({
    required List<NativePsdkCatalogRequest> requests,
    required Future<NativePsdkTrainerBundle> Function(
            List<NativePsdkCatalogRequest>)
        buildShard,
    NativePsdkCatalogLimits limits = const NativePsdkCatalogLimits(),
  }) async {
    limits._validate();
    if (requests.isEmpty || requests.length > limits.maxRequests) {
      _invalid('quota');
    }
    final ordered = requests.toList()
      ..sort((a, b) =>
          canonicalJsonOf(a.toJson()).compareTo(canonicalJsonOf(b.toJson())));
    final seen = <String>{};
    for (final request in ordered) {
      if (!seen.add(canonicalJsonOf(request.toJson()))) {
        _invalid('duplicate_request');
      }
    }
    final shards = <NativePsdkTrainerBundle>[];
    Future<void> partition(List<NativePsdkCatalogRequest> batch) async {
      try {
        final shard = await buildShard(List.unmodifiable(batch));
        final actual = (shard.evidence['catalogRequests'] as List)
            .map(canonicalJsonOf)
            .toSet();
        if (actual.length != batch.length ||
            !actual
                .containsAll(batch.map((r) => canonicalJsonOf(r.toJson())))) {
          _invalid('request_binding');
        }
        if (shards.length >= limits.maxShards) _invalid('quota');
        shards.add(shard);
      } on ContractError catch (error) {
        if (!_splitQuotaCodes.contains(error.code) || batch.length == 1) {
          rethrow;
        }
        final middle = batch.length ~/ 2;
        await partition(batch.sublist(0, middle));
        await partition(batch.sublist(middle));
      }
    }

    for (var offset = 0; offset < ordered.length; offset += 256) {
      await partition(
          ordered.sublist(offset, (offset + 256).clamp(0, ordered.length)));
    }
    return NativePsdkCatalogManifest.compose(shards, limits: limits);
  }
}

const _splitQuotaCodes = {
  'native_trainer.request_quota',
  'native_trainer.requested_base_quota',
  'native_trainer.species_closure_quota',
  'native_trainer.form_quota',
  'native_trainer.move_quota',
  'native_trainer.source_file_quota',
  'native_trainer.source_bytes_quota',
  'native_trainer.bundle_quota',
};

Map<String, T> _merge<T>(Iterable<Map<String, T>> maps,
    Object? Function(T) serialize, String domain) {
  final result = <String, T>{};
  final hashes = <String, String>{};
  for (final map in maps) {
    for (final entry in map.entries) {
      final value = canonicalJsonOf(serialize(entry.value),
          limits: nativePsdkCatalogShardJsonLimits);
      if (hashes.containsKey(entry.key) && hashes[entry.key] != value) {
        _invalid('conflict:$domain:${entry.key}');
      }
      hashes[entry.key] = value;
      result[entry.key] = entry.value;
    }
  }
  return Map.unmodifiable(
      {for (final key in result.keys.toList()..sort()) key: result[key] as T});
}

Map<String, Object?> _mergeEvidence(
    Iterable<NativePsdkTrainerBundle> shards, NativePsdkCatalogLimits limits) {
  const variable = {
    'catalogRequests',
    'nativeRequestMoveBindings',
    'nativeFormNamesBySpeciesId',
    'nativeBattleDefaultMoveIds',
    'sourceMoveAdaptations',
    'sourceSpeciesAdaptations',
    'sources'
  };
  final shared = _merge([
    for (final s in shards)
      {
        for (final e in s.evidence.entries)
          if (!variable.contains(e.key)) e.key: e.value
      }
  ], (v) => v, 'evidence');
  final sources = _merge([
    for (final s in shards)
      {
        for (final row in (s.evidence['sources'] as List).cast<Map>())
          row['relativePath'] as String: row.cast<String, Object?>()
      }
  ], (v) => v, 'source_witness');
  final requests = _merge([
    for (final s in shards)
      {
        for (final row in (s.evidence['catalogRequests'] as List).cast<Map>())
          canonicalJsonOf(row): row.cast<String, Object?>()
      }
  ], (v) => v, 'request');
  final bindings = _merge([
    for (final s in shards)
      {
        for (final row
            in (s.evidence['nativeRequestMoveBindings'] as List).cast<Map>())
          canonicalJsonOf({
            'baseId': row['baseId'],
            'form': row['form'],
            'level': row['level'],
            'movePolicy': row['movePolicy'],
            if (row['movePolicy'] == 'explicit') 'moveIds': row['moveIds']
          }): row.cast<String, Object?>()
      }
  ], (v) => v, 'request_moves');
  final names = _merge([
    for (final s in shards)
      (s.evidence['nativeFormNamesBySpeciesId'] as Map).cast<String, Object?>()
  ], (v) => v, 'form_name');
  final defaults = {
    for (final s in shards)
      ...(s.evidence['nativeBattleDefaultMoveIds'] as List).cast<String>()
  }.toList()
    ..sort();
  final adaptations = _merge([
    for (final shard in shards)
      {
        for (final row
            in ((shard.evidence['sourceMoveAdaptations'] as List?) ?? const [])
                .cast<Map>())
          '${row['sourceMoveId']}/${row['field']}': row.cast<String, Object?>()
      }
  ], (value) => value, 'source_move_adaptation');
  final speciesAdaptations = _merge([
    for (final shard in shards)
      {
        for (final row
            in ((shard.evidence['sourceSpeciesAdaptations'] as List?) ??
                    const [])
                .cast<Map>())
          '${row['sourceSpeciesId']}/${row['form']}/${row['field']}':
              row.cast<String, Object?>()
      }
  ], (value) => value, 'source_species_adaptation');
  if (requests.length > limits.maxRequests ||
      sources.length > limits.maxSourceFiles ||
      sources.values
              .fold<int>(0, (sum, row) => sum + (row['byteLength'] as int)) >
          limits.maxSourceBytes) {
    _invalid('quota');
  }
  return _freeze({
    ...shared,
    'catalogRequests': requests.values.toList(),
    'nativeRequestMoveBindings': bindings.values.toList(),
    'nativeFormNamesBySpeciesId': names,
    'nativeBattleDefaultMoveIds': defaults,
    if (adaptations.isNotEmpty)
      'sourceMoveAdaptations': adaptations.values.toList(),
    if (speciesAdaptations.isNotEmpty)
      'sourceSpeciesAdaptations': speciesAdaptations.values.toList(),
    'sources': sources.values.toList()
  }) as Map<String, Object?>;
}

void _validateShard(NativePsdkTrainerBundle shard) {
  final sources = shard.evidence['sources'];
  final requests = shard.evidence['catalogRequests'];
  if (sources is! List ||
      sources.length > 2048 ||
      requests is! List ||
      requests.isEmpty ||
      requests.length > 256) {
    _invalid('shard_quota');
  }
  final paths = <String>{};
  var bytes = 0;
  for (final row in sources) {
    if (row is! Map ||
        row['relativePath'] is! String ||
        !paths.add(row['relativePath'] as String) ||
        row['sha256'] is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(row['sha256'] as String) ||
        row['byteLength'] is! int ||
        (row['byteLength'] as int) < 1 ||
        (row['byteLength'] as int) > 1048576) {
      _invalid('source_witness');
    }
    bytes += row['byteLength'] as int;
  }
  if (bytes > 16777216) _invalid('shard_quota');
  final requestKeys = <String>{};
  final bases = <String>{};
  for (final raw in requests) {
    if (raw is! Map) _invalid('request');
    final request =
        NativePsdkCatalogRequest.fromJson(raw.cast<String, dynamic>());
    if (!requestKeys.add(canonicalJsonOf(request.toJson()))) {
      _invalid('duplicate_request');
    }
    bases.add(request.baseId);
    if (!shard.speciesById
        .containsKey(nativePsdkFormSpeciesId(request.baseId, request.form))) {
      _invalid('request_binding');
    }
  }
  if (bases.length > 64) _invalid('shard_quota');
  final ids = shard.speciesById.keys.toSet();
  if (!ids.containsAll(shard.learnsetsBySpeciesId.keys) ||
      !ids.containsAll(shard.evolutionsBySpeciesId.keys) ||
      !ids.containsAll(shard.mediaBySpeciesId.keys)) {
    _invalid('dependency_closure');
  }
  for (final species in shard.speciesById.values) {
    final base = species.forms.baseFormId;
    final form = int.tryParse(species.forms.formId);
    if (base.isEmpty ||
        form == null ||
        species.id != nativePsdkFormSpeciesId(base, form) ||
        !ids.contains(base) ||
        species.forms.otherForms.any((other) {
          final number = int.tryParse(other);
          return number == null ||
              !ids.contains(nativePsdkFormSpeciesId(base, number));
        })) {
      _invalid('dependency_closure');
    }
    final learnset = shard.learnsetsBySpeciesId[species.id]!;
    final moveIds = [
      ...learnset.startingMoves,
      ...learnset.relearnMoves,
      ...learnset.levelUp.map((move) => move.moveId),
      for (final list in [
        learnset.tm,
        learnset.hm,
        learnset.tutor,
        learnset.egg,
        learnset.event,
        learnset.transfer
      ])
        ...list.map((move) => move.moveId),
    ];
    if (moveIds.any((id) => !shard.movesById.containsKey(id))) {
      _invalid('dependency_closure');
    }
    final evolution = shard.evolutionsBySpeciesId[species.id]!;
    if ((evolution.preEvolution != null &&
            !ids.contains(evolution.preEvolution)) ||
        evolution.evolutions.any((rule) =>
            !ids.contains(rule.targetSpeciesId) ||
            (rule.requiredMoveId != null &&
                !shard.movesById.containsKey(rule.requiredMoveId)))) {
      _invalid('dependency_closure');
    }
  }
  final bindings = shard.evidence['nativeRequestMoveBindings'];
  if (bindings is! List || bindings.length != requests.length) {
    _invalid('dependency_closure');
  }
  final bindingKeys = <String>{};
  for (final raw in bindings) {
    if (raw is! Map ||
        !const {'nativeDefaults', 'explicit'}.contains(raw['movePolicy'])) {
      _invalid('dependency_closure');
    }
    final row = raw.cast<String, dynamic>();
    final moveIds = row['moveIds'];
    if (moveIds is! List ||
        moveIds.isEmpty ||
        moveIds.length > 4 ||
        moveIds
            .any((id) => id is! String || !shard.movesById.containsKey(id))) {
      _invalid('dependency_closure');
    }
    final request = NativePsdkCatalogRequest.fromJson({
      'baseId': row['baseId'],
      'form': row['form'],
      'level': row['level'],
      if (row['movePolicy'] == 'explicit') 'explicitMoveIds': moveIds,
    });
    final key = canonicalJsonOf(request.toJson());
    if (!requestKeys.contains(key) || !bindingKeys.add(key)) {
      _invalid('dependency_closure');
    }
    if (row['movePolicy'] == 'nativeDefaults') {
      final learnset = shard.learnsetsBySpeciesId[
          nativePsdkFormSpeciesId(request.baseId, request.form)]!;
      if (canonicalJsonOf(moveIds) !=
          canonicalJsonOf(
              nativeTrainerDefaultMoveIds(learnset, request.level))) {
        _invalid('dependency_closure');
      }
    }
  }
}

Object? _freeze(Object? value) => switch (value) {
      Map value => Map<String, Object?>.unmodifiable(
          value.map((key, entry) => MapEntry(key as String, _freeze(entry)))),
      List value => List<Object?>.unmodifiable(value.map(_freeze)),
      _ => value,
    };

Never _invalid(String reason) => throw ContractError('native_catalog.$reason',
    r'$', 'The bounded native catalog is invalid: $reason.');
