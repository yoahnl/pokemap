import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Align, Text, TextOverflow, Theme;
import 'package:map_core/map_core.dart';

import '../../../design_system/design_system.dart';
import 'cinematic_storyboard_strip.dart';

/// Render-neutral owner for the stage/preview surface extracted in NSC-61.
final class CinematicStagePanel extends StatefulWidget {
  const CinematicStagePanel({
    super.key,
    required this.child,
    this.cinematic,
    this.onApplyPreset,
    this.activeCues = const [],
    this.playbackTimeMs = 0,
  });

  static const surfaceKey = ValueKey<String>('cinematic-stage-panel');

  final Widget child;

  final CinematicAsset? cinematic;
  final ApplyCinematicBlockingPresetCallback? onApplyPreset;
  final List<CinematicPlaybackCue> activeCues;
  final int playbackTimeMs;

  @override
  State<CinematicStagePanel> createState() => _CinematicStagePanelState();
}

final class _CinematicStagePanelState extends State<CinematicStagePanel> {
  String? _selectedShotId;
  bool _storyboardExpanded = false;

  @override
  Widget build(BuildContext context) {
    final shake = _firstCue(
      widget.activeCues,
      CinematicPlaybackCueKind.shake,
    );
    final dialogue = _firstCue(
      widget.activeCues,
      CinematicPlaybackCueKind.dialogue,
    );
    final statusCues = widget.activeCues
        .where(
          (cue) =>
              cue.kind == CinematicPlaybackCueKind.sound ||
              cue.kind == CinematicPlaybackCueKind.music ||
              cue.kind == CinematicPlaybackCueKind.fx ||
              cue.kind == CinematicPlaybackCueKind.shake,
        )
        .toList(growable: false);
    final offset = _shakeOffset(shake, widget.playbackTimeMs);

    return KeyedSubtree(
      key: CinematicStagePanel.surfaceKey,
      child: widget.cinematic == null
          ? widget.child
          : Stack(
              fit: StackFit.expand,
              children: [
                if (shake == null)
                  widget.child
                else
                  Transform.translate(
                    key: const ValueKey('cinematic-stage-playback-transform'),
                    offset: offset,
                    child: widget.child,
                  ),
                if (statusCues.isNotEmpty)
                  Positioned(
                    key: const ValueKey('cinematic-stage-playback-status'),
                    right: 8,
                    top: _storyboardExpanded ? 96 : 8,
                    child: PokeMapCard(
                      padding: const EdgeInsets.all(8),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final cue in statusCues)
                            PokeMapBadge(
                              key: ValueKey(
                                'cinematic-stage-cue-${cue.stepId}',
                              ),
                              label: _cueLabel(cue),
                              variant: cue.kind == CinematicPlaybackCueKind.fx
                                  ? PokeMapBadgeVariant.narrative
                                  : PokeMapBadgeVariant.info,
                            ),
                        ],
                      ),
                    ),
                  ),
                if (dialogue != null)
                  Positioned(
                    key: const ValueKey('cinematic-stage-dialogue-preview'),
                    left: 24,
                    right: 24,
                    bottom: 24,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: PokeMapCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          dialogue.dialogueText ??
                              dialogue.referenceLabel ??
                              'Dialogue',
                          key: const ValueKey(
                            'cinematic-stage-dialogue-preview-text',
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
                if (_storyboardExpanded)
                  Positioned(
                    left: 8,
                    right: 8,
                    top: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CinematicStoryboardStrip(
                        cinematic: widget.cinematic!,
                        selectedShotId: _selectedShotId,
                        onSelectShot: (shot) => setState(() {
                          _selectedShotId = shot.id;
                        }),
                        onApplyPreset: widget.onApplyPreset,
                      ),
                    ),
                  ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: PokeMapIconButton(
                    key: const ValueKey('cinematic-storyboard-toggle'),
                    onPressed: () => setState(() {
                      _storyboardExpanded = !_storyboardExpanded;
                    }),
                    icon: Icon(
                      _storyboardExpanded
                          ? CupertinoIcons.rectangle_compress_vertical
                          : CupertinoIcons.rectangle_expand_vertical,
                      size: 15,
                    ),
                    tooltip: _storyboardExpanded
                        ? 'Masquer le storyboard'
                        : 'Afficher le storyboard',
                    variant: PokeMapIconButtonVariant.soft,
                    isSelected: _storyboardExpanded,
                  ),
                ),
              ],
            ),
    );
  }
}

CinematicPlaybackCue? _firstCue(
  List<CinematicPlaybackCue> cues,
  CinematicPlaybackCueKind kind,
) {
  for (final cue in cues) {
    if (cue.kind == kind) return cue;
  }
  return null;
}

Offset _shakeOffset(CinematicPlaybackCue? cue, int playbackTimeMs) {
  if (cue == null) return Offset.zero;
  final duration = math.max(1, cue.endMs - cue.startMs);
  final progress = ((playbackTimeMs - cue.startMs) / duration).clamp(0.0, 1.0);
  final envelope = math.sin(progress * math.pi);
  final x = math.sin(progress * math.pi * 6) * 8 * cue.intensity * envelope;
  return Offset(x, 0);
}

String _cueLabel(CinematicPlaybackCue cue) {
  final label = cue.referenceLabel;
  return switch (cue.kind) {
    CinematicPlaybackCueKind.shake => 'Secousse',
    CinematicPlaybackCueKind.sound => label == null ? 'Son' : 'Son · $label',
    CinematicPlaybackCueKind.music =>
      label == null ? 'Musique' : 'Musique · $label',
    CinematicPlaybackCueKind.fx => label == null ? 'FX' : 'FX · $label',
    CinematicPlaybackCueKind.dialogue => 'Dialogue',
  };
}
