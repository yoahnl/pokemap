import 'package:flutter/material.dart';

import '../../../features/verification/application/studio_failure_diagnosis.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_badge.dart';
import '../../shared/widgets/feedback/studio_notice.dart';

class StudioFailureReport extends StatelessWidget {
  const StudioFailureReport({
    super.key,
    required this.diagnosis,
    this.onOpenOwner,
  });

  final StudioFailureDiagnosis diagnosis;
  final void Function(StudioFailureOwner owner)? onOpenOwner;

  @override
  Widget build(BuildContext context) {
    final family = diagnosis.family;
    final owner = diagnosis.owner;
    final open = onOpenOwner;
    final small = Theme.of(context).textTheme.bodySmall;
    return Column(
      key: const ValueKey('studio-failure-report'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        StudioBadge(
          family?.label ?? 'Cause non déterminée',
          tone: family == null ? StudioTone.warning : StudioTone.danger,
          icon: family == null ? Icons.help_outline : Icons.error_outline,
        ),
        const SizedBox(height: 8),
        StudioNotice(
          family == null
              ? 'La cause exacte n’a pas encore été déterminée. '
                    '${diagnosis.summary}'
              : diagnosis.summary,
          isError: true,
        ),
        const SizedBox(height: 8),
        if (owner != null)
          Text('À corriger dans : ${owner.label}', style: small)
        else if (family != null)
          Text(
            'Le propriétaire de ce problème n’est pas encore identifié : '
            'aucune réparation n’est proposée.',
            style: small,
          )
        else
          Text(
            'Une action de réparation ciblée n’apparaît que lorsque la cause '
            'est connue.',
            style: small,
          ),
        if (owner != null && open != null) ...[
          const SizedBox(height: 8),
          StudioButton(
            key: const ValueKey('studio-failure-open-owner'),
            label: owner.action,
            icon: Icons.arrow_forward,
            onPressed: () => open(owner),
          ),
        ],
        ExpansionTile(
          key: const ValueKey('studio-failure-detail'),
          tilePadding: EdgeInsets.zero,
          shape: const Border(),
          collapsedShape: const Border(),
          title: const Text('Afficher le détail technique'),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SelectableText(diagnosis.detail),
            ),
          ],
        ),
      ],
    );
  }
}
