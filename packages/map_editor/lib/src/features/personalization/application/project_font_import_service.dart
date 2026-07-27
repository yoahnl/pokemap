import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

final class ProjectFontImportException implements Exception {
  const ProjectFontImportException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'ProjectFontImportException($code): $message';
}

final class ProjectFontProbeResult {
  const ProjectFontProbeResult({
    required this.family,
    required this.glyphCoverage,
  });

  final String family;
  final Set<String> glyphCoverage;
}

abstract interface class ProjectFontProbe {
  Future<ProjectFontProbeResult> probe(File file);
}

/// Reads the family and required glyph coverage directly from TTF/OTF tables.
final class SfntProjectFontProbe implements ProjectFontProbe {
  const SfntProjectFontProbe();

  @override
  Future<ProjectFontProbeResult> probe(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final font = _SfntFont(bytes);
      return ProjectFontProbeResult(
        family: font.family,
        glyphCoverage: <String>{
          for (final sample in _glyphSamples.entries)
            if (sample.value.every(font.hasGlyph)) sample.key,
        },
      );
    } on ProjectFontImportException {
      rethrow;
    } on Object {
      throw const ProjectFontImportException(
        'fontCorrupt',
        'The selected font could not be parsed.',
      );
    }
  }
}

abstract interface class ProjectFontImporter {
  Future<ProjectTypographyRoleProfile> importIntoProject({
    required Directory projectRoot,
    required ProjectTypographyRole role,
    required File fontFile,
    required File licenseFile,
    required bool redistributionConfirmed,
    required List<String> fallbackFamilies,
  });
}

final class ProjectFontImportService implements ProjectFontImporter {
  const ProjectFontImportService({
    this.probe = const SfntProjectFontProbe(),
  });

  final ProjectFontProbe probe;

  @override
  Future<ProjectTypographyRoleProfile> importIntoProject({
    required Directory projectRoot,
    required ProjectTypographyRole role,
    required File fontFile,
    required File licenseFile,
    required bool redistributionConfirmed,
    required List<String> fallbackFamilies,
  }) async {
    await _requireFile(fontFile, 'fontMissing');
    await _requireFile(licenseFile, 'fontLicenseMissing');
    if (!redistributionConfirmed) {
      throw const ProjectFontImportException(
        'fontRedistributionNotConfirmed',
        'Confirm the right to redistribute this font.',
      );
    }
    final fallbacks = fallbackFamilies
        .map((family) => family.trim())
        .where((family) => family.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (fallbacks.isEmpty) {
      throw const ProjectFontImportException(
        'fontFallbackMissing',
        'Choose at least one system fallback.',
      );
    }

    final extension = p.extension(fontFile.path).toLowerCase();
    if (extension != '.ttf' && extension != '.otf') {
      throw const ProjectFontImportException(
        'fontFormatUnsupported',
        'Embedded fonts must use TTF or OTF.',
      );
    }
    final fontBytes = await fontFile.readAsBytes();
    if (fontBytes.isEmpty || fontBytes.length > _maxFontBytes) {
      throw const ProjectFontImportException(
        'fontSizeUnsupported',
        'The font must not exceed 10 MiB.',
      );
    }
    if (!_hasSfntSignature(fontBytes, extension)) {
      throw const ProjectFontImportException(
        'fontSignatureInvalid',
        'The file signature does not match its font extension.',
      );
    }
    final licenseBytes = await licenseFile.readAsBytes();
    if (licenseBytes.isEmpty || licenseBytes.length > _maxLicenseBytes) {
      throw const ProjectFontImportException(
        'fontLicenseSizeUnsupported',
        'The font license must be a non-empty text file below 1 MiB.',
      );
    }
    try {
      if (utf8.decode(licenseBytes, allowMalformed: false).trim().isEmpty) {
        throw const FormatException();
      }
    } on FormatException {
      throw const ProjectFontImportException(
        'fontLicenseInvalid',
        'The font license must contain strict UTF-8 text.',
      );
    }

    final metadata = await probe.probe(fontFile);
    if (metadata.family.trim().isEmpty) {
      throw const ProjectFontImportException(
        'fontFamilyMissing',
        'The font does not declare a family name.',
      );
    }
    if (!metadata.glyphCoverage.containsAll(
      requiredProjectFontGlyphCoverage,
    )) {
      throw const ProjectFontImportException(
        'fontGlyphCoverageIncomplete',
        'The font does not cover the required player glyph sets.',
      );
    }

    final digest = sha256
        .convert(<int>[...fontBytes, ...licenseBytes])
        .toString()
        .substring(0, 16);
    final roleName = role.name;
    final fontPath = 'assets/presentation/fonts/$roleName-$digest$extension';
    final licensePath =
        'assets/presentation/fonts/$roleName-$digest-license.txt';
    final profile = ProjectTypographyRoleProfile(
      fontPath: fontPath,
      family: metadata.family.trim(),
      licensePath: licensePath,
      redistributable: true,
      fallbackFamilies: fallbacks,
      glyphCoverage: metadata.glyphCoverage.toList(growable: false)..sort(),
    );
    final validationProfile = switch (role) {
      ProjectTypographyRole.display =>
        ProjectTypographyProfile(display: profile),
      ProjectTypographyRole.body => ProjectTypographyProfile(body: profile),
      ProjectTypographyRole.dialogue =>
        ProjectTypographyProfile(dialogue: profile),
      ProjectTypographyRole.numbers =>
        ProjectTypographyProfile(numbers: profile),
    };
    final errors = validateProjectPresentationProfile(
      ProjectPresentationProfile(typography: validationProfile),
    ).where(
      (diagnostic) =>
          diagnostic.severity == ProjectPresentationDiagnosticSeverity.error,
    );
    if (errors.isNotEmpty) {
      throw ProjectFontImportException(
        errors.first.code,
        errors.first.message,
      );
    }

    await _writeAtomically(
      projectRoot: projectRoot,
      fontPath: fontPath,
      fontBytes: fontBytes,
      licensePath: licensePath,
      licenseBytes: licenseBytes,
    );
    return profile;
  }

  Future<void> _requireFile(File file, String code) async {
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw ProjectFontImportException(code, 'Choose a regular project file.');
    }
  }

