import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';
import '../maps/map_lifecycle_adapter.dart';

enum CampaignContentKind {
  encounterTable,
  shop,
  badge,
  trainer,
  character,
}

enum CampaignRuntimeSupportStatus { supported, partial, unsupported }

final class CampaignRuntimeSupportEntry {
  const CampaignRuntimeSupportEntry({
    required this.domain,
    required this.status,
    required this.runtimeAuthority,
    this.limitations = const [],
  });

  final String domain;
  final CampaignRuntimeSupportStatus status;
  final String runtimeAuthority;
  final List<String> limitations;

  Map<String, Object?> toJson() => {
        'domain': domain,
        'status': status.name,
        'runtimeAuthority': runtimeAuthority,
        'limitations': limitations,
      };
}

final class CampaignContentInspection {
  CampaignContentInspection({
    required Iterable<Map<String, Object?>> diagnostics,
    required Iterable<CampaignRuntimeSupportEntry> runtimeSupport,
  })  : diagnostics = List.unmodifiable(diagnostics),
        runtimeSupport = List.unmodifiable(runtimeSupport);

  final List<Map<String, Object?>> diagnostics;
  final List<CampaignRuntimeSupportEntry> runtimeSupport;

  bool get canPublish => diagnostics.every(
        (diagnostic) => diagnostic['severity'] != 'error',
      );

  Map<String, Object?> toJson() => {
        'canPublish': canPublish,
        'diagnostics': diagnostics,
        'runtimeSupport': [for (final entry in runtimeSupport) entry.toJson()],
      };
}

final class CampaignContentInspector {
  const CampaignContentInspector();

  CampaignContentInspection inspect(ProjectManifest project) {
    final diagnostics = <Map<String, Object?>>[];
    try {
      ProjectValidator.validate(project);
    } on Object catch (error) {
      diagnostics.add({
        'code': 'campaign.project_invalid',
        'severity': 'error',
        'message': 'Campaign content does not pass ProjectValidator.',
        'validationType': error.runtimeType.toString(),
      });
    }
    _diagnoseDuplicateIds(
        'encounterTables', project.encounterTables, diagnostics);
    _diagnoseDuplicateIds('shops', project.shops, diagnostics);
    _diagnoseDuplicateIds('badges', project.badges, diagnostics);
    _diagnoseDuplicateIds('trainers', project.trainers, diagnostics);
    _diagnoseDuplicateIds('characters', project.characters, diagnostics);
    return CampaignContentInspection(
      diagnostics: diagnostics,
      runtimeSupport: const [
        CampaignRuntimeSupportEntry(
          domain: 'moves',
          status: CampaignRuntimeSupportStatus.supported,
          runtimeAuthority:
              'RuntimePokemonDataRepository + map_battle move catalog',
        ),
        CampaignRuntimeSupportEntry(
          domain: 'abilities',
          status: CampaignRuntimeSupportStatus.partial,
          runtimeAuthority: 'map_battle ability effect registry',
          limitations: ['Only registered ability effects execute.'],
        ),
        CampaignRuntimeSupportEntry(
          domain: 'items',
          status: CampaignRuntimeSupportStatus.supported,
          runtimeAuthority:
              'map_gameplay bag/item operations + RuntimeShopService',
        ),
        CampaignRuntimeSupportEntry(
          domain: 'trainers',
          status: CampaignRuntimeSupportStatus.supported,
          runtimeAuthority: 'TrainerBattleRequest + RuntimeBattleSetupMapper',
        ),
        CampaignRuntimeSupportEntry(
          domain: 'encounterTables',
          status: CampaignRuntimeSupportStatus.supported,
          runtimeAuthority: 'PlayableMapGame encounter resolver',
        ),
        CampaignRuntimeSupportEntry(
          domain: 'shops',
          status: CampaignRuntimeSupportStatus.supported,
          runtimeAuthority: 'ShopStateResolver + RuntimeShopService',
        ),
        CampaignRuntimeSupportEntry(
          domain: 'badges',
          status: CampaignRuntimeSupportStatus.supported,
          runtimeAuthority: 'RuntimeBattleRewardResolver + narrative commands',
        ),
        CampaignRuntimeSupportEntry(
          domain: 'characters',
          status: CampaignRuntimeSupportStatus.supported,
          runtimeAuthority: 'RuntimeCharacterRefs + RuntimeManifestTilesets',
        ),
        CampaignRuntimeSupportEntry(
          domain: 'newGame',
          status: CampaignRuntimeSupportStatus.supported,
          runtimeAuthority:
              'createNewGameStateFromProject + PlayableMapGameSessionRuntime',
        ),
      ],
    );
  }
}

