import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/mcp/studio_mcp_service.dart';

final studioMcpServiceProvider = Provider<StudioMcpService>((ref) {
  final service = StudioMcpService(
    launch: () => Future.error(StateError('companion.not_configured')),
  );
  ref.onDispose(service.dispose);
  return service;
});
