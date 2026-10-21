import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'native_project_writer.dart';
import 'native_psdk_catalog.dart';
import 'native_psdk_trainer_bundle.dart';
import 'native_source_species_bindings.dart';
import 'native_trainer_authored_bindings.dart';
import 'native_trainer_money_binding.dart';

final class NativeTrainerQualificationLimits {
  const NativeTrainerQualificationLimits(
      {this.maxRequestedTrainers = 2048,
      this.maxCompiledBytes = 8388608,
      this.maxEvidenceBytes = 16777216});
  final int maxRequestedTrainers;
  final int maxCompiledBytes;
  final int maxEvidenceBytes;
}

final class NativeTrainerQualificationRefusal {
  const NativeTrainerQualificationRefusal(
      this.identity, this.code, this.message);
  final SourcePbsIdentity identity;
  final String code;
  final String message;
  Map<String, Object?> toJson() => {
        'sourceIdentity': identity.toJson(),
        'code': code,
        'message': message,
      };
}

final class NativeTrainerCatalogQualification {
  NativeTrainerCatalogQualification._(
      List<ProjectTrainerEntry> trainers,
      List<NativeTrainerQualificationRefusal> refusals,
      Map<String, Object?> evidence)
      : trainers = List.unmodifiable(trainers),
        refusals = List.unmodifiable(refusals),
        evidence = _freeze(evidence) as Map<String, Object?>;
  final List<ProjectTrainerEntry> trainers;
  final List<NativeTrainerQualificationRefusal> refusals;
  final Map<String, Object?> evidence;
  List<ProjectItemDefinition> get battleItemDefinitions => [
        for (final row
            in (evidence['authoredBindings'] as Map)['bindings'] as List)
          if (row['domain'] == 'item' &&
              trainers.any((trainer) => trainer.battleItems
                  .containsKey((row['nativeItem'] as Map)['id'])))
            ProjectItemDefinition.fromJson(
                (row['nativeItem'] as Map).cast<String, dynamic>()),
      ];
  List<Map<String, Object?>> get rows =>
      (evidence['trainers'] as List).cast<Map<String, Object?>>();
  late final Sha256Hash evidenceHash =
      canonicalHashOf(evidence, limits: _jsonLimits);

