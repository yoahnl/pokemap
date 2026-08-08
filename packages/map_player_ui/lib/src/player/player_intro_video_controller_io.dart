import 'dart:io';

import 'package:video_player/video_player.dart';

VideoPlayerController createPlayerIntroVideoController(
  Uri uri, {
  Future<ClosedCaptionFile>? captions,
}) {
  if (uri.scheme == 'file' || uri.scheme.isEmpty) {
    final path = uri.scheme == 'file' ? uri.toFilePath() : uri.path;
    return VideoPlayerController.file(
      File(path),
      closedCaptionFile: captions,
    );
  }
  if (uri.scheme == 'asset') {
    return VideoPlayerController.asset(
      uri.path.startsWith('/') ? uri.path.substring(1) : uri.path,
      closedCaptionFile: captions,
    );
  }
  return VideoPlayerController.networkUrl(
    uri,
    closedCaptionFile: captions,
  );
}
