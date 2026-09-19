import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'map_workspace_providers.dart';

final narrativePortProvider = Provider.autoDispose
    .family<NarrativePort, ProjectSession>(
      (ref, session) => throw StateError('Narrative port must be configured'),
    );

final sessionRuntimeBuilderProvider = Provider.autoDispose
    .family<StudioRuntimeBuilder, ProjectSession>(
      (ref, session) => ref.watch(workspaceRuntimeBuilderProvider)(
        session,
        ref.watch(mapWorkspacePortProvider(session)),
      ),
    );