final class CampaignContentActions {
  const CampaignContentActions();

  static const maxTrainerBatchSize = 512;
  static const maxEncounterBatchSize = 200;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    for (final kind in CampaignContentKind.values) ...[
      _descriptor(
        'campaign.${_wireKind(kind)}.upsert',
        kind == CampaignContentKind.shop
          ? 'Create or update a shop: value.sellPolicy is listedEntries or catalogPrices; entries support maximumOwnedQuantity and purchaseBonus {itemId, everyQuantity, quantity, maximumOwnedQuantity}. Purchase bonuses fill remaining capacity after a successful purchase.'
          : 'Create or update one ${_wireKind(kind)} campaign definition',
      ),
      _descriptor(
        'campaign.${_wireKind(kind)}.delete',
        'Delete one unreferenced ${_wireKind(kind)} campaign definition',
        risk: AuthoringRiskLevel.high,
      ),
    ],
    _descriptor('campaign.encounter_table.upsert_batch',
      'Create or update 1 to 200 encounter tables atomically with validated variant and catalog references'),
    _descriptor(
      'campaign.trainer.upsert_batch',
      'Create or update a bounded atomic batch of trainer definitions',
    ),
    _descriptor(
      'campaign.defeat_recovery.update',
      'Configure or clear the boolean Fact set atomically by native defeat recovery',
    ),
    _descriptor(
      'campaign.new_game.update',
      'Replace the validated project New Game configuration',
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final actionId = context.request.actionId;
    final parameters = context.request.parameters;
    late final ProjectManifest projected;
    late final String path;
    Object? before;
    Object? after;
    if (actionId == 'campaign.trainer.upsert_batch') {
      final values = _decodeTrainerBatch(parameters);
      before = context.snapshot.manifest.trainers
          .map((value) => value.toJson())
          .toList();
      projected = upsertTrainerBatch(context.snapshot.manifest,
          values: values, itemCatalog: context.snapshot.itemCatalog);
      after = projected.trainers.map((value) => value.toJson()).toList();
      path = '/trainers';
    } else if (actionId == 'campaign.defeat_recovery.update') {
      _rejectUnknown(parameters, const {'defeatRecovery'});
      if (!parameters.containsKey('defeatRecovery')) {
        throw const FormatException('defeatRecovery must be declared, or null to clear.');
      }
      final value = parameters['defeatRecovery'] == null
          ? null
          : ProjectDefeatRecoveryConfig.fromJson(_object(parameters, 'defeatRecovery'));
      before = context.snapshot.manifest.defeatRecovery?.toJson();
      projected = updateDefeatRecovery(context.snapshot.manifest, value);
      after = projected.defeatRecovery?.toJson();
      path = '/defeatRecovery';
    } else if (actionId == 'campaign.new_game.update') {
      _rejectUnknown(parameters, const {'newGame'});
      final value =
          ProjectNewGameConfig.fromJson(_object(parameters, 'newGame'));
      before = context.snapshot.manifest.newGame.toJson();
      projected = updateNewGame(context.snapshot.manifest, value,
          maps: context.snapshot.maps);
      after = projected.newGame.toJson();
      path = '/newGame';
    } else {
      final kind = _kindFromAction(actionId);
      final deleting = actionId.endsWith('.delete');
      _rejectUnknown(
        parameters,
        deleting ? const {'id'} : const {'value'},
      );
      if (deleting) {
        final id = _string(parameters, 'id');
        before = _jsonForId(context.snapshot.manifest, kind, id);
        projected = delete(
          context.snapshot.manifest,
          kind,
          id,
          maps: context.snapshot.maps,
        );
        path = '/${_manifestField(kind)}/$id';
      } else {
        final value = _decode(kind, _object(parameters, 'value'));
        final id = _contentId(value);
        before = _jsonForId(context.snapshot.manifest, kind, id);
        projected = upsert(context.snapshot.manifest, kind, value,
          itemCatalog: context.snapshot.itemCatalog);
        after = _contentJson(value);
        path = '/${_manifestField(kind)}/$id';
      }
    }
    return _projectDraft(
      context.snapshot,
      projected,
      operation: actionId,
      path: path,
      before: before,
      after: after,
      preview: const CampaignContentInspector().inspect(projected).toJson(),
    );
  }

