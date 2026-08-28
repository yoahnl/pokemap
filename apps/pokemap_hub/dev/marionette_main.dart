import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:pokemap_hub/app/app_root.dart';
import 'package:pokemap_hub/app/di/hub_composition.dart';
import 'package:pokemap_hub/app/di/hub_composition_provider.dart';
import 'package:pokemap_hub/features/control/application/avelune_control_service.dart';
import 'package:pokemap_hub/features/control/infrastructure/avelune_control_server.dart';
import 'package:pokemap_hub/features/dashboard/application/notifiers/hub_dashboard_notifier.dart';
import 'package:pokemap_hub/features/dashboard/application/notifiers/hub_dashboard_state.dart';

Map<String, Object?> hubQaContext({
  required Directory supportRoot,
  required HubDashboardSnapshot dashboard,
}) => <String, Object?>{
  'supportRoot': supportRoot.path,
  'status': dashboard.status.name,
  'selectedGameId': dashboard.selectedGameId,
  'games': <Map<String, Object?>>[
    for (final view in dashboard.games)
      <String, Object?>{
        'gameId': view.game.gameId,
        'gameVersion': view.game.current.gameVersion.toString(),
        'title': view.game.title,
        'canContinue': view.activity.canContinue,
      },
  ],
};

Future<void> main() async {
  MarionetteBinding.ensureInitialized();
  final container = ProviderContainer();
  final composition =
      await container.read(hubCompositionProvider.future) as HubComposition;
  final control = AveluneControlService(
    readDashboard: () => composition.controller.snapshot,
    sessionController: composition.sessionController,
    installPackage: composition.controller.importPackage,
  );
  container.listen<HubDashboardSnapshot>(
    hubDashboardNotifierProvider,
    (_, next) => control.observeDashboard(next),
    fireImmediately: true,
  );
  const controlToken = String.fromEnvironment('AVELUNE_CONTROL_TOKEN');
  if (controlToken.isNotEmpty) {
    const controlPort = int.fromEnvironment(
      'AVELUNE_CONTROL_PORT',
      defaultValue: 45873,
    );
    await AveluneControlServer(
      service: control,
      token: controlToken,
      port: controlPort,
      uploadDirectory: Directory(
        '${composition.supportRoot.path}/control/uploads',
      ),
    ).start();
  }
  registerMarionetteExtension(
    name: 'pokemapHub.qaContext',
    description: 'Returns the installed library and active Hub selection.',
    callback:
        (_) async => MarionetteExtensionResult.success(
          hubQaContext(
            supportRoot: composition.supportRoot,
            dashboard: composition.controller.snapshot,
          ),
        ),
  );
  registerMarionetteExtension(
    name: 'avelune.controlState',
    description: 'Returns the semantic state of the controlled Avelune app.',
    callback:
        (_) async =>
            MarionetteExtensionResult.success(control.state().toJson()),
  );
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PokeMapHubBootstrap(),
    ),
  );
}
