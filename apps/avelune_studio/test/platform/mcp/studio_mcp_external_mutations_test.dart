import 'package:avelune_studio/app/di/map_workspace_providers.dart';
import 'package:avelune_studio/app/di/studio_mcp_providers.dart';
import 'package:avelune_studio/platform/mcp/studio_mcp_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'studio_mcp_service_test.dart' show FakeStudioMcpProcess, flush;

void main() {
  test('companion mutations reach the map workspace feed', () async {
    final process = FakeStudioMcpProcess();
    final service = StudioMcpService(launch: () async => process);
    addTearDown(service.dispose);
    final container = ProviderContainer(
      overrides: [
        studioMcpExternalMutations,
        studioMcpServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);
    final received = <ExternalProjectMutation>[];
    final subscription = container
        .read(externalProjectMutationsProvider)
        .listen(received.add);
    addTearDown(subscription.cancel);
    await service.setProjectRoot('/projects/A');
    final starting = service.start();
    await flush();
    process.ready();
    await starting;
    process.mutation('/projects/A');
    await flush();
    expect(received.single.projectRoot, '/projects/A');
    expect(received.single.resources, {(kind: 'map', id: 'map-a')});
    await service.stop();
  });

  test('without the companion wiring the feed stays silent', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      await container.read(externalProjectMutationsProvider).isEmpty,
      isTrue,
    );
  });
}
