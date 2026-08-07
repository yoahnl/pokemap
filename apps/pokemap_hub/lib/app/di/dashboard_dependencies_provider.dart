import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'package:pokemap_hub/app/di/providers.dart';
import 'package:pokemap_hub/features/dashboard/application/notifiers/hub_dashboard_dependencies.dart';
import 'package:pokemap_hub/features/dashboard/application/services/installed_game_activity_reader.dart';
import 'package:pokemap_hub/features/installation/application/installation_providers.dart';

/// Assembles the dashboard's dependency bundle from the repository graph.
///
/// This is the seam tests override: replacing this single provider swaps every
/// dependency the dashboard has, without reaching into the notifier.
final hubDashboardDependenciesProvider =
    FutureProvider<HubDashboardDependencies>((ref) async {
  final root = await ref.watch(supportRootProvider.future);
  final installUseCase =
      await ref.watch(installGamePackageUseCaseProvider.future);
  final exportsUseCase =
      await ref.watch(consumeEditorExportsUseCaseProvider.future);

  return HubDashboardDependencies(
    supportRoot: root,
    libraryStore: await ref.watch(gameLibraryRepositoryProvider.future),
    activityReader: InstalledHubGameActivityReader(
      supportRoot: root,
      launchResolver: await ref.watch(sessionLaunchRepositoryProvider.future),
      saveRepositoryFactory: ref.watch(saveRepositoryFactoryProvider),
    ).call,
    importer: (package, cancellation, progress) async {
      await installUseCase(
        package,
        cancellationToken: cancellation,
        onProgress: progress,
      );
    },
    editorExportConsumer: exportsUseCase.call,
    preferencesStore:
        await ref.watch(playerPreferencesRepositoryProvider.future),
    diagnosticLogFile: File(p.join(root.path, 'logs', 'hub-import.log')),
  );
});
