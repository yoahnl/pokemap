import 'package:map_core/map_core.dart';

import '../../../contracts/action_descriptor.dart';
import '../../../transactions/action_planner.dart';
import '../../../transactions/authoring_plan.dart';
import 'character_studio_action_support.dart';

final class CharacterStudioAnimationClipActions {
  const CharacterStudioAnimationClipActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable(
    <AuthoringActionDescriptor>[
      characterStudioActionDescriptor(
        'characterStudio.animationClip.upsert',
        'Create or update one Character Studio animation clip slot',
        risk: AuthoringRiskLevel.low,
      ),
      characterStudioActionDescriptor(
        'characterStudio.animationClip.delete',
        'Delete one Character Studio animation clip slot',
        risk: AuthoringRiskLevel.medium,
      ),
      characterStudioActionDescriptor(
        'characterStudio.animationFrame.insert',
        'Insert one frame into a Character Studio animation clip',
        risk: AuthoringRiskLevel.low,
      ),
      characterStudioActionDescriptor(
        'characterStudio.animationFrame.update',
        'Update one frame in a Character Studio animation clip',
        risk: AuthoringRiskLevel.low,
      ),
      characterStudioActionDescriptor(
        'characterStudio.animationFrame.reorder',
        'Move one frame inside a Character Studio animation clip',
        risk: AuthoringRiskLevel.low,
      ),
      characterStudioActionDescriptor(
        'characterStudio.animationFrame.delete',
        'Delete one frame from a Character Studio animation clip',
        risk: AuthoringRiskLevel.low,
      ),
    ],
  );

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = CharacterStudioActionParameters(
      context.request.parameters,
    );
    return switch (context.request.actionId) {
      'characterStudio.animationClip.upsert' =>
        _upsertClip(context, parameters),
      'characterStudio.animationClip.delete' =>
        _deleteClip(context, parameters),
      'characterStudio.animationFrame.insert' ||
      'characterStudio.animationFrame.update' ||
      'characterStudio.animationFrame.reorder' ||
      'characterStudio.animationFrame.delete' =>
        _mutateFrames(context, parameters),
      _ => throw CharacterStudioActionException(
          'character_studio.animation.action_unsupported',
          'The requested animation clip action is unsupported.',
          details: <String, Object?>{'actionId': context.request.actionId},
        ),
    };
  }

  AuthoringMutationDraft _upsertClip(
    AuthoringPlanningContext context,
    CharacterStudioActionParameters parameters,
  ) {
    parameters.allow(
      const <String>{
        ..._slotParameterNames,
        'sourceAssetId',
        'loop',
      },
    );
    final manifest = context.snapshot.manifest;
    final characterIndex = _characterIndex(
      manifest,
      parameters.string('characterId'),
    );
    final character = manifest.characters[characterIndex];
    final slot = _parseSlot(manifest, parameters);
    final loop = parameters.optionalBoolean('loop');
    late final ProjectCharacterEntry updated;
    late final Object? before;
    late final Object after;
    if (slot.kind == _AnimationSlotKind.system) {
      final index = _systemClipIndex(character, slot);
      final current = index < 0 ? null : character.animations[index];
      final sourceAssetId = parameters.contains('sourceAssetId')
          ? parameters.optionalString('sourceAssetId')
          : current?.sourceAssetId;
      final clip = CharacterAnimation(
        state: slot.state!,
        direction: slot.direction!,
        sourceAssetId: sourceAssetId,
        frames: current?.frames ?? const <CharacterAnimationFrame>[],
        loop: loop ?? current?.loop ?? true,
      );
      final animations = character.animations.toList();
      if (index < 0) {
        animations.add(clip);
      } else {
        animations[index] = clip;
      }
      updated = character.copyWith(animations: animations);
      before = current?.toJson();
      after = clip.toJson();
    } else {
      final index = _customClipIndex(character, slot);
      final current = index < 0 ? null : character.customAnimations[index];
      final sourceAssetId = parameters.contains('sourceAssetId')
          ? parameters.optionalString('sourceAssetId')
          : current?.sourceAssetId;
      if (sourceAssetId == null) {
        throw CharacterStudioActionException(
          'character_studio.animation.source_asset_required',
          'Custom animation clips require a sourceAssetId.',
          details: <String, Object?>{'slot': slot.pathSegment},
        );
      }
      final clip = CharacterCustomAnimationClip(
        definitionId: slot.definitionId!,
        direction: slot.direction,
        sourceAssetId: sourceAssetId,
        frames: current?.frames ?? const <CharacterAnimationFrame>[],
        loop: loop ?? current?.loop ?? true,
      );
      final animations = character.customAnimations.toList();
      if (index < 0) {
        animations.add(clip);
      } else {
        animations[index] = clip;
      }
      updated = character.copyWith(customAnimations: animations);
      before = current?.toJson();
      after = clip.toJson();
    }
    return _characterDraft(
      context,
      manifest: manifest,
      characterIndex: characterIndex,
      updated: updated,
      slot: slot,
      before: before,
      after: after,
      created: before == null,
    );
  }

  AuthoringMutationDraft _deleteClip(
    AuthoringPlanningContext context,
    CharacterStudioActionParameters parameters,
  ) {
    parameters.allow(_slotParameterNames);
    final manifest = context.snapshot.manifest;
    final characterIndex = _characterIndex(
      manifest,
      parameters.string('characterId'),
    );
    final character = manifest.characters[characterIndex];
    final slot = _parseSlot(manifest, parameters);
    late final ProjectCharacterEntry updated;
    late final Object before;
    if (slot.kind == _AnimationSlotKind.system) {
      final index = _requireClipIndex(_systemClipIndex(character, slot), slot);
      before = character.animations[index].toJson();
      final animations = character.animations.toList()..removeAt(index);
      updated = character.copyWith(animations: animations);
    } else {
      final index = _requireClipIndex(_customClipIndex(character, slot), slot);
      before = character.customAnimations[index].toJson();
      final animations = character.customAnimations.toList()..removeAt(index);
      updated = character.copyWith(customAnimations: animations);
    }
    return _characterDraft(
      context,
      manifest: manifest,
      characterIndex: characterIndex,
      updated: updated,
      slot: slot,
      before: before,
    );
  }

  AuthoringMutationDraft _mutateFrames(
    AuthoringPlanningContext context,
    CharacterStudioActionParameters parameters,
  ) {
    final actionId = context.request.actionId;
    parameters.allow(
      switch (actionId) {
        'characterStudio.animationFrame.insert' => const <String>{
            ..._slotParameterNames,
            'frameIndex',
            'frame',
          },
        'characterStudio.animationFrame.update' => const <String>{
            ..._slotParameterNames,
            'frameIndex',
            'frame',
          },
        'characterStudio.animationFrame.reorder' => const <String>{
            ..._slotParameterNames,
            'fromIndex',
            'toIndex',
          },
        _ => const <String>{..._slotParameterNames, 'frameIndex'},
      },
    );
    final manifest = context.snapshot.manifest;
    final characterIndex = _characterIndex(
      manifest,
      parameters.string('characterId'),
    );
    final character = manifest.characters[characterIndex];
    final slot = _parseSlot(manifest, parameters);
    final frames = _frames(character, slot).toList();
    final before = <Object?>[for (final frame in frames) frame.toJson()];
    switch (actionId) {
      case 'characterStudio.animationFrame.insert':
        final index =
            parameters.optionalNonNegativeInt('frameIndex') ?? frames.length;
        if (index > frames.length) _frameIndexInvalid(index, frames.length);
        frames.insert(index, _parseFrame(parameters.object('frame')));
      case 'characterStudio.animationFrame.update':
        final index = parameters.nonNegativeInt('frameIndex');
        _requireFrameIndex(index, frames.length);
        frames[index] = _parseFrame(parameters.object('frame'));
      case 'characterStudio.animationFrame.reorder':
        final fromIndex = parameters.nonNegativeInt('fromIndex');
        final toIndex = parameters.nonNegativeInt('toIndex');
        _requireFrameIndex(fromIndex, frames.length);
        _requireFrameIndex(toIndex, frames.length);
        final frame = frames.removeAt(fromIndex);
        frames.insert(toIndex, frame);
      case 'characterStudio.animationFrame.delete':
        final index = parameters.nonNegativeInt('frameIndex');
        _requireFrameIndex(index, frames.length);
        frames.removeAt(index);
    }
    final updated = _replaceFrames(character, slot, frames);
    return _characterDraft(
      context,
      manifest: manifest,
      characterIndex: characterIndex,
      updated: updated,
      slot: slot,
      before: before,
      after: <Object?>[for (final frame in frames) frame.toJson()],
      frameCount: frames.length,
    );
  }
}

