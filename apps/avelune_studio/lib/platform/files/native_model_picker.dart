import 'package:file_picker/file_picker.dart';

import '../../features/resources/domain/model_source_picker.dart';
export '../../features/resources/domain/model_source_picker.dart';

Future<PickedModelSource?> pickNativeModel() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['glb'],
    dialogTitle: 'Importer un modèle 3D GLB',
    lockParentWindow: true,
  );
  final file = result?.files.single;
  if (file?.path == null) return null;
  return PickedModelSource(
    file!.path!,
    file.name.replaceFirst(RegExp(r'\.glb$', caseSensitive: false), ''),
  );
}
