import 'package:file_picker/file_picker.dart';

class NativePokemonPngPicker {
  const NativePokemonPngPicker();

  Future<String?> choose() async {
    final selected = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png'],
      allowMultiple: false,
    );
    return selected?.files.single.path;
  }
}