  Future<void> _writeAtomically({
    required Directory projectRoot,
    required String fontPath,
    required Uint8List fontBytes,
    required String licensePath,
    required Uint8List licenseBytes,
  }) async {
    final nonce = DateTime.now().microsecondsSinceEpoch;
    final staging = Directory(
      p.join(projectRoot.path, '.pokemap-font-import-$nonce'),
    );
    final stagedFont = File(p.join(staging.path, p.basename(fontPath)));
    final stagedLicense = File(p.join(staging.path, p.basename(licensePath)));
    final targetFont = File(p.join(projectRoot.path, fontPath));
    final targetLicense = File(p.join(projectRoot.path, licensePath));
    try {
      await staging.create(recursive: true);
      await stagedFont.writeAsBytes(fontBytes, flush: true);
      await stagedLicense.writeAsBytes(licenseBytes, flush: true);
      await targetFont.parent.create(recursive: true);
      if (!await targetFont.exists()) {
        await stagedFont.rename(targetFont.path);
      }
      if (!await targetLicense.exists()) {
        await stagedLicense.rename(targetLicense.path);
      }
    } on Object {
      if (await targetFont.exists() && !await targetLicense.exists()) {
        await targetFont.delete();
      }
      throw const ProjectFontImportException(
        'fontImportWriteFailed',
        'The validated font could not be copied into the project.',
      );
    } finally {
      if (await staging.exists()) await staging.delete(recursive: true);
    }
  }
}

abstract interface class ProjectFontPreviewRegistry {
  Future<String> load({
    required File fontFile,
    required ProjectTypographyRole role,
  });
}

/// Registers an imported font under an isolated family for live editor preview.
final class ProjectFontPreviewLoader implements ProjectFontPreviewRegistry {
  const ProjectFontPreviewLoader();

  @override
  Future<String> load({
    required File fontFile,
    required ProjectTypographyRole role,
  }) async {
    final bytes = await fontFile.readAsBytes();
    final digest = sha256.convert(bytes).toString().substring(0, 12);
    final family = 'PokeMapPreview-${role.name}-$digest';
    final loader = FontLoader(family)
      ..addFont(
        Future<ByteData>.value(ByteData.sublistView(bytes)),
      );
    await loader.load();
    return family;
  }
}

const int _maxFontBytes = 10 * 1024 * 1024;
const int _maxLicenseBytes = 1024 * 1024;

bool _hasSfntSignature(Uint8List bytes, String extension) {
  if (bytes.length < 4) return false;
  if (extension == '.otf') {
    return ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'OTTO';
  }
  return bytes[0] == 0 && bytes[1] == 1 && bytes[2] == 0 && bytes[3] == 0 ||
      ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'true';
}

const Map<String, List<int>> _glyphSamples = <String, List<int>>{
  'latin': <int>[0x41, 0x5a, 0x61, 0x7a],
  'latinExtended': <int>[0x00c9, 0x00e0, 0x00e7, 0x00e9, 0x0152, 0x0153],
  'digits': <int>[0x30, 0x39],
  'punctuation': <int>[0x21, 0x27, 0x2c, 0x2d, 0x2e, 0x3f],
};

final class _SfntFont {
  _SfntFont(Uint8List bytes)
      : _bytes = bytes,
        _data = ByteData.sublistView(bytes) {
    if (bytes.length < 12) _corrupt();
    final tableCount = _u16(4);
    for (var index = 0; index < tableCount; index++) {
      final record = 12 + index * 16;
      if (record + 16 > bytes.length) _corrupt();
      final tag = ascii.decode(bytes.sublist(record, record + 4));
      final offset = _u32(record + 8);
      final length = _u32(record + 12);
      if (offset < 0 || length < 0 || offset + length > bytes.length) {
        _corrupt();
      }
      _tables[tag] = (offset: offset, length: length);
    }
    _cmapOffsets = _readCmapOffsets();
  }

