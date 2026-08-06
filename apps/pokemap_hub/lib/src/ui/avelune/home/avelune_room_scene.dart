import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../appearance/avelune_appearance_catalog.dart';
import '../appearance/avelune_appearance_preferences.dart';
import '../avelune_cartridge.dart';
import '../avelune_console.dart';
import '../avelune_theme.dart';
import 'avelune_game_shelf.dart';
import 'avelune_home_geometry.dart';
import 'avelune_home_view_data.dart';

@immutable
final class AveluneRoomSceneLayout {
  const AveluneRoomSceneLayout._({
    required this.furnitureRect,
    required this.furnitureSupportY,
    required this.furnitureShelfBaselineY,
  });

  factory AveluneRoomSceneLayout.resolve(AveluneHomeGeometry geometry) {
    final supportY = geometry.consoleRect.bottom;
    final shelfBaselineY = geometry.anchors.shelfBaseline.dy;
    final height = math.max(
      math.max(
        geometry.shelfCartridgeSize.height * 2.1,
        (shelfBaselineY - supportY) /
            (_sourceShelfBaseline - _sourceVisibleTop),
      ),
      geometry.contentRect.width * 1.62 / _sourceAspectRatio,
    );
    final width = height * _sourceAspectRatio;
    final rect = Rect.fromLTWH(
      geometry.contentRect.center.dx - (width / 2),
      supportY - (height * _sourceVisibleTop),
      width,
      height,
    );

    return AveluneRoomSceneLayout._(
      furnitureRect: rect,
      furnitureSupportY: supportY,
      furnitureShelfBaselineY: shelfBaselineY,
    );
  }

  static const double _sourceAspectRatio = 768 / 700;
  static const double _sourceVisibleTop = 0.286;
  static const double _sourceShelfBaseline = 0.68;

  final Rect furnitureRect;
  final double furnitureSupportY;
  final double furnitureShelfBaselineY;
}

class AveluneRoomScene extends StatelessWidget {
  const AveluneRoomScene({
    super.key,
    required this.geometry,
    required this.appearance,
    required this.games,
    required this.selectedGame,
    this.customBackground,
    this.consoleState,
    this.insertionProgress = 0,
    this.onGameSelected,
    this.onAddGame,
    this.onHeroPressed,
    this.onHeroLongPress,
    this.heroAnchorKey,
    this.shelfCartridgeKeyFor,
    this.hiddenShelfGameIds = const <String>{},
    this.showHero = true,
    this.behindConsoleOverlay,
    this.foregroundOverlay,
    this.heroSemanticsLabel,
  });

  final AveluneHomeGeometry geometry;
  final AveluneAppearancePreferences appearance;
  final List<AveluneGameViewData> games;
  final AveluneGameViewData? selectedGame;
  final ImageProvider<Object>? customBackground;
  final AveluneConsoleState? consoleState;
  final double insertionProgress;
  final ValueChanged<AveluneGameViewData>? onGameSelected;
  final VoidCallback? onAddGame;
  final VoidCallback? onHeroPressed;
  final VoidCallback? onHeroLongPress;
  final GlobalKey? heroAnchorKey;
  final GlobalKey Function(String gameId)? shelfCartridgeKeyFor;
  final Set<String> hiddenShelfGameIds;
  final bool showHero;
  final Widget? behindConsoleOverlay;
  final Widget? foregroundOverlay;
  final String? heroSemanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final roomLayout = AveluneRoomSceneLayout.resolve(geometry);
    final selected = selectedGame;

