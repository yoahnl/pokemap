part of 'character_studio_character_actions.dart';

Map<String, Object?> _characterDeletionSchema({required bool plan}) => {
      'type': 'object',
      'additionalProperties': false,
      'required': ['characterId'],
      'properties': {
        'characterId': {'type': 'string', 'minLength': 1},
        if (!plan) ...{
          'resolution': {
            'type': 'string',
            'enum': ['replace', 'clear', 'cancel'],
          },
          'replacementId': {'type': 'string', 'minLength': 1},
        },
      },
      if (!plan)
        'allOf': [
          {
            'if': {
              'required': ['resolution'],
              'properties': {
                'resolution': {'const': 'replace'}
              },
            },
            'then': {
              'required': ['replacementId']
            },
            'else': {
              'not': {
                'required': ['replacementId']
              }
            },
          },
        ],
    };

void _requireDeletionInventory(ProjectSnapshot snapshot) {
  for (final entry in snapshot.manifest.maps) {
    final identity = 'map:${entry.id}';
    if (!snapshot.maps.any((map) => map.id == entry.id) ||
        snapshot.findResourceBytes(identity) == null ||
        snapshot.resourceFingerprints[identity] == null ||
        snapshot.resourceStorageKeys[identity] == null) {
      throw CharacterStudioActionException(
        'character_studio.map_resource_unavailable',
        'Every project map must be available before deleting a character.',
        details: {'mapId': entry.id},
      );
    }
  }
}

List<Map<String, Object?>> _characterClearProblems(
  AuthoringPlanningContext context,
  String characterId,
) {
  final manifest = context.snapshot.manifest;
  final configured = manifest.newGame.startMapId.trim().isNotEmpty;
  return [
    if (configured && manifest.settings.defaultPlayerCharacterId == characterId)
      {
        'code': 'default_player_required',
        'message': 'Le joueur par défaut doit être remplacé.'
      },
    if (configured &&
        manifest.newGame.playerAvatarCharacterIds.contains(characterId) &&
        manifest.newGame.playerAvatarCharacterIds
            .every((id) => id == characterId))
      {
        'code': 'last_avatar_required',
        'message': 'Le dernier avatar de nouvelle partie doit être remplacé.'
      },
    for (final (command, sourceId)
        in _characterAnimationCommands(context, characterId))
      if (command.fallbackPolicy == CharacterCustomAnimationFallbackPolicy.fail)
        {
          'code': 'custom_animation_character_required',
          'message':
              'L’acteur utilisé par $sourceId doit être remplacé avant de supprimer ce personnage.',
          'sourceId': sourceId
        },
  ];
}

