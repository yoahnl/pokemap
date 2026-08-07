import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pokemap_hub/app/di/providers.dart';
import 'package:pokemap_hub/features/library/application/use_cases/load_game_library_use_case.dart';

final loadGameLibraryUseCaseProvider =
    FutureProvider<LoadGameLibraryUseCase>((ref) async {
  return LoadGameLibraryUseCase(
    await ref.watch(gameLibraryRepositoryProvider.future),
  );
});
