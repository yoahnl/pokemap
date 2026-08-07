import 'dart:io';

import 'package:map_player_ui/map_player_ui.dart';

import 'package:pokemap_hub/core/diagnostics/hub_diagnostic.dart';
import 'package:pokemap_hub/features/installation/data/repositories/editor_export_install_inbox.dart';
import 'package:pokemap_hub/features/installation/domain/entities/game_installation_diagnostic.dart';
import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';

enum HubDashboardStatus { idle, loading, ready, installing, error }

enum HubSection { home, library, preferences, diagnostics }

final class HubStorageSnapshot {
  const HubStorageSnapshot({
    this.usedBytes = 0,
    this.availableBytes,
  });

  final int usedBytes;
  final int? availableBytes;
}

final class HubGameActivity {
  const HubGameActivity({
    this.canContinue = false,
    this.lastSaveAt,
    this.playTimeSeconds = 0,
    this.installationHealthy = true,
    this.updateAvailable = false,
    this.iconPath,
    this.coverPath,
    this.heroPath,
    this.diagnostic,
  });

  final bool canContinue;
  final DateTime? lastSaveAt;
  final int playTimeSeconds;
  final bool installationHealthy;
  final bool updateAvailable;
  final String? iconPath;
  final String? coverPath;
  final String? heroPath;
  final HubDiagnostic? diagnostic;
}

final class HubGameView {
  const HubGameView({
    required this.game,
    required this.activity,
  });

  final InstalledGame game;
  final HubGameActivity activity;
}

final class HubDashboardSnapshot {
  HubDashboardSnapshot({
    required this.status,
    required this.library,
    required List<HubGameView> games,
    this.query = '',
    this.section = HubSection.home,
    this.selectedGameId,
    this.installProgress,
    List<HubDiagnostic> diagnostics = const <HubDiagnostic>[],
    this.storage = const HubStorageSnapshot(),
    this.preferences = const PlayerPreferences(),
    this.safeErrorMessage,
  })  : games = List.unmodifiable(games),
        diagnostics = List.unmodifiable(diagnostics);

  factory HubDashboardSnapshot.initial() => HubDashboardSnapshot(
        status: HubDashboardStatus.idle,
        library: GameLibrary.empty(),
        games: const <HubGameView>[],
      );

  factory HubDashboardSnapshot.ready({
    required GameLibrary library,
    required List<HubGameView> games,
    String query = '',
    HubSection section = HubSection.home,
    String? selectedGameId,
    List<HubDiagnostic> diagnostics = const <HubDiagnostic>[],
    HubStorageSnapshot storage = const HubStorageSnapshot(),
    PlayerPreferences preferences = const PlayerPreferences(),
  }) =>
      HubDashboardSnapshot(
        status: HubDashboardStatus.ready,
        library: library,
        games: games,
        query: query,
        section: section,
        selectedGameId: selectedGameId,
        diagnostics: diagnostics,
        storage: storage,
        preferences: preferences,
      );

  final HubDashboardStatus status;
  final GameLibrary library;
  final List<HubGameView> games;
  final String query;
  final HubSection section;
  final String? selectedGameId;
  final GameInstallProgress? installProgress;
  final List<HubDiagnostic> diagnostics;
  final HubStorageSnapshot storage;
  final PlayerPreferences preferences;
  final String? safeErrorMessage;

  List<HubGameView> get visibleGames {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return games;
    return List<HubGameView>.unmodifiable(
      games.where((view) {
        final game = view.game;
        return game.title.toLowerCase().contains(normalized) ||
            game.authorName.toLowerCase().contains(normalized);
      }),
    );
  }

  HubGameView? get selectedGame {
    final selected = selectedGameId;
    if (selected == null) return null;
    for (final game in games) {
      if (game.game.gameId == selected) return game;
    }
    return null;
  }

  HubDashboardSnapshot copyWith({
    HubDashboardStatus? status,
    GameLibrary? library,
    List<HubGameView>? games,
    String? query,
    HubSection? section,
    String? selectedGameId,
    bool clearSelectedGame = false,
    GameInstallProgress? installProgress,
    bool clearInstallProgress = false,
    List<HubDiagnostic>? diagnostics,
    HubStorageSnapshot? storage,
    PlayerPreferences? preferences,
    String? safeErrorMessage,
    bool clearSafeError = false,
  }) =>
      HubDashboardSnapshot(
        status: status ?? this.status,
        library: library ?? this.library,
        games: games ?? this.games,
        query: query ?? this.query,
        section: section ?? this.section,
        selectedGameId:
            clearSelectedGame ? null : selectedGameId ?? this.selectedGameId,
        installProgress: clearInstallProgress
            ? null
            : installProgress ?? this.installProgress,
        diagnostics: diagnostics ?? this.diagnostics,
        storage: storage ?? this.storage,
        preferences: preferences ?? this.preferences,
        safeErrorMessage:
            clearSafeError ? null : safeErrorMessage ?? this.safeErrorMessage,
      );
}

typedef HubGameActivityReader = Future<HubGameActivity> Function(
  InstalledGame game,
);
typedef HubPackageImporter = Future<void> Function(
  File package,
  GameInstallCancellationToken cancellationToken,
  GameInstallProgressListener onProgress,
);
typedef HubStorageReader = Future<HubStorageSnapshot> Function();
typedef HubEditorExportConsumer = Future<List<EditorExportInstallResult>>
    Function();
