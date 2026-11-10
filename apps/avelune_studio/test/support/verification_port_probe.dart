import 'package:avelune_studio/features/verification/domain/verification_port.dart';
import 'package:map_core/map_core_domain.dart';

class VerificationPortProbe implements VerificationPort {
  VerificationPortProbe(this.delegate);

  final VerificationPort delegate;
  int revisions = 0;
  int analyses = 0;
  int sourceReads = 0;

  @override
  Future<String> projectRevision() {
    revisions++;
    return delegate.projectRevision();
  }

  @override
  Future<List<MapData>> loadMaps() => delegate.loadMaps();

  @override
  Future<VerificationRuntimeEvidence> readRuntimeEvidence(
    NarrativeRuntimeSmokeProfile? profile,
  ) => delegate.readRuntimeEvidence(profile);

  @override
  Future<List<VerificationDialogueSource>> readDialogueSources(
    List<ProjectDialogueEntry> entries,
  ) {
    sourceReads++;
    return delegate.readDialogueSources(entries);
  }

  @override
  VerificationJob analyse({
    required ProjectManifest project,
    required List<MapData> maps,
    required List<VerificationDialogueSource> sources,
  }) {
    analyses++;
    return delegate.analyse(project: project, maps: maps, sources: sources);
  }
}
