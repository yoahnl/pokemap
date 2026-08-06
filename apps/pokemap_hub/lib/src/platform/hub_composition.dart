import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../pokemap_hub_ui.dart';
import 'avelune_host_compatibility.dart';
import 'hub_platform_adapter.dart';
import 'hub_platform_adapter_factory.dart';
import 'public_product_identity.dart';

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
    required this.displayPreferencesController,
    required this.appearanceController,
    required HubPlatformAdapter platformAdapter,
  }) : _platformAdapter = platformAdapter;

  final Directory supportRoot;
  final HubDashboardController controller;
  final HubUiActions actions;
  final InstalledGameLaunchResolver launchResolver;
  final HubDisplayPreferencesController displayPreferencesController;
  final AveluneAppearanceController appearanceController;
  final HubPlatformAdapter _platformAdapter;

  static Future<HubComposition> create({
    HubPlatformAdapter? platformAdapter,
    Directory? supportRoot,
  }) async {
    final adapter = platformAdapter ?? createHubPlatformAdapter();
    HubComposition? composition;
    try {
      final root = supportRoot ?? await _defaultSupportRoot();
      await root.create(recursive: true);
      final hostCompatibility = aveluneHostCompatibility();
      late final GamePackageInstaller installer;
      installer = GamePackageInstaller(
        supportRoot: root,
        inspector: GamePackageInspector(
          hostCompatibility: hostCompatibility,
        ),
        availableDiskBytes: adapter.availableDiskBytes,
        loadSmoke: _loadInstalledProjectSmoke,
        prepareSavesForUpdate: (_, __) {
          throw UnsupportedError(
            'Updates remain disabled until save migration transactions '
            'are recoverable.',
          );
        },
      );
      final libraryStore = GameLibraryStore(supportRoot: root);
      final launchResolver = InstalledGameLaunchResolver(
        supportRoot: root,
        hostCompatibility: hostCompatibility,
      );
      final inbox = EditorExportInstallInbox.fromInstaller(
        inbox: Directory(p.join(root.path, 'install-inbox')),
        installer: installer,
      );
      late final HubDashboardController controller;
      controller = HubDashboardController(
        libraryStore: libraryStore,
        activityReader: InstalledHubGameActivityReader(
          supportRoot: root,
          launchResolver: launchResolver,
        ).call,
        importer: (package, cancellation, progress) async {
          await installer.install(
            package,
            source: GamePackageInstallSource.localFile,
            cancellationToken: cancellation,
            onProgress: progress,
          );
        },
        editorExportConsumer: inbox.consumePending,
        preferencesStore: HubPreferencesStore(supportRoot: root),
        diagnosticLogFile: File(
          p.join(root.path, 'logs', 'hub-import.log'),
        ),
      );
      late final HubComposition initializedComposition;
      final actions = HubUiActions(
        onImportRequested: () {
          unawaited(initializedComposition._pickAndImport());
        },
      );
      final displayPreferencesController = HubDisplayPreferencesController(
        store: HubDisplayPreferencesStore(supportRoot: root),
        driver: WindowManagerHubDisplayDriver(),
      );
      await displayPreferencesController.initialize();
      final backgroundProcessor = AveluneIsolateBackgroundImageProcessor();
      final appearanceController = AveluneAppearanceController(
        store: AveluneAppearanceStore(supportRoot: root),
        customBackground: AveluneCustomBackgroundImporter(
          picker: const AveluneFilePickerBackgroundPicker(),
          processor: backgroundProcessor,
          storage: AveluneLocalCustomBackgroundStorage(
            supportRoot: root,
            processor: backgroundProcessor,
          ),
        ),
      );
      await appearanceController.initialize();
      initializedComposition = HubComposition._(
        supportRoot: root,
        controller: controller,
        actions: actions,
        launchResolver: launchResolver,
        displayPreferencesController: displayPreferencesController,
        appearanceController: appearanceController,
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

  static Future<Directory> _defaultSupportRoot() async {
    final platformRoot = await getApplicationSupportDirectory();
    return Directory(p.join(platformRoot.path, 'PokeMap'));
  }

  @override
  Widget buildApp() => PokeMapHubApp(
        productName: publicProductName,
        controller: controller,
        actions: actions,
        mobileConsoleExperience: Platform.isAndroid || Platform.isIOS,
        displayPreferencesController: displayPreferencesController,
        appearanceController: appearanceController,
        playerBuilder: (context, game, intent, onHubRequested) =>
            HubInstalledGamePlayer(
          supportRoot: supportRoot,
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
    appearanceController.dispose();
    displayPreferencesController.dispose();
    controller.dispose();
  }
}

Future<void> _loadInstalledProjectSmoke(
  Directory stagedVersionRoot,
  GamePackageManifest manifest,
) async {
  final projectFile = File(
    p.join(stagedVersionRoot.path, 'project', 'project.json'),
  );
  final decoded = jsonDecode(await projectFile.readAsString());
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Installed project manifest is invalid.');
  }
  final project = ProjectManifest.fromJson(decoded);
  final mapId = project.newGame.enabled
      ? project.newGame.startMapId
      : project.maps.firstOrNull?.id;
  if (mapId == null || mapId.trim().isEmpty) {
    throw const FormatException('Installed game has no launchable map.');
  }
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: projectFile.path,
    mapId: mapId,
  );
  if (bundle.manifest.version.name != manifest.compatibility.projectFormat) {
    throw const FormatException('Installed project format changed on load.');
  }
}
