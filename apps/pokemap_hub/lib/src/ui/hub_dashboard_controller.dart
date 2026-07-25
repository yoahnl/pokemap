import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:map_player_ui/map_player_ui.dart';

import '../install/editor_export_install_inbox.dart';
import '../install/game_installation_diagnostic.dart';
import '../library/game_library.dart';
import '../library/game_library_store.dart';
import '../saves/hub_save_store.dart';
import '../session/installed_game_launch_resolver.dart';
import 'preferences/hub_preferences_store.dart';

enum HubDashboardStatus { idle, loading, ready, installing, error }

enum HubSection { home, library, preferences, diagnostics }

enum HubDiagnosticSeverity { information, warning, error }

final class HubDiagnostic {
  const HubDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    required this.recommendation,
    this.gameId,
    this.technicalDetails,
    this.logPath,
  });

  final String code;
  final HubDiagnosticSeverity severity;
  final String message;
  final String recommendation;
  final String? gameId;
  final String? technicalDetails;
  final String? logPath;
}

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

final class HubDashboardController extends ChangeNotifier {
  HubDashboardController({
    required this.libraryStore,
    required this.activityReader,
    this.importer,
    this.editorExportConsumer,
    this.preferencesStore,
    this.storageReader,
    this.diagnosticLogFile,
  });

  final GameLibraryStore libraryStore;
  final HubGameActivityReader activityReader;
  final HubPackageImporter? importer;
  final HubEditorExportConsumer? editorExportConsumer;
  final HubPreferencesStore? preferencesStore;
  final HubStorageReader? storageReader;
  final File? diagnosticLogFile;

  HubDashboardSnapshot _snapshot = HubDashboardSnapshot.initial();
  GameInstallCancellationToken? _installCancellation;
  Future<void> _preferenceWrites = Future<void>.value();
  bool _disposed = false;

  HubDashboardSnapshot get snapshot => _snapshot;

  Future<void> initialize() async {
    _publish(_snapshot.copyWith(status: HubDashboardStatus.loading));
    try {
      final preferences = await preferencesStore?.load();
      final exportDiagnostics = await _consumeEditorExports();
      await _reload(
        preferences: preferences?.preferences,
      );
      final preferenceDiagnostics = <HubDiagnostic>[
        if (preferences?.currentCorrupt ?? false)
          const HubDiagnostic(
            code: 'preferences.currentCorrupt',
            severity: HubDiagnosticSeverity.warning,
            message: 'Les préférences principales étaient illisibles.',
            recommendation: 'Les derniers réglages valides ont été restaurés.',
          ),
        if (preferences?.backupCorrupt ?? false)
          const HubDiagnostic(
            code: 'preferences.backupCorrupt',
            severity: HubDiagnosticSeverity.warning,
            message: 'La sauvegarde des préférences était illisible.',
            recommendation: 'Vérifiez les réglages avant de jouer.',
          ),
      ];
      if (preferenceDiagnostics.isNotEmpty || exportDiagnostics.isNotEmpty) {
        _publish(
          _snapshot.copyWith(
            diagnostics: <HubDiagnostic>[
              ..._snapshot.diagnostics,
              ...exportDiagnostics,
              ...preferenceDiagnostics,
            ],
          ),
        );
      }
    } on Object {
      _publish(
        _snapshot.copyWith(
          status: HubDashboardStatus.error,
          safeErrorMessage:
              'Le Hub ne peut pas ouvrir la bibliothèque pour le moment.',
        ),
      );
    }
  }

  Future<void> refresh() => _reload();

  Future<List<HubDiagnostic>> _consumeEditorExports() async {
    final consume = editorExportConsumer;
    if (consume == null) return const <HubDiagnostic>[];
    try {
      final results = await consume();
      return <HubDiagnostic>[
        for (final result in results)
          if (result.status == EditorExportInstallStatus.failed)
            HubDiagnostic(
              code: 'editorExport.${result.code}',
              severity: HubDiagnosticSeverity.warning,
              message:
                  'Un jeu exporté depuis l’éditeur n’a pas pu être installé.',
              recommendation:
                  'Corrigez le package dans l’éditeur puis relancez l’export.',
            )
          else if (result.code == 'installedCleanupPending')
            const HubDiagnostic(
              code: 'editorExport.cleanupPending',
              severity: HubDiagnosticSeverity.information,
              message:
                  'Un jeu exporté a été installé, mais son transfert reste à nettoyer.',
              recommendation:
                  'Le Hub réessaiera de nettoyer son inbox au prochain démarrage.',
            ),
      ];
    } on Object {
      return const <HubDiagnostic>[
        HubDiagnostic(
          code: 'editorExport.inboxUnavailable',
          severity: HubDiagnosticSeverity.warning,
          message: 'Les exports en attente ne peuvent pas être consultés.',
          recommendation:
              'La bibliothèque existante reste disponible. Réessayez plus tard.',
        ),
      ];
    }
  }