  static Future<NativeTrainerCatalogQualification> prepare({
    required NormalizedSourceProject normalizedSource,
    required SourcePbsProject source,
    required SourceFilePort files,
    required NativePsdkCatalog nativeCatalog,
    required Iterable<SourcePbsIdentity> requestedTrainers,
    ScanCancellation? cancellation,
    NativeTrainerQualificationLimits limits =
        const NativeTrainerQualificationLimits(),
  }) async {
    cancellation?.check();
    _validateLimits(limits);
    final snapshot = normalizedSource.snapshot;
    if (normalizedSource.sourceProfileId.value !=
            'profile:${snapshot.profile.evidenceHash.value}' ||
        source.profile != SourcePbsProfile.essentials21_1 ||
        source.sourceSnapshotHash != snapshot.canonicalHash ||
        source.logicalProjectNamespace != snapshot.logicalProjectNamespace) {
      _invalid('source_binding',
          'Rosters require the exact normalized Essentials 21.1 PBS snapshot.');
    }
    final requested = <SourcePbsIdentity>[];
    final keys = <String>{};
    var inputRows = 0;
    for (final identity in requestedTrainers) {
      cancellation?.check();
      if (++inputRows > limits.maxRequestedTrainers * 4) {
        _invalid('request_quota',
            'The requested input traversal budget was exceeded.');
      }
      _validateIdentity(identity, snapshot.logicalProjectNamespace);
      if (!keys.add(identity.key)) continue;
      if (requested.length >= limits.maxRequestedTrainers) {
        _invalid('request_quota',
            'The requested trainer identity budget was exceeded.');
      }
      requested.add(identity);
    }
    final catalogHash = _catalogHash(nativeCatalog);
    final witnesses = snapshot.entries
        .where((entry) => entry.relativePath == 'Data/trainers.dat')
        .toList();
    if (witnesses.length != 1 ||
        witnesses.single.kind != SourceNodeKind.file ||
        witnesses.single.sha256 == null ||
        witnesses.single.byteLength < 1 ||
        witnesses.single.byteLength > limits.maxCompiledBytes) {
      _invalid('compiled_witness',
          'Exactly one bounded Data/trainers.dat witness is required.');
    }
    final witness = witnesses.single;
    final cached = _CachedFiles(files);
    final completeSource = await const SourcePbsParser().read(
        snapshot: snapshot,
        files: cached,
        profile: SourcePbsProfile.essentials21_1,
        cancellation: cancellation);
    if (completeSource.canonicalHash != source.canonicalHash) {
      _invalid('pbs_context',
          'Trainer qualification requires the exact complete canonical PBS context from the sealed source files.');
    }
    final moneyWitness = await NativeTrainerMoneyWitness.read(
        snapshot: snapshot, files: cached, cancellation: cancellation);
    final List<int> bytes;
    try {
      bytes = await cached.read(witness.fileId);
    } catch (_) {
      cancellation?.check();
      _invalid('compiled_read',
          'The exact compiled trainer witness could not be read.');
    }
    cancellation?.check();
    if (bytes.length != witness.byteLength ||
        bytes.any((value) => value < 0 || value > 255) ||
        crypto.sha256.convert(bytes).toString() != witness.sha256!.value) {
      _invalid('compiled_changed',
          'Compiled trainer bytes differ from their snapshot witness.');
    }
    final compiled = _readCompiled(
        bytes, snapshot.logicalProjectNamespace, limits, cancellation);
    final byIdentity = <String, List<SourcePbsEntry>>{};
    for (final entry in source.entries) {
      cancellation?.check();
      if (entry.family == SourcePbsFamily.trainers && entry.identity != null) {
        (byIdentity[entry.identity!.key] ??= []).add(entry);
      }
    }
    final valid = <String, (SourcePbsEntry, _CompiledTrainer)>{};
    final errors = <String, NativeTrainerQualificationRefusal>{};
    final symbols = <String>{};
    for (final identity in requested) {
      cancellation?.check();
      try {
        final entries = byIdentity[identity.key] ?? const [];
        if (entries.isEmpty) {
          _invalid('pbs_missing',
              'The exact requested trainer has no PBS identity.');
        }
        if (entries.length != 1) {
          _invalid('pbs_ambiguous',
              'The requested trainer has duplicate PBS identities.');
        }
        final entry = entries.single;
        if (entry.party.any(
            (member) => member.fields.any((field) => field.key != 'Moves'))) {
          _invalid('party_override',
              'Authored member properties require explicit native bindings; no defaults were substituted.');
        }
        if (entry.fields.any((field) =>
            !const {'Pokemon', 'LoseText', 'Items'}.contains(field.key) &&
            !entry.party.any((member) => member.fields.contains(field)))) {
          _invalid('trainer_override',
              'Authored trainer properties require explicit native bindings.');
        }
        if (entry.isBlocked) {
          _invalid('pbs_blocked',
              'The requested PBS trainer has blocking diagnostics.');
        }
        if (entry.party.isEmpty ||
            entry.party.length > 6 ||
            entry.party.any((member) {
              final tokens = member.headerField.values;
              final level = tokens.length == 2 ? int.tryParse(tokens[1]) : null;
              return tokens.length != 2 ||
                  tokens.first.isEmpty ||
                  level == null ||
                  level < 1 ||
                  level > 100;
            })) {
          _invalid('member_invalid',
              'Every trainer requires one through six exact species and levels from 1 through 100.');
        }
        final records = compiled[identity.key] ?? const [];
        if (records.isEmpty) {
          _invalid('compiled_missing',
              'The exact requested trainer has no compiled identity.');
        }
        if (records.length != 1) {
          _invalid('compiled_ambiguous',
              'The requested trainer has duplicate compiled identities.');
        }
        final record = records.single;
        if (record.error != null) {
          _invalid(record.error!,
              'The requested compiled roster contains unsupported or malformed properties at Data/trainers.dat:${record.offset}:${record.graphPath}.');
        }
        final roster = [
          for (final member in entry.party)
            {
              'species': member.headerField.values.first,
              'level': int.parse(member.headerField.values.last),
              if (member.fields.any((field) => field.key == 'Moves'))
                'moves': _authoredMoves(member),
            }
        ];
        if (canonicalJsonOf(roster) != canonicalJsonOf(record.party)) {
          _invalid('roster_changed',
              'PBS and compiled rosters disagree in exact ordered species or levels.');
        }
        if (canonicalJsonOf(_authoredItems(entry)) !=
            canonicalJsonOf(record.items)) {
          _invalid('roster_changed',
              'PBS and compiled trainer item inventories disagree.');
        }
        final loses = entry.fieldsNamed('LoseText');
        if (loses.length > 1 ||
            (loses.isEmpty ? '' : loses.single.values.single) !=
                record.loseText ||
            source.documents
                    .singleWhere((document) => document.entries.contains(entry))
                    .suffix !=
                record.suffix) {
          _invalid('roster_changed',
              'PBS and compiled trainer text or file suffix disagree.');
        }
        valid[identity.key] = (entry, record);
        symbols.addAll(roster.map((row) => row['species'] as String));
      } on ContractError catch (error) {
        if (error.code == 'source.cancelled') rethrow;
        errors[identity.key] = NativeTrainerQualificationRefusal(
            identity, error.code, error.message);
      }
    }
    final bindings = <String, Map<String, Object?>>{};
    final speciesErrors = <String, ContractError>{};
    Map<String, Object?>? speciesEvidence;
    if (symbols.isNotEmpty) {
      try {
        final bound = await const NativeSourceSpeciesBindings().bind(
            snapshot: snapshot,
            source: source,
            files: cached,
            nativeCatalog: nativeCatalog,
            requestedSourceSymbols: symbols,
            cancellation: cancellation);
        bindings.addAll(bound.mappings);
        speciesEvidence = bound.evidence;
      } on ContractError catch (error) {
        if (error.code == 'source.cancelled') rethrow;
        final parts = <Map<String, Object?>>[];
        for (final symbol in symbols.toList()..sort()) {
          cancellation?.check();
          try {
            final bound = await const NativeSourceSpeciesBindings().bind(
                snapshot: snapshot,
                source: source,
                files: cached,
                nativeCatalog: nativeCatalog,
                requestedSourceSymbols: [symbol],
                cancellation: cancellation);
            bindings.addAll(bound.mappings);
            parts.add({
              'sourceSymbol': symbol,
              'bindingEvidenceHash':
                  canonicalHashOf(bound.evidence, limits: _jsonLimits).value
            });
          } on ContractError catch (failure) {
            if (failure.code == 'source.cancelled') rethrow;
            speciesErrors[symbol] = failure;
          }
        }
        speciesEvidence = {
          'kind': 'nativeTrainerPartialSpeciesBindings',
          'bindings': parts
        };
      }
    }
    final authored = await NativeTrainerAuthoredBindings.read(
        snapshot: snapshot,
        source: source,
        files: cached,
        native: nativeCatalog,
        moveSymbols: {
          for (final pair in valid.values)
            for (final member in pair.$1.party) ..._authoredMoves(member)
        },
        itemSymbols: {
          for (final pair in valid.values) ..._authoredItems(pair.$1)
        },
        cancellation: cancellation);
    final trainers = <ProjectTrainerEntry>[];
    final rows = <Map<String, Object?>>[];
    final abilities = nativeCatalog.catalogs['abilities']?.entries
            .map((entry) => entry['id'])
            .toSet() ??
        const {};
    for (final identity in requested) {
      cancellation?.check();
      if (errors.containsKey(identity.key)) continue;
      final (entry, record) = valid[identity.key]!;
      try {
        final team = <ProjectTrainerPokemonEntry>[];
        final members = <Map<String, Object?>>[];
        for (final member in entry.party) {
          cancellation?.check();
          final symbol = member.headerField.values.first;
          final mapping = bindings[symbol];
          if (mapping == null) {
            _invalid('species_binding',
                'Source $symbol has no qualified native identity: ${speciesErrors[symbol]?.code}.');
          }
          final id = mapping['nativeSpeciesId'] as String;
          final species = nativeCatalog.speciesById[id];
          final learnset = nativeCatalog.learnsetsBySpeciesId[id];
          if (species == null ||
              learnset == null ||
              species.id != id ||
              species.forms.formId != '${mapping['nativeForm']}' ||
              species.forms.baseFormId != mapping['nativeBaseId'] ||
              !abilities.contains(species.abilities.primary)) {
            _invalid('native_closure',
                'Every trainer species, form, learnset and primary ability must be closed in the active catalog.');
          }
          final level = int.parse(member.headerField.values.last);
          final explicit = _authoredMoves(member);
          final moves = explicit.isEmpty
              ? nativeTrainerDefaultMoveIds(learnset, level)
              : [
                  for (final symbol in explicit)
                    authored.moves[symbol] ??
                        (throw authored.errors['move:$symbol']!),
                ];
          if (moves.isEmpty || moves.length > 4) {
            _invalid('native_defaults',
                'Native defaults require one through four moves.');
          }
          final moveRows = <Map<String, Object?>>[];
          for (final id in moves) {
            cancellation?.check();
            final move = nativeCatalog.movesById[id];
            if (move == null || move.id != id || move.pp <= 0) {
              _invalid('native_move_closure',
                  'An exact native default move is missing.');
            }
            try {
              final projected =
                  const CanonicalPsdkMoveProjector().project(move: move);
              if (projected.id != id || projected.pp != move.pp) {
                _invalid('native_move_projection',
                    'Canonical move identity or PP differs.');
              }
              moveRows.add({
                'moveId': id,
                'moveHash': canonicalHashOf(move.toJson()).value,
                'battleEngineMethod': projected.battleEngineMethod,
                'psdkRegistryStatus': const CanonicalPsdkMoveProjector()
                    .registryStatusFor(projected.battleEngineMethod)
              });
            } on CanonicalPsdkMoveProjectionException catch (error) {
              _invalid('native_move_projection',
                  'Canonical projection rejected $id: ${error.reason}.');
            } on ArgumentError catch (error) {
              _invalid('native_move_projection',
                  'Canonical projection rejected $id: $error.');
            }
          }
          team.add(ProjectTrainerPokemonEntry(
              speciesId: id,
              level: level,
              moves: List.unmodifiable(moves),
              abilityId: species.abilities.primary));
          members.add({
            'sourceSymbol': symbol,
            'sourceLocator': member.headerField.locator.toJson(),
            'speciesBindingHash':
                canonicalHashOf(mapping, limits: _jsonLimits).value,
            'nativeSpeciesId': id,
            'nativeForm': mapping['nativeForm'],
            'level': level,
            'nativeSpeciesHash': canonicalHashOf(species.toJson()).value,
            'nativeLearnsetHash': canonicalHashOf(learnset.toJson()).value,
            'nativeAbilityId': species.abilities.primary,
            'movePolicy': explicit.isEmpty
                ? 'nativeAveluneDefaults'
                : 'authoredSourceIdentities',
            'sourceMoveSymbols': explicit,
            'moves': moveRows
          });
        }
        final battleItems = <String, int>{};
        for (final symbol in _authoredItems(entry)) {
          final item = authored.items[symbol] ??
              (throw authored.errors['item:$symbol']!);
          battleItems.update(item.id, (count) => count + 1, ifAbsent: () => 1);
        }
        if (battleItems.length > trainerBattleItemMaxDistinctCount ||
            battleItems.values
                .any((count) => count > trainerBattleItemMaxQuantity)) {
          _invalid('items_quota',
              'Authored trainer medicines exceed the native inventory bounds.');
        }
        final money = NativeTrainerMoneyBinding.fromPbs(
            source: source,
            roster: entry,
            team: team,
            compiledWitness: moneyWitness);
        final trainer = ProjectTrainerEntry(
            id: identity.sourceId.value,
            name: identity.trainerName!,
            trainerClass: identity.trainerType!,
            moneyReward: money.amount,
            battleItems: battleItems,
            team: List.unmodifiable(team),
            tags: const [
              'source-imported',
              'native-roster-qualified',
              'runtime-battle-unqualified'
            ]);
        trainers.add(trainer);
        final row = <String, Object?>{
          'sourceIdentity': identity.toJson(),
          'sourceLocator': entry.headerLocator.toJson(),
          'sourceRosterHash': canonicalHashOf(entry.toJson()).value,
          'compiledByteOffset': record.offset,
          'compiledGraphPath': record.graphPath,
          'sourceLoseText': record.loseText,
          'prizeMoney': money.evidence,
          'members': members,
          'nativeTrainer': trainer.toJson()
        };
        rows.add({
          ...row,
          'rowHash': canonicalHashOf(row, limits: _jsonLimits).value
        });
      } on ContractError catch (error) {
        if (error.code == 'source.cancelled') rethrow;
        errors[identity.key] = NativeTrainerQualificationRefusal(
            identity, error.code, error.message);
      }
    }
    cancellation?.check();
    if (_catalogHash(nativeCatalog) != catalogHash) {
      _invalid('catalog_integrity',
          'The active catalog changed during qualification.');
    }
    final refusals = [
      for (final identity in requested)
        if (errors[identity.key] case final failure?) failure
    ];
    final evidence = <String, Object?>{
      'kind': 'nativeTrainerCatalogQualification',
      'version': 1,
      'policy': _policy,
      'sourceSnapshotHash': snapshot.canonicalHash.value,
      'normalizationHash': normalizedSource.canonicalHash.value,
      'sourceProfileHash': snapshot.profile.evidenceHash.value,
      'sourceProfileId': normalizedSource.sourceProfileId.value,
      'sourceProfileState': snapshot.profile.state.name,
      'observedSourceVersions':
          snapshot.profile.evidence.map((row) => row.version).toSet().toList()
            ..sort(),
      'sourceVersionConfirmed': false,
      'sourcePbsHash': source.canonicalHash.value,
      'sourceProfile': source.profile.name,
      'logicalProjectNamespace': snapshot.logicalProjectNamespace.value,
      'compiledTrainerWitness': witness.toJson(),
      'nativeCatalogHash': catalogHash,
      'movePolicy': 'nativeAveluneDefaultsOnlyWithoutAuthoredMoves',
      'authoredBindings': authored.evidence,
      'abilityPolicy': 'nativeSpeciesPrimary',
      'battleLogic': 'avelune',
      'requestedTrainers':
          requested.map((identity) => identity.toJson()).toList(),
      'speciesMappings': bindings.values.toList(),
      'speciesBindingEvidenceHash': speciesEvidence == null
          ? null
          : canonicalHashOf(speciesEvidence, limits: _jsonLimits).value,
      'trainers': rows,
      'refusals': refusals.map((failure) => failure.toJson()).toList(),
      'sourceScriptsExecuted': 0,
      'aiCalls': 0,
      'runtimeBattleBuilderQualified': false,
      'eventActivationQualified': false,
    };
    if (utf8.encode(canonicalJsonOf(evidence, limits: _jsonLimits)).length >
        limits.maxEvidenceBytes) {
      _invalid(
          'evidence_quota', 'Qualification evidence exceeds its byte budget.');
    }
    return NativeTrainerCatalogQualification._(trainers, refusals, evidence);
  }

