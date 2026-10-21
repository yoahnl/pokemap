import 'dart:convert';
import 'dart:typed_data';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';
import 'package:image/image.dart' as image;
import 'native_project_writer.dart';
import 'native_field_machine_learnsets.dart';
import 'native_psdk_trainer_bundle.dart';
import 'native_psdk_catalog.dart';
import 'native_trainer_catalog_bindings.dart';
import 'native_trainer_catalog_qualification.dart';
import 'native_encounter_catalog_bindings.dart';
import 'native_source_species_bindings.dart';

enum SourceCatalogDocumentKind { catalog, species, learnset, evolution, media }

final class SourceCatalogDocument {
  SourceCatalogDocument(
      {required this.kind,
      required this.relativePath,
      required Map<String, Object?> document})
      : document = _freeze(document) as Map<String, Object?>;
  final SourceCatalogDocumentKind kind;
  final String relativePath;
  final Map<String, Object?> document;
  Map<String, Object?> toJson() =>
      {'kind': kind.name, 'relativePath': relativePath, 'document': document};
}

final class SourceCatalogDiagnostic {
  const SourceCatalogDiagnostic(
      {required this.code,
      required this.message,
      required this.blocking,
      this.identityKey,
      this.locator});
  final String code;
  final String message;
  final bool blocking;
  final String? identityKey;
  final SourceLocator? locator;
  Map<String, Object?> toJson() => {
        'code': code,
        'message': message,
        'blocking': blocking,
        'identityKey': identityKey,
        'locator': locator?.toJson()
      };
}

final class SourceCatalogProjectionLimits {
  const SourceCatalogProjectionLimits(
      {this.maxClosureEntries = 4096,
      this.maxNativeDocuments = 2048,
      this.maxCompiledBytes = 8388608,
      this.maxCompiledNodes = 500000,
      this.maxEvidenceCodeUnits = 16777216});
  final int maxClosureEntries;
  final int maxNativeDocuments;
  final int maxCompiledBytes;
  final int maxCompiledNodes;
  final int maxEvidenceCodeUnits;
}

final class SourceCatalogProjection {
  SourceCatalogProjection(
      {List<SourceCatalogDocument> documents = const [],
      this.mergedItemCatalog,
      List<ProjectEncounterTable> encounterTables = const [],
      List<ProjectTrainerEntry> trainers = const [],
      List<NativeArtifact> artifacts = const [],
      List<NativeMutation> assetMutations = const [],
      List<SourceCatalogDiagnostic> diagnostics = const [],
      Map<String, Object?> evidence = const {}})
      : documents = List.unmodifiable(documents),
        encounterTables = List.unmodifiable(encounterTables),
        trainers = List.unmodifiable(trainers),
        artifacts = List.unmodifiable(artifacts),
        assetMutations = List.unmodifiable(assetMutations),
        diagnostics = List.unmodifiable(diagnostics),
        evidence = _freeze(evidence) as Map<String, Object?>;
  final List<SourceCatalogDocument> documents;
  final ProjectItemCatalog? mergedItemCatalog;
  final List<ProjectEncounterTable> encounterTables;
  final List<ProjectTrainerEntry> trainers;
  final List<NativeArtifact> artifacts;
  final List<NativeMutation> assetMutations;
  final List<SourceCatalogDiagnostic> diagnostics;
  final Map<String, Object?> evidence;
  bool get hasBlockingDiagnostics => diagnostics.any((d) => d.blocking);
  List<Map<String, Object?>> restoreSourceEntries(
      {required SourcePbsProject pbs, ScanCancellation? cancellation}) {
    cancellation?.check();
    Never invalid() => throw ContractError(
        'source.catalog.entry_reference',
        r'$',
        'Entry references require the exact PBS source, context and complete entry hash.');
    if (evidence['kind'] != 'sourceCatalogProjection' ||
        evidence['version'] != 2 ||
        evidence['sourceSnapshotHash'] != pbs.sourceSnapshotHash.value ||
        evidence['pbsHash'] != pbs.canonicalHash.value ||
        evidence['namespace'] != pbs.logicalProjectNamespace.value ||
        evidence['profile'] != pbs.profile.name ||
        evidence['entries'] is! List) {
      invalid();
    }
    final references = evidence['entries'] as List;
    if (references.length > 16384) invalid();
    final byLocator = <String, List<SourcePbsEntry>>{};
    for (final entry in pbs.entries) {
      cancellation?.check();
      (byLocator[canonicalJsonOf(entry.headerLocator.toJson())] ??= [])
          .add(entry);
    }
    final restored = <Map<String, Object?>>[];
    for (final row in references) {
      cancellation?.check();
      if (row is! Map<String, Object?> || row['source'] is! Map) invalid();
      final reference = row['source'] as Map;
      if (reference['kind'] != 'sourcePbsEntryReference' ||
          reference['version'] != 1 ||
          reference['headerLocator'] is! Map ||
          reference.length != 5) {
        invalid();
      }
      final candidates = byLocator[canonicalJsonOf(reference['headerLocator'])];
      if (candidates == null) invalid();
      final encoded = canonicalJsonOf(reference);
      final index = candidates.indexWhere(
          (entry) => canonicalJsonOf(_pbsEntryReference(entry)) == encoded);
      if (index < 0) invalid();
      final entry = candidates.removeAt(index);
      restored.add(
          _freeze({...row, 'source': entry.toJson()}) as Map<String, Object?>);
    }
    return List.unmodifiable(restored);
  }

  Map<String, Object?> toJson() => {
        'documents': documents.map((d) => d.toJson()).toList(),
        'mergedItemCatalog': mergedItemCatalog?.toJson(),
        'encounterTables': encounterTables.map((t) => t.toJson()).toList(),
        'trainers': trainers.map((t) => t.toJson()).toList(),
        'artifacts': artifacts.map((a) => a.reference.toJson()).toList(),
        'assetMutations': [
          for (var i = 0; i < assetMutations.length; i++)
            assetMutations[i].toJson(i)
        ],
        'diagnostics': diagnostics.map((d) => d.toJson()).toList(),
        'evidence': evidence
      };
  Sha256Hash get canonicalHash => canonicalHashOf(toJson(),
      limits: const ContractLimits(
          maxNodes: 2000000,
          maxStringCodeUnits: 1048576,
          maxTextCodeUnits: 33554432));
}

Map<String, Object?> _pbsEntryReference(SourcePbsEntry entry) => {
      'kind': 'sourcePbsEntryReference',
      'version': 1,
      'identity': entry.identity?.toJson(),
      'headerLocator': entry.headerLocator.toJson(),
      'canonicalHash': canonicalHashOf(entry.toJson(),
              limits: const ContractLimits(
                  maxNodes: 2000000,
                  maxStringCodeUnits: 65536,
                  maxTextCodeUnits: 33554432))
          .value,
    };

final class SourceCatalogProjector {
  const SourceCatalogProjector();
  Future<SourceCatalogProjection> read(
          {required NormalizedSourceProject source,
          required SourcePbsProject pbs,
          required SourceFilePort files,
          required Map<int, String> nativeMapIds,
          ProjectItemCatalog? existingItemCatalog,
          List<String> requestedItemSymbols = const [],
          List<SourcePbsIdentity> requestedTrainerKeys = const [],
          List<SourcePbsIdentity> nativeTrainerKeys = const [],
          NativePsdkCatalog? nativeTrainerBundle,
          NativeTrainerCatalogQualification? nativeTrainerQualification,
          NativeEncounterCatalogQualification? nativeEncounterQualification,
          NativeEncounterRatePolicy nativeEncounterRatePolicy =
              NativeEncounterRatePolicy.unresolved,
          NativeEncounterFishingRatePolicy nativeEncounterFishingRatePolicy =
              NativeEncounterFishingRatePolicy.unresolved,
          NativeTrainerMovePolicy nativeTrainerMovePolicy =
              NativeTrainerMovePolicy.unresolved,
          SourceCatalogProjectionLimits limits =
              const SourceCatalogProjectionLimits(),
          ScanCancellation? cancellation}) async =>
      _Run(
              source,
              pbs,
              files,
              nativeMapIds,
              existingItemCatalog,
              requestedItemSymbols,
              requestedTrainerKeys,
              nativeTrainerKeys,
              nativeTrainerBundle,
              nativeTrainerQualification,
              nativeTrainerMovePolicy,
              nativeEncounterQualification,
              nativeEncounterRatePolicy,
              nativeEncounterFishingRatePolicy,
              limits,
              cancellation ?? ScanCancellation())
          .read();
}

