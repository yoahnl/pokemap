import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/core/config/avelune_host_compatibility.dart';
import 'package:pokemap_hub/features/installation/application/use_cases/install_game_package_use_case.dart';
import 'package:pokemap_hub/features/installation/data/repositories/installed_project_smoke.dart';
import 'package:pokemap_hub/features/saves/data/repositories/game_save_update_preparation.dart';
import 'package:pokemap_hub/features/session/data/repositories/control_profile_repository_impl.dart';
import 'package:pokemap_hub/platform/hub_platform_adapter_factory.dart';
import 'package:pokemap_hub/platform/path_provider_support_root_adapter.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

const _splashBranding = RuntimeHostSplashBranding(
  displayName: 'AVELUNE',
  signature: 'UNE EXPÉRIENCE DE JEU',
  primaryColorHex: '#F2D9B2',
  secondaryColorHex: '#9E79D7',
  backgroundColorHex: '#030306',
  minimumDisplayDuration: Duration(milliseconds: 2400),
  exitTransitionDuration: Duration(milliseconds: 360),
  finalCurtainDuration: Duration(milliseconds: 180),
);

const _hubPackage = 'pokemap_hub';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AveluneRuntimeApp());
}

class AveluneRuntimeApp extends StatefulWidget {
  const AveluneRuntimeApp({super.key});

  @override
  State<AveluneRuntimeApp> createState() => _AveluneRuntimeAppState();
}

class _AveluneRuntimeAppState extends State<AveluneRuntimeApp> {
  final AveluneLibraryBridge _bridge = AveluneLibraryBridge();

  @override
  void initState() {
    super.initState();
    _bridge.attach();
  }

  @override
  void dispose() {
    _bridge.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ValueListenableBuilder<InstalledGame?>(
        valueListenable: _bridge.playing,
        builder: (context, game, _) {
          if (game == null) {
            return const ColoredBox(color: Colors.black);
          }
          return HubInstalledGamePlayer(
            key: ValueKey<String>(game.gameId),
            supportRoot: _bridge.supportRoot,
            saveRepositoryFactory: (root, identity) =>
                HubSaveStore(supportRoot: root, identity: identity),
            preferencesRepository: HubPreferencesStore(
              supportRoot: _bridge.supportRoot,
            ),
            controlProfileRepository: HubControlProfileStore(
              supportRoot: _bridge.supportRoot,
            ),
            launchResolver: _bridge.launchResolver,
            game: game,
            hostBranding: _splashBranding,
            splashLogo: const AssetImage(
              'assets/avelune/logo/avelune_moon.png',
              package: _hubPackage,
            ),
            splashWordmark: const AssetImage(
              'assets/avelune/logo/avelune_glass_wordmark.png',
              package: _hubPackage,
            ),
            diagnosticLogFile: File(
              p.join(_bridge.supportRoot.path, 'logs', 'avelune-ios-player.log'),
            ),
            onHubRequested: _bridge.requestExit,
          );
        },
      ),
    );
  }
}

/// Channel surface offered to the native shell.
///
/// The shell owns the library screens; every behaviour that belongs to a game —
/// splash, intro, title menu, saves, gameplay, pause — stays inside the shared
/// player the Flutter app uses, so both hosts run the same code.
class AveluneLibraryBridge {
  static const MethodChannel _channel = MethodChannel('com.avelune.runtime/library');

  final ValueNotifier<InstalledGame?> playing = ValueNotifier<InstalledGame?>(null);

  late final Directory supportRoot;
  late final InstalledGameLaunchResolver launchResolver;
  late final GamePackageInstaller _installer;
  late final GameMaintenanceService _maintenance;
  late final GameLibraryStore _library;
  late final InstalledHubGameActivityReader _activity;

  Future<void>? _ready;

  void attach() => _channel.setMethodCallHandler(_handle);

  void detach() {
    _channel.setMethodCallHandler(null);
    playing.dispose();
  }

  Future<void> requestExit() async {
    playing.value = null;
    await _channel.invokeMethod<void>('playerDidExit');
  }

  Future<void> _ensureReady() => _ready ??= _build();

  Future<void> _build() async {
    supportRoot = await const PathProviderSupportRootAdapter().resolve();
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
      saveRepositoryFactory: (root, identity) =>
          HubSaveStore(supportRoot: root, identity: identity),
    );
  }

  Future<dynamic> _handle(MethodCall call) async {
    await _ensureReady();
    switch (call.method) {
      case 'listGames':
        return _listGames();
      case 'installGame':
        return _installGame(call.arguments['packagePath'] as String);
      case 'uninstallGame':
        await _maintenance.uninstallGame(call.arguments['gameId'] as String);
        return _listGames();
      case 'playGame':
        return _playGame(call.arguments['gameId'] as String);
      case 'stopGame':
        playing.value = null;
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
    final result =
        await InstallGamePackageUseCase(_installer).call(File(packagePath));
    return _describe(result.game);
  }

  Future<void> _playGame(String gameId) async {
    final read = await _library.load();
    final game = read.library.game(gameId);
    if (game == null) {
      throw PlatformException(
        code: 'gameNotInstalled',
        message: 'No installed game with id $gameId.',
      );
    }
    playing.value = game;
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
