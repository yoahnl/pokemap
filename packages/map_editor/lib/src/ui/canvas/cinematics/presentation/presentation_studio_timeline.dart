import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../../../theme/theme.dart';
import '../../../design_system/design_system.dart';
import 'presentation_studio_layer_tree.dart';

const presentationStudioTimelineKey = ValueKey<String>(
  'presentation-studio-timeline',
);
const presentationStudioTimelineTrackListKey = ValueKey<String>(
  'presentation-studio-timeline-track-list',
);
const presentationStudioTimelineHorizontalScrollbarKey = ValueKey<String>(
  'presentation-studio-timeline-horizontal-scrollbar',
);

enum PresentationStudioTimelineState { ready, loading, disabled, error }

final class PresentationTimelineViewportController extends ChangeNotifier {
  PresentationTimelineViewportController({
    required int durationUs,
    double pixelsPerSecond = 80,
    int playheadUs = 0,
  }) : _durationUs = _validDuration(durationUs),
       _pixelsPerSecond = _validZoom(pixelsPerSecond),
       _playheadUs = playheadUs.clamp(0, durationUs).toInt();

  static const double minPixelsPerSecond = 16;
  static const double maxPixelsPerSecond = 480;

  int _durationUs;
  double _pixelsPerSecond;
  double _viewportWidth = 0;
  double _scrollOffset = 0;
  int _playheadUs;

  int get durationUs => _durationUs;
  double get pixelsPerSecond => _pixelsPerSecond;
  double get viewportWidth => _viewportWidth;
  double get scrollOffset => _scrollOffset;
  int get playheadUs => _playheadUs;
  double get contentWidth => _durationUs / 1000000 * _pixelsPerSecond;
  double get maxScrollOffset => math.max(0, contentWidth - _viewportWidth);
  int get visibleStartUs => _timeUsAtContentX(_scrollOffset);
  int get visibleEndUs => _timeUsAtContentX(_scrollOffset + _viewportWidth);
  double get playheadViewportX =>
      _contentXAtTimeUs(_playheadUs) - _scrollOffset;

  void configureViewport(double width) {
    if (!width.isFinite || width < 0) {
      throw ArgumentError.value(
        width,
        'width',
        'must be finite and nonnegative',
      );
    }
    if (_viewportWidth == width) return;
    _viewportWidth = width;
    _scrollOffset = _clampScroll(_scrollOffset);
    notifyListeners();
  }

  void configureDuration(int value) {
    final duration = _validDuration(value);
    if (_durationUs == duration) return;
    _durationUs = duration;
    _playheadUs = _playheadUs.clamp(0, duration).toInt();
    _scrollOffset = _clampScroll(_scrollOffset);
    notifyListeners();
  }

  int timeUsAtViewportX(double viewportX) {
    final boundedX = viewportX.clamp(0, _viewportWidth).toDouble();
    return _timeUsAtContentX(_scrollOffset + boundedX);
  }

  void seekTo(int timeUs) {
    final next = timeUs.clamp(0, _durationUs).toInt();
    if (_playheadUs == next) return;
    _playheadUs = next;
    notifyListeners();
  }

  void seekBy(int deltaUs) => seekTo(_playheadUs + deltaUs);

  void scrollTo(double offset) {
    if (!offset.isFinite) {
      throw ArgumentError.value(offset, 'offset', 'must be finite');
    }
    final next = _clampScroll(offset);
    if ((_scrollOffset - next).abs() < 0.01) return;
    _scrollOffset = next;
    notifyListeners();
  }

  void scrollBy(double delta) => scrollTo(_scrollOffset + delta);

  void zoomAt({required double factor, required double anchorViewportX}) {
    if (!factor.isFinite || factor <= 0) {
      throw ArgumentError.value(
        factor,
        'factor',
        'must be positive and finite',
      );
    }
    final anchor = anchorViewportX.clamp(0, _viewportWidth).toDouble();
    final anchorTimeUs = timeUsAtViewportX(anchor);
    final nextZoom = (_pixelsPerSecond * factor)
        .clamp(minPixelsPerSecond, maxPixelsPerSecond)
        .toDouble();
    if (_pixelsPerSecond == nextZoom) return;
    _pixelsPerSecond = nextZoom;
    _scrollOffset = _clampScroll(_contentXAtTimeUs(anchorTimeUs) - anchor);
    notifyListeners();
  }

  double _contentXAtTimeUs(int timeUs) => timeUs / 1000000 * _pixelsPerSecond;

  int _timeUsAtContentX(double contentX) =>
      (contentX / _pixelsPerSecond * 1000000)
          .round()
          .clamp(0, _durationUs)
          .toInt();

  double _clampScroll(double value) =>
      value.clamp(0, maxScrollOffset).toDouble();

