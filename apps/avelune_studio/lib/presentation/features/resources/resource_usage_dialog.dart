import 'package:flutter/material.dart';

import '../../../features/resources/domain/resource_usage_port.dart';
import '../../../features/resources/application/resource_usage_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';

import 'resource_usage_results.dart';

class ResourceUsageDialog extends StatefulWidget {
  const ResourceUsageDialog({
    super.key,
    this.item,
    this.target,
    this.name,
    required this.port,
    required this.changes,
    required this.dirtyOwners,
    required this.onOpen,
    required this.canOpen,
    this.replaceUsages,
  }) : assert(item != null || (target != null && name != null));
  final ResourceItem? item;
  final ResourceUsageTarget? target;
  final String? name;
  ResourceUsageTarget get resolvedTarget =>
      target ?? resourceUsageTargetFor(item!);
  final ResourceUsagePort port;
  final Listenable changes;
  final List<String> Function() dirtyOwners;
  final Future<bool> Function(ResourceUsageEntry entry) onOpen;
  final bool Function(ResourceUsageEntry entry) canOpen;
  final Future<String?> Function(ResourceUsageReport report)? replaceUsages;

  @override
  State<ResourceUsageDialog> createState() => _ResourceUsageDialogState();
}

class _ResourceUsageDialogState extends State<ResourceUsageDialog> {
  late final ResourceUsageController controller;

  @override
  void initState() {
    super.initState();
    controller = ResourceUsageController(
      target: widget.resolvedTarget,
      port: widget.port,
      dirtyOwners: () => widget.dirtyOwners(),
      openOwner: (entry) => widget.onOpen(entry),
      canOpenOwner: (entry) => widget.canOpen(entry),
      replace: widget.replaceUsages,
      changed: _changed,
    );
    widget.changes.addListener(controller.invalidate);
  }

  @override
  void dispose() {
    widget.changes.removeListener(controller.invalidate);
    controller.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _open(ResourceUsageEntry entry) async {
    if (await controller.open(entry) && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dirty = widget.dirtyOwners();
    final phase = controller.phase;
    final status = switch (phase) {
      ResourceUsagePhase.notAnalyzed => 'Non analysé',
      ResourceUsagePhase.analyzing => 'Analyse en cours',
      ResourceUsagePhase.complete => 'Complet pour la révision identifiée',
      ResourceUsagePhase.stale => 'Résultat périmé · relancez l’analyse',
      ResourceUsagePhase.cancelled =>
        controller.working
            ? 'Analyse annulée · nettoyage en cours'
            : 'Analyse annulée',
      ResourceUsagePhase.incomplete => 'Analyse incomplète',
    };
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: MediaQuery.sizeOf(context).height - 40,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Usages dans le projet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(widget.name ?? widget.item!.name),
              const SizedBox(height: 8),
              Text(status, key: const ValueKey('resource-usage-status')),
              if (controller.error != null)
                Text(
                  controller.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (controller.notice != null)
                Text(
                  controller.notice!,
                  key: const ValueKey('resource-usage-replacement-notice'),
                ),
              if (controller.working) const LinearProgressIndicator(),
              const SizedBox(height: 12),
              Expanded(
                child: ResourceUsageResults(
                  report: controller.report,
                  error: null,
                  dirtyOwners: dirty,
                  stale: phase == ResourceUsagePhase.stale,
                  onOpen: _open,
                  canOpen: controller.canOpen,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (controller.working)
                    StudioButton(
                      label: 'Annuler l’analyse',
                      secondary: true,
                      onPressed: controller.cancelled
                          ? null
                          : controller.cancel,
                    ),
                  StudioButton(
                    label: 'Retour aux ressources',
                    secondary: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                  if (controller.replaceable)
                    StudioButton(
                      key: const ValueKey('resource-usage-replace'),
                      label: 'Remplacer ses usages…',
                      icon: Icons.swap_horiz,
                      secondary: true,
                      onPressed: controller.canReplace
                          ? controller.replaceUsages
                          : null,
                    ),
                  StudioButton(
                    key: const ValueKey('resource-usage-analyze'),
                    label: controller.report == null
                        ? 'Analyser les usages'
                        : 'Actualiser',
                    onPressed: controller.working ? null : controller.analyze,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
