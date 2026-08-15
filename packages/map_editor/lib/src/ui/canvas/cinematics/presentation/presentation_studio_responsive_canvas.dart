import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
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
const presentationStudioTransportShortcutsKey = ValueKey<String>(
  'presentation-studio-transport-shortcuts',
);
const presentationStudioFrameBackwardKey = ValueKey<String>(
  'presentation-studio-frame-backward',
);
const presentationStudioPlayPauseKey = ValueKey<String>(
  'presentation-studio-play-pause',
);
const presentationStudioStopKey = ValueKey<String>('presentation-studio-stop');
const presentationStudioFrameForwardKey = ValueKey<String>(
  'presentation-studio-frame-forward',
);
const presentationStudioLoopKey = ValueKey<String>('presentation-studio-loop');

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
    required int durationUs,
    PresentationStudioCanvasMode mode = PresentationStudioCanvasMode.landscape,
    int playheadUs = 0,
    PresentationStudioSelection? initialSelection,
  }) : _mode = mode,
       _playbackClock = PresentationPlaybackClock(
         durationUs: durationUs,
         initialPlayheadUs: playheadUs,
       ),
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
  final PresentationPlaybackClock _playbackClock;
  PresentationStudioCanvasMode _mode;
  PresentationFrameOrientation _activeOrientation;
  String? _previewErrorMessage;
  bool _disposed = false;

  PresentationStudioCanvasMode get mode => _mode;
  int get durationUs => _playbackClock.durationUs;
  int get playheadUs => _playbackClock.playheadUs;
  bool get loop => _playbackClock.loop;
  PresentationPlaybackStatus get status => _playbackClock.status;
  PresentationMediaClockPolicy get mediaClockPolicy =>
      _playbackClock.mediaClockPolicy;
  String? get previewErrorMessage => _previewErrorMessage;
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
    final previous = playheadUs;
    _playbackClock.seekTo(timeUs);
    if (previous == playheadUs) return;
    selection.resetCanvasCycle();
    notifyListeners();
  }

  int? play() {
    final previous = status;
    final token = _playbackClock.play();
    if (previous != status) notifyListeners();
    return token;
  }

  int? resume() {
    final previous = status;
    final token = _playbackClock.resume();
    if (previous != status) notifyListeners();
    return token;
  }

  void pause() => _applyTransport(_playbackClock.pause);

  void stop() {
    final previous = (status, playheadUs);
    _playbackClock.stop();
    if (previous != (status, playheadUs)) {
      selection.resetCanvasCycle();
      notifyListeners();
    }
  }

  void stepForward() => _applyPlayheadTransport(_playbackClock.stepForward);

  void stepBackward() => _applyPlayheadTransport(_playbackClock.stepBackward);

  void setLoop(bool value) {
    if (loop == value) return;
    _playbackClock.setLoop(value);
    notifyListeners();
  }

  void holdForInteraction() =>
      _applyTransport(_playbackClock.holdForInteraction);

  bool advanceBy(int deltaUs, {required int token}) {
    final changed = _playbackClock.advanceBy(deltaUs, token: token);
    if (changed) {
      selection.resetCanvasCycle();
      notifyListeners();
    }
    return changed;
  }

  void configureDuration(int value, {bool notify = true}) {
    final previous = (durationUs, playheadUs, status);
    _playbackClock.configureDuration(value);
    if (previous == (durationUs, playheadUs, status)) return;
    selection.resetCanvasCycle();
    if (notify) notifyListeners();
  }

  void setLoading() {
    _previewErrorMessage = null;
    _applyTransport(_playbackClock.setLoading);
  }

  void setError([String message = 'Le rendu de l’aperçu a échoué.']) {
    final previous = (status, _previewErrorMessage);
    _previewErrorMessage = message;
    _playbackClock.setError();
    if (previous != (status, _previewErrorMessage)) notifyListeners();
  }

  void setReady() {
    _previewErrorMessage = null;
    _applyTransport(_playbackClock.setReady);
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

  void _applyTransport(void Function() operation) {
    final previous = (status, playheadUs, mediaClockPolicy);
    operation();
    if (previous != (status, playheadUs, mediaClockPolicy)) {
      notifyListeners();
    }
  }

  void _applyPlayheadTransport(void Function() operation) {
    final previous = (status, playheadUs);
    operation();
    if (previous == (status, playheadUs)) return;
    selection.resetCanvasCycle();
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _playbackClock.dispose();
    landscapeViewport.dispose();
    portraitViewport.dispose();
    selection.dispose();
    super.dispose();
  }
}

