import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/presentation_renderer.dart';

import '../../../design_system/design_system.dart';
import 'presentation_studio_layer_tree.dart';
import 'presentation_studio_viewport.dart';

const presentationStudioResponsiveCanvasKey = ValueKey<String>(
  'presentation-studio-responsive-canvas',
);
const presentationStudioLandscapeModeKey = ValueKey<String>(
  'presentation-studio-landscape-mode',
);
const presentationStudioPortraitModeKey = ValueKey<String>(
  'presentation-studio-portrait-mode',
);
const presentationStudioCompareModeKey = ValueKey<String>(
  'presentation-studio-compare-mode',
);
const presentationStudioResponsiveMediaBlockerKey = ValueKey<String>(
  'presentation-studio-responsive-media-blocker',
);

enum PresentationStudioCanvasMode { landscape, portrait, compare }

enum PresentationStudioResponsiveMediaKind {
  image,
  video,
  poster,
  voice,
  soundEffect,
  music,
}

final class PresentationStudioResponsiveMediaBinding {
  const PresentationStudioResponsiveMediaBinding({
    required this.clipId,
    required this.kind,
    this.landscapeResourceId,
    this.landscapeDurationUs,
    this.portraitResourceId,
    this.portraitDurationUs,
    this.sharedResourceId,
    this.sharedDurationUs,
    this.requireDurationMetadata = true,
  });

  final String clipId;
  final PresentationStudioResponsiveMediaKind kind;
  final String? landscapeResourceId;
  final int? landscapeDurationUs;
  final String? portraitResourceId;
  final int? portraitDurationUs;
  final String? sharedResourceId;
  final int? sharedDurationUs;
  final bool requireDurationMetadata;

  String? resourceIdFor(PresentationFrameOrientation orientation) {
    if (kind == PresentationStudioResponsiveMediaKind.music) {
      return sharedResourceId;
    }
    return switch (orientation) {
      PresentationFrameOrientation.landscape =>
        landscapeResourceId ?? sharedResourceId ?? portraitResourceId,
      PresentationFrameOrientation.portrait =>
        portraitResourceId ?? sharedResourceId ?? landscapeResourceId,
    };
  }
}

final class PresentationStudioResponsiveCanvasController
    extends ChangeNotifier {
  PresentationStudioResponsiveCanvasController({
    PresentationStudioCanvasMode mode = PresentationStudioCanvasMode.landscape,
    int playheadUs = 0,
    PresentationStudioSelection? initialSelection,
  }) : _mode = mode,
       _playheadUs = playheadUs,
       selection = PresentationStudioSelectionController(
         initialSelection: initialSelection,
       ),
       _activeOrientation = mode == PresentationStudioCanvasMode.portrait
           ? PresentationFrameOrientation.portrait
           : PresentationFrameOrientation.landscape {
    if (playheadUs < 0) {
      throw ArgumentError.value(
        playheadUs,
        'playheadUs',
        'must be nonnegative',
      );
    }
  }

  final landscapeViewport = PresentationStudioViewportController();
  final portraitViewport = PresentationStudioViewportController();
  final PresentationStudioSelectionController selection;
  PresentationStudioCanvasMode _mode;
  int _playheadUs;
  PresentationFrameOrientation _activeOrientation;

  PresentationStudioCanvasMode get mode => _mode;
  int get playheadUs => _playheadUs;
  String? get selectedClipId => selection.value?.clipId;
  PresentationFrameOrientation get activeOrientation => _activeOrientation;

  void setMode(PresentationStudioCanvasMode value) {
    if (_mode == value) return;
    _mode = value;
    if (value == PresentationStudioCanvasMode.landscape) {
      _activeOrientation = PresentationFrameOrientation.landscape;
    } else if (value == PresentationStudioCanvasMode.portrait) {
      _activeOrientation = PresentationFrameOrientation.portrait;
    }
    notifyListeners();
  }

  void seekTo(int timeUs) {
    if (timeUs < 0) {
      throw ArgumentError.value(timeUs, 'timeUs', 'must be nonnegative');
    }
    if (_playheadUs == timeUs) return;
    _playheadUs = timeUs;
    selection.resetCanvasCycle();
    notifyListeners();
  }

  void focus(PresentationFrameOrientation orientation) {
    if (_activeOrientation == orientation) return;
    _activeOrientation = orientation;
    notifyListeners();
  }

  void fitVisibleViewports() {
    switch (_mode) {
      case PresentationStudioCanvasMode.landscape:
        landscapeViewport.fit();
      case PresentationStudioCanvasMode.portrait:
        portraitViewport.fit();
      case PresentationStudioCanvasMode.compare:
        landscapeViewport.fit();
        portraitViewport.fit();
    }
  }

  @override
  void dispose() {
    landscapeViewport.dispose();
    portraitViewport.dispose();
    selection.dispose();
    super.dispose();
  }
}

