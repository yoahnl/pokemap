import 'dart:convert';
import 'dart:typed_data';

import 'game_package_format_exception.dart';
import 'game_package_security_policy.dart';
import 'package_path_policy.dart';
import 'random_access_package_source.dart';

final class RandomAccessZipStructureEntry {
  const RandomAccessZipStructureEntry({
    required this.name,
    required this.crc32,
    required this.size,
    required this.dataOffset,
  });

  final String name;
  final int crc32;
  final int size;
  final int dataOffset;
}

final class RandomAccessZipStructure {
  RandomAccessZipStructure(List<RandomAccessZipStructureEntry> entries)
      : entries = List.unmodifiable(entries);

  final List<RandomAccessZipStructureEntry> entries;
}

/// Random-access ZIP preflight that never loads payload regions as a whole.
final class RandomAccessZipStructureReader {
  const RandomAccessZipStructureReader(this.policy);

  final GamePackageSecurityPolicy policy;

  RandomAccessZipStructure read(RandomAccessPackageSource source) {
    try {
      return _readChecked(source, source.length);
    } on GamePackageFormatException {
      rethrow;
    } on Object {
      _fail(
        'invalidZipStructure',
        r'$',
        'Malformed or truncated ZIP structure.',
      );
    }
  }

  RandomAccessZipStructure _readChecked(
    RandomAccessPackageSource source,
    int fileLength,
  ) {
    if (fileLength < 22) {
      _fail('invalidZipStructure', r'$', 'ZIP is shorter than its footer.');
    }
    final tailLength = fileLength < 65557 ? fileLength : 65557;
    final tailOffset = fileLength - tailLength;
    final tail = _readAt(source, tailOffset, tailLength);
    var eocdRelative = -1;
    for (var offset = tail.length - 22; offset >= 0; offset--) {
      if (_u32(tail, offset) == 0x06054b50) {
        eocdRelative = offset;
        break;
      }
    }
    if (eocdRelative < 0) {
      _fail('invalidZipStructure', r'$', 'ZIP footer is missing.');
    }
    final eocdOffset = tailOffset + eocdRelative;
    final diskNumber = _u16(tail, eocdRelative + 4);
    final centralDisk = _u16(tail, eocdRelative + 6);
    final diskEntries = _u16(tail, eocdRelative + 8);
    final entryCount = _u16(tail, eocdRelative + 10);
    final centralSize = _u32(tail, eocdRelative + 12);
    final centralOffset = _u32(tail, eocdRelative + 16);
    final commentLength = _u16(tail, eocdRelative + 20);
    if (diskNumber != 0 ||
        centralDisk != 0 ||
        diskEntries != entryCount ||
        entryCount == 0xffff ||
        centralSize == 0xffffffff ||
        centralOffset == 0xffffffff ||
        commentLength != 0 ||
        eocdOffset + 22 != fileLength) {
      _fail(
        'unsupportedZipFeature',
        r'$',
        'Multi-disk, ZIP64, or archive comments are not supported.',
      );
    }
    if (entryCount > policy.maxPayloadEntries + 1) {
      _fail(
        'entryCountExceeded',
        r'$',
        'ZIP payload entry count exceeds policy.',
      );
    }
    final maximumCentralSize =
        entryCount * (46 + PackagePathPolicy.maxUtf8Bytes);
    if (centralSize < entryCount * 46 ||
        centralSize > maximumCentralSize ||
        centralOffset + centralSize != eocdOffset) {
      _fail(
        'invalidZipStructure',
        r'$',
        'Central directory bounds are inconsistent.',
      );
    }
    final central = _readAt(source, centralOffset, centralSize);
    final entries = <RandomAccessZipStructureEntry>[];
    final exactNames = <String>{};
    final collisionKeys = <String>{};
    var cursor = 0;
    var expectedLocalOffset = 0;
    String? previousName;
    for (var index = 0; index < entryCount; index++) {
      if (_u32(central, cursor) != 0x02014b50) {
        _fail(
          'invalidZipStructure',
          r'$',
          'Invalid central directory entry.',
        );
      }
      final versionMadeBy = _u16(central, cursor + 4);
      final versionNeeded = _u16(central, cursor + 6);
      final flags = _u16(central, cursor + 8);
      final compression = _u16(central, cursor + 10);
      final modifiedTime = _u16(central, cursor + 12);
      final modifiedDate = _u16(central, cursor + 14);
      final crc32 = _u32(central, cursor + 16);
      final compressedSize = _u32(central, cursor + 20);
      final uncompressedSize = _u32(central, cursor + 24);
      final nameLength = _u16(central, cursor + 28);
      final extraLength = _u16(central, cursor + 30);
      final entryCommentLength = _u16(central, cursor + 32);
      final startDisk = _u16(central, cursor + 34);
      final internalAttributes = _u16(central, cursor + 36);
      final externalAttributes = _u32(central, cursor + 38);
      final localOffset = _u32(central, cursor + 42);
      final recordEnd =
          cursor + 46 + nameLength + extraLength + entryCommentLength;
      if (recordEnd > central.length) {
        _fail(
          'invalidZipStructure',
          r'$',
          'Central directory entry exceeds its region.',
        );
      }
      final name = _decodeName(
        central.sublist(cursor + 46, cursor + 46 + nameLength),
      );
      if (!exactNames.add(name)) {
        _fail('duplicateEntry', name, 'Duplicate ZIP entry.');
      }
      if (!collisionKeys.add(PackagePathPolicy.collisionKey(name))) {
        _fail('pathCollision', name, 'Colliding ZIP entry names.');
      }
      _validateName(name);
      if (previousName != null &&
          PackagePathPolicy.compareUtf8(previousName, name) >= 0) {
        _fail(
          'invalidZipStructure',
          name,
          'ZIP entries are not in canonical UTF-8 order.',
        );
      }
      previousName = name;
      if (extraLength != 0) {
        _fail(
          'unsupportedEntryType',
          name,
          'ZIP extra fields may encode links and are forbidden.',
        );
      }
      final mode = externalAttributes >> 16;
      if ((mode & 0xf000) != 0x8000) {
        _fail(
          'unsupportedEntryType',
          name,
          'Only regular ZIP files are accepted.',
        );
      }
      if (externalAttributes != 0x81a40000) {
        _fail(
          mode & 0x49 != 0 ? 'executableContent' : 'unsupportedZipFeature',
          name,
          'ZIP entry permissions are outside the format-v1 profile.',
        );
      }
      if (versionMadeBy != 0x0314 ||
          versionNeeded != 20 ||
          flags != 0x0800 ||
          compression != 0 ||
          modifiedTime != 0 ||
          modifiedDate != 33 ||
          entryCommentLength != 0 ||
          startDisk != 0 ||
          internalAttributes != 0 ||
          compressedSize != uncompressedSize) {
        _fail(
          'unsupportedZipFeature',
          name,
          'ZIP entry metadata is outside the format-v1 profile.',
        );
      }
      if (localOffset != expectedLocalOffset) {
        _fail(
          'invalidZipStructure',
          name,
          'ZIP local regions overlap, alias, or contain gaps.',
        );
      }
      final local = _readLocal(
        source,
        localOffset,
        expectedName: name,
        expectedFlags: flags,
        expectedCompression: compression,
        expectedTime: modifiedTime,
        expectedDate: modifiedDate,
        expectedCrc32: crc32,
        expectedSize: compressedSize,
      );
      expectedLocalOffset = local.endOffset;
      entries.add(
        RandomAccessZipStructureEntry(
          name: name,
          crc32: crc32,
          size: uncompressedSize,
          dataOffset: local.dataOffset,
        ),
      );
      cursor = recordEnd;
    }
    if (cursor != central.length ||
        expectedLocalOffset != centralOffset ||
        entries.length != entryCount) {
      _fail(
        'invalidZipStructure',
        r'$',
        'ZIP regions do not form one canonical contiguous archive.',
      );
    }
    return RandomAccessZipStructure(entries);
  }

