import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/presentation_renderer.dart';

import '../../../../theme/theme.dart';
import '../../../design_system/design_system.dart';
import 'presentation_frame_preview.dart';

const presentationStudioViewportKey = ValueKey<String>(
  'presentation-studio-viewport',
);
const presentationStudioViewportGestureKey = ValueKey<String>(
  'presentation-studio-viewport-gesture',
);
const presentationStudioViewportTransformKey = ValueKey<String>(
  'presentation-studio-viewport-transform',
);
const presentationStudioViewportFrameKey = ValueKey<String>(
  'presentation-studio-viewport-frame',
);
const presentationStudioSafeAreaKey = ValueKey<String>(
  'pokemap-cinematic-safe-area',
);

enum PresentationStudioViewportState { ready, loading, error }

final class PresentationStudioViewportController extends ChangeNotifier {
  static const double minimumZoom = 0.5;
  static const double maximumZoom = 3;
  static const double zoomFactor = 1.25;
  static const double keyboardPanStep = 24;

  double _zoom = 1;
  Offset _pan = Offset.zero;

  double get zoom => _zoom;
  Offset get pan => _pan;

  void zoomIn() => _setZoom(_zoom * zoomFactor);

  void zoomOut() => _setZoom(_zoom / zoomFactor);

  void panBy(Offset delta) {
    if (delta == Offset.zero) return;
    _pan += delta;
    notifyListeners();
  }

  void recenter() {
    if (_pan == Offset.zero) return;
    _pan = Offset.zero;
    notifyListeners();
  }

  void fit() {
    if (_zoom == 1 && _pan == Offset.zero) return;
    _zoom = 1;
    _pan = Offset.zero;
    notifyListeners();
  }

  void _setZoom(double value) {
    final next = value.clamp(minimumZoom, maximumZoom).toDouble();
    if (next == _zoom) return;
    _zoom = next;
    notifyListeners();
  }
}

class PresentationStudioViewport extends StatefulWidget {
  const PresentationStudioViewport({
    super.key,
    required this.frame,
    required this.orientation,
    required this.contentPort,
    required this.playerTheme,
    this.controller,
    this.state = PresentationStudioViewportState.ready,
    this.errorMessage,
    this.onRetry,
    this.showSafeArea = true,
    this.reduceMotion,
    this.reduceFlashes = false,
    this.showCaptions = true,
    this.orientationOverrides = const PresentationFrameOrientationOverrides(),
    this.onFocused,
    this.onCompositionTap,
  });

  final PresentationStudioViewportController? controller;
  final PresentationFrame? frame;
  final PresentationFrameOrientation orientation;
  final PresentationFrameContentPort contentPort;
  final ThemeData playerTheme;
  final PresentationStudioViewportState state;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool showSafeArea;
  final bool? reduceMotion;
  final bool reduceFlashes;
  final bool showCaptions;
  final PresentationFrameOrientationOverrides orientationOverrides;
  final VoidCallback? onFocused;
  final ValueChanged<Offset>? onCompositionTap;

  @override
  State<PresentationStudioViewport> createState() =>
      _PresentationStudioViewportState();
}

