import 'package:pokemap_hub/presentation/design_system/avelune_design_system.dart';
import 'package:pokemap_hub/features/dashboard/application/notifiers/hub_dashboard_notifier.dart';
import 'package:pokemap_hub/presentation/shell/hub_game_views.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_home_view_data.dart';

/// Pure projection from the Hub snapshot into immutable Avelune-facing data.
///
/// Paths are copied from the already-resolved activity snapshot. No file is
/// opened here, which keeps disk access out of Flutter build methods.
final class AveluneHomeViewDataMapper {
  const AveluneHomeViewDataMapper();

  AveluneHomeViewData map({
    required HubDashboardSnapshot snapshot,
    required bool canImport,
    required bool canContinue,
    required bool canPlay,
    required bool reducedMotion,
    String? selectedGameId,
  }) {
    final resolvedSelection = _resolveSelection(
      snapshot,
      requestedGameId: selectedGameId,
    );
    final games = snapshot.games
        .map(
          (view) => _game(
            view,
            selectedGameId: resolvedSelection,
            canContinue: canContinue,
            canPlay: canPlay,
          ),
        )
        .toList(growable: false);
    final recent = snapshot.games
        .where((view) => view.activity.lastSaveAt != null)
        .map(
          (view) => AveluneRecentActivityViewData(
            gameId: view.game.gameId,
            gameTitle: view.game.title,
            artwork: _artwork(view.activity),
            occurredAt: view.activity.lastSaveAt!,
            kind: AveluneRecentActivityKind.latestSave,
            canActivate: view.activity.installationHealthy &&
                view.activity.canContinue &&
                canContinue,
          ),
        )
        .toList(growable: false)
      ..sort((left, right) => right.occurredAt.compareTo(left.occurredAt));

    final progress = snapshot.installProgress;
    final isImporting = snapshot.status == HubDashboardStatus.installing;
    return AveluneHomeViewData(
      status: _status(snapshot),
      games: games,
      selectedGameId: resolvedSelection,
      recentActivity: recent,
      import: isImporting
          ? AveluneImportViewData(
              isImporting: true,
              canStart: false,
              completedFiles: progress?.completedFiles ?? 0,
              totalFiles: progress?.totalFiles ?? 0,
              cancellable: progress?.cancellable ?? false,
            )
          : AveluneImportViewData.idle(canStart: canImport),
      safeErrorMessage: snapshot.safeErrorMessage,
      reducedMotion: reducedMotion,
    );
  }

  AveluneGameViewData _game(
    HubGameView view, {
    required String? selectedGameId,
    required bool canContinue,
    required bool canPlay,
  }) {
    final healthy = view.activity.installationHealthy;
    final action = !healthy
        ? AvelunePrimaryAction.disabled
        : view.activity.canContinue
            ? canContinue
                ? AvelunePrimaryAction.continueGame
                : AvelunePrimaryAction.disabled
            : canPlay
                ? AvelunePrimaryAction.play
                : AvelunePrimaryAction.disabled;
    return AveluneGameViewData(
      id: view.game.gameId,
      title: view.game.title,
      subtitle: _nonEmpty(view.game.description),
      authorName: view.game.authorName,
      artwork: _artwork(view.activity),
      shellColor: decodeHubAccentColor(view.game.branding?.accentColor) ??
          AveluneColors.standard.shellNeutral,
      validity:
          healthy ? AveluneGameValidity.available : AveluneGameValidity.invalid,
      primaryAction: action,
      isSelected: view.game.gameId == selectedGameId,
      lastSaveAt: view.activity.lastSaveAt,
      playTimeSeconds: view.activity.playTimeSeconds,
      diagnosticMessage: view.activity.diagnostic?.message,
    );
  }

  AveluneArtworkViewData _artwork(HubGameActivity activity) {
    if (activity.coverPath != null) {
      return AveluneArtworkViewData(
        kind: AveluneArtworkKind.cover,
        path: activity.coverPath,
      );
    }
    if (activity.heroPath != null) {
      return AveluneArtworkViewData(
        kind: AveluneArtworkKind.hero,
        path: activity.heroPath,
      );
    }
    if (activity.iconPath != null) {
      return AveluneArtworkViewData(
        kind: AveluneArtworkKind.icon,
        path: activity.iconPath,
      );
    }
    return const AveluneArtworkViewData(kind: AveluneArtworkKind.fallback);
  }

  String? _resolveSelection(
    HubDashboardSnapshot snapshot, {
    required String? requestedGameId,
  }) {
    if (_contains(snapshot, requestedGameId)) return requestedGameId;

    HubGameView? latest;
    for (final game in snapshot.games) {
      final savedAt = game.activity.lastSaveAt;
      if (savedAt == null) continue;
      final latestAt = latest?.activity.lastSaveAt;
      if (latestAt == null || savedAt.isAfter(latestAt)) latest = game;
    }
    if (latest != null) return latest.game.gameId;

    final hubSelection = snapshot.selectedGame;
    if (hubSelection != null && hubSelection.activity.installationHealthy) {
      return hubSelection.game.gameId;
    }
    return snapshot.games.isEmpty ? null : snapshot.games.first.game.gameId;
  }

  bool _contains(HubDashboardSnapshot snapshot, String? gameId) {
    if (gameId == null) return false;
    return snapshot.games.any((game) => game.game.gameId == gameId);
  }

  AveluneHomeStatus _status(HubDashboardSnapshot snapshot) {
    switch (snapshot.status) {
      case HubDashboardStatus.idle:
      case HubDashboardStatus.loading:
        return AveluneHomeStatus.loading;
      case HubDashboardStatus.installing:
        return AveluneHomeStatus.importing;
      case HubDashboardStatus.error:
        return AveluneHomeStatus.error;
      case HubDashboardStatus.ready:
        return snapshot.games.isEmpty
            ? AveluneHomeStatus.empty
            : AveluneHomeStatus.ready;
    }
  }

  String? _nonEmpty(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
