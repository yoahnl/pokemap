import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'project_branding_image_import_service.dart';

@immutable
final class PersonalizationStudioIntroAssetSelection {
  const PersonalizationStudioIntroAssetSelection({
    required this.videoPath,
    required this.posterPath,
    this.captionsPath,
  });

  final String videoPath;
  final String posterPath;
  final String? captionsPath;
}

@immutable
final class PersonalizationStudioFontAssetSelection {
  const PersonalizationStudioFontAssetSelection({
    required this.fontPath,
    required this.licensePath,
  });

  final String fontPath;
  final String licensePath;
}

@immutable
final class PersonalizationStudioFilePickerRequest {
  const PersonalizationStudioFilePickerRequest({
    required this.dialogTitle,
    required this.allowedExtensions,
  });

  final String dialogTitle;
  final List<String> allowedExtensions;
}

final class PersonalizationStudioAssetSelectionException implements Exception {
  const PersonalizationStudioAssetSelectionException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  @override
  String toString() =>
      'PersonalizationStudioAssetSelectionException($code): $message';
}

abstract interface class PersonalizationStudioFilePickerBackend {
  Future<List<String>?> pick(PersonalizationStudioFilePickerRequest request);
}

final class PlatformPersonalizationStudioFilePickerBackend
    implements PersonalizationStudioFilePickerBackend {
  const PlatformPersonalizationStudioFilePickerBackend();

  @override
  Future<List<String>?> pick(
    PersonalizationStudioFilePickerRequest request,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: request.dialogTitle,
      type: FileType.custom,
      allowedExtensions: request.allowedExtensions,
      allowMultiple: true,
      withData: false,
      lockParentWindow: true,
    );
    if (result == null) return null;
    return result.files
        .map((file) => file.path)
        .whereType<String>()
        .toList(growable: false);
  }
}

abstract interface class PersonalizationStudioAssetPicker {
  Future<PersonalizationStudioIntroAssetSelection?> pickIntroAssets();

  Future<PersonalizationStudioFontAssetSelection?> pickFontAssets();
}

abstract interface class PersonalizationStudioBrandingImagePicker {
  Future<String?> pickBrandingImage(ProjectBrandingImageRole role);
}

abstract interface class PersonalizationStudioTitleMusicPicker {
  Future<String?> pickTitleMusic();
}

final class FilePickerPersonalizationStudioBrandingImagePicker
    implements PersonalizationStudioBrandingImagePicker {
  const FilePickerPersonalizationStudioBrandingImagePicker({
    this.backend = const PlatformPersonalizationStudioFilePickerBackend(),
  });

  final PersonalizationStudioFilePickerBackend backend;

  @override
  Future<String?> pickBrandingImage(ProjectBrandingImageRole role) async {
    final paths = await backend.pick(
      PersonalizationStudioFilePickerRequest(
        dialogTitle: 'Choisir ${_brandingImagePickerLabel(role)}',
        allowedExtensions: const <String>['png', 'jpg', 'jpeg', 'webp'],
      ),
    );
    if (paths == null) return null;
    final imagePath = _singlePath(
      paths,
      const <String>['.png', '.jpg', '.jpeg', '.webp'],
    );
    if (imagePath == null) {
      throw const PersonalizationStudioAssetSelectionException(
        code: 'brandingImageSelectionInvalid',
        message: 'Sélectionnez exactement une image PNG, JPEG ou WebP.',
      );
    }
    return imagePath;
  }
}

final class FilePickerPersonalizationStudioTitleMusicPicker
    implements PersonalizationStudioTitleMusicPicker {
  const FilePickerPersonalizationStudioTitleMusicPicker({
    this.backend = const PlatformPersonalizationStudioFilePickerBackend(),
  });

  final PersonalizationStudioFilePickerBackend backend;

  @override
  Future<String?> pickTitleMusic() async {
    final paths = await backend.pick(
      const PersonalizationStudioFilePickerRequest(
        dialogTitle: 'Choisir la musique du titre',
        allowedExtensions: <String>['ogg', 'wav', 'mp3', 'flac', 'm4a'],
      ),
    );
    if (paths == null) return null;
    final musicPath = _singlePath(
      paths,
      const <String>['.ogg', '.wav', '.mp3', '.flac', '.m4a'],
    );
    if (musicPath == null) {
      throw const PersonalizationStudioAssetSelectionException(
        code: 'titleMusicSelectionInvalid',
        message:
            'Sélectionnez exactement un fichier OGG, WAV, MP3, FLAC ou M4A.',
      );
    }
    return musicPath;
  }
}

/// Typed selection boundary used by the Personalization Studio.
///
/// The picker only selects paths. Validation, probing and project-owned copies
/// remain the responsibility of the dedicated import services.
final class FilePickerPersonalizationStudioAssetPicker
    implements PersonalizationStudioAssetPicker {
  const FilePickerPersonalizationStudioAssetPicker({
    this.backend = const PlatformPersonalizationStudioFilePickerBackend(),
  });

  final PersonalizationStudioFilePickerBackend backend;

  @override
  Future<PersonalizationStudioIntroAssetSelection?> pickIntroAssets() async {
    final paths = await backend.pick(
      const PersonalizationStudioFilePickerRequest(
        dialogTitle:
            'Choisir la vidéo, le poster et les sous-titres optionnels',
        allowedExtensions: <String>[
          'mp4',
          'png',
          'jpg',
          'jpeg',
          'webp',
          'vtt',
        ],
      ),
    );
    if (paths == null) return null;
    final video = _singlePath(paths, const <String>['.mp4']);
    final poster = _singlePath(
      paths,
      const <String>['.png', '.jpg', '.jpeg', '.webp'],
    );
    final captions = _singlePath(paths, const <String>['.vtt']);
    if (video == null || poster == null) {
      throw const PersonalizationStudioAssetSelectionException(
        code: 'introSelectionIncomplete',
        message:
            'Sélectionnez exactement une vidéo MP4 et un poster PNG, JPEG ou WebP.',
      );
    }
    return PersonalizationStudioIntroAssetSelection(
      videoPath: video,
      posterPath: poster,
      captionsPath: captions,
    );
  }

  @override
  Future<PersonalizationStudioFontAssetSelection?> pickFontAssets() async {
    final paths = await backend.pick(
      const PersonalizationStudioFilePickerRequest(
        dialogTitle: 'Choisir une fonte et son fichier de licence',
        allowedExtensions: <String>['ttf', 'otf', 'txt'],
      ),
    );
    if (paths == null) return null;
    final font = _singlePath(paths, const <String>['.ttf', '.otf']);
    final license = _singlePath(paths, const <String>['.txt']);
    if (font == null || license == null) {
      throw const PersonalizationStudioAssetSelectionException(
        code: 'fontSelectionIncomplete',
        message:
            'Sélectionnez exactement une fonte TTF/OTF et une licence TXT.',
      );
    }
    return PersonalizationStudioFontAssetSelection(
      fontPath: font,
      licensePath: license,
    );
  }
}

String? _singlePath(List<String> paths, List<String> extensions) {
  final matches = paths.where((path) {
    final lower = path.toLowerCase();
    return extensions.any(lower.endsWith);
  }).toList(growable: false);
  return matches.length == 1 ? matches.single : null;
}

String _brandingImagePickerLabel(ProjectBrandingImageRole role) =>
    switch (role) {
      ProjectBrandingImageRole.icon => 'une icône de jeu',
      ProjectBrandingImageRole.cover => 'une cover de bibliothèque',
      ProjectBrandingImageRole.hero => 'un logo ou hero de titre',
    };
