import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'resource_pack_import_preparer.dart';
import 'tileset_actions.dart';

final class ResourcePackActions {
  const ResourcePackActions({this.resolvePreparedImport});
  final ResourcePackPreparedImportResolver? resolvePreparedImport;
  static final descriptors = [
    AuthoringActionDescriptor(
      id: 'resource_pack.import',
      version: 1,
      summary: 'Install one certified prepared asset pack additively',
      inputSchemaId: 'pokemap.authoring.resource_pack.import.input.v1',
      outputSchemaId: 'pokemap.authoring.visual_library.mutation.v1',
      riskLevel: AuthoringRiskLevel.medium,
      resourceKinds: const ['project', 'asset', 'assetBlob', 'assetCatalog'],
      capabilityIds: const [
        'authoring.visual_library',
        'authoring.resource_packs',
      ],
      requiredPermissions: const [
        AuthoringPermission.projectWrite,
        AuthoringPermission.assetWrite,
        AuthoringPermission.importRun,
      ],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
      extensions: const {
        'multiFileGuarantee': 'recoverable',
        'transferProtocol': 'pokemap.authoring.resource_pack.v2',
        'applyJobVerb': 'start_apply',
        'editorTransport': 'PARTIAL:P10/P11',
        'inputSchema': {
          'type': 'object',
          'additionalProperties': false,
          'required': ['preparedImportHandle'],
          'properties': {
            'preparedImportHandle': {
              'type': 'string',
              'minLength': 1,
              'maxLength': 128,
            },
          },
        },
      },
    ),
  ];
  Future<AuthoringMutationDraft> build(AuthoringPlanningContext context) async {
    final parameters = VisualLibraryParameters(context.request.parameters);
    parameters.allow(const {'preparedImportHandle'});
    final handle = parameters.string('preparedImportHandle');
    final resolve = resolvePreparedImport;
    if (resolve == null) {
      throw const ResourcePackImportException(
          'resource_pack.preparation_unavailable',
          'The canonical preparation service is unavailable.');
    }
    return resolve(context, handle);
  }
}
