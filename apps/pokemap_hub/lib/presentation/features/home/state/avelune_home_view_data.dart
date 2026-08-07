import 'package:flutter/material.dart';

enum AveluneHomeStatus { loading, ready, empty, importing, error }

enum AveluneGameValidity { available, invalid }

enum AvelunePrimaryAction { continueGame, play, disabled }

enum AveluneArtworkKind { cover, hero, icon, fallback }

enum AveluneRecentActivityKind { latestSave }

@immutable
final class AveluneArtworkViewData {
  const AveluneArtworkViewData({required this.kind, this.path});

  final AveluneArtworkKind kind;
  final String? path;
}

@immutable
final class AveluneGameViewData {
  const AveluneGameViewData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.authorName,
    required this.artwork,
    required this.shellColor,
    required this.validity,
    required this.primaryAction,
    required this.isSelected,
    required this.lastSaveAt,
    required this.playTimeSeconds,
    this.diagnosticMessage,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String authorName;
  final AveluneArtworkViewData artwork;
  final Color shellColor;
  final AveluneGameValidity validity;
  final AvelunePrimaryAction primaryAction;
  final bool isSelected;
  final DateTime? lastSaveAt;
  final int playTimeSeconds;
  final String? diagnosticMessage;

  bool get isValid => validity == AveluneGameValidity.available;
}

@immutable
final class AveluneRecentActivityViewData {
  const AveluneRecentActivityViewData({
    required this.gameId,
    required this.gameTitle,
    required this.artwork,
    required this.occurredAt,
    required this.kind,
    required this.canActivate,
  });

  final String gameId;
  final String gameTitle;
  final AveluneArtworkViewData artwork;
  final DateTime occurredAt;
  final AveluneRecentActivityKind kind;
  final bool canActivate;
}

@immutable
final class AveluneImportViewData {
  const AveluneImportViewData({
    required this.isImporting,
    required this.canStart,
    required this.completedFiles,
    required this.totalFiles,
    required this.cancellable,
  });

  const AveluneImportViewData.idle({required bool canStart})
      : this(
          isImporting: false,
          canStart: canStart,
          completedFiles: 0,
          totalFiles: 0,
          cancellable: false,
        );

  final bool isImporting;
  final bool canStart;
  final int completedFiles;
  final int totalFiles;
  final bool cancellable;

  double? get progress {
    if (!isImporting || totalFiles <= 0) return null;
    return (completedFiles / totalFiles).clamp(0, 1);
  }
}

@immutable
final class AveluneHomeViewData {
  AveluneHomeViewData({
    required this.status,
    required List<AveluneGameViewData> games,
    required this.selectedGameId,
    required List<AveluneRecentActivityViewData> recentActivity,
    required this.import,
    required this.safeErrorMessage,
    required this.reducedMotion,
  })  : games = List<AveluneGameViewData>.unmodifiable(games),
        recentActivity =
            List<AveluneRecentActivityViewData>.unmodifiable(recentActivity);

  final AveluneHomeStatus status;
  final List<AveluneGameViewData> games;
  final String? selectedGameId;
  final List<AveluneRecentActivityViewData> recentActivity;
  final AveluneImportViewData import;
  final String? safeErrorMessage;
  final bool reducedMotion;

  bool get canImport => import.canStart;

  AveluneGameViewData? get selectedGame {
    final id = selectedGameId;
    if (id == null) return null;
    for (final game in games) {
      if (game.id == id) return game;
    }
    return null;
  }
}
