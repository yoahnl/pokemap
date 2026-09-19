import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/resource_image_import.dart';

class NativeResourceImagePicker {
  const NativeResourceImagePicker();
  Future<PickedResourceImage?> choose() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png'],
      dialogTitle: 'Importer une image PNG',
      lockParentWindow: true,
    );
    final path = result?.files.single.path;
    if (path == null) return null;
    final file = File(path);
    if (await file.length() > 64 * 1024 * 1024) {
      throw const ResourceFailure(
        'Cette image dépasse la limite de 64 Mio encodés de l’import.',
      );
    }
    final bytes = await file.readAsBytes();
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
    final name = result!.files.single.name.replaceFirst(
      RegExp(r'\.png$', caseSensitive: false),
      '',
    );
    return PickedResourceImage(path, name, bytes, width, height);
  }
}
