import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/cinematics/application/cinematic_workspace_controller.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'cinematic_view_state.dart';
import 'cinematic_library_thumbnail.dart';
import '../events/event_map_loader.dart';
import '../map_workspace/map_workspace_visuals.dart';

class CinematicLibrary extends StatelessWidget {
  const CinematicLibrary({
    super.key,
    required this.controller,
    required this.views,
    required this.changed,
    required this.onOpen,
    required this.onCreate,
    required this.loader,
    required this.visuals,
  });
  final CinematicWorkspaceController controller;
  final CinematicViewStore views;
  final VoidCallback changed, onCreate;
  final ValueChanged<String> onOpen;
  final EventMapLoader loader;
  final MapWorkspaceVisuals visuals;
  @override
  Widget build(BuildContext context) {
    final catalog = controller.project.cinematicLibraryCatalog;
    final entries = controller.entries.where((a) {
      final entry = catalog.entries
          .where(
            (e) =>
                e.family == CinematicLibraryFamily.world &&
                e.cinematicId == a.id,
          )
          .firstOrNull;
      final context =
          controller.project.maps
              .where((m) => m.id == a.mapId)
              .firstOrNull
              ?.name ??
          'Sans carte';
      return '${a.title} $context ${a.id}'.toLowerCase().contains(
            views.search.text.trim().toLowerCase(),
          ) &&
          (views.folderId.isEmpty ||
              (controller.session(a.id)?.folderId ?? entry?.folderId) ==
                  views.folderId) &&
          (views.archived || entry?.isArchived != true);
    }).toList();
    return StudioPanel(
      compact: true,
      title: 'Cinématiques',
      children: [
        StudioSearchField(
          controller: views.search,
          label: 'Rechercher une cinématique',
          hint: 'Nom, carte ou identifiant…',
          onChanged: (_) => changed(),
        ),
        const SizedBox(height: 12),
        StudioSelect(
          label: 'Dossier',
          value: views.folderId,
          options: {
            '': 'Toutes les cinématiques',
            for (final f in catalog.folders)
              if (f.family == CinematicLibraryFamily.world) f.id: f.name,
          },
          onChanged: (id) {
            views.folderId = id;
            changed();
          },
        ),
        const SizedBox(height: 8),
        StudioButton(
          label: views.archived ? 'Masquer les archives' : 'Voir les archives',
          secondary: true,
          icon: Icons.archive_outlined,
          onPressed: () {
            views.archived = !views.archived;
            changed();
          },
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final a = entries[i], s = controller.session(entries[i].id);
              return StudioChoice(
                key: ValueKey('cinematic-library-${a.id}'),
                label: a.title,
                selected: controller.activeId == a.id,
                leading: CinematicLibraryThumbnail(
                  mapId: a.mapId,
                  loader: loader,
                  visuals: visuals,
                ),
                subtitle:
                    '${controller.project.maps.where((m) => m.id == a.mapId).firstOrNull?.name ?? 'Sans carte'}\n${a.id} · ${a.timeline.steps.length} actions${s?.dirty == true ? ' · brouillon' : ''}',
                onTap: () => onOpen(a.id),
              );
            },
          ),
        ),
        StudioButton(
          label: 'Nouvelle cinématique',
          icon: Icons.add,
          onPressed: controller.busy ? null : onCreate,
        ),
      ],
    );
  }
}
