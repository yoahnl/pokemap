import 'dart:typed_data';

import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../ports/artifact_store.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import 'canonical_border_snapshot_compiler.dart';
import 'map_lifecycle_adapter.dart';
import 'semantic_map_action_support.dart';

final class BorderCatalogActions {
  const BorderCatalogActions({
    required this.artifactStore,
    this.snapshotCompiler = const CanonicalBorderSnapshotCompiler(),
  });

  final ArtifactStore artifactStore;
  final CanonicalBorderSnapshotCompiler snapshotCompiler;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable(
    <AuthoringActionDescriptor>[
      _descriptor(
        'border.blueprint.delete',
        'Delete one never-published Border blueprint',
        risk: AuthoringRiskLevel.high,
      ),
      _descriptor(
        'border.blueprint.draft.upsert',
        'Create or replace one Border blueprint draft',
      ),
      _descriptor(
        'border.blueprint.publish',
        'Publish one Border blueprint with immutable visual snapshots',
        resourceKinds: const <String>[
          'project',
          'borderBlueprint',
          'borderSnapshot',
        ],
      ),
      _descriptor(
        'border.blueprint.set_deprecated',
        'Deprecate or reactivate one Border blueprint',
        risk: AuthoringRiskLevel.high,
      ),
    ]..sort((left, right) => left.id.compareTo(right.id)),
  );

  Future<AuthoringMutationDraft> build(
    AuthoringPlanningContext planning,
  ) async {
    if (planning.request.actionVersion != 1) {
      throw semanticFailure(
        'border.action_version_unsupported',
        'The requested Border catalog action version is unsupported.',
        details: <String, Object?>{
          'actionVersion': planning.request.actionVersion,
        },
      );
    }
    return switch (planning.request.actionId) {
      'border.blueprint.draft.upsert' => _upsertDraft(planning),
      'border.blueprint.delete' => _deleteBlueprint(planning),
      'border.blueprint.set_deprecated' => _setDeprecated(planning),
      'border.blueprint.publish' => await _publish(planning),
      _ => throw semanticFailure(
          'border.action_unsupported',
          'The requested Border catalog action is unsupported.',
          details: <String, Object?>{
            'actionId': planning.request.actionId,
          },
        ),
    };
  }

  AuthoringMutationDraft _upsertDraft(AuthoringPlanningContext planning) {
    final parameters = SemanticParameters(
      planning.request.parameters,
      allowed: const <String>{'record'},
    );
    final incoming = _decodeRecord(parameters.object('record'));
    if (incoming.latestPublished != null || incoming.isDeprecated) {
      throw semanticFailure(
        'border.blueprint.draft_payload_invalid',
        'Draft upsert accepts editable draft state only.',
        details: <String, Object?>{'blueprintId': incoming.id},
      );
    }
    final catalog = planning.snapshot.manifest.borderCatalog;
    final existing = catalog.recordById(incoming.id);
    final expectedBaseRevision = existing?.latestPublished?.revision ?? 0;
    if (incoming.draft.baseRevision != expectedBaseRevision) {
      throw semanticFailure(
        'border.blueprint.draft_stale',
        'The Border draft does not target the latest published revision.',
        details: <String, Object?>{
          'blueprintId': incoming.id,
          'draftBaseRevision': incoming.draft.baseRevision,
          'latestPublishedRevision': expectedBaseRevision,
        },
        remediation: const <String>[
          'Reload the blueprint and reapply the intended draft changes.',
        ],
      );
    }
    final replacement = BorderBlueprintRecord(
      id: incoming.id,
      draft: incoming.draft,
      latestPublished: existing?.latestPublished,
      isDeprecated: existing?.isDeprecated ?? false,
    );
    final records = <BorderBlueprintRecord>[
      for (final record in catalog.records)
        if (record.id != replacement.id) record,
      replacement,
    ]..sort((left, right) => left.id.compareTo(right.id));
    final projected = _replaceCatalog(
      planning.snapshot.manifest,
      records: records,
    );
    return _manifestMutation(
      planning,
      projected: projected,
      operation: 'border.blueprint.draft.upsert',
      path: '/borderCatalog/records/${replacement.id}/draft',
      before: existing == null
          ? null
          : encodeBorderBlueprintRecordJson(
              existing,
              formatVersion: catalog.formatVersion,
            ),
      after: encodeBorderBlueprintRecordJson(
        replacement,
        formatVersion: projected.borderCatalog.formatVersion,
      ),
    );
  }

