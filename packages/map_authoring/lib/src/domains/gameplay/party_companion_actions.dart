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

final class PartyCompanionActions {
  const PartyCompanionActions();

  static final descriptors = [
    AuthoringActionDescriptor(
      id: 'party_companion.configure',
      version: 1,
      summary:
          'Configure a 3D companion resolved from the first conscious party member',
      inputSchemaId: 'pokemap.authoring/party_companion.configure.input.v1',
      outputSchemaId: 'pokemap.authoring/party_companion.configure.output.v1',
      riskLevel: AuthoringRiskLevel.medium,
      resourceKinds: const ['project', 'partyCompanionConfiguration'],
      capabilityIds: const [
        'authoring.gameData.pokemon',
        SpatialGameplayCapabilities.companionCapabilityId
      ],
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.atomic,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable
      ],
      extensions: const {
        'inputSchema': {
          'type': 'object',
          'additionalProperties': false,
          'required': ['enabled', 'mappings'],
          'properties': {
            'enabled': {'type': 'boolean'},
            'mappings': {
              'type': 'array',
              'items': {
                'type': 'object',
                'additionalProperties': false,
                'required': ['speciesId', 'formId', 'characterId'],
                'properties': {
                  'speciesId': {'type': 'string', 'minLength': 1},
                  'formId': {'type': 'string', 'minLength': 1},
                  'characterId': {'type': 'string', 'minLength': 1}
                }
              }
            }
          }
        },
        'leader': 'firstConsciousPartyMember',
        'trailDistanceCells': 1,
        'visualReference': 'projectCharacterWithFourWalkingDirections',
        'savePosition': 'transientRebuiltAfterLoadOrMapChange',
        'collision': 'validatedTrailWithoutBlockingPlayer',
        'cinematics': 'hiddenAndTrailReset',
      },
    )
  ];

  Future<AuthoringMutationDraft> build(AuthoringPlanningContext context) async {
    final config = ProjectPartyCompanionConfig.fromJson(
        Map<String, dynamic>.from(context.request.parameters));
    final snapshot = context.snapshot;
    if (snapshot.manifest.partyCompanion == config) {
      throw const FormatException(
          'The companion configuration is already current.');
    }
    final projected = snapshot.manifest.copyWith(partyCompanion: config);
    ProjectValidator.validate(projected);
    for (final visual in config.mappings) {
      final bytes = await snapshot
          .readResourceBytes(pokemonSpeciesResourceIdentity(visual.speciesId));
      if (bytes == null) {
        throw FormatException(
            'Companion species ${visual.speciesId} is not in this project.');
      }
      final species = PokemonSpeciesFile.fromJson(
          jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>);
      if (!species.classification.isEnabledInProject ||
          species.forms.formId != visual.formId) {
        throw FormatException(
            'Companion species/form ${visual.speciesId}/${visual.formId} is unavailable.');
      }
    }
    final resource = AuthoringResourceRef(
        kind: 'project',
        id: 'project',
        revision: snapshot.resourceFingerprints['project']);
    return AuthoringMutationDraft(
        changeSet: AuthoringChangeSet(
            changes: [
              AuthoringResourceChange(
                resource: resource,
                storageKey: 'project.json',
                beforeBytes: snapshot.resourceBytes('project'),
                afterBytes: encodeProjectAuthoringDocument(snapshot, projected),
              )
            ],
            diff: AuthoringDiff([
              AuthoringDiffEntry(
                  operation: AuthoringDiffOperation.replace,
                  resource: resource,
                  path: '/partyCompanion',
                  before: snapshot.manifest.partyCompanion.toJson(),
                  after: config.toJson())
            ])),
        preview: config.toJson());
  }
}
