import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_builder_workspace.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('shows populated read-only cinematic builder shell',
      (tester) async {
    _setLargeSurface(tester);
    final project = _project();
    final before = project.toJson();
    await _pumpBuilder(
      tester,
      _entry(project, 'cinematic_intro'),
      asset: _asset(project, 'cinematic_intro'),
    );

    expect(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      findsOneWidget,
    );
    expect(find.text('Cinematic Builder V0'), findsOneWidget);
    expect(find.text('Intro cinematic'), findsWidgets);
    expect(find.text('cinematic_intro'), findsWidgets);

    for (final label in <String>[
      'Caméra',
      'Déplacement acteur',
      'Dialogue',
      'FX',
      'Son',
      'Fondu',
      'Attente',
    ]) {
      expect(find.text(label), findsOneWidget);
    }

    expect(find.text('Aperçu sandbox'), findsOneWidget);
    expect(find.text('Déroulé read-only'), findsOneWidget);
    expect(find.text('2 step(s)'), findsWidgets);
    expect(find.text('750 ms estimé(s)'), findsWidgets);
    expect(find.text('Camera reveal'), findsWidgets);
    expect(find.text('Professor reacts'), findsWidgets);
    expect(find.text('Aucun bloc sélectionné'), findsOneWidget);
    expect(find.text('Sélection de bloc à venir'), findsOneWidget);
    expect(find.text('actor_professor'), findsWidgets);
    expect(find.text('Canonical scene'), findsWidgets);

    for (final key in <String>[
      'cinematic-builder-validate-button',
      'cinematic-builder-preview-button',
      'cinematic-builder-save-button',
    ]) {
      final button = tester.widget<PokeMapButton>(
        find.byKey(ValueKey<String>(key)),
      );
      expect(button.onPressed, isNull);
    }

    expect(find.text('Ajouter un bloc'), findsNothing);
    expect(project.toJson(), before);
  });

  testWidgets('lists timeline steps in order with read-only details',
      (tester) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_richCinematic()]);
    final before = project.toJson();
    await _pumpBuilder(
      tester,
      _entry(project, 'cinematic_rich'),
      asset: _asset(project, 'cinematic_rich'),
    );

    expect(find.text('Déroulé read-only'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Camera to door'), findsWidgets);
    expect(find.text('camera'), findsWidgets);
    expect(find.text('400 ms'), findsWidgets);
    expect(find.text('target_camera_focus'), findsWidgets);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Professor line'), findsWidgets);
    expect(find.text('dialogueLine'), findsWidgets);
    expect(find.text('actor_professor'), findsWidgets);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Door chime'), findsWidgets);
    expect(find.text('sound'), findsWidgets);
    expect(find.text('door_chime'), findsWidgets);

    expect(find.text('Ajouter un bloc'), findsNothing);
    expect(find.text('Supprimer le bloc'), findsNothing);
    expect(find.byType(CupertinoTextField), findsNothing);
    expect(project.toJson(), before);
  });

  testWidgets('selects a step locally and updates read-only inspector',
      (tester) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_richCinematic()]);
    final before = project.toJson();
    await _pumpBuilder(
      tester,
      _entry(project, 'cinematic_rich'),
      asset: _asset(project, 'cinematic_rich'),
    );

    expect(find.text('Aucun bloc sélectionné'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_dialogue')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_dialogue')),
    );
    await tester.pumpAndSettle();

    final selectedDialogueCard = tester.widget<PokeMapCard>(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_dialogue')),
    );
    expect(selectedDialogueCard.selected, isTrue);
    expect(find.text('Bloc sélectionné'), findsWidgets);
    expect(find.text('step_dialogue'), findsWidgets);
    expect(find.text('Index'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    expect(find.text('Kind'), findsWidgets);
    expect(find.text('dialogueLine'), findsWidgets);
    expect(find.text('Dialogue'), findsWidgets);
    expect(find.text('Labo sécurisé.'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_sound')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_sound')),
    );
    await tester.pumpAndSettle();

    final selectedSoundCard = tester.widget<PokeMapCard>(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_sound')),
    );
    expect(selectedSoundCard.selected, isTrue);
    expect(find.text('step_sound'), findsWidgets);
    expect(find.text('Asset'), findsWidgets);
    expect(find.text('door_chime'), findsWidgets);
    expect(find.text('volume = 0.8'), findsOneWidget);
    expect(project.toJson(), before);
  });

  testWidgets('shows step diagnostics without enabling timeline changes',
      (tester) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_diagnosticCinematic()]);
    final before = project.toJson();
    await _pumpBuilder(
      tester,
      _entry(project, 'cinematic_diagnostic'),
      asset: _asset(project, 'cinematic_diagnostic'),
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_bad')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_bad')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Step 1'), findsWidgets);
    expect(find.text('cinematicInvalidStepDuration'), findsWidgets);
    expect(
      find.text('Une durée de step cinematic ne peut pas être négative.'),
      findsOneWidget,
    );
    expect(find.text('Aucune action de correction dans ce lot.'), findsWidgets);
    expect(find.text('Ajouter un bloc'), findsNothing);
    expect(find.text('Sauvegarder'), findsWidgets);
    expect(project.toJson(), before);
  });

  testWidgets('adds a safe draft after selected step and inspects it',
      (tester) async {
    _setLargeSurface(tester);
    late ProjectManifest latestProject;
    final project = _project(cinematics: [_richCinematic()]);
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_rich',
      onProjectChanged: (project) => latestProject = project,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_dialogue')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_dialogue')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-add-draft-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-add-draft-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bloc brouillon'), findsWidgets);
    expect(find.text('Brouillon'), findsWidgets);
    expect(find.text('marker'), findsWidgets);
    expect(find.text('Statut'), findsWidgets);
    expect(find.text('Placeholder authoring'), findsOneWidget);
    expect(
      find.text(
        'Ce bloc est un placeholder authoring. '
        'Les vrais blocs arrivent dans un lot futur.',
      ),
      findsOneWidget,
    );
    expect(
        find.text(
            'authoring.kind = draft, authoring.source = cinematic-builder-v0'),
        findsOneWidget);
    final selectedDraftCard = tester.widget<PokeMapCard>(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_draft')),
    );
    expect(selectedDraftCard.selected, isTrue);
    expect(
      latestProject.cinematics.single.timeline.steps.map((step) => step.id),
      ['step_camera', 'step_dialogue', 'step_draft', 'step_sound'],
    );
    expect(latestProject.scenes, project.scenes);
    expect(latestProject.scenarios, project.scenarios);
  });

  testWidgets('removes only the selected draft from the builder',
      (tester) async {
    _setLargeSurface(tester);
    late ProjectManifest latestProject;
    final project = _project(cinematics: [_richCinematic()]);
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_rich',
      onProjectChanged: (project) => latestProject = project,
    );

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_camera')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey('cinematic-builder-remove-authoring-step-button'),
      ),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-add-draft-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bloc brouillon'), findsWidgets);
    await tester.tap(
      find.byKey(
        const ValueKey('cinematic-builder-remove-authoring-step-button'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cinematic-builder-step-card-step_draft')),
        findsNothing);
    expect(find.text('Aucun bloc sélectionné'), findsOneWidget);
    expect(
      latestProject.cinematics.single.timeline.steps.map((step) => step.id),
      ['step_camera', 'step_dialogue', 'step_sound'],
    );
  });

  testWidgets('adds and edits wait fade and camera basic blocks',
      (tester) async {
    _setLargeSurface(tester);
    late ProjectManifest latestProject;
    final project = _project(cinematics: [_richCinematic()]);
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_rich',
      onProjectChanged: (project) => latestProject = project,
    );

    expect(find.byKey(const ValueKey('cinematic-builder-palette-wait-button')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('cinematic-builder-palette-fade-button')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('cinematic-builder-palette-camera-button')),
        findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-palette-wait-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Attente'), findsWidgets);
    expect(find.text('Bloc authoring V0'), findsOneWidget);
    expect(find.text('wait'), findsWidgets);
    expect(find.text('1000 ms'), findsWidgets);
    expect(
      latestProject.cinematics.single.timeline.steps.last.kind,
      CinematicTimelineStepKind.wait,
    );
    expect(
      latestProject.cinematics.single.timeline.steps.last.metadata,
      containsPair('authoring.block', 'wait'),
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-duration-preset-2000')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-duration-preset-2000')),
    );
    await tester.pumpAndSettle();

    expect(
        latestProject.cinematics.single.timeline.steps.last.durationMs, 2000);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-palette-fade-button')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-fade-mode-fadeOut')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-fade-mode-fadeOut')),
    );
    await tester.pumpAndSettle();

    final fadeStep = latestProject.cinematics.single.timeline.steps.last;
    expect(fadeStep.kind, CinematicTimelineStepKind.fade);
    expect(fadeStep.metadata, containsPair('fade.mode', 'fadeOut'));
    expect(find.text('Fondu sortant'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-palette-camera-button')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-camera-mode-hold')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-camera-mode-hold')),
    );
    await tester.pumpAndSettle();

    final cameraStep = latestProject.cinematics.single.timeline.steps.last;
    expect(cameraStep.kind, CinematicTimelineStepKind.camera);
    expect(cameraStep.actorId, isNull);
    expect(cameraStep.targetId, isNull);
    expect(cameraStep.metadata, containsPair('camera.mode', 'hold'));
    expect(find.text('Caméra'), findsWidgets);
    expect(find.text('Hold'), findsWidgets);

    await tester.tap(
      find.byKey(
        const ValueKey('cinematic-builder-remove-authoring-step-button'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      latestProject.cinematics.single.timeline.steps.map((step) => step.kind),
      [
        CinematicTimelineStepKind.camera,
        CinematicTimelineStepKind.dialogueLine,
        CinematicTimelineStepKind.sound,
        CinematicTimelineStepKind.wait,
        CinematicTimelineStepKind.fade,
      ],
    );
  });

  testWidgets('shows empty timeline state without authoring controls',
      (tester) async {
    _setLargeSurface(tester);
    final project = _project(
      cinematics: [
        CinematicAsset(
          id: 'cinematic_empty',
          title: 'Empty cinematic',
          timeline: CinematicTimeline(),
        ),
      ],
      includeBridge: false,
    );
    await _pumpBuilder(
      tester,
      _entry(project, 'cinematic_empty'),
      asset: _asset(project, 'cinematic_empty'),
    );

    expect(find.text('Empty cinematic'), findsWidgets);
    expect(find.text('Timeline vide'), findsWidgets);
    expect(
      find.text('Cette cinématique ne contient encore aucun bloc.'),
      findsOneWidget,
    );
    expect(find.text('Aperçu sandbox'), findsOneWidget);
    expect(find.text('Aucun bloc sélectionné'), findsOneWidget);
    expect(find.byKey(const ValueKey('cinematic-builder-palette-wait-button')),
        findsOneWidget);
  });

  testWidgets('calls back to library from builder header', (tester) async {
    _setLargeSurface(tester);
    var returned = false;
    await _pumpBuilder(
      tester,
      _entry(_project(), 'cinematic_intro'),
      asset: _asset(_project(), 'cinematic_intro'),
      onBackToLibrary: () => returned = true,
    );

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-back-button')),
    );
    await tester.pumpAndSettle();

    expect(returned, isTrue);
  });

  testWidgets('captures V1-43 builder timeline screenshot when requested',
      (tester) async {
    if (!const bool.fromEnvironment(
      'NS_SCENES_V1_43_CAPTURE_CINEMATIC_BUILDER_TIMELINE',
    )) {
      return;
    }

    _setLargeSurface(tester);
    await _loadScreenshotFonts();
    final project = _project(cinematics: [_richCinematic()]);
    await _pumpBuilder(
      tester,
      _entry(project, 'cinematic_rich'),
      asset: _asset(project, 'cinematic_rich'),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_dialogue')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_dialogue')),
    );
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures V1-44 builder draft screenshot when requested',
      (tester) async {
    if (!const bool.fromEnvironment(
      'NS_SCENES_V1_44_CAPTURE_CINEMATIC_BUILDER_DRAFTS',
    )) {
      return;
    }

    _setLargeSurface(tester);
    await _loadScreenshotFonts();
    await _pumpBuilderHarness(
      tester,
      _project(cinematics: [_richCinematic()]),
      'cinematic_rich',
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-add-draft-button')),
    );
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures V1-45 builder basic blocks screenshot when requested',
      (tester) async {
    if (!const bool.fromEnvironment(
      'NS_SCENES_V1_45_CAPTURE_CINEMATIC_BUILDER_BASIC_BLOCKS',
    )) {
      return;
    }

    _setLargeSurface(tester);
    await _loadScreenshotFonts();
    await _pumpBuilderHarness(
      tester,
      _project(cinematics: [_richCinematic()]),
      'cinematic_rich',
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-palette-wait-button')),
    );
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });
}