  void selectSection(HubSection section) {
    _publish(
      _snapshot.copyWith(
        section: section,
        clearSelectedGame: true,
      ),
    );
  }

  void setQuery(String query) {
    _publish(_snapshot.copyWith(query: query));
  }

  void selectGame(String gameId) {
    if (_snapshot.games.every((view) => view.game.gameId != gameId)) return;
    _publish(_snapshot.copyWith(selectedGameId: gameId));
  }

  void closeGameDetails() {
    _publish(_snapshot.copyWith(clearSelectedGame: true));
  }

  Future<void> updatePreferences(PlayerPreferences preferences) {
    _publish(_snapshot.copyWith(preferences: preferences));
    _preferenceWrites = _preferenceWrites.then(
      (_) => _persistPreferences(preferences),
    );
    return _preferenceWrites;
  }

  Future<void> _persistPreferences(PlayerPreferences preferences) async {
    try {
      await preferencesStore?.save(preferences);
    } on Object {
      _publish(
        _snapshot.copyWith(
          diagnostics: <HubDiagnostic>[
            ..._snapshot.diagnostics.where(
              (diagnostic) => diagnostic.code != 'preferences.writeFailed',
            ),
            const HubDiagnostic(
              code: 'preferences.writeFailed',
              severity: HubDiagnosticSeverity.error,
              message: 'Les préférences n’ont pas pu être enregistrées.',
              recommendation: 'Vérifiez l’espace disque puis réessayez.',
            ),
          ],
        ),
      );
    }
  }

  Future<void> importPackage(File package) async {
    final import = importer;
    if (import == null || _installCancellation != null) return;
    final cancellation = GameInstallCancellationToken();
    _installCancellation = cancellation;
    _publish(
      _snapshot.copyWith(
        status: HubDashboardStatus.installing,
        clearSafeError: true,
      ),
    );
    try {
      await import(
        package,
        cancellation,
        (progress) {
          if (_disposed) return;
          _publish(
            _snapshot.copyWith(
              status: HubDashboardStatus.installing,
              installProgress: progress,
            ),
          );
        },
      );
      await _reload();
    } on GameInstallationException catch (error, stackTrace) {
      if (error.diagnostic.code == GameInstallationErrorCode.cancelled) {
        await _reload();
        return;
      }
      final effectiveStackTrace = error.stackTrace ?? stackTrace;
      final details = _technicalDetails(
        code: 'install.${error.diagnostic.code.name}',
        operation: 'import',
        packagePath: package.path,
        cause: error.cause ?? error,
        stackTrace: effectiveStackTrace,
      );
      final logPath = await _appendDiagnostic(
        code: 'install.${error.diagnostic.code.name}',
        operation: 'import',
        packagePath: package.path,
        cause: error.cause ?? error,
        stackTrace: effectiveStackTrace,
      );
      _publish(
        _snapshot.copyWith(
          status: HubDashboardStatus.error,
          clearInstallProgress: true,
          safeErrorMessage: _installMessage(error.diagnostic),
          diagnostics: <HubDiagnostic>[
            ..._snapshot.diagnostics,
            HubDiagnostic(
              code: 'install.${error.diagnostic.code.name}',
              severity: HubDiagnosticSeverity.error,
              message: _installMessage(error.diagnostic),
              recommendation: error.diagnostic.repairSuggested
                  ? 'Utilisez Réparer depuis la fiche du jeu.'
                  : 'Le package installé précédemment reste disponible.',
              gameId: error.diagnostic.gameId,
              technicalDetails: details,
              logPath: logPath,
            ),
          ],
        ),
      );
    } on Object catch (error, stackTrace) {
      const message = 'Le package n’a pas pu être installé.';
      final details = _technicalDetails(
        code: 'install.unexpected',
        operation: 'import',
        packagePath: package.path,
        cause: error,
        stackTrace: stackTrace,
      );
      final logPath = await _appendDiagnostic(
        code: 'install.unexpected',
        operation: 'import',
        packagePath: package.path,
        cause: error,
        stackTrace: stackTrace,
      );
      _publish(
        _snapshot.copyWith(
          status: HubDashboardStatus.error,
          clearInstallProgress: true,
          safeErrorMessage: message,
          diagnostics: <HubDiagnostic>[
            ..._snapshot.diagnostics,
            HubDiagnostic(
              code: 'install.unexpected',
              severity: HubDiagnosticSeverity.error,
              message: message,
              recommendation:
                  'Le package installé précédemment reste disponible.',
              technicalDetails: details,
              logPath: logPath,
            ),
          ],
        ),
      );
    } finally {
      _installCancellation = null;
    }
  }

