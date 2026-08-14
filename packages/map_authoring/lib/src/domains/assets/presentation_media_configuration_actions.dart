import 'package:map_core/map_core.dart';

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
