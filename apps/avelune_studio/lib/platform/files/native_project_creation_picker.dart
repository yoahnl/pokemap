import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

class NativeProjectCreationPicker {
  const NativeProjectCreationPicker({
    MethodChannel channel = const MethodChannel('map_editor/file_access'),
  }) : _channel = channel;
  final MethodChannel _channel;

  Future<String?> choose() => Platform.isMacOS
      ? _channel.invokeMethod<String>('chooseProjectCreationParent')
      : FilePicker.getDirectoryPath(
          dialogTitle: 'Choisir le dossier parent du nouveau projet',
          lockParentWindow: true,
        );

  Future<void> release() async {
    if (Platform.isMacOS) {
      await _channel.invokeMethod<void>('releaseProjectCreationParent');
    }
  }
}
