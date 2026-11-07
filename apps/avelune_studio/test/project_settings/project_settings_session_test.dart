import 'dart:async';

import 'package:avelune_studio/features/project_audio/application/project_audio_controller.dart';
import 'package:avelune_studio/features/project_audio/domain/project_audio_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_settings/application/project_settings_session_controller.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:avelune_studio/features/project_visuals/domain/project_visuals_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/project_settings/project_settings_page.dart';
import 'package:avelune_studio/presentation/features/project_settings/spatial_visual_controls.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  pageTests();
  late _VisualPort visualPort;
  late _AudioPort audioPort;
  late ProjectVisualsController visuals;
  late ProjectAudioController audio;
  late ProjectSettingsSessionController settings;

  setUp(() async {
    visualPort = _VisualPort();
    audioPort = _AudioPort();
    visuals = ProjectVisualsController(
      session: workspaceSession,
      port: visualPort,
    );
    audio = ProjectAudioController(session: workspaceSession, port: audioPort);
    await visuals.open();
    await audio.open();
    settings = ProjectSettingsSessionController(
      projectVisuals: visuals,
      audio: audio,
    );
  });

  tearDown(() {
    settings.dispose();
    audio.dispose();
    visuals.dispose();
  });

  final image = SpatialVisualPatch().set(
    SpatialVisualParameter.depthOfFieldEnabled,
    true,
  );

  test('the six sections are navigable without saving anything', () async {
    expect(ProjectSettingsSection.values, hasLength(6));
    visuals.edit(image);
    for (final section in ProjectSettingsSection.values) {
      settings.select(section);
      expect(settings.section, section);
    }
    settings.select(ProjectSettingsSection.sounds);
    settings.select(ProjectSettingsSection.image);
    expect(visuals.preview.value, image);
    expect(settings.isDirty(ProjectSettingsSection.image), isTrue);
    expect(settings.isDirty(ProjectSettingsSection.sounds), isFalse);
    expect(visualPort.writes, 0);
    expect(audioPort.writes, 0);
  });

  test('saving Image keeps the weather and sound drafts unsaved', () async {
    visuals.edit(
      image
          .set(SpatialVisualParameter.weatherMode, 'fixed')
          .set(SpatialVisualParameter.weatherKind, 'storm'),
    );
    audio.gain(ProjectSoundCue.uiConfirm, '40');
    expect(settings.isDirty(ProjectSettingsSection.image), isTrue);
    expect(settings.isDirty(ProjectSettingsSection.timeWeather), isTrue);
    expect(settings.isDirty(ProjectSettingsSection.sounds), isTrue);

    expect(await settings.save(ProjectSettingsSection.image), isTrue);

    expect(visualPort.writes, 1);
    expect(
      visualPort.profile.enabled(SpatialVisualParameter.depthOfFieldEnabled),
      isTrue,
    );
    expect(
      visualPort.profile.choice(SpatialVisualParameter.weatherKind),
      isNull,
    );
    expect(
      visuals.preview.value.choice(SpatialVisualParameter.weatherKind),
      'storm',
    );
    expect(settings.isDirty(ProjectSettingsSection.image), isFalse);
    expect(settings.isConfirmed(ProjectSettingsSection.image), isTrue);
    expect(settings.isDirty(ProjectSettingsSection.timeWeather), isTrue);
    expect(settings.isConfirmed(ProjectSettingsSection.timeWeather), isFalse);
    expect(settings.isDirty(ProjectSettingsSection.sounds), isTrue);
    expect(audioPort.writes, 0);
    expect(settings.isDirty(ProjectSettingsSection.general), isFalse);
  });

  test(
    'discarding Image keeps the weather draft and the sound draft',
    () async {
      visuals.edit(image.set(SpatialVisualParameter.weatherMode, 'automatic'));
      audio.gain(ProjectSoundCue.uiConfirm, '40');

      settings.discard(ProjectSettingsSection.image);

      expect(
        visuals.preview.value.enabled(
          SpatialVisualParameter.depthOfFieldEnabled,
        ),
        isNull,
      );
      expect(
        visuals.preview.value.choice(SpatialVisualParameter.weatherMode),
        'automatic',
      );
      expect(settings.isDirty(ProjectSettingsSection.image), isFalse);
      expect(settings.isDirty(ProjectSettingsSection.timeWeather), isTrue);
      expect(settings.isDirty(ProjectSettingsSection.sounds), isTrue);
      expect(visualPort.writes + audioPort.writes, 0);
    },
  );

  test('undo in one section leaves the other section of the same document', () {
    visuals.edit(
      SpatialVisualPatch().set(SpatialVisualParameter.weatherMode, 'automatic'),
    );
    visuals.edit(
      visuals.preview.value.set(
        SpatialVisualParameter.depthOfFieldEnabled,
        true,
      ),
    );

    expect(settings.canUndo(ProjectSettingsSection.timeWeather), isTrue);
    settings.undo(ProjectSettingsSection.timeWeather);

    expect(
      visuals.preview.value.choice(SpatialVisualParameter.weatherMode),
      isNull,
    );
    expect(
      visuals.preview.value.enabled(SpatialVisualParameter.depthOfFieldEnabled),
      isTrue,
    );
    expect(settings.canUndo(ProjectSettingsSection.timeWeather), isFalse);
    settings.redo(ProjectSettingsSection.timeWeather);
    expect(
      visuals.preview.value.choice(SpatialVisualParameter.weatherMode),
      'automatic',
    );
  });

  test(
    'saved is announced only after persistence and a failure keeps the draft',
    () async {
      visuals.edit(image);
      visualPort.pending = Completer<void>();
      final saving = settings.save(ProjectSettingsSection.image);
      expect(settings.isSaving(ProjectSettingsSection.image), isTrue);
      expect(settings.isConfirmed(ProjectSettingsSection.image), isFalse);
      expect(settings.isDirty(ProjectSettingsSection.image), isTrue);
      visualPort.pending!.complete();
      expect(await saving, isTrue);
      expect(settings.isConfirmed(ProjectSettingsSection.image), isTrue);

      visualPort
        ..pending = null
        ..fail = true;
      final next = image.set(SpatialVisualParameter.haloStrength, 1.5);
      visuals.edit(next);
      expect(settings.isConfirmed(ProjectSettingsSection.image), isFalse);
      expect(await settings.save(ProjectSettingsSection.image), isFalse);
      expect(visuals.preview.value, next);
      expect(settings.isDirty(ProjectSettingsSection.image), isTrue);
      expect(settings.errorOf(ProjectSettingsSection.image), isNotNull);
      expect(settings.isConfirmed(ProjectSettingsSection.image), isFalse);
    },
  );

  test(
    'map scope edits the map draft and switching scope never saves',
    () async {
      final mapPort = _VisualPort();
      final map = ProjectVisualsController(
        session: workspaceSession,
        port: mapPort,
      );
      addTearDown(map.dispose);
      await map.open(map: workspaceEntries.first);
      final scoped = ProjectSettingsSessionController(
        projectVisuals: visuals,
        mapVisuals: (id) => id == workspaceEntries.first.id ? map : null,
      );
      addTearDown(scoped.dispose);

      visuals.edit(image);
      scoped.scopeTo(workspaceEntries.first.id);
      expect(scoped.scopeMapId, workspaceEntries.first.id);
      expect(scoped.isDirty(ProjectSettingsSection.image), isFalse);
      expect(scoped.hasOtherScopeDraft(ProjectSettingsSection.image), isTrue);
      map.edit(
        SpatialVisualPatch().set(SpatialVisualParameter.cameraDistance, 10),
      );
      scoped.scopeTo(null);
      expect(scoped.isDirty(ProjectSettingsSection.image), isTrue);
      expect(visuals.preview.value, image);
      expect(
        map.preview.value.number(SpatialVisualParameter.cameraDistance),
        10,
      );
      expect(visualPort.writes + mapPort.writes, 0);

      scoped.scopeTo(workspaceEntries.first.id);
      expect(await scoped.save(ProjectSettingsSection.image), isTrue);
      expect(mapPort.writes, 1);
      expect(visualPort.writes, 0);
      expect(visuals.dirty, isTrue);
    },
  );

  test(
    'a write in flight survives closing the session without a late update',
    () async {
      visuals.edit(image);
      visualPort.pending = Completer<void>();
      var notified = 0;
      settings.addListener(() => notified++);
      final saving = settings.save(ProjectSettingsSection.image);
      settings.dispose();
      final before = notified;
      visualPort.pending!.complete();
      expect(await saving, isTrue);
      expect(notified, before);
      expect(visualPort.writes, 1);
      settings = ProjectSettingsSessionController(projectVisuals: visuals);
    },
  );
}

