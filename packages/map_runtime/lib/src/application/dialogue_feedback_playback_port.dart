import 'dart:typed_data';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

abstract interface class DialogueFeedbackPlaybackPort {
  Future<void> playCue(DialogueAudioCue cue, {required String playbackId});
}

typedef DialogueIconBytesLoader = Future<Uint8List> Function(String assetId);

String resolveDialogueFeedbackProjectFile(
  String projectRoot,
  String relativePath,
) {
  if (p.isAbsolute(relativePath)) {
    throw StateError('Dialogue asset path must be relative.');
  }
  final root = Directory(projectRoot).resolveSymbolicLinksSync();
  final requested = p.normalize(p.join(root, relativePath));
  if (!p.isWithin(root, requested) ||
      FileSystemEntity.typeSync(requested, followLinks: false) !=
          FileSystemEntityType.file) {
    throw StateError('Dialogue asset is not a regular project file.');
  }
  final resolved = File(requested).resolveSymbolicLinksSync();
  if (!p.isWithin(root, resolved) || resolved != requested) {
    throw StateError('Dialogue asset path contains a symbolic link.');
  }
  return resolved;
}

final class ProjectDialogueIconLoader {
  ProjectDialogueIconLoader({
    required this.projectRoot,
    required Map<String, String> absolutePathsByAssetId,
  }) : absolutePathsByAssetId = Map.unmodifiable(absolutePathsByAssetId);

  final String projectRoot;
  final Map<String, String> absolutePathsByAssetId;

  Future<Uint8List> load(String assetId) async {
    final absolute = absolutePathsByAssetId[assetId];
    if (absolute == null) {
      throw StateError('Unknown dialogue icon identity: $assetId.');
    }
    final relative = p.relative(absolute, from: projectRoot);
    final path = resolveDialogueFeedbackProjectFile(projectRoot, relative);
    final file = File(path);
    final before = await file.stat();
    if (before.size < 33 || before.size > 4194304) {
      throw StateError('Dialogue icon exceeds the PNG byte budget.');
    }
    final handle = await file.open();
    late final Uint8List bytes;
    try {
      bytes = await handle.read(before.size + 1);
    } finally {
      await handle.close();
    }
    final after = await file.stat();
    if (resolveDialogueFeedbackProjectFile(projectRoot, relative) != path ||
        before.size != after.size ||
        before.modified != after.modified ||
        bytes.length != before.size) {
      throw StateError('Dialogue icon changed during loading.');
    }
    validateDialogueIconPng(bytes);
    return bytes.asUnmodifiableView();
  }
}

void validateDialogueIconPng(Uint8List bytes) {
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length < 33 || bytes.length > 4194304) {
    throw StateError('Invalid dialogue icon PNG size.');
  }
  for (var i = 0; i < signature.length; i++) {
    if (bytes[i] != signature[i]) {
      throw StateError('Dialogue icon must be PNG.');
    }
  }
  final data = ByteData.sublistView(bytes);
  if (data.getUint32(8) != 13 || data.getUint32(12) != 0x49484452) {
    throw StateError('Dialogue icon PNG header is invalid.');
  }
  final width = data.getUint32(16);
  final height = data.getUint32(20);
  if (width < 1 || height < 1 || width > 256 || height > 256) {
    throw StateError('Dialogue icon dimensions exceed the decode budget.');
  }
}