  Future<void> validateContext({
    required NormalizedSourceProject normalizedSource,
    required SourcePbsProject source,
    required SourceFilePort files,
    required NativePsdkCatalog nativeCatalog,
    required Iterable<SourcePbsIdentity> requestedTrainers,
    ScanCancellation? cancellation,
  }) async {
    cancellation?.check();
    final requested = {for (final identity in requestedTrainers) identity.key}
        .toList()
      ..sort();
    final qualified = (evidence['requestedTrainers'] as List)
        .map((row) => canonicalJsonOf(row))
        .toList()
      ..sort();
    if (evidence['sourceSnapshotHash'] !=
            normalizedSource.snapshot.canonicalHash.value ||
        evidence['normalizationHash'] != normalizedSource.canonicalHash.value ||
        evidence['sourcePbsHash'] != source.canonicalHash.value ||
        source.sourceSnapshotHash != normalizedSource.snapshot.canonicalHash ||
        evidence['nativeCatalogHash'] != _catalogHash(nativeCatalog) ||
        canonicalJsonOf(requested) != canonicalJsonOf(qualified)) {
      _invalid('context_binding',
          'Trainer qualification requires its exact source, normalization, PBS, active catalog and requested identities.');
    }
    final pbsFiles =
        source.documents.map((document) => document.file.fileId).toSet();
    for (final entry in normalizedSource.snapshot.entries.where((entry) =>
        pbsFiles.contains(entry.fileId) ||
        entry.relativePath == 'Data/trainers.dat' ||
        entry.relativePath == 'Data/species.dat' ||
        entry.relativePath == 'Data/moves.dat' ||
        entry.relativePath == 'Data/items.dat')) {
      final bytes = await files.read(entry.fileId);
      cancellation?.check();
      if (bytes.length != entry.byteLength ||
          crypto.sha256.convert(bytes).toString() != entry.sha256?.value) {
        _invalid('source_changed',
            'Trainer source bytes changed after qualification.');
      }
    }
    if ((evidence['authoredBindings'] as Map)['nativeItemCatalogHash'] !=
        canonicalHashOf(mvpItemCatalog.toJson()).value) {
      _invalid('catalog_changed',
          'The active native battle medicine catalog changed.');
    }
    if (evidence['nativeCatalogHash'] != _catalogHash(nativeCatalog)) {
      _invalid('catalog_changed',
          'The active native catalog changed while source witnesses were read.');
    }
  }

