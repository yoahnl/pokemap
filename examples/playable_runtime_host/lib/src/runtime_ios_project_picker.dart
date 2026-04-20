import 'package:flutter/services.dart';

import 'runtime_project_picker.dart';

const MethodChannel _runtimeIosProjectPickerChannel =
    MethodChannel('playable_runtime_host/project_picker');

Future<RuntimeProjectPickResult> pickRuntimeProjectDirectoryOnIos({
  MethodChannel channel = _runtimeIosProjectPickerChannel,
}) async {
  try {
    final projectJsonPath =
        await channel.invokeMethod<String>('pickProjectDirectory');
    if (projectJsonPath == null || projectJsonPath.trim().isEmpty) {
      return const RuntimeProjectPickResult.cancelled();
    }
    return RuntimeProjectPickResult.selected(projectJsonPath.trim());
  } on PlatformException catch (error) {
    if (error.code == 'invalid_selection') {
      return RuntimeProjectPickResult.invalidSelection(
        error.message ?? 'Le dossier sélectionné ne contient pas de project.json.',
      );
    }
    if (error.code == 'cancelled') {
      return const RuntimeProjectPickResult.cancelled();
    }
    return RuntimeProjectPickResult.invalidSelection(
      error.message ?? 'Impossible d’importer le projet iOS sélectionné.',
    );
  }
}
