import 'package:file_picker/file_picker.dart';

class NativeResourcePackPicker {
  const NativeResourcePackPicker();
  Future<List<String>?> chooseLicenseDocuments() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      allowMultiple: true,
      dialogTitle: 'Ajouter des documents de licence UTF-8',
      lockParentWindow: true,
      withData: false,
    );
    return result == null
        ? null
        : [
            for (final file in result.files)
              if (file.path != null) file.path!,
          ];
  }

  Future<String?> choose() async => (await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['aveluneassets'],
    dialogTitle: 'Importer un pack de ressources',
    lockParentWindow: true,
    withData: false,
  ))?.files.single.path;
}