  NativeTrainerQualificationArtifacts artifacts(
      {NativeWriteLimits limits = const NativeWriteLimits()}) {
    limits.validate();
    final bytes = utf8.encode(canonicalJsonOf(evidence, limits: _jsonLimits));
    final chunks = <NativeArtifact>[];
    var total = 0;
    for (var offset = 0; offset < bytes.length; offset += 45000) {
      final end = offset + 45000 < bytes.length ? offset + 45000 : bytes.length;
      final artifact = NativeArtifact(
          bytes: utf8.encode(canonicalJsonOf({
            'kind': 'nativeTrainerQualificationChunk',
            'version': 1,
            'index': chunks.length,
            'bytes': base64.encode(bytes.sublist(offset, end)),
          })),
          mediaType: 'application/json',
          limits: limits);
      total += artifact.bytes.length;
      if (chunks.length >= limits.maxArtifacts ||
          total > limits.maxTotalArtifactBytes) {
        _invalid('artifact_quota',
            'Portable qualification exceeds the caller artifact budget.');
      }
      chunks.add(artifact);
    }
    return NativeTrainerQualificationArtifacts(
        List.unmodifiable(chunks),
        _freeze({
          'kind': 'nativeTrainerQualificationArtifacts',
          'version': 1,
          'policy': _policy,
          'qualificationHash': evidenceHash.value,
          'byteLength': bytes.length,
          'sourceSnapshotHash': evidence['sourceSnapshotHash'],
          'nativeCatalogHash': evidence['nativeCatalogHash'],
          'chunks': [
            for (final chunk in chunks)
              {
                'handle': chunk.handle,
                'sha256': chunk.rawSha256.value,
                'byteLength': chunk.bytes.length
              }
          ]
        }) as Map<String, Object?>);
  }

