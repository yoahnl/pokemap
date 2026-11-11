import 'package:flutter/material.dart';

import '../../../features/project_settings/application/project_settings_drafts.dart';
import '../../../features/project_settings/application/project_settings_recovery.dart';

export '../../../features/project_settings/application/project_settings_recovery.dart'
    show ProjectSettingsRecoveryTarget, projectSettingsRecoveryTargets;
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_empty_state.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class ProjectSettingsRecoveryPane extends StatefulWidget {
  const ProjectSettingsRecoveryPane({
    super.key,
    required this.changes,
    required this.targets,
    required this.onBack,
    required this.backLabel,
  });

  final Listenable changes;
  final List<ProjectSettingsRecoveryTarget> Function() targets;
  final VoidCallback onBack;
  final String backLabel;

  @override
  State<ProjectSettingsRecoveryPane> createState() =>
      _ProjectSettingsRecoveryPaneState();
}

class _ProjectSettingsRecoveryPaneState
    extends State<ProjectSettingsRecoveryPane> {
  int _revision = 0;
  String? _notice;

  @override
  void initState() {
    super.initState();
    widget.changes.addListener(_changed);
  }

  @override
  void didUpdateWidget(ProjectSettingsRecoveryPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.changes, widget.changes)) {
      oldWidget.changes.removeListener(_changed);
      widget.changes.addListener(_changed);
      _revision++;
    }
  }

  void _changed() {
    if (!mounted) return;
    setState(() => _revision++);
  }

  bool _pending(ProjectSettingsRecoveryTarget target) =>
      projectSettingsRecoveryPending(target);

  bool _available(ProjectSettingsRecoveryTarget target) =>
      projectSettingsRecoveryAvailable(target);

  Future<void> _recover(ProjectSettingsRecoveryTarget target) async {
    final revision = _revision;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandonner le brouillon de cette rubrique ?'),
        content: SingleChildScrollView(
          child: Text(
            'Rubrique : ${target.label}.\n\n${target.consequence}\n\n'
            'Ses saisies invalides et son historique local seront abandonnés. '
            'Les autres rubriques et cartes seront conservées. Aucun fichier ne sera écrit.',
          ),
        ),
        actions: [
          StudioButton(
            label: 'Conserver le brouillon',
            secondary: true,
            onPressed: () => Navigator.pop(context, false),
          ),
          StudioButton(
            label: 'Abandonner cette rubrique',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final current = projectSettingsRecoveryConfirmed(
      widget.targets(),
      target.id,
      changed: _revision != revision,
    );
    if (current == null) {
      setState(() {
        _notice = projectSettingsRecoveryChanged;
      });
      return;
    }
    current.recover();
    if (!mounted) return;
    setState(() {
      _notice = projectSettingsRecoveryOutcome(current);
    });
  }

  @override
  Widget build(BuildContext context) {
    final targets = widget.targets().where(_pending).toList();
    return StudioEmptyState(
      title: 'Réglages du projet indisponibles',
      description: 'Les réglages sont temporairement indisponibles. Vos configurations enregistrées et vos brouillons en cours sont conservés. Vous pouvez abandonner explicitement une rubrique ci-dessous pour débloquer la fermeture ou l’export.',
      icon: Icons.settings_outlined,
      action: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_notice case final notice?) ...[
              StudioNotice(notice),
              const SizedBox(height: 12),
            ],
            for (final target in targets) ...[
              StudioPanel(
                title: target.label,
                children: [
                  if (target.draft.error case final error?)
                    StudioNotice(error, isError: true),
                  if (target.draft.blocked)
                    const Text(
                      'Cette rubrique contient une saisie invalide ou un conflit.',
                    ),
                  if (target.draft is VisualSettingsDraft &&
                      !target.draft.dirty &&
                      !target.draft.blocked)
                    const Text(
                      'Aucun brouillon de cette rubrique ne peut être abandonné. Le conflit du document doit être résolu par son propriétaire.',
                    ),
                  StudioButton(
                    key: ValueKey('settings-recover-${target.id}'),
                    label: 'Abandonner ce brouillon',
                    secondary: true,
                    onPressed: _available(target)
                        ? () => _recover(target)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            StudioButton(
              key: const ValueKey('project-settings-return'),
              label: widget.backLabel,
              secondary: true,
              onPressed: widget.onBack,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.changes.removeListener(_changed);
    super.dispose();
  }
}