Object? _freeze(Object? value) => switch (value) {
      Map v => Map<String, Object?>.unmodifiable(
          v.map((k, v) => MapEntry(k as String, _freeze(v)))),
      List v => List<Object?>.unmodifiable(v.map(_freeze)),
      _ => value,
    };

final class _Run {
  _Run(
      this.source,
      this.pbs,
      this.files,
      this.maps,
      this.existing,
      this.items,
      this.trainers,
      this.nativeTrainers,
      this.nativeBundle,
      this.trainerQualification,
      this.nativeMovePolicy,
      this.encounterQualification,
      this.encounterRatePolicy,
      this.encounterFishingRatePolicy,
      this.limits,
      this.cancel);
  final NormalizedSourceProject source;
  final SourcePbsProject pbs;
  final SourceFilePort files;
  final Map<int, String> maps;
  final ProjectItemCatalog? existing;
  final List<String> items;
  final List<SourcePbsIdentity> trainers;
  final List<SourcePbsIdentity> nativeTrainers;
  final NativePsdkCatalog? nativeBundle;
  final NativeTrainerCatalogQualification? trainerQualification;
  final NativeTrainerMovePolicy nativeMovePolicy;
  final NativeEncounterCatalogQualification? encounterQualification;
  final NativeEncounterRatePolicy encounterRatePolicy;
  final NativeEncounterFishingRatePolicy encounterFishingRatePolicy;
  final nativeArtifacts = <NativeArtifact>[];
  final nativeAssetMutations = <NativeMutation>[];
  final SourceCatalogProjectionLimits limits;
  final ScanCancellation cancel;
  final entries = <String, SourcePbsEntry>{};
  final identities = <String, SourcePbsIdentity>{};
  final edges = <String, Set<String>>{};
  final invalid = <String>{};
  final diagnostics = <SourceCatalogDiagnostic>[];
  final documents = <SourceCatalogDocument>[];
  final itemDefinitions = <String, ProjectItemDefinition>{};
  final trainerDefinitions = <String, ProjectTrainerEntry>{};
  final queue = <SourcePbsIdentity>[];
  final dex = <String, int>{};
  final dexOrder = <String>[];
  final defaults = <Map<String, Object?>>[];
  final preservation = <Map<String, Object?>>[];
  Map<String, Object?> dexEvidence = {};
  NativeSourceSpeciesBindingResult? nativeMediaSpeciesBindings;
  ConverterId get namespace => source.snapshot.logicalProjectNamespace;
  SourcePbsIdentity identity(SourcePbsFamily family, String symbol,
          {int form = 0}) =>
      SourcePbsIdentity(
          namespace: namespace,
          family: family,
          sourceSymbol: symbol,
          form: form);
  String id(SourcePbsFamily family, String symbol, {int form = 0}) =>
      family == SourcePbsFamily.items
          ? sourcePbsItemBindingId(namespace, symbol).value
          : identity(family, symbol, form: form).sourceId.value;
  String auxiliaryId(String family, String symbol) =>
      'source-$family-${canonicalHashOf({
            'namespace': namespace.value,
            'family': family,
            'sourceSymbol': symbol
          }).value.substring(0, 24)}';

  Future<SourceCatalogProjection> read() async {
    cancel.check();
    if (nativeBundle is NativePsdkCatalogManifest &&
        encounterQualification != null &&
        canonicalHashOf(nativeBundle!.toJson(),
                limits: nativePsdkCatalogShardJsonLimits) !=
            canonicalHashOf(encounterQualification!.bundle.toJson(),
                limits: nativePsdkCatalogShardJsonLimits)) {
      throw ContractError(
          'native_catalog.encounter_qualification_identity',
          r'$',
          'A composite native catalog requires its exact encounter qualification identity.');
    }
    if ([
          limits.maxClosureEntries,
          limits.maxNativeDocuments,
          limits.maxCompiledBytes,
          limits.maxCompiledNodes,
          limits.maxEvidenceCodeUnits
        ].any((n) => n <= 0) ||
        limits.maxClosureEntries > 16384 ||
        limits.maxNativeDocuments > 16384 ||
        limits.maxCompiledBytes > 16777216 ||
        limits.maxCompiledNodes > 1000000 ||
        limits.maxEvidenceCodeUnits > 33554432) {
      throw ContractError('source.catalog.limits', r'$',
          'Projection limits must be positive and bounded.');
    }
    if (source.snapshot.state != SourceScanState.complete ||
        pbs.sourceSnapshotHash != source.snapshot.canonicalHash ||
        pbs.logicalProjectNamespace != namespace ||
        pbs.profile != SourcePbsProfile.essentials21_1 ||
        maps.keys.any((m) => !source.selectedSourceMapIds.contains(m)) ||
        maps.values.any((v) => v.trim() != v || v.isEmpty) ||
        maps.values.toSet().length != maps.length ||
        trainers.any((t) =>
            t.namespace != namespace || t.family != SourcePbsFamily.trainers)) {
      throw ContractError('source.catalog.binding', r'$',
          'PBS, normalization and selected native maps must share the exact source binding.');
    }
    if (existing != null) {
      existing!.normalized();
      for (final item in existing!.entries) {
        if (itemDefinitions.containsKey(item.id)) {
          throw ContractError('source.catalog.item_duplicate', r'$',
              'Existing item IDs must be unique.');
        }
        itemDefinitions[item.id] = item;
      }
    }
    await _readDex();
    final roots = pbs.entries
        .where((e) =>
            e.family == SourcePbsFamily.encounters &&
            maps.containsKey(e.identity?.sourceMapId))
        .map((e) => e.identity!)
        .toList();
    roots.addAll(trainers);
    roots.addAll(items.map((s) => identity(SourcePbsFamily.items, s)));
    queue.addAll(roots);
    for (var i = 0; i < queue.length; i++) {
      cancel.check();
      final key = queue[i];
      if (identities.containsKey(key.key)) continue;
      identities[key.key] = key;
      if (identities.length > limits.maxClosureEntries) {
        throw ContractError('source.catalog.quota', r'$',
            'Source dependency closure exceeds its entry limit.');
      }
      final entry = pbs.lookup(key);
      if (entry == null) {
        invalid.add(key.key);
        final candidates =
            pbs.entries.where((e) => e.identity?.key == key.key).toList();
        final owner = entries.values
            .where((e) => (edges[e.identity!.key] ?? {}).contains(key.key))
            .firstOrNull;
        final locator =
            candidates.firstOrNull?.headerLocator ?? owner?.headerLocator;
        if (key.family == SourcePbsFamily.trainers &&
            candidates.length == 1 &&
            candidates.single.party.isEmpty) {
          _gap(
              'source.catalog.trainer_incomplete',
              'Source trainer requires a complete nonempty party.',
              key.key,
              true,
              locator);
        }
        _gap(
            'source.catalog.reference_missing',
            'Source reference is missing, duplicated or blocked.',
            key.key,
            true,
            locator);
        continue;
      }
      entries[key.key] = entry;
      _dependencies(entry);
    }
    final sorted = entries.values.toList()
      ..sort((a, b) => a.identity!.key.compareTo(b.identity!.key));
    for (final e in sorted) {
      cancel.check();
      try {
        switch (e.identity!.family) {
          case SourcePbsFamily.species:
            _species(e);
          case SourcePbsFamily.moves:
            _move(e);
          case SourcePbsFamily.items:
            _item(e);
          case SourcePbsFamily.trainers:
            _trainer(e);
          case SourcePbsFamily.types || SourcePbsFamily.abilities:
            _catalogEntry(e);
          case SourcePbsFamily.encounters ||
                SourcePbsFamily.trainerTypes ||
                SourcePbsFamily.forms:
            break;
        }
      } on FormatException catch (error) {
        invalid.add(e.identity!.key);
        _gap('source.catalog.field_unrepresentable', error.message,
            e.identity!.key, true, e.headerLocator);
      } on StateError catch (error) {
        invalid.add(e.identity!.key);
        _gap('source.catalog.field_unrepresentable', error.message.toString(),
            e.identity!.key, true, e.headerLocator);
      }
    }
    _propagateInvalid();
    final validSpecies = sorted
        .where((e) =>
            e.identity!.family == SourcePbsFamily.species &&
            !invalid.contains(e.identity!.key))
        .toList();
    final validNativeIds = {
      for (final e in sorted)
        if (!invalid.contains(e.identity!.key)) e.identity!.sourceId.value
    };
    documents.removeWhere((d) =>
        d.kind != SourceCatalogDocumentKind.catalog &&
        !validNativeIds.contains(d.document['id'] ?? d.document['speciesId']));
    final catalogDocuments = <SourceCatalogDocument>[];
    for (final family in [
      SourcePbsFamily.types,
      SourcePbsFamily.abilities,
      SourcePbsFamily.moves
    ]) {
      final name = family.name;
      final values = [
        for (final entry
            in _catalogRows[family] ?? const <Map<String, Object?>>[])
          if (validNativeIds.contains(entry['id'])) entry
      ];
      values.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
      catalogDocuments.add(SourceCatalogDocument(
          kind: SourceCatalogDocumentKind.catalog,
          relativePath: 'data/pokemon/catalogs/$name.json',
          document: PokemonCatalogFile(
                  schemaVersion: 1,
                  kind: name,
                  catalog: name,
                  meta: const PokemonDataMeta(
                      description:
                          'Source catalog data; execution remains native and unqualified.'),
                  entries:
                      values.map((v) => Map<String, dynamic>.from(v)).toList())
              .toJson()));
    }
    final growth = <String, Map<String, dynamic>>{},
        eggs = <String, Map<String, dynamic>>{};
    for (final e in validSpecies) {
      final f = _fields(e);
      final g = _text(f, 'GrowthRate', 'Medium', e);
      growth[auxiliaryId('growth', g)] = {
        'id': auxiliaryId('growth', g),
        'name': g,
        'source': 'essentials21.1',
        'engineSupportLevel': 'catalogOnly'
      };
      for (final egg in _tokens(f, 'EggGroups')) {
        eggs[auxiliaryId('egg', egg)] = {
          'id': auxiliaryId('egg', egg),
          'name': egg
        };
      }
    }
    for (final pair in [('growth_rates', growth), ('egg_groups', eggs)]) {
      catalogDocuments.add(SourceCatalogDocument(
          kind: SourceCatalogDocumentKind.catalog,
          relativePath: 'data/pokemon/catalogs/${pair.$1}.json',
          document: PokemonCatalogFile(
                  schemaVersion: 1,
                  kind: pair.$1,
                  catalog: pair.$1,
                  meta: const PokemonDataMeta(
                      description:
                          'Source catalog data; execution remains native and unqualified.'),
                  entries: pair.$2.values.toList()
                    ..sort((a, b) =>
                        (a['id'] as String).compareTo(b['id'] as String)))
              .toJson()));
    }
    documents.insertAll(0, catalogDocuments);
    documents.sort((a, b) => a.relativePath.compareTo(b.relativePath));
    if (documents.length > limits.maxNativeDocuments) {
      throw ContractError('source.catalog.quota', r'$',
          'Native document count exceeds its limit.');
    }
    final tables = <ProjectEncounterTable>[];
    for (final e
        in sorted.where((e) => e.family == SourcePbsFamily.encounters)) {
      if (invalid.contains(e.identity!.key)) continue;
      for (final method in _effectiveMethods(e)) {
        final kind = switch (method.name) {
          'Land' ||
          'LandDay' ||
          'LandNight' ||
          'LandMorning' ||
          'Cave' =>
            EncounterKind.walk,
          'Water' => EncounterKind.surf,
          'OldRod' => EncounterKind.oldRod,
          'GoodRod' => EncounterKind.goodRod,
          'SuperRod' => EncounterKind.superRod,
          'HeadbuttLow' || 'HeadbuttHigh' => EncounterKind.headbutt,
          _ => null
        };
        if (kind == null) {
          _gap(
              'source.catalog.encounter_method_preserved',
              'Encounter method has no native data mapping.',
              e.identity!.key,
              false,
              method.locator);
          continue;
        }
        final mapId = e.identity!.sourceMapId!;
        final sourceName =
            source.maps.singleWhere((m) => m.map.sourceMapId == mapId).map.name;
        tables.add(ProjectEncounterTable(
            id: auxiliaryId('encounter', '${e.identity!.key}:${method.name}'),
            name: '$sourceName · ${method.name}',
            encounterKind: kind,
            chancePerStep: 0,
            entries: [
              for (final s in method.slots)
                ProjectEncounterEntry(
                    speciesId: id(SourcePbsFamily.species, s.species),
                    minLevel: s.minimumLevel,
                    maxLevel: s.maximumLevel,
                    weight: s.weight)
            ],
            tags: [
              'source-imported',
              'source-runtime-disabled',
              'source-map:${maps[mapId]}',
              'source-version:${e.identity!.version}'
            ]));
      }
    }
    final itemKeys = identities.values
        .where((i) => i.family == SourcePbsFamily.items)
        .toList();
    final itemConflict = itemKeys.any((i) => invalid.contains(i.key));
    final sourceOnlyData = <String, Object?>{
      'kind': 'sourceCatalogOnlyPreservation',
      'runtimeReady': false,
      'activeReferencesImported': false,
      'documents': documents.map((document) => document.toJson()).toList(),
      'encounterTables': tables.map((table) => table.toJson()).toList(),
      'trainers': [
        for (final entry in sorted)
          if (!invalid.contains(entry.identity!.key) &&
              trainerDefinitions.containsKey(entry.identity!.key))
            trainerDefinitions[entry.identity!.key]!.toJson(),
      ],
    };
    documents.clear();
    final trainerBinding = await _bindNativeTrainers();
    final encounterBinding = encounterQualification == null
        ? null
        : await const NativeEncounterCatalogBindings().bind(
            interpretationProfile: source.interpretationProfile,
            snapshot: source.snapshot,
            source: pbs,
            files: files,
            nativeMapIds: maps,
            sourceMapNames: {
              for (final map in source.maps) map.map.sourceMapId: map.map.name,
            },
            qualification: encounterQualification!,
            ratePolicy: encounterRatePolicy,
            fishingRatePolicy: encounterFishingRatePolicy,
            cancellation: cancel);
    final activeBundle = encounterQualification?.bundle ?? nativeBundle;
    final activeBundleIdentity = activeBundle?.toJson();
    final media = activeBundle == null
        ? const <Map<String, Object?>>[]
        : await _publishNativeBundle(
            activeBundle, trainerBinding?.trainers ?? const []);
    if (activeBundle is NativePsdkCatalogManifest) activeBundle.toJson();
    final nativeBinding = trainerBinding == null
        ? null
        : NativeTrainerCatalogBindingResult(
            trainers: trainerBinding.trainers,
            evidence: {
                ...trainerBinding.evidence,
                'nativeClosureComplete': true,
                'globalLearnsetsPublished': true,
                'globalCatalogComplete': false,
                'conditionalEvolutionExecutionQualified': false,
                'media': media
              });
    final nativeCatalogPublished = activeBundle != null;
    for (final method in encounterBinding?.unqualifiedMethods ??
        const <Map<String, Object?>>[]) {
      _gap(
          'native_encounter.method_unqualified',
          'Source encounter method remains unpublished: ${method['reason']}.',
          canonicalJsonOf(method['sourceIdentity']),
          false,
          null);
    }
    final merged = itemConflict
        ? !nativeCatalogPublished
            ? null
            : existing ??
                const ProjectItemCatalog(schemaVersion: 1, entries: [])
        : ProjectItemCatalog(
            schemaVersion: 1,
            entries: itemDefinitions.values.toList()
              ..sort((a, b) => a.id.compareTo(b.id)));
    sourceOnlyData['mergedItemCatalog'] = merged?.toJson();
    final result = SourceCatalogProjection(
        artifacts: nativeArtifacts,
        assetMutations: nativeAssetMutations,
        documents: documents,
        mergedItemCatalog: !nativeCatalogPublished ? null : merged,
        encounterTables: encounterBinding?.tables ?? const [],
        trainers: nativeBinding?.trainers ?? const [],
        diagnostics: diagnostics,
        evidence: {
          'kind': 'sourceCatalogProjection',
          'version': 2,
          'sourceSnapshotHash': source.snapshot.canonicalHash.value,
          'normalizationHash': source.canonicalHash.value,
          'pbsHash': pbs.canonicalHash.value,
          'profile': pbs.profile.name,
          'namespace': namespace.value,
          'battleAuthority': 'aveluneNative',
          if (activeBundle != null)
            'nativeCatalogIdentity': {
              'canonicalHash': canonicalHashOf(activeBundleIdentity,
                      limits: nativePsdkCatalogShardJsonLimits)
                  .value,
              'sourceWitnessHash': canonicalHashOf(
                      activeBundle.evidence['sources'],
                      limits: nativePsdkCatalogShardJsonLimits)
                  .value,
              if (activeBundle is NativePsdkCatalogManifest)
                'manifest': activeBundleIdentity,
              if (activeBundle.evidence['sourceMoveAdaptations'] != null)
                'sourceMoveAdaptations':
                    activeBundle.evidence['sourceMoveAdaptations'],
              if (activeBundle.evidence['sourceSpeciesAdaptations'] != null)
                'sourceSpeciesAdaptations':
                    activeBundle.evidence['sourceSpeciesAdaptations'],
              'runtimeBattleBuilderQualified': false,
            },
          if (nativeBinding != null)
            'nativeTrainerBindings': nativeBinding.evidence,
          if (nativeMediaSpeciesBindings case final binding?)
            'nativeMediaSpeciesBindings': {
              'evidence': binding.evidence,
              'mappings': binding.rows,
            },
          if (encounterBinding != null)
            'nativeEncounterBindings': {
              ...encounterBinding.evidence,
              'nativeClosureComplete': true,
              'media': media
            },
          'sourceOnlyData': sourceOnlyData,
          'sourceBattleScriptsExecuted': false,
          'sourceAbilitySlotSemanticsQualified': false,
          'runtimeReady': false,
          'sourceScriptsExecuted': 0,
          'aiCalls': 0,
          'nativeMapIds': {
            for (final m in maps.entries) m.key.toString(): m.value
          },
          'nationalDex': dexEvidence,
          'defaults': defaults,
          'preservedFields': preservation,
          'roots': roots.map((r) => r.toJson()).toList(),
          'entries': [
            for (final e in sorted)
              {
                'source': _pbsEntryReference(e),
                'dataImported': !invalid.contains(e.identity!.key),
                'mediaResolved': false,
                'runtimeReady': false,
                'dependentSourceKeys': (edges[e.identity!.key] ?? {}).toList()
                  ..sort()
              }
          ],
          'missingReferences': [
            for (final key in identities.keys)
              if (!entries.containsKey(key)) identities[key]!.toJson()
          ],
          'blockedIdentityKeys': invalid.toList()..sort(),
          'encounters': [
            for (final e
                in sorted.where((e) => e.family == SourcePbsFamily.encounters))
              {
                'identity': e.identity!.toJson(),
                'methods': e.methods.map((m) => m.toJson()).toList(),
                'rateQualified': false,
                'mapBindingEnabled': false
              }
          ],
          'itemCatalogMerge': {
            'preservedExistingIds':
                existing?.entries.map((i) => i.id).toList() ?? [],
            'conflicted': itemConflict,
            'sourceMergeApplied': !itemConflict,
            'nativeCatalogPolicy': !itemConflict
                ? 'sourceMerge'
                : !nativeCatalogPublished
                    ? 'sourceMergeBlocked'
                    : existing == null
                        ? 'initializeEmptyNative'
                        : 'preserveExistingNative',
            'effectsImported': false
          },
          'oracle': {
            'speciesIteration': '129:163-164',
            'nationalNumber': '295:347-370',
            'sourceDefaults': '129:173-218;126:41-57;127:119-137',
            'formInheritance': '396:452-478',
            'abilitySlots': '129:78-79,197-198;396:294-322',
            'nationalDexDisplayOffsetsImported': false
          },
        });
    if (jsonEncode(result.evidence).length > limits.maxEvidenceCodeUnits) {
      throw ContractError('source.catalog.quota', r'$',
          'Projection evidence exceeds its bounded size.');
    }
    return result;
  }

  Future<NativeTrainerCatalogBindingResult?> _bindNativeTrainers() async {
    final qualification = trainerQualification;
    if (qualification != null) {
      final bundle = encounterQualification?.bundle ?? nativeBundle;
      if (bundle == null || nativeMovePolicy != NativeTrainerMovePolicy.nativeAveluneDefaults) {
        throw ContractError('native_trainer.projection_binding', r'$',
            'Qualified trainers require their active native catalog and explicit native defaults policy.');
      }
      await qualification.validateContext(normalizedSource: source,
          source: pbs, files: files, nativeCatalog: bundle,
          requestedTrainers: trainers, cancellation: cancel);
      for (final refusal in qualification.refusals) {
        _gap(refusal.code, refusal.message, refusal.identity.key, false, null);
      }
      return NativeTrainerCatalogBindingResult(
          trainers: qualification.trainers,
          evidence: {
            'kind': 'nativeTrainerQualificationReference',
            'version': 1,
            'qualificationHash': qualification.evidenceHash.value,
            'nativeCatalogHash': qualification.evidence['nativeCatalogHash'],
            'qualifiedTrainerIds': qualification.trainers.map((row) => row.id).toList(),
            'refusals': qualification.refusals.map((row) => row.toJson()).toList(),
            'battleLogic': 'avelune',
          });
    }
    if (nativeTrainers.isNotEmpty) {
      throw ContractError('native_trainer.projection_binding', r'$',
          'Explicit native trainer keys require their exact compiled source qualification.');
    }
    return null;
  }

  Future<List<Map<String, Object?>>> _publishNativeBundle(
      NativePsdkCatalog bundle, List<ProjectTrainerEntry> trainers) async {
    final qualifiedRows = trainerQualification?.rows ?? const [];
    final qualifiedTrainers = <String, List<Object?>>{};
    for (final row in qualifiedRows) {
      final trainer = row['nativeTrainer'] as Map;
      (qualifiedTrainers[trainer['id'] as String] ??= []).add(trainer);
    }
    if (trainers.length != qualifiedRows.length ||
        trainers.map((trainer) => trainer.id).toSet().length !=
            trainers.length ||
        trainers.any((trainer) =>
            qualifiedTrainers[trainer.id]?.length != 1 ||
            canonicalJsonOf(trainer.toJson()) !=
                canonicalJsonOf(qualifiedTrainers[trainer.id]!.single))) {
      throw ContractError('native_trainer.active_qualification_binding', r'$',
          'Every published trainer must exactly match its sealed qualified roster, inventory, abilities and move order.');
    }
    for (final trainer in trainers) {
      for (final member in trainer.team) {
        final species = bundle.speciesById[member.speciesId];
        final learnset = bundle.learnsetsBySpeciesId[member.speciesId];
        if (species == null ||
            learnset == null ||
            member.abilityId != species.abilities.primary ||
            member.moves.any((move) => !bundle.movesById.containsKey(move))) {
          throw ContractError(
              'native_trainer.active_catalog_binding',
              trainer.id,
              'The active native catalogue must exactly cover every qualified trainer member, ability and qualified move.');
        }
      }
    }
    for (final catalog in bundle.catalogs.values) {
      documents.add(SourceCatalogDocument(
          kind: SourceCatalogDocumentKind.catalog,
          relativePath: 'data/pokemon/catalogs/${catalog.catalog}.json',
          document: catalog.toJson()));
    }
    for (final species in bundle.speciesById.values) {
      _doc(SourceCatalogDocumentKind.species, 'species', species.id,
          species.toJson());
      _doc(
          SourceCatalogDocumentKind.learnset,
          'learnsets',
          species.id,
          projectNativeFieldMachineLearnset(
                  bundle.learnsetsBySpeciesId[species.id]!)
              .toJson());
      _doc(SourceCatalogDocumentKind.evolution, 'evolutions', species.id,
          bundle.evolutionsBySpeciesId[species.id]!.toJson());
      _doc(SourceCatalogDocumentKind.media, 'media', species.id,
          bundle.mediaBySpeciesId[species.id]!.toJson());
    }
    final targets = <String>{};
    for (final media in bundle.mediaBySpeciesId.values) {
      for (final variant in media.variants.values) {
        targets.addAll([variant.frontStatic!, variant.backStatic!]);
      }
    }
    final mediaEvidence = <Map<String, Object?>>[];
    final sourceBases = <String>{};
    for (final target in targets) {
      if (bundle.fallbackMedia.containsKey(target)) continue;
      final match =
          RegExp(r'^assets/pokemon/native/([a-z0-9_]+)_(front|back)\.png$')
              .firstMatch(target);
      if (match == null || match[1]!.contains('_form')) {
        throw ContractError('native_trainer.media_binding', target,
            'A native form requires its attested PSDK media.');
      }
      sourceBases.add(match[1]!);
    }
    final byNativeBase = <String, Map<String, Object?>>{};
    String? speciesBindingHash;
    if (sourceBases.isNotEmpty) {
      final binding = await const NativeSourceSpeciesBindings().bindNativeBases(
          snapshot: source.snapshot,
          source: pbs,
          files: files,
          nativeCatalog: bundle,
          requestedNativeBaseIds: sourceBases.toList()..sort(),
          cancellation: cancel);
      nativeMediaSpeciesBindings = binding;
      byNativeBase.addEntries(binding.rows
          .map((row) => MapEntry(row['nativeBaseId'] as String, row)));
      speciesBindingHash = canonicalHashOf(binding.evidence,
              limits: nativePsdkCatalogShardJsonLimits)
          .value;
    }
    var staticMediaOracleVerified = false;
    const staticMediaOraclePath =
        'Plugins/[DBK_009] Animated Pokemon System/[008] Deluxe Bitmap.rb';
    const staticMediaOracleHash =
        'c0d70ca1dad14a6f92307029d5c813094d4c91bd3a7dc72e9fd53218ca2e35a5';
    for (final target in targets.toList()..sort()) {
      cancel.check();
      final fallback = bundle.fallbackMedia[target];
      late List<int> bytes;
      late ConverterId owner;
      late Map<String, Object?> witness;
      if (fallback != null) {
        bytes = base64Decode(fallback['bytesBase64'] as String);
        owner = pbs.documents.first.file.fileId;
        witness = {
          'provider': 'nativePsdkReference',
          'sourcePath': fallback['sourcePath'],
          'sha256': fallback['sha256']
        };
      } else {
        final match =
            RegExp(r'^assets/pokemon/native/([a-z0-9_]+)_(front|back)\.png$')
                .firstMatch(target);
        if (match == null || match[1]!.contains('_form')) {
          throw ContractError('native_trainer.media_binding', target,
              'A native form requires its attested PSDK media.');
        }
        final sourcePath =
            'Graphics/Pokemon/${match[2] == 'front' ? 'Front' : 'Back'}/${byNativeBase[match[1]]!['sourceSymbol']}.png';
        final sourceFile = source.snapshot.entries
            .where((entry) => entry.relativePath == sourcePath)
            .singleOrNull;
        if (sourceFile == null ||
            sourceFile.kind != SourceNodeKind.file ||
            sourceFile.sha256 == null ||
            sourceFile.byteLength > 1048576) {
          throw ContractError('native_trainer.media_missing', sourcePath,
              'Native Pokemon battle media must resolve one bounded exact source image.');
        }
        bytes = await files.read(sourceFile.fileId);
        cancel.check();
        if (bytes.length != sourceFile.byteLength ||
            crypto.sha256.convert(bytes).toString() !=
                sourceFile.sha256!.value) {
          throw ContractError('native_trainer.media_changed', sourcePath,
              'Pokemon media differs from its admitted source witness.');
        }
        owner = sourceFile.fileId;
        witness = {
          'provider': 'essentialsSourceMedia',
          'fileId': owner.value,
          'sourcePath': sourcePath,
          'sourceSymbol': byNativeBase[match[1]]!['sourceSymbol'],
          'nativeBaseId': match[1],
          'sourceSpeciesBindingHash': speciesBindingHash,
          'sha256': sourceFile.sha256!.value
        };
      }
      final decoder = image.PngDecoder();
      final info = decoder.startDecode(Uint8List.fromList(bytes));
      if (info == null ||
          info.width < 1 ||
          info.height < 1 ||
          info.width * info.height > 16777216) {
        throw ContractError('native_trainer.media_dimensions', target,
            'Native media must be a bounded PNG.');
      }
      if (fallback == null && info.width > info.height * 2) {
        if (!staticMediaOracleVerified) {
          final oracle = source.snapshot.entries
              .where((entry) => entry.relativePath == staticMediaOraclePath)
              .singleOrNull;
          if (oracle == null ||
              oracle.kind != SourceNodeKind.file ||
              oracle.byteLength > 65536 ||
              oracle.sha256?.value != staticMediaOracleHash) {
            throw ContractError(
                'native_trainer.media_oracle',
                staticMediaOraclePath,
                'Animated source media requires its exact inert frame-layout oracle.');
          }
          final oracleBytes = await files.read(oracle.fileId);
          cancel.check();
          if (oracleBytes.length != oracle.byteLength ||
              crypto.sha256.convert(oracleBytes).toString() !=
                  staticMediaOracleHash) {
            throw ContractError(
                'native_trainer.media_oracle',
                staticMediaOraclePath,
                'The source frame-layout oracle differs from its admitted bytes.');
          }
          staticMediaOracleVerified = true;
        }
        final decoded = decoder.decodeFrame(0);
        if (decoded == null) {
          throw ContractError('native_trainer.media_decode', target,
              'The source static frame could not be decoded.');
        }
        bytes = image.encodePng(image.copyCrop(
            decoded.convert(format: image.Format.uint8, numChannels: 4),
            x: 0,
            y: 0,
            width: info.height,
            height: info.height));
        witness = {
          ...witness,
          'sourceDimensions': {'width': info.width, 'height': info.height},
          'outputDimensions': {'width': info.height, 'height': info.height},
          'staticFrameIndex': 0,
          'frameLayout': 'horizontalSquareFramesWhenWidthExceedsTwiceHeight',
          'sourcePixelsResampled': false,
          'outputPixelFormat': 'rgba8',
          'animationPlaybackQualified': false,
          'oracle': {
            'path': staticMediaOraclePath,
            'sha256': staticMediaOracleHash,
            'lines': [21, 144, 145, 146, 147, 148, 150, 201, 202, 203, 221, 227]
          }
        };
      }
      final artifact = NativeArtifact(bytes: bytes);
      nativeArtifacts.add(artifact);
      final assetId =
          'native_pokemon_${canonicalHashOf(target).value.substring(0, 24)}';
      nativeAssetMutations.add(NativeMutation(
          operationId: ConverterId('native_trainer_media_${canonicalHashOf({
                'target': target,
                'sha256': artifact.rawSha256.value
              }).value}'),
          actionId: 'asset.import',
          sourceEntityIds: [
            owner
          ],
          targetEntityIds: [
            ConverterId(assetId)
          ],
          parameters: {
            'artifactHandle': artifact.handle,
            'assetId': assetId,
            'logicalPath': target,
            'tags': ['native-pokemon-battle-media'],
            'usages': ['pokemon.battleMedia']
          }));
      mediaEvidence.add({
        ...witness,
        'targetPath': target,
        'artifactHandle': artifact.handle,
        'outputSha256': artifact.rawSha256.value,
        'byteLength': bytes.length
      });
    }
    documents.sort((a, b) => a.relativePath.compareTo(b.relativePath));
    if (documents.length > limits.maxNativeDocuments) {
      throw ContractError('source.catalog.quota', r'$',
          'Native closure exceeds its document limit.');
    }
    return mediaEvidence;
  }

  Future<void> _readDex() async {
    final candidates = source.snapshot.entries
        .where((e) => e.relativePath == 'Data/species.dat')
        .toList();
    if (candidates.length != 1) {
      dexEvidence = {
        'qualified': false,
        'reason': 'compiledSpeciesUnavailable'
      };
      return;
    }
    final entry = candidates.single;
    if (entry.kind != SourceNodeKind.file ||
        entry.sha256 == null ||
        entry.byteLength > limits.maxCompiledBytes) {
      throw ContractError('source.catalog.quota', entry.relativePath,
          'Compiled species witness is unavailable or exceeds its limit.');
    }
    final bytes = await files.read(entry.fileId);
    cancel.check();
    if (bytes.length != entry.byteLength ||
        crypto.sha256.convert(bytes).toString() != entry.sha256!.value) {
      throw ContractError('source.catalog.file_changed', entry.relativePath,
          'Compiled species differs from its inventoried exact bytes.');
    }
    final doc = const MarshalDecoder().decode(bytes,
        sourcePath: entry.relativePath,
        limits: MarshalDecodeLimits(
            maxInputBytes: limits.maxCompiledBytes,
            maxNodes: limits.maxCompiledNodes,
            maxObjects: limits.maxCompiledNodes,
            maxSymbols: 100000,
            maxContainerEntries: limits.maxCompiledNodes,
            maxTotalEntries: limits.maxCompiledNodes * 2));
    final root = doc.node(doc.rootId);
    bool valid = root.kind == MarshalKind.hash;
    if (valid) {
      for (final pair in root.pairs) {
        cancel.check();
        final key = doc.node(pair.key), value = doc.node(pair.value);
        final fields = <String, MarshalNode>{};
        for (final f in value.instanceVariables) {
          fields[_nodeSymbol(doc.node(f.key)) ?? ''] = doc.node(f.value);
        }
        final form = fields['@form'];
        final symbol = _nodeSymbol(fields['@species']);
        if (key.kind != MarshalKind.symbol ||
            value.kind != MarshalKind.object ||
            value.className != 'GameData::Species' ||
            form?.kind != MarshalKind.integer ||
            form!.integerValue! < BigInt.zero ||
            symbol == null ||
            _nodeSymbol(fields['@id']) != _nodeSymbol(key)) {
          valid = false;
          break;
        }
        if (form.integerValue == BigInt.zero) {
          if (symbol != _nodeSymbol(key) || dex.containsKey(symbol)) {
            valid = false;
            break;
          }
          dexOrder.add(symbol);
          dex[symbol] = dexOrder.length;
        }
      }
    }
    if (!valid || dexOrder.isEmpty) {
      dex.clear();
      dexOrder.clear();
    }
    dexEvidence = {
      'qualified': valid && dexOrder.isNotEmpty,
      'scope': 'completeCompiledFormZeroInsertionOrder',
      'fileId': entry.fileId.value,
      'contentHash': entry.sha256!.value,
      'byteLength': entry.byteLength,
      'orderedBaseSymbols': dexOrder,
      'numbers': dex
    };
  }

  String? _nodeSymbol(MarshalNode? node) =>
      node?.kind == MarshalKind.symbol ? node!.text().text : null;
  List<SourcePbsEncounterMethod> _effectiveMethods(SourcePbsEntry e) {
    final last = <String, SourcePbsEncounterMethod>{};
    for (final method in e.methods) {
      last[method.name] = method;
    }
    return last.values.toList();
  }

  List<String> _evolutionTokens(Map<String, SourcePbsField> fields) {
    final values = List<String>.of(fields['Evolutions']?.values ?? const []);
    if (values.length % 3 == 2) values.add('');
    return values;
  }

  void _dependency(SourcePbsEntry owner, SourcePbsIdentity dep) {
    edges.putIfAbsent(owner.identity!.key, () => {}).add(dep.key);
    queue.add(dep);
  }

  void _symbols(SourcePbsEntry e, Map<String, SourcePbsField> fields,
      String field, SourcePbsFamily family) {
    for (final symbol in _tokens(fields, field)) {
      _dependency(e, identity(family, symbol));
    }
  }

  void _dependencies(SourcePbsEntry e) {
    final key = e.identity!;
    switch (key.family) {
      case SourcePbsFamily.species:
        if (key.form > 0) {
          _dependency(e, identity(SourcePbsFamily.species, key.sourceSymbol!));
        }
        if (key.form == 0) {
          for (final form in pbs.entries.where((f) =>
              f.identity?.family == SourcePbsFamily.species &&
              f.identity?.sourceSymbol == key.sourceSymbol &&
              (f.identity?.form ?? 0) > 0)) {
            _dependency(e, form.identity!);
          }
        }
        final f = _fields(e);
        _symbols(e, f, 'Types', SourcePbsFamily.types);
        _symbols(e, f, 'Abilities', SourcePbsFamily.abilities);
        _symbols(e, f, 'HiddenAbilities', SourcePbsFamily.abilities);
        final moves = _tokens(f, 'Moves');
        for (var i = 1; i < moves.length; i += 2) {
          _dependency(e, identity(SourcePbsFamily.moves, moves[i]));
        }
        for (final field in ['TutorMoves', 'EggMoves']) {
          _symbols(e, f, field, SourcePbsFamily.moves);
        }
        for (final field in [
          'WildItemCommon',
          'WildItemUncommon',
          'WildItemRare',
          'Incense'
        ]) {
          _symbols(e, f, field, SourcePbsFamily.items);
        }
        _symbols(e, f, 'Offspring', SourcePbsFamily.species);
        final evos = _evolutionTokens(f);
        for (var i = 0; i + 2 < evos.length; i += 3) {
          _dependency(e, identity(SourcePbsFamily.species, evos[i]));
          if (evos[i + 1] == 'Item') {
            _dependency(e, identity(SourcePbsFamily.items, evos[i + 2]));
          }
          if (evos[i + 1] == 'HasMove') {
            _dependency(e, identity(SourcePbsFamily.moves, evos[i + 2]));
          }
        }
      case SourcePbsFamily.moves:
        final types = _tokens(_fields(e), 'Type');
        for (final type in types.isEmpty ? ['NONE'] : types) {
          _dependency(e, identity(SourcePbsFamily.types, type));
        }
      case SourcePbsFamily.types:
        for (final field in ['Weaknesses', 'Resistances', 'Immunities']) {
          _symbols(e, _fields(e), field, SourcePbsFamily.types);
        }
      case SourcePbsFamily.items:
        _symbols(e, _fields(e), 'Move', SourcePbsFamily.moves);
      case SourcePbsFamily.encounters:
        for (final m in _effectiveMethods(e)) {
          for (final s in m.slots) {
            _dependency(e, identity(SourcePbsFamily.species, s.species));
          }
        }
      case SourcePbsFamily.trainers:
        _dependency(
            e, identity(SourcePbsFamily.trainerTypes, key.trainerType!));
        for (final member in e.party) {
          final tokens = member.headerField.values;
          if (tokens.isEmpty) continue;
          final form =
              int.tryParse(member.field('Form')?.values.singleOrNull ?? '0') ??
                  -1;
          _dependency(
              e, identity(SourcePbsFamily.species, tokens.first, form: form));
          for (final move in member.field('Moves')?.values ?? []) {
            _dependency(e, identity(SourcePbsFamily.moves, move));
          }
          for (final f in [
            ('Item', SourcePbsFamily.items),
            ('Ability', SourcePbsFamily.abilities)
          ]) {
            for (final token in member.field(f.$1)?.values ?? []) {
              _dependency(e, identity(f.$2, token));
            }
          }
        }
      case SourcePbsFamily.abilities ||
            SourcePbsFamily.trainerTypes ||
            SourcePbsFamily.forms:
        break;
    }
  }

  Map<String, SourcePbsField> _fields(SourcePbsEntry e) {
    final base =
        e.identity!.family == SourcePbsFamily.species && e.identity!.form > 0
            ? pbs.lookup(
                identity(SourcePbsFamily.species, e.identity!.sourceSymbol!))
            : null;
    final f = {
      for (final field in base?.fields ?? const <SourcePbsField>[])
        field.key: field
    };
    for (final field in e.fields) {
      if ((field.key == 'Moves' || field.key == 'Evolutions') &&
          field.values.every((v) => v.isEmpty) &&
          base != null) {
        continue;
      }
      f[field.key] = field;
    }
    return f;
  }

  List<String> _tokens(Map<String, SourcePbsField> f, String name) =>
      (f[name]?.values ?? const <String>[]).where((v) => v.isNotEmpty).toList();
  String _text(Map<String, SourcePbsField> f, String name, String fallback,
      SourcePbsEntry e) {
    final field = f[name];
    if (field == null) {
      defaults.add(
          {'identityKey': e.identity!.key, 'field': name, 'value': fallback});
      return fallback;
    }
    if (field.values.length != 1) {
      throw FormatException('$name requires exactly one source token.');
    }
    return field.values.single;
  }

  int _number(Map<String, SourcePbsField> f, String name, int fallback,
      SourcePbsEntry e,
      {int minimum = 0, int maximum = 2147483647}) {
    final value = int.tryParse(_text(f, name, '$fallback', e));
    if (value == null || value < minimum || value > maximum) {
      throw FormatException('$name is outside its representable range.');
    }
    return value;
  }

  void _gap(String code, String message, String key, bool blocking,
          [SourceLocator? locator]) =>
      diagnostics.add(SourceCatalogDiagnostic(
          code: code,
          message: message,
          blocking: blocking,
          identityKey: key,
          locator: locator));
  void _doc(SourceCatalogDocumentKind kind, String directory, String name,
          Map<String, Object?> json) =>
      documents.add(SourceCatalogDocument(
          kind: kind,
          relativePath: 'data/pokemon/$directory/$name.json',
          document: json));

  void _species(SourcePbsEntry e) {
    final key = e.identity!,
        f = _fields(e),
        symbol = key.sourceSymbol!,
        native = key.sourceId.value;
    if (!dex.containsKey(symbol)) {
      invalid.add(key.key);
      _gap(
          'source.catalog.national_dex_unqualified',
          'No exact complete source national order exists for this species.',
          key.key,
          true,
          e.headerLocator);
      return;
    }
    final stats = _tokens(f, 'BaseStats').map(int.tryParse).toList();
    if (stats.length != 6 ||
        stats.any((n) => n == null || n < 1 || n > 65535)) {
      throw const FormatException(
          'Six positive source base stats are required.');
    }
    final abilities = _tokens(f, 'Abilities'),
        hidden = _tokens(f, 'HiddenAbilities');
    if (abilities.isEmpty || abilities.length > 2 || hidden.length > 1) {
      throw const FormatException(
          'Native ability slots cannot represent this source ability list.');
    }
    final nativeAbilities = abilities
        .map((symbol) => id(SourcePbsFamily.abilities, symbol))
        .toSet()
        .toList();
    final hiddenId =
        hidden.isEmpty ? null : id(SourcePbsFamily.abilities, hidden.single);
    final nativeHidden = nativeAbilities.contains(hiddenId) ? null : hiddenId;
    final types = _tokens(f, 'Types').toSet().toList();
    if (types.isEmpty) {
      throw const FormatException('Source types are required.');
    }
    final base = id(SourcePbsFamily.species, symbol);
    final formIds = pbs.entries
        .where((s) =>
            s.identity?.family == SourcePbsFamily.species &&
            s.identity?.sourceSymbol == symbol)
        .map((s) => '${s.identity!.form}')
        .toSet()
        .toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    final learnset =
        PokemonLearnsetFile(speciesId: native, levelUp: _levelUp(e, f), tutor: [
      for (final m in _tokens(f, 'TutorMoves'))
        PokemonLearnsetMoveEntry(
            moveId: id(SourcePbsFamily.moves, m), versionGroup: '')
    ], egg: [
      for (final m in _tokens(f, 'EggMoves'))
        PokemonLearnsetMoveEntry(
            moveId: id(SourcePbsFamily.moves, m), versionGroup: '')
    ]);
    final evo = _evolutions(e, f);
    final media = PokemonMediaFile(
        speciesId: native,
        defaultFormId: '${key.form}',
        variants: {
          for (final form in formIds) form: const PokemonMediaVariant()
        });
    final species = PokemonSpeciesFile(
        id: native,
        slug: native,
        nationalDex: dex[symbol]!,
        names: {'en': _text(f, 'Name', 'Unnamed', e)},
        speciesName: {'en': _text(f, 'Category', '???', e)},
        genIntroduced: _number(f, 'Generation', 0, e),
        typing: PokemonSpeciesTyping(
            types: [for (final t in types) id(SourcePbsFamily.types, t)]),
        baseStats: PokemonSpeciesBaseStats(
            hp: stats[0]!,
            atk: stats[1]!,
            def: stats[2]!,
            spe: stats[3]!,
            spa: stats[4]!,
            spd: stats[5]!,
            bst: stats.fold(0, (sum, v) => sum + v!)),
        abilities: PokemonSpeciesAbilities(
            primary: nativeAbilities[0],
            secondary: nativeAbilities.length > 1 ? nativeAbilities[1] : null,
            hidden: nativeHidden),
        breeding: PokemonSpeciesBreeding(genderRatio: const {}, eggGroups: [
          for (final egg in _tokens(f, 'EggGroups')) auxiliaryId('egg', egg)
        ]),
        progression: PokemonSpeciesProgression(
            growthRateId:
                auxiliaryId('growth', _text(f, 'GrowthRate', 'Medium', e)),
            baseExp: _number(f, 'BaseExp', 100, e),
            catchRate:
                _number(f, 'CatchRate', 255, e, minimum: 1, maximum: 255),
            baseFriendship: _number(f, 'Happiness', 70, e, maximum: 255)),
        forms: PokemonSpeciesForms(
            baseFormId: base,
            isBaseForm: key.form == 0,
            formId: '${key.form}',
            formName: f['FormName']?.values.singleOrNull,
            otherForms: formIds.where((v) => v != '${key.form}').toList()),
        refs: PokemonSpeciesRefs(
            learnset: native, evolution: native, media: native),
        classification:
            const PokemonSpeciesClassification(isEnabledInProject: false),
        dexContent:
            PokemonSpeciesDexContent(flavorText: f['Pokedex']?.rawValue));
    preservation.add({
      'identityKey': key.key,
      'kind': 'sourceAbilitySlots',
      'abilities': abilities,
      'hiddenAbilities': hidden,
      'fields': [
        if (f['Abilities'] != null) f['Abilities']!.toJson(),
        if (f['HiddenAbilities'] != null) f['HiddenAbilities']!.toJson()
      ],
      'sourceAbilitySlotSemanticsQualified': false
    });
    _gap(
        'source.catalog.ability_slot_semantics_unqualified',
        'Native available ability identities are unique; source slot selection and probabilities remain unqualified.',
        key.key,
        false,
        f['Abilities']?.locator ?? e.headerLocator);
    preservation.add({
      'identityKey': key.key,
      'kind': 'unprojectedSpeciesFields',
      'fields': e.fields
          .where((v) => const {
                'GenderRatio',
                'HatchSteps',
                'EVs',
                'WildItemCommon',
                'WildItemUncommon',
                'WildItemRare',
                'Flags',
                'Height',
                'Weight',
                'Offspring'
              }.contains(v.key))
          .map((v) => v.toJson())
          .toList(),
      'nativeBreedingNotQualified': true,
      'nativeClassificationNotSourceObtainability': true,
      'nativeLearnsetVersionGroupUnqualified': true
    });
    _gap(
        'source.catalog.species_execution_disabled',
        'Species data is imported with breeding, growth effects and media execution unqualified.',
        key.key,
        false,
        e.headerLocator);
    _doc(
        SourceCatalogDocumentKind.species, 'species', native, species.toJson());
    _doc(SourceCatalogDocumentKind.learnset, 'learnsets', native,
        learnset.toJson());
    _doc(SourceCatalogDocumentKind.evolution, 'evolutions', native,
        evo.toJson());
    _doc(SourceCatalogDocumentKind.media, 'media', native, media.toJson());
  }

  List<PokemonLearnsetLevelUpEntry> _levelUp(
      SourcePbsEntry e, Map<String, SourcePbsField> f) {
    final moves = _tokens(f, 'Moves');
    if (moves.length.isOdd) {
      throw const FormatException(
          'Source Moves requires ordered level and symbol pairs.');
    }
    final result = <PokemonLearnsetLevelUpEntry>[];
    for (var i = 0; i < moves.length; i += 2) {
      final level = int.tryParse(moves[i]);
      if (level == null || level < 0 || level > 100) {
        throw const FormatException(
            'Source move level is outside native bounds.');
      }
      if (level == 0) {
        preservation.add({
          'identityKey': e.identity!.key,
          'kind': 'evolutionMove',
          'level': 0,
          'sourceMove': moves[i + 1]
        });
        _gap(
            'source.catalog.evolution_move_preserved',
            'Source evolution move has no native level-up-zero slot.',
            e.identity!.key,
            false,
            f['Moves']?.locator);
        continue;
      }
      result.add(PokemonLearnsetLevelUpEntry(
          level: level,
          moveId: id(SourcePbsFamily.moves, moves[i + 1]),
          source: 'essentials21.1',
          versionGroup: ''));
    }
    return result;
  }

  PokemonEvolutionFile _evolutions(
      SourcePbsEntry e, Map<String, SourcePbsField> f) {
    final values = _evolutionTokens(f);
    if (values.length % 3 != 0) {
      throw const FormatException(
          'Evolution source requires target, method and parameter triples.');
    }
    final result = <PokemonEvolutionEntry>[];
    for (var i = 0; i < values.length; i += 3) {
      final method = values[i + 1],
          param = values[i + 2],
          target = id(SourcePbsFamily.species, values[i]);
      if (method == 'Level') {
        final level = int.tryParse(param);
        if (level == null || level < 1 || level > 100) {
          throw const FormatException(
              'Evolution source level is outside native bounds.');
        }
        result.add(PokemonEvolutionEntry(
            targetSpeciesId: target, method: 'level_up', minLevel: level));
      } else {
        result.add(PokemonEvolutionEntry(
            targetSpeciesId: target,
            method: 'conditional',
            conditionText: {'en': '$method($param)'}));
        preservation.add({
          'identityKey': e.identity!.key,
          'kind': 'sourceEvolutionCondition',
          'sourceMethod': method,
          'sourceParameter': param
        });
      }
    }
    return PokemonEvolutionFile(
        speciesId: e.identity!.sourceId.value, evolutions: result);
  }

  final _catalogRows = <SourcePbsFamily, List<Map<String, Object?>>>{};
  void _catalogEntry(SourcePbsEntry e) {
    final f = _fields(e);
    _catalogRows.putIfAbsent(e.family, () => []).add({
      'id': e.identity!.sourceId.value,
      'name': _text(f, 'Name', 'Unnamed', e),
      'source': 'essentials21.1',
      'description': f['Description']?.rawValue,
      'sourceSymbol': e.identity!.sourceSymbol,
      'sourceFields': {for (final field in e.fields) field.key: field.values},
      'engineSupportLevel': 'catalogOnly'
    });
  }

  void _move(SourcePbsEntry e) {
    final f = _fields(e), category = _text(f, 'Category', 'Status', e);
    final nativeCategory = switch (category) {
      'Physical' => PokemonMoveCategory.physical,
      'Special' => PokemonMoveCategory.special,
      'Status' => PokemonMoveCategory.status,
      _ => throw const FormatException(
          'Source move category has no native mapping.')
    };
    final type = _text(f, 'Type', 'NONE', e),
        accuracy = _number(f, 'Accuracy', 100, e, maximum: 100);
    final target = _text(f, 'Target', 'None', e);
    final nativeTarget = switch (target) {
      'NearOther' => PokemonMoveTarget.normal,
      'User' => PokemonMoveTarget.self,
      'NearFoe' => PokemonMoveTarget.adjacentFoe,
      'AllNearFoes' => PokemonMoveTarget.allAdjacentFoes,
      'AllBattlers' => PokemonMoveTarget.all,
      'UserSide' => PokemonMoveTarget.allySide,
      'FoeSide' => PokemonMoveTarget.foeSide,
      'NearAlly' => PokemonMoveTarget.adjacentAlly,
      'UserOrNearAlly' => PokemonMoveTarget.adjacentAllyOrSelf,
      'AllNearOthers' => PokemonMoveTarget.allAdjacent,
      'RandomNearFoe' => PokemonMoveTarget.randomNormal,
      _ => PokemonMoveTarget.scripted
    };
    final move = PokemonMove(
        id: e.identity!.sourceId.value,
        name: _text(f, 'Name', 'Unnamed', e),
        type: id(SourcePbsFamily.types, type),
        source: 'essentials21.1',
        category: nativeCategory,
        target: nativeTarget,
        basePower: _number(f, 'Power', 0, e),
        accuracy: accuracy == 0
            ? const PokemonMoveAccuracy.alwaysHits()
            : PokemonMoveAccuracy.percent(value: accuracy),
        pp: _number(f, 'TotalPP', 5, e),
        priority: _number(f, 'Priority', 0, e, minimum: -128, maximum: 127),
        description: f['Description']?.rawValue ?? '???',
        engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
        unsupportedReasons: [
          'sourceFunctionCodeNotImported:${f['FunctionCode']?.rawValue ?? 'None'}',
          'sourceBattleAuthorityAveluneNative'
        ]);
    _catalogRows
        .putIfAbsent(SourcePbsFamily.moves, () => [])
        .add(move.toJson());
    _gap(
        'source.catalog.move_effect_unqualified',
        'Move catalog data is imported without source function handlers.',
        e.identity!.key,
        false,
        e.headerLocator);
  }

  void _item(SourcePbsEntry e) {
    final f = _fields(e),
        symbol = e.identity!.sourceSymbol!,
        native = id(SourcePbsFamily.items, symbol);
    final pocket = _number(f, 'Pocket', 1, e, minimum: 1, maximum: 8),
        price = _number(f, 'Price', 0, e);
    const pockets = [
      'items',
      'medicine',
      'balls',
      'machines',
      'berries',
      'mail',
      'battle-items',
      'key-items'
    ];
    final candidate = ProjectItemDefinition(
        id: native,
        displayName: _text(f, 'Name', 'Unnamed', e),
        pocketId: pockets[pocket - 1],
        buyPrice: price,
        sellPrice: _number(f, 'SellPrice', price ~/ 2, e),
        description: f['Description']?.rawValue,
        tags: {'source-imported'}).normalized();
    final previous = itemDefinitions[native];
    if (previous != null &&
        (previous.displayName != candidate.displayName ||
            previous.pocketId != candidate.pocketId ||
            previous.buyPrice != candidate.buyPrice ||
            previous.sellPrice != candidate.sellPrice ||
            (candidate.description != null &&
                candidate.description != previous.description))) {
      invalid.add(e.identity!.key);
      _gap(
          'source.catalog.item_binding_conflict',
          'PBS item data conflicts with the existing source-bound AC13 item.',
          e.identity!.key,
          true,
          e.headerLocator);
      return;
    }
    itemDefinitions[native] = previous ?? candidate;
    _gap(
        'source.catalog.item_effect_preserved',
        'Existing native uses are retained; source item handlers are not imported.',
        e.identity!.key,
        false,
        e.headerLocator);
  }

  void _trainer(SourcePbsEntry e) {
    final key = e.identity!;
    if (e.party.isEmpty) {
      invalid.add(key.key);
      _gap(
          'source.catalog.trainer_incomplete',
          'Source trainer requires a complete nonempty party.',
          key.key,
          true,
          e.headerLocator);
      return;
    }
    final team = <ProjectTrainerPokemonEntry>[];
    for (final member in e.party) {
      final unsupported = member.fields
          .where((f) => !const {
                'Moves',
                'Item',
                'Ability',
                'Form',
                'Gender',
                'Shiny'
              }.contains(f.key))
          .toList();
      if (unsupported.isNotEmpty) {
        invalid.add(key.key);
        _gap(
            'source.catalog.trainer_field_unsupported',
            'Source party fields have no native data representation: ${unsupported.map((f) => f.key).join(', ')}.',
            key.key,
            true,
            unsupported.first.locator);
        return;
      }
      final tokens = member.headerField.values;
      final level = tokens.length == 2 ? int.tryParse(tokens[1]) : null;
      if (level == null || level < 1 || level > 100) {
        throw const FormatException(
            'Source trainer party requires a valid species and level pair.');
      }
      final form =
          int.tryParse(member.field('Form')?.values.singleOrNull ?? '0');
      if (form == null || form < 0) {
        throw const FormatException('Source trainer form is invalid.');
      }
      final gender = member.field('Gender')?.values.singleOrNull;
      final nativeGender = switch (gender) {
        null => null,
        'male' || 'Male' || '0' => 'male',
        'female' || 'Female' || '1' => 'female',
        'genderless' => 'genderless',
        _ => throw const FormatException(
            'Source trainer gender cannot be represented.')
      };
      final shiny = member.field('Shiny')?.values.singleOrNull;
      if (shiny != null &&
          !const {'true', 'false', 'TRUE', 'FALSE', '1', '0'}.contains(shiny)) {
        throw const FormatException('Source shiny value is invalid.');
      }
      team.add(ProjectTrainerPokemonEntry(
          speciesId: id(SourcePbsFamily.species, tokens[0], form: form),
          level: level,
          formId: form == 0 ? null : '$form',
          moves: [
            for (final m in member.field('Moves')?.values ?? [])
              id(SourcePbsFamily.moves, m)
          ],
          heldItemId: member.field('Item') == null
              ? null
              : id(SourcePbsFamily.items, member.field('Item')!.values.single),
          abilityId: member.field('Ability') == null
              ? null
              : id(SourcePbsFamily.abilities,
                  member.field('Ability')!.values.single),
          gender: nativeGender,
          shiny: shiny == 'true' || shiny == 'TRUE' || shiny == '1'));
    }
    final type =
        pbs.lookup(identity(SourcePbsFamily.trainerTypes, key.trainerType!));
    trainerDefinitions[key.key] = ProjectTrainerEntry(
        id: key.sourceId.value,
        name: key.trainerName!,
        trainerClass:
            type?.field('Name')?.values.singleOrNull ?? key.trainerType!,
        team: team,
        tags: [
          'source-imported',
          'source-runtime-unbound',
          'source-version:${key.version}'
        ]);
    _gap(
        'source.catalog.trainer_runtime_unbound',
        'Trainer party data is imported without battle, reward or source default generation bindings.',
        key.key,
        false,
        e.headerLocator);
  }

  void _propagateInvalid() {
    final reverse = <String, Set<String>>{};
    for (final edge in edges.entries) {
      for (final dep in edge.value) {
        reverse.putIfAbsent(dep, () => {}).add(edge.key);
      }
    }
    final pending = invalid.toList();
    for (var i = 0; i < pending.length; i++) {
      cancel.check();
      for (final owner in reverse[pending[i]] ?? const <String>{}) {
        if (invalid.add(owner)) {
          pending.add(owner);
          _gap(
              'source.catalog.dependent_unit_blocked',
              'An entire dependent source unit is preserved because a dependency is unavailable.',
              owner,
              true,
              entries[owner]?.headerLocator);
        }
      }
    }
  }
}