  static Future<NativeTrainerCatalogQualification> fromArtifacts({
    required Map<String, Object?> evidence,
    required Iterable<NativeArtifact> artifacts,
    required NormalizedSourceProject normalizedSource,
    required SourceFilePort files,
    required NativePsdkCatalog nativeCatalog,
    ScanCancellation? cancellation,
    NativeTrainerQualificationLimits limits =
        const NativeTrainerQualificationLimits(),
    NativeWriteLimits writeLimits = const NativeWriteLimits(),
  }) async {
    cancellation?.check();
    _validateLimits(limits);
    writeLimits.validate();
    try {
      const keys = {
        'kind',
        'version',
        'policy',
        'qualificationHash',
        'byteLength',
        'sourceSnapshotHash',
        'nativeCatalogHash',
        'chunks'
      };
      if (evidence.length != keys.length ||
          !evidence.keys.every(keys.contains) ||
          evidence['kind'] != 'nativeTrainerQualificationArtifacts' ||
          evidence['version'] != 1 ||
          evidence['policy'] != _policy ||
          evidence['sourceSnapshotHash'] !=
              normalizedSource.snapshot.canonicalHash.value ||
          evidence['nativeCatalogHash'] != _catalogHash(nativeCatalog) ||
          evidence['byteLength'] is! int ||
          (evidence['byteLength'] as int) < 1 ||
          (evidence['byteLength'] as int) > limits.maxEvidenceBytes ||
          evidence['chunks'] is! List) {
        _invalid('portable_context',
            'Portable trainer qualification context differs.');
      }
      final descriptions = evidence['chunks'] as List;
      if (descriptions.isEmpty ||
          descriptions.length > writeLimits.maxArtifacts) {
        _invalid('artifact_quota', 'Portable chunk count exceeds its budget.');
      }
      final available = <String, NativeArtifact>{};
      var total = 0;
      for (final artifact in artifacts) {
        cancellation?.check();
        total += artifact.bytes.length;
        if (available.length >= writeLimits.maxArtifacts ||
            total > writeLimits.maxTotalArtifactBytes ||
            artifact.bytes.length > writeLimits.maxArtifactBytes ||
            available.containsKey(artifact.handle)) {
          _invalid('portable_artifacts',
              'Portable artifacts must be unique and bounded.');
        }
        available[artifact.handle] = artifact;
      }
      final bytes = <int>[];
      final used = <String>{};
      for (final (index, raw) in descriptions.indexed) {
        cancellation?.check();
        if (raw is! Map ||
            raw.length != 3 ||
            !raw.keys.every({'handle', 'sha256', 'byteLength'}.contains) ||
            raw['handle'] is! String) {
          _invalid(
              'portable_artifacts', 'Malformed portable chunk description.');
        }
        final artifact = available[raw['handle']];
        if (artifact == null ||
            !used.add(artifact.handle) ||
            artifact.rawSha256.value != raw['sha256'] ||
            artifact.bytes.length != raw['byteLength'] ||
            crypto.sha256.convert(artifact.bytes).toString() != raw['sha256']) {
          _invalid('portable_artifacts', 'Portable chunk witness differs.');
        }
        final chunk = jsonDecode(utf8.decode(artifact.bytes)) as Map;
        if (chunk.length != 4 ||
            !chunk.keys.every({'kind', 'version', 'index', 'bytes'}.contains) ||
            chunk['kind'] != 'nativeTrainerQualificationChunk' ||
            chunk['version'] != 1 ||
            chunk['index'] != index ||
            chunk['bytes'] is! String) {
          _invalid(
              'portable_artifacts', 'Portable chunk index or shape differs.');
        }
        final decoded = base64.decode(chunk['bytes'] as String);
        if (decoded.isEmpty ||
            decoded.length > 45000 ||
            bytes.length + decoded.length > limits.maxEvidenceBytes) {
          _invalid(
              'artifact_quota', 'Portable decoded bytes exceed their budget.');
        }
        bytes.addAll(decoded);
      }
      if (used.length != available.length ||
          bytes.length != evidence['byteLength']) {
        _invalid('portable_artifacts',
            'Portable qualification has missing or extra chunks.');
      }
      final proof =
          (jsonDecode(utf8.decode(bytes)) as Map).cast<String, Object?>();
      if (canonicalHashOf(proof, limits: _jsonLimits).value !=
              evidence['qualificationHash'] ||
          proof['requestedTrainers'] is! List) {
        _invalid('portable_hash', 'Portable qualification hash differs.');
      }
      final requests = <SourcePbsIdentity>[];
      for (final raw in proof['requestedTrainers'] as List) {
        if (raw is! Map) {
          _invalid('portable_identity', 'Malformed portable trainer identity.');
        }
        final identity = SourcePbsIdentity(
            namespace: normalizedSource.snapshot.logicalProjectNamespace,
            family: SourcePbsFamily.trainers,
            trainerType: raw['trainerType'] as String?,
            trainerName: raw['trainerName'] as String?,
            version: raw['version'] as int);
        _validateIdentity(
            identity, normalizedSource.snapshot.logicalProjectNamespace);
        if (canonicalJsonOf(raw) != canonicalJsonOf(identity.toJson())) {
          _invalid('portable_identity', 'Portable trainer identity differs.');
        }
        if (requests.length >= limits.maxRequestedTrainers) {
          _invalid('request_quota', 'Portable request budget exceeded.');
        }
        requests.add(identity);
      }
      final cached = _CachedFiles(files);
      final source = await const SourcePbsParser().read(
          snapshot: normalizedSource.snapshot,
          files: cached,
          profile: SourcePbsProfile.essentials21_1,
          cancellation: cancellation);
      final actual = await prepare(
          normalizedSource: normalizedSource,
          source: source,
          files: cached,
          nativeCatalog: nativeCatalog,
          requestedTrainers: requests,
          cancellation: cancellation,
          limits: limits);
      if (actual.evidenceHash.value != evidence['qualificationHash']) {
        _invalid('portable_requalification',
            'Source and native choices do not requalify the portable proof.');
      }
      return actual;
    } on ContractError {
      rethrow;
    } on FormatException {
      _invalid('portable_format',
          'Portable qualification JSON or bytes are malformed.');
    } on TypeError {
      _invalid(
          'portable_format', 'Portable qualification types are malformed.');
    }
  }
}