  ProjectManifest updateDefeatRecovery(
    ProjectManifest project,
    ProjectDefeatRecoveryConfig? config,
  ) {
    config?.validate(project.facts);
    return _validated(project.copyWith(defeatRecovery: config));
  }

  ProjectManifest upsert(
    ProjectManifest project,
    CampaignContentKind kind,
    Object value, {
    ProjectItemCatalog? itemCatalog,
  }
  ) {
    if (kind == CampaignContentKind.trainer) {
      ProjectValidator.validateTrainerBallItemReferences(
        [value as ProjectTrainerEntry], itemCatalog: itemCatalog,
      );
      ProjectValidator.validateTrainerBattleItemReferences(
        [value], itemCatalog: itemCatalog,
      );
    }
    final id = _contentId(value);
    final projected = switch (kind) {
      CampaignContentKind.encounterTable => project.copyWith(
          encounterTables: _replaceOrAdd(
            project.encounterTables,
            value as ProjectEncounterTable,
            id,
          ),
        ),
      CampaignContentKind.shop => project.copyWith(
          shops: _replaceOrAdd(project.shops, value as ShopDefinition, id),
        ),
      CampaignContentKind.badge => project.copyWith(
          badges: _replaceOrAdd(project.badges, value as BadgeDefinition, id),
        ),
      CampaignContentKind.trainer => project.copyWith(
          trainers: _replaceOrAdd(
            project.trainers,
            value as ProjectTrainerEntry,
            id,
          ),
        ),
      CampaignContentKind.character => project.copyWith(
          characters: _replaceOrAdd(
            project.characters,
            value as ProjectCharacterEntry,
            id,
          ),
        ),
    };
    return _validated(projected);
  }

