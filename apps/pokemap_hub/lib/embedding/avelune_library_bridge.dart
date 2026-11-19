import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/core/config/avelune_host_compatibility.dart';
import 'package:pokemap_hub/embedding/install_progress_relay.dart';
import 'package:pokemap_hub/features/installation/application/use_cases/install_game_package_use_case.dart';
import 'package:pokemap_hub/features/installation/application/game_installation_message.dart';
import 'package:pokemap_hub/features/installation/data/repositories/installed_project_smoke.dart';
import 'package:pokemap_hub/features/saves/data/repositories/game_save_update_preparation.dart';
import 'package:pokemap_hub/platform/hub_platform_adapter_factory.dart';
import 'package:pokemap_hub/platform/path_provider_support_root_adapter.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

class AveluneLibraryBridge {
  AveluneLibraryBridge({
    MethodChannel? channel,
    Future<Directory> Function()? supportRootResolver,
    this._stopPlayer,
    this._onAppLanguageChanged,
    Iterable<String> Function()? systemLocales,
    InstalledGameVerifier? verifier,
  }) : _channel = channel ?? const MethodChannel('com.avelune.runtime/library'),
       _supportRootResolver =
           supportRootResolver ??
           const PathProviderSupportRootAdapter().resolve,
       _systemLocales = systemLocales ?? _readSystemLocales,
       _verifier = verifier ?? const InstalledGameVerifier();

  static final _supportedAppLanguages = List<String>.unmodifiable(
    PlayerLanguage.values
        .where((language) => language != PlayerLanguage.system)
        .map((language) => language.name),
  );

  final MethodChannel _channel;
  final Future<Directory> Function() _supportRootResolver;
  final Future<void> Function()? _stopPlayer;
  final Future<void> Function()? _onAppLanguageChanged;
  final Iterable<String> Function() _systemLocales;
  final InstalledGameVerifier _verifier;
  Future<void> _languageTail = Future<void>.value();
  Map<String, Object>? _lastReportedLanguage;
  Future<void>? _stopping;
  int _playerGeneration = 0;
  int get playerGeneration => _playerGeneration;

  final ValueNotifier<InstalledGame?> playing = ValueNotifier<InstalledGame?>(
    null,
  );

  late final Directory supportRoot;
  late final HubPreferencesStore preferencesStore;
  late final InstalledGameLaunchResolver launchResolver;
  late final GamePackageInstaller _installer;
  late final GameMaintenanceService _maintenance;
  late final GameLibraryStore _library;
  late final InstalledHubGameActivityReader _activity;

  Future<void>? _ready;

  void attach() {
    _channel.setMethodCallHandler(_handle);
    unawaited(_notifyReady());
  }

  Future<void> _notifyReady() async {
    try {
      await _channel.invokeMethod<void>('runtimeReady');
    } on MissingPluginException {
      return;
    }
  }

  void detach() {
    _channel.setMethodCallHandler(null);
    playing.dispose();
  }

  Future<void> requestExit() async {
    await _stopGame();
    await _channel.invokeMethod<void>('playerDidExit');
  }

  Future<void> refreshLanguagePreferences() =>
      _withLanguagePreferences(() async {
        _publishLanguage(await _readLanguage());
      });

  Future<void> _ensureReady() => _ready ??= _build();

  Future<void> _build() async {
    supportRoot = await _supportRootResolver();
    final hostCompatibility = aveluneHostCompatibility();
    final platform = createHubPlatformAdapter();

    _installer = GamePackageInstaller(
      supportRoot: supportRoot,
      inspector: GamePackageInspector(hostCompatibility: hostCompatibility),
      availableDiskBytes: platform.availableDiskBytes,
      loadSmoke: loadInstalledProjectSmoke,
      prepareSavesForUpdate: GameSaveUpdatePreparation(supportRoot: supportRoot)
          .call,
    );
    _maintenance = GameMaintenanceService(
      supportRoot: supportRoot,
      installer: _installer,
    );
    _library = GameLibraryStore(supportRoot: supportRoot);
    preferencesStore = HubPreferencesStore(supportRoot: supportRoot);
    launchResolver = InstalledGameLaunchResolver(
      supportRoot: supportRoot,
      hostCompatibility: hostCompatibility,
      verifier: _verifier,
    );
    _activity = InstalledHubGameActivityReader(
      supportRoot: supportRoot,
      launchResolver: InstalledGameLaunchResolver(
        supportRoot: supportRoot,
        hostCompatibility: hostCompatibility,
        verifier: _verifier,
        verificationDepth: InstalledGameVerificationDepth.structure,
      ),
      saveRepositoryFactory: (root, identity) =>
          HubSaveStore(supportRoot: root, identity: identity),
    );
  }

  String _argument(MethodCall call, String name) {
    final arguments = call.arguments;
    final value = arguments is Map ? arguments[name] : null;
    if (value is! String || value.trim().isEmpty) {
      throw PlatformException(
        code: 'invalidArguments',
        message: '${call.method} requires $name.',
      );
    }
    return value;
  }

