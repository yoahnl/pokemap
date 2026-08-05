import 'package:flutter/material.dart';

import '../appearance/avelune_appearance_preferences.dart';
import '../avelune_console.dart';
import 'avelune_home_geometry.dart';
import 'avelune_home_view_data.dart';
import 'avelune_room_scene.dart';

class AveluneHomeScreen extends StatelessWidget {
  const AveluneHomeScreen({
    super.key,
    required this.viewData,
    required this.appearance,
    this.customBackground,
    this.consoleState,
    this.insertionProgress = 0,
    this.onGameSelected,
    this.onAddGame,
    this.onHeroPressed,
    this.onHeroLongPress,
  });

  final AveluneHomeViewData viewData;
  final AveluneAppearancePreferences appearance;
  final ImageProvider<Object>? customBackground;
  final AveluneConsoleState? consoleState;
  final double insertionProgress;
  final ValueChanged<AveluneGameViewData>? onGameSelected;
  final VoidCallback? onAddGame;
  final VoidCallback? onHeroPressed;
  final VoidCallback? onHeroLongPress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final constrainedWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : mediaQuery.size.width;
        final constrainedHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : mediaQuery.size.height;
        final viewportSize = Size(constrainedWidth, constrainedHeight);
        final geometry = AveluneHomeGeometry.resolve(
          viewportSize: viewportSize,
          safeArea: mediaQuery.padding,
          textScaleFactor: mediaQuery.textScaler.scale(1),
        );

        return SizedBox.expand(
          key: const ValueKey<String>('avelune-home-screen'),
          child: AveluneRoomScene(
            geometry: geometry,
            appearance: appearance,
            games: viewData.games,
            selectedGame: viewData.selectedGame,
            customBackground: customBackground,
            consoleState: consoleState,
            insertionProgress: insertionProgress,
            onGameSelected: onGameSelected,
            onAddGame: onAddGame,
            onHeroPressed: onHeroPressed,
            onHeroLongPress: onHeroLongPress,
          ),
        );
      },
    );
  }
}
