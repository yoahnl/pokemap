import 'package:flutter/material.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_choice.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_canvas_types.dart';

Future<SceneBlockDragData?> showSceneCanvasMenu(
  BuildContext context,
  List<SceneBlockDragData> blocks,
) => showDialog<SceneBlockDragData>(
  context: context,
  builder: (_) => _SceneCanvasMenu(blocks),
);

class _SceneCanvasMenu extends StatefulWidget {
  const _SceneCanvasMenu(this.blocks);
  final List<SceneBlockDragData> blocks;
  @override
  State<_SceneCanvasMenu> createState() => _SceneCanvasMenuState();
}

class _SceneCanvasMenuState extends State<_SceneCanvasMenu> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final blocks = widget.blocks
        .where((b) => b.label.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return AlertDialog(
      title: const Text('Ajouter un bloc'),
      content: SizedBox(
        width: 360,
        height: 330,
        child: Column(
          children: [
            TextField(
              key: const ValueKey('scene-block-search'),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Rechercher une action',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (text) => setState(() => query = text),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: blocks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (_, index) => StudioChoice(
                  label: blocks[index].label,
                  onTap: () => Navigator.pop(context, blocks[index]),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}