final class NativeTrainerQualificationArtifacts {
  NativeTrainerQualificationArtifacts(this.artifacts, this.evidence);
  final List<NativeArtifact> artifacts;
  final Map<String, Object?> evidence;
}

const _jsonLimits = ContractLimits(
    maxNodes: 2000000, maxStringCodeUnits: 1048576, maxTextCodeUnits: 33554432);

Object? _freeze(Object? value) => value is Map
    ? Map<String, Object?>.unmodifiable(
        value.map((key, item) => MapEntry(key as String, _freeze(item))))
    : value is List
        ? List<Object?>.unmodifiable(value.map(_freeze))
        : value;

List<String> _authoredMoves(SourcePbsTrainerPokemon member) {
  final fields = member.fields.where((field) => field.key == 'Moves').toList();
  if (fields.isEmpty) return const [];
  if (fields.length != 1 ||
      fields.single.values.isEmpty ||
      fields.single.values.length > 4 ||
      fields.single.values.toSet().length != fields.single.values.length ||
      fields.single.values
          .any((value) => !RegExp(r'^[A-Z][A-Z0-9_]*$').hasMatch(value))) {
    _invalid('party_override',
        'Authored moves require one ordered unique list of one through four exact symbols.');
  }
  return fields.single.values;
}

List<String> _authoredItems(SourcePbsEntry entry) {
  final fields = entry.fieldsNamed('Items');
  if (fields.isEmpty) return const [];
  if (fields.length != 1 ||
      fields.single.values.isEmpty ||
      fields.single.values.length >
          trainerBattleItemMaxDistinctCount * trainerBattleItemMaxQuantity ||
      fields.single.values
          .any((value) => !RegExp(r'^[A-Z][A-Z0-9_]*$').hasMatch(value))) {
    _invalid('trainer_override',
        'Authored trainer medicines require one bounded ordered symbol list.');
  }
  return fields.single.values;
}

