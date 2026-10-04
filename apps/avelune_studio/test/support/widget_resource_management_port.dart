import 'package:avelune_studio/features/resources/domain/resource_mutation_preparation.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_usage_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_lifecycle_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'm2_ui_fixture.dart';

class WidgetResourceManagementPort extends WidgetResourcePort
    implements
        ResourceMutationPreparationPort,
        ResourceUsageProvider,
        ResourceLifecyclePreparationPort {
  WidgetResourceManagementPort(super.port, super.tester, {this.wrapUsages});
  final ResourceUsagePort Function(ResourceUsagePort)? wrapUsages;
  ResourceMutationPreparationPort get preparation =>
      port as ResourceMutationPreparationPort;

  Future<T> _read<T>(Future<T> Function() action) =>
      _resourceIo(tester, action);

  @override
  Future<String?> resourceFingerprint(
    String tilesetId,
    String snapshotRevision,
  ) => _read<String?>(
    () => preparation.resourceFingerprint(tilesetId, snapshotRevision),
  );

  @override
  Future<String> captureResourceRevision() =>
      _read(preparation.captureResourceRevision);

  @override
  Future<ResourceReplacementPreview> prepareReplacement(
    ResourceReplacementRequest request,
  ) => _read(
    () =>
        (port as ResourceLifecyclePreparationPort).prepareReplacement(request),
  );

  @override
  Future<void> releasePreparation(ResourceMutationPreparation preparation) =>
      _read(
        () => (port as ResourceLifecyclePreparationPort).releasePreparation(
          preparation,
        ),
      );

  @override
  Future<ResourceMutationPreparation> prepareOperation(
    String action,
    Map<String, Object?> parameters, {
    String? expectedSnapshotRevision,
  }) => _read(
    () => preparation.prepareOperation(
      action,
      parameters,
      expectedSnapshotRevision: expectedSnapshotRevision,
    ),
  );

  @override
  Future<ResourceMutationReceipt> applyPrepared(
    ResourceMutationPreparation preparation, {
    bool confirmDestructive = false,
    String? Function()? validateBeforeApply,
  }) => _read(
    () => this.preparation.applyPrepared(
      preparation,
      confirmDestructive: confirmDestructive,
      validateBeforeApply: validateBeforeApply,
    ),
  );

  @override
  Future<void> reconcileReceipt(ResourceMutationReceipt receipt) async {
    await _read(() => preparation.reconcileReceipt(receipt));
  }

  @override
  late final ResourceUsagePort usages = _createUsages();
  ResourceUsagePort _createUsages() {
    final bridged = _WidgetUsagePort(
      (port as ResourceUsageProvider).usages,
      tester,
    );
    return wrapUsages?.call(bridged) ?? bridged;
  }
}

class _WidgetUsagePort implements ResourceUsagePort {
  _WidgetUsagePort(this.port, this.tester);
  final ResourceUsagePort port;
  final WidgetTester tester;
  @override
  Future<ResourceUsageReport> analyze(
    ResourceUsageTarget target, {
    bool Function()? cancelled,
  }) => _resourceIo(tester, () => port.analyze(target, cancelled: cancelled));
  @override
  Future<bool> isCurrent(ResourceUsageReport report) =>
      _resourceIo(tester, () => port.isCurrent(report));
  @override
  Future<void> dispose() => port.dispose();
}

Future<T> _resourceIo<T>(
  WidgetTester tester,
  Future<T> Function() action,
) async {
  Object? failure;
  StackTrace? stack;
  T? result;
  await WidgetResourcePort.serial<void>(tester, () async {
    try {
      result = await action();
    } on Object catch (error, trace) {
      failure = error;
      stack = trace;
    }
  });
  if (failure != null) Error.throwWithStackTrace(failure!, stack!);
  return result as T;
}
