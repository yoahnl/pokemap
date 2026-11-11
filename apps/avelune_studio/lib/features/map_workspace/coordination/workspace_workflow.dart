import 'package:avelune_studio/features/project_cs/application/project_cs_controller.dart';
import 'package:avelune_studio/features/project_audio/application/project_audio_controller.dart';
import 'package:avelune_studio/features/project_settings/application/project_identity_controller.dart';
import 'package:avelune_studio/features/verification/application/test_launch_preflight.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:avelune_studio/features/project_surf/application/project_surf_controller.dart';
import 'package:avelune_studio/features/regional_map/application/regional_map_controller.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:avelune_studio/features/presentations/application/presentation_workspace_controller.dart';

import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';

import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';

part 'workspace_workflow_close.dart';

enum WorkspaceCloseChoice { save, discard, cancel }

class WorkspaceWorkflow {
  WorkspaceWorkflow({
    required this.controller,
    required this.isActive,
    required this.changed,
    required this.resources,
    required this.narrative,
    this.scenes,
    this.events,
    this.dialogues,
    this.cinematics,
    this.presentations,
    this.regionalMap,
    this.world,
    this.projectVisuals,
    this.projectSurf,
    this.projectCs,
    this.projectAudio,
    this.projectIdentity,
    this.confirmLaunch,
    this.worldInputsValid,
    this.publishedCinematicContext,
    required this.confirmClose,
    required this.flushFocus,
    required this.launchMap,
    this.launchGame,
  });
  final MapWorkspaceController controller;
  final bool Function() isActive;
  final void Function() changed;
  final ResourceNavigation? Function() resources;
  final NarrativeWorkspaceController? Function() narrative;
  final SceneWorkspaceController? Function()? scenes;
  final EventWorkspaceController? Function()? events;
  final DialogueWorkspaceController? Function()? dialogues;
  final CinematicWorkspaceController? Function()? cinematics;
  final PresentationWorkspaceController? Function()? presentations;
  final RegionalMapController? Function()? regionalMap;
  final WorldWorkspaceController? Function()? world;
  final ProjectVisualsController? Function()? projectVisuals;
  final ProjectSurfController? Function()? projectSurf;
  final ProjectCsController? Function()? projectCs;
  final ProjectAudioController? Function()? projectAudio;
  final ProjectIdentityController? Function()? projectIdentity;
  final Future<bool> Function(TestLaunchPreflight preflight)? confirmLaunch;
  final bool Function()? worldInputsValid;
  final bool Function()? publishedCinematicContext;
  final Future<WorkspaceCloseChoice?> Function() confirmClose;
  final void Function() flushFocus;
  final Future<void> Function(ProjectMapEntry entry, String revision) launchMap;
  final Future<void> Function()? launchGame;
  bool testing = false;
  bool closing = false;
  bool get busy =>
      projectSurf?.call()?.saving == true ||
      projectCs?.call()?.saving == true ||
      projectAudio?.call()?.busy == true ||
      projectIdentity?.call()?.saving == true ||
      projectVisuals?.call()?.saving == true ||
      testing ||
      closing ||
      dialogues?.call()?.busy == true ||
      cinematics?.call()?.busy == true ||
      presentations?.call()?.busy == true ||
      regionalMap?.call()?.busy == true ||
      events?.call()?.busy == true ||
      scenes?.call()?.busy == true ||
      resources()?.busy == true ||
      narrative()?.busy == true ||
      world?.call()?.saving == true;

  Future<bool> allowClose() => _allowClose();

  bool get hasPendingChanges => controller.dirty || hasCatalogDependencyDraft;

  bool get hasCatalogDependencyDraft =>
      projectSurf?.call()?.dirty == true ||
      projectCs?.call()?.dirty == true ||
      projectAudio?.call()?.dirty == true ||
      projectIdentity?.call()?.dirty == true ||
      projectVisuals?.call()?.dirty == true ||
      resources()?.dirty == true ||
      narrative()?.dirty == true ||
      dialogues?.call()?.dirty == true ||
      cinematics?.call()?.dirty == true ||
      presentations?.call()?.dirty == true ||
      regionalMap?.call()?.dirty == true ||
      events?.call()?.dirty == true ||
      scenes?.call()?.dirty == true ||
      world?.call()?.hasRuleDraft == true ||
      worldInputsValid?.call() == false;

