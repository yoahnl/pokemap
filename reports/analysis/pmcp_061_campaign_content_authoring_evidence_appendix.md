# PMCP-061 — Contenu intégral des fichiers créés

Cette annexe reproduit intégralement les fichiers texte créés par le lot.

## `packages/map_authoring/lib/src/domains/gameplay/campaign_content_actions.dart`

```dart
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

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    for (final kind in CampaignContentKind.values) ...[
      _descriptor(
        'campaign.${_wireKind(kind)}.upsert',
        'Create or update one ${_wireKind(kind)} campaign definition',
      ),
      _descriptor(
        'campaign.${_wireKind(kind)}.delete',
        'Delete one unreferenced ${_wireKind(kind)} campaign definition',
        risk: AuthoringRiskLevel.high,
      ),
    ],
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
    if (actionId == 'campaign.new_game.update') {
      _rejectUnknown(parameters, const {'newGame'});
      final value =
          ProjectNewGameConfig.fromJson(_object(parameters, 'newGame'));
      before = context.snapshot.manifest.newGame.toJson();
      projected = updateNewGame(context.snapshot.manifest, value);
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
        projected = upsert(context.snapshot.manifest, kind, value);
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

  ProjectManifest upsert(
    ProjectManifest project,
    CampaignContentKind kind,
    Object value,
  ) {
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
    ProjectNewGameConfig newGame,
  ) =>
      _validated(project.copyWith(newGame: newGame));
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
      CampaignContentKind.trainer => ProjectTrainerEntry.fromJson(json),
      CampaignContentKind.character => ProjectCharacterEntry.fromJson(json),
    };

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
```
## `packages/map_authoring/test/domains/gameplay/campaign_content_authoring_test.dart`

```dart
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('campaign content authoring', () {
    test('upsert keeps a trainer identity unique and replaces its payload', () {
      final original = _trainer('lysa', 'Lysa');
      final project = _manifest(trainers: [original]);

      final updated = const CampaignContentActions().upsert(
        project,
        CampaignContentKind.trainer,
        _trainer('lysa', 'Champion Lysa'),
      );

      expect(updated.trainers, hasLength(1));
      expect(updated.trainers.single.name, 'Champion Lysa');
    });

    test('new game update is validated and directly inspectable', () {
      final project = _manifest();
      const newGame = ProjectNewGameConfig(
        enabled: true,
        startMapId: 'start',
        playerName: 'Hero',
      );

      final updated = const CampaignContentActions().updateNewGame(
        project,
        newGame,
      );

      expect(updated.newGame, newGame);
    });

    test('support matrix names every campaign runtime authority', () {
      final report = const CampaignContentInspector().inspect(_manifest());

      expect(
        report.runtimeSupport.map((entry) => entry.domain).toSet(),
        containsAll({
          'moves',
          'abilities',
          'items',
          'trainers',
          'encounterTables',
          'shops',
          'badges',
          'characters',
          'newGame',
        }),
      );
      expect(
        report.runtimeSupport.every(
          (entry) => entry.runtimeAuthority.isNotEmpty,
        ),
        isTrue,
      );
    });

    test('dispatcher exposes CRUD for each embedded campaign family', () {
      final actionIds = AuthoringMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();

      expect(
        actionIds,
        containsAll({
          'campaign.encounter_table.upsert',
          'campaign.shop.upsert',
          'campaign.badge.upsert',
          'campaign.trainer.upsert',
          'campaign.character.upsert',
          'campaign.new_game.update',
        }),
      );
    });
  });
}

ProjectTrainerEntry _trainer(String id, String name) => ProjectTrainerEntry(
      id: id,
      name: name,
      trainerClass: 'Gym Leader',
      team: const [
        ProjectTrainerPokemonEntry(speciesId: 'sproutle', level: 10),
      ],
    );

ProjectManifest _manifest({
  List<ProjectTrainerEntry> trainers = const [],
}) =>
    ProjectManifest(
      name: 'Campaign fixture',
      maps: const [
        ProjectMapEntry(
          id: 'start',
          name: 'Start',
          relativePath: 'maps/start.json',
        ),
      ],
      tilesets: const [],
      trainers: trainers,
    );
```
