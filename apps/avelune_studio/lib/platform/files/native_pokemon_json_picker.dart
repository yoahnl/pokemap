import 'package:file_picker/file_picker.dart';

class NativePokemonJsonPicker {
  const NativePokemonJsonPicker();

  Future<String?> choose() async {
    final selected = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      allowMultiple: false,
    );
    return selected?.files.single.path;
  }
}