class _PresentationStudioViewportState
    extends State<PresentationStudioViewport> {
  late PresentationStudioViewportController _controller;
  late bool _ownsController;
  final FocusNode _focusNode = FocusNode(
    debugLabel: 'Presentation Studio viewport',
  );

  @override
  void initState() {
    super.initState();
    _adoptController(widget.controller);
  }

  @override
  void didUpdateWidget(covariant PresentationStudioViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (_ownsController) _controller.dispose();
      _adoptController(widget.controller);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _adoptController(PresentationStudioViewportController? controller) {
    _ownsController = controller == null;
    _controller = controller ?? PresentationStudioViewportController();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.add): _controller.zoomIn,
        const SingleActivator(LogicalKeyboardKey.numpadAdd): _controller.zoomIn,
        const SingleActivator(LogicalKeyboardKey.equal): _controller.zoomIn,
        const SingleActivator(LogicalKeyboardKey.numpadSubtract):
            _controller.zoomOut,
        const SingleActivator(LogicalKeyboardKey.minus): _controller.zoomOut,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _controller.panBy(
              const Offset(
                -PresentationStudioViewportController.keyboardPanStep,
                0,
              ),
            ),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _controller.panBy(
              const Offset(
                PresentationStudioViewportController.keyboardPanStep,
                0,
              ),
            ),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _controller.panBy(
              const Offset(
                0,
                -PresentationStudioViewportController.keyboardPanStep,
              ),
            ),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _controller.panBy(
              const Offset(
                0,
                PresentationStudioViewportController.keyboardPanStep,
              ),
            ),
        const SingleActivator(LogicalKeyboardKey.home): _controller.recenter,
        const SingleActivator(LogicalKeyboardKey.keyF): _controller.fit,
        const SingleActivator(LogicalKeyboardKey.digit0): _controller.fit,
      },
      child: Focus(
        focusNode: _focusNode,
        child: Semantics(
          key: presentationStudioViewportKey,
          container: true,
          label: 'Canvas de cinématique de présentation',
          hint:
              'F ajuste le cadre, plus et moins changent le zoom, les flèches déplacent le cadre.',
          child: ColoredBox(
            color: colors.backgroundApp,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Stack(
                fit: StackFit.expand,
                children: [
                  Listener(
                    onPointerSignal: _handlePointerSignal,
                    child: GestureDetector(
                      key: presentationStudioViewportGestureKey,
                      behavior: HitTestBehavior.opaque,
                      onTap: _requestFocus,
                      onPanStart: (_) => _requestFocus(),
                      onPanUpdate: (details) =>
                          _controller.panBy(details.delta),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final size = _fitSize(
                            constraints.biggest,
                            widget.orientation.aspectRatio,
                          );
                          return Center(
                            child: Transform.translate(
                              key: presentationStudioViewportTransformKey,
                              offset: _controller.pan,
                              child: Transform.scale(
                                scale: _controller.zoom,
                                child: SizedBox(
                                  key: presentationStudioViewportFrameKey,
                                  width: size.width,
                                  height: size.height,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTapUp: widget.onCompositionTap == null
                                        ? null
                                        : (details) => widget.onCompositionTap!(
                                            Offset(
                                              details.localPosition.dx /
                                                  size.width,
                                              details.localPosition.dy /
                                                  size.height,
                                            ),
                                          ),
                                    child: PokeMapCinematicViewport(
                                      composition: _composition,
                                      semanticLabel:
                                          'Aperçu de la frame Presentation',
                                      showSafeArea: widget.showSafeArea,
                                      state: _designSystemState,
                                      statusLabel: widget.errorMessage,
                                      retryLabel:
                                          widget.state ==
                                              PresentationStudioViewportState
                                                  .error
                                          ? 'Réessayer le rendu'
                                          : null,
                                      onRetry: widget.onRetry,
                                      child: _content(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: _PresentationStudioViewportControls(
                      controller: _controller,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    if (widget.state == PresentationStudioViewportState.error) {
      return const SizedBox.expand();
    }
    final frame = widget.frame;
    if (frame == null) {
      return const PokeMapEmptyState(
        title: 'Aucun contenu à afficher',
        description:
            'Ajoutez un média ou un texte pour composer la première frame.',
        icon: Icon(Icons.movie_creation_outlined),
        compact: true,
      );
    }
    return PresentationFramePreview(
      frame: frame,
      orientation: widget.orientation,
      contentPort: widget.contentPort,
      playerTheme: widget.playerTheme,
      reduceMotion: widget.reduceMotion,
      reduceFlashes: widget.reduceFlashes,
      showCaptions: widget.showCaptions,
      orientationOverrides: widget.orientationOverrides,
    );
  }

  void _requestFocus() {
    _focusNode.requestFocus();
    widget.onFocused?.call();
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || event.scrollDelta.dy == 0) return;
    _requestFocus();
    if (event.scrollDelta.dy < 0) {
      _controller.zoomIn();
    } else {
      _controller.zoomOut();
    }
  }

  PokeMapCinematicComposition get _composition => switch (widget.orientation) {
    PresentationFrameOrientation.landscape =>
      PokeMapCinematicComposition.landscape16x9,
    PresentationFrameOrientation.portrait =>
      PokeMapCinematicComposition.portrait9x16,
  };

  PokeMapCinematicViewportState get _designSystemState =>
      switch (widget.state) {
        PresentationStudioViewportState.ready =>
          PokeMapCinematicViewportState.ready,
        PresentationStudioViewportState.loading =>
          PokeMapCinematicViewportState.loading,
        PresentationStudioViewportState.error =>
          PokeMapCinematicViewportState.error,
      };
}

class _PresentationStudioViewportControls extends StatelessWidget {
  const _PresentationStudioViewportControls({required this.controller});

  final PresentationStudioViewportController controller;

  @override
  Widget build(BuildContext context) {
    return PokeMapToolbarSurface(
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PokeMapIconButton(
            onPressed: controller.zoomOut,
            icon: const Icon(Icons.remove_rounded),
            tooltip: 'Réduire le zoom',
            semanticLabel: 'Réduire le zoom',
            size: 28,
            variant: PokeMapIconButtonVariant.ghost,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 56),
            child: Text(
              '${(controller.zoom * 100).round()} %',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.pokeMapColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          PokeMapIconButton(
            onPressed: controller.zoomIn,
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Augmenter le zoom',
            semanticLabel: 'Augmenter le zoom',
            size: 28,
            variant: PokeMapIconButtonVariant.ghost,
          ),
          const SizedBox(width: 2),
          PokeMapIconButton(
            onPressed: controller.fit,
            icon: const Icon(Icons.fit_screen_rounded),
            tooltip: 'Ajuster le cadre',
            semanticLabel: 'Ajuster le cadre',
            size: 28,
            variant: PokeMapIconButtonVariant.soft,
          ),
        ],
      ),
    );
  }
}

Size _fitSize(Size available, double aspectRatio) {
  final width = math.max(0, available.width - 48).toDouble();
  final height = math.max(0, available.height - 48).toDouble();
  if (width == 0 || height == 0) return Size.zero;
  final availableRatio = width / height;
  if (availableRatio > aspectRatio) {
    return Size(height * aspectRatio, height);
  }
  return Size(width, width / aspectRatio);
}