  Future<dynamic> _handle(MethodCall call) async {
    switch (call.method) {
      case 'listGames':
        await _ensureReady();
        return _listGames();
      case 'installGame':
        final packagePath = _argument(call, 'packagePath');
        await _ensureReady();
        return _installGame(packagePath);
      case 'uninstallGame':
        final gameId = _argument(call, 'gameId');
        await _ensureReady();
        await _maintenance.uninstallGame(gameId);
        return _listGames();
      case 'playGame':
        final gameId = _argument(call, 'gameId');
        await _ensureReady();
        return _playGame(gameId);
      case 'stopGame':
        await _stopGame();
        return null;
      case 'getLanguagePreferences':
        return _withLanguagePreferences(() async {
          final language = await _readLanguage();
          _lastReportedLanguage = language;
          return language;
        });
      case 'setAppLanguage':
        return _setAppLanguage(_argument(call, 'appLanguage'));
      default:
        throw MissingPluginException('Unknown method: ${call.method}');
    }
  }

  Future<T> _withLanguagePreferences<T>(Future<T> Function() operation) {
    final result = _languageTail.then((_) async {
      await _ensureReady();
      try {
        return await operation();
      } on HubPreferencesStorageException catch (error) {
        throw PlatformException(
          code: 'preferencesStorage',
          message: error.message,
        );
      }
    });
    _languageTail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<Map<String, Object>> _setAppLanguage(String value) {
    final choice = PlayerLanguage.values
        .where((language) => language.name == value)
        .firstOrNull;
    if (choice == null) {
      throw PlatformException(
        code: 'invalidArguments',
        message: 'Unsupported appLanguage: $value.',
      );
    }
    return _withLanguagePreferences(() async {
      late PlayerPreferences saved;
      await preferencesStore.update(
        (current) => saved = current.copyWith(language: choice),
      );
      await _onAppLanguageChanged?.call();
      final language = _languagePayload(saved);
      _publishLanguage(language);
      return language;
    });
  }

  Future<Map<String, Object>> _readLanguage() async =>
      _languagePayload((await preferencesStore.load()).preferences);

  Map<String, Object> _languagePayload(PlayerPreferences preferences) {
    final locales = resolvePlayerLocales(
      preferences: preferences,
      systemLocales: _systemLocales(),
      supportedAppLocales: _supportedAppLanguages,
      supportedPlayerLocales: PokeMapPlayerLocalizations.supportedLocales.map(
        (locale) => locale.toLanguageTag(),
      ),
    );
    return {
      'appLanguage': preferences.language.name,
      'appLocale': locales.appLocale,
      'supportedAppLanguages': _supportedAppLanguages,
    };
  }

  void _publishLanguage(Map<String, Object> language) {
    if (mapEquals(language, _lastReportedLanguage)) return;
    _lastReportedLanguage = language;
    unawaited(
      _channel
          .invokeMethod<void>('languagePreferencesChanged', language)
          .then<void>((_) {}, onError: (Object _) {}),
    );
  }

  static Iterable<String> _readSystemLocales() {
    return PlatformDispatcher.instance.locales.map(
      (locale) => locale.toLanguageTag(),
    );
  }

  Future<List<Map<String, Object?>>> _listGames() async {
    final read = await _library.load();
    return <Map<String, Object?>>[
      for (final game in read.library.games) await _describe(game),
    ];
  }

  Future<Map<String, Object?>> _installGame(String packagePath) async {
    try {
      final progressRelay = InstallProgressRelay(channel: _channel);
      final result = await InstallGamePackageUseCase(_installer)
          .call(File(packagePath), onProgress: progressRelay.call)
          .whenComplete(progressRelay.dispose);
      return await _describe(result.game);
    } on GameInstallationException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        PlatformException(
          code: 'installation.${error.diagnostic.code.name}',
          message: gameInstallationMessage(error.diagnostic),
          details: <String, Object?>{
            ...error.diagnostic.toJson(),
            if (error.cause != null) 'cause': '${error.cause}',
          },
        ),
        error.stackTrace ?? stackTrace,
      );
    }
  }

  Future<void> _playGame(String gameId) async {
    await _stopping;
    if (playing.value != null) {
      throw PlatformException(
        code: 'gameAlreadyPlaying',
        message: 'A game is already playing.',
      );
    }
    final read = await _library.load();
    final game = read.library.game(gameId);
    if (game == null) {
      throw PlatformException(
        code: 'gameNotInstalled',
        message: 'No installed game with id $gameId.',
      );
    }
    if (playing.value != null) {
      throw PlatformException(
        code: 'gameAlreadyPlaying',
        message: 'A game is already playing.',
      );
    }
    _playerGeneration++;
    playing.value = game;
  }

  Future<void> _stopGame() => _stopping ??= _stopOwnedPlayer().whenComplete(() {
    _stopping = null;
  });

  Future<void> _stopOwnedPlayer() async {
    await _stopPlayer?.call();
    playing.value = null;
  }

  Future<Map<String, Object?>> _describe(InstalledGame game) async {
    final activity = await _activity(game);
    return <String, Object?>{
      'gameId': game.gameId,
      'title': game.title,
      'description': game.description,
      'author': game.authorName,
      'publisher': game.publisherName,
      'version': game.currentVersion.gameVersion.toString(),
      'defaultLocale': game.defaultLocale,
      'supportedLocales': game.supportedLocales,
      'accentColor': game.branding?.accentColor,
      'iconPath': activity.iconPath,
      'coverPath': activity.coverPath,
      'heroPath': activity.heroPath,
      'canContinue': activity.canContinue,
      'lastPlayedAt': activity.lastSaveAt?.toIso8601String(),
      'playTimeSeconds': activity.playTimeSeconds,
    };
  }
}