List<Map<String, Object?>> _characterReplacementProblems(
  AuthoringPlanningContext context,
  String characterId,
  ProjectCharacterEntry replacement,
) {
  final manifest = context.snapshot.manifest;
  final problems = <Map<String, Object?>>[];
  final playerRole = manifest.newGame.startMapId.trim().isNotEmpty &&
      (manifest.settings.defaultPlayerCharacterId == characterId ||
          manifest.newGame.playerAvatarCharacterIds.contains(characterId));
  if (playerRole) {
    final report = analyzeCharacterStudioReadiness(
      manifest: manifest.copyWith(
          settings: manifest.settings.copyWith(defaultPlayerCharacterId: null)),
      requiredCharacterIds: {replacement.id},
    );
    problems.addAll([
      for (final diagnostic in report.forCharacter(replacement.id))
        if (diagnostic.severity == CharacterStudioReadinessSeverity.error)
          {'code': diagnostic.code.name, 'message': diagnostic.message},
    ]);
  }
  if (!manifest.tilesets
      .any((tileset) => tileset.id == replacement.tilesetId)) {
    problems.add({
      'code': 'tileset_missing',
      'message': 'La planche du remplaçant est introuvable.'
    });
  }
  final usedStates = <String>{};
  for (final entry in manifest.dialogues) {
    final bytes = context.snapshot
        .findResourceBytes(dialogueSourceResourceIdentity(entry.id));
    if (bytes == null) continue;
    final source = _decodeDialogueSource(entry.id, bytes);
    for (final match in _portraitDirectivePattern.allMatches(source)) {
      if (match.group(2) != characterId) continue;
      final stateId = match
          .group(3)!
          .trim()
          .split(RegExp(r'\s+'))
          .first
          .replaceAll('>>', '');
      usedStates.add(stateId);
      if (!replacement.portraits.any((portrait) =>
          portrait.portraitStateId == stateId &&
          portrait.assetId.trim().isNotEmpty)) {
        problems.add({
          'code': 'portrait_missing',
          'message':
              'Le portrait « $stateId » utilisé par ${entry.name} manque au remplaçant.',
          'dialogueId': entry.id,
          'portraitStateId': stateId
        });
      }
    }
  }
  final catalogBytes =
      context.snapshot.findResourceBytes(assetCatalogResourceIdentity);
  AssetCatalog? assets;
  if (catalogBytes != null) {
    assets = AssetCatalog.fromJson(Map<String, dynamic>.from(
        jsonDecode(utf8.decode(catalogBytes)) as Map));
  }
  for (final portrait in replacement.portraits
      .where((value) => usedStates.contains(value.portraitStateId))) {
    final records = assets?.records
            .where((asset) => asset.id == portrait.assetId)
            .toList() ??
        [];
    if (records.isEmpty ||
        context.snapshot.findResourceBytes(
                assetBlobResourceIdentity(records.first.artifact.digest)) ==
            null) {
      problems.add({
        'code': 'portrait_asset_unavailable',
        'message':
            'Le fichier du portrait « ${portrait.portraitStateId} » est introuvable.',
        'portraitStateId': portrait.portraitStateId
      });
    }
  }
  for (final (command, sourceId)
      in _characterAnimationCommands(context, characterId)) {
    final clips = replacement.customAnimations
        .where((clip) =>
            clip.definitionId == command.definitionId &&
            clip.direction == command.direction &&
            clip.frames.isNotEmpty)
        .toList();
    final supported = clips.isNotEmpty;
    if (!supported &&
        command.fallbackPolicy == CharacterCustomAnimationFallbackPolicy.fail) {
      problems.add({
        'code': 'custom_animation_missing',
        'message':
            'Le clip « ${command.definitionId} » utilisé par $sourceId manque au remplaçant.',
        'sourceId': sourceId,
        'definitionId': command.definitionId
      });
    }
    if (supported) {
      final records = assets?.records
              .where((asset) => asset.id == clips.first.sourceAssetId)
              .toList() ??
          [];
      if (records.isEmpty ||
          context.snapshot.findResourceBytes(
                  assetBlobResourceIdentity(records.first.artifact.digest)) ==
              null) {
        problems.add({
          'code': 'custom_animation_asset_unavailable',
          'message':
              'La planche du clip « ${command.definitionId} » est introuvable.',
          'sourceId': sourceId
        });
      }
    }
  }
  return problems;
}

List<(CharacterCustomAnimationRuntimeCommand, String)>
    _characterAnimationCommands(
  AuthoringPlanningContext context,
  String characterId,
) {
  final manifest = context.snapshot.manifest;
  final commands = <(CharacterCustomAnimationRuntimeCommand, String)>[];
  final playerReference =
      manifest.settings.defaultPlayerCharacterId == characterId ||
          manifest.newGame.playerAvatarCharacterIds.contains(characterId);
  final mapActors = {
    if (playerReference) 'player',
    for (final map in context.snapshot.maps)
      for (final entity in map.entities)
        if (entity.npc?.characterId == characterId) entity.id,
  };
  for (final cinematic in manifest.cinematics) {
    final actors = {
      for (final binding in cinematic.stageContext?.actorAppearanceBindings ??
          <CinematicActorAppearanceBinding>[])
        if (binding.characterId == characterId) binding.actorId,
      for (final binding
          in cinematic.stageContext?.actorBindings ?? <CinematicActorBinding>[])
        if (mapActors.contains(binding.mapEntityId) ||
            (playerReference &&
                binding.kind == CinematicActorBindingKind.player))
          binding.actorId,
    };
    for (final step in cinematic.timeline.steps) {
      final command = cinematicCharacterCustomAnimationCommandOf(step);
      if (command != null && actors.contains(command.actorId)) {
        commands.add((command, cinematic.id));
      }
    }
  }
  for (final scene in manifest.scenes) {
    for (final node in scene.graph.nodes) {
      final payload = node.payload;
      if (payload is SceneActionPayload &&
          payload.interactiveCommand
              is SceneCharacterCustomAnimationInteractiveCommand) {
        final command = (payload.interactiveCommand
                as SceneCharacterCustomAnimationInteractiveCommand)
            .runtimeCommand;
        if (mapActors.contains(command.actorId)) {
          commands.add((command, scene.id));
        }
      }
    }
  }
  return commands;
}

Map<String, Object?> _characterReplacementPreview(
    AuthoringPlanningContext context,
    String characterId,
    ProjectCharacterEntry candidate) {
  final problems =
      _characterReplacementProblems(context, characterId, candidate);
  return {
    'id': candidate.id,
    'name': candidate.name,
    'compatible': problems.isEmpty,
    'incompatibilities': problems
  };
}
