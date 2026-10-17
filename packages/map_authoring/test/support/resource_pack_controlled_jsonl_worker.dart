import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';

import 'resource_pack_test_gate.dart';

Future<void> main(List<String> arguments) async {
  final rootIndex = arguments.indexOf('--root');
  if (rootIndex < 0) throw ArgumentError('The test worker requires --root.');
  final root = arguments[rootIndex + 1];
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root], fileReader: reader);
  final handles = WorkspaceHandleStore();
  final snapshots = ProjectSnapshotLoader(handles: handles);
  final gate = ResourcePackTestGate(root);
  final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      resourcePackSourceRoots: [root],
      faultInjector: gate.intercept,
      actor: File('${gate.directory.path}/readonly').existsSync()
          ? AuthoringActor(actorId: 'local_cli')
          : null);
  final packs = LocalResourcePackTransferApi(
      mutations: mutations, snapshotLoader: snapshots);
  final api = AuthoringReadApi(
      openService: ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles),
      snapshotLoader: snapshots,
      resourcePacks: () => packs);
  final worker =
      JsonlWorker(api: api, mutations: mutations, resourcePacks: packs);
  try {
    await for (final line
        in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
      stdout.writeln(await worker.processLine(line));
    }
  } finally {
    await worker.close();
  }
}
