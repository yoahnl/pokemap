import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_loader/src/runtime_startup_host.dart';

void main() {
  test(
    'standalone reloads injected per-game favorites across host instances',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'host-favorites-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final projectFile = File(
        '${Directory.current.path}/golden_battle_slice/project.json',
      );
      final manifest = ProjectManifest.fromJson(
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
      );
      final gateway = FilePlayerInventoryPreferencesGateway(
        directory: directory,
      );
      for (var index = 0; index < 2; index++) {
        final host = StandaloneRuntimeStartupHost(
          projectFilePath: projectFile.path,
          manifest: manifest,
          inventoryPreferencesGateway: gateway,
          sessionPort: CallbackStandaloneRuntimeSessionPort(
            onLaunch: (_, _, _) async {},
          ),
        );
        if (index == 0) await gateway.save(host.identity.gameId, {'potion'});
        await host.playerCoordinator.initialize();
        expect(host.playerCoordinator.snapshot.phase, RuntimePlayerPhase.title);
        expect(host.playerCoordinator.snapshot.bagFavoritesAvailable, isTrue);
        expect(host.playerCoordinator.snapshot.favoriteItemIds, {'potion'});
        await host.dispose();
      }
    },
  );
}
