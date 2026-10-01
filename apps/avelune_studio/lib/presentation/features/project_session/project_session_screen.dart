import 'dart:async';
import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring_project_creation.dart';
import '../../../features/home/application/recent_projects_controller.dart';
import '../../../features/home/domain/recent_studio_project.dart';
import '../../../features/project_session/application/project_session_controller.dart';
import '../../../features/project_session/application/project_session_state.dart';
import '../../../features/project_session/domain/project_session.dart';
import '../../shell/studio_home_navigation.dart';
import '../home/studio_home_screen.dart';
import 'project_open_controls.dart';
import '../project_creation/project_creation_dialog.dart';

class ProjectSessionScreen extends StatefulWidget {
  const ProjectSessionScreen({
    super.key,
    required this.session,
    required this.chooseDirectory,
    required this.recentProjects,
    this.workspaceBuilder,
    this.creationPort,
    this.chooseCreationParent,
    this.releaseCreationParent,
    this.onCreatorVisibility,
  });
  final ProjectSessionController session;
  final RecentProjectsPort recentProjects;
  final Future<String?> Function() chooseDirectory;
  final ProjectCreationPort? creationPort;
  final Future<String?> Function()? chooseCreationParent;
  final Future<void> Function()? releaseCreationParent;
  final ValueChanged<bool>? onCreatorVisibility;
  final Widget Function(ProjectSession, Future<void> Function())?
  workspaceBuilder;
  @override
  State<ProjectSessionScreen> createState() => _ProjectSessionScreenState();
}

