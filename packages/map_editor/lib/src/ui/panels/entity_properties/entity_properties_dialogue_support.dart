part of 'package:map_editor/src/ui/panels/entity_properties_panel.dart';

/// Source du dialogue sur une entité NPC / panneau.
///
/// Ce type reste volontairement local au panneau : c'est un détail de binding
/// UI entre le registre projet moderne et les anciennes références par chemin.
enum _DialogueRefSource { none, manifest, legacy }

const _kDialogueNoneMenuId = '__dialogue_none__';
const _kNodeNoneMenuId = '__yarn_node_none__';
const _kElementNoneMenuId = '__entity_element_none__';
const _kTrainerNoneMenuId = '__entity_trainer_none__';
const _kCharacterNoneMenuId = '__entity_character_none__';

String _normalizeDialogueRelPath(String raw) {
  return raw.trim().replaceAll(r'\', '/');
}

Future<List<String>> _extractYarnNodeTitles(String absolutePath) async {
  try {
    final file = File(absolutePath);
    if (!await file.exists()) return const [];
    final lines = await file.readAsLines();
    return [
      for (final line in lines)
        if (line.trim().startsWith('title:'))
          line.trim().substring('title:'.length).trim(),
    ].where((title) => title.isNotEmpty).toList();
  } catch (_) {
    return const [];
  }
}

ProjectDialogueEntry? _dialogueEntryForLegacyPath(
  List<ProjectDialogueEntry> entries,
  String scriptPathRelative,
) {
  final normalizedPath = _normalizeDialogueRelPath(scriptPathRelative);
  if (normalizedPath.isEmpty) {
    return null;
  }
  for (final entry in entries) {
    if (_normalizeDialogueRelPath(entry.relativePath) == normalizedPath) {
      return entry;
    }
  }
  return null;
}
