
import 'package:flutter/material.dart';

import 'package:pokemap_hub/presentation/shell/hub_game_views.dart';
import 'package:pokemap_hub/presentation/theme/avelune_theme.dart';
import 'package:pokemap_hub/features/dashboard/application/notifiers/hub_dashboard_state.dart';
import 'package:pokemap_hub/presentation/shared/artwork/local_artwork_image.dart';

String aveluneArtworkHeroTag(String gameId) => 'avelune-artwork-$gameId';

Widget aveluneArtworkFlightShuttleBuilder(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final targetContext =
      direction == HeroFlightDirection.push ? toHeroContext : fromHeroContext;
  final hero = targetContext.widget as Hero;
  return KeyedSubtree(
    key: const ValueKey<String>('avelune-details-hero-flight'),
    child: FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: hero.child,
      ),
    ),
  );
}

ImageProvider<Object>? aveluneArtworkFor(HubGameView game) {
  final path = game.activity.coverPath ??
      game.activity.heroPath ??
      game.activity.iconPath;
  return localArtworkImage(path);
}

Color aveluneShellColorFor(BuildContext context, HubGameView game) {
  final colors = context.aveluneColors;
  final accent = decodeHubAccentColor(game.game.branding?.accentColor);
  return accent == null
      ? colors.shell
      : Color.lerp(accent, colors.shell, 0.24)!;
}

String formatAveluneRelativeTime(
  DateTime value,
  DateTime reference, {
  required bool french,
  bool compact = false,
}) {
  final difference = reference.toUtc().difference(value.toUtc());
  if (difference.isNegative || difference.inMinutes < 1) {
    return french ? 'À l’instant' : 'Now';
  }
  if (difference.inMinutes < 60) {
    return compact
        ? '${difference.inMinutes} min'
        : french
            ? 'Il y a ${difference.inMinutes} min'
            : '${difference.inMinutes} min ago';
  }
  if (difference.inHours < 24) {
    return compact
        ? '${difference.inHours} h'
        : french
            ? 'Il y a ${difference.inHours} h'
            : '${difference.inHours} h ago';
  }
  if (difference.inDays == 1) return french ? 'Hier' : 'Yesterday';
  return compact
      ? '${difference.inDays} j'
      : french
          ? 'Il y a ${difference.inDays} j'
          : '${difference.inDays} d ago';
}
