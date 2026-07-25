import 'dart:io';

import 'package:flutter/services.dart';

import 'hub_platform_adapter.dart';

/// iOS integration for document picking and storage capacity.
final class IOSHubPlatformAdapter implements HubPlatformAdapter {
  static const MethodChannel _channel = MethodChannel('app.pokemap.hub/ios');

  @override
  Future<void> attachPackageOpenHandler(HubPackageOpenHandler handler) async {
    // Direct document-open events are not part of the iOS V0 contract.
    // Imports are initiated through the native document picker.
  }

  @override
  Future<String?> pickPackage() => _channel.invokeMethod<String>('pickPackage');

  @override
  Future<int> availableDiskBytes(Directory supportRoot) async {
    await supportRoot.create(recursive: true);
    final available = await _channel.invokeMethod<num>('availableDiskBytes');
    final bytes = available?.toInt();
    if (bytes == null || bytes < 0) {
      throw const FileSystemException(
        'Available iOS storage capacity is invalid.',
      );
    }
    return bytes;
  }

  @override
  void dispose() {}
}