Future<void> _pumpBuilder(
  WidgetTester tester,
  CinematicsLibraryEntry entry, {
  required CinematicAsset asset,
  VoidCallback? onBackToLibrary,
}) async {
  await tester.pumpWidget(
    MacosTheme(
      data: MacosThemeData.dark(),
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1280,
            height: 860,
            child: CinematicBuilderWorkspace(
              entry: entry,
              asset: asset,
              onBackToLibrary: onBackToLibrary ?? () {},
              onAddDraftStep: ({
                required String cinematicId,
                String? afterStepId,
              }) async =>
                  null,
              onRemoveDraftStep: ({
                required String cinematicId,
                required String stepId,
              }) async =>
                  false,
              onAddBasicBlockStep: ({
                required String cinematicId,
                required CinematicTimelineBasicBlockKind blockKind,
                String? afterStepId,
              }) async =>
                  null,
              onUpdateBasicBlockStep: ({
                required String cinematicId,
                required String stepId,
                int? durationMs,
                CinematicTimelineFadeMode? fadeMode,
                CinematicTimelineCameraMode? cameraMode,
              }) async =>
                  false,
              onRemoveAuthoringStep: ({
                required String cinematicId,
                required String stepId,
              }) async =>
                  false,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpBuilderHarness(
  WidgetTester tester,
  ProjectManifest project,
  String cinematicId, {
  ValueChanged<ProjectManifest>? onProjectChanged,
}) async {
  await tester.pumpWidget(
    _BuilderHarness(
      project: project,
      cinematicId: cinematicId,
      onProjectChanged: onProjectChanged,
    ),
  );
  await tester.pumpAndSettle();
}

class _BuilderHarness extends StatefulWidget {
  const _BuilderHarness({
    required this.project,
    required this.cinematicId,
    this.onProjectChanged,
  });

  final ProjectManifest project;
  final String cinematicId;
  final ValueChanged<ProjectManifest>? onProjectChanged;

  @override
  State<_BuilderHarness> createState() => _BuilderHarnessState();
}

class _BuilderHarnessState extends State<_BuilderHarness> {
  late ProjectManifest _project = widget.project;

  @override
  Widget build(BuildContext context) {
    final entry = _entry(_project, widget.cinematicId);
    final asset = _asset(_project, widget.cinematicId);
    return MacosTheme(
      data: MacosThemeData.dark(),
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1280,
            height: 860,
            child: CinematicBuilderWorkspace(
              entry: entry,
              asset: asset,
              onBackToLibrary: () {},
              onAddDraftStep: _addDraftStep,
              onRemoveDraftStep: _removeDraftStep,
              onAddBasicBlockStep: _addBasicBlockStep,
              onUpdateBasicBlockStep: _updateBasicBlockStep,
              onRemoveAuthoringStep: _removeAuthoringStep,
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _addDraftStep({
    required String cinematicId,
    String? afterStepId,
  }) async {
    final result = addCinematicTimelineDraftStep(
      _project,
      cinematicId: cinematicId,
      afterStepId: afterStepId,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return result.step.id;
  }

  Future<bool> _removeDraftStep({
    required String cinematicId,
    required String stepId,
  }) async {
    final result = removeCinematicTimelineDraftStep(
      _project,
      cinematicId: cinematicId,
      stepId: stepId,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return true;
  }

  Future<String?> _addBasicBlockStep({
    required String cinematicId,
    required CinematicTimelineBasicBlockKind blockKind,
    String? afterStepId,
  }) async {
    final result = addCinematicTimelineBasicBlockStep(
      _project,
      cinematicId: cinematicId,
      blockKind: blockKind,
      afterStepId: afterStepId,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return result.step.id;
  }

  Future<bool> _updateBasicBlockStep({
    required String cinematicId,
    required String stepId,
    int? durationMs,
    CinematicTimelineFadeMode? fadeMode,
    CinematicTimelineCameraMode? cameraMode,
  }) async {
    final result = updateCinematicTimelineBasicBlockStep(
      _project,
      cinematicId: cinematicId,
      stepId: stepId,
      durationMs: durationMs,
      fadeMode: fadeMode,
      cameraMode: cameraMode,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return true;
  }

  Future<bool> _removeAuthoringStep({
    required String cinematicId,
    required String stepId,
  }) async {
    final result = removeCinematicTimelineAuthoringStep(
      _project,
      cinematicId: cinematicId,
      stepId: stepId,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return result.removedStep.id == stepId;
  }
}

CinematicAsset _asset(ProjectManifest project, String id) {
  final asset = findCinematicById(project, id);
  if (asset == null) {
    throw StateError('Missing cinematic asset $id');
  }
  return asset;
}

CinematicAsset _richCinematic() {
  return CinematicAsset(
    id: 'cinematic_rich',
    title: 'Rich cinematic',
    description: 'Readable step details.',
    mapId: 'map_lab',
    requiredActors: [
      CinematicActorRef(
        actorId: 'actor_professor',
        label: 'Professor',
      ),
    ],
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_camera',
          kind: CinematicTimelineStepKind.camera,
          label: 'Camera to door',
          durationMs: 400,
          targetId: 'target_camera_focus',
        ),
        CinematicTimelineStep(
          id: 'step_dialogue',
          kind: CinematicTimelineStepKind.dialogueLine,
          label: 'Professor line',
          durationMs: 1200,
          actorId: 'actor_professor',
          dialogueText: 'Labo sécurisé.',
        ),
        CinematicTimelineStep(
          id: 'step_sound',
          kind: CinematicTimelineStepKind.sound,
          label: 'Door chime',
          durationMs: 300,
          assetRef: 'door_chime',
          metadata: const {'volume': '0.8'},
        ),
      ],
    ),
  );
}

CinematicAsset _diagnosticCinematic() {
  return CinematicAsset(
    id: 'cinematic_diagnostic',
    title: 'Diagnostic cinematic',
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_bad',
          kind: CinematicTimelineStepKind.wait,
          durationMs: -5,
        ),
      ],
    ),
  );
}

CinematicsLibraryEntry _entry(ProjectManifest project, String id) {
  final entry = buildCinematicsLibraryReadModel(project).entryById(id);
  if (entry == null) {
    throw StateError('Missing cinematic entry $id');
  }
  return entry;
}

Future<void> _loadScreenshotFonts() async {
  final fontBytes =
      File('/System/Library/Fonts/Supplemental/Arial.ttf').readAsBytesSync();
  for (final family in <String>[
    'Roboto',
    'Arial',
    '.SF Pro Text',
    'SF Pro Text',
  ]) {
    final loader = FontLoader(family)
      ..addFont(Future<ByteData>.value(ByteData.sublistView(fontBytes)));
    await loader.load();
  }
}

ProjectManifest _project({
  List<CinematicAsset>? cinematics,
  bool includeBridge = true,
}) {
  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: 'cinematic_project',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(id: 'map_lab', name: 'Lab map', relativePath: 'lab.json'),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    scenes: [
      if (cinematics == null)
        _sceneReferencing(
          id: 'scene_canonical',
          name: 'Canonical scene',
          nodeId: 'node_cinematic',
          nodeTitle: 'Play intro',
          cinematicId: 'cinematic_intro',
        ),
      if (includeBridge)
        _sceneReferencing(
          id: 'scene_bridge',
          name: 'Bridge scene',
          nodeId: 'node_bridge',
          nodeTitle: 'Play bridge',
          cinematicId: 'scenario_cutscene',
        ),
    ],
    scenarios: includeBridge
        ? const <ScenarioAsset>[
            ScenarioAsset(
              id: 'scenario_cutscene',
              name: 'Legacy cutscene',
              scope: ScenarioScope.localEventFlow,
              entryNodeId: 'start',
              metadata: <String, String>{
                'authoring.cutsceneSchema': 'cutscene-studio-v0',
              },
            ),
          ]
        : const <ScenarioAsset>[],
    cinematics: [
      ...?cinematics,
      if (cinematics == null)
        CinematicAsset(
          id: 'cinematic_intro',
          title: 'Intro cinematic',
          description: 'Camera reveal.',
          mapId: 'map_lab',
          requiredActors: [
            CinematicActorRef(
              actorId: 'actor_professor',
              label: 'Professor',
            ),
          ],
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_camera',
                kind: CinematicTimelineStepKind.camera,
                label: 'Camera reveal',
                durationMs: 500,
              ),
              CinematicTimelineStep(
                id: 'step_emote',
                kind: CinematicTimelineStepKind.actorEmote,
                label: 'Professor reacts',
                durationMs: 250,
                actorId: 'actor_professor',
              ),
            ],
          ),
        ),
    ],
  );
}

SceneAsset _sceneReferencing({
  required String id,
  required String name,
  required String nodeId,
  required String nodeTitle,
  required String cinematicId,
}) {
  return SceneAsset(
    id: id,
    name: name,
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: nodeId,
          kind: SceneNodeKind.cinematic,
          title: nodeTitle,
          payload: SceneCinematicPayload(cinematicId: cinematicId),
        ),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
    ),
  );
}

void _setLargeSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 860);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
