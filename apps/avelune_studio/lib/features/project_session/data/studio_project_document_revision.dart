import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

String studioProjectDocumentRevision({
  required List<int> descriptorBytes,
  List<int>? headBytes,
}) => headBytes == null
    ? narrativeEventBytesFingerprint(descriptorBytes)
    : computeNarrativeProjectFingerprint([
        NarrativeProjectFingerprintEntry(
          relativePath: 'project.json',
          bytes: descriptorBytes,
        ),
        NarrativeProjectFingerprintEntry(
          relativePath: 'catalog/HEAD.json',
          bytes: headBytes,
        ),
      ]);

String studioProjectSnapshotRevision(ProjectSnapshot snapshot) =>
    studioProjectDocumentRevision(
      descriptorBytes: snapshot.resourceBytes('project'),
      headBytes: snapshot.findResourceBytes('catalogHead'),
    );

String studioProjectPlanRevision(ProjectSnapshot snapshot, AuthoringPlan plan) {
  final descriptor = plan.changeSet.changes
      .where((change) => change.storageKey == 'project.json')
      .firstOrNull;
  final head = plan.changeSet.changes
      .where((change) => change.storageKey == 'catalog/HEAD.json')
      .firstOrNull;
  return studioProjectDocumentRevision(
    descriptorBytes:
        descriptor?.afterBytes ?? snapshot.resourceBytes('project'),
    headBytes: head?.afterBytes ?? snapshot.findResourceBytes('catalogHead'),
  );
}
