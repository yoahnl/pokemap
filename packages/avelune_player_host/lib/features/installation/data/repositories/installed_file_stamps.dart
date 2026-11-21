import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

const installedFileStampFields = 3;

Int64List readInstalledFileStamps(List<File> files) =>
    readInstalledFileStampsInBulk(files) ?? statInstalledFileStamps(files);

Int64List statInstalledFileStamps(List<File> files) {
  final stamps = Int64List(files.length * installedFileStampFields);
  for (final (index, file) in files.indexed) {
    final stat = file.statSync();
    final offset = index * installedFileStampFields;
    stamps[offset] = stat.type == FileSystemEntityType.file ? stat.size : -1;
    stamps[offset + 1] = stat.modified.microsecondsSinceEpoch;
    stamps[offset + 2] = stat.changed.microsecondsSinceEpoch;
  }
  return stamps;
}

Int64List? readInstalledFileStampsInBulk(List<File> files) {
  if (!Platform.isIOS && !Platform.isMacOS) return null;
  final _DarwinDirectoryReader reader;
  try {
    reader = _DarwinDirectoryReader();
  } on Object {
    return null;
  }
  try {
    final byDirectory = <String, List<int>>{};
    for (final (index, file) in files.indexed) {
      final path = file.path;
      final slash = path.lastIndexOf('/');
      if (slash <= 0 || slash == path.length - 1) return null;
      (byDirectory[path.substring(0, slash)] ??= <int>[]).add(index);
    }
    final stamps = Int64List(files.length * installedFileStampFields);
    for (var index = 0; index < files.length; index++) {
      stamps[index * installedFileStampFields] = -1;
    }
    for (final MapEntry(key: directory, value: indexes)
        in byDirectory.entries) {
      final entries = reader.read(directory);
      if (entries == null) continue;
      for (final index in indexes) {
        final path = files[index].path;
        final found = entries[path.substring(path.lastIndexOf('/') + 1)];
        if (found == null) continue;
        stamps.setRange(
          index * installedFileStampFields,
          (index + 1) * installedFileStampFields,
          found,
        );
      }
    }
    return stamps;
  } on _BulkReadFailure {
    return null;
  } finally {
    reader.dispose();
  }
}

final class _BulkReadFailure implements Exception {
  const _BulkReadFailure();
}

typedef _OpenNative = Int32 Function(Pointer<Uint8>, Int32);
typedef _Open = int Function(Pointer<Uint8>, int);
typedef _CloseNative = Int32 Function(Int32);
typedef _Close = int Function(int);
typedef _BulkNative = Int32 Function(
  Int32,
  Pointer<Uint8>,
  Pointer<Uint8>,
  Size,
  Uint64,
);
typedef _Bulk = int Function(int, Pointer<Uint8>, Pointer<Uint8>, int, int);
typedef _MallocNative = Pointer<Uint8> Function(Size);
typedef _Malloc = Pointer<Uint8> Function(int);
typedef _FreeNative = Void Function(Pointer<Uint8>);
typedef _Free = void Function(Pointer<Uint8>);

final class _DarwinDirectoryReader {
  _DarwinDirectoryReader() {
    final process = DynamicLibrary.process();
    _open = process.lookupFunction<_OpenNative, _Open>('open');
    _close = process.lookupFunction<_CloseNative, _Close>('close');
    _bulk = process.lookupFunction<_BulkNative, _Bulk>('getattrlistbulk');
    _malloc = process.lookupFunction<_MallocNative, _Malloc>('malloc');
    _free = process.lookupFunction<_FreeNative, _Free>('free');
    _attributes = _malloc(_attributeListLength);
    _buffer = _malloc(_bufferLength);
    if (_attributes.address == 0 || _buffer.address == 0) {
      dispose();
      throw const _BulkReadFailure();
    }
    final list = _attributes.asTypedList(_attributeListLength)
      ..fillRange(0, _attributeListLength, 0);
    ByteData.sublistView(list)
      ..setUint16(0, 5, Endian.host)
      ..setUint32(4, _commonAttributes, Endian.host)
      ..setUint32(16, _fileDataLength, Endian.host);
  }

  static const _attributeListLength = 24;
  static const _bufferLength = 256 * 1024;
  static const _commonAttributes = 0x80000000 | 0x1 | 0x8 | 0x400 | 0x800;
  static const _fileDataLength = 0x200;
  static const _directoryOnly = 0x100000;
  static const _regularFile = 1;

  late final _Open _open;
  late final _Close _close;
  late final _Bulk _bulk;
  late final _Malloc _malloc;
  late final _Free _free;
  late final Pointer<Uint8> _attributes;
  late final Pointer<Uint8> _buffer;

  Map<String, Int64List>? read(String directory) {
    final encoded = utf8.encode(directory);
    final path = _malloc(encoded.length + 1);
    if (path.address == 0) throw const _BulkReadFailure();
    path.asTypedList(encoded.length + 1)
      ..setAll(0, encoded)
      ..[encoded.length] = 0;
    final descriptor = _open(path, _directoryOnly);
    _free(path);
    if (descriptor < 0) return null;
    try {
      final entries = <String, Int64List>{};
      final data = _buffer.asTypedList(_bufferLength);
      final bytes = ByteData.sublistView(data);
      while (true) {
        final count = _bulk(descriptor, _attributes, _buffer, _bufferLength, 0);
        if (count < 0) throw const _BulkReadFailure();
        if (count == 0) return entries;
        var entry = 0;
        for (var index = 0; index < count; index++) {
          final length = bytes.getUint32(entry, Endian.host);
          if (bytes.getUint32(entry + 4, Endian.host) != _commonAttributes) {
            throw const _BulkReadFailure();
          }
          final fileAttributes = bytes.getUint32(entry + 16, Endian.host);
          final nameOffset = bytes.getInt32(entry + 24, Endian.host);
          final nameLength = bytes.getUint32(entry + 28, Endian.host);
          final nameStart = entry + 24 + nameOffset;
          final name = utf8.decode(
            data.sublist(nameStart, nameStart + nameLength - 1),
          );
          final type = bytes.getUint32(entry + 32, Endian.host);
          entries[name] = Int64List.fromList([
            type == _regularFile && fileAttributes & _fileDataLength != 0
                ? bytes.getInt64(entry + 68, Endian.host)
                : -1,
            _micros(bytes, entry + 36),
            _micros(bytes, entry + 52),
          ]);
          entry += length;
        }
      }
    } finally {
      _close(descriptor);
    }
  }

  static int _micros(ByteData bytes, int offset) =>
      bytes.getInt64(offset, Endian.host) * 1000000 +
      bytes.getInt64(offset + 8, Endian.host) ~/ 1000;

  void dispose() {
    if (_attributes.address != 0) _free(_attributes);
    if (_buffer.address != 0) _free(_buffer);
  }
}