  Future<AuthoringMutationDraft> buildEncounterTableBatch(AuthoringPlanningContext context) async {
    final values = _decodeEncounterBatch(context.request.parameters);
    final projected = upsertEncounterTableBatch(context.snapshot.manifest, values: values);
    final species = <PokemonSpeciesFile>[];
    for (final id in {for (final table in values) for (final entry in table.allEntries) entry.speciesId}) {
      final bytes = await context.snapshot.readResourceBytes(pokemonSpeciesResourceIdentity(id));
      if (bytes == null) {
        throw ValidationException('Encounter batch references unavailable species: $id',
          code: 'encounter.species_unavailable', details: {'speciesId': id});
      }
      try {
        species.add(PokemonSpeciesFile.fromJson(Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map)));
      } on Object catch (error) {
        if (error is! FormatException && error is! TypeError && error is! ArgumentError) rethrow;
        throw ValidationException('Encounter batch references an invalid species document: $id',
          code: 'encounter.species_invalid', details: {'speciesId': id});
      }
    }
    Future<Set<String>> catalogIds(String kind) async {
      final bytes = await context.snapshot.readResourceBytes('pokemonCatalog:$kind');
      if (bytes == null) return const {};
      try {
        final catalog = PokemonCatalogFile.fromJson(Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map));
        return {for (final entry in catalog.entries) if (entry['id'] is String) entry['id'] as String};
      } on Object catch (error) {
        if (error is! FormatException && error is! TypeError && error is! ArgumentError) rethrow;
        throw ValidationException('Encounter batch requires a valid $kind catalog.',
          code: 'encounter.batch_catalog_invalid', details: {'catalog': kind});
      }
    }
    final diagnostics = validateEncounterCatalogReferences(encounterTables: values,
      species: species, moveIds: await catalogIds('moves'), abilityIds: await catalogIds('abilities'));
    if (diagnostics.isNotEmpty) {
      throw ValidationException('Encounter batch catalog references are invalid.',
        code: 'encounter.batch_catalog_invalid', details: {'diagnostics': [for (final issue in diagnostics) issue.toJson()]});
    }
    return _projectDraft(context.snapshot, projected,
      operation: context.request.actionId, path: '/encounterTables',
      before: [for (final table in context.snapshot.manifest.encounterTables) table.toJson()],
      after: [for (final table in projected.encounterTables) table.toJson()],
      preview: {'batchSize': values.length, 'atomic': true, 'projectFileWrites': 1,
        'validation': 'projectAndEncounterCatalogReferences'});
  }

  ProjectManifest upsertEncounterTableBatch(ProjectManifest project, {
    required List<ProjectEncounterTable> values,
  }) {
    if (values.isEmpty || values.length > maxEncounterBatchSize) {
      throw const ValidationException('An encounter batch requires 1 to 200 values.', code: 'encounter.batch_invalid');
    }
    final replacements = <String, ProjectEncounterTable>{};
    for (var index = 0; index < values.length; index++) {
      final table = values[index];
      if (table.id.trim() != table.id || replacements.containsKey(table.id)) {
        throw ValidationException('Encounter batch identities must be canonical and unique.',
          code: 'encounter.batch_duplicate_id', details: {'index': index, 'tableId': table.id});
      }
      replacements[table.id] = table;
    }
    final existingIds = project.encounterTables.map((table) => table.id).toSet();
    return _validated(project.copyWith(encounterTables: [
      for (final table in project.encounterTables) replacements[table.id] ?? table,
      for (final table in values) if (!existingIds.contains(table.id)) table,
    ]));
  }

  ProjectManifest upsertTrainerBatch(
    ProjectManifest project, {
    required List<ProjectTrainerEntry> values,
    ProjectItemCatalog? itemCatalog,
  }) {
    if (values.isEmpty || values.length > maxTrainerBatchSize) {
      throw const ValidationException(
          'A trainer batch requires 1 to 512 values.',
          code: 'trainer.batch_invalid');
    }
    final replacements = <String, ProjectTrainerEntry>{};
    for (var index = 0; index < values.length; index++) {
      final trainer = values[index];
      if (replacements.containsKey(trainer.id)) {
        throw ValidationException('Trainer batch identities must be unique.',
            code: 'trainer.batch_duplicate_id',
            details: {'index': index, 'trainerId': trainer.id});
      }
      replacements[trainer.id] = trainer;
    }
    ProjectValidator.validateTrainerBallItemReferences(values,
        itemCatalog: itemCatalog);
    ProjectValidator.validateTrainerBattleItemReferences(values,
        itemCatalog: itemCatalog);
    final existingIds = project.trainers.map((trainer) => trainer.id).toSet();
    return _validated(project.copyWith(trainers: [
      for (final trainer in project.trainers)
        replacements[trainer.id] ?? trainer,
      for (final trainer in values)
        if (!existingIds.contains(trainer.id)) trainer,
    ]));
  }

  ProjectManifest delete(
    ProjectManifest project,
    CampaignContentKind kind,
    String id, {
    Iterable<MapData> maps = const [],
  }) {
    if (_jsonForId(project, kind, id) == null) {
      throw ArgumentError.value(id, 'id', 'is unknown');
    }
    final projected = switch (kind) {
      CampaignContentKind.encounterTable => project.copyWith(
          encounterTables: [
            for (final item in project.encounterTables)
              if (item.id != id) item,
          ],
        ),
      CampaignContentKind.shop => project.copyWith(
          shops: [
            for (final item in project.shops)
              if (item.id != id) item
          ],
        ),
      CampaignContentKind.badge => project.copyWith(
          badges: [
            for (final item in project.badges)
              if (item.id != id) item
          ],
        ),
      CampaignContentKind.trainer => project.copyWith(
          trainers: [
            for (final item in project.trainers)
              if (item.id != id) item
          ],
        ),
      CampaignContentKind.character => project.copyWith(
          characters: [
            for (final item in project.characters)
              if (item.id != id) item,
          ],
        ),
    };
    if (_containsExactString(projected.toJson(), id) ||
        maps.any((map) => _containsExactString(map.toJson(), id))) {
      throw StateError('Campaign content "$id" is still referenced.');
    }
    return _validated(projected);
  }

  ProjectManifest updateNewGame(
    ProjectManifest project,
    ProjectNewGameConfig newGame, {
    Iterable<MapData> maps = const [],
  }) {
    final projected = _validated(project.copyWith(newGame: newGame));
    final recovery = newGame.initialRecoveryPoint;
    if (newGame.enabled && recovery != null) {
      final targets = maps.where((map) => map.id == recovery.mapId);
      if (targets.length != 1) {
        throw const ValidationException(
            'The initial recovery point requires its declared map snapshot.');
      }
      ProjectValidator.validateNewGameInitialRecoveryMap(
          projected, targets.single);
    }
    return projected;
  }
}

