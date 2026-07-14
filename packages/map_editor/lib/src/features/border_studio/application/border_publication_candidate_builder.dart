import 'dart:collection';

import 'package:map_core/map_core.dart';

import 'border_asset_snapshot_service.dart';

enum BorderPublicationCandidateErrorCode {
  targetRecordMissing,
  staleDraftRevision,
  sourceElementMissing,
  primitiveSnapshotMissing,
  unexpectedPrimitiveSnapshot,
  sourceSurfacePresetMissing,
  groundSnapshotRoleMissing,
  unexpectedGroundSnapshots,
  snapshotIdentityConflict,
}

final class BorderPublicationCandidateException implements Exception {
  const BorderPublicationCandidateException({
    required this.code,
    required this.userMessage,
    this.primitiveId,
    this.sourceElementId,
    this.sourceSurfacePresetId,
    this.surfaceRole,
    this.snapshotId,
  });

  final BorderPublicationCandidateErrorCode code;
  final String userMessage;
  final String? primitiveId;
  final String? sourceElementId;
  final String? sourceSurfacePresetId;
  final SurfaceVariantRole? surfaceRole;
  final String? snapshotId;

  @override
  String toString() =>
      'BorderPublicationCandidateException.${code.name}: $userMessage';
}

/// Fully assembled, still-uncommitted input for [BorderPublicationRequest].
///
/// Integrity entries prove the in-memory preparations used by this candidate.
/// The publication transaction remains responsible for validating and staging
/// [files] before it atomically replaces the manifest.
final class BorderPublicationCandidate {
  BorderPublicationCandidate({
    required this.nextManifest,
    required this.revision,
    required List<BorderSnapshotFilePayload> files,
    required Map<String, BorderVisualSnapshotIntegrity> snapshotIntegrity,
    required Map<String, String> primitiveSnapshotIdsByPrimitiveId,
    required Map<SurfaceVariantRole, String> groundSnapshotIdsByRole,
  })  : files = List<BorderSnapshotFilePayload>.unmodifiable(files),
        snapshotIntegrity = UnmodifiableMapView(
          Map<String, BorderVisualSnapshotIntegrity>.from(snapshotIntegrity),
        ),
        primitiveSnapshotIdsByPrimitiveId = UnmodifiableMapView(
          Map<String, String>.from(primitiveSnapshotIdsByPrimitiveId),
        ),
        groundSnapshotIdsByRole = UnmodifiableMapView(
          Map<SurfaceVariantRole, String>.from(groundSnapshotIdsByRole),
        );

  final ProjectManifest nextManifest;
  final int revision;
  final List<BorderSnapshotFilePayload> files;
  final Map<String, BorderVisualSnapshotIntegrity> snapshotIntegrity;
  final Map<String, String> primitiveSnapshotIdsByPrimitiveId;
  final Map<SurfaceVariantRole, String> groundSnapshotIdsByRole;
}

/// Builds the immutable published Border revision without performing I/O.
///
/// Primitive and Surface snapshot inputs must already have been prepared by
/// [BorderAssetSnapshotService]. Ground inputs are deliberately supplied by
/// logical [SurfaceVariantRole]; this builder never reads a Surface atlas or
/// invents filesystem state.
final class BorderPublicationCandidateBuilder {
  const BorderPublicationCandidateBuilder();

