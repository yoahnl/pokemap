import 'package:map_core/map_core.dart';

import '../../../contracts/action_descriptor.dart';
import '../../../transactions/action_planner.dart';
import '../../../transactions/authoring_plan.dart';
import 'character_studio_action_support.dart';

final class CharacterStudioCharacterActions {
  const CharacterStudioCharacterActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable(
    <AuthoringActionDescriptor>[
      characterStudioActionDescriptor(
        'characterStudio.character.create',
        'Create one Character Studio character identity',
        risk: AuthoringRiskLevel.low,
      ),
      characterStudioActionDescriptor(
        'characterStudio.character.update',
        'Update one Character Studio character identity',
        risk: AuthoringRiskLevel.low,
      ),
      characterStudioActionDescriptor(
        'characterStudio.character.setDefault',
        'Select or clear the default playable character',
        risk: AuthoringRiskLevel.low,
      ),
      characterStudioActionDescriptor(
        'characterStudio.character.portrait.assign',
        'Assign or replace one portrait state on a character',
        risk: AuthoringRiskLevel.low,
      ),
      characterStudioActionDescriptor(
        'characterStudio.character.portrait.clear',
        'Clear one portrait state from a character',
        risk: AuthoringRiskLevel.low,
      ),
      characterStudioActionDescriptor(
        'characterStudio.character.deletePlan',
        'Inspect every dependency before deleting a character',
        risk: AuthoringRiskLevel.low,
      ),
      characterStudioActionDescriptor(
        'characterStudio.character.delete',
        'Delete one character and resolve every dependency',
        risk: AuthoringRiskLevel.high,
      ),
    ],
  );

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = CharacterStudioActionParameters(
      context.request.parameters,
    );
    return switch (context.request.actionId) {
      'characterStudio.character.create' => _create(context, parameters),
      'characterStudio.character.update' => _update(context, parameters),
      'characterStudio.character.setDefault' =>
        _setDefault(context, parameters),
      'characterStudio.character.portrait.assign' =>
        _assignPortrait(context, parameters),
      'characterStudio.character.portrait.clear' =>
        _clearPortrait(context, parameters),
      'characterStudio.character.deletePlan' =>
        _delete(context, parameters, plan: true),
      'characterStudio.character.delete' =>
        _delete(context, parameters, plan: false),
      _ => throw CharacterStudioActionException(
          'character_studio.character.action_unsupported',
          'The requested character action is unsupported.',
          details: <String, Object?>{'actionId': context.request.actionId},
        ),
    };
  }

  AuthoringMutationDraft _create(
    AuthoringPlanningContext context,
    CharacterStudioActionParameters parameters,
  ) {
    parameters.allow(
      const <String>{
        'name',
        'tilesetId',
        'frameWidth',
        'frameHeight',
        'tags',
      },
    );
    final manifest = context.snapshot.manifest;
    final name = parameters.string('name');
    final tilesetId = parameters.string('tilesetId');
    _requireTileset(manifest, tilesetId);
    final frameWidth = parameters.optionalPositiveInt('frameWidth') ?? 1;
    final frameHeight = parameters.optionalPositiveInt('frameHeight') ?? 2;
    _requireFrameDimension(frameWidth, 'frameWidth');
    _requireFrameDimension(frameHeight, 'frameHeight');
    final tags = parameters.optionalStrings('tags') ?? const <String>[];
    final baseId = characterStudioSlug(name);
    final id = _availableCharacterId(manifest, baseId);
    final sortOrder = manifest.characters.isEmpty
        ? 0
        : manifest.characters
                .map((character) => character.sortOrder)
                .reduce((left, right) => left > right ? left : right) +
            1;
    final character = ProjectCharacterEntry(
      id: id,
      name: name,
      tilesetId: tilesetId,
      frameWidth: frameWidth,
      frameHeight: frameHeight,
      tags: tags,
      sortOrder: sortOrder,
    );
    final projected = manifest.copyWith(
      characters: <ProjectCharacterEntry>[...manifest.characters, character],
    );
    _validateManifest(projected);
    return characterStudioProjectDraft(
      context.snapshot,
      projected,
      operation: context.request.actionId,
      path: '/characters/$id',
      after: character.toJson(),
      preview: <String, Object?>{'characterId': id},
    );
  }

  AuthoringMutationDraft _update(
    AuthoringPlanningContext context,
    CharacterStudioActionParameters parameters,
  ) {
    parameters.allow(
      const <String>{
        'characterId',
        'name',
        'tilesetId',
        'frameWidth',
        'frameHeight',
        'tags',
      },
    );
    final manifest = context.snapshot.manifest;
    final characterId = parameters.string('characterId');
    final index = _characterIndex(manifest, characterId);
    final before = manifest.characters[index];
    final name = parameters.optionalString('name') ?? before.name;
    final tilesetId =
        parameters.optionalString('tilesetId') ?? before.tilesetId;
    _requireTileset(manifest, tilesetId);
    final frameWidth =
        parameters.optionalPositiveInt('frameWidth') ?? before.frameWidth;
    final frameHeight =
        parameters.optionalPositiveInt('frameHeight') ?? before.frameHeight;
    _requireFrameDimension(frameWidth, 'frameWidth');
    _requireFrameDimension(frameHeight, 'frameHeight');
    final after = before.copyWith(
      name: name,
      tilesetId: tilesetId,
      frameWidth: frameWidth,
      frameHeight: frameHeight,
      tags: parameters.optionalStrings('tags') ?? before.tags,
    );
    final characters = manifest.characters.toList()..[index] = after;
    final projected = manifest.copyWith(characters: characters);
    _validateManifest(projected);
    return characterStudioProjectDraft(
      context.snapshot,
      projected,
      operation: context.request.actionId,
      path: '/characters/$characterId',
      before: before.toJson(),
      after: after.toJson(),
      preview: <String, Object?>{'characterId': characterId},
    );
  }

  AuthoringMutationDraft _setDefault(
    AuthoringPlanningContext context,
    CharacterStudioActionParameters parameters,
  ) {
    parameters.allow(const <String>{'characterId'});
    final manifest = context.snapshot.manifest;
    final characterId = parameters.optionalString('characterId');
    if (characterId != null) {
      _characterIndex(manifest, characterId);
    }
    final before = manifest.settings.defaultPlayerCharacterId;
    final projected = manifest.copyWith(
      settings: manifest.settings.copyWith(
        defaultPlayerCharacterId: characterId,
      ),
    );
    _validateManifest(projected);
    return characterStudioProjectDraft(
      context.snapshot,
      projected,
      operation: context.request.actionId,
      path: '/settings/defaultPlayerCharacterId',
      before: before,
      after: characterId,
      preview: <String, Object?>{'characterId': characterId},
    );
  }

  AuthoringMutationDraft _assignPortrait(
    AuthoringPlanningContext context,
    CharacterStudioActionParameters parameters,
  ) {
    parameters.allow(
      const <String>{
        'characterId',
        'portraitStateId',
        'assetId',
        'fitMode',
      },
    );
    final manifest = context.snapshot.manifest;
    final characterId = parameters.string('characterId');
    final characterIndex = _characterIndex(manifest, characterId);
    final portraitStateId = parameters.string('portraitStateId');
    if (!manifest.characterStudioCatalog.portraitStates.any(
      (state) => state.id == portraitStateId,
    )) {
      throw CharacterStudioActionException(
        'character_studio.character.portrait_state_not_found',
        'The requested global portrait state does not exist.',
        details: <String, Object?>{'portraitStateId': portraitStateId},
      );
    }
    final fitMode = _portraitFitMode(
      parameters.optionalString('fitMode') ?? 'contain',
    );
    final character = manifest.characters[characterIndex];
    final portraitIndex = character.portraits.indexWhere(
      (portrait) => portrait.portraitStateId == portraitStateId,
    );
    final before =
        portraitIndex < 0 ? null : character.portraits[portraitIndex];
    final after = CharacterPortraitVariant(
      portraitStateId: portraitStateId,
      assetId: parameters.string('assetId'),
      fitMode: fitMode,
    );
    final portraits = character.portraits.toList();
    if (portraitIndex < 0) {
      portraits.add(after);
    } else {
      portraits[portraitIndex] = after;
    }
    final characters = manifest.characters.toList()
      ..[characterIndex] = character.copyWith(portraits: portraits);
    final projected = manifest.copyWith(characters: characters);
    _validateManifest(projected);
    return characterStudioProjectDraft(
      context.snapshot,
      projected,
      operation: context.request.actionId,
      path: '/characters/$characterId/portraits/$portraitStateId',
      before: before?.toJson(),
      after: after.toJson(),
      preview: <String, Object?>{
        'characterId': characterId,
        'portraitStateId': portraitStateId,
        'replaced': before != null,
      },
    );
  }

  AuthoringMutationDraft _clearPortrait(
    AuthoringPlanningContext context,
    CharacterStudioActionParameters parameters,
  ) {
    parameters.allow(const <String>{'characterId', 'portraitStateId'});
    final manifest = context.snapshot.manifest;
    final characterId = parameters.string('characterId');
    final characterIndex = _characterIndex(manifest, characterId);
    final portraitStateId = parameters.string('portraitStateId');
    final character = manifest.characters[characterIndex];
    final portraitIndex = character.portraits.indexWhere(
      (portrait) => portrait.portraitStateId == portraitStateId,
    );
    if (portraitIndex < 0) {
      throw CharacterStudioActionException(
        'character_studio.character.portrait_not_assigned',
        'The requested portrait state is not assigned to this character.',
        details: <String, Object?>{
          'characterId': characterId,
          'portraitStateId': portraitStateId,
        },
      );
    }
    final before = character.portraits[portraitIndex];
    final portraits = character.portraits.toList()..removeAt(portraitIndex);
    final characters = manifest.characters.toList()
      ..[characterIndex] = character.copyWith(portraits: portraits);
    final projected = manifest.copyWith(characters: characters);
    _validateManifest(projected);
    return characterStudioProjectDraft(
      context.snapshot,
      projected,
      operation: context.request.actionId,
      path: '/characters/$characterId/portraits/$portraitStateId',
      before: before.toJson(),
      preview: <String, Object?>{
        'characterId': characterId,
        'portraitStateId': portraitStateId,
      },
    );
  }

  AuthoringMutationDraft _delete(
    AuthoringPlanningContext context,
    CharacterStudioActionParameters parameters, {
    required bool plan,
  }) {
    parameters.allow(
      plan
          ? const <String>{'characterId'}
          : const <String>{
              'characterId',
              'resolution',
              'replacementId',
            },
    );
    requireCharacterStudioActionMode(
      actionId: context.request.actionId,
      dryRun: context.request.dryRun,
      plan: plan,
    );
    final manifest = context.snapshot.manifest;
    final characterId = parameters.string('characterId');
    final characterIndex = _characterIndex(manifest, characterId);
    final before = manifest.characters[characterIndex];
    final references = buildCharacterStudioReferenceIndex(
      manifest,
      maps: context.snapshot.maps,
    ).referencesTo(
      CharacterStudioReferenceTargetKind.character,
      characterId,
    );
    final basePreview = <String, Object?>{
      'characterId': characterId,
      'dependencies': <Object?>[
        for (final reference in references)
          characterStudioReferenceJson(reference),
      ],
      'requiresResolution': references.isNotEmpty,
      'choices': const <Object?>['replace', 'clear', 'cancel'],
      'replacementCandidates': <Object?>[
        for (final character in manifest.characters)
          if (character.id != characterId)
            <String, Object?>{
              'id': character.id,
              'name': character.name,
            },
      ],
    };
    final characters = <ProjectCharacterEntry>[
      for (final character in manifest.characters)
        if (character.id != characterId) character,
    ];
    if (plan) {
      return characterStudioProjectDraft(
        context.snapshot,
        manifest.copyWith(characters: characters),
        operation: context.request.actionId,
        path: '/characters/$characterId',
        before: before.toJson(),
        preview: basePreview,
      );
    }
    final resolution = parameters.optionalString('resolution');
    if (references.isNotEmpty && resolution == null) {
      throw CharacterStudioActionException(
        'character_studio.character.resolution_required',
        'Referenced characters require replace, clear, or cancel.',
        details: <String, Object?>{'characterId': characterId},
      );
    }
    if (resolution == 'cancel') {
      throw CharacterStudioActionException(
        'character_studio.character.delete_cancelled',
        'Character deletion was cancelled.',
        details: <String, Object?>{'characterId': characterId},
      );
    }
    if (resolution != null &&
        resolution != 'clear' &&
        resolution != 'replace') {
      throw CharacterStudioActionException(
        'character_studio.character.resolution_invalid',
        'resolution must be replace, clear, or cancel.',
        details: <String, Object?>{'resolution': resolution},
      );
    }
    String? replacementId;
    if (resolution == 'replace') {
      replacementId = parameters.string('replacementId');
      if (replacementId == characterId ||
          !manifest.characters.any(
            (character) => character.id == replacementId,
          )) {
        throw CharacterStudioActionException(
          'character_studio.character.replacement_invalid',
          'replacementId must reference another character.',
          details: <String, Object?>{'replacementId': replacementId},
        );
      }
    } else if (parameters.optionalString('replacementId') != null) {
      throw CharacterStudioActionException(
        'character_studio.character.replacement_unexpected',
        'replacementId is only accepted with replace resolution.',
      );
    }
    final resolvedManifest = _resolveManifestReferences(
      manifest.copyWith(characters: characters),
      deletedId: characterId,
      replacementId: replacementId,
    );
    final projectedMaps = _resolveMapReferences(
      context.snapshot.maps,
      deletedId: characterId,
      replacementId: replacementId,
    );
    _validateManifest(resolvedManifest);
    for (final map in projectedMaps.values) {
      MapValidator.validate(map, projectDialogueContext: resolvedManifest);
    }
    return characterStudioProjectDraft(
      context.snapshot,
      resolvedManifest,
      operation: context.request.actionId,
      path: '/characters/$characterId',
      before: before.toJson(),
      projectedMaps: projectedMaps,
      preview: <String, Object?>{
        ...basePreview,
        'resolution': resolution,
        'replacementId': replacementId,
        'resolvedDependencyCount': references.length,
      },
    );
  }
}

