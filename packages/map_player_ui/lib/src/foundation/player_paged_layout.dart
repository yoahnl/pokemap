import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../theme/pokemap_player_menu_theme.dart';

class PlayerPageIntent extends Intent {
  const PlayerPageIntent.previous() : delta = -1;
  const PlayerPageIntent.next() : delta = 1;

  final int delta;
}

class PlayerPagedList extends StatefulWidget {
  const PlayerPagedList({
    super.key,
    required this.children,
    this.spacing = 8,
    this.pageLabel,
    this.initialPage = 0,
    this.onPageChanged,
    this.revealChildKey,
    this.onPageReady,
    this.onContentHeightChanged,
    this.sideNavigation = false,
  });

  final List<Widget> children;
  final double spacing;
  final String? pageLabel;
  final int initialPage;
  final ValueChanged<int>? onPageChanged;
  final Key? revealChildKey;
  final VoidCallback? onPageReady;
  final ValueChanged<double>? onContentHeightChanged;
  final bool sideNavigation;

  @override
  State<PlayerPagedList> createState() => _PlayerPagedListState();
}

class _PlayerPagedListState extends State<PlayerPagedList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _transition;
  final _dragTranslation = ValueNotifier(0.0);
  int _pageDirection = 1;
  int _contentRevision = 0;
  final _heights = <Key, double>{};
  late int _page = widget.initialPage;
  Key? _lastRevealedKey;
  bool _pageWasChosen = false;
  int _measurementEpoch = 0;
  (double, double, double)? _layoutSignature;
  (int, int)? _readyPage;
  double? _reportedHeight;

  PokeMapPlayerMenuTheme get _menuTheme =>
      context.dependOnInheritedWidgetOfExactType<PlayerMenuThemeScope>() == null
      ? PokeMapPlayerMenuTheme.resolve(context)
      : context.playerMenuTheme;

  @override
  void initState() {
    super.initState();
    _transition = AnimationController(vsync: this, value: 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _transition.duration = _menuTheme.detailDuration;
  }

  @override
  void dispose() {
    _transition.dispose();
    _dragTranslation.dispose();
    super.dispose();
  }

  bool get _editing =>
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorStateOfType<EditableTextState>() !=
      null;

  @override
  void didUpdateWidget(PlayerPagedList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.children, widget.children) ||
        oldWidget.sideNavigation != widget.sideNavigation) {
      _heights.clear();
      _reportedHeight = null;
      _measurementEpoch++;
    }
  }

  Key _key(int index) => ValueKey(widget.children[index].key ?? index);

  void _measure(Key key, Size size) {
    if (!mounted || ((_heights[key] ?? -1) - size.height).abs() < .5) {
      return;
    }
    _dragTranslation.value = 0;
    _contentRevision++;
    setState(() => _heights[key] = size.height);
  }

  List<List<int>> _pages(double height) {
    final pages = <List<int>>[[]];
    var used = 0.0;
    for (var i = 0; i < widget.children.length; i++) {
      final extent = _heights[_key(i)] ?? 64;
      final gap = pages.last.isEmpty ? 0.0 : widget.spacing;
      if (pages.last.isNotEmpty && used + gap + extent > height + .5) {
        pages.add([]);
        used = 0;
      }
      used += (pages.last.isEmpty ? 0 : widget.spacing) + extent;
      pages.last.add(i);
    }
    return pages;
  }

  void _changePage(int value, int count) {
    final next = value.clamp(0, count - 1);
    if (next != _page) {
      _dragTranslation.value = 0;
      setState(() {
        _pageDirection = next > _page ? 1 : -1;
        _page = next;
        _pageWasChosen = true;
      });
      _transition.forward(from: 0);
      widget.onPageChanged?.call(next);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (!constraints.hasBoundedHeight) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < widget.children.length; i++) ...[
              if (i > 0) SizedBox(height: widget.spacing),
              widget.children[i],
            ],
          ],
        );
      }
      final sideNavigation =
          (widget.sideNavigation ||
              widget.onContentHeightChanged == null &&
                  constraints.maxHeight < 104) &&
          constraints.maxWidth >= 200 &&
          constraints.maxHeight >= 48;
      final horizontalNavigation =
          sideNavigation && constraints.maxHeight < 104;
      final navigationWidth = horizontalNavigation ? 104.0 : 48.0;
      final signature = (
        constraints.maxWidth - (sideNavigation ? navigationWidth + 8 : 0),
        constraints.maxHeight,
        MediaQuery.textScalerOf(context).scale(1),
      );
      if (_layoutSignature != signature) {
        _layoutSignature = signature;
        _heights.clear();
        _reportedHeight = null;
        _lastRevealedKey = null;
        _pageWasChosen = false;
        _measurementEpoch++;
      }
      final allMeasured = widget.children.asMap().keys.every(
        (index) => _heights.containsKey(_key(index)),
      );
      final total = widget.children.asMap().keys.fold<double>(
        math.max(0, widget.children.length - 1) * widget.spacing,
        (sum, index) => sum + (_heights[_key(index)] ?? 64),
      );
      final hasPages = total > constraints.maxHeight + .5;
      if (allMeasured && _reportedHeight != total) {
        final epoch = _measurementEpoch;
        _reportedHeight = total;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && epoch == _measurementEpoch) {
            widget.onContentHeightChanged?.call(total);
          }
        });
      }
      final pageSpace = math.max(
        0.0,
        constraints.maxHeight - (hasPages && !sideNavigation ? 56 : 0),
      );
      final pages = _pages(pageSpace);
      if (allMeasured &&
          widget.revealChildKey != null &&
          (!_pageWasChosen || widget.revealChildKey != _lastRevealedKey)) {
        final index = widget.children.indexWhere(
          (child) => child.key == widget.revealChildKey,
        );
        if (index >= 0) {
          _page = pages.indexWhere((page) => page.contains(index));
        }
        _lastRevealedKey = widget.revealChildKey;
        _pageWasChosen = false;
      }
      if (allMeasured) _page = _page.clamp(0, pages.length - 1);
      final readyPage = (_measurementEpoch, _page);
      if (allMeasured && _readyPage != readyPage) {
        _readyPage = readyPage;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _readyPage == readyPage) widget.onPageReady?.call();
        });
      }
      final indices = allMeasured ? pages[_page] : const <int>[];
      final french = Localizations.maybeLocaleOf(context)?.languageCode != 'en';
      final measuredContent = OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: 0,
        maxHeight: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < widget.children.length; i++)
              Offstage(
                key: _key(i),
                offstage: !allMeasured || !indices.contains(i),
                child: ExcludeFocus(
                  excluding: allMeasured && !indices.contains(i),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: indices.indexOf(i) > 0 ? widget.spacing : 0,
                    ),
                    child: _PlayerMeasure(
                      epoch: _measurementEpoch,
                      onSize: (size) => _measure(_key(i), size),
                      child: widget.children[i],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
      final content = ClipRect(
        key: const ValueKey('player-paged-body'),
        child: PlayerHorizontalSwipeRegion(
          resetToken: (_measurementEpoch, _contentRevision, _page),
          onPrevious: allMeasured && hasPages && _page > 0
              ? () => _changePage(_page - 1, pages.length)
              : null,
          onNext: allMeasured && hasPages && _page + 1 < pages.length
              ? () => _changePage(_page + 1, pages.length)
              : null,
          onDragChanged: (offset) => _dragTranslation.value = offset,
          child: AnimatedBuilder(
            animation: Listenable.merge([_transition, _dragTranslation]),
            builder: (context, child) {
              final progress = Curves.easeOutCubic.transform(_transition.value);
              final theme = _menuTheme;
              final rtl = Directionality.of(context) == TextDirection.rtl;
              return Transform.translate(
                key: const ValueKey('player-page-transition'),
                offset: Offset(
                  (1 - progress) *
                          theme.openTranslation *
                          _pageDirection *
                          (rtl ? -1 : 1) +
                      (theme.reducedMotion ? 0 : _dragTranslation.value),
                  0,
                ),
                transformHitTests: false,
                child: Opacity(opacity: .7 + progress * .3, child: child),
              );
            },
            child: measuredContent,
          ),
        ),
      );
      final label =
          '${widget.pageLabel ?? 'Page'} ${_page + 1} / ${pages.length}';
      Widget previous() => IconButton(
        key: const ValueKey('player-page-previous'),
        tooltip:
            '${french ? 'Page précédente' : 'Previous page'}${sideNavigation ? ' · $label' : ''}',
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        onPressed: allMeasured && _page > 0
            ? () => _changePage(_page - 1, pages.length)
            : null,
        icon: const Icon(Icons.chevron_left),
      );
      Widget next() => IconButton(
        key: const ValueKey('player-page-next'),
        tooltip:
            '${french ? 'Page suivante' : 'Next page'}${sideNavigation ? ' · $label' : ''}',
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        onPressed: allMeasured && _page + 1 < pages.length
            ? () => _changePage(_page + 1, pages.length)
            : null,
        icon: const Icon(Icons.chevron_right),
      );
      final body = sideNavigation
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: content),
                const SizedBox(width: 8),
                SizedBox(
                  width: navigationWidth,
                  child: allMeasured && hasPages
                      ? horizontalNavigation
                            ? Center(
                                child: Row(
                                  children: [
                                    previous(),
                                    const SizedBox(width: 8),
                                    next(),
                                  ],
                                ),
                              )
                            : Column(
                                children: [
                                  previous(),
                                  if (constraints.maxHeight >= 144) ...[
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: Center(
                                        child: Semantics(
                                          liveRegion: true,
                                          label: label,
                                          child: Tooltip(
                                            message: label,
                                            child: const Icon(Icons.more_horiz),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ] else
                                    const Spacer(),
                                  next(),
                                ],
                              )
                      : const SizedBox.shrink(),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: content),
                if (allMeasured && hasPages)
                  SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        previous(),
                        Expanded(
                          child: Semantics(
                            liveRegion: true,
                            child: Text(label, textAlign: TextAlign.center),
                          ),
                        ),
                        next(),
                      ],
                    ),
                  ),
              ],
            );
      return Actions(
        actions: {
          PlayerPageIntent: CallbackAction<PlayerPageIntent>(
            onInvoke: (intent) {
              if (allMeasured && !_editing) {
                _changePage(_page + intent.delta, pages.length);
              }
              return null;
            },
          ),
        },
        child: Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.pageDown):
                PlayerPageIntent.next(),
            SingleActivator(LogicalKeyboardKey.pageUp):
                PlayerPageIntent.previous(),
          },
          child: body,
        ),
      );
    },
  );
}

