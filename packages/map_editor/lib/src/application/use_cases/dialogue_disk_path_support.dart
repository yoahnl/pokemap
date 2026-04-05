import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../errors/application_errors.dart';
import '../ports/project_workspace.dart';

/// Slug de segment de chemin (dossier affiché ou fichier), cohérent avec
/// [generateUniqueDialogueId] / [generateUniqueDialogueFolderId].
String slugifyDialoguePathSegment(String rawName) {
  final normalized = rawName
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return normalized.isEmpty ? 'folder' : normalized;
}

String? _normParent(String? parentFolderId) {
  final t = parentFolderId?.trim();
  if (t == null || t.isEmpty) return null;
  return t;
}

/// Segments disque **uniques par fratrie**, déterministes (sortOrder puis id).
///
/// Clé = [ProjectDialogueFolder.id], valeur = nom de dossier réel sous le parent.
Map<String, String> computeDialogueFolderDiskSegments(ProjectManifest project) {
  final result = <String, String>{};
  final byParent = <String?, List<ProjectDialogueFolder>>{};
  for (final f in project.dialogueFolders) {
    byParent.putIfAbsent(_normParent(f.parentFolderId), () => []).add(f);
  }
  for (final list in byParent.values) {
    list.sort((a, b) {
      final o = a.sortOrder.compareTo(b.sortOrder);
      if (o != 0) return o;
      return a.id.compareTo(b.id);
    });
  }

  void assignLevel(String? parentId) {
    final children = byParent[parentId] ?? const <ProjectDialogueFolder>[];
    final used = <String>{};
    for (final child in children) {
      final base = slugifyDialoguePathSegment(child.name);
      var cand = base;
      var n = 2;
      while (used.contains(cand)) {
        cand = '${base}_$n';
        n++;
      }
      used.add(cand);
      result[child.id] = cand;
      assignLevel(child.id);
    }
  }

  assignLevel(null);
  return result;
}

/// Chemin projet relatif POSIX du répertoire représentant le dossier [folderId]
/// (ex. `dialogues/chapitre_1/maman`), sans slash final.
String dialogueFolderDirectoryRelativePath(
  ProjectManifest project,
  Map<String, String> segments,
  String folderId,
) {
  final byId = {for (final f in project.dialogueFolders) f.id: f};
  var cur = byId[folderId];
  if (cur == null) {
    throw EditorNotFoundException('Dialogue folder not found: $folderId');
  }
  final stack = <String>[];
  while (true) {
    final seg = segments[cur!.id];
    if (seg == null) {
      throw EditorValidationException(
        'Missing disk segment for folder ${cur.id}',
      );
    }
    stack.add(seg);
    final pid = _normParent(cur.parentFolderId);
    if (pid == null) break;
    cur = byId[pid];
    if (cur == null) {
      throw EditorValidationException('Broken folder parent chain at $pid');
    }
  }
  var out = kProjectDialoguesRelativeDir;
  for (var i = stack.length - 1; i >= 0; i--) {
    out = p.posix.join(out, stack[i]);
  }
  return out;
}

/// Répertoire où placer un fichier dialogue : racine `dialogues` ou sous-arbre dossier.
String dialogueFileParentDirectoryRelativePath(
  ProjectManifest project,
  Map<String, String> segments,
  String? folderId,
) {
  final fid = folderId?.trim();
  if (fid == null || fid.isEmpty) return kProjectDialoguesRelativeDir;
  return dialogueFolderDirectoryRelativePath(project, segments, fid);
}

/// Chemin relatif attendu pour `dialogues/.../id.ext` (ext = `.yarn` ou `.txt`).
String expectedDialogueFileRelativePath(
  ProjectManifest project,
  Map<String, String> segments,
  String? folderId,
  String dialogueId,
  String extensionWithDot,
) {
  final parentDir =
      dialogueFileParentDirectoryRelativePath(project, segments, folderId);
  final ext = extensionWithDot.startsWith('.')
      ? extensionWithDot.toLowerCase()
      : '.$extensionWithDot'.toLowerCase();
  return p.posix.join(parentDir, '$dialogueId$ext');
}

