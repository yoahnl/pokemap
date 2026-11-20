import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/rendering/contracts/character_workspace_visuals.dart';
import '../../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/rendering/contracts/scoped_resource_preview_visuals.dart';
import '../../../features/resources/application/project_resource_library.dart';
import '../../../features/resources/application/project_resource_preview.dart';
import '../../../features/resources/application/resource_preview_source.dart';

part 'project_character_workshop_preview.dart';

class ProjectCharacterWorkshop extends StatefulWidget {
  const ProjectCharacterWorkshop({
    super.key,
    required this.item,
    required this.previews,
    required this.visuals,
    required this.active,
    required this.onBack,
    this.onRename,
  });

  final ProjectLibraryItem item;
  final ProjectResourcePreviews previews;
  final MapWorkspaceVisuals? visuals;
  final bool active;
  final VoidCallback onBack;
  final Future<void> Function()? onRename;

  @override
  State<ProjectCharacterWorkshop> createState() =>
      _ProjectCharacterWorkshopState();
}

class _ProjectCharacterWorkshopState extends State<ProjectCharacterWorkshop> {
  late var _lease = widget.previews.acquire(widget.item);

  @override
  void didUpdateWidget(ProjectCharacterWorkshop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.identity != widget.item.identity ||
        oldWidget.previews != widget.previews) {
      _read();
    }
  }

  void _read() {
    _lease.release();
    _lease = widget.previews.acquire(widget.item);
  }

  @override
  void dispose() {
    _lease.release();
    super.dispose();
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
            Text('Personnages', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
      const Divider(height: 1),
      Expanded(
        child: FutureBuilder<ProjectResourcePreview?>(
          future: _lease.result,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Chargement du personnage',
                ),
              );
            }
            if (snapshot.hasError) {
              return StudioEmptyState(
                title: 'Impossible de lire le personnage',
                action: StudioButton(
                  label: 'Réessayer',
                  onPressed: () => setState(_read),
                ),
              );
            }
            final result = snapshot.data;
            final character = result?.item.character;
            if (result == null || character == null) {
              return const StudioEmptyState(title: 'Personnage introuvable');
            }
            return _details(context, character, result.project);
          },
        ),
      ),
    ],
  );

  Widget _details(
    BuildContext context,
    ProjectCharacterEntry character,
    ProjectManifest project,
  ) => ListView(
    padding: const EdgeInsets.all(StudioSpacing.xl),
    children: [
      Wrap(
        spacing: StudioSpacing.l,
        runSpacing: StudioSpacing.m,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(widget.item.name, style: Theme.of(context).textTheme.titleLarge),
          if (widget.onRename case final rename?)
            StudioButton(
              label: 'Renommer',
              icon: Icons.edit_outlined,
              onPressed: rename,
              variant: StudioButtonVariant.secondary,
            ),
        ],
      ),
      const SizedBox(height: StudioSpacing.xl),
      _CharacterWorkshopPreview(
        key: ValueKey(character.id),
        active: widget.active,
        character: character,
        project: project,
        visuals: widget.visuals,
      ),
    ],
  );
}
