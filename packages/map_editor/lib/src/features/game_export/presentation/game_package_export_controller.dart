import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:map_distribution/map_distribution.dart';

import '../application/game_package_export_profile.dart';
import '../application/game_package_export_service.dart';
import '../infrastructure/game_package_export_profile_store.dart';
import '../infrastructure/hub_install_request_publisher.dart';

enum GamePackageExportStatus {
  idle,
  loading,
  ready,
  exporting,
  installing,
  succeeded,
  error,
}

final class GamePackageExportDraft {
  const GamePackageExportDraft({
    this.gameId = '',
    this.gameVersion = '0.1.0',
    required this.title,
    this.description = '',
    this.authorName = '',
    this.authorUrl = '',
    this.publisherName = '',
    this.publisherUrl = '',
    this.defaultLocale = 'fr',
    this.supportedLocales = 'fr',
    this.requiredCapabilities = '',
    this.iconPath = '',
    this.coverPath = '',
    this.heroPath = '',
    this.titleMusicPath = '',
    this.accentColor = '',
    this.layoutVariant = '',
    this.licensePath = '',
    this.creditsPath = '',
  });

  factory GamePackageExportDraft.fromProfile(
    GamePackageExportProfile profile,
  ) =>
      GamePackageExportDraft(
        gameId: profile.gameId,
        gameVersion: profile.gameVersion,
        title: profile.title,
        description: profile.description ?? '',
        authorName: profile.authorName,
        authorUrl: profile.authorUrl ?? '',
        publisherName: profile.publisherName ?? '',
        publisherUrl: profile.publisherUrl ?? '',
        defaultLocale: profile.defaultLocale,
        supportedLocales: profile.supportedLocales.join(', '),
        requiredCapabilities: profile.requiredCapabilities.join(', '),
        iconPath: profile.iconPath ?? '',
        coverPath: profile.coverPath ?? '',
        heroPath: profile.heroPath ?? '',
        titleMusicPath: profile.titleMusicPath ?? '',
        accentColor: profile.accentColor ?? '',
        layoutVariant: profile.layoutVariant ?? '',
        licensePath: profile.licensePath ?? '',
        creditsPath: profile.creditsPath ?? '',
      );

  final String gameId;
  final String gameVersion;
  final String title;
  final String description;
  final String authorName;
  final String authorUrl;
  final String publisherName;
  final String publisherUrl;
  final String defaultLocale;
  final String supportedLocales;
  final String requiredCapabilities;
  final String iconPath;
  final String coverPath;
  final String heroPath;
  final String titleMusicPath;
  final String accentColor;
  final String layoutVariant;
  final String licensePath;
  final String creditsPath;

  GamePackageExportProfile toProfile() => GamePackageExportProfile(
        gameId: gameId.trim(),
        gameVersion: gameVersion.trim(),
        title: title.trim(),
        description: _optional(description),
        authorName: authorName.trim(),
        authorUrl: _optional(authorUrl),
        publisherName: _optional(publisherName),
        publisherUrl: _optional(publisherUrl),
        defaultLocale: defaultLocale.trim(),
        supportedLocales: _csv(supportedLocales),
        requiredCapabilities: _csv(requiredCapabilities),
        iconPath: _optional(iconPath),
        coverPath: _optional(coverPath),
        heroPath: _optional(heroPath),
        titleMusicPath: _optional(titleMusicPath),
        accentColor: _optional(accentColor),
        layoutVariant: _optional(layoutVariant),
        licensePath: _optional(licensePath),
        creditsPath: _optional(creditsPath),
      );

