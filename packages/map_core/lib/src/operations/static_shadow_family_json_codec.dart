import '../exceptions/map_exceptions.dart';
import '../models/shadow.dart';

String? encodeStaticShadowFamily(StaticShadowFamily? family) {
  return family?.name;
}

StaticShadowFamily? decodeStaticShadowFamily(Object? json) {
  if (json == null) {
    return null;
  }
  if (json is! String) {
    throw ValidationException(
      'StaticShadowFamily JSON must be a String or null, got ${json.runtimeType}',
    );
  }
  for (final family in StaticShadowFamily.values) {
    if (family.name == json) {
      return family;
    }
  }
  throw ValidationException('Unknown StaticShadowFamily "$json"');
}