const Set<String> _slotParameterNames = <String>{
  'characterId',
  'kind',
  'state',
  'definitionId',
  'direction',
};

enum _AnimationSlotKind { system, custom }

final class _AnimationSlot {
  const _AnimationSlot.system({
    required this.state,
    required this.direction,
  })  : kind = _AnimationSlotKind.system,
        definitionId = null;

  const _AnimationSlot.custom({
    required this.definitionId,
    required this.direction,
  })  : kind = _AnimationSlotKind.custom,
        state = null;

  final _AnimationSlotKind kind;
  final CharacterAnimationState? state;
  final String? definitionId;
  final EntityFacing? direction;

  String get pathSegment => switch (kind) {
        _AnimationSlotKind.system => 'system/${state!.name}/${direction!.name}',
        _AnimationSlotKind.custom =>
          'custom/$definitionId/${direction?.name ?? 'single'}',
      };
}

_AnimationSlot _parseSlot(
  ProjectManifest manifest,
  CharacterStudioActionParameters parameters,
) {
  final kind = parameters.string('kind');
  if (kind == 'system') {
    if (parameters.optionalString('definitionId') != null) {
      throw CharacterStudioActionException(
        'character_studio.animation.definition_unexpected',
        'System animation slots do not accept definitionId.',
      );
    }
    final state = _systemState(parameters.string('state'));
    final direction = _direction(parameters.string('direction'));
    return _AnimationSlot.system(state: state, direction: direction);
  }
  if (kind != 'custom') {
    throw CharacterStudioActionException(
      'character_studio.animation.kind_invalid',
      'kind must be system or custom.',
      details: <String, Object?>{'kind': kind},
    );
  }
  if (parameters.optionalString('state') != null) {
    throw CharacterStudioActionException(
      'character_studio.animation.state_unexpected',
      'Custom animation slots do not accept state.',
    );
  }
  final definitionId = parameters.string('definitionId');
  CharacterCustomAnimationDefinition? definition;
  for (final candidate
      in manifest.characterStudioCatalog.customAnimationDefinitions) {
    if (candidate.id == definitionId) {
      definition = candidate;
      break;
    }
  }
  if (definition == null) {
    throw CharacterStudioActionException(
      'character_studio.animation.definition_not_found',
      'The requested custom animation definition does not exist.',
      details: <String, Object?>{'definitionId': definitionId},
    );
  }
  final directionValue = parameters.optionalString('direction');
  if (definition.mode == CharacterCustomAnimationMode.directional &&
      directionValue == null) {
    throw CharacterStudioActionException(
      'character_studio.animation.direction_required',
      'Directional custom animations require a direction.',
      details: <String, Object?>{'definitionId': definitionId},
    );
  }
  if (definition.mode == CharacterCustomAnimationMode.single &&
      directionValue != null) {
    throw CharacterStudioActionException(
      'character_studio.animation.direction_forbidden',
      'Single custom animations do not accept a direction.',
      details: <String, Object?>{'definitionId': definitionId},
    );
  }
  return _AnimationSlot.custom(
    definitionId: definitionId,
    direction: directionValue == null ? null : _direction(directionValue),
  );
}

