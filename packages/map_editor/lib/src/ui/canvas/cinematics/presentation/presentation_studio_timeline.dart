import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../../../theme/theme.dart';
import '../../../../application/authoring_api/presentation_studio_timeline_command.dart';
import '../../../../application/authoring_api/presentation_timeline_projection_gateway.dart';
import '../../../design_system/design_system.dart';
import 'presentation_studio_layer_tree.dart';
import 'presentation_timeline_editing_controller.dart';

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
    this.editingController,
    this.onCommand,
    this.mutationPending = false,
    this.canUndo = false,
    this.canRedo = false,
    this.onUndo,
    this.onRedo,
    this.viewportController,
    this.projectionController,
    this.markerUsageCountById = const <String, int>{},
    this.state = PresentationStudioTimelineState.ready,
    this.diagnostic,
  });

  final PresentationCinematicAsset asset;
  final int playheadUs;
  final PresentationStudioSelectionController selectionController;
  final ValueChanged<int> onPlayheadChanged;
  final PresentationTimelineEditingController? editingController;
  final ValueChanged<PresentationTimelineClipCommand>? onCommand;
  final bool mutationPending;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final PresentationTimelineViewportController? viewportController;
  final PresentationTimelineProjectionController? projectionController;
  final Map<String, int> markerUsageCountById;
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
  late PresentationTimelineEditingController _editingController;
  late bool _ownsEditingController;
  late List<PresentationTimelineClipIndex> _clipIndexes;
  bool _syncingHorizontalProxy = false;
  Offset _dragDelta = Offset.zero;
  int _dragSourceTrackIndex = 0;
  double _trimDeltaX = 0;
  String? _projectionViewportSignature;

  @override
  void initState() {
    super.initState();
    _attachViewportController();
    _attachEditingController();
    _rebuildIndexes();
    widget.selectionController.addListener(_selectionChanged);
    _horizontalProxyController.addListener(_proxyScrolled);
    _verticalController.addListener(_verticalScrolled);
    widget.projectionController?.addListener(_projectionChanged);
  }

  @override
  void didUpdateWidget(covariant PresentationStudioTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewportController != widget.viewportController) {
      _viewportController.removeListener(_viewportChanged);
      if (_ownsViewportController) _viewportController.dispose();
      _attachViewportController();
    }
    if (oldWidget.editingController != widget.editingController) {
      _editingController.removeListener(_editingChanged);
      if (_ownsEditingController) _editingController.dispose();
      _attachEditingController();
    }
    _editingController.configureAsset(widget.asset);
    _viewportController.configureDuration(widget.asset.durationUs);
    _viewportController.seekTo(widget.playheadUs);
    if (oldWidget.asset != widget.asset) _rebuildIndexes();
    if (oldWidget.selectionController != widget.selectionController) {
      oldWidget.selectionController.removeListener(_selectionChanged);
      widget.selectionController.addListener(_selectionChanged);
    }
    if (oldWidget.projectionController != widget.projectionController) {
      oldWidget.projectionController?.removeListener(_projectionChanged);
      widget.projectionController?.addListener(_projectionChanged);
      _projectionViewportSignature = null;
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

  void _attachEditingController() {
    _ownsEditingController = widget.editingController == null;
    _editingController =
        widget.editingController ??
        PresentationTimelineEditingController(asset: widget.asset);
    _editingController.addListener(_editingChanged);
  }

  void _rebuildIndexes() {
    _clipIndexes = <PresentationTimelineClipIndex>[
      for (final track in widget.asset.tracks)
        PresentationTimelineClipIndex(track.clips),
    ];
    _projectionViewportSignature = null;
  }

  void _selectionChanged() {
    if (widget.selectionController.origin !=
        PresentationStudioSelectionOrigin.timeline) {
      final clipId = widget.selectionController.value?.clipId;
      if (clipId == null) {
        _editingController.clearSelection();
      } else {
        _editingController.selectClip(clipId);
      }
    }
    if (mounted) setState(() {});
  }

  void _editingChanged() {
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

  void _verticalScrolled() {
    if (mounted) setState(() {});
  }

  void _projectionChanged() {
    if (mounted) setState(() {});
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
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    final commandModifier =
        keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight) ||
        keys.contains(LogicalKeyboardKey.metaLeft) ||
        keys.contains(LogicalKeyboardKey.metaRight);
    final shift =
        keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight);
    if (commandModifier) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.keyC:
          _editingController.copySelection();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyV:
          _pasteSelection();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyD:
          _duplicateSelection();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyZ:
          if (shift) {
            if (widget.canRedo) widget.onRedo?.call();
          } else if (widget.canUndo) {
            widget.onUndo?.call();
          }
          return KeyEventResult.handled;
      }
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
      case LogicalKeyboardKey.escape:
        if (!_editingController.hasActiveDrag) {
          return KeyEventResult.ignored;
        }
        _editingController.cancelDrag();
      case LogicalKeyboardKey.delete:
      case LogicalKeyboardKey.backspace:
        _deleteSelection();
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
    _editingController.removeListener(_editingChanged);
    if (_ownsEditingController) _editingController.dispose();
    _viewportController.removeListener(_viewportChanged);
    if (_ownsViewportController) _viewportController.dispose();
    _horizontalProxyController
      ..removeListener(_proxyScrolled)
      ..dispose();
    _verticalController
      ..removeListener(_verticalScrolled)
      ..dispose();
    widget.projectionController?.removeListener(_projectionChanged);
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
        onPointerUp: (_) {
          if (_editingController.hasActiveDrag) _finishDrag();
        },
        onPointerCancel: (_) => _editingController.cancelDrag(),
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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  children: [
                    PokeMapIconButton(
                      semanticLabel: 'Annuler la dernière édition de clips',
                      tooltip: 'Annuler',
                      onPressed: widget.canUndo && !widget.mutationPending
                          ? widget.onUndo
                          : null,
                      icon: const Icon(Icons.undo_rounded),
                    ),
                    PokeMapIconButton(
                      semanticLabel: 'Rétablir la dernière édition de clips',
                      tooltip: 'Rétablir',
                      onPressed: widget.canRedo && !widget.mutationPending
                          ? widget.onRedo
                          : null,
                      icon: const Icon(Icons.redo_rounded),
                    ),
                    PokeMapIconButton(
                      semanticLabel: 'Copier les clips sélectionnés',
                      tooltip: 'Copier',
                      onPressed: _editingController.selectedClipIds.isEmpty
                          ? null
                          : _editingController.copySelection,
                      icon: const Icon(Icons.copy_rounded),
                    ),
                    PokeMapIconButton(
                      semanticLabel: 'Coller les clips au playhead',
                      tooltip: 'Coller',
                      onPressed:
                          _editingController.hasClipboard &&
                              !widget.mutationPending
                          ? _pasteSelection
                          : null,
                      icon: const Icon(Icons.content_paste_rounded),
                    ),
                    PokeMapIconButton(
                      semanticLabel: 'Dupliquer les clips sélectionnés',
                      tooltip: 'Dupliquer',
                      onPressed:
                          !_editingController.canEditSelection ||
                              widget.mutationPending
                          ? null
                          : _duplicateSelection,
                      icon: const Icon(Icons.control_point_duplicate_rounded),
                    ),
                    PokeMapIconButton(
                      semanticLabel: 'Supprimer les clips sélectionnés',
                      tooltip: 'Supprimer',
                      onPressed:
                          !_editingController.canEditSelection ||
                              widget.mutationPending
                          ? null
                          : _deleteSelection,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        _scheduleProjectionSync(constraints.maxHeight);
        return ListView.builder(
          key: presentationStudioTimelineTrackListKey,
          controller: _verticalController,
          itemExtent: 52,
          itemCount: widget.asset.tracks.length,
          itemBuilder: (context, index) => _trackRow(
            widget.asset.tracks[index],
            _clipIndexes[index],
            viewportWidth,
            index,
          ),
        );
      },
    );
  }

  void _scheduleProjectionSync(double viewportHeight) {
    final controller = widget.projectionController;
    if (controller == null || !viewportHeight.isFinite || viewportHeight <= 0) {
      return;
    }
    final firstTrack = math.max(
      0,
      (_verticalController.hasClients ? _verticalController.offset / 52 : 0)
              .floor() -
          1,
    );
    final lastTrack = math.min(
      widget.asset.tracks.length - 1,
      firstTrack + (viewportHeight / 52).ceil() + 2,
    );
    final startUs = math.max(
      0,
      _viewportController.visibleStartUs - _queryOverscanUs,
    );
    final endUs = math.min(
      widget.asset.durationUs,
      _viewportController.visibleEndUs + _queryOverscanUs,
    );
    final signature = Object.hash(
      identityHashCode(widget.asset),
      firstTrack,
      lastTrack,
      startUs,
      endUs,
      _projectionDensity(_viewportController.pixelsPerSecond),
    ).toString();
    if (_projectionViewportSignature == signature) return;
    _projectionViewportSignature = signature;
    final clips = <PresentationClip>[
      for (var index = firstTrack; index <= lastTrack; index += 1)
        ..._clipIndexes[index].visibleBetween(startUs: startUs, endUs: endUs),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.projectionController != controller) return;
      controller.sync(
        clips: clips,
        pixelsPerSecond: _viewportController.pixelsPerSecond,
      );
    });
  }

  Widget _trackRow(
    PresentationTrack track,
    PresentationTimelineClipIndex index,
    double viewportWidth,
    int trackIndex,
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
    final previewClipIds = _editingController.activePreviewClipIds;
    final clips =
        <PresentationClip>[
          for (final clip in index.visibleBetween(
            startUs: startUs,
            endUs: endUs,
          ))
            if (!previewClipIds.contains(clip.id)) clip,
          for (final clipId in previewClipIds)
            if (_editingController.previewTrackId(clipId) == track.id)
              if (_editingController.previewClip(clipId) case final preview
                  when preview.endUs >= startUs && preview.startUs <= endUs)
                _editingController.sourceClip(clipId),
        ]..sort((left, right) {
          final start = _editingController
              .previewClip(left.id)
              .startUs
              .compareTo(_editingController.previewClip(right.id).startUs);
          return start != 0 ? start : left.id.compareTo(right.id);
        });
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
                for (final clip in clips) _clip(clip, trackIndex),
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

  Widget _clip(PresentationClip clip, int trackIndex) {
    final renderedClip = _editingController.previewClip(clip.id);
    final left =
        renderedClip.startUs / 1000000 * _viewportController.pixelsPerSecond -
        _viewportController.scrollOffset;
    final duration = renderedClip.durationUs == 0
        ? const Duration(microseconds: 1)
        : Duration(microseconds: renderedClip.durationUs);
    final selected =
        _editingController.selectedClipIds.contains(clip.id) ||
        widget.selectionController.value?.clipId == clip.id;
    final projection = widget.projectionController?.projectionFor(
      clip,
      pixelsPerSecond: _viewportController.pixelsPerSecond,
    );
    return Positioned(
      key: ValueKey<String>('presentation-timeline-clip-${clip.id}'),
      left: left,
      top: 4,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: !_editingEnabled
            ? null
            : (_) {
                _dragDelta = Offset.zero;
                _dragSourceTrackIndex = trackIndex;
                _selectClip(clip, preserveExistingSelection: true);
                if (!_editingController.canEditSelection) return;
                _editingController.beginDrag(
                  clipId: clip.id,
                  kind: PresentationTimelineDragKind.move,
                );
              },
        onPanUpdate: !_editingEnabled
            ? null
            : (details) {
                if (!_editingController.hasActiveDrag) return;
                _dragDelta += details.delta;
                final targetTrackIndex =
                    (_dragSourceTrackIndex + (_dragDelta.dy / 52).round())
                        .clamp(0, widget.asset.tracks.length - 1)
                        .toInt();
                _editingController.updateDrag(
                  deltaUs:
                      (_dragDelta.dx /
                              _viewportController.pixelsPerSecond *
                              1000000)
                          .round(),
                  targetTrackId: widget.asset.tracks[targetTrackIndex].id,
                );
              },
        onPanEnd: !_editingEnabled ? null : (_) => _finishDrag(),
        onPanCancel: !_editingEnabled ? null : _editingController.cancelDrag,
        child: PokeMapCinematicTimelineClip(
          label: _clipLabel(clip),
          duration: duration,
          pixelsPerSecond: _viewportController.pixelsPerSecond,
          state: _projectionClipState(projection),
          stateLabel: _clipStateLabel(
            clip,
            projection,
            markerUsageCount: widget.markerUsageCountById[clip.id] ?? 0,
          ),
          preview: _clipPreview(clip, projection),
          selected: selected,
          onPressed: () => _selectClip(clip),
          startTrimLabel: selected && clip is! PresentationMarkerClip
              ? 'Rogner le début de ${_clipLabel(clip)}'
              : null,
          endTrimLabel: selected && clip is! PresentationMarkerClip
              ? 'Rogner la fin de ${_clipLabel(clip)}'
              : null,
          onStartTrimBegin:
              !_editingEnabled || !_editingController.isClipEditable(clip.id)
              ? null
              : () => _beginTrim(clip, PresentationTimelineDragKind.trimStart),
          onStartTrim: !_editingEnabled ? null : (delta) => _updateTrim(delta),
          onStartTrimEnd: !_editingEnabled ? null : _finishDrag,
          onStartTrimCancel: !_editingEnabled
              ? null
              : _editingController.cancelDrag,
          onEndTrimBegin:
              !_editingEnabled || !_editingController.isClipEditable(clip.id)
              ? null
              : () => _beginTrim(clip, PresentationTimelineDragKind.trimEnd),
          onEndTrim: !_editingEnabled ? null : (delta) => _updateTrim(delta),
          onEndTrimEnd: !_editingEnabled ? null : _finishDrag,
          onEndTrimCancel: !_editingEnabled
              ? null
              : _editingController.cancelDrag,
        ),
      ),
    );
  }

  Widget? _clipPreview(
    PresentationClip clip,
    PresentationTimelineMediaProjection? projection,
  ) => switch (clip) {
    PresentationAudioClip() when projection?.available ?? false =>
      PokeMapCinematicAudioTimelinePreview(
        key: ValueKey<String>('presentation-audio-preview-${clip.id}'),
        amplitudes: projection!.waveform,
        volume: clip.volume,
        fadeInFraction: clip.fadeInUs / clip.durationUs,
        fadeOutFraction: clip.fadeOutUs / clip.durationUs,
        loop: clip.loop,
      ),
    PresentationVisualClip(mediaKind: PresentationVisualMediaKind.video)
        when projection?.thumbnailBytes != null =>
      PokeMapCinematicVideoTimelinePreview(
        key: ValueKey<String>('presentation-video-preview-${clip.id}'),
        thumbnailBytes: projection!.thumbnailBytes!,
        spacing: math.max(48, _viewportController.pixelsPerSecond * 1.5),
        fallbackUsed: projection.fallbackUsed,
      ),
    PresentationCaptionClip() when projection?.available ?? false =>
      PokeMapCinematicCaptionTimelinePreview(
        key: ValueKey<String>('presentation-caption-preview-${clip.id}'),
        locale: clip.locale,
        segments: <String>[
          for (final segment in projection!.captions) segment.text,
        ],
        hasOverlap: _captionSegmentsOverlap(projection.captions),
      ),
    PresentationMarkerClip() => PokeMapCinematicMarkerTimelinePreview(
      key: ValueKey<String>('presentation-marker-preview-${clip.id}'),
      interactionCue: clip.markerKind == PresentationMarkerKind.interactionCue,
      required: clip.required,
      sceneUsageCount: widget.markerUsageCountById[clip.id] ?? 0,
    ),
    _ => null,
  };

  void _selectClip(
    PresentationClip clip, {
    bool preserveExistingSelection = false,
  }) {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    final additive =
        keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight) ||
        keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight) ||
        keys.contains(LogicalKeyboardKey.metaLeft) ||
        keys.contains(LogicalKeyboardKey.metaRight);
    if (!preserveExistingSelection ||
        !_editingController.selectedClipIds.contains(clip.id)) {
      _editingController.selectClip(clip.id, additive: additive);
    }
    widget.selectionController.selectClip(asset: widget.asset, clipId: clip.id);
  }

  void _finishDrag() {
    if (!_editingController.hasActiveDrag) return;
    try {
      widget.onCommand?.call(_editingController.finishDrag());
    } on StateError {
      _editingController.cancelDrag();
    }
  }

  bool get _editingEnabled =>
      widget.onCommand != null && !widget.mutationPending;

  void _beginTrim(PresentationClip clip, PresentationTimelineDragKind kind) {
    _trimDeltaX = 0;
    _selectClip(clip);
    if (!_editingController.canEditSelection) return;
    _editingController.beginDrag(clipId: clip.id, kind: kind);
  }

  void _updateTrim(double deltaX) {
    _trimDeltaX += deltaX;
    _editingController.updateDrag(
      deltaUs: (_trimDeltaX / _viewportController.pixelsPerSecond * 1000000)
          .round(),
    );
  }

  void _pasteSelection() {
    if (!_editingEnabled || !_editingController.hasClipboard) return;
    widget.onCommand?.call(
      _editingController.paste(atUs: _viewportController.playheadUs),
    );
  }

  void _duplicateSelection() {
    if (!_editingEnabled || !_editingController.canEditSelection) return;
    widget.onCommand?.call(_editingController.duplicateSelection());
  }

  void _deleteSelection() {
    if (!_editingEnabled || !_editingController.canEditSelection) return;
    widget.onCommand?.call(_editingController.deleteSelection());
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
  PresentationTextClip() => clip.text,
  PresentationAudioClip() => clip.resourceId,
  PresentationCaptionClip() => clip.captionId,
  PresentationMarkerClip() => clip.label,
};

