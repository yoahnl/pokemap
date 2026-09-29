import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/layout/studio_panel.dart';
import '../map_workspace/map_workspace_visuals.dart';

class BorderSourcePanel extends StatefulWidget {
  const BorderSourcePanel({
    super.key,
    required this.project,
    required this.visuals,
    required this.active,
    required this.onActive,
  });

  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final ProjectElementEntry? active;
  final ValueChanged<ProjectElementEntry> onActive;

  @override
  State<BorderSourcePanel> createState() => _BorderSourcePanelState();
}

class _BorderSourcePanelState extends State<BorderSourcePanel> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final matches = widget.project.elements
        .where(
          (element) =>
              element.name.toLowerCase().contains(query) ||
              element.id.toLowerCase().contains(query),
        )
        .toList();
    return SingleChildScrollView(
      child: StudioPanel(
        title: 'Décors disponibles',
        compact: true,
        children: [
          const Text(
            'Choisissez un décor, puis cliquez sur une place du patron. Vous pouvez aussi le glisser.',
          ),
          TextField(
            key: const ValueKey('border-library-search'),
            decoration: const InputDecoration(
              hintText: 'Rechercher un décor',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => query = value.toLowerCase()),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 340,
            child: ListView.builder(
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final element = matches[index];
                return Draggable<ProjectElementEntry>(
                  data: element,
                  feedback: Material(
                    elevation: 6,
                    child: widget.visuals.thumbnail(element, size: 56),
                  ),
                  child: ListTile(
                    key: ValueKey('border-library-${element.id}'),
                    dense: true,
                    selected: widget.active?.id == element.id,
                    leading: widget.visuals.thumbnail(element, size: 40),
                    title: Text(element.name, maxLines: 1),
                    onTap: () => widget.onActive(element),
                  ),
                );
              },
            ),
          ),
          if (widget.project.elements.isEmpty)
            const Text('Créez d’abord des décors dans Ressources.'),
        ],
      ),
    );
  }
}
