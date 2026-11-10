part of 'resource_navigation.dart';

Future<String?> publishResourceLibraryChange(
  ResourceNavigation navigation,
  String action,
  Map<String, Object?> parameters, {
  bool destructive = false,
  String? expectedSnapshotRevision,
}) async {
  try {
    final revision =
        expectedSnapshotRevision ?? await navigation.captureResourceRevision();
    final preparation = await navigation.prepareOperation(
      action,
      parameters,
      expectedSnapshotRevision: revision,
    );
    await navigation.applyPrepared(
      preparation,
      confirmDestructive: destructive,
    );
    return null;
  } on Object catch (failure) {
    return '$failure';
  }
}
