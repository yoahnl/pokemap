import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/map_destination_choices.dart';

export '../../../features/map_workspace/application/map_destination_choices.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../theme/studio_tokens.dart';

Future<String?> showMapDestinationPicker(
  BuildContext context,
  ProjectManifest project, {
  String? excludeMapId,
  String? selectedId,
}) => showDialog<String>(
  context: context,
  builder: (_) => _MapDestinationPicker(
    project: project,
    excludeMapId: excludeMapId,
    selectedId: selectedId,
  ),
);

class _MapDestinationPicker extends StatefulWidget {
  const _MapDestinationPicker({
    required this.project,
    required this.excludeMapId,
    required this.selectedId,
  });

  final ProjectManifest project;
  final String? excludeMapId, selectedId;

  @override
  State<_MapDestinationPicker> createState() => _MapDestinationPickerState();
}

class _MapDestinationPickerState extends State<_MapDestinationPicker> {
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
    final choices = mapDestinationChoices(
      widget.project,
      excludeMapId: widget.excludeMapId,
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
              Text('Carte d’arrivée', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Cherchez par nom de carte ou de dossier.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              StudioSearchField(
                key: const ValueKey('map-destination-search-field'),
                controller: _query,
                focusNode: _focus,
                label: 'Rechercher une carte',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Text(
                '${choices.length} ${choices.length > 1 ? 'cartes' : 'carte'}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: choices.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune carte ne correspond à cette recherche.',
                        ),
                      )
                    : ListView.builder(
                        itemCount: choices.length,
                        itemBuilder: (context, index) {
                          final choice = choices[index];
                          return StudioChoice(
                            key: ValueKey('map-destination-${choice.map.id}'),
                            label: choice.map.name,
                            subtitle: choice.folderPath,
                            leading: const Icon(Icons.map_outlined, size: 18),
                            selected: choice.map.id == widget.selectedId,
                            onTap: () =>
                                Navigator.of(context).pop(choice.map.id),
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
