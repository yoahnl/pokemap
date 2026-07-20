import '../exceptions/map_exceptions.dart';
import '../models/border_signed_int64.dart';
import 'border_signed_int64_json_codec.dart';

typedef BorderJsonObject = Map<String, Object?>;

String borderJsonPropertyPath(String parentPath, String property) =>
    '$parentPath.$property';

String borderJsonIndexPath(String parentPath, int index) =>
    '$parentPath[$index]';

BorderJsonObject borderJsonRequireObject(Object? value, String path) {
  if (value is! Map) {
    throw FormatException('$path: expected an object');
  }

  for (final key in value.keys) {
    if (key is! String) {
      throw FormatException('$path: object keys must be strings');
    }
  }

  return <String, Object?>{
    for (final entry in value.entries)
      entry.key as String: entry.value as Object?,
  };
}

List<Object?> borderJsonRequireList(Object? value, String path) {
  if (value is! List) {
    throw FormatException('$path: expected a list');
  }
  return List<Object?>.from(value);
}

void borderJsonRequireExactKeys(
  BorderJsonObject value, {
  required String path,
  required Set<String> requiredKeys,
  Set<String> optionalKeys = const <String>{},
}) {
  final acceptedKeys = <String>{...requiredKeys, ...optionalKeys};
  final unknownKeys = value.keys
      .where((key) => !acceptedKeys.contains(key))
      .toList(growable: false)
    ..sort();
  if (unknownKeys.isNotEmpty) {
    final key = unknownKeys.first;
    throw FormatException(
      '${borderJsonPropertyPath(path, key)}: unknown field',
    );
  }

  final missingKeys = requiredKeys
      .where((key) => !value.containsKey(key))
      .toList(growable: false)
    ..sort();
  if (missingKeys.isNotEmpty) {
    final key = missingKeys.first;
    throw FormatException(
      '${borderJsonPropertyPath(path, key)}: required field is missing',
    );
  }
}

Object? borderJsonRequireField(
  BorderJsonObject value,
  String key,
  String objectPath,
) {
  if (!value.containsKey(key)) {
    throw FormatException(
      '${borderJsonPropertyPath(objectPath, key)}: required field is missing',
    );
  }
  return value[key];
}

String borderJsonRequireString(Object? value, String path) {
  if (value is! String) {
    throw FormatException('$path: expected a string');
  }
  return value;
}

int borderJsonRequireInt(Object? value, String path) {
  if (value is! int) {
    throw FormatException('$path: expected an integer');
  }
  return value;
}

bool borderJsonRequireBool(Object? value, String path) {
  if (value is! bool) {
    throw FormatException('$path: expected a boolean');
  }
  return value;
}

BorderSignedInt64 borderJsonDecodeSignedInt64(Object? value, String path) {
  return decodeBorderSignedInt64Json(value, path: path);
}

String borderJsonEncodeSignedInt64(BorderSignedInt64 value) {
  return encodeBorderSignedInt64Json(value);
}

T borderJsonConstructAtPath<T>(String path, T Function() constructor) {
  try {
    return constructor();
  } on ValidationException catch (error) {
    throw FormatException('$path: ${error.message}');
  } on ArgumentError catch (error) {
    final message = error.message;
    throw FormatException(
      '$path: ${message == null ? error.toString() : message.toString()}',
    );
  }
}
