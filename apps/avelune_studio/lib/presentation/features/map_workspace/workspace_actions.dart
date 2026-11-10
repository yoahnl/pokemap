import 'package:flutter/material.dart';

import '../../../features/map_workspace/coordination/workspace_workflow.dart';
import '../../../platform/playtest/studio_playtest_builders.dart';
import '../../shared/widgets/dialogs/confirm_studio_close.dart';

export '../../../platform/playtest/studio_playtest_builders.dart'
    show StudioRuntimeBuilder;

class WorkspaceActions extends WorkspaceWorkflow {
  WorkspaceActions({
    required super.controller,
    required BuildContext Function() context,
    required bool Function() mounted,
    required super.changed,
    required super.resources,
    required super.narrative,
    super.scenes,
    super.events,
    super.dialogues,
    super.cinematics,
    super.presentations,
    super.regionalMap,
    super.world,
    super.projectVisuals,
    super.projectSurf,
    super.projectCs,
    super.projectAudio,
    super.projectIdentity,
    super.confirmLaunch,
    super.worldInputsValid,
    super.publishedCinematicContext,
    required StudioRuntimeBuilder runtimeBuilder,
    Widget Function(VoidCallback onClose)? projectRuntimeBuilder,
  }) : super(
         isActive: mounted,
         confirmClose: () async =>
             switch (await confirmStudioClose(context())) {
               'save' => WorkspaceCloseChoice.save,
               'discard' => WorkspaceCloseChoice.discard,
               'cancel' => WorkspaceCloseChoice.cancel,
               _ => null,
             },
         flushFocus: () {
           FocusManager.instance.primaryFocus?.unfocus();
           FocusManager.instance.applyFocusChangesIfNeeded();
         },
         launchMap: (entry, revision) async {
           await Navigator.of(context()).push<void>(
             MaterialPageRoute(
               builder: (routeContext) => runtimeBuilder(
                 entry,
                 revision,
                 () => Navigator.of(routeContext).pop(),
               ),
             ),
           );
         },
         launchGame: projectRuntimeBuilder == null
             ? null
             : () async {
                 await Navigator.of(context()).push<void>(
                   MaterialPageRoute(
                     builder: (routeContext) => projectRuntimeBuilder(
                       () => Navigator.of(routeContext).pop(),
                     ),
                   ),
                 );
               },
       );
}