  Future<bool> saveForExport() => _saveOwnedChanges();

  String? get exportPreparationFailure {
    final failures = <String?>[
      controller.error,
      projectSurf?.call()?.error,
      projectCs?.call()?.error,
      projectAudio?.call()?.error,
      resources()?.error,
      narrative()?.publicationError,
      narrative()?.error,
      scenes?.call()?.error,
      events?.call()?.error,
      dialogues?.call()?.error,
      cinematics?.call()?.error,
      presentations?.call()?.error,
      regionalMap?.call()?.error,
      world?.call()?.error,
    ];
    for (final failure in failures) {
      if (failure != null && failure.isNotEmpty) return failure;
    }
    return null;
  }

  Future<bool> flushEditors() async =>
      _flushDialogueEdit() &&
      _validateRegionalInputs() &&
      await _flushEventEdits() &&
      _validateWorldInputs();

  bool _validateRegionalInputs() {
    final owner = regionalMap?.call();
    if (owner == null || !owner.dirty) return true;
    final problem = owner.validate(
      maps: {
        ...?owner.source?.maps,
        for (final document in controller.documents.values)
          document.current.id: document.current,
      },
      checkMapDrafts: false,
    );
    if (problem == null) return true;
    owner.error = problem;
    changed();
    return false;
  }

  TestLaunchPreflight? _preflight(bool fullProject) {
    final document = controller.active;
    if (document == null) return null;
    final entry = controller.project?.maps
        .where((map) => map.id == document.base.mapId)
        .firstOrNull;
    final name = entry?.name ?? document.current.name;
    return TestLaunchPreflight(
      scope: fullProject ? TestLaunchScope.game : TestLaunchScope.map,
      mapName: name,
      saves: [
        if (document.dirty) 'Carte « $name »',
        if (document.atmosphere?.dirty == true) 'Ambiance de la carte',
        if (scenes?.call()?.dirty == true) 'Scènes',
        if (narrative()?.dirty == true) 'Interactions de la carte',
      ],
      blockers: [
        if (regionalMap?.call()?.dirty == true)
          const TestLaunchBlocker('Carte régionale', 'Carte régionale'),
        if (presentations?.call()?.dirty == true)
          const TestLaunchBlocker('Présentations', 'Histoire › Présentations'),
        if (cinematics?.call()?.dirty == true)
          const TestLaunchBlocker('Cinématiques', 'Histoire › Cinématiques'),
        if (dialogues?.call()?.dirty == true)
          const TestLaunchBlocker('Dialogues', 'Histoire › Dialogues'),
        if (events?.call()?.dirty == true)
          const TestLaunchBlocker('Événements', 'Histoire › Événements'),
      ],
    );
  }

