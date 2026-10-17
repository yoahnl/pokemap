import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';

import 'native_encounter_catalog_qualification.dart';

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
    ScanCancellation? cancellation,
  }) async {
    if (ratePolicy == NativeEncounterRatePolicy.unresolved) {
      _invalid('rate_policy_required',
          'Native table probability requires an explicit source base percent adaptation policy.');
    }
    if (source.sourceSnapshotHash != snapshot.canonicalHash ||
        source.logicalProjectNamespace != snapshot.logicalProjectNamespace ||
        source.profile != SourcePbsProfile.essentials21_1 ||
        nativeMapIds.length > 8 ||
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
    final bytes = await files.read(witness.fileId);
    cancellation?.check();
    if (bytes.length != witness.byteLength ||
        crypto.sha256.convert(bytes).toString() != witness.sha256!.value) {
      _invalid('compiled_species_changed',
          'Compiled species bytes differ from the source snapshot.');
    }
    final compiled =
        const MarshalDecoder().decode(bytes, sourcePath: witness.relativePath);
    final root = compiled.node(compiled.rootId);
    final baseSymbols = <String>{};
    String? symbol(MarshalNode? node) =>
        node?.kind == MarshalKind.symbol ? node!.text().text : null;
    if (root.kind != MarshalKind.hash) {
      _invalid('compiled_species',
          'Compiled species requires a typed GameData::Species SET.');
    }
    for (final pair in root.pairs) {
      final key = compiled.node(pair.key), value = compiled.node(pair.value);
      final fields = {
        for (final field in value.instanceVariables)
          symbol(compiled.node(field.key)): compiled.node(field.value)
      };
      final form = fields['@form'];
      final id = symbol(fields['@id']);
      final species = symbol(fields['@species']);
      if (value.kind != MarshalKind.object ||
          value.className != 'GameData::Species' ||
          symbol(key) != id ||
          species == null ||
          form?.kind != MarshalKind.integer ||
          form!.integerValue! < BigInt.zero ||
          (form.integerValue == BigInt.zero &&
              (id != species || !baseSymbols.add(species)))) {
        _invalid('compiled_species',
            'Compiled species SET identities are invalid or ambiguous.');
      }
    }
    final mappings = <String, Map<String, Object?>>{};
    for (final mapping in qualification.sourceMappings) {
      final sourceSymbol = mapping['sourceSymbol'];
      final rawSymbol = mapping['rawNativeDbSymbol'];
      final nativeId = mapping['nativeSpeciesId'];
      final species = native.speciesById[nativeId];
      if (sourceSymbol is! String ||
          rawSymbol is! String ||
          rawSymbol.toUpperCase() != sourceSymbol ||
          mapping['form'] != 0 ||
          mapping['nativeBaseId'] != rawSymbol ||
          species == null ||
          species.id != rawSymbol ||
          species.forms.formId != '0' ||
          species.forms.baseFormId != rawSymbol ||
          mappings.containsKey(sourceSymbol)) {
        _invalid('species_identity',
            'Source symbols require exact attested raw native dbSymbol identities at form zero.');
      }
      mappings[sourceSymbol] = mapping;
    }
    final tables = <ProjectEncounterTable>[];
    final rows = <Map<String, Object?>>[];
    final unqualified = <Map<String, Object?>>[];
    final usedCases = <String>{};
    Map<String, Object?>? fishingOracle;
    final selected = source.entries
        .where((entry) =>
            entry.family == SourcePbsFamily.encounters &&
            nativeMapIds.containsKey(entry.identity?.sourceMapId))
        .toList()
      ..sort((a, b) => a.identity!.key.compareTo(b.identity!.key));
    for (final entry in selected) {
      cancellation?.check();
      final identity = entry.identity!;
      if (entry.isBlocked ||
          source.lookup(identity) == null ||
          identity.version != 0) {
        _invalid('table_identity',
            'Native encounter tables require unique version-zero source entries.');
      }
      final methods = <String, SourcePbsEncounterMethod>{};
      for (final method in entry.methods) {
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
          fishingOracle ??=
              await _readFishingOracle(snapshot, files, cancellation);
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
              sourceSymbol: slot.species);
          final sourceSpecies = source.entries
              .where((entry) => entry.identity?.key == speciesKey.key)
              .singleOrNull;
          if (mapping == null ||
              !baseSymbols.contains(slot.species) ||
              sourceSpecies == null) {
            _invalid('species_identity',
                'Every encounter species requires unique exact native, PBS header and compiled form-zero SET identities: ${slot.species}.');
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
            final key = '$nativeId|0|$level';
            final proof = qualification.wildCases[key];
            if (proof == null || proof['sourceSymbol'] != slot.species) {
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
            'sourceSpeciesHeaderLocator': sourceSpecies.headerLocator.toJson(),
            'nativeSpeciesId': nativeId,
            'nativeForm': 0,
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
            'mappingPolicy': 'formZeroSymbolSetOnlyNoOrdinalMapping'
          },
          'identityPolicy': 'attestedRawNativeDbSymbolUppercaseEqualsPbsSymbol',
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

Future<Map<String, Object?>> _readFishingOracle(SourceSnapshot snapshot,
    SourceFilePort files, ScanCancellation? cancellation) async {
  const hash =
      '3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d';
  final entry = snapshot.entries
      .where((entry) => entry.relativePath == 'Data/Scripts.rxdata')
      .singleOrNull;
  if (entry == null ||
      entry.kind != SourceNodeKind.file ||
      entry.byteLength != 1080290 ||
      entry.sha256?.value != hash) {
    _invalid('fishing_oracle',
        'Native fishing adaptation requires the exact inert source fishing and item-effect oracles.');
  }
  final bytes = await files.read(entry.fileId);
  cancellation?.check();
  if (bytes.length != entry.byteLength ||
      crypto.sha256.convert(bytes).toString() != hash) {
    _invalid('fishing_oracle_changed',
        'Fishing oracle bytes differ from the admitted source archive.');
  }
  return {
    'archive': {
      'fileId': entry.fileId.value,
      'relativePath': entry.relativePath,
      'sha256': hash,
      'byteLength': entry.byteLength
    },
    'scripts': [
      {
        'index': 245,
        'name': 'Overworld_Fishing',
        'uncompressedSha256':
            '0c49fbc54451e9e3e503c33ead66010e93d1a398849a244f4b67cfb0a4490618',
        'lines': [30, 31, 32, 33, 34, 35, 48, 55]
      },
      {
        'index': 264,
        'name': 'Item_Effects',
        'uncompressedSha256':
            '9f5bb1a5663c6ca9d34fc256f577a7918f5def7e76b2426a37116348af0bf1bc',
        'lines': [280, 315]
      },
    ],
    'rodTypes': {'OldRod': 1, 'GoodRod': 2, 'SuperRod': 3},
    'sourceBaseBitePercentFormula': '20 + 25 * rodType',
    'sourcePbsStepChanceUsedForFishing': false,
    'sourceTimingReflexAndAbilityModifiersImported': false,
    'sourceScriptsExecuted': 0,
  };
}
