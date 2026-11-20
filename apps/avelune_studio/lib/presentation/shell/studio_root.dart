import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avelune_studio/app/di/home_providers.dart';
import 'package:avelune_studio/app/di/project_session_providers.dart';
import 'package:avelune_studio/features/home/application/recent_projects_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_opening_progress.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_open_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_state.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/home/project_import_page.dart';
import 'package:avelune_studio/presentation/features/home/project_loading_screen.dart';
import 'package:avelune_studio/presentation/features/home/studio_home_screen.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_page.dart';

import 'studio_rail.dart';

class StudioRoot extends ConsumerStatefulWidget {
  const StudioRoot({super.key});

  @override
  ConsumerState<StudioRoot> createState() => _StudioRootState();
}

class _StudioRootState extends ConsumerState<StudioRoot> {
  late final ProjectSessionController _session = ref.read(
    projectSessionControllerProvider,
  );
  late final _recents = RecentProjectsController(
    ref.read(recentProjectsPortProvider),
  );
  late final _opening = ProjectSessionOpenController(
    session: _session,
    chooseDirectory: () => ref.read(projectDirectoryPickerProvider)(),
    recentProjects: _recents,
    allowSwitch: ref.read(studioExitGuardProvider).confirmLeave,
  );
  var _initialSection = StudioRailSection.map;

  void _browse([StudioRailSection section = StudioRailSection.map]) {
    if (_opening.picking) return;
    _initialSection = section;
    unawaited(_opening.open(browse: true));
  }

  void _openPath(String path) {
    if (_opening.picking) return;
    _initialSection = StudioRailSection.map;
    unawaited(_opening.open(directoryPath: path));
  }

  StudioHomeProjectAccess get _homeProjects => (
    recent: _recents.entries,
    open: _browse,
    openRecent: (project) => _openPath(project.directoryPath),
    removeRecent: (project) =>
        unawaited(_recents.remove(project.directoryPath)),
  );

  @override
  void initState() {
    super.initState();
    _session.addListener(_changed);
    _opening.addListener(_changed);
    _recents.addListener(_changed);
    unawaited(_recents.load());
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _session.removeListener(_changed);
    _opening.dispose();
    _recents.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _session.state;
    final project = state.project;
    final progress = state.progress;
    final ready = state.status == ProjectSessionStatus.ready;
    final status = projectHomeStatus(
      context,
      state: state,
      busy: _opening.picking,
      pickerFailed: _opening.error != null,
      recentsFailed: _recents.error != null,
      onRetry: switch (state.requestedPath) {
        final path? => () => _openPath(path),
        null => null,
      },
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        if (project != null)
          _builder(project, status, ready ? progress : null)
        else if (progress == null)
          _projectImporter(status),
        if (progress != null)
          ProjectLoadingScreen(
            key: ObjectKey(progress),
            progress: progress,
            subtitle: ready ? project?.name ?? '' : state.requestedPath ?? '',
          ),
      ],
    );
  }

  Widget _projectImporter(Widget? status) => ProjectImportPage(
    busy: _opening.picking,
    projects: _homeProjects,
    destinations: {
      'map': _browse,
      'resources': () => _browse(StudioRailSection.resources),
      'story': () => _browse(StudioRailSection.story),
      'pokemon': () => _browse(StudioRailSection.pokemon),
    },
    status: status,
  );

  Widget _builder(
    ProjectSession project,
    Widget? status,
    ProjectOpeningProgress? progress,
  ) => MapBuilderPage(
    key: ValueKey(project.sessionId),
    session: project,
    onHome: _opening.close,
    homeProjects: _homeProjects,
    homeBusy: _opening.picking,
    homeStatus: status,
    initialSection: _initialSection,
    progress: progress,
  );
}
