import 'dart:io';

import 'package:pokemap_hub/features/dashboard/application/notifiers/hub_dashboard_state.dart';
import 'package:pokemap_hub/features/library/domain/repositories/game_library_repository_interface.dart';
import 'package:pokemap_hub/features/preferences/domain/repositories/player_preferences_repository_interface.dart';

/// Everything [HubDashboardNotifier] needs, resolved as one unit.
///
/// The notifier's state is synchronous while its dependencies all hang off the
/// async support root, so they cannot be resolved in `build()`. Bundling them
/// means the notifier awaits **one** provider instead of six, and a test
/// overrides **one** provider instead of six.
final class HubDashboardDependencies {
  const HubDashboardDependencies({
    required this.libraryStore,
    required this.activityReader,
    this.importer,
    this.editorExportConsumer,
    this.preferencesStore,
    this.storageReader,
    this.diagnosticLogFile,
  });

  final GameLibraryRepositoryInterface libraryStore;
  final HubGameActivityReader activityReader;
  final HubPackageImporter? importer;
  final HubEditorExportConsumer? editorExportConsumer;
  final PlayerPreferencesRepositoryInterface? preferencesStore;
  final HubStorageReader? storageReader;
  final File? diagnosticLogFile;
}
