import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_settings/application/project_settings_session_controller.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:avelune_studio/features/project_visuals/domain/project_visuals_port.dart';
import 'package:avelune_studio/presentation/features/project_settings/project_settings_page.dart';
import 'package:avelune_studio/presentation/features/project_settings/spatial_visual_controls.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_draft_field.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  Future<(MapWorkspaceController, ProjectVisualsController, _Maps)> open(
    WidgetTester tester, {
    bool fail = false,
    StudioVisualTestBuilder? testBuilder,
  }) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final maps = _Maps()..fail = fail;
    final workspace = MapWorkspaceController(workspaceSession, maps);
    await workspace.initialize();
    final owner = ProjectVisualsController(
      session: workspaceSession,
      port: maps,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: ProjectSettingsPage(
            workspace: workspace,
            owner: owner,
            testBuilder: testBuilder,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings-section-image')));
    await tester.pumpAndSettle();
    return (workspace, owner, maps);
  }

  Future<void> close(
    WidgetTester tester,
    MapWorkspaceController workspace,
    ProjectVisualsController owner,
  ) async {
    await tester.pumpWidget(const SizedBox());
    owner.dispose();
    workspace.dispose();
  }

  testWidgets(
    'changing the preview map writes nothing and keeps the project distance',
    (tester) async {
      final (workspace, owner, maps) = await open(tester);
      expect(
        find.byKey(const ValueKey('visual-provenance-cameraDistance')),
        findsOneWidget,
      );
      expect(find.text('Défini par le projet'), findsWidgets);
      tester
          .widget<StudioSelect>(
            find.byKey(const ValueKey('settings-preview-map')),
          )
          .onChanged!(workspaceEntries.last.id);
      await tester.pumpAndSettle();
      expect(maps.visualWrites, 0);
      expect(
        owner.preview.value.number(SpatialVisualParameter.cameraDistance),
        24,
      );
      final distance = tester.widget<StudioDraftField>(
        find.byKey(const ValueKey('visual-entry-cameraDistance')),
      );
      expect(distance.value, '24.00');
      expect(tester.takeException(), isNull);
      await close(tester, workspace, owner);
    },
  );

  testWidgets(
    'an invalid camera value blocks saving, keeps the text and never reaches the renderer',
    (tester) async {
      final (workspace, owner, maps) = await open(tester);
      final field = find.descendant(
        of: find.byKey(const ValueKey('visual-entry-cameraDistance')),
        matching: find.byType(TextField),
      );
      await tester.enterText(field, 'abc');
      await tester.pump();
      expect(find.text('abc'), findsOneWidget);
      expect(find.textContaining('Saisissez un nombre'), findsOneWidget);
      expect(
        owner.preview.value.number(SpatialVisualParameter.cameraDistance),
        24,
      );
      final save = tester.widget<ButtonStyleButton>(
        find.descendant(
          of: find.byKey(const ValueKey('settings-section-save')),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      );
      expect(save.onPressed, isNull);
      await tester.enterText(field, '30');
      await tester.pump();
      expect(
        owner.preview.value.number(SpatialVisualParameter.cameraDistance),
        30,
      );
      expect(find.textContaining('Saisissez un nombre'), findsNothing);
      expect(owner.invalidInputs, isEmpty);
      expect(maps.visualWrites, 0);
      await close(tester, workspace, owner);
    },
  );

  testWidgets(
    'a failed first save keeps the draft and the history on the targeted port',
    (tester) async {
      final (workspace, owner, maps) = await open(tester, fail: true);
      tester
          .widget<SpatialVisualControls>(find.byType(SpatialVisualControls))
          .change(SpatialVisualParameter.fieldOfViewDegrees, 30.0);
      await tester.pumpAndSettle();
      final draft = owner.preview.value;
      expect(draft.number(SpatialVisualParameter.fieldOfViewDegrees), 30);
      expect(draft.number(SpatialVisualParameter.cameraDistance), isNot(24));
      await tester.tap(find.byKey(const ValueKey('settings-section-save')));
      await tester.pumpAndSettle();
      expect(maps.visualAttempts, 1);
      expect(maps.lastVisualMap, isNull);
      expect(owner.preview.value, draft);
      expect(owner.canUndo, isTrue);
      owner.undo();
      expect(
        owner.preview.value.number(SpatialVisualParameter.cameraDistance),
        24,
      );
      expect(
        owner.preview.value.number(SpatialVisualParameter.fieldOfViewDegrees),
        isNull,
      );
      expect(find.text('Réessayer l’enregistrement'), findsOneWidget);
      await close(tester, workspace, owner);
    },
  );

  testWidgets('the in-game preview compares the saved values with the draft', (
    tester,
  ) async {
    ValueListenable<SpatialVisualPatch>? rendered;
    final (workspace, owner, maps) = await open(
      tester,
      testBuilder: (entry, revision, close, preview) {
        rendered = preview;
        return const SizedBox(key: ValueKey('fake-runtime'));
      },
    );
    await tester.tap(find.byKey(const ValueKey('test-project-visuals')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('fake-runtime')), findsOneWidget);
    owner.edit(
      owner.preview.value.set(SpatialVisualParameter.cameraDistance, 60.0),
    );
    await tester.pumpAndSettle();
    expect(rendered!.value.number(SpatialVisualParameter.cameraDistance), 60);
    await tester.tap(find.text('Mémorisé'));
    await tester.pumpAndSettle();
    expect(rendered!.value.number(SpatialVisualParameter.cameraDistance), 24);
    expect(
      owner.preview.value.number(SpatialVisualParameter.cameraDistance),
      60,
    );
    expect(maps.visualWrites, 0);
    await close(tester, workspace, owner);
  });

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