  final Uint8List _bytes;
  final ByteData _data;
  final Map<String, ({int offset, int length})> _tables =
      <String, ({int offset, int length})>{};
  late final List<int> _cmapOffsets;

  String get family {
    final table = _tables['name'];
    if (table == null || table.length < 6) _corrupt();
    final count = _u16(table.offset + 2);
    final stringBase = table.offset + _u16(table.offset + 4);
    String? legacy;
    for (var index = 0; index < count; index++) {
      final record = table.offset + 6 + index * 12;
      if (record + 12 > table.offset + table.length) _corrupt();
      final platform = _u16(record);
      final nameId = _u16(record + 6);
      if (nameId != 1 && nameId != 16) continue;
      final length = _u16(record + 8);
      final offset = stringBase + _u16(record + 10);
      if (offset + length > table.offset + table.length) _corrupt();
      final value = platform == 0 || platform == 3
          ? _utf16Be(offset, length)
          : latin1.decode(_bytes.sublist(offset, offset + length)).trim();
      if (value.isEmpty) continue;
      if (nameId == 16) return value;
      legacy ??= value;
    }
    if (legacy == null) _corrupt();
    return legacy;
  }

  bool hasGlyph(int codePoint) {
    for (final offset in _cmapOffsets) {
      final format = _u16(offset);
      if (format == 12 && _format12HasGlyph(offset, codePoint)) return true;
      if (format == 4 &&
          codePoint <= 0xffff &&
          _format4HasGlyph(offset, codePoint)) {
        return true;
      }
    }
    return false;
  }

  List<int> _readCmapOffsets() {
    final table = _tables['cmap'];
    if (table == null || table.length < 4) _corrupt();
    final count = _u16(table.offset + 2);
    final candidates = <({int priority, int offset})>[];
    for (var index = 0; index < count; index++) {
      final record = table.offset + 4 + index * 8;
      if (record + 8 > table.offset + table.length) _corrupt();
      final platform = _u16(record);
      final encoding = _u16(record + 2);
      final offset = table.offset + _u32(record + 4);
      if (offset + 2 > table.offset + table.length) _corrupt();
      final format = _u16(offset);
      if (format != 4 && format != 12) continue;
      final priority = platform == 3 && encoding == 10
          ? 0
          : platform == 0
              ? 1
              : platform == 3 && encoding == 1
                  ? 2
                  : 3;
      candidates.add((priority: priority, offset: offset));
    }
    candidates.sort((a, b) => a.priority.compareTo(b.priority));
    if (candidates.isEmpty) _corrupt();
    return candidates.map((candidate) => candidate.offset).toList();
  }

  bool _format12HasGlyph(int offset, int codePoint) {
    final groupCount = _u32(offset + 12);
    for (var index = 0; index < groupCount; index++) {
      final group = offset + 16 + index * 12;
      final start = _u32(group);
      final end = _u32(group + 4);
      if (codePoint < start) return false;
      if (codePoint <= end) return true;
    }
    return false;
  }

  bool _format4HasGlyph(int offset, int codePoint) {
    final segmentCount = _u16(offset + 6) ~/ 2;
    final endCodes = offset + 14;
    final startCodes = endCodes + segmentCount * 2 + 2;
    final deltas = startCodes + segmentCount * 2;
    final rangeOffsets = deltas + segmentCount * 2;
    for (var index = 0; index < segmentCount; index++) {
      final end = _u16(endCodes + index * 2);
      if (codePoint > end) continue;
      final start = _u16(startCodes + index * 2);
      if (codePoint < start) return false;
      final delta = _i16(deltas + index * 2);
      final rangeOffsetPosition = rangeOffsets + index * 2;
      final rangeOffset = _u16(rangeOffsetPosition);
      if (rangeOffset == 0) return (codePoint + delta) & 0xffff != 0;
      final glyphPosition =
          rangeOffsetPosition + rangeOffset + (codePoint - start) * 2;
      final glyph = _u16(glyphPosition);
      return glyph != 0 && (glyph + delta) & 0xffff != 0;
    }
    return false;
  }

  String _utf16Be(int offset, int length) {
    if (length.isOdd) _corrupt();
    final units = <int>[
      for (var index = 0; index < length; index += 2) _u16(offset + index),
    ];
    return String.fromCharCodes(units).trim();
  }

  int _u16(int offset) {
    if (offset < 0 || offset + 2 > _bytes.length) _corrupt();
    return _data.getUint16(offset, Endian.big);
  }

  int _i16(int offset) {
    if (offset < 0 || offset + 2 > _bytes.length) _corrupt();
    return _data.getInt16(offset, Endian.big);
  }

  int _u32(int offset) {
    if (offset < 0 || offset + 4 > _bytes.length) _corrupt();
    return _data.getUint32(offset, Endian.big);
  }

  Never _corrupt() => throw const ProjectFontImportException(
        'fontCorrupt',
        'The selected font contains malformed SFNT tables.',
      );
}
