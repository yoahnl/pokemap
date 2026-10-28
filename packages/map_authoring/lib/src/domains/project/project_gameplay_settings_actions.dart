import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../assets/project_media_store.dart';
import '../assets/asset_store.dart';

final class FieldAbilityConfigurationActions {
  const FieldAbilityConfigurationActions();

  static final descriptor = _descriptor(
    'field_ability.configure',
    'fieldAbilityConfiguration',
    'Enable or disable one field ability for this game without changing saved progression',
    ['abilityId', 'enabled'],
  );

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = context.request.parameters;
    if (parameters.length != 2 ||
        parameters['abilityId'] is! String ||
        parameters['enabled'] is! bool) {
      throw const FormatException('Expected abilityId and enabled only.');
    }
    final matches = FieldAbility.values
        .where((ability) => ability.moveId == parameters['abilityId']);
    if (matches.isEmpty) throw const FormatException('Unknown field ability.');
    final ability = matches.single;
    final enabled = parameters['enabled']! as bool;
    final manifest = context.snapshot.manifest;
    if (ability == FieldAbility.surf) {
      final surf = manifest.settings.surf ?? const ProjectSurfSettings();
      final configured = ProjectSurfSettings(
          enabled: enabled,
          requiresKnownMove: surf.requiresKnownMove,
          accessMode: surf.accessMode,
          condition: surf.condition,
          speedCellsPerSecond: surf.speedCellsPerSecond);
      return _settingsDraft(
          context,
          'surf',
          manifest.settings.surf?.toJson(),
          configured.toJson(),
          manifest.copyWith(
              settings: manifest.settings.copyWith(surf: configured)));
    }
    final disabled = {...?manifest.settings.fieldAbilities?.disabledAbilities};
    if (enabled) {
      disabled.remove(ability);
    } else {
      disabled.add(ability);
    }
    final configuration =
        ProjectFieldAbilitiesSettings(disabledAbilities: disabled);
    final next = configuration.isEmpty ? null : configuration;
    return _settingsDraft(
        context,
        'fieldAbilities',
        manifest.settings.fieldAbilities?.toJson(),
        next?.toJson(),
        manifest.copyWith(
            settings: manifest.settings.copyWith(fieldAbilities: next)));
  }
}

final class ProjectAudioCueActions {
  const ProjectAudioCueActions();

  static final descriptor = _descriptor(
    'project.audio.cue.configure',
    'projectAudio',
    'Configure one game sound cue using its default, silence or an imported audio resource',
    ['cueId', 'binding'],
  );

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = context.request.parameters;
    if (parameters.length != 2 ||
        parameters['cueId'] is! String ||
        !parameters.containsKey('binding')) {
      throw const FormatException('Expected cueId and binding only.');
    }
    final cue = ProjectSoundCue.fromWireName(parameters['cueId']! as String);
    final raw = parameters['binding'];
    if (raw != null && raw is! Map) {
      throw const FormatException('Sound binding must be an object or null.');
    }
    final binding = raw == null
        ? null
        : ProjectSoundBinding.fromJson(Map<String, dynamic>.from(raw as Map));
    if (binding?.source == ProjectSoundSource.custom) {
      final bytes = context.snapshot
          .findResourceBytes(projectMediaCatalogResourceIdentity);
      final media = ProjectMediaAsset.fromJson(
          _selectedCatalogEntry(bytes, 'entries', binding!.mediaId!));
      final source = AssetRecord.fromJson(_selectedCatalogEntry(
          context.snapshot.findResourceBytes(assetCatalogResourceIdentity),
          'records',
          media.sourceAssetId));
      final metadata = media.technicalMetadata;
      if (media.kind != ProjectMediaKind.audio ||
          metadata == null ||
          !metadata.mediaType.startsWith('audio/') ||
          source.artifact.mediaType != metadata.mediaType ||
          source.artifact.byteLength != metadata.sizeBytes) {
        throw const FormatException(
            'Choose an imported audio resource with a valid source for this sound.');
      }
    }
    final manifest = context.snapshot.manifest;
    final configuration = (manifest.settings.audio ?? ProjectAudioSettings())
        .withCue(cue, binding);
    final next = configuration.cues.isEmpty ? null : configuration;
    return _settingsDraft(
        context,
        'audio',
        manifest.settings.audio?.toJson(),
        next?.toJson(),
        manifest.copyWith(settings: manifest.settings.copyWith(audio: next)));
  }
}

