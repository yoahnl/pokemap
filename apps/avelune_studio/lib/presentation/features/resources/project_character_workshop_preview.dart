import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/rendering/contracts/character_workspace_visuals.dart';
import '../../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/rendering/contracts/scoped_resource_preview_visuals.dart';
import '../../../features/resources/application/resource_preview_source.dart';

class ProjectCharacterWorkshopPreview extends StatefulWidget {
  const ProjectCharacterWorkshopPreview({
    super.key,
    required this.active,
    required this.character,
    required this.project,
    required this.visuals,
    this.showSelectors = true,
    this.initialElapsedMs = 0,
  });

  final bool active;
  final ProjectCharacterEntry character;
  final ProjectManifest project;
  final MapWorkspaceVisuals? visuals;
  final bool showSelectors;
  final int initialElapsedMs;

  @override
  State<ProjectCharacterWorkshopPreview> createState() =>
      _CharacterWorkshopPreviewState();
}

class _CharacterWorkshopPreviewState
    extends State<ProjectCharacterWorkshopPreview>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _elapsedMs = ValueNotifier<int>(0);
  final _clips =
      <CharacterAnimationState, Map<EntityFacing, CharacterAnimation>>{};
  late CharacterAnimationState _state;
  late EntityFacing _facing;
  var _durationMs = 0;
  var _playbackStartMs = 0;

  Map<EntityFacing, CharacterAnimation> get _directions =>
      _clips[_state] ?? const {};
  CharacterAnimation? get _clip => _directions[_facing];

  @override
  void initState() {
    super.initState();
    _setCharacter();
  }

  @override
  void didUpdateWidget(ProjectCharacterWorkshopPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character != widget.character) _setCharacter();
    if (oldWidget.initialElapsedMs != widget.initialElapsedMs) {
      _ticker.stop();
      _elapsedMs.value = widget.initialElapsedMs;
    }
    if (!widget.active || oldWidget.visuals != widget.visuals) _ticker.stop();
  }

  void _setCharacter() {
    _clips.clear();
    for (final clip in widget.character.animations) {
      if (clip.frames.isNotEmpty) {
        (_clips[clip.state] ??= {})[clip.direction] = clip;
      }
    }
    const idle = CharacterAnimationState.idle;
    _facing = EntityFacing.south;
    _selectState(
      _clips.containsKey(idle) ? idle : _clips.keys.firstOrNull ?? idle,
    );
  }

  void _selectState(CharacterAnimationState state) {
    _state = state;
    _selectDirection(
      _directions.containsKey(_facing)
          ? _facing
          : _directions.keys.firstOrNull ?? EntityFacing.south,
    );
  }

  void _selectDirection(EntityFacing facing) {
    _ticker.stop();
    _elapsedMs.value = widget.initialElapsedMs;
    _facing = facing;
    _durationMs =
        _clip?.frames.fold<int>(
          0,
          (total, frame) => total + frame.durationMs,
        ) ??
        0;
  }

  void _togglePlayback() {
    if (_ticker.isActive) {
      _ticker.stop();
      return;
    }
    if (_clip?.loop == false && _elapsedMs.value >= _durationMs - 1) {
      _elapsedMs.value = 0;
    }
    _playbackStartMs = _elapsedMs.value;
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    final timeMs = _playbackStartMs + elapsed.inMilliseconds;
    if (_clip?.loop == false && timeMs >= _durationMs) {
      setState(_ticker.stop);
      _elapsedMs.value = _durationMs - 1;
      return;
    }
    _elapsedMs.value = timeMs;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _elapsedMs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.showSelectors
      ? StudioPanel(
          title: 'Aperçu du sprite',
          icon: Icons.person_outline,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final preview = _stage();
                final controls = _controls();
                return constraints.maxWidth >= 580
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: preview),
                          const SizedBox(width: StudioSpacing.xl),
                          SizedBox(width: 230, child: controls),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          preview,
                          const SizedBox(height: StudioSpacing.l),
                          controls,
                        ],
                      );
              },
            ),
          ],
        )
      : Stack(
          children: [
            _stage(height: 216),
            if (_canPlay)
              Positioned(
                bottom: StudioSpacing.l,
                left: StudioSpacing.l,
                child: _playButton(StudioButtonVariant.secondary),
              ),
          ],
        );

  Widget _stage({double height = 256}) => StudioAssetPreview(
    height: height,
    child: RepaintBoundary(
      child: ValueListenableBuilder<int>(
        valueListenable: _elapsedMs,
        builder: (context, elapsed, _) => _sprite(elapsed),
      ),
    ),
  );

  bool get _canPlay => _durationMs > 0 && (_clip?.frames.length ?? 0) > 1;

  Widget _playButton(StudioButtonVariant variant) {
    final playing = _ticker.isActive;
    return StudioButton(
      label: playing ? 'Pause' : 'Lecture',
      icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
      onPressed: widget.active ? () => setState(_togglePlayback) : null,
      variant: variant,
    );
  }

  Widget _sprite(int elapsed) {
    const size = 168.0;
    final visuals = widget.visuals;
    if (visuals is ScopedResourcePreviewVisuals) {
      return (visuals as ScopedResourcePreviewVisuals).scopedResourcePreview(
        CharacterPreviewSource(
          widget.character,
          facing: _facing,
          animationState: _state,
          elapsedMs: elapsed,
        ),
        widget.project,
        size: size,
      );
    }
    if (visuals is CharacterWorkspaceVisuals) {
      return (visuals as CharacterWorkspaceVisuals).characterAnimationThumbnail(
        widget.character,
        size: size,
        facing: _facing,
        state: _state,
        elapsedMs: elapsed,
      );
    }
    return const Text('Aperçu indisponible');
  }

  Widget _controls() {
    if (_clip == null) return const Text('Aucune animation renseignée.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showSelectors) ...[
          StudioSelect(
            label: 'Animation',
            value: _state.name,
            options: {
              for (final state in _clips.keys)
                state.name: characterAnimationLabel(state),
            },
            onChanged: (value) => setState(
              () => _selectState(CharacterAnimationState.values.byName(value)),
            ),
          ),
          const SizedBox(height: StudioSpacing.l),
          StudioSelect(
            label: 'Direction',
            value: _facing.name,
            options: {
              for (final direction in _directions.keys)
                direction.name: characterFacingLabel(direction),
            },
            onChanged: (value) => setState(
              () => _selectDirection(EntityFacing.values.byName(value)),
            ),
          ),
        ],
        if (_canPlay) ...[
          const SizedBox(height: StudioSpacing.l),
          Align(
            alignment: Alignment.centerLeft,
            child: _playButton(StudioButtonVariant.primary),
          ),
        ],
      ],
    );
  }
}

String characterAnimationLabel(CharacterAnimationState state) =>
    switch (state) {
      CharacterAnimationState.idle => 'Au repos',
      CharacterAnimationState.walk => 'Marche',
      CharacterAnimationState.run => 'Course',
      CharacterAnimationState.climb => 'Échelle',
      CharacterAnimationState.bicycleIdle => 'Vélo au repos',
      CharacterAnimationState.bicycle => 'Vélo',
      CharacterAnimationState.surfIdle => 'Surf au repos',
      CharacterAnimationState.surf => 'Surf',
      CharacterAnimationState.surfEnter => 'Entrée dans l’eau',
      CharacterAnimationState.surfExit => 'Sortie de l’eau',
      CharacterAnimationState.cut => 'Coupe',
      CharacterAnimationState.rockSmash => 'Éclate-Roc',
      CharacterAnimationState.strength => 'Force',
      CharacterAnimationState.push => 'Poussée',
    };

String characterFacingLabel(EntityFacing facing) => switch (facing) {
  EntityFacing.north => 'Nord',
  EntityFacing.south => 'Sud',
  EntityFacing.east => 'Est',
  EntityFacing.west => 'Ouest',
};
