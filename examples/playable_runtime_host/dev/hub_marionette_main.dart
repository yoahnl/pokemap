import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/app/app_root.dart';
import 'package:pokemap_hub/app/di/hub_composition.dart';
import 'package:pokemap_hub/app/di/hub_composition_provider.dart';
import 'package:pokemap_hub/app/di/infrastructure_providers.dart';

import 'hub_recipe_asset_bundle.dart';

Future<void> main() async {
  if (!kDebugMode || !Platform.isMacOS) {
    throw StateError('This recipe host requires a macOS debug build.');
  }
  MarionetteBinding.ensureInitialized();
  final supportRoot = await _ownedSupportRoot();
  final container = ProviderContainer(
    overrides: [supportRootProvider.overrideWith((ref) async => supportRoot)],
  );
  registerMarionetteExtension(
    name: 'player.qaContext',
    description: 'Observes the isolated Hub and its installed Player.',
    callback: (_) async {
      final composition = container.read(hubCompositionProvider).asData?.value;
      final hub = composition is HubComposition ? composition : null;
      final game = _mountedGame();
      final state = game?.gameStateSnapshot;
      final view = WidgetsBinding.instance.platformDispatcher.implicitView;
      return MarionetteExtensionResult.success({
        'pid': pid,
        'supportRoot': supportRoot.path,
        'surface': hub?.sessionController.surface.name,
        'dashboardStatus': hub?.controller.snapshot.status.name,
        'textScale': hub?.controller.snapshot.preferences.textScale,
        'activeGameId': hub?.sessionController.activeGame?.game.gameId,
        'installedGames': hub?.controller.snapshot.games
            .map(
              (entry) => {
                'gameId': entry.game.gameId,
                'title': entry.game.title,
                'pointer': entry.game.current.toJson(),
                'healthy': entry.activity.installationHealthy,
              },
            )
            .toList(),
        'mounted': game != null,
        'loaded': game?.isLoaded ?? false,
        'projectFilePath': game?.projectFilePath,
        'mapId': state?.currentMapId,
        'position': state?.playerPosition.toJson(),
        'metadata': state?.metadata,
        'inputContext': game?.inputAuthoritySnapshot.context.name,
        'physicalSize': view == null
            ? null
            : {
                'width': view.physicalSize.width,
                'height': view.physicalSize.height,
              },
        'devicePixelRatio': view?.devicePixelRatio,
        'logicalSize': view == null
            ? null
            : {
                'width': view.physicalSize.width / view.devicePixelRatio,
                'height': view.physicalSize.height / view.devicePixelRatio,
              },
      });
    },
  );
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: DefaultAssetBundle(
        bundle: HubRecipeAssetBundle(),
        child: const PokeMapHubBootstrap(),
      ),
    ),
  );
}

Future<Directory> _ownedSupportRoot() async {
  const configuredPath = String.fromEnvironment('UWU6_PLAYER_SUPPORT_ROOT');
  if (configuredPath.isEmpty || !p.isAbsolute(configuredPath)) {
    throw StateError('UWU6_PLAYER_SUPPORT_ROOT must be an absolute directory.');
  }
  if (await FileSystemEntity.type(configuredPath, followLinks: false) !=
      FileSystemEntityType.directory) {
    throw StateError(
      'The recipe support root must already exist without a symlink.',
    );
  }
  final root = Directory(
    await Directory(configuredPath).resolveSymbolicLinks(),
  );
  final temporaryRoot = await Directory('/tmp').resolveSymbolicLinks();
  if (!p.isWithin(temporaryRoot, root.path) ||
      !p.basename(root.path).startsWith('uwu6-native-player-')) {
    throw StateError('The Player recipe must use its own temporary directory.');
  }
  final marker = File(p.join(root.path, '.uwu6-native-player-owner'));
  if (await FileSystemEntity.type(marker.path, followLinks: false) !=
          FileSystemEntityType.file ||
      (await marker.readAsString()).trim() != 'uwu6-native-closure') {
    throw StateError('The recipe support root ownership marker is missing.');
  }
  return root;
}

PlayableMapGame? _mountedGame() {
  PlayableMapGame? found;
  void visit(Element element) {
    final widget = element.widget;
    if (widget is GameWidget && widget.game is PlayableMapGame) {
      if (found != null && !identical(found, widget.game)) {
        throw StateError('More than one installed Player is mounted.');
      }
      found = widget.game as PlayableMapGame;
    }
    element.visitChildElements(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildElements(visit);
  return found;
}
