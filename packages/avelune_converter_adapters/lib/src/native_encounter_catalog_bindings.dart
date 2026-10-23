import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';

import 'native_encounter_catalog_qualification.dart';
import 'native_source_species_bindings.dart';

export 'native_encounter_catalog_qualification.dart';

enum NativeEncounterRatePolicy {
  unresolved,
  adaptSourceBasePercentToNativeConstantChance,
}

enum NativeEncounterFishingRatePolicy {
  unresolved,
  adaptSourceBaseFishingBiteChanceToNativeTable,
}

final class NativeEncounterCatalogBindings {
  const NativeEncounterCatalogBindings();

  Future<NativeEncounterCatalogBindingResult> bind({
    required SourceSnapshot snapshot,
    required SourcePbsProject source,
    required SourceFilePort files,
    required Map<int, String> nativeMapIds,
    required NativeEncounterCatalogQualification qualification,
    required NativeEncounterRatePolicy ratePolicy,
    NativeEncounterFishingRatePolicy fishingRatePolicy =
        NativeEncounterFishingRatePolicy.unresolved,
    Map<int, String> sourceMapNames = const {},
    SourceInterpretationProfile? interpretationProfile,
    ScanCancellation? cancellation,
  }) async {
    cancellation?.check();
    if (ratePolicy == NativeEncounterRatePolicy.unresolved) {
      _invalid('rate_policy_required',
          'Native table probability requires an explicit source base percent adaptation policy.');
    }
    if (source.sourceSnapshotHash != snapshot.canonicalHash ||
        source.logicalProjectNamespace != snapshot.logicalProjectNamespace ||
        source.profile != SourcePbsProfile.essentials21_1 ||
        nativeMapIds.length > 2048 ||
        nativeMapIds.keys.any((id) => id < 1) ||
        nativeMapIds.values.any((id) => id.trim().isEmpty || id.length > 192) ||
        !qualification.admitsSourceScope(snapshot, nativeMapIds.keys,
            source: source) ||
        nativeMapIds.values.toSet().length != nativeMapIds.length) {
      _invalid('source_binding',
          'Native encounters require their exact PBS source and bounded selected map identities.');
    }
    final native = qualification.bundle;
    final witness = snapshot.entries
        .where((entry) => entry.relativePath == 'Data/species.dat')
        .singleOrNull;
    if (witness == null ||
        witness.kind != SourceNodeKind.file ||
        witness.sha256 == null ||
        witness.byteLength > 8388608) {
      _invalid('compiled_species',
          'A bounded exact compiled species SET witness is required.');
    }
    final mappings = <String, Map<String, Object?>>{};
    final resolved = await const NativeSourceSpeciesBindings().bind(
        snapshot: snapshot,
        source: source,
        files: files,
        nativeCatalog: native,
        requestedSourceSymbols: qualification.sourceMappings
            .map((row) => row['sourceSymbol'] as String),
        cancellation: cancellation);
    if (canonicalJsonOf(resolved.rows,
                limits: const ContractLimits(
                    maxNodes: 2000000, maxTextCodeUnits: 33554432)) !=
            canonicalJsonOf(qualification.sourceMappings,
                limits: const ContractLimits(
                    maxNodes: 2000000, maxTextCodeUnits: 33554432)) ||
        canonicalJsonOf(resolved.evidence,
                limits: const ContractLimits(
                    maxNodes: 2000000, maxTextCodeUnits: 33554432)) !=
            canonicalJsonOf(qualification.evidence['speciesBindingEvidence'],
                limits: const ContractLimits(
                    maxNodes: 2000000, maxTextCodeUnits: 33554432)) ||
        !qualification.admitsSourceScope(snapshot, nativeMapIds.keys,
            source: source)) {
      _invalid('species_identity',
          'Generic mappings must match fresh exact source identity resolution.');
    }
    mappings.addAll(resolved.mappings);
    final tables = <ProjectEncounterTable>[];
    final rows = <Map<String, Object?>>[];
    final unqualified = <Map<String, Object?>>[
      for (final row in qualification.unqualifiedSourceTables)
        if (nativeMapIds
            .containsKey((row['sourceIdentity'] as Map)['sourceMapId']))
          {...row, 'method': null},
    ];
    final usedCases = <String>{};
    Map<String, Object?>? fishingOracle;
    final selected = source.entries
        .where((entry) =>
            entry.family == SourcePbsFamily.encounters &&
            nativeMapIds.containsKey(entry.identity?.sourceMapId) &&
            entry.identity?.version == 0)
        .toList()
      ..sort((a, b) => a.identity!.key.compareTo(b.identity!.key));
    final seenMaps = <int>{};
    for (final entry in selected) {
      cancellation?.check();
      final identity = entry.identity!;
      if (entry.isBlocked ||
          source.lookup(identity) == null ||
          !seenMaps.add(identity.sourceMapId!)) {
        _invalid('table_identity',
            'Native encounter tables require unique version-zero source entries.');
      }
      final methods = <String, SourcePbsEncounterMethod>{};
      for (final method in entry.methods) {
        if (methods.containsKey(method.name)) {
          _invalid(
              'table_identity', 'Selected encounter methods must be unique.');
        }
        methods[method.name] = method;
      }
      for (final method in methods.values) {
        final kind = switch (method.name) {
          'Land' || 'Cave' => EncounterKind.walk,
          'Water' => EncounterKind.surf,
          'RockSmash' => EncounterKind.special,
          'OldRod' => EncounterKind.oldRod,
          'GoodRod' => EncounterKind.goodRod,
          'SuperRod' => EncounterKind.superRod,
          _ => null,
        };
        final rodType =
            const {'OldRod': 1, 'GoodRod': 2, 'SuperRod': 3}[method.name];
        final isFishing = rodType != null;
        final reason = isFishing &&
                fishingRatePolicy == NativeEncounterFishingRatePolicy.unresolved
            ? 'fishingRateUnqualified'
            : const {'LandDay', 'LandNight', 'LandMorning'}
                    .contains(method.name)
                ? 'sourceTimeConditionUnqualified'
                : kind == null
                    ? 'methodUnqualified'
                    : !isFishing && method.stepChance == null
                        ? 'sourceBaseRateMissing'
                        : null;
        if (reason != null) {
          unqualified.add({
            'sourceIdentity': identity.toJson(),
            'method': method.name,
            'sourceLocator': method.locator.toJson(),
            'reason': reason,
            'published': false
          });
          continue;
        }
        if (isFishing) {
          fishingOracle ??= await _readFishingOracle(
              snapshot, files, interpretationProfile, cancellation);
        }
        final rate = isFishing ? 20 + 25 * rodType : method.stepChance!;
        if (rate < 0 ||
            rate > 100 ||
            method.slots.isEmpty ||
            method.slots.length > 256) {
          _invalid('table_rate',
              'Source base percent and encounter slots must be bounded.');
        }
        final nativeEntries = <ProjectEncounterEntry>[];
        final slotRows = <Map<String, Object?>>[];
        for (final slot in method.slots) {
          final mapping = mappings[slot.species];
          final speciesKey = SourcePbsIdentity(
              namespace: source.logicalProjectNamespace,
              family: SourcePbsFamily.species,
              sourceSymbol: mapping?['sourceBaseSymbol'] as String?,
              form: (mapping?['sourceForm'] as int?) ?? 0);
          final sourceSpecies = source.entries
              .where((entry) => entry.identity?.key == speciesKey.key)
              .singleOrNull;
          if (mapping == null || sourceSpecies == null) {
            _invalid('species_identity',
                'Every encounter species requires unique exact native, PBS header and compiled form identities: ${slot.species}.');
          }
          if (slot.weight <= 0 ||
              slot.minimumLevel < 1 ||
              slot.maximumLevel > 100 ||
              slot.minimumLevel > slot.maximumLevel) {
            _invalid('slot_bounds',
                'Weights must be positive and levels inclusive within native bounds.');
          }
          final nativeId = mapping['nativeSpeciesId'] as String;
          final keys = <String>[];
          for (var level = slot.minimumLevel;
              level <= slot.maximumLevel;
              level++) {
            final key =
                '${mapping['nativeBaseId']}|${mapping['nativeForm']}|$level';
            final proof = qualification.wildCases[key];
            if (proof == null ||
                !(proof['sourceSymbols'] as List).contains(slot.species)) {
              _invalid('tuple_unqualified',
                  'An inclusive encounter level has no exact qualified native defaults: $key');
            }
            usedCases.add(key);
            keys.add(key);
          }
          final species = native.speciesById[nativeId]!;
          nativeEntries.add(ProjectEncounterEntry(
              speciesId: nativeId,
              minLevel: slot.minimumLevel,
              maxLevel: slot.maximumLevel,
              weight: slot.weight,
              pokemonOverrides: ProjectEncounterPokemonOverrides(
                  abilityId: species.abilities.primary)));
          slotRows.add({
            'sourceLocator': slot.locator.toJson(),
            'sourceSpeciesSymbol': slot.species,
            'sourceSpeciesHeaderLocator': mapping['sourceLocator'],
            'sourceSpeciesMapping': mapping,
            'nativeSpeciesId': nativeId,
            'nativeForm': mapping['nativeForm'],
            'minLevel': slot.minimumLevel,
            'maxLevel': slot.maximumLevel,
            'weight': slot.weight,
            'qualifiedSpeciesLevelKeys': keys
          });
        }
        final tableId = 'source-native-encounter-${canonicalHashOf({
              'sourceIdentity': identity.toJson(),
              'method': method.name
            }).value.substring(0, 24)}';
        tables.add(ProjectEncounterTable(
            id: tableId,
            name:
                '${sourceMapNames[identity.sourceMapId] ?? nativeMapIds[identity.sourceMapId]} · ${method.name}',
            encounterKind: kind!,
            chancePerStep: rate / 100,
            entries: nativeEntries,
            tags: [
              'source-imported',
              'native-defaults-qualified',
              'source-map:${nativeMapIds[identity.sourceMapId]}',
              'source-method:${method.name}',
              'source-version:0',
              isFishing
                  ? 'source-base-fishing-bite-chance-adapted'
                  : 'source-base-percent-adapted'
            ]));
        rows.add({
          'sourceIdentity': identity.toJson(),
          'sourceLocator': method.locator.toJson(),
          'method': method.name,
          'nativeMapId': nativeMapIds[identity.sourceMapId],
          'nativeTableId': tableId,
          'sourcePbsStepChance': method.stepChance,
          'sourceBasePercent': isFishing ? null : rate,
          'nativeBasePercent': rate,
          'ratePolicy': isFishing ? fishingRatePolicy.name : ratePolicy.name,
          'nativeConstantChance': rate / 100,
          'encounterKind': kind.name,
          'entries': slotRows
        });
      }
    }
    if (!qualification.admitsSourceScope(snapshot, nativeMapIds.keys,
        source: source)) {
      _invalid(
          'source_binding', 'The source changed while binding encounters.');
    }
    return NativeEncounterCatalogBindingResult(
        tables: tables,
        unqualifiedMethods: unqualified,
        evidence: {
          'kind': 'nativeEncounterCatalogBindings',
          'version': 1,
          'sourceSnapshotHash': snapshot.canonicalHash.value,
          'sourcePbsHash': source.canonicalHash.value,
          'qualification': qualification.evidence,
          'compiledSpeciesWitness': {
            'fileId': witness.fileId.value,
            'relativePath': witness.relativePath,
            'sha256': witness.sha256!.value,
            'byteLength': witness.byteLength,
            'mappingPolicy': 'exactCompiledPbsNativeNameAndFormEvidence'
          },
          'identityPolicy': 'freshExactSourceSpeciesBindings',
          'movePolicy': 'nativeAveluneDefaultsAtEveryInclusiveLevel',
          'nativeAbilityPolicy': 'speciesPrimary',
          'sourceSpeciesFieldDataUsed': false,
          'ratePolicy': ratePolicy.name,
          'fishingRatePolicy': fishingRatePolicy.name,
          if (fishingOracle != null) 'fishingOracle': fishingOracle,
          'sourceFishingTimingAndModifiersQualified': false,
          'weightPolicy': 'positiveIntegerRelativeWeightsPreserved',
          'qualifiedSpeciesLevelKeys': usedCases.toList()..sort(),
          'tables': rows,
          'tableIdsBySourceMethod': {
            for (final mapId in nativeMapIds.keys)
              mapId.toString(): {
                for (final row in rows)
                  if ((row['sourceIdentity'] as Map)['sourceMapId'] == mapId)
                    row['method'] as String: row['nativeTableId'],
              }
          },
          'unqualifiedMethods': unqualified,
          'terrainConsumersQualified': false,
          'fieldConsumersQualified': false,
          'sourceCadenceParityQualified': false,
          'runtimeBattleBuilderQualified': false,
          'sourceScriptsExecuted': 0,
          'aiCalls': 0,
        });
  }
}

