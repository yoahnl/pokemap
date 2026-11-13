import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avelune_studio/app/di/project_session_providers.dart';
import 'package:avelune_studio/app/di/studio_lifecycle_providers.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_open_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_state.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/home/project_import_page.dart';
import 'package:avelune_studio/presentation/features/home/project_loading_screen.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_page.dart';

class StudioRoot extends ConsumerStatefulWidget {
  const StudioRoot({super.key});

  @override
  ConsumerState<StudioRoot> createState() => _StudioRootState();
}

class _StudioRootState extends ConsumerState<StudioRoot> {
  late final ProjectSessionController _session = ref.read(
    projectSessionControllerProvider,
  );
  late final _opening = ProjectSessionOpenController(
    session: _session,
    chooseDirectory: () => ref.read(projectDirectoryPickerProvider)(),
    allowSwitch: ref.read(studioLifecycleControllerProvider).confirmLeave,
  );

  @override
  void initState() {
    super.initState();
    _session.addListener(_changed);
    _opening.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _session.removeListener(_changed);
    _opening.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _session.state;
    final project = state.project;
    final progress = state.progress;
    final ready = state.status == ProjectSessionStatus.ready && project != null;
    if (ready && progress == null) return _builder(project);
    if (!ready && state.status != ProjectSessionStatus.opening ||
        progress == null) {
      return ProjectImportPage(
        state: state,
        busy: _opening.picking,
        pickerError: _opening.error,
        onImport: () => unawaited(_opening.open(browse: true)),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        if (ready) _builder(project),
        ProjectLoadingScreen(
          key: ObjectKey(progress),
          progress: progress,
          subtitle: ready ? project.name : state.requestedPath ?? '',
        ),
      ],
    );
  }

  Widget _builder(ProjectSession project) => MapBuilderPage(
    key: ValueKey(project.sessionId),
    session: project,
    onHome: _opening.close,
    progress: _session.state.progress,
  );
}