class PresentationStudioResponsiveToolbar extends StatelessWidget {
  const PresentationStudioResponsiveToolbar({
    super.key,
    required this.controller,
  });

  final PresentationStudioResponsiveCanvasController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            PokeMapBadge(
              label: 'Aperçu ${_formatTime(controller.playheadUs)}',
              variant: PokeMapBadgeVariant.info,
            ),
            const SizedBox(width: 8),
            _modeButton(
              key: presentationStudioLandscapeModeKey,
              label: '16:9',
              mode: PresentationStudioCanvasMode.landscape,
            ),
            const SizedBox(width: 6),
            _modeButton(
              key: presentationStudioPortraitModeKey,
              label: '9:16',
              mode: PresentationStudioCanvasMode.portrait,
            ),
            const SizedBox(width: 6),
            _modeButton(
              key: presentationStudioCompareModeKey,
              label: 'Comparer',
              mode: PresentationStudioCanvasMode.compare,
              icon: const Icon(Icons.vertical_split_rounded),
            ),
            const SizedBox(width: 6),
            PokeMapButton(
              onPressed: controller.fitVisibleViewports,
              size: PokeMapButtonSize.small,
              variant: PokeMapButtonVariant.ghost,
              leading: const Icon(Icons.fit_screen_rounded),
              child: const Text('Ajuster'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeButton({
    required Key key,
    required String label,
    required PresentationStudioCanvasMode mode,
    Widget? icon,
  }) {
    return PokeMapButton(
      key: key,
      onPressed: () => controller.setMode(mode),
      size: PokeMapButtonSize.small,
      variant: PokeMapButtonVariant.secondary,
      isSelected: controller.mode == mode,
      leading: icon,
      child: Text(label),
    );
  }
}

class PresentationStudioResponsiveCanvas extends StatelessWidget {
  const PresentationStudioResponsiveCanvas({
    super.key,
    required this.controller,
    required this.frameBuilder,
    required this.contentPort,
    required this.playerTheme,
    this.orientationOverrides = const PresentationFrameOrientationOverrides(),
    this.mediaBindings = const <PresentationStudioResponsiveMediaBinding>[],
    this.asset,
  });

  final PresentationStudioResponsiveCanvasController controller;
  final PresentationFrame? Function(int playheadUs) frameBuilder;
  final PresentationFrameContentPort contentPort;
  final ThemeData playerTheme;
  final PresentationFrameOrientationOverrides orientationOverrides;
  final List<PresentationStudioResponsiveMediaBinding> mediaBindings;
  final PresentationCinematicAsset? asset;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      key: presentationStudioResponsiveCanvasKey,
      animation: controller,
      builder: (context, _) {
        final frame = frameBuilder(controller.playheadUs);
        final issues = frame == null
            ? const <String>[]
            : _validateBindings(frame, mediaBindings);
        if (issues.isNotEmpty) {
          return PokeMapEmptyState(
            key: presentationStudioResponsiveMediaBlockerKey,
            title: 'Composition responsive bloquée',
            description: issues.join('\n'),
            icon: const Icon(Icons.warning_amber_rounded),
          );
        }
        final responsivePort = _PresentationStudioResponsiveContentPort(
          delegate: contentPort,
          bindings: {
            for (final binding in mediaBindings) binding.clipId: binding,
          },
        );
        return switch (controller.mode) {
          PresentationStudioCanvasMode.landscape => _viewport(
            frame: frame,
            orientation: PresentationFrameOrientation.landscape,
            contentPort: responsivePort,
          ),
          PresentationStudioCanvasMode.portrait => _viewport(
            frame: frame,
            orientation: PresentationFrameOrientation.portrait,
            contentPort: responsivePort,
          ),
          PresentationStudioCanvasMode.compare => Row(
            children: [
              Expanded(
                child: _viewport(
                  frame: frame,
                  orientation: PresentationFrameOrientation.landscape,
                  contentPort: responsivePort,
                  showLabel: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _viewport(
                  frame: frame,
                  orientation: PresentationFrameOrientation.portrait,
                  contentPort: responsivePort,
                  showLabel: true,
                ),
              ),
            ],
          ),
        };
      },
    );
  }

  Widget _viewport({
    required PresentationFrame? frame,
    required PresentationFrameOrientation orientation,
    required PresentationFrameContentPort contentPort,
    bool showLabel = false,
  }) {
    final viewport = PresentationStudioViewport(
      key: ValueKey<String>('presentation-studio-${orientation.name}-viewport'),
      controller: switch (orientation) {
        PresentationFrameOrientation.landscape => controller.landscapeViewport,
        PresentationFrameOrientation.portrait => controller.portraitViewport,
      },
      frame: frame,
      orientation: orientation,
      contentPort: contentPort,
      playerTheme: playerTheme,
      orientationOverrides: orientationOverrides,
      onFocused: () => controller.focus(orientation),
      onCompositionTap: frame == null || asset == null
          ? null
          : (position) => controller.selection.selectCanvas(
              asset: asset!,
              frame: frame,
              normalizedPosition: position,
            ),
    );
    if (!showLabel) return viewport;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: PokeMapBadge(
            label: switch (orientation) {
              PresentationFrameOrientation.landscape => 'Paysage 16:9',
              PresentationFrameOrientation.portrait => 'Portrait 9:16',
            },
            variant: controller.activeOrientation == orientation
                ? PokeMapBadgeVariant.info
                : PokeMapBadgeVariant.neutral,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(child: viewport),
      ],
    );
  }
}

