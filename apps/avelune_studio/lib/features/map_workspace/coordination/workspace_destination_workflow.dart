import 'dart:async';

import '../../game_export/domain/studio_game_export_port.dart';
import '../application/map_workspace_controller.dart';
import '../domain/map_workspace_workshop.dart';
import '../domain/workspace_navigation.dart';
import 'workspace_navigation_session.dart';
import 'workspace_session_controllers.dart';
import 'workspace_workshop_routes.dart';

class WorkspaceDestinationWorkflow {
  WorkspaceDestinationWorkflow({
    required this.controller,
    required this.navigation,
    required this.sessions,
    required this.workshops,
    required this.isActive,
    required this.changed,
    required this.leavePokemon,
    required this.flushFocus,
    required this.closeContext,
    this.exporter,
    this.libraryExitGuard,
    this.libraryReleased,
    this.customResourceLibrary,
    this.clearNotice,
    this.returnFromProgression,
  });

  final MapWorkspaceController controller;
  final WorkspaceNavigationSession navigation;
  final WorkspaceSessionControllers sessions;
  final WorkspaceWorkshopRoutes workshops;
  final bool Function() isActive;
  final void Function() changed, flushFocus, closeContext;
  final Future<bool> Function() leavePokemon;
  final StudioGameExportPort? Function()? exporter;
  final Future<bool> Function()? Function()? libraryExitGuard;
  final void Function()? libraryReleased, clearNotice;
  final bool Function()? customResourceLibrary;
  final void Function(String?)? returnFromProgression;
  bool cinematicMapReturn = false, pokemonMapReturn = false;
  bool _disposed = false;

  bool get active => !_disposed && isActive() && !controller.isDisposed;

  void show(
    WorkspaceSpace destination, {
    bool libraryGuarded = false,
    bool keepCombatAnalysis = false,
  }) {
    if (!active) return;
    final previous = navigation.space;
    if (previous == WorkspaceSpace.resources &&
        destination != previous &&
        libraryExitGuard?.call() != null &&
        !libraryGuarded) {
      unawaited(_leaveLibrary(destination));
      return;
    }
    if (previous == WorkspaceSpace.pokemon &&
        destination != previous &&
        (sessions.pokemon?.hasPendingChanges == true ||
            sessions.pokemon?.mutationActive == true)) {
      unawaited(_leavePokemon(destination));
      return;
    }
    if (previous == WorkspaceSpace.gameExport &&
        destination != previous &&
        exporter?.call()?.operationActive == true) {
      return;
    }
    final workshop = switch (destination) {
      WorkspaceSpace.map ||
      WorkspaceSpace.interaction ||
      WorkspaceSpace.projectSettings => null,
      WorkspaceSpace.resources
          when customResourceLibrary?.call() == true &&
              !controller.hasWorkshop(MapWorkspaceWorkshop.resources) => null,
      _ => MapWorkspaceWorkshop.values.byName(destination.name),
    };
    if (workshop != null && !controller.hasWorkshop(workshop)) {
      unawaited(workshops.open(
        workshop,
        opened: () => show(destination, libraryGuarded: true),
      ));
      return;
    }
    if (previous == WorkspaceSpace.presentation) {
      if (destination != previous) {
        sessions.presentations?.suspendPreview?.call();
      }
      if (sessions.presentations?.flushEdits?.call() == false) return;
    }
    if (previous == WorkspaceSpace.cinematic) {
      sessions.cinematics?.transport.pause();
      flushFocus();
    }
    if (destination != WorkspaceSpace.map) {
      cinematicMapReturn = false;
      navigation.eventMapReturn = false;
      navigation.verificationMapReturn = false;
      pokemonMapReturn = false;
    }
    if (previous == WorkspaceSpace.dialogue ||
        previous == WorkspaceSpace.events ||
        previous == WorkspaceSpace.progression) {
      flushFocus();
    }
    if (previous == WorkspaceSpace.progression &&
        destination == WorkspaceSpace.story) {
      returnFromProgression?.call(sessions.stories?.activeId);
    }
    closeContext();
    workshops.request++;
    workshops.loading = false;
    clearNotice?.call();
    sessions.narrative?.cancelOpening();
    final refreshCommerce = destination == WorkspaceSpace.pokemon &&
        previous != WorkspaceSpace.pokemon &&
        sessions.pokemon?.commerce?.snapshot != null;
    final refreshCombat = destination == WorkspaceSpace.pokemon &&
        previous != WorkspaceSpace.pokemon &&
        sessions.pokemon?.combat?.snapshot != null &&
        !(keepCombatAnalysis &&
            sessions.pokemon?.combat?.snapshot?.referencesComplete == true);
    navigation.space = destination;
    changed();
    if (destination == WorkspaceSpace.regionalMap) {
      unawaited(sessions.regionalMap?.load());
    }
    if (refreshCommerce) {
      unawaited(sessions.pokemon!.commerce!.load(refresh: true));
    }
    if (refreshCombat) {
      unawaited(sessions.pokemon!.combat!.load(refresh: true));
    }
  }

  Future<void> _leaveLibrary(WorkspaceSpace destination) async {
    final guard = libraryExitGuard?.call();
    if (guard == null) return;
    if (await guard() && active && identical(guard, libraryExitGuard?.call())) {
      libraryReleased?.call();
      show(destination, libraryGuarded: true);
    }
  }

  Future<void> _leavePokemon(WorkspaceSpace destination) async {
    if (await leavePokemon() && active) show(destination);
  }

  void dispose() {
    _disposed = true;
  }
}
