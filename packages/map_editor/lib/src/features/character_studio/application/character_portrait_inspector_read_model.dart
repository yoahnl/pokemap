import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'character_studio_media_resolver.dart';

enum CharacterPortraitSourceStatus { valid, missingPortrait, invalidSource }

final class CharacterPortraitDialogueUsage {
  const CharacterPortraitDialogueUsage({
    required this.dialogueId,
    required this.dialogueName,
    required this.lineNumber,
    required this.previewText,
  });

  final String dialogueId;
  final String dialogueName;
  final int lineNumber;
  final String previewText;
}

final class CharacterPortraitInspectorReadModel {
  CharacterPortraitInspectorReadModel({
    required this.definition,
    required this.portrait,
    required this.sourceStatus,
    required Iterable<CharacterPortraitDialogueUsage> usages,
    required Iterable<String> missingCharacterNames,
  }) : usages = List<CharacterPortraitDialogueUsage>.unmodifiable(usages),
       missingCharacterNames = List<String>.unmodifiable(missingCharacterNames);

  final CharacterPortraitStateDefinition definition;
  final CharacterPortraitVariant? portrait;
  final CharacterPortraitSourceStatus sourceStatus;
  final List<CharacterPortraitDialogueUsage> usages;
  final List<String> missingCharacterNames;

  int get dialogueCount =>
      usages.map((usage) => usage.dialogueId).toSet().length;

  String get previewText =>
      usages.firstOrNull?.previewText ?? 'Aperçu du dialogue';
}

abstract interface class CharacterPortraitDialogueSourceReader {
  Future<String?> read({
    required String projectRootPath,
    required String relativePath,
  });
}

final class FileCharacterPortraitDialogueSourceReader
    implements CharacterPortraitDialogueSourceReader {
  const FileCharacterPortraitDialogueSourceReader();

  @override
  Future<String?> read({
    required String projectRootPath,
    required String relativePath,
  }) async {
    final root = p.normalize(p.absolute(projectRootPath));
    final source = p.normalize(p.join(root, relativePath));
    if (!p.isWithin(root, source)) return null;
    final file = File(source);
    if (!await file.exists()) return null;
    try {
      return await file.readAsString();
    } on Object {
      return null;
    }
  }
}

final class CharacterPortraitInspectorReadModelLoader {
  const CharacterPortraitInspectorReadModelLoader({
    required this.mediaResolver,
    required this.dialogueSourceReader,
  });

  final CharacterStudioMediaResolverContract mediaResolver;
  final CharacterPortraitDialogueSourceReader dialogueSourceReader;

  Future<CharacterPortraitInspectorReadModel> load({
    required ProjectManifest project,
    required ProjectCharacterEntry character,
    required String portraitStateId,
    required String projectRootPath,
    required String projectRevision,
  }) async {
    final definition = project.characterStudioCatalog.portraitStates
        .where((state) => state.id == portraitStateId)
        .firstOrNull;
    if (definition == null) {
      throw StateError('Unknown portrait state $portraitStateId');
    }
    final portrait = character.portraits
        .where((entry) => entry.portraitStateId == portraitStateId)
        .firstOrNull;
    final sourceStatus = await _inspectSource(
      portrait: portrait,
      projectRootPath: projectRootPath,
      projectRevision: projectRevision,
    );
    final usages = await _findUsages(
      project: project,
      projectRootPath: projectRootPath,
      characterId: character.id,
      portraitStateId: portraitStateId,
    );
    final missingCharacterNames = project.characters
        .where(
          (candidate) => !candidate.portraits.any(
            (entry) => entry.portraitStateId == portraitStateId,
          ),
        )
        .map((candidate) => candidate.name)
        .toList(growable: false);
    return CharacterPortraitInspectorReadModel(
      definition: definition,
      portrait: portrait,
      sourceStatus: sourceStatus,
      usages: usages,
      missingCharacterNames: missingCharacterNames,
    );
  }

  Future<CharacterPortraitSourceStatus> _inspectSource({
    required CharacterPortraitVariant? portrait,
    required String projectRootPath,
    required String projectRevision,
  }) async {
    if (portrait == null) return CharacterPortraitSourceStatus.missingPortrait;
    try {
      await mediaResolver.resolve(
        CharacterStudioMediaRequest(
          projectRootPath: projectRootPath,
          assetId: portrait.assetId,
          projectRevision: projectRevision,
        ),
      );
      return CharacterPortraitSourceStatus.valid;
    } on Object {
      return CharacterPortraitSourceStatus.invalidSource;
    }
  }

  Future<List<CharacterPortraitDialogueUsage>> _findUsages({
    required ProjectManifest project,
    required String projectRootPath,
    required String characterId,
    required String portraitStateId,
  }) async {
    final usages = <CharacterPortraitDialogueUsage>[];
    for (final dialogue in project.dialogues) {
      final source = await dialogueSourceReader.read(
        projectRootPath: projectRootPath,
        relativePath: dialogue.relativePath,
      );
      if (source == null) continue;
      final lines = source.split(RegExp(r'\r?\n'));
      for (var index = 0; index < lines.length; index++) {
        final match = _portraitDirective.firstMatch(lines[index]);
        if (match == null ||
            match.group(1) != characterId ||
            match.group(2) != portraitStateId) {
          continue;
        }
        usages.add(
          CharacterPortraitDialogueUsage(
            dialogueId: dialogue.id,
            dialogueName: dialogue.name,
            lineNumber: index + 1,
            previewText: _previewAfter(lines, index),
          ),
        );
      }
    }
    return usages;
  }
}

final RegExp _portraitDirective = RegExp(
  r'^\s*<<portrait\s+([^\s>]+)\s+([^\s>]+)>>\s*$',
);

String _previewAfter(List<String> lines, int directiveIndex) {
  for (var index = directiveIndex + 1; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.isEmpty) continue;
    if (line.startsWith('<<') || line == '---' || line == '===') break;
    final separator = line.indexOf(':');
    return separator > 0 ? line.substring(separator + 1).trim() : line;
  }
  return 'Ligne de dialogue référencée';
}
