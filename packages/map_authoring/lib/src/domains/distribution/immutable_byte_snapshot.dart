import 'dart:typed_data';

import 'package:map_distribution/map_distribution.dart';

Uint8List immutableByteSnapshot(List<int> bytes, {required String path}) {
  if (bytes is Uint8List) {
    return Uint8List.fromList(bytes).asUnmodifiableView();
  }
  final snapshot = Uint8List(bytes.length);
  for (var index = 0; index < bytes.length; index++) {
    final value = bytes[index];
    if (value < 0 || value > 255) {
      throw GamePackageFormatException(
        code: 'invalidFileBytes',
        path: path,
        message: 'Payload values must be bytes.',
      );
    }
    snapshot[index] = value;
  }
  return snapshot.asUnmodifiableView();
}
