import 'package:file_picker/file_picker.dart';
import 'package:map_core/map_core_domain.dart';

class NativePresentationMediaPicker {
  const NativePresentationMediaPicker();
  Future<({String path, String label})?> choose(ProjectMediaKind kind) async {
    final extensions = kind == ProjectMediaKind.audio
        ? ['mp3', 'wav', 'ogg', 'm4a']
        : kind == ProjectMediaKind.video
        ? ['mp4', 'mov', 'webm']
        : kind == ProjectMediaKind.captions
        ? ['vtt']
        : ['png', 'jpg', 'jpeg', 'webp'];
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      allowMultiple: false,
    );
    final file = result?.files.single;
    if (file?.path == null) return null;
    return (path: file!.path!, label: file.name);
  }
}
