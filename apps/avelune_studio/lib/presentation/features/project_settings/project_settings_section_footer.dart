import 'dart:async';

import 'package:flutter/material.dart';

import '../../../features/project_settings/application/project_settings_session_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_badge.dart';
import '../../shared/widgets/feedback/studio_notice.dart';

class ProjectSettingsSectionFooter extends StatelessWidget {
  const ProjectSettingsSectionFooter({
    super.key,
    required this.session,
    required this.section,
    required this.scopeLabel,
  });

  final ProjectSettingsSessionController session;
  final ProjectSettingsSection section;
  final String scopeLabel;

  @override
  Widget build(BuildContext context) {
    final draft = session.draft(section);
    if (draft == null) return const SizedBox();
    final saving = session.isSaving(section);
    final dirty = session.isDirty(section);
    final error = session.errorOf(section);
    final lastSave = section.followsScope
        ? session.scopedVisuals?.lastSaveMicroseconds
        : null;
    final (status, tone) = saving
        ? ('Enregistrement…', StudioTone.info)
        : error != null
        ? ('Échec de l’enregistrement · brouillon conservé', StudioTone.danger)
        : dirty
        ? ('Brouillon non enregistré', StudioTone.warning)
        : draft.needsFirstSave
        ? ('Valeurs proposées, pas encore enregistrées', StudioTone.warning)
        : session.isConfirmed(section)
        ? ('Rubrique enregistrée', StudioTone.success)
        : ('Aucune modification de cette rubrique', StudioTone.neutral);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (error != null) ...[
              StudioNotice(error, isError: true, maxLines: 4),
              const SizedBox(height: 8),
            ],
            if (lastSave case final micros?) ...[
              Text(
                'Dernier enregistrement : '
                '${(micros / 1000).toStringAsFixed(1)} ms',
                key: const ValueKey('settings-last-save'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StudioBadge(
                  status,
                  key: const ValueKey('settings-section-status'),
                  tone: tone,
                ),
                if (section.followsScope) StudioBadge('Portée : $scopeLabel'),
                StudioButton(
                  key: const ValueKey('settings-section-undo'),
                  label: 'Défaire',
                  icon: Icons.undo,
                  variant: StudioButtonVariant.quiet,
                  onPressed: session.canUndo(section) && !saving
                      ? () => session.undo(section)
                      : null,
                ),
                StudioButton(
                  key: const ValueKey('settings-section-redo'),
                  label: 'Rétablir',
                  icon: Icons.redo,
                  variant: StudioButtonVariant.quiet,
                  onPressed: session.canRedo(section) && !saving
                      ? () => session.redo(section)
                      : null,
                ),
                StudioButton(
                  key: const ValueKey('settings-section-discard'),
                  label: 'Abandonner les modifications',
                  secondary: true,
                  onPressed: dirty && !saving
                      ? () => session.discard(section)
                      : null,
                ),
                StudioButton(
                  key: const ValueKey('settings-section-save'),
                  label: error != null
                      ? 'Réessayer l’enregistrement'
                      : 'Enregistrer la rubrique',
                  icon: Icons.save_outlined,
                  loading: saving,
                  onPressed: session.canSave(section)
                      ? () => unawaited(session.save(section))
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