  AuthoringMutationDraft _deleteBlueprint(AuthoringPlanningContext planning) {
    final parameters = SemanticParameters(
      planning.request.parameters,
      allowed: const <String>{'blueprintId'},
    );
    final blueprintId = parameters.string('blueprintId');
    final catalog = planning.snapshot.manifest.borderCatalog;
    final existing = catalog.recordById(blueprintId);
    if (existing == null) {
      throw semanticFailure(
        'border.blueprint.not_found',
        'The requested Border blueprint does not exist.',
        details: <String, Object?>{'blueprintId': blueprintId},
      );
    }
    if (existing.latestPublished != null) {
      throw semanticFailure(
        'border.blueprint.delete_published_forbidden',
        'Published Border blueprints must be deprecated instead of deleted.',
        details: <String, Object?>{'blueprintId': blueprintId},
        remediation: const <String>[
          'Deprecate the blueprint to hide it from new authoring choices.',
        ],
      );
    }
    final projected = _replaceCatalog(
      planning.snapshot.manifest,
      records: <BorderBlueprintRecord>[
        for (final record in catalog.records)
          if (record.id != blueprintId) record,
      ],
    );
    return _manifestMutation(
      planning,
      projected: projected,
      operation: 'border.blueprint.delete',
      path: '/borderCatalog/records/$blueprintId',
      before: encodeBorderBlueprintRecordJson(
        existing,
        formatVersion: catalog.formatVersion,
      ),
    );
  }

  AuthoringMutationDraft _setDeprecated(AuthoringPlanningContext planning) {
    final parameters = SemanticParameters(
      planning.request.parameters,
      allowed: const <String>{'blueprintId', 'isDeprecated'},
    );
    final blueprintId = parameters.string('blueprintId');
    final deprecated = parameters.boolean('isDeprecated');
    final catalog = planning.snapshot.manifest.borderCatalog;
    final existing = catalog.recordById(blueprintId);
    if (existing == null) {
      throw semanticFailure(
        'border.blueprint.not_found',
        'The requested Border blueprint does not exist.',
        details: <String, Object?>{'blueprintId': blueprintId},
      );
    }
    if (existing.latestPublished == null) {
      throw semanticFailure(
        'border.blueprint.deprecation_requires_publication',
        'Only published Border blueprints can be deprecated.',
        details: <String, Object?>{'blueprintId': blueprintId},
      );
    }
    final replacement = BorderBlueprintRecord(
      id: existing.id,
      draft: existing.draft,
      latestPublished: existing.latestPublished,
      isDeprecated: deprecated,
    );
    final projected = _replaceCatalog(
      planning.snapshot.manifest,
      records: <BorderBlueprintRecord>[
        for (final record in catalog.records)
          if (record.id == blueprintId) replacement else record,
      ],
    );
    return _manifestMutation(
      planning,
      projected: projected,
      operation: 'border.blueprint.set_deprecated',
      path: '/borderCatalog/records/$blueprintId/isDeprecated',
      before: existing.isDeprecated,
      after: deprecated,
    );
  }