String _availableCharacterId(ProjectManifest manifest, String baseId) {
  final existing = manifest.characters.map((character) => character.id).toSet();
  if (!existing.contains(baseId)) return baseId;
  var suffix = 2;
  while (existing.contains('$baseId-$suffix')) {
    suffix++;
  }
  return '$baseId-$suffix';
}

int _characterIndex(ProjectManifest manifest, String characterId) {
  final index = manifest.characters.indexWhere(
    (character) => character.id == characterId,
  );
  if (index >= 0) return index;
  throw CharacterStudioActionException(
    'character_studio.character.not_found',
    'The requested character does not exist.',
    details: <String, Object?>{'characterId': characterId},
  );
}

void _requireTileset(ProjectManifest manifest, String tilesetId) {
  if (manifest.tilesets.any((tileset) => tileset.id == tilesetId)) return;
  throw CharacterStudioActionException(
    'character_studio.character.tileset_not_found',
    'The requested character tileset does not exist.',
    details: <String, Object?>{'tilesetId': tilesetId},
  );
}

void _requireFrameDimension(int value, String field) {
  if (value <= 9999) return;
  throw CharacterStudioActionException(
    'character_studio.character.frame_dimension_invalid',
    '$field must be between 1 and 9999.',
    details: <String, Object?>{'parameter': field, 'value': value},
  );
}

