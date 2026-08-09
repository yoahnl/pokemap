import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:pokemap_hub/app/app_root.dart';
import 'package:pokemap_hub/app/di/infrastructure_providers.dart';
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

void main() {
  MarionetteBinding.ensureInitialized();
  final container = ProviderContainer();
  registerMarionetteExtension(
    name: 'pokemapHub.qaContext',
    description: 'Returns the installed library and active Hub selection.',
    callback:
        (_) async => MarionetteExtensionResult.success(
          hubQaContext(
            supportRoot: await container.read(supportRootProvider.future),
            dashboard: container.read(hubDashboardNotifierProvider),
          ),
        ),
  );
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PokeMapHubBootstrap(),
    ),
  );
}