  Future<AuthoringMutationDraft> _publish(
    AuthoringPlanningContext planning,
  ) async {
    final parameters = SemanticParameters(
      planning.request.parameters,
      allowed: const <String>{
        'blueprintId',
        'primitiveSources',
        'groundSources',
        'acceptedWarningCodes',
      },
    );
    final blueprintId = parameters.string('blueprintId');
    final catalog = planning.snapshot.manifest.borderCatalog;
    final current = catalog.recordById(blueprintId);
    if (current == null) {
      throw semanticFailure(
        'border.blueprint.not_found',
        'The requested Border blueprint does not exist.',
        details: <String, Object?>{'blueprintId': blueprintId},
      );
    }
    final currentRevision = current.latestPublished?.revision ?? 0;
    if (current.draft.baseRevision != currentRevision) {
      throw semanticFailure(
        'border.blueprint.draft_stale',
        'The Border draft does not target the latest published revision.',
        details: <String, Object?>{
          'blueprintId': blueprintId,
          'draftBaseRevision': current.draft.baseRevision,
          'latestPublishedRevision': currentRevision,
        },
      );
    }

    final primitiveSources = await _preparePrimitiveSources(
      parameters.list('primitiveSources'),
      current,
    );
    final draftPrimitives = current.draft.definition.primitives;
    final elementIds = <String>{
      for (final element in planning.snapshot.manifest.elements) element.id,
    };
    final publishedPrimitives = <BorderPublishedPrimitive>[];
    for (final primitive in draftPrimitives) {
      if (primitive.weight == 0) continue;
      if (!elementIds.contains(primitive.sourceElementId)) {
        throw semanticFailure(
          'border.blueprint.source_element_missing',
          'A Border primitive references an unavailable project element.',
          details: <String, Object?>{
            'blueprintId': blueprintId,
            'primitiveId': primitive.id,
            'sourceElementId': primitive.sourceElementId,
          },
        );
      }
      final preparation = primitiveSources[primitive.id];
      if (preparation == null) {
        throw semanticFailure(
          'border.blueprint.primitive_source_missing',
          'Every enabled Border primitive requires a staged visual source.',
          details: <String, Object?>{
            'blueprintId': blueprintId,
            'primitiveId': primitive.id,
          },
        );
      }
      if (preparation.metrics != primitive.currentMetrics) {
        throw semanticFailure(
          'border.blueprint.source_asset_diverged',
          'A Border source asset changed after the draft was analyzed.',
          details: <String, Object?>{
            'blueprintId': blueprintId,
            'primitiveId': primitive.id,
            'sourceElementId': primitive.sourceElementId,
            'expectedMetrics': encodeBorderPrimitiveAssetMetricsJson(
              primitive.currentMetrics,
            ),
            'actualMetrics': encodeBorderPrimitiveAssetMetricsJson(
              preparation.metrics,
            ),
          },
          remediation: const <String>[
            'Reanalyze the source and upsert the refreshed draft before publishing.',
          ],
        );
      }
      publishedPrimitives.add(
        BorderPublishedPrimitive(
          id: primitive.id,
          sourceElementId: primitive.sourceElementId,
          visualSnapshotId: preparation.snapshot.id,
          role: primitive.role,
          authoredOrientation: primitive.authoredOrientation,
          weight: primitive.weight,
          anchorPx: primitive.anchorPx,
          transforms: primitive.transforms,
          publishedMetrics: preparation.metrics,
        ),
      );
    }

    final groundPreparations = parameters.contains('groundSources')
        ? await _prepareGroundSources(
            parameters.list('groundSources'),
            current,
          )
        : const <BorderGroundVariantRole, CanonicalBorderSnapshotPreparation>{};
    final publishedGround = _publishedGround(
      planning.snapshot.manifest,
      current,
      groundPreparations,
    );
    final nextRevision = currentRevision + 1;
    final draftDefinition = current.draft.definition;
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
    final revision = BorderBlueprintRevision(
      revision: nextRevision,
      definition: publishedDefinition,
    );
    final replacement = BorderBlueprintRecord(
      id: current.id,
      draft: BorderBlueprintDraft(
        baseRevision: nextRevision,
        definition: draftDefinition,
      ),
      latestPublished: revision,
      isDeprecated: current.isDeprecated,
    );

    final preparations = <CanonicalBorderSnapshotPreparation>[
      ...primitiveSources.values,
      ...groundPreparations.values,
    ];
    final snapshotsById = <String, BorderVisualSnapshot>{
      for (final snapshot in catalog.visualSnapshots) snapshot.id: snapshot,
    };
    for (final preparation in preparations) {
      final existing = snapshotsById[preparation.snapshot.id];
      if (existing != null && existing != preparation.snapshot) {
        throw semanticFailure(
          'border.snapshot.identity_conflict',
          'A Border snapshot identity resolves to conflicting metadata.',
          details: <String, Object?>{
            'snapshotId': preparation.snapshot.id,
          },
        );
      }
      snapshotsById[preparation.snapshot.id] = preparation.snapshot;
    }
    final projected = _replaceCatalog(
      planning.snapshot.manifest,
      records: <BorderBlueprintRecord>[
        for (final record in catalog.records)
          if (record.id == blueprintId) replacement else record,
      ],
      visualSnapshots: snapshotsById.values.toList(growable: false)
        ..sort((left, right) => left.id.compareTo(right.id)),
    );

    final gallery = resolveBorderCanonicalGallery(
      blueprintId: blueprintId,
      blueprintRevision: revision,
      visualSnapshots: projected.borderCatalog.visualSnapshots,
      tileSizePx: GridSize(
        width: projected.settings.tileWidth,
        height: projected.settings.tileHeight,
      ),
    );
    final integrity = <String, BorderVisualSnapshotIntegrity>{
      for (final preparation in preparations)
        preparation.snapshot.id: BorderVisualSnapshotIntegrity(
          snapshotId: preparation.snapshot.id,
          metadataValid: true,
          filesPresent: true,
          contentFingerprintMatches: true,
        ),
    };
    final readiness = assessBorderPublicationReadiness(
      blueprintId: blueprintId,
      definition: publishedDefinition,
      resolverVersion: borderResolverVersion,
      project: projected,
      visualSnapshots: projected.borderCatalog.visualSnapshots,
      snapshotIntegrity: integrity,
      canonicalGalleryReport: gallery.report,
    );
    final diagnostics = <BorderDiagnostic>{
      ...gallery.resolutionDiagnostics.diagnostics,
      ...readiness.diagnosticReport.diagnostics,
    }.toList(growable: false)
      ..sort();
    final errors = diagnostics
        .where(
          (diagnostic) => diagnostic.severity == BorderDiagnosticSeverity.error,
        )
        .toList(growable: false);
    if (errors.isNotEmpty) {
      throw semanticFailure(
        'border.blueprint.publication_invalid',
        'The Border blueprint does not satisfy publication requirements.',
        details: <String, Object?>{
          'blueprintId': blueprintId,
          'diagnostics': <Object?>[
            for (final diagnostic in errors) _diagnosticJson(diagnostic),
          ],
        },
      );
    }
    final acceptedWarnings = parameters.contains('acceptedWarningCodes')
        ? _stringSet(parameters.list('acceptedWarningCodes'))
        : const <String>{};
    final warningCodes = <String>{
      for (final diagnostic in diagnostics)
        if (diagnostic.severity == BorderDiagnosticSeverity.warning)
          diagnostic.code,
    };
    final unacknowledged = warningCodes.difference(acceptedWarnings).toList()
      ..sort();
    final unexpected = acceptedWarnings.difference(warningCodes).toList()
      ..sort();
    if (unacknowledged.isNotEmpty || unexpected.isNotEmpty) {
      throw semanticFailure(
        'border.blueprint.publication_warnings_unacknowledged',
        'Border publication warnings must be acknowledged exactly.',
        details: <String, Object?>{
          'blueprintId': blueprintId,
          'unacknowledgedWarningCodes': unacknowledged,
          'unexpectedWarningCodes': unexpected,
        },
      );
    }

    return _publicationMutation(
      planning,
      projected: projected,
      before: current,
      after: replacement,
      preparations: preparations,
      diagnostics: diagnostics,
    );
  }