const _policy = 'essentials21.1-exact-pbs-compiled-roster-authored-native-v2';

void _validateLimits(NativeTrainerQualificationLimits limits) {
  if (limits.maxRequestedTrainers < 1 ||
      limits.maxRequestedTrainers > 2048 ||
      limits.maxCompiledBytes < 1 ||
      limits.maxCompiledBytes > 8388608 ||
      limits.maxEvidenceBytes < 1 ||
      limits.maxEvidenceBytes > 16777216) {
    _invalid('limits', 'Qualification limits must be positive and bounded.');
  }
}

void _validateIdentity(SourcePbsIdentity identity, ConverterId namespace) {
  bool text(String? value) =>
      value != null && value.isNotEmpty && value.length <= 192;
  if (identity.namespace != namespace ||
      identity.family != SourcePbsFamily.trainers ||
      !text(identity.trainerType) ||
      !text(identity.trainerName) ||
      identity.version < 0 ||
      identity.version > 65535 ||
      identity.sourceSymbol != null ||
      identity.form != 0 ||
      identity.sourceMapId != null) {
    _invalid('source_identity',
        'Trainer identities require exact source namespace, type, name and bounded version.');
  }
}

String _catalogHash(NativePsdkCatalog catalog) =>
    canonicalHashOf(catalog.toJson(), limits: nativePsdkCatalogShardJsonLimits)
        .value;

final class _CachedFiles implements SourceFilePort {
  _CachedFiles(this.inner);
  final SourceFilePort inner;
  final _reads = <ConverterId, Future<List<int>>>{};
  @override
  Future<List<int>> read(ConverterId id) => _reads.putIfAbsent(
      id, () async => List<int>.unmodifiable(await inner.read(id)));
}

final class _CompiledTrainer {
  const _CompiledTrainer(this.party, this.items, this.loseText, this.suffix,
      this.offset, this.graphPath, this.error);
  final List<Map<String, Object?>> party;
  final List<String> items;
  final String loseText;
  final String suffix;
  final int offset;
  final String graphPath;
  final String? error;
}

String? _text(MarshalNode? value, MarshalKind kind) =>
    value?.kind == kind ? value!.text().text : null;

int? _number(MarshalNode? value, int maximum) =>
    value?.kind == MarshalKind.integer &&
            value!.integerValue != null &&
            value.integerValue! >= BigInt.zero &&
            value.integerValue! <= BigInt.from(maximum)
        ? value.integerValue!.toInt()
        : null;

