import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../avelune_cartridge.dart';
import '../avelune_theme.dart';
import 'avelune_home_geometry.dart';
import 'avelune_home_view_data.dart';

const double kAveluneGameShelfMaxCacheExtent = 640;

class AveluneGameShelf extends StatefulWidget {
  const AveluneGameShelf({
    super.key,
    required this.geometry,
    required this.games,
    required this.selectedGameId,
    this.onGameSelected,
    this.onAddGame,
    this.cartridgeKeyFor,
    this.hiddenGameIds = const <String>{},
  });

  final AveluneHomeGeometry geometry;
  final List<AveluneGameViewData> games;
  final String? selectedGameId;
  final ValueChanged<AveluneGameViewData>? onGameSelected;
  final VoidCallback? onAddGame;
  final GlobalKey Function(String gameId)? cartridgeKeyFor;
  final Set<String> hiddenGameIds;

  @override
  State<AveluneGameShelf> createState() => _AveluneGameShelfState();
}

class _AveluneGameShelfState extends State<AveluneGameShelf> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = <String, GlobalKey>{};

  double get _itemExtent =>
      widget.geometry.shelfCartridgeSize.width + widget.geometry.shelfGap;

  @override
  void initState() {
    super.initState();
    _scheduleSelectedGameReveal();
  }

  @override
  void didUpdateWidget(covariant AveluneGameShelf oldWidget) {
    super.didUpdateWidget(oldWidget);
    final gameIdsChanged = oldWidget.games.length != widget.games.length ||
        !oldWidget.games
            .map((game) => game.id)
            .toSet()
            .containsAll(widget.games.map((game) => game.id));
    if (oldWidget.selectedGameId != widget.selectedGameId || gameIdsChanged) {
      _scheduleSelectedGameReveal();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final geometry = widget.geometry;
    final bottomPadding =
        geometry.shelfRect.bottom - geometry.anchors.shelfBaseline.dy;

    return LayoutBuilder(
      builder: (context, constraints) => SizedBox.expand(
        key: const ValueKey<String>('avelune-game-shelf'),
        child: ListView.builder(
          key: const ValueKey<String>('avelune-game-shelf-list'),
          controller: _scrollController,
          primary: false,
          scrollDirection: Axis.horizontal,
          scrollCacheExtent: ScrollCacheExtent.pixels(
            math.min(
              kAveluneGameShelfMaxCacheExtent,
              constraints.maxWidth * 1.5,
            ),
          ),
          itemExtent: _itemExtent,
          padding: EdgeInsets.only(
            left: geometry.shelfHorizontalPadding,
            right: geometry.shelfHorizontalPadding,
          ),
          itemCount: widget.games.length + 1,
          semanticChildCount: widget.games.length + 1,
          itemBuilder: (context, index) {
            if (index == widget.games.length) {
              return _shelfItem(
                id: 'avelune.add-game',
                bottomPadding: bottomPadding,
                child: KeyedSubtree(
                  key: const ValueKey<String>('avelune-game-shelf-add'),
                  child: SizedBox.fromSize(
                    size: geometry.shelfCartridgeSize,
                    child: AveluneCartridge.addGame(
                      displaySize: AveluneCartridgeDisplaySize.shelf,
                      onPressed: widget.onAddGame,
                    ),
                  ),
                ),
              );
            }

            final game = widget.games[index];
            return _shelfItem(
              id: game.id,
              bottomPadding: bottomPadding,
              child: KeyedSubtree(
                key: ValueKey<String>('avelune-game-shelf-item-${game.id}'),
                child: KeyedSubtree(
                  key: const ValueKey<String>('avelune-game-shelf-game'),
                  child: KeyedSubtree(
                    key: widget.cartridgeKeyFor?.call(game.id),
                    child: Visibility(
                      visible: !widget.hiddenGameIds.contains(game.id),
                      maintainAnimation: true,
                      maintainSize: true,
                      maintainState: true,
                      child: SizedBox.fromSize(
                        size: geometry.shelfCartridgeSize,
                        child: AveluneCartridge(
                          gameId: game.id,
                          title: game.title,
                          subtitle: game.subtitle,
                          artwork: _artworkFor(game.artwork),
                          shellColor: game.shellColor,
                          selected: game.id == widget.selectedGameId,
                          invalid: !game.isValid,
                          displaySize: AveluneCartridgeDisplaySize.shelf,
                          onPressed: widget.onGameSelected == null
                              ? null
                              : () => widget.onGameSelected!(game),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _shelfItem({
    required String id,
    required double bottomPadding,
    required Widget child,
  }) =>
      KeyedSubtree(
        key: _itemKeys.putIfAbsent(id, GlobalKey.new),
        child: Padding(
          padding: EdgeInsets.only(
            right: widget.geometry.shelfGap,
            bottom: bottomPadding,
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        ),
      );

  void _scheduleSelectedGameReveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final selectedId = widget.selectedGameId;
      if (selectedId == null) return;
      final index = widget.games.indexWhere((game) => game.id == selectedId);
      if (index < 0) return;

      final position = _scrollController.position;
      final target = (widget.geometry.shelfHorizontalPadding +
              (index * _itemExtent) -
              ((position.viewportDimension - _itemExtent) / 2))
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      final reducedMotion = MediaQuery.disableAnimationsOf(context);
      final future = reducedMotion
          ? Future<void>.sync(() => _scrollController.jumpTo(target))
          : _scrollController.animateTo(
              target,
              duration: context.aveluneMotion.selection,
              curve: context.aveluneMotion.movementCurve,
            );
      future.whenComplete(() {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final itemContext = _itemKeys[selectedId]?.currentContext;
          if (!mounted || itemContext == null) return;
          Scrollable.ensureVisible(
            itemContext,
            alignment: 0.5,
            duration: Duration.zero,
          );
        });
      });
    });
  }
}

ImageProvider<Object>? _artworkFor(AveluneArtworkViewData artwork) {
  final path = artwork.path;
  if (path == null || path.trim().isEmpty) return null;
  return FileImage(File(path));
}
