import 'package:file_picker/file_picker.dart';

final class SmartTilePickedSourceImage {
  const SmartTilePickedSourceImage({
    required this.path,
    required this.displayName,
  });

  final String path;
  final String displayName;
}

abstract interface class SmartTileSourceImagePicker {
  Future<SmartTilePickedSourceImage?> pick();
}

final class FilePickerSmartTileSourceImagePicker
    implements SmartTileSourceImagePicker {
  const FilePickerSmartTileSourceImagePicker();

  @override
  Future<SmartTilePickedSourceImage?> pick() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );
    final file = result?.files.singleOrNull;
    final path = file?.path;
    if (file == null || path == null || path.trim().isEmpty) return null;
    return SmartTilePickedSourceImage(
      path: path,
      displayName: file.name,
    );
  }
}

extension<T> on Iterable<T> {
  T? get singleOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    final value = iterator.current;
    return iterator.moveNext() ? null : value;
  }
}
