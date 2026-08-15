import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'narrative_action_support.dart';
import 'presentation_cinematic_template_actions.dart';

final class CinematicLibraryAuthoringException implements Exception {
  CinematicLibraryAuthoringException(
    this.code,
    this.message, {
    Map<String, Object?> details = const {},
  }) : details = Map.unmodifiable(details);

  final String code;
  final String message;
  final Map<String, Object?> details;

  @override
  String toString() => 'CinematicLibraryAuthoringException($code): $message';
}

final class CinematicLibraryActions {
  const CinematicLibraryActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    _descriptor(
      'cinematicLibraryAsset.create',
      'Create and place one cinematic library asset',
      'cinematicLibraryEntry',
    ),
    _descriptor(
      'cinematicLibraryAsset.duplicate',
      'Duplicate and place one cinematic library asset',
      'cinematicLibraryEntry',
    ),
    _descriptor(
      'cinematicLibraryAsset.delete',
      'Delete one cinematic and its library placement',
      'cinematicLibraryEntry',
      risk: AuthoringRiskLevel.high,
    ),
    _descriptor(
      'cinematicLibraryFolder.create',
      'Create one cinematic library folder',
      'cinematicLibraryFolder',
    ),
    _descriptor(
      'cinematicLibraryFolder.rename',
      'Rename one cinematic library folder',
      'cinematicLibraryFolder',
    ),
    _descriptor(
      'cinematicLibraryFolder.move',
      'Move one cinematic library folder',
      'cinematicLibraryFolder',
    ),
    _descriptor(
      'cinematicLibraryFolder.reorder',
      'Reorder one cinematic library folder',
      'cinematicLibraryFolder',
    ),
    _descriptor(
      'cinematicLibraryFolder.setArchived',
      'Archive or restore one cinematic library folder',
      'cinematicLibraryFolder',
    ),
    _descriptor(
      'cinematicLibraryFolder.delete',
      'Delete one empty cinematic library folder',
      'cinematicLibraryFolder',
      risk: AuthoringRiskLevel.high,
    ),
    _descriptor(
      'cinematicLibraryEntry.place',
      'Place one cinematic in its family library',
      'cinematicLibraryEntry',
    ),
    _descriptor(
      'cinematicLibraryEntry.reorder',
      'Reorder one cinematic library entry',
      'cinematicLibraryEntry',
    ),
    _descriptor(
      'cinematicLibraryEntry.setArchived',
      'Archive or restore one cinematic library entry',
      'cinematicLibraryEntry',
    ),
    _descriptor(
      'cinematicLibraryEntry.remove',
      'Remove one cinematic placement from the library catalog',
      'cinematicLibraryEntry',
      risk: AuthoringRiskLevel.high,
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    if (context.snapshot.manifest.version != ProjectVersion.v7) {
      throw CinematicLibraryAuthoringException(
        'cinematic_library.project_v7_required',
        'Cinematic library authoring requires ProjectVersion.v7.',
        details: {
          'projectVersion': context.snapshot.manifest.version.name,
        },
      );
    }
    try {
      final mutation = _buildMutation(context);
      ProjectValidator.validate(mutation.project);
      return narrativeProjectDraft(
        context.snapshot,
        mutation.project,
        operation: context.request.actionId,
        path: mutation.path,
        before: mutation.before,
        after: mutation.after,
        preview: <String, Object?>{
          'resourceKind': mutation.resourceKind,
          ...mutation.preview,
        },
      );
    } on CinematicLibraryAuthoringException {
      rethrow;
    } on CinematicLibraryCatalogMutationException catch (error) {
      throw CinematicLibraryAuthoringException(
        error.code,
        error.message,
        details: error.details,
      );
    } on ValidationException catch (error) {
      throw CinematicLibraryAuthoringException(
        error.code ?? 'cinematic_library.validation_failed',
        error.message,
        details: error.details,
      );
    } on ArgumentError catch (error) {
      throw CinematicLibraryAuthoringException(
        'cinematic_library.request_invalid',
        error.message?.toString() ?? 'The request is invalid.',
      );
    } on FormatException catch (error) {
      throw CinematicLibraryAuthoringException(
        'cinematic_library.request_invalid',
        error.message.toString(),
      );
    }
  }
}

