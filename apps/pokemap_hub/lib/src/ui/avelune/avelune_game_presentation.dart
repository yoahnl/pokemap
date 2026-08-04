import 'dart:io';

import 'package:flutter/material.dart';

import '../hub_dashboard_controller.dart';
import '../hub_game_views.dart';
import 'avelune_theme.dart';

String aveluneArtworkHeroTag(String gameId) => 'avelune-artwork-$gameId';

ImageProvider<Object>? aveluneArtworkFor(HubGameView game) {
  final path = game.activity.coverPath ??
      game.activity.heroPath ??
      game.activity.iconPath;
  return path == null ? null : FileImage(File(path));
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