AuthoringActionDescriptor _descriptor(
  String id,
  String summary, {
  AuthoringRiskLevel risk = AuthoringRiskLevel.medium,
}) =>
    AuthoringActionDescriptor(
      id: id,
      version: 1,
      summary: summary,
      inputSchemaId: 'pokemap.authoring/$id.input.v1',
      outputSchemaId: 'pokemap.authoring/$id.output.v1',
      riskLevel: risk,
      resourceKinds: const ['project', 'campaignContent'],
      capabilityIds: const ['authoring.gameData.campaign'],
      requiredPermissions: const [AuthoringPermission.projectWrite],
      extensions: {'campaign.encounter_table.upsert', 'campaign.encounter_table.upsert_batch'}.contains(id)
          ? {
              'encounterVariants': encounterVariantAuthoringContract,
              'tableValueField': id.endsWith('_batch') ? 'values[]' : 'value',
              if (id.endsWith('_batch')) ...{
                'batch': const {'minValues': 1, 'maxValues': CampaignContentActions.maxEncounterBatchSize, 'uniqueBy': 'id', 'semantics': 'createOrUpdate', 'atomic': true},
                'values': const {'type': 'array', 'minItems': 1, 'maxItems': CampaignContentActions.maxEncounterBatchSize, 'items': 'ProjectEncounterTable', 'uniqueBy': 'id'},
                'validation': 'projectVariantsFactsAndReferencedSpeciesMovesAbilitiesBeforeWrite',
                'editor': 'notApplicableBulkTransport;StudioAuthorsIndividualTables',
              },
            }
          : id == 'campaign.defeat_recovery.update'
          ? const {
              'defeatRecovery': {
                'field': 'defeatRecovery.recoveredFactId',
                'referenceKind': 'narrativeFact',
                'valueType': 'boolean',
                'value': true,
                'optional': true,
                'clearWithNull': true,
                'atomicWith': 'nativeDefeatRecovery',
                'sceneContinueApplies': false,
              },
            }
          : id == 'campaign.new_game.update'
          ? const {
              'initialFactValuesByAvatarCharacterId': {
                'field': 'newGame.initialFactValuesByAvatarCharacterId',
                'optional': true,
                'type': 'object',
                'keys': 'declaredPlayerAvatarCharacterIds',
                'values': 'mapOfDeclaredTypedNarrativeFacts',
                'valueTypes': ['bool', 'int', 'string'],
                'avatarReference': {'kind': 'projectCharacter', 'declaredChoiceRequired': true},
                'factReference': {'kind': 'narrativeFact', 'declaredTypeRequired': true},
                'unknownReferences': 'rejectBeforeWrite',
                'existingPartyFactId': 'forbidden',
                'runtimeSemantics': 'initializeOnceFromResolvedNewGameAvatar',
                'precedence': ['baseInitialFacts', 'selectedAvatarFacts', 'derivedExistingParty'],
                'omitWhenEmpty': true,
                'recomputeOnOutfitChange': false,
                'recomputeOnSaveRestore': false,
              },
              'initialRecoveryPoint': {
                'field': 'newGame.initialRecoveryPoint',
                'optional': true,
                'type': 'object',
                'required': ['mapId', 'position', 'facing'],
                'additionalProperties': false,
                'mapId': {'referenceKind': 'projectMap', 'sameProject': true},
                'position': {
                  'type': 'integerGridPosition',
                  'min': 0,
                  'bounds': 'declaredMap'
                },
                'facing': ['north', 'south', 'east', 'west'],
                'dimension': 'twoD',
                'runtimeSemantics': 'nativePlayerRecoveryPoint',
                'preservesEntrySpawn': true,
              },
            }
          : const {
        'campaign.trainer.upsert',
        'campaign.trainer.upsert_batch'
      }.contains(id)
          ? {
              if (id == 'campaign.trainer.upsert_batch') ...{
                'batch': {
                  'minValues': 1,
                  'maxValues': CampaignContentActions.maxTrainerBatchSize,
                  'uniqueBy': 'id',
                  'semantics': 'createOrUpdate',
                  'atomic': true,
                },
                'values': {
                  'type': 'array',
                  'minItems': 1,
                  'maxItems': CampaignContentActions.maxTrainerBatchSize,
                  'uniqueBy': 'id'
                },
              },
              'trainerBattleFormat': {
                'field':
                    '${id.endsWith('_batch') ? 'values[]' : 'value'}.battleFormat',
                'values': ['singles', 'doubles'],
                'default': 'singles',
                'doublesTeamSize': {'min': 2, 'max': 6},
                'requiredProfileForDoubles': 'pokemap-standard-v1',
                'activePerSide': {'singles': 1, 'doubles': 2},
                'trainersPerSide': 1,
                'selection': 'explicit',
                'staticEncounterDoubles': false,
              },
              'trainerPokemonStats': {
                'fields': [
                  '${id.endsWith('_batch') ? 'values[]' : 'value'}.team[].natureId',
                  '${id.endsWith('_batch') ? 'values[]' : 'value'}.team[].ivs',
                  '${id.endsWith('_batch') ? 'values[]' : 'value'}.team[].evs'
                ],
                'standard': {
                  'natureId': standardTrainerPokemonNatureId,
                  'ivs': standardTrainerPokemonIvs.toJson(),
                  'evs': standardTrainerPokemonEvs.toJson(),
                },
                'iv': {'min': 0, 'max': 31, 'integer': true},
                'ev': {'min': 0, 'max': 252, 'integer': true, 'totalMax': 510},
                'aiIndependent': true,
                'previewResourceKind': 'trainerPokemonStats',
              },
              'trainerBattleItems': {
                'field':
                    '${id.endsWith('_batch') ? 'values[]' : 'value'}.battleItems',
                'maxDistinctItems': 16,
                'quantity': {'min': 1, 'max': 99, 'integer': true},
                'supportedEffects': ['heal_hp', 'full_restore', 'cure_status'],
                'stockScope': 'perBattle',
              },
              'trainerPokemonBall': {
                'field':
                    '${id.endsWith('_batch') ? 'values[]' : 'value'}.team[].ballItemId',
                'defaultPolicy': 'none',
                'referenceKind': 'itemDefinition',
                'requiredCapability': 'capture',
                'allowedEncounterKindsRestrictPresentation': false,
              },
            }
          : const {},
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.atomic,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
    );

