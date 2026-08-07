import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/app/di/dashboard_dependencies_provider.dart';
import 'package:pokemap_hub/features/library/domain/repositories/game_library_repository_interface.dart';
import 'package:pokemap_hub/features/preferences/domain/repositories/player_preferences_repository_interface.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

/// A dashboard notifier wired to test doubles, plus the container owning it.
///
/// [HubDashboardNotifier] resolves its dependencies from
/// [hubDashboardDependenciesProvider]. Overriding that one provider replaces
/// all seven at once, which is why these tests do not have to know about the
/// repository providers underneath.
final class DashboardHarness {
  DashboardHarness._(this.container, this.notifier);

  final ProviderContainer container;
  final HubDashboardNotifier notifier;

  HubDashboardSnapshot get snapshot => notifier.snapshot;

  /// Records every status the notifier publishes, in order.
  List<HubDashboardStatus> observeStatuses() {
    final observed = <HubDashboardStatus>[];
    container.listen<HubDashboardSnapshot>(
      hubDashboardNotifierProvider,
      (_, next) => observed.add(next.status),
    );
    return observed;
  }

  /// Wraps a widget so it resolves providers from **this** container.
  ///
  /// Without it a pumped [PokeMapHubApp] would look for its own ProviderScope
  /// and build a second, unrelated notifier.
  Widget wrap(Widget child) => UncontrolledProviderScope(
        container: container,
        child: child,
      );

  void dispose() => container.dispose();
}

/// Builds a notifier backed by the doubles a test cares about.
///
/// Anything left null keeps the notifier's own default: no importer, no export
/// consumer, no preference persistence, no diagnostic log.
DashboardHarness buildDashboardHarness({
  required GameLibraryRepositoryInterface libraryStore,
  required HubGameActivityReader activityReader,
  HubPackageImporter? importer,
  HubEditorExportConsumer? editorExportConsumer,
  PlayerPreferencesRepositoryInterface? preferencesStore,
  HubStorageReader? storageReader,
  File? diagnosticLogFile,
}) {
  final container = ProviderContainer(
    overrides: [
      hubDashboardDependenciesProvider.overrideWith(
        (ref) async => HubDashboardDependencies(
          libraryStore: libraryStore,
          activityReader: activityReader,
          importer: importer,
          editorExportConsumer: editorExportConsumer,
          preferencesStore: preferencesStore,
          storageReader: storageReader,
          diagnosticLogFile: diagnosticLogFile,
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return DashboardHarness._(
    container,
    container.read(hubDashboardNotifierProvider.notifier),
  );
}
