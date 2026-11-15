import 'package:map_authoring/map_authoring.dart'
    show CatalogStorageException, TransactionFileGatewayException;
import 'package:map_authoring/map_authoring_local.dart'
    show LocalMapAuthoringMutationApi, ProjectHandle;

import '../domain/narrative_catalog_failure.dart';

const catalogNotWritableMessage =
    'Le dossier du projet n’est pas accessible en écriture. Votre brouillon est conservé.';
const catalogUnfinishedSaveMessage =
    'Un enregistrement précédent est resté inachevé. Rouvrez le projet pour le terminer ; votre brouillon est conservé.';
const catalogSaveFailedMessage =
    'L’enregistrement a échoué sans modifier le projet. Votre brouillon est conservé.';

String? catalogWriteFailureMessage(Object failure) => switch (failure) {
  TransactionFileGatewayException(code: 'transaction.io') =>
    catalogNotWritableMessage,
  CatalogStorageException(code: 'catalog.recovery_required') =>
    catalogUnfinishedSaveMessage,
  _ => null,
};

Future<NarrativeCatalogWriteFailure> unrecoveredCatalogWrite(
  LocalMapAuthoringMutationApi api,
  ProjectHandle project, {
  required String operationId,
  required Object failure,
}) async {
  final rolledBack = await _rolledBack(api, project, operationId);
  return NarrativeCatalogWriteFailure(
    rolledBack
        ? catalogWriteFailureMessage(failure) ?? catalogSaveFailedMessage
        : catalogUnfinishedSaveMessage,
  );
}

Future<bool> _rolledBack(
  LocalMapAuthoringMutationApi api,
  ProjectHandle project,
  String operationId,
) async {
  try {
    final status = await api.recoveryStatus(project, operationId: operationId);
    return switch (status['disposition']) {
      'notFound' => true,
      'completed' => status['committed'] == false,
      _ => false,
    };
  } on Object {
    return false;
  }
}