class _ProjectSessionScreenState extends State<ProjectSessionScreen> {
  final _path = TextEditingController();
  final _home = StudioHomeNavigation();
  late final RecentProjectsController _recents;
  var _pickerGeneration = 0;
  var _picking = false;
  var _creating = false;
  String? _pickerError;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _recents = RecentProjectsController(widget.recentProjects)
      ..addListener(_refresh);
    unawaited(_recents.load());
    _home.addListener(_refresh);
    widget.session.addListener(_sessionChanged);
  }

  @override
  void didUpdateWidget(ProjectSessionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      oldWidget.session.removeListener(_sessionChanged);
      widget.session.addListener(_sessionChanged);
      _pickerGeneration++;
      _picking = false;
      _home.reset();
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _sessionChanged() {
    final project = widget.session.state.project;
    if (project?.sessionId != _sessionId) {
      _sessionId = project?.sessionId;
      _home.reset();
    }
    _refresh();
  }

  Future<void> _open({bool browse = false, String? destination}) async {
    if (_picking ||
        widget.session.state.status == ProjectSessionStatus.opening) {
      return;
    }
    FocusScope.of(context).unfocus();
    final generation = ++_pickerGeneration;
    setState(() {
      _pickerError = null;
      _picking = true;
    });
    var directory = _path.text;
    try {
      if (browse || directory.isEmpty) {
        final selected = await widget.chooseDirectory();
        if (!mounted || generation != _pickerGeneration || selected == null) {
          return;
        }
        directory = selected;
        _path.text = selected;
      }
      if (_home.allowSwitch != null && !await _home.allowSwitch!()) return;
      if (!mounted || generation != _pickerGeneration) return;
      final previous = widget.session.state.project;
      await widget.session.open(directory);
      if (!mounted || generation != _pickerGeneration) return;
      final project = widget.session.state.project;
      if (project != null && !identical(project, previous)) {
        unawaited(_recents.remember(project));
        if (widget.workspaceBuilder != null) {
          if (destination == null) {
            _home.resume();
          } else {
            _home.navigate(destination);
          }
        }
      }
    } catch (_) {
      if (mounted && generation == _pickerGeneration) {
        setState(
          () => _pickerError =
              'Le sélecteur de dossier est indisponible. Saisissez le chemin puis réessayez.',
        );
      }
    } finally {
      if (mounted && generation == _pickerGeneration) {
        setState(() => _picking = false);
      }
    }
  }

  Future<void> _createProject() async {
    final port = widget.creationPort;
    if (_creating || _picking || port == null) return;
    final owner = widget.session;
    final ownerProject = owner.state.project?.sessionId;
    setState(() => _creating = true);
    widget.onCreatorVisibility?.call(true);
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ProjectCreationDialog(
          port: port,
          chooseParent: widget.chooseCreationParent ?? widget.chooseDirectory,
          openCreated: (receipt) async {
            if (!mounted ||
                widget.session != owner ||
                owner.state.project?.sessionId != ownerProject) {
              return false;
            }
            _path.text = receipt.projectPath;
            await _open(
              destination: receipt.manifest.maps.isEmpty ? null : 'map',
            );
            return mounted &&
                widget.session == owner &&
                widget.session.state.project?.directoryPath ==
                    receipt.projectPath;
          },
        ),
      );
    } finally {
      try {
        await widget.releaseCreationParent?.call();
      } finally {
        widget.onCreatorVisibility?.call(false);
        if (mounted) setState(() => _creating = false);
      }
    }
  }

  void _destination(String destination) {
    if (widget.session.state.project == null) {
      unawaited(_open(browse: true, destination: destination));
    } else {
      _home.navigate(destination);
    }
  }

  void _cancel() {
    _pickerGeneration++;
    _picking = false;
    widget.session.cancelOpening();
    _refresh();
  }

  Future<void> _close() async {
    _pickerGeneration++;
    _picking = false;
    _pickerError = null;
    _home.showHome();
    await widget.session.close();
  }

  Future<void> _closeFromHome() async {
    if (_home.allowSwitch != null && !await _home.allowSwitch!()) return;
    if (mounted) await _close();
  }

  @override
  void dispose() {
    _pickerGeneration++;
    widget.session.removeListener(_sessionChanged);
    _home.dispose();
    _recents.dispose();
    _path.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.session.state;
    final project = state.project;
    final busy =
        _creating || _picking || state.status == ProjectSessionStatus.opening;
    final homeVisible =
        _home.visible || project == null || widget.workspaceBuilder == null;
    return StudioHomeScope(
      navigation: _home,
      child: Stack(
        children: [
          if (project != null && widget.workspaceBuilder != null)
            Positioned.fill(
              child: Offstage(
                offstage: homeVisible,
                child: TickerMode(
                  enabled: !homeVisible,
                  child: ExcludeFocus(
                    excluding: homeVisible,
                    child: KeyedSubtree(
                      key: ValueKey(project.sessionId),
                      child: widget.workspaceBuilder!(project, _close),
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: Offstage(
              offstage: !homeVisible,
              child: ExcludeFocus(
                excluding: !homeVisible,
                child: StudioHomeScreen(
                  searchController: _home.search,
                  searchFocusNode: _home.searchFocus,
                  projectName: project?.name,
                  projectPath: project?.directoryPath,
                  busy: busy,
                  onCreate: widget.creationPort == null ? null : _createProject,
                  canTest: _home.canTest,
                  onOpen: () => _open(browse: true),
                  onResume: project == null ? null : _home.resume,
                  onExport: project == null || busy
                      ? null
                      : () => _home.navigate('gameExport'),
                  onClose: project == null ? null : _closeFromHome,
                  onDestination: _destination,
                  recentProjects: _recents.entries,
                  onRecent: (entry) {
                    _path.text = entry.directoryPath;
                    unawaited(_open());
                  },
                  onRemoveRecent: (entry) =>
                      _recents.remove(entry.directoryPath),
                  maps: _home.maps,
                  mapLibrary: _home.mapLibrary,
                  mapPreviewBuilder: homeVisible
                      ? _home.mapPreviewBuilder
                      : null,
                  onMap: (id) => _home.navigate('map', id),
                  onCreateMap: project == null || busy
                      ? null
                      : () => _home.navigate('createMap'),
                  statusAtTop:
                      busy || state.problem != null || _pickerError != null,
                  status: ProjectOpenControls(
                    path: _path,
                    state: state,
                    picking: _picking,
                    error: _pickerError ?? _recents.error,
                    onOpen: _open,
                    onBrowse: () => _open(browse: true),
                    onCancel: _cancel,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
