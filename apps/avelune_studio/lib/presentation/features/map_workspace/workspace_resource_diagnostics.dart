import 'package:flutter/material.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import 'map_workspace_visuals.dart';
import 'workspace_resource_diagnostic.dart';
import 'workspace_resource_diagnostic_detail.dart';

class WorkspaceResourceDiagnostics extends StatelessWidget {
  const WorkspaceResourceDiagnostics({super.key, required this.visuals});
  final MapWorkspaceVisuals visuals;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: visuals,
    builder: (context, _) {
      final count = _unique(visuals.diagnostics).length;
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
                builder: (_) => _DiagnosticPanel(visuals: visuals),
              ),
            ),
          ],
        ],
      );
    },
  );
}

List<WorkspaceResourceDiagnostic> _unique(
  Iterable<WorkspaceResourceDiagnostic> diagnostics,
) => {for (final item in diagnostics) item.resourceId: item}.values.toList();

class _DiagnosticPanel extends StatefulWidget {
  const _DiagnosticPanel({required this.visuals});
  final MapWorkspaceVisuals visuals;

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
      final diagnostics =
          _unique(widget.visuals.diagnostics)
              .where((item) => !activeOnly || active.contains(item.resourceId))
              .toList()
            ..sort(
              (a, b) => (active.contains(b.resourceId) ? 1 : 0).compareTo(
                active.contains(a.resourceId) ? 1 : 0,
              ),
            );
      final memory = diagnostics
          .where((item) => item.cause == WorkspaceResourceCause.memoryPressure)
          .toList();
      final rows =
          [
            for (final item in diagnostics)
              if (item.cause != WorkspaceResourceCause.memoryPressure) [item],
            if (memory.isNotEmpty) memory,
          ]..sort(
            (a, b) =>
                (b.any((item) => active.contains(item.resourceId)) ? 1 : 0)
                    .compareTo(
                      a.any((item) => active.contains(item.resourceId)) ? 1 : 0,
                    ),
          );
      final retryable = diagnostics.where((item) => item.canRetry).toList();
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
                  '${diagnostics.length} ressources concernées',
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
                            items: rows[index],
                            visuals: widget.visuals,
                            active: active,
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
                            retryable.map((item) => item.resourceId),
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
    required this.items,
    required this.visuals,
    required this.active,
  });
  final List<WorkspaceResourceDiagnostic> items;
  final MapWorkspaceVisuals visuals;
  final Set<String> active;

  @override
  Widget build(BuildContext context) {
    final item = items.first;
    final grouped = item.cause == WorkspaceResourceCause.memoryPressure;
    final title = grouped
        ? '${items.length} ressources · pression mémoire'
        : item.name;
    final retryable = items.where((item) => item.canRetry).toList();
    final onMap = items.any((item) => active.contains(item.resourceId));
    return Padding(
      key: ValueKey('resource-row-${grouped ? 'memory' : item.resourceId}'),
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
                const SizedBox(height: 3),
                Text(
                  item.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                    retryable.map((item) => item.resourceId),
                  ),
          ),
        ],
      ),
    );
  }
}
