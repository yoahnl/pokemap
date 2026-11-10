import 'package:avelune_studio/features/project_audio/application/project_audio_controller.dart';
import 'package:avelune_studio/features/project_audio/domain/project_audio_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_settings/application/project_settings_session_controller.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:avelune_studio/features/project_visuals/domain/project_visuals_port.dart';
import 'package:avelune_studio/features/project_audio/application/project_audio_editing_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  late _AudioPort port;
  late _Player player;
  late ProjectAudioController audio;

  setUp(() async {
    port = _AudioPort();
    player = _Player();
    audio = ProjectAudioController(
      session: workspaceSession,
      port: port,
      audition: player,
    );
    await audio.open();
    await audio.loadLibrary();
  });

  tearDown(() => audio.dispose());

  test('association source options retain intentions and distinguish an unfinished custom choice', () async {
    final editing = ProjectAudioEditingSession(owner: audio);
    addTearDown(editing.close);
    expect(projectAudioSourceOptions.keys, ['inherit', 'builtin', 'silent', 'custom']);
    expect(projectAudioSourceOptions['inherit'], contains('défaut'));
    expect(editing.intention(ProjectSoundCue.uiConfirm), 'Réglage par défaut');
    audio.source(ProjectSoundCue.uiConfirm, 'builtin');
    audio.gain(ProjectSoundCue.uiConfirm, '40');
    expect(editing.intention(ProjectSoundCue.uiConfirm), 'Son intégré · 40 %');
    audio.source(ProjectSoundCue.uiConfirm, 'custom');
    expect(editing.intention(ProjectSoundCue.uiConfirm), 'Son de la bibliothèque à choisir');
    expect(editing.canSaveAssociation, isFalse);
    audio.assign(ProjectSoundCue.uiConfirm, 'bell');
    expect(editing.intention(ProjectSoundCue.uiConfirm), startsWith('Cloche · '));
    expect(editing.canSaveAssociation, isTrue);
    audio.source(ProjectSoundCue.uiConfirm, 'silent');
    expect(editing.intention(ProjectSoundCue.uiConfirm), 'Aucun son');
  });

  test('silence and invalid gain block association playback and persistence', () async {
    final editing = ProjectAudioEditingSession(owner: audio);
    addTearDown(editing.close);
    audio.source(ProjectSoundCue.uiConfirm, 'silent');
    expect(editing.canListenAssociation, isFalse);
    await editing.listenAssociation();
    expect(player.plays, 0);
    audio.source(ProjectSoundCue.uiConfirm, 'custom');
    audio.assign(ProjectSoundCue.uiConfirm, 'bell');
    expect(editing.canListenAssociation, isTrue);
    await editing.listenAssociation();
    expect(player.plays, 1);
    audio.gain(ProjectSoundCue.uiConfirm, 'abc');
    expect(editing.canListenAssociation, isFalse);
    expect(editing.canSaveAssociation, isFalse);
    await editing.listenAssociation();
    expect(player.plays, 1);
    expect(await audio.save(), isFalse);
    expect(port.writes, 0);
  });

  test('two actions sharing one sound keep independent gains', () async {
    audio.source(ProjectSoundCue.uiConfirm, 'custom');
    audio.assign(ProjectSoundCue.uiConfirm, 'bell');
    audio.gain(ProjectSoundCue.uiConfirm, '40');
    audio.source(ProjectSoundCue.uiCancel, 'custom');
    audio.assign(ProjectSoundCue.uiCancel, 'bell');
    audio.gain(ProjectSoundCue.uiCancel, '90');
    expect(await audio.save(), isTrue);
    expect(
      port.settings.cues[ProjectSoundCue.uiConfirm]!.gain,
      closeTo(.4, 1e-9),
    );
    expect(
      port.settings.cues[ProjectSoundCue.uiCancel]!.gain,
      closeTo(.9, 1e-9),
    );
    expect(port.settings.cues[ProjectSoundCue.uiConfirm]!.mediaId, 'bell');
    expect(port.settings.cues[ProjectSoundCue.uiCancel]!.mediaId, 'bell');
  });

  test(
    'a failed association keeps the section unsaved and names what was saved',
    () async {
      final visuals = ProjectVisualsController(
        session: workspaceSession,
        port: _NoVisuals(),
      );
      addTearDown(visuals.dispose);
      final settings = ProjectSettingsSessionController(
        projectVisuals: visuals,
        audio: audio,
      );
      addTearDown(settings.dispose);
      audio.source(ProjectSoundCue.uiConfirm, 'silent');
      audio.source(ProjectSoundCue.uiCancel, 'silent');
      port.failOn = ProjectSoundCue.uiCancel;
      expect(await settings.save(ProjectSettingsSection.sounds), isFalse);
      expect(settings.isConfirmed(ProjectSettingsSection.sounds), isFalse);
      expect(settings.isDirty(ProjectSettingsSection.sounds), isTrue);
      expect(
        port.settings.cues[ProjectSoundCue.uiConfirm]!.source,
        ProjectSoundSource.silent,
      );
      expect(audio.dirtyCues, {ProjectSoundCue.uiCancel});
      expect(audio.error, contains('1 association enregistrée'));
      port.failOn = null;
      expect(await audio.saveCue(ProjectSoundCue.uiCancel), isTrue);
      expect(audio.dirty, isFalse);
    },
  );

  test('changing action, suspending and closing stop the preview port', () async {
    final editing = ProjectAudioEditingSession(owner: audio);
    await audio.listen('bell');
    expect(player.playing.value, 'bell');
    expect(await editing.select(ProjectSoundCue.uiCancel), isTrue);
    expect(editing.selected, ProjectSoundCue.uiCancel);
    expect(player.playing.value, isNull);
    await audio.listen('bell');
    await editing.suspend();
    expect(player.playing.value, isNull);
    await audio.listen('bell');
    await editing.close();
    expect(player.stops, greaterThanOrEqualTo(3));
    expect(player.playing.value, isNull);
    expect(editing.canListenAssociation, isFalse);
    expect(await editing.select(ProjectSoundCue.uiConfirm), isFalse);
    expect(editing.selected, ProjectSoundCue.uiCancel);
  });

}