  Future<void> reportImportPickerFailure({
    required String code,
    required String message,
    required String recommendation,
    required Object cause,
    required StackTrace stackTrace,
  }) async {
    const packagePath = '<aucun package sélectionné>';
    final details = _technicalDetails(
      code: code,
      operation: 'pickPackage',
      packagePath: packagePath,
      cause: cause,
      stackTrace: stackTrace,
    );
    final logPath = await _appendDiagnostic(
      code: code,
      operation: 'pickPackage',
      packagePath: packagePath,
      cause: cause,
      stackTrace: stackTrace,
    );
    if (_disposed) return;
    _publish(
      _snapshot.copyWith(
        status: HubDashboardStatus.error,
        clearInstallProgress: true,
        safeErrorMessage: message,
        diagnostics: <HubDiagnostic>[
          ..._snapshot.diagnostics.where(
            (diagnostic) => diagnostic.code != code,
          ),
          HubDiagnostic(
            code: code,
            severity: HubDiagnosticSeverity.error,
            message: message,
            recommendation: recommendation,
            technicalDetails: details,
            logPath: logPath,
          ),
        ],
      ),
    );
  }

  void cancelImport() => _installCancellation?.cancel();

  Future<String?> _appendDiagnostic({
    required String code,
    required String operation,
    required String packagePath,
    required Object cause,
    required StackTrace stackTrace,
  }) async {
    final logFile = diagnosticLogFile;
    if (logFile == null) return null;
    try {
      await logFile.parent.create(recursive: true);
      final sink = logFile.openWrite(mode: FileMode.append);
      sink.writeln(
        jsonEncode(<String, Object?>{
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'feature': 'hub-package-import',
          'operation': operation,
          'code': code,
          'packagePath': packagePath,
          'cause': cause.toString(),
          'stackTrace': stackTrace.toString(),
        }),
      );
      await sink.flush();
      await sink.close();
      return logFile.path;
    } on Object {
      return null;
    }
  }

  static String _technicalDetails({
    required String code,
    required String operation,
    required String packagePath,
    required Object cause,
    required StackTrace stackTrace,
  }) {
    final stackLines = stackTrace
        .toString()
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .take(12)
        .join('\n');
    return <String>[
      'Code : $code',
      'Opération : $operation',
      'Package : $packagePath',
      'Cause système : $cause',
      if (stackLines.isNotEmpty) 'Pile :\n$stackLines',
    ].join('\n');
  }

  Future<void> _reload({
    PlayerPreferences? preferences,
  }) async {
    final read = await libraryStore.load();
    final storageRead = await _readStorage();
    final views = await Future.wait(
      read.library.games.map((game) async {
        try {
          return HubGameView(
            game: game,
            activity: await activityReader(game),
          );
        } on Object {
          return HubGameView(
            game: game,
            activity: HubGameActivity(
              installationHealthy: false,
              diagnostic: HubDiagnostic(
                code: 'game.activityUnavailable',
                severity: HubDiagnosticSeverity.warning,
                message: 'Les informations de ${game.title} sont incomplètes.',
                recommendation: 'Vérifiez ou réparez l’installation.',
                gameId: game.gameId,
              ),
            ),
          );
        }
      }),
    );
    views.sort(_compareRecent);
    final diagnostics = <HubDiagnostic>[
      for (final diagnostic in read.diagnostics)
        HubDiagnostic(
          code: 'library.${diagnostic.code.name}',
          severity: HubDiagnosticSeverity.warning,
          message: 'La bibliothèque principale a dû être récupérée.',
          recommendation: 'Vérifiez les jeux installés.',
        ),
      for (final view in views)
        if (view.activity.diagnostic case final diagnostic?) diagnostic,
      if (storageRead.diagnostic case final diagnostic?) diagnostic,
    ];
    final selected = _snapshot.selectedGameId;
    _publish(
      _snapshot.copyWith(
        status: HubDashboardStatus.ready,
        library: read.library,
        games: views,
        selectedGameId: selected != null &&
                views.any((view) => view.game.gameId == selected)
            ? selected
            : null,
        clearSelectedGame: selected != null &&
            views.every((view) => view.game.gameId != selected),
        clearInstallProgress: true,
        clearSafeError: true,
        diagnostics: diagnostics,
        preferences: preferences,
        storage: storageRead.snapshot,
      ),
    );
  }

