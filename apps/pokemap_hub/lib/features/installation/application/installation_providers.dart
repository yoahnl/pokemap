import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pokemap_hub/app/di/providers.dart';
import 'package:pokemap_hub/features/installation/application/use_cases/consume_editor_exports_use_case.dart';
import 'package:pokemap_hub/features/installation/application/use_cases/install_game_package_use_case.dart';

final installGamePackageUseCaseProvider =
    FutureProvider<InstallGamePackageUseCase>((ref) async {
  return InstallGamePackageUseCase(
    await ref.watch(gameInstallationRepositoryProvider.future),
  );
});

final consumeEditorExportsUseCaseProvider =
    FutureProvider<ConsumeEditorExportsUseCase>((ref) async {
  return ConsumeEditorExportsUseCase(
    await ref.watch(editorExportInboxProvider.future),
  );
});
