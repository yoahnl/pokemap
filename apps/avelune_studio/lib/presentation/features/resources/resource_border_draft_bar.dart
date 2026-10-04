import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_tabs.dart';
import '../map_workspace/workspace_compact_panel.dart';

enum BorderResourceAction { usages, deleteDraft, deprecate, reactivate }

enum _BorderView { drafts, published, deprecated }

class ResourceBorderDraftBar extends StatefulWidget {
  const ResourceBorderDraftBar({
    super.key,
    required this.records,
    required this.onResume,
    this.onManage,
    this.compact = false,
  });
  final List<BorderBlueprintRecord> records;
  final ValueChanged<BorderBlueprintRecord> onResume;
  final void Function(BorderBlueprintRecord, BorderResourceAction)? onManage;
  final bool compact;

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
      scrollDirection: Axis.horizontal,
      itemCount: records.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final record = records[index];
        return SizedBox(
          width: 320,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: StudioButton(
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
                    ? 'Préparation jamais publiée'
                    : 'Brouillon et publication r${record.latestPublished!.revision}${record.isDeprecated ? ' · Dépréciée' : ''}',
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
          child: Text('Voir les usages dans le projet'),
        ),
        if (record.latestPublished == null)
          const PopupMenuItem(
            value: BorderResourceAction.deleteDraft,
            child: Text('Retirer la préparation…'),
          )
        else if (record.isDeprecated)
          const PopupMenuItem(
            value: BorderResourceAction.reactivate,
            child: Text('Réactiver…'),
          )
        else
          const PopupMenuItem(
            value: BorderResourceAction.deprecate,
            child: Text('Déprécier…'),
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
    child: widget.compact
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
