import 'dart:convert';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';

import 'deterministic_zip_encoder.dart';
import 'game_package_format_exception.dart';
import 'game_package_security_policy.dart';
import 'package_path_policy.dart';
import 'presentation_preset_pack.dart';
import 'zip_structure_reader.dart';

final class PresentationPresetPackCodec {
  const PresentationPresetPackCodec();

  Uint8List encode(ProjectPresentationPresetPack pack) {
    final entries = <MapEntry<String, List<int>>>[
      MapEntry<String, List<int>>(
        'manifest.json',
        utf8.encode('${_canonicalJson(pack.manifest.toJson())}\n'),
      ),
      MapEntry<String, List<int>>(
        'profile.json',
        utf8.encode('${_canonicalJson(pack.profile.toJson())}\n'),
      ),
      for (final entry in pack.files.entries)
        MapEntry<String, List<int>>(entry.key, entry.value),
    ]..sort(
        (left, right) => PackagePathPolicy.compareUtf8(left.key, right.key),
      );
    final bytes = DeterministicZipEncoder.encode(entries);
    if (bytes.length > presentationPresetMaxArchiveBytes) {
      throw const PresentationPresetPackException(
        code: 'presetPackArchiveTooLarge',
        path: r'$',
        message: 'Preset archive exceeds the supported size.',
      );
    }
    return bytes;
  }

  ProjectPresentationPresetPack decode(List<int> source) {
    if (source.length > presentationPresetMaxArchiveBytes ||
        source.any((byte) => byte < 0 || byte > 255)) {
      throw const PresentationPresetPackException(
        code: 'presetPackArchiveTooLarge',
        path: r'$',
        message: 'Preset archive exceeds the supported size.',
      );
    }
    final bytes = source is Uint8List ? source : Uint8List.fromList(source);
    late final ZipStructure structure;
    try {
      structure = ZipStructureReader(
        const GamePackageSecurityPolicy(
          maxArchiveBytes: presentationPresetMaxArchiveBytes,
          maxPayloadEntries: presentationPresetMaxFiles + 2,
          maxFileBytes: presentationPresetMaxAssetBytes,
          maxTotalPayloadBytes: presentationPresetMaxArchiveBytes,
        ),
        entryNameValidator: _validatePresetEntryName,
      ).read(bytes);
    } on GamePackageFormatException catch (error) {
      throw PresentationPresetPackException(
        code: error.code == 'presetPackInvalidPath'
            ? error.code
            : 'presetPackArchiveInvalid',
        path: error.path,
        message: error.message,
      );
    }
    final byName = <String, Uint8List>{
      for (final entry in structure.entries) entry.name: entry.data,
    };
    final manifestBytes = byName.remove('manifest.json');
    final profileBytes = byName.remove('profile.json');
    if (manifestBytes == null || profileBytes == null) {
      throw const PresentationPresetPackException(
        code: 'presetPackDocumentMissing',
        path: r'$',
        message: 'manifest.json and profile.json are required.',
      );
    }
    try {
      final manifestJson = jsonDecode(
        utf8.decode(manifestBytes, allowMalformed: false),
      );
      final profileJson = jsonDecode(
        utf8.decode(profileBytes, allowMalformed: false),
      );
      if (manifestJson is! Map || profileJson is! Map) {
        throw const FormatException();
      }
      return ProjectPresentationPresetPack(
        manifest: PresentationPresetPackManifest.fromJson(
          Map<String, dynamic>.from(manifestJson),
        ),
        profile: ProjectPresentationProfile.fromJson(
          Map<String, dynamic>.from(profileJson),
        ),
        files: byName,
      );
    } on PresentationPresetPackException {
      rethrow;
    } on Object {
      throw const PresentationPresetPackException(
        code: 'presetPackDocumentInvalid',
        path: r'$',
        message: 'Preset manifest or profile JSON is invalid.',
      );
    }
  }
}

void _validatePresetEntryName(String name) {
  if (name == 'manifest.json' || name == 'profile.json') return;
  final root = name.startsWith('assets/')
      ? 'assets'
      : name.startsWith('licenses/')
          ? 'licenses'
          : null;
  if (root == null) {
    throw GamePackageFormatException(
      code: 'presetPackInvalidPath',
      path: name,
      message: 'Preset entries must stay below assets/ or licenses/.',
    );
  }
  try {
    PackagePathPolicy.validate('presentation/$name', errorPath: name);
  } on GamePackageFormatException {
    throw GamePackageFormatException(
      code: 'presetPackInvalidPath',
      path: name,
      message: 'Preset archive path is invalid.',
    );
  }
}

String _canonicalJson(Object? value) => jsonEncode(_sortedJson(value));

Object? _sortedJson(Object? value) {
  if (value is List) {
    return <Object?>[for (final item in value) _sortedJson(item)];
  }
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: _sortedJson(value[key]),
    };
  }
  return value;
}
