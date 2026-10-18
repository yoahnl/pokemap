import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:path/path.dart' as path;

final class LocalSourceInterpretationProfileStore {
  const LocalSourceInterpretationProfileStore();

  Future<SourceInterpretationProfile> read(String filePath) async {
    if (!path.isAbsolute(filePath) ||
        path.normalize(filePath) != filePath ||
        path.extension(filePath).toLowerCase() != '.json' ||
        filePath.contains('\u0000') ||
        await FileSystemEntity.type(filePath, followLinks: false) !=
            FileSystemEntityType.file ||
        await File(filePath).resolveSymbolicLinks() != filePath) {
      throw ContractError('interpretation_profile.file', r'$',
          'Select a regular absolute profile JSON file without symbolic links.');
    }
    final file = File(filePath);
    final before = await file.stat();
    if (before.size > 131072) {
      throw ContractError('interpretation_profile.quota', r'$',
          'The selected profile exceeds its byte budget.');
    }
    final bytes = <int>[];
    await for (final chunk in file.openRead()) {
      if (bytes.length + chunk.length > 131072) {
        throw ContractError('interpretation_profile.quota', r'$',
            'The selected profile exceeds its byte budget.');
      }
      bytes.addAll(chunk);
    }
    final after = await file.stat();
    if (before.size != after.size ||
        before.modified != after.modified ||
        before.changed != after.changed ||
        bytes.length != before.size ||
        await file.resolveSymbolicLinks() != filePath) {
      throw ContractError('interpretation_profile.file_changed', r'$',
          'The selected profile changed while it was read.');
    }
    try {
      return SourceInterpretationProfile.fromJson(
          jsonDecode(utf8.decode(bytes)));
    } on FormatException {
      throw ContractError('interpretation_profile.schema', r'$',
          'The selected profile must contain valid UTF-8 JSON.');
    }
  }
}
