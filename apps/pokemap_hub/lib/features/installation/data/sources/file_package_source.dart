import 'dart:io';
import 'dart:typed_data';

import 'package:map_distribution/map_distribution.dart';

final class FilePackageSource implements RandomAccessPackageSource {
  FilePackageSource._(this._file, this._handle, this.length);

  final File _file;
  final RandomAccessFile _handle;

  @override
  final int length;

  static Future<FilePackageSource> open(File file) async {
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type != FileSystemEntityType.file) {
      throw const FileSystemException(
        'Package source must be a regular file.',
      );
    }
    final handle = await file.open(mode: FileMode.read);
    return FilePackageSource._(file, handle, await handle.length());
  }

  @override
  Uint8List readAtSync(int offset, int length) {
    if (offset < 0 || length < 0 || offset + length > this.length) {
      throw RangeError.range(offset, 0, this.length, 'offset');
    }
    _handle.setPositionSync(offset);
    final bytes = _handle.readSync(length);
    if (bytes.length != length) {
      throw FileSystemException(
        'Package source changed during bounded read.',
        _file.path,
      );
    }
    return bytes;
  }

  Future<void> close() => _handle.close();
}
