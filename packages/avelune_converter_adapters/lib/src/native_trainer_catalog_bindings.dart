import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';

import 'native_psdk_trainer_bundle.dart';

enum NativeTrainerMovePolicy { unresolved, nativeAveluneDefaults }

final class NativeTrainerCatalogBindings {
  const NativeTrainerCatalogBindings();

  NativeTrainerCatalogBindingResult bind({
    required SourcePbsProject source,
    required Iterable<SourcePbsIdentity> requestedTrainers,
    required NativePsdkCatalog native,
    required NativeTrainerMovePolicy movePolicy,
  }) {
    if (movePolicy == NativeTrainerMovePolicy.unresolved) {
      throw ContractError('native_trainer.move_policy_required', r'$',
          'Trainer move selection requires an explicit native policy.');
    }
    final referenceRosters = native.evidence['sourceTrainerRosters'];
    final referenceRoster = native.evidence['sourceRosterFile'];
    if (referenceRosters is! Map || referenceRoster is! Map) {
      throw ContractError('native_trainer.roster_reference', r'$',
          'Native trainer bindings require their exact reference roster members.');
    }
    final requested = requestedTrainers.toList();
    if (requested.length > 64 ||
        requested.map((key) => key.key).toSet().length != requested.length) {
      throw ContractError('native_trainer.request_invalid', r'$',
          'Requested trainer identities must be unique and bounded.');
    }
    final speciesIndex = <String, PokemonSpeciesFile>{};
    for (final species in native.speciesById.values) {
      final symbol = species.id.toUpperCase().replaceAll('_', '');
      if (speciesIndex.containsKey(symbol)) {
        throw ContractError('native_trainer.species_ambiguous', symbol,
            'Native species identities must bind unambiguously.');
      }
      speciesIndex[symbol] = species;
    }
    final trainers = <ProjectTrainerEntry>[];
    final rows = <Map<String, Object?>>[];
    for (final key in requested) {
      if (key.family != SourcePbsFamily.trainers ||
          key.namespace != source.logicalProjectNamespace) {
        throw ContractError('native_trainer.source_identity', r'$',
            'Trainer identities must belong to the exact PBS source.');
      }
      final entry = source.lookup(key);
      if (entry == null || entry.party.isEmpty || entry.party.length > 6) {
        throw ContractError('native_trainer.source_missing', key.key,
            'A unique nonempty source trainer party is required.');
      }
      if (entry.party.any((member) => member.headerField.values.length != 2)) {
        throw ContractError('native_trainer.member_invalid', key.key,
            'Every source member requires exactly one species and level.');
      }
      final rosterKey = '${key.trainerType},${key.trainerName}';
      final reference = key.version == 0 ? referenceRosters[rosterKey] : null;
      final actual = [
        for (final member in entry.party)
          {
            'sourceSpeciesSymbol': member.headerField.values.first,
            'level': int.tryParse(member.headerField.values.last)
          }
      ];
      if (reference != null &&
          canonicalHashOf(actual) != canonicalHashOf(reference)) {
        throw ContractError('native_trainer.roster_changed', key.key,
            'Source trainer members and levels must match the exact qualified native roster.');
      }
      final team = <ProjectTrainerPokemonEntry>[];
      final members = <Map<String, Object?>>[];
      for (final member in entry.party) {
        if (member.fields.isNotEmpty) {
          throw ContractError('native_trainer.party_override', key.key,
              'Authored party overrides require explicit native bindings.');
        }
        final tokens = member.headerField.values;
        final level = tokens.length == 2 ? int.tryParse(tokens[1]) : null;
        final species = tokens.isEmpty ? null : speciesIndex[tokens.first];
        if (species == null || level == null || level < 1 || level > 100) {
          throw ContractError('native_trainer.member_invalid', key.key,
              'Every source member requires an exact native species and level.');
        }
        final learnset = native.learnsetsBySpeciesId[species.id]!;
        final moves = nativeTrainerDefaultMoveIds(learnset, level);
        if (moves.isEmpty ||
            moves.any((id) =>
                !native.movesById.containsKey(id) ||
                native.movesById[id]!.engineSupportLevel ==
                    PokemonMoveEngineSupportLevel.catalogOnly)) {
          throw ContractError('native_trainer.move_closure', key.key,
              'Native defaults must resolve every move without a fallback.');
        }
        team.add(ProjectTrainerPokemonEntry(
            speciesId: species.id,
            level: level,
            moves: moves,
            abilityId: species.abilities.primary));
        members.add({
          'sourceLocator': member.headerField.locator.toJson(),
          'sourceSpeciesSymbol': tokens.first,
          'nativeSpeciesId': species.id,
          'level': level,
          'nativeMoveIds': moves,
          'nativePrimaryAbilityId': species.abilities.primary,
          'nativeSpeciesHash': canonicalHashOf(species.toJson()).value,
          'nativeLearnsetHash': canonicalHashOf(learnset.toJson()).value,
        });
      }
      if (reference == null) {
        throw ContractError('native_trainer.roster_changed', key.key,
            'The requested source trainer has no qualified native reference roster.');
      }
      trainers.add(ProjectTrainerEntry(
          id: key.sourceId.value,
          name: key.trainerName!,
          trainerClass: key.trainerType!,
          team: team,
          tags: const [
            'source-imported',
            'native-roster-bound',
            'runtime-battle-unqualified'
          ]));
      rows.add({
        'sourceIdentity': key.toJson(),
        'sourceLocator': entry.headerLocator.toJson(),
        'nativeTrainerId': key.sourceId.value,
        'members': members
      });
    }
    final actualRoster = source.documents
        .where((document) => document.file.relativePath == 'PBS/trainers.txt')
        .singleOrNull;
    return NativeTrainerCatalogBindingResult(trainers: trainers, evidence: {
      'actualSourceRosterSHA': actualRoster?.file.sha256?.value,
      'referenceRosterSHA': referenceRoster['sha256'],
      'referenceRosterHashMatched':
          actualRoster?.file.sha256?.value == referenceRoster['sha256'],
      'kind': 'nativeTrainerCatalogBindings',
      'version': 1,
      'sourceSnapshotHash': source.sourceSnapshotHash.value,
      'sourcePbsHash': source.canonicalHash.value,
      'sourceFiles': [
        for (final document in source.documents) document.file.toJson()
      ],
      'nativeBundleHash': canonicalHashOf(native.toJson()).value,
      'movePolicy': movePolicy.name,
      'sourceDefaultMovePolicyUsed': false,
      'nativeAbilityPolicy': 'speciesPrimary',
      'nativeStatProfile': 'trainerV0',
      'runtimeBattleBuilderQualified': false,
      'sourceScriptsExecuted': 0,
      'aiCalls': 0,
      'trainers': rows,
    });
  }
}

final class NativeTrainerCatalogBindingResult {
  NativeTrainerCatalogBindingResult({
    required List<ProjectTrainerEntry> trainers,
    required Map<String, Object?> evidence,
  })  : trainers = List.unmodifiable(trainers),
        evidence = Map.unmodifiable(evidence);

  final List<ProjectTrainerEntry> trainers;
  final Map<String, Object?> evidence;
}
