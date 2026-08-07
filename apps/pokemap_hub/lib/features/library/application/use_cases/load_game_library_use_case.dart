import 'package:pokemap_hub/features/library/domain/entities/game_library_read.dart';
import 'package:pokemap_hub/features/library/domain/repositories/game_library_repository_interface.dart';

/// Reads the catalogue, carrying any recovery diagnostics with it.
final class LoadGameLibraryUseCase {
  const LoadGameLibraryUseCase(this._repository);

  final GameLibraryRepositoryInterface _repository;

  Future<GameLibraryRead> call() => _repository.load();
}
