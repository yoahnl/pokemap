import 'package:map_core/map_core.dart';
import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import 'project_media_store.dart';

final class PresentationMediaConfigurationException implements Exception {
  PresentationMediaConfigurationException(
    this.code,
    this.message, {
    Map<String, Object?> details = const <String, Object?>{},
  }) : details = Map.unmodifiable(details);

  final String code;
  final String message;
  final Map<String, Object?> details;

  @override
  String toString() =>
      'PresentationMediaConfigurationException($code): $message';
}

final class PresentationMediaConfigurationActions {
  const PresentationMediaConfigurationActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable(
    <AuthoringActionDescriptor>[
      _mediaManagementDescriptor('delete'),
      _mediaManagementDescriptor('rename'),
      AuthoringActionDescriptor(
        id: 'presentationMedia.configure',
        version: 1,
        summary: 'Configure Presentation media rights and fallback metadata',
        inputSchemaId: 'pokemap.authoring.presentationMedia.configure.input.v1',
        outputSchemaId:
            'pokemap.authoring.presentationMedia.configure.output.v1',
        riskLevel: AuthoringRiskLevel.low,
        resourceKinds: const <String>['presentationMedia'],
        capabilityIds: const <String>['authoring.presentation_media'],
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
      ),
    ],
  );

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    if (context.request.actionId == 'presentationMedia.delete' ||
        context.request.actionId == 'presentationMedia.rename') {
      return _managePresentationMedia(context);
    }
    if (context.request.actionId != 'presentationMedia.configure') {
      throw PresentationMediaConfigurationException(
        'presentation_media.action_unsupported',
        'The requested Presentation media action is unsupported.',
      );
    }
    final parameters = _ConfigurationParameters(context.request.parameters);
    final beforeBytes = context.snapshot.findResourceBytes(
      projectMediaCatalogResourceIdentity,
    );
    if (beforeBytes == null) {
      throw PresentationMediaConfigurationException(
        'presentation_media.catalog_missing',
        'The project media catalog does not exist.',
      );
    }
    final before = decodeProjectMediaCatalogBytes(beforeBytes);
    final mediaId = parameters.string('mediaId');
    final current = before.find(mediaId);
    if (current == null) {
      throw PresentationMediaConfigurationException(
        'presentation_media.missing',
        'The requested Presentation media does not exist.',
        details: <String, Object?>{'mediaId': mediaId},
      );
    }
    late final ProjectMediaAsset configured;
    try {
      configured = current.configure(
        posterMediaId: parameters.optionalString('posterMediaId'),
        captions: parameters.captions(),
        fallbackMediaId: parameters.optionalString('fallbackMediaId'),
        provenance: ProjectMediaProvenance.fromJson(
          parameters.object('provenance'),
        ),
        license: ProjectMediaLicense.fromJson(parameters.object('license')),
      );
    } on FormatException catch (error) {
      throw PresentationMediaConfigurationException(
        'presentation_media.request_invalid',
        error.message,
      );
    } on ArgumentError catch (error) {
      throw PresentationMediaConfigurationException(
        'presentation_media.request_invalid',
        error.message.toString(),
      );
    }
    final after = before.replace(configured);
    final graph = PresentationReferenceGraph.build(mediaCatalog: after);
    final diagnostics = graph.diagnostics.where((diagnostic) {
      return diagnostic.target.kind == PresentationReferenceKind.media &&
          (diagnostic.owner == null ||
              diagnostic.owner!.kind == PresentationReferenceKind.media);
    }).toList();
    if (diagnostics.isNotEmpty) {
      throw PresentationMediaConfigurationException(
        'presentation_media.configuration_invalid',
        'The Presentation media configuration contains invalid references.',
        details: <String, Object?>{
          'diagnostics':
              diagnostics.map((diagnostic) => diagnostic.toJson()).toList(),
        },
      );
    }
    final resource = AuthoringResourceRef(
      kind: 'presentationMediaCatalog',
      id: 'project',
      revision: context
          .snapshot.resourceFingerprints[projectMediaCatalogResourceIdentity],
    );
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: <AuthoringResourceChange>[
          AuthoringResourceChange(
            resource: resource,
            storageKey: projectMediaCatalogStorageKey,
            beforeBytes: beforeBytes,
            afterBytes: encodeProjectMediaCatalogBytes(after),
          ),
        ],
        diff: AuthoringDiff(<AuthoringDiffEntry>[
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.replace,
            resource: resource,
            path: '/entries/$mediaId',
            before: current.toJson(),
            after: configured.toJson(),
          ),
        ]),
      ),
      preview: <String, Object?>{
        'operation': 'presentationMedia.configure',
        'media': configured.toJson(),
      },
      referenceImpact: <String, Object?>{
        'mediaId': mediaId,
        'posterMediaId': configured.posterMediaId,
        'fallbackMediaId': configured.fallbackMediaId,
        'captionMediaIds':
            configured.captions.map((caption) => caption.mediaId).toList(),
      },
    );
  }
}

