import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';

export '../../../features/regional_map/application/regional_map_summary.dart';

import '../../../features/regional_map/application/regional_map_choices.dart';
import '../../../features/regional_map/application/regional_map_summary.dart';

class RegionalPlaceFinder extends StatefulWidget {
  const RegionalPlaceFinder({
    super.key,
    required this.points,
    required this.project,
    required this.selectedId,
    required this.onSelected,
  });

  final List<ProjectRegionPointOfInterest> points;
  final ProjectManifest project;
  final String? selectedId;
  final ValueChanged<String>? onSelected;

  @override
  State<RegionalPlaceFinder> createState() => _RegionalPlaceFinderState();
}

class _RegionalPlaceFinderState extends State<RegionalPlaceFinder> {
  final _search = TextEditingController();
  var _query = '';

  static const _limit = regionalPlaceFinderLimit;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final needle = _query.trim().toLowerCase();
    final matches = regionalPlaceMatches(
      points: widget.points,
      project: widget.project,
      query: _query,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSearchField(
          key: const ValueKey('regional-place-search'),
          controller: _search,
          label: 'Rechercher un lieu',
          hint: 'Nom du lieu ou carte d’arrivée',
          onChanged: (value) => setState(() => _query = value),
        ),
        for (final point in matches.take(_limit))
          StudioChoice(
            key: ValueKey('regional-place-${point.id}'),
            label: point.label,
            subtitle:
                '${regionalPlaceVisibility(point)} · ${regionalPlaceFlight(point, widget.project)}',
            leading: const Icon(Icons.location_on_outlined, size: 18),
            selected: point.id == widget.selectedId,
            onTap: widget.onSelected == null
                ? null
                : () {
                    _search.clear();
                    setState(() => _query = '');
                    widget.onSelected!(point.id);
                  },
          ),
        if (needle.isNotEmpty && matches.isEmpty)
          const StudioNotice('Aucun lieu ne correspond à cette recherche.'),
        if (matches.length > _limit)
          Text(
            '${matches.length - _limit} autres lieux : précisez la recherche.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}
