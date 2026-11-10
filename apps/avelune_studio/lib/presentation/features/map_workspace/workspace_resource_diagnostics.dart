import 'package:flutter/material.dart';
import '../../../features/map_workspace/application/workspace_resource_diagnostic_projection.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/feedback/studio_badge.dart';
import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import 'workspace_resource_diagnostic_detail.dart';

typedef OpenDiagnosticOwner = Future<bool> Function(String kind, String id);

class WorkspaceResourceDiagnostics extends StatelessWidget {
  const WorkspaceResourceDiagnostics({
    super.key,
    required this.visuals,
    this.onOpenOwner,
  });
  final MapWorkspaceVisuals visuals;
  final OpenDiagnosticOwner? onOpenOwner;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: visuals,
    builder: (context, _) {
      final count = WorkspaceResourceDiagnosticProjection(
        visuals.diagnostics, visuals.activeResourceIds,
      ).ownerCount;
      final message = count == 0
          ? 'Aucun incident sur les ressources demandées'
          : '$count ${count == 1 ? 'ressource' : 'ressources'} en incident · ressources demandées';
      return Row(
        key: const ValueKey('resource-summary'),
        children: [
          Icon(
            count == 0 ? Icons.check_circle_outline : Icons.info_outline,
            size: 15,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Tooltip(
              message: message,
              child: Text(
                message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            StudioButton(
              key: const ValueKey('resource-details'),
              label: 'Détails',
              secondary: true,
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => _DiagnosticPanel(
                  visuals: visuals,
                  onOpenOwner: onOpenOwner,
                ),
              ),
            ),
          ],
        ],
      );
    },
  );
}

class _DiagnosticPanel extends StatefulWidget {
  const _DiagnosticPanel({required this.visuals, this.onOpenOwner});
  final MapWorkspaceVisuals visuals;
  final OpenDiagnosticOwner? onOpenOwner;

  @override
  State<_DiagnosticPanel> createState() => _DiagnosticPanelState();
}

class _DiagnosticPanelState extends State<_DiagnosticPanel> {
  bool activeOnly = false;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.visuals,
    builder: (context, _) {
      final active = widget.visuals.activeResourceIds;
      final projection = WorkspaceResourceDiagnosticProjection(
        widget.visuals.diagnostics, active, activeOnly: activeOnly,
      );
      final diagnostics = projection.diagnostics;
      final rows = projection.groups;
      final groups = rows.length;
      final retryable = projection.retryableIds;
      return Dialog(
        child: SizedBox(
          key: const ValueKey('resource-diagnostics-panel'),
          width: 600,
          height: MediaQuery.sizeOf(context).height * .70,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ressources demandées',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    StudioTool(
                      label: 'Fermer les diagnostics',
                      icon: Icons.close,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    StudioButton(
                      label: 'Toutes demandées',
                      secondary: activeOnly,
                      onPressed: () => setState(() => activeOnly = false),
                    ),
                    StudioButton(
                      label: 'Carte active',
                      secondary: !activeOnly,
                      onPressed: () => setState(() => activeOnly = true),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  groups == diagnostics.length
                      ? '$groups ressources concernées'
                      : '$groups ressources concernées · ${diagnostics.length} références',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: diagnostics.isEmpty
                      ? const Center(
                          child: Text('Aucun incident pour ce filtre'),
                        )
                      : ListView.builder(
                          key: const ValueKey('resource-diagnostics-list'),
                          itemCount: rows.length,
                          itemBuilder: (context, index) => _DiagnosticRow(
                            group: rows[index],
                            visuals: widget.visuals,
                            onOpenOwner: widget.onOpenOwner,
                          ),
                        ),
                ),
                const Divider(),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: StudioButton(
                    key: const ValueKey('resource-retry-filter'),
                    label: 'Réessayer ce filtre',
                    icon: Icons.refresh,
                    onPressed: retryable.isEmpty
                        ? null
                        : () => widget.visuals.retryResources(
                            retryable,
                          ),
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

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({
    required this.group,
    required this.visuals,
    this.onOpenOwner,
  });
  final WorkspaceResourceDiagnosticGroup group;
  final MapWorkspaceVisuals visuals;
  final OpenDiagnosticOwner? onOpenOwner;

  @override
  Widget build(BuildContext context) {
    final items = group.items;
    final item = items.first;
    final title = group.title;
    final roles = group.roles;
    final verified = group.verified;
    final openOwner = onOpenOwner;
    final owner = group.owner;
    final retryable = group.retryableIds;
    final onMap = group.active;
    return Padding(
      key: ValueKey('resource-row-${group.key}'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message: title,
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (roles.isNotEmpty)
                  Text(
                    '${roles.join(' · ')} · ${items.length} référence${items.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(item.message),
                    StudioBadge(
                      verified ? 'Cause vérifiée' : 'Cause non vérifiée',
                    ),
                  ],
                ),
                Text(
                  item.explanation,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${onMap ? 'Carte active · ' : ''}'
                  '${retryable.isEmpty ? 'Réessai en cours' : 'Non chargé'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (owner != null && openOwner != null) ...[
            StudioTool(
              key: const ValueKey('resource-open-owner'),
              label: 'Ouvrir la ressource',
              icon: Icons.open_in_new,
              onPressed: () async {
                final navigator = Navigator.of(context);
                if (await openOwner(owner.$1, owner.$2)) {
                  navigator.pop();
                }
              },
            ),
            const SizedBox(width: 4),
          ],
          StudioTool(
            label: 'Voir le diagnostic complet',
            icon: Icons.subject,
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => WorkspaceResourceDiagnosticDetail(items: items),
            ),
          ),
          const SizedBox(width: 4),
          StudioTool(
            label: 'Réessayer ces ressources',
            icon: Icons.refresh,
            onPressed: retryable.isEmpty
                ? null
                : () => visuals.retryResources(
                    retryable,
                  ),
          ),
        ],
      ),
    );
  }
}