CharacterPortraitFitMode _portraitFitMode(String value) {
  for (final mode in CharacterPortraitFitMode.values) {
    if (mode.name == value) return mode;
  }
  throw CharacterStudioActionException(
    'character_studio.character.portrait_fit_mode_invalid',
    'fitMode must be contain or cover.',
    details: <String, Object?>{'fitMode': value},
  );
}

ProjectManifest _resolveManifestReferences(
  ProjectManifest manifest, {
  required String deletedId,
  required String? replacementId,
}) {
  final avatarIds = <String>[];
  for (final id in manifest.newGame.playerAvatarCharacterIds) {
    final resolved = id == deletedId ? replacementId : id;
    if (resolved != null && !avatarIds.contains(resolved)) {
      avatarIds.add(resolved);
    }
  }
  final newGameJson = manifest.newGame.toJson()
    ..['playerAvatarCharacterIds'] = avatarIds;
  return manifest.copyWith(
    settings: manifest.settings.copyWith(
      defaultPlayerCharacterId:
          manifest.settings.defaultPlayerCharacterId == deletedId
              ? replacementId
              : manifest.settings.defaultPlayerCharacterId,
    ),
    newGame: ProjectNewGameConfig.fromJson(newGameJson),
    trainers: <ProjectTrainerEntry>[
      for (final trainer in manifest.trainers)
        trainer.characterId == deletedId
            ? trainer.copyWith(characterId: replacementId)
            : trainer,
    ],
    cinematics: <CinematicAsset>[
      for (final cinematic in manifest.cinematics)
        _resolveCinematicReference(
          cinematic,
          deletedId: deletedId,
          replacementId: replacementId,
        ),
    ],
  );
}