  Future<Map<String, CanonicalBorderSnapshotPreparation>>
      _preparePrimitiveSources(
    List<Object?> values,
    BorderBlueprintRecord record,
  ) async {
    final primitives = <String, BorderPrimitiveDraft>{
      for (final primitive in record.draft.definition.primitives)
        primitive.id: primitive,
    };
    final result = <String, CanonicalBorderSnapshotPreparation>{};
    for (var index = 0; index < values.length; index += 1) {
      final source = _object(values[index], 'primitiveSources[$index]');
      final primitiveId = _requiredString(source, 'primitiveId');
      final primitive = primitives[primitiveId];
      if (primitive == null || result.containsKey(primitiveId)) {
        throw semanticFailure(
          'border.blueprint.primitive_source_invalid',
          'A primitive source is duplicated or does not belong to the draft.',
          details: <String, Object?>{'primitiveId': primitiveId},
        );
      }
      _requireExactKeys(
        source,
        allowed: const <String>{'primitiveId', 'frames'},
        path: 'primitiveSources[$index]',
      );
      result[primitiveId] = snapshotCompiler.prepare(
        sourceElementId: primitive.sourceElementId,
        anchorPx: primitive.anchorPx,
        frames:
            await _sourceFrames(source['frames'], 'primitiveSources[$index]'),
      );
    }
    return result;
  }

