import 'package:map_core/map_core.dart' show ProjectModel3dEntry;

import '../application/model_resource_rules.dart';
import '../domain/model_resource_port.dart';
import '../domain/model_source_picker.dart';
import '../domain/resource_port.dart';
import 'resource_navigation.dart';

Future<void> importStudioModel(
  ResourceNavigation navigation, {
  required PickModelSource picker,
}) async {
  if (navigation.isDisposed ||
      navigation.busy ||
      navigation.port is! ModelResourcePort) {
    return;
  }
  if (navigation.pendingReceipt != null) {
    navigation.setImportError(
      'Actualisez la publication précédente avant d’importer un modèle.',
    );
    return;
  }
  navigation.setImportBusy(true);
  try {
    final source = await picker();
    if (source == null || navigation.isDisposed) return;
    final receipt = await (navigation.port as ModelResourcePort).importModel(
      sourcePath: source.path,
      name: source.name,
    );
    await navigation.accept(receipt);
  } on ResourceFailure catch (failure) {
    navigation.pendingReceipt = failure.partialReceipt;
    if (!navigation.isDisposed) navigation.setImportError(failure.message);
  } on Object catch (failure) {
    if (!navigation.isDisposed) navigation.setImportError('$failure');
  } finally {
    if (!navigation.isDisposed) navigation.setImportBusy(false);
  }
}

Future<ResourceMutationReceipt?> replaceStudioModelSource(
  ResourceNavigation navigation,
  String modelId, {
  required PickModelSource picker,
}) async {
  if (navigation.isDisposed ||
      navigation.busy ||
      navigation.port is! ModelResourcePort) {
    return null;
  }
  if (navigation.pendingReceipt != null) {
    navigation.setImportError(
      'Actualisez la publication précédente avant de remplacer un modèle.',
    );
    return null;
  }
  navigation.error = null;
  navigation.setImportBusy(true);
  try {
    final source = await picker();
    if (source == null || navigation.isDisposed) return null;
    final receipt = await (navigation.port as ModelResourcePort)
        .replaceModelSource(modelId: modelId, sourcePath: source.path);
    await navigation.accept(receipt);
    return receipt;
  } on ResourceFailure catch (failure) {
    navigation.pendingReceipt = failure.partialReceipt;
    if (!navigation.isDisposed) navigation.setImportError(failure.message);
  } on Object catch (failure) {
    if (!navigation.isDisposed) navigation.setImportError('$failure');
  } finally {
    if (!navigation.isDisposed) navigation.setImportBusy(false);
  }
  return null;
}

Map<String, int> openModelOccurrences(
  ResourceNavigation navigation,
  String modelId,
) => {
  for (final document in navigation.workspace.documents.values)
    if ((document.current.spatialScene?.instances
                .where((instance) => instance.modelId == modelId)
                .length ??
            0)
        case final count when count > 0)
      document.current.name: count,
};

class ModelDefinitionWorkflow {
  ModelDefinitionWorkflow({required this.navigation, required this.isActive});
  final ResourceNavigation navigation;
  final bool Function() isActive;
  final _acknowledged = <String>{};

  Future<void> configure(
    ProjectModel3dEntry model,
    Map<String, Object?> fields, {
    required Future<bool> Function(Map<String, int>) confirmShared,
  }) async {
    if (!_acknowledged.contains(model.id)) {
      final occurrences = openModelOccurrences(navigation, model.id);
      if (occurrences.isNotEmpty) {
        if (!await confirmShared(occurrences)) {
          throw const ResourceFailure(
            'Modification annulée : la définition partagée n’a pas changé.',
          );
        }
        if (!isActive() || navigation.isDisposed) return;
        _acknowledged.add(model.id);
      }
    }
    if (!isActive() || navigation.isDisposed) return;
    await navigation.mutate(
      'model3d.configure',
      modelConfigurePayload(model.id, fields),
    );
  }

  Future<bool> remove(
    ProjectModel3dEntry model, {
    required Future<bool> Function() confirm,
  }) async {
    final problem = navigation.modelRemovalProblem(model.id);
    if (problem != null) throw ResourceFailure(problem);
    if (!await confirm() || !isActive() || navigation.isDisposed) return false;
    final currentProblem = navigation.modelRemovalProblem(model.id);
    if (currentProblem != null || navigation.busy) {
      throw ResourceFailure(
        currentProblem ?? 'Une opération est déjà en cours.',
      );
    }
    navigation.setImportBusy(true);
    try {
      await navigation.accept(
        await (navigation.port as ModelResourcePort).deleteModel(model.id),
      );
      return isActive();
    } on ResourceFailure catch (failure) {
      navigation.pendingReceipt = failure.partialReceipt;
      rethrow;
    } finally {
      if (!navigation.isDisposed) navigation.setImportBusy(false);
    }
  }
}
