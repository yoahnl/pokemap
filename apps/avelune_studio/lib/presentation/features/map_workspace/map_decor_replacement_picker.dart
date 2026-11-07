import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../theme/studio_tokens.dart';
import '../resources/resource_catalog.dart';
import 'map_border_review.dart';

List<ResourceItem> mapDecorReplacementChoices(
  ProjectManifest project, {
  required String mapId,
  required bool spatial,
  String query = '',
}) {
  final kind = spatial ? 'model3d' : 'element';
  final borderPieces = mapBorderPieceIdentities(project);
  return filterResourceCatalog(
    project,
    resourceCatalog(project).where(
      (item) =>
          item.canonicalKind == kind &&
          !borderPieces.contains('$kind:${item.id}'),
    ),
    ResourceCatalogFilterState(query: query),
    activeMapId: mapId,
    forMapPicker: true,
  );
}

Future<String?> showMapDecorReplacementPicker(
  BuildContext context,
  ProjectManifest project, {
  required String mapId,
  required bool spatial,
  required int count,
}) => showDialog<String>(
  context: context,
  builder: (_) => _MapDecorReplacementPicker(
    project: project,
    mapId: mapId,
    spatial: spatial,
    count: count,
  ),
);

class _MapDecorReplacementPicker extends StatefulWidget {
  const _MapDecorReplacementPicker({
    required this.project,
    required this.mapId,
    required this.spatial,
    required this.count,
  });

  final ProjectManifest project;
  final String mapId;
  final bool spatial;
  final int count;

  @override
  State<_MapDecorReplacementPicker> createState() =>
      _MapDecorReplacementPickerState();
}

class _MapDecorReplacementPickerState
    extends State<_MapDecorReplacementPicker> {
  final _query = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final choices = mapDecorReplacementChoices(
      widget.project,
      mapId: widget.mapId,
      spatial: widget.spatial,
      query: _query.text,
    );
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: (MediaQuery.sizeOf(context).height - 48).clamp(240, 600),
        ),
        child: Padding(
          padding: const EdgeInsets.all(StudioMetrics.panelPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.count > 1
                    ? 'Remplacer ces ${widget.count} décors ici'
                    : 'Remplacer ce décor ici',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Seules ces occurrences de la carte changent de ressource ; '
                'leur position est conservée et la ressource partagée n’est pas modifiée.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              StudioSearchField(
                key: const ValueKey('map-decor-replacement-search'),
                controller: _query,
                focusNode: _focus,
                label: 'Rechercher une ressource',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Text(
                '${choices.length} ${choices.length > 1 ? 'ressources prêtes' : 'ressource prête'}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: choices.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune ressource prête ne correspond à cette recherche.',
                        ),
                      )
                    : ListView.builder(
                        itemCount: choices.length,
                        itemBuilder: (context, index) {
                          final choice = choices[index];
                          return StudioChoice(
                            key: ValueKey('map-decor-replacement-${choice.id}'),
                            label: choice.name,
                            subtitle: choice.category.isEmpty
                                ? null
                                : choice.category,
                            leading: Icon(
                              widget.spatial
                                  ? Icons.view_in_ar_outlined
                                  : Icons.image_outlined,
                              size: 18,
                            ),
                            onTap: () => Navigator.of(context).pop(choice.id),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: StudioButton(
                  label: 'Annuler',
                  secondary: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
