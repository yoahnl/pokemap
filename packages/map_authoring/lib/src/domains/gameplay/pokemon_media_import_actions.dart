import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/artifact_ref.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../ports/artifact_store.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';
import '../assets/asset_actions.dart';
import '../assets/asset_store.dart';
import '../assets/raster_image_dimensions.dart';

enum PokemonMediaImportRole { icon, party, portrait }

final class PokemonMediaImportEntry {
  const PokemonMediaImportEntry({
    required this.speciesId,
    required this.formId,
    required this.role,
    required this.artifactHandle,
  });

  final String speciesId;
  final String formId;
  final PokemonMediaImportRole role;
  final String artifactHandle;

  Map<String, Object?> toJson() => {
        'speciesId': speciesId,
        'formId': formId,
        'role': role.name,
        'artifactHandle': artifactHandle,
      };

  factory PokemonMediaImportEntry.fromJson(Map<String, Object?> json) {
    if (json.length != 4 ||
        !json.keys.toSet().containsAll(const {
          'speciesId',
          'formId',
          'role',
          'artifactHandle',
        })) {
      throw const FormatException(
          'Pokemon media entries require exact species, form, role and artifact handle.');
    }
    String value(String key) {
      final raw = json[key];
      if (raw is! String || raw.isEmpty || raw.trim() != raw) {
        throw FormatException('Invalid Pokemon media $key.');
      }
      return raw;
    }

    return PokemonMediaImportEntry(
      speciesId: _identity(value('speciesId')),
      formId: _identity(value('formId')),
      role: PokemonMediaImportRole.values.byName(value('role')),
      artifactHandle: value('artifactHandle'),
    );
  }
}

final class PokemonMediaImportActions {
  const PokemonMediaImportActions({required this.artifactStore});

  final ArtifactStore artifactStore;

  static final descriptors = <AuthoringActionDescriptor>[
    AuthoringActionDescriptor(
      id: 'pokemon.media.import',
      version: 1,
      summary:
          'Import inspected PNG menu media by exact species, form and role, preserving existing choices',
      inputSchemaId: 'pokemap.authoring/pokemon.media.import.input.v1',
      outputSchemaId: 'pokemap.authoring/pokemon.media.import.output.v1',
      riskLevel: AuthoringRiskLevel.medium,
      resourceKinds: const ['project', 'pokemonDocument', 'asset'],
      capabilityIds: const ['authoring.gameData.pokemon'],
      requiredPermissions: const [
        AuthoringPermission.projectWrite,
        AuthoringPermission.importRun
      ],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.atomic,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
    ),
  ];

