import 'package:flutter/material.dart';

import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_path_field.dart';
import 'package:avelune_studio/presentation/shell/studio_shell.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_panel.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_session/application/project_session_state.dart';
import 'package:avelune_studio/presentation/features/project_session/project_open_message.dart';

class ProjectSessionScreen extends StatefulWidget {
  const ProjectSessionScreen({
    super.key,
    required this.session,
    required this.chooseDirectory,
    this.workspaceBuilder,
  });
  final ProjectSessionController session;
  final Future<String?> Function() chooseDirectory;
  final Widget Function(ProjectSession, Future<void> Function())?
  workspaceBuilder;

  @override
  State<ProjectSessionScreen> createState() => _ProjectSessionScreenState();
}

class _ProjectSessionScreenState extends State<ProjectSessionScreen> {
  final _path = TextEditingController();
  var _pickerGeneration = 0;
  var _picking = false;
  String? _pickerError;

  @override
  void initState() {
    super.initState();
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
    }
  }

  void _sessionChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _open({bool browse = false}) async {
    if (_picking ||
        widget.session.state.status == ProjectSessionStatus.opening) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _pickerError = null);
    var directory = _path.text;
    if (browse || directory.isEmpty) {
      final generation = ++_pickerGeneration;
      setState(() => _picking = true);
      try {
        final selected = await widget.chooseDirectory();
        if (!mounted || generation != _pickerGeneration || selected == null) {
          return;
        }
        directory = selected;
        _path.text = selected;
      } catch (_) {
        if (mounted && generation == _pickerGeneration) {
          setState(
            () => _pickerError =
                'Le sélecteur de dossier est indisponible. Saisissez le chemin puis réessayez.',
          );
        }
        return;
      } finally {
        if (mounted && generation == _pickerGeneration) {
          setState(() => _picking = false);
        }
      }
    }
    if (mounted && !widget.session.disposed) {
      await widget.session.open(directory);
    }
  }

  Future<void> _close() async {
    _pickerGeneration++;
    setState(() {
      _picking = false;
      _pickerError = null;
    });
    await widget.session.close();
  }

  @override
  void dispose() {
    _pickerGeneration++;
    widget.session.removeListener(_sessionChanged);
    _path.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.session.state;
    final project = state.project;
    final busy = _picking || state.status == ProjectSessionStatus.opening;
    if (project != null && widget.workspaceBuilder != null) {
      return widget.workspaceBuilder!(project, _close);
    }
    return StudioShell(
      child: StudioPanel(
        children: [
          if (project != null) ...[
            const StudioNotice('Projet ouvert — lecture seule'),
            const SizedBox(height: 20),
            SelectionArea(
              child: Text(
                project.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Emplacement'),
            const SizedBox(height: 8),
            SelectionArea(child: Text(project.directoryPath)),
            const SizedBox(height: 24),
            StudioButton(
              label: 'Fermer le projet',
              onPressed: _close,
              secondary: true,
            ),
          ] else ...[
            Text(
              'Ouvrez votre projet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Sélectionnez le dossier qui contient le fichier project.json.',
            ),
            const SizedBox(height: 24),
            if (!busy) StudioPathField(controller: _path, onSubmitted: _open),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                StudioButton(
                  label: 'Ouvrir un projet',
                  onPressed: busy ? null : _open,
                ),
                StudioButton(
                  label: 'Parcourir',
                  onPressed: busy ? null : () => _open(browse: true),
                  secondary: true,
                ),
              ],
            ),
            if (busy) ...[
              const SizedBox(height: 20),
              StudioNotice(
                _picking
                    ? 'Choisissez un dossier dans la fenêtre de sélection…'
                    : 'Lecture du projet…',
              ),
              if (state.requestedPath != null) Text(state.requestedPath!),
              const SizedBox(height: 12),
              StudioButton(
                label: 'Annuler l’ouverture',
                onPressed: _close,
                secondary: true,
              ),
            ],
            if (state.status == ProjectSessionStatus.failed) ...[
              const SizedBox(height: 20),
              StudioNotice(projectOpenMessage(state.problem), isError: true),
            ],
            if (_pickerError != null) ...[
              const SizedBox(height: 20),
              StudioNotice(_pickerError!, isError: true),
            ],
          ],
        ],
      ),
    );
  }
}
