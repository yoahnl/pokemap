import 'dart:convert';
import 'dart:typed_data';

import 'game_package_format_exception.dart';
import 'game_package_security_policy.dart';
import 'package_path_policy.dart';

final class ZipStructureEntry {
  const ZipStructureEntry({
    required this.name,
    required this.crc32,
    required this.size,
    required this.data,
  });

  final String name;
  final int crc32;
  final int size;
  final Uint8List data;
}

final class ZipStructure {
  ZipStructure(List<ZipStructureEntry> entries)
      : entries = List.unmodifiable(entries);

  final List<ZipStructureEntry> entries;
}

/// Strict reader for the deliberately small ZIP profile used by format v1.
final class ZipStructureReader {
  const ZipStructureReader(this.policy);

  final GamePackageSecurityPolicy policy;

  ZipStructure read(Uint8List bytes) {
    try {
      return _readChecked(bytes);
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

  ZipStructure _readChecked(Uint8List bytes) {
    final eocdOffset = _findEocd(bytes);
    final diskNumber = _u16(bytes, eocdOffset + 4);
    final centralDisk = _u16(bytes, eocdOffset + 6);
    final diskEntries = _u16(bytes, eocdOffset + 8);
    final entryCount = _u16(bytes, eocdOffset + 10);
    final centralSize = _u32(bytes, eocdOffset + 12);
    final centralOffset = _u32(bytes, eocdOffset + 16);
    final archiveCommentLength = _u16(bytes, eocdOffset + 20);
    if (diskNumber != 0 ||
        centralDisk != 0 ||
        diskEntries != entryCount ||
        entryCount == 0xffff ||
        centralSize == 0xffffffff ||
        centralOffset == 0xffffffff ||
        archiveCommentLength != 0 ||
        eocdOffset + 22 != bytes.length) {
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
    if (centralOffset + centralSize != eocdOffset) {
      _fail(
        'invalidZipStructure',
        r'$',
        'Central directory bounds are inconsistent.',
      );
    }

    final entries = <ZipStructureEntry>[];
    final exactNames = <String>{};
    final collisionKeys = <String>{};
    var centralCursor = centralOffset;
    var expectedLocalOffset = 0;
    String? previousName;
    for (var index = 0; index < entryCount; index++) {
      if (_u32(bytes, centralCursor) != 0x02014b50) {
        _fail(
          'invalidZipStructure',
          r'$',
          'Invalid central directory entry.',
        );
      }
      final versionMadeBy = _u16(bytes, centralCursor + 4);
      final versionNeeded = _u16(bytes, centralCursor + 6);
      final flags = _u16(bytes, centralCursor + 8);
      final compression = _u16(bytes, centralCursor + 10);
      final modifiedTime = _u16(bytes, centralCursor + 12);
      final modifiedDate = _u16(bytes, centralCursor + 14);
      final crc32 = _u32(bytes, centralCursor + 16);
      final compressedSize = _u32(bytes, centralCursor + 20);
      final uncompressedSize = _u32(bytes, centralCursor + 24);
      final nameLength = _u16(bytes, centralCursor + 28);
      final extraLength = _u16(bytes, centralCursor + 30);
      final commentLength = _u16(bytes, centralCursor + 32);
      final startDisk = _u16(bytes, centralCursor + 34);
      final internalAttributes = _u16(bytes, centralCursor + 36);
      final externalAttributes = _u32(bytes, centralCursor + 38);
      final localOffset = _u32(bytes, centralCursor + 42);
      final recordEnd =
          centralCursor + 46 + nameLength + extraLength + commentLength;
      if (recordEnd > eocdOffset) {
        _fail(
          'invalidZipStructure',
          r'$',
          'Central directory entry exceeds its region.',
        );
      }
      final name = _decodeName(
        bytes.sublist(centralCursor + 46, centralCursor + 46 + nameLength),
      );
      if (!exactNames.add(name)) {
        _fail('duplicateEntry', name, 'Duplicate ZIP entry.');
      }
      final collisionKey = PackagePathPolicy.collisionKey(name);
      if (!collisionKeys.add(collisionKey)) {
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
          commentLength != 0 ||
          startDisk != 0 ||
          internalAttributes != 0) {
        _fail(
          'unsupportedZipFeature',
          name,
          'ZIP entry metadata is outside the format-v1 profile.',
        );
      }
      if (compressedSize != uncompressedSize) {
        _fail(
          'unsupportedZipFeature',
          name,
          'Only uncompressed STORED entries are accepted.',
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
        bytes,
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
        ZipStructureEntry(
          name: name,
          crc32: crc32,
          size: uncompressedSize,
          data: Uint8List.sublistView(
            bytes,
            local.dataOffset,
            local.endOffset,
          ),
        ),
      );
      centralCursor = recordEnd;
    }
    if (centralCursor != eocdOffset ||
        expectedLocalOffset != centralOffset ||
        entries.length != entryCount) {
      _fail(
        'invalidZipStructure',
        r'$',
        'ZIP regions do not form one canonical contiguous archive.',
      );
    }
    return ZipStructure(entries);
  }

  ({int dataOffset, int endOffset}) _readLocal(
    Uint8List bytes,
    int offset, {
    required String expectedName,
    required int expectedFlags,
    required int expectedCompression,
    required int expectedTime,
    required int expectedDate,
    required int expectedCrc32,
    required int expectedSize,
  }) {
    if (_u32(bytes, offset) != 0x04034b50) {
      _fail(
        'invalidZipStructure',
        expectedName,
        'Invalid local ZIP entry.',
      );
    }
    final versionNeeded = _u16(bytes, offset + 4);
    final flags = _u16(bytes, offset + 6);
    final compression = _u16(bytes, offset + 8);
    final time = _u16(bytes, offset + 10);
    final date = _u16(bytes, offset + 12);
    final crc32 = _u32(bytes, offset + 14);
    final compressedSize = _u32(bytes, offset + 18);
    final uncompressedSize = _u32(bytes, offset + 22);
    final nameLength = _u16(bytes, offset + 26);
    final extraLength = _u16(bytes, offset + 28);
    final name =
        _decodeName(bytes.sublist(offset + 30, offset + 30 + nameLength));
    final dataOffset = offset + 30 + nameLength + extraLength;
    final endOffset = dataOffset + compressedSize;
    if (name != expectedName ||
        versionNeeded != 20 ||
        flags != expectedFlags ||
        compression != expectedCompression ||
        time != expectedTime ||
        date != expectedDate ||
        crc32 != expectedCrc32 ||
        compressedSize != expectedSize ||
        uncompressedSize != expectedSize ||
        extraLength != 0 ||
        endOffset > bytes.length) {
      _fail(
        'invalidZipStructure',
        expectedName,
        'Local and central ZIP metadata differ.',
      );
    }
    return (dataOffset: dataOffset, endOffset: endOffset);
  }

  int _findEocd(Uint8List bytes) {
    if (bytes.length < 22) {
      _fail('invalidZipStructure', r'$', 'ZIP is shorter than its footer.');
    }
    final minimum = bytes.length > 65557 ? bytes.length - 65557 : 0;
    for (var offset = bytes.length - 22; offset >= minimum; offset--) {
      if (_u32(bytes, offset) == 0x06054b50) return offset;
    }
    _fail('invalidZipStructure', r'$', 'ZIP footer is missing.');
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
