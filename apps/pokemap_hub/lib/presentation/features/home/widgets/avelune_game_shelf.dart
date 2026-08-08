import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:pokemap_hub/presentation/features/home/widgets/avelune_cartridge.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_game_presentation.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_home_geometry.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_home_view_data.dart';
import 'package:pokemap_hub/presentation/shared/artwork/local_artwork_image.dart';

const double kAveluneGameShelfMaxCacheExtent = 640;

class AveluneGameShelf extends StatefulWidget {
  const AveluneGameShelf({
    super.key,
    required this.geometry,
    required this.games,
    required this.selectedGameId,
    this.onGameSelected,
    this.onGameLongPress,
    this.onAddGame,
    this.includeAddGame = true,
    this.cartridgeKeyFor,
    this.artworkHeroGameId,
    this.hiddenGameIds = const <String>{},
  });

  final AveluneHomeGeometry geometry;
  final List<AveluneGameViewData> games;
  final String? selectedGameId;
  final ValueChanged<AveluneGameViewData>? onGameSelected;
  final ValueChanged<AveluneGameViewData>? onGameLongPress;
  final VoidCallback? onAddGame;
  final bool includeAddGame;
  final GlobalKey Function(String gameId)? cartridgeKeyFor;
  final String? artworkHeroGameId;
  final Set<String> hiddenGameIds;

  @override
  State<AveluneGameShelf> createState() => _AveluneGameShelfState();
}

class _AveluneGameShelfState extends State<AveluneGameShelf> {
  final ScrollController _scrollController = ScrollController();

  double get _itemExtent =>
      widget.geometry.shelfCartridgeSize.width + widget.geometry.shelfGap;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final geometry = widget.geometry;
    final shelfGames = widget.games
        .where((game) => game.id != widget.selectedGameId)
        .toList(growable: false);
    final itemCount = shelfGames.length + (widget.includeAddGame ? 1 : 0);
    final bottomPadding =
        geometry.shelfRect.bottom - geometry.anchors.shelfBaseline.dy;

    return LayoutBuilder(builder: (context, constraints) {
      final contentWidth = itemCount == 0
          ? 0.0
          : itemCount * geometry.shelfCartridgeSize.width +
              (itemCount - 1) * geometry.shelfGap;
      final horizontalPadding = math.max(
        geometry.shelfHorizontalPadding,
        (constraints.maxWidth - contentWidth) / 2,
      );

      return SizedBox.expand(
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
            left: horizontalPadding,
            right: horizontalPadding,
          ),
          itemCount: itemCount,
          semanticChildCount: itemCount,
          itemBuilder: (context, index) {
            if (widget.includeAddGame && index == shelfGames.length) {
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

            final game = shelfGames[index];
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
                          onLongPress: widget.onGameLongPress == null
                              ? null
                              : () => widget.onGameLongPress!(game),
                          artworkHeroTag: game.id == widget.artworkHeroGameId
                              ? aveluneArtworkHeroTag(game.id)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _shelfItem({
    required String id,
    required double bottomPadding,
    required Widget child,
  }) =>
      Padding(
        key: ValueKey<String>('avelune-game-shelf-slot-$id'),
        padding: EdgeInsets.only(
          right: widget.geometry.shelfGap,
          bottom: bottomPadding,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      );
}

ImageProvider<Object>? _artworkFor(AveluneArtworkViewData artwork) {
  final path = artwork.path;
  if (path == null || path.trim().isEmpty) return null;
  return requireLocalArtworkImage(path);
}
