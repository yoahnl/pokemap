import 'package:map_core/map_core.dart';

import '../../../contracts/action_descriptor.dart';
import '../../../transactions/action_planner.dart';
import '../../../transactions/authoring_plan.dart';
import 'character_studio_action_support.dart';

final class CharacterStudioAnimationDefinitionActions {
  const CharacterStudioAnimationDefinitionActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable(
    <AuthoringActionDescriptor>[
      characterStudioActionDescriptor(
        'characterStudio.animationDefinition.create',
        'Create one global custom Character Studio animation definition',
        risk: AuthoringRiskLevel.low,
      ),
      characterStudioActionDescriptor(
        'characterStudio.animationDefinition.update',
        'Update one global custom Character Studio animation definition',
        risk: AuthoringRiskLevel.medium,
      ),
      characterStudioActionDescriptor(
        'characterStudio.animationDefinition.reorder',
        'Reorder every global custom animation definition',
        risk: AuthoringRiskLevel.low,
      ),
      characterStudioActionDescriptor(
        'characterStudio.animationDefinition.deletePlan',
        'Inspect references before deleting one custom animation definition',
        risk: AuthoringRiskLevel.low,
      ),
      characterStudioActionDescriptor(
        'characterStudio.animationDefinition.delete',
        'Delete one custom animation definition and resolve every clip',
        risk: AuthoringRiskLevel.high,
      ),
    ],
  );

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = CharacterStudioActionParameters(
      context.request.parameters,
    );
    return switch (context.request.actionId) {
      'characterStudio.animationDefinition.create' =>
        _create(context, parameters),
      'characterStudio.animationDefinition.update' =>
        _update(context, parameters),
      'characterStudio.animationDefinition.reorder' =>
        _reorder(context, parameters),
      'characterStudio.animationDefinition.deletePlan' =>
        _delete(context, parameters, plan: true),
      'characterStudio.animationDefinition.delete' =>
        _delete(context, parameters, plan: false),
      _ => throw CharacterStudioActionException(
          'character_studio.animation_definition.action_unsupported',
          'The requested animation definition action is unsupported.',
          details: <String, Object?>{
            'actionId': context.request.actionId,
          },
        ),
    };
  }

  AuthoringMutationDraft _create(
    AuthoringPlanningContext context,
    CharacterStudioActionParameters parameters,
  ) {
    parameters.allow(const <String>{'displayName', 'mode'});
    final displayName = parameters.string('displayName');
    final id = characterStudioSlug(displayName);
    if (_systemAnimationIds.contains(id)) {
      throw CharacterStudioActionException(
        'character_studio.animation_definition.id_reserved',
        'System animation identifiers cannot be used by custom definitions.',
        details: <String, Object?>{'id': id},
      );
    }
    final mode = _mode(parameters.string('mode'));
    final manifest = context.snapshot.manifest;
    final definitions =
        manifest.characterStudioCatalog.customAnimationDefinitions;
    if (definitions.any((definition) => definition.id == id)) {
      throw CharacterStudioActionException(
        'character_studio.animation_definition.id_conflict',
        'A custom animation definition already uses the derived identifier.',
        details: <String, Object?>{'id': id},
      );
    }
    final definition = CharacterCustomAnimationDefinition(
      id: id,
      displayName: displayName,
      mode: mode,
      sortOrder: definitions.isEmpty
          ? 0
          : definitions
                  .map((definition) => definition.sortOrder)
                  .reduce((left, right) => left > right ? left : right) +
              1,
    );
    final projected = manifest.copyWith(
      characterStudioCatalog: manifest.characterStudioCatalog.copyWith(
        customAnimationDefinitions: <CharacterCustomAnimationDefinition>[
          ...definitions,
          definition,
        ],
      ),
    );
    return characterStudioProjectDraft(
      context.snapshot,
      projected,
      operation: context.request.actionId,
      path: '/characterStudioCatalog/customAnimationDefinitions/$id',
      after: definition.toJson(),
      preview: <String, Object?>{'animationDefinitionId': id},
    );
  }

  AuthoringMutationDraft _update(
    AuthoringPlanningContext context,
    CharacterStudioActionParameters parameters,
  ) {
    parameters.allow(const <String>{'id', 'displayName', 'mode'});
    final id = parameters.string('id');
    final manifest = context.snapshot.manifest;
    final definitions =
        manifest.characterStudioCatalog.customAnimationDefinitions;
    final index = definitions.indexWhere((definition) => definition.id == id);
    if (index < 0) _definitionMissing(id);
    final before = definitions[index];
    final displayName = parameters.optionalString('displayName');
    final modeValue = parameters.optionalString('mode');
    if (displayName == null && modeValue == null) {
      throw CharacterStudioActionException(
        'character_studio.animation_definition.update_empty',
        'Animation definition update requires displayName or mode.',
        details: <String, Object?>{'id': id},
      );
    }
    final mode = modeValue == null ? before.mode : _mode(modeValue);
    if (mode != before.mode) {
      final references =
          buildCharacterStudioReferenceIndex(manifest).referencesTo(
        CharacterStudioReferenceTargetKind.customAnimationDefinition,
        id,
      );
      if (references.isNotEmpty) {
        throw CharacterStudioActionException(
          'character_studio.animation_definition.mode_locked',
          'A referenced animation definition cannot change its clip mode.',
          details: <String, Object?>{
            'id': id,
            'dependencyCount': references.length,
          },
        );
      }
    }
    final after = before.copyWith(
      displayName: displayName ?? before.displayName,
      mode: mode,
    );
    final projectedDefinitions = definitions.toList();
    projectedDefinitions[index] = after;
    final projected = manifest.copyWith(
      characterStudioCatalog: manifest.characterStudioCatalog.copyWith(
        customAnimationDefinitions: projectedDefinitions,
      ),
    );
    return characterStudioProjectDraft(
      context.snapshot,
      projected,
      operation: context.request.actionId,
      path: '/characterStudioCatalog/customAnimationDefinitions/$id',
      before: before.toJson(),
      after: after.toJson(),
      preview: <String, Object?>{'animationDefinitionId': id},
    );
  }

  AuthoringMutationDraft _reorder(
    AuthoringPlanningContext context,
    CharacterStudioActionParameters parameters,
  ) {
    parameters.allow(const <String>{'orderedIds'});
    final orderedIds = parameters.strings('orderedIds');
    final manifest = context.snapshot.manifest;
    final definitions =
        manifest.characterStudioCatalog.customAnimationDefinitions;
    final byId = <String, CharacterCustomAnimationDefinition>{
      for (final definition in definitions) definition.id: definition,
    };
    if (orderedIds.length != byId.length ||
        orderedIds.any((id) => !byId.containsKey(id))) {
      throw CharacterStudioActionException(
        'character_studio.animation_definition.reorder_mismatch',
        'orderedIds must contain every custom definition exactly once.',
        details: <String, Object?>{
          'expectedIds': byId.keys.toList()..sort(),
          'orderedIds': orderedIds,
        },
      );
    }
    final projectedDefinitions = <CharacterCustomAnimationDefinition>[
      for (var index = 0; index < orderedIds.length; index++)
        byId[orderedIds[index]]!.copyWith(sortOrder: index),
    ];
    final projected = manifest.copyWith(
      characterStudioCatalog: manifest.characterStudioCatalog.copyWith(
        customAnimationDefinitions: projectedDefinitions,
      ),
    );
    return characterStudioProjectDraft(
      context.snapshot,
      projected,
      operation: context.request.actionId,
      path: '/characterStudioCatalog/customAnimationDefinitions',
      before: <Object?>[
        for (final definition in definitions) definition.toJson(),
      ],
      after: <Object?>[
        for (final definition in projectedDefinitions) definition.toJson(),
      ],
      preview: <String, Object?>{'orderedIds': orderedIds},
    );
  }

  AuthoringMutationDraft _delete(
    AuthoringPlanningContext context,
    CharacterStudioActionParameters parameters, {
    required bool plan,
  }) {
    parameters.allow(
      plan
          ? const <String>{'id'}
          : const <String>{'id', 'resolution', 'replacementId'},
    );
    requireCharacterStudioActionMode(
      actionId: context.request.actionId,
      dryRun: context.request.dryRun,
      plan: plan,
    );
    final id = parameters.string('id');
    if (_systemAnimationIds.contains(id)) {
      throw CharacterStudioActionException(
        'character_studio.animation_definition.system_immutable',
        'System animation definitions cannot be deleted.',
        details: <String, Object?>{'id': id},
      );
    }
    final manifest = context.snapshot.manifest;
    final definitions =
        manifest.characterStudioCatalog.customAnimationDefinitions;
    final index = definitions.indexWhere((definition) => definition.id == id);
    if (index < 0) _definitionMissing(id);
    final before = definitions[index];
    final references =
        buildCharacterStudioReferenceIndex(manifest).referencesTo(
      CharacterStudioReferenceTargetKind.customAnimationDefinition,
      id,
    );
    final replacementCandidates = <Map<String, Object?>>[
      for (final definition in definitions)
        if (definition.id != id && definition.mode == before.mode)
          definition.toJson(),
    ];
    final basePreview = <String, Object?>{
      'animationDefinitionId': id,
      'dependencies': <Object?>[
        for (final reference in references)
          characterStudioReferenceJson(reference),
      ],
      'requiresResolution': references.isNotEmpty,
      'choices': const <Object?>['replace', 'clear', 'cancel'],
      'replacementCandidates': replacementCandidates,
    };
    if (plan) {
      final projected = manifest.copyWith(
        characterStudioCatalog: manifest.characterStudioCatalog.copyWith(
          customAnimationDefinitions: <CharacterCustomAnimationDefinition>[
            for (final definition in definitions)
              if (definition.id != id) definition,
          ],
        ),
      );
      return characterStudioProjectDraft(
        context.snapshot,
        projected,
        operation: context.request.actionId,
        path: '/characterStudioCatalog/customAnimationDefinitions/$id',
        before: before.toJson(),
        preview: basePreview,
      );
    }
    final narrativeReferences = references.where(
      (reference) =>
          reference.sourceKind ==
              CharacterStudioReferenceSourceKind.cinematicCustomAnimation ||
          reference.sourceKind ==
              CharacterStudioReferenceSourceKind.sceneCustomAnimation,
    );
    if (narrativeReferences.isNotEmpty) {
      throw CharacterStudioActionException(
        'character_studio.animation_definition.narrative_reference_blocked',
        'Animation definitions used by cinematics or Scenes cannot be deleted.',
        details: <String, Object?>{
          'id': id,
          'dependencies': <Object?>[
            for (final reference in narrativeReferences)
              characterStudioReferenceJson(reference),
          ],
        },
      );
    }
    final resolution = parameters.optionalString('resolution');
    if (references.isNotEmpty && resolution == null) {
      throw CharacterStudioActionException(
        'character_studio.animation_definition.resolution_required',
        'Referenced definitions require replace, clear, or cancel.',
        details: <String, Object?>{'id': id},
      );
    }
    if (resolution == 'cancel') {
      throw CharacterStudioActionException(
        'character_studio.animation_definition.delete_cancelled',
        'Animation definition deletion was cancelled.',
        details: <String, Object?>{'id': id},
      );
    }
    if (resolution != null &&
        resolution != 'clear' &&
        resolution != 'replace') {
      throw CharacterStudioActionException(
        'character_studio.animation_definition.resolution_invalid',
        'resolution must be replace, clear, or cancel.',
        details: <String, Object?>{'resolution': resolution},
      );
    }
    CharacterCustomAnimationDefinition? replacement;
    if (resolution == 'replace') {
      final replacementId = parameters.string('replacementId');
      final replacementIndex = definitions.indexWhere(
        (definition) => definition.id == replacementId && replacementId != id,
      );
      if (replacementIndex < 0) {
        throw CharacterStudioActionException(
          'character_studio.animation_definition.replacement_invalid',
          'replacementId must reference another custom animation definition.',
          details: <String, Object?>{'replacementId': replacementId},
        );
      }
      replacement = definitions[replacementIndex];
      if (replacement.mode != before.mode) {
        throw CharacterStudioActionException(
          'character_studio.animation_definition.replacement_mode_mismatch',
          'Replacement requires the same single or directional mode.',
          details: <String, Object?>{
            'replacementId': replacement.id,
            'expectedMode': before.mode.name,
            'actualMode': replacement.mode.name,
          },
        );
      }
    } else if (parameters.optionalString('replacementId') != null) {
      throw CharacterStudioActionException(
        'character_studio.animation_definition.replacement_unexpected',
        'replacementId is only accepted with replace resolution.',
      );
    }
    final projectedCharacters = <ProjectCharacterEntry>[
      for (final character in manifest.characters)
        character.copyWith(
          customAnimations: _resolveClips(
            character,
            deletedId: id,
            replacementId: replacement?.id,
          ),
        ),
    ];
    final projected = manifest.copyWith(
      characterStudioCatalog: manifest.characterStudioCatalog.copyWith(
        customAnimationDefinitions: <CharacterCustomAnimationDefinition>[
          for (final definition in definitions)
            if (definition.id != id) definition,
        ],
      ),
      characters: projectedCharacters,
    );
    return characterStudioProjectDraft(
      context.snapshot,
      projected,
      operation: context.request.actionId,
      path: '/characterStudioCatalog/customAnimationDefinitions/$id',
      before: before.toJson(),
      preview: <String, Object?>{
        ...basePreview,
        'resolution': resolution,
        'replacementId': replacement?.id,
        'resolvedDependencyCount': references.length,
      },
    );
  }
}