ProjectManifest _validated(ProjectManifest project) {
  ProjectValidator.validate(project);
  return project;
}

List<T> _replaceOrAdd<T>(List<T> values, T replacement, String id) {
  var found = false;
  final result = <T>[];
  for (final value in values) {
    if (_contentId(value as Object) == id) {
      result.add(replacement);
      found = true;
    } else {
      result.add(value);
    }
  }
  if (!found) result.add(replacement);
  return result;
}

Object _decode(CampaignContentKind kind, Map<String, dynamic> json) =>
    switch (kind) {
      CampaignContentKind.encounterTable =>
        ProjectEncounterTable.fromJson(json),
      CampaignContentKind.shop => ShopDefinition.fromJson(json),
      CampaignContentKind.badge => BadgeDefinition.fromJson(json),
      CampaignContentKind.trainer => _trainerFromJson(json),
      CampaignContentKind.character => ProjectCharacterEntry.fromJson(json),
    };

List<ProjectEncounterTable> _decodeEncounterBatch(Map<String, Object?> parameters) {
  final values = parameters['values'];
  if (parameters.length != 1 || values is! List || values.isEmpty ||
      values.length > CampaignContentActions.maxEncounterBatchSize) {
    throw const ValidationException('An encounter batch requires only 1 to 200 values.', code: 'encounter.batch_invalid');
  }
  final decoded = <ProjectEncounterTable>[];
  for (var index = 0; index < values.length; index++) {
    try {
      final value = values[index];
      if (value is! Map) throw const FormatException('An encounter table must be an object.');
      decoded.add(ProjectEncounterTable.fromJson(Map<String, dynamic>.from(value)));
    } on Object catch (error) {
      if (error is! FormatException && error is! TypeError && error is! ArgumentError) rethrow;
      throw ValidationException('The batch contains an invalid encounter table.',
        code: 'encounter.batch_entry_invalid', details: {'index': index});
    }
  }
  return decoded;
}

