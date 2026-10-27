import 'package:avelune_studio/app/studio_bootstrap.dart';
import 'package:avelune_studio/app/di/providers.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget buildNativeResourcePhaseBootstrap(
  BuildContext context, {
  required StudioBootstrap bootstrapWidget,
  required Future<void> Function() beforeTransactionPrecondition,
  required Future<void> Function() beforeReconciliation,
  required void Function(String phase) mutationPhaseObserver,
}) {
  final bootstrap = bootstrapWidget.build(context) as ProviderScope;
  final retained = bootstrap.overrides
      .where((override) => !identical(override.origin, resourcePortProvider))
      .toList();
  if (retained.length != bootstrap.overrides.length - 1) {
    throw StateError('Expected exactly one canonical resource provider.');
  }
  return ProviderScope(
    observers: bootstrap.observers,
    retry: bootstrap.retry,
    overrides: [
      ...retained,
      resourcePortProvider.overrideWith((ref, session) {
        final port = LocalResourceAdapter(
          session: session,
          mapAdapter: ref.watch(
            mapWorkspacePortProvider(session),
          ) as LocalMapWorkspaceAdapter,
          beforeTransactionPrecondition: beforeTransactionPrecondition,
          beforeReconciliation: beforeReconciliation,
          mutationPhaseObserver: mutationPhaseObserver,
        );
        ref.onDispose(port.dispose);
        return port;
      }),
    ],
    child: bootstrap.child,
  );
}
