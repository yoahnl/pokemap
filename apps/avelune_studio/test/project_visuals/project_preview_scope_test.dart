import 'package:avelune_studio/features/project_settings/application/project_settings_preview_controller.dart';
import 'package:avelune_studio/features/project_visuals/application/spatial_visual_editing.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_settings/application/project_settings_session_controller.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:avelune_studio/features/project_visuals/domain/project_visuals_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  Future<
    (ProjectSettingsPreviewController, ProjectSettingsSessionController, _Maps)
  >
  open({bool fail = false}) async {
    final maps = _Maps()..fail = fail;
    final workspace = MapWorkspaceController(workspaceSession, maps);
    addTearDown(workspace.dispose);
    await workspace.initialize();
    final owner = ProjectVisualsController(
      session: workspaceSession,
      port: maps,
    );
    addTearDown(owner.dispose);
    await owner.open();
    final settings = ProjectSettingsSessionController(projectVisuals: owner);
    addTearDown(settings.dispose);
    final preview = ProjectSettingsPreviewController(
      workspace: workspace,
      owner: owner,
      session: settings,
    );
    addTearDown(preview.dispose);
    await preview.start();
    settings.select(ProjectSettingsSection.image);
    return (preview, settings, maps);
  }

  SpatialVisualEditing editing(ProjectSettingsPreviewController preview) =>
      SpatialVisualEditing(
        patch: preview.owner.preview.value,
        inherited: preview.base,
        onChanged: preview.owner.edit,
        onInvalidInput: (parameter, text) => text == null
            ? preview.owner.clearInvalid(parameter)
            : preview.owner.reportInvalid(parameter, text),
      );

  test(
    'changing the preview map writes nothing and keeps the project distance',
    () async {
      final (preview, _, maps) = await open();
      await preview.choosePreview(workspaceEntries.last.id);
      expect(maps.visualWrites, 0);
      expect(
        preview.owner.preview.value.number(
          SpatialVisualParameter.cameraDistance,
        ),
        24,
      );
      expect(
        preview.rendered.value.number(SpatialVisualParameter.cameraDistance),
        24,
      );
    },
  );

  test('an invalid camera value blocks saving, keeps the text and never reaches the renderer', () async {
    final (preview, settings, maps) = await open();
    editing(preview).editNumber(SpatialVisualParameter.cameraDistance, 'abc');
    expect(
      preview.owner.invalidInputs[SpatialVisualParameter.cameraDistance],
      'abc',
    );
    expect(
      preview.owner.preview.value.number(SpatialVisualParameter.cameraDistance),
      24,
    );
    expect(
      preview.rendered.value.number(SpatialVisualParameter.cameraDistance),
      24,
    );
    expect(settings.canSave(ProjectSettingsSection.image), isFalse);
    expect(await settings.save(ProjectSettingsSection.image), isFalse);
    editing(preview).editNumber(SpatialVisualParameter.cameraDistance, '30');
    expect(
      preview.owner.preview.value.number(SpatialVisualParameter.cameraDistance),
      30,
    );
    expect(preview.owner.invalidInputs, isEmpty);
    expect(maps.visualWrites, 0);
  });

  test(
    'a failed first save keeps the draft and the history on the targeted port',
    () async {
      final (preview, settings, maps) = await open(fail: true);
      final owner = preview.owner;
      editing(preview).change(SpatialVisualParameter.fieldOfViewDegrees, 30.0);
      final draft = owner.preview.value;
      expect(draft.number(SpatialVisualParameter.fieldOfViewDegrees), 30);
      expect(draft.number(SpatialVisualParameter.cameraDistance), isNot(24));
      expect(await settings.save(ProjectSettingsSection.image), isFalse);
      expect(maps.visualAttempts, 1);
      expect(maps.lastVisualMap, isNull);
      expect(owner.preview.value, draft);
      expect(owner.canUndo, isTrue);
      expect(owner.error, contains('Écriture refusée'));
      owner.undo();
      expect(
        owner.preview.value.number(SpatialVisualParameter.cameraDistance),
        24,
      );
      expect(
        owner.preview.value.number(SpatialVisualParameter.fieldOfViewDegrees),
        isNull,
      );
    },
  );

  test(
    'the in-game preview compares the saved values with the draft',
    () async {
      final (preview, _, maps) = await open();
      expect(preview.preparePlaytest(), isNotNull);
      preview.owner.edit(
        preview.owner.preview.value.set(
          SpatialVisualParameter.cameraDistance,
          60.0,
        ),
      );
      expect(
        preview.rendered.value.number(SpatialVisualParameter.cameraDistance),
        60,
      );
      preview.compareSaved(true);
      expect(
        preview.rendered.value.number(SpatialVisualParameter.cameraDistance),
        24,
      );
      expect(
        preview.owner.preview.value.number(
          SpatialVisualParameter.cameraDistance,
        ),
        60,
      );
      expect(maps.visualWrites, 0);
    },
  );

  test(
    'image and time-weather sections block only on their own invalid inputs',
    () async {
      final maps = _Maps();
      final owner = ProjectVisualsController(
        session: workspaceSession,
        port: maps,
      );
      addTearDown(owner.dispose);
      await owner.open();
      final settings = ProjectSettingsSessionController(projectVisuals: owner);
      addTearDown(settings.dispose);
      owner.reportInvalid(SpatialVisualParameter.cameraDistance, 'abc');
      owner.edit(
        owner.preview.value.set(SpatialVisualParameter.minuteOfDay, 720),
      );
      expect(settings.canSave(ProjectSettingsSection.image), isFalse);
      expect(settings.canSave(ProjectSettingsSection.timeWeather), isTrue);
      expect(await owner.saveWhere(isImageVisualParameter), isFalse);
      owner.clearInvalid(SpatialVisualParameter.cameraDistance);
      expect(settings.draft(ProjectSettingsSection.image)!.blocked, isFalse);
    },
  );
}

final class _Maps extends WorkspaceMemoryPort implements ProjectVisualsPort {
  int visualWrites = 0, visualAttempts = 0;
  bool fail = false;
  String? lastVisualMap;
  SpatialVisualPatch profile = SpatialVisualPatch().set(
    SpatialVisualParameter.cameraDistance,
    24.0,
  );

  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    final value = await super.loadMap(session, entry);
    return MapWorkspaceDocument(
      map: value.map.copyWith(
        spatialScene: MapSpatialScene(
          width: 20,
          depth: 16,
          camera: SpatialCameraProfile(
            distance: entry.id == workspaceEntries.first.id ? 12 : 40,
          ),
        ),
      ),
      revision: value.revision,
      mapId: entry.id,
    );
  }

  @override
  Future<ProjectVisualsState> loadVisuals(
    ProjectSession session, {
    ProjectMapEntry? map,
  }) async => ProjectVisualsState(
    profile: map == null ? profile : SpatialVisualPatch(),
    revision: 'v',
  );

  @override
  Future<ProjectVisualsState> saveVisuals(
    ProjectSession session,
    SpatialVisualPatch profile,
    String expectedRevision, {
    ProjectMapEntry? map,
  }) async {
    visualAttempts++;
    lastVisualMap = map?.id;
    if (fail) throw StateError('Écriture refusée');
    visualWrites++;
    this.profile = profile;
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