final class _ConfigurationParameters {
  _ConfigurationParameters(Map<String, Object?> values)
      : _values = Map.unmodifiable(values) {
    const expected = <String>{
      'mediaId',
      'posterMediaId',
      'fallbackMediaId',
      'captions',
      'provenance',
      'license',
    };
    final keys = _values.keys.toSet();
    if (keys.length != expected.length || !keys.containsAll(expected)) {
      throw PresentationMediaConfigurationException(
        'presentation_media.request_invalid',
        'The Presentation media configuration parameters are incomplete.',
      );
    }
  }

  final Map<String, Object?> _values;

  String string(String key) {
    final value = _values[key];
    if (value is! String || value.isEmpty || value.trim() != value) {
      throw PresentationMediaConfigurationException(
        'presentation_media.request_invalid',
        'Parameter $key must be a nonblank trimmed string.',
      );
    }
    return value;
  }

  String? optionalString(String key) {
    final value = _values[key];
    if (value == null) return null;
    return string(key);
  }

  Map<String, Object?> object(String key) {
    final value = _values[key];
    if (value is! Map || value.keys.any((item) => item is! String)) {
      throw PresentationMediaConfigurationException(
        'presentation_media.request_invalid',
        'Parameter $key must be an object.',
      );
    }
    return Map<String, Object?>.from(value);
  }

  List<ProjectMediaCaption> captions() {
    final value = _values['captions'];
    if (value is! List) {
      throw PresentationMediaConfigurationException(
        'presentation_media.request_invalid',
        'Parameter captions must be a list.',
      );
    }
    return value.map((item) {
      if (item is! Map || item.keys.any((key) => key is! String)) {
        throw PresentationMediaConfigurationException(
          'presentation_media.request_invalid',
          'Every caption must be an object.',
        );
      }
      return ProjectMediaCaption.fromJson(Map<String, Object?>.from(item));
    }).toList();
  }
}

AuthoringActionDescriptor _mediaManagementDescriptor(String operation) =>
    AuthoringActionDescriptor(
      id: 'presentationMedia.$operation',
      version: 1,
      summary: operation == 'delete'
          ? 'Delete an unreferenced media definition while retaining its source asset'
          : 'Rename one media without changing its source, rights or fallback metadata',
      inputSchemaId: 'pokemap.authoring.presentationMedia.$operation.input.v1',
      outputSchemaId:
          'pokemap.authoring.presentationMedia.$operation.output.v1',
      riskLevel: operation == 'delete'
          ? AuthoringRiskLevel.high
          : AuthoringRiskLevel.low,
      resourceKinds: const ['presentationMedia'],
      capabilityIds: const ['authoring.presentation_media'],
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.atomic,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable
      ],
      extensions: {
        'inputSchema': {
          'type': 'object',
          'additionalProperties': false,
          'required': [
            'mediaId',
            'expectedMedia',
            if (operation == 'rename') 'label'
          ],
          'properties': {
            'mediaId': {'type': 'string', 'minLength': 1},
            'expectedMedia': {'type': 'object'},
            if (operation == 'rename')
              'label': {'type': 'string', 'minLength': 1}
          },
        }
      },
    );

