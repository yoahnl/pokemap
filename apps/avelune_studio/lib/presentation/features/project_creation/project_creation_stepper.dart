import 'package:flutter/material.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class ProjectCreationStepper extends StatelessWidget {
  const ProjectCreationStepper({super.key, required this.step});
  final int step;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const names = [
      'Informations',
      'Modèle',
      'Paramètres',
      'Destination',
      'Création',
    ];
    return StudioPanel(
      compact: true,
      children: [
        LayoutBuilder(
          builder: (context, bounds) => Row(
            children: [
              for (var i = 0; i < names.length; i++)
                Expanded(
                  child: Semantics(
                    label: 'Étape ${i + 1} : ${names[i]}',
                    selected: step == i,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: step == i
                              ? colors.primary
                              : colors.surfaceContainerHigh,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        if (bounds.maxWidth > 720 || step == i) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              names[i],
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
