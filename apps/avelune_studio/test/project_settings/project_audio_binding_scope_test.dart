import 'package:avelune_studio/features/project_audio/application/project_audio_controller.dart';
import 'package:avelune_studio/features/project_audio/domain/project_audio_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_settings/application/project_settings_session_controller.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:avelune_studio/features/project_visuals/domain/project_visuals_port.dart';
import 'package:avelune_studio/presentation/features/project_settings/project_audio_panel.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProjectAudioPanel(owner: audio, showActions: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('every cue of the native catalog is listed with its intention', (
    tester,
  ) async {
    await pump(tester);
    for (final entry in ProjectSoundCueCatalog.entries) {
      expect(
        find.byKey(ValueKey('project-audio-row-${entry.cue.wireName}')),
        findsOneWidget,
      );
    }
    final intentions = tester
        .widget<StudioSelect>(
          find.byKey(const ValueKey('project-audio-source-ui.confirm')),
        )
        .options;
    expect(intentions.keys, ['inherit', 'builtin', 'silent', 'custom']);
    expect(intentions['inherit'], contains('défaut'));
  });

  testWidgets(
    'silence disables listening and an invalid gain blocks saving and listening',
    (tester) async {
      await pump(tester);
      audio.source(ProjectSoundCue.uiConfirm, 'silent');
      await tester.pumpAndSettle();
      final listen = find.byKey(const ValueKey('project-audio-listen'));
      expect(_enabled(tester, listen), isFalse);
      audio.source(ProjectSoundCue.uiConfirm, 'custom');
      audio.assign(ProjectSoundCue.uiConfirm, 'bell');
      await tester.pumpAndSettle();
      expect(_enabled(tester, listen), isTrue);
      audio.gain(ProjectSoundCue.uiConfirm, 'abc');
      await tester.pumpAndSettle();
      expect(_enabled(tester, listen), isFalse);
      expect(await audio.save(), isFalse);
      expect(port.writes, 0);
    },
  );

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

  testWidgets('changing action or leaving the screen stops the real player', (
    tester,
  ) async {
    await pump(tester);
    await audio.listen('bell');
    expect(player.playing.value, 'bell');
    tester
        .widget<StudioSelect>(find.byKey(const ValueKey('project-audio-cue')))
        .onChanged!(ProjectSoundCue.uiCancel.wireName);
    await tester.pumpAndSettle();
    expect(player.playing.value, isNull);
    await audio.listen('bell');
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(player.stops, greaterThanOrEqualTo(2));
    expect(player.playing.value, isNull);
  });
}

bool _enabled(WidgetTester tester, Finder button) =>
    tester
        .widget<ButtonStyleButton>(
          find.descendant(
            of: button,
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
          ),
        )
        .onPressed !=
    null;

final class _Player implements ProjectAudioPreviewPort {
  final _playing = ValueNotifier<String?>(null);
  @override
  ValueNotifier<String?> get playing => _playing;
  int stops = 0;

  @override
  Future<void> play(String mediaId) async => playing.value = mediaId;

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
