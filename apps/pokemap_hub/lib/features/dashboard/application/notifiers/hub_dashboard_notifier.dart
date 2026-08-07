import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_player_ui/map_player_ui.dart';

import 'package:pokemap_hub/core/diagnostics/hub_diagnostic.dart';
import 'package:pokemap_hub/features/dashboard/application/notifiers/hub_dashboard_state.dart';
import 'package:pokemap_hub/features/dashboard/application/services/hub_diagnostic_log_writer.dart';
import 'package:pokemap_hub/features/dashboard/application/services/hub_directory_storage_reader.dart';
import 'package:pokemap_hub/features/installation/data/repositories/editor_export_install_inbox.dart';
import 'package:pokemap_hub/features/installation/domain/entities/game_installation_diagnostic.dart';
import 'package:pokemap_hub/features/library/domain/repositories/game_library_repository_interface.dart';
import 'package:pokemap_hub/features/preferences/domain/repositories/player_preferences_repository_interface.dart';
import 'package:pokemap_hub/app/di/dashboard_dependencies_provider.dart';

/// Orchestrates the Hub dashboard.
///
/// The state is synchronous but every dependency hangs off the async support
/// root, so they are resolved once by [_wire] on the first async entry point
/// rather than in `build()`. `build()` returns the same
/// [HubDashboardSnapshot.initial] the ChangeNotifier version started from, so
/// the UI observes an identical sequence of states.
final class HubDashboardNotifier extends Notifier<HubDashboardSnapshot> {
  late GameLibraryRepositoryInterface libraryStore;
  late HubGameActivityReader activityReader;
  HubPackageImporter? importer;
  HubEditorExportConsumer? editorExportConsumer;
  PlayerPreferencesRepositoryInterface? preferencesStore;
  HubStorageReader? storageReader;
  File? diagnosticLogFile;

  bool _wired = false;

  @override
  HubDashboardSnapshot build() {
    ref.onDispose(() {
      _disposed = true;
      _installCancellation?.cancel();
    });
    return HubDashboardSnapshot.initial();
  }

  /// Resolves the dependency bundle exactly once.
  ///
  /// Called at the head of every public async entry point so no method can run
  /// against a half-built notifier, whatever order the UI calls them in.
  Future<void> _wire() async {
    if (_wired) return;
    final deps = await ref.read(hubDashboardDependenciesProvider.future);
    libraryStore = deps.libraryStore;
    activityReader = deps.activityReader;
    importer = deps.importer;
    editorExportConsumer = deps.editorExportConsumer;
    preferencesStore = deps.preferencesStore;
    storageReader = deps.storageReader;
    diagnosticLogFile = deps.diagnosticLogFile;
    _wired = true;
  }

  HubDiagnosticLogWriter get _diagnosticLog =>
      HubDiagnosticLogWriter(logFile: diagnosticLogFile);

  GameInstallCancellationToken? _installCancellation;
  Future<void> _preferenceWrites = Future<void>.value();
  bool _disposed = false;

  HubDashboardSnapshot get snapshot => state;

  Future<void> initialize() async {
    await _wire();
    _publish(state.copyWith(status: HubDashboardStatus.loading));
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
          state.copyWith(
            diagnostics: <HubDiagnostic>[
              ...state.diagnostics,
              ...exportDiagnostics,
              ...preferenceDiagnostics,
            ],
          ),
        );
      }
    } on Object {
      _publish(
        state.copyWith(
          status: HubDashboardStatus.error,
          safeErrorMessage:
              'Le Hub ne peut pas ouvrir la bibliothèque pour le moment.',
        ),
      );
    }
  }

  Future<void> refresh() async {
    await _wire();
    await _reload();
  }

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
      state.copyWith(
        section: section,
        clearSelectedGame: true,
      ),
    );
  }

  void setQuery(String query) {
    _publish(state.copyWith(query: query));
  }

  void selectGame(String gameId) {
    if (state.games.every((view) => view.game.gameId != gameId)) return;
    _publish(state.copyWith(selectedGameId: gameId));
  }

  void closeGameDetails() {
    _publish(state.copyWith(clearSelectedGame: true));
  }

  Future<void> updatePreferences(PlayerPreferences preferences) {
    _publish(state.copyWith(preferences: preferences));
    _preferenceWrites = _preferenceWrites.then(
      (_) => _persistPreferences(preferences),
    );
    return _preferenceWrites;
  }

  Future<void> _persistPreferences(PlayerPreferences preferences) async {
    await _wire();
    try {
      await preferencesStore?.save(preferences);
    } on Object {
      _publish(
        state.copyWith(
          diagnostics: <HubDiagnostic>[
            ...state.diagnostics.where(
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
    await _wire();
    final import = importer;
    if (import == null || _installCancellation != null) return;
    final cancellation = GameInstallCancellationToken();
    _installCancellation = cancellation;
    _publish(
      state.copyWith(
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
            state.copyWith(
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
      final details = HubDiagnosticLogWriter.technicalDetails(
        code: 'install.${error.diagnostic.code.name}',
        operation: 'import',
        packagePath: package.path,
        cause: error.cause ?? error,
        stackTrace: effectiveStackTrace,
      );
      final logPath = await _diagnosticLog.append(
        code: 'install.${error.diagnostic.code.name}',
        operation: 'import',
        packagePath: package.path,
        cause: error.cause ?? error,
        stackTrace: effectiveStackTrace,
      );
      _publish(
        state.copyWith(
          status: HubDashboardStatus.error,
          clearInstallProgress: true,
          safeErrorMessage: _installMessage(error.diagnostic),
          diagnostics: <HubDiagnostic>[
            ...state.diagnostics,
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
      final details = HubDiagnosticLogWriter.technicalDetails(
        code: 'install.unexpected',
        operation: 'import',
        packagePath: package.path,
        cause: error,
        stackTrace: stackTrace,
      );
      final logPath = await _diagnosticLog.append(
        code: 'install.unexpected',
        operation: 'import',
        packagePath: package.path,
        cause: error,
        stackTrace: stackTrace,
      );
      _publish(
        state.copyWith(
          status: HubDashboardStatus.error,
          clearInstallProgress: true,
          safeErrorMessage: message,
          diagnostics: <HubDiagnostic>[
            ...state.diagnostics,
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
    await _wire();
    const packagePath = '<aucun package sélectionné>';
    final details = HubDiagnosticLogWriter.technicalDetails(
      code: code,
      operation: 'pickPackage',
      packagePath: packagePath,
      cause: cause,
      stackTrace: stackTrace,
    );
    final logPath = await _diagnosticLog.append(
      code: code,
      operation: 'pickPackage',
      packagePath: packagePath,
      cause: cause,
      stackTrace: stackTrace,
    );
    if (_disposed) return;
    _publish(
      state.copyWith(
        status: HubDashboardStatus.error,
        clearInstallProgress: true,
        safeErrorMessage: message,
        diagnostics: <HubDiagnostic>[
          ...state.diagnostics.where(
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
    final selected = state.selectedGameId;
    _publish(
      state.copyWith(
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
        snapshot: state.storage,
        diagnostic: const HubDiagnostic(
          code: 'storage.measurementUnavailable',
          severity: HubDiagnosticSeverity.warning,
          message: 'L’espace disque ne peut pas être mesuré.',
          recommendation:
              'Vérifiez les autorisations du dossier de données de l’application.',
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
    state = snapshot;
  }

}

final hubDashboardNotifierProvider =
    NotifierProvider<HubDashboardNotifier, HubDashboardSnapshot>(
  HubDashboardNotifier.new,
);
