import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../shared/widgets/layout/studio_section.dart';
import 'package:avelune_studio/features/map_workspace/application/map_library_tree.dart';
import 'package:avelune_studio/features/regional_map/application/regional_map_choices.dart';

class RegionalMapLinkedMaps extends StatefulWidget {
  const RegionalMapLinkedMaps({
    super.key,
    required this.project,
    required this.mapIds,
    required this.discovery,
    required this.busy,
    required this.onChanged,
  });

  final ProjectManifest project;
  final List<String> mapIds;
  final ProjectRegionPointDiscovery discovery;
  final bool busy;
  final ValueChanged<List<String>> onChanged;

  @override
  State<RegionalMapLinkedMaps> createState() => _RegionalMapLinkedMapsState();
}

class _RegionalMapLinkedMapsState extends State<RegionalMapLinkedMaps> {
  final _search = TextEditingController();
  var _query = '';

  static const _limit = regionalLinkCandidateLimit;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final folders = mapLibraryFolderLabels(widget.project.groups);
    final maps = {for (final map in widget.project.maps) map.id: map};
    final linked = widget.mapIds;
    final lastLocked = regionalLastLinkedLocked(linked, widget.discovery);
    final needle = _query.trim().toLowerCase();
    final candidates = regionalLinkCandidates(
      project: widget.project,
      linked: linked,
      folders: folders,
      query: _query,
    );
    final textTheme = Theme.of(context).textTheme;
    return StudioSection(
      title: 'Cartes liées à la visite du lieu',
      children: [
        const Text(
          'Vol exige une visite réelle, même si le lieu est connu dès le départ.',
        ),
        const SizedBox(height: 8),
        Text(
          linked.isEmpty
              ? 'Aucune carte liée.'
              : '${linked.length} ${linked.length > 1 ? 'cartes liées' : 'carte liée'}',
          style: textTheme.titleSmall,
        ),
        for (final id in linked)
          StudioChoice(
            key: ValueKey('regional-linked-$id'),
            dense: true,
            label: maps[id] == null
                ? 'Carte introuvable conservée : $id'
                : regionalMapChoiceLabel(maps[id]!, folders),
            trailing: StudioTool(
              key: ValueKey('regional-remove-$id'),
              label: lastLocked
                  ? 'Retrait impossible : dernière carte liée'
                  : 'Retirer cette carte',
              icon: Icons.link_off,
              onPressed: widget.busy || lastLocked
                  ? null
                  : () => widget.onChanged([
                      for (final value in linked)
                        if (value != id) value,
                    ]),
            ),
            onTap: null,
          ),
        if (lastLocked)
          const StudioNotice(
            key: ValueKey('regional-linked-last-reason'),
            'Un lieu découvert par visite doit garder au moins une carte liée. Choisissez « Connu dès le départ » dans Découverte pour retirer la dernière.',
          ),
        const SizedBox(height: 10),
        StudioSearchField(
          key: const ValueKey('regional-linked-search'),
          controller: _search,
          label: 'Ajouter une carte',
          hint: 'Nom ou dossier',
          onChanged: (value) => setState(() => _query = value),
        ),
        for (final map in candidates.take(_limit))
          StudioChoice(
            key: ValueKey('regional-add-${map.id}'),
            label: map.name,
            subtitle: folders[map.groupId] ?? 'Sans dossier',
            leading: const Icon(Icons.add_link, size: 18),
            onTap: widget.busy
                ? null
                : () {
                    _search.clear();
                    setState(() => _query = '');
                    widget.onChanged([...linked, map.id]);
                  },
          ),
        if (needle.isNotEmpty && candidates.isEmpty)
          const Text('Aucune carte ne correspond.'),
        if (candidates.length > _limit)
          Text(
            '${candidates.length - _limit} autres cartes : précisez la recherche.',
            style: textTheme.bodySmall,
          ),
      ],
    );
  }
}
