import 'package:avelune_studio/features/project_surf/application/project_surf_controller.dart';
import 'package:avelune_studio/features/project_surf/domain/project_surf_port.dart';
import 'package:avelune_studio/presentation/features/project_settings/project_cs_panel.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_choice.dart';
import 'package:flutter/material.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:avelune_studio/presentation/features/project_settings/project_audio_panel.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_draft_field.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';

import 'dart:async';

import 'package:avelune_studio/features/project_audio/application/project_audio_controller.dart';
import 'package:avelune_studio/features/project_audio/domain/project_audio_port.dart';
import 'package:avelune_studio/features/project_cs/application/project_cs_controller.dart';
import 'package:avelune_studio/features/project_cs/domain/project_cs_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets(
    'nine CS share one Surf authority and keep its condition and speed',
    (tester) async {
      final owner = ProjectCsController(
        session: workspaceSession,
        port: _Port(),
      );
      final surf = ProjectSurfController(
        session: workspaceSession,
        port: _SurfPort(),
        dimension: ProjectDimension.threeD,
      );
      addTearDown(owner.dispose);
      addTearDown(surf.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProjectCsPanel(
                owner: owner,
                surf: surf,
                settings: const ProjectSettings(
                  dimension: ProjectDimension.threeD,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find
            .byType(StudioChoice)
            .evaluate()
            .where((element) => element.widget.key.toString().contains('cs-')),
        hasLength(9),
      );
      expect(find.byKey(const ValueKey('surf-enabled')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('cs-surf')));
      await tester.pump();
      expect(surf.preview.value.enabled, isFalse);
      expect(surf.preview.value.speedCellsPerSecond, 6);
      expect(
        surf.preview.value.condition,
        ScriptConditionFactory.badgeOwned('cascade'),
      );
      await tester.ensureVisible(find.byKey(const ValueKey('cs-dive')));
      await tester.tap(find.byKey(const ValueKey('cs-dive')));
      expect(owner.preview.value.disabledAbilities, {FieldAbility.dive});
      expect(owner.dirty, isTrue);
    },
  );

  testWidgets(
    'audio library assignment, invalid text and lifecycle stop use the shared owner',
    (tester) async {
      final port = _Port();
      final player = _Preview();
      final owner = ProjectAudioController(
        session: workspaceSession,
        port: port,
        audition: player,
      );
      addTearDown(owner.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SingleChildScrollView(child: ProjectAudioPanel(owner: owner)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      tester
          .widget<StudioSelect>(
            find.byKey(const ValueKey('project-audio-source-ui.confirm')),
          )
          .onChanged!('custom');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('save-project-audio')),
            )
            .onPressed,
        isNull,
      );
      tester
          .widget<StudioSelect>(
            find.byKey(const ValueKey('project-audio-media-ui.confirm')),
          )
          .onChanged!('bell');
      await tester.pumpAndSettle();
      final field = find.descendant(
        of: find.byKey(const ValueKey('project-audio-gain-ui.confirm')),
        matching: find.byType(TextField),
      );
      await tester.enterText(field, 'bad');
      await tester.pump();
      expect(
        tester
            .widget<StudioDraftField>(
              find.byKey(const ValueKey('project-audio-gain-ui.confirm')),
            )
            .value,
        'bad',
      );
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('save-project-audio')),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(field, '40');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('save-project-audio')),
      );
      await tester.tap(find.byKey(const ValueKey('save-project-audio')));
      await tester.pumpAndSettle();
      expect(port.audio!.cues[ProjectSoundCue.uiConfirm]!.gain, .4);
      await owner.listen('bell');
      expect(owner.playingId, 'bell');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(owner.playingId, isNull);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'CS defaults, local undo and disjoint revision adoption preserve drafts',
    () async {
      final port = _Port();
      final cs = ProjectCsController(session: workspaceSession, port: port);
      final audio = ProjectAudioController(
        session: workspaceSession,
        port: port,
        onRevisionChanged: cs.adoptRevision,
      );
      addTearDown(cs.dispose);
      addTearDown(audio.dispose);
      await cs.open();
      await audio.open();
      cs.setEnabled(FieldAbility.dive, false);
      cs.setEnabled(FieldAbility.surf, false);
      expect(cs.preview.value.disabledAbilities, {FieldAbility.dive});
      expect(port.writes, 0);
      audio.source(ProjectSoundCue.uiConfirm, 'silent');
      expect(await audio.save(), isTrue);
      expect(cs.saved!.revision, '1');
      expect(cs.dirty, isTrue);
      cs.adoptRevision('0', 'stale');
      expect(cs.saved!.revision, '1');
      cs.undo();
      expect(cs.dirty, isFalse);
      cs.redo();
      expect(await cs.save(), isTrue);
      expect(port.cs!.disabledAbilities, {FieldAbility.dive});
      expect(port.loads, 2);
      expect(port.writes, 2);
    },
  );

  test(
    'custom source and invalid volume retain input and block persistence',
    () async {
      final port = _Port();
      final owner = ProjectAudioController(
        session: workspaceSession,
        port: port,
      );
      addTearDown(owner.dispose);
      await owner.open();
      owner.source(ProjectSoundCue.uiConfirm, 'custom');
      expect(owner.pendingSources[ProjectSoundCue.uiConfirm], 'custom');
      expect(await owner.save(), isFalse);
      owner.assign(ProjectSoundCue.uiConfirm, 'bell');
      owner.gain(ProjectSoundCue.uiConfirm, 'NaN');
      expect(owner.rawGains[ProjectSoundCue.uiConfirm], 'NaN');
      expect(await owner.save(), isFalse);
      expect(port.writes, 0);
      owner.gain(ProjectSoundCue.uiConfirm, '25.5');
      expect(await owner.save(), isTrue);
      expect(port.audio!.cues[ProjectSoundCue.uiConfirm]!.gain, .255);
      expect(port.audio!.cues[ProjectSoundCue.uiConfirm]!.mediaId, 'bell');
      owner.source(ProjectSoundCue.uiConfirm, 'inherit');
      expect(await owner.save(), isTrue);
      expect(port.audio!.cues, isEmpty);
    },
  );

  test(
    'paged library and import advance only known revision without losing draft',
    () async {
      final port = _Port();
      final owner = ProjectAudioController(
        session: workspaceSession,
        port: port,
      );
      addTearDown(owner.dispose);
      await owner.open();
      owner.source(ProjectSoundCue.uiError, 'silent');
      await owner.loadLibrary();
      await owner.loadLibrary(more: true);
      expect(port.cursors, [null, 'next']);
      expect(owner.library.keys, ['bell', 'wind']);
      await owner.import('/selected.wav', 'Selected');
      expect(owner.saved!.revision, '1');
      expect(owner.dirty, isTrue);
      expect(owner.library.keys, contains('selected'));
      expect(await owner.save(), isTrue);
      expect(
        port.audio!.cues[ProjectSoundCue.uiError]!.source,
        ProjectSoundSource.silent,
      );
    },
  );

  test(
    'preview completion and stop prevent stale playback after close',
    () async {
      final preview = _Preview();
      final owner = ProjectAudioController(
        session: workspaceSession,
        port: _Port(),
        audition: preview,
      );
      final listening = owner.listen('bell');
      await Future<void>.delayed(Duration.zero);
      expect(owner.playingId, 'bell');
      preview.playing.value = null;
      expect(owner.playingId, isNull);
      await listening;
      preview.pauseStop = Completer<void>();
      final late = owner.listen('wind');
      owner.dispose();
      preview.pauseStop!.complete();
      await late;
      expect(preview.plays, ['bell']);
      expect(preview.closed, isTrue);
    },
  );
}

