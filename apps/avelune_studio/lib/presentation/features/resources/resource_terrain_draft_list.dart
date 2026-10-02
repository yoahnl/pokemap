import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../map_workspace/workspace_compact_panel.dart';
import 'resource_terrain_actions.dart';

class ResourceTerrainDraftList extends StatelessWidget {
  const ResourceTerrainDraftList({
    super.key,
    required this.drafts,
    required this.onResume,
    this.onManage,
    this.status,
    this.canResume,
    this.compact = false,
  });
  final List<ProjectSmartTileAuthoringDraft> drafts;
  final ValueChanged<ProjectSmartTileAuthoringDraft> onResume;
  final void Function(ProjectSmartTileAuthoringDraft, TerrainResourceAction)?
  onManage;
  final String Function(ProjectSmartTileAuthoringDraft)? status;
  final bool Function(ProjectSmartTileAuthoringDraft)? canResume;
  final bool compact;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
    child: compact
        ? StudioButton(
            key: const ValueKey('resource-terrain-preparations'),
            label: 'Préparations (${drafts.length})',
            icon: Icons.edit_outlined,
            secondary: true,
            onPressed: () => showWorkspaceCompactPanel(
              context,
              title: 'Préparations de terrains',
              closeLabel: 'Retour aux ressources',
              builder: (context, refresh, close) =>
                  _entries(context, close: close),
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Préparations (${drafts.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              _entries(context),
            ],
          ),
  );

  Widget _entries(BuildContext context, {VoidCallback? close}) => SizedBox(
    height: MediaQuery.textScalerOf(context).scale(14) > 20 ? 140 : 108,
    child: ListView.builder(
      key: const ValueKey('terrain-drafts'),
      scrollDirection: Axis.horizontal,
      itemCount: drafts.length,
      itemBuilder: (context, index) {
        final draft = drafts[index];
        final assigned = draft.rules
            .where((rule) => rule.candidates.isNotEmpty)
            .length;
        final compatible = canResume?.call(draft) ?? true;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: SizedBox(
            width: 320,
            child: Row(
              children: [
                Expanded(
                  child: StudioChoice(
                    label: 'Reprendre le brouillon : ${draft.name}',
                    subtitle:
                        '${status?.call(draft) ?? 'Brouillon enregistré'} · $assigned / ${draft.rules.length} raccords${compatible ? '' : ' · Raccords avancés en lecture seule'}',
                    leading: const Icon(Icons.edit_outlined, size: 20),
                    onTap: compatible
                        ? () {
                            close?.call();
                            onResume(draft);
                          }
                        : null,
                  ),
                ),
                if (onManage != null)
                  Builder(
                    builder: (buttonContext) => StudioTool(
                      key: ValueKey('terrain-draft-actions-${draft.id}'),
                      label: 'Actions de la préparation ${draft.name}',
                      icon: Icons.more_horiz,
                      onPressed: () async {
                        final box =
                            buttonContext.findRenderObject()! as RenderBox;
                        final overlay =
                            Overlay.of(context).context.findRenderObject()!
                                as RenderBox;
                        final position = box.localToGlobal(
                          Offset(0, box.size.height),
                        );
                        final action = await showMenu<TerrainResourceAction>(
                          context: context,
                          position: RelativeRect.fromRect(
                            Rect.fromLTWH(position.dx, position.dy, 1, 1),
                            Offset.zero & overlay.size,
                          ),
                          items: [
                            if (draft.sourcePresetId != null)
                              const PopupMenuItem(
                                value: TerrainResourceAction.usages,
                                child: Text(
                                  'Voir les usages de la publication',
                                ),
                              ),
                            const PopupMenuItem(
                              value: TerrainResourceAction.rename,
                              child: Text('Renommer le brouillon…'),
                            ),
                            const PopupMenuItem(
                              value: TerrainResourceAction.duplicate,
                              child: Text('Dupliquer le brouillon…'),
                            ),
                            const PopupMenuItem(
                              value: TerrainResourceAction.deleteDraft,
                              child: Text('Supprimer le brouillon…'),
                            ),
                          ],
                        );
                        if (context.mounted && action != null) {
                          close?.call();
                          onManage!(draft, action);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