  ({int dataOffset, int endOffset}) _readLocal(
    RandomAccessPackageSource source,
    int offset, {
    required String expectedName,
    required int expectedFlags,
    required int expectedCompression,
    required int expectedTime,
    required int expectedDate,
    required int expectedCrc32,
    required int expectedSize,
  }) {
    final header = _readAt(source, offset, 30);
    if (_u32(header, 0) != 0x04034b50) {
      _fail(
        'invalidZipStructure',
        expectedName,
        'Invalid local ZIP entry.',
      );
    }
    final nameLength = _u16(header, 26);
    final extraLength = _u16(header, 28);
    if (nameLength > PackagePathPolicy.maxUtf8Bytes || extraLength != 0) {
      _fail(
        'unsupportedZipFeature',
        expectedName,
        'Invalid local ZIP name or extra field.',
      );
    }
    final name = _decodeName(_readAt(source, offset + 30, nameLength));
    final dataOffset = offset + 30 + nameLength;
    final endOffset = dataOffset + expectedSize;
    if (name != expectedName ||
        _u16(header, 4) != 20 ||
        _u16(header, 6) != expectedFlags ||
        _u16(header, 8) != expectedCompression ||
        _u16(header, 10) != expectedTime ||
        _u16(header, 12) != expectedDate ||
        _u32(header, 14) != expectedCrc32 ||
        _u32(header, 18) != expectedSize ||
        _u32(header, 22) != expectedSize) {
      _fail(
        'invalidZipStructure',
        expectedName,
        'Local and central ZIP metadata differ.',
      );
    }
    return (dataOffset: dataOffset, endOffset: endOffset);
  }

  Uint8List _readAt(
    RandomAccessPackageSource source,
    int offset,
    int length,
  ) {
    if (offset < 0 || length < 0) throw const FormatException();
    final bytes = source.readAtSync(offset, length);
    if (bytes.length != length) throw const FormatException();
    return bytes;
  }

  String _decodeName(List<int> bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      _fail('invalidPath', r'$', 'ZIP entry name is not strict UTF-8.');
    }
  }

  void _validateName(String name) {
    if (name == 'game-manifest.json') return;
    try {
      PackagePathPolicy.validate(name, errorPath: name);
    } on GamePackageFormatException {
      _fail('invalidPath', name, 'Invalid ZIP entry path.');
    }
  }

  int _u16(Uint8List bytes, int offset) {
    if (offset < 0 || offset + 2 > bytes.length) throw const FormatException();
    return ByteData.sublistView(bytes, offset, offset + 2)
        .getUint16(0, Endian.little);
  }

  int _u32(Uint8List bytes, int offset) {
    if (offset < 0 || offset + 4 > bytes.length) throw const FormatException();
    return ByteData.sublistView(bytes, offset, offset + 4)
        .getUint32(0, Endian.little);
  }

  Never _fail(String code, String path, String message) {
    throw GamePackageFormatException(
      code: code,
      path: path,
      message: message,
    );
  }
}