class _Port implements ProjectCsPort, ProjectAudioPort {
  ProjectFieldAbilitiesSettings? cs;
  ProjectAudioSettings? audio;
  int loads = 0, writes = 0;
  final cursors = <String?>[];
  void requireRevision(String revision) {
    if (revision != '$writes') throw StateError('conflict');
  }

  @override
  Future<ProjectCsState> loadFieldAbilities(session) async {
    loads++;
    return ProjectCsState(configuration: cs, revision: '$writes');
  }

  @override
  Future<ProjectCsState> saveFieldAbility(
    session,
    FieldAbility ability,
    bool enabled,
    String expectedRevision,
  ) async {
    requireRevision(expectedRevision);
    final disabled = {...?cs?.disabledAbilities};
    enabled ? disabled.remove(ability) : disabled.add(ability);
    cs = ProjectFieldAbilitiesSettings(disabledAbilities: disabled);
    writes++;
    return ProjectCsState(configuration: cs, revision: '$writes');
  }

  @override
  Future<ProjectAudioState> loadAudio(session) async {
    loads++;
    return ProjectAudioState(configuration: audio, revision: '$writes');
  }

  @override
  Future<ProjectAudioState> saveAudioCue(
    session,
    ProjectSoundCue cue,
    ProjectSoundBinding? binding,
    String expectedRevision,
  ) async {
    requireRevision(expectedRevision);
    audio = (audio ?? ProjectAudioSettings()).withCue(cue, binding);
    writes++;
    return ProjectAudioState(configuration: audio, revision: '$writes');
  }

