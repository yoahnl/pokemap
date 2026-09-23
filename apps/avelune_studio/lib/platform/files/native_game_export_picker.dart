import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../../features/game_export/domain/studio_game_export_port.dart';

Future<StudioGameExportDestination?> pickNativeGameExportFile(
  String suggestedName,
) async {
  final path = await FilePicker.saveFile(
    dialogTitle: 'Exporter le jeu Avelune',
    fileName: suggestedName,
    type: FileType.custom,
    allowedExtensions: ['avelunegame'],
    lockParentWindow: true,
  );
  return path == null
      ? null
      : StudioGameExportDestination(path, exists: await File(path).exists());
}
