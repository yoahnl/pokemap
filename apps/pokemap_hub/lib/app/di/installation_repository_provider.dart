import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;

import 'package:pokemap_hub/app/di/infrastructure_providers.dart';
import 'package:pokemap_hub/features/installation/data/repositories/editor_export_install_inbox.dart';
import 'package:pokemap_hub/features/installation/data/repositories/game_package_installer.dart';
import 'package:pokemap_hub/features/installation/data/repositories/game_maintenance_service.dart';
import 'package:pokemap_hub/features/installation/data/repositories/installed_project_smoke.dart';
import 'package:pokemap_hub/features/installation/domain/repositories/game_installation_repository_interface.dart';
import 'package:pokemap_hub/features/saves/data/repositories/game_save_update_preparation.dart';

/// Infrastructure wiring for package installation.
final gameInstallationRepositoryProvider =
    FutureProvider<GameInstallationRepositoryInterface>((ref) async {
  final root = await ref.watch(supportRootProvider.future);
  final saveUpdatePreparation = GameSaveUpdatePreparation(supportRoot: root);
  return GamePackageInstaller(
    supportRoot: root,
    inspector: GamePackageInspector(
      hostCompatibility: ref.watch(hostCompatibilityProvider),
    ),
    availableDiskBytes: ref.watch(hubPlatformAdapterProvider).availableDiskBytes,
    loadSmoke: loadInstalledProjectSmoke,
    prepareSavesForUpdate: saveUpdatePreparation.call,
  );
});

final gameMaintenanceServiceProvider = FutureProvider<GameMaintenanceService>(
  (ref) async => GameMaintenanceService(
    supportRoot: await ref.watch(supportRootProvider.future),
    installer: await ref.watch(gameInstallationRepositoryProvider.future),
  ),
);

/// Drop folder the editor exports into; consumed on every dashboard reload.
final editorExportInboxProvider = FutureProvider<EditorExportInstallInbox>(
  (ref) async {
    final root = await ref.watch(supportRootProvider.future);
    return EditorExportInstallInbox.fromInstaller(
      inbox: Directory(p.join(root.path, 'install-inbox')),
      installer: await ref.watch(gameInstallationRepositoryProvider.future),
    );
  },
);
