import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:avelune_studio/features/resources/domain/project_library_editor.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';
import 'package:map_authoring/map_authoring_api.dart' show ContentArtifactRef;
import 'package:map_authoring/map_authoring_local.dart'
    show decodesAsSingleFramePng;
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;

const _maximumLibraryPngBytes = 64 * 1024 * 1024;
const _maximumLibraryPngPixels = _maximumLibraryPngBytes ~/ 4;
const _maximumLibraryGlbBytes = 128 * 1024 * 1024;

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
    final path = result?.files.single.path;
    if (path == null) return null;
    return inspectLibraryFile(path);
  }

  Future<PickedProjectLibraryFile> inspectLibraryFile(String path) =>
      Isolate.run(() => _inspectLibraryFile(path));

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

Future<PickedProjectLibraryFile> _inspectLibraryFile(String path) async {
  final extension = p.extension(path).toLowerCase();
  if (extension != '.png' && extension != '.glb') {
    throw const ResourceFailure('Choisissez un fichier PNG ou GLB.');
  }
  final isPng = extension == '.png';
  final bytes = await _readLibraryFile(
    File(path),
    isPng ? _maximumLibraryPngBytes : _maximumLibraryGlbBytes,
  );
  final name = p.basenameWithoutExtension(path);
  if (isPng) {
    final size = _inspectLibraryPng(bytes);
    return PickedProjectLibraryFile(
      path: path,
      name: name,
      artifact: ContentArtifactRef.fromBytes(bytes, mediaType: 'image/png'),
      imageSize: size,
    );
  }
  try {
    final model = const GlbModel3dInspector().inspect(bytes);
    return PickedProjectLibraryFile(
      path: path,
      name: name,
      artifact: ContentArtifactRef.fromBytes(
        bytes,
        mediaType: 'model/gltf-binary',
      ),
      modelInspection: model,
    );
  } on FormatException {
    throw const ResourceFailure(
      'Ce modèle ne peut pas être lu. Choisissez un fichier GLB 2.0 autonome.',
    );
  }
}

Future<Uint8List> _readLibraryFile(File file, int maximumBytes) async {
  const inaccessible = ResourceFailure(
    'Le fichier choisi est inaccessible. Sélectionnez-le à nouveau.',
  );
  final tooLarge = ResourceFailure(
    'Le fichier dépasse la limite de ${maximumBytes ~/ (1024 * 1024)} Mio.',
  );
  try {
    final metadata = await file.stat();
    if (metadata.type != FileSystemEntityType.file) throw inaccessible;
    if (metadata.size > maximumBytes) throw tooLarge;
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in file.openRead(0, maximumBytes + 1)) {
      if (bytes.length + chunk.length > maximumBytes) throw tooLarge;
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  } on FileSystemException {
    throw inaccessible;
  }
}

LibraryImageSize _inspectLibraryPng(Uint8List bytes) {
  const unreadable = ResourceFailure(
    'Cette image ne peut pas être lue. Choisissez un PNG statique complet.',
  );
  final size = decodeRasterImageDimensions(bytes, mediaType: 'image/png');
  if (size == null) throw unreadable;
  if (size.width > _maximumLibraryPngPixels ~/ size.height) {
    throw const ResourceFailure('Cette image dépasse 64 Mio une fois décodée.');
  }
  if (!decodesAsSingleFramePng(bytes, width: size.width, height: size.height)) {
    throw unreadable;
  }
  return (width: size.width, height: size.height);
}
