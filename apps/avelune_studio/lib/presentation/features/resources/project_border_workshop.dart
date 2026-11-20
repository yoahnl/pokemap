import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/resources/application/border_workshop_assembly.dart';
import '../../../features/resources/application/project_resource_library.dart';
import 'project_border_workshop_preview.dart';

class ProjectBorderWorkshop extends StatefulWidget {
  const ProjectBorderWorkshop({
    super.key,
    required this.item,
    required this.loadProject,
    required this.visuals,
    required this.onBack,
  });

  final ProjectLibraryItem item;
  final Future<ProjectManifest> Function() loadProject;
  final MapWorkspaceVisuals? visuals;
  final VoidCallback onBack;

  @override
  State<ProjectBorderWorkshop> createState() => _ProjectBorderWorkshopState();
}

class _ProjectBorderWorkshopState extends State<ProjectBorderWorkshop> {
  late Future<ProjectManifest> _reading;
  final _assemblies = <bool, BorderWorkshopAssembly>{};
  var _draft = false;

  @override
  void initState() {
    super.initState();
    _read();
  }

  @override
  void didUpdateWidget(ProjectBorderWorkshop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.identity != oldWidget.item.identity) _read();
  }

  void _read() {
    _reading = Future.sync(widget.loadProject);
    _assemblies.clear();
    _draft = false;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: StudioSpacing.xl,
          vertical: StudioSpacing.l,
        ),
        child: Wrap(
          spacing: StudioSpacing.l,
          runSpacing: StudioSpacing.m,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StudioButton(
              label: 'Retour à la bibliothèque',
              icon: Icons.arrow_back,
              onPressed: widget.onBack,
              variant: StudioButtonVariant.quiet,
            ),
            Text('Bordures', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
      const Divider(height: 1),
      Expanded(
        child: FutureBuilder<ProjectManifest>(
          future: _reading,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Chargement de la bordure',
                ),
              );
            }
            if (snapshot.hasError) {
              return StudioEmptyState(
                title: 'Lecture de la bordure impossible',
                description:
                    'Vérifiez que sa fiche et ses pièces sont disponibles.',
                action: StudioButton(
                  label: 'Réessayer',
                  onPressed: () => setState(_read),
                ),
              );
            }
            final project = snapshot.data!;
            final record = project.borderCatalog.recordById(widget.item.id);
            if (record == null) {
              return const StudioEmptyState(
                title: 'Bordure introuvable',
                description:
                    'Actualisez la bibliothèque pour retrouver sa fiche.',
              );
            }
            return _content(context, project, record);
          },
        ),
      ),
    ],
  );

  Widget _content(
    BuildContext context,
    ProjectManifest project,
    BorderBlueprintRecord record,
  ) {
    final published = record.latestPublished;
    final showDraft = _draft || published == null;
    final definition = showDraft
        ? record.draft.definition
        : published.definition;
    final assembly = _assemblies.putIfAbsent(
      showDraft,
      () => buildBorderWorkshopAssembly(project, record, draft: showDraft),
    );
    return ListView(
      padding: const EdgeInsets.all(StudioSpacing.xl),
      children: [
        Text(definition.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: StudioSpacing.m),
        Wrap(
          spacing: StudioSpacing.s,
          runSpacing: StudioSpacing.s,
          children: [
            StudioBadge(definition.isSpatial ? '3D' : '2D'),
            if (published == null) const StudioBadge('Brouillon'),
            if (record.isDeprecated) const StudioBadge('Retirée'),
          ],
        ),
        if (published != null) ...[
          const SizedBox(height: StudioSpacing.l),
          StudioTabBar<bool>(
            selected: showDraft,
            onSelected: (value) => setState(() => _draft = value),
            tabs: [
              StudioTab(
                value: false,
                label: 'Publiée · v${published.revision}',
              ),
              const StudioTab(value: true, label: 'Brouillon'),
            ],
          ),
        ],
        const SizedBox(height: StudioSpacing.l),
        ProjectBorderWorkshopPreview(
          key: ValueKey(showDraft),
          assembly: assembly,
          visuals: widget.visuals,
        ),
      ],
    );
  }
}