  Future<Map<BorderGroundVariantRole, CanonicalBorderSnapshotPreparation>>
      _prepareGroundSources(
    List<Object?> values,
    BorderBlueprintRecord record,
  ) async {
    final ground = record.draft.definition.ground;
    if (ground == null && values.isNotEmpty) {
      throw semanticFailure(
        'border.blueprint.ground_source_unexpected',
        'The Border draft does not define a Smart Tile ground band.',
      );
    }
    final result =
        <BorderGroundVariantRole, CanonicalBorderSnapshotPreparation>{};
    for (var index = 0; index < values.length; index += 1) {
      final source = _object(values[index], 'groundSources[$index]');
      _requireExactKeys(
        source,
        allowed: const <String>{'role', 'frames'},
        path: 'groundSources[$index]',
      );
      final roleName = _requiredString(source, 'role');
      final role = standardBorderGroundVariantRoleOrder
          .where((candidate) => candidate.name == roleName)
          .firstOrNull;
      if (role == null || result.containsKey(role)) {
        throw semanticFailure(
          'border.blueprint.ground_source_invalid',
          'A ground source role is invalid or duplicated.',
          details: <String, Object?>{'role': roleName},
        );
      }
      result[role] = snapshotCompiler.prepare(
        sourceElementId: ground!.sourceSmartTilePresetId,
        frames: await _sourceFrames(source['frames'], 'groundSources[$index]'),
      );
    }
    return result;
  }

  Future<List<CanonicalBorderSourceFrame>> _sourceFrames(
    Object? value,
    String path,
  ) async {
    if (value is! List || value.isEmpty) {
      throw semanticFailure(
        'border.snapshot.frames_required',
        'A Border visual source requires at least one frame.',
        details: <String, Object?>{'path': '$path.frames'},
      );
    }
    final result = <CanonicalBorderSourceFrame>[];
    for (var index = 0; index < value.length; index += 1) {
      final frame = _object(value[index], '$path.frames[$index]');
      _requireExactKeys(
        frame,
        allowed: const <String>{
          'artifactHandle',
          'sourceProjectRelativePath',
          'sourceRectPx',
          'durationMs',
          'transparentColorArgb',
          'decodedFrameIndex',
        },
        path: '$path.frames[$index]',
      );
      final handle = _requiredString(frame, 'artifactHandle');
      final artifact = artifactStore.inspect(handle);
      if (artifact == null) {
        throw semanticFailure(
          'artifact.unknown',
          'The Border source artifact handle is unknown or expired.',
          details: <String, Object?>{'artifactHandle': handle},
        );
      }
      result.add(
        CanonicalBorderSourceFrame(
          sourceProjectRelativePath:
              _requiredString(frame, 'sourceProjectRelativePath'),
          encodedImageBytes: await artifactStore.read(handle),
          sourceRectPx: frame['sourceRectPx'] == null
              ? null
              : _rect(
                  frame['sourceRectPx'], '$path.frames[$index].sourceRectPx'),
          durationMs: _optionalInt(frame, 'durationMs'),
          transparentColorArgb: _optionalInt(frame, 'transparentColorArgb'),
          decodedFrameIndex: _optionalInt(frame, 'decodedFrameIndex') ?? 0,
        ),
      );
    }
    return result;
  }
}