    return SizedBox.expand(
      key: const ValueKey<String>('avelune-room-scene'),
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: <Widget>[
          Image(
            key: const ValueKey<String>('avelune-room-background-layer'),
            image: _backgroundFor(appearance, customBackground),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            excludeFromSemantics: true,
          ),
          IgnorePointer(
            child: DecoratedBox(
              key: const ValueKey<String>('avelune-room-light-layer'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const <double>[0, 0.38, 1],
                  colors: <Color>[
                    colors.warning.withValues(alpha: 0.12),
                    colors.room.withValues(alpha: 0.08),
                    colors.canvas.withValues(alpha: 0.56),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fromRect(
            rect: roomLayout.furnitureRect,
            child: Image.asset(
              AveluneAppearanceCatalog.furnitureFinish(appearance.furnitureId)
                  .assetPath!,
              key: const ValueKey<String>('avelune-room-furniture-layer'),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true,
            ),
          ),
          Positioned(
            left: geometry.contentRect.left,
            right: geometry.viewportSize.width - geometry.contentRect.right,
            top: roomLayout.furnitureSupportY - 0.5,
            height: 1,
            child: const SizedBox(
              key: ValueKey<String>('avelune-furniture-support-anchor'),
            ),
          ),
          Positioned(
            left: geometry.contentRect.left,
            right: geometry.viewportSize.width - geometry.contentRect.right,
            top: roomLayout.furnitureShelfBaselineY - 0.5,
            height: 1,
            child: const SizedBox(
              key: ValueKey<String>('avelune-furniture-shelf-baseline'),
            ),
          ),
          Positioned.fromRect(
            rect: geometry.shelfRect,
            child: AveluneGameShelf(
              geometry: geometry,
              games: games,
              selectedGameId: selected?.id,
              onGameSelected: onGameSelected,
              onAddGame: onAddGame,
              cartridgeKeyFor: shelfCartridgeKeyFor,
              hiddenGameIds: hiddenShelfGameIds,
            ),
          ),
          if (behindConsoleOverlay != null)
            Positioned.fill(child: behindConsoleOverlay!),
          Positioned.fromRect(
            rect: geometry.consoleRect,
            child: AveluneConsole(
              state: consoleState,
              insertionProgress: insertionProgress,
            ),
          ),
          if (selected != null) ...<Widget>[
            Positioned.fromRect(
              rect: geometry.heroCartridgeRect.inflate(
                geometry.heroCartridgeSize.width * 0.22,
              ),
              child: Visibility(
                visible: showHero,
                maintainAnimation: true,
                maintainSize: true,
                maintainState: true,
                child: IgnorePointer(
                  child: DecoratedBox(
                    key: const ValueKey<String>('avelune-room-hero-glow'),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: <Color>[
                          colors.glow.withValues(alpha: 0.3),
                          colors.glow.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fromRect(
              rect: geometry.heroCartridgeRect,
              child: KeyedSubtree(
                key: heroAnchorKey,
                child: Visibility(
                  visible: showHero,
                  maintainAnimation: true,
                  maintainSize: true,
                  maintainState: true,
                  child: AveluneCartridge(
                    key: const ValueKey<String>(
                      'avelune-room-hero-cartridge',
                    ),
                    gameId: selected.id,
                    title: selected.title,
                    subtitle: selected.subtitle,
                    artwork: _artworkFor(selected.artwork),
                    shellColor: selected.shellColor,
                    selected: true,
                    invalid: !selected.isValid,
                    displaySize: AveluneCartridgeDisplaySize.hero,
                    onPressed: onHeroPressed,
                    onLongPress: onHeroLongPress,
                    semanticsLabel: heroSemanticsLabel,
                  ),
                ),
              ),
            ),
          ],
          if (foregroundOverlay != null)
            Positioned.fill(child: foregroundOverlay!),
        ],
      ),
    );
  }
}

ImageProvider<Object> _backgroundFor(
  AveluneAppearancePreferences appearance,
  ImageProvider<Object>? customBackground,
) {
  if (appearance.backgroundId == AveluneAppearanceCatalog.customBackgroundId &&
      customBackground != null) {
    return customBackground;
  }
  final id =
      appearance.backgroundId == AveluneAppearanceCatalog.customBackgroundId
          ? AveluneAppearanceCatalog.defaultBackgroundId
          : appearance.backgroundId;
  return AssetImage(AveluneAppearanceCatalog.background(id).assetPath!);
}

ImageProvider<Object>? _artworkFor(AveluneArtworkViewData artwork) {
  final path = artwork.path;
  if (path == null || path.trim().isEmpty) return null;
  return FileImage(File(path));
}
