import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/game_memory/application/game_memory_resource.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

Widget? gameMemoryResourceState(
  BuildContext context,
  GameMemoryResource<Object> resource, {
  required String loading,
  required VoidCallback onRetry,
}) {
  final l10n = context.l10n;
  if (resource.loading && !resource.ready) {
    return StudioLoadingState(label: loading);
  }
  final retry = StudioButton(
    label: l10n.memoryRetry,
    icon: Icons.refresh,
    variant: StudioButtonVariant.secondary,
    onPressed: onRetry,
  );
  return switch (resource.problem) {
    GameMemoryProblem.preparationRequired => StudioEmptyState(
      key: const ValueKey('memory-preparation-required'),
      icon: Icons.hourglass_empty,
      title: l10n.memoryPreparationRequired,
      description: l10n.memoryPreparationHint,
      action: retry,
    ),
    GameMemoryProblem.unavailable => StudioEmptyState(
      key: const ValueKey('memory-unavailable'),
      icon: Icons.inventory_2_outlined,
      title: l10n.memoryUnavailable,
      description: l10n.memoryUnavailableHint,
    ),
    GameMemoryProblem.failed => StudioEmptyState(
      key: const ValueKey('memory-failed'),
      icon: Icons.error_outline,
      title: l10n.memoryLoadFailed('${resource.cause}'),
      action: retry,
    ),
    null => resource.ready ? null : StudioLoadingState(label: loading),
  };
}
