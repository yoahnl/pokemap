import '../../../features/pokemon/application/pokemon_document_editing.dart';

import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';

class PokemonDraftControls {
  const PokemonDraftControls(this.controller, this.family);

  final PokemonWorkspaceController controller;
  final PokemonDocumentFamily family;

  Map<String, dynamic> get data => controller.selectedDraft!.document(family)!;

  Widget text(String label, List<String> path, {int lines = 1}) {
    final value = PokemonDocumentEditing.read(data, path);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: StudioDraftField(
        key: ValueKey('${family.name}-${path.join('.')}'),
        label: label,
        value: value?.toString() ?? '',
        lines: lines,
        onChanged: (text) => controller.edit(
          family,
          (json) => PokemonDocumentEditing.write(json, path, text),
        ),
      ),
    );
  }

  Widget toggle(String label, List<String> path) => StudioToggleRow(
    label: label,
    value: PokemonDocumentEditing.read(data, path) == true,
    onChanged: (value) => controller.edit(
      family,
      (json) => PokemonDocumentEditing.write(json, path, value),
    ),
  );
}
