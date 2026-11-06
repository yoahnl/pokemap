import 'package:flutter/material.dart';

import '../../../features/home/application/home_next_steps.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_badge.dart';

class StudioHomeNextSteps extends StatefulWidget {
  const StudioHomeNextSteps({
    super.key,
    required this.steps,
    required this.busy,
    required this.onDestination,
    required this.onMap,
  });

  final List<HomeNextStep> steps;
  final bool busy;
  final ValueChanged<String> onDestination, onMap;

  @override
  State<StudioHomeNextSteps> createState() => _StudioHomeNextStepsState();
}

class _StudioHomeNextStepsState extends State<StudioHomeNextSteps> {
  var _hidden = false;

  void _open(HomeNextStep step) {
    final mapId = step.mapId;
    if (mapId != null) {
      widget.onMap(mapId);
    } else {
      widget.onDestination(step.destination);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = widget.steps
        .where((step) => step.status == HomeNextStepStatus.done)
        .length;
    final header = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Prochaines étapes', style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                '$done sur ${widget.steps.length} vérifiées comme faites',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        StudioButton(
          key: ValueKey(
            _hidden ? 'home-next-steps-show' : 'home-next-steps-hide',
          ),
          label: _hidden ? 'Afficher' : 'Masquer',
          variant: StudioButtonVariant.quiet,
          onPressed: () => setState(() => _hidden = !_hidden),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        if (!_hidden)
          for (final step in widget.steps) ...[
            const SizedBox(height: 10),
            _StepRow(
              step: step,
              onPressed: widget.busy || step.unavailableReason != null
                  ? null
                  : () => _open(step),
            ),
          ],
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.onPressed});

  final HomeNextStep step;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, tone, icon) = switch (step.status) {
      HomeNextStepStatus.done => (
        'Fait',
        StudioTone.success,
        Icons.check_circle_outline,
      ),
      HomeNextStepStatus.todo => (
        'À faire',
        StudioTone.warning,
        Icons.radio_button_unchecked,
      ),
      HomeNextStepStatus.unverified => (
        'Non vérifié',
        StudioTone.neutral,
        Icons.help_outline,
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(step.title, style: theme.textTheme.bodyMedium),
            ),
            const SizedBox(width: 8),
            StudioBadge(label, tone: tone, icon: icon),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          step.unavailableReason ?? step.detail,
          style: theme.textTheme.bodySmall,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: StudioButton(
            key: ValueKey('home-next-step-${step.kind.name}'),
            label: step.action,
            icon: Icons.arrow_forward,
            variant: StudioButtonVariant.quiet,
            onPressed: onPressed,
          ),
        ),
      ],
    );
  }
}
