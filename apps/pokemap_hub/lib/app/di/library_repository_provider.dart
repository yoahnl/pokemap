import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pokemap_hub/app/di/infrastructure_providers.dart';
import 'package:pokemap_hub/features/library/data/repositories/game_library_repository_impl.dart';
import 'package:pokemap_hub/features/library/domain/repositories/game_library_repository_interface.dart';

/// Infrastructure wiring for the installed-game catalogue.
final gameLibraryRepositoryProvider =
    FutureProvider<GameLibraryRepositoryInterface>((ref) async {
  return GameLibraryStore(
    supportRoot: await ref.watch(supportRootProvider.future),
  );
});