List<ProjectTrainerEntry> _decodeTrainerBatch(Map<String, Object?> parameters) {
  final values = parameters['values'];
  if (parameters.length != 1 ||
      values is! List ||
      values.isEmpty ||
      values.length > CampaignContentActions.maxTrainerBatchSize) {
    throw const ValidationException(
        'A trainer batch requires only 1 to 512 values.',
        code: 'trainer.batch_invalid');
  }
  final decoded = <ProjectTrainerEntry>[];
  for (var index = 0; index < values.length; index++) {
    final value = values[index];
    try {
      if (value is! Map) {
        throw const FormatException('A trainer must be an object.');
      }
      decoded.add(_trainerFromJson(Map<String, dynamic>.from(value)));
    } on FormatException {
      throw ValidationException('The batch contains an invalid trainer.',
          code: 'trainer.batch_entry_invalid', details: {'index': index});
    } on TypeError {
      throw ValidationException('The batch contains an invalid trainer.',
          code: 'trainer.batch_entry_invalid', details: {'index': index});
    } on ArgumentError {
      throw ValidationException('The batch contains an invalid trainer.',
          code: 'trainer.batch_entry_invalid', details: {'index': index});
    }
  }
  return decoded;
}

ProjectTrainerEntry _trainerFromJson(Map<String, dynamic> json) {
  if (json.containsKey('battleFormat')) {
    try {
      BattleFormat.fromJson(json['battleFormat']);
    } on FormatException {
      throw ValidationException(
        'Trainer battleFormat must be singles or doubles.',
        code: 'trainer.battle_format_invalid',
      );
    }
  }
  final team = json['team'];
  if (team is List) {
    for (var i = 0; i < team.length; i++) {
      final member = team[i];
      if (member is! Map) continue;
      final ballItemId = member['ballItemId'];
      if (ballItemId != null && ballItemId is! String) {
        throw ValidationException(
          'Trainer team[$i].ballItemId must be a string or null',
          code: 'trainer.ball_item_id_invalid',
        );
      }
    }
  }
  return ProjectTrainerEntry.fromJson(json);
}

String _contentId(Object value) => switch (value) {
      ProjectEncounterTable value => value.id,
      ShopDefinition value => value.id,
      BadgeDefinition value => value.id,
      ProjectTrainerEntry value => value.id,
      ProjectCharacterEntry value => value.id,
      _ =>
        throw ArgumentError.value(value, 'value', 'unsupported content type'),
    };

Map<String, Object?> _contentJson(Object value) => switch (value) {
      ProjectEncounterTable value => value.toJson(),
      ShopDefinition value => value.toJson(),
      BadgeDefinition value => value.toJson(),
      ProjectTrainerEntry value => value.toJson(),
      ProjectCharacterEntry value => value.toJson(),
      _ =>
        throw ArgumentError.value(value, 'value', 'unsupported content type'),
    };

