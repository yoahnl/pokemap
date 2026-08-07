import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pokemap_hub/app/di/infrastructure_providers.dart';
import 'package:pokemap_hub/features/appearance/data/repositories/avelune_appearance_repository_impl.dart';
import 'package:pokemap_hub/features/appearance/data/repositories/custom_background_repository_impl.dart';
import 'package:pokemap_hub/features/appearance/domain/repositories/avelune_appearance_repository_interface.dart';
import 'package:pokemap_hub/platform/file_picker_background_picker.dart';
import 'package:pokemap_hub/platform/isolate_background_image_processor.dart';
import 'package:pokemap_hub/features/appearance/domain/repositories/custom_background_repository_interface.dart';

/// Infrastructure wiring for Avelune appearance.
final aveluneAppearanceRepositoryProvider =
    FutureProvider<AveluneAppearanceRepositoryInterface>((ref) async {
  return AveluneAppearanceStore(
    supportRoot: await ref.watch(supportRootProvider.future),
  );
});

/// Decodes and re-encodes background images off the UI isolate.
final backgroundImageProcessorProvider =
    Provider<AveluneBackgroundImageProcessor>(
  (ref) => AveluneIsolateBackgroundImageProcessor(),
);

/// Picks, validates and stores a player-supplied background.
final customBackgroundGatewayProvider =
    FutureProvider<AveluneCustomBackgroundGateway>((ref) async {
  final root = await ref.watch(supportRootProvider.future);
  final processor = ref.watch(backgroundImageProcessorProvider);
  return AveluneCustomBackgroundImporter(
    picker: const AveluneFilePickerBackgroundPicker(),
    processor: processor,
    storage: AveluneLocalCustomBackgroundStorage(
      supportRoot: root,
      processor: processor,
    ),
  );
});