/// Remplace le préfixe POSIX [oldPrefix] par [newPrefix] pour les chemins sous ce préfixe.
String? rewritePathPrefix(String relativePath, String oldPrefix, String newPrefix) {
  final norm = relativePath.replaceAll(r'\', '/');
  final op = oldPrefix.replaceAll(r'\', '/');
  final np = newPrefix.replaceAll(r'\', '/');
  if (norm.startsWith('$op/')) {
    return p.posix.join(np, norm.substring(op.length + 1));
  }
  if (norm == op) {
    return np;
  }
  return null;
}

Future<void> assertDestinationFileAvailable(
  ProjectWorkspace ws,
  String relativePath,
) async {
  final abs = ws.resolveProjectRelativePath(relativePath);
  if (await File(abs).exists()) {
    throw EditorValidationException(
      'Target file already exists: $relativePath',
    );
  }
}

/// Déplace un fichier projet (crée les dossiers parents).
Future<void> moveProjectRelativeFile(
  ProjectWorkspace ws,
  String fromRelative,
  String toRelative,
) async {
  final fromAbs = ws.resolveProjectRelativePath(fromRelative);
  final toAbs = ws.resolveProjectRelativePath(toRelative);
  final fromF = File(fromAbs);
  if (!await fromF.exists()) {
    throw EditorValidationException(
      'Cannot move dialogue file: missing source $fromRelative',
    );
  }
  if (await File(toAbs).exists()) {
    throw EditorValidationException(
      'Cannot move dialogue file: destination exists $toRelative',
    );
  }
  await Directory(p.dirname(toAbs)).create(recursive: true);
  try {
    await fromF.rename(toAbs);
  } on FileSystemException {
    await fromF.copy(toAbs);
    await fromF.delete();
  }
}

/// Renomme / déplace un répertoire projet (préfixes relatifs POSIX).
Future<void> moveProjectRelativeDirectory(
  ProjectWorkspace ws,
  String fromDirRelative,
  String toDirRelative,
) async {
  final fromAbs = ws.resolveProjectRelativePath(fromDirRelative);
  final toAbs = ws.resolveProjectRelativePath(toDirRelative);
  final fromD = Directory(fromAbs);
  if (!await fromD.exists()) {
    return;
  }
  if (await Directory(toAbs).exists()) {
    throw EditorValidationException(
      'Cannot move dialogue folder: target exists $toDirRelative',
    );
  }
  await Directory(p.dirname(toAbs)).create(recursive: true);
  try {
    await fromD.rename(toAbs);
  } on FileSystemException {
    await _copyDirectoryRecursive(fromD, Directory(toAbs));
    await fromD.delete(recursive: true);
  }
}

Future<void> _copyDirectoryRecursive(Directory from, Directory to) async {
  await to.create(recursive: true);
  await for (final entity in from.list(recursive: false)) {
    final name = p.basename(entity.path);
    if (entity is File) {
      await entity.copy(p.join(to.path, name));
    } else if (entity is Directory) {
      await _copyDirectoryRecursive(entity, Directory(p.join(to.path, name)));
    }
  }
}

/// Supprime un répertoire vide s’il existe (pas d’erreur si absent).
Future<void> deleteEmptyProjectRelativeDirectory(
  ProjectWorkspace ws,
  String dirRelative,
) async {
  final abs = ws.resolveProjectRelativePath(dirRelative);
  final d = Directory(abs);
  if (!await d.exists()) return;
  try {
    await d.delete(recursive: false);
  } on FileSystemException {
    // non vide ou verrou : ignorer — le manifeste reste la source d’interdiction
  }
}

/// Crée le répertoire du dossier logique sur disque (après ajout au manifeste).
Future<void> ensureDialogueFolderDirectoryExists(
  ProjectWorkspace ws,
  ProjectManifest project,
  Map<String, String> segments,
  String folderId,
) async {
  final rel = dialogueFolderDirectoryRelativePath(project, segments, folderId);
  final abs = ws.resolveProjectRelativePath(rel);
  await Directory(abs).create(recursive: true);
}
