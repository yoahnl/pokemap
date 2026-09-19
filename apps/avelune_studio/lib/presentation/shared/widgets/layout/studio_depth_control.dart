import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../buttons/studio_button.dart';

class StudioDepthControl extends StatelessWidget {
  const StudioDepthControl({
    super.key,
    required this.onForward,
    required this.onBackward,
  });
  final VoidCallback? onForward, onBackward;

  Widget _action(bool forward) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StudioButton(
        key: ValueKey(forward ? 'Passer devant' : 'Passer derrière'),
        label: forward ? 'Passer devant' : 'Passer derrière',
        secondary: true,
        onPressed: forward ? onForward : onBackward,
      ),
      const SizedBox(height: 4),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            defaultTargetPlatform == TargetPlatform.macOS
                ? 'Cmd + '
                : 'Ctrl + ',
          ),
          Icon(forward ? Icons.arrow_upward : Icons.arrow_downward, size: 14),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth <
          260 * MediaQuery.textScalerOf(context).scale(1)) {
        return Column(
          children: [_action(true), const SizedBox(height: 8), _action(false)],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _action(true)),
          const SizedBox(width: 8),
          Expanded(child: _action(false)),
        ],
      );
    },
  );
}
