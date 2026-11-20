import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:avelune_studio/features/resources/domain/project_library_editor.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';

class NativeResourceImagePicker {
  const NativeResourceImagePicker();
  Future<PickedResourceImage?> choose() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png'],
      dialogTitle: 'Importer une image PNG',
      lockParentWindow: true,
    );
    final selection = result?.files.single;
    final path = selection?.path;
    if (path == null) return null;
    final file = File(path);
    await _checkLength(file);
    final bytes = await file.readAsBytes();
    final size = _pngSize(bytes);
    return PickedResourceImage(
      path,
      _stem(selection!.name),
      bytes,
      size.width,
      size.height,
    );
  }

  Future<PickedProjectLibraryFile?> chooseLibraryFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'glb'],
      dialogTitle: 'Importer une ressource PNG ou GLB',
      lockParentWindow: true,
    );
    final selection = result?.files.single;
    final path = selection?.path;
    if (path == null) return null;
    if (path.toLowerCase().endsWith('.glb')) {
      return PickedProjectLibraryFile(path: path, name: _stem(selection!.name));
    }
    final file = File(path);
    await _checkLength(file);
    final input = await file.open();
    try {
      return PickedProjectLibraryFile(
        path: path,
        name: _stem(selection!.name),
        imageSize: _pngSize(await input.read(24)),
      );
    } finally {
      await input.close();
    }
  }

  static String _stem(String name) =>
      name.replaceFirst(RegExp(r'\.(png|glb)$', caseSensitive: false), '');

  static Future<void> _checkLength(File file) async {
    if (await file.length() > 64 * 1024 * 1024) {
      throw const ResourceFailure(
        'Cette image dépasse la limite de 64 Mio encodés de l’import.',
      );
    }
  }

  static LibraryImageSize _pngSize(Uint8List bytes) {
    if (bytes.length < 24 ||
        bytes[0] != 137 ||
        bytes[1] != 80 ||
        bytes[2] != 78 ||
        bytes[3] != 71) {
      throw const ResourceFailure('Choisissez une image PNG valide.');
    }
    final data = ByteData.sublistView(bytes);
    final width = data.getUint32(16);
    final height = data.getUint32(20);
    if (width <= 0 || height <= 0 || width * height * 4 > 64 * 1024 * 1024) {
      throw const ResourceFailure(
        'L’aperçu d’import est limité à 64 Mio décodés. Les grandes ressources déjà présentes restent accessibles dans la bibliothèque selon le budget disponible.',
      );
    }
    return (width: width, height: height);
  }
}