  static int _validDuration(int value) {
    if (value <= 0) {
      throw ArgumentError.value(value, 'durationUs', 'must be positive');
    }
    return value;
  }

  static double _validZoom(double value) {
    if (!value.isFinite || value <= 0) {
      throw ArgumentError.value(
        value,
        'pixelsPerSecond',
        'must be positive and finite',
      );
    }
    return value.clamp(minPixelsPerSecond, maxPixelsPerSecond).toDouble();
  }
}

final class PresentationTimelineClipIndex {
  PresentationTimelineClipIndex(Iterable<PresentationClip> clips)
    : _clips = List<PresentationClip>.of(clips)
        ..sort((left, right) {
          final start = left.startUs.compareTo(right.startUs);
          return start != 0 ? start : left.id.compareTo(right.id);
        }) {
    _prefixMaxEndUs = List<int>.filled(_clips.length, 0);
    var maximum = 0;
    for (var index = 0; index < _clips.length; index += 1) {
      maximum = math.max(maximum, _clips[index].endUs);
      _prefixMaxEndUs[index] = maximum;
    }
  }

  final List<PresentationClip> _clips;
  late final List<int> _prefixMaxEndUs;

  List<PresentationClip> visibleBetween({
    required int startUs,
    required int endUs,
  }) {
    if (_clips.isEmpty || endUs < startUs) return const <PresentationClip>[];
    var low = 0;
    var high = _prefixMaxEndUs.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (_prefixMaxEndUs[middle] < startUs) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    final result = <PresentationClip>[];
    for (var index = low; index < _clips.length; index += 1) {
      final clip = _clips[index];
      if (clip.startUs > endUs) break;
      if (clip.endUs >= startUs) result.add(clip);
    }
    return result;
  }
}

class PresentationStudioTimeline extends StatefulWidget {
  const PresentationStudioTimeline({
    super.key,
    required this.asset,
    required this.playheadUs,
    required this.selectionController,
    required this.onPlayheadChanged,
    this.viewportController,
    this.state = PresentationStudioTimelineState.ready,
    this.diagnostic,
  });

  final PresentationCinematicAsset asset;
  final int playheadUs;
  final PresentationStudioSelectionController selectionController;
  final ValueChanged<int> onPlayheadChanged;
  final PresentationTimelineViewportController? viewportController;
  final PresentationStudioTimelineState state;
  final String? diagnostic;

  @override
  State<PresentationStudioTimeline> createState() =>
      _PresentationStudioTimelineState();
}

