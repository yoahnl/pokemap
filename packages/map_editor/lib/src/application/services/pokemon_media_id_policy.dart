import '../errors/application_errors.dart';

String requireSafePokemonMediaId(String value) {
  final id = value.trim();
  if (id.isEmpty) {
    throw const EditorValidationException(
      'Pokemon media speciesId cannot be empty',
    );
  }
  if (id.contains('/') || id.contains(r'\') || id.contains('\u0000')) {
    throw const EditorValidationException(
      'Pokemon media speciesId must be a single file name',
    );
  }
  return id;
}
