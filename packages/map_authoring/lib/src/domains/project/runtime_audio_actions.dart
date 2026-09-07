import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../assets/asset_store.dart';
import '../assets/tileset_actions.dart';
import '../maps/map_lifecycle_adapter.dart';
import '../maps/semantic_map_action_support.dart';

final class RuntimeAudioActions {
  const RuntimeAudioActions();

  static const mapActionId = 'map.audio.update';
  static const projectActionId = 'project.battle_audio.update';
  static const mapFields = {'musicPath', 'battleMusicPath'};
  static const projectFields = {
    'wildBattleMusicPath',
    'trainerBattleMusicPath',
    'wildVictoryMusicPath',
    'trainerVictoryMusicPath',
    'encounterMusicPath',
    'battleStartSePath',
  };

  static final descriptors = [
    for (final id in [mapActionId, projectActionId])
      AuthoringActionDescriptor(
        id: id,
        version: 1,
        summary: id == mapActionId
            ? 'Set or clear map music and its battle music override'
            : 'Set or clear project battle, victory and encounter audio defaults',
        inputSchemaId: 'pokemap.authoring.$id.input.v1',
        outputSchemaId: 'pokemap.authoring.runtime_audio.output.v1',
        riskLevel: AuthoringRiskLevel.low,
        resourceKinds: [id == mapActionId ? 'map' : 'project', 'asset'],
        capabilityIds: const ['authoring.runtime_audio'],
        requiredPermissions: const [AuthoringPermission.projectWrite],
        guarantees: const [
          AuthoringGuarantee.atomic,
          AuthoringGuarantee.dryRun,
          AuthoringGuarantee.idempotent,
          AuthoringGuarantee.revisionChecked,
          AuthoringGuarantee.undoable,
        ],
        extensions: {
          'parameterNames': id == mapActionId
              ? ['mapId', ...mapFields]
              : projectFields.toList(),
          'omittedFields': 'preserved',
          'nullOrBlankFields': 'cleared',
          'audioReferences': 'imported project asset logical paths',
        },
      ),
  ];

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final isMap = context.request.actionId == mapActionId;
    if (!isMap && context.request.actionId != projectActionId) {
      throw const FormatException('Unsupported runtime audio action.');
    }
    final fields = isMap ? mapFields : projectFields;
    final parameters = VisualLibraryParameters(context.request.parameters);
    parameters.allow({if (isMap) 'mapId', ...fields});
    final bytes =
        context.snapshot.findResourceBytes(assetCatalogResourceIdentity);
    final catalog = bytes == null
        ? AssetCatalog()
        : AssetCatalog.fromJson(
            jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>);
    final patch = <String, Object?>{};
    for (final field in fields) {
      if (!context.request.parameters.containsKey(field)) continue;
      final value = context.request.parameters[field];
      if (value != null && value is! String) {
        throw FormatException('$field must be a string or null.');
      }
      final path = (value as String?)?.trim();
      if (path == null || path.isEmpty) {
        patch[field] = null;
        continue;
      }
      final asset = catalog.findByLogicalPath(path);
      if (!path.startsWith('assets/') ||
          path.contains('\\') ||
          path.split('/').contains('..') ||
          asset == null ||
          !asset.artifact.mediaType.startsWith('audio/')) {
        throw VisualLibraryException(
          'audio.reference_invalid',
          'Select an imported audio asset from this project.',
          details: {'parameter': field, 'path': path},
        );
      }
      patch[field] = path;
    }
    if (patch.isEmpty) {
      throw const FormatException('No audio field was provided.');
    }

    if (!isMap) {
      final manifest = context.snapshot.manifest;
      final previous = manifest.battleAudio;
      final data = {...?previous?.toJson(), ...patch};
      final next = data.values.every((value) => value == null)
          ? null
          : ProjectBattleAudioConfig.fromJson(data);
      return buildVisualManifestDraft(
        context.snapshot,
        manifest.copyWith(battleAudio: next),
        operation: projectActionId,
        path: '/battleAudio',
        before: previous?.toJson(),
        after: next?.toJson(),
      );
    }

    final mapContext =
        SemanticMapActionContext.read(context, allowedParameters: mapFields);
    final before = mapContext.map;
    final metadata =
        MapMetadata.fromJson({...before.mapMetadata.toJson(), ...patch});
    final after = before.copyWith(mapMetadata: metadata);
    MapValidator.validate(after,
        projectDialogueContext: context.snapshot.manifest);
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: [
          AuthoringResourceChange(
            resource: mapContext.resource,
            storageKey: mapContext.storageKey,
            beforeBytes: mapContext.beforeBytes,
            afterBytes: encodeMapAuthoringDocument(after),
          )
        ],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.replace,
            resource: mapContext.resource,
            path: '/mapMetadata',
            before: before.mapMetadata.toJson(),
            after: metadata.toJson(),
          )
        ]),
      ),
      preview: {'operation': mapActionId, 'mapId': before.id, 'audio': patch},
    );
  }
}