_CinematicLibraryMutation _buildMutation(AuthoringPlanningContext context) {
  const operations = CinematicLibraryCatalogOperations();
  final project = context.snapshot.manifest;
  final catalog = project.cinematicLibraryCatalog;
  final parameters = context.request.parameters;
  switch (context.request.actionId) {
    case 'cinematicLibraryAsset.create':
      return _createLibraryAsset(context, operations);
    case 'cinematicLibraryAsset.duplicate':
      return _duplicateLibraryAsset(context, operations);
    case 'cinematicLibraryAsset.delete':
      return _deleteLibraryAsset(context, operations);
    case 'cinematicLibraryFolder.create':
      _requireExactParameters(
        parameters,
        const {
          'folderId',
          'family',
          'name',
          'parentFolderId',
          'targetIndex',
        },
      );
      final folderId = _string(parameters, 'folderId');
      final updated = operations.createFolder(
        catalog,
        folderId: folderId,
        family: _family(parameters),
        name: _string(parameters, 'name'),
        parentFolderId: _nullableString(parameters, 'parentFolderId'),
        targetIndex: _integer(parameters, 'targetIndex'),
      );
      return _folderMutation(
        project,
        updated,
        folderId: folderId,
        before: null,
        after: updated.requireFolder(folderId).toJson(),
      );
    case 'cinematicLibraryFolder.rename':
      _requireExactParameters(parameters, const {'folderId', 'name'});
      final folderId = _string(parameters, 'folderId');
      final before = catalog.requireFolder(folderId);
      final updated = operations.renameFolder(
        catalog,
        folderId: folderId,
        name: _string(parameters, 'name'),
      );
      return _folderMutation(
        project,
        updated,
        folderId: folderId,
        before: before.toJson(),
        after: updated.requireFolder(folderId).toJson(),
      );
    case 'cinematicLibraryFolder.move':
      _requireExactParameters(
        parameters,
        const {'folderId', 'targetParentFolderId', 'targetIndex'},
      );
      return _moveFolder(
        project,
        operations,
        folderId: _string(parameters, 'folderId'),
        targetParentFolderId: _nullableString(
          parameters,
          'targetParentFolderId',
        ),
        targetIndex: _integer(parameters, 'targetIndex'),
      );
    case 'cinematicLibraryFolder.reorder':
      _requireExactParameters(parameters, const {'folderId', 'targetIndex'});
      final folderId = _string(parameters, 'folderId');
      return _moveFolder(
        project,
        operations,
        folderId: folderId,
        targetParentFolderId: catalog.requireFolder(folderId).parentFolderId,
        targetIndex: _integer(parameters, 'targetIndex'),
      );
    case 'cinematicLibraryFolder.setArchived':
      _requireExactParameters(parameters, const {'folderId', 'isArchived'});
      final folderId = _string(parameters, 'folderId');
      final before = catalog.requireFolder(folderId);
      final updated = operations.setFolderArchived(
        catalog,
        folderId: folderId,
        isArchived: _boolean(parameters, 'isArchived'),
      );
      return _folderMutation(
        project,
        updated,
        folderId: folderId,
        before: before.toJson(),
        after: updated.requireFolder(folderId).toJson(),
      );
    case 'cinematicLibraryFolder.delete':
      _requireExactParameters(parameters, const {'folderId'});
      final folderId = _string(parameters, 'folderId');
      final before = catalog.requireFolder(folderId);
      final updated = operations.deleteFolder(catalog, folderId: folderId);
      return _folderMutation(
        project,
        updated,
        folderId: folderId,
        before: before.toJson(),
        after: null,
      );
    case 'cinematicLibraryEntry.place':
      _requireExactParameters(
        parameters,
        const {
          'family',
          'cinematicId',
          'targetFolderId',
          'targetIndex',
        },
      );
      final family = _family(parameters);
      final cinematicId = _string(parameters, 'cinematicId');
      _requireCinematic(project, family, cinematicId);
      final before = catalog.entryFor(family, cinematicId);
      final updated = operations.placeCinematic(
        catalog,
        family: family,
        cinematicId: cinematicId,
        targetFolderId: _nullableString(parameters, 'targetFolderId'),
        targetIndex: _integer(parameters, 'targetIndex'),
      );
      return _entryMutation(
        project,
        updated,
        family: family,
        cinematicId: cinematicId,
        before: before?.toJson(),
        after: updated.entryFor(family, cinematicId)!.toJson(),
      );
    case 'cinematicLibraryEntry.reorder':
      _requireExactParameters(
        parameters,
        const {'family', 'cinematicId', 'targetIndex'},
      );
      final family = _family(parameters);
      final cinematicId = _string(parameters, 'cinematicId');
      final before = _requireEntry(catalog, family, cinematicId);
      final updated = operations.placeCinematic(
        catalog,
        family: family,
        cinematicId: cinematicId,
        targetFolderId: before.folderId,
        targetIndex: _integer(parameters, 'targetIndex'),
      );
      return _entryMutation(
        project,
        updated,
        family: family,
        cinematicId: cinematicId,
        before: before.toJson(),
        after: updated.entryFor(family, cinematicId)!.toJson(),
      );
    case 'cinematicLibraryEntry.setArchived':
      _requireExactParameters(
        parameters,
        const {'family', 'cinematicId', 'isArchived'},
      );
      final family = _family(parameters);
      final cinematicId = _string(parameters, 'cinematicId');
      final before = _requireEntry(catalog, family, cinematicId);
      final updated = operations.setCinematicArchived(
        catalog,
        family: family,
        cinematicId: cinematicId,
        isArchived: _boolean(parameters, 'isArchived'),
      );
      return _entryMutation(
        project,
        updated,
        family: family,
        cinematicId: cinematicId,
        before: before.toJson(),
        after: updated.entryFor(family, cinematicId)!.toJson(),
      );
    case 'cinematicLibraryEntry.remove':
      _requireExactParameters(parameters, const {'family', 'cinematicId'});
      final family = _family(parameters);
      final cinematicId = _string(parameters, 'cinematicId');
      final before = _requireEntry(catalog, family, cinematicId);
      final updated = operations.removeCinematic(
        catalog,
        family: family,
        cinematicId: cinematicId,
      );
      return _entryMutation(
        project,
        updated,
        family: family,
        cinematicId: cinematicId,
        before: before.toJson(),
        after: null,
      );
    default:
      throw CinematicLibraryAuthoringException(
        'cinematic_library.action_unsupported',
        'The requested cinematic library action is unsupported.',
        details: {'actionId': context.request.actionId},
      );
  }
}

