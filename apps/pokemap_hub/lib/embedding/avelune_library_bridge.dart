import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:pokemap_hub/core/config/avelune_host_compatibility.dart';
import 'package:pokemap_hub/features/installation/application/use_cases/install_game_package_use_case.dart';
import 'package:pokemap_hub/features/installation/data/repositories/installed_project_smoke.dart';
import 'package:pokemap_hub/features/saves/data/repositories/game_save_update_preparation.dart';
import 'package:pokemap_hub/platform/hub_platform_adapter_factory.dart';
import 'package:pokemap_hub/platform/path_provider_support_root_adapter.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

class AveluneLibraryBridge {
  AveluneLibraryBridge({
    MethodChannel? channel,
    Future<Directory> Function()? supportRootResolver,
    Future<void> Function()? stopPlayer,
  }) : _channel = channel ?? const MethodChannel('com.avelune.runtime/library'),
       _supportRootResolver =
           supportRootResolver ??
           const PathProviderSupportRootAdapter().resolve,
       _stopPlayer = stopPlayer;

  final MethodChannel _channel;
  final Future<Directory> Function() _supportRootResolver;
  final Future<void> Function()? _stopPlayer;
  Future<void>? _stopping;
  int _playerGeneration = 0;
  int get playerGeneration => _playerGeneration;

  final ValueNotifier<InstalledGame?> playing = ValueNotifier<InstalledGame?>(
    null,
  );

  late final Directory supportRoot;
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
      prepareSavesForUpdate:
          GameSaveUpdatePreparation(supportRoot: supportRoot).call,
    );
    _maintenance = GameMaintenanceService(
      supportRoot: supportRoot,
      installer: _installer,
    );
    _library = GameLibraryStore(supportRoot: supportRoot);
    launchResolver = InstalledGameLaunchResolver(
      supportRoot: supportRoot,
      hostCompatibility: hostCompatibility,
    );
    _activity = InstalledHubGameActivityReader(
      supportRoot: supportRoot,
      launchResolver: launchResolver,
      saveRepositoryFactory:
          (root, identity) =>
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
      default:
        throw MissingPluginException('Unknown method: ${call.method}');
    }
  }

  Future<List<Map<String, Object?>>> _listGames() async {
    final read = await _library.load();
    return <Map<String, Object?>>[
      for (final game in read.library.games) await _describe(game),
    ];
  }

  Future<Map<String, Object?>> _installGame(String packagePath) async {
    final result = await InstallGamePackageUseCase(
      _installer,
    ).call(File(packagePath));
    return _describe(result.game);
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

  Future<void> _stopGame() =>
      _stopping ??= _stopOwnedPlayer().whenComplete(() {
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
