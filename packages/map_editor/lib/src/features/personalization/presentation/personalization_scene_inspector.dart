import 'package:flutter/material.dart';

import '../../../ui/design_system/design_system.dart';

class PersonalizationSceneInspector extends StatelessWidget {
  const PersonalizationSceneInspector({
    super.key,
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) => PokeMapPanel(
    key: const ValueKey<String>('personalization-studio-scene-inspector'),
    expandChild: true,
    padding: EdgeInsets.zero,
    header: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const PokeMapBadge(
                label: 'En direct',
                variant: PokeMapBadgeVariant.mapAccent,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(description),
        ],
      ),
    ),
    child: ListView(
      key: const ValueKey<String>('personalization-studio-inspector-scroll'),
      padding: const EdgeInsets.all(16),
      children: <Widget>[child],
    ),
  );
}
