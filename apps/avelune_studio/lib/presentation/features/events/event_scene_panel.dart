import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../shared/widgets/buttons/studio_button.dart';

class EventScenePanel extends StatefulWidget {
  const EventScenePanel({
    super.key,
    required this.scenes,
    required this.selectedId,
    required this.dirtyIds,
    required this.onSelect,
    required this.onOpen,
    required this.onRemove,
    this.storylines = const [],
  });
  final List<SceneAsset> scenes;
  final List<StorylineAsset> storylines;
  final String? selectedId;
  final Set<String> dirtyIds;
  final ValueChanged<String> onSelect, onOpen;
  final VoidCallback onRemove;

  @override
  State<EventScenePanel> createState() => _EventScenePanelState();
}

class _EventScenePanelState extends State<EventScenePanel> {
  final _search = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = widget.selectedId;
    final linked = widget.scenes
        .where((scene) => scene.id == selectedId)
        .firstOrNull;
    final contexts = _sceneContexts();
    final needle = _query.trim().toLowerCase();
    final visible = [
      if (linked != null && _matches(linked, contexts[linked.id], needle))
        linked,
      for (final scene in widget.scenes)
        if (scene.id != selectedId &&
            _matches(scene, contexts[scene.id], needle))
          scene,
    ];
    final total = widget.scenes.length;
    final textTheme = Theme.of(context).textTheme;
    return StudioPanel(
      compact: true,
      title: 'Scène à jouer',
      children: [
        const Text(
          'Associez un document complet. Ses dialogues, branches et résultats restent dans la scène.',
        ),
        const SizedBox(height: 12),
        if (selectedId != null && linked == null)
          Text('Scène absente : $selectedId. La référence est conservée.'),
        StudioSearchField(
          key: const ValueKey('event-scene-search'),
          controller: _search,
          label: 'Rechercher une scène',
          hint: 'Nom, description, étiquette ou histoire',
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 6),
        Text(
          needle.isEmpty
              ? '$total ${total > 1 ? 'scènes' : 'scène'}'
              : '${visible.length} ${visible.length > 1 ? 'scènes' : 'scène'} sur $total',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        Expanded(
          child: visible.isEmpty
              ? Text(
                  needle.isEmpty
                      ? 'Aucune scène dans ce projet.'
                      : 'Aucune scène ne correspond à « ${_query.trim()} ».',
                )
              : ListView.builder(
                  itemCount: visible.length,
                  itemBuilder: (_, i) {
                    final scene = visible[i];
                    final sceneContext = contexts[scene.id];
                    return StudioChoice(
                      key: ValueKey('event-scene:${scene.id}'),
                      label: scene.name,
                      subtitle: [
                        '${scene.graph.nodes.length} blocs · ${widget.dirtyIds.contains(scene.id) ? 'Modifiée localement' : 'Enregistrée'}${scene.id == selectedId ? ' · Scène liée' : ''}',
                        if (sceneContext != null && sceneContext.isNotEmpty)
                          sceneContext,
                      ].join('\n'),
                      selected: scene.id == selectedId,
                      leading: const Icon(Icons.account_tree_outlined),
                      onTap: () => widget.onSelect(scene.id),
                    );
                  },
                ),
        ),
        if (linked != null) ...[
          const SizedBox(height: 6),
          SelectableText(
            'Identifiant de la scène liée : ${linked.id}',
            style: textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StudioButton(
              label: 'Ouvrir la scène',
              icon: Icons.open_in_new,
              onPressed: linked == null ? null : () => widget.onOpen(linked.id),
            ),
            StudioButton(
              label: 'Retirer l’association',
              secondary: true,
              onPressed: selectedId == null ? null : widget.onRemove,
            ),
          ],
        ),
      ],
    );
  }

  Map<String, String> _sceneContexts() {
    final storylines = {
      for (final storyline in widget.storylines) storyline.id: storyline,
    };
    return {
      for (final scene in widget.scenes)
        scene.id: [
          if (storylines[scene.storylineId] case final storyline?) ...[
            storyline.title,
            if (storyline.chapters
                    .where((chapter) => chapter.id == scene.chapterId)
                    .firstOrNull
                case final chapter?)
              chapter.title,
          ],
          if (scene.description?.trim() case final description?
              when description.isNotEmpty)
            description,
          ...scene.tags,
        ].join(' · '),
    };
  }

  bool _matches(SceneAsset scene, String? context, String needle) =>
      needle.isEmpty ||
      scene.name.toLowerCase().contains(needle) ||
      scene.id.toLowerCase().contains(needle) ||
      (context?.toLowerCase().contains(needle) ?? false);
}
