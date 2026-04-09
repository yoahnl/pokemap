import '../models/pokemon_validation_report.dart';
import '../ports/project_workspace.dart';
import '../services/pokemon_project_validator.dart';

class ValidatePokemonProjectDataUseCase {
  const ValidatePokemonProjectDataUseCase(this.validator);

  final PokemonProjectValidator validator;

  Future<PokemonValidationReport> execute(ProjectWorkspace workspace) {
    return validator.validate(workspace);
  }
}
