import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';
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

typedef LocalGameIdGenerator = String Function();

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
    this.errorCode,
    this.technicalErrorDetails,
    this.diagnosticLogPath,
    this.gameplayReadinessReport,
  });

  final GamePackageExportStatus status;
  final GamePackageExportDraft draft;
  final GamePackageExportArtifact? artifact;
  final GamePackageInstallRequest? installRequest;
  final String? safeErrorMessage;
  final String? errorCode;
  final String? technicalErrorDetails;
  final String? diagnosticLogPath;
  final NarrativeProjectValidationReport? gameplayReadinessReport;

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
    String? errorCode,
    String? technicalErrorDetails,
    String? diagnosticLogPath,
    NarrativeProjectValidationReport? gameplayReadinessReport,
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
        errorCode: clearError ? null : errorCode ?? this.errorCode,
        technicalErrorDetails: clearError
            ? null
            : technicalErrorDetails ?? this.technicalErrorDetails,
        diagnosticLogPath:
            clearError ? null : diagnosticLogPath ?? this.diagnosticLogPath,
        gameplayReadinessReport: clearError
            ? null
            : gameplayReadinessReport ?? this.gameplayReadinessReport,
      );
}

final class GamePackageExportController extends ChangeNotifier {
  GamePackageExportController({
    required this.projectRoot,
    required this.projectName,
    required this.profileStore,
    this.exportService = const GamePackageExportService(),
    this.installRequestPublisher,
    this.diagnosticLogFile,
    LocalGameIdGenerator? localGameIdGenerator,
  })  : _localGameId = (localGameIdGenerator ?? _generateLocalGameId).call(),
        _snapshot = GamePackageExportSnapshot(
          status: GamePackageExportStatus.idle,
          draft: GamePackageExportDraft(title: projectName),
        );

  final Directory projectRoot;
  final String projectName;
  final GamePackageExportProfileStore profileStore;
  final GamePackageExportService exportService;
  final HubInstallRequestPublisher? installRequestPublisher;
  final File? diagnosticLogFile;
  final String _localGameId;

  GamePackageExportSnapshot _snapshot;
  bool _disposed = false;

  GamePackageExportSnapshot get snapshot => _snapshot;
  bool get canInstallInHub => installRequestPublisher != null;

