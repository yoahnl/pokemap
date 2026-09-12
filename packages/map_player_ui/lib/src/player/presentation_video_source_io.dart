import 'dart:io';

final class PreparedPresentationVideoSource {
  const PreparedPresentationVideoSource(this.uri, [this._directory]);

  final Uri uri;
  final Directory? _directory;

  Future<void> dispose() async {
    final directory = _directory;
    if (directory != null && await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}

Future<PreparedPresentationVideoSource> preparePresentationVideoSource(
  Uri source,
) async {
  if (source.scheme != 'file' || !source.path.toLowerCase().endsWith('.blob')) {
    return PreparedPresentationVideoSource(source);
  }
  final original = File.fromUri(source);
  final reader = await original.open();
  late final List<int> header;
  try {
    header = await reader.read(16);
  } finally {
    await reader.close();
  }
  if (header.length < 12 ||
      String.fromCharCodes(header.sublist(4, 8)) != 'ftyp') {
    return PreparedPresentationVideoSource(source);
  }
  final brand = String.fromCharCodes(header.sublist(8, 12));
  final extension = switch (brand) {
    'isom' || 'iso2' || 'mp41' || 'mp42' || 'avc1' || 'M4V ' || 'MSNV' => 'mp4',
    'qt  ' => 'mov',
    _ => null,
  };
  if (extension == null) return PreparedPresentationVideoSource(source);
  final directory = await Directory.systemTemp.createTemp('pokemap-video-');
  try {
    final playable = await original.copy('${directory.path}/video.$extension');
    return PreparedPresentationVideoSource(playable.uri, directory);
  } on Object {
    await directory.delete(recursive: true);
    rethrow;
  }
}