class _PresentationStudioTimelineState
    extends State<PresentationStudioTimeline> {
  static const double _headerWidth = 160;
  static const int _keyboardSeekUs = 100000;
  static const int _queryOverscanUs = 1000000;

  final FocusNode _focusNode = FocusNode();
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalProxyController = ScrollController();
  late PresentationTimelineViewportController _viewportController;
  late bool _ownsViewportController;
  late List<PresentationTimelineClipIndex> _clipIndexes;
  bool _syncingHorizontalProxy = false;

  @override
  void initState() {
    super.initState();
    _attachViewportController();
    _rebuildIndexes();
    widget.selectionController.addListener(_selectionChanged);
    _horizontalProxyController.addListener(_proxyScrolled);
  }

  @override
  void didUpdateWidget(covariant PresentationStudioTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewportController != widget.viewportController) {
      _viewportController.removeListener(_viewportChanged);
      if (_ownsViewportController) _viewportController.dispose();
      _attachViewportController();
    }
    _viewportController.configureDuration(widget.asset.durationUs);
    _viewportController.seekTo(widget.playheadUs);
    if (oldWidget.asset != widget.asset) _rebuildIndexes();
    if (oldWidget.selectionController != widget.selectionController) {
      oldWidget.selectionController.removeListener(_selectionChanged);
      widget.selectionController.addListener(_selectionChanged);
    }
  }

  void _attachViewportController() {
    _ownsViewportController = widget.viewportController == null;
    _viewportController =
        widget.viewportController ??
        PresentationTimelineViewportController(
          durationUs: widget.asset.durationUs,
          playheadUs: widget.playheadUs,
        );
    _viewportController.configureDuration(widget.asset.durationUs);
    _viewportController.seekTo(widget.playheadUs);
    _viewportController.addListener(_viewportChanged);
  }

  void _rebuildIndexes() {
    _clipIndexes = <PresentationTimelineClipIndex>[
      for (final track in widget.asset.tracks)
        PresentationTimelineClipIndex(track.clips),
    ];
  }

  void _selectionChanged() {
    if (mounted) setState(() {});
  }

  void _viewportChanged() {
    if (!mounted) return;
    setState(() {});
    _scheduleProxySync();
  }

  void _scheduleProxySync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_horizontalProxyController.hasClients) return;
      final target = _viewportController.scrollOffset.clamp(
        0,
        _horizontalProxyController.position.maxScrollExtent,
      );
      if ((_horizontalProxyController.offset - target).abs() < 0.5) return;
      _syncingHorizontalProxy = true;
      _horizontalProxyController.jumpTo(target.toDouble());
      _syncingHorizontalProxy = false;
    });
  }

  void _proxyScrolled() {
    if (_syncingHorizontalProxy || !_horizontalProxyController.hasClients) {
      return;
    }
    _viewportController.scrollTo(_horizontalProxyController.offset);
  }

  void _seekTo(int timeUs) {
    final bounded = timeUs.clamp(0, widget.asset.durationUs).toInt();
    _viewportController.seekTo(bounded);
    widget.onPlayheadChanged(bounded);
  }

  void _seekAt(double viewportX) {
    _seekTo(_viewportController.timeUsAtViewportX(viewportX));
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        _seekTo(_viewportController.playheadUs - _keyboardSeekUs);
      case LogicalKeyboardKey.arrowRight:
        _seekTo(_viewportController.playheadUs + _keyboardSeekUs);
      case LogicalKeyboardKey.home:
        _seekTo(0);
      case LogicalKeyboardKey.end:
        _seekTo(widget.asset.durationUs);
      case LogicalKeyboardKey.equal:
      case LogicalKeyboardKey.add:
      case LogicalKeyboardKey.numpadAdd:
        _viewportController.zoomAt(
          factor: 1.25,
          anchorViewportX: _viewportController.viewportWidth / 2,
        );
      case LogicalKeyboardKey.minus:
      case LogicalKeyboardKey.numpadSubtract:
        _viewportController.zoomAt(
          factor: 0.8,
          anchorViewportX: _viewportController.viewportWidth / 2,
        );
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    final zooming =
        keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight) ||
        keys.contains(LogicalKeyboardKey.metaLeft) ||
        keys.contains(LogicalKeyboardKey.metaRight);
    if (zooming) {
      final anchor = (event.localPosition.dx - _headerWidth)
          .clamp(0, _viewportController.viewportWidth)
          .toDouble();
      final factor = math.pow(1.002, -event.scrollDelta.dy).toDouble();
      _viewportController.zoomAt(factor: factor, anchorViewportX: anchor);
      return;
    }
    final horizontal = event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
        ? event.scrollDelta.dx
        : keys.contains(LogicalKeyboardKey.shiftLeft) ||
              keys.contains(LogicalKeyboardKey.shiftRight)
        ? event.scrollDelta.dy
        : 0.0;
    if (horizontal != 0) _viewportController.scrollBy(horizontal);
  }

  @override
  void dispose() {
    widget.selectionController.removeListener(_selectionChanged);
    _viewportController.removeListener(_viewportChanged);
    if (_ownsViewportController) _viewportController.dispose();
    _horizontalProxyController
      ..removeListener(_proxyScrolled)
      ..dispose();
    _verticalController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateSurface = _stateSurface();
    if (stateSurface != null) return stateSurface;
    return Focus(
      key: presentationStudioTimelineKey,
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _focusNode.requestFocus(),
        onPointerSignal: _handlePointerSignal,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewportWidth = math.max(
              1.0,
              constraints.maxWidth - _headerWidth,
            );
            if (_viewportController.viewportWidth != viewportWidth) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _viewportController.configureViewport(viewportWidth);
                  _scheduleProxySync();
                }
              });
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ruler(viewportWidth),
                Expanded(child: _tracks(viewportWidth)),
                _horizontalScrollbar(viewportWidth),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget? _stateSurface() => switch (widget.state) {
    PresentationStudioTimelineState.ready => null,
    PresentationStudioTimelineState.loading => const PokeMapEmptyState(
      title: 'Chargement de la timeline',
      description: 'Préparation des pistes visibles…',
      icon: SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
    PresentationStudioTimelineState.disabled => const PokeMapEmptyState(
      title: 'Timeline indisponible',
      description: 'La timeline est désactivée pour ce document.',
      icon: Icon(Icons.block_rounded),
    ),
    PresentationStudioTimelineState.error => PokeMapEmptyState(
      title: 'Timeline invalide',
      description: widget.diagnostic ?? 'La structure des pistes est invalide.',
      icon: const Icon(Icons.error_outline_rounded),
    ),
  };

  Widget _ruler(double viewportWidth) {
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          SizedBox(
            width: _headerWidth,
            child: PokeMapToolbarSurface(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PokeMapIconButton(
                    semanticLabel: 'Dézoomer la timeline',
                    tooltip: 'Dézoomer',
                    onPressed: () => _viewportController.zoomAt(
                      factor: 0.8,
                      anchorViewportX: _viewportController.viewportWidth / 2,
                    ),
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  PokeMapIconButton(
                    semanticLabel: 'Zoomer la timeline',
                    tooltip: 'Zoomer',
                    onPressed: () => _viewportController.zoomAt(
                      factor: 1.25,
                      anchorViewportX: _viewportController.viewportWidth / 2,
                    ),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
          ),
          PokeMapCinematicTimelineViewportRuler(
            duration: Duration(microseconds: widget.asset.durationUs),
            playhead: Duration(microseconds: _viewportController.playheadUs),
            pixelsPerSecond: _viewportController.pixelsPerSecond,
            scrollOffset: _viewportController.scrollOffset,
            width: viewportWidth,
            semanticLabel: 'Règle temporelle Presentation',
            onSeekAtX: _seekAt,
          ),
        ],
      ),
    );
  }

  Widget _tracks(double viewportWidth) {
    if (widget.asset.tracks.isEmpty) {
      return const PokeMapEmptyState(
        title: 'Timeline vide',
        description: 'Ajoutez une piste pour commencer la composition.',
        icon: Icon(Icons.view_timeline_outlined),
      );
    }
    return ListView.builder(
      key: presentationStudioTimelineTrackListKey,
      controller: _verticalController,
      itemExtent: 52,
      itemCount: widget.asset.tracks.length,
      itemBuilder: (context, index) => _trackRow(
        widget.asset.tracks[index],
        _clipIndexes[index],
        viewportWidth,
      ),
    );
  }

  Widget _trackRow(
    PresentationTrack track,
    PresentationTimelineClipIndex index,
    double viewportWidth,
  ) {
    final colors = context.pokeMapColors;
    final startUs = math.max(
      0,
      _viewportController.visibleStartUs - _queryOverscanUs,
    );
    final endUs = math.min(
      widget.asset.durationUs,
      _viewportController.visibleEndUs + _queryOverscanUs,
    );
    final clips = index.visibleBetween(startUs: startUs, endUs: endUs);
    final playheadX = _viewportController.playheadViewportX;
    return PokeMapCinematicTrackRow(
      label: track.label,
      icon: _trackIcon(track.kind),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) => _seekAt(details.localPosition.dx),
        child: ClipRect(
          child: SizedBox(
            width: viewportWidth,
            height: 52,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                for (final clip in clips) _clip(clip),
                if (playheadX >= 0 && playheadX <= viewportWidth)
                  Positioned(
                    left: playheadX,
                    top: 0,
                    bottom: 0,
                    child: SizedBox(
                      width: 2,
                      child: ColoredBox(color: colors.brandPrimary),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _clip(PresentationClip clip) {
    final left =
        clip.startUs / 1000000 * _viewportController.pixelsPerSecond -
        _viewportController.scrollOffset;
    final duration = clip.durationUs == 0
        ? const Duration(microseconds: 1)
        : Duration(microseconds: clip.durationUs);
    final selected = widget.selectionController.value?.clipId == clip.id;
    return Positioned(
      key: ValueKey<String>('presentation-timeline-clip-${clip.id}'),
      left: left,
      top: 4,
      child: PokeMapCinematicTimelineClip(
        label: _clipLabel(clip),
        duration: duration,
        pixelsPerSecond: _viewportController.pixelsPerSecond,
        selected: selected,
        onPressed: clip is PresentationVisualClip
            ? () => widget.selectionController.selectClip(
                asset: widget.asset,
                clipId: clip.id,
              )
            : null,
      ),
    );
  }

  Widget _horizontalScrollbar(double viewportWidth) {
    final contentWidth = math.max(
      viewportWidth,
      _viewportController.contentWidth,
    );
    return SizedBox(
      height: 14,
      child: Row(
        children: [
          const SizedBox(width: _headerWidth),
          Expanded(
            child: Scrollbar(
              key: presentationStudioTimelineHorizontalScrollbarKey,
              controller: _horizontalProxyController,
              thumbVisibility: true,
              notificationPredicate: (notification) =>
                  notification.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                controller: _horizontalProxyController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(width: contentWidth, height: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _trackIcon(PresentationTrackKind kind) => switch (kind) {
  PresentationTrackKind.visual => Icons.image_outlined,
  PresentationTrackKind.audio => Icons.music_note_rounded,
  PresentationTrackKind.caption => Icons.subtitles_outlined,
  PresentationTrackKind.marker => Icons.bookmark_border_rounded,
};

String _clipLabel(PresentationClip clip) => switch (clip) {
  PresentationVisualClip() => clip.resourceId,
  PresentationAudioClip() => clip.resourceId,
  PresentationCaptionClip() => clip.captionId,
  PresentationMarkerClip() => clip.label,
};