  @override
  Future<ProjectAudioPage> queryAudio(
    session, {
    String query = '',
    String? cursor,
  }) async {
    cursors.add(cursor);
    return cursor == null
        ? const ProjectAudioPage(
            entries: [ProjectAudioEntry(id: 'bell', label: 'Cloche')],
            nextCursor: 'next',
          )
        : const ProjectAudioPage(
            entries: [ProjectAudioEntry(id: 'wind', label: 'Vent')],
          );
  }

  @override
  Future<ProjectAudioImport> importAudio(
    session,
    String sourcePath,
    String label,
    String expectedRevision,
  ) async {
    requireRevision(expectedRevision);
    writes++;
    return ProjectAudioImport(
      entry: ProjectAudioEntry(id: 'selected', label: label),
      beforeRevision: expectedRevision,
      revision: '$writes',
    );
  }

  @override
  Future<ProjectAudioFile> resolveAudio(session, String mediaId) async =>
      const ProjectAudioFile(path: '/selected.wav', mimeType: 'audio/wav');
}

class _Preview implements ProjectAudioPreviewPort {
  @override
  final ValueNotifier<String?> playing = ValueNotifier(null);
  final plays = <String>[];
  Completer<void>? pauseStop;
  bool closed = false;
  @override
  Future<void> play(String id) async {
    plays.add(id);
    playing.value = id;
  }

  @override
  Future<void> stop() async {
    await pauseStop?.future;
    playing.value = null;
  }

  @override
  Future<void> close() async {
    closed = true;
  }
}

class _SurfPort implements ProjectSurfPort {
  @override
  Future<ProjectSurfState> loadSurf(session) async => ProjectSurfState(
    configuration: ProjectSurfSettings(
      speedCellsPerSecond: 6,
      accessMode: ProjectSurfAccessMode.condition,
      condition: ScriptConditionFactory.badgeOwned('cascade'),
    ),
    revision: '0',
  );
  @override
  Future<ProjectSurfState> saveSurf(
    session,
    ProjectSurfSettings? configuration,
    String expectedRevision,
  ) async => ProjectSurfState(configuration: configuration, revision: '1');
  @override
  Future<ProjectSurfReferences> loadSurfReferences(session) async =>
      const ProjectSurfReferences(facts: {}, badges: {'cascade': 'Cascade'});
  @override
  Future<NarrativeFactDefinition> loadSurfFact(session, String id) async =>
      NarrativeFactDefinition(id: id, label: id);
}
