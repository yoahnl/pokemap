import 'dart:io';

import 'package:flutter/services.dart';

import 'package:pokemap_hub/core/ports/hub_platform_port.dart';

typedef AndroidPackageFilePicker = Future<String?> Function();
typedef AndroidDiskBytesReader = Future<num?> Function();

const _androidChannel = MethodChannel('com.yoahnl.avelune.player/android');

Future<String?> _pickAndroidPackage() {
  return _androidChannel.invokeMethod<String>('pickPackage');
}

Future<num?> _readAndroidDiskBytes() {
  return _androidChannel.invokeMethod<num>('availableDiskBytes');
}

/// Android integration for package selection and storage capacity.
final class AndroidHubPlatformAdapter implements HubPlatformAdapter {
  AndroidHubPlatformAdapter({
    AndroidPackageFilePicker? pickFile,
    AndroidDiskBytesReader? readAvailableDiskBytes,
  })  : _pickFile = pickFile ?? _pickAndroidPackage,
        _readAvailableDiskBytes =
            readAvailableDiskBytes ?? _readAndroidDiskBytes;

  final AndroidPackageFilePicker _pickFile;
  final AndroidDiskBytesReader _readAvailableDiskBytes;

  @override
  Future<void> attachPackageOpenHandler(HubPackageOpenHandler handler) async {
    // Direct Android intent imports are outside the V0 contract.
    // Imports are initiated from the system file selector.
  }

  @override
  Future<String?> pickPackage() async {
    try {
      return await _pickFile();
    } on Object catch (error) {
      throw HubPackagePickerFailure(
        code: 'importPicker.openFailed',
        message: 'Le sélecteur de fichiers n’a pas pu être ouvert.',
        recommendation:
            'Fermez complètement Avelune, relancez-la puis réessayez.',
        cause: error,
      );
    }
  }

  @override
  Future<int> availableDiskBytes(Directory supportRoot) async {
    await supportRoot.create(recursive: true);
    final bytes = (await _readAvailableDiskBytes())?.toInt();
    if (bytes == null || bytes < 0) {
      throw const FileSystemException(
        'Available Android storage capacity is invalid.',
      );
    }
    return bytes;
  }

  @override
  void dispose() {}
}
