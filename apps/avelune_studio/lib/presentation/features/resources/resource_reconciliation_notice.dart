import 'package:flutter/material.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'resource_navigation.dart';

class ResourceReconciliationNotice extends StatelessWidget {
  const ResourceReconciliationNotice({super.key, required this.navigation});
  final ResourceNavigation navigation;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'La publication est conservée. Relisez son résultat sans la rejouer.',
        ),
        StudioButton(
          key: const ValueKey('resource-retry-reconciliation'),
          label: 'Relire le résultat',
          icon: Icons.refresh,
          secondary: true,
          onPressed: navigation.busy ? null : navigation.retryReconciliation,
        ),
      ],
    ),
  );
}
