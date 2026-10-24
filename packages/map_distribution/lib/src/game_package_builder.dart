import 'dart:typed_data';
import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'strict_json_structure_validator.dart';

import 'package:crypto/crypto.dart';

import 'canonical_json.dart';
import 'deterministic_zip_encoder.dart';
import 'game_package_format_exception.dart';
import 'game_package_content_validator.dart';
import 'game_package_inventory_builder.dart';
import 'game_package_manifest.dart';
import 'game_package_manifest_codec.dart';
import 'game_package_project_validator.dart';
import 'game_package_security_policy.dart';
import 'package_path_policy.dart';

final class GamePackageBuildResult {
  GamePackageBuildResult({
    required GamePackageManifest manifest,
    required List<int> packageBytes,
  }) : this._fromOwnedBytes(
          manifest: manifest,
          packageBytes: _copyPackageBytes(packageBytes),
        );

  GamePackageBuildResult._fromOwnedBytes({
    required this.manifest,
    required Uint8List packageBytes,
  })  : packageBytes = packageBytes.asUnmodifiableView(),
        packageSha256 = sha256.convert(packageBytes).toString(),
        archiveBytes = packageBytes.length;

  final GamePackageManifest manifest;
  final List<int> packageBytes;
  final String packageSha256;
  final int archiveBytes;

  static Uint8List _copyPackageBytes(List<int> bytes) {
    for (final byte in bytes) {
      if (byte < 0 || byte > 255) {
        throw ArgumentError.value(byte, 'packageBytes', 'Must contain bytes.');
      }
    }
    return Uint8List.fromList(bytes);
  }
}

/// Builds the deterministic ZIP representation of a `.avelunegame` archive.
final class GamePackageBuilder {
  const GamePackageBuilder({
    this.inventoryBuilder = const GamePackageInventoryBuilder(),
    this.manifestCodec = const GamePackageManifestCodec(),
    this.securityPolicy = const GamePackageSecurityPolicy(),
  });

  final GamePackageInventoryBuilder inventoryBuilder;
  final GamePackageManifestCodec manifestCodec;
  final GamePackageSecurityPolicy securityPolicy;

  ({Map<String, List<int>> files, ProjectManifest project}) _publicationPayload(
      Map<String, List<int>> files) {
    try {
      final bytes = files['project/project.json'];
      if (bytes == null) throw const FormatException('Missing project');
      final source = utf8.decode(bytes);
      const StrictJsonStructureValidator().validate(source,
          path: 'project/project.json',
          maxDepth: securityPolicy.maxJsonDepth,
          maxNodes: securityPolicy.maxCatalogJsonValues,
          duplicateCode: 'invalidProject');
      final raw = jsonDecode(source) as Map<String, dynamic>;
      final hasPublicationMarker = raw.containsKey('format') ||
          raw.containsKey('kind') ||
          raw.containsKey('root');
      if (hasPublicationMarker) {
        final project = PortableCatalogPublication.decodeProjectSync(raw,
            limits: CatalogStorageLimits(
                maxStoredBytes: securityPolicy.maxCatalogBytes),
            readObject: (ref) =>
                files[
                    'project/${PortableCatalogPublication.objectPath(ref)}'] ??
                (throw const FormatException('Missing catalog object')));
        return (files: files, project: project);
      }
      if (files.keys
          .any((path) => path.startsWith('project/catalog/objects/'))) {
        throw const FormatException(
            'Native project contains publication objects');
      }
      if (raw['version'] is! String) {
        throw const FormatException('Missing native version');
      }
      final project = ProjectManifest.fromJson(raw);
      ProjectValidator.validate(project);
      final publication = PortableCatalogPublication.encodeProject(project,
          limits: CatalogStorageLimits(
              maxStoredBytes: securityPolicy.maxCatalogBytes));
      return (project: project, files: {
        ...files,
        'project/project.json':
            CanonicalJson.encodeUtf8(publication.descriptor),
        for (final object in publication.storage.objects.entries)
          'project/catalog/objects/${object.key}.json': object.value,
      });
    } on Object catch (error) {
      if (error is GamePackageFormatException) rethrow;
      throw GamePackageFormatException(
          code: 'invalidProject',
          path: 'project/project.json',
          message: 'Invalid project publication: $error');
    }
  }