CharacterAnimationState _systemState(String value) {
  return switch (value) {
    'base' || 'idle' => CharacterAnimationState.idle,
    'walk' => CharacterAnimationState.walk,
    'run' => CharacterAnimationState.run,
    _ => throw CharacterStudioActionException(
        'character_studio.animation.state_invalid',
        'state must be base, walk, or run.',
        details: <String, Object?>{'state': value},
      ),
  };
}

EntityFacing _direction(String value) {
  for (final direction in EntityFacing.values) {
    if (direction.name == value) return direction;
  }
  throw CharacterStudioActionException(
    'character_studio.animation.direction_invalid',
    'direction must be north, south, east, or west.',
    details: <String, Object?>{'direction': value},
  );
}

int _characterIndex(ProjectManifest manifest, String characterId) {
  final index = manifest.characters.indexWhere(
    (character) => character.id == characterId,
  );
  if (index >= 0) return index;
  throw CharacterStudioActionException(
    'character_studio.animation.character_not_found',
    'The requested character does not exist.',
    details: <String, Object?>{'characterId': characterId},
  );
}

int _systemClipIndex(ProjectCharacterEntry character, _AnimationSlot slot) {
  return character.animations.indexWhere(
    (animation) =>
        animation.state == slot.state && animation.direction == slot.direction,
  );
}

int _customClipIndex(ProjectCharacterEntry character, _AnimationSlot slot) {
  return character.customAnimations.indexWhere(
    (animation) =>
        animation.definitionId == slot.definitionId &&
        animation.direction == slot.direction,
  );
}

