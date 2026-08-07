import 'dart:io';

import 'package:flutter/services.dart';

import 'package:pokemap_hub/core/ports/hub_platform_port.dart';
import 'package:pokemap_hub/core/error/hub_failure.dart';

/// macOS platform integration for open events, picking, and disk space.
final class MacOSHubPlatformAdapter implements HubPlatformAdapter {
  static const MethodChannel _packageOpenChannel =
      MethodChannel('app.pokemap.hub/package_open');

  @override
  Future<void> attachPackageOpenHandler(HubPackageOpenHandler handler) async {
    _packageOpenChannel.setMethodCallHandler((call) async {
      if (call.method != 'openPackages') {
        throw MissingPluginException('Unknown package-open method.');
      }
      final paths = call.arguments;
      if (paths is! List<Object?>) {
        throw const FormatException('Package-open payload is invalid.');
      }
      for (final selectedPath in paths.whereType<String>()) {
        await handler(File(selectedPath));
      }
    });
    await _packageOpenChannel.invokeMethod<void>('ready');
  }

  @override
  Future<String?> pickPackage() async {
    final canSelectPackages =
        await _packageOpenChannel.invokeMethod<bool>('canSelectPackages') ??
            false;
    if (!canSelectPackages) {
      throw HubPackagePickerFailure(
        code: 'importPicker.missingEntitlement',
        message: 'Le sélecteur de fichiers ne peut pas s’ouvrir.',
        recommendation:
            'Fermez complètement le Hub puis relancez une build signée avec '
            'l’autorisation de lire les fichiers sélectionnés.',
        cause: StateError(
          'Missing com.apple.security.files.user-selected.read-only '
          'entitlement.',
        ),
      );
    }
    return _packageOpenChannel.invokeMethod<String>('pickPackage');
  }

  @override
  Future<int> availableDiskBytes(Directory supportRoot) async {
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

  @override
  void dispose() {
    _packageOpenChannel.setMethodCallHandler(null);
  }
}