AuthoringMutationDraft _managePresentationMedia(
    AuthoringPlanningContext context) {
  final deleting = context.request.actionId == 'presentationMedia.delete';
  final p = context.request.parameters;
  final keys = {'mediaId', 'expectedMedia', if (!deleting) 'label'};
  if (p.length != keys.length ||
      !p.keys.toSet().containsAll(keys) ||
      p['mediaId'] is! String ||
      (p['mediaId'] as String).trim().isEmpty ||
      p['mediaId'] != (p['mediaId'] as String).trim() ||
      p['expectedMedia'] is! Map) {
    throw PresentationMediaConfigurationException(
        'presentation_media.request_invalid',
        'A media identity and its explicit current baseline are required.');
  }
  final bytes =
      context.snapshot.findResourceBytes(projectMediaCatalogResourceIdentity);
  if (bytes == null) {
    throw PresentationMediaConfigurationException(
        'presentation_media.catalog_missing',
        'The project media catalog does not exist.');
  }
  final catalog = decodeProjectMediaCatalogBytes(bytes);
  final id = p['mediaId'] as String;
  final current = catalog.find(id);
  if (current == null) {
    throw PresentationMediaConfigurationException('presentation_media.missing',
        'The requested Presentation media does not exist.',
        details: {'mediaId': id});
  }
  if (!const DeepCollectionEquality()
      .equals(current.toJson(), p['expectedMedia'])) {
    throw PresentationMediaConfigurationException(
        'presentation_media.baseline_changed',
        'The media changed after its baseline was read.',
        details: {'mediaId': id});
  }
  ProjectMediaAsset? after;
  if (deleting) {
    final graph = PresentationReferenceGraph.build(
        cinematics: context.snapshot.manifest.presentationCinematics,
        scenes: context.snapshot.manifest.scenes,
        mediaCatalog: catalog);
    final deletion = graph.planDeletion(PresentationReferenceKey.media(id));
    if (!deletion.canDelete) {
      throw PresentationMediaConfigurationException(
          'presentation_media.references_blocking',
          'The media is still referenced and cannot be deleted.',
          details: deletion.toJson());
    }
  } else {
    final label = p['label'];
    if (label is! String || label.trim().isEmpty || label != label.trim()) {
      throw PresentationMediaConfigurationException(
          'presentation_media.request_invalid',
          'The media label must be nonblank and trimmed.');
    }
    after = ProjectMediaAsset.fromJson({...current.toJson(), 'label': label});
    if (const DeepCollectionEquality()
        .equals(after.toJson(), current.toJson())) {
      return AuthoringMutationDraft(
          changeSet: AuthoringChangeSet.noChanges(),
          preview: {
            'operation': context.request.actionId,
            'mediaId': id,
            'noOp': true
          });
    }
  }
  final updated = deleting
      ? ProjectMediaCatalog(
          entries: catalog.entries.where((entry) => entry.id != id))
      : catalog.replace(after!);
  final resource = AuthoringResourceRef(
      kind: 'presentationMediaCatalog',
      id: 'project',
      revision: context
          .snapshot.resourceFingerprints[projectMediaCatalogResourceIdentity]);
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
        changes: [
          AuthoringResourceChange(
              resource: resource,
              storageKey: projectMediaCatalogStorageKey,
              beforeBytes: bytes,
              afterBytes: encodeProjectMediaCatalogBytes(updated))
        ],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
              operation: deleting
                  ? AuthoringDiffOperation.remove
                  : AuthoringDiffOperation.replace,
              resource: resource,
              path: '/entries/$id',
              before: current.toJson(),
              after: after?.toJson())
        ])),
    preview: {
      'operation': context.request.actionId,
      'mediaId': id,
      'sourceAssetId': current.sourceAssetId,
      'sourceAssetRetained': true,
      if (after != null) 'media': after.toJson()
    },
    referenceImpact: {
      'mediaId': id,
      'sourceAssetId': current.sourceAssetId,
      'sourceAssetRetained': true
    },
  );
}
