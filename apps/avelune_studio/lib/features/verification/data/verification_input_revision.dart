import 'package:map_authoring/map_authoring_local.dart'
    show LocalProjectFileReader, ProjectResourceProbeStatus;

import '../domain/verification_port.dart';

Future<VerificationInputRevision> readVerificationInputRevision(
  String projectRoot,
  String path,
) async {
  final probe = await const LocalProjectFileReader().probeResource(
    projectRoot: projectRoot,
    relativePath: path,
  );
  final identity = probe.identity;
  final revision = switch (probe.status) {
    ProjectResourceProbeStatus.exists when identity != null =>
      '${identity.byteLength}:${identity.modifiedAtMicros}:${identity.changedAtMicros}',
    ProjectResourceProbeStatus.missing => 'missing',
    _ => null,
  };
  return (path: path, revision: revision);
}
