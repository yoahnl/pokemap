import 'package:flutter/material.dart';

import '../../../features/project_settings/application/project_settings_session_controller.dart';
import '../../../features/project_settings/application/project_verification_overview.dart';
import '../../../features/verification/application/studio_failure_diagnosis.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_badge.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'project_settings_navigator.dart';

class ProjectVerificationPanel extends StatelessWidget {
  const ProjectVerificationPanel({
    super.key,
    required this.rows,
    required this.onSelectSection,
    this.onOpenOwner,
    this.onOpenVerification,
    this.onOpenExport,
  });

  final List<ProjectCheckRow> rows;
  final ValueChanged<ProjectSettingsSection> onSelectSection;
  final ValueChanged<StudioFailureOwner>? onOpenOwner;
  final VoidCallback? onOpenVerification, onOpenExport;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StudioPanel(
        title: 'Points à examiner avant de tester ou d’exporter',
        icon: Icons.fact_check_outlined,
        children: [
          Text(
            'Chaque famille a son propriétaire. Une famille non contrôlée ici '
            'le dit, sans se déclarer vérifiée.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          for (final row in rows) _row(context, row),
        ],
      ),
      const SizedBox(height: 12),
      StudioPanel(
        title: 'Préparer',
        icon: Icons.ios_share,
        children: [
          const Text(
            'Les vérifications narratives et l’export restent des actions '
            'explicites : rien n’est préparé depuis cette page.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onOpenVerification case final open?)
                StudioButton(
                  label: 'Ouvrir les vérifications',
                  icon: Icons.fact_check_outlined,
                  secondary: true,
                  onPressed: open,
                ),
              if (onOpenExport case final open?)
                StudioButton(
                  label: 'Préparer l’export',
                  icon: Icons.ios_share,
                  secondary: true,
                  onPressed: open,
                ),
            ],
          ),
        ],
      ),
    ],
  );

  Widget _row(BuildContext context, ProjectCheckRow row) {
    final (label, tone) = switch (row.state) {
      ProjectCheckState.clear => ('Rien à corriger', StudioTone.success),
      ProjectCheckState.problem => ('À corriger', StudioTone.danger),
      ProjectCheckState.limited => ('À examiner', StudioTone.warning),
      ProjectCheckState.notChecked => ('Non vérifié ici', StudioTone.neutral),
    };
    final owner = row.owner;
    final open = onOpenOwner;
    return Padding(
      key: ValueKey('project-check-${row.family.name}'),
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                row.family.label,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              StudioBadge(label, tone: tone),
            ],
          ),
          const SizedBox(height: 4),
          Text(row.summary),
          if (row.sections.isNotEmpty ||
              (owner != null &&
                  open != null &&
                  row.state != ProjectCheckState.clear)) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final section in row.sections)
                  StudioButton(
                    key: ValueKey('project-check-open-${section.name}'),
                    label: 'Ouvrir ${section.label}',
                    icon: Icons.arrow_forward,
                    secondary: true,
                    onPressed: () => onSelectSection(section),
                  ),
                if (owner != null &&
                    open != null &&
                    row.state != ProjectCheckState.clear)
                  StudioButton(
                    key: ValueKey('project-check-owner-${row.family.name}'),
                    label: owner.action,
                    icon: Icons.arrow_forward,
                    secondary: true,
                    onPressed: () => open(owner),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
