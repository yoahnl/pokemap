part of 'resource_navigation.dart';

Future<String?> publishResourceManagementChange(
  ResourceNavigation navigation,
  String revision,
  String action,
  Map<String, Object?> parameters, {
  ResourceItem? reveal,
  bool destructive = false,
}) async {
  try {
    final preparation = await navigation.prepareOperation(
      action,
      parameters,
      expectedSnapshotRevision: revision,
    );
    final project = await navigation.applyPrepared(
      preparation,
      confirmDestructive: destructive,
    );
    if (reveal != null) {
      final current = resourceCatalog(project)
          .where((entry) => entry.identity == reveal.identity)
          .firstOrNull;
      if (current != null) {
        navigation.library.reveal(current);
        navigation.library.revealPending = false;
        navigation.showLibrary();
      }
    }
    return null;
  } on Object catch (failure) {
    return '$failure';
  }
}

void selectResourceContainer(
  ResourceNavigation navigation,
  ResourceKind family,
  String id,
) {
  navigation.library.kind = family;
  navigation.library.category = id;
  navigation.showLibrary();
}

Future<String?> deleteResourceContainer(
  ResourceNavigation navigation,
  ResourceKind family,
  ResourceContainer entry,
) async {
  final revision = await navigation.captureResourceRevision();
  final error = await publishResourceManagementChange(
    navigation,
    revision,
    containerAction(family, 'delete'),
    {family == ResourceKind.images ? 'folderId' : 'categoryId': entry.id},
    destructive: true,
  );
  if (error == null &&
      navigation.library.kind == family &&
      navigation.library.category == entry.id) {
    navigation.library.category = '';
    navigation.showLibrary();
  }
  return error;
}