int _requireClipIndex(int index, _AnimationSlot slot) {
  if (index >= 0) return index;
  throw CharacterStudioActionException(
    'character_studio.animation.clip_not_found',
    'The requested animation clip slot does not exist.',
    details: <String, Object?>{'slot': slot.pathSegment},
  );
}

List<CharacterAnimationFrame> _frames(
  ProjectCharacterEntry character,
  _AnimationSlot slot,
) {
  if (slot.kind == _AnimationSlotKind.system) {
    final index = _requireClipIndex(_systemClipIndex(character, slot), slot);
    return character.animations[index].frames;
  }
  final index = _requireClipIndex(_customClipIndex(character, slot), slot);
  return character.customAnimations[index].frames;
}

ProjectCharacterEntry _replaceFrames(
  ProjectCharacterEntry character,
  _AnimationSlot slot,
  List<CharacterAnimationFrame> frames,
) {
  if (slot.kind == _AnimationSlotKind.system) {
    final index = _requireClipIndex(_systemClipIndex(character, slot), slot);
    final animations = character.animations.toList()
      ..[index] = character.animations[index].copyWith(frames: frames);
    return character.copyWith(animations: animations);
  }
  final index = _requireClipIndex(_customClipIndex(character, slot), slot);
  final animations = character.customAnimations.toList()
    ..[index] = character.customAnimations[index].copyWith(frames: frames);
  return character.copyWith(customAnimations: animations);
}

CharacterAnimationFrame _parseFrame(Map<String, Object?> json) {
  try {
    if (json.keys.any((key) => key != 'source' && key != 'durationMs')) {
      throw const FormatException();
    }
    final sourceValue = json['source'];
    if (sourceValue is! Map || sourceValue.keys.any((key) => key is! String)) {
      throw const FormatException();
    }
    final source = Map<String, Object?>.from(sourceValue);
    if (source.keys.any(
      (key) => key != 'x' && key != 'y' && key != 'width' && key != 'height',
    )) {
      throw const FormatException();
    }
    final x = source['x'];
    final y = source['y'];
    final width = source['width'];
    final height = source['height'];
    final durationMs = json['durationMs'] ?? 150;
    if (x is! int ||
        y is! int ||
        width is! int ||
        height is! int ||
        durationMs is! int ||
        x < 0 ||
        y < 0 ||
        width <= 0 ||
        height <= 0 ||
        durationMs <= 0) {
      throw const FormatException();
    }
    return CharacterAnimationFrame(
      source: TilesetSourceRect(
        x: x,
        y: y,
        width: width,
        height: height,
      ),
      durationMs: durationMs,
    );
  } on Object {
    throw CharacterStudioActionException(
      'character_studio.animation.frame_invalid',
      'frame must contain a positive duration and a valid source rectangle.',
    );
  }
}

void _requireFrameIndex(int index, int length) {
  if (index < length) return;
  _frameIndexInvalid(index, length);
}

Never _frameIndexInvalid(int index, int length) {
  throw CharacterStudioActionException(
    'character_studio.animation.frame_index_invalid',
    'The requested frame index is outside the clip.',
    details: <String, Object?>{'frameIndex': index, 'frameCount': length},
  );
}

AuthoringMutationDraft _characterDraft(
  AuthoringPlanningContext context, {
  required ProjectManifest manifest,
  required int characterIndex,
  required ProjectCharacterEntry updated,
  required _AnimationSlot slot,
  Object? before,
  Object? after,
  bool created = false,
  int? frameCount,
}) {
  final characters = manifest.characters.toList()..[characterIndex] = updated;
  final projected = manifest.copyWith(characters: characters);
  try {
    ProjectValidator.validate(projected);
  } on Object catch (error) {
    throw CharacterStudioActionException(
      'character_studio.animation.projected_state_invalid',
      'The animation action would produce invalid project data.',
      details: <String, Object?>{
        'validationType': error.runtimeType.toString(),
      },
    );
  }
  return characterStudioProjectDraft(
    context.snapshot,
    projected,
    operation: context.request.actionId,
    path: '/characters/${updated.id}/animations/${slot.pathSegment}',
    before: before,
    after: after,
    preview: <String, Object?>{
      'characterId': updated.id,
      'slot': slot.pathSegment,
      'created': created,
      if (frameCount != null) 'frameCount': frameCount,
    },
  );
}
