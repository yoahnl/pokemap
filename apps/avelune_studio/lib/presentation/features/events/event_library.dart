import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../shared/widgets/inputs/studio_tabs.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'event_labels.dart';
import 'event_view_state.dart';
import 'event_legacy_catalog.dart';
import 'event_legacy_detail.dart';
import '../../shared/widgets/feedback/studio_icon_tile.dart';

class EventLibrary extends StatefulWidget {
  const EventLibrary({
    super.key,
    required this.project,
    required this.records,
    required this.activeId,
    required this.dirtyIds,
    required this.view,
    required this.onChanged,
    required this.onOpen,
    required this.onCreate,
    this.maps = const [],
    this.mapsComplete = false,
    this.onLoadHistory,
  });
  final ProjectManifest project;
  final List<NarrativeEventRecord> records;
  final String? activeId;
  final Set<String> dirtyIds;
  final EventViewState view;
  final VoidCallback onChanged, onCreate;
  final ValueChanged<String> onOpen;
  final List<MapData> maps;
  final bool mapsComplete;
  final VoidCallback? onLoadHistory;

  @override
  State<EventLibrary> createState() => _EventLibraryState();
}

class _EventLibraryState extends State<EventLibrary> {
  EventLegacyCatalog? _legacy;

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final records = widget.records;
    final view = widget.view;
    final activeId = widget.activeId;
    final dirtyIds = widget.dirtyIds;
    final onChanged = widget.onChanged;
    final onOpen = widget.onOpen;
    final onCreate = widget.onCreate;
    if (_legacy?.matches(project, widget.maps) != true) {
      _legacy = EventLegacyCatalog(project, widget.maps);
    }
    final query = view.search.text.toLowerCase().trim();
    final filtered = records.where((r) {
      final source = eventSource(r);
      final mapId = eventMapId(source);
      return (!view.onMapOnly || mapId != null && mapId == view.filterMapId) &&
          '${eventName(r)} ${r.id} ${eventKindLabel(source?.kind)} ${eventTargetId(source)} ${eventMapLabel(project, mapId)}'
              .toLowerCase()
              .contains(query);
    }).toList();
    final historical = _legacy!.entries
        .where(
          (entry) =>
              (!view.onMapOnly ||
                  entry.mapId != null && entry.mapId == view.filterMapId) &&
              '${entry.name} ${entry.key} ${eventMapLabel(project, entry.mapId)}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    return StudioPanel(
      compact: true,
      children: [
        Expanded(
          child: CustomScrollView(
            controller: view.scroll,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StudioTabs(
                      items: const {false: 'Tous', true: 'Sur cette carte'},
                      selected: view.onMapOnly,
                      onChanged: (value) {
                        view.onMapOnly = value;
                        onChanged();
                      },
                    ),
                    const SizedBox(height: 12),
                    StudioSearchField(
                      controller: view.search,
                      label: 'Rechercher un événement',
                      onChanged: (_) => onChanged(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      view.onMapOnly
                          ? eventMapLabel(project, view.filterMapId)
                          : '${records.length} événements',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (activeId != null &&
                        !filtered.any((r) => r.id == activeId))
                      const StudioNotice('Événement ouvert hors filtre'),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              SliverList.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final record = filtered[index];
                  final source = eventSource(record);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Tooltip(
                      message:
                          '${record.id}\n${eventTargetId(source) ?? eventKindLabel(source?.kind)}',
                      child: StudioChoice(
                        key: ValueKey('event-library:${record.id}'),
                        label: eventName(record),
                        selected: activeId == record.id,
                        tone: eventKindTone(source?.kind),
                        leading: StudioIconTile(
                          icon: eventKindIcon(source?.kind),
                          tone: eventKindTone(source?.kind),
                          size: 40,
                        ),
                        subtitle:
                            '${eventMapLabel(project, eventMapId(source))}\n${dirtyIds.contains(record.id) ? 'Modifications locales' : eventStateLabel(record)}',
                        onTap: () => onOpen(record.id),
                      ),
                    ),
                  );
                },
              ),
              if (filtered.isEmpty && historical.isEmpty)
                const SliverToBoxAdapter(
                  child: Text('Aucun événement dans cette recherche.'),
                ),
              if (historical.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Historique · ${historical.length}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
                SliverList.builder(
                  itemCount: historical.length,
                  itemBuilder: (context, index) {
                    final entry = historical[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: StudioChoice(
                        key: ValueKey('event-legacy:${entry.key}'),
                        label: entry.name,
                        leading: const Icon(Icons.history),
                        subtitle:
                            '${eventMapLabel(project, entry.mapId)}\nConsultation seule',
                        onTap: () => showLegacyEventDetail(context, entry),
                      ),
                    );
                  },
                ),
              ],
              if (!widget.mapsComplete)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Historique des cartes chargées. Le catalogue complet est disponible après préparation des sources.',
                    ),
                  ),
                ),
              if (!widget.mapsComplete && widget.onLoadHistory != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: StudioButton(
                      label: 'Charger l’historique des autres cartes',
                      secondary: true,
                      onPressed: widget.onLoadHistory,
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: StudioButton(
                    label: 'Nouvel événement',
                    icon: Icons.add,
                    onPressed: onCreate,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
