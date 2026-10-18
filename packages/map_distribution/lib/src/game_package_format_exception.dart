final class GamePackageFormatException extends FormatException {
  GamePackageFormatException({
    required this.code,
    required String path,
    required String message,
    List<String> relatedCodes = const <String>[],
    Map<String, Object?>? details,
  })  : path = _safePath(path),
        relatedCodes = List.unmodifiable(relatedCodes),
        details = details == null ? null : Map.unmodifiable(details),
        super(_redact(message), _safePath(path));

  final String code;
  final String path;
  final List<String> relatedCodes;
  final Map<String, Object?>? details;

  @override
  String toString() =>
      'GamePackageFormatException($code at ${_safePath(path)}): $message';

  static String _safePath(String value) {
    if (_sensitive.hasMatch(value) || _controls.hasMatch(value)) {
      return '<redacted-path>';
    }
    return value.length <= 512 ? value : '${value.substring(0, 509)}...';
  }

  static String _redact(String value) => value
      .replaceAll(_sensitive, '<redacted>')
      .replaceAll(_controls, '\u{fffd}');

  static final RegExp _controls = RegExp(r'[\u0000-\u001f\u007f]');
  static final RegExp _sensitive = RegExp(
    r'(?:'
    r'sk-[A-Za-z0-9_-]{8,}|'
    r'ghp_[A-Za-z0-9]{8,}|'
    r'xox[baprs]-[A-Za-z0-9_-]*|'
    r'-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----|'
    r'[a-z][a-z0-9+.-]*://[^/\s:@]+:[^/\s@]+@|'
    r'(?:^|[/\\._-])secret(?:[/\\._-]|$)'
    r')',
    caseSensitive: false,
  );
}