class _PlayerMeasure extends SingleChildRenderObjectWidget {
  const _PlayerMeasure({
    required this.onSize,
    required this.epoch,
    required super.child,
  });

  final int epoch;

  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _PlayerMeasureBox(onSize, epoch);

  @override
  void updateRenderObject(
    BuildContext context,
    _PlayerMeasureBox renderObject,
  ) {
    renderObject.onSize = onSize;
    if (renderObject.epoch != epoch) {
      renderObject.epoch = epoch;
      renderObject.resetMeasurement();
    }
  }
}

class _PlayerMeasureBox extends RenderProxyBox {
  _PlayerMeasureBox(this.onSize, this.epoch);

  int epoch;

  void resetMeasurement() {
    _lastSize = null;
    markNeedsLayout();
  }

  ValueChanged<Size> onSize;
  Size? _lastSize;

  @override
  void performLayout() {
    super.performLayout();
    if (_lastSize == size) return;
    _lastSize = size;
    final measured = size;
    final measuredEpoch = epoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached && epoch == measuredEpoch) onSize(measured);
    });
  }
}

class PlayerHorizontalSwipeRegion extends StatefulWidget {
  const PlayerHorizontalSwipeRegion({
    super.key,
    required this.child,
    this.onPrevious,
    this.onNext,
    this.resetToken,
    this.onDragChanged,
  });

