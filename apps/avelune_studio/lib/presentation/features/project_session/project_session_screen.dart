import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring_project_creation.dart';

import '../../../features/home/application/recent_projects_controller.dart';
import '../../../features/home/domain/recent_studio_project.dart';
import '../../../features/project_session/application/project_session_controller.dart';
import '../../../features/project_session/application/project_session_state.dart';
import '../../../features/project_session/domain/project_session.dart';
import '../../../features/project_session/domain/project_history_maintenance.dart';
import '../../shell/studio_home_navigation.dart';
import '../home/studio_home_screen.dart';
import 'project_open_controls.dart';
import '../project_creation/project_creation_dialog.dart';
import '../../shared/widgets/dialogs/studio_review_dialog.dart';

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
    this.historyMaintenance,
    this.onMaintenanceBusy,
  });
  final ProjectSessionController session;
  final RecentProjectsPort recentProjects;
  final Future<String?> Function() chooseDirectory;
  final ProjectCreationPort? creationPort;
  final Future<String?> Function()? chooseCreationParent;
  final Future<void> Function()? releaseCreationParent;
  final ValueChanged<bool>? onCreatorVisibility;
  final ProjectHistoryMaintenancePort? historyMaintenance;
  final ValueChanged<bool>? onMaintenanceBusy;
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
  var _maintainingHistory = false;
  var _applyingHistory = false;
  String? _historyMaintenanceMessage;
  var _historyMaintenanceFailed = false;
  String? _pickerError;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _sessionId = widget.session.state.project?.sessionId;
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
      _sessionId = widget.session.state.project?.sessionId;
      _pickerGeneration++;
      _picking = false;
      _home.reset();
      _historyMaintenanceMessage = null;
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
      _historyMaintenanceMessage = null;
      _historyMaintenanceFailed = false;
    }
    _refresh();
  }

  Future<void> _open({bool browse = false, String? destination}) async {
    if (_maintainingHistory ||
        _picking ||
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
          () => _pickerError = 'Le sélecteur de dossier est indisponible. Saisissez le chemin puis réessayez.',
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
    if (_creating || _picking || _maintainingHistory || port == null) return;
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
    if (_maintainingHistory) return;
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
    if (_maintainingHistory) return;
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

  Future<void> _maintainHistory() async {
    final port = widget.historyMaintenance;
    final project = widget.session.state.project;
    if (_maintainingHistory ||
        port == null ||
        project == null ||
        project.storage != ProjectSessionStorage.workingCatalog) {
      return;
    }
    if (_home.allowSwitch != null && !await _home.allowSwitch!()) return;
    if (!mounted ||
        widget.session.state.project?.sessionId != project.sessionId) {
      return;
    }
    setState(() {
      _maintainingHistory = true;
      _historyMaintenanceFailed = false;
      _historyMaintenanceMessage = 'Analyse de l’historique…';
    });
    widget.onMaintenanceBusy?.call(true);
    try {
      final preview = await port.preview(project);
      if (!mounted ||
          widget.session.state.project?.sessionId != project.sessionId) {
        return;
      }
      final approved = await showDialog<bool>(
        context: context,
        builder: (context) => StudioReviewDialog(
          title: 'Entretenir l’historique ?',
          content: Text(
            '${preview.retainedOperations} opérations resteront disponibles pour Annuler ou Rétablir, soit ${_historyMiB(preview.retainedBytes)} Mio de données d’historique.\n\n'
            '${preview.expiredOperations} entrées anciennes expireront. Leur annulation ne sera plus disponible. Le projet actuel et les données encore utilisées par d’autres sessions seront conservés.\n\n'
            '${preview.hasLegacyBarrier ? 'Cet historique contient d’anciennes annulations indépendantes. L’entretien conservera la suite d’opérations sûre indiquée ci-dessus ; les entrées précédentes expireront.\n\n' : ''}'
            '${preview.blocked ? 'Une opération dépasse à elle seule le budget de l’historique. Cet entretien ne peut pas être appliqué.' : 'L’entretien supprimera les données devenues inutiles. Cette suppression ne peut pas être annulée.'}',
          ),
          confirmLabel: 'Appliquer l’entretien',
          onConfirmed: preview.blocked
              ? null
              : () => Navigator.pop(context, true),
          onCancelled: () => Navigator.pop(context, false),
        ),
      );
      if (approved != true ||
          !mounted ||
          widget.session.state.project?.sessionId != project.sessionId) {
        if (mounted) setState(() => _historyMaintenanceMessage = null);
        return;
      }
      setState(() {
        _applyingHistory = true;
        _historyMaintenanceMessage = 'Suppression des données expirées…';
      });
      final result = await port.apply(project, preview);
      if (mounted &&
          widget.session.state.project?.sessionId == project.sessionId) {
        setState(
          () => _historyMaintenanceMessage =
              'Entretien terminé : ${result.deletedObjects} fichiers supprimés (${_historyMiB(result.deletedBytes)} Mio de contenu). Les données utilisées par d’autres sessions sont conservées.',
        );
      }
    } catch (failure) {
      if (mounted &&
          widget.session.state.project?.sessionId == project.sessionId) {
        setState(() {
          _historyMaintenanceFailed = true;
          _historyMaintenanceMessage =
              failure is ProjectHistoryMaintenanceFailure ? failure.message : 'L’entretien n’a pas pu aboutir. Les données du projet restent conservées ; relancez l’analyse.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _maintainingHistory = false;
          _applyingHistory = false;
        });
      }
      widget.onMaintenanceBusy?.call(false);
    }
  }

  String _historyMiB(int bytes) =>
      (bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',');

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
        _creating ||
        _maintainingHistory ||
        _picking ||
        _home.optimizingLibrary ||
        state.status == ProjectSessionStatus.opening;
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
                  onOptimizeLibrary: _home.onOptimizeLibrary,
                  optimizingLibrary: _home.optimizingLibrary,
                  libraryOptimizationError: _home.libraryOptimizationError,
                  onMaintainHistory:
                      project?.storage ==
                              ProjectSessionStorage.workingCatalog &&
                          widget.historyMaintenance != null
                      ? _maintainHistory
                      : null,
                  historyMaintenanceLabel: _maintainingHistory
                      ? _applyingHistory
                            ? 'Entretien de l’historique…'
                            : 'Analyse de l’historique…'
                      : 'Entretenir l’historique',
                  historyMaintenanceMessage: _historyMaintenanceMessage,
                  historyMaintenanceFailed: _historyMaintenanceFailed,
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