final class _PresentationStudioResponsiveContentPort
    implements PresentationFrameContentPort {
  const _PresentationStudioResponsiveContentPort({
    required this.delegate,
    required this.bindings,
  });

  final PresentationFrameContentPort delegate;
  final Map<String, PresentationStudioResponsiveMediaBinding> bindings;

  @override
  PresentationVisualResolution resolveVisual({
    required PresentationVisualFrameClip clip,
    required PresentationFrameOrientation orientation,
  }) {
    final resourceId = bindings[clip.clipId]?.resourceIdFor(orientation);
    return delegate.resolveVisual(
      clip: resourceId == null || resourceId == clip.resourceId
          ? clip
          : _withResourceId(clip, resourceId),
      orientation: orientation,
    );
  }

  @override
  PresentationCaptionResolution resolveCaption({
    required PresentationCaptionFrameClip clip,
    required Locale locale,
  }) => delegate.resolveCaption(clip: clip, locale: locale);
}

PresentationVisualFrameClip _withResourceId(
  PresentationVisualFrameClip clip,
  String resourceId,
) => PresentationVisualFrameClip(
  clipId: clip.clipId,
  trackId: clip.trackId,
  layerId: clip.layerId,
  zIndex: clip.zIndex,
  resourceId: resourceId,
  startUs: clip.startUs,
  durationUs: clip.durationUs,
  elapsedUs: clip.elapsedUs,
  progress: clip.progress,
  easedProgress: clip.easedProgress,
  easing: clip.easing,
  composition: clip.composition,
  reducedMotionComposition: clip.reducedMotionComposition,
  reducedFlashOpacity: clip.reducedFlashOpacity,
);

