import 'package:flutter/material.dart';

import '../../shared/widgets/buttons/studio_tool.dart';

Future<void> showWorkspaceCompactPanel(
  BuildContext context, {
  required String title,
  String closeLabel = 'Retour à la carte',
  double width = 360,
  bool dimBackground = true,
  required Widget Function(
    BuildContext context,
    VoidCallback refresh,
    VoidCallback close,
  )
  builder,
}) => showDialog<void>(
  context: context,
  barrierColor: dimBackground
      ? null
      : Theme.of(context).colorScheme.scrim.withValues(alpha: 0),
  builder: (context) => Dialog(
    alignment: Alignment.centerRight,
    insetPadding: const EdgeInsets.all(12),
    child: SizedBox(
      width: width,
      height: MediaQuery.sizeOf(context).height - 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StudioTool(
                  label: closeLabel,
                  icon: Icons.close,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StatefulBuilder(
              builder: (context, setState) => builder(
                context,
                () => setState(() {}),
                () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
