import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pokemap_hub/features/appearance/application/notifiers/avelune_appearance_notifier.dart';
import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_preferences.dart';
import 'package:pokemap_hub/presentation/theme/avelune_theme.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_room_scene.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemap_hub/presentation/shared/artwork/local_artwork_image.dart';

/// Letterbox backdrop and the too-small viewport notice.
///
/// Split out of hub_shell.dart. These widgets were private; Dart privacy is
/// library-scoped, so crossing a file requires them to be public.

class AveluneLetterboxBackdrop extends StatelessWidget {
  const AveluneLetterboxBackdrop({required this.appearanceController});

  final AveluneAppearanceNotifier? appearanceController;

  @override
  Widget build(BuildContext context) {
    if (appearanceController == null) return _paint(context, null, null);
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(aveluneAppearanceNotifierProvider);
        return _paint(
          context,
          state.preferences,
          state.customBackgroundPath,
        );
      },
    );
  }

  Widget _paint(
    BuildContext context,
    AveluneAppearancePreferences? preferences,
    String? customBackgroundPath,
  ) {
    final colors = context.aveluneColors;
    final image = aveluneRoomBackgroundImage(
      preferences ?? const AveluneAppearancePreferences(),
      customBackgroundPath == null
          ? null
          : requireLocalArtworkImage(customBackgroundPath),
    );
    return IgnorePointer(
      child: Stack(
        key: const ValueKey<String>('avelune-letterbox-backdrop'),
        fit: StackFit.expand,
        children: <Widget>[
          ColoredBox(color: colors.canvas),
          // Blurring the image directly rather than with a BackdropFilter: there
          // is nothing painted underneath to sample.
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 56, sigmaY: 56),
            child: Image(
              image: image,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) => ColoredBox(color: colors.canvas),
            ),
          ),
          // Held well back so the console stays the subject.
          ColoredBox(color: colors.canvas.withValues(alpha: 0.68)),
        ],
      ),
    );
  }
}

/// Shown when the window is smaller than the console geometry supports.
class HubViewportTooSmall extends StatelessWidget {
  const HubViewportTooSmall({
    required this.minimumWidth,
    required this.minimumHeight,
  });

  final double minimumWidth;
  final double minimumHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final french = Localizations.maybeLocaleOf(context)?.languageCode == 'fr';
    return ColoredBox(
      key: const ValueKey<String>('avelune-viewport-too-small'),
      color: colors.canvas,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AveluneSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                AveluneIcons.viewport,
                color: colors.textSecondary,
                size: 32,
              ),
              const SizedBox(height: AveluneSpacing.md),
              Text(
                french ? 'Fenêtre trop petite' : 'Window too small',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AveluneSpacing.xs),
              Text(
                french
                    ? 'Agrandissez la fenêtre à au moins '
                        '${minimumWidth.toInt()} x ${minimumHeight.toInt()}.'
                    : 'Resize the window to at least '
                        '${minimumWidth.toInt()} x ${minimumHeight.toInt()}.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
