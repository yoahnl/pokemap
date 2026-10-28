import 'package:map_core/map_core_domain.dart';
import 'package:flutter/foundation.dart';

import '../../project_session/domain/project_session.dart';

final class ProjectAudioState {
  const ProjectAudioState({
    required this.configuration,
    required this.revision,
  });
  final ProjectAudioSettings? configuration;
  final String revision;
}

final class ProjectAudioEntry {
  const ProjectAudioEntry({required this.id, required this.label});
  final String id, label;
}

final class ProjectAudioPage {
  const ProjectAudioPage({required this.entries, this.nextCursor});
  final List<ProjectAudioEntry> entries;
  final String? nextCursor;
}

final class ProjectAudioImport {
  const ProjectAudioImport({
    required this.entry,
    required this.beforeRevision,
    required this.revision,
  });
  final ProjectAudioEntry entry;
  final String beforeRevision, revision;
}

final class ProjectAudioFile {
  const ProjectAudioFile({required this.path, required this.mimeType});
  final String path, mimeType;
}

abstract interface class ProjectAudioPort {
  Future<ProjectAudioState> loadAudio(ProjectSession session);
  Future<ProjectAudioState> saveAudioCue(
    ProjectSession session,
    ProjectSoundCue cue,
    ProjectSoundBinding? binding,
    String expectedRevision,
  );
  Future<ProjectAudioPage> queryAudio(
    ProjectSession session, {
    String query = '',
    String? cursor,
  });
  Future<ProjectAudioImport> importAudio(
    ProjectSession session,
    String sourcePath,
    String label,
    String expectedRevision,
  );
  Future<ProjectAudioFile> resolveAudio(ProjectSession session, String mediaId);
}

abstract interface class ProjectAudioPreviewPort {
  ValueListenable<String?> get playing;
  Future<void> play(String mediaId);
  Future<void> stop();
  Future<void> close();
}
