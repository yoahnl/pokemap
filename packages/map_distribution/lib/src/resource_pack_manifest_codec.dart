import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';

import 'canonical_json.dart';
import 'game_package_format_exception.dart';
import 'package_path_policy.dart';
import 'resource_pack_security_policy.dart';
import 'strict_json_structure_validator.dart';

final class ResourcePackManifestCodec {
  const ResourcePackManifestCodec(
      {this.policy = const ResourcePackSecurityPolicy()});

  final ResourcePackSecurityPolicy policy;

  ResourcePackManifest decodeUtf8(List<int> bytes) {
    if (bytes.length > policy.maxManifestBytes) {
      _fail(
          'resource_pack.manifest_too_large', 'Pack manifest exceeds policy.');
    }
    late final String source;
    try {
      source = utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      _fail('resource_pack.invalid_utf8',
          'Pack manifest must contain valid UTF-8.');
    }
    try {
      const StrictJsonStructureValidator().validate(
        source,
        path: 'manifest.json',
        maxDepth: policy.maxJsonDepth,
        maxNodes: policy.maxJsonNodes < 1000000 ? policy.maxJsonNodes : 1000000,
        duplicateCode: 'resource_pack.json_duplicate_key',
      );
    } on GamePackageFormatException catch (error) {
      if (error.code == 'resource_pack.json_duplicate_key') rethrow;
      _fail(
        error.code == 'entryTooLarge'
            ? 'resource_pack.json_complexity'
            : 'resource_pack.invalid_json',
        error.code == 'entryTooLarge'
            ? 'Pack manifest exceeds the JSON complexity policy.'
            : 'Pack manifest contains malformed JSON.',
      );
    }
    late final Object? value;
    try {
      value = jsonDecode(source);
    } on FormatException {
      _fail('resource_pack.invalid_json',
          'Pack manifest contains malformed JSON.');
    }
    return decodeJson(value);
  }

  ResourcePackManifest decodeJson(Object? value) {
    if (value is! Map || value.keys.any((key) => key is! String)) {
      _fail(
          'resource_pack.manifest_invalid', 'Pack manifest must be an object.');
    }
    late final ResourcePackManifest manifest;
    late final bool canonicalValues;
    try {
      manifest =
          ResourcePackManifest.fromJson(Map<String, Object?>.from(value));
      canonicalValues = CanonicalJson.encode(value) ==
          CanonicalJson.encode(manifest.toJson());
    } on FormatException {
      _fail(
        'resource_pack.manifest_invalid',
        'Pack manifest does not satisfy the supported format contract.',
      );
    }
    if (!canonicalValues) {
      _fail(
        'resource_pack.manifest_noncanonical_values',
        'Pack manifest arrays and values must use their canonical order.',
      );
    }
    return manifest;
  }

  Uint8List encodeUtf8(ResourcePackManifest manifest) {
    late final Uint8List bytes;
    try {
      bytes = CanonicalJson.encodeUtf8(manifest.toJson());
    } on CanonicalJsonException {
      _fail(
        'resource_pack.manifest_invalid',
        'Pack manifest contains unsupported JSON values.',
      );
    }
    if (bytes.length > policy.maxManifestBytes) {
      _fail(
          'resource_pack.manifest_too_large', 'Pack manifest exceeds policy.');
    }
    return bytes;
  }

  Never _fail(String code, String message) => throw GamePackageFormatException(
        code: code,
        path: 'manifest.json',
        message: message,
      );
}

String resourcePackTreeSha256(
  ResourcePackInventoryFile catalog,
  Iterable<ResourcePackInventoryFile> files,
) {
  final entries = [catalog, ...files]
    ..sort((a, b) => PackagePathPolicy.compareUtf8(a.path, b.path));
  final rows = [for (final entry in entries) entry.toJson()];
  return sha256
      .convert(utf8.encode(
        'avelune.asset-pack.tree.v1\n${CanonicalJson.encode(rows)}\n',
      ))
      .toString();
}
