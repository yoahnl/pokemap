import 'package:file_picker/file_picker.dart';

class NativeResourcePackPicker {
  const NativeResourcePackPicker();
  Future<String?> choose() async => (await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['aveluneassets'],
    dialogTitle: 'Importer un pack de ressources',
    lockParentWindow: true,
    withData: false,
  ))?.files.single.path;
}
