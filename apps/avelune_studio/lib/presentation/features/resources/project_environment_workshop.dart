import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/resources/application/resource_catalog.dart';
import 'library/resource_library_map_usage_links.dart';
import 'project_library_resource_art.dart';

class ProjectEnvironmentWorkshop extends StatefulWidget {
  const ProjectEnvironmentWorkshop({
    super.key,
    required this.id,
    required this.name,
    required this.load,
    required this.onBack,
    required this.usages,
    required this.loadingMapUsages,
    required this.paletteName,
    this.visuals,
    this.onEdit,
    this.onOpenMap,
    this.trialMap,
    this.tryOnMap,
  });

  final String id, name;
  final Future<ProjectManifest> Function() load;
  final VoidCallback onBack;
  final Map<String, String>? usages;
  final bool loadingMapUsages;
  final String Function(EnvironmentPaletteItem) paletteName;
  final MapWorkspaceVisuals? visuals;
  final Future<bool> Function(EnvironmentPreset)? onEdit;
  final Future<bool> Function(String)? onOpenMap;
  final String? trialMap;
  final Future<bool> Function()? tryOnMap;

  @override
  State<ProjectEnvironmentWorkshop> createState() =>
      _ProjectEnvironmentWorkshopState();
}

class _ProjectEnvironmentWorkshopState
    extends State<ProjectEnvironmentWorkshop> {
  late var _reading = widget.load();
  bool _trying = false;

  Future<void> _edit(EnvironmentPreset preset) async {
    final updated = await widget.onEdit?.call(preset);
    if (mounted && updated == true) setState(() => _reading = widget.load());
  }

  Future<void> _try() async {
    if (_trying) return;
    setState(() => _trying = true);
    var opened = false;
    try {
      opened = await widget.tryOnMap!.call();
    } on Object {
      opened = false;
    } finally {
      if (mounted) {
        setState(() => _trying = false);
        if (!opened) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(
              content: Text(
                'Cet environnement ne peut pas être utilisé sur cette carte.',
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(StudioSpacing.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudioButton(
          label: 'Retour à la bibliothèque',
          icon: Icons.arrow_back,
          variant: StudioButtonVariant.quiet,
          onPressed: widget.onBack,
        ),
        const SizedBox(height: StudioSpacing.m),
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: StudioSpacing.m),
        Expanded(
          child: FutureBuilder<ProjectManifest>(
            future: _reading,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final project = snapshot.data;
              final environment = project == null
                  ? null
                  : findProjectEnvironmentPresetById(project, widget.id);
              if (project == null || environment == null) {
                return StudioEmptyState(
                  title: 'Impossible de lire l’environnement',
                  action: StudioButton(
                    label: 'Réessayer',
                    onPressed: () => setState(() => _reading = widget.load()),
                  ),
                );
              }
              return _details(project, environment);
            },
          ),
        ),
      ],
    ),
  );

  Widget _details(ProjectManifest project, EnvironmentPreset environment) {
    final palette = environment.palette;
    final first = palette.firstOrNull;
    final art = first == null || widget.visuals == null
        ? null
        : resourceCatalog(project)
              .where(
                (item) =>
                    item.id == first.resourceId &&
                    item.canonicalKind ==
                        (first.isSpatial ? 'model3d' : 'element'),
              )
              .firstOrNull;
    final usages = widget.usages;
    return ListView(
      children: [
        StudioPanel(
          title: 'Décors à répartir',
          icon: Icons.forest_outlined,
          children: [
            if (art != null)
              Align(
                alignment: Alignment.centerLeft,
                child: ProjectLibraryResourceArt(
                  item: art,
                  project: project,
                  visuals: widget.visuals!,
                  size: 144,
                  compact: false,
                ),
              ),
            for (final entry in palette)
              Text('${widget.paletteName(entry)} · Poids ${entry.weight}'),
            Text(
              'Densité ${(environment.defaultParams.density * 100).round()} %',
            ),
            if (widget.onEdit != null)
              Align(
                alignment: Alignment.centerLeft,
                child: StudioButton(
                  label: 'Modifier l’environnement',
                  onPressed: () => _edit(environment),
                ),
              ),
          ],
        ),
        const SizedBox(height: StudioSpacing.m),
        StudioPanel(
          title: 'Utilisation dans les cartes',
          icon: Icons.map_outlined,
          children: [
            ResourceLibraryMapUsageLinks(
              key: ValueKey(widget.id),
              mapIds: usages?.keys ?? const [],
              maps: usages ?? const {},
              emptyLabel: switch ((usages, widget.loadingMapUsages)) {
                (null, true) => 'Calcul des usages par carte…',
                (null, false) => 'Usages indisponibles.',
                _ => 'Aucune carte ne l’utilise.',
              },
              onOpenMap: widget.onOpenMap,
            ),
            if (widget.trialMap case final name?)
              Align(
                alignment: Alignment.centerLeft,
                child: StudioButton(
                  label: 'Essayer sur $name',
                  icon: Icons.map_outlined,
                  variant: StudioButtonVariant.secondary,
                  onPressed: _trying || widget.tryOnMap == null ? null : _try,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
