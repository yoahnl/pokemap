import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../maps/map_lifecycle_adapter.dart';

final class PokemonRulesetAuthoringException implements Exception {
  const PokemonRulesetAuthoringException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'PokemonRulesetAuthoringException($code): $message';
}

final class PokemonRulesetActions {
  const PokemonRulesetActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable(
    <AuthoringActionDescriptor>[
      AuthoringActionDescriptor(
        id: 'pokemon.configuration.set_enabled',
        version: 1,
        summary:
            'Enable or disable canonical Pokemon data without changing its paths or ruleset',
        inputSchemaId:
            'pokemap.authoring/pokemon.configuration.set_enabled.input.v1',
        outputSchemaId:
            'pokemap.authoring/pokemon.configuration.set_enabled.output.v1',
        riskLevel: AuthoringRiskLevel.medium,
        resourceKinds: const <String>['project'],
        capabilityIds: const <String>['authoring.gameData.pokemon'],
        requiredPermissions: const <AuthoringPermission>[
          AuthoringPermission.projectWrite
        ],
        guarantees: const <AuthoringGuarantee>[
          AuthoringGuarantee.dryRun,
          AuthoringGuarantee.idempotent,
          AuthoringGuarantee.atomic,
          AuthoringGuarantee.revisionChecked,
          AuthoringGuarantee.undoable,
        ],
        extensions: const <String, Object?>{
          'inputSchema': {
            'type': 'object',
            'additionalProperties': false,
            'properties': {
              'enabled': {'type': 'boolean'}
            },
            'required': ['enabled'],
          },
        },
      ),
      AuthoringActionDescriptor(
        id: 'pokemon.ruleset.set',
        version: 1,
        summary: 'Set the validated project Pokemon ruleset profile',
        inputSchemaId: 'pokemap.authoring/pokemon.ruleset.set.input.v1',
        outputSchemaId: 'pokemap.authoring/pokemon.ruleset.set.output.v1',
        riskLevel: AuthoringRiskLevel.medium,
        resourceKinds: const <String>['project', 'pokemonRuleset'],
        capabilityIds: const <String>['authoring.gameData.pokemon'],
        requiredPermissions: const <AuthoringPermission>[
          AuthoringPermission.projectWrite,
        ],
        guarantees: const <AuthoringGuarantee>[
          AuthoringGuarantee.dryRun,
          AuthoringGuarantee.idempotent,
          AuthoringGuarantee.atomic,
          AuthoringGuarantee.revisionChecked,
          AuthoringGuarantee.undoable,
        ],
      ),
    ],
  );

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    if (context.request.actionId == 'pokemon.configuration.set_enabled') {
      return _setEnabled(context);
    }
    if (context.request.actionId != 'pokemon.ruleset.set') {
      throw PokemonRulesetAuthoringException(
        'pokemon.ruleset.action_unsupported',
        'The requested Pokemon ruleset action is unsupported.',
      );
    }
    final unknown = context.request.parameters.keys
        .where((key) => key != 'profile')
        .toList()
      ..sort();
    if (unknown.isNotEmpty) {
      throw PokemonRulesetAuthoringException(
        'pokemon.ruleset.parameters_unknown',
        'The request contains unsupported Pokemon ruleset parameters.',
      );
    }
    final rawProfile = context.request.parameters['profile'];
    if (rawProfile is! Map) {
      throw PokemonRulesetAuthoringException(
        'pokemon.ruleset.profile_required',
        'A complete Pokemon ruleset profile is required.',
      );
    }

    late final PokemonRulesetProfile profile;
    try {
      profile = PokemonRulesetProfile.fromJson(
        Map<String, dynamic>.from(rawProfile),
      );
    } on FormatException {
      throw PokemonRulesetAuthoringException(
        'pokemon.ruleset.profile_invalid',
        'The Pokemon ruleset profile is unknown or incomplete.',
      );
    }

    final snapshot = context.snapshot;
    final before = snapshot.manifest.pokemon.ruleset;
    if (before == profile) {
      throw PokemonRulesetAuthoringException(
        'pokemon.ruleset.no_change',
        'The Pokemon ruleset profile is already current.',
      );
    }
    final projected = snapshot.manifest.copyWith(
      pokemon: snapshot.manifest.pokemon.copyWith(ruleset: profile),
    );
    try {
      ProjectValidator.validate(projected);
    } on ValidationException {
      throw PokemonRulesetAuthoringException(
        'pokemon.ruleset.projected_state_invalid',
        'The Pokemon ruleset mutation would invalidate the project.',
      );
    }

    final project = AuthoringResourceRef(
      kind: 'project',
      id: 'project',
      revision: snapshot.resourceFingerprints['project'],
    );
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: <AuthoringResourceChange>[
          AuthoringResourceChange(
            resource: project,
            storageKey: 'project.json',
            beforeBytes: snapshot.resourceBytes('project'),
            afterBytes: encodeProjectAuthoringDocument(snapshot, projected),
          ),
        ],
        diff: AuthoringDiff(<AuthoringDiffEntry>[
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.replace,
            resource: project,
            path: '/pokemon/ruleset',
            before: before.toJson(),
            after: profile.toJson(),
          ),
        ]),
      ),
      preview: <String, Object?>{
        'profileId': profile.profileId,
        'schemaVersion': profile.schemaVersion,
        'ruleset': profile.toJson(),
      },
    );
  }

  AuthoringMutationDraft _setEnabled(AuthoringPlanningContext context) {
    final parameters = context.request.parameters;
    final enabled = parameters['enabled'];
    if (enabled is! bool || parameters.keys.any((key) => key != 'enabled')) {
      throw const PokemonRulesetAuthoringException(
        'pokemon.configuration.parameters_invalid',
        'The Pokemon configuration requires only a boolean enabled parameter.',
      );
    }
    final snapshot = context.snapshot;
    final before = snapshot.manifest.pokemon.enabled;
    if (before == enabled) {
      throw const PokemonRulesetAuthoringException(
        'pokemon.configuration.no_change',
        'The Pokemon configuration is already current.',
      );
    }
    final newGame = snapshot.manifest.newGame;
    if (!enabled &&
        (newGame.initialParty.isNotEmpty ||
            newGame.starterOptions.isNotEmpty)) {
      throw const PokemonRulesetAuthoringException(
        'pokemon.configuration.in_use',
        'The New Game party or starter options require enabled Pokemon data.',
      );
    }
    final projected = snapshot.manifest.copyWith(
      pokemon: snapshot.manifest.pokemon.copyWith(enabled: enabled),
    );
    ProjectValidator.validate(projected);
    final project = AuthoringResourceRef(
        kind: 'project',
        id: 'project',
        revision: snapshot.resourceFingerprints['project']);
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: [
          AuthoringResourceChange(
              resource: project,
              storageKey: 'project.json',
              beforeBytes: snapshot.resourceBytes('project'),
              afterBytes: encodeProjectAuthoringDocument(snapshot, projected))
        ],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
              operation: AuthoringDiffOperation.replace,
              resource: project,
              path: '/pokemon/enabled',
              before: before,
              after: enabled)
        ]),
      ),
      preview: {
        'enabled': enabled,
        'rulesetUnchanged': true,
        'dataPathsUnchanged': true
      },
    );
  }
}