_CinematicLibraryMutation _createLibraryAsset(
  AuthoringPlanningContext context,
  CinematicLibraryCatalogOperations operations,
) {
  final parameters = context.request.parameters;
  final family = _family(parameters);
  final expected = switch (family) {
    CinematicLibraryFamily.world => const <String>{
        'family',
        'cinematicId',
        'title',
        'targetFolderId',
        'targetIndex',
        'startingPoint',
      },
    CinematicLibraryFamily.presentation => const <String>{
        'family',
        'cinematicId',
        'title',
        'targetFolderId',
        'targetIndex',
        'templateId',
        'templateVersion',
      },
  };
  _requireExactParameters(parameters, expected);
  final project = context.snapshot.manifest;
  final cinematicId = _string(parameters, 'cinematicId');
  final title = _string(parameters, 'title');
  _requireAvailableCinematicId(project, family, cinematicId);
  final withAsset = switch (family) {
    CinematicLibraryFamily.world => project.copyWith(
        cinematics: <CinematicAsset>[
          ...project.cinematics,
          CinematicAsset(
            id: cinematicId,
            title: title,
            timeline: _worldStartingTimeline(
              _string(parameters, 'startingPoint'),
            ),
          ),
        ],
      ),
    CinematicLibraryFamily.presentation => project.copyWith(
        presentationCinematics: <PresentationCinematicAsset>[
          ...project.presentationCinematics,
          instantiatePresentationCinematicTemplate(
            PresentationCinematicTemplateCatalog.canonical().require(
              _string(parameters, 'templateId'),
              version: _integer(parameters, 'templateVersion'),
            ),
            cinematicId: cinematicId,
            title: title,
            description: null,
          ),
        ],
      ),
  };
  final updatedCatalog = operations.placeCinematic(
    withAsset.cinematicLibraryCatalog,
    family: family,
    cinematicId: cinematicId,
    targetFolderId: _nullableString(parameters, 'targetFolderId'),
    targetIndex: _integer(parameters, 'targetIndex'),
  );
  return _assetMutation(
    project,
    withAsset.copyWith(cinematicLibraryCatalog: updatedCatalog),
    family: family,
    cinematicId: cinematicId,
    before: null,
    after: _encodedLibraryAsset(withAsset, family, cinematicId),
  );
}

