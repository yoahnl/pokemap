import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

import 'package:pokemap_hub/pokemap_hub_ui.dart';
import 'package:pokemap_hub/core/config/avelune_host_compatibility.dart';
import 'package:pokemap_hub/core/ports/hub_platform_port.dart';
import 'package:pokemap_hub/platform/hub_platform_adapter_factory.dart';
import 'package:pokemap_hub/core/config/public_product_identity.dart';
import 'package:pokemap_hub/core/error/hub_failure.dart';
import 'package:pokemap_hub/platform/path_provider_support_root_adapter.dart';
import 'package:pokemap_hub/features/session/data/repositories/control_profile_repository_impl.dart';

abstract interface class HubAppComposition {
  Widget buildApp();

  void dispose();
}

/// Platform-neutral composition root for the PokeMap player product.
///
/// Native adapters only select files, report disk capacity, and forward
/// operating-system open events. Package trust decisions remain in Dart.
final class HubComposition implements HubAppComposition {
  HubComposition._({
    required this.supportRoot,
    required this.controller,
    required this.actions,
    required this.launchResolver,
    required this.appearanceController,
    required GameMaintenanceService? gameMaintenance,
    required HubPlatformAdapter platformAdapter,
  })  : _gameMaintenance = gameMaintenance,
        _platformAdapter = platformAdapter;

  final Directory supportRoot;
  final HubDashboardNotifier controller;
  final HubUiActions actions;
  final InstalledGameLaunchResolver launchResolver;
  final AveluneAppearanceNotifier appearanceController;
  final GameMaintenanceService? _gameMaintenance;
  final HubPlatformAdapter _platformAdapter;

  /// Builds the app shell around an already-wired dashboard notifier.
  ///
  /// The notifier used to be assembled here from seven hand-held dependencies;
  /// it now arrives from [hubDashboardNotifierProvider] and resolves its own
  /// graph through [hubDashboardDependenciesProvider]. What is left is genuinely
  /// composition: the platform adapter, the launch resolver the player screen
  /// needs, and the widget tree.
  static Future<HubComposition> create({
    required HubDashboardNotifier dashboardNotifier,
    required AveluneAppearanceNotifier appearanceNotifier,
    GameMaintenanceService? gameMaintenance,
    HubPlatformAdapter? platformAdapter,
    Directory? supportRoot,
  }) async {
    final adapter = platformAdapter ?? createHubPlatformAdapter();
    HubComposition? composition;
    try {
      final root = supportRoot ?? await const PathProviderSupportRootAdapter().resolve();
      await root.create(recursive: true);
      final launchResolver = InstalledGameLaunchResolver(
        supportRoot: root,
        hostCompatibility: aveluneHostCompatibility(),
      );
      final controller = dashboardNotifier;
      late final HubComposition initializedComposition;
      final actions = HubUiActions(
        onImportRequested: () {
          unawaited(initializedComposition._pickAndImport());
        },
        onUninstall: gameMaintenance == null
            ? null
            : (game) => initializedComposition._uninstall(game),
      );
      final appearanceController = appearanceNotifier;
      await appearanceController.initialize();
      initializedComposition = HubComposition._(
        supportRoot: root,
        controller: controller,
        actions: actions,
        launchResolver: launchResolver,
        appearanceController: appearanceController,
        gameMaintenance: gameMaintenance,
        platformAdapter: adapter,
      );
      composition = initializedComposition;
      await adapter.attachPackageOpenHandler(
        initializedComposition._importExternalPackage,
      );
      return initializedComposition;
    } on Object {
      if (composition case final initialized?) {
        initialized.dispose();
      } else {
        adapter.dispose();
      }
      rethrow;
    }
  }


  @override
  Widget buildApp() => PokeMapHubApp(
        productName: publicProductName,
        controller: controller,
        actions: actions,
        appearanceController: appearanceController,
        playerBuilder: (context, game, intent, onHubRequested) =>
            HubInstalledGamePlayer(
          supportRoot: supportRoot,
          // Interface meets implementation here and nowhere else (rule 6).
          saveRepositoryFactory: (root, identity) => HubSaveStore(
            supportRoot: root,
            identity: identity,
          ),
          preferencesRepository: HubPreferencesStore(supportRoot: supportRoot),
          controlProfileRepository:
              HubControlProfileStore(supportRoot: supportRoot),
          launchResolver: launchResolver,
          game: game.game,
          initialLaunchIntent: intent,
          preferences: controller.snapshot.preferences,
          diagnosticLogFile: File(
            p.join(supportRoot.path, 'logs', 'hub-player.log'),
          ),
          onHubRequested: onHubRequested,
        ),
      );

  Future<void> _pickAndImport() async {
    try {
      final selectedPath = await _platformAdapter.pickPackage();
      if (selectedPath == null) return;
      await _importExternalPackage(File(selectedPath), reportInvalid: true);
    } on HubPackagePickerFailure catch (error, stackTrace) {
      await controller.reportImportPickerFailure(
        code: error.code,
        message: error.message,
        recommendation: error.recommendation,
        cause: error.cause ?? error,
        stackTrace: stackTrace,
      );
    } on Object catch (error, stackTrace) {
      await controller.reportImportPickerFailure(
        code: 'importPicker.openFailed',
        message: 'Le sélecteur de fichiers n’a pas pu être ouvert.',
        recommendation:
            'Fermez complètement le Hub, relancez-le puis réessayez. '
            'Les détails techniques sont disponibles dans Diagnostics.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _uninstall(HubGameView game) async {
    await _gameMaintenance!.uninstallGame(game.game.gameId);
    await controller.refresh();
  }

  Future<void> _importExternalPackage(
    File package, {
    bool reportInvalid = false,
  }) async {
    const supportedExtensions = <String>{'.avelunegame', '.pokemapgame'};
    final isPackage = supportedExtensions.contains(
      p.extension(package.path).toLowerCase(),
    );
    if (!isPackage || !await package.exists()) {
      if (reportInvalid) {
        throw const HubPackagePickerFailure(
          code: 'importPicker.invalidSelection',
          message: 'Le fichier sélectionné n’est pas un package de jeu valide.',
          recommendation: 'Choisissez un package de jeu compatible.',
        );
      }
      return;
    }
    await controller.importPackage(package);
  }

  @override
  void dispose() {
    _platformAdapter.dispose();
  }
}