  GamePackageExportProfile quickProfile({String? title}) {
    final draft = _snapshot.draft;
    final resolvedTitle = title?.trim().isNotEmpty ?? false
        ? title!.trim()
        : draft.title.trim().isNotEmpty
            ? draft.title.trim()
            : projectName.trim();
    final gameId =
        draft.gameId.trim().isEmpty ? _localGameId : draft.gameId.trim();
    final authorName = draft.authorName.trim().isEmpty
        ? 'Projet local'
        : draft.authorName.trim();
    final version =
        draft.gameVersion.trim().isEmpty ? '0.1.0' : draft.gameVersion.trim();
    final defaultLocale =
        draft.defaultLocale.trim().isEmpty ? 'fr' : draft.defaultLocale.trim();
    final supportedLocales = GamePackageExportDraft._csv(
      draft.supportedLocales,
    );

    return GamePackageExportProfile(
      gameId: gameId,
      gameVersion: version,
      title: resolvedTitle,
      authorName: authorName,
      defaultLocale: defaultLocale,
      supportedLocales: supportedLocales.isEmpty
          ? <String>[defaultLocale]
          : supportedLocales.contains(defaultLocale)
              ? supportedLocales
              : <String>[defaultLocale, ...supportedLocales],
    );
  }

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
    } on Object catch (error, stackTrace) {
      await _publishUnexpectedError(
        operation: 'initialisation',
        userMessage:
            'Les métadonnées de publication ne peuvent pas être ouvertes.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> exportDraft(
    GamePackageExportDraft draft,
    File outputFile,
  ) async {
    try {
      await export(profile: draft.toProfile(), outputFile: outputFile);
    } on GamePackageExportException catch (error, stackTrace) {
      await _publishExportError(
        operation: 'export',
        error: error,
        stackTrace: stackTrace,
        destinationPath: outputFile.path,
      );
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
    } on GamePackageExportException catch (error, stackTrace) {
      await _publishExportError(
        operation: 'export',
        error: error,
        stackTrace: stackTrace,
        destinationPath: outputFile.path,
      );
    } on Object catch (error, stackTrace) {
      await _publishUnexpectedError(
        operation: 'export',
        userMessage: 'Le package ne peut pas être exporté pour le moment.',
        error: error,
        stackTrace: stackTrace,
        destinationPath: outputFile.path,
      );
    }
  }

  Future<void> installInHub(GamePackageExportProfile profile) async {
    final publisher = installRequestPublisher;
    if (publisher == null) {
      await _publishUnexpectedError(
        operation: 'installation',
        userMessage: 'L’installation directe dans le Hub n’est pas disponible.',
        error: StateError('HubInstallRequestPublisher is not configured.'),
        stackTrace: StackTrace.current,
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
    } on GamePackageExportException catch (error, stackTrace) {
      await _publishExportError(
        operation: 'installation',
        error: error,
        stackTrace: stackTrace,
      );
    } on Object catch (error, stackTrace) {
      await _publishUnexpectedError(
        operation: 'installation',
        userMessage:
            'Le jeu ne peut pas être transmis à PokeMap Hub pour le moment.',
        error: error,
        stackTrace: stackTrace,
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

  void _publishError({
    required String message,
    String? errorCode,
    String? technicalErrorDetails,
    String? diagnosticLogPath,
    NarrativeProjectValidationReport? gameplayReadinessReport,
  }) {
    _publish(
      _snapshot.copyWith(
        status: GamePackageExportStatus.error,
        safeErrorMessage: message,
        errorCode: errorCode,
        technicalErrorDetails: technicalErrorDetails,
        diagnosticLogPath: diagnosticLogPath,
        gameplayReadinessReport: gameplayReadinessReport,
      ),
    );
  }

  Future<void> _publishExportError({
    required String operation,
    required GamePackageExportException error,
    required StackTrace stackTrace,
    String? destinationPath,
  }) async {
    final details = _technicalDetails(
      operation: operation,
      code: error.code,
      path: error.path ?? destinationPath,
      cause: error.cause ?? error,
      stackTrace: stackTrace,
    );
    final logPath = await _appendDiagnostic(
      operation: operation,
      code: error.code,
      path: error.path ?? destinationPath,
      cause: error.cause ?? error,
      stackTrace: stackTrace,
    );
    _publishError(
      message: _safeMessage(error),
      errorCode: error.code,
      technicalErrorDetails: details,
      diagnosticLogPath: logPath,
      gameplayReadinessReport: error.gameplayReadinessReport,
    );
  }

  Future<void> _publishUnexpectedError({
    required String operation,
    required String userMessage,
    required Object error,
    required StackTrace stackTrace,
    String? destinationPath,
  }) async {
    const code = 'unexpectedExportError';
    final details = _technicalDetails(
      operation: operation,
      code: code,
      path: destinationPath,
      cause: error,
      stackTrace: stackTrace,
    );
    final logPath = await _appendDiagnostic(
      operation: operation,
      code: code,
      path: destinationPath,
      cause: error,
      stackTrace: stackTrace,
    );
    _publishError(
      message: userMessage,
      errorCode: code,
      technicalErrorDetails: details,
      diagnosticLogPath: logPath,
    );
  }

  Future<String?> _appendDiagnostic({
    required String operation,
    required String code,
    required Object cause,
    required StackTrace stackTrace,
    String? path,
  }) async {
    final logFile = diagnosticLogFile;
    if (logFile == null) return null;
    try {
      await logFile.parent.create(recursive: true);
      final sink = logFile.openWrite(mode: FileMode.append);
      sink.writeln(
        jsonEncode(<String, Object?>{
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'feature': 'game-export',
          'operation': operation,
          'code': code,
          if (path != null) 'path': path,
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
    required String operation,
    required String code,
    required Object cause,
    required StackTrace stackTrace,
    String? path,
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
      if (path != null) 'Chemin : $path',
      'Cause système : $cause',
      if (stackLines.isNotEmpty) 'Pile :\n$stackLines',
    ].join('\n');
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
          'Le fichier « ${error.path ?? 'inconnu'} » contient une valeur qui '
              'ressemble à un secret ou à un identifiant privé. Retirez cette '
              'valeur du projet joueur avant de réessayer.',
        'referenceEscapesRoot' =>
          'Le fichier « ${error.path ?? 'inconnu'} » contient une référence '
              'absolue, distante ou utilisant « .. ». Remplacez-la par un '
              'chemin relatif vers un fichier présent dans le projet.',
        'invalidPackagePath' =>
          'Le chemin « ${error.path ?? 'inconnu'} » n’est pas compatible avec '
              'un package multiplateforme. Renommez le fichier sans caractère '
              'réservé et réessayez.',
        'projectionPathCollision' =>
          'Deux fichiers du projet produisent le même chemin '
              '« ${error.path ?? 'inconnu'} » après normalisation. Renommez '
              'l’un des deux fichiers.',
        'dialogueCompilationFailed' =>
          'Un dialogue ne peut pas être compilé pour le lecteur.',
        'missingProjectFile' => _missingProjectFileMessage(error.path),
        'invalidBrandingAsset' =>
          'Le fichier de branding « ${error.path ?? 'inconnu'} » utilise un '
              'format non pris en charge. Utilisez une image PNG, JPG, JPEG '
              'ou WebP.',
        'invalidTitleMusic' =>
          'La musique de titre « ${error.path ?? 'inconnue'} » doit être un '
              'fichier audio existant : OGG, WAV, MP3, FLAC ou M4A.',
        'invalidLegalText' =>
          'Le fichier « ${error.path ?? 'inconnu'} » doit être un texte UTF-8 '
              'valide.',
        'manifestTooLarge' =>
          'L’inventaire des fichiers du jeu dépasse la limite de 4 Mio du '
              'format .pokemapgame v1. Retirez les fichiers runtime inutilisés '
              'ou regroupez les données avant de réessayer.',
        'exportWriteFailed' =>
          'Le package a bien été construit et certifié, mais PokeMap ne peut '
              'pas l’écrire dans « ${error.path ?? 'l’emplacement choisi'} ». '
              'Vérifiez les autorisations, l’espace disque et que la '
              'destination n’est pas un dossier, puis réessayez. Le détail '
              'système est disponible ci-dessous.',
        _ => error.message,
      };

  static String _missingProjectFileMessage(String? path) {
    final label = path?.trim();
    final displayedPath =
        label == null || label.isEmpty ? 'demandé' : '« $label »';
    return 'Le fichier $displayedPath est introuvable dans le dossier du '
        'projet. Ajoutez ce fichier, choisissez un chemin existant, ou laissez '
        'ce champ vide s’il est optionnel.';
  }

  static String _generateLocalGameId() {
    final random = Random.secure();
    final token = List<int>.generate(
      16,
      (_) => random.nextInt(256),
      growable: false,
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return 'games.local.g$token';
  }

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
