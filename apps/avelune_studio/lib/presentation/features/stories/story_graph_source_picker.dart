import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import 'story_graph_geometry.dart';

Future<String?> chooseStoryGraphSource(
  BuildContext context,
  StoryGraphGeometry graph,
) => showDialog<String>(
  context: context,
  builder: (_) => _SourcePicker(
    items: {
      for (final fact in graph.project.facts)
        if (fact.valueKind == NarrativeValueKind.boolean &&
            !graph.nodes.containsKey('fact:${fact.id}'))
          'fact:${fact.id}': 'Fait · ${fact.label}',
      for (final story in graph.project.storylines)
        if (!graph.nodes.containsKey('storyline:${story.id}'))
          'storyline:${story.id}': 'Histoire · ${story.title}',
    },
  ),
);

class _SourcePicker extends StatefulWidget {
  const _SourcePicker({required this.items});
  final Map<String, String> items;
  @override
  State<_SourcePicker> createState() => _SourcePickerState();
}

class _SourcePickerState extends State<_SourcePicker> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.toLowerCase();
    final items = widget.items.entries
        .where(
          (e) =>
              e.value.toLowerCase().contains(query) ||
              e.key.toLowerCase().contains(query),
        )
        .toList();
    return AlertDialog(
      title: const Text('Afficher une source dans le graphe'),
      content: SizedBox(
        width: 420,
        height: 360,
        child: Column(
          children: [
            StudioSearchField(
              controller: _search,
              label: 'Rechercher un fait ou une histoire',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('Aucune source supplémentaire'))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          title: Text(item.value),
                          subtitle: Text(item.key),
                          onTap: () => Navigator.pop(context, item.key),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
