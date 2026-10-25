import 'dart:convert';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/map_authoring.dart'
    show AuthoringTransactionFaultInjector;
import 'package:map_core/map_core.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../../project_session/data/local_workshop_reader.dart';
import '../domain/pokemon_combat_port.dart';
import 'local_pokemon_transaction.dart';

final class LocalPokemonCombatAdapter
    implements PokemonCombatPort, PokemonCombatReferencePort {
  const LocalPokemonCombatAdapter({
    required this.session,
    required this.mapAdapter,
    this.reader = const LocalProjectFileReader(),
    this.faultInjector,
  });

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final ProjectFileReader reader;
  final AuthoringTransactionFaultInjector? faultInjector;

  @override
  Future<PokemonCombatSnapshot> load() =>
      LocalWorkshopReader(session, reader: reader).read(
        metadataFields: {'pokemon', 'trainers', 'encounterTables', 'facts'},
        operation: (project, _, _) async => PokemonCombatSnapshot(
          project: project,
          maps: const [],
          referencesComplete: false,
        ),
      );

  @override
  Future<PokemonCombatSnapshot> analyzeReferences() => _transaction.analyze(
    (snapshot) async => PokemonCombatSnapshot(
      project: snapshot.manifest,
      maps: List.unmodifiable(snapshot.maps),
    ),
  );

  @override
  Future<void> setRuleset(
    PokemonRulesetProfile before,
    PokemonRulesetProfile after,
  ) => _change(
    current: (snapshot) => snapshot.manifest.pokemon.ruleset.toJson(),
    before: before.toJson(),
    after: after.toJson(),
    action: 'pokemon.ruleset.set',
    parameters: {'profile': after.toJson()},
  );

  @override
  Future<void> saveTable(
    ProjectEncounterTable? before,
    ProjectEncounterTable after,
  ) => _change(
    current: (snapshot) => snapshot.manifest.encounterTables
        .where((value) => value.id == after.id)
        .firstOrNull
        ?.toJson(),
    before: before?.toJson(),
    after: after.toJson(),
    action: 'campaign.encounter_table.upsert',
    parameters: {'value': after.toJson()},
  );

  @override
  Future<void> deleteTable(ProjectEncounterTable before) => _change(
    current: (snapshot) => snapshot.manifest.encounterTables
        .where((value) => value.id == before.id)
        .firstOrNull
        ?.toJson(),
    before: before.toJson(),
    after: null,
    action: 'campaign.encounter_table.delete',
    parameters: {'id': before.id},
  );

  @override
  Future<void> saveTrainer(
    ProjectTrainerEntry? before,
    ProjectTrainerEntry after,
  ) => _change(
    current: (snapshot) => snapshot.manifest.trainers
        .where((value) => value.id == after.id)
        .firstOrNull
        ?.toJson(),
    before: before?.toJson(),
    after: after.toJson(),
    action: 'campaign.trainer.upsert',
    parameters: {'value': after.toJson()},
  );

  @override
  Future<void> deleteTrainer(ProjectTrainerEntry before) => _change(
    current: (snapshot) => snapshot.manifest.trainers
        .where((value) => value.id == before.id)
        .firstOrNull
        ?.toJson(),
    before: before.toJson(),
    after: null,
    action: 'campaign.trainer.delete',
    parameters: {'id': before.id},
  );

  LocalPokemonTransaction get _transaction => LocalPokemonTransaction(
    session: session,
    mapAdapter: mapAdapter,
    reader: reader,
    faultInjector: faultInjector,
  );

  Future<void> _change({
    required Map<String, dynamic>? Function(ProjectSnapshot) current,
    required Map<String, dynamic>? before,
    required Map<String, dynamic>? after,
    required String action,
    required Map<String, Object?> parameters,
  }) async {
    final warning = await _transaction.run(
      actionId: action,
      parameters: parameters,
      allowedStorageKeys: (_) => {'project.json'},
      validateBefore: (snapshot) {
        if (jsonEncode(current(snapshot)) != jsonEncode(before)) {
          throw StateError(
            'Cette fiche a changé sur le disque. Votre brouillon est conservé.',
          );
        }
      },
      validateAfter: (snapshot) {
        if (jsonEncode(current(snapshot)) != jsonEncode(after)) {
          throw StateError('La fiche enregistrée ne correspond pas au reçu.');
        }
      },
    );
    if (warning != null) throw StateError(warning);
  }
}
