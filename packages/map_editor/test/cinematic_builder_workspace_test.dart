import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_builder_workspace.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

const _defaultBuilderSurfaceSize = Size(1280, 860);
const _referenceTimelineSurfaceSize = Size(1663, 926);

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
      expect(find.text(label), findsWidgets);
    }

    expect(find.text('Aperçu sandbox'), findsOneWidget);
    expect(find.text('Timeline par pistes'), findsOneWidget);
    expect(find.text('Projection temporelle dérivée du déroulé linéaire'),
        findsOneWidget);
    expect(find.text('2 step(s)'), findsWidgets);
    expect(find.text('750 ms estimé(s)'), findsWidgets);
    expect(find.text('8 piste(s)'), findsOneWidget);
    expect(find.text('Ordre linéaire conservé'), findsOneWidget);
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

  testWidgets('renders a derived time axis with proportional bars',
      (tester) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_timeLayoutCinematic()]);
    final before = project.toJson();
    await _pumpBuilder(
      tester,
      _entry(project, 'cinematic_time_layout'),
      asset: _asset(project, 'cinematic_time_layout'),
    );

    expect(find.text('Timeline par pistes'), findsOneWidget);
    expect(find.text('Projection temporelle dérivée du déroulé linéaire'),
        findsOneWidget);
    expect(find.text('Layout temporel dérivé'), findsOneWidget);
    expect(find.text('0 ms'), findsOneWidget);
    expect(find.text('500 ms'), findsWidgets);
    expect(find.text('1 s'), findsOneWidget);
    expect(find.text('1.5 s'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cinematic-builder-lane-camera')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('cinematic-builder-lane-actor:actor_professor'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('cinematic-builder-lane-time-global')),
      findsOneWidget,
    );

    final cameraRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_camera')),
    );
    final faceRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
    );
    final waitRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_wait')),
    );
    final moveRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_move')),
    );

    expect(faceRect.left, greaterThan(cameraRect.left));
    expect(waitRect.left, greaterThan(faceRect.left));
    expect(moveRect.left, greaterThan(waitRect.left));
    expect(moveRect.width, greaterThan(cameraRect.width));
    expect(cameraRect.width, greaterThan(faceRect.width));

    expect(find.text('Professor → Centre scène'), findsWidgets);
    expect(find.text('Cible: Centre scène'), findsWidgets);

    await tester.tapAt(Offset(cameraRect.left + 16, cameraRect.top + 16));
    await tester.pumpAndSettle();

    final selectedCameraBar = tester.widget<PokeMapCard>(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_camera')),
    );
    expect(selectedCameraBar.selected, isTrue);
    expect(find.text('Bloc sélectionné'), findsWidgets);
    expect(find.text('step_camera'), findsWidgets);
    expect(find.text('Camera reveal'), findsWidgets);
    expect(find.text('Fallback visuel'), findsWidgets);
    expect(find.text('drag'), findsNothing);
    expect(find.text('resize'), findsNothing);
    expect(project.toJson(), before);
  });

  testWidgets(
      'shows a non-interactive selection cursor on selected block start',
      (tester) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_timeLayoutCinematic()]);
    final before = project.toJson();
    await _pumpBuilder(
      tester,
      _entry(project, 'cinematic_time_layout'),
      asset: _asset(project, 'cinematic_time_layout'),
    );

    expect(find.textContaining('Sélection :'), findsNothing);
    expect(
      find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
      findsNothing,
    );

    final faceTapRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
    );
    await tester.tapAt(Offset(faceTapRect.left + 16, faceTapRect.top + 12));
    await tester.pumpAndSettle();

    expect(find.text('Sélection : 500 ms'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cinematic-builder-selection-cursor-handle')),
      findsOneWidget,
    );
    final faceCardRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
    );
    final faceCursorRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
    );
    expect(faceCursorRect.center.dx, closeTo(faceCardRect.left, 1));

    final moveTapRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_move')),
    );
    await tester.tapAt(Offset(moveTapRect.left + 16, moveTapRect.top + 12));
    await tester.pumpAndSettle();

    expect(find.text('Sélection : 1.1 s'), findsOneWidget);
    expect(find.text('Sélection : 500 ms'), findsNothing);
    final moveCardRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_move')),
    );
    final moveCursorRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-selection-cursor')),
    );
    expect(moveCursorRect.center.dx, closeTo(moveCardRect.left, 1));
    expect(moveCursorRect.left, greaterThan(faceCursorRect.left));

    final axisRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-axis')),
    );
    await tester.tapAt(Offset(axisRect.left + 24, axisRect.center.dy));
    await tester.pumpAndSettle();

    final selectedMoveCard = tester.widget<PokeMapCard>(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_move')),
    );
    expect(selectedMoveCard.selected, isTrue);
    expect(find.text('Sélection : 1.1 s'), findsOneWidget);
    expect(find.text('Playback'), findsNothing);
    expect(find.text('Lecture'), findsNothing);
    expect(find.text('Scrubber'), findsNothing);
    expect(project.toJson(), before);
  });

  testWidgets('balances sandbox preview and timeline proportions on reference',
      (tester) async {
    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    final project = _project(cinematics: [_timeLayoutCinematic()]);
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
    );

    final previewRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-preview-placeholder')),
    );
    final timelineRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-timeline-placeholder')),
    );

    expect(timelineRect.height, greaterThanOrEqualTo(360));
    expect(previewRect.height, lessThanOrEqualTo(450));
    expect(timelineRect.top, greaterThan(previewRect.bottom));
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

    expect(find.text('Timeline par pistes'), findsOneWidget);
    expect(find.byKey(const ValueKey('cinematic-builder-lane-camera')),
        findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('cinematic-builder-lane-actor:actor_professor'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('cinematic-builder-lane-dialogue')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('cinematic-builder-lane-audio')),
        findsOneWidget);
    expect(find.text('Acteur: Professor'), findsWidgets);
    expect(find.text('Aucun step dans cette piste.'), findsWidgets);
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

  testWidgets('shows lane grouping V0 without enabling actor movement',
      (tester) async {
    _setLargeSurface(tester);
    final project = _project(cinematics: [_laneShowcaseCinematic()]);
    final before = project.toJson();
    await _pumpBuilder(
      tester,
      _entry(project, 'cinematic_lane_showcase'),
      asset: _asset(project, 'cinematic_lane_showcase'),
    );

    for (final key in <String>[
      'cinematic-builder-lane-camera',
      'cinematic-builder-lane-actor:actor_professor',
      'cinematic-builder-lane-actor:actor_rival',
      'cinematic-builder-lane-dialogue',
      'cinematic-builder-lane-fx',
      'cinematic-builder-lane-audio',
      'cinematic-builder-lane-transitions',
      'cinematic-builder-lane-time-global',
      'cinematic-builder-lane-other',
    ]) {
      expect(find.byKey(ValueKey<String>(key)), findsOneWidget);
    }

    expect(find.text('Acteur: Professor'), findsWidgets);
    expect(find.text('Acteur: Rival'), findsWidgets);
    expect(find.text('Aucun step dans cette piste.'), findsWidgets);
    expect(find.text('Timeline par pistes'), findsOneWidget);
    expect(find.text('9 piste(s)'), findsOneWidget);
    expect(find.text('Déplacement acteur'), findsOneWidget);
    expect(find.text('Ajoutez d’abord une cible'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cinematic-builder-palette-actorMove-button')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(
              const ValueKey('cinematic-builder-palette-actorMove-button'),
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
    );
    await tester.pumpAndSettle();

    final selectedFaceCard = tester.widget<PokeMapCard>(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
    );
    expect(selectedFaceCard.selected, isTrue);
    expect(find.text('Bloc sélectionné'), findsWidgets);
    expect(find.text('step_face'), findsWidgets);
    expect(find.text('Direction'), findsWidgets);
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
    final addDraftButton =
        find.byKey(const ValueKey('cinematic-builder-add-draft-button'));
    await tester.ensureVisible(addDraftButton);
    await tester.tap(addDraftButton);
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

    final cameraStepCard =
        find.byKey(const ValueKey('cinematic-builder-step-card-step_camera'));
    await tester.ensureVisible(cameraStepCard);
    await tester.tap(cameraStepCard);
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey('cinematic-builder-remove-authoring-step-button'),
      ),
      findsNothing,
    );

    await tester.drag(
      find.byKey(const ValueKey('cinematic-builder-timeline-placeholder')),
      const Offset(0, 500),
    );
    await tester.pumpAndSettle();
    final addDraftButton =
        find.byKey(const ValueKey('cinematic-builder-add-draft-button'));
    await tester.ensureVisible(addDraftButton);
    await tester.tap(addDraftButton);
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

  testWidgets('adds a required actor before enabling actor facing',
      (tester) async {
    _setLargeSurface(tester);
    late ProjectManifest latestProject;
    final project = _project(
      cinematics: [
        CinematicAsset(
          id: 'cinematic_no_actor',
          title: 'No actor cinematic',
          timeline: CinematicTimeline(),
        ),
      ],
      includeBridge: false,
    );
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_no_actor',
      onProjectChanged: (project) => latestProject = project,
    );

    final actorFaceButton = find.byKey(
      const ValueKey('cinematic-builder-palette-actorFace-button'),
    );
    expect(actorFaceButton, findsOneWidget);
    expect(tester.widget<PokeMapButton>(actorFaceButton).onPressed, isNull);
    expect(find.text('Ajoutez d’abord un acteur requis'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-add-required-actor-button')),
    );
    await tester.pumpAndSettle();

    expect(
        latestProject.cinematics.single.requiredActors.single.actorId, 'actor');
    expect(
        latestProject.cinematics.single.requiredActors.single.label, 'Acteur');
    expect(find.text('Acteur'), findsWidgets);
    expect(tester.widget<PokeMapButton>(actorFaceButton).onPressed, isNotNull);
  });

  testWidgets('adds and edits actor facing with actor picker and direction',
      (tester) async {
    _setLargeSurface(tester);
    late ProjectManifest latestProject;
    final project = _project(cinematics: [_actorFacingCinematic()]);
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_actor_face',
      onProjectChanged: (project) => latestProject = project,
    );

    expect(
      find.byKey(const ValueKey('cinematic-builder-palette-actorFace-button')),
      findsOneWidget,
    );
    expect(find.text('Professor'), findsWidgets);
    expect(find.text('Rival'), findsWidgets);

    final actorFaceButton = find
        .byKey(const ValueKey('cinematic-builder-palette-actorFace-button'));
    await tester.ensureVisible(actorFaceButton);
    await tester.tap(actorFaceButton);
    await tester.pumpAndSettle();

    var actorFaceStep = latestProject.cinematics.single.timeline.steps.last;
    expect(actorFaceStep.kind, CinematicTimelineStepKind.actorFace);
    expect(actorFaceStep.label, 'Orientation Professor');
    expect(actorFaceStep.actorId, 'actor_professor');
    expect(
        actorFaceStep.metadata, containsPair('authoring.block', 'actorFace'));
    expect(actorFaceStep.metadata, containsPair('actor.direction', 'down'));
    expect(find.text('Orientation Professor'), findsWidgets);
    expect(find.text('Acteur: Professor'), findsWidgets);
    expect(find.text('Direction'), findsWidgets);

    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-actor-picker-actor_rival')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-actor-picker-actor_rival')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-actor-direction-left')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-actor-direction-left')),
    );
    await tester.pumpAndSettle();

    actorFaceStep = latestProject.cinematics.single.timeline.steps.last;
    expect(actorFaceStep.actorId, 'actor_rival');
    expect(actorFaceStep.label, 'Orientation Rival');
    expect(actorFaceStep.metadata, containsPair('actor.direction', 'left'));
    expect(find.text('Acteur: Rival'), findsWidgets);
    expect(find.text('Gauche'), findsWidgets);

    await tester.tap(
      find.byKey(
        const ValueKey('cinematic-builder-remove-authoring-step-button'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      latestProject.cinematics.single.timeline.steps.map((step) => step.kind),
      [CinematicTimelineStepKind.wait],
    );
  });

  testWidgets('enables actor movement only after actor and target exist',
      (tester) async {
    _setLargeSurface(tester);
    late ProjectManifest latestProject;
    final project = _project(
      cinematics: [
        CinematicAsset(
          id: 'cinematic_no_target',
          title: 'No target cinematic',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
          ],
          timeline: CinematicTimeline(),
        ),
      ],
      includeBridge: false,
    );
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_no_target',
      onProjectChanged: (project) => latestProject = project,
    );

    final actorMoveButton = find.byKey(
      const ValueKey('cinematic-builder-palette-actorMove-button'),
    );
    expect(actorMoveButton, findsOneWidget);
    expect(tester.widget<PokeMapButton>(actorMoveButton).onPressed, isNull);
    expect(find.text('Ajoutez d’abord une cible'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const ValueKey('cinematic-builder-add-movement-target-button'),
      ),
    );
    await tester.pumpAndSettle();

    expect(latestProject.cinematics.single.movementTargets.single.targetId,
        'target');
    expect(
        latestProject.cinematics.single.movementTargets.single.label, 'Cible');
    expect(find.text('Cibles de déplacement'), findsOneWidget);
    expect(find.text('Cible'), findsWidgets);
    expect(tester.widget<PokeMapButton>(actorMoveButton).onPressed, isNotNull);
  });

  testWidgets('keeps actor movement disabled without required actor',
      (tester) async {
    _setLargeSurface(tester);
    final project = _project(
      cinematics: [
        CinematicAsset(
          id: 'cinematic_no_actor_move',
          title: 'No actor move cinematic',
          movementTargets: [
            CinematicMovementTargetRef(targetId: 'target', label: 'Cible'),
          ],
          timeline: CinematicTimeline(),
        ),
      ],
      includeBridge: false,
    );
    await _pumpBuilderHarness(tester, project, 'cinematic_no_actor_move');

    final actorMoveButton = find.byKey(
      const ValueKey('cinematic-builder-palette-actorMove-button'),
    );
    expect(actorMoveButton, findsOneWidget);
    expect(tester.widget<PokeMapButton>(actorMoveButton).onPressed, isNull);
    expect(find.text('Ajoutez d’abord un acteur'), findsOneWidget);
  });

  testWidgets('adds edits and removes actor movement authoring block',
      (tester) async {
    _setLargeSurface(tester);
    late ProjectManifest latestProject;
    final project = _project(cinematics: [_actorMovementCinematic()]);
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_actor_move',
      onProjectChanged: (project) => latestProject = project,
    );

    final actorMoveButton = find
        .byKey(const ValueKey('cinematic-builder-palette-actorMove-button'));
    await tester.ensureVisible(actorMoveButton);
    await tester.tap(actorMoveButton);
    await tester.pumpAndSettle();

    var actorMoveStep = latestProject.cinematics.single.timeline.steps.last;
    expect(actorMoveStep.kind, CinematicTimelineStepKind.actorMove);
    expect(actorMoveStep.label, 'Déplacement Professor');
    expect(actorMoveStep.actorId, 'actor_professor');
    expect(actorMoveStep.targetId, 'target_center');
    expect(actorMoveStep.durationMs, 1000);
    expect(
        actorMoveStep.metadata, containsPair('authoring.block', 'actorMove'));
    expect(actorMoveStep.metadata, containsPair('actor.movementMode', 'walk'));
    expect(actorMoveStep.metadata, containsPair('actor.pathMode', 'direct'));
    expect(find.text('Professor → Centre scène'), findsWidgets);
    expect(find.text('Acteur: Professor'), findsWidgets);
    expect(find.text('Cible: Centre scène'), findsWidgets);
    expect(find.text('Mode mouvement'), findsOneWidget);
    expect(find.text('Chemin direct verrouillé'), findsOneWidget);
    expect(
      find.text('Le chemin direct est un contrat authoring V0.'),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-actor-picker-actor_rival')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-actor-picker-actor_rival')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-target-picker-target_exit')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-target-picker-target_exit')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(
        const ValueKey('cinematic-builder-actor-move-duration-preset-2000'),
      ),
    );
    await tester.tap(
      find.byKey(
        const ValueKey('cinematic-builder-actor-move-duration-preset-2000'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(
        const ValueKey('cinematic-builder-actor-move-mode-run'),
      ),
    );
    await tester.tap(
      find.byKey(
        const ValueKey('cinematic-builder-actor-move-mode-run'),
      ),
    );
    await tester.pumpAndSettle();

    actorMoveStep = latestProject.cinematics.single.timeline.steps.last;
    expect(actorMoveStep.actorId, 'actor_rival');
    expect(actorMoveStep.targetId, 'target_exit');
    expect(actorMoveStep.durationMs, 2000);
    expect(actorMoveStep.metadata, containsPair('actor.movementMode', 'run'));
    expect(actorMoveStep.metadata, containsPair('actor.pathMode', 'direct'));
    expect(find.text('Rival → Sortie'), findsWidgets);
    expect(find.text('Cible: Sortie'), findsWidgets);
    expect(find.text('Course'), findsWidgets);

    await tester.tap(
      find.byKey(
        const ValueKey('cinematic-builder-remove-authoring-step-button'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      latestProject.cinematics.single.timeline.steps.map((step) => step.kind),
      [CinematicTimelineStepKind.wait],
    );
  });

  testWidgets('polishes movement target labels and actor movement inspector',
      (tester) async {
    _setLargeSurface(tester);
    late ProjectManifest latestProject;
    final project = _project(cinematics: [_actorMovementCinematic()]);
    await _pumpBuilderHarness(
      tester,
      project,
      'cinematic_actor_move',
      onProjectChanged: (project) => latestProject = project,
    );

    final actorMoveButton = find
        .byKey(const ValueKey('cinematic-builder-palette-actorMove-button'));
    await tester.ensureVisible(actorMoveButton);
    await tester.tap(actorMoveButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Professor marche vers Centre scène en 1000 ms.'),
      findsOneWidget,
    );
    expect(find.text('Professor → Centre scène'), findsWidgets);
    expect(find.text('Chemin direct verrouillé'), findsOneWidget);
    expect(
      find.text('Le chemin direct est un contrat authoring V0.'),
      findsOneWidget,
    );
    expect(
      find.text('Intention visuelle, sans vitesse runtime.'),
      findsOneWidget,
    );

    final usedDeleteButton = find.byKey(
      const ValueKey('cinematic-builder-delete-movement-target-target_center'),
    );
    await tester.ensureVisible(usedDeleteButton);
    expect(tester.widget<PokeMapButton>(usedDeleteButton).onPressed, isNull);
    expect(
      find.text('Cette cible est utilisée par un bloc Déplacement acteur.'),
      findsOneWidget,
    );

    final labelField = find.byKey(
      const ValueKey('cinematic-builder-movement-target-label-target_center'),
    );
    await tester.ensureVisible(labelField);
    await tester.enterText(labelField, 'Centre du plateau');
    await tester.enterText(
      find.byKey(
        const ValueKey(
          'cinematic-builder-movement-target-description-target_center',
        ),
      ),
      'Point central authoring.',
    );
    final saveTargetButton = find.byKey(
      const ValueKey('cinematic-builder-save-movement-target-target_center'),
    );
    await tester.ensureVisible(saveTargetButton);
    await tester.pumpAndSettle();
    await tester.tap(saveTargetButton);
    await tester.pumpAndSettle();

    final renamedTarget = latestProject.cinematics.single.movementTargets
        .singleWhere((target) => target.targetId == 'target_center');
    expect(renamedTarget.label, 'Centre du plateau');
    expect(renamedTarget.description, 'Point central authoring.');
    expect(
      latestProject.cinematics.single.timeline.steps.last.label,
      'Déplacement Professor',
    );
    expect(
      find.text('Professor marche vers Centre du plateau en 1000 ms.'),
      findsOneWidget,
    );
    expect(find.text('Professor → Centre du plateau'), findsWidgets);

    await tester.enterText(labelField, '   ');
    await tester.ensureVisible(saveTargetButton);
    await tester.pumpAndSettle();
    await tester.tap(saveTargetButton);
    await tester.pumpAndSettle();
    expect(find.text('Label cible obligatoire'), findsOneWidget);
    expect(
      latestProject.cinematics.single.movementTargets
          .singleWhere((target) => target.targetId == 'target_center')
          .label,
      'Centre du plateau',
    );

    final unusedDeleteButton = find.byKey(
      const ValueKey('cinematic-builder-delete-movement-target-target_exit'),
    );
    await tester.ensureVisible(unusedDeleteButton);
    expect(
        tester.widget<PokeMapButton>(unusedDeleteButton).onPressed, isNotNull);
    await tester.tap(unusedDeleteButton);
    await tester.pumpAndSettle();
    expect(
      latestProject.cinematics.single.movementTargets
          .map((target) => target.targetId),
      ['target_center'],
    );
    expect(find.text('target_exit'), findsNothing);
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

  testWidgets('captures V1-46 builder actor facing screenshot when requested',
      (tester) async {
    if (!const bool.fromEnvironment(
      'NS_SCENES_V1_46_CAPTURE_CINEMATIC_BUILDER_ACTOR_FACING',
    )) {
      return;
    }

    _setLargeSurface(tester);
    await _loadScreenshotFonts();
    await _pumpBuilderHarness(
      tester,
      _project(cinematics: [_actorFacingCinematic()]),
      'cinematic_actor_face',
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-palette-actorFace-button')),
    );
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_46_cinematic_actor_references_actor_facing_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures V1-48 builder lane grouping screenshot when requested',
      (tester) async {
    if (!const bool.fromEnvironment(
      'NS_SCENES_V1_48_CAPTURE_CINEMATIC_TIMELINE_LANES',
    )) {
      return;
    }

    _setLargeSurface(tester);
    await _loadScreenshotFonts();
    await _pumpBuilderHarness(
      tester,
      _project(cinematics: [_laneVisualGateCinematic()]),
      'cinematic_lane_visual_gate',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
    );
    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-step-card-step_face')),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('cinematic-builder-timeline-placeholder')),
      const Offset(0, 260),
    );
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_48_cinematic_timeline_lane_grouping_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures V1-49 actor movement block screenshot when requested',
      (tester) async {
    if (!const bool.fromEnvironment(
      'NS_SCENES_V1_49_CAPTURE_CINEMATIC_ACTOR_MOVEMENT',
    )) {
      return;
    }

    _setLargeSurface(tester);
    await _loadScreenshotFonts();
    await _pumpBuilderHarness(
      tester,
      _project(cinematics: [_actorMovementCinematic()]),
      'cinematic_actor_move',
    );
    final actorMoveButton = find
        .byKey(const ValueKey('cinematic-builder-palette-actorMove-button'));
    await tester.ensureVisible(actorMoveButton);
    await tester.tap(actorMoveButton);
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_49_cinematic_actor_movement_block_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets(
      'captures V1-50 actor movement target polish screenshot when requested',
      (tester) async {
    if (!const bool.fromEnvironment(
      'NS_SCENES_V1_50_CAPTURE_CINEMATIC_ACTOR_MOVEMENT_POLISH',
    )) {
      return;
    }

    _setLargeSurface(tester);
    await _loadScreenshotFonts();
    await _pumpBuilderHarness(
      tester,
      _project(cinematics: [_actorMovementCinematic()]),
      'cinematic_actor_move',
    );
    final actorMoveButton = find
        .byKey(const ValueKey('cinematic-builder-palette-actorMove-button'));
    await tester.ensureVisible(actorMoveButton);
    await tester.tap(actorMoveButton);
    await tester.pumpAndSettle();

    final labelField = find.byKey(
      const ValueKey('cinematic-builder-movement-target-label-target_center'),
    );
    await tester.ensureVisible(labelField);
    await tester.enterText(labelField, 'Centre du plateau');
    await tester.enterText(
      find.byKey(
        const ValueKey(
          'cinematic-builder-movement-target-description-target_center',
        ),
      ),
      'Point central authoring.',
    );
    final saveTargetButton = find.byKey(
      const ValueKey('cinematic-builder-save-movement-target-target_center'),
    );
    await tester.ensureVisible(saveTargetButton);
    await tester.pumpAndSettle();
    await tester.tap(saveTargetButton);
    await tester.pumpAndSettle();
    await tester.ensureVisible(labelField);
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_50_cinematic_actor_movement_inspector_polish_'
      'target_labels_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures V1-51 timeline time axis bar layout when requested',
      (tester) async {
    if (!const bool.fromEnvironment(
      'NS_SCENES_V1_51_CAPTURE_CINEMATIC_TIMELINE_BAR_LAYOUT',
    )) {
      return;
    }

    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    await _loadScreenshotFonts();
    await _pumpBuilderHarness(
      tester,
      _project(cinematics: [_timeLayoutCinematic()]),
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
    );
    final cameraRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_camera')),
    );
    await tester.tapAt(Offset(cameraRect.left + 16, cameraRect.top + 16));
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });

  testWidgets('captures V1-52 timeline selection cursor when requested',
      (tester) async {
    if (!const bool.fromEnvironment(
      'NS_SCENES_V1_52_CAPTURE_CINEMATIC_TIMELINE_SELECTION_CURSOR',
    )) {
      return;
    }

    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
    await _loadScreenshotFonts();
    await _pumpBuilderHarness(
      tester,
      _project(cinematics: [_timeLayoutCinematic()]),
      'cinematic_time_layout',
      surfaceSize: _referenceTimelineSurfaceSize,
    );
    final faceRect = tester.getRect(
      find.byKey(const ValueKey('cinematic-builder-time-block-step_face')),
    );
    await tester.tapAt(Offset(faceRect.left + 16, faceRect.top + 16));
    await tester.pumpAndSettle();

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_52_cinematic_timeline_selection_cursor_'
      'playhead_placeholder_v0.png',
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
  Size surfaceSize = _defaultBuilderSurfaceSize,
}) async {
  await tester.pumpWidget(
    MacosTheme(
      data: MacosThemeData.dark(),
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: surfaceSize.width,
            height: surfaceSize.height,
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
              onAddRequiredActor: ({required String cinematicId}) async => null,
              onAddMovementTarget: ({required String cinematicId}) async =>
                  null,
              onUpdateMovementTarget: ({
                required String cinematicId,
                required String targetId,
                required String label,
                String? description,
              }) async =>
                  false,
              onRemoveMovementTarget: ({
                required String cinematicId,
                required String targetId,
              }) async =>
                  false,
              onAddActorFacingStep: ({
                required String cinematicId,
                required String actorId,
                required CinematicTimelineActorFacingDirection direction,
                String? afterStepId,
              }) async =>
                  null,
              onUpdateActorFacingStep: ({
                required String cinematicId,
                required String stepId,
                String? actorId,
                CinematicTimelineActorFacingDirection? direction,
              }) async =>
                  false,
              onAddActorMoveStep: ({
                required String cinematicId,
                required String actorId,
                required String targetId,
                required int durationMs,
                required CinematicTimelineActorMovementMode movementMode,
                String? afterStepId,
              }) async =>
                  null,
              onUpdateActorMoveStep: ({
                required String cinematicId,
                required String stepId,
                String? actorId,
                String? targetId,
                int? durationMs,
                CinematicTimelineActorMovementMode? movementMode,
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
  Size surfaceSize = _defaultBuilderSurfaceSize,
}) async {
  await tester.pumpWidget(
    _BuilderHarness(
      project: project,
      cinematicId: cinematicId,
      onProjectChanged: onProjectChanged,
      surfaceSize: surfaceSize,
    ),
  );
  await tester.pumpAndSettle();
}

class _BuilderHarness extends StatefulWidget {
  const _BuilderHarness({
    required this.project,
    required this.cinematicId,
    required this.surfaceSize,
    this.onProjectChanged,
  });

  final ProjectManifest project;
  final String cinematicId;
  final Size surfaceSize;
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
            width: widget.surfaceSize.width,
            height: widget.surfaceSize.height,
            child: CinematicBuilderWorkspace(
              entry: entry,
              asset: asset,
              onBackToLibrary: () {},
              onAddDraftStep: _addDraftStep,
              onRemoveDraftStep: _removeDraftStep,
              onAddBasicBlockStep: _addBasicBlockStep,
              onUpdateBasicBlockStep: _updateBasicBlockStep,
              onAddRequiredActor: _addRequiredActor,
              onAddMovementTarget: _addMovementTarget,
              onUpdateMovementTarget: _updateMovementTarget,
              onRemoveMovementTarget: _removeMovementTarget,
              onAddActorFacingStep: _addActorFacingStep,
              onUpdateActorFacingStep: _updateActorFacingStep,
              onAddActorMoveStep: _addActorMoveStep,
              onUpdateActorMoveStep: _updateActorMoveStep,
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

  Future<String?> _addRequiredActor({required String cinematicId}) async {
    final result = addCinematicRequiredActor(
      _project,
      cinematicId: cinematicId,
      label: 'Acteur',
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return result.actor.actorId;
  }

  Future<String?> _addMovementTarget({required String cinematicId}) async {
    final result = addCinematicMovementTarget(
      _project,
      cinematicId: cinematicId,
      label: 'Cible',
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return result.target.targetId;
  }

  Future<bool> _updateMovementTarget({
    required String cinematicId,
    required String targetId,
    required String label,
    String? description,
  }) async {
    final result = updateCinematicMovementTarget(
      _project,
      cinematicId: cinematicId,
      targetId: targetId,
      label: label,
      description: description,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return result.target.targetId == targetId;
  }

  Future<bool> _removeMovementTarget({
    required String cinematicId,
    required String targetId,
  }) async {
    final result = removeCinematicMovementTarget(
      _project,
      cinematicId: cinematicId,
      targetId: targetId,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return result.removedTarget.targetId == targetId;
  }

  Future<String?> _addActorFacingStep({
    required String cinematicId,
    required String actorId,
    required CinematicTimelineActorFacingDirection direction,
    String? afterStepId,
  }) async {
    final result = addCinematicTimelineActorFacingStep(
      _project,
      cinematicId: cinematicId,
      actorId: actorId,
      direction: direction,
      afterStepId: afterStepId,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return result.step.id;
  }

  Future<String?> _addActorMoveStep({
    required String cinematicId,
    required String actorId,
    required String targetId,
    required int durationMs,
    required CinematicTimelineActorMovementMode movementMode,
    String? afterStepId,
  }) async {
    final result = addCinematicTimelineActorMoveStep(
      _project,
      cinematicId: cinematicId,
      actorId: actorId,
      targetId: targetId,
      durationMs: durationMs,
      movementMode: movementMode,
      afterStepId: afterStepId,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return result.step.id;
  }

  Future<bool> _updateActorMoveStep({
    required String cinematicId,
    required String stepId,
    String? actorId,
    String? targetId,
    int? durationMs,
    CinematicTimelineActorMovementMode? movementMode,
  }) async {
    final result = updateCinematicTimelineActorMoveStep(
      _project,
      cinematicId: cinematicId,
      stepId: stepId,
      actorId: actorId,
      targetId: targetId,
      durationMs: durationMs,
      movementMode: movementMode,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return result.step.id == stepId;
  }

  Future<bool> _updateActorFacingStep({
    required String cinematicId,
    required String stepId,
    String? actorId,
    CinematicTimelineActorFacingDirection? direction,
  }) async {
    final result = updateCinematicTimelineActorFacingStep(
      _project,
      cinematicId: cinematicId,
      stepId: stepId,
      actorId: actorId,
      direction: direction,
    );
    setState(() => _project = result.updatedProject);
    widget.onProjectChanged?.call(_project);
    return result.step.id == stepId;
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

CinematicAsset _actorFacingCinematic() {
  return CinematicAsset(
    id: 'cinematic_actor_face',
    title: 'Actor facing cinematic',
    description: 'Actor picker and facing direction.',
    mapId: 'map_lab',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
      CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
    ],
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_wait',
          kind: CinematicTimelineStepKind.wait,
          label: 'Opening wait',
          durationMs: 500,
        ),
      ],
    ),
  );
}

CinematicAsset _actorMovementCinematic() {
  return CinematicAsset(
    id: 'cinematic_actor_move',
    title: 'Actor movement cinematic',
    description: 'Actor movement V0 fixture.',
    mapId: 'map_lab',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
      CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
    ],
    movementTargets: [
      CinematicMovementTargetRef(
        targetId: 'target_center',
        label: 'Centre scène',
        description: 'Point central authoring.',
      ),
      CinematicMovementTargetRef(
        targetId: 'target_exit',
        label: 'Sortie',
        description: 'Sortie de scène.',
      ),
    ],
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_wait',
          kind: CinematicTimelineStepKind.wait,
          label: 'Opening wait',
          durationMs: 500,
        ),
      ],
    ),
  );
}

CinematicAsset _timeLayoutCinematic() {
  return CinematicAsset(
    id: 'cinematic_time_layout',
    title: 'Time layout cinematic',
    description: 'Neutral fixture for timeline bars.',
    mapId: 'map_lab',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
      CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
    ],
    movementTargets: [
      CinematicMovementTargetRef(
        targetId: 'target_center',
        label: 'Centre scène',
        description: 'Point central authoring.',
      ),
      CinematicMovementTargetRef(
        targetId: 'target_exit',
        label: 'Sortie',
        description: 'Sortie de scène.',
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
          id: 'step_face',
          kind: CinematicTimelineStepKind.actorFace,
          label: 'Professor turns',
          actorId: 'actor_professor',
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey:
                cinematicTimelineActorFaceBlockMetadataValue,
            cinematicTimelineActorDirectionMetadataKey: 'right',
          },
        ),
        CinematicTimelineStep(
          id: 'step_wait',
          kind: CinematicTimelineStepKind.wait,
          label: 'Beat',
          durationMs: 0,
        ),
        CinematicTimelineStep(
          id: 'step_move',
          kind: CinematicTimelineStepKind.actorMove,
          label: 'Move Professor',
          actorId: 'actor_professor',
          targetId: 'target_center',
          durationMs: 1000,
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey:
                cinematicTimelineActorMoveBlockMetadataValue,
            cinematicTimelineActorMovementModeMetadataKey: 'walk',
            cinematicTimelineActorPathModeMetadataKey: 'direct',
          },
        ),
        CinematicTimelineStep(
          id: 'step_fade',
          kind: CinematicTimelineStepKind.fade,
          label: 'Fade out',
          durationMs: 600,
        ),
        CinematicTimelineStep(
          id: 'step_sound',
          kind: CinematicTimelineStepKind.sound,
          label: 'Cue bell',
          durationMs: 300,
          assetRef: 'cue_bell',
        ),
      ],
    ),
  );
}

CinematicAsset _laneShowcaseCinematic() {
  return CinematicAsset(
    id: 'cinematic_lane_showcase',
    title: 'Lane showcase cinematic',
    description: 'Neutral fixture for lane grouping.',
    mapId: 'map_lab',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
      CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
    ],
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_camera',
          kind: CinematicTimelineStepKind.camera,
          label: 'Camera pan',
          durationMs: 400,
        ),
        CinematicTimelineStep(
          id: 'step_face',
          kind: CinematicTimelineStepKind.actorFace,
          label: 'Professor turns',
          durationMs: 300,
          actorId: 'actor_professor',
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey:
                cinematicTimelineActorFaceBlockMetadataValue,
            cinematicTimelineActorDirectionMetadataKey: 'right',
          },
        ),
        CinematicTimelineStep(
          id: 'step_dialogue',
          kind: CinematicTimelineStepKind.dialogueLine,
          label: 'Professor line',
          durationMs: 900,
          actorId: 'actor_professor',
          dialogueText: 'Tout est prêt.',
        ),
        CinematicTimelineStep(
          id: 'step_fx',
          kind: CinematicTimelineStepKind.fx,
          label: 'Sparkle',
          durationMs: 250,
          assetRef: 'sparkle_fx',
        ),
        CinematicTimelineStep(
          id: 'step_sound',
          kind: CinematicTimelineStepKind.sound,
          label: 'Cue bell',
          durationMs: 200,
          assetRef: 'cue_bell',
        ),
        CinematicTimelineStep(
          id: 'step_fade',
          kind: CinematicTimelineStepKind.fade,
          label: 'Fade out',
          durationMs: 600,
        ),
        CinematicTimelineStep(
          id: 'step_wait',
          kind: CinematicTimelineStepKind.wait,
          label: 'Beat',
          durationMs: 500,
        ),
      ],
    ),
  );
}

CinematicAsset _laneVisualGateCinematic() {
  return CinematicAsset(
    id: 'cinematic_lane_visual_gate',
    title: 'Lane visual gate cinematic',
    description: 'Neutral fixture for lane grouping screenshot.',
    mapId: 'map_lab',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_professor', label: 'Professor'),
      CinematicActorRef(actorId: 'actor_rival', label: 'Rival'),
    ],
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_face',
          kind: CinematicTimelineStepKind.actorFace,
          label: 'Professor turns',
          durationMs: 300,
          actorId: 'actor_professor',
          metadata: const {
            cinematicTimelineDraftMetadataKindKey:
                cinematicTimelineBasicBlockMetadataKindValue,
            cinematicTimelineDraftMetadataSourceKey:
                cinematicTimelineDraftMetadataSourceValue,
            cinematicTimelineAuthoringBlockMetadataKey:
                cinematicTimelineActorFaceBlockMetadataValue,
            cinematicTimelineActorDirectionMetadataKey: 'right',
          },
        ),
        CinematicTimelineStep(
          id: 'step_dialogue',
          kind: CinematicTimelineStepKind.dialogueLine,
          label: 'Professor line',
          durationMs: 900,
          actorId: 'actor_professor',
          dialogueText: 'Tout est prêt.',
        ),
        CinematicTimelineStep(
          id: 'step_fx',
          kind: CinematicTimelineStepKind.fx,
          label: 'Sparkle',
          durationMs: 250,
          assetRef: 'sparkle_fx',
        ),
        CinematicTimelineStep(
          id: 'step_sound',
          kind: CinematicTimelineStepKind.sound,
          label: 'Cue bell',
          durationMs: 200,
          assetRef: 'cue_bell',
        ),
        CinematicTimelineStep(
          id: 'step_fade',
          kind: CinematicTimelineStepKind.fade,
          label: 'Fade out',
          durationMs: 600,
        ),
        CinematicTimelineStep(
          id: 'step_wait',
          kind: CinematicTimelineStepKind.wait,
          label: 'Beat',
          durationMs: 500,
        ),
      ],
    ),
  );
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

void _setLargeSurface(
  WidgetTester tester, [
  Size surfaceSize = _defaultBuilderSurfaceSize,
]) {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