List<String> _validateBindings(
  PresentationFrame frame,
  List<PresentationStudioResponsiveMediaBinding> bindings,
) {
  final clipDurations = <String, int>{
    for (final clip in frame.visuals) clip.clipId: clip.durationUs,
    for (final clip in frame.audio) clip.clipId: clip.durationUs,
  };
  final issues = <String>[];
  final ids = <String>{};
  for (final binding in bindings) {
    if (!ids.add(binding.clipId)) {
      issues.add('Le clip ${binding.clipId} possède plusieurs liaisons média.');
      continue;
    }
    final clipDurationUs = clipDurations[binding.clipId];
    if (clipDurationUs == null) {
      continue;
    }
    if (binding.kind == PresentationStudioResponsiveMediaKind.music) {
      if (binding.sharedResourceId == null ||
          binding.landscapeResourceId != null ||
          binding.portraitResourceId != null) {
        issues.add(
          'La musique ${binding.clipId} doit garder une source partagée unique.',
        );
        continue;
      }
      _validateDuration(
        issues: issues,
        resourceId: binding.sharedResourceId!,
        availableUs: binding.sharedDurationUs,
        requiredUs: clipDurationUs,
        requiredMetadata: true,
      );
      continue;
    }
    if (binding.sharedResourceId == null &&
        binding.landscapeResourceId == null &&
        binding.portraitResourceId == null) {
      issues.add(
        'Le clip ${binding.clipId} doit fournir au moins une source média.',
      );
      continue;
    }
    final timed =
        binding.kind == PresentationStudioResponsiveMediaKind.video ||
        binding.kind == PresentationStudioResponsiveMediaKind.voice ||
        binding.kind == PresentationStudioResponsiveMediaKind.soundEffect;
    if (binding.sharedResourceId case final resourceId?) {
      _validateDuration(
        issues: issues,
        resourceId: resourceId,
        availableUs: binding.sharedDurationUs,
        requiredUs: clipDurationUs,
        requiredMetadata: timed && binding.requireDurationMetadata,
      );
    }
    if (binding.landscapeResourceId case final resourceId?) {
      _validateDuration(
        issues: issues,
        resourceId: resourceId,
        availableUs: binding.landscapeDurationUs,
        requiredUs: clipDurationUs,
        requiredMetadata: timed && binding.requireDurationMetadata,
      );
    }
    if (binding.portraitResourceId case final resourceId?) {
      _validateDuration(
        issues: issues,
        resourceId: resourceId,
        availableUs: binding.portraitDurationUs,
        requiredUs: clipDurationUs,
        requiredMetadata: timed && binding.requireDurationMetadata,
      );
    }
  }
  return issues;
}

void _validateDuration({
  required List<String> issues,
  required String resourceId,
  required int? availableUs,
  required int requiredUs,
  required bool requiredMetadata,
}) {
  if (availableUs == null) {
    if (requiredMetadata) {
      issues.add('La durée de $resourceId est inconnue.');
    }
    return;
  }
  if (availableUs < requiredUs) {
    issues.add(
      '$resourceId est trop court : $availableUs µs disponibles pour $requiredUs µs.',
    );
  }
}

String _formatTime(int timeUs) {
  final milliseconds = timeUs ~/ 1000;
  final minutes = milliseconds ~/ 60000;
  final seconds = (milliseconds ~/ 1000) % 60;
  final remainder = milliseconds % 1000;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}.'
      '${remainder.toString().padLeft(3, '0')}';
}