_CinematicLibraryMutation _duplicateLibraryAsset(
  AuthoringPlanningContext context,
  CinematicLibraryCatalogOperations operations,
) {
  final parameters = context.request.parameters;
  _requireExactParameters(
    parameters,
    const <String>{
      'family',
      'cinematicId',
      'duplicateId',
      'title',
      'targetFolderId',
      'targetIndex',
    },
  );
  final project = context.snapshot.manifest;
  final family = _family(parameters);
  final cinematicId = _string(parameters, 'cinematicId');
  final duplicateId = _string(parameters, 'duplicateId');
  final title = _string(parameters, 'title');
  _requireAvailableCinematicId(project, family, duplicateId);
  final withAsset = switch (family) {
    CinematicLibraryFamily.world => project.copyWith(
        cinematics: <CinematicAsset>[
          ...project.cinematics,
          _duplicateWorldCinematic(
            _worldCinematic(project, cinematicId),
            duplicateId: duplicateId,
            title: title,
          ),
        ],
      ),
    CinematicLibraryFamily.presentation => project.copyWith(
        presentationCinematics: <PresentationCinematicAsset>[
          ...project.presentationCinematics,
          _duplicatePresentationCinematic(
            _presentationCinematic(project, cinematicId),
            duplicateId: duplicateId,
            title: title,
          ),
        ],
      ),
  };
  final updatedCatalog = operations.placeCinematic(
    withAsset.cinematicLibraryCatalog,
    family: family,
    cinematicId: duplicateId,
    targetFolderId: _nullableString(parameters, 'targetFolderId'),
    targetIndex: _integer(parameters, 'targetIndex'),
  );
  return _assetMutation(
    project,
    withAsset.copyWith(cinematicLibraryCatalog: updatedCatalog),
    family: family,
    cinematicId: duplicateId,
    before: null,
    after: _encodedLibraryAsset(withAsset, family, duplicateId),
  );
}

_CinematicLibraryMutation _deleteLibraryAsset(
  AuthoringPlanningContext context,
  CinematicLibraryCatalogOperations operations,
) {
  final parameters = context.request.parameters;
  _requireExactParameters(parameters, const <String>{'family', 'cinematicId'});
  final project = context.snapshot.manifest;
  final family = _family(parameters);
  final cinematicId = _string(parameters, 'cinematicId');
  final before = _encodedLibraryAsset(project, family, cinematicId);
  final withoutAsset = switch (family) {
    CinematicLibraryFamily.world => removeCinematicAsset(
        project,
        cinematicId,
      ).updatedProject,
    CinematicLibraryFamily.presentation => _deletePresentationCinematic(
        project,
        cinematicId,
      ),
  };
  final entry = withoutAsset.cinematicLibraryCatalog.entryFor(
    family,
    cinematicId,
  );
  final updatedCatalog = entry == null
      ? withoutAsset.cinematicLibraryCatalog
      : operations.removeCinematic(
          withoutAsset.cinematicLibraryCatalog,
          family: family,
          cinematicId: cinematicId,
        );
  return _assetMutation(
    project,
    withoutAsset.copyWith(cinematicLibraryCatalog: updatedCatalog),
    family: family,
    cinematicId: cinematicId,
    before: before,
    after: null,
  );
}

