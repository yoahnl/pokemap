import 'package:flutter/material.dart';

import 'workshop_review.dart';

class WorkshopReviewControls extends StatelessWidget {
  const WorkshopReviewControls({
    super.key,
    required this.status,
    required this.enabled,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onChanged,
  });

  final WorkshopReviewStatus status;
  final bool enabled;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<WorkshopReviewStatus> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 4,
    children: [
      IconButton(tooltip: 'Attaque précédente', onPressed: canGoPrevious ? onPrevious : null,
        icon: const Icon(Icons.chevron_left)),
      IconButton(tooltip: 'Attaque suivante', onPressed: canGoNext ? onNext : null,
        icon: const Icon(Icons.chevron_right)),
      const Text('Ta revue :'),
      DropdownButton<WorkshopReviewStatus>(
        value: status,
        onChanged: enabled ? (value) { if (value != null) onChanged(value); } : null,
        items: const [
          DropdownMenuItem(value: WorkshopReviewStatus.toReview, child: Text('À revoir')),
          DropdownMenuItem(value: WorkshopReviewStatus.issue, child: Text('Écart à corriger')),
          DropdownMenuItem(value: WorkshopReviewStatus.approved, child: Text('Validée')),
        ],
      ),
    ],
  );
}