Map<String, dynamic> _selectedCatalogEntry(
    List<int>? bytes, String field, String id) {
  final raw = bytes == null ? null : jsonDecode(utf8.decode(bytes));
  if (raw is! Map || raw['schemaVersion'] != 1 || raw[field] is! List) {
    throw const FormatException(
        'The selected audio library or source catalog is unavailable.');
  }
  final matches =
      (raw[field] as List).whereType<Map>().where((entry) => entry['id'] == id);
  final iterator = matches.iterator;
  if (!iterator.moveNext()) {
    throw const FormatException(
        'The selected audio resource or source is missing.');
  }
  final selected = Map<String, dynamic>.from(iterator.current);
  if (iterator.moveNext()) {
    throw const FormatException(
        'The selected audio resource or source has an ambiguous identity.');
  }
  return selected;
}

AuthoringActionDescriptor _descriptor(
        String id, String resource, String summary, List<String> parameters) =>
    AuthoringActionDescriptor(
        id: id,
        version: 1,
        summary: summary,
        inputSchemaId: 'pokemap.authoring.$id.input.v1',
        outputSchemaId: 'pokemap.authoring.$id.output.v1',
        riskLevel: AuthoringRiskLevel.low,
        resourceKinds: ['project', resource],
        capabilityIds: id == 'field_ability.configure'
            ? [
                'authoring.field_abilities',
                FieldAbilityActivationCapabilities.capabilityId
              ]
            : [
                'authoring.project_audio',
                ProjectAudioCapabilities.capabilityId
              ],
        requiredPermissions: const [AuthoringPermission.projectWrite],
        guarantees: const [
          AuthoringGuarantee.atomic,
          AuthoringGuarantee.dryRun,
          AuthoringGuarantee.idempotent,
          AuthoringGuarantee.revisionChecked,
          AuthoringGuarantee.undoable
        ],
        extensions: {
          'parameterNames': parameters,
          'inputSchema': {
            'type': 'object',
            'additionalProperties': false,
            'required': parameters,
            'properties': id == 'field_ability.configure'
                ? {
                    'abilityId': {
                      'type': 'string',
                      'enum': [
                        for (final ability in FieldAbility.values)
                          ability.moveId
                      ]
                    },
                    'enabled': {'type': 'boolean'},
                  }
                : {
                    'cueId': {
                      'type': 'string',
                      'enum': [
                        for (final cue in ProjectSoundCue.values) cue.wireName
                      ]
                    },
                    'binding': {
                      'oneOf': [
                        {'type': 'null'},
                        {
                          'type': 'object',
                          'additionalProperties': false,
                          'required': ['source'],
                          'properties': {
                            'source': {
                              'enum': ['builtin', 'silent', 'custom']
                            },
                            'mediaId': {'type': 'string', 'minLength': 1},
                            'gain': {
                              'type': 'number',
                              'minimum': 0,
                              'maximum': 1
                            },
                          }
                        },
                      ]
                    },
                  },
          },
        });

AuthoringMutationDraft _settingsDraft(AuthoringPlanningContext context,
    String field, Object? before, Object? after, ProjectManifest projected) {
  if (jsonEncode(before) == jsonEncode(after)) {
    return AuthoringMutationDraft(
        changeSet: AuthoringChangeSet.noChanges(),
        preview: {'operation': context.request.actionId, 'noOp': true});
  }
  final snapshot = context.snapshot;
  final original =
      jsonDecode(utf8.decode(snapshot.authoringProjectBytes)) as Map;
  final document = Map<String, Object?>.from(original);
  final settings =
      Map<String, Object?>.from(document['settings'] as Map? ?? const {});
  if (after == null) {
    settings.remove(field);
  } else {
    settings[field] = after;
  }
  document['settings'] = settings;
  final resource = AuthoringResourceRef(
      kind: 'project',
      id: 'project',
      revision: snapshot.resourceFingerprints['project']);
  return AuthoringMutationDraft(
      projectedProject: projected,
      changeSet: AuthoringChangeSet(
          changes: [
            AuthoringResourceChange(
                resource: resource,
                storageKey: 'project.json',
                beforeBytes: snapshot.resourceBytes('project'),
                afterBytes: utf8.encode(jsonEncode(document)))
          ],
          diff: AuthoringDiff([
            AuthoringDiffEntry(
                operation: AuthoringDiffOperation.replace,
                resource: resource,
                path: '/settings/$field',
                before: before,
                after: after)
          ])),
      preview: {
        'operation': context.request.actionId,
        'path': '/settings/$field'
      });
}