_CinematicLibraryMutation _assetMutation(
  ProjectManifest beforeProject,
  ProjectManifest afterProject, {
  required CinematicLibraryFamily family,
  required String cinematicId,
  required Object? before,
  required Object? after,
}) =>
    _CinematicLibraryMutation(
      project: afterProject,
      resourceKind: 'cinematicLibraryEntry',
      path: '/cinematicLibraryCatalog/assets/${family.name}/$cinematicId',
      before: before,
      after: after,
      preview: <String, Object?>{
        'family': family.name,
        'cinematicId': cinematicId,
        'catalogChanged': beforeProject.cinematicLibraryCatalog !=
            afterProject.cinematicLibraryCatalog,
      },
    );

CinematicTimeline _worldStartingTimeline(String startingPoint) =>
    switch (startingPoint) {
      'blank' => CinematicTimeline(),
      'establishingShot' => CinematicTimeline(
          steps: <CinematicTimelineStep>[
            CinematicTimelineStep(
              id: 'template.establishing.marker',
              kind: CinematicTimelineStepKind.marker,
              label: 'Plan d’établissement',
            ),
            CinematicTimelineStep(
              id: 'template.establishing.camera',
              kind: CinematicTimelineStepKind.camera,
              label: 'Installer le décor',
              durationMs: 1200,
            ),
          ],
        ),
      'dialogueBeat' => CinematicTimeline(
          steps: <CinematicTimelineStep>[
            CinematicTimelineStep(
              id: 'template.dialogue.marker',
              kind: CinematicTimelineStepKind.marker,
              label: 'Temps de dialogue',
            ),
            CinematicTimelineStep(
              id: 'template.dialogue.line',
              kind: CinematicTimelineStepKind.dialogueLine,
              label: 'Réplique à configurer',
              dialogueText: 'Dialogue à configurer',
              durationMs: 1000,
            ),
          ],
        ),
      _ => throw CinematicLibraryAuthoringException(
          'cinematic_library.starting_point_unknown',
          'The requested in-game cinematic starting point is unknown.',
          details: <String, Object?>{'startingPoint': startingPoint},
        ),
    };

CinematicAsset _duplicateWorldCinematic(
  CinematicAsset source, {
  required String duplicateId,
  required String title,
}) =>
    source.copyWith(
      id: duplicateId,
      title: title,
      timeline: CinematicTimeline(
        steps: <CinematicTimelineStep>[
          for (var index = 0; index < source.timeline.steps.length; index++)
            CinematicTimelineStep.fromJson(<String, Object?>{
              ...source.timeline.steps[index].toJson(),
              'id': '${duplicateId}_step_${index + 1}',
            }),
        ],
      ),
      metadata: Map<String, String>.from(source.metadata)
        ..remove(cinematicLibraryArchivedMetadataKey),
    );

PresentationCinematicAsset _duplicatePresentationCinematic(
  PresentationCinematicAsset source, {
  required String duplicateId,
  required String title,
}) {
  final encoded = encodePresentationCinematicAsset(source);
  final tracks = (encoded['tracks']! as List<Object?>)
      .cast<Map<String, Object?>>()
      .map(
        (track) => <String, Object?>{
          ...track,
          'clips': <Object?>[
            for (final clip in (track['clips']! as List<Object?>))
              <String, Object?>{
                ...(clip as Map<String, Object?>),
                'id': '$duplicateId-${clip['id']}',
              },
          ],
        },
      )
      .toList(growable: false);
  return decodePresentationCinematicAsset(<String, Object?>{
    ...encoded,
    'id': duplicateId,
    'title': title,
    'tracks': tracks,
  });
}