Map<String, Object?>? _jsonForId(
  ProjectManifest project,
  CampaignContentKind kind,
  String id,
) {
  final values = switch (kind) {
    CampaignContentKind.encounterTable => project.encounterTables,
    CampaignContentKind.shop => project.shops,
    CampaignContentKind.badge => project.badges,
    CampaignContentKind.trainer => project.trainers,
    CampaignContentKind.character => project.characters,
  };
  for (final value in values) {
    if (_contentId(value) == id) return _contentJson(value);
  }
  return null;
}

CampaignContentKind _kindFromAction(String actionId) {
  for (final kind in CampaignContentKind.values) {
    if (actionId.startsWith('campaign.${_wireKind(kind)}.')) return kind;
  }
  throw ArgumentError.value(
      actionId, 'actionId', 'unsupported campaign action');
}

String _wireKind(CampaignContentKind kind) => switch (kind) {
      CampaignContentKind.encounterTable => 'encounter_table',
      CampaignContentKind.shop => 'shop',
      CampaignContentKind.badge => 'badge',
      CampaignContentKind.trainer => 'trainer',
      CampaignContentKind.character => 'character',
    };

String _manifestField(CampaignContentKind kind) => switch (kind) {
      CampaignContentKind.encounterTable => 'encounterTables',
      CampaignContentKind.shop => 'shops',
      CampaignContentKind.badge => 'badges',
      CampaignContentKind.trainer => 'trainers',
      CampaignContentKind.character => 'characters',
    };

void _diagnoseDuplicateIds(
  String family,
  Iterable<Object> values,
  List<Map<String, Object?>> diagnostics,
) {
  final ids = <String>{};
  for (final value in values) {
    final id = _contentId(value);
    if (!ids.add(id)) {
      diagnostics.add({
        'code': 'campaign.duplicate_id',
        'severity': 'error',
        'path': '/$family/$id',
        'message': 'Duplicate campaign content identity.',
      });
    }
  }
}

bool _containsExactString(Object? value, String target) {
  if (value is String) return value == target;
  if (value is List) {
    return value.any((item) => _containsExactString(item, target));
  }
  if (value is Map) {
    return value.values.any((item) => _containsExactString(item, target));
  }
  return false;
}

Map<String, dynamic> _object(Map<String, Object?> values, String key) {
  final value = values[key];
  if (value is! Map) throw ArgumentError.value(value, key, 'must be an object');
  return Map<String, dynamic>.from(value);
}

String _string(Map<String, Object?> values, String key) {
  final value = values[key];
  if (value is! String || value.trim().isEmpty || value != value.trim()) {
    throw ArgumentError.value(value, key, 'must be a nonblank string');
  }
  return value;
}

void _rejectUnknown(Map<String, Object?> values, Set<String> allowed) {
  final unknown = values.keys.where((key) => !allowed.contains(key)).toList();
  if (unknown.isNotEmpty) {
    throw ArgumentError.value(unknown, 'parameters', 'contains unknown keys');
  }
}

AuthoringMutationDraft _projectDraft(
  ProjectSnapshot snapshot,
  ProjectManifest projected, {
  required String operation,
  required String path,
  Object? before,
  Object? after,
  required Map<String, Object?> preview,
}) {
  final project = AuthoringResourceRef(
    kind: 'project',
    id: 'project',
    revision: snapshot.resourceFingerprints['project'],
  );
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: [
        AuthoringResourceChange(
          resource: project,
          storageKey: 'project.json',
          beforeBytes: snapshot.resourceBytes('project'),
          afterBytes: encodeProjectAuthoringDocument(snapshot, projected),
        ),
      ],
      diff: AuthoringDiff([
        AuthoringDiffEntry(
          operation: operation.endsWith('.delete')
              ? AuthoringDiffOperation.remove
              : before == null
                  ? AuthoringDiffOperation.add
                  : AuthoringDiffOperation.replace,
          resource: project,
          path: path,
          before: before,
          after: after,
        ),
      ]),
    ),
    preview: preview,
  );
}