CinematicAsset _resolveCinematicReference(
  CinematicAsset cinematic, {
  required String deletedId,
  required String? replacementId,
}) {
  final stage = cinematic.stageContext;
  if (stage == null ||
      !stage.actorAppearanceBindings.any(
        (binding) => binding.characterId == deletedId,
      )) {
    return cinematic;
  }
  final bindings = <CinematicActorAppearanceBinding>[
    for (final binding in stage.actorAppearanceBindings)
      if (binding.characterId != deletedId)
        binding
      else if (replacementId != null)
        CinematicActorAppearanceBinding(
          actorId: binding.actorId,
          characterId: replacementId,
        ),
  ];
  return cinematic.copyWith(
    stageContext: CinematicStageContext(
      backdropMode: stage.backdropMode,
      actorBindings: stage.actorBindings,
      actorAppearanceBindings: bindings,
      initialPlacements: stage.initialPlacements,
      movementTargetBindings: stage.movementTargetBindings,
      stagePoints: stage.stagePoints,
      manualPaths: stage.manualPaths,
    ),
  );
}

Map<String, MapData> _resolveMapReferences(
  Iterable<MapData> maps, {
  required String deletedId,
  required String? replacementId,
}) {
  final resolved = <String, MapData>{};
  for (final map in maps) {
    var changed = false;
    final entities = <MapEntity>[
      for (final entity in map.entities)
        if (entity.npc?.characterId == deletedId)
          (() {
            changed = true;
            return entity.copyWith(
              npc: entity.npc!.copyWith(characterId: replacementId),
            );
          })()
        else
          entity,
    ];
    if (changed) {
      resolved[map.id] = map.copyWith(entities: entities);
    }
  }
  return resolved;
}

void _validateManifest(ProjectManifest manifest) {
  try {
    ProjectValidator.validate(manifest);
  } on Object catch (error) {
    throw CharacterStudioActionException(
      'character_studio.character.projected_state_invalid',
      'The character action would produce invalid project data.',
      details: <String, Object?>{
        'validationType': error.runtimeType.toString(),
      },
    );
  }
}