ProjectManifest _deletePresentationCinematic(
  ProjectManifest project,
  String cinematicId,
) {
  _presentationCinematic(project, cinematicId);
  final deletion = PresentationReferenceGraph.build(
    cinematics: project.presentationCinematics,
    scenes: project.scenes,
  ).planDeletion(PresentationReferenceKey.presentationCinematic(cinematicId));
  if (!deletion.canDelete) {
    throw CinematicLibraryAuthoringException(
      'cinematic_library.asset_in_use',
      'The Presentation cinematic is still referenced.',
      details: <String, Object?>{
        'usages': <Object?>[
          for (final usage in deletion.usages) usage.toJson(),
        ],
      },
    );
  }
  return project.copyWith(
    presentationCinematics: <PresentationCinematicAsset>[
      for (final cinematic in project.presentationCinematics)
        if (cinematic.id != cinematicId) cinematic,
    ],
  );
}

void _requireAvailableCinematicId(
  ProjectManifest project,
  CinematicLibraryFamily family,
  String cinematicId,
) {
  final exists = switch (family) {
    CinematicLibraryFamily.world =>
      project.cinematics.any((asset) => asset.id == cinematicId),
    CinematicLibraryFamily.presentation =>
      project.presentationCinematics.any((asset) => asset.id == cinematicId),
  };
  if (exists) {
    throw CinematicLibraryAuthoringException(
      'cinematic_library.asset_id_unavailable',
      'The requested cinematic identity already exists.',
      details: <String, Object?>{
        'family': family.name,
        'cinematicId': cinematicId,
      },
    );
  }
}

CinematicAsset _worldCinematic(ProjectManifest project, String cinematicId) {
  for (final cinematic in project.cinematics) {
    if (cinematic.id == cinematicId) return cinematic;
  }
  throw CinematicLibraryAuthoringException(
    'cinematic_library.asset_unknown',
    'The cinematic identity is unknown in the requested family.',
  );
}

PresentationCinematicAsset _presentationCinematic(
  ProjectManifest project,
  String cinematicId,
) {
  for (final cinematic in project.presentationCinematics) {
    if (cinematic.id == cinematicId) return cinematic;
  }
  throw CinematicLibraryAuthoringException(
    'cinematic_library.asset_unknown',
    'The cinematic identity is unknown in the requested family.',
  );
}

Object _encodedLibraryAsset(
  ProjectManifest project,
  CinematicLibraryFamily family,
  String cinematicId,
) =>
    switch (family) {
      CinematicLibraryFamily.world =>
        _worldCinematic(project, cinematicId).toJson(),
      CinematicLibraryFamily.presentation => encodePresentationCinematicAsset(
          _presentationCinematic(project, cinematicId),
        ),
    };

_CinematicLibraryMutation _moveFolder(
  ProjectManifest project,
  CinematicLibraryCatalogOperations operations, {
  required String folderId,
  required String? targetParentFolderId,
  required int targetIndex,
}) {
  final catalog = project.cinematicLibraryCatalog;
  final before = catalog.requireFolder(folderId);
  final updated = operations.moveFolder(
    catalog,
    folderId: folderId,
    targetParentFolderId: targetParentFolderId,
    targetIndex: targetIndex,
  );
  return _folderMutation(
    project,
    updated,
    folderId: folderId,
    before: before.toJson(),
    after: updated.requireFolder(folderId).toJson(),
  );
}

_CinematicLibraryMutation _folderMutation(
  ProjectManifest project,
  CinematicLibraryCatalog updated, {
  required String folderId,
  required Object? before,
  required Object? after,
}) =>
    _CinematicLibraryMutation(
      project: project.copyWith(cinematicLibraryCatalog: updated),
      resourceKind: 'cinematicLibraryFolder',
      path: '/cinematicLibraryCatalog/folders/$folderId',
      before: before,
      after: after,
      preview: {'folderId': folderId},
    );