  static String? _optional(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  static List<String> _csv(String value) => value
      .split(',')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

final class GamePackageExportSnapshot {
  const GamePackageExportSnapshot({
    required this.status,
    required this.draft,
    this.artifact,
    this.installRequest,
    this.safeErrorMessage,
  });

  final GamePackageExportStatus status;
  final GamePackageExportDraft draft;
  final GamePackageExportArtifact? artifact;
  final GamePackageInstallRequest? installRequest;
  final String? safeErrorMessage;

  bool get isBusy =>
      status == GamePackageExportStatus.loading ||
      status == GamePackageExportStatus.exporting ||
      status == GamePackageExportStatus.installing;

  GamePackageExportSnapshot copyWith({
    GamePackageExportStatus? status,
    GamePackageExportDraft? draft,
    GamePackageExportArtifact? artifact,
    bool clearArtifact = false,
    GamePackageInstallRequest? installRequest,
    bool clearInstallRequest = false,
    String? safeErrorMessage,
    bool clearError = false,
  }) =>
      GamePackageExportSnapshot(
        status: status ?? this.status,
        draft: draft ?? this.draft,
        artifact: clearArtifact ? null : artifact ?? this.artifact,
        installRequest:
            clearInstallRequest ? null : installRequest ?? this.installRequest,
        safeErrorMessage:
            clearError ? null : safeErrorMessage ?? this.safeErrorMessage,
      );
}

final class GamePackageExportController extends ChangeNotifier {
  GamePackageExportController({
    required this.projectRoot,
    required this.projectName,
    required this.profileStore,
    this.exportService = const GamePackageExportService(),
    this.installRequestPublisher,
  }) : _snapshot = GamePackageExportSnapshot(
          status: GamePackageExportStatus.idle,
          draft: GamePackageExportDraft(title: projectName),
        );

  final Directory projectRoot;
  final String projectName;
  final GamePackageExportProfileStore profileStore;
  final GamePackageExportService exportService;
  final HubInstallRequestPublisher? installRequestPublisher;

  GamePackageExportSnapshot _snapshot;
  bool _disposed = false;

  GamePackageExportSnapshot get snapshot => _snapshot;
  bool get canInstallInHub => installRequestPublisher != null;

  Future<void> initialize() async {
    if (_snapshot.status != GamePackageExportStatus.idle) return;
    _publish(_snapshot.copyWith(status: GamePackageExportStatus.loading));
    try {
      final profile = await profileStore.load();
      _publish(
        _snapshot.copyWith(
          status: GamePackageExportStatus.ready,
          draft: profile == null
              ? GamePackageExportDraft(title: projectName)
              : GamePackageExportDraft.fromProfile(profile),
          clearError: true,
        ),
      );
    } on Object {
      _publishError(
        'Les métadonnées de publication ne peuvent pas être ouvertes.',
      );
    }
  }

  Future<void> exportDraft(
    GamePackageExportDraft draft,
    File outputFile,
  ) async {
    try {
      await export(profile: draft.toProfile(), outputFile: outputFile);
    } on GamePackageExportException catch (error) {
      _publishError(_safeMessage(error));
    }
  }

  Future<void> export({
    required GamePackageExportProfile profile,
    required File outputFile,
  }) async {
    _publish(
      _snapshot.copyWith(
        status: GamePackageExportStatus.exporting,
        draft: GamePackageExportDraft.fromProfile(profile),
        clearArtifact: true,
        clearInstallRequest: true,
        clearError: true,
      ),
    );
    try {
      await profileStore.save(profile);
      final artifact = await exportService.exportToFile(
        projectRoot: projectRoot,
        profile: profile,
        outputFile: outputFile,
      );
      _publish(
        _snapshot.copyWith(
          status: GamePackageExportStatus.succeeded,
          artifact: artifact,
        ),
      );
    } on GamePackageExportException catch (error) {
      _publishError(_safeMessage(error));
    } on Object {
      _publishError('Le package ne peut pas être exporté pour le moment.');
    }
  }

  Future<void> installInHub(GamePackageExportProfile profile) async {
    final publisher = installRequestPublisher;
    if (publisher == null) {
      _publishError(
        'L’installation directe dans le Hub n’est pas disponible.',
      );
      return;
    }
    _publish(
      _snapshot.copyWith(
        status: GamePackageExportStatus.installing,
        draft: GamePackageExportDraft.fromProfile(profile),
        clearArtifact: true,
        clearInstallRequest: true,
        clearError: true,
      ),
    );
    try {
      await profileStore.save(profile);
      final artifact = await exportService.build(
        projectRoot: projectRoot,
        profile: profile,
      );
      final request = await publisher.publish(artifact.packageBytes);
      _publish(
        _snapshot.copyWith(
          status: GamePackageExportStatus.succeeded,
          artifact: artifact,
          installRequest: request,
        ),
      );
    } on GamePackageExportException catch (error) {
      _publishError(_safeMessage(error));
    } on Object {
      _publishError(
        'Le jeu ne peut pas être transmis à PokeMap Hub pour le moment.',
      );
    }
  }

  void clearError() {
    if (_snapshot.status != GamePackageExportStatus.error) return;
    _publish(
      _snapshot.copyWith(
        status: GamePackageExportStatus.ready,
        clearError: true,
      ),
    );
  }

  void _publishError(String message) {
    _publish(
      _snapshot.copyWith(
        status: GamePackageExportStatus.error,
        safeErrorMessage: message,
      ),
    );
  }

  String _safeMessage(GamePackageExportException error) => switch (error.code) {
        'invalidGameId' =>
          'Renseignez un identifiant stable, par exemple games.studio.auteur.jeu.',
        'invalidGameVersion' =>
          'La version du jeu doit respecter le format SemVer, par exemple 1.0.0.',
        'invalidAuthor' => 'Renseignez le nom de l’auteur ou du studio.',
        'invalidLocales' =>
          'La langue principale doit figurer dans les langues disponibles.',
        'probableSecret' =>
          'Un secret probable reste présent dans la projection joueur.',
        'dialogueCompilationFailed' =>
          'Un dialogue ne peut pas être compilé pour le lecteur.',
        _ => error.message,
      };

  void _publish(GamePackageExportSnapshot next) {
    if (_disposed) return;
    _snapshot = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
