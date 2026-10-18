import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../application/resource_pack_transfer_api_test.dart' show waitForJob;
import '../domains/assets/resource_pack_import_fixture.dart';
import '../support/resource_pack_stdio_client.dart';

void main() {
  test('real JSONL reports exactly the same project budget as the direct API', () async {
    final fixture = await NativeResourcePackImportFixture.create();
    final api = LocalResourcePackTransferApi(
        mutations: fixture.mutations, snapshotLoader: fixture.loader);
    final client = await ResourcePackStdioClient.start(fixture.source.directory.path);
    try {
      final project = fixture.opened.projectHandle;
      final before = await fixture.loader.load(project);
      final direct = await waitForJob(api, project,
          await api.transfer(project, verb: 'diagnose', input: {
        'expectedRevision': before.revision,
      }));
      final opened = await client.call('open', {'projectRoot': fixture.root.path});
      final described = await client.call('describe', {});
      expect((described['resourcePackTransfer'] as Map)['verbs'], contains('diagnose'));
      final validated = await client.call('validate', {'projectHandle': opened['projectHandle']});
      final transported = await client.result(opened,
          await client.pack(opened, 'diagnose', {
        'expectedRevision': validated['snapshotRevision'],
      }));
      expect(transported['budgetReports'], (direct['result'] as Map)['budgetReports']);
      expect((await fixture.loader.load(project)).revision, before.revision);
      await client.call('close', {'workspaceHandle': opened['workspaceHandle']});
    } finally {
      await client.close();
      await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
      await fixture.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
