import 'package:video_player/video_player.dart';

VideoPlayerController createPlayerIntroVideoController(
  Uri uri, {
  Future<ClosedCaptionFile>? captions,
}) {
  if (uri.scheme == 'asset') {
    return VideoPlayerController.asset(
      uri.path.startsWith('/') ? uri.path.substring(1) : uri.path,
      closedCaptionFile: captions,
    );
  }
  if (uri.scheme == 'file') {
    throw UnsupportedError('Local intro files are unavailable on this host.');
  }
  return VideoPlayerController.networkUrl(
    uri,
    closedCaptionFile: captions,
  );
}