PokeMapCinematicTimelineClipState _projectionClipState(
  PresentationTimelineMediaProjection? projection,
) => switch (projection?.status) {
  PresentationTimelineProjectionStatus.loading =>
    PokeMapCinematicTimelineClipState.pending,
  PresentationTimelineProjectionStatus.missing ||
  PresentationTimelineProjectionStatus.error =>
    PokeMapCinematicTimelineClipState.error,
  _ => PokeMapCinematicTimelineClipState.normal,
};

String? _clipStateLabel(
  PresentationClip clip,
  PresentationTimelineMediaProjection? projection, {
  required int markerUsageCount,
}) {
  if (projection?.loading ?? false) return 'Préparation de l’aperçu…';
  final diagnostic = projection?.diagnostic?.trim();
  if (diagnostic != null && diagnostic.isNotEmpty) return diagnostic;
  return switch (clip) {
    PresentationAudioClip() => <String>[
      '${(clip.volume * 100).round()} %',
      if (clip.loop) 'boucle',
      if (clip.fadeInUs > 0 || clip.fadeOutUs > 0) 'fondus',
      if (_hasResponsiveVariants(clip)) 'variantes L/P',
      if (projection?.fallbackUsed ?? false) 'fallback',
    ].join(' · '),
    PresentationVisualClip(mediaKind: PresentationVisualMediaKind.video) =>
      <String>[
        'Vidéo',
        if (_hasResponsiveVariants(clip)) 'variantes L/P',
        if (projection?.fallbackUsed ?? false) 'fallback',
      ].join(' · '),
    PresentationCaptionClip() => <String>[
      clip.locale.toUpperCase(),
      if (projection != null) '${projection.captions.length} segments',
      if (clip.fallbackToProjectDefault) 'fallback locale',
    ].join(' · '),
    PresentationMarkerClip() => <String>[
      clip.markerKind == PresentationMarkerKind.interactionCue
          ? 'Cue Scene'
          : 'Repère',
      if (clip.required) 'requis',
      if (clip.markerKind == PresentationMarkerKind.interactionCue)
        markerUsageCount == 0
            ? 'non relié'
            : '$markerUsageCount ${markerUsageCount == 1 ? 'usage' : 'usages'} Scene',
    ].join(' · '),
    _ => null,
  };
}

bool _hasResponsiveVariants(PresentationClip clip) => switch (clip) {
  PresentationVisualClip() =>
    clip.landscapeResourceId != null || clip.portraitResourceId != null,
  PresentationAudioClip() =>
    clip.landscapeResourceId != null || clip.portraitResourceId != null,
  _ => false,
};

bool _captionSegmentsOverlap(
  List<PresentationTimelineCaptionSegment> segments,
) {
  if (segments.length < 2) return false;
  final ordered = segments.toList()
    ..sort((left, right) => left.startUs.compareTo(right.startUs));
  var maximumEndUs = ordered.first.endUs;
  for (final segment in ordered.skip(1)) {
    if (segment.startUs < maximumEndUs) return true;
    maximumEndUs = math.max(maximumEndUs, segment.endUs);
  }
  return false;
}

int _projectionDensity(double pixelsPerSecond) => pixelsPerSecond < 160
    ? 64
    : pixelsPerSecond < 320
    ? 128
    : 256;
