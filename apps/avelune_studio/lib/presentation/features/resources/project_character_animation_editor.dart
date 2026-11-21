import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/rendering/contracts/scoped_resource_preview_visuals.dart';
import '../../../features/resources/application/resource_preview_source.dart';
import '../../../features/resources/domain/project_character_workshop_port.dart';
import '../../../features/resources/domain/project_library_editor.dart';
import '../../../features/resources/domain/resource_port.dart';
import 'project_character_pose_sheet.dart';
import 'project_character_workshop_preview.dart';
import 'project_character_workspace_layout.dart';

part 'project_character_animation_import.dart';
part 'project_character_animation_timeline.dart';
part 'project_character_animation_layout.dart';
part 'project_character_animation_navigation.dart';

class ProjectCharacterAnimationEditor extends StatefulWidget {
  const ProjectCharacterAnimationEditor({
    super.key,
    required this.project,
    required this.character,
    required this.visuals,
    required this.enabled,
    required this.edit,
    required this.pickImage,
    required this.onDirty,
  });

  final ProjectManifest project;
  final ProjectCharacterEntry character;
  final MapWorkspaceVisuals? visuals;
  final bool enabled;
  final EditWorkshopCharacter edit;
  final Future<PickedProjectLibraryFile?> Function() pickImage;
  final ValueChanged<bool> onDirty;

  @override
  State<ProjectCharacterAnimationEditor> createState() =>
      _ProjectCharacterAnimationEditorState();
}

