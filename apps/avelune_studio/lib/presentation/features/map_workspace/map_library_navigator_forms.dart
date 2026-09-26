import 'package:flutter/material.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';

class MapFolderCreationForm extends StatelessWidget {
  const MapFolderCreationForm({
    super.key,
    required this.name,
    required this.parent,
    required this.folders,
    required this.busy,
    required this.onName,
    required this.onParent,
    required this.onCancel,
    required this.onCreate,
  });

  final String name, parent;
  final Map<String, String> folders;
  final bool busy;
  final ValueChanged<String> onName, onParent;
  final VoidCallback onCancel, onCreate;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      StudioDraftField(value: name, label: 'Nom du dossier', onChanged: onName),
      StudioSelect(
        label: 'Dossier parent',
        value: parent,
        options: folders,
        onChanged: onParent,
      ),
      Row(
        children: [
          Expanded(
            child: StudioButton(
              label: 'Annuler',
              secondary: true,
              onPressed: onCancel,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: StudioButton(
              label: 'Créer',
              onPressed: busy ? null : onCreate,
            ),
          ),
        ],
      ),
    ],
  );
}

class MapFolderMoveForm extends StatelessWidget {
  const MapFolderMoveForm({
    super.key,
    required this.count,
    required this.destination,
    required this.folders,
    required this.busy,
    required this.onDestination,
    required this.onMove,
  });

  final int count;
  final String destination;
  final Map<String, String> folders;
  final bool busy;
  final ValueChanged<String> onDestination;
  final VoidCallback onMove;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('$count carte(s) sélectionnée(s)'),
      StudioSelect(
        label: 'Déplacer vers',
        value: destination,
        options: folders,
        onChanged: onDestination,
      ),
      StudioButton(
        label: 'Déplacer les cartes',
        icon: Icons.drive_file_move_outlined,
        onPressed: busy ? null : onMove,
      ),
    ],
  );
}