final class _Player implements ProjectAudioPreviewPort {
  final _playing = ValueNotifier<String?>(null);
  @override
  ValueNotifier<String?> get playing => _playing;
  int stops = 0, plays = 0;

  @override
  Future<void> play(String mediaId) async {
    plays++;
    playing.value = mediaId;
  }

  @override
  Future<void> stop() async {
    stops++;
    playing.value = null;
  }

  @override
  Future<void> close() async => playing.value = null;
}

final class _AudioPort implements ProjectAudioPort {
  ProjectAudioSettings settings = ProjectAudioSettings();
  int writes = 0;
  ProjectSoundCue? failOn;

  @override
  Future<ProjectAudioState> loadAudio(ProjectSession session) async =>
      ProjectAudioState(configuration: settings, revision: '$writes');

  @override
  Future<ProjectAudioState> saveAudioCue(
    ProjectSession session,
    ProjectSoundCue cue,
    ProjectSoundBinding? binding,
    String expectedRevision,
  ) async {
    if (cue == failOn) throw StateError('Écriture refusée');
    if (expectedRevision != '$writes') throw StateError('stale');
    writes++;
    settings = settings.withCue(cue, binding);
    return ProjectAudioState(configuration: settings, revision: '$writes');
  }

  @override
  Future<ProjectAudioPage> queryAudio(
    ProjectSession session, {
    String query = '',
    String? cursor,
  }) async => const ProjectAudioPage(
    entries: [ProjectAudioEntry(id: 'bell', label: 'Cloche')],
  );

  @override
  Future<ProjectAudioPage> queryLegacyAudio(
    ProjectSession session, {
    String query = '',
    String? cursor,
  }) async => const ProjectAudioPage(entries: []);

  @override
  Future<ProjectAudioImport> importAudio(
    ProjectSession session,
    String sourcePath,
    String label,
    String expectedRevision,
  ) => throw UnimplementedError();

  @override
  Future<ProjectAudioImport> adoptAudioAsset(
    ProjectSession session,
    String assetId,
    String mediaId,
    String label,
    String expectedRevision,
  ) => throw UnimplementedError();

  @override
  Future<ProjectAudioFile> resolveAudio(
    ProjectSession session,
    String mediaId,
  ) => throw UnimplementedError();
}

final class _NoVisuals implements ProjectVisualsPort {
  @override
  Future<ProjectVisualsState> loadVisuals(
    ProjectSession session, {
    ProjectMapEntry? map,
  }) async => ProjectVisualsState(profile: SpatialVisualPatch(), revision: 'v');

  @override
  Future<ProjectVisualsState> saveVisuals(
    ProjectSession session,
    SpatialVisualPatch profile,
    String expectedRevision, {
    ProjectMapEntry? map,
  }) => throw UnimplementedError();

  @override
  Future<ProjectVisualsState> undoVisuals(
    ProjectSession session,
    String receiptId,
    String expectedRevision, {
    ProjectMapEntry? map,
  }) => throw UnimplementedError();
}