class _ProjectCharacterAnimationEditorState
    extends State<ProjectCharacterAnimationEditor> {
  late String _selection = _preferredSystem.name;
  late EntityFacing _facing = _preferredDirection(EntityFacing.south);
  var _position = 0;
  List<CharacterAnimationFrame>? _frames;
  bool? _loop;
  String? _invalidDuration;
  String? _problem;
  String? _newAnimationName;
  final _timelineScroll = ScrollController();

  CharacterAnimationState get _preferredSystem =>
      widget.character.animations.any(
        (clip) => clip.state == CharacterAnimationState.walk,
      )
      ? CharacterAnimationState.walk
      : widget.character.animations.firstOrNull?.state ??
            CharacterAnimationState.idle;

  CharacterCustomAnimationDefinition? get _custom => widget
      .project
      .characterStudioCatalog
      .customAnimationDefinitions
      .where((definition) => _selection == 'custom:${definition.id}')
      .firstOrNull;

  CharacterAnimationState get _state =>
      CharacterAnimationState.values
          .where((state) => state.name == _selection)
          .firstOrNull ??
      CharacterAnimationState.idle;

  bool get _single => _custom?.mode == CharacterCustomAnimationMode.single;

  CharacterAnimation? get _systemClip => _custom == null
      ? widget.character.animations
            .where((clip) => clip.state == _state && clip.direction == _facing)
            .firstOrNull
      : null;

  CharacterCustomAnimationClip? get _customClip => widget
      .character
      .customAnimations
      .where(
        (clip) =>
            clip.definitionId == _custom?.id &&
            clip.direction == (_single ? null : _facing),
      )
      .firstOrNull;

  String? get _sourceId =>
      _systemClip?.sourceAssetId ?? _customClip?.sourceAssetId;
  int? get _referenceHeight =>
      _systemClip?.presentationReferenceHeightPx ??
      _customClip?.presentationReferenceHeightPx;
  List<CharacterAnimationFrame> get _saved =>
      _systemClip?.frames ?? _customClip?.frames ?? const [];
  List<CharacterAnimationFrame> get _poses => _frames ?? _saved;
  bool get _defaultLoop =>
      _state != CharacterAnimationState.surfEnter &&
      _state != CharacterAnimationState.surfExit;
  bool get _savedLoop => _systemClip?.loop ?? _customClip?.loop ?? _defaultLoop;
  bool get _dirty =>
      _frames != null || _loop != null || _invalidDuration != null;
  bool get _canNavigate => widget.enabled && !_dirty;
  bool get _canSave =>
      widget.enabled &&
      _dirty &&
      _invalidDuration == null &&
      (_poses.isNotEmpty || _saved.isNotEmpty);
  int get _width =>
      widget.project.settings.tileWidth *
      widget.character.frameWidth.clamp(2, 1 << 20);
  int get _height =>
      widget.project.settings.tileHeight *
      widget.character.frameHeight.clamp(2, 1 << 20);

  Map<String, Object?> get _slot => {
    'kind': _custom == null ? 'system' : 'custom',
    if (_custom case final definition?)
      'definitionId': definition.id
    else
      'state': CharacterAnimation(
        state: _state,
        direction: _facing,
      ).toJson()['state'],
    if (!_single) 'direction': _facing.name,
  };

  void _change(VoidCallback update) {
    setState(update);
    widget.onDirty(_dirty);
  }

  void _reset() {
    _frames = null;
    _loop = null;
    _invalidDuration = null;
    _problem = null;
  }

  void _selectAnimation(String selection) => _change(() {
    _selection = selection;
    _facing = _preferredDirection(_facing);
    _position = 0;
    _reset();
    if (_timelineScroll.hasClients) _timelineScroll.jumpTo(0);
  });

  void _selectDirection(EntityFacing direction) {
    if (!_canNavigate || direction == _facing) return;
    _change(() {
      _facing = direction;
      _position = 0;
      _reset();
      if (_timelineScroll.hasClients) _timelineScroll.jumpTo(0);
    });
  }

  void _setLoop(bool value) =>
      _change(() => _loop = value == _savedLoop ? null : value);

  EntityFacing _preferredDirection(EntityFacing current) =>
      _poseCount(current) > 0
      ? current
      : EntityFacing.values
                .where((facing) => _poseCount(facing) > 0)
                .firstOrNull ??
            EntityFacing.south;

  int _poseCount(EntityFacing direction) => switch (_custom) {
    final definition? =>
      widget.character.customAnimations
              .where(
                (clip) =>
                    clip.definitionId == definition.id &&
                    clip.direction == direction,
              )
              .firstOrNull
              ?.frames
              .length ??
          0,
    null =>
      widget.character.animations
              .where(
                (clip) => clip.state == _state && clip.direction == direction,
              )
              .firstOrNull
              ?.frames
              .length ??
          0,
  };

  void _selectPose(int position) => _change(() {
    _position = position;
    _invalidDuration = null;
  });

  void _discard() => _change(() {
    _position = _position.clamp(0, _saved.isEmpty ? 0 : _saved.length - 1);
    _reset();
  });

  void _replacePoses(List<CharacterAnimationFrame> poses) {
    _frames = _samePoses(poses, _saved) ? null : poses;
    _invalidDuration = null;
  }

  void _assign(TilesetSourceRect source) => _change(() {
    final poses = _poses.toList();
    if (_position < poses.length) {
      poses[_position] = poses[_position].copyWith(source: source);
    } else {
      poses.add(CharacterAnimationFrame(source: source, durationMs: 150));
    }
    _replacePoses(poses);
  });

  void _setDuration(String value) => _change(() {
    final duration = int.tryParse(value);
    if (duration == null || duration < 1 || duration > 60000) {
      _invalidDuration = value;
      return;
    }
    final poses = _poses.toList();
    poses[_position] = poses[_position].copyWith(durationMs: duration);
    _replacePoses(poses);
  });

  Future<void> _save() async {
    if (!_canSave) return;
    final poses = _poses;
    final saved = await widget.edit(
      poses.isEmpty
          ? 'characterStudio.animationClip.delete'
          : 'characterStudio.animationClip.upsert',
      {
        ..._slot,
        if (poses.isNotEmpty)
          'frames': poses.map((pose) => pose.toJson()).toList(),
        if (poses.isNotEmpty) 'loop': _loop ?? _savedLoop,
      },
    );
    if (saved && mounted) _change(_reset);
  }

  Future<void> _create() async {
    final choice = await _describeCustomCharacterAnimation(context);
    if (choice == null || !mounted) return;
    _newAnimationName = choice.name;
    final created = await widget.edit(
      'characterStudio.animationDefinition.create',
      {
        'displayName': choice.name,
        'mode': choice.directional ? 'directional' : 'single',
      },
    );
    if (!created) _newAnimationName = null;
  }

  @override
  void didUpdateWidget(ProjectCharacterAnimationEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final name = _newAnimationName;
    if (name == null) return;
    final definition = widget
        .project
        .characterStudioCatalog
        .customAnimationDefinitions
        .where((definition) => definition.displayName == name)
        .firstOrNull;
    if (definition == null) return;
    _selection = 'custom:${definition.id}';
    _facing = _preferredDirection(EntityFacing.south);
    _position = 0;
    _newAnimationName = null;
  }

  ProjectCharacterEntry get _previewCharacter => widget.character.copyWith(
    customAnimations: const [],
    animations: _poses.isEmpty
        ? const []
        : [
            CharacterAnimation(
              state: _state,
              direction: _facing,
              sourceAssetId: _sourceId,
              presentationReferenceHeightPx: _referenceHeight,
              frames: _poses,
              loop: _loop ?? _savedLoop,
            ),
          ],
  );

  @override
  Widget build(BuildContext context) => _buildEditor(context);

  @override
  void dispose() {
    _timelineScroll.dispose();
    super.dispose();
  }
}

bool _samePoses(
  List<CharacterAnimationFrame> left,
  List<CharacterAnimationFrame> right,
) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
