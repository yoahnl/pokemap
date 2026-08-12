import 'package:file_picker/file_picker.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../application/authoring_api/authoring_mutation_adapter.dart';
import '../../../application/authoring_api/character_studio_authoring_gateway.dart';

final class CharacterStudioPortraitImportException implements Exception {
  const CharacterStudioPortraitImportException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() =>
      'CharacterStudioPortraitImportException($code): $message';
}

abstract interface class CharacterStudioPortraitSourcePicker {
  Future<String?> pickPng();
}

final class FilePickerCharacterStudioPortraitSourcePicker
    implements CharacterStudioPortraitSourcePicker {
  const FilePickerCharacterStudioPortraitSourcePicker();

  @override
  Future<String?> pickPng() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['png'],
      allowMultiple: false,
      withData: false,
    );
    final path = result?.files.singleOrNull?.path;
    if (path == null || path.trim().isEmpty) return null;
    return p.normalize(p.absolute(path));
  }
}

abstract interface class CharacterStudioPortraitAssetGateway {
  Future<ContentArtifactRef> stageExactFile({
    required String projectRootPath,
    required String sourcePath,
  });

  Future<ProjectManifest> apply({
    required String projectRootPath,
    required ProjectManifest expectedProject,
    required String actionId,
    required Map<String, Object?> parameters,
    required String operationLabel,
  });
}

final class CanonicalCharacterStudioPortraitAssetGateway
    implements CharacterStudioPortraitAssetGateway {
  CanonicalCharacterStudioPortraitAssetGateway({
    required AuthoringMutationAdapter mutations,
    required CharacterStudioAuthoringGateway authoring,
  }) : _mutations = mutations,
       _authoring = authoring;

  final AuthoringMutationAdapter _mutations;
  final CharacterStudioAuthoringGateway _authoring;

  @override
  Future<ContentArtifactRef> stageExactFile({
    required String projectRootPath,
    required String sourcePath,
  }) async {
    final staged = await _mutations.stageArtifact(
      projectRootPath,
      sourcePath: sourcePath,
      declaredMediaType: 'image/png',
    );
    return staged.reference;
  }

  @override
  Future<ProjectManifest> apply({
    required String projectRootPath,
    required ProjectManifest expectedProject,
    required String actionId,
    required Map<String, Object?> parameters,
    required String operationLabel,
  }) {
    return _authoring.apply(
      projectRootPath: projectRootPath,
      expectedProject: expectedProject,
      actionId: actionId,
      parameters: parameters,
      operationLabel: operationLabel,
    );
  }
}

final class CharacterStudioPortraitImportService {
  const CharacterStudioPortraitImportService({required this.gateway});

  final CharacterStudioPortraitAssetGateway gateway;

  Future<ProjectManifest> import({
    required String projectRootPath,
    required ProjectManifest project,
    required String characterId,
    required String portraitStateId,
    required String sourcePath,
    required CharacterPortraitFitMode fitMode,
  }) async {
    final character = project.characters
        .where((entry) => entry.id == characterId)
        .firstOrNull;
    if (character == null) {
      throw const CharacterStudioPortraitImportException(
        'character_studio.character_not_found',
        'Le personnage sélectionné n’existe plus.',
      );
    }
    if (!project.characterStudioCatalog.portraitStates.any(
      (state) => state.id == portraitStateId,
    )) {
      throw const CharacterStudioPortraitImportException(
        'character_studio.portrait_state_not_found',
        'L’expression sélectionnée n’existe plus.',
      );
    }
    final staged = await gateway.stageExactFile(
      projectRootPath: projectRootPath,
      sourcePath: sourcePath,
    );
    if (staged.mediaType != 'image/png') {
      throw const CharacterStudioPortraitImportException(
        'character_studio.portrait_source_not_png',
        'Le portrait doit être une image PNG.',
      );
    }
    final current = character.portraits
        .where((portrait) => portrait.portraitStateId == portraitStateId)
        .firstOrNull;
    final digestSuffix = staged.hexDigest.substring(0, 12);
    final assetId =
        current?.assetId ??
        'portrait-${_safeSegment(characterId)}-'
            '${_safeSegment(portraitStateId)}-$digestSuffix';
    return gateway.apply(
      projectRootPath: projectRootPath,
      expectedProject: project,
      actionId: current == null
          ? 'characterStudio.asset.import'
          : 'characterStudio.asset.replace',
      parameters: current == null
          ? <String, Object?>{
              'artifactHandle': staged.handle,
              'assetId': assetId,
              'logicalPath':
                  'assets/characters/${_safeSegment(characterId)}/portraits/'
                  '${_safeSegment(portraitStateId)}-$digestSuffix.png',
              'mediaKind': 'portrait',
              'binding': <String, Object?>{
                'kind': 'portrait',
                'characterId': characterId,
                'portraitStateId': portraitStateId,
                'fitMode': fitMode.name,
              },
            }
          : <String, Object?>{
              'artifactHandle': staged.handle,
              'assetId': assetId,
              'binding': <String, Object?>{
                'kind': 'portrait',
                'characterId': characterId,
                'portraitStateId': portraitStateId,
                'fitMode': fitMode.name,
              },
            },
      operationLabel: 'portrait_import_${characterId}_$portraitStateId',
    );
  }
}

String _safeSegment(String value) {
  final normalized = value.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9_-]+'),
    '-',
  );
  final compact = normalized.replaceAll(RegExp(r'-+'), '-');
  return compact.replaceAll(RegExp(r'^-|-$'), '');
}