class PresentationStudioResponsiveToolbar extends StatefulWidget {
  const PresentationStudioResponsiveToolbar({
    super.key,
    required this.controller,
  });

  final PresentationStudioResponsiveCanvasController controller;

  @override
  State<PresentationStudioResponsiveToolbar> createState() =>
      _PresentationStudioResponsiveToolbarState();
}

class _PresentationStudioResponsiveToolbarState
    extends State<PresentationStudioResponsiveToolbar>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  final FocusNode _focusNode = FocusNode(
    debugLabel: 'Presentation Studio transports',
  );
  Duration _lastTick = Duration.zero;
  int? _activeToken;

  PresentationStudioResponsiveCanvasController get controller =>
      widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_tick);
  }

  @override
  void didUpdateWidget(
    covariant PresentationStudioResponsiveToolbar oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) _stopTicker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed ||
        controller.status != PresentationPlaybackStatus.playing) {
      return;
    }
    controller.pause();
    _stopTicker();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.space): _togglePlayback,
          const SingleActivator(LogicalKeyboardKey.home): _stop,
          const SingleActivator(LogicalKeyboardKey.arrowLeft): _stepBackward,
          const SingleActivator(LogicalKeyboardKey.arrowRight): _stepForward,
          const SingleActivator(LogicalKeyboardKey.keyL): _toggleLoop,
        },
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          child: GestureDetector(
            key: presentationStudioTransportShortcutsKey,
            behavior: HitTestBehavior.opaque,
            onTap: _focusNode.requestFocus,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  PokeMapBadge(
                    label: _statusLabel,
                    variant: _statusBadgeVariant,
                  ),
                  const SizedBox(width: 8),
                  PokeMapIconButton(
                    key: presentationStudioFrameBackwardKey,
                    onPressed: _transportsEnabled ? _stepBackward : null,
                    icon: const Icon(Icons.skip_previous_rounded),
                    tooltip: 'Frame précédente',
                    disabledReason: _disabledReason,
                    variant: PokeMapIconButtonVariant.soft,
                  ),
                  const SizedBox(width: 4),
                  PokeMapIconButton(
                    key: presentationStudioPlayPauseKey,
                    onPressed: _transportsEnabled ? _togglePlayback : null,
                    icon: Icon(
                      controller.status == PresentationPlaybackStatus.playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    tooltip:
                        controller.status == PresentationPlaybackStatus.playing
                        ? 'Pause'
                        : 'Lecture',
                    disabledReason: _disabledReason,
                    isSelected:
                        controller.status == PresentationPlaybackStatus.playing,
                    variant: PokeMapIconButtonVariant.soft,
                  ),
                  const SizedBox(width: 4),
                  PokeMapIconButton(
                    key: presentationStudioStopKey,
                    onPressed: _transportsEnabled ? _stop : null,
                    icon: const Icon(Icons.stop_rounded),
                    tooltip: 'Stop et retour au début',
                    disabledReason: _disabledReason,
                    variant: PokeMapIconButtonVariant.soft,
                  ),
                  const SizedBox(width: 4),
                  PokeMapIconButton(
                    key: presentationStudioFrameForwardKey,
                    onPressed: _transportsEnabled ? _stepForward : null,
                    icon: const Icon(Icons.skip_next_rounded),
                    tooltip: 'Frame suivante',
                    disabledReason: _disabledReason,
                    variant: PokeMapIconButtonVariant.soft,
                  ),
                  const SizedBox(width: 4),
                  PokeMapIconButton(
                    key: presentationStudioLoopKey,
                    onPressed: _transportsEnabled ? _toggleLoop : null,
                    icon: const Icon(Icons.repeat_rounded),
                    tooltip: controller.loop
                        ? 'Désactiver la boucle'
                        : 'Activer la boucle',
                    disabledReason: _disabledReason,
                    isSelected: controller.loop,
                    variant: PokeMapIconButtonVariant.soft,
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
          ),
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

  bool get _transportsEnabled =>
      controller.durationUs > 0 &&
      controller.status != PresentationPlaybackStatus.loading &&
      controller.status != PresentationPlaybackStatus.error &&
      controller.status != PresentationPlaybackStatus.disposed;

  String? get _disabledReason => switch (controller.status) {
    PresentationPlaybackStatus.loading =>
      'L’aperçu est en cours de chargement.',
    PresentationPlaybackStatus.error => 'Le rendu de l’aperçu a échoué.',
    _ when controller.durationUs == 0 => 'La cinématique est vide.',
    _ => null,
  };

  String get _statusLabel => switch (controller.status) {
    PresentationPlaybackStatus.loading => 'Chargement de l’aperçu',
    PresentationPlaybackStatus.error => 'Aperçu indisponible',
    PresentationPlaybackStatus.interactionHold => 'Interaction en attente',
    _ =>
      '${_formatTime(controller.playheadUs)} / ${_formatTime(controller.durationUs)}',
  };

  PokeMapBadgeVariant get _statusBadgeVariant => switch (controller.status) {
    PresentationPlaybackStatus.error => PokeMapBadgeVariant.error,
    PresentationPlaybackStatus.interactionHold => PokeMapBadgeVariant.warning,
    _ => PokeMapBadgeVariant.info,
  };

  void _togglePlayback() {
    if (!_transportsEnabled) return;
    if (controller.status == PresentationPlaybackStatus.playing) {
      controller.pause();
      _stopTicker();
      return;
    }
    _activeToken =
        controller.status == PresentationPlaybackStatus.paused ||
            controller.status == PresentationPlaybackStatus.interactionHold
        ? controller.resume()
        : controller.play();
    if (_activeToken != null && !_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    }
  }

  void _stop() {
    if (!_transportsEnabled) return;
    _stopTicker();
    controller.stop();
  }

  void _stepBackward() {
    if (!_transportsEnabled) return;
    _stopTicker();
    controller.stepBackward();
  }

  void _stepForward() {
    if (!_transportsEnabled) return;
    _stopTicker();
    controller.stepForward();
  }

  void _toggleLoop() {
    if (!_transportsEnabled) return;
    controller.setLoop(!controller.loop);
  }

  void _tick(Duration elapsed) {
    final token = _activeToken;
    if (token == null) {
      _stopTicker();
      return;
    }
    final delta = elapsed - _lastTick;
    _lastTick = elapsed;
    controller.advanceBy(delta.inMicroseconds, token: token);
    if (controller.status != PresentationPlaybackStatus.playing) {
      _stopTicker();
    }
  }

  void _stopTicker() {
    if (_ticker.isActive) _ticker.stop(canceled: false);
    _lastTick = Duration.zero;
    _activeToken = null;
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
    this.reduceMotion,
    this.reduceFlashes = false,
    this.showCaptions = true,
    this.asset,
    this.onRetry,
  });

  final PresentationStudioResponsiveCanvasController controller;
  final PresentationFrame? Function(int playheadUs) frameBuilder;
  final PresentationFrameContentPort contentPort;
  final ThemeData playerTheme;
  final PresentationFrameOrientationOverrides orientationOverrides;
  final List<PresentationStudioResponsiveMediaBinding> mediaBindings;
  final bool? reduceMotion;
  final bool reduceFlashes;
  final bool showCaptions;
  final PresentationCinematicAsset? asset;
  final VoidCallback? onRetry;

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
      state: switch (controller.status) {
        PresentationPlaybackStatus.loading =>
          PresentationStudioViewportState.loading,
        PresentationPlaybackStatus.error =>
          PresentationStudioViewportState.error,
        _ => PresentationStudioViewportState.ready,
      },
      errorMessage: controller.previewErrorMessage,
      reduceMotion: reduceMotion,
      reduceFlashes: reduceFlashes,
      showCaptions: showCaptions,
      orientationOverrides: orientationOverrides,
      onFocused: () => controller.focus(orientation),
      onRetry: onRetry,
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