_CinematicLibraryMutation _entryMutation(
  ProjectManifest project,
  CinematicLibraryCatalog updated, {
  required CinematicLibraryFamily family,
  required String cinematicId,
  required Object? before,
  required Object? after,
}) =>
    _CinematicLibraryMutation(
      project: project.copyWith(cinematicLibraryCatalog: updated),
      resourceKind: 'cinematicLibraryEntry',
      path: '/cinematicLibraryCatalog/entries/${family.name}/$cinematicId',
      before: before,
      after: after,
      preview: {'family': family.name, 'cinematicId': cinematicId},
    );

void _requireCinematic(
  ProjectManifest project,
  CinematicLibraryFamily family,
  String cinematicId,
) {
  final exists = switch (family) {
    CinematicLibraryFamily.world =>
      project.cinematics.any((cinematic) => cinematic.id == cinematicId),
    CinematicLibraryFamily.presentation => project.presentationCinematics.any(
        (cinematic) => cinematic.id == cinematicId,
      ),
  };
  if (!exists) {
    throw CinematicLibraryAuthoringException(
      'cinematic_library.asset_unknown',
      'The cinematic identity is unknown in the requested family.',
      details: {'family': family.name, 'cinematicId': cinematicId},
    );
  }
}

CinematicLibraryEntry _requireEntry(
  CinematicLibraryCatalog catalog,
  CinematicLibraryFamily family,
  String cinematicId,
) {
  final entry = catalog.entryFor(family, cinematicId);
  if (entry != null) return entry;
  throw CinematicLibraryAuthoringException(
    'cinematic_library.entry_unknown',
    'The cinematic library entry is unknown.',
    details: {'family': family.name, 'cinematicId': cinematicId},
  );
}

CinematicLibraryFamily _family(Map<String, Object?> parameters) {
  return CinematicLibraryFamily.fromJson(parameters['family']);
}

String _string(Map<String, Object?> parameters, String key) {
  final value = parameters[key];
  if (value is! String || value.trim().isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, key, 'must be a nonblank trimmed string');
  }
  return value;
}

String? _nullableString(Map<String, Object?> parameters, String key) {
  final value = parameters[key];
  if (value == null) return null;
  return _string(parameters, key);
}

int _integer(Map<String, Object?> parameters, String key) {
  final value = parameters[key];
  if (value is! int) {
    throw ArgumentError.value(value, key, 'must be an integer');
  }
  return value;
}

bool _boolean(Map<String, Object?> parameters, String key) {
  final value = parameters[key];
  if (value is! bool) {
    throw ArgumentError.value(value, key, 'must be a boolean');
  }
  return value;
}

void _requireExactParameters(
  Map<String, Object?> parameters,
  Set<String> expected,
) {
  final actual = parameters.keys.toSet();
  if (actual.length != expected.length || !actual.containsAll(expected)) {
    final missing = expected.difference(actual).toList()..sort();
    final unknown = actual.difference(expected).toList()..sort();
    throw ArgumentError.value(
      {'missing': missing, 'unknown': unknown},
      'parameters',
      'must match the action contract exactly',
    );
  }
}

final class _CinematicLibraryMutation {
  const _CinematicLibraryMutation({
    required this.project,
    required this.resourceKind,
    required this.path,
    required this.before,
    required this.after,
    required this.preview,
  });

  final ProjectManifest project;
  final String resourceKind;
  final String path;
  final Object? before;
  final Object? after;
  final Map<String, Object?> preview;
}

AuthoringActionDescriptor _descriptor(
  String id,
  String summary,
  String resourceKind, {
  AuthoringRiskLevel risk = AuthoringRiskLevel.low,
}) =>
    narrativeActionDescriptor(
      id,
      summary,
      resourceKinds: <String>[
        'project',
        'cinematicLibraryCatalog',
        resourceKind,
      ],
      risk: risk,
    );