List<CharacterCustomAnimationClip> _resolveClips(
  ProjectCharacterEntry character, {
  required String deletedId,
  required String? replacementId,
}) {
  if (replacementId != null) {
    final replacementSlots = <String>{
      for (final clip in character.customAnimations)
        if (clip.definitionId == replacementId)
          clip.direction?.name ?? 'single',
    };
    for (final clip in character.customAnimations) {
      if (clip.definitionId == deletedId &&
          replacementSlots.contains(clip.direction?.name ?? 'single')) {
        throw CharacterStudioActionException(
          'character_studio.animation_definition.replacement_slot_conflict',
          'The replacement would create a duplicate custom animation slot.',
          details: <String, Object?>{
            'characterId': character.id,
            'replacementId': replacementId,
            'direction': clip.direction?.name,
          },
        );
      }
    }
  }
  return <CharacterCustomAnimationClip>[
    for (final clip in character.customAnimations)
      if (clip.definitionId != deletedId)
        clip
      else if (replacementId != null)
        clip.copyWith(definitionId: replacementId),
  ];
}

CharacterCustomAnimationMode _mode(String value) {
  return switch (value) {
    'single' => CharacterCustomAnimationMode.single,
    'directional' => CharacterCustomAnimationMode.directional,
    _ => throw CharacterStudioActionException(
        'character_studio.animation_definition.mode_invalid',
        'mode must be single or directional.',
        details: <String, Object?>{'mode': value},
      ),
  };
}

Never _definitionMissing(String id) {
  throw CharacterStudioActionException(
    'character_studio.animation_definition.not_found',
    'The requested custom animation definition does not exist.',
    details: <String, Object?>{'id': id},
  );
}

const Set<String> _systemAnimationIds = <String>{
  'base',
  'idle',
  'walk',
  'run',
};