BorderPublishedGround? _publishedGround(
  ProjectManifest manifest,
  BorderBlueprintRecord record,
  Map<BorderGroundVariantRole, CanonicalBorderSnapshotPreparation> preparations,
) {
  final draftGround = record.draft.definition.ground;
  if (draftGround == null) {
    if (preparations.isNotEmpty) {
      throw semanticFailure(
        'border.blueprint.ground_source_unexpected',
        'The Border draft does not define a Smart Tile ground band.',
      );
    }
    return null;
  }
  final preset = manifest.smartTileCatalog.presets
      .where((candidate) => candidate.id == draftGround.sourceSmartTilePresetId)
      .firstOrNull;
  if (preset == null || preset.status != SmartTilePresetStatus.published) {
    throw semanticFailure(
      'border.blueprint.ground_preset_missing',
      'The Border ground source must be a published Smart Tile preset.',
      details: <String, Object?>{
        'sourceSmartTilePresetId': draftGround.sourceSmartTilePresetId,
      },
    );
  }
  final missing = standardBorderGroundVariantRoleOrder
      .where((role) => !preparations.containsKey(role))
      .map((role) => role.name)
      .toList(growable: false);
  if (missing.isNotEmpty) {
    throw semanticFailure(
      'border.blueprint.ground_sources_incomplete',
      'Every canonical Border ground role requires a staged visual source.',
      details: <String, Object?>{'missingRoles': missing},
    );
  }
  return BorderPublishedGround(
    sourceSmartTilePresetId: draftGround.sourceSmartTilePresetId,
    edgeBandCells: draftGround.edgeBandCells,
    visualSnapshotIdsByRole: <BorderGroundVariantRole, String>{
      for (final role in standardBorderGroundVariantRoleOrder)
        role: preparations[role]!.snapshot.id,
    },
  );
}

AuthoringMutationDraft _publicationMutation(
  AuthoringPlanningContext planning, {
  required ProjectManifest projected,
  required BorderBlueprintRecord before,
  required BorderBlueprintRecord after,
  required List<CanonicalBorderSnapshotPreparation> preparations,
  required List<BorderDiagnostic> diagnostics,
}) {
  final projectRef = _projectResource(planning);
  final changes = <AuthoringResourceChange>[
    AuthoringResourceChange(
      resource: projectRef,
      storageKey: 'project.json',
      beforeBytes: planning.snapshot.resourceBytes('project'),
      afterBytes: encodeProjectAuthoringDocument(
        planning.snapshot,
        projected,
      ),
    ),
  ];
  final diff = <AuthoringDiffEntry>[
    AuthoringDiffEntry(
      operation: AuthoringDiffOperation.replace,
      resource: projectRef,
      path: '/borderCatalog/records/${after.id}',
      before: encodeBorderBlueprintRecordJson(
        before,
        formatVersion: planning.snapshot.manifest.borderCatalog.formatVersion,
      ),
      after: encodeBorderBlueprintRecordJson(
        after,
        formatVersion: projected.borderCatalog.formatVersion,
      ),
    ),
  ];
  final knownSnapshotIds = planning
      .snapshot.manifest.borderCatalog.visualSnapshots
      .map((snapshot) => snapshot.id)
      .toSet();
  final filesByPath = <String, Uint8List>{};
  for (final preparation in preparations) {
    if (knownSnapshotIds.contains(preparation.snapshot.id)) continue;
    for (final file in preparation.files) {
      final existing = filesByPath[file.relativePath];
      if (existing != null && !_sameBytes(existing, file.bytes)) {
        throw semanticFailure(
          'border.snapshot.payload_conflict',
          'Two Border snapshots resolve to conflicting immutable files.',
          details: <String, Object?>{'relativePath': file.relativePath},
        );
      }
      filesByPath[file.relativePath] = file.bytes;
    }
  }
  for (final entry in filesByPath.entries) {
    final resource = AuthoringResourceRef(
      kind: 'borderSnapshot',
      id: entry.key,
    );
    changes.add(
      AuthoringResourceChange(
        resource: resource,
        storageKey: entry.key,
        beforeBytes: null,
        afterBytes: entry.value,
      ),
    );
    diff.add(
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.add,
        resource: resource,
        path: '/',
        after: <String, Object?>{
          'relativePath': entry.key,
          'byteLength': entry.value.length,
        },
      ),
    );
  }
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: changes,
      diff: AuthoringDiff(diff),
    ),
    preview: <String, Object?>{
      'operation': 'border.blueprint.publish',
      'blueprintId': after.id,
      'publishedRevision': after.latestPublished!.revision,
      'primitiveSnapshotIdsByPrimitiveId': <String, Object?>{
        for (final primitive in after.latestPublished!.definition.primitives)
          primitive.id: primitive.visualSnapshotId,
      },
      'groundSnapshotIdsByRole': <String, Object?>{
        for (final entry in after.latestPublished!.definition.ground
                ?.visualSnapshotIdsByRole.entries ??
            const <MapEntry<BorderGroundVariantRole, String>>[])
          entry.key.name: entry.value,
      },
      'diagnosticCount': diagnostics.length,
      'projectWidePreflight': 'passed',
    },
  );
}