Future<void> _pumpPage(
  WidgetTester tester,
  MapWorkspaceController workspace,
  ProjectVisualsController owner,
) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: ProjectSettingsPage(workspace: workspace, owner: owner),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void pageTests() {
  final image = SpatialVisualPatch().set(
    SpatialVisualParameter.depthOfFieldEnabled,
    true,
  );

  testWidgets(
    'every section opens without a 3D map and the preview map writes nothing',
    (tester) async {
      final maps = _Maps(spatial: false);
      final workspace = MapWorkspaceController(workspaceSession, maps);
      await workspace.initialize();
      final owner = ProjectVisualsController(
        session: workspaceSession,
        port: maps,
      );
      await _pumpPage(tester, workspace, owner);
      for (final section in ProjectSettingsSection.values) {
        expect(
          find.byKey(ValueKey('settings-section-${section.name}')),
          findsOneWidget,
        );
      }
      await tester.tap(find.byKey(const ValueKey('settings-section-image')));
      await tester.pumpAndSettle();
      final controls = tester.widget<SpatialVisualControls>(
        find.byType(SpatialVisualControls),
      );
      expect(controls.onChanged, isNotNull);
      controls.onChanged!(image);
      await tester.pumpAndSettle();
      tester
          .widget<StudioSelect>(
            find.byKey(const ValueKey('settings-preview-map')),
          )
          .onChanged!(workspaceEntries.last.id);
      await tester.pumpAndSettle();
      expect(maps.visualWrites, 0);
      expect(owner.preview.value, image);
      await tester.tap(
        find.byKey(const ValueKey('settings-section-timeWeather')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-section-image')));
      await tester.pumpAndSettle();
      expect(owner.preview.value, image);
      expect(find.text('Brouillon non enregistré'), findsOneWidget);
      expect(maps.visualWrites, 0);
      await tester.tap(find.byKey(const ValueKey('settings-section-save')));
      await tester.pumpAndSettle();
      expect(maps.visualWrites, 1);
      expect(maps.lastVisualMap, isNull);
      expect(find.text('Rubrique enregistrée'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      owner.dispose();
      workspace.dispose();
    },
  );

  testWidgets('the map scope edits the map draft shared with the map space', (
    tester,
  ) async {
    final maps = _Maps(spatial: true);
    final workspace = MapWorkspaceController(workspaceSession, maps);
    await workspace.initialize();
    final owner = ProjectVisualsController(
      session: workspaceSession,
      port: maps,
    );
    await _pumpPage(tester, workspace, owner);
    await tester.tap(find.byKey(const ValueKey('settings-section-image')));
    await tester.pumpAndSettle();
    tester
        .widget<StudioSelect>(find.byKey(const ValueKey('settings-scope')))
        .onChanged!('map');
    await tester.pumpAndSettle();
    final local =
        workspace.documents[workspaceEntries.first.id]!.weatherVisuals!;
    tester
        .widget<SpatialVisualControls>(find.byType(SpatialVisualControls))
        .onChanged!(
      SpatialVisualPatch().set(SpatialVisualParameter.cameraDistance, 10),
    );
    await tester.pumpAndSettle();
    expect(
      local.preview.value.number(SpatialVisualParameter.cameraDistance),
      10,
    );
    expect(owner.dirty, isFalse);
    tester
        .widget<StudioSelect>(find.byKey(const ValueKey('settings-scope')))
        .onChanged!('project');
    await tester.pumpAndSettle();
    expect(local.dirty, isTrue);
    expect(maps.visualWrites, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    owner.dispose();
    workspace.dispose();
  });
}

final class _Maps extends WorkspaceMemoryPort implements ProjectVisualsPort {
  _Maps({required this.spatial});
  final bool spatial;
  int visualWrites = 0;
  String? lastVisualMap;

  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    final value = await super.loadMap(session, entry);
    if (!spatial) return value;
    return MapWorkspaceDocument(
      map: value.map.copyWith(
        spatialScene: MapSpatialScene(width: 20, depth: 16),
      ),
      revision: value.revision,
      mapId: entry.id,
    );
  }

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
  }) async {
    visualWrites++;
    lastVisualMap = map?.id;
    return ProjectVisualsState(profile: profile, revision: 'v$visualWrites');
  }

  @override
  Future<ProjectVisualsState> undoVisuals(
    ProjectSession session,
    String receiptId,
    String expectedRevision, {
    ProjectMapEntry? map,
  }) => throw UnimplementedError();
}

final class _VisualPort implements ProjectVisualsPort {
  SpatialVisualPatch profile = SpatialVisualPatch();
  int reads = 0, writes = 0;
  bool fail = false;
  Completer<void>? pending;

  @override
  Future<ProjectVisualsState> loadVisuals(
    ProjectSession session, {
    ProjectMapEntry? map,
  }) async {
    reads++;
    return ProjectVisualsState(profile: profile, revision: '$writes');
  }

  @override
  Future<ProjectVisualsState> saveVisuals(
    ProjectSession session,
    SpatialVisualPatch profile,
    String expectedRevision, {
    ProjectMapEntry? map,
  }) async {
    await pending?.future;
    if (fail) throw StateError('conflict');
    if (expectedRevision != '$writes') throw StateError('stale');
    writes++;
    this.profile = profile;
    return ProjectVisualsState(profile: profile, revision: '$writes');
  }

  @override
  Future<ProjectVisualsState> undoVisuals(
    ProjectSession session,
    String receiptId,
    String expectedRevision, {
    ProjectMapEntry? map,
  }) => throw UnimplementedError();
}

final class _AudioPort implements ProjectAudioPort {
  int writes = 0;

  @override
  Future<ProjectAudioState> loadAudio(ProjectSession session) async =>
      ProjectAudioState(configuration: ProjectAudioSettings(), revision: 'a0');

  @override
  Future<ProjectAudioState> saveAudioCue(
    ProjectSession session,
    ProjectSoundCue cue,
    ProjectSoundBinding? binding,
    String expectedRevision,
  ) async {
    writes++;
    return ProjectAudioState(
      configuration: ProjectAudioSettings().withCue(cue, binding),
      revision: 'a$writes',
    );
  }

  @override
  Future<ProjectAudioPage> queryAudio(
    ProjectSession session, {
    String query = '',
    String? cursor,
  }) async => const ProjectAudioPage(entries: []);

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
