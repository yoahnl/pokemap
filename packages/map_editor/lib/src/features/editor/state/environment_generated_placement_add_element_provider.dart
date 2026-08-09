import 'package:flutter_riverpod/flutter_riverpod.dart';

final environmentGeneratedPlacementAddElementProvider = NotifierProvider<
    EnvironmentGeneratedPlacementAddElementController, String?>(
  EnvironmentGeneratedPlacementAddElementController.new,
);

/// Owns the transient generated-element selection used by placement tools.
final class EnvironmentGeneratedPlacementAddElementController
    extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? elementId) {
    if (state == elementId) return;
    state = elementId;
  }
}
