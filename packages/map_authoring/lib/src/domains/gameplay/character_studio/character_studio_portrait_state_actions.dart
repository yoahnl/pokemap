import 'package:map_core/map_core.dart';

import '../../../contracts/action_descriptor.dart';
import '../../../transactions/action_planner.dart';
import '../../../transactions/authoring_plan.dart';
import 'character_studio_action_support.dart';

final class CharacterStudioPortraitStateActions {
  const CharacterStudioPortraitStateActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable(
    <AuthoringActionDescriptor>[
      characterStudioActionDescriptor(
        'characterStudio.portraitState.create',
        'Create one global Character Studio portrait state',
        risk: AuthoringRiskLevel.low,
      ),
      characterStudioActionDescriptor(
        'characterStudio.portraitState.update',
        'Rename one global Character Studio portrait state',
        risk: AuthoringRiskLevel.low,
      ),
      characterStudioActionDescriptor(
        'characterStudio.portraitState.reorder',
        'Reorder every global Character Studio portrait state',
        risk: AuthoringRiskLevel.low,
      ),
      characterStudioActionDescriptor(
        'characterStudio.portraitState.deletePlan',
        'Inspect references before deleting one global portrait state',
        risk: AuthoringRiskLevel.low,
      ),
      characterStudioActionDescriptor(
        'characterStudio.portraitState.delete',
        'Delete one global portrait state and resolve every reference',
        risk: AuthoringRiskLevel.high,
      ),
    ],
  );

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = CharacterStudioActionParameters(
      context.request.parameters,
    );
    return switch (context.request.actionId) {
      'characterStudio.portraitState.create' => _create(context, parameters),
      'characterStudio.portraitState.update' => _update(context, parameters),
      'characterStudio.portraitState.reorder' => _reorder(context, parameters),
      'characterStudio.portraitState.deletePlan' =>
        _delete(context, parameters, plan: true),
      'characterStudio.portraitState.delete' =>
        _delete(context, parameters, plan: false),
      _ => throw CharacterStudioActionException(
          'character_studio.portrait_state.action_unsupported',
          'The requested portrait state action is unsupported.',
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
    parameters.allow(const <String>{'displayName'});
    final displayName = parameters.string('displayName');
    final id = characterStudioSlug(displayName);
    final manifest = context.snapshot.manifest;
    final states = manifest.characterStudioCatalog.portraitStates;
    if (states.any((state) => state.id == id)) {
      throw CharacterStudioActionException(
        'character_studio.portrait_state.id_conflict',
        'A global portrait state already uses the derived identifier.',
        details: <String, Object?>{'id': id},
      );
    }
    final definition = CharacterPortraitStateDefinition(
      id: id,
      displayName: displayName,
      sortOrder: states.isEmpty
          ? 0
          : states
                  .map((state) => state.sortOrder)
                  .reduce((left, right) => left > right ? left : right) +
              1,
    );
    final projected = manifest.copyWith(
      characterStudioCatalog: manifest.characterStudioCatalog.copyWith(
        portraitStates: <CharacterPortraitStateDefinition>[
          ...states,
          definition,
        ],
      ),
    );
    return characterStudioProjectDraft(
      context.snapshot,
      projected,
      operation: context.request.actionId,
      path: '/characterStudioCatalog/portraitStates/$id',
      after: definition.toJson(),
      preview: <String, Object?>{'portraitStateId': id},
    );
  }

  AuthoringMutationDraft _update(
    AuthoringPlanningContext context,
    CharacterStudioActionParameters parameters,
  ) {
    parameters.allow(const <String>{'id', 'displayName'});
    final id = parameters.string('id');
    final displayName = parameters.string('displayName');
    final manifest = context.snapshot.manifest;
    final index = manifest.characterStudioCatalog.portraitStates.indexWhere(
      (state) => state.id == id,
    );
    if (index < 0) _stateMissing(id);
    final before = manifest.characterStudioCatalog.portraitStates[index];
    final after = before.copyWith(displayName: displayName);
    final states = manifest.characterStudioCatalog.portraitStates.toList();
    states[index] = after;
    final projected = manifest.copyWith(
      characterStudioCatalog: manifest.characterStudioCatalog.copyWith(
        portraitStates: states,
      ),
    );
    return characterStudioProjectDraft(
      context.snapshot,
      projected,
      operation: context.request.actionId,
      path: '/characterStudioCatalog/portraitStates/$id',
      before: before.toJson(),
      after: after.toJson(),
      preview: <String, Object?>{'portraitStateId': id},
    );
  }

  AuthoringMutationDraft _reorder(
    AuthoringPlanningContext context,
    CharacterStudioActionParameters parameters,
  ) {
    parameters.allow(const <String>{'orderedIds'});
    final orderedIds = parameters.strings('orderedIds');
    final manifest = context.snapshot.manifest;
    final byId = <String, CharacterPortraitStateDefinition>{
      for (final state in manifest.characterStudioCatalog.portraitStates)
        state.id: state,
    };
    if (orderedIds.length != byId.length ||
        orderedIds.any((id) => !byId.containsKey(id))) {
      throw CharacterStudioActionException(
        'character_studio.portrait_state.reorder_mismatch',
        'orderedIds must contain every portrait state identifier exactly once.',
        details: <String, Object?>{
          'expectedIds': byId.keys.toList()..sort(),
          'orderedIds': orderedIds,
        },
      );
    }
    final states = <CharacterPortraitStateDefinition>[
      for (var index = 0; index < orderedIds.length; index++)
        byId[orderedIds[index]]!.copyWith(sortOrder: index),
    ];
    final projected = manifest.copyWith(
      characterStudioCatalog: manifest.characterStudioCatalog.copyWith(
        portraitStates: states,
      ),
    );
    return characterStudioProjectDraft(
      context.snapshot,
      projected,
      operation: context.request.actionId,
      path: '/characterStudioCatalog/portraitStates',
      before: <Object?>[
        for (final state in manifest.characterStudioCatalog.portraitStates)
          state.toJson(),
      ],
      after: <Object?>[for (final state in states) state.toJson()],
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
    final manifest = context.snapshot.manifest;
    final states = manifest.characterStudioCatalog.portraitStates;
    final index = states.indexWhere((state) => state.id == id);
    if (index < 0) _stateMissing(id);
    final before = states[index];
    final references = buildCharacterStudioReferenceIndex(manifest)
        .referencesTo(CharacterStudioReferenceTargetKind.portraitState, id);
    final replacementCandidates = <Map<String, Object?>>[
      for (final state in states)
        if (state.id != id) state.toJson(),
    ];
    final basePreview = <String, Object?>{
      'portraitStateId': id,
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
          portraitStates: <CharacterPortraitStateDefinition>[
            for (final state in states)
              if (state.id != id) state,
          ],
        ),
      );
      return characterStudioProjectDraft(
        context.snapshot,
        projected,
        operation: context.request.actionId,
        path: '/characterStudioCatalog/portraitStates/$id',
        before: before.toJson(),
        preview: basePreview,
      );
    }
    final resolution = parameters.optionalString('resolution');
    if (references.isNotEmpty && resolution == null) {
      throw CharacterStudioActionException(
        'character_studio.portrait_state.resolution_required',
        'Referenced portrait states require replace, clear, or cancel.',
        details: <String, Object?>{'id': id},
      );
    }
    if (resolution == 'cancel') {
      throw CharacterStudioActionException(
        'character_studio.portrait_state.delete_cancelled',
        'Portrait state deletion was cancelled.',
        details: <String, Object?>{'id': id},
      );
    }
    if (resolution != null &&
        resolution != 'clear' &&
        resolution != 'replace') {
      throw CharacterStudioActionException(
        'character_studio.portrait_state.resolution_invalid',
        'resolution must be replace, clear, or cancel.',
        details: <String, Object?>{'resolution': resolution},
      );
    }
    String? replacementId;
    if (resolution == 'replace') {
      replacementId = parameters.string('replacementId');
      if (replacementId == id ||
          !states.any((state) => state.id == replacementId)) {
        throw CharacterStudioActionException(
          'character_studio.portrait_state.replacement_invalid',
          'replacementId must reference another global portrait state.',
          details: <String, Object?>{'replacementId': replacementId},
        );
      }
    } else if (parameters.optionalString('replacementId') != null) {
      throw CharacterStudioActionException(
        'character_studio.portrait_state.replacement_unexpected',
        'replacementId is only accepted with replace resolution.',
      );
    }
    final projectedCharacters = <ProjectCharacterEntry>[
      for (final character in manifest.characters)
        character.copyWith(
          portraits: _resolvePortraits(
            character,
            deletedId: id,
            replacementId: replacementId,
          ),
        ),
    ];
    final projected = manifest.copyWith(
      characterStudioCatalog: manifest.characterStudioCatalog.copyWith(
        portraitStates: <CharacterPortraitStateDefinition>[
          for (final state in states)
            if (state.id != id) state,
        ],
      ),
      characters: projectedCharacters,
    );
    return characterStudioProjectDraft(
      context.snapshot,
      projected,
      operation: context.request.actionId,
      path: '/characterStudioCatalog/portraitStates/$id',
      before: before.toJson(),
      preview: <String, Object?>{
        ...basePreview,
        'resolution': resolution,
        'replacementId': replacementId,
        'resolvedDependencyCount': references.length,
      },
    );
  }
}

List<CharacterPortraitVariant> _resolvePortraits(
  ProjectCharacterEntry character, {
  required String deletedId,
  required String? replacementId,
}) {
  if (replacementId != null &&
      character.portraits.any(
        (portrait) => portrait.portraitStateId == replacementId,
      ) &&
      character.portraits.any(
        (portrait) => portrait.portraitStateId == deletedId,
      )) {
    throw CharacterStudioActionException(
      'character_studio.portrait_state.replacement_slot_conflict',
      'The replacement would create a duplicate portrait slot.',
      details: <String, Object?>{
        'characterId': character.id,
        'replacementId': replacementId,
      },
    );
  }
  return <CharacterPortraitVariant>[
    for (final portrait in character.portraits)
      if (portrait.portraitStateId != deletedId)
        portrait
      else if (replacementId != null)
        portrait.copyWith(portraitStateId: replacementId),
  ];
}

Never _stateMissing(String id) {
  throw CharacterStudioActionException(
    'character_studio.portrait_state.not_found',
    'The requested global portrait state does not exist.',
    details: <String, Object?>{'id': id},
  );
}
