import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/mcp/studio_mcp_service.dart';
import 'map_workspace_providers.dart';

final studioMcpServiceProvider = Provider<StudioMcpService>((ref) {
  final service = StudioMcpService(
    launch: () => Future.error(StateError('companion.not_configured')),
  );
  ref.onDispose(service.dispose);
  return service;
});

final studioMcpExternalMutations = externalProjectMutationsProvider
    .overrideWith(
      (ref) => ref
          .watch(studioMcpServiceProvider)
          .mutations
          .map(
            (mutation) => (
              projectRoot: mutation.projectRoot,
              resources: {
                for (final resource in mutation.resources)
                  (kind: resource.kind, id: resource.id),
              },
            ),
          ),
    );
