import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import 'resource_catalog.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_tabs.dart';
import '../map_workspace/workspace_compact_panel.dart';

enum BorderResourceAction { usages, deleteDraft, deprecate, reactivate }

enum _BorderView { drafts, published, deprecated }

class ResourceBorderDraftBar extends StatefulWidget {
  const ResourceBorderDraftBar({
    super.key,
    required this.records,
    required this.project,
    required this.onResume,
    this.onManage,
    this.compact = false,
    this.library = false,
  });
  final List<BorderBlueprintRecord> records;
  final ProjectManifest project;
  final ValueChanged<BorderBlueprintRecord> onResume;
  final void Function(BorderBlueprintRecord, BorderResourceAction)? onManage;
  final bool compact;
  final bool library;

  @override
  State<ResourceBorderDraftBar> createState() => _ResourceBorderDraftBarState();
}

class _ResourceBorderDraftBarState extends State<ResourceBorderDraftBar> {
  _BorderView _view = _BorderView.drafts;

  List<BorderBlueprintRecord> get _visible => widget.records.where((record) {
    return switch (_view) {
      _BorderView.drafts => true,
      _BorderView.published =>
        record.latestPublished != null && !record.isDeprecated,
      _BorderView.deprecated => record.isDeprecated,
    };
  }).toList();

  Widget _tabs(ValueChanged<_BorderView> onChanged) => StudioTabs<_BorderView>(
    items: const {
      _BorderView.drafts: 'Brouillons',
      _BorderView.published: 'Publiées',
      _BorderView.deprecated: 'Dépréciées',
    },
    selected: _view,
    onChanged: onChanged,
  );

  Widget _entries({VoidCallback? close}) {
    final records = _visible;
    if (records.isEmpty) {
      return const Center(child: Text('Aucune bordure dans cette vue.'));
    }
    return ListView.separated(
      scrollDirection: widget.library ? Axis.vertical : Axis.horizontal,
      itemCount: records.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final record = records[index];
        return SizedBox(
          width: widget.library ? null : 320,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: StudioButton(
                      key: ValueKey('border-resource-${record.id}'),
                      label: record.latestPublished == null
                          ? 'Reprendre « ${record.draft.definition.name} »'
                          : 'Modifier « ${record.draft.definition.name} »',
                      icon: Icons.edit_outlined,
                      secondary: true,
                      onPressed: () {
                        close?.call();
                        widget.onResume(record);
                      },
                    ),
                  ),
                  if (widget.onManage != null)
                    Builder(
                      builder: (buttonContext) => StudioTool(
                        key: ValueKey('border-resource-actions-${record.id}'),
                        label:
                            'Actions de la bordure ${record.draft.definition.name}',
                        icon: Icons.more_horiz,
                        onPressed: () => _menu(buttonContext, record, close),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                record.latestPublished == null
                    ? 'Préparation jamais publiée · ${resourcePlacementContextLabel(widget.project.resourceLibraryCatalog.entryFor('borderBlueprint', record.id)?.placementContext)}'
                    : 'Brouillon et publication r${record.latestPublished!.revision}${record.isDeprecated ? ' · Dépréciée' : ''} · ${resourcePlacementContextLabel(widget.project.resourceLibraryCatalog.entryFor('borderBlueprint', record.id)?.placementContext)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _menu(
    BuildContext context,
    BorderBlueprintRecord record,
    VoidCallback? close,
  ) async {
    final box = context.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final position = box.localToGlobal(Offset(0, box.size.height));
    final action = await showMenu<BorderResourceAction>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(
          value: BorderResourceAction.usages,
          child: ListTile(
            leading: Icon(Icons.account_tree_outlined),
            title: Text('Voir les usages dans le projet'),
            dense: true,
          ),
        ),
        if (record.latestPublished == null)
          const PopupMenuItem(
            value: BorderResourceAction.deleteDraft,
            child: ListTile(
              leading: Icon(Icons.delete_outline),
              title: Text('Retirer la préparation…'),
              dense: true,
            ),
          )
        else if (record.isDeprecated)
          const PopupMenuItem(
            value: BorderResourceAction.reactivate,
            child: ListTile(
              leading: Icon(Icons.restore_outlined),
              title: Text('Réactiver…'),
              dense: true,
            ),
          )
        else
          const PopupMenuItem(
            value: BorderResourceAction.deprecate,
            child: ListTile(
              leading: Icon(Icons.visibility_off_outlined),
              title: Text('Déprécier…'),
              dense: true,
            ),
          ),
      ],
    );
    if (context.mounted && action != null) {
      close?.call();
      widget.onManage!(record, action);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
    child: widget.library
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _tabs((view) => setState(() => _view = view)),
              const SizedBox(height: 12),
              const Text(
                'Une publication reste conservée sur les cartes. Déprécier retire seulement les nouveaux choix.',
              ),
              const SizedBox(height: 12),
              Expanded(child: _entries()),
            ],
          )
        : widget.compact
        ? StudioButton(
            key: const ValueKey('resource-border-library'),
            label: 'Bordures (${widget.records.length})',
            icon: Icons.timeline,
            secondary: true,
            onPressed: () => showWorkspaceCompactPanel(
              context,
              title: 'Bordures du projet',
              closeLabel: 'Retour aux ressources',
              builder: (context, refresh, close) => Column(
                children: [
                  _tabs((view) {
                    _view = view;
                    refresh();
                  }),
                  Expanded(child: _entries(close: close)),
                ],
              ),
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _tabs((view) => setState(() => _view = view)),
              SizedBox(height: 100, child: _entries()),
            ],
          ),
  );
}
