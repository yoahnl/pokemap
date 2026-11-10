import '../domain/resource_image_picker.dart';
import '../domain/resource_port.dart';

class ResourceImageImportDraft {
  ResourceImageImportDraft({
    required this.image,
    required int tileWidth,
    required int tileHeight,
    Set<String> existingNames = const {},
  }) : name = image.name,
       width = '$tileWidth',
       height = '$tileHeight',
       takenNames = {
         for (final value in existingNames) value.trim().toLowerCase(),
       };

  final PickedResourceImage image;
  final Set<String> takenNames;
  String name, width, height;
  bool? decoded;
  bool _closed = false;
  int _sequence = 0;

  int get cellWidth => int.tryParse(width) ?? 0;
  int get cellHeight => int.tryParse(height) ?? 0;
  int get restWidth => cellWidth > 0 ? image.width % cellWidth : 0;
  int get restHeight => cellHeight > 0 ? image.height % cellHeight : 0;
  bool get nameTaken => takenNames.contains(name.trim().toLowerCase());
  bool get valid =>
      !_closed &&
      decoded == true &&
      name.trim().isNotEmpty &&
      cellWidth > 0 &&
      cellHeight > 0 &&
      cellWidth <= image.width &&
      cellHeight <= image.height &&
      restWidth == 0 &&
      restHeight == 0;

  Future<void> verify(
    Future<bool> Function(PickedResourceImage) verifyContent,
  ) async {
    if (_closed) return;
    final sequence = ++_sequence;
    decoded = null;
    var result = false;
    try {
      result = await verifyContent(image);
    } on Object {
      result = false;
    }
    if (!_closed && sequence == _sequence) decoded = result;
  }

  ResourceImageImport? build() => valid
      ? ResourceImageImport(
          sourcePath: image.path,
          name: name.trim(),
          tileWidth: cellWidth,
          tileHeight: cellHeight,
        )
      : null;

  void dispose() {
    _closed = true;
    _sequence++;
  }
}