Map<String, List<_CompiledTrainer>> _readCompiled(
    List<int> bytes,
    ConverterId namespace,
    NativeTrainerQualificationLimits limits,
    ScanCancellation? cancellation) {
  try {
    final document = const MarshalDecoder().decode(bytes,
        sourcePath: 'Data/trainers.dat',
        limits: MarshalDecodeLimits(
            maxInputBytes: limits.maxCompiledBytes,
            maxTotalLocationCodeUnits: 33554432));
    final root = document.node(document.rootId);
    if (root.kind != MarshalKind.hash ||
        root.defaultValue != null ||
        root.pairs.length > 100000) {
      _invalid('compiled_shape',
          'Compiled trainers require an inert bounded hash of typed trainer objects.');
    }
    List<Object?>? identity(MarshalNode? value) {
      if (value == null ||
          value.kind != MarshalKind.array ||
          value.elements.length != 3) {
        return null;
      }
      final type = _text(document.node(value.elements[0]), MarshalKind.symbol);
      final name = _text(document.node(value.elements[1]), MarshalKind.string);
      final version = _number(document.node(value.elements[2]), 65535);
      if (type == null ||
          type.isEmpty ||
          type.length > 192 ||
          name == null ||
          name.isEmpty ||
          name.length > 192 ||
          version == null) {
        return null;
      }
      return [type, name, version];
    }

    final result = <String, List<_CompiledTrainer>>{};
    for (final pair in root.pairs) {
      cancellation?.check();
      final key = identity(document.node(pair.key));
      if (key == null) {
        _invalid('compiled_identity',
            'Compiled trainer keys require exact bounded type, name and version identities.');
      }
      final sourceIdentity = SourcePbsIdentity(
          namespace: namespace,
          family: SourcePbsFamily.trainers,
          trainerType: key[0] as String,
          trainerName: key[1] as String,
          version: key[2] as int);
      final object = document.node(pair.value);
      if (object.kind != MarshalKind.object ||
          object.className != 'GameData::Trainer') {
        (result[sourceIdentity.key] ??= []).add(_CompiledTrainer(
            const [],
            const [],
            '',
            '',
            object.location.byteOffset,
            object.location.graphPath,
            'compiled_shape'));
        continue;
      }
      final fields = <String, MarshalNode>{};
      String? error;
      for (final field in object.instanceVariables) {
        final name = _text(document.node(field.key), MarshalKind.symbol);
        if (name == null || fields.containsKey(name)) {
          error ??= 'compiled_shape';
          continue;
        }
        fields[name] = document.node(field.value);
      }
      const allowed = {
        '@id',
        '@trainer_type',
        '@real_name',
        '@version',
        '@items',
        '@real_lose_text',
        '@pokemon',
        '@pbs_file_suffix'
      };
      if (!fields.keys.every(allowed.contains)) error ??= 'compiled_override';
      final id = fields['@id'];
      if (id == null ||
          canonicalJsonOf(identity(id)) != canonicalJsonOf(key) ||
          _text(fields['@trainer_type'], MarshalKind.symbol) != key[0] ||
          _text(fields['@real_name'], MarshalKind.string) != key[1] ||
          _number(fields['@version'], 65535) != key[2]) {
        error ??= 'compiled_identity';
      }
      final items = fields['@items'];
      final itemSymbols = <String>[];
      if (items == null ||
          items.kind != MarshalKind.array ||
          items.extensions.isNotEmpty ||
          items.userClass != null ||
          items.instanceVariables.isNotEmpty ||
          items.elements.length >
              trainerBattleItemMaxDistinctCount *
                  trainerBattleItemMaxQuantity) {
        error ??= 'compiled_override';
      } else {
        for (final child in items.elements) {
          final symbol = _text(document.node(child), MarshalKind.symbol);
          if (symbol == null || symbol.isEmpty) {
            error ??= 'compiled_override';
          } else {
            itemSymbols.add(symbol);
          }
        }
      }
      final lose = _text(fields['@real_lose_text'], MarshalKind.string);
      final suffix = _text(fields['@pbs_file_suffix'], MarshalKind.string);
      if (lose == null || suffix == null) {
        error ??= 'compiled_shape';
      }
      final party = fields['@pokemon'];
      final members = <Map<String, Object?>>[];
      if (party?.kind != MarshalKind.array ||
          party!.elements.isEmpty ||
          party.elements.length > 6) {
        error ??= 'member_invalid';
      } else {
        for (final child in party.elements) {
          cancellation?.check();
          final row = document.node(child);
          if (row.kind != MarshalKind.hash || row.defaultValue != null) {
            error ??= 'compiled_shape';
            continue;
          }
          final member = <String, MarshalNode>{};
          for (final field in row.pairs) {
            final name = _text(document.node(field.key), MarshalKind.symbol);
            if (name == null || member.containsKey(name)) {
              error ??= 'compiled_shape';
              continue;
            }
            member[name] = document.node(field.value);
          }
          if (!const [2, 3].contains(member.length) ||
              !member.keys.every({'species', 'level', 'moves'}.contains)) {
            error ??= 'compiled_override';
          }
          final symbol = _text(member['species'], MarshalKind.symbol);
          final level = _number(member['level'], 100);
          if (symbol == null || symbol.isEmpty || level == null || level < 1) {
            error ??= 'member_invalid';
          }
          final moves = <String>[];
          if (member['moves'] case final authored?) {
            if (authored.kind != MarshalKind.array ||
                authored.extensions.isNotEmpty ||
                authored.userClass != null ||
                authored.instanceVariables.isNotEmpty ||
                authored.elements.isEmpty ||
                authored.elements.length > 4) {
              error ??= 'compiled_override';
            } else {
              for (final child in authored.elements) {
                final move = _text(document.node(child), MarshalKind.symbol);
                if (move == null || move.isEmpty || moves.contains(move)) {
                  error ??= 'compiled_override';
                } else {
                  moves.add(move);
                }
              }
            }
          }
          members.add({
            'species': symbol,
            'level': level,
            if (member.containsKey('moves')) 'moves': moves
          });
        }
      }
      (result[sourceIdentity.key] ??= []).add(_CompiledTrainer(
          members,
          itemSymbols,
          lose ?? '',
          suffix ?? '',
          object.location.byteOffset,
          object.location.graphPath,
          error));
    }
    return result;
  } on BinaryDecodeError catch (error) {
    _invalid(
        'compiled_decode', 'Inert trainer decoding failed: ${error.code}.');
  }
}

Never _invalid(String code, String message) =>
    throw ContractError('native_trainer.$code', r'$', message);