  Future<void> test({bool fullProject = false}) async {
    if (fullProject && launchGame == null) {
      controller.error = 'Le test du jeu complet est indisponible.';
      changed();
      return;
    }
    if (confirmLaunch case final confirm? when !busy && !controller.loading) {
      if (_preflight(fullProject) case final preflight?) {
        final accepted = await confirm(preflight);
        if (!isActive() || controller.isDisposed) return;
        if (preflight.canLaunch && !accepted) return;
      }
    }
    if (regionalMap?.call()?.dirty == true) {
      regionalMap!.call()!.error =
          'Enregistrez la carte régionale avant de tester le jeu.';
      changed();
      return;
    }
    if (presentations?.call()?.flushEdits?.call() == false) return;
    if (presentations?.call()?.dirty == true) {
      presentations!.call()!.error =
          'Enregistrez les présentations avant de tester le jeu.';
      changed();
      return;
    }
    if (cinematics?.call()?.dirty == true) {
      cinematics!.call()!.error =
          'Enregistrez les cinématiques avant de tester le jeu.';
      changed();
      return;
    }
    if (!_flushDialogueEdit()) return;
    if (dialogues?.call()?.dirty == true) {
      dialogues!.call()!.error =
          'Enregistrez les dialogues avant de tester le jeu.';
      changed();
      return;
    }
    if (!await _flushEventEdits()) return;
    if (events?.call()?.dirty == true) {
      events!.call()!.error = 'Enregistrez les événements avant de tester.';
      changed();
      return;
    }
    if (publishedCinematicContext?.call() == true) {
      final owner = cinematics?.call();
      final mapId = owner?.active?.asset.mapId;
      if (mapId == null || controller.active?.current.id != mapId) {
        owner?.error = 'Rejoignez la carte de la cinématique avec Voir sur la carte avant de lancer sa version publiée.';
        changed();
        return;
      }
      if (controller.dirty ||
          scenes?.call()?.dirty == true ||
          narrative()?.dirty == true) {
        owner?.error = 'Des cartes, scènes ou interactions ont un brouillon. Enregistrez-les dans leur éditeur avant ce test ; aucun brouillon n’a été publié.';
        changed();
        return;
      }
    }
    final document = controller.active;
    if (document == null || busy || controller.loading) return;
    final entry = controller.project!.maps.firstWhere(
      (e) => e.id == document.base.mapId,
    );
    testing = true;
    changed();
    try {
      final sceneController = scenes?.call();
      if (sceneController?.dirty == true && !await sceneController!.saveAll()) {
        return;
      }
      if (!await (document.atmosphere?.save() ?? Future.value(true))) return;
      if (!await (narrative()?.save(document: document) ??
              controller.save(document)) ||
          !isActive()) {
        return;
      }
      if (!identical(controller.active, document) || controller.loading) return;
      if (document.dirty) {
        document.error =
            'La carte a encore changé. Enregistrez-la avant de tester.';
        return;
      }
      if (sceneController?.dirty == true) {
        const message =
            'Une scène a encore changé. Enregistrez-la avant de tester.';
        sceneController!.error = message;
        sceneController.active?.error = message;
        return;
      }
      final narrativeController = narrative();
      if (events?.call()?.dirty == true) {
        events!.call()!.error = 'Les événements ont changé pendant la préparation. Enregistrez-les avant de tester.';
        return;
      }
      if (narrativeController != null &&
          (narrativeController.pendingStories.isNotEmpty ||
              narrativeController.pendingStoryDeletions.isNotEmpty ||
              narrativeController.pendingFacts.isNotEmpty)) {
        narrativeController.publicationError = 'Les histoires ou états ont encore changé. Enregistrez-les avant de tester.';
        return;
      }
      if (cinematics?.call()?.dirty == true) {
        cinematics!.call()!.error = 'La cinématique a changé pendant la préparation. Enregistrez-la avant de tester.';
        return;
      }
      if (presentations?.call()?.dirty == true) {
        presentations!.call()!.error =
            'La présentation a changé pendant la préparation.';
        return;
      }
      if (fullProject) {
        await launchGame!();
      } else {
        await launchMap(entry, document.base.revision);
      }
    } finally {
      testing = false;
      changed();
    }
  }

  Future<bool> _flushEventEdits() async {
    final owner = events?.call();
    try {
      await owner?.flushEdits?.call();
      return isActive() &&
          !controller.isDisposed &&
          identical(owner, events?.call());
    } catch (failure) {
      if (isActive() && !controller.isDisposed) {
        final message =
            'L’édition d’événement en cours ne peut pas être validée : $failure';
        owner?.error = message;
        controller.error = message;
        changed();
      }
      return false;
    }
  }

  bool _flushDialogueEdit({bool allowInvalidCinematic = false}) {
    if (presentations?.call()?.flushEdits?.call() == false) return false;
    final owner = dialogues?.call(), previous = dialogues?.call()?.error;
    final cinema = cinematics?.call(),
        previousCinema = cinematics?.call()?.error;
    cinema?.transport.pause();
    final cinematicFlushed = cinema?.flushEdits?.call() != false;
    final canDiscardCinematic =
        !cinematicFlushed && allowInvalidCinematic && cinema?.dirty == true;
    if (!cinematicFlushed && !canDiscardCinematic) {
      return false;
    }
    flushFocus();
    return (owner?.error == null || owner?.error == previous) &&
        (canDiscardCinematic ||
            cinema?.error == null ||
            cinema?.error == previousCinema);
  }
}