AuthoringMutationDraft _manifestMutation(
  AuthoringPlanningContext planning, {
  required ProjectManifest projected,
  required String operation,
  required String path,
  Object? before,
  Object? after,
}) {
  final beforeBytes = planning.snapshot.resourceBytes('project');
  final afterBytes = encodeProjectAuthoringDocument(
    planning.snapshot,
    projected,
  );
  if (_sameBytes(beforeBytes, afterBytes)) {
    throw semanticFailure(
      'border.blueprint.no_change',
      'The Border catalog mutation changes nothing.',
    );
  }
  final project = _projectResource(planning);
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: <AuthoringResourceChange>[
        AuthoringResourceChange(
          resource: project,
          storageKey: 'project.json',
          beforeBytes: beforeBytes,
          afterBytes: afterBytes,
        ),
      ],
      diff: AuthoringDiff(<AuthoringDiffEntry>[
        AuthoringDiffEntry(
          operation: operation.endsWith('.delete')
              ? AuthoringDiffOperation.remove
              : before == null
                  ? AuthoringDiffOperation.add
                  : AuthoringDiffOperation.replace,
          resource: project,
          path: path,
          before: before,
          after: after,
        ),
      ]),
    ),
    preview: <String, Object?>{
      'operation': operation,
      'path': path,
      'projectWidePreflight': 'passed',
    },
  );
}

AuthoringActionDescriptor _descriptor(
  String id,
  String summary, {
  AuthoringRiskLevel risk = AuthoringRiskLevel.medium,
  List<String> resourceKinds = const <String>[
    'project',
    'borderBlueprint',
  ],
}) =>
    AuthoringActionDescriptor(
      id: id,
      version: 1,
      summary: summary,
      inputSchemaId: 'pokemap.authoring.$id.input.v1',
      outputSchemaId: 'pokemap.authoring.border.mutation.v1',
      riskLevel: risk,
      resourceKinds: resourceKinds,
      capabilityIds: const <String>['authoring.borders'],
      requiredPermissions: const <AuthoringPermission>[
        AuthoringPermission.projectWrite,
      ],
      guarantees: const <AuthoringGuarantee>[
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.atomic,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
      extensions: const <String, Object?>{
        'catalogFormatVersion':
            ProjectBorderCatalog.latestSupportedFormatVersion,
        'projectWidePreflight': true,
        'artifactSnapshots': true,
      },
    );

ProjectBorderCatalog _catalog({
  required ProjectBorderCatalog current,
  required List<BorderBlueprintRecord> records,
  List<BorderVisualSnapshot>? visualSnapshots,
}) {
  final minimum = minimumBorderCatalogFormatVersionForRecords(records);
  return ProjectBorderCatalog(
    formatVersion:
        current.formatVersion < minimum ? minimum : current.formatVersion,
    records: records,
    visualSnapshots: visualSnapshots ?? current.visualSnapshots,
  );
}

ProjectManifest _replaceCatalog(
  ProjectManifest manifest, {
  required List<BorderBlueprintRecord> records,
  List<BorderVisualSnapshot>? visualSnapshots,
}) =>
    replaceProjectBorderCatalog(
      manifest,
      _catalog(
        current: manifest.borderCatalog,
        records: records,
        visualSnapshots: visualSnapshots,
      ),
    );

BorderBlueprintRecord _decodeRecord(Map<String, Object?> json) {
  try {
    return decodeBorderBlueprintRecordJson(
      json,
      formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
    );
  } on Object catch (error) {
    throw semanticFailure(
      'border.blueprint.request_invalid',
      'The Border blueprint document is invalid.',
      details: <String, Object?>{
        'validationType': error.runtimeType.toString(),
      },
    );
  }
}

AuthoringResourceRef _projectResource(AuthoringPlanningContext planning) {
  final revision = planning.snapshot.resourceFingerprints['project'];
  if (revision == null) {
    throw semanticFailure(
      'border.project_preimage_missing',
      'The project manifest pre-image is unavailable.',
    );
  }
  return AuthoringResourceRef(
    kind: 'project',
    id: 'project',
    revision: revision,
  );
}

Map<String, Object?> _object(Object? value, String path) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw semanticFailure(
      'border.blueprint.request_invalid',
      'A Border action parameter must be a JSON object.',
      details: <String, Object?>{'path': path},
    );
  }
  return Map<String, Object?>.from(value);
}

