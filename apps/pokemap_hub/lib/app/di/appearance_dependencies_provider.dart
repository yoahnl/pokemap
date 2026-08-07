import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pokemap_hub/app/di/providers.dart';
import 'package:pokemap_hub/features/appearance/application/notifiers/avelune_appearance_dependencies.dart';

/// Assembles the appearance bundle. The seam tests override.
final aveluneAppearanceDependenciesProvider =
    FutureProvider<AveluneAppearanceDependencies>((ref) async {
  return AveluneAppearanceDependencies(
    store: await ref.watch(aveluneAppearanceRepositoryProvider.future),
    customBackground: await ref.watch(customBackgroundGatewayProvider.future),
  );
});
