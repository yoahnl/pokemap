import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

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

class _PlayerPagedListState extends State<PlayerPagedList> {
  final _heights = <Key, double>{};
  late int _page = widget.initialPage;
  Key? _lastRevealedKey;
  bool _pageWasChosen = false;
  int _measurementEpoch = 0;
  (double, double, double)? _layoutSignature;
  (int, int)? _readyPage;
  double? _reportedHeight;

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
      setState(() {
        _page = next;
        _pageWasChosen = true;
      });
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
          widget.sideNavigation &&
          constraints.maxWidth >= 200 &&
          constraints.maxHeight >= 48;
      final horizontalNavigation = sideNavigation && constraints.maxHeight < 104;
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
      final content = ClipRect(
        key: const ValueKey('player-paged-body'),
        child: OverflowBox(
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
                          ? Center(child: Row(children: [previous(), const SizedBox(width: 8), next()]))
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
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.pageDown): () =>
              _changePage(_page + 1, pages.length),
          const SingleActivator(LogicalKeyboardKey.pageUp): () =>
              _changePage(_page - 1, pages.length),
        },
        child: body,
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