void _requireExactKeys(
  Map<String, Object?> value, {
  required Set<String> allowed,
  required String path,
}) {
  final unknown = value.keys.where((key) => !allowed.contains(key)).toList()
    ..sort();
  if (unknown.isNotEmpty) {
    throw semanticFailure(
      'border.blueprint.request_invalid',
      'A Border action parameter contains unsupported fields.',
      details: <String, Object?>{
        'path': path,
        'unknownParameters': unknown,
      },
    );
  }
}

String _requiredString(Map<String, Object?> value, String key) {
  final result = value[key];
  if (result is! String || result.isEmpty || result != result.trim()) {
    throw semanticFailure(
      'border.blueprint.request_invalid',
      'A Border action string parameter is invalid.',
      details: <String, Object?>{'parameter': key},
    );
  }
  return result;
}

int? _optionalInt(Map<String, Object?> value, String key) {
  final result = value[key];
  if (result == null) return null;
  if (result is! int) {
    throw semanticFailure(
      'border.blueprint.request_invalid',
      'A Border action integer parameter is invalid.',
      details: <String, Object?>{'parameter': key},
    );
  }
  return result;
}

BorderPixelRect _rect(Object? value, String path) {
  final object = _object(value, path);
  _requireExactKeys(
    object,
    allowed: const <String>{'x', 'y', 'width', 'height'},
    path: path,
  );
  int field(String key) {
    final value = object[key];
    if (value is! int) {
      throw semanticFailure(
        'border.blueprint.request_invalid',
        'A Border source rectangle is invalid.',
        details: <String, Object?>{'path': '$path.$key'},
      );
    }
    return value;
  }

  return BorderPixelRect(
    x: field('x'),
    y: field('y'),
    width: field('width'),
    height: field('height'),
  );
}

Set<String> _stringSet(List<Object?> values) {
  final result = <String>{};
  for (var index = 0; index < values.length; index += 1) {
    final value = values[index];
    if (value is! String || value.isEmpty || value != value.trim()) {
      throw semanticFailure(
        'border.blueprint.request_invalid',
        'Warning codes must be nonblank strings.',
        details: <String, Object?>{'index': index},
      );
    }
    if (!result.add(value)) {
      throw semanticFailure(
        'border.blueprint.request_invalid',
        'Warning codes must not be duplicated.',
        details: <String, Object?>{'warningCode': value},
      );
    }
  }
  return result;
}

Map<String, Object?> _diagnosticJson(BorderDiagnostic diagnostic) =>
    <String, Object?>{
      'code': diagnostic.code,
      'severity': diagnostic.severity.name,
      'phase': diagnostic.phase.name,
      'scope': diagnostic.scope.name,
      if (diagnostic.blueprintId != null) 'blueprintId': diagnostic.blueprintId,
      'parameters': diagnostic.parameters,
      'suggestedAction': diagnostic.suggestedAction,
    };

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
