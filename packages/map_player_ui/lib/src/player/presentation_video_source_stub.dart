final class PreparedPresentationVideoSource {
  const PreparedPresentationVideoSource(this.uri);

  final Uri uri;

  Future<void> dispose() async {}
}

Future<PreparedPresentationVideoSource> preparePresentationVideoSource(
  Uri source,
) async =>
    PreparedPresentationVideoSource(source);
