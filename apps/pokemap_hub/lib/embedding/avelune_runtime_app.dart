import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/core/config/avelune_runtime_splash_branding.dart';
import 'package:pokemap_hub/features/session/data/repositories/control_profile_repository_impl.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

import 'avelune_library_bridge.dart';
import 'avelune_gameplay_companion.dart';
import 'avelune_surface_probe.dart';
import 'avelune_surface_probe_app.dart';

class AveluneRuntimeApp extends StatefulWidget {
  const AveluneRuntimeApp({super.key});

  @override
  State<AveluneRuntimeApp> createState() => _AveluneRuntimeAppState();
}

class _AveluneRuntimeAppState extends State<AveluneRuntimeApp> {
  final _playerController = HubInstalledGamePlayerController();
  final _companion = AveluneGameplayCompanionOwner();
  late final _companionBridge = AveluneGameplayCompanionBridge(
    _companion,
    canStart: () => _probe.value == null,
  );
  late final AveluneLibraryBridge _bridge = AveluneLibraryBridge(
    stopPlayer: () async {
      await _companionBridge.stopOwnedSession();
      await _playerController.stop();
    },
  );
  final _probe = AveluneSurfaceProbeController();
  late final _probeBridge = AveluneSurfaceProbeBridge(
    _probe,
    canStart: () => _bridge.playing.value == null && _companion.value == null,
  );

  @override
  void initState() {
    super.initState();
    _probeBridge.attach();
    _companionBridge.attach();
    _bridge.attach();
  }

  @override
  void dispose() {
    unawaited(_companionBridge.stopOwnedSession());
    _probeBridge.detach();
    _companionBridge.detach();
    _companion.dispose();
    _probe.dispose();
    _bridge.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ListenableBuilder(
        listenable: Listenable.merge([_bridge.playing, _probe]),
        builder: (context, _) {
          if (_probe.value != null) {
            return Theme(
              data: ThemeData.dark(useMaterial3: true),
              child: AvelunePrimaryProbeSurface(
                controller: _probe,
                bridge: _probeBridge,
              ),
            );
          }
          final game = _bridge.playing.value;
          if (game == null) return const SizedBox.expand();
          return HubInstalledGamePlayer(
            key: ValueKey<String>('${game.gameId}:${_bridge.playerGeneration}'),
            controller: _playerController,
            companionOwner: _companion,
            onCompanionInput: _companionBridge.forwardInput,
            beforePlayerStops: _companionBridge.stopOwnedSession,
            supportRoot: _bridge.supportRoot,
            saveRepositoryFactory:
                (root, identity) =>
                    HubSaveStore(supportRoot: root, identity: identity),
            preferencesRepository: HubPreferencesStore(
              supportRoot: _bridge.supportRoot,
            ),
            controlProfileRepository: HubControlProfileStore(
              supportRoot: _bridge.supportRoot,
            ),
            launchResolver: _bridge.launchResolver,
            game: game,
            hostBranding: aveluneRuntimeSplashBranding,
            splashLogo: AssetImage(
              Platform.isAndroid
                  ? 'assets/avelune/logo/avelune_symbol_android.png'
                  : 'assets/avelune/logo/avelune_moon.png',
              package: 'pokemap_hub',
            ),
            splashWordmark: const AssetImage(
              'assets/avelune/logo/avelune_glass_wordmark.png',
              package: 'pokemap_hub',
            ),
            diagnosticLogFile: File(
              p.join(
                _bridge.supportRoot.path,
                'logs',
                'avelune-${Platform.operatingSystem}-player.log',
              ),
            ),
            onHubRequested: _bridge.requestExit,
          );
        },
      ),
    );
  }
}
