import 'package:flutter/material.dart';

import '../../../features/verification/application/test_launch_preflight.dart';
import '../../shared/widgets/dialogs/studio_review_dialog.dart';
import '../../shared/widgets/feedback/studio_notice.dart';

Future<bool> showTestLaunchDialog(
  BuildContext context,
  TestLaunchPreflight preflight,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StudioReviewDialog(
        title: preflight.title,
        confirmLabel: preflight.saves.isEmpty
            ? 'Lancer le test'
            : 'Enregistrer puis lancer',
        onCancelled: () => Navigator.pop(dialogContext, false),
        onConfirmed: preflight.canLaunch
            ? () => Navigator.pop(dialogContext, true)
            : null,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(preflight.scopeNote),
            const SizedBox(height: 12),
            if (preflight.blockers.isNotEmpty) ...[
              StudioNotice(
                [
                  'Le test ne peut pas démarrer : ces brouillons doivent '
                      'd’abord être enregistrés ou abandonnés dans leur page.',
                  for (final blocker in preflight.blockers)
                    '• ${blocker.label} — ${blocker.where}',
                ].join('\n'),
                isError: true,
              ),
              const SizedBox(height: 12),
            ],
            if (preflight.saves.isEmpty)
              const Text('Aucun brouillon à enregistrer avant le test.')
            else ...[
              const Text('Ces brouillons seront enregistrés avant le test :'),
              const SizedBox(height: 4),
              for (final save in preflight.saves) Text('• $save'),
            ],
          ],
        ),
      ),
    ) ??
    false;
