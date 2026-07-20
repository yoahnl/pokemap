import '../models/border_signed_int64.dart';

/// Encodes an exact Border signed 64-bit value as its canonical JSON string.
String encodeBorderSignedInt64Json(BorderSignedInt64 value) => value.toString();

/// Decodes a strict canonical decimal JSON string into an exact Border value.
///
/// JSON numbers are deliberately rejected because they cannot carry every
/// signed 64-bit value exactly on JavaScript targets.
BorderSignedInt64 decodeBorderSignedInt64Json(
  Object? json, {
  String path = r'$',
}) {
  if (json is! String) {
    throw FormatException(
      '$path: expected a canonical signed 64-bit decimal string',
    );
  }
  try {
    return BorderSignedInt64.parse(json);
  } on FormatException catch (error) {
    throw FormatException('$path: ${error.message}');
  }
}
