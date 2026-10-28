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
  test('configuration-only CS use stable IDs and preserve typed edits, undo and reopen', () async {
    final port = _Port();
    final owner = ProjectCsController(session: workspaceSession, port: port);
    addTearDown(owner.dispose);
    await owner.open();
    owner.setEnabledId('rock_climb', false);
    owner.setEnabledId('defog', false);
    owner.setEnabled(FieldAbility.dive, false);
    owner.undo();
    expect(owner.preview.value.disabledAbilityIds, {'rock_climb', 'defog'});
    owner.redo();
    expect(owner.preview.value.disabledAbilityIds, {
      'rock_climb',
      'defog',
      'dive',
    });
    expect(port.loads, 1);
    expect(port.writes, 0);
    expect(await owner.save(), isTrue);
    expect(port.writes, 3);
    final reopened = ProjectCsController(session: workspaceSession, port: port);
    addTearDown(reopened.dispose);
    await reopened.open();
    expect(reopened.preview.value.disabledAbilityIds, {
      'rock_climb',
      'defog',
      'dive',
    });
    expect(reopened.preview.value.disabledAbilities, {FieldAbility.dive});
    reopened.setEnabledId('rock_climb', true);
    expect(await reopened.save(), isTrue);
    expect(port.cs!.disabledAbilityIds, {'defog', 'dive'});
    expect(FieldAbility.values, hasLength(9));
  });
  test(
    'CS conflict retains configuration-only IDs and the pending Surf draft',
    () async {
      final port = _Port();
      final owner = ProjectCsController(session: workspaceSession, port: port);
      final surf = ProjectSurfController(
        session: workspaceSession,
        port: _SurfPort(),
        dimension: ProjectDimension.threeD,
      );
      addTearDown(owner.dispose);
      addTearDown(surf.dispose);
      await owner.open();
      await surf.open();
      owner.setEnabledId('rock_climb', false);
      owner.setEnabledId('defog', false);
      surf.change(enabled: false, speedCellsPerSecond: 7);
      final surfDraft = surf.preview.value;
      port.writes++;
      expect(await owner.save(), isFalse);
      expect(owner.error, contains('conflict'));
      expect(owner.saved!.revision, '0');
      expect(owner.preview.value.disabledAbilityIds, {'rock_climb', 'defog'});
      expect(owner.dirty, isTrue);
      expect(owner.canUndo, isTrue);
      expect(surf.preview.value, same(surfDraft));
      expect(surf.dirty, isTrue);
      expect(port.loads, 1);
      expect(port.writes, 1);
    },
  );
  for (final dimension in [ProjectDimension.twoD, ProjectDimension.threeD]) {
    testWidgets(
      'Escalade and Anti-Brume status is unimplemented for $dimension',
      (tester) async {
        final port = _Port();
        final owner = ProjectCsController(
          session: workspaceSession,
          port: port,
        );
        final surf = ProjectSurfController(
          session: workspaceSession,
          port: _SurfPort(),
          dimension: dimension,
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
                  settings: ProjectSettings(dimension: dimension),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final id in ['rock_climb', 'defog']) {
          final row = find.byKey(ValueKey('cs-$id'));
          expect(
            tester.widget<StudioChoice>(row).subtitle,
            contains('mécanique à implémenter en 2D et 3D'),
          );
          await tester.ensureVisible(row);
          await tester.tap(row);
          await tester.pump();
        }
        expect(owner.preview.value.disabledAbilityIds, {'rock_climb', 'defog'});
        expect(port.writes, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'an old project sound is visible, explicitly adopted and selected',
    (tester) async {
      final port = _Port()..legacyAvailable = true;
      final owner = ProjectAudioController(
        session: workspaceSession,
        port: port,
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
      final adopt = find.byKey(
        const ValueKey('adopt-project-audio-legacy-bell'),
      );
      expect(adopt, findsOneWidget);
      expect(port.adoptionWrites, 0);
      await tester.ensureVisible(adopt);
      await tester.tap(adopt);
      await tester.pumpAndSettle();
      expect(port.adoptionWrites, 1);
      final selected = owner.preview.value.cues[ProjectSoundCue.uiConfirm]!;
      expect(selected.source, ProjectSoundSource.custom);
      expect(selected.mediaId, port.adoptedAssets['legacy-bell']!.id);
      expect(
        owner.library.values.map((entry) => entry.label),
        contains('Ancienne cloche.wav'),
      );
      expect(owner.dirty, isTrue);
      expect(port.audio, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  test('legacy pages and duplicate adoption preserve other drafts and invalid gain', () async {
    final port = _Port()..legacyAvailable = true;
    final owner = ProjectAudioController(session: workspaceSession, port: port);
    addTearDown(owner.dispose);
    await owner.open();
    owner.source(ProjectSoundCue.uiError, 'silent');
    owner.source(ProjectSoundCue.uiConfirm, 'builtin');
    owner.gain(ProjectSoundCue.uiConfirm, 'bad');
    await owner.loadLegacyLibrary();
    await owner.loadLegacyLibrary(more: true);
    expect(port.legacyCursors, [null, 'legacy-next']);
    final asset = owner.legacyLibrary['legacy-bell']!;
    await owner.adopt(asset, ProjectSoundCue.uiConfirm);
    final id = owner.preview.value.cues[ProjectSoundCue.uiConfirm]!.mediaId;
    expect(
      owner.preview.value.cues[ProjectSoundCue.uiError]!.source,
      ProjectSoundSource.silent,
    );
    expect(owner.rawGains[ProjectSoundCue.uiConfirm], 'bad');
    expect(owner.fieldErrors[ProjectSoundCue.uiConfirm], isNotNull);
    expect(await owner.save(), isFalse);
    await owner.adopt(asset, ProjectSoundCue.doorOpen);
    expect(owner.preview.value.cues[ProjectSoundCue.doorOpen]!.mediaId, id);
    expect(port.adoptionWrites, 1);
    expect(owner.saved!.revision, '1');
    owner.gain(ProjectSoundCue.uiConfirm, '40');
    expect(await owner.save(), isTrue);
  });
  test('pending legacy adoption blocks close/save work and retains draft on conflict', () async {
    final port = _Port()..adoptGate = Completer<void>();
    final owner = ProjectAudioController(session: workspaceSession, port: port);
    addTearDown(owner.dispose);
    await owner.open();
    owner.source(ProjectSoundCue.uiConfirm, 'silent');
    final before = owner.preview.value;
    final adding = owner.adopt(
      const ProjectAudioEntry(id: 'old', label: 'Ancien'),
      ProjectSoundCue.uiConfirm,
    );
    expect(owner.busy, isTrue);
    expect(await owner.save(), isFalse);
    port.writes++;
    port.adoptGate!.complete();
    await adding;
    expect(owner.busy, isFalse);
    expect(owner.preview.value, before);
    expect(owner.error, contains('conflict'));
  });

  testWidgets(
    'eleven CS share one Surf authority and label unimplemented mechanics',
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
        hasLength(11),
      );
      expect(find.byKey(const ValueKey('cs-rock_climb')), findsOneWidget);
      expect(find.byKey(const ValueKey('cs-defog')), findsOneWidget);
      expect(find.text('Escalade'), findsOneWidget);
      expect(find.text('Anti-Brume'), findsOneWidget);
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
  final legacyCursors = <String?>[];
  bool legacyAvailable = false;
  Completer<void>? adoptGate;
  final adoptedAssets = <String, ProjectAudioEntry>{};
  int adoptionWrites = 0;
  @override
  Future<ProjectAudioPage> queryLegacyAudio(
    session, {
    String query = '',
    String? cursor,
  }) async {
    legacyCursors.add(cursor);
    return ProjectAudioPage(
      entries: legacyAvailable
          ? [
              ProjectAudioEntry(
                id: cursor == null ? 'legacy-bell' : 'legacy-rain',
                label: cursor == null
                    ? 'Ancienne cloche.wav'
                    : 'Ancienne pluie.wav',
              ),
            ]
          : [],
      nextCursor: legacyAvailable && cursor == null ? 'legacy-next' : null,
    );
  }

  @override
  Future<ProjectAudioImport> adoptAudioAsset(
    session,
    String assetId,
    String mediaId,
    String label,
    String expectedRevision,
  ) async {
    await adoptGate?.future;
    requireRevision(expectedRevision);
    var entry = adoptedAssets[assetId];
    if (entry == null) {
      entry = ProjectAudioEntry(id: mediaId, label: label);
      adoptedAssets[assetId] = entry;
      writes++;
      adoptionWrites++;
    }
    return ProjectAudioImport(
      entry: entry,
      beforeRevision: expectedRevision,
      revision: '$writes',
    );
  }

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
  ) => saveFieldAbilityId(session, ability.moveId, enabled, expectedRevision);

  @override
  Future<ProjectCsState> saveFieldAbilityId(
    session,
    String abilityId,
    bool enabled,
    String expectedRevision,
  ) async {
    requireRevision(expectedRevision);
    final disabled = {...?cs?.disabledAbilityIds};
    enabled ? disabled.remove(abilityId) : disabled.add(abilityId);
    cs = ProjectFieldAbilitiesSettings.fromIds(disabled);
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