  Future<
      ({
        HubStorageSnapshot snapshot,
        HubDiagnostic? diagnostic,
      })> _readStorage() async {
    try {
      return (
        snapshot: await (storageReader?.call() ??
            HubDirectoryStorageReader(
              supportRoot: libraryStore.supportRoot,
            ).call()),
        diagnostic: null,
      );
    } on Object {
      return (
        snapshot: _snapshot.storage,
        diagnostic: const HubDiagnostic(
          code: 'storage.measurementUnavailable',
          severity: HubDiagnosticSeverity.warning,
          message: 'L’espace disque ne peut pas être mesuré.',
          recommendation: 'Vérifiez les autorisations du dossier PokeMap.',
        ),
      );
    }
  }

  int _compareRecent(HubGameView left, HubGameView right) {
    final leftDate = left.activity.lastSaveAt;
    final rightDate = right.activity.lastSaveAt;
    if (leftDate != null || rightDate != null) {
      if (leftDate == null) return 1;
      if (rightDate == null) return -1;
      final byDate = rightDate.compareTo(leftDate);
      if (byDate != 0) return byDate;
    }
    return left.game.title.toLowerCase().compareTo(
          right.game.title.toLowerCase(),
        );
  }

  String _installMessage(GameInstallationDiagnostic diagnostic) =>
      switch (diagnostic.code) {
        GameInstallationErrorCode.cancelled =>
          'L’installation a été annulée sans modifier le jeu actuel.',
        GameInstallationErrorCode.incompatible =>
          'Ce jeu n’est pas compatible avec cette version du Hub.',
        GameInstallationErrorCode.insufficientDisk =>
          'L’espace disque est insuffisant pour installer ce jeu.',
        GameInstallationErrorCode.integrityFailed ||
        GameInstallationErrorCode.sourceChanged =>
          'Le package est incomplet ou a été modifié.',
        _ => 'L’installation n’a pas pu être terminée.',
      };

  void _publish(HubDashboardSnapshot snapshot) {
    if (_disposed) return;
    _snapshot = snapshot;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _installCancellation?.cancel();
    super.dispose();
  }
}

/// Reads save activity and branding only after the installed release verifies.
final class InstalledHubGameActivityReader {
  const InstalledHubGameActivityReader({
    required this.supportRoot,
    required this.launchResolver,
  });

  final Directory supportRoot;
  final InstalledGameLaunchResolver launchResolver;

  Future<HubGameActivity> call(InstalledGame game) async {
    try {
      final launch = await launchResolver.resolve(game);
      final save = await HubSaveStore(
        supportRoot: supportRoot,
        identity: launch.identity,
      ).findContinue();
      Future<String?> resolve(String? path) async {
        if (path == null) return null;
        try {
          return (await launch.assets.resolveFile(path)).path;
        } on Object {
          return null;
        }
      }

      final branding = launch.manifest.branding;
      return HubGameActivity(
        canContinue: save?.canContinue ?? false,
        lastSaveAt: save?.envelope?.updatedAt,
        playTimeSeconds: save?.envelope?.playTimeSeconds ?? 0,
        iconPath: await resolve(branding?.icon),
        coverPath: await resolve(branding?.cover),
        heroPath: await resolve(branding?.hero),
      );
    } on InstalledGameLaunchException catch (error) {
      return HubGameActivity(
        installationHealthy: false,
        diagnostic: HubDiagnostic(
          code: 'launch.${error.code.name}',
          severity: HubDiagnosticSeverity.error,
          message: '${game.title} ne peut pas être lancé.',
          recommendation: 'Réparez l’installation avant de jouer.',
          gameId: game.gameId,
        ),
      );
    }
  }
}

/// Bounded, symlink-safe measurement of Hub-owned application data.
final class HubDirectoryStorageReader {
  const HubDirectoryStorageReader({
    required this.supportRoot,
    this.maxEntries = 100000,
  });

  final Directory supportRoot;
  final int maxEntries;

  Future<HubStorageSnapshot> call() async {
    final type = await FileSystemEntity.type(
      supportRoot.path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.notFound) {
      return const HubStorageSnapshot();
    }
    if (type != FileSystemEntityType.directory) {
      throw const FileSystemException('Unsafe Hub storage root.');
    }
    var entries = 0;
    var bytes = 0;
    await for (final entity
        in supportRoot.list(recursive: true, followLinks: false)) {
      if (++entries > maxEntries) break;
      if (entity is! File) continue;
      final entityType = await FileSystemEntity.type(
        entity.path,
        followLinks: false,
      );
      if (entityType != FileSystemEntityType.file) continue;
      bytes += await entity.length();
    }
    return HubStorageSnapshot(usedBytes: bytes);
  }
}