  final Widget child;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final Object? resetToken;
  final ValueChanged<double>? onDragChanged;

  @override
  State<PlayerHorizontalSwipeRegion> createState() =>
      _PlayerHorizontalSwipeRegionState();
}

class _PlayerHorizontalSwipeRegionState
    extends State<PlayerHorizontalSwipeRegion> {
  Offset _offset = Offset.zero;
  double _furthest = 0;
  int _direction = 0;
  bool _active = false;
  bool _cancelled = false;

  bool get _editing =>
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorStateOfType<EditableTextState>() !=
      null;

  bool _allowPointer(PointerDownEvent event) {
    if (_editing || widget.onPrevious == null && widget.onNext == null) {
      return false;
    }
    final hits = HitTestResult();
    WidgetsBinding.instance.hitTestInView(hits, event.position, event.viewId);
    return !hits.path.any((entry) => entry.target is RenderEditable);
  }

  @override
  void didUpdateWidget(PlayerHorizontalSwipeRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetToken != widget.resetToken) _cancel();
  }

  void _start() {
    _offset = Offset.zero;
    _furthest = 0;
    _direction = 0;
    _active = true;
    _cancelled = _editing;
    widget.onDragChanged?.call(0);
  }

  VoidCallback? _target() {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return (_offset.dx < 0) != rtl ? widget.onNext : widget.onPrevious;
  }

  void _move(PointerMoveEvent event) {
    if (!_active) return;
    _offset += event.localDelta;
    final horizontal = _offset.dx.abs();
    final vertical = _offset.dy.abs();
    if (_editing || vertical >= kTouchSlop && vertical >= horizontal * .75) {
      _cancelled = true;
    }
    if (_direction == 0 && horizontal >= kTouchSlop) {
      _direction = _offset.dx.sign.toInt();
    }
    if (_direction != 0) {
      final distance = _offset.dx * _direction;
      _furthest = math.max(_furthest, distance);
      if (_furthest - distance >= kTouchSlop) _cancelled = true;
    }
    widget.onDragChanged?.call(
      !_cancelled && _target() != null
          ? (_offset.dx * .12).clamp(-14.0, 14.0)
          : 0,
    );
  }

  void _cancel() {
    _active = false;
    widget.onDragChanged?.call(0);
  }

  void _end() {
    final action =
        _active &&
            !_cancelled &&
            _offset.dx.abs() >= 48 &&
            _offset.dx.abs() >= _offset.dy.abs() * 1.5
        ? _target()
        : null;
    _cancel();
    action?.call();
  }

  @override
  Widget build(BuildContext context) => RawGestureDetector(
    behavior: HitTestBehavior.opaque,
    gestures: {
      _PlayerPagePanRecognizer:
          GestureRecognizerFactoryWithHandlers<_PlayerPagePanRecognizer>(
            () => _PlayerPagePanRecognizer(),
            (recognizer) {
              recognizer.allowPointer = _allowPointer;
              recognizer
                ..onPointerStarted = _start
                ..onPointerMoved = _move
                ..onPointerCancelled = _cancel
                ..onEnd = (_) {
                  _end();
                }
                ..onCancel = _cancel;
            },
          ),
    },
    child: widget.child,
  );
}

class _PlayerPagePanRecognizer extends PanGestureRecognizer {
  bool Function(PointerDownEvent)? allowPointer;
  VoidCallback? onPointerStarted;
  ValueChanged<PointerMoveEvent>? onPointerMoved;
  VoidCallback? onPointerCancelled;
  int? _pointer;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _pointer = event.pointer;
    onPointerStarted?.call();
    super.addAllowedPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer == _pointer) {
      if (event is PointerMoveEvent) onPointerMoved?.call(event);
      if (event is PointerCancelEvent) onPointerCancelled?.call();
    }
    super.handleEvent(event);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _pointer = null;
    super.didStopTrackingLastPointer(pointer);
  }

  @override
  bool isPointerAllowed(PointerEvent event) =>
      event is PointerDownEvent &&
      _pointer == null &&
      (allowPointer?.call(event) ?? false) &&
      super.isPointerAllowed(event);
}
