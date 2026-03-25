import '../exceptions/map_exceptions.dart';

/// Préfixe obligatoire des chemins de dialogue dans le projet (dossier dédié).
const String kProjectDialoguesRelativeDir = 'dialogues';

/// Vérifie la forme d’un titre de nœud (Yarn / autre) sans parser le moteur.
bool isValidDialogueStartNode(String? raw) {
  if (raw == null) return true;
  final s = raw.trim();
  if (s.isEmpty) return true;
  if (s.length > 256) return false;
  if (s.contains('\n') || s.contains('\r')) return false;
  return RegExp(r'^[\w\-. ]+$').hasMatch(s);
}

void assertValidDialogueStartNode(String? raw, {required String contextLabel}) {
  if (!isValidDialogueStartNode(raw)) {
    throw ValidationException(
      '$contextLabel: invalid startNode (use letters, numbers, spaces, - or .; max 256 chars)',
    );
  }
}

/// Règles sur [ProjectDialogueEntry.relativePath] : relatif, sous `dialogues/`, sans `..`.
void assertValidProjectDialogueRelativePath(String path, {required String dialogueId}) {
  final p = path.trim();
  if (p.isEmpty) {
    throw ValidationException('Dialogue $dialogueId has an empty relativePath');
  }
  if (p.startsWith('/') || p.startsWith(r'\')) {
    throw ValidationException('Dialogue $dialogueId relativePath must not be absolute');
  }
  if (p.contains('..')) {
    throw ValidationException('Dialogue $dialogueId relativePath must not contain ..');
  }
  final norm = p.replaceAll(r'\', '/');
  if (!norm.startsWith('$kProjectDialoguesRelativeDir/')) {
    throw ValidationException(
      'Dialogue $dialogueId relativePath must start with "$kProjectDialoguesRelativeDir/"',
    );
  }
}
