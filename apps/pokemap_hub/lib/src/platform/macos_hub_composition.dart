import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../pokemap_hub_ui.dart';

/// macOS composition root for the player product.
///
/// Updates deliberately fail closed until the Phase 8 save-update transaction
/// coordinator can durably couple a migration batch to installer recovery.
final class MacOSHubComposition {
  MacOSHubComposition._({
    required this.supportRoot,
    required this.controller,
    required this.actions,
  });

  final Directory supportRoot;
  final HubDashboardController controller;
  final HubUiActions actions;
  static const MethodChannel _packageOpenChannel =
      MethodChannel('app.pokemap.hub/package_open');

  static Future<MacOSHubComposition> create() async {
    final platformRoot = await getApplicationSupportDirectory();
    final supportRoot = Directory(p.join(platformRoot.path, 'PokeMap'));
    await supportRoot.create(recursive: true);
    final hostCompatibility = _hostCompatibility();
    late final GamePackageInstaller installer;
    installer = GamePackageInstaller(
      supportRoot: supportRoot,
      inspector: GamePackageInspector(
        hostCompatibility: hostCompatibility,
      ),
      availableDiskBytes: _availableDiskBytes,
      loadSmoke: _loadInstalledProjectSmoke,
      prepareSavesForUpdate: (_, __) {
        throw UnsupportedError(
          'Updates remain disabled until save migration transactions '
          'are recoverable.',
        );
      },
    );
    final libraryStore = GameLibraryStore(supportRoot: supportRoot);
    final launchResolver = InstalledGameLaunchResolver(
      supportRoot: supportRoot,
      hostCompatibility: hostCompatibility,
    );
    final inbox = EditorExportInstallInbox.fromInstaller(
      inbox: Directory(p.join(supportRoot.path, 'install-inbox')),
      installer: installer,
    );
    late final HubDashboardController controller;
    controller = HubDashboardController(
      libraryStore: libraryStore,
      activityReader: InstalledHubGameActivityReader(
        supportRoot: supportRoot,
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
      preferencesStore: HubPreferencesStore(supportRoot: supportRoot),
    );
    final actions = HubUiActions(
      onImportRequested: () {
        unawaited(_pickAndImport(controller));
      },
    );
    final composition = MacOSHubComposition._(
      supportRoot: supportRoot,
      controller: controller,
      actions: actions,
    );
    await composition._attachPackageOpenBridge();
    return composition;
  }

  Widget buildApp() => PokeMapHubApp(
        controller: controller,
        actions: actions,
      );

  Future<void> _attachPackageOpenBridge() async {
    _packageOpenChannel.setMethodCallHandler((call) async {
      if (call.method != 'openPackages') {
        throw MissingPluginException('Unknown package-open method.');
      }
      final paths = call.arguments;
      if (paths is! List<Object?>) {
        throw const FormatException('Package-open payload is invalid.');
      }
      for (final path in paths.whereType<String>()) {
        final package = File(path);
        if (p.extension(package.path).toLowerCase() != '.pokemapgame' ||
            !await package.exists()) {
          continue;
        }
        await controller.importPackage(package);
      }
    });
    await _packageOpenChannel.invokeMethod<void>('ready');
  }

  void dispose() {
    _packageOpenChannel.setMethodCallHandler(null);
    controller.dispose();
  }
}

GamePackageHostCompatibility _hostCompatibility() =>
    GamePackageHostCompatibility(
      hubVersion: Version.parse('0.1.0'),
      runtimeApiVersion: Version.parse('1.4.0'),
      capabilities: const <String>{
        'dialogue.choices@1',
        'overworld.menu@1',
        'world.shop@1',
      },
      supportedProjectFormats: const <String>{'v1', 'v2'},
      currentProjectFormat: 'v2',
      supportedSaveFormats: const <int>{1},
    );

Future<void> _pickAndImport(HubDashboardController controller) async {
  final result = await FilePicker.platform.pickFiles(
    dialogTitle: 'Importer un jeu PokeMap',
    allowMultiple: false,
    allowedExtensions: const <String>['pokemapgame'],
    type: FileType.custom,
    lockParentWindow: true,
  );
  final path = result?.files.single.path;
  if (path == null) return;
  await controller.importPackage(File(path));
}

Future<int> _availableDiskBytes(Directory supportRoot) async {
  await supportRoot.create(recursive: true);
  final result = await Process.run(
    '/bin/df',
    <String>['-Pk', supportRoot.path],
  );
  if (result.exitCode != 0) {
    throw const FileSystemException('Available disk space is unavailable.');
  }
  final lines = (result.stdout as String)
      .trim()
      .split('\n')
      .where((line) => line.trim().isNotEmpty)
      .toList(growable: false);
  if (lines.length < 2) {
    throw const FileSystemException('Available disk space is invalid.');
  }
  final columns = lines.last.trim().split(RegExp(r'\s+'));
  if (columns.length < 4) {
    throw const FileSystemException('Available disk space is invalid.');
  }
  final availableKilobytes = int.tryParse(columns[3]);
  if (availableKilobytes == null || availableKilobytes < 0) {
    throw const FileSystemException('Available disk space is invalid.');
  }
  return availableKilobytes * 1024;
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
