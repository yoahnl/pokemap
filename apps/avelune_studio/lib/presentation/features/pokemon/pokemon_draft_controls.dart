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
    final value = _read(path);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: StudioDraftField(
        key: ValueKey('${family.name}-${path.join('.')}'),
        label: label,
        value: value?.toString() ?? '',
        lines: lines,
        onChanged: (text) =>
            controller.edit(family, (json) => _write(json, path, text)),
      ),
    );
  }

  Widget toggle(String label, List<String> path) => StudioToggleRow(
    label: label,
    value: _read(path) == true,
    onChanged: (value) =>
        controller.edit(family, (json) => _write(json, path, value)),
  );

  Object? _read(List<String> path) {
    Object? value = data;
    for (final segment in path) {
      if (value is! Map) return null;
      value = value[segment];
    }
    return value;
  }

  void _write(Map<String, dynamic> json, List<String> path, Object? value) {
    Map<String, dynamic> current = json;
    for (final segment in path.take(path.length - 1)) {
      final next = current[segment];
      if (next is Map<String, dynamic>) {
        current = next;
      } else {
        final created = <String, dynamic>{};
        current[segment] = created;
        current = created;
      }
    }
    current[path.last] = value;
  }
}
