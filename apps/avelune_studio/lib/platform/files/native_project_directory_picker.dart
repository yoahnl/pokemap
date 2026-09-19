import 'package:file_picker/file_picker.dart';

class NativeProjectDirectoryPicker {
  const NativeProjectDirectoryPicker();

  Future<String?> choose() => FilePicker.getDirectoryPath(
    dialogTitle: 'Ouvrir un projet Avelune Studio',
    lockParentWindow: true,
  );
}