final class NativeEncounterCatalogBindingResult {
  NativeEncounterCatalogBindingResult(
      {required List<ProjectEncounterTable> tables,
      required List<Map<String, Object?>> unqualifiedMethods,
      required Map<String, Object?> evidence})
      : tables = List.unmodifiable(tables),
        unqualifiedMethods = List.unmodifiable(unqualifiedMethods),
        evidence = Map.unmodifiable(evidence);
  final List<ProjectEncounterTable> tables;
  final List<Map<String, Object?>> unqualifiedMethods;
  final Map<String, Object?> evidence;
  Map<int, Map<String, String>> get tableIdsBySourceMethod => Map.unmodifiable({
        for (final entry in (evidence['tableIdsBySourceMethod'] as Map).entries)
          int.parse(entry.key as String): Map<String, String>.unmodifiable(
              Map<String, String>.from(entry.value as Map)),
      });
}

Never _invalid(String code, String message) =>
    throw ContractError('native_encounter.$code', r'$', message);

Future<Map<String, Object?>> _readFishingOracle(
    SourceSnapshot snapshot,
    SourceFilePort files,
    SourceInterpretationProfile? profile,
    ScanCancellation? cancellation) async {
  const roles = ['encounters.Overworld_Fishing', 'encounters.Item_Effects'];
  if (profile == null ||
      !profile.supports('encounters') ||
      roles.any((role) => !profile.sections.containsKey(role))) {
    _invalid('fishing_oracle',
        'Native fishing adaptation requires explicit source fishing and item-effect witnesses.');
  }
  await profile.verifySource(
      snapshot: snapshot, files: files, cancellation: cancellation);
  final entry = snapshot.entries.singleWhere(
      (entry) => entry.relativePath == profile.scriptsRelativePath);
  return {
    'archive': {
      'fileId': entry.fileId.value,
      'relativePath': entry.relativePath,
      'sha256': profile.scriptsArchiveHash.value,
      'byteLength': entry.byteLength
    },
    'scripts': [
      for (final role in roles)
        {
          'index': profile.sections[role]!['index'],
          'name': profile.sections[role]!['name'] ?? role.substring(11),
          'uncompressedSha256': profile.sections[role]!['sha256'],
          if (profile.sections[role]!.containsKey('lines'))
            'lines': profile.sections[role]!['lines'],
        }
    ],
    'rodTypes': {'OldRod': 1, 'GoodRod': 2, 'SuperRod': 3},
    'sourceBaseBitePercentFormula': '20 + 25 * rodType',
    'sourcePbsStepChanceUsedForFishing': false,
    'sourceTimingReflexAndAbilityModifiersImported': false,
    'sourceScriptsExecuted': 0,
  };
}
