import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/terrains/application/terrain_draft_controller.dart';
import '../../../features/terrains/domain/terrain_connections.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../resources/atlas_selection_view.dart';
import 'terrain_scratch_view.dart';
import '../../shared/widgets/layout/studio_page_header.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class TerrainEditorScreen extends StatefulWidget {
  const TerrainEditorScreen({
    super.key,
    required this.controller,
    required this.image,
    required this.frameBuilder,
    required this.onMutate,
    required this.onUse,
    required this.onClose,
  });
  final TerrainDraftController controller;
  final Widget image;
  final TerrainFrameBuilder frameBuilder;
  final MutateTerrainResource onMutate;
  final ValueChanged<ProjectSmartTilePreset> onUse;
  final VoidCallback onClose;

  @override
  State<TerrainEditorScreen> createState() => _TerrainEditorScreenState();
}

class _TerrainEditorScreenState extends State<TerrainEditorScreen> {
  late final _name = TextEditingController(text: widget.controller.draft.name);
  String _tool = 'Corriger';
  TerrainDraftController get model => widget.controller;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save(bool publish) async {
    final pending = model.save(widget.onMutate, publish: publish);
    setState(() {});
    final success = await pending;
    if (!mounted) return;
    setState(() {});
    if (success && publish) {
      widget.onUse(
        model.manifest.smartTileCatalog.presets.firstWhere(
          (preset) => preset.id == model.draft.targetPresetId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final atlas = model.atlas;
    final source = model.manifest.tilesets
        .firstWhere((t) => t.id == atlas.tilesetId)
        .source;
    if (source is! ProjectRegularAtlasTilesetSource) {
      return Center(
        child: Text('Cette source n’est pas encore éditable dans Studio.'),
      );
    }
    final frame = model.frameFor(model.selectedRule);
    final selection = TilesetSourceRect(
      x: frame?.column ?? 0,
      y: frame?.row ?? 0,
      width: 1,
      height: 1,
    );
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLowest,
      child: Column(
        children: [
          StudioPageHeader(
            title: 'Terrain automatique',
            description: model.dirty
                ? 'Brouillon modifié'
                : 'Brouillon enregistré',
            actions: [
              StudioButton(
                label: 'Retour aux ressources',
                secondary: true,
                onPressed: model.busy ? null : widget.onClose,
              ),
              StudioButton(
                label: 'Enregistrer le brouillon',
                secondary: true,
                onPressed: model.busy ? null : () => _save(false),
              ),
              StudioButton(
                label: 'Publier et peindre',
                onPressed: model.busy || !model.complete
                    ? null
                    : () => _save(true),
              ),
            ],
          ),
          if (model.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(model.error!, style: TextStyle(color: colors.error)),
            ),
          if (model.busy) const LinearProgressIndicator(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final sourcePanel = StudioPanel(
                  title: 'Image et raccords',
                  children: [
                    TextField(
                      controller: _name,
                      enabled: !model.busy,
                      decoration: const InputDecoration(
                        labelText: 'Nom du terrain',
                      ),
                      onChanged: (value) => setState(() => model.rename(value)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Raccords sur 4 côtés · 16 morceaux',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choisissez un raccord puis sa case dans l’image. Les croix signalent un morceau manquant.',
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 290,
                      child: AbsorbPointer(
                        absorbing: model.busy,
                        child: AtlasSelectionView(
                          source: source,
                          selected: selection,
                          image: widget.image,
                          singleCell: true,
                          onSelected: (rect) =>
                              setState(() => model.assign(rect.x, rect.y)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _rules(),
                  ],
                );
                final scratchPanel = StudioPanel(
                  children: [
                    Text(
                      'Terrain d’essai',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Cliquez un raccord pour retrouver sa règle. Dessinez pour vérifier les voisins.',
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final tool in ['Corriger', 'Peindre', 'Gommer'])
                          StudioButton(
                            label: tool,
                            secondary: _tool != tool,
                            onPressed: model.busy
                                ? null
                                : () => setState(() => _tool = tool),
                          ),
                        StudioButton(
                          label: 'Exemple complet',
                          secondary: true,
                          onPressed: model.busy
                              ? null
                              : () => setState(model.example),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AbsorbPointer(
                      absorbing: model.busy,
                      child: TerrainScratchView(
                        controller: model,
                        frameBuilder: widget.frameBuilder,
                        tool: _tool,
                        onChanged: () => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Raccord sélectionné : ${terrainConnectionNames[model.selectedRule]}',
                    ),
                    Text(
                      '${model.draft.rules.where((rule) => rule.candidates.isNotEmpty).length} / 16 morceaux associés',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Les modèles avancés existants restent utilisables sur la carte ; leur préparation n’est pas encore disponible ici.',
                    ),
                  ],
                );
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: constraints.maxWidth < 850
                      ? Column(
                          children: [
                            sourcePanel,
                            const SizedBox(height: 24),
                            scratchPanel,
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 6, child: sourcePanel),
                            const SizedBox(width: 20),
                            Expanded(flex: 5, child: scratchPanel),
                          ],
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _rules() => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: 16,
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 165,
      mainAxisExtent: 74,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
    ),
    itemBuilder: (context, index) {
      final colors = Theme.of(context).colorScheme;
      final frame = model.frameFor(index);
      return Material(
        color: index == model.selectedRule
            ? colors.primaryContainer
            : colors.surfaceContainer,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          key: ValueKey('terrain-rule-$index'),
          onTap: model.busy
              ? null
              : () => setState(() => model.selectedRule = index),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: frame == null
                      ? Icon(
                          Icons.add_photo_alternate_outlined,
                          color: colors.onSurfaceVariant,
                        )
                      : widget.frameBuilder(frame, 32),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    terrainConnectionNames[index],
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
