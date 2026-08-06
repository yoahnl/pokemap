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
import 'avelune_relative_time.dart';

/// Fraction of the credenza canvas at which its shelf board sits — the surface
/// the shelf cartridges stand on.
const double kAveluneCredenzaShelfBoardFraction = 0.68;

/// Fraction of the credenza canvas at which its art starts.
///
/// `room/furniture/credenza_*.webp` are 768x700 with the back edge of the top
/// surface as their first opaque row (y=199). The console is seated on that
/// edge, so the two fractions have to be read together.
const double kAveluneCredenzaVisibleTopFraction = 199 / 700;

@immutable
final class AveluneRoomSceneLayout {
  const AveluneRoomSceneLayout._({
    required this.furnitureRect,
    required this.furnitureSupportY,
    required this.furnitureShelfBaselineY,
  });

  factory AveluneRoomSceneLayout.resolve(AveluneHomeGeometry geometry) {
    // The console art keeps transparent padding below its feet, so the surface
    // has to meet the foot line rather than the bottom of the layout box.
    final supportY = geometry.consoleRect.top +
        (geometry.consoleRect.height * kAveluneConsoleFootlineFraction);
    final shelfBaselineY = geometry.anchors.shelfBaseline.dy;
    // Scale so both anchors land: the top surface on the console's feet and the
    // shelf board under the cartridges. A `contentWidth * 1.62` candidate used
    // to win this comparison, overriding the shelf anchor and running the
    // credenza past the bottom of the screen.
    final anchoredHeight = (shelfBaselineY - supportY) /
        (kAveluneCredenzaShelfBoardFraction -
            kAveluneCredenzaVisibleTopFraction);
    // On very small screens the anchored piece would not reach the side walls,
    // so covering the room wins and the board drifts instead.
    final coveringHeight = geometry.contentRect.width / _sourceAspectRatio;
    final height = math.max(anchoredHeight, coveringHeight);
    final width = height * _sourceAspectRatio;
    final rect = Rect.fromLTWH(
      geometry.contentRect.center.dx - (width / 2),
      supportY - (height * kAveluneCredenzaVisibleTopFraction),
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
    this.recentActivity = const [],
    this.onGameSelected,
    this.onAddGame,
    this.onHeroPressed,
    this.onHeroLongPress,
    this.onActivitySelected,
    this.heroAnchorKey,
    this.shelfCartridgeKeyFor,
    this.hiddenShelfGameIds = const <String>{},
    this.showHero = true,
    this.insertionOverlay,
    this.foregroundOverlay,
    this.heroSemanticsLabel,
    this.referenceTime,
  });

  final AveluneHomeGeometry geometry;
  final AveluneAppearancePreferences appearance;
  final List<AveluneGameViewData> games;
  final AveluneGameViewData? selectedGame;
  final ImageProvider<Object>? customBackground;
  final AveluneConsoleState? consoleState;
  final double insertionProgress;
  final List<AveluneRecentActivityViewData> recentActivity;
  final ValueChanged<AveluneGameViewData>? onGameSelected;
  final VoidCallback? onAddGame;
  final VoidCallback? onHeroPressed;
  final VoidCallback? onHeroLongPress;
  final ValueChanged<AveluneRecentActivityViewData>? onActivitySelected;
  final GlobalKey? heroAnchorKey;
  final GlobalKey Function(String gameId)? shelfCartridgeKeyFor;
  final Set<String> hiddenShelfGameIds;
  final bool showHero;
  /// Cartridge being inserted. Painted over the console and clipped at the slot
  /// mouth so it disappears into the cavity instead of behind the hardware.
  final Widget? insertionOverlay;
  final Widget? foregroundOverlay;
  final String? heroSemanticsLabel;