  Future<AuthoringMutationDraft> build(AuthoringPlanningContext context) async {
    final snapshot = context.snapshot;
    if (!snapshot.manifest.pokemon.enabled ||
        !snapshot.pokemonInventoryComplete) {
      throw AssetActionException('pokemon.media.inventory_unavailable',
          'A complete Pokemon species and media inventory is required.');
    }
    final parameters = context.request.parameters;
    if (parameters.keys
            .any((key) => key != 'entries' && key != 'conflictPolicy') ||
        (parameters['conflictPolicy'] ?? 'preserve') != 'preserve' ||
        parameters['entries'] is! List) {
      throw const FormatException(
          'Expected entries and optional preserve conflictPolicy.');
    }
    final rawEntries = parameters['entries']! as List;
    if (rawEntries.isEmpty || rawEntries.length > 4096) {
      throw const FormatException(
          'Import batches require between 1 and 4096 entries.');
    }
    final entries = rawEntries.map((raw) {
      if (raw is! Map) throw const FormatException('Expected import entry.');
      return PokemonMediaImportEntry.fromJson(Map<String, Object?>.from(raw));
    }).toList();
    final targets = <String>{};
    for (final entry in entries) {
      if (!targets
          .add('${entry.speciesId}/${entry.formId}/${entry.role.name}')) {
        throw const FormatException('Duplicate Pokemon media target in batch.');
      }
    }
    final species = <String, PokemonSpeciesFile>{};
    final media = <String, Map<String, dynamic>>{};
    for (final identity in snapshot.resourceFingerprints.keys) {
      if (identity.startsWith('pokemonSpecies:')) {
        final value = PokemonSpeciesFile.fromJson(
            _json(snapshot.resourceBytes(identity)));
        if (value.id.isEmpty || species.containsKey(value.id)) {
          throw const FormatException(
              'Invalid or duplicate Pokemon species identity.');
        }
        species[value.id] = value;
      } else if (identity.startsWith('pokemonMedia:')) {
        final raw = _json(snapshot.resourceBytes(identity));
        final document = PokemonMediaFile.fromJson(raw);
        if (document.speciesId.isEmpty ||
            document.defaultFormId.isEmpty ||
            raw['variants'] is! Map) {
          throw const FormatException('Incomplete Pokemon media document.');
        }
        media[identity] = raw;
      }
    }
    final catalogBefore =
        snapshot.findResourceBytes(assetCatalogResourceIdentity);
    var catalog = catalogBefore == null
        ? AssetCatalog()
        : AssetCatalog.fromJson(_json(catalogBefore));
    final changes = <String, AuthoringResourceChange>{};
    final diffs = <AuthoringDiffEntry>[];
    final added = <Map<String, Object?>>[];
    final preserved = <Map<String, Object?>>[];
    final repaired = <Map<String, Object?>>[];
    final conflicts = <Map<String, Object?>>[];
    final inspected = <String, (ContentArtifactRef, List<int>)>{};
    final changedMedia = <String>{};
    final mediaPaths = <String, String>{};
    var catalogChanged = false;
    var totalBytes = 0;
    for (final entry in entries) {
      final source = species[entry.speciesId];
      if (source == null) {
        throw FormatException('Unknown species ${entry.speciesId}.');
      }
      final forms =
          PokemonSpeciesIndexEntry.fromSpeciesFile(source, relativePath: '')
              .formIds;
      if (!forms.contains(entry.formId)) {
        throw FormatException(
            'Unknown form ${entry.formId} for ${entry.speciesId}.');
      }
      final mediaId = _identity(source.mediaRef);
      final identity = pokemonMediaResourceIdentity(mediaId);
      final mediaPath = '${snapshot.manifest.pokemon.mediaDir}/$mediaId.json';
      final storedPath = snapshot.resourceStorageKeys[identity];
      if (storedPath != null && storedPath != mediaPath) {
        throw const FormatException(
            'Pokemon media reference path does not match its inventory.');
      }
      mediaPaths[identity] = mediaPath;
      final document = media.putIfAbsent(
          identity,
          () => PokemonMediaFile(
                speciesId: mediaId,
                defaultFormId: _identity(source.forms.formId),
              ).toJson().cast<String, dynamic>());
      if (document['speciesId'] != mediaId) {
        throw const FormatException(
            'Pokemon media document identity mismatch.');
      }
      final variants =
          Map<String, dynamic>.from(document['variants'] as Map? ?? const {});
      final variant =
          Map<String, dynamic>.from(variants[entry.formId] as Map? ?? const {});
      var staged = inspected[entry.artifactHandle];
      if (staged == null) {
        final artifact = artifactStore.inspect(entry.artifactHandle);
        if (artifact == null) {
          throw const ArtifactStoreException(
              'artifact.unknown', 'The artifact handle is unknown or expired.');
        }
        final bytes = await artifactStore.read(entry.artifactHandle);
        totalBytes += bytes.length;
        if (totalBytes > 128 << 20) {
          throw const FormatException('Pokemon media batch exceeds 128 MiB.');
        }
        final actual =
            ContentArtifactRef.fromBytes(bytes, mediaType: artifact.mediaType);
        if (actual.digest != artifact.digest ||
            actual.byteLength != artifact.byteLength) {
          throw const FormatException(
              'Staged Pokemon image identity mismatch.');
        }
        final dimensions =
            decodeRasterImageDimensions(bytes, mediaType: artifact.mediaType);
        if (artifact.mediaType != 'image/png' ||
            dimensions == null ||
            dimensions.width * dimensions.height > 16777216 ||
            image.decodePng(Uint8List.fromList(bytes)) == null) {
          throw const FormatException(
              'Pokemon menu media must be a decodable PNG within 16 megapixels.');
        }
        staged = (artifact, bytes);
        inspected[entry.artifactHandle] = staged;
      }
      final (artifact, bytes) = staged;
      final logicalPath =
          'assets/pokemon/menu/${entry.speciesId}/${entry.formId}/${artifact.hexDigest}.png';
      final preview = <String, Object?>{
        'speciesId': entry.speciesId,
        'formId': entry.formId,
        'role': entry.role.name,
        'logicalPath': logicalPath,
        'digest': artifact.digest,
      };
      final existing = variant[entry.role.name];
      if (existing != null && existing != '') {
        preserved.add({...preview, 'existing': existing});
        if (existing != logicalPath) {
          conflicts.add(
              {...preview, 'existing': existing, 'resolution': 'preserve'});
        }
        continue;
      }
      final assetId =
          'pokemon-menu-${entry.speciesId}-${entry.formId}-${artifact.hexDigest}';
      final existingAsset =
          catalog.find(assetId) ?? catalog.findByLogicalPath(logicalPath);
      if (existingAsset != null &&
          (existingAsset.logicalPath != logicalPath ||
              existingAsset.artifact.digest != artifact.digest)) {
        conflicts.add({
          ...preview,
          'resolution': 'skip',
          'reason': 'asset_identity_conflict'
        });
        continue;
      }
      if (existingAsset != null && !changes.containsKey(logicalPath)) {
        List<int>? logicalBytes;
        for (final stored in snapshot.resourceStorageKeys.entries) {
          if (stored.value == logicalPath) {
            logicalBytes = snapshot.findResourceBytes(stored.key);
            break;
          }
        }
        if (logicalBytes != null &&
            ContentArtifactRef.fromBytes(logicalBytes,
                        mediaType: artifact.mediaType)
                    .digest !=
                artifact.digest) {
          throw AssetActionException(
            'pokemon.media.logical_asset_changed',
            'The Pokemon menu image differs from its catalog; resolve the authored change before importing new associations.',
            details: {'assetId': existingAsset.id, 'logicalPath': logicalPath},
          );
        }
        if (logicalBytes == null) {
          final resource =
              AuthoringResourceRef(kind: 'asset', id: existingAsset.id);
          changes[logicalPath] = AuthoringResourceChange(
            resource: resource,
            storageKey: logicalPath,
            beforeBytes: null,
            afterBytes: bytes,
          );
          diffs.add(AuthoringDiffEntry(
            operation: AuthoringDiffOperation.add,
            resource: resource,
            path: '/',
            after: existingAsset.toJson(),
          ));
          repaired.add({...preview, 'reason': 'missing_logical_image'});
        }
      }
      if (existingAsset == null) {
        final record = AssetRecord(
            id: assetId,
            logicalPath: logicalPath,
            artifact: artifact,
            tags: const ['pokemon', 'menu']);
        final projection =
            const AssetImportProjector().project(catalog, record: record);
        catalog = projection.catalog;
        catalogChanged = true;
        final resource = AuthoringResourceRef(kind: 'asset', id: assetId);
        changes[logicalPath] = AuthoringResourceChange(
            resource: resource,
            storageKey: logicalPath,
            beforeBytes: null,
            afterBytes: bytes);
        diffs.add(AuthoringDiffEntry(
            operation: AuthoringDiffOperation.add,
            resource: resource,
            path: '/',
            after: record.toJson()));
      }
      final blobPath = assetBlobStorageKey(artifact);
      final existingBlob = snapshot
          .findResourceBytes(assetBlobResourceIdentity(artifact.digest));
      if (existingBlob == null && !changes.containsKey(blobPath)) {
        changes[blobPath] = AuthoringResourceChange(
            resource:
                AuthoringResourceRef(kind: 'assetBlob', id: artifact.digest),
            storageKey: blobPath,
            beforeBytes: null,
            afterBytes: bytes);
      } else if (existingBlob != null &&
          ContentArtifactRef.fromBytes(existingBlob,
                      mediaType: artifact.mediaType)
                  .digest !=
              artifact.digest) {
        throw const FormatException('Existing Pokemon media blob is corrupt.');
      }
      variant[entry.role.name] = logicalPath;
      variants[entry.formId] = variant;
      document['variants'] = variants;
      changedMedia.add(identity);
      added.add(preview);
    }
    if (catalogChanged) {
      final resource =
          AuthoringResourceRef(kind: 'assetCatalog', id: 'project');
      changes[assetCatalogStorageKey] = AuthoringResourceChange(
          resource: resource,
          storageKey: assetCatalogStorageKey,
          beforeBytes: catalogBefore,
          afterBytes: _encode(catalog.toJson()));
    }
    for (final identity in changedMedia) {
      final before = snapshot.findResourceBytes(identity);
      final resource = AuthoringResourceRef(
          kind: 'pokemonDocument',
          id: 'media:${identity.substring('pokemonMedia:'.length)}');
      changes[mediaPaths[identity]!] = AuthoringResourceChange(
          resource: resource,
          storageKey: mediaPaths[identity]!,
          beforeBytes: before,
          afterBytes: _encode(media[identity]!));
      diffs.add(AuthoringDiffEntry(
          operation: before == null
              ? AuthoringDiffOperation.add
              : AuthoringDiffOperation.replace,
          resource: resource,
          path: '/',
          before: before == null ? null : _json(before),
          after: media[identity]));
    }
    for (final change in changes.values) {
      if (!diffs.any((entry) =>
          entry.resource.kind == change.resource.kind &&
          entry.resource.id == change.resource.id)) {
        diffs.add(AuthoringDiffEntry(
          operation: change.beforeBytes == null
              ? AuthoringDiffOperation.add
              : AuthoringDiffOperation.replace,
          resource: change.resource,
          path: '/',
          after: {'byteLength': change.afterBytes!.length},
        ));
      }
    }
    return AuthoringMutationDraft(
      changeSet: changes.isEmpty
          ? AuthoringChangeSet.noChanges()
          : AuthoringChangeSet(
              changes: changes.values, diff: AuthoringDiff(diffs)),
      preview: {
        'operation': 'pokemon.media.import',
        'added': added,
        'preserved': preserved,
        'repaired': repaired,
        'conflicts': conflicts,
        'idempotent': changes.isEmpty,
        'conflictPolicy': 'preserve',
      },
    );
  }
}

String _identity(String value) {
  if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]*$').hasMatch(value)) {
    throw const FormatException(
        'Pokemon media identities must be exact safe identifiers.');
  }
  return value;
}

Map<String, dynamic> _json(List<int> bytes) {
  final raw = jsonDecode(utf8.decode(bytes));
  if (raw is! Map) {
    throw const FormatException('Expected Pokemon JSON document.');
  }
  return Map<String, dynamic>.from(raw);
}

List<int> _encode(Map<String, Object?> json) =>
    utf8.encode('${const JsonEncoder.withIndent('  ').convert(json)}\n');
