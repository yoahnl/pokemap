import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/buttons/studio_button.dart';

class EventScenePanel extends StatelessWidget {
  const EventScenePanel({
    super.key,
    required this.scenes,
    required this.selectedId,
    required this.dirtyIds,
    required this.onSelect,
    required this.onOpen,
    required this.onRemove,
  });
  final List<SceneAsset> scenes;
  final String? selectedId;
  final Set<String> dirtyIds;
  final ValueChanged<String> onSelect, onOpen;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => StudioPanel(
    compact: true,
    title: 'Scène à jouer',
    children: [
      const Text(
        'Associez un document complet. Ses dialogues, branches et résultats restent dans la scène.',
      ),
      const SizedBox(height: 12),
      if (selectedId != null && !scenes.any((s) => s.id == selectedId))
        Text('Scène absente : $selectedId. La référence est conservée.'),
      Expanded(
        child: ListView.builder(
          itemCount: scenes.length,
          itemBuilder: (_, i) {
            final scene = scenes[i];
            return StudioChoice(
              key: ValueKey('event-scene:${scene.id}'),
              label: scene.name,
              subtitle:
                  '${scene.graph.nodes.length} blocs · ${dirtyIds.contains(scene.id) ? 'Modifiée localement' : 'Enregistrée'}\n${scene.id}',
              selected: scene.id == selectedId,
              leading: const Icon(Icons.account_tree_outlined),
              onTap: () => onSelect(scene.id),
            );
          },
        ),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          StudioButton(
            label: 'Ouvrir la scène',
            icon: Icons.open_in_new,
            onPressed:
                selectedId == null || !scenes.any((s) => s.id == selectedId)
                ? null
                : () => onOpen(selectedId!),
          ),
          StudioButton(
            label: 'Retirer l’association',
            secondary: true,
            onPressed: selectedId == null ? null : onRemove,
          ),
        ],
      ),
    ],
  );
}
