import 'dart:async';

import 'package:avelune_studio/features/project_settings/application/project_settings_preview_controller.dart';

import 'package:avelune_studio/features/project_audio/application/project_audio_controller.dart';
import 'package:avelune_studio/features/project_audio/domain/project_audio_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_settings/application/project_settings_session_controller.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:avelune_studio/features/project_visuals/domain/project_visuals_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
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

  test('invalid text alone is a pending draft only in its section', () async {
    final original = visuals.preview.value;
    final saved = visuals.saved;
    final reads = visualPort.reads;
    visuals.reportInvalid(SpatialVisualParameter.fieldOfViewDegrees, 'abc');

    expect(visuals.preview.value, same(original));
    expect(visuals.saved, same(saved));
    expect(visuals.dirty, isTrue);
    expect(settings.dirtySections, {ProjectSettingsSection.image});
    expect(visuals.dirtyWhere(isImageVisualParameter), isTrue);
    expect(visuals.dirtyWhere(isTimeWeatherVisualParameter), isFalse);
    expect(settings.canSave(ProjectSettingsSection.image), isFalse);
    expect(await settings.save(ProjectSettingsSection.image), isFalse);
    expect(visuals.invalidInputs, {
      SpatialVisualParameter.fieldOfViewDegrees: 'abc',
    });
    expect(visuals.preview.value, same(original));
    expect(visuals.saved, same(saved));
    expect(visuals.canUndo, isFalse);
    expect(visualPort.reads, reads);
    expect(visualPort.writes, 0);

    visuals.clearInvalid(SpatialVisualParameter.fieldOfViewDegrees);
    expect(visuals.dirty, isFalse);
    expect(settings.dirtySections, isEmpty);
    expect(visuals.preview.value, same(original));
    expect(visualPort.reads, reads);
    expect(visualPort.writes, 0);
  });

  test(
    'another section can save while invalid image text is retained',
    () async {
      visuals.reportInvalid(SpatialVisualParameter.fieldOfViewDegrees, 'abc');
      expect(settings.dirtySections, {ProjectSettingsSection.image});
      expect(await settings.save(ProjectSettingsSection.timeWeather), isTrue);
      expect(visualPort.writes, 0);
      visuals.edit(
        visuals.preview.value.set(SpatialVisualParameter.weatherIntensity, .5),
      );
      expect(await settings.save(ProjectSettingsSection.timeWeather), isTrue);
      expect(visualPort.writes, 1);
      expect(visualPort.reads, 1);
      expect(settings.dirtySections, {ProjectSettingsSection.image});
      expect(
        visuals.invalidInputs[SpatialVisualParameter.fieldOfViewDegrees],
        'abc',
      );
      expect(
        visualPort.profile.number(SpatialVisualParameter.weatherIntensity),
        .5,
      );
      expect(visuals.preview.value, visualPort.profile);

      visuals.reportInvalid(SpatialVisualParameter.weatherIntensity, 'xyz');
      settings.discard(ProjectSettingsSection.image);
      expect(visuals.invalidInputs, {
        SpatialVisualParameter.weatherIntensity: 'xyz',
      });
      expect(settings.dirtySections, {ProjectSettingsSection.timeWeather});
      expect(visuals.preview.value, visualPort.profile);
      settings.discard(ProjectSettingsSection.timeWeather);
      expect(visuals.dirty, isFalse);
      expect(visuals.invalidInputs, isEmpty);
      expect(visuals.preview.value, visualPort.profile);
      expect(visualPort.reads, 1);
      expect(visualPort.writes, 1);
    },
  );

  test(
    'an external profile cannot replace a draft containing only invalid text',
    () {
      final saved = visuals.saved;
      final original = visuals.preview.value;
      visuals.reportInvalid(SpatialVisualParameter.fieldOfViewDegrees, 'abc');
      expect(
        visuals.acceptExternalState(
          ProjectVisualsState(profile: image, revision: 'external'),
        ),
        isFalse,
      );
      expect(visuals.saved, same(saved));
      expect(visuals.preview.value, same(original));
      expect(
        visuals.invalidInputs[SpatialVisualParameter.fieldOfViewDegrees],
        'abc',
      );
      expect(visuals.dirty, isTrue);
      expect(visuals.error, contains('modification externe'));
      expect(visualPort.reads, 1);
      expect(visualPort.writes, 0);
    },
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

Future<
  ({
    MapWorkspaceController workspace,
    ProjectVisualsController owner,
    ProjectSettingsSessionController settings,
    ProjectSettingsPreviewController preview,
  })
>
_openPreview(_Maps maps) async {
  final workspace = MapWorkspaceController(workspaceSession, maps);
  addTearDown(workspace.dispose);
  await workspace.initialize();
  final owner = ProjectVisualsController(session: workspaceSession, port: maps);
  addTearDown(owner.dispose);
  await owner.open();
  final settings = ProjectSettingsSessionController(
    projectVisuals: owner,
    mapVisuals: (id) => workspace.documents[id] == null
        ? null
        : workspace.weatherDraftFor(workspace.documents[id]!),
  );
  addTearDown(settings.dispose);
  final preview = ProjectSettingsPreviewController(
    workspace: workspace,
    owner: owner,
    session: settings,
  );
  addTearDown(preview.dispose);
  await preview.start();
  return (
    workspace: workspace,
    owner: owner,
    settings: settings,
    preview: preview,
  );
}

void pageTests() {
  final image = SpatialVisualPatch().set(
    SpatialVisualParameter.depthOfFieldEnabled,
    true,
  );

  test(
    'every section opens without a 3D map and the preview map writes nothing',
    () async {
      final maps = _Maps(spatial: false);
      final f = await _openPreview(maps);
      for (final section in ProjectSettingsSection.values) {
        f.settings.select(section);
        expect(f.settings.section, section);
      }
      f.settings.select(ProjectSettingsSection.image);
      f.settings.scopedVisuals!.edit(image);
      await f.preview.choosePreview(workspaceEntries.last.id);
      expect(maps.visualWrites, 0);
      expect(f.owner.preview.value, image);
      f.settings.select(ProjectSettingsSection.timeWeather);
      f.settings.select(ProjectSettingsSection.image);
      expect(f.owner.preview.value, image);
      expect(f.settings.isDirty(ProjectSettingsSection.image), isTrue);
      expect(await f.settings.save(ProjectSettingsSection.image), isTrue);
      expect(maps.visualWrites, 1);
      expect(maps.lastVisualMap, isNull);
      expect(f.settings.isConfirmed(ProjectSettingsSection.image), isTrue);
    },
  );

  test('the map scope edits the map draft shared with the map space', () async {
    final maps = _Maps(spatial: true);
    final f = await _openPreview(maps);
    f.settings.select(ProjectSettingsSection.image);
    f.preview.chooseScope('map');
    await Future<void>.delayed(Duration.zero);
    final local =
        f.workspace.documents[workspaceEntries.first.id]!.weatherVisuals!;
    expect(f.settings.scopedVisuals, same(local));
    f.settings.scopedVisuals!.edit(
      SpatialVisualPatch().set(SpatialVisualParameter.cameraDistance, 10),
    );
    expect(
      local.preview.value.number(SpatialVisualParameter.cameraDistance),
      10,
    );
    expect(f.owner.dirty, isFalse);
    f.preview.chooseScope('project');
    expect(local.dirty, isTrue);
    expect(maps.visualWrites, 0);
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
