import 'package:avelune_studio/features/map_workspace/domain/map_catalog_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'm2_ui_fixture.dart' show WidgetResourcePort;

class WidgetMapCatalogPort
    implements MapCatalogPort, MapCatalogPreparationPort {
  WidgetMapCatalogPort(this.delegate, this.tester);
  final MapCatalogPort delegate;
  final WidgetTester tester;

  Future<T> _run<T>(Future<T> Function() action) async {
    final result = await WidgetResourcePort.serial(tester, () async {
      try {
        return (value: await action(), error: null);
      } catch (error) {
        return (value: null, error: error);
      }
    });
    if (result!.error case final error?) throw error;
    return result.value as T;
  }

  @override
  Future<MapCatalogReceipt> mutate(
    ProjectSession session,
    String actionId,
    Map<String, Object?> parameters, {
    Map<String, String> expectedMapRevisions = const {},
    bool confirmDestructive = false,
    ProjectManifest? expectedManifest,
  }) => _run(
    () => delegate.mutate(
      session,
      actionId,
      parameters,
      expectedMapRevisions: expectedMapRevisions,
      confirmDestructive: confirmDestructive,
      expectedManifest: expectedManifest,
    ),
  );

  @override
  Future<void> reconcile(ProjectSession session, MapCatalogReceipt receipt) =>
      _run(() => delegate.reconcile(session, receipt));

  @override
  Future<MapCatalogPreparation> prepare(
    ProjectSession session,
    String actionId,
    Map<String, Object?> parameters, {
    Map<String, String> expectedMapRevisions = const {},
    ProjectManifest? expectedManifest,
  }) => _run(
    () => (delegate as MapCatalogPreparationPort).prepare(
      session,
      actionId,
      parameters,
      expectedMapRevisions: expectedMapRevisions,
      expectedManifest: expectedManifest,
    ),
  );

  @override
  Future<MapCatalogReceipt> applyPrepared(
    ProjectSession session,
    MapCatalogPreparation preparation, {
    Map<String, String> expectedMapRevisions = const {},
    bool confirmDestructive = false,
    ProjectManifest? expectedManifest,
    String? Function()? validateBeforeApply,
  }) => _run(
    () => (delegate as MapCatalogPreparationPort).applyPrepared(
      session,
      preparation,
      expectedMapRevisions: expectedMapRevisions,
      confirmDestructive: confirmDestructive,
      expectedManifest: expectedManifest,
      validateBeforeApply: validateBeforeApply,
    ),
  );
}