  GamePackageBuildResult build({
    required GamePackageManifest manifest,
    required Map<String, List<int>> payloadFiles,
    PackageMediaTypeResolver? mediaTypeForPath,
  }) {
    final publication = _publicationPayload(payloadFiles);
    final publicationPayload = publication.files;
    final recordsParty =
        GameCompletionPartyCapabilities.requiresCapability(publication.project);
    if (recordsParty &&
        manifest.compatibility.saveFormat != SaveEnvelopeCodec.currentSaveFormat) {
      throw GamePackageFormatException(
        code: 'completionPartySaveFormatUnsupported',
        path: r'$.compatibility.saveFormat',
        message: 'Party recording requires save format '
            '${SaveEnvelopeCodec.currentSaveFormat}.',
      );
    }
    final required = manifest.compatibility.requiredCapabilities;
    final targetCapabilities = {
      ...required,
      'catalog.partitioned@2',
      if (recordsParty)
        GameCompletionPartyCapabilities.capabilityId,
    };
    final changesCapability = !required.toSet().containsAll(targetCapabilities);
    if (manifest.signature != null && changesCapability) {
      throw GamePackageFormatException(
          code: 'staleSignature',
          path: r'$.signature',
          message: 'Project publication changes signed capabilities.');
    }
    final old = manifest.compatibility;
    final compatibility = changesCapability
        ? GamePackageCompatibility(
            minHubVersion: old.minHubVersion,
            runtimeApiExpression: old.runtimeApiExpression,
            projectFormat: old.projectFormat,
            saveFormat: old.saveFormat,
            compatibilityId: old.compatibilityId,
            requiredCapabilities:
                targetCapabilities.toList()..sort())
        : old;
    final inventory = inventoryBuilder.buildWithSnapshot(
      publicationPayload,
      mediaTypeForPath: mediaTypeForPath,
    );
    final content = inventory.content;
    final payloadSnapshot = inventory.payloadSnapshot;
    if (content.fileCount > securityPolicy.maxPayloadEntries) {
      throw GamePackageFormatException(
        code: 'entryCountExceeded',
        path: r'$.content.files',
        message: 'Payload entry count exceeds builder policy.',
      );
    }
    if (content.totalBytes > securityPolicy.maxTotalPayloadBytes) {
      throw GamePackageFormatException(
        code: 'archiveTooLarge',
        path: r'$.content.totalBytes',
        message: 'Payload total exceeds builder policy.',
      );
    }
    for (final entry in content.files) {
      if (entry.size > securityPolicy.maxFileBytes) {
        throw GamePackageFormatException(
          code: 'entryTooLarge',
          path: entry.path,
          message: 'Payload entry exceeds builder policy.',
        );
      }
    }
    if (manifest.signature != null &&
        CanonicalJson.encode(manifest.content.toJson()) !=
            CanonicalJson.encode(content.toJson())) {
      throw GamePackageFormatException(
        code: 'staleSignature',
        path: r'$.signature',
        message: 'Signed manifest content differs from the payload inventory.',
      );
    }
    final packagedManifest =
        manifest.copyWith(content: content, compatibility: compatibility);
    final manifestBytes = manifestCodec.encodeCanonicalUtf8(packagedManifest);
    if (manifestBytes.length > securityPolicy.maxManifestBytes) {
      throw GamePackageFormatException(
        code: 'manifestTooLarge',
        path: 'game-manifest.json',
        message: 'Manifest exceeds builder policy.',
      );
    }
    final contentValidator = GamePackageContentValidator(securityPolicy);
    GamePackageBinarySecretScanner('game-manifest.json').add(manifestBytes);
    for (final entry in content.files) {
      contentValidator.validate(
        entry,
        payloadSnapshot[entry.path]! as Uint8List,
      );
    }
    GamePackageProjectValidator(securityPolicy).validate(
      packagedManifest,
      payloadSnapshot['project/project.json']! as Uint8List,
      payloadPaths: payloadSnapshot.keys.toSet(),
      readPayload: (path) => payloadSnapshot[path],
    );
    final entries = <MapEntry<String, List<int>>>[
      MapEntry<String, List<int>>('game-manifest.json', manifestBytes),
      ...payloadSnapshot.entries,
    ]..sort(
        (left, right) => PackagePathPolicy.compareUtf8(left.key, right.key),
      );

    final bytes = DeterministicZipEncoder.encode(entries);
    if (bytes.length > securityPolicy.maxArchiveBytes) {
      throw GamePackageFormatException(
        code: 'archiveTooLarge',
        path: r'$',
        message: 'Built package exceeds archive policy.',
      );
    }
    return GamePackageBuildResult._fromOwnedBytes(
      manifest: manifestCodec.decodeUtf8(manifestBytes),
      packageBytes: bytes,
    );
  }
}