  BorderPublicationCandidate build({
    required ProjectManifest manifest,
    required BorderBlueprintRecord draftRecord,
    required Map<String, BorderAssetSnapshotPreparation>
        primitiveSnapshotsByPrimitiveId,
    Map<SurfaceVariantRole, BorderAssetSnapshotPreparation> groundSnapshotsByRole =
        const <SurfaceVariantRole, BorderAssetSnapshotPreparation>{},
  }) {
    final recordIndex = manifest.borderCatalog.records.indexWhere(
      (record) => record.id == draftRecord.id,
    );
    if (recordIndex < 0) {
      throw const BorderPublicationCandidateException(
        code: BorderPublicationCandidateErrorCode.targetRecordMissing,
        userMessage:
            'Enregistrez le brouillon dans le projet avant de le publier.',
      );
    }

    final currentRecord = manifest.borderCatalog.records[recordIndex];
    final currentRevision = currentRecord.latestPublished?.revision ?? 0;
    if (draftRecord.draft.baseRevision != currentRevision) {
      throw const BorderPublicationCandidateException(
        code: BorderPublicationCandidateErrorCode.staleDraftRevision,
        userMessage:
            'Le brouillon ne repose plus sur la dernière révision publiée. Rechargez-le avant de publier.',
      );
    }

    final elementIds = <String>{
      for (final element in manifest.elements) element.id,
    };
    final draftPrimitives = draftRecord.draft.definition.primitives;
    for (final primitive in draftPrimitives) {
      if (!elementIds.contains(primitive.sourceElementId)) {
        throw BorderPublicationCandidateException(
          code: BorderPublicationCandidateErrorCode.sourceElementMissing,
          userMessage:
              'La primitive « ${primitive.id} » doit référencer un élément existant du projet.',
          primitiveId: primitive.id,
          sourceElementId: primitive.sourceElementId,
        );
      }
    }

    final draftPrimitiveIds = <String>{
      for (final primitive in draftPrimitives) primitive.id,
    };
    for (final primitiveId in primitiveSnapshotsByPrimitiveId.keys) {
      if (!draftPrimitiveIds.contains(primitiveId)) {
        throw BorderPublicationCandidateException(
          code: BorderPublicationCandidateErrorCode.unexpectedPrimitiveSnapshot,
          userMessage:
              'La préparation de snapshot « $primitiveId » ne correspond à aucune primitive du brouillon.',
          primitiveId: primitiveId,
        );
      }
    }

    final snapshots = List<BorderVisualSnapshot>.from(
      manifest.borderCatalog.visualSnapshots,
    );
    final snapshotsById = <String, BorderVisualSnapshot>{
      for (final snapshot in snapshots) snapshot.id: snapshot,
    };
    final files = <BorderSnapshotFilePayload>[];
    final integrity = <String, BorderVisualSnapshotIntegrity>{};

    String registerSnapshot(BorderAssetSnapshotPreparation preparation) {
      final snapshot = preparation.snapshot;
      final known = snapshotsById[snapshot.id];
      if (known != null && known != snapshot) {
        throw BorderPublicationCandidateException(
          code: BorderPublicationCandidateErrorCode.snapshotIdentityConflict,
          userMessage:
              'Un snapshot existant possède le même identifiant mais un contenu différent.',
          snapshotId: snapshot.id,
        );
      }
      if (known == null) {
        snapshots.add(snapshot);
        snapshotsById[snapshot.id] = snapshot;
        files.addAll(preparation.files);
      }
      integrity[snapshot.id] = BorderVisualSnapshotIntegrity(
        snapshotId: snapshot.id,
        metadataValid: true,
        filesPresent: true,
        contentFingerprintMatches: true,
      );
      return snapshot.id;
    }

    final publishedPrimitives = <BorderPublishedPrimitive>[];
    final primitiveBindings = <String, String>{};
    for (final primitive in draftPrimitives) {
      if (primitive.weight == 0) {
        continue;
      }
      final preparation = primitiveSnapshotsByPrimitiveId[primitive.id];
      if (preparation == null) {
        throw BorderPublicationCandidateException(
          code: BorderPublicationCandidateErrorCode.primitiveSnapshotMissing,
          userMessage:
              'Réanalysez la primitive « ${primitive.id} » avant de publier.',
          primitiveId: primitive.id,
        );
      }
      final snapshotId = registerSnapshot(preparation);
      primitiveBindings[primitive.id] = snapshotId;
      publishedPrimitives.add(
        BorderPublishedPrimitive(
          id: primitive.id,
          sourceElementId: primitive.sourceElementId,
          visualSnapshotId: snapshotId,
          role: primitive.role,
          weight: primitive.weight,
          anchorPx: primitive.anchorPx,
          transforms: primitive.transforms,
          publishedMetrics: preparation.metrics,
        ),
      );
    }

    final draftGround = draftRecord.draft.definition.ground;
    BorderPublishedGround? publishedGround;
    final groundBindings = <SurfaceVariantRole, String>{};
    if (draftGround == null) {
      if (groundSnapshotsByRole.isNotEmpty) {
        throw const BorderPublicationCandidateException(
          code: BorderPublicationCandidateErrorCode.unexpectedGroundSnapshots,
          userMessage:
              'Retirez les snapshots de sol : ce brouillon n’utilise pas de bande Surface.',
        );
      }
    } else {
      if (manifest.surfaceCatalog.presetById(
            draftGround.sourceSurfacePresetId,
          ) ==
          null) {
        throw BorderPublicationCandidateException(
          code: BorderPublicationCandidateErrorCode.sourceSurfacePresetMissing,
          userMessage:
              'La Surface « ${draftGround.sourceSurfacePresetId} » n’existe plus dans le projet.',
          sourceSurfacePresetId: draftGround.sourceSurfacePresetId,
        );
      }
      for (final role in standardSurfaceVariantRoleOrder) {
        final preparation = groundSnapshotsByRole[role];
        if (preparation == null) {
          throw BorderPublicationCandidateException(
            code: BorderPublicationCandidateErrorCode.groundSnapshotRoleMissing,
            userMessage:
                'Préparez la variante Surface « ${role.name} » avant de publier.',
            surfaceRole: role,
          );
        }
        groundBindings[role] = registerSnapshot(preparation);
      }
      publishedGround = BorderPublishedGround(
        sourceSurfacePresetId: draftGround.sourceSurfacePresetId,
        edgeBandCells: draftGround.edgeBandCells,
        visualSnapshotIdsByRole: groundBindings,
      );
    }

    final draftDefinition = draftRecord.draft.definition;
    final nextRevision = currentRevision + 1;
    final publishedDefinition = BorderBlueprintPublishedDefinition(
      name: draftDefinition.name,
      previewSeed: draftDefinition.previewSeed,
      template: draftDefinition.template,
      primitives: publishedPrimitives,
      defaults: draftDefinition.defaults,
      ground: publishedGround,
      categoryId: draftDefinition.categoryId,
      sortOrder: draftDefinition.sortOrder,
    );
    final replacement = BorderBlueprintRecord(
      id: currentRecord.id,
      draft: BorderBlueprintDraft(
        baseRevision: nextRevision,
        definition: draftDefinition,
      ),
      latestPublished: BorderBlueprintRevision(
        revision: nextRevision,
        definition: publishedDefinition,
      ),
      isDeprecated: currentRecord.isDeprecated,
    );
    final records = List<BorderBlueprintRecord>.from(
      manifest.borderCatalog.records,
    );
    records[recordIndex] = replacement;
    final nextCatalog = ProjectBorderCatalog(
      formatVersion: manifest.borderCatalog.formatVersion,
      records: records,
      visualSnapshots: snapshots,
    );

    return BorderPublicationCandidate(
      nextManifest: replaceProjectBorderCatalog(manifest, nextCatalog),
      revision: nextRevision,
      files: files,
      snapshotIntegrity: integrity,
      primitiveSnapshotIdsByPrimitiveId: primitiveBindings,
      groundSnapshotIdsByRole: groundBindings,
    );
  }
}
