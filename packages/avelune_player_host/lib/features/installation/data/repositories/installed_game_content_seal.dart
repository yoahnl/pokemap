import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

final class InstalledGameContentSeal {
  InstalledGameContentSeal._(this._stamps);

  static const _magic = 'AVSEAL1';
  static const _fieldsPerFile = 3;

  final Int64List _stamps;

  static File fileFor({
    required String supportRootPath,
    required String gameId,
    required String receiptFileName,
  }) => File(
    p.join(
      supportRootPath,
      'games',
      gameId,
      'content-seals',
      '$receiptFileName.seal',
    ),
  );

  static InstalledGameContentSeal capture(List<File> files) {
    final stamps = Int64List(files.length * _fieldsPerFile);
    for (final (index, file) in files.indexed) {
      final stat = file.statSync();
      final offset = index * _fieldsPerFile;
      stamps[offset] = stat.type == FileSystemEntityType.file ? stat.size : -1;
      stamps[offset + 1] = stat.modified.microsecondsSinceEpoch;
      stamps[offset + 2] = stat.changed.microsecondsSinceEpoch;
    }
    return InstalledGameContentSeal._(stamps);
  }

  static InstalledGameContentSeal? read(File file, {required int fileCount}) {
    try {
      final bytes = file.readAsBytesSync();
      final header = ascii.encode(_magic);
      final expectedLength = header.length + 8 * fileCount * _fieldsPerFile;
      if (bytes.length != expectedLength) return null;
      for (var index = 0; index < header.length; index++) {
        if (bytes[index] != header[index]) return null;
      }
      final view = ByteData.sublistView(bytes, header.length);
      final stamps = Int64List(fileCount * _fieldsPerFile);
      for (var index = 0; index < stamps.length; index++) {
        stamps[index] = view.getInt64(index * 8, Endian.little);
      }
      return InstalledGameContentSeal._(stamps);
    } on Object {
      return null;
    }
  }

  bool matches(InstalledGameContentSeal other, int index) {
    if (other._stamps.length != _stamps.length) return false;
    final offset = index * _fieldsPerFile;
    for (var field = 0; field < _fieldsPerFile; field++) {
      if (_stamps[offset + field] != other._stamps[offset + field]) {
        return false;
      }
    }
    return _stamps[offset] >= 0;
  }

  bool write(File file) {
    final header = ascii.encode(_magic);
    final view = ByteData(_stamps.length * 8);
    for (var index = 0; index < _stamps.length; index++) {
      view.setInt64(index * 8, _stamps[index], Endian.little);
    }
    final temporary = File('${file.path}.tmp-$pid');
    try {
      file.parent.createSync(recursive: true);
      temporary.writeAsBytesSync(
        Uint8List(header.length + view.lengthInBytes)
          ..setAll(0, header)
          ..setAll(header.length, view.buffer.asUint8List()),
        flush: true,
      );
      temporary.renameSync(file.path);
      return true;
    } on FileSystemException {
      if (temporary.existsSync()) temporary.deleteSync();
      return false;
    }
  }
}
