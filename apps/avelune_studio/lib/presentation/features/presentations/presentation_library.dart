import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/presentations/application/presentation_workspace_controller.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_resource_card.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';
import 'presentation_workspace_visuals.dart';
import 'presentation_library_elements.dart';
import 'presentation_view_state.dart';
import 'presentation_clip_labels.dart';

class PresentationLibrary extends StatelessWidget {
  const PresentationLibrary({
    super.key,
    required this.controller,
    required this.views,
    required this.changed,
    required this.onOpen,
    required this.onCreate,
    required this.onLayer,
    this.visuals,
    this.beforeSelection,
  });
  final PresentationWorkspaceController controller;
  final PresentationViewStore views;
  final PresentationWorkspaceVisuals? visuals;
  final bool Function()? beforeSelection;
  final VoidCallback changed, onCreate;
  final ValueChanged<String> onOpen;
  final void Function(String action, Map<String, Object?> params) onLayer;
  @override
  Widget build(BuildContext context) {
    final asset = controller.active?.asset;
    final view = asset == null ? null : views.forAsset(asset);
    final elements = view?.elements ?? false;
    final query = views.search.text.toLowerCase().trim();
    final entries = controller.entries
        .where(
          (a) =>
              a.title.toLowerCase().contains(query) &&
              (views.archived || !_archived(a.id)) &&
              (views.folderId.isEmpty || _folder(a.id) == views.folderId),
        )
        .toList();
    return StudioPanel(
      compact: true,
      children: [
        Row(
          children: [
            for (final tab in const {
              false: 'Cinématiques',
              true: 'Éléments',
            }.entries) ...[
              if (tab.key) const SizedBox(width: 6),
              Expanded(
                child: StudioButton(
                  label: tab.value,
                  secondary: elements != tab.key,
                  onPressed: () {
                    if (!(beforeSelection?.call() ?? true)) return;
                    if (view != null) view.elements = tab.key;
                    changed();
                  },
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (!elements) ...[
          TextField(
            controller: views.search,
            onChanged: (_) => changed(),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Rechercher une cinématique',
            ),
          ),
          const SizedBox(height: 10),
          StudioSelect(
            label: 'Dossier',
            value: views.folderId,
            options: {
              '': 'Tous les dossiers',
              for (final folder in controller.catalog.folders)
                if (folder.family == CinematicLibraryFamily.presentation)
                  folder.id: folder.name,
            },
            onChanged: (value) {
              views.folderId = value;
              changed();
            },
          ),
          StudioToggleRow(
            label: 'Archives',
            value: views.archived,
            onChanged: (value) {
              views.archived = value;
              changed();
            },
          ),
          if (asset != null && !entries.any((e) => e.id == asset.id))
            Text('Ouverte hors filtre : ${asset.title}', maxLines: 2),
          Expanded(
            child: ListView(
              children: [
                for (final entry in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      height: 186,
                      child: StudioResourceCard(
                        key: ValueKey('presentation-entry-${entry.id}'),
                        name: entry.title,
                        maxNameLines: 2,
                        selected: entry.id == asset?.id,
                        preview: _preview(
                          context,
                          entry,
                          entry.id == asset?.id,
                        ),
                        metadata:
                            '${presentationTime(entry.durationUs)} · ${entry.tracks.length} pistes${controller.session(entry.id)?.dirty == true ? ' • Brouillon' : ''}${_archived(entry.id) ? ' · Archive' : ''}',
                        onTap: () => onOpen(entry.id),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (asset != null && _archived(asset.id))
            StudioButton(
              label: 'Restaurer',
              icon: Icons.unarchive_outlined,
              secondary: true,
              onPressed: () async {
                if (!(beforeSelection?.call() ?? true)) return;
                await controller.setArchived(asset.id, false);
                changed();
              },
            ),
          StudioButton(
            label: 'Nouvelle cinématique',
            icon: Icons.add,
            onPressed: onCreate,
            secondary: true,
          ),
        ] else if (asset != null && view != null) ...[
          Expanded(
            child: PresentationLibraryElements(
              asset: asset,
              view: view,
              changed: changed,
              onLayer: onLayer,
              beforeSelection: beforeSelection,
            ),
          ),
        ],
      ],
    );
  }

  bool _archived(String id) =>
      controller.catalog
          .entryFor(CinematicLibraryFamily.presentation, id)
          ?.isArchived ??
      false;
  String? _folder(String id) {
    final session = controller.session(id);
    return session != null
        ? session.folderId
        : controller.catalog
              .entryFor(CinematicLibraryFamily.presentation, id)
              ?.folderId;
  }

  Widget _preview(
    BuildContext context,
    PresentationCinematicAsset asset,
    bool active,
  ) {
    if (!active || visuals == null) {
      return Center(
        child: Icon(
          Icons.auto_awesome_motion,
          size: 34,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    final clips =
        asset.tracks
            .expand((t) => t.clips)
            .where(
              (c) => c is PresentationVisualClip || c is PresentationTextClip,
            )
            .toList()
          ..sort((a, b) => a.startUs.compareTo(b.startUs));
    final time = clips.isEmpty
        ? 0
        : (clips.first.startUs +
                  (clips.first.durationUs ~/ 2).clamp(0, 1000000))
              .clamp(0, asset.durationUs);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: visuals!,
        builder: (context, _) => FittedBox(
          child: SizedBox(
            width: 960,
            height: 540,
            child: MediaQuery.withNoTextScaling(
              child: visuals!.frame(
                asset: asset,
                frame: const PresentationCinematicEvaluator().evaluate(
                  asset,
                  timeUs: time,
                ),
                portrait: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