  /// Pinned clock for relative wording. Goldens and tests must supply it so
  /// the render does not drift with the calendar.
  final DateTime? referenceTime;

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
          if (recentActivity.isNotEmpty)
            Positioned.fromRect(
              rect: geometry.activityRect,
              child: _RoomActivityRail(
                activities: recentActivity,
                referenceTime: referenceTime,
                maxVisibleRows: geometry.activityRowCapacity,
                onActivitySelected: onActivitySelected,
              ),
            ),
          Positioned.fromRect(
            rect: geometry.consoleRect,
            child: AveluneConsole(
              state: consoleState,
              insertionProgress: insertionProgress,
            ),
          ),
          if (insertionOverlay != null)
            Positioned.fill(
              child: ClipRect(
                key: const ValueKey<String>('avelune-slot-mouth-clip'),
                clipper: _AveluneSlotMouthClipper(geometry.consoleSlotMouthY),
                child: insertionOverlay!,
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

/// Cuts everything below the slot's near lip, so a descending cartridge is
/// swallowed by the opening rather than hidden by the console silhouette.
class _AveluneSlotMouthClipper extends CustomClipper<Rect> {
  const _AveluneSlotMouthClipper(this.mouthY);

  final double mouthY;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, 0, size.width, mouthY);

  @override
  bool shouldReclip(_AveluneSlotMouthClipper oldClipper) =>
      oldClipper.mouthY != mouthY;
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

class _RoomActivityRail extends StatelessWidget {
  const _RoomActivityRail({
    required this.activities,
    required this.maxVisibleRows,
    this.onActivitySelected,
    this.referenceTime,
  });

  final List<AveluneRecentActivityViewData> activities;
  final int maxVisibleRows;
  final DateTime? referenceTime;
  final ValueChanged<AveluneRecentActivityViewData>? onActivitySelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final french = Localizations.localeOf(context).languageCode == 'fr';
    const titleHeight = 16.0;
    const spacingAfterTitle = AveluneSpacing.xxs;
    const tileHeight = 32.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableForTiles =
            constraints.maxHeight - titleHeight - spacingAfterTitle;
        final fitsByHeight = availableForTiles <= 0
            ? 0
            : (availableForTiles / tileHeight).floor();
        final visibleCount =
            activities.length.clamp(0, math.min(maxVisibleRows, fitsByHeight));
        final hasMore = activities.length > visibleCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: titleHeight,
              child: Row(
                children: <Widget>[
                  Icon(Icons.schedule_rounded, size: 12, color: colors.brass),
                  const SizedBox(width: AveluneSpacing.xxs),
                  Expanded(
                    child: Text(
                      french ? 'ACTIVITÉ RÉCENTE' : 'RECENT ACTIVITY',
                      maxLines: 1,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        height: 1.1,
                      ),
                    ),
                  ),
                  if (hasMore)
                    GestureDetector(
                      onTap: () => _showAllActivities(context),
                      child: Text(
                        french ? 'Voir tout' : 'See all',
                        maxLines: 1,
                        style: TextStyle(
                          color: colors.brass,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: spacingAfterTitle),
            for (var i = 0; i < visibleCount; i++)
              _ActivityTile(
                activity: activities[i],
                referenceTime: referenceTime,
                onTap: onActivitySelected != null
                    ? () => onActivitySelected!(activities[i])
                    : null,
              ),
          ],
        );
      },
    );
  }

  void _showAllActivities(BuildContext context) {
    final french = Localizations.localeOf(context).languageCode == 'fr';
    AveluneSheet.show<void>(
      context: context,
      title: french ? 'Activité récente' : 'Recent activity',
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        itemCount: activities.length,
        itemBuilder: (context, index) => _ActivityTile(
          activity: activities[index],
          referenceTime: referenceTime,
          onTap: () {
            Navigator.of(context).pop();
            onActivitySelected?.call(activities[index]);
          },
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.activity,
    this.onTap,
    this.referenceTime,
  });

  final AveluneRecentActivityViewData activity;
  final VoidCallback? onTap;
  final DateTime? referenceTime;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final now = referenceTime ?? DateTime.now();
    final french = Localizations.localeOf(context).languageCode == 'fr';
    final relative =
        aveluneRelativeTime(activity.occurredAt, now, french: french);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: AveluneSpacing.xs),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                width: 24,
                height: 24,
                child: _activityArtwork(activity.artwork),
              ),
            ),
            const SizedBox(width: AveluneSpacing.sm),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    activity.gameTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    relative,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 9,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityArtwork(AveluneArtworkViewData artwork) {
    final path = artwork.path;
    if (path == null || path.trim().isEmpty) {
      return ColoredBox(color: Colors.grey.shade800);
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => ColoredBox(color: Colors.grey.shade800),
    );
  }
}

