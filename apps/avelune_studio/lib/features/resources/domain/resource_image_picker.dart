import 'dart:typed_data';

class PickedResourceImage {
  const PickedResourceImage(
    this.path,
    this.name,
    this.bytes,
    this.width,
    this.height,
  );
  final String path;
  final String name;
  final Uint8List bytes;
  final int width;
  final int height;
}

typedef PickResourceImage = Future<PickedResourceImage?> Function();

enum ResourceImportIntent { source, decor, terrain }
